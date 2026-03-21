// ========================================
// WEEKLY RAW LOAD CALCULATOR
// Pure utility – no Firestore access
// ========================================

import { calculateSessionLoad, Session, UserProfile } from './calculateSessionLoad';

// ---------- Types ----------

export interface SessionWithDate extends Session {
  date?: { toDate?: () => Date } | Date | string;
  userId?: string;
}

export interface WeeklyRawLoadResult {
  rawLoad: number;
  strengthLoad: number;
  cardioLoad: number;
  sessionCount: number;
}

// ---------- Helpers ----------

const ZERO_RESULT: WeeklyRawLoadResult = {
  rawLoad: 0,
  strengthLoad: 0,
  cardioLoad: 0,
  sessionCount: 0,
};

function parseSessionDate(date: unknown): Date | null {
  try {
    const d = (date as any)?.toDate
      ? (date as any).toDate()
      : new Date(date as any);
    return isNaN(d.getTime()) ? null : d;
  } catch {
    return null;
  }
}

// ---------- Main ----------

export async function getWeeklyRawLoad(
  sessions: SessionWithDate[] | null | undefined,
  referenceDate: Date,
  userProfile: UserProfile | null | undefined,
  userId?: string | null,
): Promise<WeeklyRawLoadResult> {
  if (!sessions?.length) return { ...ZERO_RESULT };

  const startDate = new Date(referenceDate);
  startDate.setDate(startDate.getDate() - 6);
  startDate.setHours(0, 0, 0, 0);

  const endDate = new Date(referenceDate);
  endDate.setHours(23, 59, 59, 999);

  let strengthLoad = 0;
  let cardioLoad = 0;
  let sessionCount = 0;

  for (const s of sessions) {
    if (s.type !== 'strength' && s.type !== 'cardio') continue;

    if (userId && s.userId && s.userId !== userId) continue;

    const sessionDate = parseSessionDate(s.date);
    if (!sessionDate) continue;
    if (sessionDate < startDate || sessionDate > endDate) continue;

    const result = calculateSessionLoad(s, userProfile);

    if (result.type === 'strength') {
      strengthLoad += result.rawLoad;
    } else if (result.type === 'cardio') {
      cardioLoad += result.rawLoad;
    }
    sessionCount++;
  }

  return {
    rawLoad: strengthLoad + cardioLoad,
    strengthLoad,
    cardioLoad,
    sessionCount,
  };
}
