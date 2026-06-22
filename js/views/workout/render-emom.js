// ==================== RENDERING ====================

/**
 * Render workout screen - Session Tracker Layout
 * Calm, non-linear, iOS-style workout tracking
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
        <button onclick="startEmptyWorkout()" class="empty-state-btn btn-primary" style="margin-bottom:0.5rem;">
          <span class="material-symbols-rounded">add</span>
          <span>${t('workout.screen.logWorkout')}</span>
        </button>
        <button onclick="showTrainingTab ? showTrainingTab('plans') : showView('training')" class="empty-state-btn">
          <span class="material-symbols-rounded">assignment</span>
          <span>${t('workout.screen.toPlans')}</span>
        </button>
      </div>
    `;
    return;
  }

  const progress = calculateProgress();
  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];

  const hasExercises = activeWorkout.exercises.length > 0;

  const emptyWorkoutContent = `
    <div style="text-align:center;padding:2rem 1rem;">
      <span class="material-symbols-rounded" style="font-size:48px;color:var(--text-tertiary);margin-bottom:0.5rem;display:block;">add_circle</span>
      <p style="color:var(--text-secondary);margin-bottom:1rem;">${t('workout.screen.emptyHint')}</p>
      <button onclick="openAddExerciseToWorkout()" class="btn-primary" style="margin:0 auto;">
        <span class="material-symbols-rounded">add</span>
        ${t('workout.screen.addExercise')}
      </button>
    </div>`;

  const currentBlock = hasExercises ? getCurrentBlock() : null;
  const blockType = currentBlock ? currentBlock.type : 'normal';
  const isGroupBlock = blockType === 'emom' || blockType === 'superset';

  let mainContent = '';
  if (!hasExercises) {
    mainContent = emptyWorkoutContent;
  } else if (blockType === 'emom') {
    mainContent = renderEmomBlockContent(currentBlock);
  } else if (blockType === 'superset') {
    mainContent = renderSupersetBlockContent(currentBlock, currentExercise);
  } else {
    mainContent = `
      ${renderSTDetail(currentExercise)}
      ${renderSTTargetAndLastPerf(currentExercise)}
      ${renderSTSetList(currentExercise)}
    `;
  }

  container.innerHTML = `
    <div class="st-screen">
      ${renderSTHeader(progress)}
      ${hasExercises ? renderBlockSwitcher() : ''}
      ${mainContent}
      ${hasExercises ? renderWorkoutBottomActions() : ''}
    </div>
  `;

  const activePill = container.querySelector('.st-pill--active');
  if (activePill) {
    setTimeout(() => {
      activePill.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
    }, 50);
  }

  window.scrollTo(0, 0);

  if (isRestTimerActive()) {
    renderTimerWidget();
  }

  startWorkoutTimer();
}

/**
 * Elapsed timer state
 */
let workoutTimerIntervalId = null;

