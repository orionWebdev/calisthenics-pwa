// ========================================
// DASHBOARD - SESSIONS ONLY
// ========================================

const DASHBOARD_RECENT_LIMIT = 3;
// Dashboard Hybrid Balance fixed to 7 days - no toggle
const DASHBOARD_BALANCE_DAYS = 7;
let dashboardIsLoading = false;
// Dashboard Activity Calendar state
let dashboardActivityMonth = new Date();
let dashboardCalendarTab = 'activity';

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
 * Berechnet die ISO-Wochennummer für ein Datum (Europe/Berlin)
 * @returns {Object} { year, week } - ISO Jahr und Wochennummer
 */
function getISOWeekBerlin(date) {
  // Konvertiere zu Berlin-Zeit
  const berlinDate = new Date(date.toLocaleString('en-US', { timeZone: 'Europe/Berlin' }));
  berlinDate.setHours(0, 0, 0, 0);

  // ISO-Woche: Woche beginnt am Montag, erste Woche enthält den 4. Januar
  const thursday = new Date(berlinDate);
  thursday.setDate(berlinDate.getDate() - ((berlinDate.getDay() + 6) % 7) + 3);

  const firstThursday = new Date(thursday.getFullYear(), 0, 4);
  firstThursday.setDate(firstThursday.getDate() - ((firstThursday.getDay() + 6) % 7) + 3);

  const weekNumber = Math.round((thursday - firstThursday) / (7 * 24 * 60 * 60 * 1000)) + 1;

  return { year: thursday.getFullYear(), week: weekNumber };
}

/**
 * Zählt Sessions in der aktuellen Kalenderwoche (ISO, Europe/Berlin)
 */
function getSessionsThisWeekCount(sessions) {
  if (!Array.isArray(sessions) || sessions.length === 0) return 0;

  const now = new Date();
  const currentWeek = getISOWeekBerlin(now);

  return sessions.filter(session => {
    const date = getSessionDate(session);
    if (!date) return false;
    const sessionWeek = getISOWeekBerlin(date);
    return sessionWeek.year === currentWeek.year && sessionWeek.week === currentWeek.week;
  }).length;
}

/**
 * Berechnet die Gesamtbewegungsminuten der aktuellen ISO-Woche (Europe/Berlin)
 */
function getMovementMinutesThisWeek(sessions) {
  if (!Array.isArray(sessions) || sessions.length === 0) return 0;

  const now = new Date();
  const currentWeek = getISOWeekBerlin(now);

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

async function useDashboardData() {
  const state = {
    loading: true,
    error: null,
    activeSession: null,
    balance: {
      strengthSec: 0,
      cardioSec: 0,
      rangeDays: DASHBOARD_BALANCE_DAYS,
      contextLabelKey: 'balance.context.lowData'
    },
    recentSessions: [],
    scheduledWorkouts: [],
    // Quick Stats
    sessionsThisWeekCount: 0,
    movementMinutesThisWeek: 0
  };

  try {
    if (typeof loadSessions === 'function' && !sessionsLoaded) {
      await loadSessions();
    }

    const sessions = Array.isArray(allSessions) ? allSessions : [];

    state.activeSession = getActiveWorkout();
    state.balance = buildBalanceData(sessions, DASHBOARD_BALANCE_DAYS);
    state.recentSessions = getRecentSessions(sessions, DASHBOARD_RECENT_LIMIT);
    state.scheduledWorkouts = getTodaysScheduledWorkouts();

    // Quick Stats berechnen
    state.sessionsThisWeekCount = getSessionsThisWeekCount(sessions);
    state.movementMinutesThisWeek = getMovementMinutesThisWeek(sessions);
  } catch (error) {
    console.error('Error loading dashboard data:', error);
    state.error = error;
  }

  state.loading = false;
  return state;
}

function openStartWorkoutSheet() {
  if (getActiveWorkout()) {
    return;
  }

  if (typeof openSheet !== 'function') {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', tr('errors.startUnavailable'));
    }
    return;
  }

  openSheet({
    title: tr('dashboard.primary.title'),
    render: (container) => {
      container.innerHTML = `
        <button class="picker-item strength" type="button" onclick="startManualWorkout('strength')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">fitness_center</span>
          </div>
          <span>${tr('common.strength')}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item cardio" type="button" onclick="startManualWorkout('cardio')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">directions_run</span>
          </div>
          <span>${tr('common.cardio')}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item recovery" type="button" onclick="startManualWorkout('recovery')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">self_improvement</span>
          </div>
          <span>${tr('common.recovery')}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
      `;
    }
  });
}

function startManualWorkout(type) {
  if (getActiveWorkout()) {
    return;
  }

  if (typeof closeSheet === 'function') {
    closeSheet();
  }

  if (type === 'cardio') {
    if (typeof openAddCardioModal === 'function') {
      openAddCardioModal();
      return;
    }
  }

  if (type === 'recovery') {
    if (typeof openAddRecoveryModal === 'function') {
      openAddRecoveryModal();
      return;
    }
  }

  if (type === 'strength') {
    if (typeof openAddStrengthModal === 'function') {
      openAddStrengthModal();
      return;
    }
  }

  if (typeof showView === 'function') {
    if (typeof showTrainingTab === 'function') {
      showTrainingTab('plans');
      return;
    }
    showView('training');
  }
}

