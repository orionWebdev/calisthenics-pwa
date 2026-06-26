// ========================================
// WORKOUT MODAL - VIEW & MANAGE WORKOUTS
// ========================================

/**
 * Open workout detail modal
 */
function openWorkoutDetailModal(sessionId) {
  const session = allSessions.find(s => s.id === sessionId);
  if (!session) {
    console.error('Session not found:', sessionId);
    return;
  }

  const date = session.date?.toDate ? session.date.toDate() : new Date(session.date);
  const totalSets = calculateTotalSets(session);
  const totalVolume = calculateTotalVolume(session);
  const exCount = session.exercises?.length || 0;
  const durMin = Number(session.duration) || (Number(session.durationSec) ? Number(session.durationSec) / 60 : 0);
  const titleName = session.planName || 'Workout';
  const durBig = durMin >= 60
    ? `${Math.floor(durMin / 60)}:${String(Math.round(durMin % 60)).padStart(2, '0')}<small>h</small>`
    : `${Math.round(durMin)}<small>min</small>`;
  const volTxt = totalVolume >= 1000 ? `${(totalVolume / 1000).toFixed(1).replace('.', ',')}<small>k</small>` : `${totalVolume}`;

  const tile = (v, l, ic) => `<div class="sd-tile"><div class="v">${v}</div><div class="l">${ic ? `<span class="material-symbols-rounded">${ic}</span>` : ''}${l}</div></div>`;
  let tiles = tile(exCount, t('workoutModal.exercises'), 'fitness_center') + tile(totalSets, t('workoutModal.sets'), 'repeat');
  if (totalVolume) tiles += tile(volTxt, 'Volumen', 'monitoring');

  const modalContent = `
    <div class="sd" style="--sd-accent:#C0196333;--sd-grad:linear-gradient(135deg,#C01963,#F02277)">
      <div class="sd-hero">
        <div class="sd-hero-top">
          <div class="sd-hero-ic"><span class="material-symbols-rounded">exercise</span></div>
          <div class="sd-hero-meta"><div class="n">${titleName}</div><div class="d">${formatFullDate(date)}</div></div>
        </div>
        <div class="sd-hero-big">${durBig}</div>
      </div>
      <div class="sd-grid">${tiles}</div>
      <div class="sd-card">
        <div class="sd-sec-t"><span class="material-symbols-rounded">list</span>${t('workoutModal.exercises')}</div>
        ${renderSdWorkoutExercises(session)}
      </div>
      ${typeof renderRpeFeedbackSection === 'function' ? renderRpeFeedbackSection(session) : ''}
      ${session.notes ? `<div class="sd-card"><div class="sd-sec-t"><span class="material-symbols-rounded">notes</span>${t('common.notes')}</div><p class="sd-note">${session.notes}</p></div>` : ''}
      <div class="workout-modal-actions">
        <button onclick="openEditStrengthSessionModal('${session.id}')" class="btn-edit">
          <span class="material-symbols-rounded">settings</span>
          <span>${t('common.editSession')}</span>
        </button>
        <button onclick="confirmDeleteWorkout('${session.id}')" class="btn-danger">
          <span class="material-symbols-rounded">delete</span>
          <span>${t('common.delete')}</span>
        </button>
      </div>
    </div>
  `;

  openGenericModal(titleName, modalContent);
}

// Exercise list for the strength detail — a muscle dust orb per exercise + sets.
function renderSdWorkoutExercises(session) {
  if (!session.exercises || session.exercises.length === 0) {
    return `<p class="sd-note">${t('workoutModal.noExercises')}</p>`;
  }
  const unit = typeof getWeightUnit === 'function' ? getWeightUnit() : 'kg';
  return session.exercises.map(ex => {
    const exercise = (typeof allExercises !== 'undefined' ? allExercises : []).find(e => e.id === ex.exerciseId);
    const name = (typeof getExerciseName === 'function' && exercise ? getExerciseName(exercise) : exercise?.name) || ex.exerciseName || ex.exerciseId || t('workoutModal.exercise');
    const orb = typeof getPrimaryMuscleIcon === 'function' ? getPrimaryMuscleIcon(exercise?.muscleGroups || [], 'muscle-icon--lg') : '';
    const sets = (ex.sets && ex.sets.length)
      ? ex.sets.map(set => {
          let label;
          if (set.type === 'cardio') label = `${set.duration || 0} min${set.distance ? ` · ${set.distance} km` : ''}`;
          else if (set.holdSec) label = `${set.holdSec}s`;
          else label = `${set.reps || 0}×${set.weight ? ` ${set.weight} ${unit}` : ''}`;
          return `<span class="sd-set">${label}</span>`;
        }).join('')
      : `<span class="sd-set">${t('workoutModal.noSets')}</span>`;
    return `<div class="sd-ex">${orb}<div class="sd-ex-info"><div class="sd-ex-name">${name}</div><div class="sd-ex-sets">${sets}</div></div></div>`;
  }).join('');
}

