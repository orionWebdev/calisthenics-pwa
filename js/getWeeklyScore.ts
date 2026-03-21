// ========================================
// WEEKLY SCORE CALCULATOR
// Pure utility – no Firestore access
// ========================================

import { UserProfile } from './calculateSessionLoad';
import { getWeeklyRawLoad, SessionWithDate } from './getWeeklyRawLoad';

// ---------- Types ----------

export interface WeeklyScoreResult {
  weeklyScore: number;
  rawLoad: number;
  strengthLoad: number;
  cardioLoad: number;
  baseline: number;
  sessionCount: number;
}

// ---------- Helpers ----------

const ZERO_RESULT: WeeklyScoreResult = {
  weeklyScore: 0,
  rawLoad: 0,
  strengthLoad: 0,
  cardioLoad: 0,
  baseline: 0,
  sessionCount: 0,
};

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function shiftDateByDays(date: Date, days: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

// ---------- Main ----------

export async function getWeeklyScore(
  sessions: SessionWithDate[] | null | undefined,
  referenceDate: Date,
  userProfile: UserProfile | null | undefined,
  userId?: string | null,
): Promise<WeeklyScoreResult> {
  if (!sessions?.length) return { ...ZERO_RESULT };

  // Current week
  const currentWeek = await getWeeklyRawLoad(sessions, referenceDate, userProfile, userId);

  // Previous 6 weeks
  const previousWeeks = await Promise.all(
    Array.from({ length: 6 }, (_, i) => {
      const refDate = shiftDateByDays(referenceDate, -(i + 1) * 7);
      return getWeeklyRawLoad(sessions, refDate, userProfile, userId);
    }),
  );

  // Baseline: average of previous weeks that have data
  const weeksWithData = previousWeeks.filter((w) => w.rawLoad > 0);
  let baseline: number;

  if (weeksWithData.length < 2) {
    baseline = currentWeek.rawLoad;
  } else {
    const totalLoad = weeksWithData.reduce((sum, w) => sum + w.rawLoad, 0);
    baseline = totalLoad / weeksWithData.length;
  }

  // Score
  const weeklyScore =
    baseline === 0 ? 0 : clamp((currentWeek.rawLoad / baseline) * 70, 0, 100);

  return {
    weeklyScore: Math.round(weeklyScore),
    rawLoad: currentWeek.rawLoad,
    strengthLoad: currentWeek.strengthLoad,
    cardioLoad: currentWeek.cardioLoad,
    baseline,
    sessionCount: currentWeek.sessionCount,
  };
}
