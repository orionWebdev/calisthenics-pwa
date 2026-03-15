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

  const modalContent = `
    <div class="workout-detail-modal">
      <!-- Header -->
      <div class="workout-detail-header">
        <div class="workout-type-badge type-strength">Kraft</div>
        <div class="workout-date" style="font-size: 0.875rem; color: #9ca3af;">
          ${formatFullDate(date)}
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="workout-stats-grid">
        <div class="workout-stat">
          <span class="material-symbols-rounded">schedule</span>
          <div class="workout-stat-value">${session.duration || '-'}</div>
          <div class="workout-stat-label">Minuten</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">fitness_center</span>
          <div class="workout-stat-value">${session.exercises?.length || 0}</div>
          <div class="workout-stat-label">Übungen</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">repeat</span>
          <div class="workout-stat-value">${totalSets}</div>
          <div class="workout-stat-label">Sätze</div>
        </div>
      </div>

      <!-- Exercises List -->
      <div class="workout-exercises">
        <h4 class="workout-section-title">Übungen</h4>
        ${renderWorkoutExercises(session)}
      </div>

      <!-- Notes -->
      ${session.notes ? `
        <div class="workout-notes" style="margin-bottom: 1.5rem;">
          <h4 class="workout-section-title">Notizen</h4>
          <p style="color: #d1d5db; font-size: 0.875rem;">${session.notes}</p>
        </div>
      ` : ''}

      <!-- Actions -->
      <div class="workout-modal-actions">
        <button onclick="openEditStrengthSessionModal('${session.id}')" class="btn-edit">
          <span class="material-symbols-rounded">settings</span>
          <span>${typeof t === 'function' ? t('common.editSession') : 'Session bearbeiten'}</span>
        </button>
        <button onclick="confirmDeleteWorkout('${session.id}')" class="btn-danger">
          <span class="material-symbols-rounded">delete</span>
          <span>${typeof t === 'function' ? t('common.delete') : 'Löschen'}</span>
        </button>
      </div>
    </div>
  `;

  openGenericModal(session.planName || 'Workout Details', modalContent);
}

/**
 * Render workout exercises
 */
