// ========================================
// DASHBOARD - SESSIONS ONLY
// ========================================

const DASHBOARD_RECENT_LIMIT = 3;
// Dashboard Hybrid Balance fixed to 7 days - no toggle
const DASHBOARD_BALANCE_DAYS = 7;
let dashboardIsLoading = false;
// Dashboard Activity Calendar state
// Plan calendar is now the only calendar on dashboard (activity calendar moved to Progress).
// The activity-calendar helpers below (aggregateDayByType, renderNestedDots, getDashboardSessionsByDate)
// remain exported so progressv3.js can reuse them.

const tr = (key, params) => (typeof t === 'function' ? t(key, params) : key);

function getSessionDate(session) {
  if (session?.date?.toDate) {
    return session.date.toDate();
  }
  const parsed = new Date(session?.date);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed;
}

function getSessionDateTime(session) {
  const sessionDate = getSessionDate(session);

  // Resolve createdAt (contains the actual time)
  let createdAt = null;
  if (session?.createdAt?.toDate) {
    createdAt = session.createdAt.toDate();
  } else if (session?.createdAt) {
    const parsed = new Date(session.createdAt);
    if (!Number.isNaN(parsed.getTime())) createdAt = parsed;
  }

  // Combine: date from session.date, time from createdAt
  if (sessionDate && createdAt) {
    const combined = new Date(sessionDate);
    combined.setHours(createdAt.getHours(), createdAt.getMinutes(), createdAt.getSeconds());
    return combined;
  }

  return createdAt || sessionDate || null;
}

function getSessionDurationSeconds(session) {
  if (!session) return 0;
  const sec = Number(session.durationSec || session.durationSeconds || 0);
  if (Number.isFinite(sec) && sec > 0) return Math.round(sec);
  const minutes = Number(session.duration || 0);
  if (Number.isFinite(minutes) && minutes > 0) return Math.round(minutes * 60);
  return 0;
}

function getBerlinDateKey(date) {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Berlin',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  });
  return formatter.format(date);
}

// ========================================
// QUICK STATS HELPERS
// ========================================

/**
 * ISO week number for a date in Europe/Berlin timezone
 * @returns {{year: number, week: number}}
 */
function getISOWeekBerlin(date) {
  const berlinDate = new Date(date.toLocaleString('en-US', { timeZone: 'Europe/Berlin' }));
  berlinDate.setHours(0, 0, 0, 0);

  // ISO week: Monday-based, week 1 is the one containing 4 January
  const thursday = new Date(berlinDate);
  thursday.setDate(berlinDate.getDate() - ((berlinDate.getDay() + 6) % 7) + 3);

  const firstThursday = new Date(thursday.getFullYear(), 0, 4);
  firstThursday.setDate(firstThursday.getDate() - ((firstThursday.getDay() + 6) % 7) + 3);

  const weekNumber = Math.round((thursday - firstThursday) / (7 * 24 * 60 * 60 * 1000)) + 1;
  return { year: thursday.getFullYear(), week: weekNumber };
}

function getSessionsThisWeekCount(sessions) {
  if (!Array.isArray(sessions) || sessions.length === 0) return 0;
  const currentWeek = getISOWeekBerlin(new Date());
  return sessions.filter(session => {
    const date = getSessionDate(session);
    if (!date) return false;
    const sessionWeek = getISOWeekBerlin(date);
    return sessionWeek.year === currentWeek.year && sessionWeek.week === currentWeek.week;
  }).length;
}

function getMovementMinutesThisWeek(sessions) {
  if (!Array.isArray(sessions) || sessions.length === 0) return 0;
  const currentWeek = getISOWeekBerlin(new Date());
  const totalSeconds = sessions.reduce((sum, session) => {
    const date = getSessionDate(session);
    if (!date) return sum;
    const sessionWeek = getISOWeekBerlin(date);
    if (sessionWeek.year !== currentWeek.year || sessionWeek.week !== currentWeek.week) return sum;
    return sum + getSessionDurationSeconds(session);
  }, 0);
  return Math.round(totalSeconds / 60);
}


function getBalanceContextLabelKey(strengthSec, cardioSec) {
  const totalSec = strengthSec + cardioSec;
  if (totalSec < 3600) {
    return 'balance.context.lowData';
  }
  const strengthPct = totalSec ? (strengthSec / totalSec) * 100 : 0;
  if (strengthPct >= 55) return 'balance.context.strength';
  if (strengthPct >= 45 && strengthPct < 55) return 'balance.context.balanced';
  return 'balance.context.cardio';
}

function getActiveWorkout() {
  try {
    const stored = localStorage.getItem('activeWorkout');
    if (!stored) return null;
    const parsed = JSON.parse(stored);
    if (!parsed || !parsed.id) return null;
    return parsed;
  } catch (error) {
    localStorage.removeItem('activeWorkout');
    return null;
  }
}

function buildBalanceData(sessions, rangeDays) {
  const now = new Date();
  const cutoff = new Date(now.getTime() - rangeDays * 24 * 60 * 60 * 1000);
  const cutoffKey = getBerlinDateKey(cutoff);

  let strengthSec = 0;
  let cardioSec = 0;

  sessions.forEach(session => {
    const date = getSessionDate(session);
    if (!date) return;
    if (getBerlinDateKey(date) < cutoffKey) return;

    const durationSec = getSessionDurationSeconds(session);
    if (!durationSec) return;

    if (session.type === 'cardio') {
      cardioSec += durationSec;
    } else if (session.type === 'strength') {
      strengthSec += durationSec;
    }
  });

  return {
    strengthSec,
    cardioSec,
    rangeDays,
    contextLabelKey: getBalanceContextLabelKey(strengthSec, cardioSec)
  };
}

function getRecentSessions(sessions, limit = DASHBOARD_RECENT_LIMIT) {
  return sessions
    .map(session => ({
      session,
      date: getSessionDateTime(session)
    }))
    .filter(item => item.date)
    .sort((a, b) => b.date.getTime() - a.date.getTime())
    .slice(0, limit)
    .map(item => item.session);
}

function getTodaysScheduledWorkouts() {
  if (typeof scheduleData === 'undefined' || !Array.isArray(scheduleData)) {
    return [];
  }
  const today = getBerlinDateKey(new Date());
  return scheduleData.filter(item =>
    item.date === today &&
    !item.completed
  );
}

