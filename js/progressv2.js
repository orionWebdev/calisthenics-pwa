// ========================================
// PROGRESS V2 - HYBRID TRACKING (STRENGTH + CARDIO)
// ========================================

let exercisesData = [];
let exercisesLoaded = false;
let recentWorkoutsExpanded = false;
let currentOverviewPeriod = 7;
let currentOverviewMetric = 'strength';
let currentStrengthStat = 'last';
let currentCardioStat = 'last';

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
        <p>Starte dein erstes Training oder logge eine Cardio-Session, um deinen Fortschritt zu sehen</p>
        <div class="progress-empty-actions">
          <button onclick="openAddCardioModal()" class="progress-cta-btn primary">
            <span class="material-symbols-rounded">directions_run</span>
            <span>Cardio Session hinzufügen</span>
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

      <div id="overview-chart-container" class="progress-chart-container"></div>

      ${renderRecentWorkoutsHTML()}
    </div>
  `;

  renderOverviewChart();
}

function renderOverviewStatsHTML(stats) {
  return `
    <div class="overview-stats-grid">
      <div class="overview-stat-card ${currentOverviewMetric === 'strength' ? 'active' : ''}" onclick="selectOverviewMetric('strength')">
        <div class="stat-icon" style="background: rgba(240, 34, 119, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-primary);">fitness_center</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">Kraft-Sessions</p>
          <p class="stat-value">${stats.strengthCount}</p>
        </div>
      </div>

      <div class="overview-stat-card ${currentOverviewMetric === 'cardio' ? 'active' : ''}" onclick="selectOverviewMetric('cardio')">
        <div class="stat-icon" style="background: rgba(59, 130, 246, 0.1);">
          <span class="material-symbols-rounded" style="color: #3b82f6;">directions_run</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">Cardio-Sessions</p>
          <p class="stat-value">${stats.cardioCount}</p>
        </div>
      </div>

      <div class="overview-stat-card ${currentOverviewMetric === 'time' ? 'active' : ''}" onclick="selectOverviewMetric('time')">
        <div class="stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">schedule</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">Trainingszeit</p>
          <p class="stat-value">${formatDuration(stats.totalTime)}</p>
        </div>
      </div>

      <div class="overview-stat-card ${currentOverviewMetric === 'streak' ? 'active' : ''}" onclick="selectOverviewMetric('streak')">
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

  renderOverviewChart();
}

function selectOverviewMetric(metric) {
  currentOverviewMetric = metric;
  renderOverviewTab();
  triggerHapticFeedback('light');
}