function openAddWorkoutSheet() {
  if (typeof openSheet !== 'function') {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', tr('errors.startUnavailable'));
    }
    return;
  }

  openSheet({
    title: tr('dashboard.logWorkout.title'),
    render: (container) => {
      container.innerHTML = `
        <button class="picker-item" type="button" onclick="openLogWorkoutTypeSheet()">
          <span class="material-symbols-rounded" style="font-size: 24px; color: white;">done</span>
          <div class="picker-item-content">
            <span class="picker-item-label">${tr('dashboard.logWorkout.log')}</span>
            <span class="picker-item-desc">${tr('dashboard.logWorkout.logDesc')}</span>
          </div>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item" type="button" onclick="openPlanWorkoutSheet()">
          <span class="material-symbols-rounded" style="font-size: 24px; color: white;">event</span>
          <div class="picker-item-content">
            <span class="picker-item-label">${tr('dashboard.logWorkout.plan')}</span>
            <span class="picker-item-desc">${tr('dashboard.logWorkout.planDesc')}</span>
          </div>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item" type="button" onclick="openStartWorkoutFromPlanSheet()">
          <span class="material-symbols-rounded" style="font-size: 24px; color: white;">play_arrow</span>
          <div class="picker-item-content">
            <span class="picker-item-label">${tr('dashboard.logWorkout.start')}</span>
            <span class="picker-item-desc">${tr('dashboard.logWorkout.startDesc')}</span>
          </div>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
      `;
    }
  });
}

function openLogWorkoutTypeSheet() {
  if (typeof openSheet !== 'function') return;

  openSheet({
    title: tr('dashboard.logWorkout.log'),
    render: (container) => {
      container.innerHTML = `
        <button class="picker-item strength" type="button" onclick="addWorkoutOfType('strength')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">fitness_center</span>
          </div>
          <span>${tr('common.strength')}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item cardio" type="button" onclick="addWorkoutOfType('cardio')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">directions_run</span>
          </div>
          <span>${tr('common.cardio')}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item recovery" type="button" onclick="addWorkoutOfType('recovery')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">self_improvement</span>
          </div>
          <span>${tr('common.recovery')}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
      `;
    }
  });
}

function openPlanWorkoutSheet() {
  if (typeof closeSheet === 'function') {
    closeSheet();
  }
  // Switch to plan calendar tab on dashboard
  if (typeof switchCalendarWidgetTab === 'function') {
    switchCalendarWidgetTab('planen');
  }
}

function openStartWorkoutFromPlanSheet() {
  if (typeof openSheet !== 'function') return;

  openSheet({
    title: tr('dashboard.logWorkout.start'),
    render: (container) => {
      container.innerHTML = `
        <button class="picker-item" type="button" onclick="startWorkoutFromPlanOption()">
          <span class="material-symbols-rounded" style="font-size: 24px; color: white;">description</span>
          <div class="picker-item-content">
            <span class="picker-item-label">Plan auswählen</span>
            <span class="picker-item-desc">Starte ein Training aus deinen Plänen</span>
          </div>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item" type="button" onclick="startFreeWorkoutOption()">
          <span class="material-symbols-rounded" style="font-size: 24px; color: white;">add_circle</span>
          <div class="picker-item-content">
            <span class="picker-item-label">Neues Training</span>
            <span class="picker-item-desc">Starte ein leeres Workout und füge Übungen hinzu</span>
          </div>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
      `;
    }
  });
}

function startWorkoutFromPlanOption() {
  if (typeof closeSheet === 'function') {
    closeSheet();
  }
  if (typeof openPlanPickerSheet === 'function') {
    openPlanPickerSheet((planId) => {
      if (typeof startWorkoutFromPlan === 'function') {
        startWorkoutFromPlan(planId);
      }
    });
  } else if (typeof showView === 'function') {
    showView('training');
    if (typeof showTrainingTab === 'function') {
      showTrainingTab('plans');
    }
  }
}

function startFreeWorkoutOption() {
  if (typeof closeSheet === 'function') {
    closeSheet();
  }
  if (typeof startEmptyWorkout === 'function') {
    startEmptyWorkout();
  }
}

function addWorkoutOfType(type) {
  if (typeof closeSheet === 'function') {
    closeSheet();
  }

  if (type === 'cardio') {
    if (typeof openAddCardioModal === 'function') {
      openAddCardioModal();
      return;
    }
  }

  if (type === 'recovery') {
    if (typeof openAddRecoveryModal === 'function') {
      openAddRecoveryModal();
      return;
    }
  }

  if (type === 'strength') {
    if (typeof openAddStrengthModal === 'function') {
      openAddStrengthModal();
      return;
    }
  }

  if (typeof showView === 'function') {
    showView('training');
  }
}

function getPlanTypeColor(type) {
  const colors = {
    strength: 'var(--color-category-strength)',
    bodyweight: 'var(--color-category-bodyweight)',
    cardio: 'var(--color-category-cardio)',
    recovery: 'var(--color-category-recovery)'
  };
  return colors[type] || colors.strength;
}

function renderScheduledWorkoutsCard(state) {
  const container = document.getElementById('dashboard-scheduled-card');
  if (!container) return;

  // Hide container if no scheduled workouts
  if (!state.scheduledWorkouts || state.scheduledWorkouts.length === 0) {
    container.innerHTML = '';
    container.style.display = 'none';
    return;
  }

  container.style.display = 'block';

  const workoutTypeLabels = {
    strength: tr('common.strength'),
    bodyweight: tr('common.bodyweight'),
    cardio: tr('common.cardio'),
    recovery: tr('common.recovery')
  };

  const items = state.scheduledWorkouts.map(workout => `
    <div class="dashboard-scheduled-item" onclick="startScheduledWorkout('${workout.id}')">
      <div class="dashboard-scheduled-info">
        <span class="dashboard-scheduled-type" style="background: color-mix(in srgb, ${getPlanTypeColor(workout.planType)} 20%, transparent); color: ${getPlanTypeColor(workout.planType)};">
          ${workoutTypeLabels[workout.planType] || workout.planType}
        </span>
        <span class="dashboard-scheduled-name">${workout.planName}</span>
      </div>
      <div class="dashboard-scheduled-meta">
        <span class="dashboard-scheduled-duration">${workout.planDuration || 45} Min</span>
        <span class="material-symbols-rounded dashboard-scheduled-play">play_arrow</span>
      </div>
    </div>
  `).join('');

  container.innerHTML = `
    <div class="dashboard-scheduled-widget">
      <div class="dashboard-scheduled-header" onclick="if(typeof switchCalendarWidgetTab==='function') switchCalendarWidgetTab('planen')" style="cursor: pointer;">
        <span class="material-symbols-rounded">event</span>
        <span>${tr('dashboard.scheduled.title')}</span>
        <span class="material-symbols-rounded" style="margin-left: auto; font-size: 18px; opacity: 0.5;">chevron_right</span>
      </div>
      <div class="dashboard-scheduled-list">
        ${items}
      </div>
    </div>
  `;
}

