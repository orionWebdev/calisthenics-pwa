// ========================================
// MUSCLE GROUP PNG ICONS
// ========================================
// External PNG icons from assets/icons/dark/
// Falls back to chest.png for muscle groups without a dedicated icon

const MUSCLE_ICON_PATHS = {
  chest:     'assets/icons/dark/chest.png',
  back:      'assets/icons/dark/back.png',
  shoulders: 'assets/icons/dark/shoulder.png',
  biceps:    'assets/icons/dark/biceps.png',
  triceps:   'assets/icons/dark/triceps.png',
  core:      'assets/icons/dark/core.png',
  legs:      'assets/icons/dark/legs.png',
  calf:      'assets/icons/dark/calf.png',
  arms:      'assets/icons/dark/biceps.png',
  'full-body': 'assets/icons/dark/body.png',
};

const MUSCLE_ICON_FALLBACK = 'assets/icons/dark/body.png';

// ========================================
// HELPER FUNCTIONS
// ========================================

/**
 * Returns the icon path for a given muscle group key.
 * Falls back to chest.png if no dedicated icon exists.
 * @param {string} muscleKey
 * @returns {string}
 */
function getMuscleIconPath(muscleKey) {
  return MUSCLE_ICON_PATHS[muscleKey] || MUSCLE_ICON_FALLBACK;
}

/**
 * Returns an <img> tag for the given muscle group key.
 * @param {string} muscleKey - One of: chest, back, shoulders, biceps, triceps, core, legs, calf, arms, full-body, cardio, mobility
 * @param {string} sizeClass - Optional size class: muscle-icon--sm, muscle-icon--md, muscle-icon--lg, muscle-icon--xl
 */
function getMuscleIcon(muscleKey, sizeClass = '') {
  const src = getMuscleIconPath(muscleKey);
  return `<span class="muscle-icon ${sizeClass}"><img src="${src}" alt="${muscleKey}"></span>`;
}

/**
 * Returns the muscle icon for the first (primary) muscle group of an exercise.
 * Falls back to full-body if no muscle groups are set.
 * @param {string[]} muscleGroups - Array of muscle group keys
 * @param {string} sizeClass - Optional size class
 */
function getPrimaryMuscleIcon(muscleGroups, sizeClass = '') {
  if (!muscleGroups || muscleGroups.length === 0) return getMuscleIcon('full-body', sizeClass);

  // Map legacy 'arms' to 'biceps'
  const primary = muscleGroups[0] === 'arms' ? 'biceps' : muscleGroups[0];
  return getMuscleIcon(primary, sizeClass);
}

/**
 * Returns all muscle icons for given muscle groups as a combined HTML string.
 * @param {string[]} muscleGroups - Array of muscle group keys
 * @param {string} sizeClass - Optional size class
 */
function getMuscleIconsRow(muscleGroups, sizeClass = 'muscle-icon--sm') {
  if (!muscleGroups || muscleGroups.length === 0) return getMuscleIcon('full-body', sizeClass);
  return muscleGroups
    .map(m => getMuscleIcon(m === 'arms' ? 'biceps' : m, sizeClass))
    .join('');
}
