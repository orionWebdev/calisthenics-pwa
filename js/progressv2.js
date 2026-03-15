// ========================================
// PROGRESS V2 - HYBRID TRACKING (STRENGTH + CARDIO)
// ========================================

let exercisesData = [];
let exercisesLoaded = false;
// New unified period system: 7D, 30D, 6M, 1Y
let progressOverviewPeriod = '7D';
let progressStrengthPeriod = '7D';
let progressBodyweightPeriod = '7D';
let progressCardioPeriod = '7D';
let activityCalendarDate = new Date(); // Current displayed month for activity calendar
let hybridBalanceDays = 7; // 7 or 30 days for Hybrid Balance toggle on Progress

const trProgress = (key, params) => (typeof t === 'function' ? t(key, params) : key);

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
 * Rendert Segmented Control (4 Tabs: Overview, Strength, Bodyweight, Cardio)
 */
function renderSegmentedControl(activeTab = 'overview') {
  const container = document.getElementById('progress-segmented-control');
  if (!container) return;

  container.innerHTML = `
    <div class="segmented-control segmented-control-4">
      <button
        class="segmented-btn ${activeTab === 'overview' ? 'active' : ''}"
        onclick="switchProgressTab('overview')"
        data-tab="overview"
      >
        <span class="material-symbols-rounded">insights</span>
        <span>${trProgress('progress.tabs.overview')}</span>
      </button>
      <button
        class="segmented-btn ${activeTab === 'strength' ? 'active' : ''}"
        onclick="switchProgressTab('strength')"
        data-tab="strength"
      >
        <span class="material-symbols-rounded">fitness_center</span>
        <span>${trProgress('progress.tabs.strength')}</span>
      </button>
      <button
        class="segmented-btn ${activeTab === 'bodyweight' ? 'active' : ''}"
        onclick="switchProgressTab('bodyweight')"
        data-tab="bodyweight"
      >
        <span class="material-symbols-rounded">sports_gymnastics</span>
        <span>${trProgress('progress.tabs.bodyweight')}</span>
      </button>
      <button
        class="segmented-btn ${activeTab === 'cardio' ? 'active' : ''}"
        onclick="switchProgressTab('cardio')"
        data-tab="cardio"
      >
        <span class="material-symbols-rounded">directions_run</span>
        <span>${trProgress('progress.tabs.cardio')}</span>
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
  } else if (tab === 'bodyweight') {
    renderBodyweightTab();
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
        <p>${trProgress('common.loading')}</p>
      </div>
    `;
    return;
  }

  if (allSessions.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-state">
        <span class="material-symbols-rounded progress-empty-icon">insights</span>
        <h3>${trProgress('progress.overview.emptyTitle')}</h3>
        <p>${trProgress('progress.overview.emptyBody')}</p>
        <button onclick="openOverviewAddSheet()" class="header-add-btn" style="margin-top: 1rem;" aria-label="${trProgress('progress.overview.addSessionAria')}" type="button">
          <span class="material-symbols-rounded">add</span>
          <span>${trProgress('common.add')}</span>
        </button>
      </div>
    `;
    return;
  }

  // Calculate stats using the new period system
  const periodDays = hybridBalanceDays;
  const currentStats = calculateOverviewStats(periodDays);
  const consistencyStats = calculateConsistencyStats(periodDays === 7 ? '7D' : '30D');
  const balanceData = computeHybridBalance(periodDays);
  const insight = generateCalmInsight(consistencyStats, balanceData);

  container.innerHTML = `
    <h3 style="margin-bottom: 1.5rem;">Balance</h3>
    <div class="overview-section">
      ${renderHybridBalanceHTML()}

      ${renderConsistencyCardHTML(consistencyStats)}

      <!-- Calm Insight -->
      <div class="calm-insight-card">
        <span class="material-symbols-rounded insight-icon">lightbulb</span>
        <p class="insight-text">${trProgress(insight.key, insight.params)}</p>
      </div>
    </div>
  `;
}

/**
 * Renders the Consistency Card (Rhythmus & Konsistenz)
 */
function renderConsistencyCardHTML(stats) {
  const daysSinceText = stats.daysSinceLastSession !== null
    ? `${stats.daysSinceLastSession} ${trProgress('progress.consistency.daysSinceLastUnit')}`
    : '-';

  return `
    <div class="progress-card consistency-card">
      <div class="card-header">
        <h3 class="card-title">${trProgress('progress.consistency.title')}</h3>
      </div>
      <div class="consistency-stats-grid">
        <div class="consistency-stat">
          <span class="consistency-value">${stats.sessionsPerWeek}</span>
          <span class="consistency-label">${trProgress('progress.consistency.sessionsPerWeek')}</span>
        </div>
        <div class="consistency-stat">
          <span class="consistency-value">${formatDurationText(stats.avgTrainingMinutesPerWeek * 60)}</span>
          <span class="consistency-label">${trProgress('progress.consistency.timePerWeek')}</span>
        </div>
        <div class="consistency-stat">
          <span class="consistency-value">${daysSinceText}</span>
          <span class="consistency-label">${trProgress('progress.consistency.daysSinceLast')}</span>
        </div>
        <div class="consistency-stat">
          <span class="consistency-value">${stats.trainingDaysInPeriod}</span>
          <span class="consistency-label">${trProgress('progress.consistency.trainingDays')}</span>
        </div>
      </div>
    </div>
  `;
}

/**
 * Renders the unified period selector component
 * @param {string} section - 'overview', 'strength', or 'cardio'
 * @param {PeriodKey} currentPeriod - Current selected period
 */
function renderProgressPeriodSelector(section, currentPeriod) {
  const periods = ['7D', '30D', '6M', '1Y'];

  // Period selector only - add buttons have been moved to dashboard
  return `
    <div class="progress-tab-header">
      <div class="progress-period-selector">
        ${periods.map(period => `
          <button
            class="period-btn ${currentPeriod === period ? 'active' : ''}"
            onclick="switchProgressPeriod('${section}', '${period}')"
            data-period="${period}"
          >
            ${trProgress(PERIOD_CONFIG[period].labelKey)}
          </button>
        `).join('')}
      </div>
    </div>
  `;
}

/**
 * Switches period for a specific section
 * @param {string} section - 'overview', 'strength', 'bodyweight', or 'cardio'
 * @param {PeriodKey} periodKey
 */
function switchProgressPeriod(section, periodKey) {
  if (section === 'overview') {
    progressOverviewPeriod = periodKey;
    renderOverviewTab();
  } else if (section === 'strength') {
    progressStrengthPeriod = periodKey;
    renderStrengthTab();
  } else if (section === 'bodyweight') {
    progressBodyweightPeriod = periodKey;
    renderBodyweightTab();
  } else if (section === 'cardio') {
    progressCardioPeriod = periodKey;
    renderCardioTab();
  }
  triggerHapticFeedback('light');
}

function renderOverviewStatsHTML(stats) {
  return `
    <div class="overview-stats-grid">
      <div class="overview-stat-card">
        <div class="stat-icon" style="background: color-mix(in srgb, var(--color-category-strength) 20%, transparent);">
          <span class="material-symbols-rounded" style="color: var(--color-category-strength);">fitness_center</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">${trProgress('progress.overview.stats.strengthCount')}</p>
          <p class="stat-value">${stats.strengthCount}</p>
        </div>
      </div>

      <div class="overview-stat-card">
        <div class="stat-icon" style="background: color-mix(in srgb, var(--color-category-cardio) 20%, transparent);">
          <span class="material-symbols-rounded" style="color: var(--color-category-cardio);">directions_run</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">${trProgress('progress.overview.stats.cardioCount')}</p>
          <p class="stat-value">${stats.cardioCount}</p>
        </div>
      </div>

      <div class="overview-stat-card">
        <div class="stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">schedule</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">${trProgress('progress.overview.stats.totalTime')}</p>
          <p class="stat-value">${formatDurationText(stats.totalTime * 60)}</p>
        </div>
      </div>

      <div class="overview-stat-card">
        <div class="stat-icon" style="background: rgba(168, 85, 247, 0.1);">
          <span class="material-symbols-rounded" style="color: #a855f7;">local_fire_department</span>
        </div>
        <div class="stat-content">
          <p class="stat-label">${trProgress('progress.overview.stats.streak')}</p>
          <p class="stat-value">${stats.streak} ${trProgress('progress.overview.stats.streakUnit')}</p>
        </div>
      </div>
    </div>
  `;
}

function openOverviewAddSheet() {
  if (typeof openSheet !== 'function') {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', trProgress('progress.modals.modalUnavailable'));
    }
    return;
  }

  openSheet({
    title: trProgress('common.add'),
    render: (container) => {
      container.innerHTML = `
        <button class="picker-item strength" type="button" onclick="handleOverviewQuickAdd('strength')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">fitness_center</span>
          </div>
          <span>${trProgress('common.strength')}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item cardio" type="button" onclick="handleOverviewQuickAdd('cardio')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">directions_run</span>
          </div>
          <span>${trProgress('common.cardio')}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item recovery" type="button" onclick="handleOverviewQuickAdd('recovery')">
          <div class="picker-item-icon">
            <span class="material-symbols-rounded">self_improvement</span>
          </div>
          <span>${trProgress('common.recovery')}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
      `;
    }
  });
}

function handleOverviewQuickAdd(type) {
  if (typeof closeSheet === 'function') {
    closeSheet();
  }

  if (type === 'cardio' && typeof openAddCardioModal === 'function') {
    openAddCardioModal();
    return;
  }

  if (type === 'recovery' && typeof openAddRecoveryModal === 'function') {
    openAddRecoveryModal();
    return;
  }

  if (type === 'strength') {
    openStrengthQuickAdd();
  }
}

function openStrengthQuickAdd() {
  if (typeof startManualWorkout === 'function') {
    startManualWorkout('strength');
    return;
  }
  if (typeof showTrainingTab === 'function') {
    showTrainingTab('plans');
    return;
  }
  if (typeof showView === 'function') {
    showView('training');
  }
}

/**
 * @deprecated Use switchProgressPeriod('overview', periodKey) instead
 */
function switchOverviewPeriod(days) {
  // Convert days to period key for backwards compatibility
  let periodKey = '7D';
  if (days >= 30) periodKey = '30D';
  else if (days >= 7) periodKey = '7D';

  switchProgressPeriod('overview', periodKey);
}

function renderHybridBalanceHTML() {
  if (typeof computeHybridBalance !== 'function') return '';

  const balance = computeHybridBalance(hybridBalanceDays);

  return `
    <div class="hybrid-balance-card">
      <div class="hybrid-balance-header">
        <div>
          <h3 class="hybrid-balance-title">${trProgress('progress.hybridBalance.title')}</h3>
          <p class="hybrid-balance-subtitle">${trProgress('progress.hybridBalance.subtitle', { days: hybridBalanceDays })}</p>
        </div>
        <div class="hybrid-balance-toggle" role="group" aria-label="${trProgress('progress.hybridBalance.toggleLabel')}">
          <button class="hybrid-toggle-btn ${hybridBalanceDays === 7 ? 'active' : ''}" onclick="switchHybridBalanceDays(7)" type="button">
            ${trProgress('progress.hybridBalance.sevenDays')}
          </button>
          <button class="hybrid-toggle-btn ${hybridBalanceDays === 30 ? 'active' : ''}" onclick="switchHybridBalanceDays(30)" type="button">
            ${trProgress('progress.hybridBalance.thirtyDays')}
          </button>
        </div>
      </div>
      <p class="hybrid-balance-description">${trProgress('progress.overview.hybridBalanceHelper')}</p>
      <div class="hybrid-balance-bar" role="img" aria-label="${trProgress('dashboard.hybridBalance.aria', { strength: balance.strengthPct, cardio: balance.cardioPct })}">
        <div class="hybrid-balance-segment strength" style="width: ${balance.strengthPct}%"></div>
        <div class="hybrid-balance-segment cardio" style="width: ${balance.cardioPct}%"></div>
      </div>
      <div class="hybrid-balance-meta">
        <span>${trProgress('progress.hybridBalance.metaStrength', { duration: formatDurationShortText(balance.strengthSec) })}</span>
        <span>${trProgress('progress.hybridBalance.metaCardio', { duration: formatDurationShortText(balance.cardioSec) })}</span>
      </div>
      <div class="hybrid-balance-label">${trProgress(balance.labelKey || 'balance.context.lowData')}</div>
    </div>
  `;
}

function switchHybridBalanceDays(days) {
  const nextDays = days === 30 ? 30 : 7;
  if (hybridBalanceDays === nextDays) return;
  hybridBalanceDays = nextDays;
  const balanceCard = document.querySelector('.hybrid-balance-card');
  if (balanceCard) {
    balanceCard.outerHTML = renderHybridBalanceHTML();
  }
  triggerHapticFeedback('light');
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
    return ACTIVITY_TYPES[session.activityType]?.name || trProgress('common.cardio');
  }
  if (session.type === 'recovery') {
    return trProgress('common.recovery');
  }
  return session.planName || trProgress('common.strength');
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
    showErrorMessage(trProgress('progress.modals.workoutNotFound'));
    return;
  }

  const date = getSessionDate(session);
  const duration = formatSessionDurationText(session);
  const title = getSessionTitle(session);
  const typeLabel = session.type === 'cardio'
    ? trProgress('progress.session.typeCardio')
    : session.type === 'recovery'
      ? trProgress('progress.session.typeRecovery')
      : trProgress('progress.session.typeStrength');

  const summary = session.type === 'cardio'
    ? renderCardioSummary(session)
    : session.type === 'recovery'
      ? renderRecoverySummary(session)
      : renderStrengthSummary(session);

  const content = `
    <div class="workout-detail-modal">
      <div class="workout-detail-header">
        <div class="workout-type-badge type-${session.type}">
          ${typeLabel}
        </div>
        <div class="workout-date" style="font-size: 0.875rem; color: #9ca3af;">
          ${formatDateLongText(date)}
        </div>
      </div>

      <div class="workout-stats-grid">
        <div class="workout-stat">
          <span class="material-symbols-rounded">schedule</span>
          <div class="workout-stat-value">${duration}</div>
          <div class="workout-stat-label">${trProgress('common.duration')}</div>
        </div>
        ${summary}
      </div>

      <div class="workout-modal-actions">
        <button onclick="startWorkoutAgainFromSession('${session.id}')" class="btn-primary">
          <span class="material-symbols-rounded">play_arrow</span>
          <span>${trProgress('common.startAgain')}</span>
        </button>
        <button onclick="viewWorkoutDetailsFromSession('${session.id}')" class="btn-secondary">
          <span class="material-symbols-rounded">info</span>
          <span>${trProgress('common.viewDetails')}</span>
        </button>
        <button onclick="deleteSessionWithReferences('${session.id}')" class="btn-danger">
          <span class="material-symbols-rounded">delete</span>
          <span>${trProgress('common.delete')}</span>
        </button>
      </div>
    </div>
  `;

  if (typeof openGenericModal === 'function') {
    openGenericModal(title, content);
  } else {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', trProgress('progress.modals.modalUnavailable'));
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
      <div class="workout-stat-label">${trProgress('progress.strength.summary.exercises')}</div>
    </div>
    <div class="workout-stat">
      <span class="material-symbols-rounded">repeat</span>
      <div class="workout-stat-value">${totalSets}</div>
      <div class="workout-stat-label">${trProgress('progress.strength.summary.sets')}</div>
    </div>
    <div class="workout-stat">
      <span class="material-symbols-rounded">trending_up</span>
      <div class="workout-stat-value">${totalReps}</div>
      <div class="workout-stat-label">${trProgress('progress.strength.summary.reps')}</div>
    </div>
  `;
}

