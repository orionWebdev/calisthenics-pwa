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

// Timestamp-based rest timer state (no drift)
let restTimerEndAt = null;         // Date.now() + remainingMs when running
let restTimerTotalMs = 0;          // Total duration in ms
let restTimerPausedRemaining = 0;  // Remaining ms when paused (>0 = paused)
let restTimerTickId = null;        // requestAnimationFrame / setInterval ID for UI ticks

// State for active set row (iOS-style set logger)
let activeSetValues = { reps: 10, weight: 0, holdSec: 0 };

function getWeightUnit() {
  if (typeof userProfile !== 'undefined' && userProfile.unitSystem === 'imperial') return 'lbs';
  return 'kg';
}

function isHoldTarget(exercise) {
  if (!exercise) return false;
  if (exercise.targetMode === 'hold') return true;
  if (exercise.targetMode === 'reps') return false;
  const holdSec = Number(exercise.targetHoldSec);
  return Number.isFinite(holdSec) && holdSec > 0;
}

function getTargetHoldSeconds(exercise) {
  const holdSec = Number(exercise?.targetHoldSec);
  return Number.isFinite(holdSec) ? holdSec : 0;
}

function formatHoldSeconds(seconds) {
  const value = Number(seconds);
  if (!Number.isFinite(value) || value <= 0) return '';
  if (value >= 60) {
    const minutes = Math.floor(value / 60);
    const remaining = Math.round(value % 60);
    return `${minutes}:${remaining.toString().padStart(2, '0')}`;
  }
  return t('common.secondsShort', { n: value });
}

function getExerciseTargetLine(exercise, options = {}) {
  const includeLabel = options.includeLabel !== false;
  if (isHoldTarget(exercise)) {
    const formatted = formatHoldSeconds(getTargetHoldSeconds(exercise));
    if (!formatted) {
      return includeLabel
        ? `${t('workout.setLogger.target')}: ${t('workout.hold')}`
        : t('workout.hold');
    }
    if (includeLabel) {
      return t('workout.targetHold', { seconds: formatted });
    }
    return `${formatted} ${t('workout.hold')}`;
  }
  const sets = exercise?.targetSets ?? 0;
  const reps = exercise?.targetReps ?? '-';
  return includeLabel
    ? `${t('workout.setLogger.target')}: ${sets} × ${reps}`
    : `${sets} × ${reps}`;
}

function getExerciseTargetDetailLine(exercise) {
  if (!exercise) return '';
  const restText = exercise.targetRest ? t('workout.setLogger.rest', { seconds: exercise.targetRest }) : '';
  if (isHoldTarget(exercise)) {
    const formatted = formatHoldSeconds(getTargetHoldSeconds(exercise));
    const base = formatted
      ? t('workout.targetHold', { seconds: formatted })
      : `${t('workout.setLogger.target')}: ${t('workout.hold')}`;
    return restText ? `${base} · ${restText}` : base;
  }
  const sets = exercise.targetSets ?? 0;
  const reps = exercise.targetReps ?? '-';
  const base = `${t('workout.setLogger.target')}: ${t('workout.setLogger.targetSets', { sets })} × ${t('workout.setLogger.targetReps', { reps })}`;
  return restText ? `${base} · ${restText}` : base;
}

function mapPlanItemToWorkoutExercise(item) {
  const exercise = allExercises.find(e => e.id === item.exerciseId);
  const target = item.target || {};
  const holdSec = Number(target.holdSec);
  const hasHold = Number.isFinite(holdSec) && holdSec > 0;
  const targetMode = hasHold ? 'hold' : 'reps';
  const targetReps = !hasHold ? (target.reps || '10-12') : undefined;

  const exType = exercise?.type || 'strength';
  const isCardioOrRecovery = exType === 'cardio' || exType === 'recovery';

  return {
    exerciseId: item.exerciseId,
    exerciseName: (typeof getExerciseName === 'function' ? getExerciseName(exercise) : exercise?.name) || item.exerciseId || t('exercise.title'),
    exerciseType: exType,
    targetSets: isCardioOrRecovery ? 1 : (target.sets || 3),
    targetMode,
    targetHoldSec: hasHold ? holdSec : undefined,
    targetReps,
    targetRest: isCardioOrRecovery ? 0 : (item.restSec || 90),
    completedSets: [],
    status: 'not-started',
    notes: '',
    executionType: item.executionType || 'normal',
    groupId: item.groupId || null,
    durationSec: item.durationSec || null,
    intervalSec: item.intervalSec || null
  };
}

// ========================================
// BLOCK HELPERS (derived at render time)
// ========================================

function getWorkoutBlocks() {
  if (!activeWorkout || !activeWorkout.exercises) return [];
  const exercises = activeWorkout.exercises;
  const blocks = [];
  const groupMap = new Map();

  exercises.forEach((ex, idx) => {
    if (ex.groupId) {
      let block = groupMap.get(ex.groupId);
      if (!block) {
        block = {
          type: ex.executionType || 'normal',
          groupId: ex.groupId,
          exerciseIndices: [],
          exercises: [],
          durationSec: ex.durationSec,
          intervalSec: ex.intervalSec
        };
        groupMap.set(ex.groupId, block);
        blocks.push(block);
      }
      block.exerciseIndices.push(idx);
      block.exercises.push(ex);
    } else {
      blocks.push({
        type: ex.executionType || 'normal',
        groupId: null,
        exerciseIndices: [idx],
        exercises: [ex],
        durationSec: null,
        intervalSec: null
      });
    }
  });
  return blocks;
}

