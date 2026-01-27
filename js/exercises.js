// ========================================
// EXERCISES MANAGEMENT
// ========================================

let allExercises = [];
let filteredExercises = [];
let editingExerciseId = null;
let exercisesExpanded = false;

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
// LOAD & DISPLAY EXERCISES
// ========================================

async function loadExercises() {
  try {
    const exercises = await getAllDocs(exercisesCollection);
    allExercises = exercises.map(normalizeExerciseForRuntime);
    filteredExercises = [...allExercises];
    renderExercises();
  } catch (error) {
    console.error('Error loading exercises:', error);
  }
}

function renderExercises() {
  const grid = document.getElementById('exercises-grid');

  if (filteredExercises.length === 0) {
    grid.innerHTML = `
      <div class="col-span-full empty-state">
        <div class="empty-state-icon">
          <span class="material-symbols-rounded">search_off</span>
        </div>
        <h3 class="empty-state-title">Keine Übungen gefunden</h3>
        <p class="empty-state-text">Versuche einen anderen Suchbegriff oder Filter</p>
        <button onclick="resetFilters()" class="empty-state-btn">
          <span class="material-symbols-rounded">refresh</span>
          <span>Filter zurücksetzen</span>
        </button>
      </div>
    `;
    return;
  }

  const sortedExercises = [...filteredExercises].sort((a, b) => (a.name || '').localeCompare(b.name || ''));
  const visibleExercises = exercisesExpanded ? sortedExercises : sortedExercises.slice(0, 8);

  const exerciseCards = visibleExercises.map(exercise => {
    const primaryMuscle = exercise.muscleGroups[0];
    const muscleLabel = muscleNames[primaryMuscle] || 'Muskel';
    const allMuscles = exercise.muscleGroups.map(muscle => muscleNames[muscle]).filter(Boolean).join(', ');
    const equipmentList = (exercise.equipment || []).filter(eq => eq && eq !== 'none');
    const equipmentLabel = equipmentList.length > 0
      ? equipmentList.map(eq => equipmentNames[eq]).filter(Boolean).join(', ')
      : '';
    const iconKey = equipmentList[0] || 'none';
    const iconName = equipmentIcons[iconKey] || 'fitness_center';
    const discipline = exercise.discipline || 'calisthenics';
    const disciplineIcon = discipline === 'gym' ? 'fitness_center' : discipline === 'both' ? 'layers' : 'sports_gymnastics';

    return `
      <div class="exercise-row-card" id="exercise-card-${exercise.id}" onclick="viewExerciseDetails('${exercise.id}')">
        <div class="exercise-row-accent muscle-${primaryMuscle || 'default'}"></div>
        <div class="exercise-row-icon">
          <span class="material-symbols-rounded">${iconName}</span>
        </div>
        <div class="exercise-row-content">
          <div class="exercise-row-title">${exercise.name}</div>
          <div class="exercise-row-meta">${allMuscles}${equipmentLabel ? ` ? ${equipmentLabel}` : ''}</div>
        </div>
        <div class="exercise-row-discipline" title="${discipline}">
          <span class="material-symbols-rounded">${disciplineIcon}</span>
        </div>
        <div class="exercise-row-chevron">
          <span class="material-symbols-rounded">chevron_right</span>
        </div>
      </div>
    `;
  }).join('');

  const toggleButton = sortedExercises.length > 8
    ? `
      <button class="exercise-toggle-btn col-span-full" onclick="toggleExercisesExpanded()">
        <span>${exercisesExpanded ? 'Weniger anzeigen' : 'Alle anzeigen'}</span>
        <span class="material-symbols-rounded">${exercisesExpanded ? 'expand_less' : 'expand_more'}</span>
      </button>
    `
    : '';

  grid.innerHTML = exerciseCards + toggleButton;
}

// Toggle Exercise Card Expansion
function toggleExerciseCard(id) {
  viewExerciseDetails(id);
}

// ========================================
// FILTER & SEARCH
// ========================================

