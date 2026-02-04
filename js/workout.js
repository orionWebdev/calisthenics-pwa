// ========================================
// WORKOUT ENGINE - LIVE WORKOUT TRACKING
// ========================================

/**
 * Active Workout State (stored in localStorage)
 * {
 *   id: string,
 *   status: 'in-progress',
 *   type: 'strength',
 *   planId: string,
 *   planName: string,
 *   scheduleId: string | null,
 *   scheduledDate: 'YYYY-MM-DD',
 *   startedAt: Timestamp,
 *   exercises: [{
 *     exerciseId: string,
 *     exerciseName: string,
 *     targetSets: number,
 *     targetReps: string,
 *     targetRest: number,
 *     completedSets: [{ reps: number, weight: number|null, completedAt: Timestamp }],
 *     status: 'not-started' | 'in-progress' | 'completed',
 *     notes: string
 *   }],
 *   notes: string,
 *   currentExerciseIndex: number
 * }
 */

let activeWorkout = null;
let restTimerInterval = null;
let restTimerRemaining = 0;

// State for active set row (iOS-style set logger)
let activeSetValues = { reps: 10, weight: 0 };

const WORKOUT_USER_ID = typeof CURRENT_USER_ID !== 'undefined' ? CURRENT_USER_ID : 'demo-user-123';

// ==================== LIFECYCLE ====================

/**
 * Start workout from a plan
 */
async function startWorkoutFromPlan(planId, scheduledDate = null, scheduleId = null) {
  try {
    if (!activeWorkout) {
      loadActiveWorkout();
    }
    if (activeWorkout && !confirmReplaceActiveWorkout()) {
      return;
    }

    // Find the plan
    const plan = allPlans.find(p => p.id === planId);
    if (!plan) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', 'Plan nicht gefunden');
      }
      return;
    }

    if (plan.type === 'recovery' && typeof openAddRecoveryModal === 'function') {
      scheduledDate = ensureValidDateString(scheduledDate);
      openAddRecoveryModal(scheduledDate);
      return;
    }
    if (!allExercises || allExercises.length === 0) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', 'Uebungen werden noch geladen. Bitte versuche es gleich erneut.');
      }
      return;
    }

    // Default to today if no scheduled date or invalid date
    scheduledDate = ensureValidDateString(scheduledDate);

    // Initialize active workout
    activeWorkout = {
      id: generateTempId(),
      status: 'in-progress',
      type: 'strength',
      planId: plan.id,
      planName: plan.name,
      scheduleId: scheduleId,
      scheduledDate: scheduledDate,
      startedAt: firebase.firestore.Timestamp.now(),
      exercises: plan.exercises.map(ex => {
        const exercise = allExercises.find(e => e.id === ex.exerciseId);
        return {
          exerciseId: ex.exerciseId,
          exerciseName: exercise ? exercise.name : 'Übung',
          targetSets: ex.sets || 3,
          targetReps: ex.reps || '10-12',
          targetRest: ex.rest || 90,
          completedSets: [],
          status: 'not-started',
          notes: ''
        };
      }),
      notes: '',
      currentExerciseIndex: 0
    };

    // Mark first exercise as in-progress
    if (activeWorkout.exercises.length > 0) {
      activeWorkout.exercises[0].status = 'in-progress';
    }

    saveActiveWorkout();
    if (typeof showView === 'function') {
      showView('workout');
    }
    renderWorkoutScreen();

    console.log('✅ Workout started:', activeWorkout.planName);
  } catch (error) {
    console.error('❌ Error starting workout:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Starten des Workouts');
    }
  }
}

/**
 * Start workout from previous session (restart feature)
 */
async function startWorkoutFromSession(sessionId) {
  try {
    if (!activeWorkout) {
      loadActiveWorkout();
    }
    if (activeWorkout && !confirmReplaceActiveWorkout()) {
      return;
    }

    const session = allSessions.find(s => s.id === sessionId);
    if (!session) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', 'Session nicht gefunden');
      }
      return;
    }

    const plan = allPlans.find(p => p.id === session.planId);
    if (!plan) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', 'Plan nicht gefunden');
      }
      return;
    }
    if (!allExercises || allExercises.length === 0) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', 'Uebungen werden noch geladen. Bitte versuche es gleich erneut.');
      }
      return;
    }

    // Create new workout based on session template
    const today = new Date();
    const dateStr = formatDate(today);

    activeWorkout = {
      id: generateTempId(),
      status: 'in-progress',
      type: 'strength',
      planId: session.planId,
      planName: session.planName,
      scheduleId: null, // No schedule link for manual workouts
      scheduledDate: dateStr,
      startedAt: firebase.firestore.Timestamp.now(),
      exercises: plan.exercises.map(ex => {
        const exercise = allExercises.find(e => e.id === ex.exerciseId);
        return {
          exerciseId: ex.exerciseId,
          exerciseName: exercise ? exercise.name : 'Übung',
          targetSets: ex.sets || 3,
          targetReps: ex.reps || '10-12',
          targetRest: ex.rest || 90,
          completedSets: [],
          status: 'not-started',
          notes: ''
        };
      }),
      notes: '',
      currentExerciseIndex: 0
    };

    // Mark first exercise as in-progress
    if (activeWorkout.exercises.length > 0) {
      activeWorkout.exercises[0].status = 'in-progress';
    }

    saveActiveWorkout();
    showView('workout');
    renderWorkoutScreen();

    console.log('✅ Workout restarted from session');
  } catch (error) {
    console.error('❌ Error restarting workout:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Neustarten des Workouts');
    }
  }
}

/**
 * Load active workout from localStorage
 */
function loadActiveWorkout() {
  try {
    const stored = localStorage.getItem('activeWorkout');
    if (stored) {
      activeWorkout = JSON.parse(stored);
      localStorage.setItem('activeWorkoutId', activeWorkout.id);
      console.log('✅ Active workout loaded from localStorage');
      return true;
    }
    return false;
  } catch (error) {
    console.error('❌ Error loading active workout:', error);
    localStorage.removeItem('activeWorkout');
    localStorage.removeItem('activeWorkoutId');
    return false;
  }
}

/**
 * Save active workout to localStorage
 */
function saveActiveWorkout() {
  try {
    if (activeWorkout) {
      localStorage.setItem('activeWorkout', JSON.stringify(activeWorkout));
      localStorage.setItem('activeWorkoutId', activeWorkout.id);
    }
  } catch (error) {
    console.error('❌ Error saving active workout:', error);
  }
}

/**
 * Check if there's an active workout on app load
 */
function checkActiveWorkout() {
  if (loadActiveWorkout()) {
    showActiveWorkoutBanner();
  }
}

function ensureActiveWorkoutBanner() {
  if (activeWorkout && !document.getElementById('active-workout-banner')) {
    showActiveWorkoutBanner();
  }
}

/**
 * Show banner for resuming active workout
 */
function showActiveWorkoutBanner() {
  const existing = document.getElementById('active-workout-banner');
  if (existing) existing.remove();

  const banner = document.createElement('div');
  banner.id = 'active-workout-banner';
  banner.className = 'active-workout-banner';
  banner.innerHTML = `
    <div class="banner-content">
      <span class="material-symbols-rounded">play_circle</span>
      <span>Du hast ein aktives Workout: ${activeWorkout.planName}</span>
    </div>
    <div class="banner-actions">
      <button onclick="resumeWorkout()" class="banner-btn primary">Fortsetzen</button>
      <button onclick="cancelActiveWorkoutFromBanner()" class="banner-btn secondary">Abbrechen</button>
    </div>
  `;

  document.body.appendChild(banner);

  // Auto-show workout view after 1 second if user doesn't interact
  setTimeout(() => {
    if (document.getElementById('active-workout-banner')) {
      // User hasn't clicked anything, show hint
      console.log('💡 Active workout waiting...');
    }
  }, 3000);
}