function getWorkoutElapsedStr() {
  if (!activeWorkout || !activeWorkout.startedAt) return '00:00';
  const startTime = activeWorkout.startedAt.toDate
    ? activeWorkout.startedAt.toDate()
    : new Date(activeWorkout.startedAt.seconds * 1000);
  const elapsed = Math.floor((Date.now() - startTime.getTime()) / 1000);
  const h = Math.floor(elapsed / 3600);
  const m = Math.floor((elapsed % 3600) / 60);
  const s = elapsed % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

function startWorkoutTimer() {
  stopWorkoutTimer();
  workoutTimerIntervalId = setInterval(() => {
    const el = document.getElementById('workout-elapsed-timer');
    if (el) el.textContent = getWorkoutElapsedStr();
  }, 1000);
}

function stopWorkoutTimer() {
  if (workoutTimerIntervalId) {
    clearInterval(workoutTimerIntervalId);
    workoutTimerIntervalId = null;
  }
}

/**
 * Session Tracker Header
 */
function renderSTHeader(progress) {
  const pct = (progress && progress.total) ? Math.round((progress.completed / progress.total) * 100) : 0;
  return `
    <div class="st-header">
      <button type="button" class="st-header-back" onclick="showView('dashboard')" aria-label="${t('common.back')}">
        <span class="material-symbols-rounded">arrow_back</span>
      </button>
      <div class="st-header-center">
        <h2 class="st-header-title">${activeWorkout.planName || t('workout.screen.freeWorkout')}</h2>
        <div class="st-header-sub">
          <span class="material-symbols-rounded" style="font-size:14px;">timer</span>
          <span id="workout-elapsed-timer">${getWorkoutElapsedStr()}</span>
          <span class="st-header-dot">&middot;</span>
          <span>${t('workout.screen.exerciseProgress', { completed: progress.completed, total: progress.total })}</span>
        </div>
      </div>
      <button type="button" class="st-header-menu" onclick="showWorkoutMenu()" aria-label="${t('workout.screen.menu')}">
        <span class="material-symbols-rounded">more_horiz</span>
      </button>
    </div>
    <div class="st-progress-track" aria-hidden="true"><div class="st-progress-fill" style="width:${pct}%"></div></div>
  `;
}

/**
 * Exercise Switcher - Horizontal scrollable Pills
 */
function renderSTSwitcher() {
  return `
    <div class="st-switcher" role="tablist">
      ${activeWorkout.exercises.map((ex, index) => {
        const isActive = index === activeWorkout.currentExerciseIndex;
        const isCompleted = ex.status === 'completed';
        const hasProgress = ex.completedSets.length > 0;
        return `
          <button
            type="button"
            class="st-pill ${isActive ? 'st-pill--active' : ''} ${isCompleted ? 'st-pill--completed' : ''} ${hasProgress && !isCompleted ? 'st-pill--progress' : ''}"
            onclick="switchToExercise(${index})"
            role="tab"
            aria-selected="${isActive}"
          >
            ${isCompleted ? '<span class="material-symbols-rounded st-pill-check">check</span>' : ''}
            <span class="st-pill-label">${ex.exerciseName}</span>
          </button>
        `;
      }).join('')}
    </div>
  `;
}

/**
 * Block Switcher — shows pills per block (grouped exercises = 1 pill)
 */
function renderBlockSwitcher() {
  const blocks = getWorkoutBlocks();
  const currentBlock = getCurrentBlock();

  const pills = blocks.map(function(block) {
    const isActive = block === currentBlock;
    const completed = isBlockCompleted(block);
    const hasProgress = block.exercises.some(function(ex) { return ex.completedSets.length > 0; });

    var label = '';
    var typeClass = '';
    if (block.type === 'emom') {
      var mins = Math.round((block.durationSec || 600) / 60);
      label = t('block.workout.blockPill.emom', { minutes: mins });
      typeClass = 'st-pill--emom';
    } else if (block.type === 'superset') {
      label = t('block.workout.blockPill.superset');
      typeClass = 'st-pill--superset';
    } else {
      label = (block.exercises[0] && block.exercises[0].exerciseName) || '';
    }

    var firstIdx = block.exerciseIndices[0];
    var classes = 'st-pill ' + typeClass;
    if (isActive) classes += ' st-pill--active';
    if (completed) classes += ' st-pill--completed';
    if (hasProgress && !completed) classes += ' st-pill--progress';

    var checkIcon = completed ? '<span class="material-symbols-rounded st-pill-check">check</span>' : '';

    return '<button type="button" class="' + classes + '" onclick="switchToBlock(' + firstIdx + ')" role="tab" aria-selected="' + isActive + '">'
      + checkIcon
      + '<span class="st-pill-label">' + label + '</span>'
      + '</button>';
  });

  return '<div class="st-switcher" role="tablist">' + pills.join('') + '</div>';
}

function switchToBlock(firstExerciseIndex) {
  if (!activeWorkout) return;
  activeWorkout.currentExerciseIndex = firstExerciseIndex;
  saveActiveWorkout();
  renderWorkoutScreen();
}

// ========================================
// EMOM RUNNER
// ========================================

let emomTimerState = null;

function renderEmomBlockContent(block) {
  if (!block) return '';

  if (isBlockCompleted(block)) {
    return renderEmomComplete(block);
  }

  if (!emomTimerState || emomTimerState.blockGroupId !== block.groupId) {
    return renderEmomPrescreen(block);
  }

  return renderEmomActive(block);
}

function renderBlockBanner(type, label, meta) {
  const iconKey = type === 'emom' ? 'timer' : 'swap_horiz';
  return `
    <div class="block-banner block-banner--${type}">
      <span class="block-banner-icon">
        <span class="material-symbols-rounded">${iconKey}</span>
      </span>
      <div class="block-banner-text">
        <div class="block-banner-label">${label}</div>
        ${meta ? `<div class="block-banner-meta">${meta}</div>` : ''}
      </div>
    </div>
  `;
}

function renderEmomPrescreen(block) {
  const durationMin = Math.round((block.durationSec || 600) / 60);
  const intervalSec = block.intervalSec || 60;
  const totalMinutes = Math.ceil((block.durationSec || 600) / intervalSec);
  const exCount = block.exercises.length;
  const isMulti = exCount > 1;
  const rounds = isMulti ? Math.ceil(totalMinutes / exCount) : null;

  const exerciseRows = block.exercises.map((ex, i) => {
    const reps = ex.targetReps || '-';
    const indexLabel = isMulti ? `<span class="emom-prescreen-exercise-num">${i + 1}</span>` : '';
    return `
      <div class="emom-prescreen-exercise">
        ${indexLabel}
        <span class="emom-prescreen-exercise-name">${ex.exerciseName}</span>
        <span class="emom-prescreen-exercise-reps">×${reps}</span>
      </div>
    `;
  }).join('');

  const rotationCaption = isMulti
    ? `<div class="emom-prescreen-rotation">
         <span class="material-symbols-rounded">sync</span>
         ${t('block.workout.emom.rotation', { rounds })}
       </div>`
    : `<div class="emom-prescreen-rotation emom-prescreen-rotation--single">
         <span class="material-symbols-rounded">repeat</span>
         ${t('block.workout.emom.prescreenEveryMinute')}
       </div>`;

  const bannerLabel = `EMOM · ${t('block.workout.emom.prescreenDuration', { minutes: durationMin })}`;
  const bannerMeta = isMulti
    ? t('block.workout.emom.bannerMetaMulti', { exercises: exCount, rounds })
    : t('block.workout.emom.prescreenEveryMinute');

  return `
    <div class="block-content block-content--emom">
      ${renderBlockBanner('emom', bannerLabel, bannerMeta)}
      <div class="emom-prescreen">
        <div class="emom-prescreen-icon">
          <span class="material-symbols-rounded" style="font-size:3rem;">timer</span>
        </div>
        <div class="emom-prescreen-title">${t('block.workout.emom.prescreenTitle')}</div>
        ${rotationCaption}
        <div class="emom-prescreen-exercises">
          ${exerciseRows}
        </div>
        <button type="button" class="emom-start-btn" onclick="startEmomTimer()">
          <span class="material-symbols-rounded">play_arrow</span>
          ${t('block.workout.emom.start')}
        </button>
        <button type="button" class="emom-skip-btn" onclick="skipEmomBlock()">
          ${t('block.workout.emom.skip')}
        </button>
      </div>
    </div>
  `;
}

function startEmomTimer() {
  const block = getCurrentBlock();
  if (!block || block.type !== 'emom') return;

  const firstEx = block.exercises[0];
  emomTimerState = {
    blockGroupId: block.groupId,
    startedAt: Date.now(),
    durationSec: block.durationSec || 600,
    intervalSec: block.intervalSec || 60,
    tickId: null,
    lastMinute: -1,
    // Reps the user is about to log for the current round. Defaults to target,
    // gets reset to the next exercise's target whenever the minute rolls over.
    currentRoundReps: parseInt(firstEx?.targetReps, 10) || 0,
    // Status of the most recent log within the current minute. Cleared on
    // minute advance. Used to render the success/skipped panel + undo it.
    lastLogged: null
  };

  block.exercises.forEach(ex => { ex.status = 'in-progress'; });
  saveActiveWorkout();

  renderWorkoutScreen();
  startEmomTick();
}

function startEmomTick() {
  if (emomTimerState && emomTimerState.tickId) {
    clearInterval(emomTimerState.tickId);
  }
  if (!emomTimerState) return;

  emomTimerState.tickId = setInterval(() => {
    if (!emomTimerState) return;
    const elapsed = (Date.now() - emomTimerState.startedAt) / 1000;

    if (elapsed >= emomTimerState.durationSec) {
      completeEmomBlock();
      return;
    }

    const currentMinute = Math.floor(elapsed / emomTimerState.intervalSec);
    if (currentMinute !== emomTimerState.lastMinute) {
      const isFirstTick = emomTimerState.lastMinute === -1;
      emomTimerState.lastMinute = currentMinute;
      // Reset the reps counter to the new minute's exercise target
      const block = getCurrentBlock();
      if (block && block.exercises.length) {
        const exIdx = currentMinute % block.exercises.length;
        const exTarget = parseInt(block.exercises[exIdx]?.targetReps, 10);
        emomTimerState.currentRoundReps = Number.isFinite(exTarget) ? exTarget : 0;
      }
      // Clear last-log status so the stepper reappears for the new round.
      // On first tick we don't need to re-render (initial render already drew the stepper).
      if (!isFirstTick && emomTimerState.lastLogged) {
        emomTimerState.lastLogged = null;
        renderWorkoutScreen();
      } else {
        const repsValueEl = document.getElementById('emom-reps-value');
        if (repsValueEl) repsValueEl.textContent = emomTimerState.currentRoundReps;
      }
      if (typeof triggerHapticFeedback === 'function') {
        triggerHapticFeedback('medium');
      }
    }

    updateEmomTimerUI(elapsed);
  }, 250);
}

function updateEmomTimerUI(elapsedSec) {
  if (!emomTimerState) return;

  const { durationSec, intervalSec } = emomTimerState;
  const totalMinutes = Math.ceil(durationSec / intervalSec);
  const currentMinute = Math.floor(elapsedSec / intervalSec) + 1;
  const timeInMinute = elapsedSec % intervalSec;
  const remainingInMinute = intervalSec - timeInMinute;
  const totalRemaining = durationSec - elapsedSec;
  const minuteProgressPct = Math.min(100, Math.max(0, (timeInMinute / intervalSec) * 100));

  const block = getCurrentBlock();
  if (!block) return;
  const exCount = block.exercises.length;
  const currentExIdx = (currentMinute - 1) % exCount;
  const nextExIdx = currentMinute % exCount;
  const currentEx = block.exercises[currentExIdx];
  const nextEx = block.exercises[nextExIdx];

  const timerEl = document.getElementById('emom-timer-value');
  const minuteEl = document.getElementById('emom-minute-label');
  const currentNameEl = document.getElementById('emom-current-name');
  const currentTargetEl = document.getElementById('emom-current-target');
  const nextHintEl = document.getElementById('emom-next-hint');
  const totalEl = document.getElementById('emom-total-remaining');
  const progressFillEl = document.getElementById('emom-minute-progress-fill');
  const bannerMetaEl = document.querySelector('.block-content--emom .block-banner-meta');
  const bannerLabelEl = document.querySelector('.block-content--emom .block-banner-label');

  const isMulti = exCount > 1;
  const totalRounds = isMulti ? Math.ceil(totalMinutes / exCount) : null;
  const currentRound = isMulti ? Math.ceil(Math.min(currentMinute, totalMinutes) / exCount) : null;

  if (timerEl) timerEl.textContent = formatEmomTime(remainingInMinute);
  if (minuteEl) minuteEl.textContent = t('block.workout.emom.minute', { current: Math.min(currentMinute, totalMinutes), total: totalMinutes });
  if (currentNameEl) currentNameEl.textContent = currentEx?.exerciseName || '';
  if (currentTargetEl) currentTargetEl.textContent = t('block.workout.emom.targetReps', { reps: currentEx?.targetReps || '-' });
  if (nextHintEl) nextHintEl.textContent = t('block.workout.emom.next', { name: nextEx?.exerciseName || '', reps: nextEx?.targetReps || '-' });
  if (totalEl) totalEl.textContent = t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) });
  if (progressFillEl) progressFillEl.style.width = `${minuteProgressPct}%`;
  if (bannerLabelEl) bannerLabelEl.textContent = `EMOM · ${t('block.workout.emom.minute', { current: Math.min(currentMinute, totalMinutes), total: totalMinutes })}`;
  if (bannerMetaEl) {
    bannerMetaEl.textContent = isMulti
      ? `${t('block.workout.emom.round', { current: currentRound, total: totalRounds })} · ${t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) })}`
      : t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) });
  }
}