function renderLogWorkoutCard(state) {
  const container = document.getElementById('dashboard-log-workout-card');
  if (!container) return;

  const todayTitle = tr('dashboard.today') || 'Heute';
  const todayDate = typeof formatDateLongText === 'function'
    ? formatDateLongText(new Date(), false)
    : new Intl.DateTimeFormat('de-DE', {
      weekday: 'long',
      day: 'numeric',
      month: 'long'
    }).format(new Date());
  const todayTitleEl = document.getElementById('dashboard-today-title');
  const todayDateEl = document.getElementById('dashboard-today-date');
  if (todayTitleEl) todayTitleEl.textContent = todayTitle;
  if (todayDateEl) todayDateEl.textContent = todayDate;

  if (state.loading) {
    container.innerHTML = `
      <div class="dashboard-log-workout-loading">
        <p>${tr('common.loading')}</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <button class="dashboard-log-workout-btn" type="button" onclick="openAddWorkoutSheet()">
      <div class="dashboard-log-workout-content">
        <h3 class="dashboard-log-workout-title">${tr('dashboard.logWorkout.title')}</h3>
        <p class="dashboard-log-workout-subtitle">${tr('dashboard.logWorkout.subtitle')}</p>
      </div>
      <span class="material-symbols-rounded dashboard-log-workout-icon">add</span>
    </button>
  `;
}

// ========================================
// QUICK STATS WIDGET
// ========================================

function renderQuickStatsWidget(state) {
  const container = document.getElementById('dashboard-quick-stats');
  if (!container) return;

  if (state.loading) {
    container.innerHTML = `
      <div class="quick-stats-grid">
        <div class="quick-stats-card">
          <div class="quick-stats-skeleton"></div>
        </div>
        <div class="quick-stats-card">
          <div class="quick-stats-skeleton"></div>
        </div>
      </div>
    `;
    return;
  }

  const sessionsCount = state.sessionsThisWeekCount || 0;
  const movementMinutes = state.movementMinutesThisWeek || 0;

  container.innerHTML = `
    <div class="quick-stats-grid">
      <div class="quick-stats-card">
        <div class="quick-stats-header">
          <span class="quick-stats-label">${tr('dashboard.quickStats.thisWeek')}</span>
          <span class="quick-stats-icon">
            <span class="material-symbols-rounded">fitness_center</span>
          </span>
        </div>
        <div class="quick-stats-value">${sessionsCount}</div>
        <div class="quick-stats-subtext">${tr('dashboard.quickStats.sessions')}</div>
      </div>
      <div class="quick-stats-card">
        <div class="quick-stats-header">
          <span class="quick-stats-label">${tr('dashboard.quickStats.movementMinutes')}</span>
          <span class="quick-stats-icon">
            <span class="material-symbols-rounded">timer</span>
          </span>
        </div>
        <div class="quick-stats-value">${movementMinutes}</div>
        <div class="quick-stats-subtext">${tr('dashboard.quickStats.thisWeek')}</div>
      </div>
    </div>
  `;
}

function resumeWorkoutFromDashboard() {
  if (!getActiveWorkout()) return;
  if (typeof resumeWorkout === 'function') {
    resumeWorkout();
    return;
  }
  if (typeof showView === 'function') {
    showView('workout');
  }
}

function renderHybridBalanceCard(state) {
  const container = document.getElementById('hybrid-balance-card');
  if (!container) return;

  if (state.loading) {
    container.innerHTML = `
      <div class="dashboard-balance-card">
        <div class="dashboard-balance-header">
          <h3 class="dashboard-balance-title">${tr('dashboard.hybridBalance.title')}</h3>
        </div>
        <div class="dashboard-balance-empty">${tr('common.loading')}</div>
      </div>
    `;
    return;
  }

  const balance = state.balance;
  const totalSec = balance.strengthSec + balance.cardioSec;
  const strengthPct = totalSec ? Math.round((balance.strengthSec / totalSec) * 100) : 0;
  const cardioPct = totalSec ? 100 - strengthPct : 0;

  // Dashboard always shows 7 days - no toggle (period selection is in Progress pages)
  container.innerHTML = `
    <div class="dashboard-balance-card" onclick="openProgressOverview()" role="button" tabindex="0">
      <div class="dashboard-balance-header">
        <div>
          <h3 class="dashboard-balance-title">${tr('dashboard.hybridBalance.title')}</h3>
          <p class="dashboard-balance-subtitle">${tr('dashboard.hybridBalance.subtitle', { days: DASHBOARD_BALANCE_DAYS })}</p>
        </div>
        <span class="material-symbols-rounded dashboard-balance-arrow">chevron_right</span>
      </div>
      <p class="dashboard-balance-description">${tr('dashboard.hybridBalance.description')}</p>
      <div class="dashboard-balance-bar" role="img" aria-label="${tr('dashboard.hybridBalance.aria', { strength: strengthPct, cardio: cardioPct })}">
        <div class="dashboard-balance-segment strength" style="width: ${strengthPct}%;"></div>
        <div class="dashboard-balance-segment cardio" style="width: ${cardioPct}%;"></div>
      </div>
      <div class="dashboard-balance-meta">
        <span>${tr('common.strength')} ${formatDurationShortText(balance.strengthSec)}</span>
        <span>${tr('common.cardio')} ${formatDurationShortText(balance.cardioSec)}</span>
      </div>
      <div class="dashboard-balance-context">${tr(balance.contextLabelKey)}</div>
    </div>
  `;
}

function renderRecentSessionsList(state) {
  const container = document.getElementById('recent-sessions-card');
  if (!container) return;

  // Prüfe ob es mehr Sessions gibt als angezeigt werden
  const allSessionsArray = Array.isArray(allSessions) ? allSessions : [];
  const hasMoreSessions = allSessionsArray.length > DASHBOARD_RECENT_LIMIT;

  if (state.loading) {
    container.innerHTML = `
      <div class="dashboard-recent-header">
        <h3 class="dashboard-recent-title">${tr('dashboard.recent.title')}</h3>
      </div>
      <div class="dashboard-recent-empty">${tr('common.loading')}</div>
    `;
    return;
  }

  if (!state.recentSessions.length) {
    container.innerHTML = `
      <div class="dashboard-recent-header">
        <h3 class="dashboard-recent-title">${tr('dashboard.recent.title')}</h3>
      </div>
      <div class="dashboard-recent-empty">${tr('dashboard.recent.empty')}</div>
    `;
    return;
  }

  const rows = state.recentSessions.map(session => {
    const date = getSessionDateTime(session);
    const duration = formatDurationShortText(getSessionDurationSeconds(session));
    const typeLabel = session.type === 'cardio'
      ? tr('common.cardio')
      : session.type === 'recovery'
        ? tr('common.recovery')
        : tr('common.strength');
    const distance = session.type === 'cardio' && session.distanceKm
      ? ` | ${tr('format.distanceKm', { distance: Number(session.distanceKm).toFixed(1) })}`
      : '';

    const sessionId = session.id || '';
    return `
      <button class="dashboard-session-item" type="button" onclick="openSessionDetail('${sessionId}')">
        <div class="dashboard-session-main">
          <div class="dashboard-session-type ${session.type === 'cardio' ? 'cardio' : session.type === 'recovery' ? 'recovery' : 'strength'}">${typeLabel}</div>
          <div class="dashboard-session-date">${formatDateTimeText(date)}</div>
        </div>
        <div class="dashboard-session-meta">
          <span>${duration}</span>
          ${distance ? `<span>${distance}</span>` : ''}
        </div>
      </button>
    `;
  }).join('');

  // Chevron nur anzeigen wenn mehr Sessions existieren
  const chevronHtml = hasMoreSessions ? `
    <span class="material-symbols-rounded dashboard-recent-chevron">chevron_right</span>
  ` : '';

  container.innerHTML = `
    <div class="dashboard-recent-header${hasMoreSessions ? ' clickable' : ''}" ${hasMoreSessions ? 'onclick="navigateToAllSessions()" role="button" tabindex="0"' : ''}>
      <h3 class="dashboard-recent-title">${tr('dashboard.recent.title')}</h3>
      ${chevronHtml}
    </div>
    <div class="dashboard-recent-list">
      ${rows}
    </div>
  `;
}

function navigateToAllSessions() {
  if (typeof showView === 'function') {
    showView('allSessions');
  }
}

// ========================================
// ALL SESSIONS PAGE
// ========================================

function getDateGroupKey(date) {
  if (!date) return 'earlier';

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  const sessionDate = new Date(date);
  sessionDate.setHours(0, 0, 0, 0);

  if (sessionDate.getTime() === today.getTime()) {
    return 'today';
  }
  if (sessionDate.getTime() === yesterday.getTime()) {
    return 'yesterday';
  }
  return 'earlier';
}

function renderAllSessionsPage() {
  const container = document.getElementById('all-sessions-list');
  const titleEl = document.getElementById('all-sessions-title');

  if (!container) return;

  // Setze den i18n-Titel
  if (titleEl) {
    titleEl.textContent = tr('dashboard.allSessions.title');
  }

  const sessions = Array.isArray(allSessions) ? allSessions : [];

  if (!sessions.length) {
    container.innerHTML = `
      <div class="all-sessions-empty">
        <span class="material-symbols-rounded">history</span>
        <p>${tr('dashboard.allSessions.empty')}</p>
      </div>
    `;
    return;
  }

  // Sortiere nach Datum (neueste zuerst)
  const sortedSessions = sessions
    .map(session => ({
      session,
      date: getSessionDateTime(session)
    }))
    .filter(item => item.date)
    .sort((a, b) => b.date.getTime() - a.date.getTime())
    .map(item => item.session);

  // Gruppiere nach Datum
  const groups = {
    today: [],
    yesterday: [],
    earlier: []
  };

  sortedSessions.forEach(session => {
    const date = getSessionDateTime(session);
    const groupKey = getDateGroupKey(date);
    groups[groupKey].push(session);
  });

  const groupLabels = {
    today: tr('dashboard.allSessions.today'),
    yesterday: tr('dashboard.allSessions.yesterday'),
    earlier: tr('dashboard.allSessions.earlier')
  };

  let html = '';

  ['today', 'yesterday', 'earlier'].forEach(groupKey => {
    const groupSessions = groups[groupKey];
    if (!groupSessions.length) return;

    html += `
      <div class="all-sessions-group">
        <h3 class="all-sessions-group-title">${groupLabels[groupKey]}</h3>
        <div class="all-sessions-group-list">
    `;

    groupSessions.forEach(session => {
      const date = getSessionDateTime(session);
      const duration = formatDurationShortText(getSessionDurationSeconds(session));
      const typeLabel = session.type === 'cardio'
        ? tr('common.cardio')
        : session.type === 'recovery'
          ? tr('common.recovery')
          : tr('common.strength');
      const distance = session.type === 'cardio' && session.distanceKm
        ? ` | ${tr('format.distanceKm', { distance: Number(session.distanceKm).toFixed(1) })}`
        : '';
      const sessionId = session.id || '';

      html += `
        <button class="all-sessions-item" type="button" onclick="openSessionDetail('${sessionId}')">
          <div class="all-sessions-item-main">
            <div class="all-sessions-item-type ${session.type === 'cardio' ? 'cardio' : session.type === 'recovery' ? 'recovery' : 'strength'}">${typeLabel}</div>
            <div class="all-sessions-item-date">${formatDateTimeText(date)}</div>
          </div>
          <div class="all-sessions-item-meta">
            <span>${duration}</span>
            ${distance ? `<span>${distance}</span>` : ''}
            <span class="material-symbols-rounded all-sessions-item-chevron">chevron_right</span>
          </div>
        </button>
      `;
    });

    html += `
        </div>
      </div>
    `;
  });

  container.innerHTML = html;
}

window.renderAllSessionsPage = renderAllSessionsPage;

function openSessionDetail(sessionId) {
  if (!sessionId) return;
  if (typeof viewWorkoutDetailsFromSession === 'function') {
    viewWorkoutDetailsFromSession(sessionId);
    return;
  }
  if (typeof openWorkoutDetailModal === 'function') {
    openWorkoutDetailModal(sessionId);
  }
}

function openProgressOverview() {
  if (typeof showView === 'function') {
    showView('progress');
  }
  if (typeof switchProgressTab === 'function') {
    switchProgressTab('overview');
  }
}

// ========================================
// DASHBOARD ACTIVITY CALENDAR WIDGET (Suunto Style)
// ========================================

function getDashboardMonthDuration(sessions) {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();

  let totalMinutes = 0;

  sessions.forEach(session => {
    const date = getSessionDate(session);
    if (!date) return;
    if (date.getFullYear() !== year || date.getMonth() !== month) return;

    const durationSec = getSessionDurationSeconds(session);
    if (durationSec > 0) {
      totalMinutes += Math.round(durationSec / 60);
    }
  });

  return totalMinutes;
}

function getDashboardSessionsByDate(sessions, year, month) {
  const result = {};
  sessions.forEach(session => {
    const date = getSessionDate(session);
    if (!date) return;
    if (date.getFullYear() !== year || date.getMonth() !== month) return;
    const dateKey = getBerlinDateKey(date);
    if (!result[dateKey]) result[dateKey] = [];
    result[dateKey].push(session);
  });
  return result;
}

/**
 * Aggregiert Sessions pro Typ pro Tag und berechnet Dot-Größen
 * @param {Array} daySessions - Sessions eines Tages
 * @returns {Array} - Array von {type, size, rank, minutes} sortiert nach Größe (größte zuerst)
 */
function aggregateDayByType(daySessions) {
  // Summiere Minuten pro Typ
  const typeMinutes = {};
  daySessions.forEach(session => {
    const type = session.type === 'cardio' ? 'cardio' : session.type === 'recovery' ? 'recovery' : 'strength';
    const durationSec = getSessionDurationSeconds(session);
    const minutes = Math.round(durationSec / 60);
    typeMinutes[type] = (typeMinutes[type] || 0) + minutes;
  });

  // Konvertiere zu Dot-Metadaten mit Größe basierend auf Gesamtdauer
  const dots = Object.entries(typeMinutes).map(([type, minutes]) => {
    const { size, rank } = getSizeFromMinutes(minutes);
    return { type, size, rank, minutes };
  });

  // Sortiere nach rank (größte zuerst für z-index Stacking)
  dots.sort((a, b) => b.rank - a.rank);

  return dots;
}

/**
 * Mappt Minuten zu Dot-Größe nach Spezifikation
 * < 15min => S, < 30min => M, < 45min => L, < 60min => XL, >= 60min => XXL
 */
function getSizeFromMinutes(minutes) {
  if (minutes >= 60) return { size: 'xxl', rank: 5 };
  if (minutes >= 45) return { size: 'xl', rank: 4 };
  if (minutes >= 30) return { size: 'l', rank: 3 };
  if (minutes >= 15) return { size: 'm', rank: 2 };
  return { size: 's', rank: 1 };
}

/**
 * Rendert nested Dots für einen Tag
 * - Größte Dots unten (niedrigster z-index), kleinste oben
 * - Micro-offset bei gleicher Größe
 */
function renderNestedDots(dots) {
  if (!dots || dots.length === 0) return '';

  // Erkenne Größen-Duplikate und markiere diese für offset
  const sizeCount = {};
  dots.forEach(dot => {
    sizeCount[dot.size] = (sizeCount[dot.size] || 0) + 1;
  });

  // Sortiere nach rank absteigend (größte zuerst für Rendering-Reihenfolge)
  // Größte werden zuerst gerendert = unterste Schicht
  const sortedDots = [...dots].sort((a, b) => b.rank - a.rank);

  const sizeOffsetUsed = {};
  const dotElements = sortedDots.map(dot => {
    let offsetClass = '';
    // Wenn es mehrere Dots mit dieser Größe gibt, gib dem zweiten/dritten ein offset
    if (sizeCount[dot.size] > 1) {
      if (!sizeOffsetUsed[dot.size]) {
        sizeOffsetUsed[dot.size] = true;
      } else {
        offsetClass = ' offset';
      }
    }
    return `<span class="mini-dot ${dot.type} size-${dot.size}${offsetClass}"></span>`;
  });

  return `<div class="mini-dot-stack">${dotElements.join('')}</div>`;
}

function formatDurationHoursMinutes(totalMinutes) {
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) {
    return `${hours}:${String(minutes).padStart(2, '0')}`;
  }
  if (hours > 0) {
    return `${hours}:00`;
  }
  return `0:${String(minutes).padStart(2, '0')}`;
}