/**
 * Resume active workout
 */
function resumeWorkout() {
  const banner = document.getElementById('active-workout-banner');
  if (banner) banner.remove();

  showView('workout');
  renderWorkoutScreen();
}

/**
 * Cancel active workout from banner
 */
function cancelActiveWorkoutFromBanner() {
  if (confirm('Aktives Workout wirklich abbrechen? Alle Fortschritte gehen verloren.')) {
    const banner = document.getElementById('active-workout-banner');
    if (banner) banner.remove();

    cancelWorkout(false); // Don't ask again
  }
}

/**
 * Cancel workout
 */
function cancelWorkout(askConfirmation = true) {
  if (askConfirmation && !confirm('Workout wirklich abbrechen? Alle Fortschritte gehen verloren.')) {
    return;
  }

  activeWorkout = null;
  localStorage.removeItem('activeWorkout');
  localStorage.removeItem('activeWorkoutId');
  cancelRestTimer();

  showView('dashboard');
  console.log('❌ Workout cancelled');
}

/**
 * Complete workout and save to Firestore
 */
async function completeWorkout() {
  if (!activeWorkout) return;

  try {
    // Calculate duration (in minutes)
    const startTime = activeWorkout.startedAt.toDate ? activeWorkout.startedAt.toDate() : new Date(activeWorkout.startedAt.seconds * 1000);
    const endTime = new Date();
    const durationMinutes = Math.round((endTime - startTime) / 60000);

    // Parse the scheduled date (guard against invalid/epoch)
    const normalizedDate = ensureValidDateString(activeWorkout.scheduledDate);
    const [year, month, day] = normalizedDate.split('-').map(Number);
    const workoutDate = new Date(year, month - 1, day);

    // Create session document
    const sessionData = {
      userId: WORKOUT_USER_ID,
      type: 'strength',
      date: firebase.firestore.Timestamp.fromDate(workoutDate),
      planId: activeWorkout.planId,
      planName: activeWorkout.planName,
      exercises: activeWorkout.exercises.map(ex => ({
        exerciseId: ex.exerciseId,
        sets: ex.completedSets.map(set => ({
          reps: set.reps,
          weight: set.weight
        }))
      })),
      duration: durationMinutes,
      notes: activeWorkout.notes,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    };

    // Add scheduleId if this was from calendar
    if (activeWorkout.scheduleId) {
      sessionData.scheduleId = activeWorkout.scheduleId;
    }

    // Save session to Firestore
    const savedSessionId = await addDoc(sessionsCollection, sessionData);
    console.log('✅ Session saved:', savedSessionId);

    // If this workout was from a schedule, mark it as completed
    if (activeWorkout.scheduleId) {
      const scheduleUpdate = {
        status: 'completed',
        sessionId: savedSessionId,
        completedAt: firebase.firestore.Timestamp.now()
      };

      try {
        await updateDoc(scheduleCollection, activeWorkout.scheduleId, scheduleUpdate);
        console.log('✅ Schedule marked as completed');
      } catch (error) {
        console.error('❌ Error updating schedule entry:', error);
      }
    }

    // Clear active workout
    activeWorkout = null;
    localStorage.removeItem('activeWorkout');
    localStorage.removeItem('activeWorkoutId');
    cancelRestTimer();

    // Reload sessions
    await loadSessions();

    // Navigate to progress page
    showView('progress');

    // Trigger success animation
    triggerSuccessGlow();

    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', 'Workout gespeichert!');
    }
  } catch (error) {
    console.error('❌ Error completing workout:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Speichern des Workouts: ' + error.message);
    }
  }
}

// ==================== RENDERING ====================

/**
 * Render workout screen - Accordion Layout
 * Alle Übungen sind in einer Liste als Accordion dargestellt.
 * Die aktuelle Übung ist ausgeklappt mit Set Logger.
 */
