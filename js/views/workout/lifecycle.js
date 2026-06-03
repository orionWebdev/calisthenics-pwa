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
        showEdgeFeedback('error', t('errors.planNotFound'));
      }
      return;
    }

    const normalizedDate = ensureValidDateString(scheduledDate);

    if (plan.type === 'cardio' && typeof openAddCardioModal === 'function') {
      if (scheduleId) {
        window.pendingScheduledEntry = { id: scheduleId };
      }
      openAddCardioModal();
      setTimeout(() => {
        const dateInput = document.getElementById('cardio-date');
        if (dateInput) dateInput.value = normalizedDate;
        const activityInput = document.getElementById('cardio-activity-type');
        if (activityInput && plan.activityType) {
          activityInput.value = plan.activityType;
        }
        const durationInput = document.getElementById('cardio-duration');
        const distanceInput = document.getElementById('cardio-distance');
        if (durationInput && plan.targetDurationMin) {
          durationInput.value = plan.targetDurationMin;
        }
        if (distanceInput && plan.targetDistanceKm) {
          distanceInput.value = plan.targetDistanceKm;
        }
        if (typeof updateCardioLivePace === 'function') {
          updateCardioLivePace();
        }
      }, 100);
      return;
    }

    if (plan.type === 'recovery' && typeof openAddRecoveryModal === 'function') {
      if (scheduleId) {
        window.pendingScheduledEntry = { id: scheduleId };
      }
      openAddRecoveryModal(normalizedDate);
      setTimeout(() => {
        const durationInput = document.getElementById('recovery-duration');
        if (durationInput && plan.targetDurationMin) {
          durationInput.value = plan.targetDurationMin;
        }
      }, 100);
      return;
    }
    if (!allExercises || allExercises.length === 0) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', t('errors.exercisesLoading'));
      }
      return;
    }

    // Default to today if no scheduled date or invalid date
    scheduledDate = normalizedDate;

    const planItems = typeof getPlanItems === 'function' ? getPlanItems(plan) : (plan.items || plan.exercises || []);
    if (!planItems || planItems.length === 0) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', t('errors.planExercisesRequired'));
      }
      return;
    }

    // Initialize active workout
    activeWorkout = {
      id: generateTempId(),
      status: 'in-progress',
      type: plan.type || 'strength',
      planId: plan.id,
      planName: plan.name,
      scheduleId: scheduleId,
      scheduledDate: scheduledDate,
      startedAt: firebase.firestore.Timestamp.now(),
      exercises: planItems.map(item => mapPlanItemToWorkoutExercise(item)),
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
      showEdgeFeedback('error', t('errors.workoutStartFailed'));
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
        showEdgeFeedback('error', t('errors.sessionNotFound'));
      }
      return;
    }

    const plan = allPlans.find(p => p.id === session.planId);
    if (!plan) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', t('errors.planNotFound'));
      }
      return;
    }
    if (!allExercises || allExercises.length === 0) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', t('errors.exercisesLoading'));
      }
      return;
    }

    // Create new workout based on session template
    const today = new Date();
    const dateStr = formatDate(today);

    const planItems = typeof getPlanItems === 'function' ? getPlanItems(plan) : (plan.items || plan.exercises || []);
    if (!planItems || planItems.length === 0) {
      if (typeof showEdgeFeedback === 'function') {
        showEdgeFeedback('error', t('errors.planExercisesRequired'));
      }
      return;
    }

    activeWorkout = {
      id: generateTempId(),
      status: 'in-progress',
      type: plan.type || 'strength',
      planId: session.planId,
      planName: session.planName,
      scheduleId: null, // No schedule link for manual workouts
      scheduledDate: dateStr,
      startedAt: firebase.firestore.Timestamp.now(),
      exercises: planItems.map(item => mapPlanItemToWorkoutExercise(item)),
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
      showEdgeFeedback('error', t('workout.feedback.restartError'));
    }
  }
}

/**
 * Start an empty (free) workout without a plan
 */