function renderRecoverySummary() {
  return '';
}

function renderCardioSummary(session) {
  const distance = session.distanceKm
    ? trProgress('format.distanceKm', { distance: session.distanceKm })
    : trProgress('format.pace.na');
  const pace = session.pace ? formatPaceValueText(session.pace) : trProgress('format.pace.na');

  return `
    <div class="workout-stat">
      <span class="material-symbols-rounded">straighten</span>
      <div class="workout-stat-value">${distance}</div>
      <div class="workout-stat-label">${trProgress('progress.cardio.metricDistance')}</div>
    </div>
    <div class="workout-stat">
      <span class="material-symbols-rounded">speed</span>
      <div class="workout-stat-value">${pace}</div>
      <div class="workout-stat-label">${trProgress('progress.cardio.metricPace')}</div>
    </div>
    <div class="workout-stat">
      <span class="material-symbols-rounded">directions_run</span>
      <div class="workout-stat-value">${ACTIVITY_TYPES[session.activityType]?.name || trProgress('common.cardio')}</div>
      <div class="workout-stat-label">${trProgress('progress.cardio.activityLabel')}</div>
    </div>
  `;
}

function startWorkoutAgainFromSession(sessionId) {
  const session = allSessions.find((s) => s.id === sessionId);
  if (!session) {
    showErrorMessage(trProgress('errors.workoutNotFound'));
    return;
  }

  closeGenericModal();

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
    showErrorMessage(trProgress('progress.modals.modalUnavailable'));
  }
}

