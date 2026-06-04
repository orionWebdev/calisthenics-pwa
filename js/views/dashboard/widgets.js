// ========================================
// QUICK STATS WIDGET
// ========================================

function renderQuickStatsWidget(state) {
  const container = document.getElementById('dashboard-quick-stats');
  if (!container) return;

  if (state.loading) {
    container.innerHTML = `
      <div class="quick-stats-grid">
        <div class="quick-stats-card"><div class="quick-stats-skeleton"></div></div>
        <div class="quick-stats-card"><div class="quick-stats-skeleton"></div></div>
      </div>
    `;
    return;
  }

  const sessionsCount = state.sessionsThisWeekCount || 0;
  const movementMinutes = state.movementMinutesThisWeek || 0;

  container.innerHTML = `
    <div class="quick-stats-grid">
      <div class="quick-stats-card" style="--qs-delay:0ms">
        <div class="quick-stats-header">
          <span class="quick-stats-label">${tr('dashboard.quickStats.thisWeek')}</span>
          <span class="quick-stats-icon">
            <span class="material-symbols-rounded">fitness_center</span>
          </span>
        </div>
        <div class="quick-stats-value">${sessionsCount}</div>
        <div class="quick-stats-subtext">${tr('dashboard.quickStats.sessions')}</div>
      </div>
      <div class="quick-stats-card" style="--qs-delay:80ms">
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
        <div class="dashboard-balance-segment strength" style="width: ${strengthPct}%; --bar-delay:0ms;"></div>
        <div class="dashboard-balance-segment cardio" style="width: ${cardioPct}%; --bar-delay:120ms;"></div>
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

