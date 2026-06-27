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
    chest: t('exercise.muscles.chest') || 'Chest',
    back: t('exercise.muscles.back') || 'Back',
    shoulders: t('exercise.muscles.shoulders') || 'Shoulders',
    biceps: t('exercise.muscles.biceps') || 'Biceps',
    triceps: t('exercise.muscles.triceps') || 'Triceps',
    core: t('exercise.muscles.core') || 'Core',
    legs: t('exercise.muscles.legs') || 'Legs',
    'full-body': t('exercise.muscles.fullBody') || 'Full body',
    // Legacy keys kept for backward compat display
    arms: t('exercise.muscles.arms') || 'Arms',
    calf: t('exercise.muscles.calf') || 'Calves',
    cardio: t('exercise.muscles.cardio') || 'Cardio',
    mobility: t('exercise.muscles.mobility') || 'Mobility'
  }
};

// ---- Primary-muscle filtering -------------------------------------------
// Exercise data has no explicit primary/secondary split — by convention the
// FIRST entry of `muscleGroups` is the primary mover. These helpers also
// reconcile the differing muscle keys between the curated JSON
// (quads/hamstrings/glutes/calves/full_body) and the filter chips
// (legs/calf/full-body).
const MUSCLE_GROUP_ALIASES = {
  quads: 'legs', quadriceps: 'legs', hamstrings: 'legs', glutes: 'legs', legs: 'legs',
  calves: 'calf', calf: 'calf',
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

// Equipment name mapping → i18n keys (resolved at access time so the labels
// follow the active locale). Accessed as equipmentNames[key] across views.
const EQUIPMENT_LABEL_KEYS = {
  'bodyweight': 'recent.equipment.bodyweight',
  'pull-up-bar': 'recent.equipment.pullUpBar',
  'barbell': 'recent.equipment.barbell',
  'dumbbell': 'recent.equipment.dumbbell',
  'resistance-bands': 'recent.equipment.resistanceBands',
  'gym-machine': 'recent.equipment.machine',
  'parallettes': 'recent.equipment.parallettes',
  'rings': 'recent.equipment.rings',
  'bench': 'recent.equipment.bench',
  // Legacy keys kept for backward compat display
  'none': 'recent.equipment.none',
  'dip-bars': 'recent.equipment.dipBars',
  'box': 'recent.equipment.box',
  'wall': 'recent.equipment.wall',
  'mat': 'recent.equipment.mat',
  'weights': 'recent.equipment.weights'
};
const equipmentNames = new Proxy({}, {
  get(_t, prop) {
    const key = EQUIPMENT_LABEL_KEYS[prop];
    if (!key) return undefined;
    const label = (typeof t === 'function') ? t(key) : key;
    return (label && label !== key) ? label : undefined;
  },
  has(_t, prop) { return prop in EQUIPMENT_LABEL_KEYS; },
  ownKeys() { return Object.keys(EQUIPMENT_LABEL_KEYS); },
  getOwnPropertyDescriptor() { return { enumerable: true, configurable: true }; }
});

// Equipment Icons Mapping
const equipmentIcons = {
  'bodyweight': 'accessibility_new',
  'pull-up-bar': 'fitness_center',
  'barbell': 'fitness_center',
  'dumbbell': 'fitness_center',
  'resistance-bands': 'cable',
  'gym-machine': 'precision_manufacturing',
  'parallettes': 'straighten',
  'rings': 'sports_gymnastics',
  'bench': 'airline_seat_flat',
  // Legacy
  'none': 'accessibility',
  'dip-bars': 'sports_gymnastics',
  'box': 'square',
  'wall': 'wall',
  'mat': 'airline_seat_flat',
  'weights': 'fitness_center'
};

