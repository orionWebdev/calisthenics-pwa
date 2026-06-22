// ========================================
// SUPERSET RUNNER
// ========================================

function renderSupersetBlockContent(block, currentExercise) {
  if (!block) return '';

  if (isBlockCompleted(block)) {
    return renderEmomComplete(block);
  }

  const labels = ['A1', 'A2', 'A3', 'A4'];
  const activeExIdx = block.exercises.indexOf(currentExercise);
  const activeInBlock = activeExIdx >= 0 ? activeExIdx : 0;
  const activeEx = block.exercises[activeInBlock];
  const activeLabel = labels[activeInBlock] || 'A' + (activeInBlock + 1);

  // Compute current round = (min completed sets across exercises) + 1
  const minCompleted = Math.min(...block.exercises.map(ex => ex.completedSets.length || 0));
  const totalRounds = Math.max(...block.exercises.map(ex => ex.targetSets || 3));
  const currentRound = Math.min(totalRounds, minCompleted + 1);

  const overviewRows = block.exercises.map((ex, i) => {
    const label = labels[i] || 'A' + (i + 1);
    const targetSets = ex.targetSets || 3;
    const isActive = i === activeInBlock;
    const dots = [];
    for (let s = 0; s < targetSets; s++) {
      const done = s < ex.completedSets.length;
      const isNext = !done && s === ex.completedSets.length && i === activeInBlock;
      dots.push(`<div class="superset-set-dot ${done ? 'superset-set-dot--done' : ''} ${isNext ? 'superset-set-dot--active' : ''}">${s + 1}</div>`);
    }
    return `
      <div class="superset-exercise-row${isActive ? ' superset-exercise-row--active' : ''}">
        <span class="superset-label">${label}</span>
        <span class="superset-exercise-name">${ex.exerciseName}</span>
        <div class="superset-set-dots">${dots.join('')}</div>
      </div>
    `;
  }).join('');

  const bannerLabel = `Superset · ${block.exercises.length} ${block.exercises.length === 1 ? 'Übung' : 'Übungen'}`;
  const bannerMeta = `Runde ${currentRound} / ${totalRounds}`;

  return `
    <div class="block-content block-content--superset">
      ${renderBlockBanner('superset', bannerLabel, bannerMeta)}
      <div class="superset-overview">
        <div class="superset-pair">
          ${overviewRows}
        </div>
        <div class="superset-current-label">
          ${t('block.workout.superset.current', { label: activeLabel, name: activeEx?.exerciseName || '' })}
        </div>
      </div>
      ${renderSTDetail(activeEx)}
      ${renderSTTargetAndLastPerf(activeEx)}
      ${renderSTSetList(activeEx)}
    </div>
  `;
}

/**
 * Exercise Detail Section
 */
function renderSTDetail(exercise) {
  if (!exercise) return '';

  const exType = getWorkoutExerciseType(exercise);
  const typeLabelMap = {
    'bodyweight': t('workout.screen.bodyweight'),
    'strength': t('workout.screen.weighted'),
    'cardio': t('workout.screen.cardio') || 'Cardio',
    'recovery': t('workout.screen.recovery') || 'Recovery'
  };
  const typeLabel = typeLabelMap[exType] || t('workout.screen.weighted');

  // Muskel-Badge (workout.png: z.B. "Brust" oben rechts)
  const exMeta = (typeof allExercises !== 'undefined' && Array.isArray(allExercises))
    ? allExercises.find(e => e && e.id === exercise.exerciseId) : null;
  const primaryMuscle = (exMeta && Array.isArray(exMeta.muscleGroups)) ? exMeta.muscleGroups[0] : null;
  const muscleMap = { chest: 'Brust', back: 'Rücken', legs: 'Beine', quads: 'Beine', hamstrings: 'Beine', glutes: 'Gesäß', shoulders: 'Schultern', arms: 'Arme', biceps: 'Bizeps', triceps: 'Trizeps', core: 'Core', abs: 'Core', fullbody: 'Ganzkörper', cardio: 'Cardio' };
  const muscleBadge = primaryMuscle ? `<span class="st-detail-muscle">${muscleMap[primaryMuscle] || primaryMuscle}</span>` : '';

  return `
    <div class="st-detail">
      <div class="st-detail-info">
        <h3 class="st-detail-name">${exercise.exerciseName}</h3>
        <span class="st-detail-type">${typeLabel}</span>
      </div>
      ${muscleBadge}
    </div>
  `;
}