/**
 * Formatiert Dauer als "Xh Xm" String (für Activity Calendar)
 * Erwartet Minuten als Input
 */
function formatDurationMinutesText(totalMinutes) {
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) {
    return `${hours}h ${minutes}m`;
  }
  if (hours > 0) {
    return `${hours}h`;
  }
  return `${minutes}m`;
}

/**
 * Aggregiert Sessions pro Trainingstyp für einen Zeitraum
 * @returns {Array} [{type, minutes, color}] sortiert nach Minuten absteigend
 */
function aggregateSessionsByType(sessions, year, month) {
  const typeMinutes = {
    strength: 0,
    cardio: 0,
    recovery: 0
  };

  sessions.forEach(session => {
    const date = getSessionDate(session);
    if (!date) return;
    if (date.getFullYear() !== year || date.getMonth() !== month) return;

    const type = session.type === 'cardio' ? 'cardio' : session.type === 'recovery' ? 'recovery' : 'strength';
    const durationSec = getSessionDurationSeconds(session);
    typeMinutes[type] += Math.round(durationSec / 60);
  });

  // Konvertiere zu Array und sortiere nach Minuten absteigend
  const typeColors = {
    strength: 'var(--color-category-strength)',
    cardio: 'var(--color-category-cardio)',
    recovery: 'var(--color-category-recovery)'
  };

  return Object.entries(typeMinutes)
    .filter(([_, minutes]) => minutes > 0)
    .map(([type, minutes]) => ({
      type,
      minutes,
      color: typeColors[type]
    }))
    .sort((a, b) => b.minutes - a.minutes);
}