function formatEmomTime(seconds) {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

function renderEmomActive(block) {
  const elapsed = (Date.now() - emomTimerState.startedAt) / 1000;
  const { durationSec, intervalSec } = emomTimerState;
  const totalMinutes = Math.ceil(durationSec / intervalSec);
  const currentMinute = Math.min(Math.floor(elapsed / intervalSec) + 1, totalMinutes);
  const timeInMinute = elapsed % intervalSec;
  const remainingInMinute = intervalSec - timeInMinute;
  const totalRemaining = durationSec - elapsed;
  const minuteProgressPct = Math.min(100, Math.max(0, (timeInMinute / intervalSec) * 100));

  const exCount = block.exercises.length;
  const isMulti = exCount > 1;
  const currentExIdx = (currentMinute - 1) % exCount;
  const nextExIdx = currentMinute % exCount;
  const currentEx = block.exercises[currentExIdx];
  const nextEx = block.exercises[nextExIdx];

  // For round-robin EMOMs: round number = ceil(currentMinute / exCount)
  const totalRounds = isMulti ? Math.ceil(totalMinutes / exCount) : null;
  const currentRound = isMulti ? Math.ceil(currentMinute / exCount) : null;

  const bannerLabel = `EMOM · ${t('block.workout.emom.minute', { current: currentMinute, total: totalMinutes })}`;
  const bannerMeta = isMulti
    ? `${t('block.workout.emom.round', { current: currentRound, total: totalRounds })} · ${t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) })}`
    : t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) });

  return `
    <div class="block-content block-content--emom">
      <div id="emom-banner-wrap">
        ${renderBlockBanner('emom', bannerLabel, bannerMeta)}
      </div>
      <div class="emom-minute-progress" aria-hidden="true">
        <div class="emom-minute-progress-fill" id="emom-minute-progress-fill" style="width: ${minuteProgressPct}%"></div>
      </div>
      <div class="emom-active">
        <div class="emom-minute-label" id="emom-minute-label">
          ${t('block.workout.emom.minute', { current: currentMinute, total: totalMinutes })}
        </div>
        <div class="emom-timer-display" id="emom-timer-value">
          ${formatEmomTime(remainingInMinute)}
        </div>
        <div class="emom-timer-sub">${t('block.workout.emom.remainingInMinute')}</div>

        <div class="emom-current-exercise">
          <div class="emom-current-exercise-name" id="emom-current-name">${currentEx?.exerciseName || ''}</div>
          <div class="emom-current-exercise-target" id="emom-current-target">${t('block.workout.emom.targetReps', { reps: currentEx?.targetReps || '-' })}</div>
        </div>

        ${renderEmomLoggingArea()}

        <div class="emom-next-hint" id="emom-next-hint">
          ${t('block.workout.emom.next', { name: nextEx?.exerciseName || '', reps: nextEx?.targetReps || '-' })}
        </div>
        <div class="emom-total-remaining" id="emom-total-remaining">
          ${t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) })}
        </div>
      </div>
    </div>
  `;
}

