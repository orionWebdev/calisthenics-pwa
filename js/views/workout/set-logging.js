/**
 * Show workout menu (three-dot menu)
 */
function showWorkoutMenu() {
  // Remove existing menu
  const existing = document.getElementById('st-menu-overlay');
  if (existing) { existing.remove(); return; }

  const overlay = document.createElement('div');
  overlay.id = 'st-menu-overlay';
  overlay.className = 'st-menu-overlay';
  overlay.innerHTML = `
    <div class="st-menu" role="menu">
      <button type="button" class="st-menu-item" onclick="closeWorkoutMenu(); confirmEndWorkout();" role="menuitem">
        <span class="material-symbols-rounded">stop_circle</span>
        <span>${t('workout.screen.endWorkout')}</span>
      </button>
      <div class="st-menu-divider"></div>
      <button type="button" class="st-menu-item st-menu-item--danger" onclick="closeWorkoutMenu(); confirmDiscardWorkout();" role="menuitem">
        <span class="material-symbols-rounded">delete_forever</span>
        <span>${t('workout.screen.discardWorkout')}</span>
      </button>
    </div>
  `;

  // Close on overlay click
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) closeWorkoutMenu();
  });

  document.body.appendChild(overlay);
  requestAnimationFrame(() => overlay.classList.add('active'));

  triggerHapticFeedback('light');
}

function closeWorkoutMenu() {
  const overlay = document.getElementById('st-menu-overlay');
  if (!overlay) return;
  overlay.classList.remove('active');
  setTimeout(() => overlay.remove(), 200);
}

/**
 * Save workout snapshot (keep workout active)
 */
async function saveWorkoutSnapshot() {
  if (!activeWorkout) return;
  saveActiveWorkout();
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('success', t('workout.screen.saveWorkout'));
  }
}

/**
 * Switch to exercise (non-linear, doesn't interrupt timer)
 */
function switchToExercise(index) {
  if (!activeWorkout) return;
  if (index < 0 || index >= activeWorkout.exercises.length) return;
  if (index === activeWorkout.currentExerciseIndex) return;

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

  // DO NOT cancel rest timer on exercise switch
  saveActiveWorkout();
  renderWorkoutScreen();
  triggerHapticFeedback('light');
}

/**
 * Add empty set slot (extends target sets for current exercise)
 */
function addEmptySet() {
  if (!activeWorkout) return;
  const exercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!exercise) return;

  exercise.targetSets = getTargetSetCount(exercise) + 1;
  saveActiveWorkout();
  renderWorkoutScreen();
  triggerHapticFeedback('light');
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
        <span>${t('workout.exercise.progress', { completed: progress.completed, total: progress.total }) || `${progress.completed} / ${progress.total} Übungen`}</span>
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
          <div class="exercise-accordion-target">${getExerciseTargetLine(exercise, { includeLabel: false })}${exercise.targetRest ? ` · ${exercise.targetRest}s` : ''}</div>
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
                ${set.type === 'hold' || (isHoldTarget(exercise) && set.holdSec)
                  ? `<span class="accordion-set-value">${t('common.secondsShort', { n: set.holdSec })} ${t('workout.hold')}</span>`
                  : `<span class="accordion-set-value">${set.reps} ${t('workout.setLogger.reps')}</span>
                     ${set.weight ? `<span class="accordion-set-value">${set.weight} ${getWeightUnit()}</span>` : ''}`
                }
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
  // Weight is always available for all exercises
  const isBodyweight = false;

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
        <span>${getExerciseTargetLine(exercise)}</span>
      </div>

      <!-- Letzte Leistung aus vorheriger Session -->
      ${(() => {
        if (!activeWorkout?.planId || !exercise?.exerciseId) return '';
        const lastSet = getLastPlanPerformance(activeWorkout.planId, exercise.exerciseId);
        const hint = formatLastPerformanceHint(lastSet);
        const label = typeof t === 'function' ? (t('workout.lastPerformance') || 'Letztes Mal') : 'Letztes Mal';
        const fallback = typeof t === 'function' ? (t('workout.noLastPerformance') || 'Kein vorheriger Wert') : 'Kein vorheriger Wert';
        return `
          <div class="last-performance-hint">
            <span class="material-symbols-rounded">history</span>
            <span>${label}: ${hint || fallback}</span>
          </div>
        `;
      })()}
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

  // Only hide weight for explicitly bodyweight/calisthenics plans or bodyweight type
  return plan.type === 'bodyweight' || discipline === 'bodyweight' || discipline === 'calisthenics';
}

/**
 * Get default values for new set based on last set or targets
 */