/**
 * Wiederverwendbare Activity Calendar Grid Komponente
 * @param {Object} options - { year, month, sessionsByDate, detailed, dayLabels }
 */
function renderActivityCalendarGrid(options) {
  const { year, month, sessionsByDate, detailed = false, dayLabels } = options;

  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  let startDay = firstDay.getDay();
  startDay = startDay === 0 ? 6 : startDay - 1; // Monday-based
  const daysInMonth = lastDay.getDate();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const cellClass = detailed ? 'activity-cal-cell' : 'mini-cal-cell';
  const gridClass = detailed ? 'activity-cal-grid' : 'mini-cal-grid';
  const headerClass = detailed ? 'activity-cal-header' : 'mini-cal-header';
  const labelClass = detailed ? 'activity-cal-day-label' : 'mini-cal-day-label';

  let html = `<div class="${headerClass}">`;
  html += dayLabels.map(d => `<span class="${labelClass}">${d}</span>`).join('');
  html += `</div>`;
  html += `<div class="${gridClass}">`;

  // Empty cells for previous month
  for (let i = 0; i < startDay; i++) {
    html += `<div class="${cellClass} empty"></div>`;
  }

  // Days of current month
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const dateKey = getBerlinDateKey(date);
    const isToday = date.toDateString() === today.toDateString();
    const daySessions = sessionsByDate[dateKey] || [];

    const aggregatedDots = aggregateDayByType(daySessions);
    const dotHTML = renderNestedDots(aggregatedDots);

    const todayClass = isToday ? 'today' : '';
    const dayNumberHTML = detailed ? `<span class="day-number">${day}</span>` : '';

    html += `
      <div class="${cellClass} ${todayClass}" data-date="${dateKey}">
        ${dayNumberHTML}
        ${dotHTML}
      </div>
    `;
  }

  html += `</div>`;
  return html;
}

