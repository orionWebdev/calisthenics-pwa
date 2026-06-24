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
function logSet(reps, weight = null, holdSec = null) {
  if (!activeWorkout) return;

  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!currentExercise) return;

  // Build set data based on mode
  const setData = {
    completedAt: firebase.firestore.Timestamp.now()
  };

  if (holdSec != null && holdSec > 0) {
    setData.type = 'hold';
    setData.holdSec = holdSec;
  } else {
    setData.reps = reps;
    setData.weight = weight;
  }

  currentExercise.completedSets.push(setData);

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

  // Always re-render the set list
  renderWorkoutScreen();

  // Start rest timer if configured (separate widget, no re-render needed)
  const restSeconds = currentExercise.targetRest
    || (typeof getSettingValue === 'function' ? getSettingValue('defaultRestTimer') : 60);
  if (restSeconds) {
    startRestTimer(restSeconds);
  }


  // Superset: after logging a set, switch to next exercise in group
  const currentBlock = getCurrentBlock();
  if (currentBlock && currentBlock.type === 'superset' && !exerciseJustCompleted) {
    const exIdxInBlock = currentBlock.exerciseIndices.indexOf(activeWorkout.currentExerciseIndex);
    if (exIdxInBlock >= 0) {
      const nextInBlock = (exIdxInBlock + 1) % currentBlock.exerciseIndices.length;
      const nextGlobalIdx = currentBlock.exerciseIndices[nextInBlock];
      if (nextGlobalIdx !== activeWorkout.currentExerciseIndex) {
        setTimeout(() => {
          activeWorkout.currentExerciseIndex = nextGlobalIdx;
          saveActiveWorkout();
          renderWorkoutScreen();
        }, 400);
        return;
      }
    }
  }

  // Auto-advance to next exercise/block after completion
  if (exerciseJustCompleted) {
    if (currentBlock && (currentBlock.type === 'superset' || currentBlock.type === 'emom')) {
      if (isBlockCompleted(currentBlock)) {
        setTimeout(() => {
          autoAdvanceToNextBlock();
          if (typeof showEdgeFeedback === 'function') {
            showEdgeFeedback('success', t('workout.feedback.exerciseComplete'));
          }
        }, 800);
      } else {
        const nextInBlock = currentBlock.exerciseIndices.find(idx => {
          const ex = activeWorkout.exercises[idx];
          return ex && ex.status !== 'completed';
        });
        if (nextInBlock !== undefined) {
          setTimeout(() => {
            activeWorkout.currentExerciseIndex = nextInBlock;
            saveActiveWorkout();
            renderWorkoutScreen();
          }, 400);
        }
      }
    } else {
      const nextIndex = activeWorkout.exercises.findIndex(
        (ex, i) => i > activeWorkout.currentExerciseIndex && ex.status !== 'completed'
      );
      if (nextIndex !== -1) {
        setTimeout(() => {
          goToExercise(nextIndex);
          if (typeof showEdgeFeedback === 'function') {
            showEdgeFeedback('success', t('workout.feedback.exerciseComplete'));
          }
        }, 800);
      } else if (activeWorkout.exercises.every(ex => ex.status === 'completed')) {
        setTimeout(() => {
          confirmEndWorkout();
        }, 800);
      }
    }
  }
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
  if (!activeWorkout) return;
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

  // DO NOT cancel rest timer - it persists across exercise switches
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

// ==================== REST TIMER (Timestamp-based) ====================

/**
 * Get remaining ms from timestamp (no drift)
 */
function getRestTimerRemainingMs() {
  if (restTimerPausedRemaining > 0) return restTimerPausedRemaining;
  if (!restTimerEndAt) return 0;
  return Math.max(0, restTimerEndAt - Date.now());
}

/**
 * Check if rest timer is active (running or paused)
 */
function isRestTimerActive() {
  return restTimerEndAt !== null || restTimerPausedRemaining > 0;
}

/**
 * Check if rest timer is paused
 */
function isRestTimerPaused() {
  return restTimerPausedRemaining > 0 && restTimerEndAt === null;
}

/**
 * Start rest timer - timestamp-based (no drift)
 */
function startRestTimer(seconds) {
  cancelRestTimer();

  const ms = seconds * 1000;
  restTimerEndAt = Date.now() + ms;
  restTimerTotalMs = ms;
  restTimerPausedRemaining = 0;

  // Show the mini widget
  renderTimerWidget();
  startTimerTick();

  triggerHapticFeedback('light');
}

/**
 * Start the UI tick loop (updates every 250ms for smooth display)
 */
function startTimerTick() {
  if (restTimerTickId) clearInterval(restTimerTickId);

  restTimerTickId = setInterval(() => {
    // Guard: stop if timer was already cancelled
    if (!isRestTimerActive()) {
      clearInterval(restTimerTickId);
      restTimerTickId = null;
      return;
    }

    const remaining = getRestTimerRemainingMs();

    if (remaining <= 0 && !isRestTimerPaused()) {
      // Timer finished - clean up and notify
      clearInterval(restTimerTickId);
      restTimerTickId = null;
      restTimerEndAt = null;
      restTimerTotalMs = 0;
      restTimerPausedRemaining = 0;

      triggerHapticFeedback('heavy');
      showTimerDoneFlash();
      return;
    }

    // Update widget display
    updateTimerWidgetDisplay();
    // Update modal display if open
    updateTimerModalDisplay();
  }, 250);
}

