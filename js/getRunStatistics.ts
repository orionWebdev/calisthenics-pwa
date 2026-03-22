// ========================================
// RUN STATISTICS CALCULATOR
// Pure utility – no Firestore access
// ========================================

// ---------- Types ----------

export interface CardioSessionWithDate {
  type: 'strength' | 'cardio' | 'recovery';
  activityType?: string;
  duration?: number | null;
  distanceKm?: number | null;
  rpe?: number | null;
  date?: { toDate?: () => Date } | Date | string;
}

export interface WeeklyRunData {
  weekLabel: string;
  totalDistanceKm: number;
  totalDurationMin: number;
  runCount: number;
  avgPace: number | null;
  avgRpe: number | null;
}

export interface RunStatisticsResult {
  weeklyData: WeeklyRunData[];
}

// ---------- Helpers ----------

const RUN_ACTIVITY_TYPES = ['run', 'running', 'laufen'];

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

function isoWeekKey(date: Date): string {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7));
  const week1 = new Date(d.getFullYear(), 0, 4);
  const weekNum = 1 + Math.round(((d.getTime() - week1.getTime()) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7);
  return `${d.getFullYear()}-${String(weekNum).padStart(2, '0')}`;
}

function weekLabel(weekKey: string): string {
  const [yearStr, weekStr] = weekKey.split('-');
  return `KW ${parseInt(weekStr, 10)}`;
}

// ---------- Main ----------

export function getRunStatistics(
  sessions: CardioSessionWithDate[] | null | undefined,
  periodStart: Date,
  periodEnd: Date,
): RunStatisticsResult {
  if (!sessions?.length) return { weeklyData: [] };

  const start = new Date(periodStart);
  start.setHours(0, 0, 0, 0);
  const end = new Date(periodEnd);
  end.setHours(23, 59, 59, 999);

  // Accumulator per week
  const weeks = new Map<string, {
    distanceKm: number;
    durationMin: number;
    runCount: number;
    rpeSum: number;
    rpeCount: number;
  }>();

  for (const s of sessions) {
    if (s.type !== 'cardio') continue;
    const activity = (s.activityType ?? '').toLowerCase();
    if (!RUN_ACTIVITY_TYPES.includes(activity)) continue;

    const d = parseSessionDate(s.date);
    if (!d || d < start || d > end) continue;

    const key = isoWeekKey(d);
    let bucket = weeks.get(key);
    if (!bucket) {
      bucket = { distanceKm: 0, durationMin: 0, runCount: 0, rpeSum: 0, rpeCount: 0 };
      weeks.set(key, bucket);
    }

    bucket.distanceKm += Number(s.distanceKm) || 0;
    bucket.durationMin += Number(s.duration) || 0;
    bucket.runCount += 1;

    if (s.rpe != null && Number.isFinite(Number(s.rpe))) {
      bucket.rpeSum += Number(s.rpe);
      bucket.rpeCount += 1;
    }
  }

  // Sort by week key and build result
  const sortedKeys = [...weeks.keys()].sort();

  const weeklyData: WeeklyRunData[] = sortedKeys.map(key => {
    const b = weeks.get(key)!;
    return {
      weekLabel: weekLabel(key),
      totalDistanceKm: Math.round(b.distanceKm * 10) / 10,
      totalDurationMin: Math.round(b.durationMin),
      runCount: b.runCount,
      avgPace: b.distanceKm > 0
        ? Math.round((b.durationMin / b.distanceKm) * 100) / 100
        : null,
      avgRpe: b.rpeCount > 0
        ? Math.round((b.rpeSum / b.rpeCount) * 10) / 10
        : null,
    };
  });

  return { weeklyData };
}
