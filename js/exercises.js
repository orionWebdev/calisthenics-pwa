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
let exerciseNotes = '';
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

// Equipment Namen Mapping
const equipmentNames = {
  'bodyweight': 'Bodyweight',
  'pull-up-bar': 'Klimmzugstange',
  'barbell': 'Langhantel',
  'dumbbell': 'Kurzhantel',
  'resistance-bands': 'Widerstandsbänder',
  'gym-machine': 'Maschine',
  'parallettes': 'Paralettes',
  'rings': 'Ringe',
  'bench': 'Bank',
  // Legacy keys kept for backward compat display
  'none': 'Kein Equipment',
  'dip-bars': 'Dip-Barren',
  'box': 'Box/Bank',
  'wall': 'Wand',
  'mat': 'Matte',
  'weights': 'Gewichte'
};

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

// ========================================
// EXERCISE LOCALE HELPERS
// ========================================

function getExerciseName(exercise) {
  if (!exercise) return '';
  if (currentLocale === 'de' && exercise.name_de) return exercise.name_de;
  return exercise.name || '';
}

function applyExerciseLocale(exercise) {
  const localeData = exercise.i18n?.[currentLocale];
  if (!localeData) return exercise;
  return { ...exercise, ...localeData };
}

// ========================================
// EXERCISE V3 TYPE & PATTERN CONSTANTS
// ========================================

const exerciseTypes = {
  strength: { icon: 'fitness_center' },
  bodyweight: { icon: 'sports_gymnastics' },
  cardio: { icon: 'directions_run' },
  recovery: { icon: 'spa' },
  // Legacy – hidden from UI, still valid in data
  mobility: { icon: 'self_improvement', hidden: true }
};

const exercisePatterns = {
  push: { icon: 'arrow_upward' },
  pull: { icon: 'arrow_downward' },
  legs: { icon: 'directions_walk' },
  core: { icon: 'self_improvement' },
  full: { icon: 'accessibility_new' }
};

// ========================================
// INSTRUCTIONS NORMALIZATION (Legacy Support)
// ========================================

function splitInstructionText(text) {
  if (!text || typeof text !== 'string') return [];
  const trimmed = text.trim();
  if (!trimmed) return [];

  const lineSplit = trimmed
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(Boolean);

  if (lineSplit.length > 1) return lineSplit;

  const bulletSplit = trimmed
    .split(/•|â€¢|-|\u2022/)
    .map(part => part.trim())
    .filter(Boolean);

  if (bulletSplit.length > 1) return bulletSplit;

  return [trimmed];
}

function normalizeInstructionList(value) {
  if (Array.isArray(value)) {
    return value.map(item => String(item || '').trim()).filter(Boolean);
  }
  if (typeof value === 'string') {
    return splitInstructionText(value);
  }
  return [];
}

function normalizeExerciseInstructions(exercise) {
  const normalized = {
    instructionsSteps: [],
    setupNotes: '',
    cues: [],
    commonMistakes: [],
    progressions: []
  };

  const steps = normalizeInstructionList(exercise.instructionsSteps);
  if (steps.length > 0) {
    normalized.instructionsSteps = steps;
  } else if (Array.isArray(exercise.instructions)) {
    normalized.instructionsSteps = normalizeInstructionList(exercise.instructions);
  } else if (exercise.instructions && typeof exercise.instructions === 'object') {
    const legacySteps = normalizeInstructionList(exercise.instructions.execution || exercise.instructions.setup);
    normalized.instructionsSteps = legacySteps;
    normalized.setupNotes = typeof exercise.instructions.setup === 'string' ? exercise.instructions.setup.trim() : '';
    normalized.cues = normalizeInstructionList(exercise.instructions.cues);
    normalized.commonMistakes = normalizeInstructionList(exercise.instructions.mistakes);
    normalized.progressions = normalizeInstructionList(exercise.instructions.progressions);
  }

  if (normalized.instructionsSteps.length === 0) {
    const legacyText = exercise.instructionsText || exercise.description || '';
    normalized.instructionsSteps = normalizeInstructionList(legacyText);
  }

  if (typeof exercise.setupNotes === 'string' && exercise.setupNotes.trim()) {
    normalized.setupNotes = exercise.setupNotes.trim();
  } else if (Array.isArray(exercise.setupSteps) && exercise.setupSteps.length > 0) {
    normalized.setupNotes = normalizeInstructionList(exercise.setupSteps).join('\n');
  }

  if (Array.isArray(exercise.cues) || typeof exercise.cues === 'string') {
    normalized.cues = normalizeInstructionList(exercise.cues);
  }

  if (Array.isArray(exercise.commonMistakes) || typeof exercise.commonMistakes === 'string') {
    normalized.commonMistakes = normalizeInstructionList(exercise.commonMistakes);
  } else if (Array.isArray(exercise.mistakes) || typeof exercise.mistakes === 'string') {
    normalized.commonMistakes = normalizeInstructionList(exercise.mistakes);
  }

  if (Array.isArray(exercise.progressions) || typeof exercise.progressions === 'string') {
    normalized.progressions = normalizeInstructionList(exercise.progressions);
  }

  return normalized;
}

function normalizeExerciseForRuntime(exercise) {
  const normalized = normalizeExerciseInstructions(exercise);
  return {
    ...exercise,
    instructionsSteps: normalized.instructionsSteps,
    setupNotes: normalized.setupNotes,
    cues: normalized.cues,
    commonMistakes: normalized.commonMistakes,
    progressions: normalized.progressions
  };
}

// ========================================
// EXERCISE V3 MAPPERS
// ========================================

/**
 * Maps any exercise document (legacy or new) to v3 runtime shape.
 * Adds defaults for missing v3 fields, maps imageUrl to visual.
 */
function mapExerciseToV3(exercise) {
  const localized = applyExerciseLocale(exercise);
  const normalized = normalizeExerciseInstructions(localized);

  // Type: default 'strength' for legacy; map removed types to bodyweight
  let type = exercise.type && exerciseTypes[exercise.type] ? exercise.type : 'strength';
  if (type === 'mobility') type = 'bodyweight';

  // Pattern: default 'full' for legacy
  const pattern = exercise.pattern && exercisePatterns[exercise.pattern] ? exercise.pattern : 'full';

  // Difficulty: ensure enum string
  const difficulty = convertDifficultyToEnum(exercise.difficulty) || 'intermediate';

  // Instructions: use normalized
  const instructions = normalized.instructionsSteps;

  // Visual: map from legacy imageUrl if needed
  let visual = exercise.visual || null;
  if (!visual && exercise.imageUrl) {
    visual = { kind: 'url', value: exercise.imageUrl };
  }

  // Variants: keep if array, default empty
  const variants = Array.isArray(exercise.variants) ? exercise.variants : [];

  // Notes
  const notes = exercise.notes || '';

  return {
    ...exercise,
    type,
    pattern,
    difficulty,
    instructions,
    instructionsSteps: instructions,
    visual,
    variants,
    notes,
    setupNotes: normalized.setupNotes,
    cues: normalized.cues,
    commonMistakes: normalized.commonMistakes,
    progressions: normalized.progressions,
    muscleGroups: exercise.muscleGroups || [],
    equipment: exercise.equipment || ['none'],
    icon: exercise.icon || 'fitness_center',
    // Bodyweight flag for load calculation
    usesBodyweight: exercise.usesBodyweight ?? (type === 'bodyweight'),
    // Additive fields (Phase 5)
    parentId: exercise.parentId || null,
    source: exercise.source || 'user',
    progressionLinks: exercise.progressionLinks || null
  };
}

/**
 * Maps v3 runtime shape to Firestore document for saving.
 * Writes both new and legacy fields for backward compat.
 */
function mapV3ToExerciseDoc(v3) {
  const doc = {
    name: v3.name,
    type: v3.type || 'strength',
    difficulty: v3.difficulty || 'intermediate',
    instructionsSteps: v3.instructions || [],
    muscleGroups: v3.muscleGroups || [],
    equipment: v3.equipment?.length ? v3.equipment : ['none'],
    icon: v3.icon || 'fitness_center'
  };

  // Optional fields - only write if non-empty
  if (v3.variants?.length) doc.variants = v3.variants;
  if (v3.notes) doc.notes = v3.notes;
  if (v3.setupNotes) doc.setupNotes = v3.setupNotes;
  if (v3.cues?.length) doc.cues = v3.cues;
  if (v3.commonMistakes?.length) doc.commonMistakes = v3.commonMistakes;
  if (v3.progressions?.length) doc.progressions = v3.progressions;

  // Additive fields (Phase 5)
  if (v3.parentId) doc.parentId = v3.parentId;
  if (v3.source) doc.source = v3.source;
  if (v3.progressionLinks) doc.progressionLinks = v3.progressionLinks;

  return doc;
}

// ========================================
// LOAD & DISPLAY EXERCISES
// ========================================

async function loadExercises() {
  try {
    // Load curated (read-only) and user exercises in parallel
    const [curatedRaw, userRaw] = await Promise.all([
      getAllDocs(exercisesCuratedCollection),
      getAllDocs(exercisesCollection)
    ]);

    // Curated first, then user exercises override by ID
    const exerciseMap = new Map();
    for (const ex of curatedRaw) {
      exerciseMap.set(ex.id, mapExerciseToV3(ex));
    }
    for (const ex of userRaw) {
      exerciseMap.set(ex.id, mapExerciseToV3(ex));
    }

    allExercises = Array.from(exerciseMap.values());
    filteredExercises = [...allExercises];
    applyExerciseSearchI18n();
    renderExercises();
    updateExerciseFiltersUI();
  } catch (error) {
    console.error('Error loading exercises:', error);
  }
}