function renderWorkoutScreen() {
  const container = document.getElementById('workout-screen-container');
  if (!container) return;
  if (!activeWorkout) {
    loadActiveWorkout();
  }
  if (!activeWorkout) {
    container.innerHTML = `
      <div class="empty-state">
        <div class="empty-state-icon">
          <span class="material-symbols-rounded">fitness_center</span>
        </div>
        <h3 class="empty-state-title">${t('workout.screen.noActiveWorkout')}</h3>
        <p class="empty-state-text">${t('workout.screen.noActiveWorkoutText')}</p>
        <button onclick="showTrainingTab ? showTrainingTab('plans') : showView('training')" class="empty-state-btn">
          <span class="material-symbols-rounded">assignment</span>
          <span>${t('workout.screen.toPlans')}</span>
        </button>
      </div>
    `;
    return;
  }

  const progress = calculateProgress();

  container.innerHTML = `
    <div class="workout-screen workout-screen--accordion">
      ${renderWorkoutHeaderCompact(progress)}
      ${renderExerciseAccordionList()}
    </div>
    ${renderStickyBottomBar()}
  `;

  // Auto-focus reps input der aktiven Übung
  const repsInput = document.getElementById('reps-input');
  if (repsInput) {
    setTimeout(() => repsInput.focus(), 100);
  }

  // Scroll zur aktiven Übung
  const activeAccordion = document.querySelector('.exercise-accordion-item.expanded');
  if (activeAccordion) {
    setTimeout(() => {
      activeAccordion.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 150);
  }
}

/**
 * Render workout header (legacy - kept for compatibility)
 */
function renderWorkoutHeader(progress) {
  return `
    <div class="workout-header">
      <h2 class="workout-title">${activeWorkout.planName}</h2>
      <div class="workout-meta">
        <span>${formatWorkoutDate(activeWorkout.scheduledDate)}</span>
        <span>·</span>
        <span>${t('workout.exercise.progress', { completed: progress.completed, total: progress.total }) || `${progress.completed} / ${progress.total} Uebungen`}</span>
      </div>
      <div class="workout-progress-bar">
        <div class="workout-progress-fill" style="width: ${progress.percentage}%"></div>
      </div>
    </div>
  `;
}

/**
 * Render compact workout header
 * Zeigt Plan-Name, Datum, Fortschritt
 */
function renderWorkoutHeaderCompact(progress) {
  const exerciseIndex = activeWorkout.currentExerciseIndex + 1;
  const totalExercises = activeWorkout.exercises.length;

  return `
    <div class="workout-header workout-header--compact">
      <div class="workout-header-top">
        <div class="workout-header-info">
          <h2 class="workout-title">${activeWorkout.planName}</h2>
          <div class="workout-meta">
            <span>${formatWorkoutDate(activeWorkout.scheduledDate)}</span>
            <span class="workout-meta-separator">·</span>
            <span>${t('workout.screen.exerciseOf', { current: exerciseIndex, total: totalExercises })}</span>
          </div>
        </div>
        <div class="workout-header-progress-badge">
          <span class="material-symbols-rounded">check_circle</span>
          <span>${progress.completed}/${progress.total}</span>
        </div>
      </div>
      <div class="workout-progress-bar">
        <div class="workout-progress-fill" style="width: ${progress.percentage}%"></div>
      </div>
    </div>
  `;
}

/**
 * Render active exercise card - Fokus auf die aktuelle Übung (Legacy)
 */
function renderActiveExerciseCard(exercise) {
  if (!exercise) return '';

  const restText = exercise.targetRest ? `${exercise.targetRest}s` : '';

  return `
    <div class="active-exercise-card">
      <div class="active-exercise-badge">
        <span class="material-symbols-rounded">fitness_center</span>
        <span>${t('workout.screen.currentExercise')}</span>
      </div>
      <h3 class="active-exercise-name">${exercise.exerciseName}</h3>
      <div class="active-exercise-meta">
        <div class="active-exercise-goal">
          <span class="material-symbols-rounded">target</span>
          <span>${t('workout.screen.goal')}: ${exercise.targetSets} × ${exercise.targetReps}</span>
        </div>
        ${restText ? `
          <div class="active-exercise-rest">
            <span class="material-symbols-rounded">timer</span>
            <span>${t('workout.screen.rest')}: ${restText}</span>
          </div>
        ` : ''}
      </div>
    </div>
  `;
}

/**
 * Render exercise accordion list - Alle Übungen als Accordion
 */
function renderExerciseAccordionList() {
  if (!activeWorkout) return '';

  return `
    <div class="exercise-accordion-list">
      ${activeWorkout.exercises.map((exercise, index) => renderExerciseAccordionItem(exercise, index)).join('')}
    </div>
  `;
}

/**
 * Render single exercise accordion item
 */
function renderExerciseAccordionItem(exercise, index) {
  const isActive = index === activeWorkout.currentExerciseIndex;
  const isCompleted = exercise.status === 'completed';
  const setsProgress = `${exercise.completedSets.length}/${exercise.targetSets}`;
  const isExpanded = isActive; // Standardmäßig ist nur die aktive Übung offen

  return `
    <div class="exercise-accordion-item ${isExpanded ? 'expanded' : ''} ${isCompleted ? 'completed' : ''} ${isActive ? 'active' : ''}" data-exercise-index="${index}">
      <button
        type="button"
        class="exercise-accordion-header"
        onclick="toggleExerciseAccordion(${index})"
        aria-expanded="${isExpanded}"
        aria-controls="exercise-accordion-content-${index}"
      >
        <div class="exercise-accordion-number ${isCompleted ? 'completed' : ''}">
          ${isCompleted
            ? '<span class="material-symbols-rounded">check</span>'
            : index + 1
          }
        </div>
        <div class="exercise-accordion-info">
          <div class="exercise-accordion-name">${exercise.exerciseName}</div>
          <div class="exercise-accordion-target">${exercise.targetSets} × ${exercise.targetReps}${exercise.targetRest ? ` · ${exercise.targetRest}s` : ''}</div>
        </div>
        <div class="exercise-accordion-right">
          <span class="exercise-accordion-progress ${isCompleted ? 'completed' : ''}">${setsProgress}</span>
          <span class="material-symbols-rounded exercise-accordion-chevron">${isExpanded ? 'expand_less' : 'expand_more'}</span>
        </div>
      </button>
      <div id="exercise-accordion-content-${index}" class="exercise-accordion-content" ${isExpanded ? '' : 'hidden'}>
        ${renderAccordionExerciseContent(exercise, index)}
      </div>
    </div>
  `;
}

/**
 * Render accordion content for an exercise
 */
function renderAccordionExerciseContent(exercise, exerciseIndex) {
  const isActive = exerciseIndex === activeWorkout.currentExerciseIndex;

  return `
    <div class="accordion-exercise-content">
      <!-- Completed Sets als Rows -->
      ${exercise.completedSets.length > 0 ? `
        <div class="accordion-sets-list">
          ${exercise.completedSets.map((set, setIndex) => `
            <div class="accordion-set-row ${setIndex === exercise.completedSets.length - 1 ? 'latest' : ''}">
              <div class="accordion-set-number">
                <span class="material-symbols-rounded">check_circle</span>
                <span>${t('workout.setLogger.set')} ${setIndex + 1}</span>
              </div>
              <div class="accordion-set-data">
                <span class="accordion-set-value">${set.reps} ${t('workout.setLogger.reps')}</span>
                ${set.weight ? `<span class="accordion-set-value">${set.weight} ${t('workout.setLogger.weightUnit')}</span>` : ''}
              </div>
              <button
                type="button"
                onclick="deleteSet(${exerciseIndex}, ${setIndex})"
                class="accordion-set-delete"
                aria-label="${t('workout.setLogger.deleteSet')}"
              >
                <span class="material-symbols-rounded">close</span>
              </button>
            </div>
          `).join('')}
        </div>
      ` : ''}

      <!-- Set Logger nur für aktive Übung -->
      ${isActive ? renderAccordionSetLogger(exercise, exerciseIndex) : `
        <button
          type="button"
          class="accordion-goto-btn"
          onclick="goToExercise(${exerciseIndex})"
        >
          <span class="material-symbols-rounded">play_arrow</span>
          <span>${t('workout.screen.switchToExercise')}</span>
        </button>
      `}
    </div>
  `;
}

/**
 * Render iOS-style set logger inside accordion
 * Shows set rows with value buttons instead of stepper inputs
 */
function renderAccordionSetLogger(exercise, exerciseIndex) {
  // Determine if bodyweight or weighted exercise
  const isBodyweight = isBodyweightExercise();

  // Initialize active set values with defaults
  initActiveSetValues(exercise);

  return `
    <div class="set-logger-modern">
      <!-- Completed Sets as Rows -->
      ${renderSetRows(exercise, exerciseIndex, isBodyweight)}

      <!-- Active Set Input Row -->
      ${renderActiveSetRow(exercise, exerciseIndex, isBodyweight)}

      <!-- Target Info -->
      <div class="set-logger-target">
        <span class="material-symbols-rounded">target</span>
        <span>${t('workout.setLogger.target')}: ${exercise.targetSets} × ${exercise.targetReps}</span>
      </div>
    </div>
  `;
}

/**
 * Check if current workout is bodyweight-based
 * Derives from plan discipline
 * Default: Show weight (isBodyweight = false) to allow all exercises
 */
function isBodyweightExercise() {
  if (!activeWorkout) return false; // Default: show weight

  // Get plan to check discipline
  const plan = typeof allPlans !== 'undefined'
    ? allPlans.find(p => p.id === activeWorkout.planId)
    : null;

  if (!plan) return false; // Default: show weight

  const discipline = plan.discipline || '';

  // Only hide weight for explicitly bodyweight/calisthenics plans
  return discipline === 'bodyweight' || discipline === 'calisthenics';
}

/**
 * Get default values for new set based on last set or targets
 */
function getDefaultSetValues(exercise) {
  const lastSet = exercise.completedSets.length > 0
    ? exercise.completedSets[exercise.completedSets.length - 1]
    : null;

  return {
    reps: lastSet ? lastSet.reps : (parseInt(exercise.targetReps) || 10),
    weight: lastSet ? (lastSet.weight || 0) : 0
  };
}

/**
 * Initialize active set values from exercise defaults
 */
function initActiveSetValues(exercise) {
  const defaults = getDefaultSetValues(exercise);
  activeSetValues = {
    reps: defaults.reps,
    weight: defaults.weight
  };
}

/**
 * Render completed sets as rows
 */
function renderSetRows(exercise, exerciseIndex, isBodyweight) {
  if (exercise.completedSets.length === 0) return '';

  return `
    <div class="set-rows-list">
      ${exercise.completedSets.map((set, setIndex) => {
        const isLatest = setIndex === exercise.completedSets.length - 1;
        const weightDisplay = set.weight != null && set.weight > 0
          ? (set.weight % 1 !== 0 ? set.weight.toFixed(1).replace('.', ',') : set.weight)
          : 0;

        return `
          <div class="set-row ${isLatest ? 'set-row--latest' : ''}" data-set-index="${setIndex}">
            <!-- Set Number Pill -->
            <div class="set-row-pill">
              <span>${setIndex + 1}</span>
            </div>

            <!-- Value Buttons -->
            <div class="set-row-values">
              <button
                type="button"
                class="set-row-value-btn"
                onclick="openNumberPickerForSet(${exerciseIndex}, ${setIndex}, 'reps')"
                aria-label="${t('workout.setLogger.reps')}: ${set.reps}"
              >
                <span class="set-row-value">${set.reps}</span>
                <span class="set-row-unit">${t('workout.logging.totalReps')}</span>
              </button>

              ${!isBodyweight ? `
                <button
                  type="button"
                  class="set-row-value-btn"
                  onclick="openNumberPickerForSet(${exerciseIndex}, ${setIndex}, 'weight')"
                  aria-label="${t('workout.setLogger.weight')}: ${weightDisplay}"
                >
                  <span class="set-row-value">${weightDisplay}</span>
                  <span class="set-row-unit">${t('workout.setLogger.weightUnit')}</span>
                </button>
              ` : ''}
            </div>

            <!-- Delete Button (shows X on hover) -->
            <button
              type="button"
              class="set-row-check set-row-check--completed"
              onclick="deleteSet(${exerciseIndex}, ${setIndex})"
              aria-label="${t('workout.setLogger.deleteSet')}"
            >
              <span class="material-symbols-rounded">check</span>
            </button>
          </div>
        `;
      }).join('')}
    </div>
  `;
}

/**
 * Render active set input row
 */
function renderActiveSetRow(exercise, exerciseIndex, isBodyweight) {
  const setNumber = exercise.completedSets.length + 1;
  const weightDisplay = activeSetValues.weight % 1 !== 0
    ? activeSetValues.weight.toFixed(1).replace('.', ',')
    : activeSetValues.weight;

  return `
    <div class="set-row set-row--active" data-set-index="new">
      <!-- Set Number Pill -->
      <div class="set-row-pill set-row-pill--active">
        <span>${setNumber}</span>
      </div>

      <!-- Value Buttons -->
      <div class="set-row-values">
        <button
          type="button"
          class="set-row-value-btn set-row-value-btn--editable"
          onclick="openNumberPickerForNewSet('reps')"
          id="active-reps-btn"
          data-value="${activeSetValues.reps}"
          aria-label="${t('workout.setLogger.reps')}: ${activeSetValues.reps}"
        >
          <span class="set-row-value" id="active-reps-value">${activeSetValues.reps}</span>
          <span class="set-row-unit">${t('workout.logging.totalReps')}</span>
        </button>

        ${!isBodyweight ? `
          <button
            type="button"
            class="set-row-value-btn set-row-value-btn--editable"
            onclick="openNumberPickerForNewSet('weight')"
            id="active-weight-btn"
            data-value="${activeSetValues.weight}"
            aria-label="${t('workout.setLogger.weight')}: ${weightDisplay}"
          >
            <span class="set-row-value" id="active-weight-value">${weightDisplay}</span>
            <span class="set-row-unit">${t('workout.setLogger.weightUnit')}</span>
          </button>
        ` : ''}
      </div>

      <!-- Log Button -->
      <button
        type="button"
        class="set-row-check set-row-check--log"
        onclick="logSetFromActiveRow()"
        aria-label="${t('workout.setLogger.logSet')}"
      >
        <span class="material-symbols-rounded">check</span>
      </button>
    </div>
  `;
}

/**
 * Open number picker for an existing set
 */
function openNumberPickerForSet(exerciseIndex, setIndex, type) {
  if (!activeWorkout) return;

  const exercise = activeWorkout.exercises[exerciseIndex];
  if (!exercise) return;

  const set = exercise.completedSets[setIndex];
  if (!set) return;

  const initialValue = type === 'reps' ? set.reps : (set.weight || 0);

  openNumberPicker({
    type: type,
    initialValue: initialValue,
    onConfirm: (newValue) => {
      // Update existing set
      if (type === 'reps') {
        set.reps = newValue;
      } else {
        set.weight = newValue;
      }
      saveActiveWorkout();
      renderWorkoutScreen();
      triggerHapticFeedback('success');
    }
  });
}

/**
 * Open number picker for new set input
 */
function openNumberPickerForNewSet(type) {
  const initialValue = type === 'reps' ? activeSetValues.reps : activeSetValues.weight;

  openNumberPicker({
    type: type,
    initialValue: initialValue,
    onConfirm: (newValue) => {
      if (type === 'reps') {
        activeSetValues.reps = newValue;
        updateActiveRowDisplay('reps', newValue);
      } else {
        activeSetValues.weight = newValue;
        updateActiveRowDisplay('weight', newValue);
      }
      triggerHapticFeedback('light');
    }
  });
}

/**
 * Update active row display after picker selection
 */
function updateActiveRowDisplay(type, value) {
  const valueEl = document.getElementById(`active-${type}-value`);
  const btnEl = document.getElementById(`active-${type}-btn`);

  if (valueEl) {
    const displayValue = type === 'weight' && value % 1 !== 0
      ? value.toFixed(1).replace('.', ',')
      : value;
    valueEl.textContent = displayValue;
  }
  if (btnEl) {
    btnEl.dataset.value = value;
  }
}

/**
 * Log set from active row values
 */
function logSetFromActiveRow() {
  const reps = activeSetValues.reps;

  if (!reps || reps <= 0) {
    showEdgeFeedback('error', t('workout.setLogger.enterReps'));
    return;
  }

  // Get weight only if not bodyweight
  const isBodyweight = isBodyweightExercise();
  const weight = isBodyweight ? null : (activeSetValues.weight || null);

  // Log the set using existing function
  logSet(reps, weight);
}

/**
 * Toggle exercise accordion open/closed
 */
function toggleExerciseAccordion(index) {
  const item = document.querySelector(`.exercise-accordion-item[data-exercise-index="${index}"]`);
  if (!item) return;

  const isExpanded = item.classList.contains('expanded');
  const content = item.querySelector('.exercise-accordion-content');
  const chevron = item.querySelector('.exercise-accordion-chevron');
  const header = item.querySelector('.exercise-accordion-header');

  if (isExpanded) {
    // Schließen
    item.classList.remove('expanded');
    content.hidden = true;
    chevron.textContent = 'expand_more';
    header.setAttribute('aria-expanded', 'false');
  } else {
    // Öffnen
    item.classList.add('expanded');
    content.hidden = false;
    chevron.textContent = 'expand_less';
    header.setAttribute('aria-expanded', 'true');
  }

  triggerHapticFeedback('light');
}

/**
 * Render exercise list
 */
function renderExerciseList() {
  return `
    <div class="workout-exercise-list">
      ${activeWorkout.exercises.map((ex, index) => `
        <div
          class="workout-exercise-card ${index === activeWorkout.currentExerciseIndex ? 'active' : ''} ${ex.status === 'completed' ? 'completed' : ''}"
          onclick="goToExercise(${index})"
        >
          <div class="workout-exercise-header">
            <div class="exercise-number ${ex.status === 'completed' ? 'completed' : ''}">
              ${ex.status === 'completed' ? '<span class="material-symbols-rounded" style="font-size: 18px;">check</span>' : index + 1}
            </div>
            <div class="exercise-info">
              <div class="exercise-name">${ex.exerciseName}</div>
              <div class="exercise-target">${ex.targetSets} × ${ex.targetReps} Reps</div>
            </div>
            <div class="exercise-status">${ex.completedSets.length} / ${ex.targetSets}</div>
          </div>
        </div>
      `).join('')}
    </div>
  `;
}

/**
 * Render current exercise
 */
function renderCurrentExercise(exercise) {
  if (!exercise) return '';

  return `
    <div class="current-exercise-detail">
      <h3 style="font-size: 1.25rem; font-weight: 700; color: white; margin-bottom: 0.5rem;">
        ${exercise.exerciseName}
      </h3>
      <p style="font-size: 0.875rem; color: #9ca3af;">
        Ziel: ${exercise.targetSets} Sätze × ${exercise.targetReps} Wiederholungen
        ${exercise.targetRest ? ` · ${exercise.targetRest}s Pause` : ''}
      </p>
    </div>
  `;
}

/**
 * Render set logger - Mobile-first Exercise Card layout
 */
function renderSetLogger(exercise) {
  if (!exercise) return '';

  const setNumber = exercise.completedSets.length + 1;
  const lastSet = exercise.completedSets.length > 0
    ? exercise.completedSets[exercise.completedSets.length - 1]
    : null;

  // Default values from last set or target
  const defaultReps = lastSet ? lastSet.reps : (exercise.targetReps ? parseInt(exercise.targetReps) || 10 : 10);
  const defaultWeight = lastSet ? (lastSet.weight || '') : '';

  return `
    <div class="exercise-card-logger">
      <div class="exercise-card-header">
        <span class="exercise-card-set-badge">${t('workout.setLogger.set')} ${setNumber}</span>
        <span class="exercise-card-target">${t('workout.setLogger.target')}: ${exercise.targetSets} × ${exercise.targetReps}</span>
      </div>

      <div class="exercise-card-inputs">
        <!-- Reps Input with Steppers -->
        <div class="input-with-steppers">
          <label class="input-stepper-label">${t('workout.setLogger.reps')} *</label>
          <div class="stepper-group">
            <button
              type="button"
              class="stepper-btn stepper-minus"
              onclick="adjustInputValue('reps-input', -1)"
              aria-label="Verringern"
            >
              <span class="material-symbols-rounded">remove</span>
            </button>
            <input
              type="text"
              id="reps-input"
              class="stepper-input"
              value="${defaultReps}"
              inputmode="numeric"
              pattern="[0-9]*"
              enterkeyhint="next"
              autocomplete="off"
              aria-label="${t('workout.setLogger.reps')}"
            />
            <button
              type="button"
              class="stepper-btn stepper-plus"
              onclick="adjustInputValue('reps-input', 1)"
              aria-label="Erhoehen"
            >
              <span class="material-symbols-rounded">add</span>
            </button>
          </div>
        </div>

        <!-- Weight Input with Steppers -->
        <div class="input-with-steppers">
          <label class="input-stepper-label">${t('workout.setLogger.weight')} (${t('workout.setLogger.weightUnit')})</label>
          <div class="stepper-group">
            <button
              type="button"
              class="stepper-btn stepper-minus"
              onclick="adjustInputValue('weight-input', -2.5)"
              aria-label="Verringern"
            >
              <span class="material-symbols-rounded">remove</span>
            </button>
            <input
              type="text"
              id="weight-input"
              class="stepper-input"
              value="${defaultWeight}"
              inputmode="decimal"
              pattern="[0-9]*[.,]?[0-9]*"
              enterkeyhint="done"
              autocomplete="off"
              placeholder="0"
              aria-label="${t('workout.setLogger.weight')}"
            />
            <button
              type="button"
              class="stepper-btn stepper-plus"
              onclick="adjustInputValue('weight-input', 2.5)"
              aria-label="Erhoehen"
            >
              <span class="material-symbols-rounded">add</span>
            </button>
          </div>
        </div>
      </div>

      <div class="exercise-card-actions">
        <button onclick="logSetFromInput()" class="log-set-btn-primary">
          <span class="material-symbols-rounded">check_circle</span>
          <span>${t('workout.setLogger.logSet')}</span>
        </button>
        ${lastSet ? `
          <button onclick="duplicateLastSet()" class="log-set-btn-secondary">
            <span class="material-symbols-rounded">content_copy</span>
            <span>${t('workout.setLogger.duplicateLast')}</span>
          </button>
        ` : ''}
      </div>
    </div>
  `;
}

/**
 * Adjust input value with stepper buttons
 */
function adjustInputValue(inputId, delta) {
  const input = document.getElementById(inputId);
  if (!input) return;

  let currentValue = parseFloat(input.value.replace(',', '.')) || 0;
  let newValue = currentValue + delta;

  // Ensure non-negative
  if (newValue < 0) newValue = 0;

  // Round to sensible precision for weight
  if (inputId === 'weight-input') {
    newValue = Math.round(newValue * 2) / 2; // Round to 0.5
  } else {
    newValue = Math.round(newValue);
  }

  input.value = newValue || (inputId === 'weight-input' ? '' : '0');

  // Haptic feedback
  triggerHapticFeedback('light');
}

/**
 * Duplicate the last logged set
 */
function duplicateLastSet() {
  if (!activeWorkout) return;

  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!currentExercise || currentExercise.completedSets.length === 0) return;

  const lastSet = currentExercise.completedSets[currentExercise.completedSets.length - 1];
  logSet(lastSet.reps, lastSet.weight);
}