/**
 * Render workout exercises
 */
function renderWorkoutExercises(session) {
  if (!session.exercises || session.exercises.length === 0) {
    return `<p class="workout-no-exercises">${t('workoutModal.noExercises')}</p>`;
  }

  return session.exercises.map((ex, index) => {
    const exercise = allExercises.find(e => e.id === ex.exerciseId);
    const exerciseName = (typeof getExerciseName === 'function' && exercise ? getExerciseName(exercise) : exercise?.name) || ex.exerciseName || ex.exerciseId || t('workoutModal.exercise');

    return `
      <div class="workout-exercise-item">
        <div class="exercise-number">${index + 1}</div>
        <div class="exercise-info">
          <div class="workout-exercise-name">${exerciseName}</div>
          <div class="exercise-sets">
            ${ex.sets && ex.sets.length > 0 ? ex.sets.map((set, i) => {
              let label = '';
              if (set.type === 'cardio') {
                label = `${set.duration || 0} min`;
                if (set.distance) label += ` / ${set.distance} km`;
                if (set.rpe) label += ` / RPE ${set.rpe}`;
              } else if (set.type === 'recovery') {
                label = `${set.duration || 0} min`;
              } else if (set.holdSec) {
                label = `${set.holdSec}s`;
              } else {
                label = `${set.reps || 0} reps${set.weight ? ` @ ${set.weight} ${typeof getWeightUnit === 'function' ? getWeightUnit() : 'kg'}` : ''}`;
              }
              return `<span class="set-badge">${i + 1}: ${label}</span>`;
            }).join('') : `<span class="set-badge">${t('workoutModal.noSets')}</span>`}
          </div>
        </div>
      </div>
    `;
  }).join('');
}

/**
 * Calculate total sets in a session
 */
function calculateTotalSets(session) {
  if (!session.exercises) return 0;
  return session.exercises.reduce((sum, ex) => sum + (ex.sets?.length || 0), 0);
}

/**
 * Calculate total volume (total reps) in a session
 */
function calculateTotalVolume(session) {
  if (!session.exercises) return 0;
  return session.exercises.reduce((total, ex) => {
    if (!ex.sets) return total;
    return total + ex.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
  }, 0);
}

/**
 * Confirm and delete workout
 */
async function confirmDeleteWorkout(sessionId) {
  if (!confirm(t('workoutModal.deleteConfirm'))) {
    return;
  }

  try {
    const session = allSessions.find(s => s.id === sessionId);
    await deleteDoc(sessionsCollection, sessionId);

    if (session?.scheduleId) {
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
    closeWorkoutDetailModal();
    await loadSessions();

    // Always navigate to progress after deletion
    if (typeof showView === 'function') {
      showView('progress');
    }

    triggerSuccessGlow();
  } catch (error) {
    console.error('❌ Error deleting workout:', error);
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', t('workoutModal.deleteError') + ': ' + error.message);
  }
  }
}

/**
 * Close workout detail modal
 */
function closeWorkoutDetailModal() {
  closeGenericModal();
}

/**
 * Format date (short): "22. Jan"
 */
function formatShortDate(date) {
  if (typeof formatDateShortText === 'function') return formatDateShortText(date);
  return date.toLocaleDateString();
}

/**
 * Format date (full): locale-aware long date
 */
