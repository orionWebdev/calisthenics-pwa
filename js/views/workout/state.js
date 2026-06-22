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

// Runtime set-type overrides within a session (exerciseId -> 'hold' | 'reps').
// Lets the user switch an exercise between Wdh and Halten on the fly via the
// number-picker tab strip, regardless of the exercise's configured target mode.
let activeSetModeOverrides = {};

function getActiveSetMode(exercise) {
  if (!exercise) return 'reps';
  const id = exercise.exerciseId || exercise.id;
  if (id && activeSetModeOverrides[id]) return activeSetModeOverrides[id];
  return isHoldTarget(exercise) ? 'hold' : 'reps';
}

function setActiveSetMode(exercise, mode) {
  if (!exercise) return;
  const id = exercise.exerciseId || exercise.id;
  if (!id || (mode !== 'hold' && mode !== 'reps')) return;
  activeSetModeOverrides[id] = mode;
}

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
  const sets = getTargetSetCount(exercise);
  const reps = exercise?.targetReps ?? '-';
  return includeLabel
    ? `${t('workout.setLogger.target')}: ${sets} × ${reps}`
    : `${sets} × ${reps}`;
}

// Normalize targetSets to a positive integer. Real plan data may carry it as an
// array of set definitions (or a corrupted string); always derive a clean count.
function getTargetSetCount(exercise) {
  const ts = exercise && exercise.targetSets;
  if (Array.isArray(ts)) return ts.length || 3;
  const n = parseInt(ts, 10);
  return (Number.isFinite(n) && n > 0) ? n : 3;
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
  const sets = getTargetSetCount(exercise);
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
    targetSets: isCardioOrRecovery ? 1 : (Array.isArray(target.sets) ? (target.sets.length || 3) : (parseInt(target.sets, 10) || 3)),
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

