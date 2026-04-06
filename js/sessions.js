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

// ==================== DATA LOADING ====================

/**
 * Lädt alle Sessions
 */
async function loadSessions() {
  try {
    console.log('Loading sessions...');
    sessionsLoaded = false;
    allSessions = await getAllDocs(sessionsCollection);
    sessionsLoaded = true;
    console.log(`Loaded ${allSessions.length} sessions`);
    return allSessions;
  } catch (error) {
    console.error('Error loading sessions:', error);
    sessionsLoaded = false;
    return [];
  }
}

/**
 * Speichert letzten aktiven Tab in localStorage
 */
function saveLastProgressTab(tab) {
  localStorage.setItem('lastProgressTab', tab);
  currentProgressTab = tab;
}

/**
 * Lädt letzten aktiven Tab
 */
function loadLastProgressTab() {
  const saved = localStorage.getItem('lastProgressTab');
  if (saved && ['overview', 'strength', 'bodyweight', 'cardio'].includes(saved)) {
    currentProgressTab = saved;
  }
  return currentProgressTab;
}

// ==================== CARDIO CALCULATIONS ====================

/**
 * Berechnet Pace (min/km) aus Duration und Distance
 * @param {number} durationMinutes
 * @param {number} distanceKm
 * @returns {number|null} Pace in min/km
 */
function calculatePace(durationMinutes, distanceKm) {
  if (!distanceKm || distanceKm <= 0) return null;
  return durationMinutes / distanceKm;
}

/**
 * Formatiert Pace als "5:30 min/km"
 */
function formatPace(paceMinPerKm) {
  if (!paceMinPerKm) return '-';
  const minutes = Math.floor(paceMinPerKm);
  const seconds = Math.round((paceMinPerKm - minutes) * 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')} min/km`;
}

// ==================== STRENGTH CALCULATIONS ====================

/**
 * Berechnet Volumen (Summe aller Reps) für eine Exercise in einer Session
 */
function calculateExerciseVolume(exerciseEntry) {
  if (!exerciseEntry.sets || !Array.isArray(exerciseEntry.sets)) return 0;
  return exerciseEntry.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
}

/**
 * Findet Best Set (max Reps in einem Set) für eine Exercise in einer Session
 */
function calculateBestSet(exerciseEntry) {
  if (!exerciseEntry.sets || !Array.isArray(exerciseEntry.sets)) return 0;
  return Math.max(...exerciseEntry.sets.map(set => set.reps || 0));
}

/**
 * Berechnet TOTAL Volumen für eine komplette Strength-Session
 * Formula: sum of all sets; if set has weight AND reps => (weight * reps), else just reps
 */
function calculateSessionStrengthVolume(session) {
  if (session.type !== 'strength' || !session.exercises) return 0;

  let totalVolume = 0;
  session.exercises.forEach(exercise => {
    if (!exercise.sets || !Array.isArray(exercise.sets)) return;
    exercise.sets.forEach(set => {
      const reps = set.reps || 0;
      const weight = set.weight || 0;
      totalVolume += weight > 0 ? (weight * reps) : reps;
    });
  });
  return totalVolume;
}

// ==================== BODYWEIGHT VOLUME SYSTEM ====================

/**
 * Load Factor Mapping for Bodyweight Exercises
 * Higher factor = more demanding exercise (relative effort per rep)
 * Based on muscle engagement and typical difficulty
 */
const EXERCISE_LOAD_FACTORS = {
  // Pull exercises (highest relative effort)
  'pull-up': 1.5,
  'pull-ups': 1.5,
  'klimmzug': 1.5,
  'klimmzuege': 1.5,
  'chin-up': 1.4,
  'chin-ups': 1.4,
  'muscle-up': 2.0,
  'muscle-ups': 2.0,
  'row': 1.1,
  'rows': 1.1,
  'rudern': 1.1,
  'inverted row': 1.1,
  'inverted rows': 1.1,
  'australian pull-up': 1.1,

  // Push exercises (medium-high)
  'dip': 1.3,
  'dips': 1.3,
  'push-up': 1.0,
  'push-ups': 1.0,
  'liegestuetz': 1.0,
  'liegestuetze': 1.0,
  'diamond push-up': 1.1,
  'archer push-up': 1.2,
  'pike push-up': 1.2,
  'handstand push-up': 1.8,
  'hspu': 1.8,

  // Leg exercises (high effort)
  'pistol squat': 1.6,
  'pistol squats': 1.6,
  'squat': 0.8,
  'squats': 0.8,
  'kniebeuge': 0.8,
  'kniebeugen': 0.8,
  'lunge': 0.9,
  'lunges': 0.9,
  'ausfallschritt': 0.9,
  'ausfallschritte': 0.9,
  'bulgarian split squat': 1.1,
  'step-up': 0.9,
  'step-ups': 0.9,
  'nordic curl': 1.5,
  'nordic curls': 1.5,

  // Core exercises (medium)
  'plank': 0.5,
  'unterarmstuetz': 0.5,
  'l-sit': 1.3,
  'l-sits': 1.3,
  'dragon flag': 1.6,
  'dragon flags': 1.6,
  'ab rollout': 1.2,
  'hanging leg raise': 1.2,
  'hanging leg raises': 1.2,
  'toes to bar': 1.3,
  'knee raise': 0.9,
  'knee raises': 0.9,
  'leg raise': 1.0,
  'leg raises': 1.0,
  'sit-up': 0.6,
  'sit-ups': 0.6,
  'crunch': 0.5,
  'crunches': 0.5,

  // Skills (very high)
  'front lever': 2.0,
  'back lever': 1.8,
  'planche': 2.2,
  'human flag': 2.0
};

/**
 * Default load factor for unknown bodyweight exercises
 */
const DEFAULT_LOAD_FACTOR = 1.0;

/**
 * Gets load factor for an exercise based on name
 * @param {string} exerciseName
 * @returns {number} Load factor
 */
function getExerciseLoadFactor(exerciseName) {
  if (!exerciseName) return DEFAULT_LOAD_FACTOR;

  const normalized = exerciseName.toLowerCase().trim();

  // Direct match
  if (EXERCISE_LOAD_FACTORS[normalized]) {
    return EXERCISE_LOAD_FACTORS[normalized];
  }

  // Partial match
  for (const [key, factor] of Object.entries(EXERCISE_LOAD_FACTORS)) {
    if (normalized.includes(key) || key.includes(normalized)) {
      return factor;
    }
  }

  return DEFAULT_LOAD_FACTOR;
}

/**
 * Calculates WEIGHTED volume for a strength session
 * Only includes sets with weight > 0
 * Formula: sum of (weight * reps) for all weighted sets
 */
function calculateWeightedVolume(session) {
  if (session.type !== 'strength' || !session.exercises) return 0;

  let totalVolume = 0;
  session.exercises.forEach(exercise => {
    if (!exercise.sets || !Array.isArray(exercise.sets)) return;
    exercise.sets.forEach(set => {
      const reps = set.reps || 0;
      const weight = set.weight || 0;
      if (weight > 0) {
        totalVolume += weight * reps;
      }
    });
  });
  return totalVolume;
}

/**
 * Calculates BODYWEIGHT (Effort) volume for a strength session
 * Only includes sets without weight (bodyweight exercises)
 * Formula: sum of (reps * loadFactor) for all bodyweight sets
 * @param {Object} session
 * @param {Array} exercisesData - Exercise metadata for load factor lookup
 */
function calculateBodyweightVolume(session, exercisesData = []) {
  if (session.type !== 'strength' || !session.exercises) return 0;

  let totalVolume = 0;
  session.exercises.forEach(exerciseEntry => {
    if (!exerciseEntry.sets || !Array.isArray(exerciseEntry.sets)) return;

    // Find exercise metadata for load factor
    let loadFactor = DEFAULT_LOAD_FACTOR;
    const exerciseMeta = exercisesData.find(e => e.id === exerciseEntry.exerciseId);
    if (exerciseMeta) {
      // Use custom loadFactor if stored, otherwise derive from name
      loadFactor = exerciseMeta.loadFactor || getExerciseLoadFactor(exerciseMeta.name);
    }

    exerciseEntry.sets.forEach(set => {
      const reps = set.reps || 0;
      const weight = set.weight || 0;
      // Only count bodyweight sets (no additional weight)
      if (weight === 0 && reps > 0) {
        totalVolume += reps * loadFactor;
      }
    });
  });
  return Math.round(totalVolume);
}

/**
 * Calculates both weighted and bodyweight volumes for a session
 * @param {Object} session
 * @param {Array} exercisesData
 * @returns {{ weighted: number, bodyweight: number, hasWeighted: boolean, hasBodyweight: boolean }}
 */
function calculateDualVolume(session, exercisesData = []) {
  const weighted = calculateWeightedVolume(session);
  const bodyweight = calculateBodyweightVolume(session, exercisesData);

  return {
    weighted,
    bodyweight,
    hasWeighted: weighted > 0,
    hasBodyweight: bodyweight > 0,
    total: weighted + bodyweight
  };
}

/**
 * Aggregates DUAL strength volumes by period
 * @param {PeriodKey} periodKey
 * @param {Array} exercisesData - Exercise metadata for load factors
 * @returns {Array} [{ label, date, weightedVolume, bodyweightVolume, sessionCount }]
 */
function aggregateDualStrengthByPeriod(periodKey = '7D', exercisesData = []) {
  const config = PERIOD_CONFIG[periodKey];
  if (!config) return [];

  const now = new Date();
  const cutoffDate = new Date(now.getTime() - config.days * 24 * 60 * 60 * 1000);

  // Filter relevant sessions
  const relevantSessions = allSessions.filter(s => {
    if (s.type !== 'strength') return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  if (config.bucketType === 'weekly') {
    return aggregateDualWeeklyBuckets(config.days, relevantSessions, exercisesData);
  } else {
    return aggregateDualDailyBuckets(config.days, relevantSessions, exercisesData);
  }
}

/**
 * Aggregates dual volume into daily buckets
 */
function aggregateDualDailyBuckets(days, sessions, exercisesData) {
  const result = [];
  const now = new Date();
  now.setHours(23, 59, 59, 999);

  for (let i = days - 1; i >= 0; i--) {
    const dayStart = new Date(now);
    dayStart.setDate(dayStart.getDate() - i);
    dayStart.setHours(0, 0, 0, 0);

    const dayEnd = new Date(dayStart);
    dayEnd.setHours(23, 59, 59, 999);

    const daySessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= dayStart && sessionDate <= dayEnd;
    });

    let weightedVolume = 0;
    let bodyweightVolume = 0;

    daySessions.forEach(s => {
      const dual = calculateDualVolume(s, exercisesData);
      weightedVolume += dual.weighted;
      bodyweightVolume += dual.bodyweight;
    });

    result.push({
      label: formatDayLabel(dayStart),
      weekLabel: formatDayLabel(dayStart),
      date: dayStart,
      value: weightedVolume + bodyweightVolume, // For backwards compatibility
      weightedVolume,
      bodyweightVolume,
      sessionCount: daySessions.length
    });
  }
  return result;
}

/**
 * Aggregates dual volume into weekly buckets
 */
function aggregateDualWeeklyBuckets(days, sessions, exercisesData) {
  const result = [];
  const now = new Date();
  const currentWeekStart = getWeekStart(now);
  const weeks = Math.ceil(days / 7);

  for (let i = weeks - 1; i >= 0; i--) {
    const weekStart = new Date(currentWeekStart);
    weekStart.setDate(weekStart.getDate() - (i * 7));
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999);

    const weekSessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= weekStart && sessionDate <= weekEnd;
    });

    let weightedVolume = 0;
    let bodyweightVolume = 0;

    weekSessions.forEach(s => {
      const dual = calculateDualVolume(s, exercisesData);
      weightedVolume += dual.weighted;
      bodyweightVolume += dual.bodyweight;
    });

    result.push({
      label: formatWeekLabel(weekStart),
      weekLabel: formatWeekLabel(weekStart),
      weekStart: weekStart,
      date: weekStart,
      value: weightedVolume + bodyweightVolume,
      weightedVolume,
      bodyweightVolume,
      sessionCount: weekSessions.length
    });
  }
  return result;
}

/**
 * Calculates dual strength stats for a given period
 * @param {PeriodKey} periodKey
 * @param {Array} exercisesData
 */
function calculateDualStrengthStats(periodKey, exercisesData = []) {
  const data = aggregateDualStrengthByPeriod(periodKey, exercisesData);

  if (!data || data.length === 0) {
    return {
      weighted: { lastValue: 0, bestValue: 0, avgValue: 0 },
      bodyweight: { lastValue: 0, bestValue: 0, avgValue: 0 },
      totalSessions: 0,
      hasWeighted: false,
      hasBodyweight: false
    };
  }

  // Weighted stats
  const weightedValues = data.map(d => d.weightedVolume);
  const nonZeroWeighted = weightedValues.filter(v => v > 0);

  const weightedStats = {
    lastValue: weightedValues[weightedValues.length - 1] || 0,
    bestValue: nonZeroWeighted.length > 0 ? Math.max(...nonZeroWeighted) : 0,
    avgValue: nonZeroWeighted.length > 0
      ? Math.round(nonZeroWeighted.reduce((s, v) => s + v, 0) / nonZeroWeighted.length)
      : 0
  };

  // Bodyweight stats
  const bodyweightValues = data.map(d => d.bodyweightVolume);
  const nonZeroBodyweight = bodyweightValues.filter(v => v > 0);

  const bodyweightStats = {
    lastValue: bodyweightValues[bodyweightValues.length - 1] || 0,
    bestValue: nonZeroBodyweight.length > 0 ? Math.max(...nonZeroBodyweight) : 0,
    avgValue: nonZeroBodyweight.length > 0
      ? Math.round(nonZeroBodyweight.reduce((s, v) => s + v, 0) / nonZeroBodyweight.length)
      : 0
  };

  const totalSessions = data.reduce((sum, d) => sum + d.sessionCount, 0);

  return {
    weighted: weightedStats,
    bodyweight: bodyweightStats,
    totalSessions,
    hasWeighted: nonZeroWeighted.length > 0,
    hasBodyweight: nonZeroBodyweight.length > 0
  };
}

/**
 * Gibt den Montag der Woche zurück (für wochenbasierte Aggregation)
 */
