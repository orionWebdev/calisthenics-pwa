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
  quads:      'assets/icons/dark/legs.png',
  hamstrings: 'assets/icons/dark/legs.png',
  glutes:     'assets/icons/dark/legs.png',
  calves:     'assets/icons/dark/calf.png',
  // Legacy
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

// Normalize a muscle key to its dust palette class suffix (handles aliases).
function muscleDustKey(muscleKey) {
  if (!muscleKey) return 'full-body';
  return muscleKey === 'arms' ? 'biceps' : muscleKey;
}

/**
 * Returns a "gradient dust" orb for a single muscle group (replaces the old PNG).
 * Keeps the legacy `muscle-icon` class for layout compatibility.
 * @param {string} muscleKey - chest, back, shoulders, biceps, triceps, core, legs, calf, arms, full-body, cardio, mobility
 * @param {string} sizeClass - Optional size class: muscle-icon--sm/md/lg/xl/filter/xs
 */
function getMuscleIcon(muscleKey, sizeClass = '') {
  const key = muscleDustKey(muscleKey);
  return `<span class="muscle-icon muscle-dust ${sizeClass} m-${key}"></span>`;
}

/**
 * Dust orb for an exercise — blends its primary muscle (+ optional secondary)
 * colour into one foggy blob. Falls back to full-body if none are set.
 * @param {string[]} muscleGroups - Array of muscle group keys
 * @param {string} sizeClass - Optional size class
 */
function getPrimaryMuscleIcon(muscleGroups, sizeClass = '') {
  const groups = Array.isArray(muscleGroups) ? muscleGroups.filter(Boolean) : [];
  if (groups.length === 0) {
    return `<span class="muscle-icon muscle-dust ${sizeClass} m-full-body"></span>`;
  }
  const primary = muscleDustKey(groups[0]);
  const secRaw = groups.find((g, i) => i > 0 && muscleDustKey(g) !== primary);
  const secCls = secRaw ? ` s-${muscleDustKey(secRaw)}` : '';
  return `<span class="muscle-icon muscle-dust ${sizeClass} m-${primary}${secCls}"></span>`;
}

/**
 * Row of small dust orbs for given muscle groups.
 * @param {string[]} muscleGroups
 * @param {string} sizeClass
 */
function getMuscleIconsRow(muscleGroups, sizeClass = 'muscle-icon--sm') {
  const groups = Array.isArray(muscleGroups) ? muscleGroups.filter(Boolean) : [];
  if (groups.length === 0) return getMuscleIcon('full-body', sizeClass);
  return groups.map(m => getMuscleIcon(m, sizeClass)).join('');
}