function getDefaultSetValues(exercise) {
  const lastSet = exercise.completedSets.length > 0
    ? exercise.completedSets[exercise.completedSets.length - 1]
    : null;

  if (getActiveSetMode(exercise) === 'hold') {
    return {
      holdSec: lastSet ? (lastSet.holdSec || getTargetHoldSeconds(exercise)) : getTargetHoldSeconds(exercise),
      reps: 0,
      weight: 0
    };
  }

  return {
    reps: lastSet ? lastSet.reps : (parseInt(exercise.targetReps) || 10),
    weight: lastSet ? (lastSet.weight || 0) : 0,
    holdSec: 0
  };
}

/**
 * Initialize active set values from exercise defaults
 */
function initActiveSetValues(exercise) {
  const defaults = getDefaultSetValues(exercise);
  activeSetValues = {
    reps: defaults.reps,
    weight: defaults.weight,
    holdSec: defaults.holdSec || 0
  };
}

/**
 * Liefert einen bestimmten Satz einer Übung aus der vorherigen Session desselben Plans.
 * Berücksichtigt nur Sessions des aktuellen Users.
 * setIndex: 0-basiert (0 = erster Satz, 1 = zweiter Satz, etc.)
 *           null = nimmt letzten Satz
 */
function getLastPlanPerformance(planId, exerciseId, setIndex = null) {
  if (!planId || !exerciseId) return null;
  const userId = typeof getActiveUserId === 'function' ? getActiveUserId() : null;
  const sessions = typeof allSessions !== 'undefined' ? allSessions : [];
  const relevant = sessions.filter(s =>
    s.planId === planId &&
    (!userId || s.userId === userId)
  );
  if (!relevant.length) return null;
  relevant.sort((a, b) => {
    const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return db - da;
  });
  const lastSession = relevant[0];
  const ex = (lastSession.exercises || []).find(e => e.exerciseId === exerciseId);
  if (!ex || !ex.sets?.length) return null;

  // Wenn setIndex null: nimm letzten Satz (fallback)
  if (setIndex === null) {
    return ex.sets[ex.sets.length - 1];
  }

  // Sonst: nimm den Satz an Position setIndex (falls vorhanden)
  return ex.sets[setIndex] || null;
}

/**
 * Global last performance: search ALL sessions for the latest entry of a given exercise.
 * Returns { sets: [...], date: Date, planName: string } or null.
 */
function getGlobalLastPerformance(exerciseId) {
  if (!exerciseId) return null;
  const userId = typeof getActiveUserId === 'function' ? getActiveUserId() : null;
  const sessions = typeof allSessions !== 'undefined' ? allSessions : [];

  // Find sessions that contain this exercise, sorted by date desc
  let bestSession = null;
  let bestDate = null;
  let bestExerciseEntry = null;

  for (const session of sessions) {
    if (userId && session.userId !== userId) continue;
    if (!session.exercises || !session.exercises.length) continue;

    const ex = session.exercises.find(e => e.exerciseId === exerciseId);
    if (!ex || !ex.sets || !ex.sets.length) continue;

    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    if (!bestDate || sessionDate > bestDate) {
      bestDate = sessionDate;
      bestSession = session;
      bestExerciseEntry = ex;
    }
  }

  if (!bestExerciseEntry) return null;

  return {
    sets: bestExerciseEntry.sets,
    date: bestDate,
    planName: bestSession.planName || null
  };
}

/**
 * Opens a clean bottom-sheet listing ALL past recordings of an exercise.
 * Replaces the cluttered inline "Letztes Mal" dump in the tracker.
 */
