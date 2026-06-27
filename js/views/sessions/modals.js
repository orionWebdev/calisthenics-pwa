// ==================== CARDIO SESSION MODAL ====================

/**
 * Öffnet "Add Cardio Session" Modal
 */
function openAddCardioModal() {
  const modal = document.getElementById('add-cardio-modal');
  if (!modal) return;


  // Reset inline styles
  modal.style.display = '';

  // Reset Form
  const today = new Date().toISOString().split('T')[0];
  const dateInput = document.getElementById('cardio-date');
  const activityInput = document.getElementById('cardio-activity-type');
  const nameInput = document.getElementById('cardio-name');
  const durationInput = document.getElementById('cardio-duration');
  const distanceInput = document.getElementById('cardio-distance');
  const paceDisplay = document.getElementById('cardio-computed-pace');
  const notesInput = document.getElementById('cardio-notes');

  if (dateInput) dateInput.value = today;
  if (activityInput) activityInput.value = 'run';
  if (nameInput) nameInput.value = '';
  if (durationInput) durationInput.value = '';
  if (distanceInput) distanceInput.value = '';
  if (paceDisplay) {
    paceDisplay.textContent = '-';
    paceDisplay.classList.remove('active');
  }
  if (notesInput) notesInput.value = '';

  // Add active class
  modal.classList.add('active');
  triggerHapticFeedback('light');

}

/**
 * Schließt Cardio Modal
 */
function closeAddCardioModal() {
  const modal = document.getElementById('add-cardio-modal');
  if (!modal) return;


  // Remove active class immediately
  modal.classList.remove('active');

  // Force display none after animation
  setTimeout(() => {
    modal.style.display = 'none';
  }, 300);

  // Reset form after animation completes
  setTimeout(() => {
    const dateInput = document.getElementById('cardio-date');
    const activityInput = document.getElementById('cardio-activity-type');
    const nameInput = document.getElementById('cardio-name');
    const durationInput = document.getElementById('cardio-duration');
    const distanceInput = document.getElementById('cardio-distance');
    const paceDisplay = document.getElementById('cardio-computed-pace');
    const notesInput = document.getElementById('cardio-notes');

    if (dateInput) dateInput.value = '';
    if (activityInput) activityInput.value = 'run';
    if (nameInput) nameInput.value = '';
    if (durationInput) durationInput.value = '';
    if (distanceInput) distanceInput.value = '';
    if (paceDisplay) {
      paceDisplay.textContent = '-';
      paceDisplay.classList.remove('active');
    }
    if (notesInput) notesInput.value = '';

  }, 300);
}

/**
 * Live Pace Berechnung im Modal
 */
function updateCardioLivePace() {
  const duration = parseFloat(document.getElementById('cardio-duration').value) || 0;
  const distance = parseFloat(document.getElementById('cardio-distance').value) || 0;

  const paceDisplay = document.getElementById('cardio-computed-pace');
  if (!paceDisplay) return;

  if (duration > 0 && distance > 0) {
    const pace = calculatePace(duration, distance);
    paceDisplay.textContent = formatPace(pace);
    paceDisplay.classList.add('active');
  } else {
    paceDisplay.textContent = '-';
    paceDisplay.classList.remove('active');
  }
}

/**
 * Speichert neue Cardio Session
 */