// ========================================
// ALPHABETICAL GROUPING UTILITY
// ========================================

/**
 * Normalizes a character for grouping:
 * - Converts umlauts: Ä->A, Ö->O, Ü->U, ß->S
 * - Uppercase A-Z returns the letter
 * - Everything else (numbers, symbols, emojis) returns '#'
 */
function getExerciseInitial(name) {
  if (!name || typeof name !== 'string') return '#';

  const trimmed = name.trim();
  if (!trimmed) return '#';

  // Get first character and normalize
  let firstChar = trimmed.charAt(0).toUpperCase();

  // Umlaut mapping
  const umlautMap = {
    'Ä': 'A', 'Ö': 'O', 'Ü': 'U',
    'ä': 'A', 'ö': 'O', 'ü': 'U',
    'ß': 'S'
  };

  if (umlautMap[firstChar]) {
    firstChar = umlautMap[firstChar];
  }

  // Check if A-Z
  if (/^[A-Z]$/.test(firstChar)) {
    return firstChar;
  }

  return '#';
}

/**
 * Groups exercises by their initial letter
 * Returns an object with letters as keys and arrays of exercises as values
 * Sorted alphabetically, with '#' section first
 */
function groupExercisesByInitial(exercises) {
  const groups = {};

  // Sort exercises alphabetically first
  const sorted = [...exercises].sort((a, b) => {
    const nameA = (a.name || '').toLowerCase();
    const nameB = (b.name || '').toLowerCase();
    return nameA.localeCompare(nameB, 'de');
  });

  // Group by initial
  sorted.forEach(exercise => {
    const initial = getExerciseInitial(getExerciseName(exercise));
    if (!groups[initial]) {
      groups[initial] = [];
    }
    groups[initial].push(exercise);
  });

  // Get sorted keys: '#' first, then A-Z
  const sortedKeys = Object.keys(groups).sort((a, b) => {
    if (a === '#') return -1;
    if (b === '#') return 1;
    return a.localeCompare(b);
  });

  return { groups, sortedKeys };
}

// ========================================
// RENDER EXERCISES (iOS Contacts Style)
// ========================================

function renderExercises() {
  const grid = document.getElementById('exercises-grid');
  const isSearchActive = !!_exerciseSearchTerm;

  if (filteredExercises.length === 0) {
    grid.innerHTML = `
      <div class="col-span-full empty-state">
        <div class="empty-state-icon">
          <span class="material-symbols-rounded">search_off</span>
        </div>
        <h3 class="empty-state-title">${t('exercise.noResultsTitle')}</h3>
        <p class="empty-state-text">${t('exercise.noResultsHint')}</p>
      </div>
    `;
    return;
  }

  // Bei aktiver Suche: flache, alphabetisch sortierte Liste (keine Buchstaben-Sections)
  if (isSearchActive) {
    const sorted = [...filteredExercises].sort((a, b) =>
      (a.name || '').localeCompare(b.name || '', 'de')
    );
    let html = '<div class="exercises-list-container"><div class="exercise-section-items">';
    sorted.forEach((exercise, index) => {
      html += renderExerciseRow(exercise, index === sorted.length - 1);
    });
    html += '</div></div>';
    grid.innerHTML = html;
    return;
  }

  // Standard: Alphabetische Gruppierung
  const { groups, sortedKeys } = groupExercisesByInitial(filteredExercises);
  let sectionsHTML = '<div class="exercises-list-container">';

  sortedKeys.forEach(letter => {
    const exercises = groups[letter];
    sectionsHTML += `
      <div class="exercise-section" data-section="${letter}">
        <div class="exercise-section-header">
          <span class="exercise-section-letter">${letter}</span>
        </div>
        <div class="exercise-section-items">
    `;
    exercises.forEach((exercise, index) => {
      sectionsHTML += renderExerciseRow(exercise, index === exercises.length - 1);
    });
    sectionsHTML += '</div></div>';
  });

  sectionsHTML += '</div>';
  grid.innerHTML = sectionsHTML;
}

/**
 * Renders a single exercise row (v3: visual + name + meta)
 */
function renderExerciseRow(exercise, isLast = false) {
  // Visual: muscle group icon instead of photo/icon
  const visualHTML = `<div class="exercise-list-visual-placeholder">
      ${getPrimaryMuscleIcon(exercise.muscleGroups, 'muscle-icon--md')}
    </div>`;

  // Meta line: muscle groups (replaces type · pattern)
  const names = getMuscleNames();
  const muscleLabel = (exercise.muscleGroups || [])
    .map(m => names[m]).filter(Boolean).slice(0, 3).join(', ');
  const metaText = muscleLabel || t('exercise.type.' + exercise.type) || '';

  // Difficulty stripe color
  const diffColor = {
    beginner: '#4CAF50',
    intermediate: '#FF9800',
    advanced: '#F44336',
    elite: '#9C27B0'
  }[exercise.difficulty] || 'transparent';

  return `
    <div class="exercise-list-row${isLast ? ' is-last' : ''}" onclick="viewExerciseDetails('${exercise.id}')">
      <div class="exercise-difficulty-stripe" style="background: ${diffColor}"></div>
      ${visualHTML}
      <div class="exercise-list-text">
        <span class="exercise-list-name">${getExerciseName(exercise)}</span>
        <span class="exercise-list-meta">${metaText}</span>
      </div>
      <span class="material-symbols-rounded exercise-list-chevron">chevron_right</span>
    </div>
  `;
}

// Toggle Exercise Card Expansion
function toggleExerciseCard(id) {
  viewExerciseDetails(id);
}

// ========================================
// FILTER & SEARCH (Debounced)
// ========================================

let _exerciseSearchTimer = null;
let _exerciseSearchTerm = '';

/** Called on every keypress – debounces the actual filter */
function onExerciseSearchInput() {
  clearTimeout(_exerciseSearchTimer);
  _exerciseSearchTimer = setTimeout(() => {
    filterExercises();
  }, 180);

  // Sofort Clear-Button togglen (kein Debounce noetig)
  const input = document.getElementById('search-input');
  const clearBtn = document.getElementById('exercise-search-clear');
  if (input && clearBtn) {
    clearBtn.classList.toggle('hidden', !input.value);
  }
}

/** Clears search input and re-filters */
function clearExerciseSearch() {
  const input = document.getElementById('search-input');
  if (input) input.value = '';
  const clearBtn = document.getElementById('exercise-search-clear');
  if (clearBtn) clearBtn.classList.add('hidden');
  filterExercises();
  if (input) input.focus();
}

/** Applies search placeholder via i18n */
function applyExerciseSearchI18n() {
  const input = document.getElementById('search-input');
  if (input) input.placeholder = t('exercise.searchPlaceholder');
}

function filterExercises() {
  const input = document.getElementById('search-input');
  const searchTerm = input ? input.value.trim() : '';
  _exerciseSearchTerm = searchTerm;
  const searchLower = searchTerm.toLocaleLowerCase('de-DE');
  const muscleFilter = exerciseMuscleFilter;
  const difficultyFilter = exerciseDifficultyFilter;
  const equipmentFilter = exerciseEquipmentFilter;

  filteredExercises = allExercises.filter(exercise => {
    // Search filter – Name hat Prioritaet, dann type/difficulty
    let matchesSearch = true;
    if (searchLower) {
      const nameLower = (getExerciseName(exercise)).toLocaleLowerCase('de-DE');
      const nameEnLower = (exercise.name || '').toLocaleLowerCase('de-DE');
      if (nameLower.includes(searchLower) || nameEnLower.includes(searchLower)) {
        matchesSearch = true;
      } else {
        const typeLabel = (t('exercise.type.' + exercise.type) || '').toLocaleLowerCase('de-DE');
        const diffLabel = (t('difficulty.' + exercise.difficulty) || '').toLocaleLowerCase('de-DE');
        matchesSearch = typeLabel.includes(searchLower) ||
                        diffLabel.includes(searchLower);
      }
    }

    // Muscle filter
    const matchesMuscle = !muscleFilter || exercise.muscleGroups.includes(muscleFilter);

    // Difficulty filter
    let matchesDifficulty = true;
    if (difficultyFilter) {
      const exerciseDiff = convertDifficultyToEnum(exercise.difficulty);
      matchesDifficulty = exerciseDiff === difficultyFilter;
    }

    // Equipment filter
    const matchesEquipment = !equipmentFilter || (exercise.equipment || []).includes(equipmentFilter);

    return matchesSearch && matchesMuscle && matchesDifficulty && matchesEquipment;
  });

  exercisesExpanded = false;
  renderExercises();
  updateActiveFilters();
}

function setExerciseMuscleFilter(value) {
  exerciseMuscleFilter = value || '';
  updateExerciseFiltersUI();
  filterExercises();
}

function setExerciseDifficultyFilter(value) {
  exerciseDifficultyFilter = value || '';
  updateExerciseFiltersUI();
  filterExercises();
}