function navigateDashboardActivityMonth(direction) {
  dashboardActivityMonth.setMonth(dashboardActivityMonth.getMonth() + (direction === 'next' ? 1 : -1));
  renderDashboardActivityCalendar({ loading: false });
}

function openDashboardActivityDaySheet(dateKey) {
  // Use existing openActivityDaySheet from progressv2.js if available
  if (typeof openActivityDaySheet === 'function') {
    openActivityDaySheet(dateKey);
    return;
  }

  // Fallback: get sessions and show basic info
  const sessions = typeof getSessionsForDate === 'function' ? getSessionsForDate(dateKey) : [];
  const date = new Date(dateKey + 'T12:00:00');
  const monthNamesFull = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
                          'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

  if (typeof openSheet === 'function') {
    openSheet({
      title: `Sessions am ${date.getDate()}. ${monthNamesFull[date.getMonth()]}`,
      render: (sheetContainer) => {
        if (sessions.length === 0) {
          const emptyText = tr('dashboard.activityCalendar.emptyState') || 'Keine Sessions an diesem Tag';
          sheetContainer.innerHTML = `
            <div class="activity-day-empty">
              <span class="material-symbols-rounded">event_busy</span>
              <p>${emptyText}</p>
            </div>
          `;
          return;
        }

        sheetContainer.innerHTML = sessions.map(session => {
          const typeLabel = session.type === 'cardio' ? 'Cardio' : session.type === 'recovery' ? 'Recovery' : 'Kraft';
          const durationSec = getSessionDurationSeconds(session);
          const duration = Math.round(durationSec / 60);

          return `
            <div class="activity-session-item">
              <div class="session-item-content">
                <span class="session-type-badge ${session.type}">${typeLabel}</span>
                <span class="session-duration">${duration} min</span>
              </div>
            </div>
          `;
        }).join('');
      }
    });
  }
}

