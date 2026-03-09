// ========================================
// MUSCLE GROUP SVG ICONS
// ========================================
// Inline stroke-style SVGs for muscle group visualization
// All icons: viewBox 0 0 24 24, stroke-only, currentColor

const MUSCLE_ICONS = {
  chest: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 6C12 6 8 4 4 6C2 7 1.5 10 2 12C2.5 14 4 16 6 17C8 18 10 18 12 16"/>
    <path d="M12 6C12 6 16 4 20 6C22 7 22.5 10 22 12C21.5 14 20 16 18 17C16 18 14 18 12 16"/>
    <line x1="12" y1="6" x2="12" y2="16"/>
  </svg>`,

  back: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 3C12 3 12 5 12 8"/>
    <path d="M12 8C9 8 6 9 5 12C4 15 5 18 7 20"/>
    <path d="M12 8C15 8 18 9 19 12C20 15 19 18 17 20"/>
    <path d="M8 12L12 11L16 12"/>
    <path d="M9 16L12 15L15 16"/>
  </svg>`,

  shoulders: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 8C12 8 12 12 12 16"/>
    <path d="M12 8C8 8 4 9.5 3 13"/>
    <path d="M12 8C16 8 20 9.5 21 13"/>
    <circle cx="5" cy="11" r="2"/>
    <circle cx="19" cy="11" r="2"/>
  </svg>`,

  biceps: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <path d="M16 5C16 5 14 4 13 5C12 6 11 9 11 11C11 13 12 14 13 14"/>
    <path d="M13 14C13 14 12 16 12 18C12 20 13 21 14 21"/>
    <path d="M16 5C17 5 18 6 18 8C18 10 17 12 15 13C14 13.5 13 14 13 14"/>
    <path d="M14.5 8C15.5 8.5 16 9.5 15.5 11"/>
  </svg>`,

  triceps: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <path d="M10 5C10 5 8 4 7 5C6 6 6 8 7 10"/>
    <path d="M10 5C11 5 12 6 12 8C12 10 11 12 10 13"/>
    <path d="M7 10C7 10 8 12 10 13"/>
    <path d="M10 13C10 13 10 16 10 18C10 20 9 21 8 21"/>
    <path d="M8.5 8C8 9 8 10 8.5 11"/>
  </svg>`,

  core: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <rect x="7" y="4" width="10" height="16" rx="3"/>
    <line x1="7" y1="8" x2="17" y2="8"/>
    <line x1="7" y1="12" x2="17" y2="12"/>
    <line x1="7" y1="16" x2="17" y2="16"/>
    <line x1="12" y1="4" x2="12" y2="20"/>
  </svg>`,

  legs: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <path d="M9 3C9 3 8 7 8 10C8 13 9 15 9 18C9 20 8 22 7 22"/>
    <path d="M15 3C15 3 16 7 16 10C16 13 15 15 15 18C15 20 16 22 17 22"/>
    <path d="M8 7C8.5 8 9.5 8 10 7"/>
    <path d="M16 7C15.5 8 14.5 8 14 7"/>
    <path d="M8 14C8.5 15 9.5 15 10 14"/>
    <path d="M16 14C15.5 15 14.5 15 14 14"/>
  </svg>`,

  'full-body': `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <circle cx="12" cy="4" r="2"/>
    <path d="M12 6V12"/>
    <path d="M12 12L8 22"/>
    <path d="M12 12L16 22"/>
    <path d="M6 10L12 8L18 10"/>
  </svg>`,

  cardio: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 20C12 20 4 14 4 9C4 6.5 5.5 4 8 4C9.5 4 11 5 12 6.5C13 5 14.5 4 16 4C18.5 4 20 6.5 20 9C20 14 12 20 12 20Z"/>
    <path d="M4 12H8L10 9L12 15L14 11L16 12H20"/>
  </svg>`,

  mobility: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
    <circle cx="12" cy="5" r="2"/>
    <path d="M12 7V11"/>
    <path d="M12 11L8 15"/>
    <path d="M12 11L18 13"/>
    <path d="M8 15L6 21"/>
    <path d="M8 15L12 19"/>
    <path d="M12 19L14 22"/>
  </svg>`
};

// ========================================
// HELPER FUNCTIONS
// ========================================

/**
 * Returns an SVG icon for the given muscle group key.
 * @param {string} muscleKey - One of: chest, back, shoulders, biceps, triceps, core, legs, full-body, cardio, mobility
 * @param {string} sizeClass - Optional size class: muscle-icon--sm, muscle-icon--md, muscle-icon--lg, muscle-icon--xl
 */
function getMuscleIcon(muscleKey, sizeClass = '') {
  const svg = MUSCLE_ICONS[muscleKey] || MUSCLE_ICONS['full-body'];
  return `<span class="muscle-icon ${sizeClass}">${svg}</span>`;
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