async function saveCardioSession() {
  const dateInput = document.getElementById('cardio-date').value;
  const validDate = getValidDateStringForCardio(dateInput);
  const activityType = document.getElementById('cardio-activity-type').value;
  const sessionName = document.getElementById('cardio-name').value.trim();
  const duration = parseFloat(document.getElementById('cardio-duration').value);
  const distance = parseFloat(document.getElementById('cardio-distance').value);
  const avgHrRaw = parseInt(document.getElementById('cardio-avg-hr')?.value, 10);
  const maxHrRaw = parseInt(document.getElementById('cardio-max-hr')?.value, 10);
  const avgHr = Number.isFinite(avgHrRaw) && avgHrRaw > 0 ? avgHrRaw : null;
  const maxHr = Number.isFinite(maxHrRaw) && maxHrRaw > 0 ? maxHrRaw : null;
  const notes = document.getElementById('cardio-notes').value.trim();

  // Validation
  if (!validDate) {
    showErrorMessage(t('workout.quick.dateRequired'));
    return;
  }

  if (!duration || duration <= 0) {
    showErrorMessage(t('workout.quick.durationRequired'));
    return;
  }

  try {
    // Show loading
    const saveBtn = document.querySelector('#add-cardio-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<div class="spinner-small"></div><span>Speichert...</span>';
    }

    // Parse date from input (YYYY-MM-DD)
    const selectedDate = new Date(validDate + 'T12:00:00');
    const pace = distance > 0 ? calculatePace(duration, distance) : null;

    const cardioSession = {
      type: 'cardio',
      date: firebase.firestore.Timestamp.fromDate(selectedDate),
      activityType,
      name: sessionName || null,
      duration,
      distanceKm: distance || null,
      pace: pace,
      avgHr,
      maxHr,
      notes: notes || null,
      createdAt: firebase.firestore.Timestamp.now()
    };

    const savedSessionId = await addDoc(sessionsCollection, cardioSession);


    // Mark pending scheduled entry as completed (Quick Entry support)
    await markPendingScheduledEntryCompleted(savedSessionId);

    // Close modal FIRST (before feedback/reload)
    closeAddCardioModal();

    // Show RPE feedback modal and patch session if provided
    if (typeof showRpeFeedbackModal === 'function') {
      const feedbackData = await showRpeFeedbackModal();
      if (feedbackData) {
        await updateDoc(sessionsCollection, savedSessionId, feedbackData);
      }
    }

    // Then reload sessions and refresh view
    await loadSessions();
    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    } else if (typeof renderCurrentProgressTab === 'function') {
      renderCurrentProgressTab();
    }

    // Trigger success glow animation
    triggerSuccessGlow();

  } catch (error) {
    console.error('❌ Error saving cardio session:', error);
    showErrorMessage(t('workoutModal.saveError') + ': ' + error.message);
  } finally {
    const saveBtn = document.querySelector('#add-cardio-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span class="material-symbols-rounded">check</span><span>Speichern</span>';
    }
  }
}

// ==================== UI HELPERS ====================

/**
 * Triggert Screen Edge Glow Animation (Apple Intelligence Style)
 */
function triggerSuccessGlow() {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('success');
  }
}

/**
 * Zeigt Fehler-Toast (nur für Fehler behalten wir eine Text-Notification)
 */
function showErrorMessage(message) {
  console.error('❌', message);
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', message);
  }
}

/**
 * Formatiert Datum als kurze Version
 */
function formatShortDate(date) {
  const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  const day = date.getDate();
  const month = months[date.getMonth()];
  return `${day}. ${month}`;
}

/**
 * Formatiert Duration als "1:30 h" oder "45 min"
 */
function formatDuration(minutes) {
  if (minutes >= 60) {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return mins > 0 ? `${hours}:${mins.toString().padStart(2, '0')} h` : `${hours} h`;
  }
  return `${minutes} min`;
}