/**
 * Pause rest timer
 */
function pauseRestTimer() {
  if (!restTimerEndAt) return;

  restTimerPausedRemaining = Math.max(0, restTimerEndAt - Date.now());
  restTimerEndAt = null;

  // Stop tick - nothing changes while paused
  if (restTimerTickId) {
    clearInterval(restTimerTickId);
    restTimerTickId = null;
  }

  updateTimerWidgetDisplay();
  updateTimerModalDisplay();
  triggerHapticFeedback('light');
}

/**
 * Resume rest timer after pause
 */
function resumeRestTimer() {
  if (restTimerPausedRemaining <= 0) return;

  restTimerEndAt = Date.now() + restTimerPausedRemaining;
  restTimerPausedRemaining = 0;

  if (!restTimerTickId) startTimerTick();

  updateTimerWidgetDisplay();
  updateTimerModalDisplay();
  triggerHapticFeedback('light');
}

/**
 * Adjust timer by delta ms (+/- 10s etc.)
 */
function adjustRestTimer(deltaMs) {
  if (!isRestTimerActive()) return;

  if (isRestTimerPaused()) {
    restTimerPausedRemaining = Math.max(1000, restTimerPausedRemaining + deltaMs);
    restTimerTotalMs = Math.max(restTimerTotalMs, restTimerPausedRemaining);
  } else if (restTimerEndAt) {
    restTimerEndAt = Math.max(Date.now() + 1000, restTimerEndAt + deltaMs);
    const newRemaining = restTimerEndAt - Date.now();
    if (newRemaining > restTimerTotalMs) restTimerTotalMs = newRemaining;
  }

  updateTimerWidgetDisplay();
  updateTimerModalDisplay();
  triggerHapticFeedback('light');
}

/**
 * Cancel rest timer
 */
function cancelRestTimer() {
  if (restTimerTickId) {
    clearInterval(restTimerTickId);
    restTimerTickId = null;
  }

  restTimerEndAt = null;
  restTimerTotalMs = 0;
  restTimerPausedRemaining = 0;

  // Remove widget immediately to prevent stale elements
  removeTimerWidget(true);
  // Close modal if open
  closeTimerModal();

  // Clean up legacy floating timer if exists
  const timer = document.getElementById('rest-timer');
  if (timer) timer.remove();
}

/**
 * Brief "done" flash when timer expires
 * State cleanup is handled by the caller (tick or cancelRestTimer)
 */
function showTimerDoneFlash() {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('success', t('workout.screen.timerDone'));
  }
  removeTimerWidget(); // animated fade-out
  closeTimerModal();
}

// ==================== TIMER MINI WIDGET (Fixed Bottom) ====================

/**
 * Render/create the mini live widget at bottom of screen
 */
function renderTimerWidget() {
  removeTimerWidget(true); // immediate removal to prevent duplicate ID conflicts

  const widget = document.createElement('div');
  widget.id = 'rest-timer-widget';
  widget.className = 'timer-widget';
  widget.onclick = openTimerModal;

  widget.innerHTML = `
    <div class="timer-widget-inner">
      <div class="timer-widget-bar">
        <div class="timer-widget-bar-fill" id="tw-bar-fill"></div>
      </div>
      <div class="timer-widget-content">
        <span class="material-symbols-rounded timer-widget-icon">timer</span>
        <div class="timer-widget-textgroup">
          <span class="timer-widget-label">Pause läuft</span>
          <span class="timer-widget-time" id="tw-time">0:00</span>
        </div>
        <button type="button" class="timer-widget-skip" onclick="event.stopPropagation(); cancelRestTimer()">
          ${t('workout.screen.skip') || 'Überspringen'}
        </button>
      </div>
    </div>
  `;

  document.body.appendChild(widget);

  // Animate in
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      widget.classList.add('timer-widget--visible');
    });
  });

  // Initial display update
  updateTimerWidgetDisplay();
}

/**
 * Remove the mini widget
 * @param {boolean} immediate - Skip fade-out animation (used when re-creating widget)
 */
function removeTimerWidget(immediate = false) {
  const widget = document.getElementById('rest-timer-widget');
  if (!widget) return;

  if (immediate) {
    widget.remove();
  } else {
    widget.classList.remove('timer-widget--visible');
    setTimeout(() => widget.remove(), 200);
  }
}

/**
 * Update widget display (called by tick)
 */
function updateTimerWidgetDisplay() {
  const barFill = document.getElementById('tw-bar-fill');
  const timeEl = document.getElementById('tw-time');
  if (!barFill || !timeEl) return;

  const remainingMs = getRestTimerRemainingMs();
  const totalMs = restTimerTotalMs || 1;
  const progressPct = Math.min(100, ((totalMs - remainingMs) / totalMs) * 100);

  const totalSec = Math.ceil(remainingMs / 1000);
  const minutes = Math.floor(totalSec / 60);
  const seconds = totalSec % 60;

  barFill.style.width = `${progressPct}%`;
  timeEl.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;

  // Paused visual indicator
  const widget = document.getElementById('rest-timer-widget');
  if (widget) {
    widget.classList.toggle('timer-widget--paused', isRestTimerPaused());
  }
}