/**
 * Render completed sets - Clean card-based layout
 */
function renderCompletedSets(exercise) {
  if (!exercise || exercise.completedSets.length === 0) {
    return `
      <div class="completed-sets-section">
        <h4 class="completed-sets-title">${t('workout.setLogger.completedSets')}</h4>
        <div class="completed-sets-empty">
          <span class="material-symbols-rounded">playlist_add</span>
          <span>${t('workout.setLogger.noSets')}</span>
        </div>
      </div>
    `;
  }

  return `
    <div class="completed-sets-section">
      <h4 class="completed-sets-title">${t('workout.setLogger.completedSets')} (${exercise.completedSets.length}/${exercise.targetSets})</h4>
      <div class="completed-sets-grid">
        ${exercise.completedSets.map((set, setIndex) => `
          <div class="completed-set-card ${setIndex === exercise.completedSets.length - 1 ? 'latest' : ''}">
            <div class="completed-set-number">
              <span class="material-symbols-rounded">check_circle</span>
              <span>${setIndex + 1}</span>
            </div>
            <div class="completed-set-data">
              <div class="completed-set-reps">
                <span class="data-value">${set.reps}</span>
                <span class="data-label">${t('workout.setLogger.reps')}</span>
              </div>
              ${set.weight ? `
                <div class="completed-set-weight">
                  <span class="data-value">${set.weight}</span>
                  <span class="data-label">${t('workout.setLogger.weightUnit')}</span>
                </div>
              ` : ''}
            </div>
            <button
              onclick="deleteSet(${activeWorkout.currentExerciseIndex}, ${setIndex})"
              class="completed-set-delete"
              title="${t('workout.setLogger.deleteSet')}"
              aria-label="${t('workout.setLogger.deleteSet')}"
            >
              <span class="material-symbols-rounded">close</span>
            </button>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

/**
 * Render workout actions (Cancel, Next/Finish) - Legacy
 */
function renderWorkoutActions() {
  const isLastExercise = activeWorkout.currentExerciseIndex === activeWorkout.exercises.length - 1;
  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  const hasSets = currentExercise && currentExercise.completedSets.length > 0;

  return `
    <div class="workout-bottom-actions">
      <!-- Abbrechen Button -->
      <button
        onclick="cancelWorkout()"
        class="btn-secondary workout-cancel-btn"
      >
        <span class="material-symbols-rounded" style="font-size: 18px;">close</span>
        <span>${t('common.cancel') || 'Abbrechen'}</span>
      </button>

      <!-- Primary Action -->
      ${!isLastExercise ? `
        <button
          onclick="goToNextExercise()"
          class="btn-primary"
          ${!hasSets ? 'disabled' : ''}
        >
          <span>${t('workout.exercise.next') || 'Naechste Uebung'}</span>
          <span class="material-symbols-rounded">arrow_forward</span>
        </button>
      ` : `
        <button
          onclick="completeWorkout()"
          class="btn-primary"
        >
          <span class="material-symbols-rounded">check_circle</span>
          <span>${t('workout.exercise.finish') || 'Workout beenden'}</span>
        </button>
      `}
    </div>
  `;
}

/**
 * Render completed sets - Collapsible version for focus mode
 */
function renderCompletedSetsCollapsible(exercise) {
  if (!exercise) return '';

  const setCount = exercise.completedSets.length;
  const isEmpty = setCount === 0;

  if (isEmpty) {
    return `
      <div class="completed-sets-section completed-sets-section--collapsible">
        <div class="completed-sets-header">
          <h4 class="completed-sets-title">${t('workout.setLogger.completedSets')}</h4>
          <span class="completed-sets-count">0/${exercise.targetSets}</span>
        </div>
        <div class="completed-sets-empty">
          <span class="material-symbols-rounded">playlist_add</span>
          <span>${t('workout.setLogger.noSets')}</span>
        </div>
      </div>
    `;
  }

  return `
    <div class="completed-sets-section completed-sets-section--collapsible">
      <button
        type="button"
        class="completed-sets-header completed-sets-header--clickable"
        onclick="toggleCompletedSets()"
        aria-expanded="true"
        aria-controls="completed-sets-content"
      >
        <h4 class="completed-sets-title">${t('workout.setLogger.completedSets')}</h4>
        <div class="completed-sets-header-right">
          <span class="completed-sets-count">${setCount}/${exercise.targetSets}</span>
          <span class="material-symbols-rounded completed-sets-chevron">expand_less</span>
        </div>
      </button>
      <div id="completed-sets-content" class="completed-sets-content">
        <div class="completed-sets-grid">
          ${exercise.completedSets.map((set, setIndex) => `
            <div class="completed-set-card ${setIndex === exercise.completedSets.length - 1 ? 'latest' : ''}">
              <div class="completed-set-number">
                <span class="material-symbols-rounded">check_circle</span>
                <span>${setIndex + 1}</span>
              </div>
              <div class="completed-set-data">
                <div class="completed-set-reps">
                  <span class="data-value">${set.reps}</span>
                  <span class="data-label">${t('workout.setLogger.reps')}</span>
                </div>
                ${set.weight ? `
                  <div class="completed-set-weight">
                    <span class="data-value">${set.weight}</span>
                    <span class="data-label">${t('workout.setLogger.weightUnit')}</span>
                  </div>
                ` : ''}
              </div>
              <button
                onclick="deleteSet(${activeWorkout.currentExerciseIndex}, ${setIndex})"
                class="completed-set-delete"
                title="${t('workout.setLogger.deleteSet')}"
                aria-label="${t('workout.setLogger.deleteSet')}"
              >
                <span class="material-symbols-rounded">close</span>
              </button>
            </div>
          `).join('')}
        </div>
      </div>
    </div>
  `;
}

/**
 * Toggle completed sets visibility
 */
function toggleCompletedSets() {
  const content = document.getElementById('completed-sets-content');
  const header = content?.previousElementSibling;
  if (!content || !header) return;

  const isExpanded = header.getAttribute('aria-expanded') === 'true';
  header.setAttribute('aria-expanded', !isExpanded);
  content.classList.toggle('collapsed', isExpanded);

  const chevron = header.querySelector('.completed-sets-chevron');
  if (chevron) {
    chevron.textContent = isExpanded ? 'expand_more' : 'expand_less';
  }
}

/**
 * Render sticky bottom bar - Always visible actions
 * "Workout beenden" ist IMMER verfügbar (mit Confirm Modal)
 */
function renderStickyBottomBar() {
  const isLastExercise = activeWorkout.currentExerciseIndex === activeWorkout.exercises.length - 1;
  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  const hasSets = currentExercise && currentExercise.completedSets.length > 0;

  return `
    <div class="workout-sticky-bar">
      <div class="workout-sticky-bar-inner">
        <!-- Secondary Actions Row -->
        <div class="workout-sticky-secondary">
          <button
            type="button"
            onclick="cancelWorkout()"
            class="workout-sticky-btn workout-sticky-btn--cancel"
            aria-label="${t('workout.screen.cancelWorkout')}"
          >
            <span class="material-symbols-rounded">close</span>
            <span>${t('workout.screen.cancelWorkout')}</span>
          </button>
          <button
            type="button"
            onclick="confirmEndWorkout()"
            class="workout-sticky-btn workout-sticky-btn--end"
            aria-label="${t('workout.screen.endWorkout')}"
          >
            <span class="material-symbols-rounded">stop_circle</span>
            <span>${t('workout.screen.endWorkout')}</span>
          </button>
        </div>

        <!-- Primary Action -->
        ${!isLastExercise ? `
          <button
            type="button"
            onclick="goToNextExercise()"
            class="workout-sticky-btn workout-sticky-btn--primary"
            ${!hasSets ? 'disabled' : ''}
            aria-label="${t('workout.screen.nextExercise')}"
          >
            <span>${t('workout.screen.nextExercise')}</span>
            <span class="material-symbols-rounded">arrow_forward</span>
          </button>
        ` : `
          <button
            type="button"
            onclick="confirmEndWorkout()"
            class="workout-sticky-btn workout-sticky-btn--primary workout-sticky-btn--finish"
            aria-label="${t('workout.screen.finishWorkout')}"
          >
            <span class="material-symbols-rounded">check_circle</span>
            <span>${t('workout.screen.finishWorkout')}</span>
          </button>
        `}
      </div>
    </div>
  `;
}

/**
 * Confirm end workout modal
 */
function confirmEndWorkout() {
  // Zeige Confirm Modal
  showWorkoutEndConfirmModal();
}

/**
 * Show workout end confirmation modal
 */
function showWorkoutEndConfirmModal() {
  // Entferne existierendes Modal falls vorhanden
  const existing = document.getElementById('workout-end-confirm-modal');
  if (existing) existing.remove();

  const modal = document.createElement('div');
  modal.id = 'workout-end-confirm-modal';
  modal.className = 'workout-confirm-modal-overlay';
  modal.innerHTML = `
    <div class="workout-confirm-modal" role="dialog" aria-modal="true" aria-labelledby="workout-end-title">
      <div class="workout-confirm-modal-icon">
        <span class="material-symbols-rounded">check_circle</span>
      </div>
      <h3 id="workout-end-title" class="workout-confirm-modal-title">${t('workout.screen.endWorkoutConfirm')}</h3>
      <p class="workout-confirm-modal-text">${t('workout.screen.endWorkoutConfirmText')}</p>
      <div class="workout-confirm-modal-actions">
        <button
          type="button"
          onclick="closeWorkoutEndConfirmModal()"
          class="workout-confirm-btn workout-confirm-btn--secondary"
        >
          ${t('common.cancel')}
        </button>
        <button
          type="button"
          onclick="closeWorkoutEndConfirmModal(); completeWorkout();"
          class="workout-confirm-btn workout-confirm-btn--primary"
        >
          ${t('workout.screen.finishWorkout')}
        </button>
      </div>
    </div>
  `;

  document.body.appendChild(modal);

  // Focus trap
  setTimeout(() => {
    const firstBtn = modal.querySelector('.workout-confirm-btn--secondary');
    if (firstBtn) firstBtn.focus();
  }, 100);

  // Escape to close
  modal.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      closeWorkoutEndConfirmModal();
    }
  });

  // Click outside to close
  modal.addEventListener('click', (e) => {
    if (e.target === modal) {
      closeWorkoutEndConfirmModal();
    }
  });
}