function formatFullDate(date) {
  if (typeof formatDateLongText === 'function') return formatDateLongText(date, true);
  return date.toLocaleDateString();
}

// ========================================
// SESSION EDIT MODALS
// ========================================

const trEdit = (key, params) => (typeof t === 'function' ? t(key, params) : key);

/**
 * Open edit modal for strength session
 */
function openEditStrengthSessionModal(sessionId) {
  const session = allSessions.find(s => s.id === sessionId);
  if (!session) {
    console.error('Session not found:', sessionId);
    return;
  }

  const durationMinutes = session.duration || Math.round((session.durationSec || session.durationSeconds || 0) / 60);
  const notes = session.notes || '';
  const exercises = session.exercises || [];

  // Render exercises section
  let exercisesHtml = '';
  if (exercises.length > 0) {
    exercisesHtml = `
      <div class="session-edit-exercises">
        <label class="session-edit-exercises-label">${trEdit('plan.exercises')}</label>
        <div id="edit-exercises-list" class="edit-exercises-list">
          ${exercises.map((ex, exIndex) => renderEditExercise(ex, exIndex)).join('')}
        </div>
      </div>
    `;
  }

  const content = `
    <div class="session-edit-modal">
      <form id="edit-strength-form" onsubmit="saveStrengthSessionEdit(event, '${sessionId}')">
        <div class="session-edit-field">
          <label for="edit-strength-duration">${trEdit('common.duration')} (${trEdit('format.duration.minutes', { minutes: '' }).replace('min', 'Min')})</label>
          <input type="number" id="edit-strength-duration" value="${durationMinutes}" min="1" max="600" required />
        </div>
        ${exercisesHtml}
        <div class="session-edit-field">
          <label for="edit-strength-notes">${trEdit('common.notes')} (${trEdit('common.optional')})</label>
          <textarea id="edit-strength-notes" rows="3" placeholder="${trEdit('common.notes')}">${notes}</textarea>
        </div>
        <div class="session-edit-actions">
          <button type="submit" class="btn-primary">
            <span class="material-symbols-rounded">save</span>
            <span>${trEdit('common.save')}</span>
          </button>
        </div>
      </form>
    </div>
  `;

  if (typeof openGenericModal === 'function') {
    openGenericModal(trEdit('common.editSession'), content);
  }
}

/**
 * Render a single exercise for editing
 */
function renderEditExercise(exercise, exIndex) {
  const exerciseData = Array.isArray(allExercises)
    ? allExercises.find(e => e.id === exercise.exerciseId)
    : null;
  const exerciseName = exerciseData?.name || exercise.exerciseId || `${t('workoutModal.exercise')} ${exIndex + 1}`;
  const sets = exercise.sets || [];

  const setsHtml = sets.map((set, setIndex) => `
    <div class="edit-set-row" data-ex="${exIndex}" data-set="${setIndex}">
      <span class="edit-set-number">${setIndex + 1}</span>
      <div class="edit-set-inputs">
        <div class="edit-set-input-group">
          <input type="number"
                 class="edit-set-reps"
                 data-ex="${exIndex}"
                 data-set="${setIndex}"
                 value="${set.reps || ''}"
                 min="0"
                 max="999"
                 placeholder="${t('workoutModal.reps')}" />
          <span class="edit-set-label">${t('workoutModal.reps')}</span>
        </div>
        <div class="edit-set-input-group">
          <input type="number"
                 class="edit-set-weight"
                 data-ex="${exIndex}"
                 data-set="${setIndex}"
                 value="${set.weight || ''}"
                 min="0"
                 max="999"
                 step="0.5"
                 placeholder="${typeof getWeightUnit === 'function' ? getWeightUnit() : 'kg'}" />
          <span class="edit-set-label">${typeof getWeightUnit === 'function' ? getWeightUnit() : 'kg'}</span>
        </div>
      </div>
      <button type="button" class="edit-set-remove" onclick="removeEditSet(${exIndex}, ${setIndex})" aria-label="${t('workoutModal.removeSet')}">
        <span class="material-symbols-rounded">close</span>
      </button>
    </div>
  `).join('');

  return `
    <div class="edit-exercise-card" data-ex-index="${exIndex}">
      <div class="edit-exercise-header">
        <span class="edit-exercise-name">${exerciseName}</span>
      </div>
      <div class="edit-exercise-sets" id="edit-sets-${exIndex}">
        ${setsHtml || `<p class="edit-no-sets">${t('workoutModal.noSets')}</p>`}
      </div>
      <button type="button" class="edit-add-set-btn" onclick="addEditSet(${exIndex})">
        <span class="material-symbols-rounded">add</span>
        <span>${t('workoutModal.addSet')}</span>
      </button>
    </div>
  `;
}

