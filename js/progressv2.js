// ========================================
// PROGRESS V2 - HYBRID TRACKING (STRENGTH + CARDIO)
// ========================================

let exercisesData = [];
let exercisesLoaded = false;
let recentWorkoutsExpanded = false;
let currentOverviewPeriod = 7;
let strengthPeriod = 8; // weeks for strength tab
let cardioPeriod = 8; // weeks for cardio tab
let activityCalendarDate = new Date(); // Current displayed month for activity calendar

// ==================== INIT ====================

/**
 * Initialisiert die neue Progress-Seite
 */
async function initProgressV2() {
  console.log('📊 Initializing Progress V2...');

  showProgressLoading();

  // Load data
  await Promise.all([
    loadSessions(),
    loadExercisesForProgressV2()
  ]);

  // Load last used tab
  const lastTab = loadLastProgressTab();

  // Render segmented control
  renderSegmentedControl(lastTab);

  // Render selected tab
  switchProgressTab(lastTab);

  hideProgressLoading();
}

/**
 * Lädt Exercises für Progress
 */
async function loadExercisesForProgressV2() {
  try {
    exercisesData = await getAllDocs(exercisesCollection);
    exercisesLoaded = true;
    console.log(`✅ Loaded ${exercisesData.length} exercises`);
    return exercisesData;
  } catch (error) {
    console.error('❌ Error loading exercises:', error);
    exercisesLoaded = false;
    return [];
  }
}

// ==================== SEGMENTED CONTROL ====================

/**
 * Rendert Segmented Control
 */
function renderSegmentedControl(activeTab = 'overview') {
  const container = document.getElementById('progress-segmented-control');
  if (!container) return;

  container.innerHTML = `
    <div class="segmented-control">
      <button
        class="segmented-btn ${activeTab === 'overview' ? 'active' : ''}"
        onclick="switchProgressTab('overview')"
        data-tab="overview"
      >
        <span class="material-symbols-rounded">insights</span>
        <span>Übersicht</span>
      </button>
      <button
        class="segmented-btn ${activeTab === 'strength' ? 'active' : ''}"
        onclick="switchProgressTab('strength')"
        data-tab="strength"
      >
        <span class="material-symbols-rounded">fitness_center</span>
        <span>Kraft</span>
      </button>
      <button
        class="segmented-btn ${activeTab === 'cardio' ? 'active' : ''}"
        onclick="switchProgressTab('cardio')"
        data-tab="cardio"
      >
        <span class="material-symbols-rounded">directions_run</span>
        <span>Cardio</span>
      </button>
    </div>
  `;
}

/**
 * Wechselt zwischen Progress Tabs
 */
