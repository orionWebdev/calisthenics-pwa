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

// ---------- EMA Constants ----------

const ACUTE_ALPHA = 2 / (7 + 1);
const CHRONIC_ALPHA = 2 / (28 + 1);

// ---------- Main ----------

export function getACWR(
  sessions: SessionWithDate[] | null | undefined,
  userProfile: UserProfile | null | undefined,
  referenceDate: Date,
): ACWRResult {
  if (!sessions?.length) return { ...ZERO_RESULT };

  const end = new Date(referenceDate);
  end.setHours(23, 59, 59, 999);

  // Build daily load map (aggregate same-day sessions, skip recovery)
  const dailyLoads = new Map<string, number>();

  for (const s of sessions) {
    if (s.type !== 'strength' && s.type !== 'cardio') continue;

    const sessionDate = parseSessionDate(s.date);
    if (!sessionDate || sessionDate > end) continue;

    const { rawLoad } = calculateSessionLoad(s, userProfile);
    const key = sessionDate.toISOString().slice(0, 10);
    dailyLoads.set(key, (dailyLoads.get(key) ?? 0) + rawLoad);
  }

  // Need at least 14 unique days of data
  if (dailyLoads.size < 14) {
    return { acuteLoad: 0, chronicLoad : 0, acwr: null, readinessScore: null };
  }

  // Sort days ascending and iterate with EMA
  const sortedDays = [...dailyLoads.entries()].sort((a, b) => a[0].localeCompare(b[0]));

  let acuteEMA = 0;
  let chronicEMA = 0;

  for (const [, load] of sortedDays) {
    acuteEMA = load * ACUTE_ALPHA + acuteEMA * (1 - ACUTE_ALPHA);
    chronicEMA = load * CHRONIC_ALPHA + chronicEMA * (1 - CHRONIC_ALPHA);
  }

  const acwr = chronicEMA === 0
    ? 1
    : Math.round((acuteEMA / chronicEMA) * 100) / 100;

  const readinessScore = mapReadiness(acwr);

  return { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr, readinessScore };
}