/**
 * Target + Last Performance Info (zwischen Detail und Set List)
 * Zeigt den Vergleich für den AKTUELLEN Satz (nächster zu loggender Satz)
 */
function renderSTTargetAndLastPerf(exercise) {
  if (!exercise) return '';

  const targetLine = getExerciseTargetLine(exercise);

  // Global last performance across all plans
  const globalPerf = getGlobalLastPerformance(exercise.exerciseId);

  let lastPerfHtml = '';
  if (globalPerf && globalPerf.sets && globalPerf.sets.length > 0) {
    const relTime = formatRelativeTime(globalPerf.date);
    const setsHtml = globalPerf.sets.map((set, i) => {
      const parts = [];
      if (set.holdSec != null && set.holdSec > 0) {
        parts.push(`${set.holdSec}${t('common.secondsShort', { n: '' }).trim() || 's'}`);
      } else {
        if (set.reps != null) parts.push(`${set.reps} ${t('workout.setLogger.reps') || 'Wdh.'}`);
        if (set.weight != null && set.weight > 0) parts.push(`${set.weight} ${getWeightUnit()}`);
      }
      if (set.duration != null) parts.push(`${set.duration} min`);
      if (set.distance != null) parts.push(`${set.distance} km`);
      return `<div class="st-last-perf-set">Set ${i + 1}: ${parts.join(' / ')}</div>`;
    }).join('');

    lastPerfHtml = `
      <div class="st-last-perf-info">
        <div class="st-last-perf-header">
          <span class="material-symbols-rounded">history</span>
          <span>${t('workout.lastPerformance') || 'Letztes Mal'} — ${relTime}</span>
        </div>
        <div class="st-last-perf-sets">${setsHtml}</div>
      </div>
    `;
  } else {
    lastPerfHtml = `
      <div class="st-last-perf-info st-last-perf-info--empty">
        <span class="material-symbols-rounded">history</span>
        <span>${t('workout.noPreviousData') || 'Keine vorherigen Daten'}</span>
      </div>
    `;
  }

  return `
    <div class="st-target-section">
      <div class="st-target-info">
        <span class="material-symbols-rounded">target</span>
        <span>${targetLine}</span>
      </div>
      ${lastPerfHtml}
    </div>
  `;
}

/**
 * Set List - Calm vertical set rows
 */
/**
 * Render cardio exercise input (duration, distance, optional RPE)
 */
function renderSTCardioInput(exercise) {
  const completed = exercise.completedSets && exercise.completedSets.length > 0;
  const set = completed ? exercise.completedSets[0] : null;

  if (completed && set) {
    // Show logged values
    const parts = [];
    if (set.duration != null) parts.push(`${set.duration} min`);
    if (set.distance != null && set.distance > 0) parts.push(`${set.distance} km`);
    if (set.rpe != null) parts.push(`RPE ${set.rpe}`);
    if (set.duration && set.distance && set.distance > 0) {
      const pace = (set.duration / set.distance).toFixed(2).replace('.', ',');
      parts.push(`${pace} min/km`);
    }
    return `
      <div class="st-set-list">
        <div class="st-cardio-done">
          <div class="st-cardio-done-values">
            ${parts.map(p => `<div class="st-cardio-done-value">${p}</div>`).join('')}
          </div>
          <div class="st-set-check st-set-check--done" style="margin: 0 auto;">
            <span class="material-symbols-rounded">check</span>
          </div>
        </div>
      </div>
    `;
  }

  // Input form
  const rpeButtons = [1, 2, 3, 4, 5].map(v =>
    `<button type="button" class="st-rpe-option" data-rpe="${v}" onclick="selectCardioRPE(${v})">${v}</button>`
  ).join('');

  return `
    <div class="st-set-list">
      <div class="st-cardio-input">
        <div class="st-cardio-field">
          <label>${t('workout.cardio.duration') || 'Dauer (Min.)'}</label>
          <div class="st-cardio-field-row">
            <button type="button" class="st-stepper-btn" onclick="adjustCardioField('cardio-duration', -1)">
              <span class="material-symbols-rounded">remove</span>
            </button>
            <input type="number" id="cardio-duration" placeholder="min" min="0" step="1" inputmode="numeric" oninput="updateCardioPace()">
            <button type="button" class="st-stepper-btn" onclick="adjustCardioField('cardio-duration', 1)">
              <span class="material-symbols-rounded">add</span>
            </button>
          </div>
        </div>
        <div class="st-cardio-field">
          <label>${t('workout.cardio.distance') || 'Distanz (km)'}</label>
          <div class="st-cardio-field-row">
            <button type="button" class="st-stepper-btn" onclick="adjustCardioField('cardio-distance', -0.5)">
              <span class="material-symbols-rounded">remove</span>
            </button>
            <input type="number" id="cardio-distance" placeholder="km" min="0" step="0.1" inputmode="decimal" oninput="updateCardioPace()">
            <button type="button" class="st-stepper-btn" onclick="adjustCardioField('cardio-distance', 0.5)">
              <span class="material-symbols-rounded">add</span>
            </button>
          </div>
          <div class="st-pace-display" id="cardio-pace-display"></div>
        </div>
        <div class="st-cardio-field">
          <label>${t('workout.cardio.rpe') || 'Belastung (1–5)'}</label>
          <div class="st-rpe-selector" id="cardio-rpe-selector">
            ${rpeButtons}
          </div>
        </div>
        <button type="button" class="st-cardio-log-btn" onclick="logCardioSetFromInput()">
          ${t('workout.cardio.log') || 'Cardio loggen'}
        </button>
      </div>
    </div>
  `;
}