function getCurrentBlock() {
  const blocks = getWorkoutBlocks();
  const idx = activeWorkout.currentExerciseIndex;
  return blocks.find(b => b.exerciseIndices.includes(idx)) || blocks[0] || null;
}

function getBlockIndex(block) {
  const blocks = getWorkoutBlocks();
  return blocks.indexOf(block);
}

function isBlockCompleted(block) {
  return block.exercises.every(ex => ex.status === 'completed');
}

/**
 * Get the exercise type for a workout exercise.
 * Falls back to looking up allExercises if exerciseType not stored.
 */
function getWorkoutExerciseType(exercise) {
  if (exercise.exerciseType) return exercise.exerciseType;
  const ex = typeof allExercises !== 'undefined'
    ? allExercises.find(e => e.id === exercise.exerciseId)
    : null;
  return ex?.type || 'strength';
}

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
      type: 'strength',
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
      type: 'strength',
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
    <div class="banner-content">
      <span class="material-symbols-rounded">play_circle</span>
      <span>${t('workout.banner.active', { name: activeWorkout.planName })}</span>
    </div>
    <div class="banner-actions">
      <button onclick="resumeWorkout()" class="banner-btn primary">${t('workout.banner.resume')}</button>
      <button onclick="cancelActiveWorkoutFromBanner()" class="banner-btn secondary">${t('workout.banner.cancel')}</button>
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
      type: 'strength',
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

// ==================== POST-WORKOUT SUMMARY ====================

/**
 * Gibt die letzte abgeschlossene Session für einen Plan zurück,
 * exklusive der gerade gespeicherten Session (per ID).
 */
function getPreviousSessionForPlan(planId, excludeId) {
  if (!planId) return null;
  const userId = typeof getActiveUserId === 'function' ? getActiveUserId() : null;
  const sessions = typeof allSessions !== 'undefined' ? allSessions : [];
  const relevant = sessions.filter(s =>
    s.planId === planId &&
    s.id !== excludeId &&
    (!userId || s.userId === userId)
  );
  if (!relevant.length) return null;
  relevant.sort((a, b) => {
    const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return db - da;
  });
  return relevant[0];
}

/**
 * Berechnet Gesamtvolumen einer Session: Σ (reps × weight) oder Σ reps falls kein Gewicht.
 */
function calcSessionVolume(session) {
  if (!session?.exercises) return 0;
  return session.exercises.reduce((total, ex) => {
    return total + (ex.sets || []).reduce((s, set) => {
      const reps = set.reps || 0;
      const weight = set.weight || 0;
      return s + (weight > 0 ? reps * weight : reps);
    }, 0);
  }, 0);
}

/**
 * Berechnet Gesamtanzahl Sätze einer Session.
 */
function calcSessionSets(session) {
  if (!session?.exercises) return 0;
  return session.exercises.reduce((total, ex) => total + (ex.sets?.length || 0), 0);
}

/**
 * Formatiert ein Delta für die Anzeige: +5%, −2 Min, etc.
 */
function formatDelta(current, previous, unit) {
  if (previous == null || previous === 0) return null;
  const diff = current - previous;
  if (diff === 0) return null;
  const pct = Math.round((diff / previous) * 100);
  const sign = diff > 0 ? '+' : '';
  if (unit === '%') return `${sign}${pct}%`;
  return `${sign}${diff} ${unit}`;
}

/**
 * Baut per-exercise Vergleich zwischen aktueller und vorheriger Session.
 */
