// ========================================
// SESSIONS - HYBRID STRENGTH + CARDIO TRACKING
// ========================================

/**
 * Session Data Model:
 *
 * Strength Session:
 * {
 *   id: string
 *   type: 'strength'
 *   date: timestamp
 *   exercises: [{
 *     exerciseId: string
 *     sets: [{ reps: number, weight?: number }]
 *   }]
 *   duration?: number (minutes)
 *   notes?: string
 *   createdAt: timestamp
 * }
 *
 * Cardio Session:
 * {
 *   id: string
 *   type: 'cardio'
 *   date: timestamp
 *   activityType: 'run' | 'bike' | 'swim' | 'row' | 'other'
 *   duration: number (minutes, required)
 *   distanceKm?: number (optional)
 *   pace?: number (computed: min/km, read-only)
 *   notes?: string
 *   createdAt: timestamp
 * }
 *
 * Recovery Session:
 * {
 *   id: string
 *   type: 'recovery'
 *   date: timestamp
 *   duration: number (minutes, required)
 *   notes?: string
 *   createdAt: timestamp
 * }
 */

let allSessions = [];
let sessionsLoaded = false;
let currentProgressTab = 'overview'; // 'overview', 'strength', 'cardio'
let selectedExerciseId = null;
let selectedActivityType = 'run';
let strengthMetric = 'volume'; // 'volume' or 'bestSet'
let cardioMetric = 'time'; // 'time', 'distance', or 'pace'

// ==================== PERIOD SYSTEM ====================

/**
 * Unified Period Keys: 7D, 30D, 6M, 1Y
 * @typedef {'7D' | '30D' | '6M' | '1Y'} PeriodKey
 */
const PERIOD_CONFIG = {
  '7D': { days: 7, labelKey: 'progress.period.7d', bucketType: 'daily' },
  '30D': { days: 30, labelKey: 'progress.period.30d', bucketType: 'daily' },
  '6M': { days: 180, labelKey: 'progress.period.6m', bucketType: 'weekly' },
  '1Y': { days: 365, labelKey: 'progress.period.1y', bucketType: 'weekly' }
};

// Current period states (default to 7D)
let currentOverviewPeriod = '7D';
let currentStrengthPeriod = '7D';
let currentCardioPeriod = '7D';

// Activity Types Config
const ACTIVITY_TYPES = {
  run: { name: 'Laufen', icon: 'directions_run', color: '#3b82f6' },
  bike: { name: 'Radfahren', icon: 'directions_bike', color: '#10b981' },
  swim: { name: 'Schwimmen', icon: 'pool', color: '#06b6d4' },
  hike: { name: 'Wandern', icon: 'hiking', color: '#a3e635' },
  row: { name: 'Rudern', icon: 'rowing', color: '#8b5cf6' },
  other: { name: 'Sonstiges', icon: 'fitness_center', color: '#f59e0b' }
};

// Recovery Types Config
const RECOVERY_TYPES = {
  yoga: { name: 'Yoga', icon: 'self_improvement', color: '#22c55e' },
  stretching: { name: 'Stretching', icon: 'accessibility_new', color: '#22c55e' },
  foam_roll: { name: 'Foam Rolling', icon: 'sports_gymnastics', color: '#22c55e' },
  sauna: { name: 'Sauna', icon: 'hot_tub', color: '#22c55e' },
  walk: { name: 'Spaziergang', icon: 'directions_walk', color: '#22c55e' },
  meditation: { name: 'Meditation', icon: 'mindfulness', color: '#22c55e' },
  other: { name: 'Sonstiges', icon: 'self_improvement', color: '#22c55e' }
};

function getSessionDurationMinutesSafe(session) {
  const sec = Number(session?.durationSec || session?.durationSeconds || 0);
  if (Number.isFinite(sec) && sec > 0) return Math.round(sec / 60);
  const minutes = Number(session?.duration || 0);
  if (!Number.isFinite(minutes) || minutes <= 0) return 0;
  return Math.round(minutes);
}