function getWeekStart(date) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Monday-based
  d.setDate(diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

/**
 * Formatiert Wochenlabel als "KW 3" oder "6. Jan"
 */
function formatWeekLabel(weekStart) {
  const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  return `${weekStart.getDate()}. ${months[weekStart.getMonth()]}`;
}

/**
 * Aggregiert Strength-Volumen basierend auf PeriodKey
 * @param {PeriodKey} periodKey - '7D', '30D', '6M', '1Y'
 * @returns {Array} [{label, date, value, sessionCount}]
 */
function aggregateStrengthByPeriod(periodKey = '7D') {
  const config = PERIOD_CONFIG[periodKey];
  if (!config) return [];

  const now = new Date();
  const cutoffDate = new Date(now.getTime() - config.days * 24 * 60 * 60 * 1000);

  // Filter relevant sessions
  const relevantSessions = allSessions.filter(s => {
    if (s.type !== 'strength') return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  // Use weekly buckets for longer periods, daily for shorter
  if (config.bucketType === 'weekly') {
    return aggregateStrengthWeeklyBuckets(config.days, relevantSessions);
  } else {
    return aggregateStrengthDailyBuckets(config.days, relevantSessions);
  }
}

/**
 * Aggregates strength data into daily buckets
 */
function aggregateStrengthDailyBuckets(days, sessions) {
  const result = [];
  const now = new Date();
  now.setHours(23, 59, 59, 999);

  for (let i = days - 1; i >= 0; i--) {
    const dayStart = new Date(now);
    dayStart.setDate(dayStart.getDate() - i);
    dayStart.setHours(0, 0, 0, 0);

    const dayEnd = new Date(dayStart);
    dayEnd.setHours(23, 59, 59, 999);

    const daySessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= dayStart && sessionDate <= dayEnd;
    });

    const totalVolume = daySessions.reduce((sum, s) => sum + calculateSessionStrengthVolume(s), 0);

    result.push({
      label: formatDayLabel(dayStart),
      date: dayStart,
      value: totalVolume,
      sessionCount: daySessions.length
    });
  }
  return result;
}

/**
 * Aggregates strength data into weekly buckets
 */
function aggregateStrengthWeeklyBuckets(days, sessions) {
  const result = [];
  const now = new Date();
  const currentWeekStart = getWeekStart(now);
  const weeks = Math.ceil(days / 7);

  for (let i = weeks - 1; i >= 0; i--) {
    const weekStart = new Date(currentWeekStart);
    weekStart.setDate(weekStart.getDate() - (i * 7));
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999);

    const weekSessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= weekStart && sessionDate <= weekEnd;
    });

    const totalVolume = weekSessions.reduce((sum, s) => sum + calculateSessionStrengthVolume(s), 0);

    result.push({
      label: formatWeekLabel(weekStart),
      weekLabel: formatWeekLabel(weekStart),
      weekStart: weekStart,
      date: weekStart,
      value: totalVolume,
      sessionCount: weekSessions.length
    });
  }
  return result;
}

/**
 * Calculates strength stats for a given period
 * @param {PeriodKey} periodKey
 */
function calculateStrengthStats(periodKey) {
  const data = aggregateStrengthByPeriod(periodKey);

  if (!data || data.length === 0) {
    return { lastValue: 0, bestValue: 0, avgValue: 0, totalSessions: 0 };
  }

  const values = data.map(d => d.value);
  const lastValue = values[values.length - 1] || 0;
  const bestValue = Math.max(...values);

  const nonZeroValues = values.filter(v => v > 0);
  const avgValue = nonZeroValues.length > 0
    ? Math.round(nonZeroValues.reduce((sum, v) => sum + v, 0) / nonZeroValues.length)
    : 0;

  const totalSessions = data.reduce((sum, d) => sum + d.sessionCount, 0);

  return { lastValue, bestValue, avgValue, totalSessions };
}

/**
 * Legacy wrapper for backwards compatibility
 * @deprecated Use aggregateStrengthByPeriod instead
 */
function aggregateWeeklyStrengthVolume(weeks = 8) {
  // Convert weeks to closest period key
  let periodKey = '30D';
  if (weeks <= 2) periodKey = '7D';
  else if (weeks <= 5) periodKey = '30D';
  else if (weeks <= 26) periodKey = '6M';
  else periodKey = '1Y';

  return aggregateStrengthByPeriod(periodKey);
}

// Normalize localized/variant activity types to canonical keys
const ACTIVITY_ALIASES = {
  running: 'run', laufen: 'run',
  cycling: 'bike', radfahren: 'bike',
  swimming: 'swim', schwimmen: 'swim',
  hiking: 'hike', wandern: 'hike',
  rowing: 'row', rudern: 'row'
};
function normalizeActivityType(raw) {
  const key = (raw || '').toLowerCase();
  return ACTIVITY_ALIASES[key] || key;
}

/**
 * Aggregiert Cardio-Daten basierend auf PeriodKey
 * @param {string} metric - 'time', 'distance', or 'pace'
 * @param {PeriodKey} periodKey - '7D', '30D', '6M', '1Y'
 * @param {string|null} activityFilter - optional filter by activity type
 */
function aggregateCardioByPeriod(metric = 'time', periodKey = '7D', activityFilter = null) {
  const config = PERIOD_CONFIG[periodKey];
  if (!config) return [];

  const now = new Date();
  const cutoffDate = new Date(now.getTime() - config.days * 24 * 60 * 60 * 1000);

  // Filter relevant sessions
  const relevantSessions = allSessions.filter(s => {
    if (s.type !== 'cardio') return false;
    if (activityFilter && normalizeActivityType(s.activityType) !== activityFilter) return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  // Use weekly buckets for longer periods (6M, 1Y), daily for shorter
  if (config.bucketType === 'weekly') {
    return aggregateCardioWeeklyBuckets(metric, config.days, relevantSessions);
  } else {
    return aggregateCardioDailyBuckets(metric, config.days, relevantSessions);
  }
}

/**
 * Aggregates cardio data into daily buckets
 */
function aggregateCardioDailyBuckets(metric, days, sessions) {
  const result = [];
  const now = new Date();
  now.setHours(23, 59, 59, 999);

  for (let i = days - 1; i >= 0; i--) {
    const dayStart = new Date(now);
    dayStart.setDate(dayStart.getDate() - i);
    dayStart.setHours(0, 0, 0, 0);

    const dayEnd = new Date(dayStart);
    dayEnd.setHours(23, 59, 59, 999);

    const daySessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= dayStart && sessionDate <= dayEnd;
    });

    const bucket = computeCardioBucketValue(metric, daySessions);

    result.push({
      label: formatDayLabel(dayStart),
      date: dayStart,
      value: bucket.value,
      sessionCount: daySessions.length,
      totalDuration: bucket.totalDuration,
      totalDistance: bucket.totalDistance
    });
  }
  return result;
}

/**
 * Aggregates cardio data into weekly buckets
 */
function aggregateCardioWeeklyBuckets(metric, days, sessions) {
  const result = [];
  const now = new Date();
  const currentWeekStart = getWeekStart(now);
  const weeks = Math.ceil(days / 7);

  for (let i = weeks - 1; i >= 0; i--) {
    const weekStart = new Date(currentWeekStart);
    weekStart.setDate(weekStart.getDate() - (i * 7));
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999);

    const weekSessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= weekStart && sessionDate <= weekEnd;
    });

    const bucket = computeCardioBucketValue(metric, weekSessions);

    result.push({
      label: formatWeekLabel(weekStart),
      weekLabel: formatWeekLabel(weekStart),
      weekStart: weekStart,
      date: weekStart,
      value: bucket.value,
      sessionCount: weekSessions.length,
      totalDuration: bucket.totalDuration,
      totalDistance: bucket.totalDistance
    });
  }
  return result;
}

/**
 * Computes the value for a bucket based on metric
 * For pace: uses distance-weighted calculation (totalDuration / totalDistance)
 */
function computeCardioBucketValue(metric, sessions) {
  let totalDuration = 0;
  let totalDistance = 0;

  sessions.forEach(s => {
    totalDuration += getSessionDurationMinutesSafe(s);
    totalDistance += s.distanceKm || 0;
  });

  let value = 0;
  if (metric === 'time') {
    value = totalDuration;
  } else if (metric === 'distance') {
    value = Math.round(totalDistance * 10) / 10;
  } else if (metric === 'pace') {
    // Distance-weighted pace: totalDuration / totalDistance
    if (totalDistance > 0 && totalDuration > 0) {
      value = totalDuration / totalDistance; // min/km
      value = Math.round(value * 100) / 100; // Round to 2 decimals
    } else {
      value = 0; // Not enough data
    }
  }

  return { value, totalDuration, totalDistance };
}

/**
 * Returns which endurance sports (run/bike/swim) have sessions in the given period.
 * @param {PeriodKey} periodKey
 * @returns {string[]}
 */
function getAvailableEnduranceSports(periodKey) {
  const config = PERIOD_CONFIG[periodKey];
  if (!config) return [];
  const cutoff = new Date(Date.now() - config.days * 86400000);
  const found = new Set();
  allSessions.forEach(s => {
    if (s.type !== 'cardio') return;
    const d = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (d < cutoff) return;
    const norm = normalizeActivityType(s.activityType);
    if (['run', 'bike', 'swim'].includes(norm)) found.add(norm);
  });
  return ['run', 'bike', 'swim'].filter(s => found.has(s));
}

// ==================== RUN ANALYTICS ====================

const RUN_ACTIVITY_TYPES = ['run', 'running', 'laufen'];
const RUN_WEEKS_MAP = { '7D': 4, '30D': 4, '6M': 26, '1Y': 52 };

/**
 * Aggregates run sessions into weekly buckets for chart display.
 * Returns: [{ weekLabel, totalDistanceKm, totalDurationMin, runCount, avgRpe, avgPace }]
 * @param {PeriodKey} periodKey
 */
function aggregateRunByPeriod(periodKey) {
  const numWeeks = RUN_WEEKS_MAP[periodKey] || 4;
  const now = new Date();
  const currentWeekStart = getWeekStart(now);

  // Filter run sessions
  const cutoff = new Date(currentWeekStart);
  cutoff.setDate(cutoff.getDate() - ((numWeeks - 1) * 7));

  const runSessions = allSessions.filter(s => {
    if (s.type !== 'cardio') return false;
    const activity = (s.activityType || '').toLowerCase();
    if (!RUN_ACTIVITY_TYPES.includes(activity)) return false;
    const d = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return d >= cutoff;
  });

  // Build weekly buckets
  const result = [];
  for (let i = numWeeks - 1; i >= 0; i--) {
    const weekStart = new Date(currentWeekStart);
    weekStart.setDate(weekStart.getDate() - (i * 7));
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999);

    let totalDist = 0;
    let totalDur = 0;
    let count = 0;
    let rpeSum = 0;
    let rpeCount = 0;

    runSessions.forEach(s => {
      const d = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      if (d >= weekStart && d <= weekEnd) {
        totalDist += Number(s.distanceKm) || 0;
        totalDur += getSessionDurationMinutesSafe(s);
        count += 1;
        if (s.rpe != null && Number.isFinite(Number(s.rpe))) {
          rpeSum += Number(s.rpe);
          rpeCount += 1;
        }
      }
    });

    result.push({
      weekLabel: formatWeekLabel(weekStart),
      totalDistanceKm: Math.round(totalDist * 10) / 10,
      totalDurationMin: Math.round(totalDur),
      runCount: count,
      avgPace: totalDist > 0 ? Math.round((totalDur / totalDist) * 100) / 100 : null,
      avgRpe: rpeCount > 0 ? Math.round((rpeSum / rpeCount) * 10) / 10 : null,
    });
  }

  return result;
}

/**
 * Formats a day label for chart display
 */
function formatDayLabel(date) {
  const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  return `${date.getDate()}. ${months[date.getMonth()]}`;
}

/**
 * Calculates cardio stats for a given period
 * @param {PeriodKey} periodKey
 * @param {string} metric - 'time', 'distance', or 'pace'
 * @param {string|null} activityFilter
 */
function calculateCardioStats(periodKey, metric, activityFilter = null) {
  const data = aggregateCardioByPeriod(metric, periodKey, activityFilter);

  if (!data || data.length === 0) {
    return {
      lastValue: 0,
      bestValue: 0,
      avgValue: 0,
      totalSessions: 0,
      hasData: false
    };
  }

  const nonZeroValues = data.filter(d => d.value > 0).map(d => d.value);

  if (nonZeroValues.length === 0) {
    return {
      lastValue: 0,
      bestValue: 0,
      avgValue: 0,
      totalSessions: data.reduce((sum, d) => sum + d.sessionCount, 0),
      hasData: false
    };
  }

  const lastValue = data[data.length - 1]?.value || 0;
  let bestValue, avgValue;

  if (metric === 'pace') {
    // For pace, lower is better (faster)
    bestValue = Math.min(...nonZeroValues);
    avgValue = nonZeroValues.reduce((sum, v) => sum + v, 0) / nonZeroValues.length;
    avgValue = Math.round(avgValue * 100) / 100;
  } else {
    bestValue = Math.max(...nonZeroValues);
    avgValue = Math.round(nonZeroValues.reduce((sum, v) => sum + v, 0) / nonZeroValues.length);
  }

  return {
    lastValue,
    bestValue,
    avgValue,
    totalSessions: data.reduce((sum, d) => sum + d.sessionCount, 0),
    hasData: true
  };
}

/**
 * Formats pace value as "5:30 /km"
 */
function formatPaceShort(paceMinPerKm) {
  if (!paceMinPerKm || paceMinPerKm <= 0) return '-';
  const minutes = Math.floor(paceMinPerKm);
  const seconds = Math.round((paceMinPerKm - minutes) * 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
}

/**
 * Legacy wrapper for backwards compatibility
 * @deprecated Use aggregateCardioByPeriod instead
 */
function aggregateWeeklyCardio(metric = 'time', weeks = 8, activityFilter = null) {
  // Convert weeks to closest period key
  let periodKey = '30D';
  if (weeks <= 2) periodKey = '7D';
  else if (weeks <= 5) periodKey = '30D';
  else if (weeks <= 26) periodKey = '6M';
  else periodKey = '1Y';

  return aggregateCardioByPeriod(metric, periodKey, activityFilter);
}

/**
 * Formatiert Datum als YYYY-MM-DD (timezone-safe, Europe/Berlin)
 */
function formatDateToYYYYMMDD(date) {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Berlin',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  });
  return formatter.format(date);
}

/**
 * Gruppiert Sessions nach YYYY-MM-DD für Activity Calendar
 * @param {number} year
 * @param {number} month (0-indexed)
 * @returns {Object} { 'YYYY-MM-DD': [{session}, ...] }
 */
function getSessionsByDate(year, month) {
  const result = {};

  allSessions.forEach(session => {
    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);

    if (sessionDate.getFullYear() !== year || sessionDate.getMonth() !== month) return;

    const dateKey = formatDateToYYYYMMDD(sessionDate);
    if (!result[dateKey]) {
      result[dateKey] = [];
    }
    result[dateKey].push(session);
  });

  return result;
}

