// ========================================
// ACUTE:CHRONIC WORKLOAD RATIO (ACWR)
// Pure utility – no Firestore access
// ========================================

import { calculateSessionLoad, UserProfile } from './calculateSessionLoad';
import { SessionWithDate } from './getWeeklyRawLoad';

// ---------- Types ----------

export type ACWRZone = 'overreaching' | 'fatigued' | 'maintaining' | 'building' | 'peak' | 'form_loss';

export interface ACWRResult {
  acuteLoad: number;
  chronicLoad: number;
  acwr: number | null;
  readinessScore: number | null;
  zone: ACWRZone | null;
  daysSinceLastSession: number | null;
}

// ---------- Helpers ----------

const ZERO_RESULT: ACWRResult = {
  acuteLoad: 0,
  chronicLoad: 0,
  acwr: null,
  readinessScore: null,
  zone: null,
  daysSinceLastSession: null,
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

function mapZone(score: number): ACWRZone {
  if (score <= 35) return 'overreaching';
  if (score <= 55) return 'fatigued';
  if (score <= 70) return 'maintaining';
  if (score <= 85) return 'building';
  return 'peak';
}

// ---------- EMA Constants ----------

const ACUTE_ALPHA = 0.35;
const CHRONIC_ALPHA = 0.10;

// ---------- Helpers ----------

function toLocalDateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${dd}`;
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

  // Build daily load map (aggregate same-day sessions, skip recovery)
  const dailyLoads = new Map<string, number>();

  for (const s of sessions) {
    if (s.type !== 'strength' && s.type !== 'cardio') continue;

    const sessionDate = parseSessionDate(s.date);
    if (!sessionDate || sessionDate > end) continue;

    const { rawLoad } = calculateSessionLoad(s, userProfile);
    const key = toLocalDateKey(sessionDate);
    dailyLoads.set(key, (dailyLoads.get(key) ?? 0) + rawLoad);
  }

  if (dailyLoads.size === 0) return { ...ZERO_RESULT };

  // Sort keys to find earliest session and compute day span
  const sortedKeys = [...dailyLoads.keys()].sort();
  const refDay = new Date(referenceDate);
  refDay.setHours(0, 0, 0, 0);
  const earliestDate = new Date(sortedKeys[0] + 'T00:00:00');
  const daySpan = Math.floor((refDay.getTime() - earliestDate.getTime()) / (1000 * 60 * 60 * 24));

  // Need at least 14 days of history
  if (daySpan < 14) {
    return { acuteLoad: 0, chronicLoad: 0, acwr: null, readinessScore: null, zone: null, daysSinceLastSession: null };
  }

  // daysSinceLastSession (for UI/insights only, not score manipulation)
  const lastSessionKey = sortedKeys[sortedKeys.length - 1];
  const lastSessionDate = new Date(lastSessionKey + 'T00:00:00');
  const daysSinceLastSession = Math.floor((refDay.getTime() - lastSessionDate.getTime()) / (1000 * 60 * 60 * 24));

  // Continuous EMA over ALL days (including rest days with load=0)
  const loopStart = new Date(Math.max(
    earliestDate.getTime(),
    refDay.getTime() - 56 * 24 * 60 * 60 * 1000
  ));

  let acuteEMA = 0;
  let chronicEMA = 0;
  const cursor = new Date(loopStart);

  while (cursor <= refDay) {
    const dateKey = toLocalDateKey(cursor);
    const dailyLoad = dailyLoads.get(dateKey) || 0;

    acuteEMA = ACUTE_ALPHA * dailyLoad + (1 - ACUTE_ALPHA) * acuteEMA;
    chronicEMA = CHRONIC_ALPHA * dailyLoad + (1 - CHRONIC_ALPHA) * chronicEMA;

    console.log("ACWR DAILY STEP:", { date: dateKey, dailyLoad, acuteEMA, chronicEMA });
    cursor.setDate(cursor.getDate() + 1);
  }

  const acwr = chronicEMA === 0
    ? 1
    : Math.round((acuteEMA / chronicEMA) * 100) / 100;

  const readinessScore = Math.round(mapReadiness(acwr));
  const zone: ACWRZone = mapZone(readinessScore);

  console.log('ACWR RESULT:', { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr, readinessScore, zone, daysSinceLastSession });
  return { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr, readinessScore, zone, daysSinceLastSession };
}