/**
 * Add a new set to an exercise in the edit modal
 */
function addEditSet(exIndex) {
  const setsContainer = document.getElementById(`edit-sets-${exIndex}`);
  if (!setsContainer) return;

  // Remove "no sets" message if present
  const noSetsMsg = setsContainer.querySelector('.edit-no-sets');
  if (noSetsMsg) noSetsMsg.remove();

  const existingSets = setsContainer.querySelectorAll('.edit-set-row');
  const newSetIndex = existingSets.length;

  const newSetHtml = `
    <div class="edit-set-row" data-ex="${exIndex}" data-set="${newSetIndex}">
      <span class="edit-set-number">${newSetIndex + 1}</span>
      <div class="edit-set-inputs">
        <div class="edit-set-input-group">
          <input type="number"
                 class="edit-set-reps"
                 data-ex="${exIndex}"
                 data-set="${newSetIndex}"
                 value=""
                 min="0"
                 max="999"
                 placeholder="${t('workoutModal.reps')}" />
          <span class="edit-set-label">${t('workoutModal.reps')}</span>
        </div>
        <div class="edit-set-input-group">
          <input type="number"
                 class="edit-set-weight"
                 data-ex="${exIndex}"
                 data-set="${newSetIndex}"
                 value=""
                 min="0"
                 max="999"
                 step="0.5"
                 placeholder="${typeof getWeightUnit === 'function' ? getWeightUnit() : 'kg'}" />
          <span class="edit-set-label">${typeof getWeightUnit === 'function' ? getWeightUnit() : 'kg'}</span>
        </div>
      </div>
      <button type="button" class="edit-set-remove" onclick="removeEditSet(${exIndex}, ${newSetIndex})" aria-label="${t('workoutModal.removeSet')}">
        <span class="material-symbols-rounded">close</span>
      </button>
    </div>
  `;

  setsContainer.insertAdjacentHTML('beforeend', newSetHtml);
}

/**
 * Remove a set from an exercise in the edit modal
 */
function removeEditSet(exIndex, setIndex) {
  const setsContainer = document.getElementById(`edit-sets-${exIndex}`);
  if (!setsContainer) return;

  const setRow = setsContainer.querySelector(`.edit-set-row[data-ex="${exIndex}"][data-set="${setIndex}"]`);
  if (setRow) {
    setRow.remove();
    // Renumber remaining sets
    const remainingSets = setsContainer.querySelectorAll('.edit-set-row');
    remainingSets.forEach((row, newIndex) => {
      row.dataset.set = newIndex;
      row.querySelector('.edit-set-number').textContent = newIndex + 1;
      row.querySelector('.edit-set-reps').dataset.set = newIndex;
      row.querySelector('.edit-set-weight').dataset.set = newIndex;
      row.querySelector('.edit-set-remove').setAttribute('onclick', `removeEditSet(${exIndex}, ${newIndex})`);
    });

    // Show "no sets" if empty
    if (remainingSets.length === 0) {
      setsContainer.innerHTML = `<p class="edit-no-sets">${t('workoutModal.noSets')}</p>`;
    }
  }
}

window.addEditSet = addEditSet;
window.removeEditSet = removeEditSet;

/**
 * Save edited strength session
 */