/**
 * Holt Sessions für ein spezifisches Datum
 */
function getSessionsForDate(dateKey) {
  return allSessions.filter(session => {
    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    return formatDateToYYYYMMDD(sessionDate) === dateKey;
  });
}

// ==================== DATA AGGREGATION ====================

/**
 * Aggregiert Strength-Daten für eine Übung
 * @param {string} exerciseId
 * @param {string} metric - 'volume' or 'bestSet'
 * @param {number} weeks
 * @returns {Array} [{date, value, sessionCount}]
 */
function aggregateStrengthData(exerciseId, metric = 'volume', weeks = 8) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - (weeks * 7));

  const strengthSessions = allSessions.filter(s => {
    if (s.type !== 'strength') return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  const groupedByDate = {};

  strengthSessions.forEach(session => {
    const exercise = session.exercises?.find(ex => ex.exerciseId === exerciseId);
    if (!exercise) return;

    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    const dateKey = sessionDate.toISOString().split('T')[0];

    const value = metric === 'volume'
      ? calculateExerciseVolume(exercise)
      : calculateBestSet(exercise);

    if (!groupedByDate[dateKey]) {
      groupedByDate[dateKey] = {
        date: sessionDate,
        value: 0,
        sessionCount: 0
      };
    }

    groupedByDate[dateKey].value += value;
    groupedByDate[dateKey].sessionCount += 1;
  });

  return Object.values(groupedByDate).sort((a, b) => a.date - b.date);
}

/**
 * Aggregiert Cardio-Daten für eine Activity
 * @param {string} activityType
 * @param {string} metric - 'time' or 'distance'
 * @param {number} weeks
 * @returns {Array} [{date, value, sessionCount}]
 */
function aggregateCardioData(activityType, metric = 'time', weeks = 8) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - (weeks * 7));

  const cardioSessions = allSessions.filter(s => {
    if (s.type !== 'cardio') return false;
    if (s.activityType !== activityType) return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  const groupedByDate = {};

  cardioSessions.forEach(session => {
    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    const dateKey = sessionDate.toISOString().split('T')[0];

    let value = 0;
    if (metric === 'time') {
      value = getSessionDurationMinutesSafe(session);
    } else if (metric === 'distance') {
      value = session.distanceKm || 0;
    }

    if (!groupedByDate[dateKey]) {
      groupedByDate[dateKey] = {
        date: sessionDate,
        value: 0,
        sessionCount: 0
      };
    }

    groupedByDate[dateKey].value += value;
    groupedByDate[dateKey].sessionCount += 1;
  });

  return Object.values(groupedByDate).sort((a, b) => a.date - b.date);
}

/**
 * Berechnet Overview Stats (letzte N Tage)
 * @param {number} days
 * @returns {Object}
 */
function calculateOverviewStats(days = 7) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  const recentSessions = allSessions.filter(s => {
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  const strengthCount = recentSessions.filter(s => s.type === 'strength').length;
  const cardioCount = recentSessions.filter(s => s.type === 'cardio').length;

  // Total training time
  let totalTime = 0;
  recentSessions.forEach(s => {
    totalTime += getSessionDurationMinutesSafe(s);
  });

  // Streak berechnen (vereinfacht: aufeinanderfolgende Tage mit Training)
  const streak = calculateStreak();

  return {
    strengthCount,
    cardioCount,
    totalSessions: recentSessions.length,
    totalTime,
    streak
  };
}

/**
 * Berechnet Training Streak
 */
function calculateStreak() {
  if (allSessions.length === 0) return 0;

  // Sortiere Sessions nach Datum (neueste zuerst)
  const sorted = [...allSessions].sort((a, b) => {
    const dateA = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const dateB = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return dateB - dateA;
  });

  // Unique Dates
  const uniqueDates = new Set();
  sorted.forEach(s => {
    const date = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    uniqueDates.add(date.toISOString().split('T')[0]);
  });

  const sortedDates = Array.from(uniqueDates).sort().reverse();

  let streak = 0;
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  for (let i = 0; i < sortedDates.length; i++) {
    const checkDate = new Date(today);
    checkDate.setDate(checkDate.getDate() - i);
    const checkDateStr = checkDate.toISOString().split('T')[0];

    if (sortedDates.includes(checkDateStr)) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}

/**
 * Berechnet Stats für aggregierte Daten
 */
function calculateStats(aggregatedData) {
  if (!aggregatedData || aggregatedData.length === 0) {
    return {
      lastValue: 0,
      bestValue: 0,
      avgValue: 0,
      totalSessions: 0
    };
  }

  const values = aggregatedData.map(d => d.value);
  const lastValue = values[values.length - 1] || 0;
  const bestValue = Math.max(...values);
  const avgValue = Math.round(values.reduce((sum, v) => sum + v, 0) / values.length);
  const totalSessions = aggregatedData.reduce((sum, d) => sum + d.sessionCount, 0);

  return {
    lastValue,
    bestValue,
    avgValue,
    totalSessions
  };
}

function computeHybridBalance(days = 7) {
  const cutoffDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
  const cutoffKey = formatDateToYYYYMMDD(cutoffDate);

  let strengthSec = 0;
  let cardioSec = 0;

  allSessions.forEach(session => {
    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    if (!sessionDate || Number.isNaN(sessionDate.getTime())) return;
    if (formatDateToYYYYMMDD(sessionDate) < cutoffKey) return;

    const sec = Number(session.durationSec || session.durationSeconds || 0);
    const minutes = Number(session.duration || 0);
    const durationSec = sec > 0 ? sec : minutes > 0 ? Math.round(minutes * 60) : 0;
    if (!durationSec) return;

    if (session.type === 'strength') {
      strengthSec += durationSec;
    } else if (session.type === 'cardio') {
      cardioSec += durationSec;
    }
  });

  const totalSec = strengthSec + cardioSec;
  const strengthPct = totalSec ? Math.round((strengthSec / totalSec) * 100) : 0;
  const cardioPct = totalSec ? 100 - strengthPct : 0;

  let labelKey = 'balance.context.balanced';
  if (totalSec < 3600) {
    labelKey = 'balance.context.lowData';
  } else if (strengthPct >= 55) {
    labelKey = 'balance.context.strength';
  } else if (strengthPct < 45) {
    labelKey = 'balance.context.cardio';
  }

  return {
    strengthSec,
    cardioSec,
    strengthPct,
    cardioPct,
    labelKey,
    status: totalSec ? 'ok' : 'empty'
  };
}

// ==================== TRAINING CHARACTER PROGRESS ====================

/**
 * Intensity thresholds for bodyweight training classification
 * Based on total effort points (reps * loadFactor)
 */
const INTENSITY_THRESHOLDS = {
  low: 0,        // < 50 effort points
  medium: 50,    // 50-150 effort points
  high: 150      // > 150 effort points
};

/**
 * Calculates consistency stats for a given period
 * @param {PeriodKey} periodKey
 * @returns {Object} { sessionsPerWeek, avgTrainingMinutesPerWeek, daysSinceLastSession, restDaysInPeriod, trainingDaysInPeriod }
 */
function calculateConsistencyStats(periodKey = '7D') {
  const config = PERIOD_CONFIG[periodKey];
  if (!config) {
    return {
      sessionsPerWeek: 0,
      avgTrainingMinutesPerWeek: 0,
      daysSinceLastSession: null,
      restDaysInPeriod: 0,
      trainingDaysInPeriod: 0
    };
  }

  const now = new Date();
  const cutoffDate = new Date(now.getTime() - config.days * 24 * 60 * 60 * 1000);

  // Filter sessions in period
  const relevantSessions = allSessions.filter(s => {
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  // Unique training days
  const trainingDays = new Set();
  let totalMinutes = 0;

  relevantSessions.forEach(s => {
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    trainingDays.add(formatDateToYYYYMMDD(sessionDate));
    totalMinutes += getSessionDurationMinutesSafe(s);
  });

  const trainingDaysInPeriod = trainingDays.size;
  const restDaysInPeriod = config.days - trainingDaysInPeriod;

  // Sessions per week (rolling average)
  const weeks = config.days / 7;
  const sessionsPerWeek = weeks > 0 ? Math.round((relevantSessions.length / weeks) * 10) / 10 : 0;
  const avgTrainingMinutesPerWeek = weeks > 0 ? Math.round(totalMinutes / weeks) : 0;

  // Days since last session
  let daysSinceLastSession = null;
  if (allSessions.length > 0) {
    const sorted = [...allSessions].sort((a, b) => {
      const dateA = a.date?.toDate ? a.date.toDate() : new Date(a.date);
      const dateB = b.date?.toDate ? b.date.toDate() : new Date(b.date);
      return dateB - dateA;
    });
    const lastSessionDate = sorted[0].date?.toDate ? sorted[0].date.toDate() : new Date(sorted[0].date);
    const diffMs = now.getTime() - lastSessionDate.getTime();
    daysSinceLastSession = Math.floor(diffMs / (24 * 60 * 60 * 1000));
  }

  return {
    sessionsPerWeek,
    avgTrainingMinutesPerWeek,
    daysSinceLastSession,
    restDaysInPeriod,
    trainingDaysInPeriod
  };
}

/**
 * Generates a calm, neutral insight based on stats
 * @param {Object} consistencyStats
 * @param {Object} balanceData
 * @returns {{ key: string, params: object }}
 */
function generateCalmInsight(consistencyStats, balanceData) {
  // No sessions at all
  if (!consistencyStats || consistencyStats.trainingDaysInPeriod === 0) {
    return { key: 'progress.insights.noSessions', params: {} };
  }

  // Rest day today
  if (consistencyStats.daysSinceLastSession >= 1) {
    return { key: 'progress.insights.restDay', params: {} };
  }

  // Check balance
  if (balanceData && balanceData.status === 'ok') {
    if (balanceData.strengthPct >= 55) {
      return { key: 'progress.insights.strengthFocused', params: {} };
    }
    if (balanceData.cardioPct >= 55) {
      return { key: 'progress.insights.cardioFocused', params: {} };
    }
    return { key: 'progress.insights.balanced', params: {} };
  }

  // Default: show session count
  return {
    key: 'progress.insights.sessionsThisWeek',
    params: { count: consistencyStats.trainingDaysInPeriod }
  };
}

/**
 * Calculates weighted load index for a strength session
 * Average of (weight * reps) for all weighted sets
 * @param {Object} session
 * @returns {number} Average load index (0 if no weighted sets)
 */
function calculateWeightedLoadIndex(session) {
  if (session.type !== 'strength' || !session.exercises) return 0;

  let totalLoad = 0;
  let setCount = 0;

  session.exercises.forEach(exercise => {
    if (!exercise.sets || !Array.isArray(exercise.sets)) return;
    exercise.sets.forEach(set => {
      const reps = set.reps || 0;
      const weight = set.weight || 0;
      if (weight > 0 && reps > 0) {
        totalLoad += weight * reps;
        setCount++;
      }
    });
  });

  return setCount > 0 ? Math.round(totalLoad / setCount) : 0;
}

/**
 * Aggregates weighted load index by period
 * @param {PeriodKey} periodKey
 * @returns {Array} [{ label, date, avgLoad, sessionCount }]
 */
function aggregateWeightedLoadByPeriod(periodKey = '7D') {
  const config = PERIOD_CONFIG[periodKey];
  if (!config) return [];

  const now = new Date();
  const cutoffDate = new Date(now.getTime() - config.days * 24 * 60 * 60 * 1000);

  // Filter weighted strength sessions (includes quick-add sessions with discipline='weights')
  const relevantSessions = allSessions.filter(s => {
    if (s.type !== 'strength') return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (sessionDate < cutoffDate) return false;
    // Include sessions with weighted exercises OR quick-add sessions with discipline='weights'
    const hasWeightedExercises = calculateWeightedLoadIndex(s) > 0;
    const isQuickAddWeights = s.discipline === 'weights' && !s.exercises;
    return hasWeightedExercises || isQuickAddWeights;
  });

  if (config.bucketType === 'weekly') {
    return aggregateWeightedLoadWeeklyBuckets(config.days, relevantSessions);
  } else {
    return aggregateWeightedLoadDailyBuckets(config.days, relevantSessions);
  }
}

/**
 * Estimates a load value for quick-add sessions based on duration and difficulty
 * @param {Object} session - Session with duration and difficulty
 * @returns {number} Estimated load
 */
function estimateQuickAddLoad(session) {
  const duration = session.duration || 30;
  const difficultyMultiplier = {
    beginner: 0.5,
    intermediate: 1.0,
    advanced: 1.5,
    elite: 2.0
  };
  const multiplier = difficultyMultiplier[session.difficulty] || 1.0;
  // Base estimate: duration * difficulty multiplier * factor
  return Math.round(duration * multiplier * 2);
}

function aggregateWeightedLoadDailyBuckets(days, sessions) {
  const result = [];
  const now = new Date();
  now.setHours(23, 59, 59, 999);

  for (let i = days - 1; i >= 0; i--) {
    const dayStart = new Date(now);
    dayStart.setDate(dayStart.getDate() - i);
    dayStart.setHours(0, 0, 0, 0);

    const dayEnd = new Date(dayStart);
    dayEnd.setHours(23, 59, 59, 999);

    const daySessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= dayStart && sessionDate <= dayEnd;
    });

    let totalLoad = 0;
    daySessions.forEach(s => {
      const exerciseLoad = calculateWeightedLoadIndex(s);
      // Use calculated load if available, otherwise estimate from quick-add data
      totalLoad += exerciseLoad > 0 ? exerciseLoad : estimateQuickAddLoad(s);
    });
    const avgLoad = daySessions.length > 0 ? Math.round(totalLoad / daySessions.length) : 0;

    result.push({
      label: formatDayLabel(dayStart),
      date: dayStart,
      avgLoad,
      value: avgLoad, // For chart compatibility
      sessionCount: daySessions.length
    });
  }
  return result;
}

function aggregateWeightedLoadWeeklyBuckets(days, sessions) {
  const result = [];
  const now = new Date();
  const currentWeekStart = getWeekStart(now);
  const weeks = Math.ceil(days / 7);

  for (let i = weeks - 1; i >= 0; i--) {
    const weekStart = new Date(currentWeekStart);
    weekStart.setDate(weekStart.getDate() - (i * 7));
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999);

    const weekSessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= weekStart && sessionDate <= weekEnd;
    });

    let totalLoad = 0;
    weekSessions.forEach(s => {
      const exerciseLoad = calculateWeightedLoadIndex(s);
      // Use calculated load if available, otherwise estimate from quick-add data
      totalLoad += exerciseLoad > 0 ? exerciseLoad : estimateQuickAddLoad(s);
    });
    const avgLoad = weekSessions.length > 0 ? Math.round(totalLoad / weekSessions.length) : 0;

    result.push({
      label: formatWeekLabel(weekStart),
      weekLabel: formatWeekLabel(weekStart),
      date: weekStart,
      avgLoad,
      value: avgLoad,
      sessionCount: weekSessions.length
    });
  }
  return result;
}