function buildExerciseComparison(currentSession, prevSession, planSessions) {
  const currentExercises = currentSession?.exercises || [];
  const prevExercises = prevSession?.exercises || [];
  const prevMap = {};
  prevExercises.forEach(ex => { prevMap[ex.exerciseId] = ex; });
  const currentMap = {};
  currentExercises.forEach(ex => { currentMap[ex.exerciseId] = ex; });

  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
  const result = [];

  // Current exercises
  currentExercises.forEach(ex => {
    const prev = prevMap[ex.exerciseId];
    const exData = exercises.find(e => e.id === ex.exerciseId);
    const name = exData?.name || ex.exerciseId;
    const curVol = typeof calculateExerciseWeightedVolume === 'function'
      ? calculateExerciseWeightedVolume(ex) : (ex.sets || []).reduce((s, set) => s + (set.reps || 0), 0);
    const prevVol = prev ? (typeof calculateExerciseWeightedVolume === 'function'
      ? calculateExerciseWeightedVolume(prev) : (prev.sets || []).reduce((s, set) => s + (set.reps || 0), 0)) : null;

    const curSets = ex.sets?.length || 0;
    const curAvgReps = curSets > 0 ? Math.round((ex.sets || []).reduce((s, set) => s + (set.reps || 0), 0) / curSets) : 0;
    const prevSets = prev ? (prev.sets?.length || 0) : null;
    const prevAvgReps = prevSets > 0 ? Math.round((prev.sets || []).reduce((s, set) => s + (set.reps || 0), 0) / prevSets) : null;

    const sparkline = planSessions.length > 0 && typeof getExerciseSparklineData === 'function'
      ? getExerciseSparklineData(planSessions, ex.exerciseId) : [];

    result.push({
      exerciseId: ex.exerciseId, name,
      curSets, curAvgReps, prevSets, prevAvgReps,
      curVol, prevVol,
      isNew: !prev, isRemoved: false,
      sparkline,
      trend: prevVol !== null ? (curVol > prevVol ? 'up' : curVol < prevVol ? 'down' : 'same') : null
    });
  });

  // Removed exercises
  prevExercises.forEach(ex => {
    if (!currentMap[ex.exerciseId]) {
      const exData = exercises.find(e => e.id === ex.exerciseId);
      const name = exData?.name || ex.exerciseId;
      const prevSets = ex.sets?.length || 0;
      const prevAvgReps = prevSets > 0 ? Math.round((ex.sets || []).reduce((s, set) => s + (set.reps || 0), 0) / prevSets) : 0;
      result.push({
        exerciseId: ex.exerciseId, name,
        curSets: null, curAvgReps: null, prevSets, prevAvgReps,
        curVol: null, prevVol: typeof calculateExerciseWeightedVolume === 'function' ? calculateExerciseWeightedVolume(ex) : 0,
        isNew: false, isRemoved: true, sparkline: [], trend: null
      });
    }
  });

  return result;
}
window.buildExerciseComparison = buildExerciseComparison;

/**
 * Monotone cubic tangents (Fritsch-Carlson) for smooth sparkline curves.
 */
function _monotoneTangents(points) {
  const n = points.length;
  if (n < 2) return [];
  const d = [], m = [];
  for (let i = 0; i < n - 1; i++) {
    const dx = points[i + 1].x - points[i].x;
    d[i] = dx === 0 ? 0 : (points[i + 1].y - points[i].y) / dx;
  }
  m[0] = d[0];
  for (let i = 1; i < n - 1; i++) {
    if (d[i - 1] * d[i] <= 0) { m[i] = 0; }
    else { m[i] = (d[i - 1] + d[i]) / 2; }
  }
  m[n - 1] = d[n - 2];
  for (let i = 0; i < n - 1; i++) {
    if (Math.abs(d[i]) < 1e-6) { m[i] = m[i + 1] = 0; continue; }
    const a = m[i] / d[i], b = m[i + 1] / d[i];
    const s = a * a + b * b;
    if (s > 9) { const t = 3 / Math.sqrt(s); m[i] = t * a * d[i]; m[i + 1] = t * b * d[i]; }
  }
  return m;
}

/**
 * Zeichnet Mini-Sparkline in ein Canvas.
 * options: { smooth: bool, fill: bool, lineWidth: number }
 */
function drawMiniSparkline(canvasId, values, trendColor, options) {
  const canvas = document.getElementById(canvasId);
  if (!canvas || values.length < 2) return;
  const opts = options || {};
  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);
  const w = rect.width, h = rect.height, pad = 2;
  const max = Math.max(...values), min = Math.min(...values);
  const range = max - min || 1;

  // Compute point coordinates
  const points = values.map((v, i) => ({
    x: pad + (i / (values.length - 1)) * (w - 2 * pad),
    y: h - pad - ((v - min) / range) * (h - 2 * pad)
  }));

  // Draw line path
  ctx.beginPath();
  ctx.strokeStyle = trendColor;
  ctx.lineWidth = opts.lineWidth || 1.5;
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';

  if (opts.smooth && points.length >= 3) {
    const m = _monotoneTangents(points);
    ctx.moveTo(points[0].x, points[0].y);
    for (let i = 1; i < points.length; i++) {
      const prev = points[i - 1];
      const cur = points[i];
      const dx = (cur.x - prev.x) / 3;
      ctx.bezierCurveTo(
        prev.x + dx, prev.y + m[i - 1] * dx,
        cur.x - dx, cur.y - m[i] * dx,
        cur.x, cur.y
      );
    }
  } else {
    points.forEach((p, i) => {
      if (i === 0) ctx.moveTo(p.x, p.y); else ctx.lineTo(p.x, p.y);
    });
  }
  ctx.stroke();

  // Gradient fill under curve
  if (opts.fill) {
    ctx.lineTo(points[points.length - 1].x, h);
    ctx.lineTo(points[0].x, h);
    ctx.closePath();
    const grad = ctx.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, trendColor + '33'); // ~0.2 opacity
    grad.addColorStop(1, trendColor + '00'); // transparent
    ctx.fillStyle = grad;
    ctx.fill();
  }
}
window.drawMiniSparkline = drawMiniSparkline;
window._monotoneTangents = _monotoneTangents;

/**
 * Trend-Farbe bestimmen.
 */