/**
 * Close workout end confirmation modal
 */
function closeWorkoutEndConfirmModal() {
  const modal = document.getElementById('workout-end-confirm-modal');
  if (modal) {
    modal.classList.add('closing');
    setTimeout(() => modal.remove(), 200);
  }
}

// ==================== EXERCISES BOTTOM SHEET ====================

let exercisesSheetOpen = false;

/**
 * Open exercises overview bottom sheet
 */
function openExercisesSheet() {
  if (exercisesSheetOpen) return;
  exercisesSheetOpen = true;

  // Entferne existierendes Sheet falls vorhanden
  const existing = document.getElementById('exercises-overview-sheet');
  if (existing) existing.remove();

  const sheet = document.createElement('div');
  sheet.id = 'exercises-overview-sheet';
  sheet.className = 'exercises-sheet-overlay';
  sheet.innerHTML = `
    <div class="exercises-sheet" role="dialog" aria-modal="true" aria-labelledby="exercises-sheet-title">
      <div class="exercises-sheet-header">
        <div class="exercises-sheet-drag-handle"></div>
        <h3 id="exercises-sheet-title" class="exercises-sheet-title">${t('workout.screen.exercisesSheetTitle')}</h3>
        <button
          type="button"
          onclick="closeExercisesSheet()"
          class="exercises-sheet-close"
          aria-label="${t('common.close')}"
        >
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
      <div class="exercises-sheet-content">
        ${renderExercisesSheetList()}
      </div>
    </div>
  `;

  document.body.appendChild(sheet);
  document.body.style.overflow = 'hidden';

  // Animate in
  requestAnimationFrame(() => {
    sheet.classList.add('active');
  });

  // Setup swipe to close
  setupExercisesSheetSwipe(sheet);

  // Escape to close
  sheet.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      closeExercisesSheet();
    }
  });

  // Click outside to close
  sheet.addEventListener('click', (e) => {
    if (e.target === sheet) {
      closeExercisesSheet();
    }
  });

  triggerHapticFeedback('light');
}