function startEmptyWorkout() {
  if (activeWorkout && !confirmReplaceActiveWorkout()) return;

  const today = new Date();
  const dateStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;

  activeWorkout = {
    id: generateTempId(),
    status: 'in-progress',
    type: 'strength',
    planId: null,
    planName: '',
    scheduleId: null,
    scheduledDate: dateStr,
    startedAt: firebase.firestore.Timestamp.now(),
    exercises: [],
    notes: '',
    currentExerciseIndex: 0,
    isFreeWorkout: true
  };

  saveActiveWorkout();
  showView('workout');
  renderWorkoutScreen();
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
    <button type="button" class="awb-main" onclick="resumeWorkout()">
      <span class="awb-icon material-symbols-rounded">play_circle</span>
      <span class="awb-text">
        <span class="awb-title">${t('workout.banner.resume')}</span>
        <span class="awb-sub">${activeWorkout.planName || ''}</span>
      </span>
      <span class="awb-cta material-symbols-rounded">chevron_right</span>
    </button>
    <button type="button" class="awb-dismiss" onclick="cancelActiveWorkoutFromBanner()" aria-label="${t('workout.banner.cancel')}">
      <span class="material-symbols-rounded">close</span>
    </button>
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
  if (confirm(t('workout.banner.cancelConfirm'))) {
    const banner = document.getElementById('active-workout-banner');
    if (banner) banner.remove();

    cancelWorkout(false); // Don't ask again
  }
}

/**
 * Cancel workout
 */
function cancelWorkout(askConfirmation = true) {
  if (askConfirmation && !confirm(t('workout.banner.cancelWorkoutConfirm'))) {
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
 * Confirm discard workout with i18n confirm dialog
 */
function confirmDiscardWorkout() {
  if (!confirm(t('workout.screen.discardConfirm'))) return;
  cancelWorkout(false);
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
      type: activeWorkout.type || 'strength',
      date: firebase.firestore.Timestamp.fromDate(workoutDate),
      planId: activeWorkout.planId,
      planName: activeWorkout.planName,
      exercises: activeWorkout.exercises
        .filter(ex => ex.completedSets && ex.completedSets.length > 0)
        .map(ex => {
          const entry = { exerciseId: ex.exerciseId };
          // Resolve usesBodyweight from exercise metadata
          const exMeta = typeof allExercises !== 'undefined'
            ? allExercises.find(e => e.id === ex.exerciseId)
            : null;
          if (exMeta?.usesBodyweight || ex.exerciseType === 'bodyweight') {
            entry.usesBodyweight = true;
          }
          entry.sets = ex.completedSets.map(set => {
            const s = {};
            if (set.reps != null) s.reps = set.reps;
            if (set.weight != null) s.weight = set.weight;
            if (set.holdSec != null) s.holdSec = set.holdSec;
            if (set.duration != null) s.duration = set.duration;
            if (set.distance != null) s.distance = set.distance;
            if (set.rpe != null) s.rpe = set.rpe;
            if (set.type) s.type = set.type;
            return s;
          });
          return entry;
        }),
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
    sessionData.id = savedSessionId;
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

    // Show RPE feedback modal and patch session if provided
    const feedbackData = await showRpeFeedbackModal();
    if (feedbackData) {
      await updateDoc(sessionsCollection, savedSessionId, feedbackData);
    }

    // Save data before clearing activeWorkout
    const planId = activeWorkout.planId;
    const isFreeWorkout = activeWorkout.isFreeWorkout || !activeWorkout.planId;
    const workoutExercises = activeWorkout.exercises.map(ex => ({
      exerciseId: ex.exerciseId,
      exerciseName: ex.exerciseName,
      targetSets: ex.targetSets || ex.completedSets.length || 3,
      targetReps: ex.targetReps || '10'
    }));

    // Clear active workout
    activeWorkout = null;
    localStorage.removeItem('activeWorkout');
    localStorage.removeItem('activeWorkoutId');
    cancelRestTimer();
    stopWorkoutTimer();

    // Reload sessions
    await loadSessions();

    // Re-render progress widgets so Form/Readiness scores are up-to-date
    if (typeof renderProgressV4 === 'function') {
      renderProgressV4();
    }

    // Vorherige Session + letzte 5 Sessions für Sparklines
    const prevSession = getPreviousSessionForPlan(planId, savedSessionId);
    const planSessions = typeof getSessionsForPlan === 'function'
      ? getSessionsForPlan(planId, 5, savedSessionId) : [];

    // Post-Workout Summary zeigen statt direkt zu Progress
    showPostWorkoutSummary(sessionData, prevSession, durationMinutes, planSessions);

    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', t('workout.feedback.saved'));
    }

    // For free workouts: ask if user wants to save as plan
    if (isFreeWorkout && workoutExercises.length > 0) {
      setTimeout(() => {
        askSaveWorkoutAsPlan(workoutExercises);
      }, 500);
    }
  } catch (error) {
    console.error('❌ Error completing workout:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workout.feedback.saveError') + ': ' + error.message);
    }
  }
}

