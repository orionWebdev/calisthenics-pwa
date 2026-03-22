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
  row: { name: 'Rudern', icon: 'rowing', color: '#8b5cf6' },
  other: { name: 'Sonstiges', icon: 'fitness_center', color: '#f59e0b' }
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
    if (activityFilter && s.activityType !== activityFilter) return false;
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
  const durationInput = document.getElementById('cardio-duration');
  const distanceInput = document.getElementById('cardio-distance');
  const paceDisplay = document.getElementById('cardio-computed-pace');
  const notesInput = document.getElementById('cardio-notes');

  if (dateInput) dateInput.value = today;
  if (activityInput) activityInput.value = 'run';
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
    const durationInput = document.getElementById('cardio-duration');
    const distanceInput = document.getElementById('cardio-distance');
    const paceDisplay = document.getElementById('cardio-computed-pace');
    const notesInput = document.getElementById('cardio-notes');

    if (dateInput) dateInput.value = '';
    if (activityInput) activityInput.value = 'run';
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
      duration,
      distanceKm: distance || null,
      pace: pace,
      notes: notes || null,
      createdAt: firebase.firestore.Timestamp.now()
    };

    const savedDoc = await addDoc(sessionsCollection, cardioSession);

    console.log('✅ Cardio session saved');

    // Mark pending scheduled entry as completed (Quick Entry support)
    await markPendingScheduledEntryCompleted(savedDoc.id);

    // Close modal FIRST (before feedback/reload)
    closeAddCardioModal();

    // Show RPE feedback modal and patch session if provided
    if (typeof showRpeFeedbackModal === 'function') {
      const feedbackData = await showRpeFeedbackModal();
      if (feedbackData) {
        await updateDoc(sessionsCollection, savedDoc.id, feedbackData);
      }
    }

    // Then reload sessions and refresh view
    await loadSessions();
    if (typeof renderCurrentProgressTab === 'function') {
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
      createdAt: firebase.firestore.Timestamp.now()
    };

    // Add exercises if any were logged
    if (strengthLoggingExercises.length > 0) {
      strengthSession.exercises = strengthLoggingExercises.map(ex => ({
        exerciseId: ex.exerciseId,
        sets: ex.sets
      }));
    }

    const savedDoc = await addDoc(sessionsCollection, strengthSession);

    // Mark pending scheduled entry as completed (Quick Entry support)
    await markPendingScheduledEntryCompleted(savedDoc.id);

    closeAddStrengthModal();

    // Show RPE feedback modal and patch session if provided
    if (typeof showRpeFeedbackModal === 'function') {
      const feedbackData = await showRpeFeedbackModal();
      if (feedbackData) {
        await updateDoc(sessionsCollection, savedDoc.id, feedbackData);
      }
    }
    await loadSessions();
    if (typeof renderCurrentProgressTab === 'function') {
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
  const durationInput = document.getElementById('recovery-duration');
  const notesInput = document.getElementById('recovery-notes');

  if (dateInput) {
    dateInput.value = dateStr || today;
  }
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
    const durationInput = document.getElementById('recovery-duration');
    const notesInput = document.getElementById('recovery-notes');

    if (dateInput) dateInput.value = '';
    if (durationInput) durationInput.value = '';
    if (notesInput) notesInput.value = '';
  }, 300);
}

async function saveRecoverySession() {
  const dateInput = document.getElementById('recovery-date').value;
  const validDate = getValidDateStringForCardio(dateInput);
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
      duration,
      notes: notes || null,
      createdAt: firebase.firestore.Timestamp.now()
    };

    const savedDoc = await addDoc(sessionsCollection, recoverySession);

    console.log('✅ Recovery session saved');

    // Mark pending scheduled entry as completed (Quick Entry support)
    await markPendingScheduledEntryCompleted(savedDoc.id);

    closeAddRecoveryModal();

    // Show RPE feedback modal and patch session if provided
    if (typeof showRpeFeedbackModal === 'function') {
      const feedbackData = await showRpeFeedbackModal();
      if (feedbackData) {
        await updateDoc(sessionsCollection, savedDoc.id, feedbackData);
      }
    }

    await loadSessions();
    if (typeof renderCurrentProgressTab === 'function') {
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

/**
 * Calculates raw load for a session (ports calculateSessionLoad.ts)
 * @param {Object} session
 * @returns {{ rawLoad: number, type: string }}
 */
function calculateSessionLoadValue(session) {
  const type = session?.type;
  if (!type || type === 'recovery') return { rawLoad: 0, type: type || 'recovery' };

  if (type === 'strength') {
    let totalVolume = 0;
    const bodyWeight = (typeof userProfile !== 'undefined' && userProfile?.bodyWeight) || 0;

    if (session.exercises && Array.isArray(session.exercises)) {
      for (const exercise of session.exercises) {
        if (!exercise.sets || !Array.isArray(exercise.sets)) continue;
        for (const set of exercise.sets) {
          const reps = set.reps || 0;
          if (reps <= 0) continue;
          const effectiveLoad = exercise.usesBodyweight
            ? bodyWeight + (set.weight || 0)
            : (set.weight || 0);
          totalVolume += effectiveLoad * reps;
        }
      }
    }
    return { rawLoad: totalVolume * getLoadRpeFactor(session.rpe), type };
  }

  if (type === 'cardio') {
    const duration = session.duration || 0;
    if (duration <= 0) return { rawLoad: 0, type };
    return { rawLoad: duration * getLoadRpeFactor(session.rpe) * 10, type };
  }

  return { rawLoad: 0, type };
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

  for (const s of allSessions) {
    if (s.type !== 'strength' && s.type !== 'cardio') continue;

    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) continue;
    if (sessionDate < startDate || sessionDate > endDate) continue;

    const result = calculateSessionLoadValue(s);
    if (result.type === 'strength') {
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
window.aggregateCardioByPeriod = aggregateCardioByPeriod;
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