function viewWorkoutDetailsFromSession(sessionId) {
  const session = allSessions.find((s) => s.id === sessionId);
  if (!session) {
    showErrorMessage(trProgress('errors.workoutNotFound'));
    return;
  }

  closeGenericModal();

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
    showErrorMessage(trProgress('progress.modals.modalUnavailable'));
  }
}

function openCardioDetailModal(session) {
  const date = getSessionDate(session);
  const duration = formatSessionDurationText(session);
  const distance = session.distanceKm ? trProgress('format.distanceKm', { distance: session.distanceKm }) : trProgress('format.pace.na');
  const pace = session.pace ? formatPaceValueText(session.pace) : trProgress('format.pace.na');
  const activity = ACTIVITY_TYPES[session.activityType]?.name || trProgress('common.cardio');

  const content = `
    <div class="workout-detail-modal">
      <div class="workout-detail-header">
        <div class="workout-type-badge type-cardio">${trProgress('common.cardio')}</div>
        <div class="workout-date" style="font-size: 0.875rem; color: #9ca3af;">
          ${formatDateLongText(date)}
        </div>
      </div>
      <div class="workout-stats-grid">
        <div class="workout-stat">
          <span class="material-symbols-rounded">schedule</span>
          <div class="workout-stat-value">${duration}</div>
          <div class="workout-stat-label">${trProgress('progress.overview.stats.totalTime')}</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">straighten</span>
          <div class="workout-stat-value">${distance}</div>
          <div class="workout-stat-label">${trProgress('progress.cardio.metricDistance')}</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">speed</span>
          <div class="workout-stat-value">${pace}</div>
          <div class="workout-stat-label">${trProgress('progress.cardio.metricPace')}</div>
        </div>
      </div>
      <div class="workout-exercises">
        <h4 class="workout-section-title">${trProgress('progress.cardio.activityLabel')}</h4>
        <p class="text-sm text-gray-300">${activity}</p>
      </div>
      ${session.notes ? `
        <div class="workout-exercises">
          <h4 class="workout-section-title">${trProgress('common.notes')}</h4>
          <p class="text-sm text-gray-300">${session.notes}</p>
        </div>
      ` : ''}
      <div class="workout-modal-actions">
        <button onclick="openEditCardioSessionModal('${session.id}')" class="btn-edit">
          <span class="material-symbols-rounded">settings</span>
          <span>${trProgress('common.editSession')}</span>
        </button>
        <button onclick="deleteSessionWithReferences('${session.id}')" class="btn-danger">
          <span class="material-symbols-rounded">delete</span>
          <span>${trProgress('common.delete')}</span>
        </button>
      </div>
    </div>
  `;

  if (typeof openGenericModal === 'function') {
    openGenericModal(activity, content);
  } else {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', trProgress('progress.modals.modalUnavailable'));
    }
  }
}

function openRecoveryDetailModal(session) {
  const date = getSessionDate(session);
  const duration = formatSessionDurationText(session);
  const notes = session.notes ? session.notes : trProgress('common.notAvailable');

  const content = `
    <div class="workout-detail-modal">
      <div class="workout-detail-header">
        <div class="workout-type-badge type-recovery">${trProgress('common.recovery')}</div>
        <div class="workout-date" style="font-size: 0.875rem; color: #9ca3af;">
          ${formatDateLongText(date)}
        </div>
      </div>
      <div class="workout-stats-grid">
        <div class="workout-stat">
          <span class="material-symbols-rounded">schedule</span>
          <div class="workout-stat-value">${duration}</div>
          <div class="workout-stat-label">${trProgress('progress.overview.stats.totalTime')}</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">notes</span>
          <div class="workout-stat-value">${notes}</div>
          <div class="workout-stat-label">${trProgress('common.notes')}</div>
        </div>
      </div>
      <div class="workout-modal-actions">
        <button onclick="openEditRecoverySessionModal('${session.id}')" class="btn-edit">
          <span class="material-symbols-rounded">settings</span>
          <span>${trProgress('common.editSession')}</span>
        </button>
        <button onclick="deleteSessionWithReferences('${session.id}')" class="btn-danger">
          <span class="material-symbols-rounded">delete</span>
          <span>${trProgress('common.delete')}</span>
        </button>
      </div>
    </div>
  `;

  if (typeof openGenericModal === 'function') {
    openGenericModal(trProgress('common.recovery'), content);
  } else {
    showErrorMessage(trProgress('progress.modals.modalUnavailable'));
  }
}