/**
 * Render recovery exercise input (duration only)
 */
function renderSTRecoveryInput(exercise) {
  const completed = exercise.completedSets && exercise.completedSets.length > 0;
  const set = completed ? exercise.completedSets[0] : null;

  if (completed && set) {
    return `
      <div class="st-set-list">
        <div class="st-cardio-done">
          <div class="st-cardio-done-values">
            <div class="st-cardio-done-value">${set.duration || 0} min</div>
          </div>
          <div class="st-set-check st-set-check--done" style="margin: 0 auto;">
            <span class="material-symbols-rounded">check</span>
          </div>
        </div>
      </div>
    `;
  }

  return `
    <div class="st-set-list">
      <div class="st-recovery-input">
        <div class="st-cardio-field">
          <label>${t('workout.recovery.duration') || 'Dauer (Min.)'}</label>
          <div class="st-cardio-field-row">
            <button type="button" class="st-stepper-btn" onclick="adjustCardioField('recovery-duration', -1)">
              <span class="material-symbols-rounded">remove</span>
            </button>
            <input type="number" id="recovery-duration" placeholder="min" min="0" step="1" inputmode="numeric">
            <button type="button" class="st-stepper-btn" onclick="adjustCardioField('recovery-duration', 1)">
              <span class="material-symbols-rounded">add</span>
            </button>
          </div>
        </div>
        <button type="button" class="st-cardio-log-btn" onclick="logRecoverySetFromInput()">
          ${t('workout.recovery.log') || 'Recovery loggen'}
        </button>
      </div>
    </div>
  `;
}

/**
 * Select RPE value for cardio
 */
function selectCardioRPE(value) {
  const selector = document.getElementById('cardio-rpe-selector');
  if (!selector) return;
  selector.querySelectorAll('.st-rpe-option').forEach(btn => {
    btn.classList.toggle('active', parseInt(btn.dataset.rpe) === value);
  });
  selector.dataset.selectedRpe = value;
  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('light');
}

/**
 * Adjust a cardio/recovery field value by delta
 */
function adjustCardioField(inputId, delta) {
  const input = document.getElementById(inputId);
  if (!input) return;
  const current = parseFloat(input.value) || 0;
  const newVal = Math.max(0, Math.round((current + delta) * 10) / 10);
  input.value = newVal;
  if (inputId.includes('duration') || inputId.includes('distance')) {
    updateCardioPace();
  }
  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('light');
}

/**
 * Update pace display for cardio
 */
function updateCardioPace() {
  const durationEl = document.getElementById('cardio-duration');
  const distanceEl = document.getElementById('cardio-distance');
  const paceEl = document.getElementById('cardio-pace-display');
  if (!paceEl) return;

  const duration = parseFloat(durationEl?.value) || 0;
  const distance = parseFloat(distanceEl?.value) || 0;
  if (duration > 0 && distance > 0) {
    const pace = (duration / distance).toFixed(2).replace('.', ',');
    paceEl.textContent = `${t('workout.cardio.pace') || 'Pace'}: ${pace} min/km`;
  } else {
    paceEl.textContent = '';
  }
}

/**
 * Log cardio set from input fields
 */