/**
 * Close exercises overview bottom sheet
 */
function closeExercisesSheet() {
  const sheet = document.getElementById('exercises-overview-sheet');
  if (!sheet) return;

  sheet.classList.remove('active');
  sheet.classList.add('closing');

  setTimeout(() => {
    sheet.remove();
    document.body.style.overflow = '';
    exercisesSheetOpen = false;
  }, 300);
}

/**
 * Render exercises list for the bottom sheet
 */
function renderExercisesSheetList() {
  if (!activeWorkout) return '';

  return `
    <div class="exercises-sheet-list">
      ${activeWorkout.exercises.map((ex, index) => {
        const isActive = index === activeWorkout.currentExerciseIndex;
        const isCompleted = ex.status === 'completed';
        const setsProgress = `${ex.completedSets.length}/${ex.targetSets}`;

        return `
          <button
            type="button"
            class="exercises-sheet-item ${isActive ? 'active' : ''} ${isCompleted ? 'completed' : ''}"
            onclick="selectExerciseFromSheet(${index})"
            aria-current="${isActive ? 'true' : 'false'}"
          >
            <div class="exercises-sheet-item-number ${isCompleted ? 'completed' : ''}">
              ${isCompleted
                ? '<span class="material-symbols-rounded">check</span>'
                : index + 1
              }
            </div>
            <div class="exercises-sheet-item-info">
              <div class="exercises-sheet-item-name">${ex.exerciseName}</div>
              <div class="exercises-sheet-item-target">${ex.targetSets} × ${ex.targetReps}</div>
            </div>
            <div class="exercises-sheet-item-status">
              <span class="exercises-sheet-item-progress">${setsProgress}</span>
              ${isActive ? '<span class="material-symbols-rounded exercises-sheet-item-active-icon">play_arrow</span>' : ''}
            </div>
          </button>
        `;
      }).join('')}
    </div>
  `;
}