function getValidDateStringForCardio(dateStr) {
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

/**
 * Handles backdrop click to close modal
 */
function handleModalBackdropClick(event, modalId) {
  if (event.target.id === modalId) {
    if (modalId === 'add-cardio-modal') {
      closeAddCardioModal();
    }
    if (modalId === 'add-strength-modal') {
      closeAddStrengthModal();
    }
    if (modalId === 'add-recovery-modal') {
      closeAddRecoveryModal();
    }
  }
}

// ==================== STRENGTH QUICK ENTRY MODAL ====================

// State for exercises being logged
let strengthLoggingExercises = [];
let exercisePickerCallback = null;

function openAddStrengthModal(dateStr = null) {
  // Reset exercises list
  strengthLoggingExercises = [];

  // Pre-populate exercises from scheduled plan if available
  const pending = window.pendingScheduledEntry;
  if (pending?.planId && typeof allPlans !== 'undefined' && allPlans) {
    const plan = allPlans.find(p => p.id === pending.planId);
    if (plan) {
      const items = typeof getPlanItems === 'function' ? getPlanItems(plan) : [];
      for (const item of items) {
        if (!item.exerciseId) continue;
        const exercise = typeof allExercises !== 'undefined' && allExercises
          ? allExercises.find(e => e.id === item.exerciseId)
          : null;
        const targetSets = item.target?.sets || 3;
        const targetReps = parseInt(item.target?.reps) || 10;
        strengthLoggingExercises.push({
          exerciseId: item.exerciseId,
          exerciseName: exercise ? getExerciseName(exercise) : item.exerciseId,
          sets: Array.from({ length: targetSets }, () => ({ reps: targetReps }))
        });
      }
    }
  }

  renderStrengthExercisesList();
  const modal = document.getElementById('add-strength-modal');
  if (!modal) return;

  const title = document.getElementById('strength-modal-title');
  if (title) title.textContent = t('workout.quick.title');
  const dateLabel = document.getElementById('strength-date-label');
  if (dateLabel) dateLabel.textContent = t('workout.quick.date');
  const nameLabel = document.getElementById('strength-name-label');
  if (nameLabel) nameLabel.textContent = t('workout.quick.name');
  const durationLabel = document.getElementById('strength-duration-label');
  if (durationLabel) durationLabel.textContent = t('workout.quick.duration');
  const typeLabel = document.getElementById('strength-type-label');
  if (typeLabel) typeLabel.textContent = t('workout.quick.type');
  const difficultyLabel = document.getElementById('strength-difficulty-label');
  if (difficultyLabel) difficultyLabel.textContent = t('workout.quick.difficulty');
  const bodyLabel = document.getElementById('strength-type-body-label');
  if (bodyLabel) bodyLabel.textContent = t('workout.quick.bodyweight');
  const bodyDesc = document.getElementById('strength-type-body-desc');
  if (bodyDesc) bodyDesc.textContent = t('workout.quick.bodyweightDesc');
  const weightsLabel = document.getElementById('strength-type-weights-label');
  if (weightsLabel) weightsLabel.textContent = t('workout.quick.weights');
  const weightsDesc = document.getElementById('strength-type-weights-desc');
  if (weightsDesc) weightsDesc.textContent = t('workout.quick.weightsDesc');
  const cancelLabel = document.getElementById('strength-cancel-label');
  if (cancelLabel) cancelLabel.textContent = t('common.cancel');
  const saveLabel = document.getElementById('strength-save-label');
  if (saveLabel) saveLabel.textContent = t('common.save');

  // Exercise logging labels
  const exercisesLabel = document.getElementById('strength-exercises-label');
  if (exercisesLabel) exercisesLabel.textContent = t('workout.logging.exercisesOptional');
  const addExerciseLabel = document.getElementById('strength-add-exercise-label');
  if (addExerciseLabel) addExerciseLabel.textContent = t('workout.logging.addExercise');

  // Reset form fields
  const today = new Date().toISOString().split('T')[0];
  const dateInput = document.getElementById('strength-date');
  const nameInput = document.getElementById('strength-name');
  const durationInput = document.getElementById('strength-duration');

  if (dateInput) dateInput.value = dateStr || today;
  if (nameInput) nameInput.value = '';
  if (durationInput) durationInput.value = '';

  setStrengthType('bodyweight');
  setStrengthDifficulty('intermediate');

  modal.style.display = '';
  modal.classList.add('active');
  triggerHapticFeedback('light');
}

function closeAddStrengthModal() {
  const modal = document.getElementById('add-strength-modal');
  if (!modal) return;

  modal.classList.remove('active');
  setTimeout(() => {
    modal.style.display = 'none';
  }, 300);
}

function setStrengthType(type) {
  const input = document.getElementById('strength-type');
  if (input) input.value = type;
  document.querySelectorAll('#add-strength-modal .discipline-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.discipline === type);
  });
}

function setStrengthDifficulty(level) {
  const input = document.getElementById('strength-difficulty');
  if (input) input.value = level;
  document.querySelectorAll('#add-strength-modal .difficulty-pill').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.difficulty === level);
  });

  document.querySelectorAll('#add-strength-modal .difficulty-pill').forEach(btn => {
    const key = btn.dataset.difficulty;
    if (key && t) {
      btn.textContent = t(`difficulty.${key}`);
    }
  });
}

// ==================== EXERCISE LOGGING FUNCTIONS ====================

/**
 * Open exercise picker for logging a workout
 */
