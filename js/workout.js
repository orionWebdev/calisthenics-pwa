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

  return {
    exerciseId: item.exerciseId,
    exerciseName: exercise ? exercise.name : t('exercise.title'),
    targetSets: target.sets || 3,
    targetMode,
    targetHoldSec: hasHold ? holdSec : undefined,
    targetReps,
    targetRest: item.restSec || 90,
    completedSets: [],
    status: 'not-started',
    notes: ''
  };
}

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
      showEdgeFeedback('error', 'Fehler beim Neustarten des Workouts');
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
      <span>Aktives Workout: ${activeWorkout.planName}</span>
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
      userId: WORKOUT_USER_ID,
      type: 'strength',
      date: firebase.firestore.Timestamp.fromDate(workoutDate),
      planId: activeWorkout.planId,
      planName: activeWorkout.planName,
      exercises: activeWorkout.exercises
        .filter(ex => ex.completedSets && ex.completedSets.length > 0)
        .map(ex => ({
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

    // Vorherige Session + letzte 5 Sessions fuer Sparklines
    const prevSession = getPreviousSessionForPlan(planId, savedSessionId);
    const planSessions = typeof getSessionsForPlan === 'function'
      ? getSessionsForPlan(planId, 5, savedSessionId) : [];

    // Post-Workout Summary zeigen statt direkt zu Progress
    showPostWorkoutSummary(sessionData, prevSession, durationMinutes, planSessions);

    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', 'Workout gespeichert!');
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
      showEdgeFeedback('error', 'Fehler beim Speichern des Workouts: ' + error.message);
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
  const userId = typeof WORKOUT_USER_ID !== 'undefined' ? WORKOUT_USER_ID : null;
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
 * Zeichnet Mini-Sparkline in ein Canvas.
 */
function drawMiniSparkline(canvasId, values, trendColor) {
  const canvas = document.getElementById(canvasId);
  if (!canvas || values.length < 2) return;
  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);
  const w = rect.width, h = rect.height, pad = 2;
  const max = Math.max(...values), min = Math.min(...values);
  const range = max - min || 1;
  ctx.beginPath();
  ctx.strokeStyle = trendColor;
  ctx.lineWidth = 1.5;
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';
  values.forEach((v, i) => {
    const x = pad + (i / (values.length - 1)) * (w - 2 * pad);
    const y = h - pad - ((v - min) / range) * (h - 2 * pad);
    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
  });
  ctx.stroke();
}
window.drawMiniSparkline = drawMiniSparkline;

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
    items.push({ icon: 'schedule', label: 'Zeit', current: `${durationMinutes} Min`, delta: durDelta, positive: durationMinutes >= prevDuration });
    const setsDelta = formatDelta(currentSets, prevSets, 'Sets');
    items.push({ icon: 'repeat', label: 'Sets', current: String(currentSets), delta: setsDelta, positive: currentSets >= prevSets });
    if (currentVol > 0 || prevVol > 0) {
      const volDelta = formatDelta(currentVol, prevVol, '%');
      items.push({ icon: 'fitness_center', label: 'Volumen', current: currentVol > 0 ? `${currentVol} kg` : '\u2014', delta: volDelta, positive: currentVol >= prevVol });
    }
    comparisonHTML = `
      <div class="pws-section-title">Vergleich zum letzten Mal</div>
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
    const exTitle = tr('progress.v4.postWorkout.exercisesTitle') || 'Uebungen im Detail';
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
      <h2 class="pws-title">Workout abgeschlossen!</h2>
      <p class="pws-subtitle">${savedSession.planName || 'Training'}</p>
    </div>

    <div class="pws-stats-row">
      <div class="pws-quick-stat">
        <div class="pws-quick-stat-value">${durationMinutes}</div>
        <div class="pws-quick-stat-label">Minuten</div>
      </div>
      <div class="pws-quick-stat">
        <div class="pws-quick-stat-value">${currentSets}</div>
        <div class="pws-quick-stat-label">Sets</div>
      </div>
      ${(savedSession.exercises || []).length > 0 ? `
      <div class="pws-quick-stat">
        <div class="pws-quick-stat-value">${savedSession.exercises.length}</div>
        <div class="pws-quick-stat-label">Uebungen</div>
      </div>
      ` : ''}
    </div>

    ${comparisonHTML}
    ${exercisesHTML}

    <button type="button" class="pws-dismiss-btn" onclick="dismissPostWorkoutSummary()">
      <span class="material-symbols-rounded">bar_chart</span>
      <span>Zum Fortschritt</span>
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
          <span>Workout erfassen</span>
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
      <p style="color:var(--text-secondary);margin-bottom:1rem;">Füge Übungen hinzu, um dein Workout zu starten</p>
      <button onclick="openAddExerciseToWorkout()" class="btn-primary" style="margin:0 auto;">
        <span class="material-symbols-rounded">add</span>
        Übung hinzufügen
      </button>
    </div>`;

  container.innerHTML = `
    <div class="st-screen">
      ${renderSTHeader(progress)}
      ${hasExercises ? renderSTSwitcher() : ''}
      ${hasExercises ? renderSTDetail(currentExercise) : emptyWorkoutContent}
      ${hasExercises ? renderSTTargetAndLastPerf(currentExercise) : ''}
      ${hasExercises ? renderSTSetList(currentExercise) : ''}
      ${hasExercises ? renderWorkoutBottomActions() : ''}
    </div>
  `;

  // Scroll active Pill in Switcher in Sichtbereich
  const activePill = container.querySelector('.st-pill--active');
  if (activePill) {
    setTimeout(() => {
      activePill.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
    }, 50);
  }

  // Scroll to top on mount
  window.scrollTo(0, 0);

  // Re-render timer widget if timer is active (survives re-renders)
  if (isRestTimerActive()) {
    renderTimerWidget();
  }

  // Start elapsed workout timer
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
        <h2 class="st-header-title">${activeWorkout.planName || 'Freies Workout'}</h2>
        <div class="st-header-sub">
          <span class="material-symbols-rounded" style="font-size:14px;">timer</span>
          <span id="workout-elapsed-timer">${getWorkoutElapsedStr()}</span>
          <span class="st-header-dot">&middot;</span>
          <span>${progress.completed} / ${progress.total} Übungen</span>
        </div>
      </div>
      <button type="button" class="st-header-menu" onclick="showWorkoutMenu()" aria-label="Menue">
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
 * Exercise Detail Section
 */
function renderSTDetail(exercise) {
  if (!exercise) return '';

  const isBodyweight = isBodyweightExercise();
  const typeLabel = isBodyweight ? t('workout.screen.bodyweight') : t('workout.screen.weighted');

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

  // Aktueller Satz = nächster zu loggender Satz = Anzahl bereits gelогter Sätze
  const currentSetIndex = exercise.completedSets.length;

  // Hole Vergleich zu demselben Satz aus vorheriger Session
  const lastSetPerformance = activeWorkout?.planId
    ? getLastPlanPerformance(activeWorkout.planId, exercise.exerciseId, currentSetIndex)
    : null;
  const lastPerfHint = formatLastPerformanceHint(lastSetPerformance);

  return `
    <div class="st-target-section">
      <div class="st-target-info">
        <span class="material-symbols-rounded">target</span>
        <span>${targetLine}</span>
      </div>
      ${lastPerfHint ? `
      <div class="st-last-perf-info">
        <span class="material-symbols-rounded">history</span>
        <span>Satz ${currentSetIndex + 1}: ${lastPerfHint}</span>
      </div>
      ` : ''}
    </div>
  `;
}

/**
 * Set List - Calm vertical set rows
 */
function renderSTSetList(exercise) {
  if (!exercise) return '';

  const isBodyweight = isBodyweightExercise();
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
            <span class="material-symbols-rounded">check</span>
          </button>
        </div>
      `;
    } else {
      // Reps mode: show reps + optional weight
      const weightDisplay = !isBodyweight && set.weight != null && set.weight > 0
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
            ${!isBodyweight ? `
              <button type="button" class="st-set-val" onclick="openNumberPickerForSet(${activeWorkout.currentExerciseIndex}, ${setIndex}, 'weight')">
                <span class="st-set-val-num">${weightDisplay || '—'}</span>
                <span class="st-set-val-unit">${t('workout.setLogger.weightUnit')}</span>
              </button>
            ` : ''}
          </div>
          <button type="button" class="st-set-check st-set-check--done" onclick="deleteSet(${activeWorkout.currentExerciseIndex}, ${setIndex})" aria-label="${t('workout.setLogger.deleteSet')}">
            <span class="material-symbols-rounded">check</span>
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
    // Reps mode: reps + optional weight
    const activeWeightDisplay = !isBodyweight
      ? (defaults.weight % 1 !== 0 ? defaults.weight.toFixed(1).replace('.', ',') : defaults.weight)
      : null;

    rows += `
      <div class="st-set-row st-set-row--active" data-set-index="active">
        <div class="st-set-num st-set-num--active">${activeSetNum}</div>
        <div class="st-set-values">
          <button type="button" class="st-set-val st-set-val--editable" onclick="openNumberPickerForNewSet('reps')" id="active-reps-btn" data-value="${activeSetValues.reps}">
            <span class="st-set-val-num" id="active-reps-value">${activeSetValues.reps}</span>
            <span class="st-set-val-unit">${valueUnit}</span>
          </button>
          ${!isBodyweight ? `
            <button type="button" class="st-set-val st-set-val--editable" onclick="openNumberPickerForNewSet('weight')" id="active-weight-btn" data-value="${activeSetValues.weight}">
              <span class="st-set-val-num" id="active-weight-value">${activeWeightDisplay || '0'}</span>
              <span class="st-set-val-unit">${t('workout.setLogger.weightUnit')}</span>
            </button>
          ` : ''}
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
          ${!holdMode && !isBodyweight ? `
            <div class="st-set-val st-set-val--placeholder">
              <span class="st-set-val-num">—</span>
              <span class="st-set-val-unit">${t('workout.setLogger.weightUnit')}</span>
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
        <span>${t('workout.exercise.progress', { completed: progress.completed, total: progress.total }) || `${progress.completed} / ${progress.total} Uebungen`}</span>
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
                     ${set.weight ? `<span class="accordion-set-value">${set.weight} ${t('workout.setLogger.weightUnit')}</span>` : ''}`
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
  // Determine if bodyweight or weighted exercise
  const isBodyweight = isBodyweightExercise();

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
  const userId = typeof WORKOUT_USER_ID !== 'undefined' ? WORKOUT_USER_ID : null;
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
      parts.push(`${lastSet.weight} ${t ? t('workout.setLogger.weightUnit') || 'kg' : 'kg'}`);
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
                <span class="material-symbols-rounded">check</span>
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
                  <span class="set-row-unit">${t('workout.setLogger.weightUnit')}</span>
                </button>
              ` : ''}
            </div>
            <button
              type="button"
              class="set-row-check set-row-check--completed"
              onclick="deleteSet(${exerciseIndex}, ${setIndex})"
              aria-label="${t('workout.setLogger.deleteSet')}"
            >
              <span class="material-symbols-rounded">check</span>
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
            onclick="openNumberPickerForNewSet('weight')"
            id="active-weight-btn"
            data-value="${activeSetValues.weight}"
            aria-label="${t('workout.setLogger.weight')}: ${weightDisplay}"
          >
            <span class="set-row-value" id="active-weight-value">${weightDisplay}</span>
            <span class="set-row-unit">${t('workout.setLogger.weightUnit')}</span>
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

  const isBodyweight = isBodyweightExercise();
  const weight = isBodyweight ? null : (activeSetValues.weight || null);
  logSet(reps, weight);
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
          <label class="input-stepper-label">${t('workout.setLogger.weight')} (${t('workout.setLogger.weightUnit')})</label>
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
                  <span class="data-label">${t('workout.setLogger.weightUnit')}</span>
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
          <span>${t('workout.exercise.next') || 'Naechste Uebung'}</span>
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
                    <span class="data-label">${t('workout.setLogger.weightUnit')}</span>
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

  // Auto-advance to next exercise after short delay so user sees completion
  if (exerciseJustCompleted) {
    const nextIndex = activeWorkout.exercises.findIndex(
      (ex, i) => i > activeWorkout.currentExerciseIndex && ex.status !== 'completed'
    );
    if (nextIndex !== -1) {
      setTimeout(() => {
        goToExercise(nextIndex);
        if (typeof showEdgeFeedback === 'function') {
          showEdgeFeedback('success', t('workout.screen.exerciseComplete') || 'Übung abgeschlossen!');
        }
      }, 800);
    } else if (activeWorkout.exercises.every(ex => ex.status === 'completed')) {
      // All exercises completed - trigger finish flow
      setTimeout(() => {
        confirmEndWorkout();
      }, 800);
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
        <h3 class="exercises-sheet-title">Übung hinzufügen</h3>
        <button type="button" onclick="closeWorkoutExercisePicker()" class="exercises-sheet-close" aria-label="Schließen">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
      <div class="exercises-sheet-content" style="padding:0.5rem 1rem;">
        <input type="text" id="workout-exercise-search" placeholder="Übung suchen..."
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
    return '<p style="text-align:center;color:var(--text-tertiary);padding:1rem;">Keine Übungen gefunden</p>';
  }

  return filtered.map(ex => `
    <button type="button" class="exercises-sheet-item" onclick="addExerciseToWorkout('${ex.id}')">
      <div class="exercises-sheet-item-number">
        <span class="material-symbols-rounded" style="font-size:18px;">add</span>
      </div>
      <div class="exercises-sheet-item-info">
        <div class="exercises-sheet-item-name">${ex.name}</div>
        <div class="exercises-sheet-item-target" style="font-size:0.75rem;color:var(--text-tertiary);">
          ${(ex.muscleGroups || []).map(m => typeof muscleNames !== 'undefined' ? (muscleNames[m] || m) : m).join(', ')}
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
    exerciseName: exercise.name,
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
    showEdgeFeedback('success', `${exercise.name} hinzugefügt`);
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