/**
 * Select exercise from sheet and close it
 */
function selectExerciseFromSheet(index) {
  closeExercisesSheet();
  // Kleine Verzögerung für smoothe Animation
  setTimeout(() => {
    goToExercise(index);
  }, 150);
}

/**
 * Setup swipe to close for exercises sheet
 */
function setupExercisesSheetSwipe(overlay) {
  const sheet = overlay.querySelector('.exercises-sheet');
  const header = sheet.querySelector('.exercises-sheet-header');
  if (!header) return;

  let startY = 0;
  let currentY = 0;
  let isDragging = false;
  let startTime = 0;

  header.addEventListener('touchstart', (e) => {
    startY = e.touches[0].clientY;
    startTime = Date.now();
    isDragging = true;
    sheet.style.transition = 'none';
  }, { passive: true });

  header.addEventListener('touchmove', (e) => {
    if (!isDragging) return;
    currentY = e.touches[0].clientY;
    const deltaY = currentY - startY;

    if (deltaY > 0) {
      e.preventDefault();
      const resistance = 1 - (deltaY / window.innerHeight) * 0.5;
      sheet.style.transform = `translateY(${deltaY * resistance}px)`;
    }
  }, { passive: false });

  header.addEventListener('touchend', () => {
    if (!isDragging) return;

    const deltaY = currentY - startY;
    const duration = Date.now() - startTime;
    const velocity = deltaY / duration;

    sheet.style.transition = '';
    sheet.style.transform = '';

    if (deltaY > 100 || (velocity > 0.5 && deltaY > 30)) {
      closeExercisesSheet();
    }

    isDragging = false;
    startY = 0;
    currentY = 0;
  });
}

// ==================== SET MANAGEMENT ====================

/**
 * Log set from input fields
 */
function logSetFromInput() {
  const repsInput = document.getElementById('reps-input');
  const weightInput = document.getElementById('weight-input');

  const reps = parseInt(repsInput.value);
  const weight = weightInput.value ? parseFloat(weightInput.value) : null;

  if (!reps || reps <= 0) {
    if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Bitte gib die Anzahl der Wiederholungen ein');
  }
    repsInput.focus();
    return;
  }

  logSet(reps, weight);

  // Clear inputs
  repsInput.value = '';
  weightInput.value = '';
  repsInput.focus();
}

/**
 * Log a set
 */
function logSet(reps, weight = null) {
  if (!activeWorkout) return;

  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!currentExercise) return;

  // Add set
  currentExercise.completedSets.push({
    reps: reps,
    weight: weight,
    completedAt: firebase.firestore.Timestamp.now()
  });

  // Update status
  if (currentExercise.status === 'not-started') {
    currentExercise.status = 'in-progress';
  }

  // Check if target sets reached - auto advance to next exercise
  const exerciseJustCompleted = currentExercise.completedSets.length >= currentExercise.targetSets;
  if (exerciseJustCompleted) {
    currentExercise.status = 'completed';
  }

  saveActiveWorkout();

  // Haptic feedback
  triggerHapticFeedback('medium');

  // Start rest timer if configured and not last set of this exercise
  if (currentExercise.targetRest && !exerciseJustCompleted) {
    startRestTimer(currentExercise.targetRest);
  }

  // Auto-advance to next exercise when completed
  if (exerciseJustCompleted) {
    const isLastExercise = activeWorkout.currentExerciseIndex >= activeWorkout.exercises.length - 1;
    if (!isLastExercise) {
      // Gehe zur nächsten Übung
      setTimeout(() => {
        goToExercise(activeWorkout.currentExerciseIndex + 1);
        if (typeof showEdgeFeedback === 'function') {
          showEdgeFeedback('success', t('workout.exercise.next'));
        }
      }, 300);
    } else {
      // Letzte Übung fertig - re-render und zeige Finish-Option
      renderWorkoutScreen();
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('success', t('workout.screen.finishWorkout'));
      }
    }
  } else {
    renderWorkoutScreen();
  }

  console.log('✅ Set logged:', reps, 'reps', weight ? `@ ${weight}kg` : '');
}

