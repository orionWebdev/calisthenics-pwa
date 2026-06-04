
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