function switchProgressTab(tab) {
  console.log('📊 Switching to tab:', tab);

  // Update active state
  document.querySelectorAll('#progress-segmented-control .segmented-btn').forEach(btn => {
    if (btn.dataset.tab === tab) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  // Save to localStorage
  saveLastProgressTab(tab);

  // Render tab content
  renderCurrentProgressTab();

  triggerHapticFeedback('light');
}

/**
 * Rendert aktuellen Tab
 */
function renderCurrentProgressTab() {
  const tab = currentProgressTab;

  if (tab === 'overview') {
    renderOverviewTab();
  } else if (tab === 'strength') {
    renderStrengthTab();
  } else if (tab === 'cardio') {
    renderCardioTab();
  }
}

// ==================== OVERVIEW TAB ====================

function renderOverviewTab() {
  const container = document.getElementById('progress-tab-content');
  if (!container) return;

  if (!sessionsLoaded) {
    container.innerHTML = `
      <div class="progress-loading">
        <div class="spinner"></div>
        <p>Lade Daten...</p>
      </div>
    `;
    return;
  }

  if (allSessions.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-state">
        <span class="material-symbols-rounded progress-empty-icon">insights</span>
        <h3>Noch keine Trainings</h3>
        <p>Starte dein erstes Training oder logge eine Session, um deinen Fortschritt zu sehen</p>
        <div class="progress-empty-actions">
          <button onclick="openAddCardioModal()" class="progress-cta-btn primary">
            <span class="material-symbols-rounded">directions_run</span>
            <span>Cardio Session hinzufügen</span>
          </button>
          <button onclick="openAddRecoveryModal()" class="progress-cta-btn secondary">
            <span class="material-symbols-rounded">self_improvement</span>
            <span>Recovery Session hinzufuegen</span>
          </button>
        </div>
      </div>
    `;
    return;
  }

  // Calculate stats
  const currentStats = calculateOverviewStats(currentOverviewPeriod);

  container.innerHTML = `
    <div class="overview-section">
      <div class="overview-period-selector">
        <button class="period-btn ${currentOverviewPeriod === 7 ? 'active' : ''}" onclick="switchOverviewPeriod(7)" data-period="7">
          7 Tage
        </button>
        <button class="period-btn ${currentOverviewPeriod === 30 ? 'active' : ''}" onclick="switchOverviewPeriod(30)" data-period="30">
          30 Tage
        </button>
      </div>

      <div id="overview-stats-container">
        ${renderOverviewStatsHTML(currentStats)}
      </div>

      ${renderHybridBalanceHTML()}

      <!-- Activity Calendar -->
      <div id="activity-calendar-container" class="activity-calendar-section">
        ${renderActivityCalendarHTML()}
      </div>

      <div class="progress-empty-actions">
        <button onclick="openAddCardioModal()" class="progress-cta-btn secondary">
          <span class="material-symbols-rounded">directions_run</span>
          <span>Cardio Session</span>
        </button>
        <button onclick="openAddRecoveryModal()" class="progress-cta-btn secondary">
          <span class="material-symbols-rounded">self_improvement</span>
          <span>Recovery Session</span>
        </button>
      </div>

      ${renderRecentWorkoutsHTML()}
    </div>
  `;
}

function renderOverviewStatsHTML(stats) {
  return `
    <div class="overview-stats-grid">
      <div class="overview-stat-card">
        <div class="stat-icon" style="background: color-mix(in srgb, var(--color-category-strength) 20%, transparent);">
          <span class="material-symbols-rounded" style="color: var(--color-category-strength);">fitness_center</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">Kraft-Sessions</p>
          <p class="stat-value">${stats.strengthCount}</p>
        </div>
      </div>

      <div class="overview-stat-card">
        <div class="stat-icon" style="background: color-mix(in srgb, var(--color-category-cardio) 20%, transparent);">
          <span class="material-symbols-rounded" style="color: var(--color-category-cardio);">directions_run</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">Cardio-Sessions</p>
          <p class="stat-value">${stats.cardioCount}</p>
        </div>
      </div>

      <div class="overview-stat-card">
        <div class="stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">schedule</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">Trainingszeit</p>
          <p class="stat-value">${formatDuration(stats.totalTime)}</p>
        </div>
      </div>

      <div class="overview-stat-card">
        <div class="stat-icon" style="background: rgba(168, 85, 247, 0.1);">
          <span class="material-symbols-rounded" style="color: #a855f7;">local_fire_department</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">Streak</p>
          <p class="stat-value">${stats.streak} Tage</p>
        </div>
      </div>
    </div>
  `;
}

function switchOverviewPeriod(days) {
  currentOverviewPeriod = days;
  const stats = calculateOverviewStats(days);
  const container = document.getElementById('overview-stats-container');
  if (container) {
    container.innerHTML = renderOverviewStatsHTML(stats);
  }

  // Update active button
  document.querySelectorAll('.period-btn').forEach(btn => {
    if (parseInt(btn.dataset.period) === days) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  // Update hybrid balance
  const balanceContainer = document.querySelector('.hybrid-balance-card');
  if (balanceContainer) {
    balanceContainer.outerHTML = renderHybridBalanceHTML();
  }
}

function renderHybridBalanceHTML() {
  if (typeof computeHybridBalance !== 'function') return '';

  const days = currentOverviewPeriod >= 30 ? 28 : 14;
  const balance = computeHybridBalance(days);

  if (balance.status === 'empty') {
    return `
      <div class="hybrid-balance-card">
        <div class="hybrid-balance-header">
          <div>
            <h3 class="hybrid-balance-title">Hybrid Balance</h3>
            <p class="hybrid-balance-subtitle">Letzte ${days} Tage</p>
          </div>
        </div>
        <div class="hybrid-balance-empty">Noch keine Daten fuer Hybrid Balance</div>
      </div>
    `;
  }

  return `
    <div class="hybrid-balance-card">
      <div class="hybrid-balance-header">
        <div>
          <h3 class="hybrid-balance-title">Hybrid Balance</h3>
          <p class="hybrid-balance-subtitle">Letzte ${days} Tage</p>
        </div>
        <div class="hybrid-balance-label">${balance.label}</div>
      </div>
      <div class="hybrid-balance-bar" role="img" aria-label="Strength ${balance.strengthPct} Prozent, Cardio ${balance.cardioPct} Prozent">
        <div class="hybrid-balance-segment strength" style="width: ${balance.strengthPct}%"></div>
        <div class="hybrid-balance-segment cardio" style="width: ${balance.cardioPct}%"></div>
      </div>
      <div class="hybrid-balance-meta">
        <span>Strength ${balance.strengthPct}%</span>
        <span>Cardio ${balance.cardioPct}%</span>
      </div>
    </div>
  `;
}

function renderRecentWorkoutsHTML() {
  const sortedSessions = [...allSessions].sort((a, b) => {
    const dateA = getSessionDate(a);
    const dateB = getSessionDate(b);
    return dateB - dateA;
  });

  const visibleSessions = recentWorkoutsExpanded ? sortedSessions : sortedSessions.slice(0, 3);
  const hasMore = sortedSessions.length > 3;

  const listHTML = visibleSessions.length === 0
    ? `
      <div class="recent-workouts-empty">
        <span class="material-symbols-rounded">history</span>
        <p>Noch keine getrackten Workouts</p>
      </div>
    `
    : visibleSessions.map((session) => {
      const icon = getSessionIcon(session);
      const color = getSessionColor(session);
      const title = getSessionTitle(session);
      const date = getSessionDate(session);
      const duration = session.duration ? formatDuration(session.duration) : 'Dauer n/a';

      return `
        <div class="recent-workout-card" onclick="openRecentWorkoutModal('${session.id}')">
          <div class="workout-card-icon" style="background: color-mix(in srgb, ${color} 20%, transparent);">
            <span class="material-symbols-rounded" style="color: ${color};">${icon}</span>
          </div>
          <div class="workout-card-content">
            <div class="workout-card-title">${title}</div>
            <div class="workout-card-meta">${formatShortDate(date)} · ${duration}</div>
          </div>
        </div>
      `;
    }).join('');

  return `
    <div class="recent-workouts-section">
      <div class="flex items-center justify-between mb-4">
        <h3 class="section-subtitle">Zuletzt getrackte Workouts</h3>
        ${hasMore ? `
          <button class="recent-workouts-toggle" onclick="toggleRecentWorkouts()">
            <span>${recentWorkoutsExpanded ? 'Weniger anzeigen' : 'Alle anzeigen'}</span>
            <span class="material-symbols-rounded" style="transform: ${recentWorkoutsExpanded ? 'rotate(180deg)' : 'none'};">expand_more</span>
          </button>
        ` : ''}
      </div>
      <div>
        ${listHTML}
      </div>
    </div>
  `;
}

function toggleRecentWorkouts() {
  recentWorkoutsExpanded = !recentWorkoutsExpanded;
  renderOverviewTab();
}

function getSessionDate(session) {
  if (session?.date?.toDate) {
    return session.date.toDate();
  }
  return new Date(session.date);
}

function getCategoryColorVar(type) {
  if (type === 'cardio') return 'var(--color-category-cardio)';
  if (type === 'recovery') return 'var(--color-category-recovery)';
  return 'var(--color-category-strength)';
}

function getCategoryColorValue(type) {
  const varName = type === 'cardio'
    ? '--color-category-cardio'
    : type === 'recovery'
      ? '--color-category-recovery'
      : '--color-category-strength';
  return getComputedStyle(document.documentElement).getPropertyValue(varName).trim() || '#ffffff';
}

function getSessionTitle(session) {
  if (session.type === 'cardio') {
    return ACTIVITY_TYPES[session.activityType]?.name || 'Cardio';
  }
  if (session.type === 'recovery') {
    return 'Recovery';
  }
  return session.planName || 'Krafttraining';
}

function getSessionIcon(session) {
  if (session.type === 'cardio') {
    return ACTIVITY_TYPES[session.activityType]?.icon || 'directions_run';
  }
  if (session.type === 'recovery') {
    return 'self_improvement';
  }
  return 'fitness_center';
}

function getSessionColor(session) {
  if (session.type === 'cardio') {
    return getCategoryColorVar('cardio');
  }
  if (session.type === 'recovery') {
    return getCategoryColorVar('recovery');
  }
  return getCategoryColorVar('strength');
}

function openRecentWorkoutModal(sessionId) {
  const session = allSessions.find((s) => s.id === sessionId);
  if (!session) {
    showErrorMessage('Workout nicht gefunden');
    return;
  }

  const date = getSessionDate(session);
  const duration = session.duration ? formatDuration(session.duration) : 'Dauer n/a';
  const title = getSessionTitle(session);

  const summary = session.type === 'cardio'
    ? renderCardioSummary(session)
    : session.type === 'recovery'
      ? renderRecoverySummary(session)
      : renderStrengthSummary(session);

  const content = `
    <div class="workout-detail-modal">
      <div class="workout-detail-header">
        <div class="workout-type-badge type-${session.type}">
          ${session.type === 'cardio' ? 'Cardio' : session.type === 'recovery' ? 'Recovery' : 'Kraft'}
        </div>
        <div class="workout-date" style="font-size: 0.875rem; color: #9ca3af;">
          ${formatFullDateDisplay(date)}
        </div>
      </div>

      <div class="workout-stats-grid">
        <div class="workout-stat">
          <span class="material-symbols-rounded">schedule</span>
          <div class="workout-stat-value">${duration}</div>
          <div class="workout-stat-label">Dauer</div>
        </div>
        ${summary}
      </div>

      <div class="workout-modal-actions">
        <button onclick="startWorkoutAgainFromSession('${session.id}')" class="btn-primary">
          <span class="material-symbols-rounded">play_arrow</span>
          <span>Erneut starten</span>
        </button>
        <button onclick="viewWorkoutDetailsFromSession('${session.id}')" class="btn-secondary">
          <span class="material-symbols-rounded">info</span>
          <span>Details ansehen</span>
        </button>
        <button onclick="deleteSessionWithReferences('${session.id}')" class="btn-danger">
          <span class="material-symbols-rounded">delete</span>
          <span>Loeschen</span>
        </button>
      </div>
    </div>
  `;

  if (typeof openGenericModal === 'function') {
    openGenericModal(title, content);
  } else {
    if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Modal nicht verfuegbar');
  }
  }
}

function renderStrengthSummary(session) {
  const exerciseCount = session.exercises?.length || 0;
  const totalSets = session.exercises?.reduce((sum, ex) => sum + (ex.sets?.length || 0), 0) || 0;
  const totalReps = session.exercises?.reduce((sum, ex) => {
    const reps = ex.sets?.reduce((setSum, set) => setSum + (set.reps || 0), 0) || 0;
    return sum + reps;
  }, 0) || 0;

  return `
    <div class="workout-stat">
      <span class="material-symbols-rounded">fitness_center</span>
      <div class="workout-stat-value">${exerciseCount}</div>
      <div class="workout-stat-label">Uebungen</div>
    </div>
    <div class="workout-stat">
      <span class="material-symbols-rounded">repeat</span>
      <div class="workout-stat-value">${totalSets}</div>
      <div class="workout-stat-label">Saetze</div>
    </div>
    <div class="workout-stat">
      <span class="material-symbols-rounded">trending_up</span>
      <div class="workout-stat-value">${totalReps}</div>
      <div class="workout-stat-label">Reps</div>
    </div>
  `;
}

function renderRecoverySummary() {
  return '';
}

function renderCardioSummary(session) {
  const distance = session.distanceKm ? `${session.distanceKm} km` : '-';
  const pace = session.pace ? formatPace(session.pace) : '-';

  return `
    <div class="workout-stat">
      <span class="material-symbols-rounded">straighten</span>
      <div class="workout-stat-value">${distance}</div>
      <div class="workout-stat-label">Distanz</div>
    </div>
    <div class="workout-stat">
      <span class="material-symbols-rounded">speed</span>
      <div class="workout-stat-value">${pace}</div>
      <div class="workout-stat-label">Pace</div>
    </div>
    <div class="workout-stat">
      <span class="material-symbols-rounded">directions_run</span>
      <div class="workout-stat-value">${ACTIVITY_TYPES[session.activityType]?.name || 'Cardio'}</div>
      <div class="workout-stat-label">Typ</div>
    </div>
  `;
}

function startWorkoutAgainFromSession(sessionId) {
  const session = allSessions.find((s) => s.id === sessionId);
  if (!session) {
    showErrorMessage('Workout nicht gefunden');
    return;
  }

  if (typeof closeGenericModal === 'function') {
    closeGenericModal();
  }

  if (session.type === 'cardio') {
    prefillCardioFromSession(session);
    return;
  }
  if (session.type === 'recovery') {
    prefillRecoveryFromSession(session);
    return;
  }

  if (typeof startWorkoutFromSession === 'function') {
    startWorkoutFromSession(sessionId);
  } else {
    showErrorMessage('Workout-Engine nicht geladen');
  }
}

function viewWorkoutDetailsFromSession(sessionId) {
  const session = allSessions.find((s) => s.id === sessionId);
  if (!session) {
    showErrorMessage('Workout nicht gefunden');
    return;
  }

  if (typeof closeGenericModal === 'function') {
    closeGenericModal();
  }

  if (session.type === 'cardio') {
    openCardioDetailModal(session);
    return;
  }
  if (session.type === 'recovery') {
    openRecoveryDetailModal(session);
    return;
  }

  if (typeof openWorkoutDetailModal === 'function') {
    openWorkoutDetailModal(sessionId);
  } else {
    showErrorMessage('Detailansicht nicht verfuegbar');
  }
}

function openCardioDetailModal(session) {
  const date = getSessionDate(session);
  const duration = session.duration ? formatDuration(session.duration) : 'Dauer n/a';
  const distance = session.distanceKm ? `${session.distanceKm} km` : '-';
  const pace = session.pace ? formatPace(session.pace) : '-';
  const activity = ACTIVITY_TYPES[session.activityType]?.name || 'Cardio';

  const content = `
    <div class="workout-detail-modal">
      <div class="workout-detail-header">
        <div class="workout-type-badge type-cardio">Cardio</div>
        <div class="workout-date" style="font-size: 0.875rem; color: #9ca3af;">
          ${formatFullDateDisplay(date)}
        </div>
      </div>
      <div class="workout-stats-grid">
        <div class="workout-stat">
          <span class="material-symbols-rounded">schedule</span>
          <div class="workout-stat-value">${duration}</div>
          <div class="workout-stat-label">Dauer</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">straighten</span>
          <div class="workout-stat-value">${distance}</div>
          <div class="workout-stat-label">Distanz</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">speed</span>
          <div class="workout-stat-value">${pace}</div>
          <div class="workout-stat-label">Pace</div>
        </div>
      </div>
      <div class="workout-exercises">
        <h4 class="workout-section-title">Aktivitaet</h4>
        <p class="text-sm text-gray-300">${activity}</p>
      </div>
      ${session.notes ? `
        <div class="workout-exercises">
          <h4 class="workout-section-title">Notizen</h4>
          <p class="text-sm text-gray-300">${session.notes}</p>
        </div>
      ` : ''}
      <div class="workout-modal-actions">
        <button onclick="startWorkoutAgainFromSession('${session.id}')" class="btn-primary">
          <span class="material-symbols-rounded">play_arrow</span>
          <span>Erneut starten</span>
        </button>
        <button onclick="closeGenericModal()" class="btn-secondary">
          <span class="material-symbols-rounded">close</span>
          <span>Schliessen</span>
        </button>
      </div>
    </div>
  `;

  if (typeof openGenericModal === 'function') {
    openGenericModal(activity, content);
  } else {
    if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Modal nicht verfuegbar');
  }
  }
}

function openRecoveryDetailModal(session) {
  const date = getSessionDate(session);
  const duration = session.duration ? formatDuration(session.duration) : 'Dauer n/a';
  const notes = session.notes ? session.notes : '-';

  const content = `
    <div class="workout-detail-modal">
      <div class="workout-detail-header">
        <div class="workout-type-badge type-recovery">Recovery</div>
        <div class="workout-date" style="font-size: 0.875rem; color: #9ca3af;">
          ${formatFullDateDisplay(date)}
        </div>
      </div>
      <div class="workout-stats-grid">
        <div class="workout-stat">
          <span class="material-symbols-rounded">schedule</span>
          <div class="workout-stat-value">${duration}</div>
          <div class="workout-stat-label">Dauer</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">notes</span>
          <div class="workout-stat-value">${notes}</div>
          <div class="workout-stat-label">Notizen</div>
        </div>
      </div>
    </div>
  `;

  if (typeof openGenericModal === 'function') {
    openGenericModal('Recovery', content);
  } else {
    showErrorMessage('Modal nicht verfuegbar');
  }
}

function prefillCardioFromSession(session) {
  if (typeof openAddCardioModal !== 'function') {
    showErrorMessage('Cardio-Modal nicht verfuegbar');
    return;
  }

  openAddCardioModal();

  setTimeout(() => {
    const activityInput = document.getElementById('cardio-activity-type');
    const durationInput = document.getElementById('cardio-duration');
    const distanceInput = document.getElementById('cardio-distance');
    const notesInput = document.getElementById('cardio-notes');

    if (activityInput) activityInput.value = session.activityType || 'run';
    if (durationInput) durationInput.value = session.duration || '';
    if (distanceInput) distanceInput.value = session.distanceKm || '';
    if (notesInput) notesInput.value = session.notes || '';

    if (typeof updateCardioLivePace === 'function') {
      updateCardioLivePace();
    }
  }, 0);
}

function formatFullDateDisplay(date) {
  const days = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
  const months = ['Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
  const dayName = days[date.getDay()];
  return `${dayName}, ${date.getDate()}. ${months[date.getMonth()]} ${date.getFullYear()}`;
}

async function deleteSessionWithReferences(sessionId) {
  if (!confirm('Dieses Workout wirklich loeschen? Diese Aktion kann nicht rueckgaengig gemacht werden.')) {
    return;
  }

  const session = allSessions.find((s) => s.id === sessionId);
  if (!session) {
    showErrorMessage('Workout nicht gefunden');
    return;
  }

  try {
    await deleteDoc(sessionsCollection, sessionId);

    if (session.scheduleId) {
      const updatePayload = {
        completed: false,
        completedAt: null,
        sessionId: null
      };
      try {
        await updateDoc(scheduleCollection, session.scheduleId, updatePayload);
      } catch (error) {
        console.error('❌ Error clearing schedule reference:', error);
      }
    }

    if (typeof closeGenericModal === 'function') {
      closeGenericModal();
    }

    await loadSessions();
    renderCurrentProgressTab();
    triggerSuccessGlow();
  } catch (error) {
    console.error('❌ Error deleting session:', error);
    showErrorMessage('Fehler beim Loeschen: ' + error.message);
  }
}

// ==================== STRENGTH TAB ====================

function renderStrengthTab() {
  const container = document.getElementById('progress-tab-content');
  if (!container) return;

  if (!sessionsLoaded) {
    container.innerHTML = `
      <div class="progress-loading">
        <div class="spinner"></div>
        <p>Lade Daten...</p>
      </div>
    `;
    return;
  }

  const strengthSessions = allSessions.filter(s => s.type === 'strength');

  if (strengthSessions.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-state">
        <span class="material-symbols-rounded progress-empty-icon">fitness_center</span>
        <h3>Noch keine Kraft-Trainings</h3>
        <p>Starte ein Training im Workout-Bereich, um deinen Fortschritt zu tracken</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="strength-section">
      <!-- Period Toggle -->
      <div class="metric-toggle">
        <button
          class="metric-btn ${strengthPeriod === 8 ? 'active' : ''}"
          onclick="switchStrengthPeriod(8)"
        >
          8 Wochen
        </button>
        <button
          class="metric-btn ${strengthPeriod === 12 ? 'active' : ''}"
          onclick="switchStrengthPeriod(12)"
        >
          12 Wochen
        </button>
      </div>

      <!-- Stats -->
      <div id="strength-stats-container"></div>

      <!-- Chart -->
      <div id="strength-chart-container" class="progress-chart-container"></div>
    </div>
  `;

  renderStrengthStats();
  renderStrengthChart();
}

function switchStrengthPeriod(weeks) {
  strengthPeriod = weeks;
  renderStrengthTab();
  triggerHapticFeedback('light');
}

function renderStrengthStats() {
  const container = document.getElementById('strength-stats-container');
  if (!container) return;

  const data = aggregateWeeklyStrengthVolume(strengthPeriod);
  const stats = calculateWeeklyStats(data);

  container.innerHTML = `
    <div class="progress-stats-grid">
      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(240, 34, 119, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-primary);">trending_up</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Letzte Woche</p>
          <p class="progress-stat-value">${formatVolume(stats.lastValue)}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">emoji_events</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Beste Woche</p>
          <p class="progress-stat-value">${formatVolume(stats.bestValue)}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(59, 130, 246, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-category-strength);">analytics</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Durchschnitt</p>
          <p class="progress-stat-value">${formatVolume(stats.avgValue)}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(168, 85, 247, 0.1);">
          <span class="material-symbols-rounded" style="color: #a855f7;">calendar_month</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Sessions</p>
          <p class="progress-stat-value">${stats.totalSessions}</p>
        </div>
      </div>
    </div>
  `;
}

/**
 * Berechnet Stats fuer woechentliche Daten
 */
function calculateWeeklyStats(weeklyData) {
  if (!weeklyData || weeklyData.length === 0) {
    return { lastValue: 0, bestValue: 0, avgValue: 0, totalSessions: 0 };
  }

  const values = weeklyData.map(d => d.value);
  const lastValue = values[values.length - 1] || 0;
  const bestValue = Math.max(...values);

  // Only average weeks with data
  const nonZeroValues = values.filter(v => v > 0);
  const avgValue = nonZeroValues.length > 0
    ? Math.round(nonZeroValues.reduce((sum, v) => sum + v, 0) / nonZeroValues.length)
    : 0;

  const totalSessions = weeklyData.reduce((sum, d) => sum + d.sessionCount, 0);

  return { lastValue, bestValue, avgValue, totalSessions };
}

/**
 * Formatiert Volumen mit Tausendertrennzeichen
 */
function formatVolume(value) {
  if (value >= 1000) {
    return (value / 1000).toFixed(1).replace('.', ',') + 'k';
  }
  return value.toString();
}

function renderStrengthChart() {
  const container = document.getElementById('strength-chart-container');
  if (!container) return;

  const data = aggregateWeeklyStrengthVolume(strengthPeriod);

  // Check if there's any data
  const hasData = data.some(d => d.value > 0);

  if (!hasData) {
    container.innerHTML = `
      <div class="progress-empty-chart">
        <span class="material-symbols-rounded">insert_chart</span>
        <p>Noch keine Daten fuer diesen Zeitraum</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="progress-chart-header">
      <h3 class="progress-chart-title">Kraft-Volumen - Letzte ${strengthPeriod} Wochen</h3>
    </div>
    <div class="progress-chart-canvas-wrapper">
      <canvas id="progress-chart-canvas"></canvas>
    </div>
  `;

  animateChartContainer(container);
  drawWeeklyChart(data);
}

/**
 * Zeichnet Chart fuer woechentliche Daten
 */
function drawWeeklyChart(data) {
  const canvas = document.getElementById('progress-chart-canvas');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;

  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);

  const width = rect.width;
  const height = rect.height;

  const padding = { top: 20, right: 20, bottom: 40, left: 50 };
  const chartWidth = width - padding.left - padding.right;
  const chartHeight = height - padding.top - padding.bottom;

  const values = data.map(d => d.value);
  const maxValue = Math.max(...values) || 1;
  const minValue = 0; // Start from 0 for volume charts

  ctx.clearRect(0, 0, width, height);

  // Colors
  const gridColor = 'rgba(75, 85, 99, 0.3)';
  const textColor = '#9ca3af';
  const lineColor = getCategoryColorValue('strength');

  // Grid
  ctx.strokeStyle = gridColor;
  ctx.lineWidth = 1;
  for (let i = 0; i <= 5; i++) {
    const y = padding.top + (chartHeight / 5) * i;
    ctx.beginPath();
    ctx.moveTo(padding.left, y);
    ctx.lineTo(padding.left + chartWidth, y);
    ctx.stroke();
  }

  // Y-axis labels
  ctx.fillStyle = textColor;
  ctx.font = '11px Inter, sans-serif';
  ctx.textAlign = 'right';
  ctx.textBaseline = 'middle';
  for (let i = 0; i <= 5; i++) {
    const value = Math.round(maxValue - (maxValue / 5) * i);
    const y = padding.top + (chartHeight / 5) * i;
    ctx.fillText(formatVolume(value), padding.left - 10, y);
  }

  // Points
  const points = data.map((d, i) => {
    const x = padding.left + (chartWidth / (data.length - 1 || 1)) * i;
    const y = padding.top + chartHeight - ((d.value - minValue) / (maxValue - minValue || 1)) * chartHeight;
    return { x, y, value: d.value, label: d.weekLabel };
  });

  // Line
  ctx.strokeStyle = lineColor;
  ctx.lineWidth = 3;
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';

  ctx.beginPath();
  points.forEach((point, i) => {
    if (i === 0) {
      ctx.moveTo(point.x, point.y);
    } else {
      ctx.lineTo(point.x, point.y);
    }
  });
  ctx.stroke();

  // Points
  points.forEach(point => {
    ctx.beginPath();
    ctx.arc(point.x, point.y, 6, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(240, 34, 119, 0.2)';
    ctx.fill();

    ctx.beginPath();
    ctx.arc(point.x, point.y, 4, 0, Math.PI * 2);
    ctx.fillStyle = lineColor;
    ctx.fill();
  });

  // X-axis labels (week labels)
  ctx.fillStyle = textColor;
  ctx.font = '10px Inter, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';

  const labelStep = Math.ceil(data.length / 6);
  data.forEach((d, i) => {
    if (i % labelStep === 0 || i === data.length - 1) {
      const point = points[i];
      ctx.fillText(d.weekLabel, point.x, padding.top + chartHeight + 10);
    }
  });
}

// ==================== CARDIO TAB ====================

function renderCardioTab() {
  const container = document.getElementById('progress-tab-content');
  if (!container) return;

  if (!sessionsLoaded) {
    container.innerHTML = `
      <div class="progress-loading">
        <div class="spinner"></div>
        <p>Lade Daten...</p>
      </div>
    `;
    return;
  }

  const cardioSessions = allSessions.filter(s => s.type === 'cardio');

  if (cardioSessions.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-state">
        <span class="material-symbols-rounded progress-empty-icon">directions_run</span>
        <h3>Noch keine Cardio-Sessions</h3>
        <p>Logge deine erste Cardio-Session, um deinen Fortschritt zu sehen</p>
        <button onclick="openAddCardioModal()" class="progress-cta-btn primary">
          <span class="material-symbols-rounded">add</span>
          <span>Cardio Session hinzufuegen</span>
        </button>
      </div>
    `;
    return;
  }

  // Select default activity if none selected
  if (!selectedActivityType) {
    selectedActivityType = 'run';
  }

  container.innerHTML = `
    <div class="cardio-section">
      <!-- Activity Picker -->
      <div class="activity-picker-compact">
        <button onclick="openActivityPickerSheet()" class="activity-picker-btn">
          <span class="material-symbols-rounded">${ACTIVITY_TYPES[selectedActivityType].icon}</span>
          <span id="selected-activity-name">${ACTIVITY_TYPES[selectedActivityType].name}</span>
          <span class="material-symbols-rounded">expand_more</span>
        </button>
      </div>

      <!-- Period Toggle -->
      <div class="metric-toggle" style="margin-bottom: 0.5rem;">
        <button
          class="metric-btn ${cardioPeriod === 8 ? 'active' : ''}"
          onclick="switchCardioPeriod(8)"
        >
          8 Wochen
        </button>
        <button
          class="metric-btn ${cardioPeriod === 12 ? 'active' : ''}"
          onclick="switchCardioPeriod(12)"
        >
          12 Wochen
        </button>
      </div>

      <!-- Metric Toggle -->
      <div class="metric-toggle">
        <button
          class="metric-btn ${cardioMetric === 'time' ? 'active' : ''}"
          onclick="switchCardioMetric('time')"
        >
          Zeit
        </button>
        <button
          class="metric-btn ${cardioMetric === 'distance' ? 'active' : ''}"
          onclick="switchCardioMetric('distance')"
        >
          Distanz
        </button>
      </div>

      <!-- Stats -->
      <div id="cardio-stats-container"></div>

      <!-- Chart -->
      <div id="cardio-chart-container" class="progress-chart-container"></div>

      <!-- Add Button -->
      <button onclick="openAddCardioModal()" class="floating-add-btn">
        <span class="material-symbols-rounded">add</span>
      </button>
    </div>
  `;

  renderCardioStats();
  renderCardioChart();
}

function switchCardioPeriod(weeks) {
  cardioPeriod = weeks;
  renderCardioTab();
  triggerHapticFeedback('light');
}

function switchCardioMetric(metric) {
  cardioMetric = metric;
  renderCardioTab();
  triggerHapticFeedback('light');
}

function renderCardioStats() {
  const container = document.getElementById('cardio-stats-container');
  if (!container) return;

  const data = aggregateWeeklyCardio(cardioMetric, cardioPeriod, selectedActivityType);
  const stats = calculateWeeklyStats(data);

  const metricLabel = cardioMetric === 'time' ? 'min' : 'km';

  container.innerHTML = `
    <div class="progress-stats-grid">
      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(59, 130, 246, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-category-cardio);">trending_up</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Letzte Woche</p>
          <p class="progress-stat-value">${stats.lastValue} ${metricLabel}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">emoji_events</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Beste Woche</p>
          <p class="progress-stat-value">${stats.bestValue} ${metricLabel}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(168, 85, 247, 0.1);">
          <span class="material-symbols-rounded" style="color: #a855f7;">analytics</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Durchschnitt</p>
          <p class="progress-stat-value">${stats.avgValue} ${metricLabel}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(240, 34, 119, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-primary);">calendar_month</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Sessions</p>
          <p class="progress-stat-value">${stats.totalSessions}</p>
        </div>
      </div>
    </div>
  `;
}

function renderCardioChart() {
  const container = document.getElementById('cardio-chart-container');
  if (!container) return;

  const data = aggregateWeeklyCardio(cardioMetric, cardioPeriod, selectedActivityType);

  // Check if there's any data
  const hasData = data.some(d => d.value > 0);

  if (!hasData) {
    container.innerHTML = `
      <div class="progress-empty-chart">
        <span class="material-symbols-rounded">insert_chart</span>
        <p>Noch keine Daten fuer diese Aktivitaet</p>
      </div>
    `;
    return;
  }

  const metricLabel = cardioMetric === 'time' ? 'Zeit (min)' : 'Distanz (km)';

  container.innerHTML = `
    <div class="progress-chart-header">
      <h3 class="progress-chart-title">${metricLabel} - Letzte ${cardioPeriod} Wochen</h3>
    </div>
    <div class="progress-chart-canvas-wrapper">
      <canvas id="progress-chart-canvas"></canvas>
    </div>
  `;

  animateChartContainer(container);
  drawWeeklyCardioChart(data, cardioMetric);
}

/**
 * Zeichnet Cardio Chart fuer woechentliche Daten
 */
function drawWeeklyCardioChart(data, metric) {
  const canvas = document.getElementById('progress-chart-canvas');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;

  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);

  const width = rect.width;
  const height = rect.height;

  const padding = { top: 20, right: 20, bottom: 40, left: 50 };
  const chartWidth = width - padding.left - padding.right;
  const chartHeight = height - padding.top - padding.bottom;

  const values = data.map(d => d.value);
  const maxValue = Math.max(...values) || 1;
  const minValue = 0;

  ctx.clearRect(0, 0, width, height);

  // Colors - Blue for cardio
  const gridColor = 'rgba(75, 85, 99, 0.3)';
  const textColor = '#9ca3af';
  const lineColor = getCategoryColorValue('cardio');

  // Grid
  ctx.strokeStyle = gridColor;
  ctx.lineWidth = 1;
  for (let i = 0; i <= 5; i++) {
    const y = padding.top + (chartHeight / 5) * i;
    ctx.beginPath();
    ctx.moveTo(padding.left, y);
    ctx.lineTo(padding.left + chartWidth, y);
    ctx.stroke();
  }

  // Y-axis labels
  ctx.fillStyle = textColor;
  ctx.font = '11px Inter, sans-serif';
  ctx.textAlign = 'right';
  ctx.textBaseline = 'middle';
  for (let i = 0; i <= 5; i++) {
    const value = Math.round(maxValue - (maxValue / 5) * i);
    const y = padding.top + (chartHeight / 5) * i;
    const label = metric === 'distance' ? value.toFixed(1) : value.toString();
    ctx.fillText(label, padding.left - 10, y);
  }

  // Points
  const points = data.map((d, i) => {
    const x = padding.left + (chartWidth / (data.length - 1 || 1)) * i;
    const y = padding.top + chartHeight - ((d.value - minValue) / (maxValue - minValue || 1)) * chartHeight;
    return { x, y, value: d.value, label: d.weekLabel };
  });

  // Line
  ctx.strokeStyle = lineColor;
  ctx.lineWidth = 3;
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';

  ctx.beginPath();
  points.forEach((point, i) => {
    if (i === 0) {
      ctx.moveTo(point.x, point.y);
    } else {
      ctx.lineTo(point.x, point.y);
    }
  });
  ctx.stroke();

  // Points
  points.forEach(point => {
    ctx.beginPath();
    ctx.arc(point.x, point.y, 6, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(59, 130, 246, 0.2)';
    ctx.fill();

    ctx.beginPath();
    ctx.arc(point.x, point.y, 4, 0, Math.PI * 2);
    ctx.fillStyle = lineColor;
    ctx.fill();
  });

  // X-axis labels
  ctx.fillStyle = textColor;
  ctx.font = '10px Inter, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';

  const labelStep = Math.ceil(data.length / 6);
  data.forEach((d, i) => {
    if (i % labelStep === 0 || i === data.length - 1) {
      const point = points[i];
      ctx.fillText(d.weekLabel, point.x, padding.top + chartHeight + 10);
    }
  });
}

// ==================== ACTIVITY CALENDAR ====================

const ACTIVITY_DOT_MAX = 3;

function getSessionDurationMinutes(session) {
  const raw = Number(session?.duration || 0);
  if (!Number.isFinite(raw) || raw < 0) return 0;
  return Math.round(raw);
}

function getDurationBucket(minutes) {
  if (minutes <= 20) return { size: 's', rank: 1 };
  if (minutes <= 40) return { size: 'm', rank: 2 };
  if (minutes <= 60) return { size: 'l', rank: 3 };
  if (minutes <= 90) return { size: 'xl', rank: 4 };
  return { size: 'xxl', rank: 5 };
}

function getSessionDotMeta(session) {
  const minutes = getSessionDurationMinutes(session);
  const bucket = getDurationBucket(minutes);
  return {
    type: session.type === 'cardio'
      ? 'cardio'
      : session.type === 'recovery'
        ? 'recovery'
        : 'strength',
    size: bucket.size,
    rank: bucket.rank,
    minutes
  };
}

function prefillRecoveryFromSession(session) {
  if (typeof openAddRecoveryModal !== 'function') {
    showErrorMessage('Recovery-Modal nicht verfuegbar');
    return;
  }

  const date = getSessionDate(session);
  const dateKey = typeof formatDateToYYYYMMDD === 'function'
    ? formatDateToYYYYMMDD(date)
    : null;

  openAddRecoveryModal(dateKey);

  setTimeout(() => {
    const durationInput = document.getElementById('recovery-duration');
    const notesInput = document.getElementById('recovery-notes');

    if (durationInput) durationInput.value = session.duration || '';
    if (notesInput) notesInput.value = session.notes || '';
  }, 0);
}

/**
 * Rendert den Activity Calendar HTML
 */
function renderActivityCalendarHTML() {
  const year = activityCalendarDate.getFullYear();
  const month = activityCalendarDate.getMonth();
  const sessionsByDate = getSessionsByDate(year, month);

  const monthNames = ['Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
  const dayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  return `
    <div class="activity-calendar">
      <div class="activity-calendar-header">
        <button onclick="navigateActivityCalendar('prev')" class="cal-nav-btn" aria-label="Vorheriger Monat">
          <span class="material-symbols-rounded">chevron_left</span>
        </button>
        <h3 class="activity-calendar-title">${monthNames[month]} ${year}</h3>
        <button onclick="navigateActivityCalendar('next')" class="cal-nav-btn" aria-label="Naechster Monat">
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
      </div>

      <div class="activity-calendar-weekdays">
        ${dayLabels.map(d => `<div class="weekday-label">${d}</div>`).join('')}
      </div>

      <div class="activity-calendar-grid" id="activity-calendar-grid">
        ${renderActivityCalendarDays(year, month, sessionsByDate)}
      </div>
    </div>
  `;
}

/**
 * Rendert die Tage des Activity Calendars
 */
function renderActivityCalendarDays(year, month, sessionsByDate) {
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Monday-based week start
  let startDay = firstDay.getDay();
  startDay = startDay === 0 ? 6 : startDay - 1;

  const daysInMonth = lastDay.getDate();
  let html = '';

  // Previous month days (greyed out)
  const prevMonthDays = new Date(year, month, 0).getDate();
  for (let i = startDay - 1; i >= 0; i--) {
    const day = prevMonthDays - i;
    html += `<div class="activity-day other-month"><span class="day-number">${day}</span></div>`;
  }

  // Current month days
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const dateKey = formatDateToYYYYMMDD(date);
    const isToday = date.toDateString() === today.toDateString();
    const sessions = sessionsByDate[dateKey] || [];

    const dots = sessions
      .map(getSessionDotMeta)
      .sort((a, b) => {
        if (b.rank !== a.rank) return b.rank - a.rank;
        if (b.minutes !== a.minutes) return b.minutes - a.minutes;
        return a.type.localeCompare(b.type);
      });

    const visibleDots = dots.slice(0, ACTIVITY_DOT_MAX);
    const overflow = dots.length - visibleDots.length;

    const hasSessionsClass = sessions.length > 0 ? 'has-sessions' : '';
    const todayClass = isToday ? 'today' : '';

    html += `
      <div class="activity-day ${todayClass} ${hasSessionsClass}"
           onclick="openActivityDaySheet('${dateKey}')"
           role="button"
           tabindex="0"
           aria-label="${day}. ${sessions.length} Sessions">
        <span class="day-number">${day}</span>
        <div class="session-dots" aria-hidden="true">
          ${visibleDots.map(dot => `
            <span class="session-dot ${dot.type} size-${dot.size}" title="${dot.minutes} min"></span>
          `).join('')}
          ${overflow > 0 ? `<span class="session-overflow">+${overflow}</span>` : ''}
        </div>
      </div>
    `;
  }

  // Next month days (fill grid to 42 cells for 6 rows)
  const totalCells = startDay + daysInMonth;
  const remaining = totalCells <= 35 ? 35 - totalCells : 42 - totalCells;
  for (let day = 1; day <= remaining; day++) {
    html += `<div class="activity-day other-month"><span class="day-number">${day}</span></div>`;
  }

  return html;
}

/**
 * Navigiert den Activity Calendar
 */
function navigateActivityCalendar(direction) {
  if (direction === 'prev') {
    activityCalendarDate.setMonth(activityCalendarDate.getMonth() - 1);
  } else {
    activityCalendarDate.setMonth(activityCalendarDate.getMonth() + 1);
  }

  // Re-render only the calendar section
  const container = document.getElementById('activity-calendar-container');
  if (container) {
    container.innerHTML = renderActivityCalendarHTML();
  }

  triggerHapticFeedback('light');
}

/**
 * Oeffnet das Day Detail Sheet
 */
function openActivityDaySheet(dateKey) {
  const sessions = getSessionsForDate(dateKey);
  const date = new Date(dateKey + 'T12:00:00');
  const dayNames = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
  const monthNames = ['Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

  const title = `${dayNames[date.getDay()]}, ${date.getDate()}. ${monthNames[date.getMonth()]}`;

  openSheet({
    title: title,
    render: (container) => {
      if (sessions.length === 0) {
        container.innerHTML = `
          <div class="activity-day-empty">
            <span class="material-symbols-rounded">event_busy</span>
            <p>Keine Sessions an diesem Tag</p>
          </div>
        `;
        return;
      }

      container.innerHTML = sessions.map(session => {
        const icon = getSessionIcon(session);
        const color = getSessionColor(session);
        const sessionTitle = getSessionTitle(session);
        const duration = session.duration ? formatDuration(session.duration) : 'Dauer n/a';

        return `
          <div class="activity-session-item">
            <div class="session-item-icon" style="background: color-mix(in srgb, ${color} 20%, transparent);">
              <span class="material-symbols-rounded" style="color: ${color};">${icon}</span>
            </div>
            <div class="session-item-content">
              <div class="session-item-title">${sessionTitle}</div>
              <div class="session-item-meta">${duration}</div>
            </div>
            <div class="session-item-actions">
              <button onclick="viewWorkoutDetailsFromSession('${session.id}'); closeSheet();" class="session-action-btn" aria-label="Ansehen">
                <span class="material-symbols-rounded">visibility</span>
              </button>
              <button onclick="deleteSessionFromCalendar('${session.id}', '${dateKey}')" class="session-action-btn danger" aria-label="Loeschen">
                <span class="material-symbols-rounded">delete</span>
              </button>
            </div>
          </div>
        `;
      }).join('');
    }
  });
}

/**
 * Loescht eine Session und aktualisiert den Kalender
 */
async function deleteSessionFromCalendar(sessionId, dateKey) {
  if (!confirm('Diese Session wirklich loeschen?')) {
    return;
  }

  try {
    await deleteDoc(sessionsCollection, sessionId);
    await loadSessions();

    // Refresh the day sheet
    openActivityDaySheet(dateKey);

    // Refresh the calendar
    const container = document.getElementById('activity-calendar-container');
    if (container) {
      container.innerHTML = renderActivityCalendarHTML();
    }

    triggerSuccessGlow();
  } catch (error) {
    console.error('Error deleting session:', error);
    showErrorMessage('Fehler beim Loeschen');
  }
}

// ==================== BOTTOM SHEETS ====================

let sheetRoot = null;
let sheetIsOpen = false;
let sheetCloseTimer = null;

function createSheetRoot() {
  if (sheetRoot) return sheetRoot;

  const root = document.createElement('div');
  root.id = 'sheet-root';
  root.innerHTML = `
    <div class="sheet__backdrop" data-sheet-backdrop></div>
    <div class="sheet__panel" role="dialog" aria-modal="true">
      <div class="sheet__header">
        <h3 class="sheet__title" id="sheet-title">Auswahl</h3>
        <button class="sheet__close" type="button" aria-label="Schliessen" data-sheet-close>
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
      <div class="sheet__content" id="sheet-content" role="list"></div>
    </div>
  `;

  document.body.appendChild(root);
  sheetRoot = root;

  const backdrop = root.querySelector('[data-sheet-backdrop]');
  const closeBtn = root.querySelector('[data-sheet-close]');
  const panel = root.querySelector('.sheet__panel');

  backdrop.addEventListener('click', () => closeSheet());
  closeBtn.addEventListener('click', () => closeSheet());
  panel.addEventListener('click', (event) => {
    event.stopPropagation();
  });

  return root;
}

function openSheet({ title, render, listRole = 'list' }) {
  if (sheetCloseTimer) {
    clearTimeout(sheetCloseTimer);
    sheetCloseTimer = null;
  }

  const root = createSheetRoot();
  const titleEl = root.querySelector('#sheet-title');
  const contentEl = root.querySelector('#sheet-content');

  if (titleEl) {
    titleEl.textContent = title || 'Auswahl';
  }

  if (contentEl) {
    contentEl.setAttribute('role', listRole);
    contentEl.innerHTML = '';
    if (typeof render === 'function') {
      render(contentEl);
    }
  }

  if (sheetIsOpen) return;

  sheetIsOpen = true;
  document.body.style.overflow = 'hidden';
  requestAnimationFrame(() => {
    root.classList.add('is-open');
  });
}

function closeSheet() {
  if (!sheetRoot || !sheetIsOpen) return;

  sheetIsOpen = false;
  sheetRoot.classList.remove('is-open');

  if (sheetCloseTimer) {
    clearTimeout(sheetCloseTimer);
  }

  sheetCloseTimer = setTimeout(() => {
    document.body.style.overflow = '';
    sheetCloseTimer = null;
  }, 220);
}

function openActivityPickerSheet() {
  openSheet({
    title: 'Aktivität auswählen',
    render: (container) => {
      const listHTML = Object.entries(ACTIVITY_TYPES)
        .map(([key, config]) => `
          <button
            class="picker-item ${key === selectedActivityType ? 'active' : ''}"
            onclick="selectActivity('${key}')"
            type="button"
          >
            <div class="picker-item-icon">
              <span class="material-symbols-rounded">${config.icon}</span>
            </div>
            <span>${config.name}</span>
            <span class="material-symbols-rounded">check</span>
          </button>
        `).join('');
      container.innerHTML = listHTML;
    }
  });
}

function closePickerSheet(sheetId) {
  closeSheet();
}

function closeAllPickerSheets() {
  closeSheet();
}

function selectActivity(activityType) {
  selectedActivityType = activityType;
  closeSheet();
  renderCardioTab();
}

// ==================== CHART DRAWING ====================

function animateChartContainer(container) {
  if (!container) return;

  container.classList.remove('chart-animating');
  void container.offsetWidth;
  container.classList.add('chart-animating');

  container.addEventListener('animationend', () => {
    container.classList.remove('chart-animating');
  }, { once: true });
}

// ==================== LOADING ====================

function showProgressLoading() {
  const content = document.getElementById('progress-tab-content');
  if (content) {
    content.innerHTML = `
      <div class="progress-loading">
        <div class="spinner"></div>
        <p>Lade Daten...</p>
      </div>
    `;
  }
}

function hideProgressLoading() {
  // Automatically replaced by tab content
}

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && sheetIsOpen) {
    closeSheet();
  }
});

// Expose functions
window.initProgressV2 = initProgressV2;
window.switchProgressTab = switchProgressTab;
window.switchStrengthPeriod = switchStrengthPeriod;
window.switchCardioPeriod = switchCardioPeriod;
window.switchCardioMetric = switchCardioMetric;
window.switchOverviewPeriod = switchOverviewPeriod;
window.openExercisePickerSheet = openExercisePickerSheet;
window.openActivityPickerSheet = openActivityPickerSheet;
window.closePickerSheet = closePickerSheet;
window.closeAllPickerSheets = closeAllPickerSheets;
window.openSheet = openSheet;
window.closeSheet = closeSheet;
window.selectExercise = selectExercise;
window.selectActivity = selectActivity;
window.toggleRecentWorkouts = toggleRecentWorkouts;
window.openRecentWorkoutModal = openRecentWorkoutModal;
window.startWorkoutAgainFromSession = startWorkoutAgainFromSession;
window.viewWorkoutDetailsFromSession = viewWorkoutDetailsFromSession;
window.deleteSessionWithReferences = deleteSessionWithReferences;
window.navigateActivityCalendar = navigateActivityCalendar;
window.openActivityDaySheet = openActivityDaySheet;
window.deleteSessionFromCalendar = deleteSessionFromCalendar;

console.log('📊 Progress V2 module loaded');