function setExerciseEquipmentFilter(value) {
  exerciseEquipmentFilter = value || '';
  updateExerciseFiltersUI();
  filterExercises();
}

/**
 * Opens muscle group filter as a bottom sheet (single-select)
 */
function openMuscleGroupFilterSheet() {
  const mn = getMuscleNames();
  const filterOptions = [
    { value: '', label: t('exercise.filters.allMuscles'), description: t('exercise.muscleDescriptions.all') },
    { value: 'chest', label: mn.chest, description: t('exercise.muscleDescriptions.chest'), icon: getMuscleIconPath('chest') },
    { value: 'back', label: mn.back, description: t('exercise.muscleDescriptions.back'), icon: getMuscleIconPath('back') },
    { value: 'biceps', label: mn.biceps, description: t('exercise.muscleDescriptions.biceps'), icon: getMuscleIconPath('biceps') },
    { value: 'triceps', label: mn.triceps, description: t('exercise.muscleDescriptions.triceps'), icon: getMuscleIconPath('triceps') },
    { value: 'shoulders', label: mn.shoulders, description: t('exercise.muscleDescriptions.shoulders'), icon: getMuscleIconPath('shoulders') },
    { value: 'core', label: mn.core, description: t('exercise.muscleDescriptions.core'), icon: getMuscleIconPath('core') },
    { value: 'legs', label: mn.legs, description: t('exercise.muscleDescriptions.legs'), icon: getMuscleIconPath('legs') },
    { value: 'full-body', label: mn['full-body'], description: t('exercise.muscleDescriptions.fullBody'), icon: getMuscleIconPath('full-body') }
  ];

  openBottomSheet({
    title: t('exercise.muscleFilter.title'),
    options: filterOptions,
    selectedValues: exerciseMuscleFilter ? [exerciseMuscleFilter] : [''],
    enableSearch: false,
    fieldId: 'exercise-muscle-filter-btn',
    onConfirm: (selectedValues) => {
      // Single-select: use the last selected value
      const selected = selectedValues.length > 0 ? selectedValues[selectedValues.length - 1] : '';
      setExerciseMuscleFilter(selected);
    }
  });
}

/**
 * Opens difficulty filter as a bottom sheet (single-select)
 */
function openDifficultyFilterSheet() {
  const filterOptions = [
    { value: '', label: t('exercise.filters.allDifficulties'), description: '' },
    { value: 'beginner', label: t('difficulty.beginner'), description: t('difficulty.descriptions.beginner') },
    { value: 'intermediate', label: t('difficulty.intermediate'), description: t('difficulty.descriptions.intermediate') },
    { value: 'advanced', label: t('difficulty.advanced'), description: t('difficulty.descriptions.advanced') },
    { value: 'elite', label: t('difficulty.elite'), description: t('difficulty.descriptions.elite') }
  ];

  openBottomSheet({
    title: t('exercise.difficultyFilter.title'),
    options: filterOptions,
    selectedValues: exerciseDifficultyFilter ? [exerciseDifficultyFilter] : [''],
    enableSearch: false,
    fieldId: 'exercise-difficulty-filter-btn',
    onConfirm: (selectedValues) => {
      const selected = selectedValues.length > 0 ? selectedValues[selectedValues.length - 1] : '';
      setExerciseDifficultyFilter(selected);
    }
  });
}

/**
 * Opens equipment filter as a bottom sheet (single-select)
 */
function openEquipmentFilterSheet() {
  const mainEquipment = ['bodyweight', 'pull-up-bar', 'parallettes', 'rings', 'dumbbell', 'barbell', 'resistance-bands', 'gym-machine', 'bench'];

  const filterOptions = [
    { value: '', label: t('plan.filters.all'), description: '' }
  ];

  mainEquipment.forEach(eq => {
    filterOptions.push({
      value: eq,
      label: equipmentNames[eq] || eq,
      description: ''
    });
  });

  openBottomSheet({
    title: t('exercise.equipmentFilter.title'),
    options: filterOptions,
    selectedValues: exerciseEquipmentFilter ? [exerciseEquipmentFilter] : [''],
    enableSearch: false,
    fieldId: 'exercise-equipment-filter-btn',
    onConfirm: (selectedValues) => {
      const selected = selectedValues.length > 0 ? selectedValues[selectedValues.length - 1] : '';
      setExerciseEquipmentFilter(selected);
    }
  });
}

function updateExerciseFiltersUI() {
  // Update muscle filter button label
  const muscleFilterLabel = document.getElementById('exercise-muscle-filter-label');
  const muscleFilterBtn = document.getElementById('exercise-muscle-filter-btn');
  if (muscleFilterLabel) {
    muscleFilterLabel.textContent = exerciseMuscleFilter
      ? (getMuscleNames()[exerciseMuscleFilter] || exerciseMuscleFilter)
      : t('exercise.filters.allMuscles');
  }
  if (muscleFilterBtn) {
    muscleFilterBtn.classList.toggle('active', !!exerciseMuscleFilter);
  }

  // Update difficulty filter button label
  const difficultyFilterLabel = document.getElementById('exercise-difficulty-filter-label');
  const difficultyFilterBtn = document.getElementById('exercise-difficulty-filter-btn');
  if (difficultyFilterLabel) {
    difficultyFilterLabel.textContent = exerciseDifficultyFilter
      ? (t('difficulty.' + exerciseDifficultyFilter) || exerciseDifficultyFilter)
      : t('exercise.filters.allDifficulties');
  }
  if (difficultyFilterBtn) {
    difficultyFilterBtn.classList.toggle('active', !!exerciseDifficultyFilter);
  }

  // Update equipment filter button label
  const equipmentFilterLabel = document.getElementById('exercise-equipment-filter-label');
  const equipmentFilterBtn = document.getElementById('exercise-equipment-filter-btn');
  if (equipmentFilterLabel) {
    equipmentFilterLabel.textContent = exerciseEquipmentFilter
      ? (equipmentNames[exerciseEquipmentFilter] || exerciseEquipmentFilter)
      : t('plan.filters.all');
  }
  if (equipmentFilterBtn) {
    equipmentFilterBtn.classList.toggle('active', !!exerciseEquipmentFilter);
  }
}

function toggleExercisesExpanded() {
  exercisesExpanded = !exercisesExpanded;
  renderExercises();
}

function resetFilters() {
  const input = document.getElementById('search-input');
  if (input) input.value = '';
  const clearBtn = document.getElementById('exercise-search-clear');
  if (clearBtn) clearBtn.classList.add('hidden');
  exerciseMuscleFilter = '';
  exerciseDifficultyFilter = '';
  exerciseEquipmentFilter = '';
  updateExerciseFiltersUI();
  filterExercises();
}

// Active Filter Pills
function updateActiveFilters() {
  const searchInput = document.getElementById('search-input');
  const searchTerm = searchInput ? searchInput.value : '';
  const muscleFilter = exerciseMuscleFilter;
  const difficultyFilter = exerciseDifficultyFilter;
  const equipmentFilter = exerciseEquipmentFilter;

  let filterPills = '';

  if (searchTerm) {
    filterPills += `
      <div class="filter-pill">
        <span class="material-symbols-rounded">search</span>
        <span>${searchTerm}</span>
        <button onclick="clearSearchFilter()" class="filter-pill-remove">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
    `;
  }

  if (muscleFilter) {
    filterPills += `
      <div class="filter-pill">
        <span class="material-symbols-rounded">sports_gymnastics</span>
        <span>${getMuscleNames()[muscleFilter]}</span>
        <button onclick="clearMuscleFilter()" class="filter-pill-remove">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
    `;
  }

  if (difficultyFilter) {
    filterPills += `
      <div class="filter-pill">
        <span class="material-symbols-rounded">star</span>
        <span>${t(`difficulty.${difficultyFilter}`)}</span>
        <button onclick="clearDifficultyFilter()" class="filter-pill-remove">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
    `;
  }

  if (equipmentFilter) {
    filterPills += `
      <div class="filter-pill">
        <span class="material-symbols-rounded">build</span>
        <span>${equipmentNames[equipmentFilter] || equipmentFilter}</span>
        <button onclick="setExerciseEquipmentFilter('')" class="filter-pill-remove">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
    `;
  }

  const container = document.getElementById('active-filters');
  if (container) {
    if (filterPills) {
      container.innerHTML = filterPills + `
        <button onclick="resetFilters()" class="filter-pill filter-pill-reset">
          <span class="material-symbols-rounded">restart_alt</span>
          <span>Alle zurücksetzen</span>
        </button>
      `;
      container.style.display = 'flex';
    } else {
      container.style.display = 'none';
    }
  }
}

function clearSearchFilter() {
  clearExerciseSearch();
}

function clearMuscleFilter() {
  setExerciseMuscleFilter('');
}

function clearDifficultyFilter() {
  setExerciseDifficultyFilter('');
}

// ========================================
// MODAL MANAGEMENT
// ========================================

