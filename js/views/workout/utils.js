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
  if (typeof formatDateLongText === 'function') return formatDateLongText(date, true);
  return date.toLocaleDateString();
}

/**
 * Edit workout date
 */
function editWorkoutDate() {
  const newDate = prompt(t('workout.editDate.prompt'), activeWorkout.scheduledDate);
  if (!newDate) return;

  const validDate = getValidDateString(newDate);
  if (!validDate) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workout.editDate.error'));
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
  if (typeof getSettingValue === 'function' && !getSettingValue('hapticsEnabled')) return;

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

// ========================================
// SAVE WORKOUT AS PLAN
// ========================================

function askSaveWorkoutAsPlan(workoutExercises) {
  if (!confirm('Workout als Plan speichern?')) return;
  openPlanModalWithExercises(workoutExercises);
}

function openPlanModalWithExercises(workoutExercises) {
  if (typeof openAddPlanModal !== 'function') return;

  // Open the plan modal fresh
  openAddPlanModal();

  // Pre-fill exercises into currentPlan
  if (typeof currentPlan !== 'undefined' && currentPlan) {
    currentPlan.items = workoutExercises.map(ex => ({
      exerciseId: ex.exerciseId,
      target: {
        sets: ex.targetSets || 3,
        reps: ex.targetReps || '10'
      }
    }));

    if (typeof renderPlanExercises === 'function') {
      renderPlanExercises();
    }
  }
}

// ========================================
// ADD/REMOVE EXERCISES DURING WORKOUT
// ========================================

let workoutPickerMuscleFilter = 'all';

function openAddExerciseToWorkout() {
  // Use existing exercise picker bottom sheet pattern
  const existing = document.getElementById('workout-exercise-picker-sheet');
  if (existing) existing.remove();

  workoutPickerMuscleFilter = 'all';
  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];

  const muscleFilters = ['all', 'chest', 'back', 'shoulders', 'biceps', 'triceps', 'core', 'legs', 'calf'];
  const muscleNames = typeof getMuscleNames === 'function' ? getMuscleNames() : {};
  const chipsHTML = muscleFilters.map(key => {
    const label = key === 'all' ? t('plan.filters.all') : (muscleNames[key] || key);
    return `<button type="button" class="workout-picker-chip${key === 'all' ? ' active' : ''}" data-muscle="${key}" onclick="setWorkoutPickerMuscleFilter('${key}')">${label}</button>`;
  }).join('');

  const sheet = document.createElement('div');
  sheet.id = 'workout-exercise-picker-sheet';
  sheet.className = 'exercises-sheet-overlay';
  sheet.innerHTML = `
    <div class="exercises-sheet" role="dialog" aria-modal="true">
      <div class="exercises-sheet-header">
        <div class="exercises-sheet-drag-handle"></div>
        <h3 class="exercises-sheet-title">${t('workout.screen.addExercise')}</h3>
        <button type="button" onclick="closeWorkoutExercisePicker()" class="exercises-sheet-close" aria-label="${t('common.close')}">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
      <div class="workout-picker-controls">
        <div class="workout-picker-search">
          <span class="material-symbols-rounded">search</span>
          <input type="text" id="workout-exercise-search" placeholder="${t('workout.screen.searchExercise')}"
            oninput="filterWorkoutExercisePicker(this.value)" />
        </div>
        <div class="workout-picker-chips">${chipsHTML}</div>
      </div>
      <div class="exercises-sheet-content">
        <div id="workout-exercise-picker-list" class="exercises-sheet-list">
          ${renderWorkoutExercisePickerList(exercises, '')}
        </div>
      </div>
    </div>
  `;

  document.body.appendChild(sheet);
  document.body.style.overflow = 'hidden';
  requestAnimationFrame(() => sheet.classList.add('active'));

  sheet.addEventListener('click', (e) => {
    if (e.target === sheet) closeWorkoutExercisePicker();
  });
}

function renderWorkoutExercisePickerList(exercises, filter) {
  const search = (filter || '').toLowerCase().trim();
  const muscle = workoutPickerMuscleFilter;

  const filtered = exercises.filter(ex => {
    if (muscle !== 'all' && !exercisePrimaryMatchesMuscle(ex, muscle)) return false;
    if (search) {
      const name = getExerciseName(ex).toLowerCase();
      const nameEn = (ex.name || '').toLowerCase();
      if (!name.includes(search) && !nameEn.includes(search)) return false;
    }
    return true;
  });

  if (filtered.length === 0) {
    return `<p style="text-align:center;color:var(--text-tertiary);padding:1.5rem 1rem;">${t('workout.screen.noExercisesFound')}</p>`;
  }

  return filtered.map(ex => `
    <button type="button" class="exercises-sheet-item" onclick="addExerciseToWorkout('${ex.id}')">
      <div class="exercises-sheet-item-number">
        <span class="material-symbols-rounded" style="font-size:18px;">add</span>
      </div>
      <div class="exercises-sheet-item-info">
        <div class="exercises-sheet-item-name">${getExerciseName(ex)}</div>
        <div class="exercises-sheet-item-target" style="font-size:0.75rem;color:var(--text-tertiary);">
          ${(ex.muscleGroups || []).map(m => typeof getMuscleNames === 'function' ? (getMuscleNames()[m] || m) : m).join(', ')}
        </div>
      </div>
    </button>
  `).join('');
}