/**
 * Render either the rep-stepper + log buttons (default) or the status panel
 * (after the user logged or skipped this round).
 */
function renderEmomLoggingArea() {
  const logged = emomTimerState && emomTimerState.lastLogged;
  if (logged) {
    const isSkip = logged.kind === 'skip';
    const variant = isSkip ? 'skipped' : 'success';
    const titleText = isSkip
      ? t('block.workout.emom.skippedTitle')
      : t('block.workout.emom.loggedTitle', { reps: logged.reps });
    const iconKey = isSkip ? 'close' : 'check';
    return `
      <button type="button"
              class="emom-log-status emom-log-status--${variant}"
              onclick="undoEmomRound()"
              aria-label="${t('block.workout.emom.undoLog')}">
        <span class="emom-log-status-icon">
          <span class="material-symbols-rounded">${iconKey}</span>
        </span>
        <span class="emom-log-status-text">
          <span class="emom-log-status-title">${titleText}</span>
          <span class="emom-log-status-hint">${t('block.workout.emom.tapToUndo')}</span>
        </span>
        <span class="material-symbols-rounded emom-log-status-undo">undo</span>
      </button>
    `;
  }

  return `
    <div class="emom-reps-stepper" role="group" aria-label="${t('block.workout.emom.actualReps')}">
      <button type="button" class="emom-reps-btn" onclick="adjustEmomReps(-1)" aria-label="-1">
        <span class="material-symbols-rounded">remove</span>
      </button>
      <button type="button" class="emom-reps-value" id="emom-reps-value-btn" onclick="openEmomRepsPicker()">
        <span id="emom-reps-value">${emomTimerState.currentRoundReps}</span>
        <span class="emom-reps-unit">${t('workout.setLogger.reps')}</span>
      </button>
      <button type="button" class="emom-reps-btn" onclick="adjustEmomReps(1)" aria-label="+1">
        <span class="material-symbols-rounded">add</span>
      </button>
    </div>

    <div class="emom-log-buttons">
      <button type="button" class="emom-log-btn emom-log-btn--done" onclick="logEmomRoundReps()">
        <span class="material-symbols-rounded">check</span>
        ${t('block.workout.emom.logReps')}
      </button>
      <button type="button" class="emom-log-btn emom-log-btn--missed" onclick="logEmomRoundSkip()">
        <span class="material-symbols-rounded">close</span>
        ${t('block.workout.emom.skipRound')}
      </button>
    </div>
  `;
}