function filterExercises() {
  const searchTerm = document.getElementById('search-input').value.toLowerCase();
  const muscleFilter = document.getElementById('muscle-filter').value;
  const difficultyFilter = document.getElementById('difficulty-filter').value;

  filteredExercises = allExercises.filter(exercise => {
    // Search filter
    const matchesSearch = exercise.name.toLowerCase().includes(searchTerm) ||
                         (exercise.description && exercise.description.toLowerCase().includes(searchTerm));

    // Muscle filter
    const matchesMuscle = !muscleFilter || exercise.muscleGroups.includes(muscleFilter);

    // Difficulty filter - handle both enum strings and legacy numeric values
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

function toggleExercisesExpanded() {
  exercisesExpanded = !exercisesExpanded;
  renderExercises();
}

function resetFilters() {
  document.getElementById('search-input').value = '';
  document.getElementById('muscle-filter').value = '';
  document.getElementById('difficulty-filter').value = '';
  filterExercises();
}

// Active Filter Pills
function updateActiveFilters() {
  const searchTerm = document.getElementById('search-input').value;
  const muscleFilter = document.getElementById('muscle-filter').value;
  const difficultyFilter = document.getElementById('difficulty-filter').value;

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
        <span>Level ${difficultyFilter}</span>
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
  document.getElementById('search-input').value = '';
  filterExercises();
}

function clearMuscleFilter() {
  document.getElementById('muscle-filter').value = '';
  filterExercises();
}

function clearDifficultyFilter() {
  document.getElementById('difficulty-filter').value = '';
  filterExercises();
}

// ========================================
// MODAL MANAGEMENT
// ========================================

function openAddExerciseModal() {
  editingExerciseId = null;
  document.getElementById('modal-title').textContent = 'Neue Übung';
  clearExerciseForm();
  if (exerciseInstructionSteps.length === 0) {
    addInstructionStep();
  }

  // Initialize multi-select inputs
  exerciseMuscleGroups = [];
  exerciseEquipment = [];
  renderExerciseMuscleGroupsInput();
  renderExerciseEquipmentInput();

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
  editingExerciseId = null;
}

// ========================================
// DIFFICULTY SELECTION (Enum-based)
// ========================================

// Difficulty enum mapping (for backward compatibility)
const exerciseDifficultyEnum = {
  beginner: { label: 'Anfaenger', value: 1 },
  intermediate: { label: 'Mittel', value: 2 },
  advanced: { label: 'Fortgeschritten', value: 3 },
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
  const difficulty = document.getElementById('exercise-difficulty').value;
  const icon = document.getElementById('exercise-icon').value || 'fitness_center';

  // Get instructions as string[] (nummerierte Schritte)
  const instructionsSteps = getCleanInstructionSteps();
  const cues = getCleanInstructionList('cues');
  const commonMistakes = getCleanInstructionList('mistakes');
  const progressions = getCleanInstructionList('progressions');
  const setupNotesInput = document.getElementById('exercise-setup-notes');
  const setupNotes = setupNotesInput ? setupNotesInput.value.trim() : '';

  // Get selected muscle groups and equipment from state
  const muscleGroups = exerciseMuscleGroups;
  const equipment = exerciseEquipment.length > 0 ? exerciseEquipment : ['none'];

  // Validation
  if (!name) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('errors.exerciseNameRequired') || 'Bitte gib einen Namen fuer die Uebung ein!');
    }
    return;
  }

  if (muscleGroups.length === 0) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('errors.muscleGroupsRequired') || 'Bitte waehle mindestens eine Muskelgruppe!');
    }
    return;
  }

  const exerciseData = {
    name,
    instructionsSteps,
    muscleGroups,
    equipment,
    difficulty,
    icon,
    ...(setupNotes ? { setupNotes } : {}),
    ...(cues.length ? { cues } : {}),
    ...(commonMistakes.length ? { commonMistakes } : {}),
    ...(progressions.length ? { progressions } : {})
  };

  try {
    if (editingExerciseId) {
      // Update existing
      await updateDoc(exercisesCollection, editingExerciseId, exerciseData);
      console.log('✅ Exercise updated!');
    } else {
      // Add new
      await addDoc(exercisesCollection, exerciseData);
      console.log('✅ Exercise added!');
    }

    closeExerciseModal();
    await loadExercises();
  } catch (error) {
    console.error('Error saving exercise:', error);
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Fehler beim Speichern der Übung!');
  }
  }
}