function renderWorkoutExercises(session) {
  if (!session.exercises || session.exercises.length === 0) {
    return '<p style="color: #9ca3af;">Keine Übungen</p>';
  }

  return session.exercises.map((ex, index) => {
    const exercise = allExercises.find(e => e.id === ex.exerciseId);
    const exerciseName = exercise?.name || ex.exerciseName || ex.exerciseId || 'Übung';

    return `
      <div class="workout-exercise-item">
        <div class="exercise-number">${index + 1}</div>
        <div class="exercise-info" style="flex: 1;">
          <h5 style="font-size: 1rem; font-weight: 600; color: white; margin-bottom: 0.5rem;">
            ${exerciseName}
          </h5>
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
            }).join('') : '<span class="set-badge">Keine Sätze</span>'}
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
  if (!confirm('Dieses Workout wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.')) {
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
    console.log('✅ Workout deleted');
  } catch (error) {
    console.error('❌ Error deleting workout:', error);
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Fehler beim Löschen: ' + error.message);
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
  const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  const day = date.getDate();
  const month = months[date.getMonth()];
  return `${day}. ${month}`;
}

/**
 * Format date (full): "Montag, 22. Januar 2026"
 */
function formatFullDate(date) {
  const days = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
  const months = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

  const dayName = days[date.getDay()];
  const day = date.getDate();
  const month = months[date.getMonth()];
  const year = date.getFullYear();

  return `${dayName}, ${day}. ${month} ${year}`;
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
  const exerciseName = exerciseData?.name || exercise.exerciseId || `Übung ${exIndex + 1}`;
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
                 placeholder="Wdh" />
          <span class="edit-set-label">Wdh</span>
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
      <button type="button" class="edit-set-remove" onclick="removeEditSet(${exIndex}, ${setIndex})" aria-label="Satz entfernen">
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
        ${setsHtml || '<p class="edit-no-sets">Keine Sätze</p>'}
      </div>
      <button type="button" class="edit-add-set-btn" onclick="addEditSet(${exIndex})">
        <span class="material-symbols-rounded">add</span>
        <span>Satz hinzufügen</span>
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
                 placeholder="Wdh" />
          <span class="edit-set-label">Wdh</span>
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
      <button type="button" class="edit-set-remove" onclick="removeEditSet(${exIndex}, ${newSetIndex})" aria-label="Satz entfernen">
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
      setsContainer.innerHTML = '<p class="edit-no-sets">Keine Sätze</p>';
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
      showEdgeFeedback('error', 'Session nicht gefunden.');
    }
    return;
  }

  const durationInput = document.getElementById('edit-strength-duration');
  const notesInput = document.getElementById('edit-strength-notes');

  const duration = parseInt(durationInput?.value || '0', 10);
  const notes = notesInput?.value?.trim() || '';

  if (!duration || duration < 1) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Bitte gib eine gültige Dauer ein.');
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

    if (typeof triggerSuccessGlow === 'function') {
      triggerSuccessGlow();
    }

    console.log('✅ Strength session updated');
  } catch (error) {
    console.error('❌ Error updating session:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Speichern: ' + error.message);
    }
  }
}

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

  const content = `
    <div class="session-edit-modal">
      <form id="edit-cardio-form" onsubmit="saveCardioSessionEdit(event, '${sessionId}')">
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

  const durationInput = document.getElementById('edit-cardio-duration');
  const distanceInput = document.getElementById('edit-cardio-distance');
  const notesInput = document.getElementById('edit-cardio-notes');

  const duration = parseInt(durationInput?.value || '0', 10);
  const distanceKm = parseFloat(distanceInput?.value || '0') || null;
  const notes = notesInput?.value?.trim() || '';

  if (!duration || duration < 1) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Bitte gib eine gültige Dauer ein.');
    }
    return;
  }

  try {
    const updateData = {
      duration: duration,
      durationSec: duration * 60,
      notes: notes
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

    if (typeof triggerSuccessGlow === 'function') {
      triggerSuccessGlow();
    }

    console.log('✅ Cardio session updated');
  } catch (error) {
    console.error('❌ Error updating session:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Speichern: ' + error.message);
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

  const content = `
    <div class="session-edit-modal">
      <form id="edit-recovery-form" onsubmit="saveRecoverySessionEdit(event, '${sessionId}')">
        <div class="session-edit-field">
          <label for="edit-recovery-duration">${trEdit('common.duration')} (${trEdit('format.duration.minutes', { minutes: '' }).replace('min', 'Min')})</label>
          <input type="number" id="edit-recovery-duration" value="${durationMinutes}" min="1" max="600" required />
        </div>
        <div class="session-edit-field">
          <label for="edit-recovery-notes">${trEdit('common.notes')} (${trEdit('common.optional')})</label>
          <textarea id="edit-recovery-notes" rows="3" placeholder="${trEdit('common.notes')}">${notes}</textarea>
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
 * Save edited recovery session
 */
async function saveRecoverySessionEdit(event, sessionId) {
  event.preventDefault();

  const durationInput = document.getElementById('edit-recovery-duration');
  const notesInput = document.getElementById('edit-recovery-notes');

  const duration = parseInt(durationInput?.value || '0', 10);
  const notes = notesInput?.value?.trim() || '';

  if (!duration || duration < 1) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Bitte gib eine gültige Dauer ein.');
    }
    return;
  }

  try {
    const updateData = {
      duration: duration,
      durationSec: duration * 60,
      notes: notes
    };

    await updateDoc(sessionsCollection, sessionId, updateData);
    closeGenericModal();

    if (typeof loadSessions === 'function') {
      await loadSessions();
    }

    if (typeof refreshDashboard === 'function') {
      refreshDashboard();
    }

    if (typeof triggerSuccessGlow === 'function') {
      triggerSuccessGlow();
    }

    console.log('✅ Recovery session updated');
  } catch (error) {
    console.error('❌ Error updating session:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Speichern: ' + error.message);
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

console.log('✅ Workout modal loaded');