// ==================== TIMER MODAL (Bottom Sheet) ====================

/**
 * Open timer modal (bottom sheet with full controls)
 */
function openTimerModal() {
  if (!isRestTimerActive()) return;

  // Remove existing
  const existing = document.getElementById('timer-modal-overlay');
  if (existing) { closeTimerModal(); return; }

  const overlay = document.createElement('div');
  overlay.id = 'timer-modal-overlay';
  overlay.className = 'timer-modal-overlay';
  overlay.setAttribute('role', 'dialog');
  overlay.setAttribute('aria-modal', 'true');

  overlay.innerHTML = `
    <div class="timer-modal" id="timer-modal-sheet">
      <div class="timer-modal-handle"></div>
      <div class="timer-modal-body">
        <div class="timer-modal-time-display">
          <span class="timer-modal-time" id="tm-time">0:00</span>
          <span class="timer-modal-label">${t('workout.screen.restTimer')}</span>
        </div>
        <div class="timer-modal-bar">
          <div class="timer-modal-bar-fill" id="tm-bar-fill"></div>
        </div>
        <div class="timer-modal-controls">
          <button type="button" class="timer-modal-btn timer-modal-btn--adjust" onclick="adjustRestTimer(-10000)" aria-label="${t('workout.screen.timerSub')}">
            <span>-10s</span>
          </button>
          <button type="button" class="timer-modal-btn timer-modal-btn--main" id="tm-pause-btn" onclick="toggleTimerPause()" aria-label="${t('workout.screen.timerPause')}">
            <span class="material-symbols-rounded" id="tm-pause-icon">pause</span>
          </button>
          <button type="button" class="timer-modal-btn timer-modal-btn--adjust" onclick="adjustRestTimer(10000)" aria-label="${t('workout.screen.timerAdd')}">
            <span>+10s</span>
          </button>
        </div>
        <button type="button" class="timer-modal-skip" onclick="cancelRestTimer()">
          <span class="material-symbols-rounded">skip_next</span>
          <span>${t('workout.screen.timerSkip')}</span>
        </button>
      </div>
    </div>
  `;

  // Close on overlay click
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) closeTimerModal();
  });

  // Swipe-to-close on handle
  const sheet = overlay.querySelector('.timer-modal');
  const handle = overlay.querySelector('.timer-modal-handle');
  let startY = 0, currentY = 0, dragging = false;

  const onTouchStart = (e) => {
    startY = e.touches[0].clientY;
    currentY = startY;
    dragging = true;
    sheet.style.transition = 'none';
  };
  const onTouchMove = (e) => {
    if (!dragging) return;
    currentY = e.touches[0].clientY;
    const dy = currentY - startY;
    if (dy > 0) sheet.style.transform = `translateY(${dy}px)`;
  };
  const onTouchEnd = () => {
    if (!dragging) return;
    dragging = false;
    sheet.style.transition = '';
    if (currentY - startY > 80) { closeTimerModal(); }
    else { sheet.style.transform = ''; }
  };

  if (handle) {
    handle.addEventListener('touchstart', onTouchStart, { passive: true });
    handle.addEventListener('touchmove', onTouchMove, { passive: true });
    handle.addEventListener('touchend', onTouchEnd);
  }

  document.body.appendChild(overlay);
  requestAnimationFrame(() => overlay.classList.add('active'));

  // Initial display update
  updateTimerModalDisplay();
  triggerHapticFeedback('light');
}

/**
 * Close timer modal
 */
function closeTimerModal() {
  const overlay = document.getElementById('timer-modal-overlay');
  if (!overlay) return;
  overlay.classList.remove('active');
  setTimeout(() => overlay.remove(), 250);
}

/**
 * Update modal display (called by tick)
 */
function updateTimerModalDisplay() {
  const barFill = document.getElementById('tm-bar-fill');
  const timeEl = document.getElementById('tm-time');
  const pauseIcon = document.getElementById('tm-pause-icon');
  if (!timeEl) return;

  const remainingMs = getRestTimerRemainingMs();
  const totalMs = restTimerTotalMs || 1;
  const progressPct = Math.min(100, ((totalMs - remainingMs) / totalMs) * 100);

  const totalSec = Math.ceil(remainingMs / 1000);
  const minutes = Math.floor(totalSec / 60);
  const seconds = totalSec % 60;

  if (barFill) barFill.style.width = `${progressPct}%`;
  timeEl.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;

  if (pauseIcon) {
    pauseIcon.textContent = isRestTimerPaused() ? 'play_arrow' : 'pause';
  }
}

/**
 * Toggle pause/resume from modal
 */
function toggleTimerPause() {
  if (isRestTimerPaused()) {
    resumeRestTimer();
  } else {
    pauseRestTimer();
  }
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