function openExerciseHistorySheet(exerciseId) {
  if (!exerciseId || typeof openSheet !== 'function') return;

  const userId = typeof getActiveUserId === 'function' ? getActiveUserId() : null;
  const sessions = typeof allSessions !== 'undefined' ? allSessions : [];
  const wkEx = (activeWorkout && activeWorkout.exercises || []).find(e => e.exerciseId === exerciseId);
  const exName = (wkEx && wkEx.exerciseName)
    || (typeof allExercises !== 'undefined' && (allExercises.find(e => e.id === exerciseId)?.name))
    || t('exercise.title');

  const entries = [];
  sessions.forEach(s => {
    if (userId && s.userId && s.userId !== userId) return;
    if (!s.exercises || !s.exercises.length) return;
    const ex = s.exercises.find(e => e.exerciseId === exerciseId);
    if (!ex || !ex.sets || !ex.sets.length) return;
    const d = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (!d || isNaN(d.getTime())) return;
    entries.push({ date: d, sets: ex.sets, planName: s.planName || null });
  });
  entries.sort((a, b) => b.date - a.date);

  const unit = typeof getWeightUnit === 'function' ? getWeightUnit() : 'kg';
  const fmtSet = (set) => {
    const parts = [];
    if (set.holdSec != null && set.holdSec > 0) parts.push(`${set.holdSec}s`);
    else {
      if (set.reps != null) parts.push(`${set.reps} ${t('workout.setLogger.reps') || 'Wdh.'}`);
      if (set.weight != null && set.weight > 0) parts.push(`${set.weight} ${unit}`);
    }
    if (set.distance != null) parts.push(`${set.distance} km`);
    if (set.duration != null) parts.push(`${set.duration} min`);
    return parts.join(' · ') || '–';
  };

  openSheet({
    title: `${exName} · ${t('workout.lastPerformance') || 'Verlauf'}`,
    render: (el) => {
      if (!entries.length) {
        el.innerHTML = `<div class="st-history-empty">${t('workout.noPreviousData') || 'Keine vorherigen Aufzeichnungen'}</div>`;
        return;
      }
      el.innerHTML = entries.map(en => {
        const dateStr = en.date.toLocaleDateString('de-DE', { day: '2-digit', month: 'short', year: 'numeric' });
        const setsTxt = en.sets.map((set, i) =>
          `<div class="st-history-set"><span class="st-history-set-n">${i + 1}</span>${fmtSet(set)}</div>`
        ).join('');
        return `
          <div class="st-history-entry">
            <div class="st-history-entry-head">
              <span class="st-history-date">${dateStr}</span>
              ${en.planName ? `<span class="st-history-plan">${en.planName}</span>` : ''}
            </div>
            <div class="st-history-sets">${setsTxt}</div>
          </div>`;
      }).join('');
    }
  });
}
window.openExerciseHistorySheet = openExerciseHistorySheet;

/**
 * Format a date as relative time string (e.g. "heute", "gestern", "vor 3 Tagen")
 */
function formatRelativeTime(date) {
  if (!date) return '';
  const now = new Date();
  const diffMs = now - date;
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return t('workout.relativeTime.today') || 'heute';
  if (diffDays === 1) return t('workout.relativeTime.yesterday') || 'gestern';
  if (diffDays < 7) return (t('workout.relativeTime.daysAgo') || 'vor {n} Tagen').replace('{n}', diffDays);
  const diffWeeks = Math.floor(diffDays / 7);
  if (diffWeeks === 1) return t('workout.relativeTime.oneWeekAgo') || 'vor 1 Woche';
  return (t('workout.relativeTime.weeksAgo') || 'vor {n} Wochen').replace('{n}', diffWeeks);
}

/**
 * Gibt einen lesbaren String für die letzte Leistung zurück.
 */
function formatLastPerformanceHint(lastSet) {
  if (!lastSet) return null;
  const parts = [];
  if (lastSet.holdSec != null && lastSet.holdSec > 0) {
    parts.push(`${lastSet.holdSec}${t ? t('common.secondsShort', { n: '' }).trim() || 's' : 's'}`);
  } else {
    if (lastSet.reps != null && lastSet.reps > 0) {
      parts.push(`${lastSet.reps} ${t ? t('workout.setLogger.reps') || 'Wdh.' : 'Wdh.'}`);
    }
    if (lastSet.weight != null && lastSet.weight > 0) {
      parts.push(`${lastSet.weight} ${t ? getWeightUnit() : 'kg'}`);
    }
  }
  return parts.length ? parts.join(' / ') : null;
}

/**
 * Render completed sets as rows
 */