function getTrendColor(trend) {
  if (trend === 'up') return '#22c55e';
  if (trend === 'down') return '#ef4444';
  return '#9ca3af';
}

/**
 * Trend-Icon bestimmen.
 */
function getTrendIcon(trend) {
  if (trend === 'up') return 'trending_up';
  if (trend === 'down') return 'trending_down';
  return 'trending_flat';
}

/**
 * Zeigt den Post-Workout Summary Screen.
 */
function showPostWorkoutSummary(savedSession, prevSession, durationMinutes, planSessions) {
  const modal = document.getElementById('post-workout-summary-modal');
  const body = document.getElementById('post-workout-summary-body');
  if (!modal || !body) {
    showView('progress');
    triggerSuccessGlow();
    return;
  }

  const tr = typeof t === 'function' ? t : (k) => k;
  const currentSets = savedSession.exercises
    ? savedSession.exercises.reduce((t, ex) => t + (ex.sets?.length || 0), 0)
    : 0;
  const currentVol = calcSessionVolume(savedSession);

  // Overall comparison
  let comparisonHTML = '';
  if (prevSession) {
    const prevDuration = prevSession.duration || 0;
    const prevSets = calcSessionSets(prevSession);
    const prevVol = calcSessionVolume(prevSession);
    const items = [];
    const durDelta = formatDelta(durationMinutes, prevDuration, 'Min');
    items.push({ icon: 'schedule', label: t('workout.postWorkout.time'), current: `${durationMinutes} Min`, delta: durDelta, positive: durationMinutes >= prevDuration });
    const setsDelta = formatDelta(currentSets, prevSets, 'Sets');
    items.push({ icon: 'repeat', label: t('workout.postWorkout.sets'), current: String(currentSets), delta: setsDelta, positive: currentSets >= prevSets });
    if (currentVol > 0 || prevVol > 0) {
      const volDelta = formatDelta(currentVol, prevVol, '%');
      items.push({ icon: 'fitness_center', label: t('workout.postWorkout.volume'), current: currentVol > 0 ? `${currentVol} ${getWeightUnit()}` : '\u2014', delta: volDelta, positive: currentVol >= prevVol });
    }
    comparisonHTML = `
      <div class="pws-section-title">${t('workout.postWorkout.comparisonTitle')}</div>
      <div class="pws-comparison-grid">
        ${items.map(item => `
          <div class="pws-stat-card">
            <span class="material-symbols-rounded pws-stat-icon">${item.icon}</span>
            <div class="pws-stat-value">${item.current}</div>
            <div class="pws-stat-label">${item.label}</div>
            ${item.delta ? `<div class="pws-stat-delta ${item.positive ? 'positive' : 'negative'}">${item.delta}</div>` : ''}
          </div>
        `).join('')}
      </div>
    `;
  }

  // Per-exercise comparison
  const exComparison = buildExerciseComparison(savedSession, prevSession, planSessions || []);
  let exercisesHTML = '';
  if (exComparison.length > 0) {
    const exTitle = tr('progress.v4.postWorkout.exercisesTitle') || 'Übungen im Detail';
    const badgeNew = tr('progress.v4.postWorkout.badgeNew') || 'Neu';
    const badgeRemoved = tr('progress.v4.postWorkout.badgeRemoved') || 'Letztes Mal';
    exercisesHTML = `
      <div class="pws-exercises-section">
        <div class="pws-section-title">${exTitle}</div>
        <div class="pws-exercise-list">
          ${exComparison.map(ex => {
            const curLabel = ex.curSets !== null ? `${ex.curSets}x${ex.curAvgReps}` : '\u2014';
            const prevLabel = ex.prevSets !== null ? `${ex.prevSets}x${ex.prevAvgReps}` : '';
            const badge = ex.isNew ? `<span class="pws-exercise-badge new">${badgeNew}</span>`
              : ex.isRemoved ? `<span class="pws-exercise-badge removed">${badgeRemoved}</span>` : '';
            const trendClass = ex.trend || 'same';
            const trendIcon = getTrendIcon(ex.trend);
            const hasSparkline = ex.sparkline && ex.sparkline.length >= 2;
            const sparkId = `pws-spark-${ex.exerciseId.replace(/[^a-zA-Z0-9]/g, '_')}`;
            return `
              <div class="pws-exercise-row${ex.isRemoved ? ' removed' : ''}">
                <div class="pws-exercise-info">
                  <div class="pws-exercise-name">${ex.name} ${badge}</div>
                  <div class="pws-exercise-sets">
                    ${curLabel}${prevLabel && !ex.isNew ? ` <span class="pws-exercise-vs">vs ${prevLabel}</span>` : ''}
                  </div>
                </div>
                ${hasSparkline ? `<canvas class="pws-exercise-sparkline" id="${sparkId}"></canvas>` : '<div class="pws-exercise-sparkline"></div>'}
                ${ex.trend ? `<span class="material-symbols-rounded pws-exercise-trend ${trendClass}">${trendIcon}</span>` : '<div style="width:20px"></div>'}
              </div>
            `;
          }).join('')}
        </div>
      </div>
    `;
  }

  body.innerHTML = `
    <div class="pws-header">
      <div class="pws-success-icon">
        <span class="material-symbols-rounded">check_circle</span>
      </div>
      <h2 class="pws-title">${t('workout.postWorkout.title')}</h2>
      <p class="pws-subtitle">${savedSession.planName || t('workout.postWorkout.fallbackName')}</p>
    </div>

    <div class="pws-stats-row">
      <div class="pws-quick-stat">
        <div class="pws-quick-stat-value">${durationMinutes}</div>
        <div class="pws-quick-stat-label">${t('workout.postWorkout.minutes')}</div>
      </div>
      <div class="pws-quick-stat">
        <div class="pws-quick-stat-value">${currentSets}</div>
        <div class="pws-quick-stat-label">${t('workout.postWorkout.sets')}</div>
      </div>
      ${(savedSession.exercises || []).length > 0 ? `
      <div class="pws-quick-stat">
        <div class="pws-quick-stat-value">${savedSession.exercises.length}</div>
        <div class="pws-quick-stat-label">${t('workout.postWorkout.exercises')}</div>
      </div>
      ` : ''}
    </div>

    ${comparisonHTML}
    ${exercisesHTML}

    <button type="button" class="pws-dismiss-btn" onclick="dismissPostWorkoutSummary()">
      <span class="material-symbols-rounded">bar_chart</span>
      <span>${t('workout.postWorkout.toProgress')}</span>
    </button>
  `;

  modal.classList.add('active');

  // Draw sparklines after DOM is ready
  requestAnimationFrame(() => {
    exComparison.forEach(ex => {
      if (ex.sparkline && ex.sparkline.length >= 2) {
        const sparkId = `pws-spark-${ex.exerciseId.replace(/[^a-zA-Z0-9]/g, '_')}`;
        drawMiniSparkline(sparkId, ex.sparkline, getTrendColor(ex.trend));
      }
    });
  });
}