function filterWorkoutExercisePicker(value) {
  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
  const list = document.getElementById('workout-exercise-picker-list');
  if (list) list.innerHTML = renderWorkoutExercisePickerList(exercises, value);
}

function setWorkoutPickerMuscleFilter(key) {
  workoutPickerMuscleFilter = key;
  const sheet = document.getElementById('workout-exercise-picker-sheet');
  if (sheet) {
    sheet.querySelectorAll('.workout-picker-chip').forEach(c => {
      c.classList.toggle('active', c.dataset.muscle === key);
    });
  }
  const searchInput = document.getElementById('workout-exercise-search');
  filterWorkoutExercisePicker(searchInput ? searchInput.value : '');
}

function addExerciseToWorkout(exerciseId) {
  addExerciseToWorkoutOrReplace(exerciseId);
}

function closeWorkoutExercisePicker() {
  const sheet = document.getElementById('workout-exercise-picker-sheet');
  if (!sheet) return;
  sheet.classList.remove('active');
  sheet.classList.add('closing');
  setTimeout(() => {
    sheet.remove();
    document.body.style.overflow = '';
  }, 300);
}

function removeCurrentExerciseFromWorkout() {
  if (!activeWorkout || activeWorkout.exercises.length === 0) return;
  const currentEx = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!confirm(`"${currentEx.exerciseName}" aus dem Workout entfernen?`)) return;

  activeWorkout.exercises.splice(activeWorkout.currentExerciseIndex, 1);

  // Adjust current index
  if (activeWorkout.exercises.length === 0) {
    activeWorkout.currentExerciseIndex = 0;
  } else if (activeWorkout.currentExerciseIndex >= activeWorkout.exercises.length) {
    activeWorkout.currentExerciseIndex = activeWorkout.exercises.length - 1;
  }

  // Mark new current as in-progress if needed
  if (activeWorkout.exercises.length > 0) {
    const current = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
    if (current.status === 'not-started') current.status = 'in-progress';
  }

  saveActiveWorkout();
  renderWorkoutScreen();
}

let replacingExerciseIndex = null;

function replaceCurrentExerciseInWorkout() {
  if (!activeWorkout || activeWorkout.exercises.length === 0) return;
  replacingExerciseIndex = activeWorkout.currentExerciseIndex;
  openAddExerciseToWorkout();
}

function addExerciseToWorkoutOrReplace(exerciseId) {
  if (!activeWorkout) return;
  const exercise = allExercises.find(ex => ex.id === exerciseId);
  if (!exercise) return;

  const newExercise = {
    exerciseId: exercise.id,
    exerciseName: getExerciseName(exercise),
    targetSets: 3,
    targetReps: '10',
    targetRest: 90,
    completedSets: [],
    status: 'not-started',
    notes: ''
  };

  if (replacingExerciseIndex !== null && replacingExerciseIndex < activeWorkout.exercises.length) {
    // Replace
    newExercise.status = activeWorkout.exercises[replacingExerciseIndex].status;
    activeWorkout.exercises[replacingExerciseIndex] = newExercise;
    replacingExerciseIndex = null;
  } else {
    // Add
    activeWorkout.exercises.push(newExercise);
    if (activeWorkout.exercises.length === 1) {
      activeWorkout.currentExerciseIndex = 0;
      activeWorkout.exercises[0].status = 'in-progress';
    }
  }

  saveActiveWorkout();
  closeWorkoutExercisePicker();
  renderWorkoutScreen();

  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('success', `${getExerciseName(exercise)} hinzugefügt`);
  }
}


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
window.switchToExercise = switchToExercise;
window.showWorkoutMenu = showWorkoutMenu;
window.closeWorkoutMenu = closeWorkoutMenu;
window.addEmptySet = addEmptySet;
window.confirmDiscardWorkout = confirmDiscardWorkout;
// Timer exports
window.startRestTimer = startRestTimer;
window.pauseRestTimer = pauseRestTimer;
window.resumeRestTimer = resumeRestTimer;
window.cancelRestTimer = cancelRestTimer;
window.adjustRestTimer = adjustRestTimer;
window.toggleTimerPause = toggleTimerPause;
window.openTimerModal = openTimerModal;
window.closeTimerModal = closeTimerModal;
window.adjustActiveSetValue = adjustActiveSetValue;
window.adjustWeightByCurrentStep = adjustWeightByCurrentStep;
window.handleWeightValueTap = handleWeightValueTap;
window.adjustEmomReps = adjustEmomReps;
window.openEmomRepsPicker = openEmomRepsPicker;
window.logEmomRoundReps = logEmomRoundReps;
window.logEmomRoundSkip = logEmomRoundSkip;
window.undoEmomRound = undoEmomRound;
window.duplicateLastSetST = duplicateLastSetST;
window.selectCardioRPE = selectCardioRPE;
window.adjustCardioField = adjustCardioField;
window.updateCardioPace = updateCardioPace;
window.logCardioSetFromInput = logCardioSetFromInput;
window.logRecoverySetFromInput = logRecoverySetFromInput;