/**
 * Calculates weighted load stats for a given period
 * @param {PeriodKey} periodKey
 */
function calculateWeightedLoadStats(periodKey) {
  const data = aggregateWeightedLoadByPeriod(periodKey);

  if (!data || data.length === 0) {
    return { lastValue: 0, bestValue: 0, avgValue: 0, totalSessions: 0, hasData: false };
  }

  const nonZeroValues = data.filter(d => d.avgLoad > 0).map(d => d.avgLoad);

  if (nonZeroValues.length === 0) {
    return {
      lastValue: 0,
      bestValue: 0,
      avgValue: 0,
      totalSessions: data.reduce((sum, d) => sum + d.sessionCount, 0),
      hasData: false
    };
  }

  const lastValue = data[data.length - 1]?.avgLoad || 0;
  const bestValue = Math.max(...nonZeroValues);
  const avgValue = Math.round(nonZeroValues.reduce((sum, v) => sum + v, 0) / nonZeroValues.length);

  return {
    lastValue,
    bestValue,
    avgValue,
    totalSessions: data.reduce((sum, d) => sum + d.sessionCount, 0),
    hasData: true
  };
}

/**
 * Calculates training variance for a period
 * Higher value = more variety in exercises
 * @param {PeriodKey} periodKey
 * @returns {number} Variance index (0-1)
 */
function calculateTrainingVariance(periodKey = '7D') {
  const config = PERIOD_CONFIG[periodKey];
  if (!config) return 0;

  const now = new Date();
  const cutoffDate = new Date(now.getTime() - config.days * 24 * 60 * 60 * 1000);

  const relevantSessions = allSessions.filter(s => {
    if (s.type !== 'strength') return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  if (relevantSessions.length === 0) return 0;

  const exerciseOccurrences = new Map();
  let totalOccurrences = 0;

  relevantSessions.forEach(session => {
    if (!session.exercises) return;
    session.exercises.forEach(ex => {
      const id = ex.exerciseId || 'unknown';
      exerciseOccurrences.set(id, (exerciseOccurrences.get(id) || 0) + 1);
      totalOccurrences++;
    });
  });

  if (totalOccurrences === 0) return 0;

  const uniqueExercises = exerciseOccurrences.size;
  // Variance = unique / total (capped at 1)
  return Math.min(1, Math.round((uniqueExercises / totalOccurrences) * 100) / 100);
}

/**
 * Classifies bodyweight session intensity based on effort points
 * @param {Object} session
 * @param {Array} exercisesData
 * @returns {'low' | 'medium' | 'high'}
 */
function classifyBodyweightIntensity(session, exercisesData = []) {
  const effort = calculateBodyweightVolume(session, exercisesData);

  if (effort >= INTENSITY_THRESHOLDS.high) return 'high';
  if (effort >= INTENSITY_THRESHOLDS.medium) return 'medium';
  return 'low';
}

/**
 * Aggregates bodyweight effort by period
 * @param {PeriodKey} periodKey
 * @param {Array} exercisesData
 * @returns {Array} [{ label, date, effortVolume, intensityClass, sessionCount }]
 */
function aggregateBodyweightByPeriod(periodKey = '7D', exercisesData = []) {
  const config = PERIOD_CONFIG[periodKey];
  if (!config) return [];

  const now = new Date();
  const cutoffDate = new Date(now.getTime() - config.days * 24 * 60 * 60 * 1000);

  // Filter sessions with bodyweight exercises (includes quick-add sessions with discipline='bodyweight')
  const relevantSessions = allSessions.filter(s => {
    if (s.type !== 'strength') return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (sessionDate < cutoffDate) return false;
    // Include sessions with bodyweight volume OR quick-add sessions with discipline='bodyweight'
    const hasBodyweightExercises = calculateBodyweightVolume(s, exercisesData) > 0;
    const isQuickAddBodyweight = s.discipline === 'bodyweight' && !s.exercises;
    return hasBodyweightExercises || isQuickAddBodyweight;
  });

  if (config.bucketType === 'weekly') {
    return aggregateBodyweightWeeklyBuckets(config.days, relevantSessions, exercisesData);
  } else {
    return aggregateBodyweightDailyBuckets(config.days, relevantSessions, exercisesData);
  }
}

function aggregateBodyweightDailyBuckets(days, sessions, exercisesData) {
  const result = [];
  const now = new Date();
  now.setHours(23, 59, 59, 999);

  for (let i = days - 1; i >= 0; i--) {
    const dayStart = new Date(now);
    dayStart.setDate(dayStart.getDate() - i);
    dayStart.setHours(0, 0, 0, 0);

    const dayEnd = new Date(dayStart);
    dayEnd.setHours(23, 59, 59, 999);

    const daySessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= dayStart && sessionDate <= dayEnd;
    });

    let totalEffort = 0;
    daySessions.forEach(s => {
      const bwVolume = calculateBodyweightVolume(s, exercisesData);
      // Use calculated volume if available, otherwise estimate from quick-add data
      totalEffort += bwVolume > 0 ? bwVolume : estimateQuickAddLoad(s);
    });

    // Determine intensity class for the day
    let intensityClass = 'low';
    if (totalEffort >= INTENSITY_THRESHOLDS.high) intensityClass = 'high';
    else if (totalEffort >= INTENSITY_THRESHOLDS.medium) intensityClass = 'medium';

    result.push({
      label: formatDayLabel(dayStart),
      date: dayStart,
      effortVolume: totalEffort,
      value: totalEffort, // For chart compatibility
      intensityClass,
      sessionCount: daySessions.length
    });
  }
  return result;
}

function aggregateBodyweightWeeklyBuckets(days, sessions, exercisesData) {
  const result = [];
  const now = new Date();
  const currentWeekStart = getWeekStart(now);
  const weeks = Math.ceil(days / 7);

  for (let i = weeks - 1; i >= 0; i--) {
    const weekStart = new Date(currentWeekStart);
    weekStart.setDate(weekStart.getDate() - (i * 7));
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999);

    const weekSessions = sessions.filter(s => {
      const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
      return sessionDate >= weekStart && sessionDate <= weekEnd;
    });

    let totalEffort = 0;
    weekSessions.forEach(s => {
      const bwVolume = calculateBodyweightVolume(s, exercisesData);
      // Use calculated volume if available, otherwise estimate from quick-add data
      totalEffort += bwVolume > 0 ? bwVolume : estimateQuickAddLoad(s);
    });

    let intensityClass = 'low';
    if (totalEffort >= INTENSITY_THRESHOLDS.high * 7) intensityClass = 'high';
    else if (totalEffort >= INTENSITY_THRESHOLDS.medium * 7) intensityClass = 'medium';

    result.push({
      label: formatWeekLabel(weekStart),
      weekLabel: formatWeekLabel(weekStart),
      date: weekStart,
      effortVolume: totalEffort,
      value: totalEffort,
      intensityClass,
      sessionCount: weekSessions.length
    });
  }
  return result;
}

/**
 * Calculates bodyweight stats for a given period
 * @param {PeriodKey} periodKey
 * @param {Array} exercisesData
 */
function calculateBodyweightStats(periodKey, exercisesData = []) {
  const data = aggregateBodyweightByPeriod(periodKey, exercisesData);

  if (!data || data.length === 0) {
    return { lastValue: 0, bestValue: 0, avgValue: 0, totalSessions: 0, hasData: false };
  }

  const nonZeroValues = data.filter(d => d.effortVolume > 0).map(d => d.effortVolume);

  if (nonZeroValues.length === 0) {
    return {
      lastValue: 0,
      bestValue: 0,
      avgValue: 0,
      totalSessions: data.reduce((sum, d) => sum + d.sessionCount, 0),
      hasData: false
    };
  }

  const lastValue = data[data.length - 1]?.effortVolume || 0;
  const bestValue = Math.max(...nonZeroValues);
  const avgValue = Math.round(nonZeroValues.reduce((sum, v) => sum + v, 0) / nonZeroValues.length);

  return {
    lastValue,
    bestValue,
    avgValue,
    totalSessions: data.reduce((sum, d) => sum + d.sessionCount, 0),
    hasData: true
  };
}

// ==================== CARDIO SESSION MODAL ====================

/**
 * Öffnet "Add Cardio Session" Modal
 */
function openAddCardioModal() {
  const modal = document.getElementById('add-cardio-modal');
  if (!modal) return;

  console.log('🔓 Opening cardio modal...');

  // Reset inline styles
  modal.style.display = '';

  // Reset Form
  const today = new Date().toISOString().split('T')[0];
  const dateInput = document.getElementById('cardio-date');
  const activityInput = document.getElementById('cardio-activity-type');
  const nameInput = document.getElementById('cardio-name');
  const durationInput = document.getElementById('cardio-duration');
  const distanceInput = document.getElementById('cardio-distance');
  const paceDisplay = document.getElementById('cardio-computed-pace');
  const notesInput = document.getElementById('cardio-notes');

  if (dateInput) dateInput.value = today;
  if (activityInput) activityInput.value = 'run';
  if (nameInput) nameInput.value = '';
  if (durationInput) durationInput.value = '';
  if (distanceInput) distanceInput.value = '';
  if (paceDisplay) {
    paceDisplay.textContent = '-';
    paceDisplay.classList.remove('active');
  }
  if (notesInput) notesInput.value = '';

  // Add active class
  modal.classList.add('active');
  triggerHapticFeedback('light');

  console.log('✅ Modal opened');
}

/**
 * Schließt Cardio Modal
 */
function closeAddCardioModal() {
  const modal = document.getElementById('add-cardio-modal');
  if (!modal) return;

  console.log('🔒 Closing cardio modal...');

  // Remove active class immediately
  modal.classList.remove('active');

  // Force display none after animation
  setTimeout(() => {
    modal.style.display = 'none';
  }, 300);

  // Reset form after animation completes
  setTimeout(() => {
    const dateInput = document.getElementById('cardio-date');
    const activityInput = document.getElementById('cardio-activity-type');
    const nameInput = document.getElementById('cardio-name');
    const durationInput = document.getElementById('cardio-duration');
    const distanceInput = document.getElementById('cardio-distance');
    const paceDisplay = document.getElementById('cardio-computed-pace');
    const notesInput = document.getElementById('cardio-notes');

    if (dateInput) dateInput.value = '';
    if (activityInput) activityInput.value = 'run';
    if (nameInput) nameInput.value = '';
    if (durationInput) durationInput.value = '';
    if (distanceInput) distanceInput.value = '';
    if (paceDisplay) {
      paceDisplay.textContent = '-';
      paceDisplay.classList.remove('active');
    }
    if (notesInput) notesInput.value = '';

    console.log('✅ Modal closed and form reset');
  }, 300);
}

/**
 * Live Pace Berechnung im Modal
 */
function updateCardioLivePace() {
  const duration = parseFloat(document.getElementById('cardio-duration').value) || 0;
  const distance = parseFloat(document.getElementById('cardio-distance').value) || 0;

  const paceDisplay = document.getElementById('cardio-computed-pace');
  if (!paceDisplay) return;

  if (duration > 0 && distance > 0) {
    const pace = calculatePace(duration, distance);
    paceDisplay.textContent = formatPace(pace);
    paceDisplay.classList.add('active');
  } else {
    paceDisplay.textContent = '-';
    paceDisplay.classList.remove('active');
  }
}

/**
 * Speichert neue Cardio Session
 */
async function saveCardioSession() {
  const dateInput = document.getElementById('cardio-date').value;
  const validDate = getValidDateStringForCardio(dateInput);
  const activityType = document.getElementById('cardio-activity-type').value;
  const sessionName = document.getElementById('cardio-name').value.trim();
  const duration = parseFloat(document.getElementById('cardio-duration').value);
  const distance = parseFloat(document.getElementById('cardio-distance').value);
  const notes = document.getElementById('cardio-notes').value.trim();

  // Validation
  if (!validDate) {
    showErrorMessage('Bitte wähle ein Datum');
    return;
  }

  if (!duration || duration <= 0) {
    showErrorMessage('Bitte gib eine gültige Dauer ein');
    return;
  }

  try {
    // Show loading
    const saveBtn = document.querySelector('#add-cardio-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<div class="spinner-small"></div><span>Speichert...</span>';
    }

    // Parse date from input (YYYY-MM-DD)
    const selectedDate = new Date(validDate + 'T12:00:00');
    const pace = distance > 0 ? calculatePace(duration, distance) : null;

    const cardioSession = {
      type: 'cardio',
      date: firebase.firestore.Timestamp.fromDate(selectedDate),
      activityType,
      name: sessionName || null,
      duration,
      distanceKm: distance || null,
      pace: pace,
      notes: notes || null,
      createdAt: firebase.firestore.Timestamp.now()
    };

    const savedSessionId = await addDoc(sessionsCollection, cardioSession);

    console.log('✅ Cardio session saved');

    // Mark pending scheduled entry as completed (Quick Entry support)
    await markPendingScheduledEntryCompleted(savedSessionId);

    // Close modal FIRST (before feedback/reload)
    closeAddCardioModal();

    // Show RPE feedback modal and patch session if provided
    if (typeof showRpeFeedbackModal === 'function') {
      const feedbackData = await showRpeFeedbackModal();
      if (feedbackData) {
        await updateDoc(sessionsCollection, savedSessionId, feedbackData);
      }
    }

    // Then reload sessions and refresh view
    await loadSessions();
    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    } else if (typeof renderCurrentProgressTab === 'function') {
      renderCurrentProgressTab();
    }

    // Trigger success glow animation
    triggerSuccessGlow();

  } catch (error) {
    console.error('❌ Error saving cardio session:', error);
    showErrorMessage('Fehler beim Speichern: ' + error.message);
  } finally {
    const saveBtn = document.querySelector('#add-cardio-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span class="material-symbols-rounded">check</span><span>Speichern</span>';
    }
  }
}