function openAddExerciseModal() {
  editingExerciseId = null;
  document.getElementById('modal-title').textContent = t('exercise.create.title');
  clearExerciseForm();
  if (exerciseInstructionSteps.length === 0) {
    addInstructionStep();
  }

  // Initialize multi-select inputs
  exerciseMuscleGroups = [];
  exerciseEquipment = [];
  renderExerciseMuscleGroupsInput();
  renderExerciseEquipmentInput();

  // V3 fields
  setExerciseType('strength');
  exerciseVariants = [];
  exerciseNotes = '';
  renderVariants();

  // Collapse step 2
  exerciseStep2Expanded = false;
  const section = document.getElementById('exercise-step2-section');
  const content = document.getElementById('exercise-step2-content');
  const toggle = document.getElementById('exercise-step2-toggle');
  if (section) section.classList.remove('open');
  if (content) content.classList.add('collapsed');
  if (toggle) toggle.style.transform = '';

  document.getElementById('exercise-modal').classList.add('active');
}

function editExercise(id) {
  editingExerciseId = id;
  const exercise = allExercises.find(ex => ex.id === id);

  if (!exercise) return;

  document.getElementById('modal-title').textContent = t('exercise.editTitle');
  document.getElementById('exercise-name').value = getExerciseName(exercise);

  // Set muscle groups and equipment for multi-select
  exerciseMuscleGroups = [...exercise.muscleGroups];
  exerciseEquipment = exercise.equipment ? [...exercise.equipment] : [];

  // Render multi-select inputs
  renderExerciseMuscleGroupsInput();
  renderExerciseEquipmentInput();

  // Difficulty - convert old numeric values to enum
  const difficultyValue = convertDifficultyToEnum(exercise.difficulty);
  setDifficulty(difficultyValue);

  // Icon
  const iconValue = exercise.icon || 'fitness_center';
  setExerciseIcon(iconValue);

  // V3 fields
  setExerciseType(exercise.type || 'strength');
  exerciseVariants = exercise.variants ? exercise.variants.map(v => ({...v})) : [];
  exerciseNotes = exercise.notes || '';
  renderVariants();

  // Notes textarea
  const notesInput = document.getElementById('exercise-notes');
  if (notesInput) notesInput.value = exerciseNotes;

  // Instructions - normalize legacy data into new fields
  const normalized = normalizeExerciseInstructions(exercise);
  exerciseInstructionSteps = [...normalized.instructionsSteps];
  exerciseInstructionCues = [...normalized.cues];
  exerciseInstructionMistakes = [...normalized.commonMistakes];
  exerciseInstructionProgressions = [...normalized.progressions];
  exerciseSetupNotes = normalized.setupNotes || '';

  renderInstructionSteps();
  renderInstructionLists();
  updateSetupNotesInput();
  applyExerciseInstructionI18n();

  const hasAdvancedContent = exerciseInstructionCues.length > 0 ||
    exerciseInstructionMistakes.length > 0 ||
    exerciseInstructionProgressions.length > 0 ||
    !!exerciseSetupNotes;
  setExerciseInstructionAdvancedExpanded(hasAdvancedContent);

  // Expand step 2 if exercise has detail content
  const hasStep2Content = exerciseInstructionSteps.length > 0 ||
    exerciseVariants.length > 0 || exerciseNotes ||
    hasAdvancedContent;
  exerciseStep2Expanded = hasStep2Content;
  const section = document.getElementById('exercise-step2-section');
  const contentEl = document.getElementById('exercise-step2-content');
  const toggle = document.getElementById('exercise-step2-toggle');
  if (hasStep2Content) {
    if (section) section.classList.add('open');
    if (contentEl) contentEl.classList.remove('collapsed');
    if (toggle) toggle.style.transform = 'rotate(180deg)';
  } else {
    if (section) section.classList.remove('open');
    if (contentEl) contentEl.classList.add('collapsed');
    if (toggle) toggle.style.transform = '';
  }

  document.getElementById('exercise-modal').classList.add('active');
}

function closeExerciseModal() {
  const exerciseModal = document.getElementById('exercise-modal');
  if (exerciseModal) {
    exerciseModal.classList.remove('active');
    exerciseModal.classList.remove('modal--elevated');
  }
  // Modal-Stacking: Exercise-Picker wieder einblenden falls versteckt
  const pickerModal = document.getElementById('exercise-picker-modal');
  if (pickerModal) {
    pickerModal.classList.remove('modal--hidden-by-stack');
  }
  clearExerciseForm();
}

function clearExerciseForm() {
  document.getElementById('exercise-name').value = '';

  // Clear instruction steps
  exerciseInstructionSteps = [];
  exerciseInstructionCues = [];
  exerciseInstructionMistakes = [];
  exerciseInstructionProgressions = [];
  exerciseSetupNotes = '';
  renderInstructionSteps();
  renderInstructionLists();
  updateSetupNotesInput();
  applyExerciseInstructionI18n();

  // Collapse advanced instructions section
  setExerciseInstructionAdvancedExpanded(false);

  // Clear multi-select inputs
  exerciseMuscleGroups = [];
  exerciseEquipment = [];
  renderExerciseMuscleGroupsInput();
  renderExerciseEquipmentInput();

  setDifficulty('intermediate');
  setExerciseIcon('fitness_center');

  // V3 fields
  exerciseType = 'strength';
  exerciseVariants = [];
  exerciseNotes = '';
  const notesInput = document.getElementById('exercise-notes');
  if (notesInput) notesInput.value = '';

  editingExerciseId = null;
}

// ========================================
// DIFFICULTY SELECTION (Enum-based)
// ========================================

// Difficulty enum mapping (for backward compatibility)
const exerciseDifficultyEnum = {
  beginner: { label: 'Anfänger', value: 1 },
  intermediate: { label: 'Fortgeschritten', value: 2 },
  advanced: { label: 'Profi', value: 3 },
  elite: { label: 'Elite', value: 4 }
};

function setDifficulty(difficulty) {
  document.getElementById('exercise-difficulty').value = difficulty;

  // Handle both standard and compact difficulty pills
  document.querySelectorAll('#exercise-modal .difficulty-pill, #exercise-modal .difficulty-pill-sm').forEach(pill => {
    pill.classList.toggle('active', pill.dataset.difficulty === difficulty);
  });
}

// Convert old numeric difficulty to new enum
function convertDifficultyToEnum(difficulty) {
  if (typeof difficulty === 'string') return difficulty;
  if (difficulty <= 1) return 'beginner';
  if (difficulty <= 2) return 'intermediate';
  if (difficulty <= 3) return 'advanced';
  return 'elite';
}

// Convert enum to numeric value for filtering
function getDifficultyNumericValue(difficulty) {
  if (typeof difficulty === 'number') return difficulty;
  const info = exerciseDifficultyEnum[difficulty];
  return info ? info.value : 2;
}

// ========================================
// EXERCISE ICON SELECTION
// ========================================

let selectedExerciseIcon = 'fitness_center';

function setExerciseIcon(icon) {
  selectedExerciseIcon = icon;
  document.getElementById('exercise-icon').value = icon;

  document.querySelectorAll('.icon-picker-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.icon === icon);
  });
}

// ========================================
// EXERCISE V3 SETTERS & RENDERERS
// ========================================

function setExerciseType(type) {
  exerciseType = type;
  const hidden = document.getElementById('exercise-type');
  if (hidden) hidden.value = type;
  document.querySelectorAll('#exercise-type-pills .difficulty-pill').forEach(pill => {
    pill.classList.toggle('active', pill.dataset.type === type);
  });
}

function toggleExerciseStep2() {
  exerciseStep2Expanded = !exerciseStep2Expanded;
  const section = document.getElementById('exercise-step2-section');
  const content = document.getElementById('exercise-step2-content');
  const toggle = document.getElementById('exercise-step2-toggle');
  if (exerciseStep2Expanded) {
    if (section) section.classList.add('open');
    if (content) content.classList.remove('collapsed');
    if (toggle) toggle.style.transform = 'rotate(180deg)';
  } else {
    if (section) section.classList.remove('open');
    if (content) content.classList.add('collapsed');
    if (toggle) toggle.style.transform = '';
  }
}

// --- Variants ---

function renderVariants() {
  const container = document.getElementById('exercise-variants-list');
  if (!container) return;

  if (exerciseVariants.length === 0) {
    container.innerHTML = `
      <div class="empty-steps-hint">
        <span class="material-symbols-rounded">swap_horiz</span>
        <span>${t('exercise.variants.empty')}</span>
      </div>`;
    return;
  }

  container.innerHTML = exerciseVariants.map((v, i) => `
    <div class="variant-edit-row" data-index="${i}">
      <div class="variant-edit-inputs">
        <input type="text" class="variant-name-input" value="${(v.name || '').replace(/"/g, '&quot;')}"
          placeholder="${t('exercise.variants.namePlaceholder')}"
          onchange="updateVariant(${i}, 'name', this.value)"
          onkeydown="handleVariantKeydown(event, ${i})">
        <input type="text" class="variant-note-input" value="${(v.note || '').replace(/"/g, '&quot;')}"
          placeholder="${t('exercise.variants.notePlaceholder')}"
          onchange="updateVariant(${i}, 'note', this.value)">
      </div>
      <button type="button" class="remove-step-btn" onclick="removeVariant(${i})"
        title="${t('exercise.variants.remove')}">
        <span class="material-symbols-rounded">close</span>
      </button>
    </div>
  `).join('');
}

function addVariant() {
  if (exerciseVariants.length >= 10) return;
  exerciseVariants.push({ name: '', note: '' });
  renderVariants();
  setTimeout(() => {
    const inputs = document.querySelectorAll('.variant-name-input');
    if (inputs.length) inputs[inputs.length - 1].focus();
  }, 50);
}