function renderSetRows(exercise, exerciseIndex, isBodyweight) {
  if (exercise.completedSets.length === 0) return '';

  const holdMode = getActiveSetMode(exercise) === 'hold';

  return `
    <div class="set-rows-list">
      ${exercise.completedSets.map((set, setIndex) => {
        const isLatest = setIndex === exercise.completedSets.length - 1;

        if (holdMode) {
          return `
            <div class="set-row ${isLatest ? 'set-row--latest' : ''}" data-set-index="${setIndex}">
              <div class="set-row-pill">
                <span>${setIndex + 1}</span>
              </div>
              <div class="set-row-values">
                <button
                  type="button"
                  class="set-row-value-btn"
                  onclick="openNumberPickerForSet(${exerciseIndex}, ${setIndex}, 'hold')"
                  aria-label="${t('workout.holdDurationLabel')}: ${set.holdSec || 0}"
                >
                  <span class="set-row-value">${set.holdSec || 0}</span>
                  <span class="set-row-unit">${t('workout.holdDurationLabel')}</span>
                </button>
              </div>
              <button
                type="button"
                class="set-row-check set-row-check--completed"
                onclick="deleteSet(${exerciseIndex}, ${setIndex})"
                aria-label="${t('workout.setLogger.deleteSet')}"
              >
                <span class="material-symbols-rounded">close</span>
              </button>
            </div>
          `;
        }

        const weightDisplay = set.weight != null && set.weight > 0
          ? (set.weight % 1 !== 0 ? set.weight.toFixed(1).replace('.', ',') : set.weight)
          : 0;

        return `
          <div class="set-row ${isLatest ? 'set-row--latest' : ''}" data-set-index="${setIndex}">
            <div class="set-row-pill">
              <span>${setIndex + 1}</span>
            </div>
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
                  <span class="set-row-unit">${getWeightUnit()}</span>
                </button>
              ` : ''}
            </div>
            <button
              type="button"
              class="set-row-check set-row-check--completed"
              onclick="deleteSet(${exerciseIndex}, ${setIndex})"
              aria-label="${t('workout.setLogger.deleteSet')}"
            >
              <span class="material-symbols-rounded">close</span>
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
  const holdMode = getActiveSetMode(exercise) === 'hold';

  if (holdMode) {
    return `
      <div class="set-row set-row--active" data-set-index="new">
        <div class="set-row-pill set-row-pill--active">
          <span>${setNumber}</span>
        </div>
        <div class="set-row-values">
          <button
            type="button"
            class="set-row-value-btn set-row-value-btn--editable"
            onclick="openNumberPickerForNewSet('hold')"
            id="active-hold-btn"
            data-value="${activeSetValues.holdSec}"
            aria-label="${t('workout.holdDurationLabel')}: ${activeSetValues.holdSec}"
          >
            <span class="set-row-value" id="active-hold-value">${activeSetValues.holdSec}</span>
            <span class="set-row-unit">${t('workout.holdDurationLabel')}</span>
          </button>
        </div>
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

  const weightDisplay = activeSetValues.weight % 1 !== 0
    ? activeSetValues.weight.toFixed(1).replace('.', ',')
    : activeSetValues.weight;

  return `
    <div class="set-row set-row--active" data-set-index="new">
      <div class="set-row-pill set-row-pill--active">
        <span>${setNumber}</span>
      </div>
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
            onclick="handleWeightValueTap()"
            id="active-weight-btn"
            data-value="${activeSetValues.weight}"
            aria-label="${t('workout.setLogger.weight')}: ${weightDisplay}"
          >
            <span class="set-row-value" id="active-weight-value">${weightDisplay}</span>
            <span class="set-row-unit">${getWeightUnit()}</span>
          </button>
        ` : ''}
      </div>
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

  let initialValue;
  if (type === 'hold') {
    initialValue = set.holdSec || 0;
  } else if (type === 'reps') {
    initialValue = set.reps;
  } else {
    initialValue = set.weight || 0;
  }

  openNumberPicker({
    type: type,
    initialValue: initialValue,
    onConfirm: (newValue) => {
      // Update existing set
      if (type === 'hold') {
        set.holdSec = newValue;
      } else if (type === 'reps') {
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
  let initialValue;
  if (type === 'hold') {
    initialValue = activeSetValues.holdSec;
  } else if (type === 'reps') {
    initialValue = activeSetValues.reps;
  } else {
    initialValue = activeSetValues.weight;
  }

  const currentExercise = activeWorkout?.exercises[activeWorkout.currentExerciseIndex];
  // Reps/hold support the Wdh ↔ Halten tab strip inside the picker
  const supportsModeToggle = (type === 'reps' || type === 'hold') && !!currentExercise;

  const applyValue = (confirmedType, newValue) => {
    if (confirmedType === 'hold') activeSetValues.holdSec = newValue;
    else if (confirmedType === 'reps') activeSetValues.reps = newValue;
    else activeSetValues.weight = newValue;
  };

  const pickerConfig = {
    type: type,
    initialValue: initialValue,
    onConfirm: (newValue) => {
      // numberPickerConfig.type reflects the mode the user confirmed in —
      // it may differ from `type` if they used the Wdh/Halten tab strip.
      const confirmedType = (typeof numberPickerConfig !== 'undefined' && numberPickerConfig.type)
        ? numberPickerConfig.type
        : type;

      if (supportsModeToggle && confirmedType !== type) {
        // Set-type changed: persist the override, re-render the row in the new
        // layout, then re-apply the picked value on top of the fresh row.
        setActiveSetMode(currentExercise, confirmedType);
        renderWorkoutScreen();
        applyValue(confirmedType, newValue);
        updateActiveRowDisplay(confirmedType, newValue);
      } else {
        applyValue(confirmedType, newValue);
        updateActiveRowDisplay(confirmedType, newValue);
      }
      triggerHapticFeedback('light');
    }
  };

  if (supportsModeToggle) {
    pickerConfig.modeToggle = {
      reps: activeSetValues.reps,
      hold: activeSetValues.holdSec,
    };
  }

  openNumberPicker(pickerConfig);
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
  const currentExercise = activeWorkout?.exercises[activeWorkout.currentExerciseIndex];

  // Hold mode: log holdSec instead of reps
  if (getActiveSetMode(currentExercise) === 'hold') {
    const holdSec = activeSetValues.holdSec;
    if (!holdSec || holdSec <= 0) {
      showEdgeFeedback('error', t('workout.setLogger.enterHold'));
      return;
    }
    logSet(null, null, holdSec);
    return;
  }

  // Reps mode
  const reps = activeSetValues.reps;
  if (!reps || reps <= 0) {
    showEdgeFeedback('error', t('workout.setLogger.enterReps'));
    return;
  }

  const weight = activeSetValues.weight > 0 ? activeSetValues.weight : null;
  logSet(reps, weight);
}

/**
 * Adjust active set value by delta (stepper buttons)
 * type: 'reps' (step ±1), 'weight' (step ±2.5), 'hold' (step ±1)
 */
function adjustActiveSetValue(type, delta) {
  if (type === 'reps') {
    activeSetValues.reps = Math.max(0, (activeSetValues.reps || 0) + delta);
    updateActiveRowDisplay('reps', activeSetValues.reps);
  } else if (type === 'weight') {
    activeSetValues.weight = Math.max(0, Math.round(((activeSetValues.weight || 0) + delta) * 10) / 10);
    updateActiveRowDisplay('weight', activeSetValues.weight);
  } else if (type === 'hold') {
    activeSetValues.holdSec = Math.max(0, (activeSetValues.holdSec || 0) + delta);
    updateActiveRowDisplay('hold', activeSetValues.holdSec);
  }
  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('light');
}

/**
 * Adjust the weight value by the user's current step mode (2.5 / 1.0 / 0.5 kg).
 * `sign` is -1 for the minus button, +1 for the plus button.
 */
function adjustWeightByCurrentStep(sign) {
  const step = (typeof getWeightStep === 'function') ? getWeightStep() : 2.5;
  adjustActiveSetValue('weight', sign * step);
}

/**
 * Tap handler on the active weight value button.
 * - Single tap → open number-picker (existing behavior)
 * - Double tap → cycle weight step mode (2,5 → 1,0 → 0,5 → 2,5 …)
 *
 * The first tap is delayed ~220 ms; if a second tap arrives in that window it's
 * treated as a double-tap and the picker open is cancelled.
 */
let _weightTapTimer = null;
function handleWeightValueTap() {
  if (_weightTapTimer) {
    clearTimeout(_weightTapTimer);
    _weightTapTimer = null;
    onWeightValueDoubleTap();
    return;
  }
  _weightTapTimer = setTimeout(() => {
    _weightTapTimer = null;
    if (typeof openNumberPickerForNewSet === 'function') {
      openNumberPickerForNewSet('weight');
    }
  }, 220);
}

function onWeightValueDoubleTap() {
  if (typeof cycleWeightStepMode !== 'function') return;
  cycleWeightStepMode();
  const step = (typeof getWeightStep === 'function') ? getWeightStep() : 2.5;
  const stepLabel = step % 1 === 0 ? String(step) : String(step).replace('.', ',');
  const unit = (typeof getWeightUnit === 'function') ? getWeightUnit() : 'kg';
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('info', t('workout.setLogger.stepModeChanged', { step: stepLabel, unit }));
  }
  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('selection');
}

/**
 * Duplicate last completed set (Copy Last Set button in ST UI)
 */
function duplicateLastSetST() {
  const currentExercise = activeWorkout?.exercises[activeWorkout.currentExerciseIndex];
  if (!currentExercise || currentExercise.completedSets.length === 0) return;

  const lastSet = currentExercise.completedSets[currentExercise.completedSets.length - 1];

  if (lastSet.holdSec != null && lastSet.holdSec > 0) {
    logSet(null, null, lastSet.holdSec);
  } else {
    logSet(lastSet.reps, lastSet.weight || null);
  }
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