// ==================== UI HELPERS ====================

/**
 * Triggert Screen Edge Glow Animation (Apple Intelligence Style)
 */
function triggerSuccessGlow() {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('success');
  }
}

/**
 * Zeigt Fehler-Toast (nur für Fehler behalten wir eine Text-Notification)
 */
function showErrorMessage(message) {
  console.error('❌', message);
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', message);
  }
}

/**
 * Formatiert Datum als kurze Version
 */
function formatShortDate(date) {
  const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  const day = date.getDate();
  const month = months[date.getMonth()];
  return `${day}. ${month}`;
}

/**
 * Formatiert Duration als "1:30 h" oder "45 min"
 */
function formatDuration(minutes) {
  if (minutes >= 60) {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return mins > 0 ? `${hours}:${mins.toString().padStart(2, '0')} h` : `${hours} h`;
  }
  return `${minutes} min`;
}

function getValidDateStringForCardio(dateStr) {
  if (typeof dateStr !== 'string') return null;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return null;

  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(year, month - 1, day);

  if (Number.isNaN(date.getTime())) return null;
  if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
    return null;
  }

  return dateStr;
}

/**
 * Handles backdrop click to close modal
 */
function handleModalBackdropClick(event, modalId) {
  if (event.target.id === modalId) {
    if (modalId === 'add-cardio-modal') {
      closeAddCardioModal();
    }
    if (modalId === 'add-strength-modal') {
      closeAddStrengthModal();
    }
    if (modalId === 'add-recovery-modal') {
      closeAddRecoveryModal();
    }
  }
}

// ==================== STRENGTH QUICK ENTRY MODAL ====================

// State for exercises being logged
let strengthLoggingExercises = [];
let exercisePickerCallback = null;

function openAddStrengthModal(dateStr = null) {
  // Reset exercises list
  strengthLoggingExercises = [];

  // Pre-populate exercises from scheduled plan if available
  const pending = window.pendingScheduledEntry;
  if (pending?.planId && typeof allPlans !== 'undefined' && allPlans) {
    const plan = allPlans.find(p => p.id === pending.planId);
    if (plan) {
      const items = typeof getPlanItems === 'function' ? getPlanItems(plan) : [];
      for (const item of items) {
        if (!item.exerciseId) continue;
        const exercise = typeof allExercises !== 'undefined' && allExercises
          ? allExercises.find(e => e.id === item.exerciseId)
          : null;
        const targetSets = item.target?.sets || 3;
        const targetReps = parseInt(item.target?.reps) || 10;
        strengthLoggingExercises.push({
          exerciseId: item.exerciseId,
          exerciseName: exercise ? getExerciseName(exercise) : item.exerciseId,
          sets: Array.from({ length: targetSets }, () => ({ reps: targetReps }))
        });
      }
    }
  }

  renderStrengthExercisesList();
  const modal = document.getElementById('add-strength-modal');
  if (!modal) return;

  const title = document.getElementById('strength-modal-title');
  if (title) title.textContent = t('workout.quick.title');
  const dateLabel = document.getElementById('strength-date-label');
  if (dateLabel) dateLabel.textContent = t('workout.quick.date') || 'Datum *';
  const nameLabel = document.getElementById('strength-name-label');
  if (nameLabel) nameLabel.textContent = t('workout.quick.name');
  const durationLabel = document.getElementById('strength-duration-label');
  if (durationLabel) durationLabel.textContent = t('workout.quick.duration');
  const typeLabel = document.getElementById('strength-type-label');
  if (typeLabel) typeLabel.textContent = t('workout.quick.type');
  const difficultyLabel = document.getElementById('strength-difficulty-label');
  if (difficultyLabel) difficultyLabel.textContent = t('workout.quick.difficulty');
  const bodyLabel = document.getElementById('strength-type-body-label');
  if (bodyLabel) bodyLabel.textContent = t('workout.quick.bodyweight');
  const bodyDesc = document.getElementById('strength-type-body-desc');
  if (bodyDesc) bodyDesc.textContent = t('workout.quick.bodyweightDesc');
  const weightsLabel = document.getElementById('strength-type-weights-label');
  if (weightsLabel) weightsLabel.textContent = t('workout.quick.weights');
  const weightsDesc = document.getElementById('strength-type-weights-desc');
  if (weightsDesc) weightsDesc.textContent = t('workout.quick.weightsDesc');
  const cancelLabel = document.getElementById('strength-cancel-label');
  if (cancelLabel) cancelLabel.textContent = t('common.cancel');
  const saveLabel = document.getElementById('strength-save-label');
  if (saveLabel) saveLabel.textContent = t('common.save');

  // Exercise logging labels
  const exercisesLabel = document.getElementById('strength-exercises-label');
  if (exercisesLabel) exercisesLabel.textContent = t('workout.logging.exercisesOptional') || 'Übungen (optional)';
  const addExerciseLabel = document.getElementById('strength-add-exercise-label');
  if (addExerciseLabel) addExerciseLabel.textContent = t('workout.logging.addExercise') || 'Übung hinzufügen';

  // Reset form fields
  const today = new Date().toISOString().split('T')[0];
  const dateInput = document.getElementById('strength-date');
  const nameInput = document.getElementById('strength-name');
  const durationInput = document.getElementById('strength-duration');

  if (dateInput) dateInput.value = dateStr || today;
  if (nameInput) nameInput.value = '';
  if (durationInput) durationInput.value = '';

  setStrengthType('bodyweight');
  setStrengthDifficulty('intermediate');

  modal.style.display = '';
  modal.classList.add('active');
  triggerHapticFeedback('light');
}

function closeAddStrengthModal() {
  const modal = document.getElementById('add-strength-modal');
  if (!modal) return;

  modal.classList.remove('active');
  setTimeout(() => {
    modal.style.display = 'none';
  }, 300);
}

function setStrengthType(type) {
  const input = document.getElementById('strength-type');
  if (input) input.value = type;
  document.querySelectorAll('#add-strength-modal .discipline-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.discipline === type);
  });
}

function setStrengthDifficulty(level) {
  const input = document.getElementById('strength-difficulty');
  if (input) input.value = level;
  document.querySelectorAll('#add-strength-modal .difficulty-pill').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.difficulty === level);
  });

  document.querySelectorAll('#add-strength-modal .difficulty-pill').forEach(btn => {
    const key = btn.dataset.difficulty;
    if (key && t) {
      btn.textContent = t(`difficulty.${key}`);
    }
  });
}

// ==================== EXERCISE LOGGING FUNCTIONS ====================

/**
 * Open exercise picker for logging a workout
 */
function openExercisePickerForLogging() {
  // Set callback for when exercise is selected
  exercisePickerCallback = (exerciseId) => {
    addExerciseToStrengthLogging(exerciseId);
  };

  // Open the existing exercise picker in single-select mode
  if (typeof openAddExerciseToPlan === 'function') {
    // Temporarily override selectExerciseForPlan
    window._originalSelectExerciseForPlan = window.selectExerciseForPlan;
    window.selectExerciseForPlan = (exerciseId) => {
      if (exercisePickerCallback) {
        exercisePickerCallback(exerciseId);
        exercisePickerCallback = null;
      }
      closeExercisePicker();
      // Restore original function
      window.selectExerciseForPlan = window._originalSelectExerciseForPlan;
    };
    openAddExerciseToPlan();
    // Elevate exercise picker above the strength modal
    document.getElementById('exercise-picker-modal').classList.add('modal--elevated');
    // Switch to single-select mode for sessions
    if (typeof exercisePickerMode !== 'undefined') {
      exercisePickerMode = 'single';
      renderExercisePicker();
      updateExercisePickerAddButton();
    }
  }
}

/**
 * Add an exercise to the strength logging list
 */
function addExerciseToStrengthLogging(exerciseId) {
  // Check if exercise already exists
  if (strengthLoggingExercises.find(e => e.exerciseId === exerciseId)) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('info', t('workout.logging.exerciseAlreadyAdded') || 'Übung bereits hinzugefügt');
    }
    return;
  }

  // Get exercise details
  const exercise = (typeof allExercises !== 'undefined' && allExercises)
    ? allExercises.find(e => e.id === exerciseId)
    : null;

  if (!exercise) {
    console.error('Exercise not found:', exerciseId);
    return;
  }

  // Add with default sets
  strengthLoggingExercises.push({
    exerciseId: exerciseId,
    exerciseName: getExerciseName(exercise),
    sets: [{ reps: 10 }] // Default: 1 set of 10 reps
  });

  renderStrengthExercisesList();
  triggerHapticFeedback('light');
}

/**
 * Remove an exercise from the logging list
 */
function removeExerciseFromLogging(index) {
  strengthLoggingExercises.splice(index, 1);
  renderStrengthExercisesList();
}

/**
 * Open modal to edit exercise sets
 */
function editExerciseSets(index) {
  const exercise = strengthLoggingExercises[index];
  if (!exercise) return;

  // Open a simple prompt for sets count
  const currentSets = exercise.sets.length;
  const currentReps = exercise.sets[0]?.reps || 10;

  if (typeof openSheet === 'function') {
    openSheet({
      title: exercise.exerciseName,
      render: (container) => {
        container.innerHTML = `
          <div class="space-y-4 p-2">
            <div>
              <label class="block text-sm font-medium mb-2">${t('workout.logging.sets') || 'Sätze'}</label>
              <input type="number" id="edit-sets-count" value="${currentSets}" min="1" max="20"
                class="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 text-xl font-semibold focus:outline-none focus:ring-2 focus:ring-pink-500">
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">${t('workout.logging.reps') || 'Wiederholungen pro Satz'}</label>
              <input type="number" id="edit-reps-count" value="${currentReps}" min="1" max="100"
                class="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 text-xl font-semibold focus:outline-none focus:ring-2 focus:ring-pink-500">
            </div>
            <button onclick="saveExerciseSets(${index})" class="w-full btn-primary mt-4">
              <span class="material-symbols-rounded">check</span>
              <span>${t('common.save') || 'Speichern'}</span>
            </button>
          </div>
        `;
      }
    });
  }
}

/**
 * Save edited exercise sets
 */
function saveExerciseSets(index) {
  const setsInput = document.getElementById('edit-sets-count');
  const repsInput = document.getElementById('edit-reps-count');

  if (!setsInput || !repsInput) return;

  const setsCount = parseInt(setsInput.value) || 1;
  const repsCount = parseInt(repsInput.value) || 10;

  // Create sets array
  const sets = [];
  for (let i = 0; i < setsCount; i++) {
    sets.push({ reps: repsCount });
  }

  strengthLoggingExercises[index].sets = sets;

  if (typeof closeSheet === 'function') {
    closeSheet();
  }

  renderStrengthExercisesList();
}

/**
 * Render the list of exercises being logged
 */