function removeVariant(index) {
  exerciseVariants.splice(index, 1);
  renderVariants();
}

function updateVariant(index, field, value) {
  if (exerciseVariants[index]) {
    exerciseVariants[index][field] = value;
  }
}

function handleVariantKeydown(event, index) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    updateVariant(index, 'name', event.target.value);
    addVariant();
  }
}

function getCleanVariants() {
  document.querySelectorAll('.variant-name-input').forEach((input, i) => {
    if (exerciseVariants[i]) exerciseVariants[i].name = input.value.trim();
  });
  document.querySelectorAll('.variant-note-input').forEach((input, i) => {
    if (exerciseVariants[i]) exerciseVariants[i].note = input.value.trim();
  });
  return exerciseVariants.filter(v => v.name.trim() !== '');
}

// --- Inline Create Hook ---

function openExerciseCreateSheet(options) {
  exerciseCreateCallback = (options && options.onCreated) ? options.onCreated : null;
  // Modal-Stacking: Exercise-Picker verbergen und Exercise-Modal anheben
  const pickerModal = document.getElementById('exercise-picker-modal');
  if (pickerModal && pickerModal.classList.contains('active')) {
    pickerModal.classList.add('modal--hidden-by-stack');
  }
  const exerciseModal = document.getElementById('exercise-modal');
  if (exerciseModal) {
    exerciseModal.classList.add('modal--elevated');
  }
  openAddExerciseModal();
}

// ========================================
// EXERCISE INSTRUCTIONS (Steps + Advanced)
// ========================================

let exerciseInstructionSteps = []; // string[] für nummerierte Schritte
let exerciseInstructionCues = [];
let exerciseInstructionMistakes = [];
let exerciseInstructionProgressions = [];
let exerciseSetupNotes = '';
let exerciseInstructionsAdvancedExpanded = false;

const instructionListConfig = {
  cues: {
    containerId: 'exercise-cues-list',
    labelId: 'exercise-cues-label',
    addLabelId: 'exercise-cues-add-label',
    placeholderKey: 'exercise.instructions.advanced.cuesPlaceholder'
  },
  mistakes: {
    containerId: 'exercise-mistakes-list',
    labelId: 'exercise-mistakes-label',
    addLabelId: 'exercise-mistakes-add-label',
    placeholderKey: 'exercise.instructions.advanced.mistakesPlaceholder'
  },
  progressions: {
    containerId: 'exercise-progressions-list',
    labelId: 'exercise-progressions-label',
    addLabelId: 'exercise-progressions-add-label',
    placeholderKey: 'exercise.instructions.advanced.progressionsPlaceholder'
  }
};

function applyExerciseInstructionI18n() {
  const title = document.getElementById('exercise-instructions-title');
  if (title) title.textContent = t('exercise.instructions.title');

  const hint = document.getElementById('exercise-instructions-hint');
  if (hint) hint.textContent = t('exercise.instructions.hint');

  const addStepLabel = document.getElementById('exercise-add-step-label');
  if (addStepLabel) addStepLabel.textContent = t('exercise.instructions.addStep');

  Object.values(instructionListConfig).forEach(config => {
    const label = document.getElementById(config.labelId);
    if (label) {
      if (config.labelId === 'exercise-cues-label') {
        label.textContent = t('exercise.instructions.advanced.cues');
      } else if (config.labelId === 'exercise-mistakes-label') {
        label.textContent = t('exercise.instructions.advanced.mistakes');
      } else if (config.labelId === 'exercise-progressions-label') {
        label.textContent = t('exercise.instructions.advanced.progressions');
      }
    }
    const addLabel = document.getElementById(config.addLabelId);
    if (addLabel) {
      if (config.addLabelId === 'exercise-cues-add-label') {
        addLabel.textContent = t('exercise.instructions.advanced.cuesAdd');
      } else if (config.addLabelId === 'exercise-mistakes-add-label') {
        addLabel.textContent = t('exercise.instructions.advanced.mistakesAdd');
      } else if (config.addLabelId === 'exercise-progressions-add-label') {
        addLabel.textContent = t('exercise.instructions.advanced.progressionsAdd');
      }
    }
  });

  const setupLabel = document.getElementById('exercise-setup-notes-label');
  if (setupLabel) setupLabel.textContent = t('exercise.instructions.advanced.setup');

  const setupInput = document.getElementById('exercise-setup-notes');
  if (setupInput) setupInput.placeholder = t('exercise.instructions.advanced.setupPlaceholder');

  updateExerciseInstructionAdvancedToggle();
}

function setExerciseInstructionAdvancedExpanded(isExpanded) {
  exerciseInstructionsAdvancedExpanded = !!isExpanded;
  const advancedContent = document.getElementById('exercise-instructions-advanced');
  if (advancedContent) {
    advancedContent.classList.toggle('hidden', !exerciseInstructionsAdvancedExpanded);
  }
  updateExerciseInstructionAdvancedToggle();
}

function updateExerciseInstructionAdvancedToggle() {
  const label = document.getElementById('exercise-advanced-toggle-label');
  const icon = document.getElementById('exercise-advanced-toggle-icon');
  if (label) {
    label.textContent = exerciseInstructionsAdvancedExpanded
      ? t('exercise.instructions.advanced.hide')
      : t('exercise.instructions.advanced.add');
  }
  if (icon) {
    icon.textContent = exerciseInstructionsAdvancedExpanded ? 'expand_less' : 'add_circle';
  }
}

function toggleExerciseInstructionAdvanced() {
  setExerciseInstructionAdvancedExpanded(!exerciseInstructionsAdvancedExpanded);
}

// ========================================
// INSTRUCTION STEPS MANAGEMENT
// ========================================

/**
 * Rendert alle Anleitung-Schritte
 */
function renderInstructionSteps() {
  const container = document.getElementById('exercise-instruction-steps');
  if (!container) return;

  if (exerciseInstructionSteps.length === 0) {
    container.innerHTML = `
      <div class="empty-steps-hint">
        <span class="material-symbols-rounded">format_list_numbered</span>
        <span>${t('exercise.instructions.noSteps')}</span>
      </div>
    `;
    return;
  }

  container.innerHTML = exerciseInstructionSteps.map((step, index) => `
    <div class="instruction-step" data-index="${index}">
      <div class="instruction-step-header">
        <span class="step-number">${index + 1}.</span>
        <button type="button" class="remove-step-btn" onclick="removeInstructionStep(${index})" title="${t('exercise.instructions.removeStep')}">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
      <textarea
        class="instruction-step-input instruction-step-input-main"
        rows="2"
        placeholder="${t('exercise.instructions.stepPlaceholder')}"
        aria-label="${t('exercise.instructions.stepTitle', { number: index + 1 })}"
        onchange="updateInstructionStep(${index}, this.value)"
        onkeydown="handleStepKeydown(event, ${index})"
      >${step}</textarea>
    </div>
  `).join('');
}

/**
 * Fügt einen neuen Schritt hinzu
 */
function addInstructionStep(initialValue = '') {
  if (exerciseInstructionSteps.length >= 10) return;
  exerciseInstructionSteps.push(initialValue);
  renderInstructionSteps();

  // Fokussiere das neue Eingabefeld
  setTimeout(() => {
    const inputs = document.querySelectorAll('.instruction-step-input-main');
    const lastInput = inputs[inputs.length - 1];
    if (lastInput) lastInput.focus();
  }, 50);
}

/**
 * Entfernt einen Schritt
 */
function removeInstructionStep(index) {
  exerciseInstructionSteps.splice(index, 1);
  renderInstructionSteps();
}

/**
 * Aktualisiert einen Schritt
 */
function updateInstructionStep(index, value) {
  exerciseInstructionSteps[index] = value;
}

/**
 * Handle Enter-Taste um neuen Schritt hinzuzufügen
 */
function handleStepKeydown(event, index) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    // Speichere aktuellen Wert
    exerciseInstructionSteps[index] = event.target.value;
    // Füge neuen Schritt hinzu
    addInstructionStep();
  }
}

/**
 * Holt die Schritte ohne leere trailing Steps
 */
function getCleanInstructionSteps() {
  // Sync alle Input-Werte
  const inputs = document.querySelectorAll('.instruction-step-input-main');
  inputs.forEach((input, index) => {
    exerciseInstructionSteps[index] = input.value.trim();
  });

  // Entferne leere trailing Steps
  while (exerciseInstructionSteps.length > 0 && exerciseInstructionSteps[exerciseInstructionSteps.length - 1] === '') {
    exerciseInstructionSteps.pop();
  }

  return exerciseInstructionSteps.filter(step => step.trim() !== '');
}

// ========================================
// ADVANCED INSTRUCTION LISTS
// ========================================

function getInstructionListByKey(listKey) {
  if (listKey === 'cues') return exerciseInstructionCues;
  if (listKey === 'mistakes') return exerciseInstructionMistakes;
  if (listKey === 'progressions') return exerciseInstructionProgressions;
  return [];
}

function setInstructionListByKey(listKey, list) {
  if (listKey === 'cues') exerciseInstructionCues = list;
  if (listKey === 'mistakes') exerciseInstructionMistakes = list;
  if (listKey === 'progressions') exerciseInstructionProgressions = list;
}

function renderInstructionLists() {
  renderInstructionList('cues');
  renderInstructionList('mistakes');
  renderInstructionList('progressions');
}