/**
 * Adjust the reps counter for the current EMOM round (+1 / -1).
 */
function adjustEmomReps(delta) {
  if (!emomTimerState) return;
  const next = Math.max(0, (emomTimerState.currentRoundReps || 0) + delta);
  emomTimerState.currentRoundReps = next;
  const valueEl = document.getElementById('emom-reps-value');
  if (valueEl) valueEl.textContent = next;
  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('light');
}

/**
 * Open the number picker so the user can type the actual reps directly.
 */
function openEmomRepsPicker() {
  if (!emomTimerState) return;
  if (typeof openNumberPicker !== 'function') return;
  openNumberPicker({
    type: 'reps',
    initialValue: emomTimerState.currentRoundReps || 0,
    onConfirm: (newValue) => {
      emomTimerState.currentRoundReps = Math.max(0, parseInt(newValue, 10) || 0);
      const valueEl = document.getElementById('emom-reps-value');
      if (valueEl) valueEl.textContent = emomTimerState.currentRoundReps;
    }
  });
}

/**
 * Internal: write a completed round to the active exercise.
 * Returns metadata so the caller can store it for the undo flow.
 */
function _commitEmomRound(reps) {
  if (!emomTimerState || !activeWorkout) return null;
  const block = getCurrentBlock();
  if (!block) return null;

  const elapsed = (Date.now() - emomTimerState.startedAt) / 1000;
  const currentMinute = Math.floor(elapsed / emomTimerState.intervalSec);
  const exCount = block.exercises.length;
  const currentExIdx = currentMinute % exCount;
  const exercise = block.exercises[currentExIdx];
  const cleanReps = Math.max(0, parseInt(reps, 10) || 0);

  if (!exercise) return null;

  exercise.completedSets.push({
    reps: cleanReps,
    weight: null,
    completedAt: firebase.firestore.Timestamp.now(),
    emomMinute: currentMinute + 1
  });
  saveActiveWorkout();

  return {
    reps: cleanReps,
    exerciseIdx: currentExIdx,
    minute: currentMinute + 1
  };
}

