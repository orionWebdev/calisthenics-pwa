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
const CHRONIC_DECAY_FACTOR = 0.96;

// ---------- Main ----------

export function getACWR(
  sessions: SessionWithDate[] | null | undefined,
  userProfile: UserProfile | null | undefined,
  referenceDate: Date,
): ACWRResult {
  if (!sessions?.length) return { ...ZERO_RESULT };

  const end = new Date(referenceDate);
  end.setHours(23, 59, 59, 999);

  console.log("ACWR RAW SESSIONS:", sessions);
  console.log("ACWR COUNT:", sessions.length);

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
    return { acuteLoad: 0, chronicLoad: 0, acwr: null, readinessScore: null, zone: null, daysSinceLastSession: null };
  }

  // Sort days ascending and iterate with EMA
  const sortedDays = [...dailyLoads.entries()].sort((a, b) => a[0].localeCompare(b[0]));

  // daysSinceLastSession
  const lastSessionKey = sortedDays[sortedDays.length - 1][0];
  const lastSessionDate = new Date(lastSessionKey + 'T00:00:00');
  const refDay = new Date(referenceDate);
  refDay.setHours(0, 0, 0, 0);
  const daysSinceLastSession = Math.floor((refDay.getTime() - lastSessionDate.getTime()) / (1000 * 60 * 60 * 24));

  // 4-week boundary for tracking max chronic
  const fourWeeksAgo = new Date(refDay);
  fourWeeksAgo.setDate(fourWeeksAgo.getDate() - 28);
  const fourWeeksAgoKey = fourWeeksAgo.toISOString().slice(0, 10);

  let acuteEMA = 0;
  let chronicEMA = 0;
  let maxChronicIn4Weeks = 0;

  for (const [day, load] of sortedDays) {
    acuteEMA = load * ACUTE_ALPHA + acuteEMA * (1 - ACUTE_ALPHA);
    chronicEMA = load * CHRONIC_ALPHA + chronicEMA * (1 - CHRONIC_ALPHA);

    if (day >= fourWeeksAgoKey) {
      maxChronicIn4Weeks = Math.max(maxChronicIn4Weeks, chronicEMA);
    }
  }

  // Accelerated chronic decay for extended rest
  if (daysSinceLastSession > 5) {
    chronicEMA *= Math.pow(CHRONIC_DECAY_FACTOR, daysSinceLastSession - 5);
  }

  const acwr = chronicEMA === 0
    ? 1
    : Math.round((acuteEMA / chronicEMA) * 100) / 100;

  // Readiness score: recovery boost when no recent training, else normal mapping
  let readinessScore: number;
  if (daysSinceLastSession >= 7) {
    readinessScore = Math.min(75 + daysSinceLastSession * 2.5, 95);
  } else {
    readinessScore = mapReadiness(acwr);
  }
  readinessScore = Math.round(readinessScore);

  // Zone mapping with form-loss override
  let zone: ACWRZone = mapZone(readinessScore);

  if (daysSinceLastSession > 10 && chronicEMA < 0.4 * maxChronicIn4Weeks) {
    zone = 'form_loss';
  }

  console.log('ACWR RESULT:', { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr, readinessScore, zone, daysSinceLastSession });
  return { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr, readinessScore, zone, daysSinceLastSession };
}