function logCardioSetFromInput() {
  const duration = parseFloat(document.getElementById('cardio-duration')?.value) || 0;
  if (duration <= 0) {
    if (typeof showEdgeFeedback === 'function') showEdgeFeedback('error', t('workout.feedback.enterDuration'));
    return;
  }
  const distance = parseFloat(document.getElementById('cardio-distance')?.value) || null;
  const rpeSelector = document.getElementById('cardio-rpe-selector');
  const rpe = rpeSelector?.dataset.selectedRpe ? parseInt(rpeSelector.dataset.selectedRpe) : null;

  logCardioSet(duration, distance, rpe);
}

/**
 * Log recovery set from input fields
 */
function logRecoverySetFromInput() {
  const duration = parseFloat(document.getElementById('recovery-duration')?.value) || 0;
  if (duration <= 0) {
    if (typeof showEdgeFeedback === 'function') showEdgeFeedback('error', t('workout.feedback.enterDuration'));
    return;
  }
  logRecoverySet(duration);
}

/**
 * Log a cardio set (duration, distance, optional RPE)
 */
function logCardioSet(duration, distance, rpe) {
  if (!activeWorkout) return;
  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!currentExercise) return;

  const setData = {
    type: 'cardio',
    duration: duration,
    completedAt: firebase.firestore.Timestamp.now()
  };
  if (distance != null && distance > 0) setData.distance = distance;
  if (rpe != null) setData.rpe = rpe;

  currentExercise.completedSets.push(setData);
  currentExercise.status = 'completed';
  saveActiveWorkout();

  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('medium');
  renderWorkoutScreen();

  // Auto-advance (no rest timer for cardio)
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
    setTimeout(() => confirmEndWorkout(), 800);
  }
}

/**
 * Log a recovery set (duration only)
 */
function logRecoverySet(duration) {
  if (!activeWorkout) return;
  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!currentExercise) return;

  const setData = {
    type: 'recovery',
    duration: duration,
    completedAt: firebase.firestore.Timestamp.now()
  };

  currentExercise.completedSets.push(setData);
  currentExercise.status = 'completed';
  saveActiveWorkout();

  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('medium');
  renderWorkoutScreen();

  // Auto-advance (no rest timer for recovery)
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
    setTimeout(() => confirmEndWorkout(), 800);
  }
}