function renderStrengthExercisesList() {
  const container = document.getElementById('strength-exercises-list');
  if (!container) return;

  if (strengthLoggingExercises.length === 0) {
    container.innerHTML = '';
    return;
  }

  container.innerHTML = strengthLoggingExercises.map((exercise, index) => {
    const totalReps = exercise.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
    const setsCount = exercise.sets.length;

    return `
      <div class="strength-exercise-item">
        <div class="exercise-icon">
          <span class="material-symbols-rounded">fitness_center</span>
        </div>
        <div class="exercise-info">
          <div class="exercise-name">${exercise.exerciseName}</div>
          <div class="exercise-sets-info">
            <span class="sets-badge">${setsCount} ${setsCount === 1 ? 'Satz' : 'Sätze'}</span>
            <span>${totalReps} Wdh.</span>
          </div>
        </div>
        <div class="exercise-actions">
          <button type="button" onclick="editExerciseSets(${index})" title="Bearbeiten">
            <span class="material-symbols-rounded">edit</span>
          </button>
          <button type="button" class="delete-btn" onclick="removeExerciseFromLogging(${index})" title="Entfernen">
            <span class="material-symbols-rounded">delete</span>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

async function saveStrengthSession() {
  const selectedDate = document.getElementById('strength-date')?.value;
  const name = document.getElementById('strength-name')?.value.trim();
  const duration = parseFloat(document.getElementById('strength-duration')?.value);
  const trainingType = document.getElementById('strength-type')?.value || 'bodyweight';
  const difficulty = document.getElementById('strength-difficulty')?.value || 'intermediate';

  if (!selectedDate) {
    showErrorMessage(t('workout.quick.dateRequired') || 'Bitte wähle ein Datum');
    return;
  }

  if (!name) {
    showErrorMessage(t('workout.quick.nameRequired'));
    return;
  }

  if (!duration || duration <= 0) {
    showErrorMessage(t('workout.quick.durationRequired'));
    return;
  }

  try {
    const saveBtn = document.querySelector('#add-strength-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<div class="spinner-small"></div><span>Speichert...</span>';
    }

    const strengthSession = {
      type: 'strength',
      planName: name,
      date: firebase.firestore.Timestamp.fromDate(new Date(selectedDate + 'T12:00:00')),
      duration,
      discipline: trainingType,
      difficulty,
      exercises: strengthLoggingExercises.map(ex => {
        const entry = { exerciseId: ex.exerciseId, sets: ex.sets };
        const exMeta = typeof allExercises !== 'undefined'
          ? allExercises.find(e => e.id === ex.exerciseId)
          : null;
        if (exMeta?.usesBodyweight) {
          entry.usesBodyweight = true;
        }
        return entry;
      }),
      createdAt: firebase.firestore.Timestamp.now()
    };

    const savedSessionId = await addDoc(sessionsCollection, strengthSession);

    // Mark pending scheduled entry as completed (Quick Entry support)
    await markPendingScheduledEntryCompleted(savedSessionId);

    closeAddStrengthModal();

    // Show RPE feedback modal and patch session if provided
    if (typeof showRpeFeedbackModal === 'function') {
      const feedbackData = await showRpeFeedbackModal();
      if (feedbackData) {
        await updateDoc(sessionsCollection, savedSessionId, feedbackData);
      }
    }
    await loadSessions();
    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    } else if (typeof renderCurrentProgressTab === 'function') {
      renderCurrentProgressTab();
    }
    triggerSuccessGlow();
  } catch (error) {
    console.error('Error saving strength session:', error);
    showErrorMessage(t('workout.quick.saveError'));
  } finally {
    const saveBtn = document.querySelector('#add-strength-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span class="material-symbols-rounded">check</span><span>' + t('common.save') + '</span>';
    }
  }
}

// ==================== RECOVERY SESSION MODAL ====================

function openAddRecoveryModal(dateStr = null) {
  const modal = document.getElementById('add-recovery-modal');
  if (!modal) return;

  console.log('🔓 Opening recovery modal...');

  modal.style.display = '';

  const today = new Date().toISOString().split('T')[0];
  const dateInput = document.getElementById('recovery-date');
  const activityInput = document.getElementById('recovery-activity-type');
  const nameInput = document.getElementById('recovery-name');
  const durationInput = document.getElementById('recovery-duration');
  const notesInput = document.getElementById('recovery-notes');

  if (dateInput) {
    dateInput.value = dateStr || today;
  }
  if (activityInput) activityInput.value = 'yoga';
  if (nameInput) nameInput.value = '';
  if (durationInput) durationInput.value = '';
  if (notesInput) notesInput.value = '';

  modal.classList.add('active');
  triggerHapticFeedback('light');
}

function closeAddRecoveryModal() {
  const modal = document.getElementById('add-recovery-modal');
  if (!modal) return;

  console.log('🔒 Closing recovery modal...');

  modal.classList.remove('active');
  setTimeout(() => {
    modal.style.display = 'none';
  }, 300);

  setTimeout(() => {
    const dateInput = document.getElementById('recovery-date');
    const activityInput = document.getElementById('recovery-activity-type');
    const nameInput = document.getElementById('recovery-name');
    const durationInput = document.getElementById('recovery-duration');
    const notesInput = document.getElementById('recovery-notes');

    if (dateInput) dateInput.value = '';
    if (activityInput) activityInput.value = 'yoga';
    if (nameInput) nameInput.value = '';
    if (durationInput) durationInput.value = '';
    if (notesInput) notesInput.value = '';
  }, 300);
}

async function saveRecoverySession() {
  const dateInput = document.getElementById('recovery-date').value;
  const validDate = getValidDateStringForCardio(dateInput);
  const activityType = document.getElementById('recovery-activity-type').value;
  const sessionName = document.getElementById('recovery-name').value.trim();
  const duration = parseFloat(document.getElementById('recovery-duration').value);
  const notes = document.getElementById('recovery-notes').value.trim();

  if (!validDate) {
    showErrorMessage('Bitte wähle ein Datum');
    return;
  }

  if (!duration || duration <= 0) {
    showErrorMessage('Bitte gib eine gültige Dauer ein');
    return;
  }

  try {
    const saveBtn = document.querySelector('#add-recovery-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<div class="spinner-small"></div><span>Speichert...</span>';
    }

    const selectedDate = new Date(validDate + 'T12:00:00');

    const recoverySession = {
      type: 'recovery',
      date: firebase.firestore.Timestamp.fromDate(selectedDate),
      activityType,
      name: sessionName || null,
      duration,
      notes: notes || null,
      createdAt: firebase.firestore.Timestamp.now()
    };

    const savedSessionId = await addDoc(sessionsCollection, recoverySession);

    console.log('✅ Recovery session saved');

    // Mark pending scheduled entry as completed (Quick Entry support)
    await markPendingScheduledEntryCompleted(savedSessionId);

    closeAddRecoveryModal();

    // Show RPE feedback modal and patch session if provided
    if (typeof showRpeFeedbackModal === 'function') {
      const feedbackData = await showRpeFeedbackModal();
      if (feedbackData) {
        await updateDoc(sessionsCollection, savedSessionId, feedbackData);
      }
    }

    await loadSessions();
    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    } else if (typeof renderCurrentProgressTab === 'function') {
      renderCurrentProgressTab();
    }

    triggerSuccessGlow();
  } catch (error) {
    console.error('❌ Error saving recovery session:', error);
    showErrorMessage('Fehler beim Speichern: ' + error.message);
  } finally {
    const saveBtn = document.querySelector('#add-recovery-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span class="material-symbols-rounded">check</span><span>Speichern</span>';
    }
  }
}

// ==================== SCHEDULED ENTRY COMPLETION ====================

/**
 * Mark a pending scheduled entry (Quick Entry) as completed after session save
 * @param {string} sessionId - The ID of the saved session
 */
async function markPendingScheduledEntryCompleted(sessionId) {
  const pendingEntry = window.pendingScheduledEntry;
  if (!pendingEntry || !pendingEntry.id) {
    return; // No pending entry to mark
  }

  try {
    const scheduleUpdate = {
      status: 'completed',
      sessionId: sessionId,
      completedAt: firebase.firestore.Timestamp.now()
    };

    await updateDoc(scheduleCollection, pendingEntry.id, scheduleUpdate);
    console.log('✅ Scheduled entry marked as completed:', pendingEntry.id);
  } catch (error) {
    console.error('❌ Error marking scheduled entry as completed:', error);
  } finally {
    // Always clear pending entry after attempt
    window.pendingScheduledEntry = null;
  }
}

// ==================== WEEKLY SCORE CALCULATIONS ====================

const LOAD_RPE_FACTORS = { 1: 0.6, 2: 0.8, 3: 1.0, 4: 1.2, 5: 1.4 };

function getLoadRpeFactor(rpe) {
  if (rpe == null) return 1.0;
  return LOAD_RPE_FACTORS[rpe] ?? 1.0;
}

// Cardio sport factors (mirrors calculateSessionLoad.ts)
const CARDIO_SPORT_FACTORS = {
  run: 1.0, bike: 0.85, swim: 0.9, hike: 0.4, row: 0.95, other: 1.0
};
const DEFAULT_SPORT_FACTOR = 1.0;
const STRENGTH_VOLUME_DIVISOR = 50;

function getLoadSportFactor(activityType) {
  if (!activityType) return DEFAULT_SPORT_FACTOR;
  return CARDIO_SPORT_FACTORS[activityType.toLowerCase()] ?? DEFAULT_SPORT_FACTOR;
}

// Duration dampening for long sessions (mirrors calculateSessionLoad.ts)
const DAMPENING_THRESHOLD = 120;
const DAMPENING_EXPONENT = 0.8;

function getEffectiveDuration(duration) {
  if (duration <= DAMPENING_THRESHOLD) return duration;
  const excess = duration - DAMPENING_THRESHOLD;
  return DAMPENING_THRESHOLD + Math.pow(excess, DAMPENING_EXPONENT);
}

/**
 * Calculates raw load for a session (ports calculateSessionLoad.ts)
 * @param {Object} session
 * @returns {{ rawLoad: number, type: string }}
 */
function calculateSessionLoadValue(session) {
  const type = session?.type;
  if (!type || type === 'recovery') return { rawLoad: 0, type: type || 'recovery' };

  if (type === 'strength' || type === 'bodyweight') {
    const bodyWeight = (typeof userProfile !== 'undefined' && userProfile?.bodyWeight) || 0;
    const rpe = session.rpe ?? 3;
    const rpeFactor = getLoadRpeFactor(rpe);

    // No exercises: duration-based fallback (Quick Log)
    if (!session.exercises || !Array.isArray(session.exercises) || session.exercises.length === 0) {
      const duration = session.duration || 0;
      if (duration <= 0) return { rawLoad: 0, type };
      const multiplier = session.discipline === 'bodyweight' ? 4.5 : 6;
      const rawLoad = Math.round(duration * rpeFactor * multiplier * 100) / 100;
      console.log('TEST LOAD:', { type, rawLoad, duration, exercises: 0, discipline: session.discipline });
      return { rawLoad, type };
    }

    // Has exercises: volume-based calculation
    let totalVolume = 0;
    for (const exercise of session.exercises) {
      if (!exercise.sets || !Array.isArray(exercise.sets)) continue;

      // Resolve usesBodyweight: stored flag, or fallback to exercise metadata
      let usesBodyweight = exercise.usesBodyweight;
      if (usesBodyweight === undefined && exercise.exerciseId
          && typeof allExercises !== 'undefined' && allExercises) {
        const exMeta = allExercises.find(e => e.id === exercise.exerciseId);
        if (exMeta?.usesBodyweight) usesBodyweight = true;
      }

      for (const set of exercise.sets) {
        const reps = set.reps || 0;
        if (reps <= 0) continue;
        const effectiveWeight = usesBodyweight
          ? bodyWeight
          : (set.weight || 0);
        if (effectiveWeight === 0) continue;
        totalVolume += effectiveWeight * reps;
      }
    }

    // Fallback: if all exercises had 0 effective weight (e.g. bodyweight without profile weight),
    // use duration-based calculation so the session still contributes to ACWR
    if (totalVolume === 0 && session.duration > 0) {
      const multiplier = session.discipline === 'bodyweight' ? 4.5 : 6;
      const rawLoad = Math.round(session.duration * rpeFactor * multiplier * 100) / 100;
      console.log('TEST LOAD (bw fallback):', { type, rawLoad, duration: session.duration, discipline: session.discipline });
      return { rawLoad, type };
    }

    const rawLoad = Math.round((totalVolume / STRENGTH_VOLUME_DIVISOR) * rpeFactor * 100) / 100;
    console.log('TEST LOAD:', { type, rawLoad, duration: session.duration, exercises: session.exercises?.length });
    return { rawLoad, type };
  }

  if (type === 'cardio') {
    const duration = session.duration || 0;
    if (duration <= 0) return { rawLoad: 0, type };
    const rpe = session.rpe ?? 3;
    const effectiveDuration = getEffectiveDuration(duration);
    const sportFactor = getLoadSportFactor(session.activityType);
    const rawLoad = Math.round(effectiveDuration * getLoadRpeFactor(rpe) * 4 * sportFactor * 100) / 100;
    return { rawLoad, type };
  }

  return { rawLoad: 0, type };
}

// ---------- Recovery Detection ----------

const RECOVERY_MAX_RPE = 2;
const RECOVERY_MAX_DURATION = 60; // minutes

function isRecoverySession(session) {
  const rpe = session.rpe ?? 3;
  const duration = session.duration ?? 0;

  if (rpe > RECOVERY_MAX_RPE) return false;
  if (duration <= 0 || duration > RECOVERY_MAX_DURATION) return false;

  return session.type === 'cardio'
      || session.type === 'recovery'
      || session.type === 'strength';
}

/**
 * Computes weekly raw load for a 7-day window ending at referenceDate
 * @param {Date} referenceDate
 * @returns {{ rawLoad: number, strengthLoad: number, cardioLoad: number, sessionCount: number }}
 */
function computeWeeklyRawLoad(referenceDate) {
  const startDate = new Date(referenceDate);
  startDate.setDate(startDate.getDate() - 6);
  startDate.setHours(0, 0, 0, 0);

  const endDate = new Date(referenceDate);
  endDate.setHours(23, 59, 59, 999);

  let strengthLoad = 0;
  let cardioLoad = 0;
  let sessionCount = 0;

  console.log('WeeklyRawLoad sessions:', allSessions.filter(s => s.type === 'strength' || s.type === 'bodyweight' || s.type === 'cardio').length, 'strength+bodyweight+cardio of', allSessions.length, 'total');

  for (const s of allSessions) {
    if (s.type !== 'strength' && s.type !== 'bodyweight' && s.type !== 'cardio') continue;

    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) continue;
    if (sessionDate < startDate || sessionDate > endDate) continue;

    const result = calculateSessionLoadValue(s);
    if (result.type === 'strength' || result.type === 'bodyweight') {
      strengthLoad += result.rawLoad;
    } else if (result.type === 'cardio') {
      cardioLoad += result.rawLoad;
    }
    sessionCount++;
  }

  return { rawLoad: strengthLoad + cardioLoad, strengthLoad, cardioLoad, sessionCount };
}

/**
 * Computes weekly score (0-100) for a given reference date
 * @param {Date} referenceDate
 * @returns {{ weeklyScore: number, rawLoad: number, strengthLoad: number, cardioLoad: number, baseline: number, sessionCount: number }}
 */
function computeWeeklyScore(referenceDate) {
  const currentWeek = computeWeeklyRawLoad(referenceDate);

  // Previous 6 weeks for baseline
  const previousWeeks = [];
  for (let i = 1; i <= 6; i++) {
    const refDate = new Date(referenceDate);
    refDate.setDate(refDate.getDate() - i * 7);
    previousWeeks.push(computeWeeklyRawLoad(refDate));
  }

  const weeksWithData = previousWeeks.filter(w => w.rawLoad > 0);
  let baseline;

  if (weeksWithData.length < 2) {
    baseline = currentWeek.rawLoad;
  } else {
    const totalLoad = weeksWithData.reduce((sum, w) => sum + w.rawLoad, 0);
    baseline = totalLoad / weeksWithData.length;
  }

  const weeklyScore = baseline === 0
    ? 0
    : Math.min(100, Math.max(0, Math.round((currentWeek.rawLoad / baseline) * 70)));

  return {
    weeklyScore,
    rawLoad: currentWeek.rawLoad,
    strengthLoad: currentWeek.strengthLoad,
    cardioLoad: currentWeek.cardioLoad,
    baseline,
    sessionCount: currentWeek.sessionCount,
  };
}

/**
 * Maps ACWR ratio to a training-phase score (0–100) via continuous piecewise
 * linear interpolation. The curve peaks at ACWR ≈ 1.0 (optimal load balance)
 * and drops symmetrically for under- and over-training.
 */
function mapReadiness(acwr) {
  // Steeper curve with more differentiation in the normal 0.8-1.2 range.
  // Peak is narrower (only ACWR ≈ 0.95-1.05 scores above 85).
  const curve = [
    [0.0,  10],  // deep under-training
    [0.3,  22],
    [0.5,  38],
    [0.65, 50],
    [0.75, 60],
    [0.85, 72],
    [0.95, 85],
    [1.0,  90],  // optimal balance — narrow peak
    [1.05, 85],
    [1.15, 72],
    [1.25, 60],
    [1.35, 50],
    [1.5,  38],
    [1.7,  25],
    [2.0,  14],
    [2.5,  6],   // deep over-training
  ];

  const clamped = Math.max(0, Math.min(acwr, 2.5));

  // Below first point
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

/**
 * Maps score + ACWR direction to a training zone.
 * Uses ACWR to distinguish under-training (form_loss) from over-training (overreaching).
 */
function mapZone(score, acwr) {
  if (acwr !== undefined && acwr < 0.8 && score <= 55) return 'form_loss';
  if (score <= 30) return 'overreaching';
  if (score <= 50) return 'fatigued';
  if (score <= 68) return 'maintaining';
  if (score <= 82) return 'building';
  return 'peak';
}

/**
 * Computes Acute:Chronic Workload Ratio (ports getACWR.ts)
 * @param {Array} sessions
 * @param {Date} referenceDate
 * @param {{ applyFatigue?: boolean }} [options]
 * @returns {{ acuteLoad: number, chronicLoad: number, acwr: number|null, readinessScore: number|null, zone: string|null, daysSinceLastSession: number|null, todayLoad: number, fatiguePenalty: number }}
 */
function getACWR(sessions, referenceDate, options) {
  const applyFatigue = options?.applyFatigue ?? false;
  if (!sessions || !sessions.length) {
    return { acuteLoad: 0, chronicLoad: 0, acwr: null, readinessScore: null, zone: null, daysSinceLastSession: null, todayLoad: 0, fatiguePenalty: 0 };
  }

  const ACUTE_ALPHA = 0.22;   // ~5-day effective window (was 0.35 ~3d, too reactive)
  const CHRONIC_ALPHA = 0.07;  // ~14-day effective window (was 0.10 ~10d)
  const RECOVERY_BOOST_FACTOR = 0.05;

  // Use local date keys (YYYY-MM-DD) to avoid UTC/local timezone mismatch
  function toLocalDateKey(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${dd}`;
  }

  const end = new Date(referenceDate);
  end.setHours(23, 59, 59, 999);

  // Build daily load map (aggregate same-day sessions, skip recovery)
  const dailyLoads = new Map();
  const recoveryDays = new Set();

  for (const s of sessions) {
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) continue;
    if (sessionDate > end) continue;

    if (isRecoverySession(s)) {
      recoveryDays.add(toLocalDateKey(sessionDate));
    }

    if (s.type !== 'strength' && s.type !== 'bodyweight' && s.type !== 'cardio') continue;

    const { rawLoad } = calculateSessionLoadValue(s);
    if (rawLoad <= 0) continue;
    const key = toLocalDateKey(sessionDate);
    dailyLoads.set(key, (dailyLoads.get(key) ?? 0) + rawLoad);
  }

  if (dailyLoads.size === 0) {
    return { acuteLoad: 0, chronicLoad: 0, acwr: null, readinessScore: null, zone: null, daysSinceLastSession: null, todayLoad: 0, fatiguePenalty: 0 };
  }

  // Sort keys to find earliest session and compute day span
  const sortedKeys = [...dailyLoads.keys()].sort();
  const refDay = new Date(referenceDate);
  refDay.setHours(0, 0, 0, 0);
  const earliestDate = new Date(sortedKeys[0] + 'T00:00:00');
  const daySpan = Math.floor((refDay.getTime() - earliestDate.getTime()) / (1000 * 60 * 60 * 24));

  // Debug: log today's sessions
  const todayDbgKey = toLocalDateKey(refDay);
  const todayDbgLoad = dailyLoads.get(todayDbgKey);
  if (todayDbgLoad) {
    console.log('[READINESS DEBUG] today total load:', { todayKey: todayDbgKey, todayLoad: Math.round(todayDbgLoad * 100) / 100, totalDays: dailyLoads.size });
  }

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

    // Recovery Boost: aktive Erholung beschleunigt Acute-Abbau
    if (recoveryDays.has(dateKey)) {
      acuteEMA *= (1 - RECOVERY_BOOST_FACTOR);
    }

    cursor.setDate(cursor.getDate() + 1);
  }

  // When chronic load is negligible, there's no meaningful baseline for a ratio
  if (chronicEMA < 0.01) {
    return { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr: null, readinessScore: null, zone: null, daysSinceLastSession, todayLoad: 0, fatiguePenalty: 0 };
  }

  const acwr = Math.round((acuteEMA / chronicEMA) * 100) / 100;

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
    console.log('[READINESS DEBUG] fatigue calc:', {
      todayLoad: Math.round(todayLoad * 100) / 100,
      chronicEMA: Math.round(chronicEMA * 100) / 100,
      loadRatio: Math.round(loadRatio * 100) / 100,
      sqrtLoadRatio: Math.round(Math.sqrt(loadRatio) * 100) / 100,
      rawPenalty: Math.round(10 * Math.sqrt(loadRatio)),
      fatiguePenalty,
    });
  }

  const readinessScore = Math.max(5, rawReadinessScore - fatiguePenalty);
  const zone = mapZone(readinessScore, acwr);

  console.log('[READINESS DEBUG] final:', {
    acuteEMA: Math.round(acuteEMA * 100) / 100,
    chronicEMA: Math.round(chronicEMA * 100) / 100,
    acwr,
    rawReadinessScore,
    fatiguePenalty,
    readinessScore,
    zone,
    todayLoad: Math.round(todayLoad * 100) / 100,
    todayKey,
    applyFatigue,
  });

  return { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr, readinessScore, zone, daysSinceLastSession, todayLoad, fatiguePenalty };
}