function prefillCardioFromSession(session) {
  if (typeof openAddCardioModal !== 'function') {
    showErrorMessage(trProgress('progress.modals.cardioModalUnavailable'));
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

async function deleteSessionWithReferences(sessionId) {
  if (!confirm(trProgress('progress.modals.deleteConfirm'))) {
    return;
  }

  const session = allSessions.find((s) => s.id === sessionId);
  if (!session) {
    showErrorMessage(trProgress('progress.modals.workoutNotFound'));
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

    closeGenericModal();
    await loadSessions();
    renderCurrentProgressTab();
    triggerSuccessGlow();
  } catch (error) {
    console.error('❌ Error deleting session:', error);
    showErrorMessage(trProgress('progress.modals.deleteError', { message: error.message }));
  }
}

// ==================== STRENGTH TAB ====================

/**
 * Renders the Strength Tab - Load Index based (gewichtete Übungen only)
 */
function renderStrengthTab() {
  const container = document.getElementById('progress-tab-content');
  if (!container) return;

  if (!sessionsLoaded) {
    container.innerHTML = `
      <div class="progress-loading">
        <div class="spinner"></div>
        <p>${trProgress('common.loading')}</p>
      </div>
    `;
    return;
  }

  // Check for weighted strength sessions
  const loadStats = calculateWeightedLoadStats(progressStrengthPeriod);

  if (!loadStats.hasData && loadStats.totalSessions === 0) {
    container.innerHTML = `
      <div class="progress-empty-state">
        <span class="material-symbols-rounded progress-empty-icon">fitness_center</span>
        <h3>${trProgress('progress.strength.emptyTitle')}</h3>
        <p>${trProgress('progress.strength.emptyBody')}</p>
        <button onclick="openStrengthQuickAdd()" class="header-add-btn strength" style="margin-top: 1rem;" aria-label="${trProgress('common.add')}" type="button">
          <span class="material-symbols-rounded">add</span>
          <span>${trProgress('common.add')}</span>
        </button>
      </div>
    `;
    return;
  }

  // Calculate variance
  const variance = calculateTrainingVariance(progressStrengthPeriod);

  container.innerHTML = `
    <h3 style="margin-bottom: 1.5rem;">Krafttraining</h3>
    <div class="strength-section">
      <!-- Period Selector with Add Button -->
      ${renderProgressPeriodSelector('strength', progressStrengthPeriod)}

      <!-- Load Index Card -->
      <div class="progress-card load-index-card">
        <div class="card-header">
          <h3 class="card-title">${trProgress('progress.strength.loadIndex.title')}</h3>
        </div>
        <p class="card-hint">${trProgress('progress.strength.loadIndex.hint')}</p>
        <div id="strength-stats-container"></div>
      </div>

      <!-- Variance Card -->
      ${renderVarianceCardHTML(variance)}

      <!-- Chart -->
      <div id="strength-chart-container" class="progress-chart-container"></div>
    </div>
  `;

  renderStrengthLoadStats();
  renderStrengthLoadChart();
}

/**
 * Renders the Variance Card
 */
function renderVarianceCardHTML(variance) {
  let varianceLabel;
  let varianceColor;

  if (variance >= 0.5) {
    varianceLabel = trProgress('progress.strength.variance.high');
    varianceColor = 'var(--color-success)';
  } else if (variance >= 0.25) {
    varianceLabel = trProgress('progress.strength.variance.medium');
    varianceColor = 'var(--color-warning)';
  } else {
    varianceLabel = trProgress('progress.strength.variance.low');
    varianceColor = 'var(--color-primary)';
  }

  return `
    <div class="progress-card variance-card">
      <div class="card-header">
        <h3 class="card-title">${trProgress('progress.strength.variance.title')}</h3>
      </div>
      <p class="card-hint">${trProgress('progress.strength.variance.hint')}</p>
      <div class="variance-display">
        <div class="variance-bar-container">
          <div class="variance-bar" style="width: ${Math.round(variance * 100)}%; background: ${varianceColor};"></div>
        </div>
        <span class="variance-label" style="color: ${varianceColor};">${varianceLabel}</span>
      </div>
    </div>
  `;
}

/**
 * Renders the Load Index stats (Last/Best/Avg/Sessions)
 */
function renderStrengthLoadStats() {
  const container = document.getElementById('strength-stats-container');
  if (!container) return;

  const stats = calculateWeightedLoadStats(progressStrengthPeriod);
  const bucketLabel = PERIOD_CONFIG[progressStrengthPeriod]?.bucketType === 'weekly'
    ? trProgress('progress.period.bucket.week')
    : trProgress('progress.period.bucket.day');
  const lastLabel = trProgress('progress.labels.lastBucket', { bucket: bucketLabel });
  const bestLabel = trProgress('progress.labels.bestBucket', { bucket: bucketLabel });

  if (!stats.hasData) {
    container.innerHTML = `
      <div class="no-data-hint">
        <span class="material-symbols-rounded">info</span>
        <p>${trProgress('progress.strength.loadIndex.noData')}</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="progress-stats-grid">
      <div class="progress-stat-card">
        <p class="stat-label">${lastLabel}</p>
        <p class="stat-value">${stats.lastValue > 0 ? stats.lastValue : '-'}</p>
        <p class="stat-unit">${trProgress('progress.strength.loadIndex.unit')}</p>
      </div>
      <div class="progress-stat-card">
        <p class="stat-label">${bestLabel}</p>
        <p class="stat-value">${stats.bestValue > 0 ? stats.bestValue : '-'}</p>
        <p class="stat-unit">${trProgress('progress.strength.loadIndex.unit')}</p>
      </div>
      <div class="progress-stat-card">
        <p class="stat-label">${trProgress('progress.strength.stats.average')}</p>
        <p class="stat-value">${stats.avgValue > 0 ? stats.avgValue : '-'}</p>
        <p class="stat-unit">${trProgress('progress.strength.loadIndex.unit')}</p>
      </div>
      <div class="progress-stat-card">
        <p class="stat-label">${trProgress('progress.strength.stats.sessions')}</p>
        <p class="stat-value">${stats.totalSessions}</p>
      </div>
    </div>
  `;
}

/**
 * Renders the Load Index Chart
 */
function renderStrengthLoadChart() {
  const container = document.getElementById('strength-chart-container');
  if (!container) return;

  const data = aggregateWeightedLoadByPeriod(progressStrengthPeriod);

  if (!data || data.length === 0 || data.every(d => d.avgLoad === 0)) {
    container.innerHTML = `
      <div class="chart-empty-state">
        <p>${trProgress('progress.strength.noData')}</p>
      </div>
    `;
    return;
  }

  const chartTitle = trProgress('progress.strength.loadIndex.chartTitle', {
    period: trProgress(PERIOD_CONFIG[progressStrengthPeriod].labelKey)
  });

  container.innerHTML = `
    <div class="chart-header">
      <h4 class="chart-title">${chartTitle}</h4>
    </div>
    <div class="chart-canvas-wrapper">
      <canvas id="strength-load-chart"></canvas>
    </div>
  `;

  // Delay chart rendering to ensure canvas dimensions are available
  setTimeout(() => drawLoadIndexChart('strength-load-chart', data), 50);
}

/**
 * Draws a Load Index line chart
 */
function drawLoadIndexChart(canvasId, data) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;

  // Set canvas dimensions
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);

  const width = rect.width;
  const height = rect.height;
  const padding = { top: 20, right: 20, bottom: 40, left: 50 };

  const chartWidth = width - padding.left - padding.right;
  const chartHeight = height - padding.top - padding.bottom;

  // Clear canvas
  ctx.clearRect(0, 0, width, height);

  // Get values
  const values = data.map(d => d.avgLoad || d.value || 0);
  const maxValue = Math.max(...values, 1);
  const minValue = 0;

  // Draw grid lines
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
  ctx.lineWidth = 1;

  const gridLines = 4;
  for (let i = 0; i <= gridLines; i++) {
    const y = padding.top + (chartHeight / gridLines) * i;
    ctx.beginPath();
    ctx.moveTo(padding.left, y);
    ctx.lineTo(width - padding.right, y);
    ctx.stroke();

    // Y-axis labels
    const value = maxValue - (maxValue / gridLines) * i;
    ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
    ctx.font = '10px system-ui';
    ctx.textAlign = 'right';
    ctx.fillText(Math.round(value), padding.left - 8, y + 4);
  }

  // Draw line
  if (values.length > 1) {
    ctx.beginPath();
    ctx.strokeStyle = 'var(--color-category-strength)';
    ctx.lineWidth = 2;
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';

    values.forEach((value, i) => {
      const x = padding.left + (chartWidth / (values.length - 1)) * i;
      const y = padding.top + chartHeight - (value / maxValue) * chartHeight;

      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    });
    ctx.stroke();

    // Draw points
    values.forEach((value, i) => {
      const x = padding.left + (chartWidth / (values.length - 1)) * i;
      const y = padding.top + chartHeight - (value / maxValue) * chartHeight;

      ctx.beginPath();
      ctx.arc(x, y, 4, 0, Math.PI * 2);
      ctx.fillStyle = value > 0 ? 'var(--color-category-strength)' : 'rgba(255,255,255,0.2)';
      ctx.fill();
    });
  }

  // X-axis labels
  ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
  ctx.font = '10px system-ui';
  ctx.textAlign = 'center';

  const labelStep = Math.ceil(data.length / 6);
  data.forEach((d, i) => {
    if (i % labelStep === 0 || i === data.length - 1) {
      const x = padding.left + (chartWidth / (data.length - 1)) * i;
      ctx.fillText(d.label, x, height - 10);
    }
  });
}

/**
 * @deprecated Use switchProgressPeriod('strength', periodKey) instead
 */
function switchStrengthPeriod(weeks) {
  // Convert weeks to period key for backwards compatibility
  let periodKey = '30D';
  if (weeks <= 2) periodKey = '7D';
  else if (weeks <= 5) periodKey = '30D';
  else if (weeks <= 26) periodKey = '6M';
  else periodKey = '1Y';

  switchProgressPeriod('strength', periodKey);
}

function renderStrengthStats() {
  const container = document.getElementById('strength-stats-container');
  if (!container) return;

  // Use dual stats if available
  const dualStats = typeof calculateDualStrengthStats === 'function'
    ? calculateDualStrengthStats(progressStrengthPeriod, exercisesData)
    : null;

  const bucketLabel = PERIOD_CONFIG[progressStrengthPeriod]?.bucketType === 'weekly'
    ? trProgress('progress.period.bucket.week')
    : trProgress('progress.period.bucket.day');
  const lastLabel = trProgress('progress.labels.lastBucket', { bucket: bucketLabel });
  const bestLabel = trProgress('progress.labels.bestBucket', { bucket: bucketLabel });

  // Determine which stats to show based on selected metric
  let stats;
  let volumeTypeLabel = '';
  let volumeTypeIcon = 'fitness_center';
  let volumeHint = '';

  if (dualStats && strengthVolumeMetric === 'weighted') {
    stats = {
      lastValue: dualStats.weighted.lastValue,
      bestValue: dualStats.weighted.bestValue,
      avgValue: dualStats.weighted.avgValue,
      totalSessions: dualStats.totalSessions
    };
    volumeTypeLabel = trProgress('progress.strength.volume.weighted');
    volumeTypeIcon = 'fitness_center';
    volumeHint = trProgress('progress.strength.volume.weightedHint');
  } else if (dualStats && strengthVolumeMetric === 'bodyweight') {
    stats = {
      lastValue: dualStats.bodyweight.lastValue,
      bestValue: dualStats.bodyweight.bestValue,
      avgValue: dualStats.bodyweight.avgValue,
      totalSessions: dualStats.totalSessions
    };
    volumeTypeLabel = trProgress('progress.strength.volume.bodyweight');
    volumeTypeIcon = 'self_improvement';
    volumeHint = trProgress('progress.strength.volume.bodyweightHint');
  } else if (dualStats) {
    // Combined view
    stats = {
      lastValue: dualStats.weighted.lastValue + dualStats.bodyweight.lastValue,
      bestValue: Math.max(
        dualStats.weighted.bestValue + dualStats.bodyweight.bestValue,
        dualStats.weighted.bestValue,
        dualStats.bodyweight.bestValue
      ),
      avgValue: dualStats.weighted.avgValue + dualStats.bodyweight.avgValue,
      totalSessions: dualStats.totalSessions
    };
    volumeTypeLabel = trProgress('progress.strength.volume.combined');
    volumeTypeIcon = 'join';
    volumeHint = '';
  } else {
    // Fallback to legacy stats
    stats = calculateStrengthStats(progressStrengthPeriod);
  }

  // Show dual volume cards for combined view
  const showDualCards = dualStats && strengthVolumeMetric === 'combined' &&
                       dualStats.hasWeighted && dualStats.hasBodyweight;

  container.innerHTML = `
    ${showDualCards ? `
      <div class="dual-volume-display">
        <div class="volume-card weighted">
          <div class="volume-card-header">
            <span class="material-symbols-rounded">fitness_center</span>
            <span class="volume-card-label">${trProgress('progress.strength.volume.weighted')}</span>
          </div>
          <div class="volume-card-value">${formatVolume(dualStats.weighted.lastValue)}</div>
          <div class="volume-card-hint">${trProgress('progress.strength.volume.weightedHint')}</div>
        </div>
        <div class="volume-card bodyweight">
          <div class="volume-card-header">
            <span class="material-symbols-rounded">self_improvement</span>
            <span class="volume-card-label">${trProgress('progress.strength.volume.bodyweight')}</span>
          </div>
          <div class="volume-card-value">${formatVolume(dualStats.bodyweight.lastValue)}</div>
          <div class="volume-card-hint">${trProgress('progress.strength.volume.bodyweightHint')}</div>
        </div>
      </div>
    ` : ''}

    <div class="progress-stats-grid">
      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(240, 34, 119, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-primary);">trending_up</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">${lastLabel}</p>
          <p class="progress-stat-value">${formatVolume(stats.lastValue)}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">emoji_events</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">${bestLabel}</p>
          <p class="progress-stat-value">${formatVolume(stats.bestValue)}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(59, 130, 246, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-category-strength);">analytics</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">${trProgress('progress.strength.stats.average')}</p>
          <p class="progress-stat-value">${formatVolume(stats.avgValue)}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(168, 85, 247, 0.1);">
          <span class="material-symbols-rounded" style="color: #a855f7;">calendar_month</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">${trProgress('progress.strength.stats.sessions')}</p>
          <p class="progress-stat-value">${stats.totalSessions}</p>
        </div>
      </div>
    </div>
  `;
}

/**
 * Berechnet Stats für wöchentliche Daten
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

  // Get dual volume data if available
  const dualData = typeof aggregateDualStrengthByPeriod === 'function'
    ? aggregateDualStrengthByPeriod(progressStrengthPeriod, exercisesData)
    : null;

  // Prepare chart data based on selected metric
  let chartData;
  let chartTitleKey = 'progress.strength.chartTitle';
  let chartColor = 'strength';

  if (dualData && strengthVolumeMetric === 'weighted') {
    chartData = dualData.map(d => ({
      ...d,
      value: d.weightedVolume,
      weekLabel: d.label
    }));
    chartTitleKey = 'progress.strength.volume.chartTitleWeighted';
  } else if (dualData && strengthVolumeMetric === 'bodyweight') {
    chartData = dualData.map(d => ({
      ...d,
      value: d.bodyweightVolume,
      weekLabel: d.label
    }));
    chartTitleKey = 'progress.strength.volume.chartTitleBodyweight';
    chartColor = 'bodyweight';
  } else if (dualData) {
    // Combined
    chartData = dualData.map(d => ({
      ...d,
      value: d.weightedVolume + d.bodyweightVolume,
      weekLabel: d.label
    }));
  } else {
    // Fallback
    chartData = aggregateStrengthByPeriod(progressStrengthPeriod);
  }

  // Check if there's any data
  const hasData = chartData && chartData.some(d => d.value > 0);

  if (!hasData) {
    const emptyMsg = strengthVolumeMetric === 'weighted'
      ? trProgress('progress.strength.volume.noWeighted')
      : strengthVolumeMetric === 'bodyweight'
        ? trProgress('progress.strength.volume.noBodyweight')
        : trProgress('progress.strength.noData');

    container.innerHTML = `
      <div class="progress-empty-chart">
        <span class="material-symbols-rounded">insert_chart</span>
        <p>${emptyMsg}</p>
      </div>
    `;
    return;
  }

  const periodLabel = PERIOD_CONFIG[progressStrengthPeriod]?.labelKey
    ? trProgress(PERIOD_CONFIG[progressStrengthPeriod].labelKey)
    : trProgress('progress.period.7d');

  container.innerHTML = `
    <div class="progress-chart-header">
      <h3 class="progress-chart-title">${trProgress(chartTitleKey, { period: periodLabel })}</h3>
    </div>
    <div class="progress-chart-canvas-wrapper">
      <canvas id="progress-chart-canvas"></canvas>
    </div>
  `;

  animateChartContainer(container);
  drawWeeklyChart(chartData, chartColor);
}

/**
 * Zeichnet Chart für wöchentliche Daten
 * @param {Array} data - Chart data
 * @param {string} colorType - 'strength', 'bodyweight', or 'cardio'
 */
function drawWeeklyChart(data, colorType = 'strength') {
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

  // Colors based on type
  const gridColor = 'rgba(75, 85, 99, 0.3)';
  const textColor = '#9ca3af';
  let lineColor;
  let pointBgColor;

  if (colorType === 'bodyweight') {
    lineColor = '#22c55e'; // Green for bodyweight
    pointBgColor = 'rgba(34, 197, 94, 0.2)';
  } else {
    lineColor = getCategoryColorValue('strength');
    pointBgColor = 'rgba(240, 34, 119, 0.2)';
  }

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
    ctx.fillStyle = pointBgColor;
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

// ==================== BODYWEIGHT TAB ====================

/**
 * Renders the Bodyweight Tab - Intensitätsniveaus und Effort-Trend
 */
function renderBodyweightTab() {
  const container = document.getElementById('progress-tab-content');
  if (!container) return;

  if (!sessionsLoaded) {
    container.innerHTML = `
      <div class="progress-loading">
        <div class="spinner"></div>
        <p>${trProgress('common.loading')}</p>
      </div>
    `;
    return;
  }

  // Check for bodyweight sessions
  const bwStats = calculateBodyweightStats(progressBodyweightPeriod, exercisesData);

  if (!bwStats.hasData && bwStats.totalSessions === 0) {
    container.innerHTML = `
      <div class="progress-empty-state">
        <span class="material-symbols-rounded progress-empty-icon">sports_gymnastics</span>
        <h3>${trProgress('progress.bodyweight.emptyTitle')}</h3>
        <p>${trProgress('progress.bodyweight.emptyBody')}</p>
        <button onclick="openStrengthQuickAdd()" class="header-add-btn bodyweight" style="margin-top: 1rem;" aria-label="${trProgress('common.add')}" type="button">
          <span class="material-symbols-rounded">add</span>
          <span>${trProgress('common.add')}</span>
        </button>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <h3 style="margin-bottom: 1.5rem;">Bodyweight</h3>
    <div class="bodyweight-section">
      <!-- Period Selector with Add Button -->
      ${renderProgressPeriodSelector('bodyweight', progressBodyweightPeriod)}

      <!-- Intensity Levels Card -->
      <div class="progress-card intensity-card">
        <div class="card-header">
          <h3 class="card-title">${trProgress('progress.bodyweight.intensityTitle')}</h3>
        </div>
        <p class="card-hint">${trProgress('progress.bodyweight.intensityHint')}</p>
        <div id="intensity-distribution-container"></div>
      </div>

      <!-- Effort Stats Card -->
      <div class="progress-card effort-card">
        <div class="card-header">
          <h3 class="card-title">${trProgress('progress.bodyweight.effortTitle')}</h3>
        </div>
        <p class="card-hint">${trProgress('progress.bodyweight.effortHint')}</p>
        <div id="bodyweight-stats-container"></div>
      </div>

      <!-- Chart -->
      <div id="bodyweight-chart-container" class="progress-chart-container"></div>
    </div>
  `;

  renderIntensityDistribution();
  renderBodyweightStats();
  renderBodyweightChart();
}

/**
 * Renders the Intensity Distribution (Low/Medium/High)
 */
function renderIntensityDistribution() {
  const container = document.getElementById('intensity-distribution-container');
  if (!container) return;

  const data = aggregateBodyweightByPeriod(progressBodyweightPeriod, exercisesData);

  if (!data || data.length === 0) {
    container.innerHTML = `
      <div class="no-data-hint">
        <span class="material-symbols-rounded">info</span>
        <p>${trProgress('progress.bodyweight.noData')}</p>
      </div>
    `;
    return;
  }

  // Count intensity classes
  let lowCount = 0;
  let mediumCount = 0;
  let highCount = 0;

  data.forEach(d => {
    if (d.sessionCount > 0) {
      if (d.intensityClass === 'high') highCount++;
      else if (d.intensityClass === 'medium') mediumCount++;
      else if (d.intensityClass === 'low') lowCount++;
    }
  });

  const total = lowCount + mediumCount + highCount;
  const lowPct = total > 0 ? Math.round((lowCount / total) * 100) : 0;
  const medPct = total > 0 ? Math.round((mediumCount / total) * 100) : 0;
  const highPct = total > 0 ? Math.round((highCount / total) * 100) : 0;

  container.innerHTML = `
    <div class="intensity-bars">
      <div class="intensity-row">
        <span class="intensity-label">${trProgress('progress.bodyweight.intensityHigh')}</span>
        <div class="intensity-bar-container">
          <div class="intensity-bar high" style="width: ${highPct}%;"></div>
        </div>
        <span class="intensity-count">${highCount}</span>
      </div>
      <div class="intensity-row">
        <span class="intensity-label">${trProgress('progress.bodyweight.intensityMedium')}</span>
        <div class="intensity-bar-container">
          <div class="intensity-bar medium" style="width: ${medPct}%;"></div>
        </div>
        <span class="intensity-count">${mediumCount}</span>
      </div>
      <div class="intensity-row">
        <span class="intensity-label">${trProgress('progress.bodyweight.intensityLow')}</span>
        <div class="intensity-bar-container">
          <div class="intensity-bar low" style="width: ${lowPct}%;"></div>
        </div>
        <span class="intensity-count">${lowCount}</span>
      </div>
    </div>
  `;
}

/**
 * Renders the Bodyweight Stats (Last/Best/Avg/Sessions)
 */
function renderBodyweightStats() {
  const container = document.getElementById('bodyweight-stats-container');
  if (!container) return;

  const stats = calculateBodyweightStats(progressBodyweightPeriod, exercisesData);
  const bucketLabel = PERIOD_CONFIG[progressBodyweightPeriod]?.bucketType === 'weekly'
    ? trProgress('progress.period.bucket.week')
    : trProgress('progress.period.bucket.day');
  const lastLabel = trProgress('progress.labels.lastBucket', { bucket: bucketLabel });
  const bestLabel = trProgress('progress.labels.bestBucket', { bucket: bucketLabel });

  if (!stats.hasData) {
    container.innerHTML = `
      <div class="no-data-hint">
        <span class="material-symbols-rounded">info</span>
        <p>${trProgress('progress.bodyweight.noData')}</p>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="progress-stats-grid">
      <div class="progress-stat-card">
        <p class="stat-label">${lastLabel}</p>
        <p class="stat-value">${stats.lastValue > 0 ? stats.lastValue : '-'}</p>
      </div>
      <div class="progress-stat-card">
        <p class="stat-label">${bestLabel}</p>
        <p class="stat-value">${stats.bestValue > 0 ? stats.bestValue : '-'}</p>
      </div>
      <div class="progress-stat-card">
        <p class="stat-label">${trProgress('progress.bodyweight.stats.average')}</p>
        <p class="stat-value">${stats.avgValue > 0 ? stats.avgValue : '-'}</p>
      </div>
      <div class="progress-stat-card">
        <p class="stat-label">${trProgress('progress.bodyweight.stats.sessions')}</p>
        <p class="stat-value">${stats.totalSessions}</p>
      </div>
    </div>
  `;
}

/**
 * Renders the Bodyweight Effort Chart
 */
function renderBodyweightChart() {
  const container = document.getElementById('bodyweight-chart-container');
  if (!container) return;

  const data = aggregateBodyweightByPeriod(progressBodyweightPeriod, exercisesData);

  if (!data || data.length === 0 || data.every(d => d.effortVolume === 0)) {
    container.innerHTML = `
      <div class="chart-empty-state">
        <p>${trProgress('progress.bodyweight.noData')}</p>
      </div>
    `;
    return;
  }

  const chartTitle = trProgress('progress.bodyweight.chartTitle', {
    period: trProgress(PERIOD_CONFIG[progressBodyweightPeriod].labelKey)
  });

  container.innerHTML = `
    <div class="chart-header">
      <h4 class="chart-title">${chartTitle}</h4>
    </div>
    <div class="chart-canvas-wrapper">
      <canvas id="bodyweight-effort-chart"></canvas>
    </div>
  `;

  // Delay chart rendering to ensure canvas dimensions are available
  setTimeout(() => drawBodyweightEffortChart('bodyweight-effort-chart', data), 50);
}

/**
 * Draws a Bodyweight Effort chart with intensity colors
 */
function drawBodyweightEffortChart(canvasId, data) {
  const canvas = document.getElementById(canvasId);
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

  ctx.clearRect(0, 0, width, height);

  const values = data.map(d => d.effortVolume || d.value || 0);
  const maxValue = Math.max(...values, 1);

  // Draw grid lines
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
  ctx.lineWidth = 1;

  const gridLines = 4;
  for (let i = 0; i <= gridLines; i++) {
    const y = padding.top + (chartHeight / gridLines) * i;
    ctx.beginPath();
    ctx.moveTo(padding.left, y);
    ctx.lineTo(width - padding.right, y);
    ctx.stroke();

    const value = maxValue - (maxValue / gridLines) * i;
    ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
    ctx.font = '10px system-ui';
    ctx.textAlign = 'right';
    ctx.fillText(Math.round(value), padding.left - 8, y + 4);
  }

  // Draw bars with intensity colors
  const barWidth = Math.max(8, (chartWidth / data.length) * 0.6);
  const barSpacing = chartWidth / data.length;

  data.forEach((d, i) => {
    const x = padding.left + barSpacing * i + (barSpacing - barWidth) / 2;
    const barHeight = (d.effortVolume / maxValue) * chartHeight;
    const y = padding.top + chartHeight - barHeight;

    // Color based on intensity class
    let color;
    if (d.intensityClass === 'high') color = '#ef4444';
    else if (d.intensityClass === 'medium') color = '#f59e0b';
    else color = '#22c55e';

    if (d.effortVolume > 0) {
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.roundRect(x, y, barWidth, barHeight, 4);
      ctx.fill();
    }
  });

  // X-axis labels
  ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
  ctx.font = '10px system-ui';
  ctx.textAlign = 'center';

  const labelStep = Math.ceil(data.length / 6);
  data.forEach((d, i) => {
    if (i % labelStep === 0 || i === data.length - 1) {
      const x = padding.left + barSpacing * i + barSpacing / 2;
      ctx.fillText(d.label, x, height - 10);
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
        <p>${trProgress('common.loading')}</p>
      </div>
    `;
    return;
  }

  const cardioSessions = allSessions.filter(s => s.type === 'cardio');

  if (cardioSessions.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-state cardio">
        <span class="material-symbols-rounded progress-empty-icon">directions_run</span>
        <h3>${trProgress('progress.cardio.emptyTitle')}</h3>
        <p>${trProgress('progress.cardio.emptyBody')}</p>
        <button onclick="openAddCardioModal()" class="header-add-btn cardio" style="margin-top: 1rem;" aria-label="${trProgress('common.add')}" type="button">
          <span class="material-symbols-rounded">add</span>
          <span>${trProgress('progress.cardio.add')}</span>
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
    <h3 style="margin-bottom: 1.5rem;">Cardio</h3>
    <div class="cardio-section">
      <!-- Header with Activity Picker -->
      <div class="progress-tab-header">
        <div class="activity-picker-compact">
          <button onclick="openActivityPickerSheet()" class="activity-picker-btn">
            <span class="material-symbols-rounded">${ACTIVITY_TYPES[selectedActivityType].icon}</span>
            <span id="selected-activity-name">${ACTIVITY_TYPES[selectedActivityType].name}</span>
            <span class="material-symbols-rounded">expand_more</span>
          </button>
        </div>
      </div>

      <!-- Period Selector -->
      <div class="progress-period-selector" style="margin: 0 auto 1rem auto;">
        ${['7D', '30D', '6M', '1Y'].map(period => `
          <button
            class="period-btn ${progressCardioPeriod === period ? 'active' : ''}"
            onclick="switchProgressPeriod('cardio', '${period}')"
            data-period="${period}"
          >
            ${trProgress(PERIOD_CONFIG[period].labelKey)}
          </button>
        `).join('')}
      </div>

      <!-- Metric Toggle: Time | Distance | Pace -->
      <div class="metric-toggle cardio-metric-toggle">
        <button
          class="metric-btn ${cardioMetric === 'time' ? 'active' : ''}"
          onclick="switchCardioMetric('time')"
          data-metric="time"
        >
          ${trProgress('progress.cardio.metricTime')}
        </button>
        <button
          class="metric-btn ${cardioMetric === 'distance' ? 'active' : ''}"
          onclick="switchCardioMetric('distance')"
          data-metric="distance"
        >
          ${trProgress('progress.cardio.metricDistance')}
        </button>
        <button
          class="metric-btn ${cardioMetric === 'pace' ? 'active' : ''}"
          onclick="switchCardioMetric('pace')"
          data-metric="pace"
        >
          ${trProgress('progress.cardio.metricPace')}
        </button>
      </div>
      <p class="section-helper">${trProgress('progress.cardio.metricHelper')}</p>

      <!-- Stats -->
      <div id="cardio-stats-container"></div>
      <p class="section-helper">${trProgress('progress.cardio.helper')}</p>

      <!-- Chart -->
      <div id="cardio-chart-container" class="progress-chart-container"></div>
    </div>
  `;

  renderCardioStats();
  renderCardioChart();
}

/**
 * @deprecated Use switchProgressPeriod('cardio', periodKey) instead
 */
function switchCardioPeriod(weeks) {
  // Convert weeks to period key for backwards compatibility
  let periodKey = '30D';
  if (weeks <= 2) periodKey = '7D';
  else if (weeks <= 5) periodKey = '30D';
  else if (weeks <= 26) periodKey = '6M';
  else periodKey = '1Y';

  switchProgressPeriod('cardio', periodKey);
}

function switchCardioMetric(metric) {
  cardioMetric = metric;
  renderCardioStats();
  renderCardioChart();
  triggerHapticFeedback('light');

  // Update active button state
  document.querySelectorAll('.cardio-metric-toggle .metric-btn').forEach(btn => {
    const btnMetric = btn.dataset.metric;
    btn.classList.toggle('active', btnMetric === metric);
  });
}

function renderCardioStats() {
  const container = document.getElementById('cardio-stats-container');
  if (!container) return;

  const stats = calculateCardioStats(progressCardioPeriod, cardioMetric, selectedActivityType);
  const bucketLabel = PERIOD_CONFIG[progressCardioPeriod]?.bucketType === 'weekly'
    ? trProgress('progress.period.bucket.week')
    : trProgress('progress.period.bucket.day');

  // Format values based on metric
  let lastValueFormatted, bestValueFormatted, avgValueFormatted, metricUnit;
  const lastLabel = trProgress('progress.labels.lastBucket', { bucket: bucketLabel });
  let bestLabel = trProgress('progress.labels.bestBucket', { bucket: bucketLabel });

  if (cardioMetric === 'pace') {
    // For pace, format as min:sec /km
    lastValueFormatted = stats.lastValue > 0 ? formatPaceValueText(stats.lastValue) : trProgress('format.pace.na');
    bestValueFormatted = stats.bestValue > 0 ? formatPaceValueText(stats.bestValue) : trProgress('format.pace.na');
    avgValueFormatted = stats.avgValue > 0 ? formatPaceValueText(stats.avgValue) : trProgress('format.pace.na');
    metricUnit = '';
    bestLabel = trProgress('progress.labels.fastestBucket', { bucket: bucketLabel }); // For pace, lower is better

    // Show empty state if no pace data
    if (!stats.hasData) {
      container.innerHTML = `
        <div class="progress-stats-grid">
          <div class="progress-stat-card pace-empty-state" style="grid-column: 1 / -1;">
            <div class="progress-stat-icon" style="background: rgba(59, 130, 246, 0.1);">
              <span class="material-symbols-rounded" style="color: var(--color-category-cardio);">speed</span>
            </div>
            <div class="progress-stat-content">
              <p class="progress-stat-label">${trProgress('progress.cardio.paceEmptyTitle')}</p>
              <p class="progress-stat-value" style="font-size: 1rem;">${trProgress('progress.cardio.paceEmptyValue')}</p>
              <p class="progress-stat-hint">${trProgress('progress.cardio.paceEmptyHint')}</p>
            </div>
          </div>
        </div>
      `;
      return;
    }
  } else if (cardioMetric === 'distance') {
    lastValueFormatted = stats.lastValue.toFixed(1);
    bestValueFormatted = stats.bestValue.toFixed(1);
    avgValueFormatted = stats.avgValue.toFixed(1);
    metricUnit = trProgress('progress.cardio.metricUnit.distance');
  } else {
    // time
    lastValueFormatted = stats.lastValue;
    bestValueFormatted = stats.bestValue;
    avgValueFormatted = stats.avgValue;
    metricUnit = trProgress('progress.cardio.metricUnit.time');
  }

  const unitSuffix = metricUnit ? ` ${metricUnit}` : '';

  container.innerHTML = `
    <div class="progress-stats-grid">
      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(59, 130, 246, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-category-cardio);">trending_up</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">${lastLabel}</p>
          <p class="progress-stat-value">${lastValueFormatted}${unitSuffix}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">emoji_events</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">${bestLabel}</p>
          <p class="progress-stat-value">${bestValueFormatted}${unitSuffix}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(168, 85, 247, 0.1);">
          <span class="material-symbols-rounded" style="color: #a855f7;">analytics</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">${trProgress('progress.cardio.stats.average')}</p>
          <p class="progress-stat-value">${avgValueFormatted}${unitSuffix}</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(240, 34, 119, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-primary);">calendar_month</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">${trProgress('progress.cardio.stats.sessions')}</p>
          <p class="progress-stat-value">${stats.totalSessions}</p>
        </div>
      </div>
    </div>
  `;
}

function renderCardioChart() {
  const container = document.getElementById('cardio-chart-container');
  if (!container) return;

  const data = aggregateCardioByPeriod(cardioMetric, progressCardioPeriod, selectedActivityType);

  // Check if there's any data
  const hasData = data.some(d => d.value > 0);

  if (!hasData) {
    const emptyMessage = cardioMetric === 'pace'
      ? trProgress('progress.cardio.noPaceData')
      : trProgress('progress.cardio.noData');

    container.innerHTML = `
      <div class="progress-empty-chart">
        <span class="material-symbols-rounded">insert_chart</span>
        <p>${emptyMessage}</p>
      </div>
    `;
    return;
  }

  let metricLabel;
  if (cardioMetric === 'time') {
    metricLabel = trProgress('progress.cardio.metricLabel.time');
  } else if (cardioMetric === 'distance') {
    metricLabel = trProgress('progress.cardio.metricLabel.distance');
  } else {
    metricLabel = trProgress('progress.cardio.metricLabel.pace');
  }

  const periodLabel = PERIOD_CONFIG[progressCardioPeriod]?.labelKey
    ? trProgress(PERIOD_CONFIG[progressCardioPeriod].labelKey)
    : trProgress('progress.period.7d');

  container.innerHTML = `
    <div class="progress-chart-header">
      <h3 class="progress-chart-title">${trProgress('progress.cardio.chartTitle', { metric: metricLabel, period: periodLabel })}</h3>
    </div>
    <div class="progress-chart-canvas-wrapper">
      <canvas id="progress-chart-canvas"></canvas>
    </div>
  `;

  animateChartContainer(container);
  drawWeeklyCardioChart(data, cardioMetric);
}

/**
 * Zeichnet Cardio Chart für wöchentliche Daten
 * For pace metric: uses inverted Y-axis (faster pace = higher on chart)
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

  // Filter out zero values for pace calculations
  const nonZeroValues = data.filter(d => d.value > 0).map(d => d.value);
  if (nonZeroValues.length === 0) return;

  let minValue, maxValue, invertYAxis;

  if (metric === 'pace') {
    // For pace: lower value = faster = should be higher on chart
    // So we invert the Y-axis
    invertYAxis = true;
    minValue = Math.min(...nonZeroValues) * 0.9; // Add some padding
    maxValue = Math.max(...nonZeroValues) * 1.1;
  } else {
    invertYAxis = false;
    minValue = 0;
    maxValue = Math.max(...nonZeroValues) || 1;
  }

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
    const y = padding.top + (chartHeight / 5) * i;
    let value, label;

    if (invertYAxis) {
      // Inverted: top = min (fast), bottom = max (slow)
      value = minValue + ((maxValue - minValue) / 5) * i;
      label = formatPaceValueText(value);
    } else {
      value = Math.round(maxValue - (maxValue / 5) * i);
      label = metric === 'distance' ? value.toFixed(1) : value.toString();
    }

    ctx.fillText(label, padding.left - 10, y);
  }

  // Calculate points
  const points = data.map((d, i) => {
    const x = padding.left + (chartWidth / (data.length - 1 || 1)) * i;
    let y;

    if (d.value <= 0) {
      // No data point - use middle
      y = padding.top + chartHeight / 2;
    } else if (invertYAxis) {
      // Inverted Y: lower value (faster) = higher on chart (smaller y)
      const normalizedValue = (d.value - minValue) / (maxValue - minValue || 1);
      y = padding.top + normalizedValue * chartHeight;
    } else {
      const normalizedValue = (d.value - minValue) / (maxValue - minValue || 1);
      y = padding.top + chartHeight - normalizedValue * chartHeight;
    }

    return {
      x,
      y,
      value: d.value,
      label: d.label || d.weekLabel,
      hasData: d.value > 0
    };
  });

  // Filter points with data for line drawing
  const validPoints = points.filter(p => p.hasData);

  if (validPoints.length > 0) {
    // Line
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 3;
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';

    ctx.beginPath();
    validPoints.forEach((point, i) => {
      if (i === 0) {
        ctx.moveTo(point.x, point.y);
      } else {
        ctx.lineTo(point.x, point.y);
      }
    });
    ctx.stroke();

    // Points (only for data points)
    validPoints.forEach(point => {
      ctx.beginPath();
      ctx.arc(point.x, point.y, 6, 0, Math.PI * 2);
      ctx.fillStyle = 'rgba(59, 130, 246, 0.2)';
      ctx.fill();

      ctx.beginPath();
      ctx.arc(point.x, point.y, 4, 0, Math.PI * 2);
      ctx.fillStyle = lineColor;
      ctx.fill();
    });
  }

  // X-axis labels
  ctx.fillStyle = textColor;
  ctx.font = '10px Inter, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';

  const labelStep = Math.ceil(data.length / 6);
  data.forEach((d, i) => {
    if (i % labelStep === 0 || i === data.length - 1) {
      const point = points[i];
      ctx.fillText(d.label || d.weekLabel, point.x, padding.top + chartHeight + 10);
    }
  });
}

// ==================== ACTIVITY CALENDAR ====================

const ACTIVITY_DOT_MAX = 3;

function getSessionDurationMinutes(session) {
  const sec = Number(session?.durationSec || session?.durationSeconds || 0);
  if (Number.isFinite(sec) && sec > 0) return Math.round(sec / 60);
  const raw = Number(session?.duration || 0);
  if (!Number.isFinite(raw) || raw < 0) return 0;
  return Math.round(raw);
}

function formatSessionDurationText(session) {
  const minutes = getSessionDurationMinutes(session);
  if (!minutes) return trProgress('progress.session.durationNA');
  return formatDurationText(minutes * 60);
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
    showErrorMessage(trProgress('progress.modals.recoveryModalUnavailable'));
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

  const dayLabels = [
    trProgress('progress.activityCalendar.weekday.mon'),
    trProgress('progress.activityCalendar.weekday.tue'),
    trProgress('progress.activityCalendar.weekday.wed'),
    trProgress('progress.activityCalendar.weekday.thu'),
    trProgress('progress.activityCalendar.weekday.fri'),
    trProgress('progress.activityCalendar.weekday.sat'),
    trProgress('progress.activityCalendar.weekday.sun')
  ];
  const monthTitle = trProgress('progress.activityCalendar.monthTitle', {
    month: formatMonthYearText(activityCalendarDate)
  });

  return `
    <div class="activity-calendar">
      <div class="activity-calendar-header">
        <button onclick="navigateActivityCalendar('prev')" class="cal-nav-btn" aria-label="${trProgress('progress.activityCalendar.prevMonth')}">
          <span class="material-symbols-rounded">chevron_left</span>
        </button>
        <h3 class="activity-calendar-title">${monthTitle}</h3>
        <button onclick="navigateActivityCalendar('next')" class="cal-nav-btn" aria-label="${trProgress('progress.activityCalendar.nextMonth')}">
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
           aria-label="${trProgress('progress.activityCalendar.dayLabel', { day, count: sessions.length })}">
        <span class="day-number">${day}</span>
        <div class="session-dots" aria-hidden="true">
          ${visibleDots.map(dot => `
            <span class="session-dot ${dot.type} size-${dot.size}" title="${trProgress('format.duration.minutes', { minutes: dot.minutes })}"></span>
          `).join('')}
          ${overflow > 0 ? `<span class="session-overflow">${trProgress('progress.activityCalendar.overflow', { count: overflow })}</span>` : ''}
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
  const title = trProgress('progress.activityCalendar.sheetTitle', {
    date: formatDateLongText(date, false)
  });

  openSheet({
    title: title,
    render: (container) => {
      if (sessions.length === 0) {
        container.innerHTML = `
          <div class="activity-day-empty">
            <span class="material-symbols-rounded">event_busy</span>
            <p>${trProgress('progress.overview.activityDayEmpty')}</p>
          </div>
        `;
        return;
      }

      container.innerHTML = sessions.map(session => {
        const icon = getSessionIcon(session);
        const color = getSessionColor(session);
        const sessionTitle = getSessionTitle(session);
        const duration = formatSessionDurationText(session);

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
              <button onclick="viewWorkoutDetailsFromSession('${session.id}'); closeSheet();" class="session-action-btn" aria-label="${trProgress('common.view')}">
                <span class="material-symbols-rounded">visibility</span>
              </button>
              <button onclick="deleteSessionFromCalendar('${session.id}', '${dateKey}')" class="session-action-btn danger" aria-label="${trProgress('common.delete')}">
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
  if (!confirm(trProgress('progress.modals.deleteCalendarConfirm'))) {
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
    showErrorMessage(trProgress('progress.modals.deleteErrorShort'));
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
        <h3 class="sheet__title" id="sheet-title">${trProgress('common.select')}</h3>
        <button class="sheet__close" type="button" aria-label="${trProgress('common.close')}" data-sheet-close>
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
    titleEl.textContent = title || trProgress('common.select');
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
    title: trProgress('progress.cardio.activityPickerTitle'),
    render: (container) => {
      const listHTML = Object.entries(ACTIVITY_TYPES)
        .map(([key, config]) => `
          <button
            class="picker-item cardio ${key === selectedActivityType ? 'active' : ''}"
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

function openExercisePickerSheet() {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', trProgress('progress.modals.modalUnavailable'));
  }
}

function selectExercise() {
  // Placeholder to avoid runtime errors if legacy handlers call this.
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
        <p>${trProgress('common.loading')}</p>
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
window.switchStrengthVolumeMetric = switchStrengthVolumeMetric;
window.switchOverviewPeriod = switchOverviewPeriod;
window.switchProgressPeriod = switchProgressPeriod;
window.openExercisePickerSheet = openExercisePickerSheet;
window.openActivityPickerSheet = openActivityPickerSheet;
window.closePickerSheet = closePickerSheet;
window.closeAllPickerSheets = closeAllPickerSheets;
window.openSheet = openSheet;
window.closeSheet = closeSheet;
window.selectExercise = selectExercise;
window.selectActivity = selectActivity;
window.openOverviewAddSheet = openOverviewAddSheet;
window.handleOverviewQuickAdd = handleOverviewQuickAdd;
window.openStrengthQuickAdd = openStrengthQuickAdd;
window.openRecentWorkoutModal = openRecentWorkoutModal;
window.startWorkoutAgainFromSession = startWorkoutAgainFromSession;
window.viewWorkoutDetailsFromSession = viewWorkoutDetailsFromSession;
window.deleteSessionWithReferences = deleteSessionWithReferences;
window.navigateActivityCalendar = navigateActivityCalendar;
window.openActivityDaySheet = openActivityDaySheet;
window.deleteSessionFromCalendar = deleteSessionFromCalendar;

console.log('📊 Progress V2 module loaded');


