// ========================================
// DASHBOARD - SESSIONS ONLY
// ========================================

const DASHBOARD_RECENT_LIMIT = 5;
// Dashboard Hybrid Balance fixed to 7 days - no toggle
const DASHBOARD_BALANCE_DAYS = 7;
let dashboardIsLoading = false;

function getSessionDate(session) {
  if (session?.date?.toDate) {
    return session.date.toDate();
  }
  const parsed = new Date(session?.date);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed;
}

function getSessionDurationSeconds(session) {
  if (!session) return 0;
  const sec = Number(session.durationSec || session.durationSeconds || 0);
  if (Number.isFinite(sec) && sec > 0) return Math.round(sec);
  const minutes = Number(session.duration || 0);
  if (Number.isFinite(minutes) && minutes > 0) return Math.round(minutes * 60);
  return 0;
}

function formatDurationShort(totalSeconds) {
  const totalMinutes = Math.round((totalSeconds || 0) / 60);
  if (!totalMinutes) return '0 min';
  if (totalMinutes < 60) return `${totalMinutes} min`;
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  return minutes ? `${hours}h ${minutes}m` : `${hours}h`;
}

function formatSessionDateTime(date) {
  if (!date) return 'Unbekannt';
  const formatter = new Intl.DateTimeFormat('de-DE', {
    timeZone: 'Europe/Berlin',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
  return formatter.format(date);
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

function getBalanceContextLabel(strengthSec, cardioSec) {
  const totalSec = strengthSec + cardioSec;
  if (totalSec < 3600) {
    return 'noch wenig Daten - einfach weitermachen';
  }
  const strengthPct = totalSec ? (strengthSec / totalSec) * 100 : 0;
  if (strengthPct >= 55) return 'leicht strength-lastig';
  if (strengthPct > 45 && strengthPct < 55) return 'ausgeglichen';
  return 'leicht cardio-fokussiert';
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
    contextLabel: getBalanceContextLabel(strengthSec, cardioSec)
  };
}

function getRecentSessions(sessions, limit = DASHBOARD_RECENT_LIMIT) {
  return sessions
    .map(session => ({
      session,
      date: getSessionDate(session)
    }))
    .filter(item => item.date)
    .sort((a, b) => b.date.getTime() - a.date.getTime())
    .slice(0, limit)
    .map(item => item.session);
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
      contextLabel: 'noch wenig Daten - einfach weitermachen'
    },
    recentSessions: []
  };

  try {
    if (typeof loadSessions === 'function' && !sessionsLoaded) {
      await loadSessions();
    }

    const sessions = Array.isArray(allSessions) ? allSessions : [];

    state.activeSession = getActiveWorkout();
    state.balance = buildBalanceData(sessions, DASHBOARD_BALANCE_DAYS);
    state.recentSessions = getRecentSessions(sessions, DASHBOARD_RECENT_LIMIT);
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
      showEdgeFeedback('error', 'Start-Auswahl ist nicht verfuegbar.');
    }
    return;
  }

  openSheet({
    title: 'Workout starten',
    render: (container) => {
      container.innerHTML = `
        <button class="picker-item strength" type="button" onclick="startManualWorkout('strength')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">fitness_center</span>
          </div>
          <span>Strength</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item cardio" type="button" onclick="startManualWorkout('cardio')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">directions_run</span>
          </div>
          <span>Cardio</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item recovery" type="button" onclick="startManualWorkout('recovery')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">self_improvement</span>
          </div>
          <span>Recovery</span>
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

  if (typeof showView === 'function') {
    if (typeof showTrainingTab === 'function') {
      showTrainingTab('plans');
      return;
    }
    showView('training');
  }
}

function renderPrimaryActionCard(state) {
  const container = document.getElementById('dashboard-primary-card');
  if (!container) return;

  if (state.loading) {
    container.innerHTML = `
      <div class="dashboard-primary-card">
        <div class="dashboard-primary-title">Workout</div>
        <p class="dashboard-primary-subtitle">Lade Daten...</p>
      </div>
    `;
    return;
  }

  const hasActive = Boolean(state.activeSession);
  const buttonLabel = hasActive ? 'Resume Workout' : 'Start Workout';
  const actionHandler = hasActive ? 'resumeWorkoutFromDashboard()' : 'openStartWorkoutSheet()';

  container.innerHTML = `
    <div class="dashboard-primary-card">
      <div class="dashboard-primary-header">
        <div>
          <h3 class="dashboard-primary-title">Workout</h3>
          <p class="dashboard-primary-subtitle">
            ${hasActive ? 'Ein Workout ist aktiv.' : 'Waehle Strength, Cardio oder Recovery.'}
          </p>
        </div>
        <span class="material-symbols-rounded dashboard-primary-icon">fitness_center</span>
      </div>
      <button class="dashboard-primary-btn" type="button" ${hasActive ? '' : ''} onclick="${actionHandler}">
        <span>${buttonLabel}</span>
      </button>
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
          <h3 class="dashboard-balance-title">Hybrid Balance</h3>
        </div>
        <div class="dashboard-balance-empty">Lade Daten...</div>
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
          <h3 class="dashboard-balance-title">Hybrid Balance</h3>
          <p class="dashboard-balance-subtitle">Letzte 7 Tage</p>
        </div>
        <span class="material-symbols-rounded dashboard-balance-arrow">chevron_right</span>
      </div>
      <div class="dashboard-balance-bar" role="img" aria-label="Strength ${strengthPct} Prozent, Cardio ${cardioPct} Prozent">
        <div class="dashboard-balance-segment strength" style="width: ${strengthPct}%;"></div>
        <div class="dashboard-balance-segment cardio" style="width: ${cardioPct}%;"></div>
      </div>
      <div class="dashboard-balance-meta">
        <span>Strength ${formatDurationShort(balance.strengthSec)}</span>
        <span>Cardio ${formatDurationShort(balance.cardioSec)}</span>
      </div>
      <div class="dashboard-balance-context">${balance.contextLabel}</div>
    </div>
  `;
}

function renderRecentSessionsList(state) {
  const container = document.getElementById('recent-sessions-card');
  if (!container) return;

  if (state.loading) {
    container.innerHTML = `
      <div class="dashboard-recent-header">
        <h3 class="dashboard-recent-title">Letzte Sessions</h3>
      </div>
      <div class="dashboard-recent-empty">Lade Daten...</div>
    `;
    return;
  }

  if (!state.recentSessions.length) {
    container.innerHTML = `
      <div class="dashboard-recent-header">
        <h3 class="dashboard-recent-title">Letzte Sessions</h3>
      </div>
      <div class="dashboard-recent-empty">Noch keine Sessions</div>
    `;
    return;
  }

  const rows = state.recentSessions.map(session => {
    const date = getSessionDate(session);
    const duration = formatDurationShort(getSessionDurationSeconds(session));
    const typeLabel = session.type === 'cardio'
      ? 'Cardio'
      : session.type === 'recovery'
        ? 'Recovery'
        : 'Strength';
    const distance = session.type === 'cardio' && session.distanceKm ? ` | ${Number(session.distanceKm).toFixed(1)} km` : '';

    const sessionId = session.id || '';
    return `
      <button class="dashboard-session-item" type="button" onclick="openSessionDetail('${sessionId}')">
        <div class="dashboard-session-main">
          <div class="dashboard-session-type ${session.type === 'cardio' ? 'cardio' : session.type === 'recovery' ? 'recovery' : 'strength'}">${typeLabel}</div>
          <div class="dashboard-session-date">${formatSessionDateTime(date)}</div>
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
      <h3 class="dashboard-recent-title">Letzte Sessions</h3>
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
  renderPrimaryActionCard(data);
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
  await refreshDashboard();
  console.log('Dashboard initialized!');
}

// Expose functions
window.refreshDashboard = refreshDashboard;
window.openStartWorkoutSheet = openStartWorkoutSheet;
window.startManualWorkout = startManualWorkout;
window.resumeWorkoutFromDashboard = resumeWorkoutFromDashboard;

// ========================================
// AUTO-INITIALIZE
// ========================================

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDashboard);
} else {
  initDashboard();
}