function renderDashboardActivityCalendar(state) {
  const container = document.getElementById('dashboard-activity-calendar');
  if (!container) return;

  if (state.loading) {
    container.innerHTML = `
      <div class="dashboard-activity-widget-expanded">
        <div class="dashboard-activity-loading">${tr('common.loading')}</div>
      </div>
    `;
    return;
  }

  const activeIdx = dashboardCalendarTab === 'activity' ? 0 : 1;

  // Build segmented control
  const segmentedControl = `
    <div class="cal-widget-segmented-control" style="--seg-count:2;--active-idx:${activeIdx}">
      <div class="cal-widget-seg-indicator"></div>
      <button class="cal-widget-seg-btn${dashboardCalendarTab === 'activity' ? ' active' : ''}" data-tab="activity" onclick="switchCalendarWidgetTab('activity')">Aktivität</button>
      <button class="cal-widget-seg-btn${dashboardCalendarTab === 'planen' ? ' active' : ''}" data-tab="planen" onclick="switchCalendarWidgetTab('planen')">Planen</button>
    </div>
  `;

  container.innerHTML = `
    <div class="dashboard-activity-widget-expanded">
      ${segmentedControl}
      <div id="cal-widget-content"></div>
    </div>
  `;

  // Render the active tab content
  if (dashboardCalendarTab === 'activity') {
    renderActivityCalendarContent();
  } else {
    renderPlanCalendarInWidget();
  }
}

function renderActivityCalendarContent() {
  const contentEl = document.getElementById('cal-widget-content');
  if (!contentEl) return;

  const sessions = Array.isArray(allSessions) ? allSessions : [];
  const year = dashboardActivityMonth.getFullYear();
  const month = dashboardActivityMonth.getMonth();

  const sessionsByDate = getDashboardSessionsByDate(sessions, year, month);

  const monthNamesFull = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
                          'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
  const monthDisplay = `${monthNamesFull[month]} ${year}`;

  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  let startDay = firstDay.getDay();
  startDay = startDay === 0 ? 6 : startDay - 1;
  const daysInMonth = lastDay.getDate();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const dayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  let calendarHTML = `<div class="dashboard-mini-calendar-expanded">`;
  calendarHTML += `<div class="mini-cal-header-expanded">`;
  calendarHTML += dayLabels.map(d => `<span class="mini-cal-day-label-expanded">${d}</span>`).join('');
  calendarHTML += `</div>`;
  calendarHTML += `<div class="mini-cal-grid-expanded">`;

  for (let i = 0; i < startDay; i++) {
    calendarHTML += `<div class="mini-cal-cell-expanded empty"></div>`;
  }

  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const dateKey = getBerlinDateKey(date);
    const isToday = date.toDateString() === today.toDateString();
    const daySessions = sessionsByDate[dateKey] || [];

    const aggregatedDots = aggregateDayByType(daySessions);
    const dotHTML = renderNestedDots(aggregatedDots);

    const todayClass = isToday ? 'today' : '';
    const hasSessionsClass = daySessions.length > 0 ? 'has-sessions' : '';

    calendarHTML += `
      <div class="mini-cal-cell-expanded ${todayClass} ${hasSessionsClass}"
           onclick="openDashboardActivityDaySheet('${dateKey}')"
           role="button"
           tabindex="0">
        <span class="mini-cal-day-number">${day}</span>
        ${dotHTML}
      </div>
    `;
  }

  calendarHTML += `</div></div>`;

  contentEl.innerHTML = `
    <div class="dashboard-activity-month-nav">
      <button class="activity-nav-btn" onclick="event.stopPropagation(); navigateDashboardActivityMonth('prev')" aria-label="Vorheriger Monat">
        <span class="material-symbols-rounded">chevron_left</span>
      </button>
      <span class="activity-month-title">${monthDisplay}</span>
      <button class="activity-nav-btn" onclick="event.stopPropagation(); navigateDashboardActivityMonth('next')" aria-label="Nächster Monat">
        <span class="material-symbols-rounded">chevron_right</span>
      </button>
      <button class="activity-calendar-more-link" onclick="event.stopPropagation(); if(typeof showView==='function') showView('progress')">
        ${tr('dashboard.activityCalendar.more')}
        <span class="material-symbols-rounded">chevron_right</span>
      </button>
    </div>
    ${calendarHTML}
  `;
}

function renderPlanCalendarInWidget() {
  const contentEl = document.getElementById('cal-widget-content');
  if (!contentEl) return;

  contentEl.innerHTML = `
    <div class="plan-calendar-widget-wrapper">
      <div class="calendar-month-section">
        <div class="dashboard-activity-month-nav">
          <button class="activity-nav-btn" onclick="navigateCalendar('prev')" aria-label="Vorheriger Monat">
            <span class="material-symbols-rounded">chevron_left</span>
          </button>
          <span class="activity-month-title" id="calendar-title">Januar 2026</span>
          <button class="activity-nav-btn" onclick="navigateCalendar('next')" aria-label="Nächster Monat">
            <span class="material-symbols-rounded">chevron_right</span>
          </button>
        </div>
        <div class="plan-calendar-weekdays">
          <span>Mo</span><span>Di</span><span>Mi</span><span>Do</span><span>Fr</span><span>Sa</span><span>So</span>
        </div>
        <div id="calendar-grid" class="plan-calendar-grid"></div>
      </div>
      <div class="calendar-agenda-container">
        <div class="calendar-agenda-list-header">
          <h3 class="calendar-agenda-list-title" id="agenda-list-title"></h3>
          <button class="agenda-add-btn" onclick="openQuickAddSheet()" aria-label="Training hinzufuegen">
            <span class="material-symbols-rounded">add</span>
          </button>
        </div>
        <div id="calendar-agenda-list" class="calendar-agenda-list"></div>
      </div>
    </div>
  `;

  // Load schedule data if not yet loaded
  if (typeof loadSchedule === 'function' && (!Array.isArray(scheduleData) || scheduleData.length === 0)) {
    loadSchedule().then(() => {
      if (typeof renderCalendar === 'function') renderCalendar();
    });
  } else {
    if (typeof renderCalendar === 'function') renderCalendar();
  }
}