/** Log the current round with the value the user dialled in. */
function logEmomRoundReps() {
  if (!emomTimerState) return;
  const meta = _commitEmomRound(emomTimerState.currentRoundReps);
  if (!meta) return;
  emomTimerState.lastLogged = { ...meta, kind: 'log' };
  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('success');
  renderWorkoutScreen();
}

/** Skip the round entirely (logs 0 reps). */
function logEmomRoundSkip() {
  const meta = _commitEmomRound(0);
  if (!meta) return;
  emomTimerState.lastLogged = { ...meta, kind: 'skip' };
  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('light');
  renderWorkoutScreen();
}

/** Undo the most recent EMOM round (triggered by tapping the status panel). */
function undoEmomRound() {
  if (!emomTimerState || !emomTimerState.lastLogged || !activeWorkout) return;
  const block = getCurrentBlock();
  if (!block) return;

  const { exerciseIdx } = emomTimerState.lastLogged;
  const exercise = block.exercises[exerciseIdx];
  if (exercise && exercise.completedSets.length) {
    exercise.completedSets.pop();
    saveActiveWorkout();
  }

  emomTimerState.lastLogged = null;
  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('light');
  renderWorkoutScreen();
}

function completeEmomBlock() {
  if (emomTimerState && emomTimerState.tickId) {
    clearInterval(emomTimerState.tickId);
  }

  const block = getCurrentBlock();
  if (block) {
    block.exercises.forEach(ex => { ex.status = 'completed'; });
  }

  emomTimerState = null;
  saveActiveWorkout();

  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('success');
  }

  renderWorkoutScreen();
  autoAdvanceToNextBlock();
}

