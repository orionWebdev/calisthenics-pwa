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
 * Render workout screen
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
        <h3 class="empty-state-title">Kein aktives Workout</h3>
        <p class="empty-state-text">Starte ein Training aus dem Kalender oder einem Plan.</p>
        <button onclick="showView('plans')" class="empty-state-btn">
          <span class="material-symbols-rounded">assignment</span>
          <span>Zu den Plaenen</span>
        </button>
      </div>
    `;
    return;
  }

  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  const progress = calculateProgress();

  container.innerHTML = `
    <div class="workout-screen">
      ${renderWorkoutHeader(progress)}
      ${renderExerciseList()}
      ${renderCurrentExercise(currentExercise)}
      ${renderSetLogger(currentExercise)}
      ${renderCompletedSets(currentExercise)}
      ${renderWorkoutActions()}
    </div>
  `;

  // Auto-focus reps input
  const repsInput = document.getElementById('reps-input');
  if (repsInput) {
    setTimeout(() => repsInput.focus(), 100);
  }
}

/**
 * Render workout header
 */
function renderWorkoutHeader(progress) {
  return `
    <div class="workout-header">
      <h2 class="workout-title">${activeWorkout.planName}</h2>
      <div class="workout-meta">
        <span>${formatWorkoutDate(activeWorkout.scheduledDate)}</span>
        <span>·</span>
        <span>${progress.completed} / ${progress.total} Übungen</span>
      </div>
      <div class="workout-progress-bar">
        <div class="workout-progress-fill" style="width: ${progress.percentage}%"></div>
      </div>
      <div class="workout-actions">
        <button onclick="editWorkoutDate()" class="btn-secondary" style="flex: 1;">
          <span class="material-symbols-rounded" style="font-size: 18px;">calendar_month</span>
          <span>Datum ändern</span>
        </button>
        <button onclick="cancelWorkout()" class="btn-secondary" style="flex: 1;">
          <span class="material-symbols-rounded" style="font-size: 18px;">close</span>
          <span>Abbrechen</span>
        </button>
      </div>
    </div>
  `;
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
 * Render set logger
 */
function renderSetLogger(exercise) {
  if (!exercise) return '';

  const setNumber = exercise.completedSets.length + 1;

  return `
    <div class="set-logger">
      <h4 class="set-logger-title">Satz ${setNumber} loggen</h4>
      <div class="set-input-row">
        <div class="set-input-group">
          <label for="reps-input">Wiederholungen *</label>
          <input
            type="number"
            id="reps-input"
            class="set-input"
            placeholder="0"
            min="0"
            step="1"
            inputmode="numeric"
          />
        </div>
        <div class="set-input-group">
          <label for="weight-input">Gewicht (kg)</label>
          <input
            type="number"
            id="weight-input"
            class="set-input"
            placeholder="0"
            min="0"
            step="0.5"
            inputmode="decimal"
          />
        </div>
      </div>
      <button onclick="logSetFromInput()" class="log-set-btn">
        <span class="material-symbols-rounded">add_circle</span>
        <span>Satz loggen</span>
      </button>
    </div>
  `;
}

/**
 * Render completed sets
 */
function renderCompletedSets(exercise) {
  if (!exercise || exercise.completedSets.length === 0) return '';

  return `
    <div class="completed-sets-section">
      <h4 class="completed-sets-title">Abgeschlossene Sätze</h4>
      <div class="completed-sets-list">
        ${exercise.completedSets.map((set, setIndex) => `
          <div class="completed-set-item">
            <div class="set-info">
              <span class="material-symbols-rounded" style="font-size: 20px; color: #22c55e;">check_circle</span>
              <span>Satz ${setIndex + 1}:</span>
              <span>${set.reps} Reps${set.weight ? ` @ ${set.weight}kg` : ''}</span>
            </div>
            <div class="set-actions">
              <button
                onclick="deleteSet(${activeWorkout.currentExerciseIndex}, ${setIndex})"
                class="set-action-btn"
                title="Löschen"
              >
                <span class="material-symbols-rounded" style="font-size: 18px;">delete</span>
              </button>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

/**
 * Render workout actions (Next/Finish)
 */
function renderWorkoutActions() {
  const isLastExercise = activeWorkout.currentExerciseIndex === activeWorkout.exercises.length - 1;
  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  const hasSets = currentExercise && currentExercise.completedSets.length > 0;

  return `
    <div style="display: flex; gap: 1rem; margin-top: 1.5rem;">
      ${!isLastExercise ? `
        <button
          onclick="goToNextExercise()"
          class="btn-primary"
          style="flex: 1;"
          ${!hasSets ? 'disabled' : ''}
        >
          <span>Nächste Übung</span>
          <span class="material-symbols-rounded">arrow_forward</span>
        </button>
      ` : `
        <button
          onclick="completeWorkout()"
          class="btn-primary"
          style="flex: 1;"
        >
          <span class="material-symbols-rounded">check_circle</span>
          <span>Workout beenden</span>
        </button>
      `}
    </div>
  `;
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

  // Check if target sets reached
  if (currentExercise.completedSets.length >= currentExercise.targetSets) {
    currentExercise.status = 'completed';
  }

  saveActiveWorkout();
  renderWorkoutScreen();

  // Haptic feedback
  triggerHapticFeedback('medium');

  // Start rest timer if configured and not last set
  if (currentExercise.targetRest && currentExercise.completedSets.length < currentExercise.targetSets) {
    startRestTimer(currentExercise.targetRest);
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
 */
function goToNextExercise() {
  const currentExercise = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!currentExercise || currentExercise.completedSets.length === 0) {
    if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Bitte logge mindestens einen Satz bevor du weitergehst');
  }
    return;
  }

  if (activeWorkout.currentExerciseIndex < activeWorkout.exercises.length - 1) {
    goToExercise(activeWorkout.currentExerciseIndex + 1);
  }
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
  timer.className = 'rest-timer';
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

window.checkActiveWorkout = checkActiveWorkout;
window.ensureActiveWorkoutBanner = ensureActiveWorkoutBanner;