function openExercisePickerForLogging() {
  // Set callback for when exercise is selected
  exercisePickerCallback = (exerciseId) => {
    addExerciseToStrengthLogging(exerciseId);
  };

  // Open the existing exercise picker in single-select mode
  if (typeof openAddExerciseToPlan === 'function') {
    // Temporarily override selectExerciseForPlan
    window._originalSelectExerciseForPlan = window.selectExerciseForPlan;
    window.selectExerciseForPlan = (exerciseId) => {
      if (exercisePickerCallback) {
        exercisePickerCallback(exerciseId);
        exercisePickerCallback = null;
      }
      closeExercisePicker();
      // Restore original function
      window.selectExerciseForPlan = window._originalSelectExerciseForPlan;
    };
    openAddExerciseToPlan();
    // Elevate exercise picker above the strength modal
    document.getElementById('exercise-picker-modal').classList.add('modal--elevated');
    // Switch to single-select mode for sessions
    if (typeof exercisePickerMode !== 'undefined') {
      exercisePickerMode = 'single';
      renderExercisePicker();
      updateExercisePickerAddButton();
    }
  }
}

/**
 * Add an exercise to the strength logging list
 */
function addExerciseToStrengthLogging(exerciseId) {
  // Check if exercise already exists
  if (strengthLoggingExercises.find(e => e.exerciseId === exerciseId)) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('info', t('workout.logging.exerciseAlreadyAdded'));
    }
    return;
  }

  // Get exercise details
  const exercise = (typeof allExercises !== 'undefined' && allExercises)
    ? allExercises.find(e => e.id === exerciseId)
    : null;

  if (!exercise) {
    console.error('Exercise not found:', exerciseId);
    return;
  }

  // Add with default sets
  strengthLoggingExercises.push({
    exerciseId: exerciseId,
    exerciseName: getExerciseName(exercise),
    sets: [{ reps: 10 }] // Default: 1 set of 10 reps
  });

  renderStrengthExercisesList();
  triggerHapticFeedback('light');
}

/**
 * Remove an exercise from the logging list
 */
function removeExerciseFromLogging(index) {
  strengthLoggingExercises.splice(index, 1);
  renderStrengthExercisesList();
}

/**
 * Open modal to edit exercise sets
 */
function editExerciseSets(index) {
  const exercise = strengthLoggingExercises[index];
  if (!exercise) return;

  // Open a simple prompt for sets count
  const currentSets = exercise.sets.length;
  const currentReps = exercise.sets[0]?.reps || 10;

  if (typeof openSheet === 'function') {
    openSheet({
      title: exercise.exerciseName,
      render: (container) => {
        container.innerHTML = `
          <div class="space-y-4 p-2">
            <div>
              <label class="block text-sm font-medium mb-2">${t('workout.logging.sets')}</label>
              <input type="number" id="edit-sets-count" value="${currentSets}" min="1" max="20"
                class="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 text-xl font-semibold focus:outline-none focus:ring-2 focus:ring-pink-500">
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">${t('workout.logging.reps')}</label>
              <input type="number" id="edit-reps-count" value="${currentReps}" min="1" max="100"
                class="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 text-xl font-semibold focus:outline-none focus:ring-2 focus:ring-pink-500">
            </div>
            <button onclick="saveExerciseSets(${index})" class="w-full btn-primary mt-4">
              <span class="material-symbols-rounded">check</span>
              <span>${t('common.save')}</span>
            </button>
          </div>
        `;
      }
    });
  }
}

/**
 * Save edited exercise sets
 */
function saveExerciseSets(index) {
  const setsInput = document.getElementById('edit-sets-count');
  const repsInput = document.getElementById('edit-reps-count');

  if (!setsInput || !repsInput) return;

  const setsCount = parseInt(setsInput.value) || 1;
  const repsCount = parseInt(repsInput.value) || 10;

  // Create sets array
  const sets = [];
  for (let i = 0; i < setsCount; i++) {
    sets.push({ reps: repsCount });
  }

  strengthLoggingExercises[index].sets = sets;

  if (typeof closeSheet === 'function') {
    closeSheet();
  }

  renderStrengthExercisesList();
}

/**
 * Render the list of exercises being logged
 */