function skipEmomBlock() {
  const block = getCurrentBlock();
  if (block) {
    block.exercises.forEach(ex => { ex.status = 'completed'; });
  }
  emomTimerState = null;
  saveActiveWorkout();
  renderWorkoutScreen();
  autoAdvanceToNextBlock();
}

function renderEmomComplete(block) {
  const blockType = block && block.type === 'superset' ? 'superset' : 'emom';
  const bannerLabel = blockType === 'superset' ? 'Superset' : 'EMOM';
  return `
    <div class="block-content block-content--${blockType} block-content--done">
      ${renderBlockBanner(blockType, bannerLabel, t('block.workout.emom.blockComplete'))}
      <div class="emom-complete">
        <div class="emom-complete-icon">
          <span class="material-symbols-rounded">check_circle</span>
        </div>
        <div class="emom-complete-title">${t('block.workout.emom.blockComplete')}</div>
        <button type="button" class="emom-complete-btn" onclick="autoAdvanceToNextBlock()">
          <span class="material-symbols-rounded">arrow_forward</span>
        </button>
      </div>
    </div>
  `;
}

function autoAdvanceToNextBlock() {
  const blocks = getWorkoutBlocks();
  const currentBlock = getCurrentBlock();
  const currentIdx = blocks.indexOf(currentBlock);
  const nextBlock = blocks.find((b, i) => i > currentIdx && !isBlockCompleted(b));

  if (nextBlock) {
    activeWorkout.currentExerciseIndex = nextBlock.exerciseIndices[0];
    saveActiveWorkout();
    renderWorkoutScreen();
  } else {
    const allDone = blocks.every(b => isBlockCompleted(b));
    if (allDone && typeof confirmEndWorkout === 'function') {
      confirmEndWorkout();
    }
  }
}