function renderInstructionList(listKey) {
  const config = instructionListConfig[listKey];
  if (!config) return;

  const container = document.getElementById(config.containerId);
  if (!container) return;

  const list = getInstructionListByKey(listKey);
  if (list.length === 0) {
    container.innerHTML = `
      <div class="empty-steps-hint">
        <span class="material-symbols-rounded">notes</span>
        <span>${t('exercise.instructions.advanced.emptyList')}</span>
      </div>
    `;
    return;
  }

  container.innerHTML = list.map((item, index) => `
    <div class="instruction-step" data-index="${index}">
      <div class="instruction-step-header">
        <span class="step-number">${index + 1}.</span>
        <button type="button" class="remove-step-btn" onclick="removeInstructionListItem('${listKey}', ${index})" title="${t('exercise.instructions.removeStep')}">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
      <textarea
        class="instruction-step-input instruction-step-input-advanced"
        rows="2"
        placeholder="${t(config.placeholderKey)}"
        aria-label="${t('exercise.instructions.stepTitle', { number: index + 1 })}"
        onchange="updateInstructionListItem('${listKey}', ${index}, this.value)"
        onkeydown="handleInstructionListKeydown(event, '${listKey}', ${index})"
      >${item}</textarea>
    </div>
  `).join('');
}

function addInstructionListItem(listKey, initialValue = '') {
  const list = getInstructionListByKey(listKey);
  list.push(initialValue);
  setInstructionListByKey(listKey, list);
  renderInstructionList(listKey);

  setTimeout(() => {
    const container = document.getElementById(instructionListConfig[listKey]?.containerId);
    const inputs = container ? container.querySelectorAll('.instruction-step-input') : [];
    const lastInput = inputs[inputs.length - 1];
    if (lastInput) lastInput.focus();
  }, 50);
}

function removeInstructionListItem(listKey, index) {
  const list = getInstructionListByKey(listKey);
  list.splice(index, 1);
  setInstructionListByKey(listKey, list);
  renderInstructionList(listKey);
}

function updateInstructionListItem(listKey, index, value) {
  const list = getInstructionListByKey(listKey);
  list[index] = value;
  setInstructionListByKey(listKey, list);
}

function handleInstructionListKeydown(event, listKey, index) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    updateInstructionListItem(listKey, index, event.target.value);
    addInstructionListItem(listKey);
  }
}

function getCleanInstructionList(listKey) {
  const config = instructionListConfig[listKey];
  const container = document.getElementById(config?.containerId);
  const inputs = container ? container.querySelectorAll('.instruction-step-input') : [];
  const list = getInstructionListByKey(listKey).slice();

  inputs.forEach((input, index) => {
    list[index] = input.value.trim();
  });

  while (list.length > 0 && list[list.length - 1] === '') {
    list.pop();
  }

  return list.filter(item => item.trim() !== '');
}

function updateSetupNotesInput() {
  const input = document.getElementById('exercise-setup-notes');
  if (!input) return;
  input.value = exerciseSetupNotes || '';
}

// ========================================
// SAVE EXERCISE
// ========================================

async function saveExercise() {
  const name = document.getElementById('exercise-name').value.trim();
  const type = document.getElementById('exercise-type')?.value || 'strength';
  const difficulty = document.getElementById('exercise-difficulty').value;
  const icon = document.getElementById('exercise-icon')?.value || 'fitness_center';

  // Get instructions as string[] (nummerierte Schritte)
  const instructionsSteps = getCleanInstructionSteps();
  const cues = getCleanInstructionList('cues');
  const commonMistakes = getCleanInstructionList('mistakes');
  const progressions = getCleanInstructionList('progressions');
  const setupNotesInput = document.getElementById('exercise-setup-notes');
  const setupNotes = setupNotesInput ? setupNotesInput.value.trim() : '';
  const notesEl = document.getElementById('exercise-notes');
  const notes = notesEl ? notesEl.value.trim() : '';
  const variants = getCleanVariants();

  // Get selected muscle groups and equipment from state
  const muscleGroups = exerciseMuscleGroups;
  const equipment = exerciseEquipment.length > 0 ? exerciseEquipment : ['none'];

  // Validation - only name required in v3
  if (!name) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('errors.exerciseNameRequired') || 'Bitte gib einen Namen für die Übung ein!');
    }
    return;
  }

  // Build v3 data and map to Firestore format
  const v3Data = {
    name, type, difficulty, icon,
    instructions: instructionsSteps,
    muscleGroups, equipment,
    variants, notes,
    setupNotes, cues, commonMistakes, progressions
  };

  const exerciseData = mapV3ToExerciseDoc(v3Data);

  try {
    if (editingExerciseId) {
      await updateDoc(exercisesCollection, editingExerciseId, exerciseData);
    } else {
      const newId = await addDoc(exercisesCollection, exerciseData);

      // Inline create callback (for plan integration)
      if (typeof exerciseCreateCallback === 'function') {
        const callbackFn = exerciseCreateCallback;
        exerciseCreateCallback = null;
        closeExerciseModal();
        await loadExercises();
        callbackFn(newId);
        return;
      }
    }

    closeExerciseModal();
    await loadExercises();
  } catch (error) {
    console.error('Error saving exercise:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('exercise.feedback.saveError'));
    }
  }
}

// ========================================
// DELETE EXERCISE
// ========================================

async function deleteExercise(exerciseId) {
  // Check if exercise is used in any plan
  const usedInPlans = (typeof allPlans !== 'undefined' ? allPlans : []).filter(plan => {
    const items = plan.items || plan.exercises || [];
    return items.some(item => item.exerciseId === exerciseId);
  });

  let confirmMessage = t('exercise.deleteConfirm');
  if (usedInPlans.length > 0) {
    const planNames = usedInPlans.map(p => p.name).join(', ');
    confirmMessage = t('exercise.deleteUsedInPlans', {
      count: usedInPlans.length,
      plans: planNames
    });
  }

  if (!confirm(confirmMessage)) return;

  try {
    await deleteDoc(exercisesCollection, exerciseId);
    closeGenericModal();
    await loadExercises();
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', t('exercise.deleted'));
    }
  } catch (error) {
    console.error('Error deleting exercise:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('exercise.deleteError'));
    }
  }
}

// ========================================
// EXERCISE DETAIL HELPERS
// ========================================

function getExerciseSetsFromSessions(exerciseId) {
  const sessions = typeof allSessions !== 'undefined' ? allSessions : [];
  const results = [];
  sessions.forEach(session => {
    if (!session.exercises || !Array.isArray(session.exercises)) return;
    session.exercises.forEach(ex => {
      if (ex.exerciseId !== exerciseId) return;
      if (!ex.sets || !Array.isArray(ex.sets)) return;
      let sessionDate;
      if (session.date && session.date.toDate) sessionDate = session.date.toDate();
      else if (session.date instanceof Date) sessionDate = session.date;
      else if (typeof session.date === 'string') sessionDate = new Date(session.date);
      else sessionDate = new Date();
      results.push({ sessionId: session.id, date: sessionDate, sets: ex.sets });
    });
  });
  return results;
}

function computeExerciseQuickStats(exerciseId) {
  const exerciseEntries = getExerciseSetsFromSessions(exerciseId);

  let bestReps = 0;
  let heaviestWeight = 0;
  let bestSetVolume = 0;

  exerciseEntries.forEach(entry => {
    entry.sets.forEach(s => {
      const reps = s.reps || 0;
      const weight = s.weight || 0;
      if (reps > bestReps) bestReps = reps;
      if (weight > heaviestWeight) heaviestWeight = weight;
      const volume = weight > 0 ? reps * weight : reps;
      if (volume > bestSetVolume) bestSetVolume = volume;
    });
  });

  return { bestReps, heaviestWeight, bestSetVolume };
}

function renderExerciseHistoryTab(exerciseId) {
  const exerciseEntries = getExerciseSetsFromSessions(exerciseId);

  if (exerciseEntries.length === 0) {
    return '<div class="exercise-history-empty"><span class="material-symbols-rounded" style="font-size:40px;display:block;margin-bottom:0.5rem;">history</span>Noch keine Historie vorhanden</div>';
  }

  // Sort descending by date
  exerciseEntries.sort((a, b) => b.date - a.date);

  // Group by date key
  const groups = {};
  exerciseEntries.forEach(e => {
    const key = e.date.toISOString().split('T')[0];
    if (!groups[key]) groups[key] = { date: e.date, entries: [] };
    groups[key].entries.push(e);
  });

  let html = '';
  Object.keys(groups).sort().reverse().forEach(key => {
    const g = groups[key];
    const dateStr = g.date.toLocaleDateString('de-DE', { weekday: 'short', day: '2-digit', month: '2-digit', year: 'numeric' });
    html += `<div class="exercise-history-date-group">
      <div class="exercise-history-date-header">${dateStr}</div>`;

    g.entries.forEach(entry => {
      const setsStr = entry.sets.map((s, i) =>
        `Satz ${i + 1}: ${s.reps || 0} Wdh${s.weight ? ' × ' + s.weight + ' kg' : ''}`
      ).join('<br>');

      html += `<div class="exercise-history-entry">
        <div class="exercise-history-sets">${setsStr}</div>
        <button class="exercise-history-delete" onclick="deleteExerciseFromSession('${entry.sessionId}', '${exerciseId}')" title="Eintrag löschen">
          <span class="material-symbols-rounded" style="font-size:20px;">delete</span>
        </button>
      </div>`;
    });

    html += '</div>';
  });

  return html;
}