function renderOverviewChart() {
  const container = document.getElementById('overview-chart-container');
  if (!container) return;

  const data = aggregateOverviewSeries(currentOverviewMetric, 8);

  if (data.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-chart">
        <span class="material-symbols-rounded">insert_chart</span>
        <p>Noch keine Daten fuer diesen Zeitraum</p>
      </div>
    `;
    return;
  }

  let metricLabel = 'Sessions';
  if (currentOverviewMetric === 'strength') metricLabel = 'Kraft-Sessions';
  if (currentOverviewMetric === 'cardio') metricLabel = 'Cardio-Sessions';
  if (currentOverviewMetric === 'time') metricLabel = 'Trainingszeit (min)';
  if (currentOverviewMetric === 'streak') metricLabel = 'Trainingstage';

  container.innerHTML = `
    <div class="progress-chart-header">
      <h3 class="progress-chart-title">${metricLabel} - Letzte 8 Wochen</h3>
    </div>
    <div class="progress-chart-canvas-wrapper">
      <canvas id="progress-chart-canvas"></canvas>
    </div>
  `;

  animateChartContainer(container);
  drawVolumeChart(data);
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
          <div class="workout-card-icon" style="background: ${color}20;">
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

function getSessionTitle(session) {
  if (session.type === 'cardio') {
    return ACTIVITY_TYPES[session.activityType]?.name || 'Cardio';
  }
  return session.planName || 'Krafttraining';
}

function getSessionIcon(session) {
  if (session.type === 'cardio') {
    return ACTIVITY_TYPES[session.activityType]?.icon || 'directions_run';
  }
  return 'fitness_center';
}

function getSessionColor(session) {
  if (session.type === 'cardio') {
    return ACTIVITY_TYPES[session.activityType]?.color || '#3b82f6';
  }
  return '#ef4444';
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
    : renderStrengthSummary(session);

  const content = `
    <div class="workout-detail-modal">
      <div class="workout-detail-header">
        <div class="workout-type-badge type-${session.type}">
          ${session.type === 'cardio' ? 'Cardio' : 'Kraft'}
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

  if (!sessionsLoaded || !exercisesLoaded) {
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

  // Collect all unique exercises from sessions
  const exerciseIds = new Set();
  strengthSessions.forEach(session => {
    session.exercises?.forEach(ex => {
      exerciseIds.add(ex.exerciseId);
    });
  });

  const availableExercises = exercisesData.filter(ex => exerciseIds.has(ex.id));

  if (availableExercises.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-state">
        <span class="material-symbols-rounded progress-empty-icon">search_off</span>
        <h3>Keine Übungen gefunden</h3>
        <p>Die Trainings enthalten keine bekannten Übungen</p>
      </div>
    `;
    return;
  }

  // Select first exercise if none selected
  if (!selectedExerciseId || !exerciseIds.has(selectedExerciseId)) {
    selectedExerciseId = availableExercises[0].id;
  }

  container.innerHTML = `
    <div class="strength-section">
      <!-- Exercise Picker -->
      <div class="exercise-picker-compact">
        <button onclick="openExercisePickerSheet()" class="exercise-picker-btn">
          <span class="material-symbols-rounded">fitness_center</span>
          <span id="selected-exercise-name">${getExerciseName(selectedExerciseId)}</span>
          <span class="material-symbols-rounded">expand_more</span>
        </button>
      </div>

      <!-- Metric Toggle -->
      <div class="metric-toggle">
        <button
          class="metric-btn ${strengthMetric === 'volume' ? 'active' : ''}"
          onclick="switchStrengthMetric('volume')"
        >
          Volumen
        </button>
        <button
          class="metric-btn ${strengthMetric === 'bestSet' ? 'active' : ''}"
          onclick="switchStrengthMetric('bestSet')"
        >
          Best Set
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

function switchStrengthMetric(metric) {
  strengthMetric = metric;
  renderStrengthTab();
  triggerHapticFeedback('light');
}

function renderStrengthStats() {
  const container = document.getElementById('strength-stats-container');
  if (!container) return;

  const data = aggregateStrengthData(selectedExerciseId, strengthMetric, 8);
  const stats = calculateStats(data);

  const metricLabel = strengthMetric === 'volume' ? 'Reps' : 'Reps/Set';

  container.innerHTML = `
    <div class="progress-stats-grid">
      <div class="progress-stat-card ${currentStrengthStat === 'last' ? 'active' : ''}" onclick="selectStrengthStat('last')">
        <div class="progress-stat-icon" style="background: rgba(240, 34, 119, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-primary);">trending_up</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Letztes Training</p>
          <p class="progress-stat-value">${stats.lastValue} ${metricLabel}</p>
        </div>
      </div>

      <div class="progress-stat-card ${currentStrengthStat === 'best' ? 'active' : ''}" onclick="selectStrengthStat('best')">
        <div class="progress-stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">emoji_events</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Bestes Training</p>
          <p class="progress-stat-value">${stats.bestValue} ${metricLabel}</p>
        </div>
      </div>

      <div class="progress-stat-card ${currentStrengthStat === 'avg' ? 'active' : ''}" onclick="selectStrengthStat('avg')">
        <div class="progress-stat-icon" style="background: rgba(59, 130, 246, 0.1);">
          <span class="material-symbols-rounded" style="color: #3b82f6;">analytics</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Durchschnitt</p>
          <p class="progress-stat-value">${stats.avgValue} ${metricLabel}</p>
        </div>
      </div>

      <div class="progress-stat-card ${currentStrengthStat === 'sessions' ? 'active' : ''}" onclick="selectStrengthStat('sessions')">
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

function renderStrengthChart() {
  const container = document.getElementById('strength-chart-container');
  if (!container) return;

  const { data, label } = getStrengthChartData();

  if (data.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-chart">
        <span class="material-symbols-rounded">insert_chart</span>
        <p>Noch keine Daten für diese Übung</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="progress-chart-header">
      <h3 class="progress-chart-title">${label} - Letzte 8 Wochen</h3>
    </div>
    <div class="progress-chart-canvas-wrapper">
      <canvas id="progress-chart-canvas"></canvas>
    </div>
  `;

  animateChartContainer(container);
  drawVolumeChart(data);
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
          <span>Cardio Session hinzufügen</span>
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

function switchCardioMetric(metric) {
  cardioMetric = metric;
  renderCardioTab();
  triggerHapticFeedback('light');
}

function renderCardioStats() {
  const container = document.getElementById('cardio-stats-container');
  if (!container) return;

  const data = aggregateCardioData(selectedActivityType, cardioMetric, 8);
  const stats = calculateStats(data);

  const metricLabel = cardioMetric === 'time' ? 'min' : 'km';

  container.innerHTML = `
    <div class="progress-stats-grid">
      <div class="progress-stat-card ${currentCardioStat === 'last' ? 'active' : ''}" onclick="selectCardioStat('last')">
        <div class="progress-stat-icon" style="background: rgba(59, 130, 246, 0.1);">
          <span class="material-symbols-rounded" style="color: #3b82f6;">trending_up</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Letzte Session</p>
          <p class="progress-stat-value">${stats.lastValue} ${metricLabel}</p>
        </div>
      </div>

      <div class="progress-stat-card ${currentCardioStat === 'best' ? 'active' : ''}" onclick="selectCardioStat('best')">
        <div class="progress-stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">emoji_events</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Beste Session</p>
          <p class="progress-stat-value">${stats.bestValue} ${metricLabel}</p>
        </div>
      </div>

      <div class="progress-stat-card ${currentCardioStat === 'avg' ? 'active' : ''}" onclick="selectCardioStat('avg')">
        <div class="progress-stat-icon" style="background: rgba(168, 85, 247, 0.1);">
          <span class="material-symbols-rounded" style="color: #a855f7;">analytics</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Durchschnitt</p>
          <p class="progress-stat-value">${stats.avgValue} ${metricLabel}</p>
        </div>
      </div>

      <div class="progress-stat-card ${currentCardioStat === 'sessions' ? 'active' : ''}" onclick="selectCardioStat('sessions')">
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

  const { data, label } = getCardioChartData();

  if (data.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-chart">
        <span class="material-symbols-rounded">insert_chart</span>
        <p>Noch keine Daten für diese Aktivität</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="progress-chart-header">
      <h3 class="progress-chart-title">${label} - Letzte 8 Wochen</h3>
    </div>
    <div class="progress-chart-canvas-wrapper">
      <canvas id="progress-chart-canvas"></canvas>
    </div>
  `;

  animateChartContainer(container);
  drawVolumeChart(data);
}

function selectStrengthStat(stat) {
  currentStrengthStat = stat;
  renderStrengthStats();
  renderStrengthChart();
  triggerHapticFeedback('light');
}

function selectCardioStat(stat) {
  currentCardioStat = stat;
  renderCardioStats();
  renderCardioChart();
  triggerHapticFeedback('light');
}

function getStrengthChartData() {
  const baseData = aggregateStrengthData(selectedExerciseId, strengthMetric, 8);
  const metricLabel = strengthMetric === 'volume' ? 'Volumen (Reps)' : 'Best Set (Reps)';
  const label = getChartLabel(metricLabel, currentStrengthStat);
  return {
    data: buildStatSeries(baseData, currentStrengthStat),
    label
  };
}

function getCardioChartData() {
  const baseData = aggregateCardioData(selectedActivityType, cardioMetric, 8);
  const metricLabel = cardioMetric === 'time' ? 'Zeit (min)' : 'Distanz (km)';
  const label = getChartLabel(metricLabel, currentCardioStat);
  return {
    data: buildStatSeries(baseData, currentCardioStat),
    label
  };
}

function getChartLabel(metricLabel, stat) {
  if (stat === 'best') return `Bestes ${metricLabel}`;
  if (stat === 'avg') return `Durchschnitt ${metricLabel}`;
  if (stat === 'sessions') return 'Sessions';
  return metricLabel;
}

function buildStatSeries(baseData, stat) {
  if (!baseData || baseData.length === 0) return [];

  if (stat === 'sessions') {
    return baseData.map(point => ({
      date: point.date,
      value: point.sessionCount || 0
    }));
  }

  if (stat === 'best') {
    let best = 0;
    return baseData.map(point => {
      best = Math.max(best, point.value || 0);
      return { date: point.date, value: best };
    });
  }

  if (stat === 'avg') {
    let sum = 0;
    return baseData.map((point, index) => {
      sum += point.value || 0;
      return { date: point.date, value: Math.round(sum / (index + 1)) };
    });
  }

  return baseData.map(point => ({
    date: point.date,
    value: point.value || 0
  }));
}

function aggregateOverviewSeries(metric = 'strength', weeks = 8) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - (weeks * 7));

  const groupedByDate = {};

  allSessions.forEach(session => {
    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    if (sessionDate < cutoffDate) return;

    const dateKey = sessionDate.toISOString().split('T')[0];

    if (!groupedByDate[dateKey]) {
      groupedByDate[dateKey] = {
        date: sessionDate,
        strengthCount: 0,
        cardioCount: 0,
        totalTime: 0,
        sessionCount: 0
      };
    }

    groupedByDate[dateKey].sessionCount += 1;
    if (session.type === 'strength') {
      groupedByDate[dateKey].strengthCount += 1;
    } else if (session.type === 'cardio') {
      groupedByDate[dateKey].cardioCount += 1;
    }
    if (session.duration) {
      groupedByDate[dateKey].totalTime += session.duration;
    }
  });

  const series = Object.values(groupedByDate).sort((a, b) => a.date - b.date);

  return series.map(point => {
    if (metric === 'cardio') return { date: point.date, value: point.cardioCount };
    if (metric === 'time') return { date: point.date, value: point.totalTime };
    if (metric === 'streak') return { date: point.date, value: point.sessionCount ? 1 : 0 };
    return { date: point.date, value: point.strengthCount };
  });
}

// ==================== BOTTOM SHEETS ====================

function openExercisePickerSheet() {
  const sheet = document.getElementById('exercise-picker-sheet');
  if (!sheet) return;

  // Collect available exercises
  const strengthSessions = allSessions.filter(s => s.type === 'strength');
  const exerciseIds = new Set();
  strengthSessions.forEach(session => {
    session.exercises?.forEach(ex => exerciseIds.add(ex.exerciseId));
  });

  const available = exercisesData.filter(ex => exerciseIds.has(ex.id));

  const listHTML = available
    .sort((a, b) => (a.name || '').localeCompare(b.name || ''))
    .map(ex => `
      <button
        class="picker-item ${ex.id === selectedExerciseId ? 'active' : ''}"
        onclick="selectExercise('${ex.id}')"
      >
        <span>${ex.name}</span>
        <span class="material-symbols-rounded">check</span>
      </button>
    `).join('');

  document.getElementById('exercise-picker-list').innerHTML = listHTML;
  sheet.classList.add('active');
}

function openActivityPickerSheet() {
  const sheet = document.getElementById('activity-picker-sheet');
  if (!sheet) return;

  const listHTML = Object.entries(ACTIVITY_TYPES)
    .map(([key, config]) => `
      <button
        class="picker-item ${key === selectedActivityType ? 'active' : ''}"
        onclick="selectActivity('${key}')"
      >
        <div class="picker-item-icon">
          <span class="material-symbols-rounded">${config.icon}</span>
        </div>
        <span>${config.name}</span>
        <span class="material-symbols-rounded">check</span>
      </button>
    `).join('');

  document.getElementById('activity-picker-list').innerHTML = listHTML;
  sheet.classList.add('active');
}

function closePickerSheet(sheetId) {
  const sheet = document.getElementById(sheetId);
  if (sheet) {
    sheet.classList.remove('active');
  }
}

function selectExercise(exerciseId) {
  selectedExerciseId = exerciseId;
  closePickerSheet('exercise-picker-sheet');
  renderStrengthTab();
}

function selectActivity(activityType) {
  selectedActivityType = activityType;
  closePickerSheet('activity-picker-sheet');
  renderCardioTab();
}

function getExerciseName(exerciseId) {
  const ex = exercisesData.find(e => e.id === exerciseId);
  return ex?.name || 'Übung';
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

function drawVolumeChart(data) {
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
  const maxValue = Math.max(...values);
  const minValue = Math.min(...values);
  const valueRange = maxValue - minValue || 1;

  ctx.clearRect(0, 0, width, height);

  // Colors
  const gridColor = 'rgba(75, 85, 99, 0.3)';
  const textColor = '#9ca3af';
  const lineColor = '#F02277';

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
    const value = Math.round(maxValue - (valueRange / 5) * i);
    const y = padding.top + (chartHeight / 5) * i;
    ctx.fillText(value.toString(), padding.left - 10, y);
  }

  // Points
  const points = data.map((d, i) => {
    const x = padding.left + (chartWidth / (data.length - 1 || 1)) * i;
    const y = padding.top + chartHeight - ((d.value - minValue) / valueRange) * chartHeight;
    return { x, y, value: d.value, date: d.date };
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

  // X-axis labels
  ctx.fillStyle = textColor;
  ctx.font = '10px Inter, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';

  const labelStep = Math.ceil(data.length / 6);
  data.forEach((d, i) => {
    if (i % labelStep === 0 || i === data.length - 1) {
      const point = points[i];
      const dateStr = formatShortDate(d.date);
      ctx.fillText(dateStr, point.x, padding.top + chartHeight + 10);
    }
  });
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

// Expose functions
window.initProgressV2 = initProgressV2;
window.switchProgressTab = switchProgressTab;
window.switchStrengthMetric = switchStrengthMetric;
window.switchCardioMetric = switchCardioMetric;
window.switchOverviewPeriod = switchOverviewPeriod;
window.openExercisePickerSheet = openExercisePickerSheet;
window.openActivityPickerSheet = openActivityPickerSheet;
window.closePickerSheet = closePickerSheet;
window.selectExercise = selectExercise;
window.selectActivity = selectActivity;
window.toggleRecentWorkouts = toggleRecentWorkouts;
window.openRecentWorkoutModal = openRecentWorkoutModal;
window.startWorkoutAgainFromSession = startWorkoutAgainFromSession;
window.viewWorkoutDetailsFromSession = viewWorkoutDetailsFromSession;
window.deleteSessionWithReferences = deleteSessionWithReferences;

console.log('📊 Progress V2 module loaded');