function renderStrengthExercisesList() {
  const container = document.getElementById('strength-exercises-list');
  if (!container) return;

  if (strengthLoggingExercises.length === 0) {
    container.innerHTML = '';
    return;
  }

  container.innerHTML = strengthLoggingExercises.map((exercise, index) => {
    const totalReps = exercise.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
    const setsCount = exercise.sets.length;

    return `
      <div class="strength-exercise-item">
        <div class="exercise-icon">
          <span class="material-symbols-rounded">fitness_center</span>
        </div>
        <div class="exercise-info">
          <div class="exercise-name">${exercise.exerciseName}</div>
          <div class="exercise-sets-info">
            <span class="sets-badge">${setsCount} ${setsCount === 1 ? 'Satz' : 'Sätze'}</span>
            <span>${totalReps} Wdh.</span>
          </div>
        </div>
        <div class="exercise-actions">
          <button type="button" onclick="editExerciseSets(${index})" title="Bearbeiten">
            <span class="material-symbols-rounded">edit</span>
          </button>
          <button type="button" class="delete-btn" onclick="removeExerciseFromLogging(${index})" title="Entfernen">
            <span class="material-symbols-rounded">delete</span>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

async function saveStrengthSession() {
  const selectedDate = document.getElementById('strength-date')?.value;
  const name = document.getElementById('strength-name')?.value.trim();
  const duration = parseFloat(document.getElementById('strength-duration')?.value);
  const trainingType = document.getElementById('strength-type')?.value || 'bodyweight';
  const difficulty = document.getElementById('strength-difficulty')?.value || 'intermediate';

  if (!selectedDate) {
    showErrorMessage(t('workout.quick.dateRequired'));
    return;
  }

  if (!name) {
    showErrorMessage(t('workout.quick.nameRequired'));
    return;
  }

  if (!duration || duration <= 0) {
    showErrorMessage(t('workout.quick.durationRequired'));
    return;
  }

  try {
    const saveBtn = document.querySelector('#add-strength-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<div class="spinner-small"></div><span>Speichert...</span>';
    }

    const strengthSession = {
      type: 'strength',
      planName: name,
      date: firebase.firestore.Timestamp.fromDate(new Date(selectedDate + 'T12:00:00')),
      duration,
      discipline: trainingType,
      difficulty,
      exercises: strengthLoggingExercises.map(ex => {
        const entry = { exerciseId: ex.exerciseId, sets: ex.sets };
        const exMeta = typeof allExercises !== 'undefined'
          ? allExercises.find(e => e.id === ex.exerciseId)
          : null;
        if (exMeta?.usesBodyweight) {
          entry.usesBodyweight = true;
        }
        return entry;
      }),
      createdAt: firebase.firestore.Timestamp.now()
    };

    const savedSessionId = await addDoc(sessionsCollection, strengthSession);

    // Mark pending scheduled entry as completed (Quick Entry support)
    await markPendingScheduledEntryCompleted(savedSessionId);

    closeAddStrengthModal();

    // Show RPE feedback modal and patch session if provided
    if (typeof showRpeFeedbackModal === 'function') {
      const feedbackData = await showRpeFeedbackModal();
      if (feedbackData) {
        await updateDoc(sessionsCollection, savedSessionId, feedbackData);
      }
    }
    await loadSessions();
    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    } else if (typeof renderCurrentProgressTab === 'function') {
      renderCurrentProgressTab();
    }
    triggerSuccessGlow();
  } catch (error) {
    console.error('Error saving strength session:', error);
    showErrorMessage(t('workout.quick.saveError'));
  } finally {
    const saveBtn = document.querySelector('#add-strength-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span class="material-symbols-rounded">check</span><span>' + t('common.save') + '</span>';
    }
  }
}

// ==================== RECOVERY SESSION MODAL ====================

function openAddRecoveryModal(dateStr = null) {
  const modal = document.getElementById('add-recovery-modal');
  if (!modal) return;


  modal.style.display = '';

  const today = new Date().toISOString().split('T')[0];
  const dateInput = document.getElementById('recovery-date');
  const activityInput = document.getElementById('recovery-activity-type');
  const nameInput = document.getElementById('recovery-name');
  const durationInput = document.getElementById('recovery-duration');
  const notesInput = document.getElementById('recovery-notes');

  if (dateInput) {
    dateInput.value = dateStr || today;
  }
  if (activityInput) activityInput.value = 'yoga';
  if (nameInput) nameInput.value = '';
  if (durationInput) durationInput.value = '';
  if (notesInput) notesInput.value = '';

  modal.classList.add('active');
  triggerHapticFeedback('light');
}

function closeAddRecoveryModal() {
  const modal = document.getElementById('add-recovery-modal');
  if (!modal) return;


  modal.classList.remove('active');
  setTimeout(() => {
    modal.style.display = 'none';
  }, 300);

  setTimeout(() => {
    const dateInput = document.getElementById('recovery-date');
    const activityInput = document.getElementById('recovery-activity-type');
    const nameInput = document.getElementById('recovery-name');
    const durationInput = document.getElementById('recovery-duration');
    const notesInput = document.getElementById('recovery-notes');

    if (dateInput) dateInput.value = '';
    if (activityInput) activityInput.value = 'yoga';
    if (nameInput) nameInput.value = '';
    if (durationInput) durationInput.value = '';
    if (notesInput) notesInput.value = '';
  }, 300);
}

async function saveRecoverySession() {
  const dateInput = document.getElementById('recovery-date').value;
  const validDate = getValidDateStringForCardio(dateInput);
  const activityType = document.getElementById('recovery-activity-type').value;
  const sessionName = document.getElementById('recovery-name').value.trim();
  const duration = parseFloat(document.getElementById('recovery-duration').value);
  const notes = document.getElementById('recovery-notes').value.trim();

  if (!validDate) {
    showErrorMessage(t('workout.quick.dateRequired'));
    return;
  }

  if (!duration || duration <= 0) {
    showErrorMessage(t('workout.quick.durationRequired'));
    return;
  }

  try {
    const saveBtn = document.querySelector('#add-recovery-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<div class="spinner-small"></div><span>Speichert...</span>';
    }

    const selectedDate = new Date(validDate + 'T12:00:00');

    const recoverySession = {
      type: 'recovery',
      date: firebase.firestore.Timestamp.fromDate(selectedDate),
      activityType,
      name: sessionName || null,
      duration,
      notes: notes || null,
      createdAt: firebase.firestore.Timestamp.now()
    };

    const savedSessionId = await addDoc(sessionsCollection, recoverySession);


    // Mark pending scheduled entry as completed (Quick Entry support)
    await markPendingScheduledEntryCompleted(savedSessionId);

    closeAddRecoveryModal();

    // Show RPE feedback modal and patch session if provided
    if (typeof showRpeFeedbackModal === 'function') {
      const feedbackData = await showRpeFeedbackModal();
      if (feedbackData) {
        await updateDoc(sessionsCollection, savedSessionId, feedbackData);
      }
    }

    await loadSessions();
    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    } else if (typeof renderCurrentProgressTab === 'function') {
      renderCurrentProgressTab();
    }

    triggerSuccessGlow();
  } catch (error) {
    console.error('❌ Error saving recovery session:', error);
    showErrorMessage(t('workoutModal.saveError') + ': ' + error.message);
  } finally {
    const saveBtn = document.querySelector('#add-recovery-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span class="material-symbols-rounded">check</span><span>Speichern</span>';
    }
  }
}

// ==================== SCHEDULED ENTRY COMPLETION ====================

/**
 * Mark a pending scheduled entry (Quick Entry) as completed after session save
 * @param {string} sessionId - The ID of the saved session
 */
async function markPendingScheduledEntryCompleted(sessionId) {
  const pendingEntry = window.pendingScheduledEntry;
  if (!pendingEntry || !pendingEntry.id) {
    return; // No pending entry to mark
  }

  try {
    const scheduleUpdate = {
      status: 'completed',
      sessionId: sessionId,
      completedAt: firebase.firestore.Timestamp.now()
    };

    await updateDoc(scheduleCollection, pendingEntry.id, scheduleUpdate);
  } catch (error) {
    console.error('❌ Error marking scheduled entry as completed:', error);
  } finally {
    // Always clear pending entry after attempt
    window.pendingScheduledEntry = null;
  }
}

