// ==================== DATA LOADING ====================

/**
 * Lädt alle Sessions
 */
async function loadSessions() {
  try {
    sessionsLoaded = false;
    allSessions = await getAllDocsForUser(sessionsCollection);
    sessionsLoaded = true;
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
  const month = (typeof monthShortLabel === 'function') ? monthShortLabel(weekStart.getMonth()) : ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'][weekStart.getMonth()];
  return `${weekStart.getDate()}. ${month}`;
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