/**
 * Schließt den Summary Screen und navigiert zum Fortschritt.
 */
function dismissPostWorkoutSummary() {
  const modal = document.getElementById('post-workout-summary-modal');
  if (modal) modal.classList.remove('active');
  showView('progress');
  triggerSuccessGlow();
}

window.dismissPostWorkoutSummary = dismissPostWorkoutSummary;

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

  const exerciseRows = block.exercises.map(ex => {
    const reps = ex.targetReps || '-';
    return `
      <div class="emom-prescreen-exercise">
        <span class="emom-prescreen-exercise-name">${ex.exerciseName}</span>
        <span class="emom-prescreen-exercise-reps">×${reps}</span>
      </div>
    `;
  }).join('');

  const bannerLabel = `EMOM · ${t('block.workout.emom.prescreenDuration', { minutes: durationMin })}`;
  const bannerMeta = t('block.workout.emom.prescreenEveryMinute');

  return `
    <div class="block-content block-content--emom">
      ${renderBlockBanner('emom', bannerLabel, bannerMeta)}
      <div class="emom-prescreen">
        <div class="emom-prescreen-icon">
          <span class="material-symbols-rounded" style="font-size:3rem;">timer</span>
        </div>
        <div class="emom-prescreen-title">${t('block.workout.emom.prescreenTitle')}</div>
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

  emomTimerState = {
    blockGroupId: block.groupId,
    startedAt: Date.now(),
    durationSec: block.durationSec || 600,
    intervalSec: block.intervalSec || 60,
    tickId: null,
    lastMinute: -1
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
      emomTimerState.lastMinute = currentMinute;
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

  if (timerEl) timerEl.textContent = formatEmomTime(remainingInMinute);
  if (minuteEl) minuteEl.textContent = t('block.workout.emom.minute', { current: Math.min(currentMinute, totalMinutes), total: totalMinutes });
  if (currentNameEl) currentNameEl.textContent = currentEx?.exerciseName || '';
  if (currentTargetEl) currentTargetEl.textContent = '×' + (currentEx?.targetReps || '-');
  if (nextHintEl) nextHintEl.textContent = t('block.workout.emom.next', { name: nextEx?.exerciseName || '', reps: nextEx?.targetReps || '-' });
  if (totalEl) totalEl.textContent = t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) });
  if (progressFillEl) progressFillEl.style.width = `${minuteProgressPct}%`;
  if (bannerLabelEl) bannerLabelEl.textContent = `EMOM · ${t('block.workout.emom.minute', { current: Math.min(currentMinute, totalMinutes), total: totalMinutes })}`;
  if (bannerMetaEl) bannerMetaEl.textContent = t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) });
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
  const currentExIdx = (currentMinute - 1) % exCount;
  const nextExIdx = currentMinute % exCount;
  const currentEx = block.exercises[currentExIdx];
  const nextEx = block.exercises[nextExIdx];

  const bannerLabel = `EMOM · ${t('block.workout.emom.minute', { current: currentMinute, total: totalMinutes })}`;
  const bannerMeta = t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) });

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
          <div class="emom-current-exercise-target" id="emom-current-target">×${currentEx?.targetReps || '-'}</div>
        </div>

        <div class="emom-next-hint" id="emom-next-hint">
          ${t('block.workout.emom.next', { name: nextEx?.exerciseName || '', reps: nextEx?.targetReps || '-' })}
        </div>
        <div class="emom-total-remaining" id="emom-total-remaining">
          ${t('block.workout.emom.totalRemaining', { time: formatEmomTime(totalRemaining) })}
        </div>

        <div class="emom-log-buttons">
          <button type="button" class="emom-log-btn emom-log-btn--done" onclick="logEmomRound(true)">
            <span class="material-symbols-rounded">check</span>
            ${t('block.workout.emom.done')}
          </button>
          <button type="button" class="emom-log-btn emom-log-btn--missed" onclick="logEmomRound(false)">
            <span class="material-symbols-rounded">close</span>
            ${t('block.workout.emom.missed')}
          </button>
        </div>
      </div>
    </div>
  `;
}

