// ========================================
// EXERCISES MANAGEMENT
// ========================================

let allExercises = [];
let filteredExercises = [];
let editingExerciseId = null;
let exercisesExpanded = false;
let exerciseMuscleFilter = '';
let exerciseDifficultyFilter = '';

// V3 State
let exerciseType = 'strength';
let exercisePattern = 'full';
let exerciseVariants = [];
let exerciseNotes = '';
let exerciseVisual = null;
let exerciseStep2Expanded = false;
let exerciseCreateCallback = null;

// Muscle Group Namen Mapping
const muscleNames = {
  chest: 'Brust',
  back: 'Rücken',
  shoulders: 'Schultern',
  arms: 'Arme',
  core: 'Core',
  legs: 'Beine'
};

// Equipment Namen Mapping
const equipmentNames = {
  'none': 'Kein Equipment',
  'pull-up-bar': 'Klimmzugstange',
  'dip-bars': 'Dip-Barren',
  'rings': 'Ringe',
  'resistance-bands': 'Widerstandsbänder',
  'parallettes': 'Paralettes',
  'box': 'Box/Bank',
  'wall': 'Wand',
  'mat': 'Matte',
  'weights': 'Gewichte'
};

// Equipment Icons Mapping
const equipmentIcons = {
  'none': 'accessibility',
  'pull-up-bar': 'fitness_center',
  'dip-bars': 'sports_gymnastics',
  'rings': 'sports_gymnastics',
  'resistance-bands': 'cable',
  'parallettes': 'straighten',
  'box': 'square',
  'wall': 'wall',
  'mat': 'airline_seat_flat',
  'weights': 'fitness_center'
};

// ========================================
// EXERCISE V3 TYPE & PATTERN CONSTANTS
// ========================================

const exerciseTypes = {
  strength: { icon: 'fitness_center' },
  bodyweight: { icon: 'sports_gymnastics' },
  cardio: { icon: 'directions_run' },
  mobility: { icon: 'self_improvement' },
  recovery: { icon: 'spa' }
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
  const normalized = normalizeExerciseInstructions(exercise);

  // Type: default 'strength' for legacy
  const type = exercise.type && exerciseTypes[exercise.type] ? exercise.type : 'strength';

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
    icon: exercise.icon || 'fitness_center'
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
    pattern: v3.pattern || 'full',
    difficulty: v3.difficulty || 'intermediate',
    instructionsSteps: v3.instructions || [],
    muscleGroups: v3.muscleGroups || [],
    equipment: v3.equipment?.length ? v3.equipment : ['none'],
    icon: v3.icon || 'fitness_center'
  };

  // Optional fields - only write if non-empty
  if (v3.visual) doc.visual = v3.visual;
  if (v3.variants?.length) doc.variants = v3.variants;
  if (v3.notes) doc.notes = v3.notes;
  if (v3.setupNotes) doc.setupNotes = v3.setupNotes;
  if (v3.cues?.length) doc.cues = v3.cues;
  if (v3.commonMistakes?.length) doc.commonMistakes = v3.commonMistakes;
  if (v3.progressions?.length) doc.progressions = v3.progressions;

  return doc;
}

// ========================================
// LOAD & DISPLAY EXERCISES
// ========================================