/**
 * Computes a Training Form score based on long-term chronic load (Fitness EMA).
 * Uses a slow EMA (~33 day effective window) to represent accumulated fitness,
 * normalized against a decaying personal peak.
 * @param {Array} sessions
 * @param {Date} referenceDate
 * @returns {{ formScore: number|null, zone: string|null, fitnessLoad: number, peakLoad: number, trend: string, daysSinceLastSession: number|null }}
 */
function computeFormScore(sessions, referenceDate) {
  if (!sessions || !sessions.length) {
    return { formScore: null, zone: null, consistency: 0, loadLevel: 0, recency: 0, trend: 'none', daysSinceLastSession: null };
  }

  function toLocalDateKey(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${dd}`;
  }

  const refDay = new Date(referenceDate);
  refDay.setHours(0, 0, 0, 0);
  const end = new Date(referenceDate);
  end.setHours(23, 59, 59, 999);

  // Build daily load map + collect training day keys
  const dailyLoads = new Map();
  for (const s of sessions) {
    if (s.type !== 'strength' && s.type !== 'bodyweight' && s.type !== 'cardio') continue;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) continue;
    if (sessionDate > end) continue;
    const { rawLoad } = calculateSessionLoadValue(s);
    if (rawLoad <= 0) continue; // Skip zero-load sessions
    const key = toLocalDateKey(sessionDate);
    dailyLoads.set(key, (dailyLoads.get(key) ?? 0) + rawLoad);
  }

  if (dailyLoads.size === 0) {
    return { formScore: null, zone: null, consistency: 0, loadLevel: 0, recency: 0, trend: 'none', daysSinceLastSession: null };
  }

  const sortedKeys = [...dailyLoads.keys()].sort();
  const earliestDate = new Date(sortedKeys[0] + 'T00:00:00');
  const daySpan = Math.floor((refDay.getTime() - earliestDate.getTime()) / (1000 * 60 * 60 * 24));

  // Need at least 14 days of history
  if (daySpan < 14) {
    return { formScore: null, zone: null, consistency: 0, loadLevel: 0, recency: 0, trend: 'none', daysSinceLastSession: null };
  }

  // ── Component 1: Training Consistency (0-35) ──
  // Count training days in last 28 days
  const last28Start = new Date(refDay);
  last28Start.setDate(last28Start.getDate() - 27);
  let trainingDays28 = 0;
  for (const key of dailyLoads.keys()) {
    const d = new Date(key + 'T00:00:00');
    if (d >= last28Start && d <= refDay) trainingDays28++;
  }
  // 16+ days in 28 (≥4x/week) = full 35 points
  const consistency = Math.min(35, Math.round((trainingDays28 / 16) * 35));

  // ── Component 2: Load Progression (0-35) ──
  // Compare recent 14-day load trend against prior 14-day period.
  // This measures whether training load is progressing, stable, or declining.
  const FITNESS_ALPHA = 0.03;
  const loopStart = new Date(Math.max(
    earliestDate.getTime(),
    refDay.getTime() - 120 * 24 * 60 * 60 * 1000
  ));

  let fitnessEMA = 0;
  let fitnessAt14DaysAgo = 0;
  let peakFitness = 0;

  // Collect recent-14d and prior-14d raw loads for direct comparison
  let recent14Load = 0;
  let prior14Load = 0;

  const cursor = new Date(loopStart);
  while (cursor <= refDay) {
    const dateKey = toLocalDateKey(cursor);
    const dailyLoad = dailyLoads.get(dateKey) || 0;
    fitnessEMA = FITNESS_ALPHA * dailyLoad + (1 - FITNESS_ALPHA) * fitnessEMA;
    if (fitnessEMA > peakFitness) peakFitness = fitnessEMA;

    const daysToRef = Math.floor((refDay.getTime() - cursor.getTime()) / (1000 * 60 * 60 * 24));
    if (daysToRef < 14) {
      recent14Load += dailyLoad;
    } else if (daysToRef < 28) {
      prior14Load += dailyLoad;
    }
    if (daysToRef === 14) {
      fitnessAt14DaysAgo = fitnessEMA;
    }

    cursor.setDate(cursor.getDate() + 1);
  }

  // Load progression: compare recent vs prior 14-day window
  // Ratio > 1 = progressing, < 1 = declining, ≈ 1 = maintaining
  // Cap ratio at 2.0 to prevent extreme spikes from low baselines
  let loadLevel = 0;
  if (prior14Load > 0) {
    const progressionRatio = Math.min(recent14Load / prior14Load, 2.0);
    // 0.0 → 0pts, 0.5 → 8pts, 0.8 → 15pts, 1.0 → 20pts, 1.5 → 25pts, 2.0 → 30pts
    if (progressionRatio <= 0.3) {
      loadLevel = 0;
    } else if (progressionRatio <= 1.0) {
      // Linear scale 0.3→5 to 1.0→20
      loadLevel = Math.round(5 + (progressionRatio - 0.3) / 0.7 * 15);
    } else {
      // Above baseline: 1.0→20 to 2.0→30 (gentler curve, capped at 30)
      loadLevel = Math.round(20 + Math.min(progressionRatio - 1.0, 1.0) * 10);
    }
  } else if (recent14Load > 0) {
    loadLevel = 12; // bootstrapping: training started recently
  }

  // ── Component 3: Training Recency (0-15) ──
  const lastSessionKey = sortedKeys[sortedKeys.length - 1];
  const lastSessionDate = new Date(lastSessionKey + 'T00:00:00');
  const daysSinceLastSession = Math.floor((refDay.getTime() - lastSessionDate.getTime()) / (1000 * 60 * 60 * 24));

  let recency = 0;
  if (daysSinceLastSession <= 1) recency = 15;
  else if (daysSinceLastSession <= 2) recency = 12;
  else if (daysSinceLastSession <= 3) recency = 8;
  else if (daysSinceLastSession <= 5) recency = 4;
  else if (daysSinceLastSession <= 7) recency = 1;

  // ── Component 4: Fitness vs Peak (0-15) ──
  // How close is current fitness EMA to all-time peak within the window?
  // This rewards sustained high load over time, not just showing up.
  let fitnessVsPeak = 0;
  if (peakFitness > 0) {
    const peakRatio = fitnessEMA / peakFitness;
    fitnessVsPeak = Math.round(Math.min(15, peakRatio * 15));
  }

  // ── Component 5: Session Impact Bonus (0-8) ──
  // Immediate boost when training was logged today. Uses sqrt curve so
  // multiple sessions or longer workouts keep increasing the bonus:
  //   1 moderate session (~1x avg) → ~4pt bonus
  //   1 hard session   (~2x avg)  → ~6pt bonus
  //   2 sessions       (~3x avg)  → ~7pt bonus
  //   extreme day      (~5x avg)  → ~8pt bonus (cap)
  const todayKey = toLocalDateKey(refDay);
  const todayLoad = dailyLoads.get(todayKey) || 0;
  let sessionBonus = 0;
  if (todayLoad > 0 && recent14Load > 0) {
    const avgDailyLoad = recent14Load / 14;
    sessionBonus = avgDailyLoad > 0
      ? Math.min(8, Math.round(4 * Math.sqrt(todayLoad / avgDailyLoad)))
      : 3;
  }

  // ── Combined Form Score (0-100) ──
  let formScore = Math.max(0, Math.min(100, consistency + loadLevel + recency + fitnessVsPeak + sessionBonus));

  console.log('[FORM DEBUG]', {
    consistency, loadLevel, recency, fitnessVsPeak, sessionBonus,
    formScore,
    todayLoad: Math.round(todayLoad * 100) / 100,
    avgDailyLoad: recent14Load > 0 ? Math.round((recent14Load / 14) * 100) / 100 : 0,
    loadRatio: recent14Load > 0 && (recent14Load / 14) > 0 ? Math.round((todayLoad / (recent14Load / 14)) * 100) / 100 : 'N/A',
    recent14Load: Math.round(recent14Load * 100) / 100,
    prior14Load: Math.round(prior14Load * 100) / 100,
    progressionRatio: prior14Load > 0 ? Math.round((recent14Load / prior14Load) * 100) / 100 : 'N/A',
    trainingDays28,
    daysSinceLastSession,
    fitnessEMA: Math.round(fitnessEMA * 100) / 100,
    peakFitness: Math.round(peakFitness * 100) / 100,
  });

  // ── Inactivity Decay (starts slow, accelerates) ──
  // After 3 days without training, form score decays progressively.
  // This ensures the phase drops when not training:
  //   4d off → -1, 7d → -8, 10d → -18, 14d → -35, 21d → -68
  if (daysSinceLastSession > 3) {
    const restDays = daysSinceLastSession - 3;
    const inactivityPenalty = Math.min(70, Math.round(1.2 * Math.pow(restDays, 1.4)));
    formScore = Math.max(0, formScore - inactivityPenalty);
  }

  // ── Trend ──
  let trend = 'stable';
  if (fitnessAt14DaysAgo > 0) {
    const trendRatio = fitnessEMA / fitnessAt14DaysAgo;
    if (trendRatio > 1.05) trend = 'rising';
    else if (trendRatio < 0.95) trend = 'falling';
  } else if (fitnessEMA > 0) {
    trend = 'rising';
  }

  const zone = mapFormZone(formScore);

  return { formScore, zone, consistency, loadLevel, recency, trend, daysSinceLastSession };
}

/**
 * Maps form score to a training form zone.
 */
function mapFormZone(score) {
  if (score <= 20) return 'detrained';
  if (score <= 38) return 'base';
  if (score <= 55) return 'developing';
  if (score <= 75) return 'trained';
  if (score <= 90) return 'peak_form';
  return 'overload';
}

/**
 * Combines training form zone (long-term) and readiness zone (short-term)
 * into a concrete training recommendation.
 * Readiness (acute) takes priority; form phase steers the direction.
 *
 * @param {string} formZone   – one of: detrained, base, developing, trained, peak_form, overload
 * @param {string} readinessZone – one of: overreaching, fatigued, maintaining, building, peak, form_loss
 * @returns {{ key: string, intensity: string }}
 */
function getTrainingRecommendation(formZone, readinessZone) {
  // --- Overreaching: always rest, regardless of phase ---
  if (readinessZone === 'overreaching') {
    return { key: 'overreaching', intensity: 'rest' };
  }

  // --- Form loss (long inactivity): special case ---
  if (readinessZone === 'form_loss') {
    if (formZone === 'detrained' || formZone === 'base') {
      return { key: 'formLossDetrained', intensity: 'low' };
    }
    return { key: 'formLoss', intensity: 'moderate' };
  }

  // --- Fatigued: low intensity, phase adjusts nuance ---
  if (readinessZone === 'fatigued') {
    if (formZone === 'overload') return { key: 'fatiguedOverload', intensity: 'low' };
    if (formZone === 'peak_form' || formZone === 'trained') return { key: 'fatiguedGoodForm', intensity: 'low' };
    return { key: 'fatiguedDefault', intensity: 'low' };
  }

  // --- Maintaining: moderate, phase adjusts ---
  if (readinessZone === 'maintaining') {
    if (formZone === 'overload') return { key: 'maintainingOverload', intensity: 'low' };
    if (formZone === 'peak_form') return { key: 'maintainingPeak', intensity: 'moderate' };
    return { key: 'maintainingDefault', intensity: 'moderate' };
  }

  // --- Building: ready for normal to high training ---
  if (readinessZone === 'building') {
    if (formZone === 'overload') return { key: 'buildingOverload', intensity: 'moderate' };
    if (formZone === 'peak_form' || formZone === 'trained') return { key: 'buildingGoodForm', intensity: 'high' };
    return { key: 'buildingDefault', intensity: 'moderate' };
  }

  // --- Peak: fully recovered, can push ---
  if (readinessZone === 'peak') {
    if (formZone === 'overload') return { key: 'peakOverload', intensity: 'moderate' };
    if (formZone === 'peak_form' || formZone === 'trained') return { key: 'peakGoodForm', intensity: 'high' };
    if (formZone === 'detrained') return { key: 'peakDetrained', intensity: 'moderate' };
    return { key: 'peakDefault', intensity: 'high' };
  }

  // Fallback
  return { key: 'maintainingDefault', intensity: 'moderate' };
}

/**
 * Compares today's ACWR with yesterday's to explain why the readiness score changed.
 * @param {Array} sessions
 * @param {Date} referenceDate
 * @returns {{ scoreDelta: number, acuteDelta: number, chronicDelta: number, daysSinceLastSession: number|null, driver: string|null, todayLoad: number, biggestSession: object|null, previous: object|null, current: object|null }}
 */
function getScoreChange(sessions, referenceDate) {
  const nullResult = { scoreDelta: 0, acuteDelta: 0, chronicDelta: 0, daysSinceLastSession: null, driver: null, todayLoad: 0, biggestSession: null, previous: null, current: null };

  const current = getACWR(sessions, referenceDate);
  if (current.readinessScore === null) return nullResult;

  const yesterday = new Date(referenceDate);
  yesterday.setDate(yesterday.getDate() - 1);
  const previous = getACWR(sessions, yesterday);
  if (previous.readinessScore === null) return nullResult;

  const scoreDelta = current.readinessScore - previous.readinessScore;
  const acuteDelta = current.acuteLoad - previous.acuteLoad;
  const chronicDelta = current.chronicLoad - previous.chronicLoad;
  const daysSinceLastSession = current.daysSinceLastSession;

  // Determine primary driver
  let driver = 'none';
  if (scoreDelta !== 0) {
    if (acuteDelta > 0.5) {
      driver = 'training';
    } else if (acuteDelta <= 0 && daysSinceLastSession >= 1) {
      driver = 'recovery';
    } else if (Math.abs(chronicDelta) > 1) {
      driver = 'baseline_shift';
    }
  }

  // Find sessions from last 24h for load context
  const refEnd = new Date(referenceDate);
  refEnd.setHours(23, 59, 59, 999);
  const refStart = new Date(referenceDate);
  refStart.setHours(0, 0, 0, 0);

  let todayLoad = 0;
  let biggestSession = null;
  let biggestLoad = 0;

  for (const s of (sessions || [])) {
    if (s.type !== 'strength' && s.type !== 'bodyweight' && s.type !== 'cardio') continue;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) continue;
    if (sessionDate < refStart || sessionDate > refEnd) continue;

    const { rawLoad } = calculateSessionLoadValue(s);
    todayLoad += rawLoad;

    if (rawLoad > biggestLoad) {
      biggestLoad = rawLoad;
      biggestSession = {
        name: s.planName || s.activityType || s.type,
        duration: s.duration || 0,
        load: rawLoad
      };
    }
  }

  return {
    scoreDelta,
    acuteDelta,
    chronicDelta,
    daysSinceLastSession,
    driver,
    todayLoad: Math.round(todayLoad),
    biggestSession,
    previous: { readinessScore: previous.readinessScore, acuteLoad: previous.acuteLoad, chronicLoad: previous.chronicLoad },
    current: { readinessScore: current.readinessScore, acuteLoad: current.acuteLoad, chronicLoad: current.chronicLoad }
  };
}

/**
 * Aggregates weekly scores by period for chart data
 * @param {string} periodKey - '7D', '30D', '6M', '1Y'
 * @returns {Array<{ label: string, date: Date, weeklyScore: number, baseline: number, strengthLoad: number, cardioLoad: number, sessionCount: number }>}
 */
function aggregateWeeklyScoresByPeriod(periodKey) {
  const WEEKS_FOR_PERIOD = { '7D': 4, '30D': 4, '6M': 26, '1Y': 52 };
  const numWeeks = WEEKS_FOR_PERIOD[periodKey] || 4;

  const result = [];
  const now = new Date();
  const currentWeekEnd = new Date(now);
  currentWeekEnd.setHours(23, 59, 59, 999);

  for (let i = numWeeks - 1; i >= 0; i--) {
    const weekEnd = new Date(currentWeekEnd);
    weekEnd.setDate(weekEnd.getDate() - i * 7);

    const weekStart = new Date(weekEnd);
    weekStart.setDate(weekStart.getDate() - 6);

    const score = computeWeeklyScore(weekEnd);

    result.push({
      label: formatWeekLabel(weekStart),
      date: weekStart,
      weeklyScore: score.weeklyScore,
      baseline: score.baseline,
      strengthLoad: score.strengthLoad,
      cardioLoad: score.cardioLoad,
      sessionCount: score.sessionCount,
    });
  }

  return result;
}

/**
 * Returns training status based on weekly score
 * @param {number} weeklyScore - Score 0-100
 * @returns {{ label: string, color: string, description: string }}
 */
function getTrainingStatus(weeklyScore) {
  const tr = typeof t === 'function' ? t : (key) => key;

  if (weeklyScore < 50) {
    return {
      label: tr('progress.readiness.lowLoad'),
      color: 'var(--color-category-strength)',
      description: tr('progress.readiness.descLow'),
    };
  } else if (weeklyScore <= 85) {
    return {
      label: tr('progress.readiness.balanced'),
      color: 'var(--color-category-recovery)',
      description: tr('progress.readiness.descBalanced'),
    };
  } else {
    return {
      label: tr('progress.readiness.highLoad'),
      color: 'var(--color-primary)',
      description: tr('progress.readiness.descHigh'),
    };
  }
}

// Expose functions
window.openAddCardioModal = openAddCardioModal;
window.closeAddCardioModal = closeAddCardioModal;
window.updateCardioLivePace = updateCardioLivePace;
window.saveCardioSession = saveCardioSession;
window.handleModalBackdropClick = handleModalBackdropClick;
window.triggerSuccessGlow = triggerSuccessGlow;
window.showErrorMessage = showErrorMessage;
window.openAddRecoveryModal = openAddRecoveryModal;
window.closeAddRecoveryModal = closeAddRecoveryModal;
window.saveRecoverySession = saveRecoverySession;
window.openAddStrengthModal = openAddStrengthModal;
window.closeAddStrengthModal = closeAddStrengthModal;
window.saveStrengthSession = saveStrengthSession;
window.setStrengthType = setStrengthType;
window.setStrengthDifficulty = setStrengthDifficulty;
window.openExercisePickerForLogging = openExercisePickerForLogging;
window.addExerciseToStrengthLogging = addExerciseToStrengthLogging;
window.removeExerciseFromLogging = removeExerciseFromLogging;
window.editExerciseSets = editExerciseSets;
window.saveExerciseSets = saveExerciseSets;
window.renderStrengthExercisesList = renderStrengthExercisesList;
window.calculateSessionStrengthVolume = calculateSessionStrengthVolume;
window.aggregateWeeklyStrengthVolume = aggregateWeeklyStrengthVolume;
window.aggregateWeeklyCardio = aggregateWeeklyCardio;
window.getSessionsByDate = getSessionsByDate;
window.getSessionsForDate = getSessionsForDate;
window.formatDateToYYYYMMDD = formatDateToYYYYMMDD;

// New period-based aggregation functions
window.PERIOD_CONFIG = PERIOD_CONFIG;
window.ACTIVITY_TYPES = ACTIVITY_TYPES;
window.RECOVERY_TYPES = RECOVERY_TYPES;
window.aggregateCardioByPeriod = aggregateCardioByPeriod;
window.getAvailableEnduranceSports = getAvailableEnduranceSports;
window.aggregateStrengthByPeriod = aggregateStrengthByPeriod;
window.calculateCardioStats = calculateCardioStats;
window.calculateStrengthStats = calculateStrengthStats;
window.formatPaceShort = formatPaceShort;

// Dual volume (weighted + bodyweight) functions
window.EXERCISE_LOAD_FACTORS = EXERCISE_LOAD_FACTORS;
window.getExerciseLoadFactor = getExerciseLoadFactor;
window.calculateWeightedVolume = calculateWeightedVolume;
window.calculateBodyweightVolume = calculateBodyweightVolume;
window.calculateDualVolume = calculateDualVolume;
window.aggregateDualStrengthByPeriod = aggregateDualStrengthByPeriod;
window.calculateDualStrengthStats = calculateDualStrengthStats;

// Training Character Progress functions
window.INTENSITY_THRESHOLDS = INTENSITY_THRESHOLDS;
window.calculateConsistencyStats = calculateConsistencyStats;
window.generateCalmInsight = generateCalmInsight;
window.calculateWeightedLoadIndex = calculateWeightedLoadIndex;
window.aggregateWeightedLoadByPeriod = aggregateWeightedLoadByPeriod;
window.calculateWeightedLoadStats = calculateWeightedLoadStats;
window.calculateTrainingVariance = calculateTrainingVariance;
window.classifyBodyweightIntensity = classifyBodyweightIntensity;
window.aggregateBodyweightByPeriod = aggregateBodyweightByPeriod;
window.calculateBodyweightStats = calculateBodyweightStats;
window.computeHybridBalance = computeHybridBalance;

// Weekly score functions
window.calculateSessionLoadValue = calculateSessionLoadValue;
window.computeWeeklyRawLoad = computeWeeklyRawLoad;
window.computeWeeklyScore = computeWeeklyScore;
window.aggregateWeeklyScoresByPeriod = aggregateWeeklyScoresByPeriod;
window.getTrainingStatus = getTrainingStatus;

// ACWR
window.getACWR = getACWR;
window.getScoreChange = getScoreChange;

// Training Form
window.computeFormScore = computeFormScore;
window.mapFormZone = mapFormZone;

// Run analytics
window.aggregateRunByPeriod = aggregateRunByPeriod;

// ==================== PROGRESS DATA QUERIES ====================

/**
 * Letzte N Sessions eines Plans, sortiert newest-first.
 */
function getSessionsForPlan(planId, limit = 5, excludeId = null) {
  if (!planId) return [];
  const sessions = typeof allSessions !== 'undefined' ? allSessions : [];
  const relevant = sessions.filter(s =>
    s.planId === planId && s.id !== excludeId
  );
  relevant.sort((a, b) => {
    const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return db - da;
  });
  return relevant.slice(0, limit);
}

/**
 * Gewichtetes Volumen einer einzelnen Exercise (reps*weight oder nur reps).
 */
function calculateExerciseWeightedVolume(exerciseEntry) {
  if (!exerciseEntry?.sets || !Array.isArray(exerciseEntry.sets)) return 0;
  return exerciseEntry.sets.reduce((sum, set) => {
    const reps = set.reps || 0;
    const weight = set.weight || 0;
    return sum + (weight > 0 ? reps * weight : reps);
  }, 0);
}

/**
 * Sparkline-Daten für eine Exercise aus gegebenen Sessions.
 * Return: Array oldest-first [12, 15, 14, 16, 18]
 */
function getExerciseSparklineData(sessions, exerciseId) {
  const values = [];
  sessions.forEach(s => {
    const ex = (s.exercises || []).find(e => e.exerciseId === exerciseId);
    if (ex) values.push(calculateExerciseWeightedVolume(ex));
  });
  return values.reverse(); // sessions are newest-first, sparkline needs oldest-first
}

/**
 * Sparkline-Daten für eine Exercise über alle Sessions (nicht plan-spezifisch).
 */
function getExerciseGlobalSparkline(exerciseId, limit = 8) {
  const sessions = (typeof allSessions !== 'undefined' ? allSessions : [])
    .filter(s => s.exercises?.some(e => e.exerciseId === exerciseId))
    .sort((a, b) => {
      const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
      const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
      return db - da;
    })
    .slice(0, limit);
  return getExerciseSparklineData(sessions, exerciseId);
}

window.getSessionsForPlan = getSessionsForPlan;
window.calculateExerciseWeightedVolume = calculateExerciseWeightedVolume;
window.getExerciseSparklineData = getExerciseSparklineData;
window.getExerciseGlobalSparkline = getExerciseGlobalSparkline;

console.log('📊 Sessions module loaded');