async function saveStrengthSessionEdit(event, sessionId) {
  event.preventDefault();

  const session = allSessions.find(s => s.id === sessionId);
  if (!session) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workoutModal.sessionNotFound'));
    }
    return;
  }

  const durationInput = document.getElementById('edit-strength-duration');
  const notesInput = document.getElementById('edit-strength-notes');

  const duration = parseInt(durationInput?.value || '0', 10);
  const notes = notesInput?.value?.trim() || '';

  if (!duration || duration < 1) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workoutModal.invalidDuration'));
    }
    return;
  }

  // Collect exercises data from the form
  const originalExercises = session.exercises || [];
  const updatedExercises = [];

  const exerciseCards = document.querySelectorAll('.edit-exercise-card');
  exerciseCards.forEach((card, exIndex) => {
    const originalExercise = originalExercises[exIndex];
    if (!originalExercise) return;

    const sets = [];
    const setRows = card.querySelectorAll('.edit-set-row');

    setRows.forEach(row => {
      const repsInput = row.querySelector('.edit-set-reps');
      const weightInput = row.querySelector('.edit-set-weight');

      const reps = parseInt(repsInput?.value || '0', 10);
      const weight = parseFloat(weightInput?.value || '0') || null;

      // Only add set if reps > 0
      if (reps > 0) {
        const setData = { reps };
        if (weight !== null && weight > 0) {
          setData.weight = weight;
        }
        sets.push(setData);
      }
    });

    updatedExercises.push({
      exerciseId: originalExercise.exerciseId,
      sets: sets
    });
  });

  try {
    const updateData = {
      duration: duration,
      durationSec: duration * 60,
      notes: notes,
      exercises: updatedExercises
    };

    await updateDoc(sessionsCollection, sessionId, updateData);
    closeGenericModal();

    if (typeof loadSessions === 'function') {
      await loadSessions();
    }

    if (typeof refreshDashboard === 'function') {
      refreshDashboard();
    }

    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    }

    if (typeof triggerSuccessGlow === 'function') {
      triggerSuccessGlow();
    }

  } catch (error) {
    console.error('❌ Error updating session:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workoutModal.saveError') + ': ' + error.message);
    }
  }
}

/**
 * Build RPE button row HTML for edit modals
 */
function buildRpeEditRow(fieldId, label, currentValue) {
  const buttons = [1,2,3,4,5].map(n =>
    `<button type="button" class="difficulty-btn${currentValue === n ? ' active' : ''}" data-value="${n}" onclick="selectEditRpeValue('${fieldId}', ${n})">${n}</button>`
  ).join('');
  return `
    <div class="session-edit-field">
      <label>${label}</label>
      <div class="rpe-btn-row" id="${fieldId}-row">${buttons}</div>
      <input type="hidden" id="${fieldId}" value="${currentValue || ''}" />
    </div>
  `;
}

window.selectEditRpeValue = function(fieldId, value) {
  const input = document.getElementById(fieldId);
  if (input) input.value = value;
  const row = document.getElementById(fieldId + '-row');
  if (row) {
    row.querySelectorAll('.difficulty-btn').forEach(btn => {
      btn.classList.toggle('active', parseInt(btn.dataset.value) === value);
    });
  }
};

/**
 * Open edit modal for cardio session
 */
function openEditCardioSessionModal(sessionId) {
  const session = allSessions.find(s => s.id === sessionId);
  if (!session) {
    console.error('Session not found:', sessionId);
    return;
  }

  const durationMinutes = session.duration || Math.round((session.durationSec || session.durationSeconds || 0) / 60);
  const distanceKm = session.distanceKm || '';
  const notes = session.notes || '';
  const sessionName = session.name || '';

  const content = `
    <div class="session-edit-modal">
      <form id="edit-cardio-form" onsubmit="saveCardioSessionEdit(event, '${sessionId}')">
        <div class="session-edit-field">
          <label for="edit-cardio-name">Name (${trEdit('common.optional')})</label>
          <input type="text" id="edit-cardio-name" value="${sessionName}" placeholder="z.B. Morgenlauf" />
        </div>
        <div class="session-edit-field">
          <label for="edit-cardio-duration">${trEdit('common.duration')} (${trEdit('format.duration.minutes', { minutes: '' }).replace('min', 'Min')})</label>
          <input type="number" id="edit-cardio-duration" value="${durationMinutes}" min="1" max="600" required />
        </div>
        <div class="session-edit-field">
          <label for="edit-cardio-distance">${trEdit('common.distance')} (km)</label>
          <input type="number" id="edit-cardio-distance" value="${distanceKm}" min="0" max="500" step="0.1" />
        </div>
        <div class="session-edit-field">
          <label for="edit-cardio-notes">${trEdit('common.notes')} (${trEdit('common.optional')})</label>
          <textarea id="edit-cardio-notes" rows="3" placeholder="${trEdit('common.notes')}">${notes}</textarea>
        </div>
        ${buildRpeEditRow('edit-cardio-energy', 'Energie vorher (1-5)', session.preWorkoutEnergy)}
        ${buildRpeEditRow('edit-cardio-feeling', 'Gefühl danach (1-5)', session.postWorkoutFeeling)}
        ${buildRpeEditRow('edit-cardio-rpe', 'RPE - Belastung (1-5)', session.rpe)}
        <div class="session-edit-actions">
          <button type="submit" class="btn-primary">
            <span class="material-symbols-rounded">save</span>
            <span>${trEdit('common.save')}</span>
          </button>
        </div>
      </form>
    </div>
  `;

  if (typeof openGenericModal === 'function') {
    openGenericModal(trEdit('common.editSession'), content);
  }
}

