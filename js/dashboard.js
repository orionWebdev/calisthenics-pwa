// ========================================
// DASHBOARD - SESSIONS ONLY
// ========================================

const DASHBOARD_RECENT_LIMIT = 5;
// Dashboard Hybrid Balance fixed to 7 days - no toggle
const DASHBOARD_BALANCE_DAYS = 7;
let dashboardIsLoading = false;

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
  if (session?.createdAt?.toDate) {
    return session.createdAt.toDate();
  }
  const createdParsed = new Date(session?.createdAt);
  if (!Number.isNaN(createdParsed.getTime())) return createdParsed;
  return getSessionDate(session);
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
    scheduledWorkouts: []
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
  // Navigate to calendar view
  if (typeof showView === 'function') {
    showView('calendar');
  }
}

function openStartWorkoutFromPlanSheet() {
  if (typeof closeSheet === 'function') {
    closeSheet();
  }
  // Open plan picker to start a workout from an existing plan
  if (typeof openCalendarPlanPicker === 'function') {
    openCalendarPlanPicker((planId) => {
      if (typeof startWorkoutFromPlan === 'function') {
        startWorkoutFromPlan(planId);
      }
    });
  } else if (typeof showView === 'function') {
    // Fallback: navigate to training tab
    showView('training');
    if (typeof showTrainingTab === 'function') {
      showTrainingTab('plans');
    }
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
      <div class="dashboard-scheduled-header">
        <span class="material-symbols-rounded">event</span>
        <span>${tr('dashboard.scheduled.title')}</span>
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

  if (state.loading) {
    container.innerHTML = `
      <div class="dashboard-recent-header">
        <h3 class="dashboard-recent-title">${tr('dashboard.recent.title')}</h3>
        <p class="dashboard-recent-description">${tr('dashboard.recent.description')}</p>
      </div>
      <div class="dashboard-recent-empty">${tr('common.loading')}</div>
    `;
    return;
  }

  if (!state.recentSessions.length) {
    container.innerHTML = `
      <div class="dashboard-recent-header">
        <h3 class="dashboard-recent-title">${tr('dashboard.recent.title')}</h3>
        <p class="dashboard-recent-description">${tr('dashboard.recent.description')}</p>
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

  container.innerHTML = `
    <div class="dashboard-recent-header">
      <h3 class="dashboard-recent-title">${tr('dashboard.recent.title')}</h3>
      <p class="dashboard-recent-description">${tr('dashboard.recent.description')}</p>
    </div>
    <div class="dashboard-recent-list">
      ${rows}
    </div>
  `;
}

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

async function refreshDashboard() {
  if (dashboardIsLoading) return;
  dashboardIsLoading = true;

  const data = await useDashboardData();
  renderScheduledWorkoutsCard(data);
  renderLogWorkoutCard(data);
  renderHybridBalanceCard(data);
  renderRecentSessionsList(data);

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

// ========================================
// AUTO-INITIALIZE
// ========================================

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDashboard);
} else {
  initDashboard();
}