/**
 * Delete a set
 */
function deleteSet(exerciseIndex, setIndex) {
  if (!confirm('Diesen Satz wirklich löschen?')) return;

  const exercise = activeWorkout.exercises[exerciseIndex];
  if (!exercise) return;

  exercise.completedSets.splice(setIndex, 1);

  // Update status
  if (exercise.completedSets.length === 0) {
    exercise.status = 'not-started';
  } else {
    exercise.status = 'in-progress';
  }

  saveActiveWorkout();
  renderWorkoutScreen();
  triggerHapticFeedback('light');
}

// ==================== NAVIGATION ====================

/**
 * Go to specific exercise
 */
function goToExercise(index) {
  if (index < 0 || index >= activeWorkout.exercises.length) return;

  // Mark current as in-progress if not completed
  const current = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (current && current.completedSets.length > 0 && current.status !== 'completed') {
    current.status = 'in-progress';
  }

  activeWorkout.currentExerciseIndex = index;

  // Mark new exercise as in-progress if not started
  const newExercise = activeWorkout.exercises[index];
  if (newExercise && newExercise.status === 'not-started') {
    newExercise.status = 'in-progress';
  }

  cancelRestTimer();
  saveActiveWorkout();
  renderWorkoutScreen();
  triggerHapticFeedback('light');

  // Scroll to top
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

/**
 * Go to next exercise
 * Bei der letzten Übung wird der Finish Flow getriggert
 */
function goToNextExercise() {
  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!currentExercise || currentExercise.completedSets.length === 0) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workout.setLogger.atLeastOneSet'));
    }
    return;
  }

  // Wenn letzte Übung: Finish Flow triggern
  if (activeWorkout.currentExerciseIndex >= activeWorkout.exercises.length - 1) {
    confirmEndWorkout();
    return;
  }

  goToExercise(activeWorkout.currentExerciseIndex + 1);
}

/**
 * Go to previous exercise
 */
function goToPreviousExercise() {
  if (activeWorkout.currentExerciseIndex > 0) {
    goToExercise(activeWorkout.currentExerciseIndex - 1);
  }
}

// ==================== REST TIMER ====================

/**
 * Start rest timer
 */
function startRestTimer(seconds) {
  cancelRestTimer(); // Clear any existing timer

  restTimerRemaining = seconds;

  // Create timer element
  const existing = document.getElementById('rest-timer');
  if (existing) existing.remove();

  const timer = document.createElement('div');
  timer.id = 'rest-timer';
  // Add focus-mode class if sticky bar is present
  const hasStickyBar = document.querySelector('.workout-sticky-bar');
  timer.className = hasStickyBar ? 'rest-timer rest-timer--with-sticky' : 'rest-timer';
  document.body.appendChild(timer);

  // Update display
  updateRestTimerDisplay();

  // Start countdown
  restTimerInterval = setInterval(() => {
    restTimerRemaining--;
    updateRestTimerDisplay();

    if (restTimerRemaining <= 0) {
      cancelRestTimer();
      triggerHapticFeedback('heavy');
    }
  }, 1000);
}

/**
 * Update rest timer display
 */
function updateRestTimerDisplay() {
  const timer = document.getElementById('rest-timer');
  if (!timer) return;

  const minutes = Math.floor(restTimerRemaining / 60);
  const seconds = restTimerRemaining % 60;
  const timeStr = `${minutes}:${seconds.toString().padStart(2, '0')}`;

  timer.innerHTML = `
    <div class="rest-timer-countdown">${timeStr}</div>
    <div class="rest-timer-label">Pause</div>
    <button onclick="cancelRestTimer()" class="skip-rest-btn">
      Skip
    </button>
  `;
}

/**
 * Cancel rest timer
 */
function cancelRestTimer() {
  if (restTimerInterval) {
    clearInterval(restTimerInterval);
    restTimerInterval = null;
  }

  const timer = document.getElementById('rest-timer');
  if (timer) timer.remove();

  restTimerRemaining = 0;
}

function confirmReplaceActiveWorkout() {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Du hast bereits ein aktives Workout. Bitte fortsetzen oder abbrechen.');
  }
  ensureActiveWorkoutBanner();
  if (typeof showView === 'function') {
    showView('workout');
  }
  return false;
}

// ==================== UTILITIES ====================

/**
 * Calculate workout progress
 */
function calculateProgress() {
  if (!activeWorkout) return { completed: 0, total: 0, percentage: 0 };

  const total = activeWorkout.exercises.length;
  const completed = activeWorkout.exercises.filter(ex => ex.status === 'completed').length;
  const percentage = total > 0 ? (completed / total) * 100 : 0;

  return { completed, total, percentage };
}

/**
 * Format workout date
 */
function formatWorkoutDate(dateStr) {
  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(year, month - 1, day);

  const days = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
  const dayName = days[date.getDay()];

  return `${dayName}, ${day}.${month}.${year}`;
}

/**
 * Edit workout date
 */
function editWorkoutDate() {
  const newDate = prompt('Neues Datum (YYYY-MM-DD):', activeWorkout.scheduledDate);
  if (!newDate) return;

  const validDate = getValidDateString(newDate);
  if (!validDate) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Ungueltiges Datumsformat. Bitte verwende YYYY-MM-DD');
    }
    return;
  }

  activeWorkout.scheduledDate = validDate;
  saveActiveWorkout();
  renderWorkoutScreen();
}

/**
 * Generate temporary ID
 */
function generateTempId() {
  return 'temp-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
}

/**
 * Trigger haptic feedback
 */
function triggerHapticFeedback(type = 'light') {
  if (!('vibrate' in navigator)) return;

  const patterns = {
    light: 10,
    medium: 20,
    heavy: [30, 10, 30]
  };

  navigator.vibrate(patterns[type] || 10);
}

/**
 * Format date to YYYY-MM-DD
 */
function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function getValidDateString(dateStr) {
  if (typeof dateStr !== 'string') return null;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return null;

  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(year, month - 1, day);

  if (Number.isNaN(date.getTime())) return null;
  if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
    return null;
  }

  return dateStr;
}

function ensureValidDateString(dateStr) {
  const valid = getValidDateString(dateStr);
  if (valid) return valid;
  return formatDate(new Date());
}

console.log('✅ Workout engine loaded');

// Global exports
window.checkActiveWorkout = checkActiveWorkout;
window.ensureActiveWorkoutBanner = ensureActiveWorkoutBanner;
window.openExercisesSheet = openExercisesSheet;
window.closeExercisesSheet = closeExercisesSheet;
window.selectExerciseFromSheet = selectExerciseFromSheet;
window.toggleCompletedSets = toggleCompletedSets;
window.confirmEndWorkout = confirmEndWorkout;
window.closeWorkoutEndConfirmModal = closeWorkoutEndConfirmModal;
window.toggleExerciseAccordion = toggleExerciseAccordion;
