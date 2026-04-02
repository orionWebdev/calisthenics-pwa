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
  todayLoad: number;
  fatiguePenalty: number;
}

export interface ACWROptions {
  applyFatigue?: boolean;
}

// ---------- Helpers ----------

const ZERO_RESULT: ACWRResult = {
  acuteLoad: 0,
  chronicLoad: 0,
  acwr: null,
  readinessScore: null,
  zone: null,
  daysSinceLastSession: null,
  todayLoad: 0,
  fatiguePenalty: 0,
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
  const curve: [number, number][] = [
    [0.0,  15],
    [0.3,  28],
    [0.5,  45],
    [0.65, 58],
    [0.8,  72],
    [0.9,  83],
    [1.0,  92],
    [1.1,  89],
    [1.2,  78],
    [1.3,  66],
    [1.5,  46],
    [1.7,  30],
    [2.0,  16],
    [2.5,  8],
  ];

  const clamped = clamp(acwr, 0, 2.5);
  if (clamped <= curve[0][0]) return curve[0][1];

  for (let i = 0; i < curve.length - 1; i++) {
    const [x0, y0] = curve[i];
    const [x1, y1] = curve[i + 1];
    if (clamped >= x0 && clamped <= x1) {
      const t = (clamped - x0) / (x1 - x0);
      return Math.round(y0 + (y1 - y0) * t);
    }
  }

  return curve[curve.length - 1][1];
}

function mapZone(score: number, acwr?: number): ACWRZone {
  if (acwr !== undefined && acwr < 0.8 && score <= 50) return 'form_loss';
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
  options?: ACWROptions,
): ACWRResult {
  const applyFatigue = options?.applyFatigue ?? false;
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
    return { acuteLoad: 0, chronicLoad: 0, acwr: null, readinessScore: null, zone: null, daysSinceLastSession: null, todayLoad: 0, fatiguePenalty: 0 };
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

  const rawReadinessScore = Math.round(mapReadiness(acwr));

  // Acute fatigue modifier: reduce readiness on days with training load.
  // Uses sqrt curve for diminishing returns so that:
  //   1 moderate session (~1x chronic) → ~10pt penalty
  //   1 hard session   (~2x chronic)  → ~14pt penalty
  //   2 sessions       (~3x chronic)  → ~17pt penalty
  //   extreme day      (~6x chronic)  → ~24pt penalty
  const todayKey = toLocalDateKey(refDay);
  const todayLoad = dailyLoads.get(todayKey) || 0;
  let fatiguePenalty = 0;

  if (applyFatigue && todayLoad > 0 && chronicEMA > 0.01) {
    const loadRatio = todayLoad / chronicEMA;
    fatiguePenalty = Math.min(35, Math.round(10 * Math.sqrt(loadRatio)));
  }

  const readinessScore = Math.max(5, rawReadinessScore - fatiguePenalty);
  const zone: ACWRZone = mapZone(readinessScore, acwr);

  console.log('ACWR RESULT:', { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr, readinessScore, zone, daysSinceLastSession, todayLoad, fatiguePenalty });
  return { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr, readinessScore, zone, daysSinceLastSession, todayLoad, fatiguePenalty };
}