async function deleteExerciseFromSession(sessionId, exerciseId) {
  if (!confirm('Diese Übung aus der Session löschen?')) return;

  try {
    const session = allSessions.find(s => s.id === sessionId);
    if (!session) return;

    // Remove exercise from session
    const updatedExercises = (session.exercises || []).filter(ex => ex.exerciseId !== exerciseId);

    if (updatedExercises.length === 0) {
      // No exercises left -> delete entire session
      await deleteDoc(sessionsCollection, sessionId);
      const idx = allSessions.findIndex(s => s.id === sessionId);
      if (idx !== -1) allSessions.splice(idx, 1);
    } else {
      // Update session with remaining exercises
      await updateDoc(sessionsCollection, sessionId, { exercises: updatedExercises });
      session.exercises = updatedExercises;
    }

    // Re-render history tab
    const historyPanel = document.querySelector('[data-panel="history"]');
    if (historyPanel) {
      historyPanel.innerHTML = renderExerciseHistoryTab(exerciseId);
    }
    // Re-render info tab stats
    const statsContainer = document.getElementById('exercise-detail-stats');
    if (statsContainer) {
      const stats = computeExerciseQuickStats(exerciseId);
      statsContainer.innerHTML = renderExerciseQuickStatsHTML(stats);
    }
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', t('exercise.feedback.deleted'));
    }
  } catch (error) {
    console.error('Error deleting exercise from session:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('exercise.feedback.deleteError'));
    }
  }
}

function renderExerciseQuickStatsHTML(stats) {
  return `
    <div class="quick-stats-grid quick-stats-grid--3col">
      <div class="quick-stats-card">
        <div class="quick-stats-header">
          <span class="quick-stats-icon"><span class="material-symbols-rounded">repeat</span></span>
          <span class="quick-stats-label">Beste Wiederholungen</span>
        </div>
        <div class="quick-stats-value">${stats.bestReps || '–'}</div>
      </div>
      <div class="quick-stats-card">
        <div class="quick-stats-header">
          <span class="quick-stats-icon"><span class="material-symbols-rounded">fitness_center</span></span>
          <span class="quick-stats-label">Meistes Gewicht</span>
        </div>
        <div class="quick-stats-value">${stats.heaviestWeight ? stats.heaviestWeight + ' kg' : '–'}</div>
      </div>
      <div class="quick-stats-card">
        <div class="quick-stats-header">
          <span class="quick-stats-icon"><span class="material-symbols-rounded">speed</span></span>
          <span class="quick-stats-label">Bestes Satzvolumen</span>
        </div>
        <div class="quick-stats-value">${stats.bestSetVolume || '–'}</div>
      </div>
    </div>`;
}

function attachExerciseDetailTabListeners() {
  const control = document.querySelector('#generic-modal-body .cal-widget-segmented-control');
  const btns = document.querySelectorAll('#generic-modal-body [data-detail-tab]');
  btns.forEach((btn, idx) => {
    btn.addEventListener('click', () => {
      btns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      if (control) control.style.setProperty('--active-idx', idx);
      const tab = btn.dataset.detailTab;
      document.querySelectorAll('.exercise-detail-tab-panel').forEach(panel => {
        panel.classList.toggle('active', panel.dataset.panel === tab);
      });
    });
  });
}

// ========================================
// VIEW EXERCISE DETAILS
// ========================================

function viewExerciseDetails(id) {
  const exercise = allExercises.find(ex => ex.id === id);
  if (!exercise) return;

  const difficultyValue = convertDifficultyToEnum(exercise.difficulty);
  const typeLabel = t('exercise.type.' + exercise.type) || exercise.type || '';
  const difficultyLabel = t('difficulty.' + difficultyValue) || difficultyValue;
  const normalizedInstructions = normalizeExerciseInstructions(exercise);

  // Difficulty color for subtle badge
  const diffColor = {
    beginner: '#4CAF50',
    intermediate: '#FF9800',
    advanced: '#F44336',
    elite: '#9C27B0'
  }[difficultyValue] || '#6b7280';

  // Muscle group label
  const muscleNamesMap = getMuscleNames();
  const muscleChipLabel = (exercise.muscleGroups || [])
    .map(m => muscleNamesMap[m]).filter(Boolean).join(', ');

  // Chips: Type + Muscle groups + difficulty
  const chipsHTML = `
    <div class="exercise-detail-chips">
      <span class="exercise-chip">${typeLabel}</span>
      ${muscleChipLabel ? `<span class="exercise-chip">${muscleChipLabel}</span>` : ''}
      <span class="exercise-chip exercise-chip--diff" style="border-color: ${diffColor}; color: ${diffColor}">${difficultyLabel}</span>
    </div>
  `;

  // Equipment label
  const equipmentLabel = (exercise.equipment || []).filter(eq => eq && eq !== 'none')
    .map(eq => equipmentNames[eq]).filter(Boolean).join(', ');

  const metaFooterHTML = (muscleChipLabel || equipmentLabel) ? `
    <div class="exercise-detail-meta-footer">
      ${muscleChipLabel ? '<div class="exercise-detail-chip"><span class="material-symbols-rounded">sports_gymnastics</span><span>' + muscleChipLabel + '</span></div>' : ''}
      ${equipmentLabel ? '<div class="exercise-detail-chip"><span class="material-symbols-rounded">build</span><span>' + equipmentLabel + '</span></div>' : ''}
    </div>` : '';

  // Quick stats
  const stats = computeExerciseQuickStats(exercise.id);

  // Only show edit/delete for user-created exercises
  const isCustomExercise = !exercise.source || exercise.source === 'user' || exercise.source === 'custom';

  // === TAB 1: INFO ===
  const infoTabHTML = `
    <div class="exercise-detail">
      <div class="exercise-detail-header">
        ${chipsHTML}
      </div>
      ${metaFooterHTML}
      <div id="exercise-detail-stats" style="margin-top: 1rem;">
        ${renderExerciseQuickStatsHTML(stats)}
      </div>
    </div>`;

  // === TAB 2: HISTORIE ===
  const historyTabHTML = renderExerciseHistoryTab(exercise.id);

  // === TAB 3: ANLEITUNG ===
  const stepsHtml = normalizedInstructions.instructionsSteps.length > 0
    ? `<ol class="instruction-steps-list">
        ${normalizedInstructions.instructionsSteps.map((step, index) => `
          <li>
            <span class="instruction-step-index">${index + 1}.</span>
            <span>${step}</span>
          </li>
        `).join('')}
      </ol>`
    : `<p class="instruction-empty">${t('exercise.instructions.noSteps')}</p>`;

  const variantsHTML = exercise.variants && exercise.variants.length > 0
    ? `<div class="exercise-detail-block">
        <div class="exercise-detail-block-title">
          <span class="material-symbols-rounded">swap_horiz</span>
          <span>${t('exercise.variants.label')}</span>
        </div>
        <ul class="exercise-variants-list">
          ${exercise.variants.map(v => `
            <li class="exercise-variant-item">
              <span class="exercise-variant-name">${v.name}</span>
              ${v.note ? '<span class="exercise-variant-note">' + v.note + '</span>' : ''}
            </li>
          `).join('')}
        </ul>
      </div>`
    : '';

  const notesHTML = exercise.notes
    ? `<div class="exercise-detail-block">
        <div class="exercise-detail-block-title">
          <span class="material-symbols-rounded">notes</span>
          <span>${t('exercise.notesLabel')}</span>
        </div>
        <p class="instruction-text">${exercise.notes}</p>
      </div>`
    : '';

  const advancedSections = [
    normalizedInstructions.cues.length > 0
      ? renderInstructionAccordionSection('tips_and_updates', t('exercise.instructions.advanced.cues'),
        '<ul class="instruction-list">' +
          normalizedInstructions.cues.map(item => '<li>' + item + '</li>').join('') +
        '</ul>')
      : '',
    normalizedInstructions.commonMistakes.length > 0
      ? renderInstructionAccordionSection('warning', t('exercise.instructions.advanced.mistakes'),
        '<ul class="instruction-list">' +
          normalizedInstructions.commonMistakes.map(item => '<li>' + item + '</li>').join('') +
        '</ul>')
      : '',
    normalizedInstructions.progressions.length > 0
      ? renderInstructionAccordionSection('trending_up', t('exercise.instructions.advanced.progressions'),
        '<ul class="instruction-list">' +
          normalizedInstructions.progressions.map(item => '<li>' + item + '</li>').join('') +
        '</ul>')
      : '',
    normalizedInstructions.setupNotes
      ? renderInstructionAccordionSection('tune', t('exercise.instructions.advanced.setup'),
        '<p class="instruction-text">' + normalizedInstructions.setupNotes + '</p>', true)
      : ''
  ].filter(Boolean);

  const instructionsTabHTML = `
    <div class="exercise-detail">
      <div class="exercise-detail-block">
        <div class="exercise-detail-block-title">
          <span class="material-symbols-rounded">format_list_numbered</span>
          <span>${t('exercise.instructions.title')}</span>
        </div>
        ${stepsHtml}
      </div>
      ${variantsHTML}
      ${notesHTML}
      ${advancedSections.length > 0 ? `
        <div class="exercise-detail-block">
          <div class="exercise-detail-block-title">
            <span class="material-symbols-rounded">tune</span>
            <span>${t('exercise.instructions.advanced.title')}</span>
          </div>
          <div class="instruction-accordion">
            ${advancedSections.join('')}
          </div>
        </div>
      ` : ''}
    </div>`;

  // Sticky action buttons (only for custom exercises)
  const actionsHTML = isCustomExercise ? `
    <div class="exercise-detail-actions exercise-detail-actions--sticky">
      <button onclick="closeGenericModal(); editExercise('${exercise.id}')" class="btn-edit">
        <span class="material-symbols-rounded">settings</span>
      </button>
      <button onclick="deleteExercise('${exercise.id}')" class="btn-danger">
        <span class="material-symbols-rounded">delete</span>
      </button>
    </div>` : '';

  // === MODAL CONTENT WITH TABS ===
  const modalContent = `
    <div class="cal-widget-segmented-control" style="--seg-count:3;--active-idx:0">
      <div class="cal-widget-seg-indicator"></div>
      <button class="cal-widget-seg-btn active" data-detail-tab="info">Info</button>
      <button class="cal-widget-seg-btn" data-detail-tab="history">Historie</button>
      <button class="cal-widget-seg-btn" data-detail-tab="instructions">Anleitung</button>
    </div>

    <div class="exercise-detail-tab-panel active" data-panel="info">
      ${infoTabHTML}
    </div>
    <div class="exercise-detail-tab-panel" data-panel="history">
      ${historyTabHTML}
    </div>
    <div class="exercise-detail-tab-panel" data-panel="instructions">
      ${instructionsTabHTML}
    </div>

    ${actionsHTML}
  `;

  openGenericModal(getExerciseName(exercise), modalContent);
  // Make modal full height
  const modalContentEl = document.querySelector('#generic-modal .modal-content');
  if (modalContentEl) modalContentEl.classList.add('modal-content--full-height');
  attachExerciseDetailTabListeners();
}