function renderSTSetList(exercise) {
  if (!exercise) return '';

  // Branch by exercise type for cardio/recovery
  const exType = getWorkoutExerciseType(exercise);
  if (exType === 'cardio') return renderSTCardioInput(exercise);
  if (exType === 'recovery') return renderSTRecoveryInput(exercise);

  const holdMode = getActiveSetMode(exercise) === 'hold';
  const targetSets = getTargetSetCount(exercise);
  const completedCount = exercise.completedSets.length;
  const valueUnit = holdMode ? t('workout.holdDurationLabel') : t('workout.logging.totalReps');

  // Build rows: completed sets + one active set + remaining empty sets
  let rows = '';

  // Completed sets
  exercise.completedSets.forEach((set, setIndex) => {
    if (holdMode) {
      // Hold mode: show holdSec only, no weight
      rows += `
        <div class="st-set-row st-set-row--done" data-set-index="${setIndex}">
          <div class="st-set-num st-set-num--done">${setIndex + 1}</div>
          <div class="st-set-values">
            <button type="button" class="st-set-val" onclick="openNumberPickerForSet(${activeWorkout.currentExerciseIndex}, ${setIndex}, 'hold')">
              <span class="st-set-val-num">${set.holdSec || 0}</span>
              <span class="st-set-val-unit">${valueUnit}</span>
            </button>
          </div>
          <button type="button" class="st-set-check st-set-check--done" onclick="deleteSet(${activeWorkout.currentExerciseIndex}, ${setIndex})" aria-label="${t('workout.setLogger.deleteSet')}">
            <span class="material-symbols-rounded">close</span>
          </button>
        </div>
      `;
    } else {
      // Reps mode: show reps + weight (always visible)
      const weightDisplay = set.weight != null && set.weight > 0
        ? (set.weight % 1 !== 0 ? set.weight.toFixed(1).replace('.', ',') : set.weight)
        : null;

      rows += `
        <div class="st-set-row st-set-row--done" data-set-index="${setIndex}">
          <div class="st-set-num st-set-num--done">${setIndex + 1}</div>
          <div class="st-set-values">
            <button type="button" class="st-set-val" onclick="openNumberPickerForSet(${activeWorkout.currentExerciseIndex}, ${setIndex}, 'reps')">
              <span class="st-set-val-num">${set.reps}</span>
              <span class="st-set-val-unit">${valueUnit}</span>
            </button>
            <button type="button" class="st-set-val" onclick="openNumberPickerForSet(${activeWorkout.currentExerciseIndex}, ${setIndex}, 'weight')">
              <span class="st-set-val-num">${weightDisplay || '—'}</span>
              <span class="st-set-val-unit">${getWeightUnit()}</span>
            </button>
          </div>
          <button type="button" class="st-set-check st-set-check--done" onclick="deleteSet(${activeWorkout.currentExerciseIndex}, ${setIndex})" aria-label="${t('workout.setLogger.deleteSet')}">
            <span class="material-symbols-rounded">close</span>
          </button>
        </div>
      `;
    }
  });

  // Active set (next to log)
  const activeSetNum = completedCount + 1;
  const defaults = getDefaultSetValues(exercise);

  // Initialize active set values
  initActiveSetValues(exercise);

  if (holdMode) {
    // Hold mode: single holdSec input
    rows += `
      <div class="st-set-row st-set-row--active" data-set-index="active">
        <div class="st-set-num st-set-num--active">${activeSetNum}</div>
        <div class="st-set-values">
          <button type="button" class="st-set-val st-set-val--editable" onclick="openNumberPickerForNewSet('hold')" id="active-hold-btn" data-value="${activeSetValues.holdSec}">
            <span class="st-set-val-num" id="active-hold-value">${activeSetValues.holdSec}</span>
            <span class="st-set-val-unit">${valueUnit}</span>
          </button>
        </div>
        <button type="button" class="st-set-check st-set-check--log" onclick="logSetFromActiveRow()" aria-label="${t('workout.setLogger.logSet')}">
          <span class="material-symbols-rounded">check</span>
        </button>
      </div>
    `;
  } else {
    // Reps mode: reps + weight (always visible)
    const activeWeightDisplay = defaults.weight % 1 !== 0 ? defaults.weight.toFixed(1).replace('.', ',') : defaults.weight;

    rows += `
      <div class="st-set-row st-set-row--active" data-set-index="active">
        <div class="st-set-num st-set-num--active">${activeSetNum}</div>
        <div class="st-set-values">
          <button type="button" class="st-set-val st-set-val--editable" onclick="openNumberPickerForNewSet('reps')" id="active-reps-btn" data-value="${activeSetValues.reps}">
            <span class="st-set-val-num" id="active-reps-value">${activeSetValues.reps}</span>
            <span class="st-set-val-unit">${valueUnit}</span>
          </button>
          <button type="button" class="st-set-val st-set-val--editable" onclick="handleWeightValueTap()" id="active-weight-btn" data-value="${activeSetValues.weight}">
            <span class="st-set-val-num" id="active-weight-value">${activeWeightDisplay || '0'}</span>
            <span class="st-set-val-unit">${getWeightUnit()}</span>
          </button>
        </div>
        <button type="button" class="st-set-check st-set-check--log" onclick="logSetFromActiveRow()" aria-label="${t('workout.setLogger.logSet')}">
          <span class="material-symbols-rounded">check</span>
        </button>
      </div>
    `;
  }

  // Remaining empty sets (placeholders)
  for (let i = activeSetNum + 1; i <= targetSets; i++) {
    rows += `
      <div class="st-set-row st-set-row--empty" data-set-index="empty-${i}">
        <div class="st-set-num">${i}</div>
        <div class="st-set-values">
          <div class="st-set-val st-set-val--placeholder">
            <span class="st-set-val-num">—</span>
            <span class="st-set-val-unit">${valueUnit}</span>
          </div>
          ${!holdMode ? `
            <div class="st-set-val st-set-val--placeholder">
              <span class="st-set-val-num">—</span>
              <span class="st-set-val-unit">${getWeightUnit()}</span>
            </div>
          ` : ''}
        </div>
        <div class="st-set-check st-set-check--empty">
          <span class="material-symbols-rounded">radio_button_unchecked</span>
        </div>
      </div>
    `;
  }

  return `
    <div class="st-sets">
      ${rows}
      <button type="button" class="st-set-add-btn" onclick="addEmptySet()">
        <span class="material-symbols-rounded">add</span>${t('workout.setLogger.addSet') || 'Satz hinzufügen'}
      </button>
    </div>
  `;
}

// renderSTRestTimer() removed - timer is now a separate fixed widget (renderTimerWidget)

