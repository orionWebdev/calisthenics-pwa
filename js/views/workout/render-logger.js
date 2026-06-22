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
          <label class="input-stepper-label">${t('workout.setLogger.weight')} (${getWeightUnit()})</label>
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
                  <span class="data-label">${getWeightUnit()}</span>
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
          <span>${t('workout.exercise.next') || 'Nächste Übung'}</span>
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

function renderWorkoutBottomActions() {
  // EMOM and Superset blocks are tightly defined: rotation, round count and
  // set dots all depend on a fixed exercise list. Mutating the list mid-block
  // would corrupt that state, so the add/replace/delete actions are hidden
  // for grouped blocks. Users can leave the block, edit the plan, and restart.
  const currentBlock = getCurrentBlock();
  if (currentBlock && (currentBlock.type === 'emom' || currentBlock.type === 'superset')) {
    return '';
  }

  const idx = activeWorkout.currentExerciseIndex;
  const isLast = idx >= activeWorkout.exercises.length - 1;
  const ctaIcon = isLast ? 'check_circle' : 'arrow_forward';
  const ctaLabel = isLast ? t('workout.screen.finishWorkout') : 'Nächste Übung';
  const ctaAction = isLast ? 'finishWorkoutFromConfirm()' : ('goToExercise(' + (idx + 1) + ')');

  return `
    <div class="workout-bottom-actions">
      <button type="button" onclick="replacingExerciseIndex=null;openAddExerciseToWorkout()" class="workout-ex-action">
        <span class="material-symbols-rounded">add</span>
        <span>Hinzufügen</span>
      </button>
      <button type="button" onclick="replaceCurrentExerciseInWorkout()" class="workout-ex-action">
        <span class="material-symbols-rounded">swap_horiz</span>
        <span>Ersetzen</span>
      </button>
      <button type="button" onclick="removeCurrentExerciseFromWorkout()" class="workout-ex-action workout-ex-action--danger">
        <span class="material-symbols-rounded">delete</span>
        <span>Löschen</span>
      </button>
    </div>
    <button type="button" class="workout-next-cta" onclick="${ctaAction}">
      <span class="material-symbols-rounded">${ctaIcon}</span>
      <span>${ctaLabel}</span>
    </button>
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
                    <span class="data-label">${getWeightUnit()}</span>
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
          onclick="finishWorkoutFromConfirm()"
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

// Proceeding to finish: drop the confirm modal instantly (no close animation)
// so it never overlaps the post-workout summary that completeWorkout() opens.
function finishWorkoutFromConfirm() {
  const modal = document.getElementById('workout-end-confirm-modal');
  if (modal) modal.remove();
  completeWorkout();
}
window.finishWorkoutFromConfirm = finishWorkoutFromConfirm;

// ==================== RPE FEEDBACK MODAL ====================

let _rpeFeedbackResolve = null;
const _rpeFeedbackValues = { preWorkoutEnergy: null, postWorkoutFeeling: null, rpe: null };

function showRpeFeedbackModal() {
  return new Promise((resolve) => {
    _rpeFeedbackResolve = resolve;
    _rpeFeedbackValues.preWorkoutEnergy = null;
    _rpeFeedbackValues.postWorkoutFeeling = null;
    _rpeFeedbackValues.rpe = null;

    const existing = document.getElementById('rpe-feedback-modal');
    if (existing) existing.remove();

    const tr = typeof t === 'function' ? t : (k) => k;

    const modal = document.createElement('div');
    modal.id = 'rpe-feedback-modal';
    modal.className = 'workout-confirm-modal-overlay';

    const buildRow = (field, labelKey, hintId) => {
      return `
        <div class="rpe-feedback-section">
          <label class="rpe-feedback-label">${tr('feedback.' + labelKey)}</label>
          <div class="rpe-feedback-label-hint" id="${hintId}"></div>
          <div class="rpe-btn-row" data-field="${field}">
            ${[1,2,3,4,5].map(n =>
              `<button type="button" class="difficulty-btn" data-value="${n}" onclick="selectRpeValue('${field}', ${n})">${n}</button>`
            ).join('')}
          </div>
        </div>
      `;
    };

    modal.innerHTML = `
      <div class="workout-confirm-modal rpe-feedback-modal" role="dialog" aria-modal="true">
        <div class="workout-confirm-modal-icon">
          <span class="material-symbols-rounded">mood</span>
        </div>
        <h3 class="workout-confirm-modal-title">${tr('feedback.title')}</h3>
        <p class="workout-confirm-modal-text">${tr('feedback.subtitle')}</p>

        ${buildRow('preWorkoutEnergy', 'preEnergy', 'rpe-energy-hint')}
        ${buildRow('postWorkoutFeeling', 'postFeeling', 'rpe-feeling-hint')}
        ${buildRow('rpe', 'rpeLabel', 'rpe-rpe-hint')}

        <div class="rpe-feedback-actions">
          <button type="button" class="workout-confirm-btn workout-confirm-btn--primary" onclick="submitRpeFeedback()" id="rpe-submit-btn" disabled>
            ${tr('feedback.submit')}
          </button>
          <button type="button" class="rpe-skip-btn" onclick="skipRpeFeedback()">
            ${tr('feedback.skip')}
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(modal);

    if (typeof triggerHapticFeedback === 'function') {
      triggerHapticFeedback('light');
    }
  });
}

function selectRpeValue(field, value) {
  _rpeFeedbackValues[field] = value;

  const row = document.querySelector(`.rpe-btn-row[data-field="${field}"]`);
  if (row) {
    row.querySelectorAll('.difficulty-btn').forEach(btn => {
      btn.classList.toggle('active', parseInt(btn.dataset.value) === value);
    });
  }

  // Show hint label
  const tr = typeof t === 'function' ? t : (k) => k;
  const hintMap = { preWorkoutEnergy: 'energy', postWorkoutFeeling: 'feeling', rpe: 'rpe' };
  const hintIdMap = { preWorkoutEnergy: 'rpe-energy-hint', postWorkoutFeeling: 'rpe-feeling-hint', rpe: 'rpe-rpe-hint' };
  const hintEl = document.getElementById(hintIdMap[field]);
  if (hintEl) {
    hintEl.textContent = tr('feedback.' + hintMap[field] + '.' + value);
  }

  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('selection');
  }

  // Enable submit when all 3 are selected
  const allSelected = _rpeFeedbackValues.preWorkoutEnergy && _rpeFeedbackValues.postWorkoutFeeling && _rpeFeedbackValues.rpe;
  const submitBtn = document.getElementById('rpe-submit-btn');
  if (submitBtn) submitBtn.disabled = !allSelected;
}

function submitRpeFeedback() {
  const modal = document.getElementById('rpe-feedback-modal');
  if (modal) {
    modal.classList.add('closing');
    setTimeout(() => modal.remove(), 200);
  }
  if (_rpeFeedbackResolve) {
    _rpeFeedbackResolve({ ...(_rpeFeedbackValues) });
    _rpeFeedbackResolve = null;
  }
}

function skipRpeFeedback() {
  const modal = document.getElementById('rpe-feedback-modal');
  if (modal) {
    modal.classList.add('closing');
    setTimeout(() => modal.remove(), 200);
  }
  if (_rpeFeedbackResolve) {
    _rpeFeedbackResolve(null);
    _rpeFeedbackResolve = null;
  }
}

window.showRpeFeedbackModal = showRpeFeedbackModal;
window.selectRpeValue = selectRpeValue;
window.submitRpeFeedback = submitRpeFeedback;
window.skipRpeFeedback = skipRpeFeedback;

