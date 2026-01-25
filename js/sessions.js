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
  if (saved && ['overview', 'strength', 'cardio'].includes(saved)) {
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
 * Berechnet TOTAL Volumen fuer eine komplette Strength-Session
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

/**
 * Gibt den Montag der Woche zurueck (fuer wochenbasierte Aggregation)
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
    totalDuration += s.duration || 0;
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
 * Gruppiert Sessions nach YYYY-MM-DD fuer Activity Calendar
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
 * Holt Sessions fuer ein spezifisches Datum
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
      value = session.duration || 0;
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
    if (s.duration) {
      totalTime += s.duration;
    }
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

    await addDoc(sessionsCollection, cardioSession);

    console.log('✅ Cardio session saved');

    // Close modal FIRST (before reload)
    closeAddCardioModal();

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
    if (modalId === 'add-recovery-modal') {
      closeAddRecoveryModal();
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

    await addDoc(sessionsCollection, recoverySession);

    console.log('✅ Recovery session saved');

    closeAddRecoveryModal();

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

console.log('📊 Sessions module loaded');