/**
 * Save edited cardio session
 */
async function saveCardioSessionEdit(event, sessionId) {
  event.preventDefault();

  const nameInput = document.getElementById('edit-cardio-name');
  const durationInput = document.getElementById('edit-cardio-duration');
  const distanceInput = document.getElementById('edit-cardio-distance');
  const notesInput = document.getElementById('edit-cardio-notes');
  const energyInput = document.getElementById('edit-cardio-energy');
  const feelingInput = document.getElementById('edit-cardio-feeling');
  const rpeInput = document.getElementById('edit-cardio-rpe');

  const sessionName = nameInput?.value?.trim() || '';
  const duration = parseInt(durationInput?.value || '0', 10);
  const distanceKm = parseFloat(distanceInput?.value || '0') || null;
  const notes = notesInput?.value?.trim() || '';
  const preWorkoutEnergy = parseInt(energyInput?.value) || null;
  const postWorkoutFeeling = parseInt(feelingInput?.value) || null;
  const rpe = parseInt(rpeInput?.value) || null;

  if (!duration || duration < 1) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workoutModal.invalidDuration'));
    }
    return;
  }

  try {
    const updateData = {
      duration: duration,
      durationSec: duration * 60,
      name: sessionName || null,
      notes: notes,
      preWorkoutEnergy: preWorkoutEnergy,
      postWorkoutFeeling: postWorkoutFeeling,
      rpe: rpe
    };

    if (distanceKm !== null && distanceKm > 0) {
      updateData.distanceKm = distanceKm;
      // Berechne Pace (min/km)
      updateData.pace = duration / distanceKm;
    }

    await updateDoc(sessionsCollection, sessionId, updateData);
    closeGenericModal();

    if (typeof loadSessions === 'function') {
      await loadSessions();
    }

    if (typeof refreshDashboard === 'function') {
      refreshDashboard();
    }

    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    }

    if (typeof triggerSuccessGlow === 'function') {
      triggerSuccessGlow();
    }

  } catch (error) {
    console.error('❌ Error updating session:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workoutModal.saveError') + ': ' + error.message);
    }
  }
}

/**
 * Open edit modal for recovery session
 */