function logEmomRound(completed) {
  if (!emomTimerState || !activeWorkout) return;
  const block = getCurrentBlock();
  if (!block) return;

  const elapsed = (Date.now() - emomTimerState.startedAt) / 1000;
  const currentMinute = Math.floor(elapsed / emomTimerState.intervalSec);
  const exCount = block.exercises.length;
  const currentExIdx = currentMinute % exCount;
  const exercise = block.exercises[currentExIdx];

  if (exercise) {
    const reps = completed ? parseInt(exercise.targetReps, 10) || 0 : 0;
    exercise.completedSets.push({
      reps,
      weight: null,
      completedAt: firebase.firestore.Timestamp.now(),
      emomMinute: currentMinute + 1
    });
    saveActiveWorkout();
  }

  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback(completed ? 'success' : 'light');
  }
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

  return `
    <div class="st-detail">
      <div class="st-detail-info">
        <h3 class="st-detail-name">${exercise.exerciseName}</h3>
        <span class="st-detail-type">${typeLabel}</span>
      </div>
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

  const holdMode = isHoldTarget(exercise);
  const targetSets = exercise.targetSets || 3;
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
          <div class="st-set-stepper-group">
            <button type="button" class="st-stepper-btn" onclick="adjustActiveSetValue('reps', -1)" aria-label="-1">
              <span class="material-symbols-rounded">remove</span>
            </button>
            <button type="button" class="st-set-val st-set-val--editable" onclick="openNumberPickerForNewSet('reps')" id="active-reps-btn" data-value="${activeSetValues.reps}">
              <span class="st-set-val-num" id="active-reps-value">${activeSetValues.reps}</span>
              <span class="st-set-val-unit">${valueUnit}</span>
            </button>
            <button type="button" class="st-stepper-btn" onclick="adjustActiveSetValue('reps', 1)" aria-label="+1">
              <span class="material-symbols-rounded">add</span>
            </button>
          </div>
          <div class="st-set-stepper-group">
            <button type="button" class="st-stepper-btn" onclick="adjustWeightByCurrentStep(-1)" aria-label="${t('workout.setLogger.decreaseWeight')}">
              <span class="material-symbols-rounded">remove</span>
            </button>
            <button type="button" class="st-set-val st-set-val--editable" onclick="handleWeightValueTap()" id="active-weight-btn" data-value="${activeSetValues.weight}">
              <span class="st-set-val-num" id="active-weight-value">${activeWeightDisplay || '0'}</span>
              <span class="st-set-val-unit">${getWeightUnit()}</span>
            </button>
            <button type="button" class="st-stepper-btn" onclick="adjustWeightByCurrentStep(1)" aria-label="${t('workout.setLogger.increaseWeight')}">
              <span class="material-symbols-rounded">add</span>
            </button>
          </div>
        </div>
        <div class="st-set-actions">
          <button type="button" class="st-set-check st-set-check--log" onclick="logSetFromActiveRow()" aria-label="${t('workout.setLogger.logSet')}">
            <span class="material-symbols-rounded">check</span>
          </button>
        </div>
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
    </div>
  `;
}

