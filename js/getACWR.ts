// ========================================
// ACUTE:CHRONIC WORKLOAD RATIO (ACWR)
// Pure utility – no Firestore access
// ========================================

import { calculateSessionLoad, UserProfile } from './calculateSessionLoad';
import { SessionWithDate } from './getWeeklyRawLoad';

// ---------- Types ----------

export interface ACWRResult {
  acuteLoad: number;
  chronicLoad: number;
  acwr: number | null;
  readinessScore: number | null;
}

// ---------- Helpers ----------

const ZERO_RESULT: ACWRResult = {
  acuteLoad: 0,
  chronicLoad: 0,
  acwr: null,
  readinessScore: null,
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

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function mapReadiness(acwr: number): number {
  let readiness: number;
  if (acwr < 0.8) readiness = 60;
  else if (acwr < 1.0) readiness = 75;
  else if (acwr <= 1.2) readiness = 85;
  else if (acwr <= 1.4) readiness = 65;
  else readiness = 40;
  return clamp(readiness, 0, 100);
}

// ---------- Main ----------

export function getACWR(
  sessions: SessionWithDate[] | null | undefined,
  userProfile: UserProfile | null | undefined,
  referenceDate: Date,
): ACWRResult {
  if (!sessions?.length) return { ...ZERO_RESULT };

  const end = new Date(referenceDate);
  end.setHours(23, 59, 59, 999);

  const acuteStart = new Date(referenceDate);
  acuteStart.setDate(acuteStart.getDate() - 6);
  acuteStart.setHours(0, 0, 0, 0);

  const chronicStart = new Date(referenceDate);
  chronicStart.setDate(chronicStart.getDate() - 27);
  chronicStart.setHours(0, 0, 0, 0);

  let acuteLoad = 0;
  let chronicTotal = 0;
  let earliestSessionDate: Date | null = null;

  for (const s of sessions) {
    if (s.type !== 'strength' && s.type !== 'cardio') continue;

    const sessionDate = parseSessionDate(s.date);
    if (!sessionDate) continue;
    if (sessionDate < chronicStart || sessionDate > end) continue;

    const { rawLoad } = calculateSessionLoad(s, userProfile);

    chronicTotal += rawLoad;

    if (sessionDate >= acuteStart) {
      acuteLoad += rawLoad;
    }

    if (!earliestSessionDate || sessionDate < earliestSessionDate) {
      earliestSessionDate = sessionDate;
    }
  }

  const chronicLoad = chronicTotal / 4;

  // Need at least 14 days of data to produce a meaningful ratio
  if (earliestSessionDate) {
    const daySpan =
      (end.getTime() - earliestSessionDate.getTime()) / (1000 * 60 * 60 * 24);
    if (daySpan < 14) {
      return { acuteLoad, chronicLoad, acwr: null, readinessScore: null };
    }
  } else {
    return { acuteLoad, chronicLoad, acwr: null, readinessScore: null };
  }

  const acwr = chronicLoad === 0
    ? 1
    : Math.round((acuteLoad / chronicLoad) * 100) / 100;

  const readinessScore = mapReadiness(acwr);

  return { acuteLoad, chronicLoad, acwr, readinessScore };
}
