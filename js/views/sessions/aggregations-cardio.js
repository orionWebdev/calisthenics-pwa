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