// ========================================
// INSTRUCTION ACCORDION HELPERS
// ========================================

function renderInstructionAccordionSection(icon, title, contentHTML, isOpen = false) {
  const itemId = 'accordion-' + title.toLowerCase().replace(/\s+/g, '-');
  return `
    <div class="instruction-accordion-item ${isOpen ? 'open' : ''}" data-accordion-id="${itemId}">
      <button class="instruction-accordion-header" onclick="toggleInstructionAccordion('${itemId}')">
        <div class="instruction-accordion-title">
          <span class="material-symbols-rounded">${icon}</span>
          <span>${title}</span>
        </div>
        <span class="material-symbols-rounded instruction-accordion-icon">expand_more</span>
      </button>
      <div class="instruction-accordion-content">
        ${contentHTML}
      </div>
    </div>
  `;
}

/**
 * Toggle accordion item open/closed
 */
function toggleInstructionAccordion(itemId) {
  const item = document.querySelector(`[data-accordion-id="${itemId}"]`);
  if (item) {
    item.classList.toggle('open');
  }
}

// ========================================
// GENERIC MODAL HELPERS
// ========================================

function openGenericModal(title, bodyHTML) {
  document.getElementById('generic-modal-title').textContent = title;
  document.getElementById('generic-modal-body').innerHTML = bodyHTML;
  document.getElementById('generic-modal').classList.add('active');
}

function closeGenericModal() {
  document.getElementById('generic-modal').classList.remove('active');
  document.getElementById('generic-modal-body').innerHTML = '';
  const modalContentEl = document.querySelector('#generic-modal .modal-content');
  if (modalContentEl) modalContentEl.classList.remove('modal-content--full-height');
}

// ========================================
// REAL-TIME LISTENER
// ========================================

// Übungen in Echtzeit synchronisieren (curated + user exercises)
function setupExercisesListener() {
  let curatedExercises = [];
  let userExercises = [];

  function mergeAndUpdate() {
    const exerciseMap = new Map();
    for (const ex of curatedExercises) {
      exerciseMap.set(ex.id, ex);
    }
    for (const ex of userExercises) {
      exerciseMap.set(ex.id, ex);
    }
    allExercises = Array.from(exerciseMap.values());
    filterExercises();
  }

  onCollectionChange(exercisesCuratedCollection, (exercises) => {
    curatedExercises = exercises.map(mapExerciseToV3);
    mergeAndUpdate();
  });

  onCollectionChange(exercisesCollection, (exercises) => {
    userExercises = exercises.map(mapExerciseToV3);
    mergeAndUpdate();
  });
}

// ========================================
// BOTTOM SHEET INTEGRATION FOR EXERCISES
// ========================================

// State for multi-select inputs in exercise modal
let exerciseMuscleGroups = [];
let exerciseEquipment = [];

/**
 * Opens muscle groups bottom sheet
 */
function openMuscleGroupsBottomSheet() {
  const mn = getMuscleNames();
  const muscleOptions = [
    { value: 'chest', label: mn.chest, description: t('exercise.muscleDescriptions.chest'), icon: getMuscleIconPath('chest') },
    { value: 'back', label: mn.back, description: t('exercise.muscleDescriptions.back'), icon: getMuscleIconPath('back') },
    { value: 'biceps', label: mn.biceps, description: t('exercise.muscleDescriptions.biceps'), icon: getMuscleIconPath('biceps') },
    { value: 'triceps', label: mn.triceps, description: t('exercise.muscleDescriptions.triceps'), icon: getMuscleIconPath('triceps') },
    { value: 'shoulders', label: mn.shoulders, description: t('exercise.muscleDescriptions.shoulders'), icon: getMuscleIconPath('shoulders') },
    { value: 'core', label: mn.core, description: t('exercise.muscleDescriptions.core'), icon: getMuscleIconPath('core') },
    { value: 'legs', label: mn.legs, description: t('exercise.muscleDescriptions.legs'), icon: getMuscleIconPath('legs') },
    { value: 'full-body', label: mn['full-body'], description: t('exercise.muscleDescriptions.fullBody'), icon: getMuscleIconPath('full-body') }
  ];

  openBottomSheet({
    title: t('exercise.muscleFilter.selectTitle'),
    options: muscleOptions,
    selectedValues: exerciseMuscleGroups,
    enableSearch: true,
    searchPlaceholder: t('exercise.muscleFilter.searchPlaceholder'),
    fieldId: 'exercise-muscle-groups-wrapper',
    onConfirm: (selectedValues) => {
      exerciseMuscleGroups = selectedValues;
      renderExerciseMuscleGroupsInput();
    }
  });
}

/**
 * Opens equipment bottom sheet
 */
function openEquipmentBottomSheet() {
  const equipmentOptions = [
    { value: 'bodyweight', label: 'Bodyweight', description: 'Kein Equipment nötig' },
    { value: 'pull-up-bar', label: 'Klimmzugstange', description: 'Für Klimmzüge und Hanging-Übungen' },
    { value: 'barbell', label: 'Langhantel', description: 'Langhantel-Training' },
    { value: 'dumbbell', label: 'Kurzhantel', description: 'Kurzhantel-Training' },
    { value: 'resistance-bands', label: 'Widerstandsbänder', description: 'Für Assistance oder zusätzlichen Widerstand' },
    { value: 'gym-machine', label: 'Maschine', description: 'Geräte im Fitnessstudio' },
    { value: 'parallettes', label: 'Paralettes', description: 'Für L-Sits, Handstands und Push-Ups' },
    { value: 'rings', label: 'Ringe', description: 'Gymnastikringe für instabiles Training' },
    { value: 'bench', label: 'Bank', description: 'Flach-/Schrägbank' }
  ];

  openBottomSheet({
    title: 'Equipment auswählen',
    options: equipmentOptions,
    selectedValues: exerciseEquipment,
    enableSearch: true,
    searchPlaceholder: 'Equipment suchen...',
    fieldId: 'exercise-equipment-wrapper',
    onConfirm: (selectedValues) => {
      exerciseEquipment = selectedValues;
      renderExerciseEquipmentInput();
    }
  });
}

/**
 * Renders the muscle groups multi-select input
 */
function renderExerciseMuscleGroupsInput() {
  renderMultiSelectInput('exercise-muscle-groups-wrapper', {
    icon: 'fitness_center',
    placeholder: t('exercise.muscleFilter.selectPlaceholder'),
    selectedValues: exerciseMuscleGroups,
    valueLabels: getMuscleNames()
  });
}

/**
 * Renders the equipment multi-select input
 */
function renderExerciseEquipmentInput() {
  renderMultiSelectInput('exercise-equipment-wrapper', {
    icon: 'build',
    placeholder: 'Equipment auswählen...',
    selectedValues: exerciseEquipment,
    valueLabels: equipmentNames
  });
}

/**
 * Removes a muscle group chip
 */
function removeMultiSelectChip(containerId, value) {
  if (containerId === 'exercise-muscle-groups-wrapper') {
    exerciseMuscleGroups = exerciseMuscleGroups.filter(v => v !== value);
    renderExerciseMuscleGroupsInput();
  } else if (containerId === 'exercise-equipment-wrapper') {
    exerciseEquipment = exerciseEquipment.filter(v => v !== value);
    renderExerciseEquipmentInput();
  }
}
