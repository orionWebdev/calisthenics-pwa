// ========================================
// EXERCISES MANAGEMENT
// ========================================

let allExercises = [];
let filteredExercises = [];
let editingExerciseId = null;
let exercisesExpanded = false;
let exerciseMuscleFilter = '';
let exerciseDifficultyFilter = '';
let exerciseEquipmentFilter = '';

// V3 State
let exerciseType = 'strength';
let exerciseVariants = [];
let exerciseStep2Expanded = false;
let exerciseCreateCallback = null;

// Muscle Group Namen Mapping (i18n-aware)
function getMuscleNames() {
  return {
    chest: t('exercise.muscles.chest'),
    back: t('exercise.muscles.back'),
    shoulders: t('exercise.muscles.shoulders'),
    biceps: t('exercise.muscles.biceps'),
    triceps: t('exercise.muscles.triceps'),
    core: t('exercise.muscles.core'),
    quads: t('exercise.muscles.quads'),
    hamstrings: t('exercise.muscles.hamstrings'),
    glutes: t('exercise.muscles.glutes'),
    calves: t('exercise.muscles.calves'),
    // Legacy keys kept for backward compat display
    legs: t('exercise.muscles.legs'),
    'full-body': t('exercise.muscles.fullBody'),
    arms: t('exercise.muscles.arms'),
    calf: t('exercise.muscles.calf'),
    cardio: t('exercise.muscles.cardio'),
    mobility: t('exercise.muscles.mobility')
  }
};

// ---- Primary-muscle filtering -------------------------------------------
// Exercises have an explicit primaryMuscles array; for legacy/user data the
// FIRST entry of `muscleGroups` is the primary mover. The leg muscles
// (quads/hamstrings/glutes/calves) are now first-class canonical groups.
// Legacy generic keys (legs/calf/arms/full_body) are normalised for display.
const MUSCLE_GROUP_ALIASES = {
  quads: 'quads', quadriceps: 'quads',
  hamstrings: 'hamstrings',
  glutes: 'glutes',
  calves: 'calves', calf: 'calves',
  legs: 'legs', // legacy generic — kept as-is for old data
  full_body: 'full-body', 'full-body': 'full-body', fullbody: 'full-body',
  chest: 'chest', back: 'back', shoulders: 'shoulders',
  biceps: 'biceps', triceps: 'triceps', arms: 'arms',
  core: 'core', cardio: 'cardio', mobility: 'mobility'
};

function canonicalMuscle(key) {
  if (!key) return '';
  const k = String(key).toLowerCase();
  return MUSCLE_GROUP_ALIASES[k] || k;
}

function getPrimaryMuscle(exercise) {
  const prim = Array.isArray(exercise?.primaryMuscles) ? exercise.primaryMuscles : [];
  if (prim.length) return canonicalMuscle(prim[0]);
  const mg = Array.isArray(exercise?.muscleGroups) ? exercise.muscleGroups : [];
  return mg.length ? canonicalMuscle(mg[0]) : '';
}

// True when the exercise's PRIMARY muscle matches the given filter key.
function exercisePrimaryMatchesMuscle(exercise, filterKey) {
  if (!filterKey || filterKey === 'all') return true;
  const primary = getPrimaryMuscle(exercise);
  const target = canonicalMuscle(filterKey);
  if (primary === target) return true;
  // The generic "arms" filter is satisfied by a biceps/triceps primary.
  if (target === 'arms' && (primary === 'biceps' || primary === 'triceps')) return true;
  return false;
}

// Equipment Namen Mapping — resolved via t() at call time so it follows the
// active locale (a frozen const would stay in the default language).
const EQUIPMENT_KEYS = [
  'bodyweight', 'pull-up-bar', 'dip-bars', 'parallettes', 'rings',
  'box', 'bench', 'wall', 'mat',
  'barbell', 'dumbbell', 'kettlebell', 'machine', 'resistance-bands',
  // Legacy keys kept for backward compat display
  'none', 'gym-machine', 'weights'
];

function getEquipmentNames() {
  const map = {};
  EQUIPMENT_KEYS.forEach(k => { map[k] = t('exercise.equipmentNames.' + k); });
  return map;
}

function getEquipmentName(key) {
  if (!key) return key;
  const label = t('exercise.equipmentNames.' + key);
  // t() returns the key path on a miss — fall back to the raw key in that case.
  return label === 'exercise.equipmentNames.' + key ? key : label;
}

// Equipment Icons Mapping
const equipmentIcons = {
  'bodyweight': 'accessibility_new',
  'pull-up-bar': 'fitness_center',
  'dip-bars': 'sports_gymnastics',
  'parallettes': 'straighten',
  'rings': 'sports_gymnastics',
  'box': 'square',
  'bench': 'airline_seat_flat',
  'wall': 'wall',
  'mat': 'airline_seat_flat',
  'barbell': 'fitness_center',
  'dumbbell': 'fitness_center',
  'kettlebell': 'fitness_center',
  'machine': 'precision_manufacturing',
  'resistance-bands': 'cable',
  // Legacy
  'none': 'accessibility',
  'gym-machine': 'precision_manufacturing',
  'weights': 'fitness_center'
};