// ========================================
// VIEW EXERCISE DETAILS
// ========================================

function viewExerciseDetails(id) {
  const exercise = allExercises.find(ex => ex.id === id);
  if (!exercise) return;

  // Modal-Inhalt erstellen
  const equipmentLabel = (exercise.equipment || []).filter(eq => eq && eq !== 'none')
    .map(eq => equipmentNames[eq])
    .filter(Boolean)
    .join(', ') || 'Kein Equipment';
  const muscleLabel = exercise.muscleGroups.map(muscle => muscleNames[muscle]).filter(Boolean).join(', ');
  const normalizedInstructions = normalizeExerciseInstructions(exercise);
  const difficultyValue = convertDifficultyToEnum(exercise.difficulty);
  const difficultyInfo = exerciseDifficultyEnum[difficultyValue] || exerciseDifficultyEnum.intermediate;
  const exerciseIcon = exercise.icon || 'fitness_center';

  const stepsHtml = normalizedInstructions.instructionsSteps.length > 0
    ? `
      <ol class="instruction-steps-list">
        ${normalizedInstructions.instructionsSteps.map((step, index) => `
          <li>
            <span class="instruction-step-index">${index + 1}.</span>
            <span>${step}</span>
          </li>
        `).join('')}
      </ol>
    `
    : `<p class="instruction-empty">${t('exercise.instructions.noSteps')}</p>`;

  const advancedSections = [
    normalizedInstructions.cues.length > 0
      ? renderInstructionAccordionSection('tips_and_updates', t('exercise.instructions.advanced.cues'),
        `<ul class="instruction-list">
          ${normalizedInstructions.cues.map(item => `<li>${item}</li>`).join('')}
        </ul>`)
      : '',
    normalizedInstructions.commonMistakes.length > 0
      ? renderInstructionAccordionSection('warning', t('exercise.instructions.advanced.mistakes'),
        `<ul class="instruction-list">
          ${normalizedInstructions.commonMistakes.map(item => `<li>${item}</li>`).join('')}
        </ul>`)
      : '',
    normalizedInstructions.progressions.length > 0
      ? renderInstructionAccordionSection('trending_up', t('exercise.instructions.advanced.progressions'),
        `<ul class="instruction-list">
          ${normalizedInstructions.progressions.map(item => `<li>${item}</li>`).join('')}
        </ul>`)
      : '',
    normalizedInstructions.setupNotes
      ? renderInstructionAccordionSection('tune', t('exercise.instructions.advanced.setup'),
        `<p class="instruction-text">${normalizedInstructions.setupNotes}</p>`, true)
      : ''
  ].filter(Boolean);

  const modalContent = `
    <div class="exercise-detail">
      <div class="exercise-detail-hero">
        <div class="exercise-detail-icon">
          <span class="material-symbols-rounded">${exerciseIcon}</span>
        </div>
        <div>
          <div class="exercise-detail-title">${exercise.name}</div>
          <div class="exercise-detail-subtitle">${muscleLabel || 'Ganzkoerper'} ? ${equipmentLabel}</div>
        </div>
      </div>

      <div class="exercise-detail-meta">
        <span class="difficulty-badge ${difficultyValue}">${difficultyInfo.label}</span>
        <div class="exercise-detail-chip">
          <span class="material-symbols-rounded">sports_gymnastics</span>
          <span>${muscleLabel || 'Ganzkoerper'}</span>
        </div>
        <div class="exercise-detail-chip">
          <span class="material-symbols-rounded">build</span>
          <span>${equipmentLabel}</span>
        </div>
      </div>

      <div class="exercise-detail-block">
        <div class="exercise-detail-block-title">
          <span class="material-symbols-rounded">format_list_numbered</span>
          <span>${t('exercise.instructions.title')}</span>
        </div>
        ${stepsHtml}
      </div>

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
        <button
          onclick="closeGenericModal(); editExercise('${exercise.id}')"
          class="btn-primary"
        >
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

  // Generic Modal ?ffnen öffnen
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
    allExercises = exercises.map(normalizeExerciseForRuntime);
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
