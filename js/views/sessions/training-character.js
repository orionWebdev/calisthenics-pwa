
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