// renderSTRestTimer() removed - timer is now a separate fixed widget (renderTimerWidget)

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

  exercise.targetSets = (exercise.targetSets || 3) + 1;
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

  if (isHoldTarget(exercise)) {
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

  const holdMode = isHoldTarget(exercise);

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
  const holdMode = isHoldTarget(exercise);

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

  openNumberPicker({
    type: type,
    initialValue: initialValue,
    onConfirm: (newValue) => {
      if (type === 'hold') {
        activeSetValues.holdSec = newValue;
        updateActiveRowDisplay('hold', newValue);
      } else if (type === 'reps') {
        activeSetValues.reps = newValue;
        updateActiveRowDisplay('reps', newValue);
      } else {
        activeSetValues.weight = newValue;
        updateActiveRowDisplay('weight', newValue);
      }
      triggerHapticFeedback('light');
    }
  });
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
  if (isHoldTarget(currentExercise)) {
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
  return `
    <div class="workout-bottom-actions">
      <button onclick="replacingExerciseIndex=null;openAddExerciseToWorkout()" class="btn-primary" style="width:100%;">
        <span class="material-symbols-rounded" style="font-size:18px;">add</span>
        <span>Übung hinzufügen</span>
      </button>
      <div style="display:flex;gap:0.5rem;width:100%;">
        <button onclick="replaceCurrentExerciseInWorkout()" class="workout-action-btn-outline" style="flex:1;">
          <span class="material-symbols-rounded" style="font-size:16px;">swap_horiz</span>
          <span>Übung ersetzen</span>
        </button>
        <button onclick="removeCurrentExerciseFromWorkout()" class="workout-action-btn-outline workout-action-btn-outline--danger" style="flex:1;">
          <span class="material-symbols-rounded" style="font-size:16px;">delete</span>
          <span>Übung löschen</span>
        </button>
      </div>
    </div>
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
          onclick="closeWorkoutEndConfirmModal(); completeWorkout();"
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

  console.log('✅ Set logged:', holdSec ? `${holdSec}s hold` : `${reps} reps`, weight ? `@ ${weight}kg` : '');

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
        <span class="timer-widget-label">${t('workout.screen.restTimer')}</span>
        <span class="timer-widget-time" id="tw-time">0:00</span>
        <span class="material-symbols-rounded timer-widget-chevron">expand_less</span>
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
  if (typeof formatDateLongText === 'function') return formatDateLongText(date, true);
  return date.toLocaleDateString();
}

/**
 * Edit workout date
 */
function editWorkoutDate() {
  const newDate = prompt(t('workout.editDate.prompt'), activeWorkout.scheduledDate);
  if (!newDate) return;

  const validDate = getValidDateString(newDate);
  if (!validDate) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workout.editDate.error'));
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
  if (typeof getSettingValue === 'function' && !getSettingValue('hapticsEnabled')) return;

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

// ========================================
// SAVE WORKOUT AS PLAN
// ========================================

function askSaveWorkoutAsPlan(workoutExercises) {
  if (!confirm('Workout als Plan speichern?')) return;
  openPlanModalWithExercises(workoutExercises);
}

function openPlanModalWithExercises(workoutExercises) {
  if (typeof openAddPlanModal !== 'function') return;

  // Open the plan modal fresh
  openAddPlanModal();

  // Pre-fill exercises into currentPlan
  if (typeof currentPlan !== 'undefined' && currentPlan) {
    currentPlan.items = workoutExercises.map(ex => ({
      exerciseId: ex.exerciseId,
      target: {
        sets: ex.targetSets || 3,
        reps: ex.targetReps || '10'
      }
    }));

    if (typeof renderPlanExercises === 'function') {
      renderPlanExercises();
    }
  }
}

// ========================================
// ADD/REMOVE EXERCISES DURING WORKOUT
// ========================================

function openAddExerciseToWorkout() {
  // Use existing exercise picker bottom sheet pattern
  const existing = document.getElementById('workout-exercise-picker-sheet');
  if (existing) existing.remove();

  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];

  const sheet = document.createElement('div');
  sheet.id = 'workout-exercise-picker-sheet';
  sheet.className = 'exercises-sheet-overlay';
  sheet.innerHTML = `
    <div class="exercises-sheet" role="dialog" aria-modal="true">
      <div class="exercises-sheet-header">
        <div class="exercises-sheet-drag-handle"></div>
        <h3 class="exercises-sheet-title">${t('workout.screen.addExercise')}</h3>
        <button type="button" onclick="closeWorkoutExercisePicker()" class="exercises-sheet-close" aria-label="${t('common.close')}">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
      <div class="exercises-sheet-content" style="padding:0.5rem 1rem;">
        <input type="text" id="workout-exercise-search" placeholder="${t('workout.screen.searchExercise')}"
          class="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-2 mb-3 focus:outline-none focus:ring-2 focus:ring-pink-500"
          oninput="filterWorkoutExercisePicker(this.value)" />
        <div id="workout-exercise-picker-list" class="exercises-sheet-list">
          ${renderWorkoutExercisePickerList(exercises, '')}
        </div>
      </div>
    </div>
  `;

  document.body.appendChild(sheet);
  document.body.style.overflow = 'hidden';
  requestAnimationFrame(() => sheet.classList.add('active'));

  sheet.addEventListener('click', (e) => {
    if (e.target === sheet) closeWorkoutExercisePicker();
  });
}

function renderWorkoutExercisePickerList(exercises, filter) {
  const filtered = filter
    ? exercises.filter(ex => ex.name.toLowerCase().includes(filter.toLowerCase()))
    : exercises;

  if (filtered.length === 0) {
    return `<p style="text-align:center;color:var(--text-tertiary);padding:1rem;">${t('workout.screen.noExercisesFound')}</p>`;
  }

  return filtered.map(ex => `
    <button type="button" class="exercises-sheet-item" onclick="addExerciseToWorkout('${ex.id}')">
      <div class="exercises-sheet-item-number">
        <span class="material-symbols-rounded" style="font-size:18px;">add</span>
      </div>
      <div class="exercises-sheet-item-info">
        <div class="exercises-sheet-item-name">${ex.name}</div>
        <div class="exercises-sheet-item-target" style="font-size:0.75rem;color:var(--text-tertiary);">
          ${(ex.muscleGroups || []).map(m => typeof getMuscleNames === 'function' ? (getMuscleNames()[m] || m) : m).join(', ')}
        </div>
      </div>
    </button>
  `).join('');
}

function filterWorkoutExercisePicker(value) {
  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
  const list = document.getElementById('workout-exercise-picker-list');
  if (list) list.innerHTML = renderWorkoutExercisePickerList(exercises, value);
}

function addExerciseToWorkout(exerciseId) {
  addExerciseToWorkoutOrReplace(exerciseId);
}

function closeWorkoutExercisePicker() {
  const sheet = document.getElementById('workout-exercise-picker-sheet');
  if (!sheet) return;
  sheet.classList.remove('active');
  sheet.classList.add('closing');
  setTimeout(() => {
    sheet.remove();
    document.body.style.overflow = '';
  }, 300);
}

function removeCurrentExerciseFromWorkout() {
  if (!activeWorkout || activeWorkout.exercises.length === 0) return;
  const currentEx = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
  if (!confirm(`"${currentEx.exerciseName}" aus dem Workout entfernen?`)) return;

  activeWorkout.exercises.splice(activeWorkout.currentExerciseIndex, 1);

  // Adjust current index
  if (activeWorkout.exercises.length === 0) {
    activeWorkout.currentExerciseIndex = 0;
  } else if (activeWorkout.currentExerciseIndex >= activeWorkout.exercises.length) {
    activeWorkout.currentExerciseIndex = activeWorkout.exercises.length - 1;
  }

  // Mark new current as in-progress if needed
  if (activeWorkout.exercises.length > 0) {
    const current = activeWorkout.exercises[activeWorkout.currentExerciseIndex];
    if (current.status === 'not-started') current.status = 'in-progress';
  }

  saveActiveWorkout();
  renderWorkoutScreen();
}

let replacingExerciseIndex = null;

function replaceCurrentExerciseInWorkout() {
  if (!activeWorkout || activeWorkout.exercises.length === 0) return;
  replacingExerciseIndex = activeWorkout.currentExerciseIndex;
  openAddExerciseToWorkout();
}

function addExerciseToWorkoutOrReplace(exerciseId) {
  if (!activeWorkout) return;
  const exercise = allExercises.find(ex => ex.id === exerciseId);
  if (!exercise) return;

  const newExercise = {
    exerciseId: exercise.id,
    exerciseName: getExerciseName(exercise),
    targetSets: 3,
    targetReps: '10',
    targetRest: 90,
    completedSets: [],
    status: 'not-started',
    notes: ''
  };

  if (replacingExerciseIndex !== null && replacingExerciseIndex < activeWorkout.exercises.length) {
    // Replace
    newExercise.status = activeWorkout.exercises[replacingExerciseIndex].status;
    activeWorkout.exercises[replacingExerciseIndex] = newExercise;
    replacingExerciseIndex = null;
  } else {
    // Add
    activeWorkout.exercises.push(newExercise);
    if (activeWorkout.exercises.length === 1) {
      activeWorkout.currentExerciseIndex = 0;
      activeWorkout.exercises[0].status = 'in-progress';
    }
  }

  saveActiveWorkout();
  closeWorkoutExercisePicker();
  renderWorkoutScreen();

  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('success', `${getExerciseName(exercise)} hinzugefügt`);
  }
}

console.log('✅ Workout engine loaded');

// Global exports
window.checkActiveWorkout = checkActiveWorkout;
window.ensureActiveWorkoutBanner = ensureActiveWorkoutBanner;
window.openExercisesSheet = openExercisesSheet;
window.closeExercisesSheet = closeExercisesSheet;
window.selectExerciseFromSheet = selectExerciseFromSheet;
window.toggleCompletedSets = toggleCompletedSets;
window.confirmEndWorkout = confirmEndWorkout;
window.closeWorkoutEndConfirmModal = closeWorkoutEndConfirmModal;
window.toggleExerciseAccordion = toggleExerciseAccordion;
window.switchToExercise = switchToExercise;
window.showWorkoutMenu = showWorkoutMenu;
window.closeWorkoutMenu = closeWorkoutMenu;
window.addEmptySet = addEmptySet;
window.confirmDiscardWorkout = confirmDiscardWorkout;
// Timer exports
window.startRestTimer = startRestTimer;
window.pauseRestTimer = pauseRestTimer;
window.resumeRestTimer = resumeRestTimer;
window.cancelRestTimer = cancelRestTimer;
window.adjustRestTimer = adjustRestTimer;
window.toggleTimerPause = toggleTimerPause;
window.openTimerModal = openTimerModal;
window.closeTimerModal = closeTimerModal;
window.adjustActiveSetValue = adjustActiveSetValue;
window.adjustWeightByCurrentStep = adjustWeightByCurrentStep;
window.handleWeightValueTap = handleWeightValueTap;
window.duplicateLastSetST = duplicateLastSetST;
window.selectCardioRPE = selectCardioRPE;
window.adjustCardioField = adjustCardioField;
window.updateCardioPace = updateCardioPace;
window.logCardioSetFromInput = logCardioSetFromInput;
window.logRecoverySetFromInput = logRecoverySetFromInput;
