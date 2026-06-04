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
  renderVariants();

  // Collapse step 2
  exerciseStep2Expanded = false;
  const content = document.getElementById('exercise-step2-content');
  const toggle = document.getElementById('exercise-step2-toggle');
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
  renderVariants();

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
    exerciseVariants.length > 0 ||
    hasAdvancedContent;
  exerciseStep2Expanded = hasStep2Content;
  const contentEl = document.getElementById('exercise-step2-content');
  const toggle = document.getElementById('exercise-step2-toggle');
  if (hasStep2Content) {
    if (contentEl) contentEl.classList.remove('collapsed');
    if (toggle) toggle.style.transform = 'rotate(180deg)';
  } else {
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
  const content = document.getElementById('exercise-step2-content');
  const toggle = document.getElementById('exercise-step2-toggle');
  if (exerciseStep2Expanded) {
    if (content) content.classList.remove('collapsed');
    if (toggle) toggle.style.transform = 'rotate(180deg)';
  } else {
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