function openEditRecoverySessionModal(sessionId) {
  const session = allSessions.find(s => s.id === sessionId);
  if (!session) {
    console.error('Session not found:', sessionId);
    return;
  }

  const durationMinutes = session.duration || Math.round((session.durationSec || session.durationSeconds || 0) / 60);
  const notes = session.notes || '';
  const sessionName = session.name || '';
  const currentActivityType = session.activityType || 'yoga';

  const recoveryOptions = Object.entries(RECOVERY_TYPES || {}).map(([key, val]) =>
    `<option value="${key}"${key === currentActivityType ? ' selected' : ''}>${val.name}</option>`
  ).join('');

  const content = `
    <div class="session-edit-modal">
      <form id="edit-recovery-form" onsubmit="saveRecoverySessionEdit(event, '${sessionId}')">
        <div class="session-edit-field">
          <label for="edit-recovery-activity">Aktivität</label>
          <select id="edit-recovery-activity">${recoveryOptions}</select>
        </div>
        <div class="session-edit-field">
          <label for="edit-recovery-name">Name (${trEdit('common.optional')})</label>
          <input type="text" id="edit-recovery-name" value="${sessionName}" placeholder="z.B. Morgen-Yoga" />
        </div>
        <div class="session-edit-field">
          <label for="edit-recovery-duration">${trEdit('common.duration')} (${trEdit('format.duration.minutes', { minutes: '' }).replace('min', 'Min')})</label>
          <input type="number" id="edit-recovery-duration" value="${durationMinutes}" min="1" max="600" required />
        </div>
        <div class="session-edit-field">
          <label for="edit-recovery-notes">${trEdit('common.notes')} (${trEdit('common.optional')})</label>
          <textarea id="edit-recovery-notes" rows="3" placeholder="${trEdit('common.notes')}">${notes}</textarea>
        </div>
        ${buildRpeEditRow('edit-recovery-energy', 'Energie vorher (1-5)', session.preWorkoutEnergy)}
        ${buildRpeEditRow('edit-recovery-feeling', 'Gefühl danach (1-5)', session.postWorkoutFeeling)}
        ${buildRpeEditRow('edit-recovery-rpe', 'RPE - Belastung (1-5)', session.rpe)}
        <div class="session-edit-actions">
          <button type="submit" class="btn-primary">
            <span class="material-symbols-rounded">save</span>
            <span>${trEdit('common.save')}</span>
          </button>
        </div>
      </form>
    </div>
  `;

  if (typeof openGenericModal === 'function') {
    openGenericModal(trEdit('common.editSession'), content);
  }
}

/**
 * Save edited recovery session
 */
async function saveRecoverySessionEdit(event, sessionId) {
  event.preventDefault();

  const activityInput = document.getElementById('edit-recovery-activity');
  const nameInput = document.getElementById('edit-recovery-name');
  const durationInput = document.getElementById('edit-recovery-duration');
  const notesInput = document.getElementById('edit-recovery-notes');
  const energyInput = document.getElementById('edit-recovery-energy');
  const feelingInput = document.getElementById('edit-recovery-feeling');
  const rpeInput = document.getElementById('edit-recovery-rpe');

  const activityType = activityInput?.value || 'yoga';
  const sessionName = nameInput?.value?.trim() || '';
  const duration = parseInt(durationInput?.value || '0', 10);
  const notes = notesInput?.value?.trim() || '';
  const preWorkoutEnergy = parseInt(energyInput?.value) || null;
  const postWorkoutFeeling = parseInt(feelingInput?.value) || null;
  const rpe = parseInt(rpeInput?.value) || null;

  if (!duration || duration < 1) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workoutModal.invalidDuration'));
    }
    return;
  }

  try {
    const updateData = {
      duration: duration,
      durationSec: duration * 60,
      activityType: activityType,
      name: sessionName || null,
      notes: notes,
      preWorkoutEnergy: preWorkoutEnergy,
      postWorkoutFeeling: postWorkoutFeeling,
      rpe: rpe
    };

    await updateDoc(sessionsCollection, sessionId, updateData);
    closeGenericModal();

    if (typeof loadSessions === 'function') {
      await loadSessions();
    }

    if (typeof refreshDashboard === 'function') {
      refreshDashboard();
    }

    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    }

    if (typeof triggerSuccessGlow === 'function') {
      triggerSuccessGlow();
    }

  } catch (error) {
    console.error('❌ Error updating session:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workoutModal.saveError') + ': ' + error.message);
    }
  }
}

// Expose edit functions globally
window.openEditStrengthSessionModal = openEditStrengthSessionModal;
window.saveStrengthSessionEdit = saveStrengthSessionEdit;
window.openEditCardioSessionModal = openEditCardioSessionModal;
window.saveCardioSessionEdit = saveCardioSessionEdit;
window.openEditRecoverySessionModal = openEditRecoverySessionModal;
window.saveRecoverySessionEdit = saveRecoverySessionEdit;