function switchCalendarWidgetTab(tab) {
  if (tab === dashboardCalendarTab) return;
  dashboardCalendarTab = tab;

  // Update segmented control indicator
  const control = document.querySelector('.cal-widget-segmented-control');
  if (control) {
    const idx = tab === 'activity' ? 0 : 1;
    control.style.setProperty('--active-idx', idx);
    control.querySelectorAll('.cal-widget-seg-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.tab === tab);
    });
  }

  // Re-render content after animation
  setTimeout(() => {
    if (tab === 'activity') {
      renderActivityCalendarContent();
    } else {
      renderPlanCalendarInWidget();
    }
  }, 220);
}

function renderDashboardTrainingTypesList(sessions, year, month) {
  const typeData = aggregateSessionsByType(sessions, year, month);

  if (typeData.length === 0) {
    return '';
  }

  const maxMinutes = typeData[0]?.minutes || 1;

  const typeConfig = {
    strength: {
      label: tr('dashboard.trainingTypes.strength') || 'Krafttraining',
      icon: 'fitness_center'
    },
    cardio: {
      label: tr('dashboard.trainingTypes.cardio') || 'Cardio',
      icon: 'directions_run'
    },
    recovery: {
      label: tr('dashboard.trainingTypes.recovery') || 'Recovery',
      icon: 'self_improvement'
    }
  };

  const items = typeData.map(item => {
    const config = typeConfig[item.type] || { label: item.type, icon: 'fitness_center' };
    const durationText = formatDurationMinutesText(item.minutes);
    const percentage = Math.round((item.minutes / maxMinutes) * 100);

    return `
      <div class="dashboard-training-type-item">
        <div class="dashboard-training-type-header">
          <span class="dashboard-training-type-icon" style="color: ${item.color};">
            <span class="material-symbols-rounded">${config.icon}</span>
          </span>
          <span class="dashboard-training-type-label">${config.label}</span>
          <span class="dashboard-training-type-duration">${durationText}</span>
        </div>
        <div class="dashboard-training-type-bar-bg">
          <div class="dashboard-training-type-bar" style="width: ${percentage}%; background: ${item.color};"></div>
        </div>
      </div>
    `;
  }).join('');

  return `
    <div class="dashboard-training-types-list">
      ${items}
    </div>
  `;
}

async function refreshDashboard() {
  if (dashboardIsLoading) return;
  dashboardIsLoading = true;

  const data = await useDashboardData();
  renderScheduledWorkoutsCard(data);
  renderLogWorkoutCard(data);
  renderQuickStatsWidget(data);
  renderDashboardActivityCalendar(data);
  // Recent sessions removed - now in Progress > Overview

  dashboardIsLoading = false;
}

async function initDashboard() {
  console.log('Initializing Dashboard...');
  if (typeof onCollectionChange === 'function' && typeof sessionsCollection !== 'undefined') {
    onCollectionChange(sessionsCollection, (sessions) => {
      allSessions = sessions;
      sessionsLoaded = true;
      refreshDashboard();
    });
  }
  // Listen to schedule changes for scheduled workouts display
  if (typeof onCollectionChange === 'function' && typeof scheduleCollection !== 'undefined') {
    onCollectionChange(scheduleCollection, () => {
      refreshDashboard();
    });
  }
  // Pre-load schedule data for plan calendar tab
  if (typeof loadSchedule === 'function') {
    loadSchedule();
  }
  await refreshDashboard();
  console.log('Dashboard initialized!');
}

// Expose functions
window.refreshDashboard = refreshDashboard;
window.openStartWorkoutSheet = openStartWorkoutSheet;
window.startManualWorkout = startManualWorkout;
window.resumeWorkoutFromDashboard = resumeWorkoutFromDashboard;
window.openAddWorkoutSheet = openAddWorkoutSheet;
window.addWorkoutOfType = addWorkoutOfType;
window.openLogWorkoutTypeSheet = openLogWorkoutTypeSheet;
window.openPlanWorkoutSheet = openPlanWorkoutSheet;
window.openStartWorkoutFromPlanSheet = openStartWorkoutFromPlanSheet;
window.navigateToAllSessions = navigateToAllSessions;
window.navigateDashboardActivityMonth = navigateDashboardActivityMonth;
window.openDashboardActivityDaySheet = openDashboardActivityDaySheet;
window.switchCalendarWidgetTab = switchCalendarWidgetTab;
window.renderPlanCalendarInWidget = renderPlanCalendarInWidget;

// Shared Activity Calendar functions (used by calendar.js)
window.aggregateDayByType = aggregateDayByType;
window.getSizeFromMinutes = getSizeFromMinutes;
window.renderNestedDots = renderNestedDots;
window.aggregateSessionsByType = aggregateSessionsByType;
window.formatDurationMinutesText = formatDurationMinutesText;
window.renderActivityCalendarGrid = renderActivityCalendarGrid;
window.getDashboardSessionsByDate = getDashboardSessionsByDate;
window.getSessionDurationSeconds = getSessionDurationSeconds;
window.getSessionDate = getSessionDate;
window.getBerlinDateKey = getBerlinDateKey;

// ========================================
// AUTO-INITIALIZE
// ========================================

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDashboard);
} else {
  initDashboard();
}