async function loadExercises() {
  try {
    const exercises = await getAllDocs(exercisesCollection);
    allExercises = exercises.map(mapExerciseToV3);
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
    const initial = getExerciseInitial(exercise.name);
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
        <div class="empty-state-actions">
          <button onclick="resetFilters()" class="empty-state-btn btn-secondary">
            <span class="material-symbols-rounded">refresh</span>
            <span>Filter zuruecksetzen</span>
          </button>
          <button onclick="openExerciseCreateSheet()" class="empty-state-btn btn-primary">
            <span class="material-symbols-rounded">add_circle</span>
            <span>${t('exercise.createNew')}</span>
          </button>
        </div>
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
  // Visual: small thumbnail or placeholder icon
  const visualHTML = exercise.visual && exercise.visual.value
    ? `<img src="${exercise.visual.value}" alt="" class="exercise-list-visual" loading="lazy">`
    : `<div class="exercise-list-visual-placeholder">
        <span class="material-symbols-rounded">${exercise.icon || 'fitness_center'}</span>
      </div>`;

  // Meta line: type + pattern (subdued)
  const typeLabel = t('exercise.type.' + exercise.type) || exercise.type || '';
  const patternLabel = t('exercise.pattern.' + exercise.pattern) || exercise.pattern || '';
  const metaText = typeLabel && patternLabel ? (typeLabel + ' \u00B7 ' + patternLabel) : (typeLabel || patternLabel);

  return `
    <div class="exercise-list-row${isLast ? ' is-last' : ''}" onclick="viewExerciseDetails('${exercise.id}')">
      ${visualHTML}
      <div class="exercise-list-text">
        <span class="exercise-list-name">${exercise.name}</span>
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

  filteredExercises = allExercises.filter(exercise => {
    // Search filter – Name hat Prioritaet, dann type/pattern/difficulty
    let matchesSearch = true;
    if (searchLower) {
      const nameLower = (exercise.name || '').toLocaleLowerCase('de-DE');
      if (nameLower.includes(searchLower)) {
        matchesSearch = true;
      } else {
        const typeLabel = (t('exercise.type.' + exercise.type) || '').toLocaleLowerCase('de-DE');
        const patternLabel = (t('exercise.pattern.' + exercise.pattern) || '').toLocaleLowerCase('de-DE');
        const diffLabel = (t('difficulty.' + exercise.difficulty) || '').toLocaleLowerCase('de-DE');
        matchesSearch = typeLabel.includes(searchLower) ||
                        patternLabel.includes(searchLower) ||
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

    return matchesSearch && matchesMuscle && matchesDifficulty;
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

function updateExerciseFiltersUI() {
  const muscleContainer = document.getElementById('exercise-muscle-filters');
  if (muscleContainer) {
    muscleContainer.querySelectorAll('.filter-chip').forEach(btn => {
      const value = btn.dataset.muscle || '';
      btn.classList.toggle('active', value === exerciseMuscleFilter);
    });
  }

  const difficultyContainer = document.getElementById('exercise-difficulty-filters');
  if (difficultyContainer) {
    difficultyContainer.querySelectorAll('.filter-chip').forEach(btn => {
      const value = btn.dataset.difficulty || '';
      btn.classList.toggle('active', value === exerciseDifficultyFilter);
    });
  }

  const allMusclesLabel = document.getElementById('exercise-filter-muscle-all');
  if (allMusclesLabel) allMusclesLabel.textContent = t('exercise.filters.allMuscles');
  const chestLabel = document.getElementById('exercise-filter-muscle-chest');
  if (chestLabel) chestLabel.textContent = muscleNames.chest;
  const backLabel = document.getElementById('exercise-filter-muscle-back');
  if (backLabel) backLabel.textContent = muscleNames.back;
  const shouldersLabel = document.getElementById('exercise-filter-muscle-shoulders');
  if (shouldersLabel) shouldersLabel.textContent = muscleNames.shoulders;
  const armsLabel = document.getElementById('exercise-filter-muscle-arms');
  if (armsLabel) armsLabel.textContent = muscleNames.arms;
  const coreLabel = document.getElementById('exercise-filter-muscle-core');
  if (coreLabel) coreLabel.textContent = muscleNames.core;
  const legsLabel = document.getElementById('exercise-filter-muscle-legs');
  if (legsLabel) legsLabel.textContent = muscleNames.legs;

  const allDifficultyLabel = document.getElementById('exercise-filter-difficulty-all');
  if (allDifficultyLabel) allDifficultyLabel.textContent = t('exercise.filters.allDifficulties');
  const beginnerLabel = document.getElementById('exercise-filter-difficulty-beginner');
  if (beginnerLabel) beginnerLabel.textContent = t('difficulty.beginner');
  const intermediateLabel = document.getElementById('exercise-filter-difficulty-intermediate');
  if (intermediateLabel) intermediateLabel.textContent = t('difficulty.intermediate');
  const advancedLabel = document.getElementById('exercise-filter-difficulty-advanced');
  if (advancedLabel) advancedLabel.textContent = t('difficulty.advanced');
  const eliteLabel = document.getElementById('exercise-filter-difficulty-elite');
  if (eliteLabel) eliteLabel.textContent = t('difficulty.elite');
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
  updateExerciseFiltersUI();
  filterExercises();
}

// Active Filter Pills
function updateActiveFilters() {
  const searchInput = document.getElementById('search-input');
  const searchTerm = searchInput ? searchInput.value : '';
  const muscleFilter = exerciseMuscleFilter;
  const difficultyFilter = exerciseDifficultyFilter;

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
        <span>${muscleNames[muscleFilter]}</span>
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
  setExercisePattern('full');
  exerciseVariants = [];
  exerciseNotes = '';
  exerciseVisual = null;
  renderVariants();
  renderVisualInput();

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

  document.getElementById('modal-title').textContent = t('exercise.title') + ' bearbeiten';
  document.getElementById('exercise-name').value = exercise.name;

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
  setExercisePattern(exercise.pattern || 'full');
  exerciseVariants = exercise.variants ? exercise.variants.map(v => ({...v})) : [];
  exerciseNotes = exercise.notes || '';
  exerciseVisual = exercise.visual ? {...exercise.visual} : null;
  renderVariants();
  renderVisualInput();

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
    exerciseVariants.length > 0 || exerciseNotes || exerciseVisual ||
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
  document.getElementById('exercise-modal').classList.remove('active');
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
  exercisePattern = 'full';
  exerciseVariants = [];
  exerciseNotes = '';
  exerciseVisual = null;
  const notesInput = document.getElementById('exercise-notes');
  if (notesInput) notesInput.value = '';

  editingExerciseId = null;
}

// ========================================
// DIFFICULTY SELECTION (Enum-based)
// ========================================

// Difficulty enum mapping (for backward compatibility)
const exerciseDifficultyEnum = {
  beginner: { label: 'Anfaenger', value: 1 },
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

function setExercisePattern(pattern) {
  exercisePattern = pattern;
  const hidden = document.getElementById('exercise-pattern');
  if (hidden) hidden.value = pattern;
  document.querySelectorAll('#exercise-pattern-pills .difficulty-pill').forEach(pill => {
    pill.classList.toggle('active', pill.dataset.pattern === pattern);
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

// --- Visual ---

function renderVisualInput() {
  const container = document.getElementById('exercise-visual-container');
  if (!container) return;

  if (exerciseVisual && exerciseVisual.value) {
    container.innerHTML = `
      <div class="exercise-visual-preview">
        <img src="${exerciseVisual.value}" alt="" class="exercise-visual-preview-img"
          onerror="this.style.display='none'">
        <button type="button" class="exercise-visual-remove" onclick="removeExerciseVisual()">
          <span class="material-symbols-rounded">close</span>
          <span>${t('exercise.visualRemove')}</span>
        </button>
      </div>`;
  } else {
    container.innerHTML = `
      <div class="exercise-visual-add">
        <button type="button" class="btn-secondary exercise-visual-add-btn" onclick="showVisualUrlInput()">
          <span class="material-symbols-rounded">add_photo_alternate</span>
          <span>${t('exercise.visualAdd')}</span>
        </button>
        <div id="exercise-visual-url-input" style="display:none;" class="mt-2">
          <input type="url" id="exercise-visual-url"
            class="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-pink-500"
            placeholder="${t('exercise.visualUrlPlaceholder')}"
            onchange="setVisualFromUrl(this.value)">
        </div>
      </div>`;
  }
}

function showVisualUrlInput() {
  const urlInput = document.getElementById('exercise-visual-url-input');
  if (urlInput) {
    urlInput.style.display = 'block';
    const input = document.getElementById('exercise-visual-url');
    if (input) input.focus();
  }
}

function setVisualFromUrl(url) {
  const trimmed = (url || '').trim();
  if (!trimmed) return;
  try {
    new URL(trimmed);
  } catch {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Keine gueltige URL');
    }
    return;
  }
  exerciseVisual = { kind: 'url', value: trimmed };
  renderVisualInput();
}

function removeExerciseVisual() {
  exerciseVisual = null;
  renderVisualInput();
}

// --- Inline Create Hook ---

function openExerciseCreateSheet(options) {
  exerciseCreateCallback = (options && options.onCreated) ? options.onCreated : null;
  openAddExerciseModal();
}

// ========================================
// EXERCISE INSTRUCTIONS (Steps + Advanced)
// ========================================

let exerciseInstructionSteps = []; // string[] fuer nummerierte Schritte
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
  const pattern = document.getElementById('exercise-pattern')?.value || 'full';
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
      showEdgeFeedback('error', t('errors.exerciseNameRequired') || 'Bitte gib einen Namen fuer die Uebung ein!');
    }
    return;
  }

  // Build v3 data and map to Firestore format
  const v3Data = {
    name, type, pattern, difficulty, icon,
    instructions: instructionsSteps,
    muscleGroups, equipment,
    visual: exerciseVisual,
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
      showEdgeFeedback('error', 'Fehler beim Speichern der Uebung!');
    }
  }
}

// ========================================
// VIEW EXERCISE DETAILS
// ========================================

function viewExerciseDetails(id) {
  const exercise = allExercises.find(ex => ex.id === id);
  if (!exercise) return;

  const difficultyValue = convertDifficultyToEnum(exercise.difficulty);
  const typeLabel = t('exercise.type.' + exercise.type) || exercise.type || '';
  const patternLabel = t('exercise.pattern.' + exercise.pattern) || exercise.pattern || '';
  const difficultyLabel = t('difficulty.' + difficultyValue) || difficultyValue;
  const normalizedInstructions = normalizeExerciseInstructions(exercise);

  // Visual section (large)
  const visualHTML = exercise.visual && exercise.visual.value
    ? `<div class="exercise-detail-visual">
        <img src="${exercise.visual.value}" alt="${exercise.name}" class="exercise-detail-visual-img"
          onerror="this.parentElement.style.display='none'">
      </div>`
    : '';

  // Chips: Type, Pattern, Difficulty
  const chipsHTML = `
    <div class="exercise-detail-chips">
      <span class="exercise-chip">${typeLabel}</span>
      <span class="exercise-chip">${patternLabel}</span>
      <span class="exercise-chip">${difficultyLabel}</span>
    </div>
  `;

  // Instructions
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

  // Variants
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

  // Notes
  const notesHTML = exercise.notes
    ? `<div class="exercise-detail-block">
        <div class="exercise-detail-block-title">
          <span class="material-symbols-rounded">notes</span>
          <span>${t('exercise.notesLabel')}</span>
        </div>
        <p class="instruction-text">${exercise.notes}</p>
      </div>`
    : '';

  // Advanced sections (cues, mistakes, progressions, setup)
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

  // Muscle groups + equipment (de-emphasized footer)
  const muscleLabel = (exercise.muscleGroups || []).map(m => muscleNames[m]).filter(Boolean).join(', ');
  const equipmentLabel = (exercise.equipment || []).filter(eq => eq && eq !== 'none')
    .map(eq => equipmentNames[eq]).filter(Boolean).join(', ');

  const metaFooterHTML = (muscleLabel || equipmentLabel) ? `
    <div class="exercise-detail-meta-footer">
      ${muscleLabel ? '<div class="exercise-detail-chip"><span class="material-symbols-rounded">sports_gymnastics</span><span>' + muscleLabel + '</span></div>' : ''}
      ${equipmentLabel ? '<div class="exercise-detail-chip"><span class="material-symbols-rounded">build</span><span>' + equipmentLabel + '</span></div>' : ''}
    </div>` : '';

  const modalContent = `
    <div class="exercise-detail">
      ${visualHTML}

      <div class="exercise-detail-header">
        <div class="exercise-detail-title">${exercise.name}</div>
        ${chipsHTML}
      </div>

      <div class="exercise-detail-block">
        <div class="exercise-detail-block-title">
          <span class="material-symbols-rounded">format_list_numbered</span>
          <span>${t('exercise.instructions.title')}</span>
        </div>
        ${stepsHtml}
      </div>

      ${variantsHTML}
      ${notesHTML}
      ${metaFooterHTML}

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

      <div class="exercise-detail-actions">
        <button onclick="closeGenericModal(); editExercise('${exercise.id}')" class="btn-primary">
          <span class="material-symbols-rounded">edit</span>
          ${t('common.edit')}
        </button>
        <button onclick="closeGenericModal()" class="btn-secondary">
          <span class="material-symbols-rounded">close</span>
          ${t('common.close')}
        </button>
      </div>
    </div>
  `;

  openGenericModal(exercise.name, modalContent);
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
}

// ========================================
// REAL-TIME LISTENER
// ========================================

// Übungen in Echtzeit synchronisieren
function setupExercisesListener() {
  onCollectionChange(exercisesCollection, (exercises) => {
    allExercises = exercises.map(mapExerciseToV3);
    filterExercises();
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
  const muscleOptions = [
    { value: 'chest', label: 'Brust', description: 'Brustmuskulatur' },
    { value: 'back', label: 'Rücken', description: 'Rückenmuskulatur' },
    { value: 'shoulders', label: 'Schultern', description: 'Schultermuskulatur' },
    { value: 'arms', label: 'Arme', description: 'Bizeps, Trizeps, Unterarme' },
    { value: 'core', label: 'Core', description: 'Bauch- und Rumpfmuskulatur' },
    { value: 'legs', label: 'Beine', description: 'Beinmuskulatur' }
  ];

  openBottomSheet({
    title: 'Muskelgruppen auswählen',
    options: muscleOptions,
    selectedValues: exerciseMuscleGroups,
    enableSearch: true,
    searchPlaceholder: 'Muskelgruppe suchen...',
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
    { value: 'none', label: 'Kein Equipment', description: 'Bodyweight Training' },
    { value: 'pull-up-bar', label: 'Klimmzugstange', description: 'Für Klimmzüge und Hanging-Übungen' },
    { value: 'dip-bars', label: 'Dip-Barren', description: 'Für Dips und Support-Holds' },
    { value: 'rings', label: 'Ringe', description: 'Gymnastikringe für instabiles Training' },
    { value: 'resistance-bands', label: 'Widerstandsbänder', description: 'Für Assistance oder zusätzlichen Widerstand' },
    { value: 'parallettes', label: 'Paralettes', description: 'Für L-Sits, Handstands und Push-Ups' },
    { value: 'box', label: 'Box/Bank', description: 'Erhöhte Plattform für Step-Ups, Box Jumps' },
    { value: 'wall', label: 'Wand', description: 'Für Handstand und Wall-Sits' },
    { value: 'mat', label: 'Matte', description: 'Für Bodenübungen' },
    { value: 'weights', label: 'Gewichte', description: 'Kurz- oder Langhanteln' }
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
    placeholder: 'Muskelgruppen auswählen...',
    selectedValues: exerciseMuscleGroups,
    valueLabels: muscleNames
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
