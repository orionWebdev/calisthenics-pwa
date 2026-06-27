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
  // Open the plan-quick-add sheet directly (plan calendar is the only calendar on dashboard now)
  if (typeof openQuickAddSheet === 'function') {
    setTimeout(() => openQuickAddSheet(), 220);
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
            <span class="picker-item-label">${tr('dashboard.startWorkout.selectPlan')}</span>
            <span class="picker-item-desc">${tr('dashboard.startWorkout.selectPlanDesc')}</span>
          </div>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
        <button class="picker-item" type="button" onclick="startFreeWorkoutOption()">
          <span class="material-symbols-rounded" style="font-size: 24px; color: white;">add_circle</span>
          <div class="picker-item-content">
            <span class="picker-item-label">${tr('dashboard.startWorkout.newWorkout')}</span>
            <span class="picker-item-desc">${tr('dashboard.startWorkout.newWorkoutDesc')}</span>
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
        <span class="dashboard-scheduled-duration">${workout.planDuration || 45} min</span>
        <span class="dashboard-scheduled-play"><span class="material-symbols-rounded">play_arrow</span></span>
      </div>
    </div>
  `).join('');

  container.innerHTML = `
    <div class="dashboard-scheduled-widget">
      <div class="dashboard-scheduled-header">
        <span class="dashboard-scheduled-title">${tr('dashboard.scheduled.title')}</span>
      </div>
      <div class="dashboard-scheduled-list">
        ${items}
      </div>
    </div>
  `;
}

// The "Workout erfassen" CTA was removed from Home (logging lives in the bottom-nav
// FAB). This now only keeps the "Heute"-header title/date in sync.
function renderLogWorkoutCard(state) {
  const todayTitle = tr('dashboard.today');
  const todayDate = typeof formatDateLongText === 'function'
    ? formatDateLongText(new Date(), false)
    : new Date().toLocaleDateString();
  const todayTitleEl = document.getElementById('dashboard-today-title');
  const todayDateEl = document.getElementById('dashboard-today-date');
  if (todayTitleEl) todayTitleEl.textContent = todayTitle;
  if (todayDateEl) todayDateEl.textContent = todayDate;

  const container = document.getElementById('dashboard-log-workout-card');
  if (container) container.remove();
}

