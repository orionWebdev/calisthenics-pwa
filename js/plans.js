// ========================================
// PLANS MANAGEMENT
// ========================================

let allPlans = [];
let filteredPlans = [];
let editingPlanId = null;
let currentPlan = null; // Currently selected plan for editing

// Workout Type Namen Mapping (nur noch 3 Typen)
const workoutTypeNames = {
  strength: t('plan.types.strength'),
  cardio: t('plan.types.cardio'),
  recovery: t('plan.types.recovery'),
  unknown: t('plan.types.unknown')
};

// Cardio Goal Namen Mapping
const cardioGoalNames = {
  liss: 'LISS',
  hiit: 'HIIT',
  zone2: 'Zone 2',
  tempo: 'Tempo'
};

// Tag Namen Mapping
const tagNames = {
  'full-body': 'Ganzkörper',
  'upper-body': 'Oberkörper',
  'lower-body': 'Unterkörper',
  'push': 'Push',
  'pull': 'Pull',
  'legs': 'Beine',
  'core': 'Core'
};

const legacyPlanTypeMap = {
  strength: 'strength',
  kraft: 'strength',
  krafttraining: 'strength',
  strengthtraining: 'strength',
  cardio: 'cardio',
  ausdauer: 'cardio',
  endurance: 'cardio',
  recovery: 'recovery',
  erholung: 'recovery',
  regeneration: 'recovery',
  mobility: 'recovery',
  skill: 'strength',
  hiit: 'cardio',
  mixed: 'strength'
};

const planTypeIconFallbacks = {
  strength: 'fitness_center',
  cardio: 'directions_run',
  recovery: 'self_improvement',
  unknown: 'help'
};

function normalizePlanType(rawType) {
  if (!rawType || typeof rawType !== 'string') {
    return { type: 'strength', displayType: 'strength', wasLegacy: false, wasUnknown: false };
  }

  const normalizedKey = rawType.trim().toLowerCase();
  const mapped = legacyPlanTypeMap[normalizedKey];

  if (mapped) {
    return {
      type: mapped,
      displayType: mapped,
      wasLegacy: normalizedKey !== mapped,
      wasUnknown: false
    };
  }

  return {
    type: 'strength',
    displayType: 'unknown',
    wasLegacy: true,
    wasUnknown: true
  };
}

function normalizePlan(plan) {
  const typeInfo = normalizePlanType(plan.type);
  const normalizedPlan = {
    ...plan,
    type: typeInfo.type,
    displayType: typeInfo.displayType,
    typeLabel: typeInfo.displayType === 'unknown'
      ? workoutTypeNames.unknown
      : workoutTypeNames[typeInfo.displayType] || workoutTypeNames.strength
  };

  if (typeInfo.wasLegacy) {
    console.warn('WARN Legacy plan type mapped', {
      planId: plan.id,
      from: plan.type,
      to: typeInfo.type
    });
  }

  if (typeInfo.wasUnknown) {
    console.warn('WARN Unknown plan type fallback', {
      planId: plan.id,
      from: plan.type
    });
  }

  return normalizedPlan;
}

function getPlanTypeLabel(plan) {
  return plan.typeLabel || workoutTypeNames[plan.displayType] || workoutTypeNames[plan.type] || workoutTypeNames.strength;
}

function getPlanIconKey(plan, fallbackType) {
  const fallback = planTypeIconFallbacks[fallbackType] || planTypeIconFallbacks.strength;
  return plan.iconKey || plan.icon || fallback;
}

function getPlanGoalLabel(plan) {
  const goal = plan.cardioGoal || plan.goal;
  if (!goal) return '';
  return cardioGoalNames[goal] || goal;
}

// ========================================
// LOAD & DISPLAY PLANS
// ========================================

async function loadPlans() {
  try {
    const plans = await getAllDocs(plansCollection);
    allPlans = plans.map(normalizePlan);
    filteredPlans = [...allPlans];
    renderPlans();
  } catch (error) {
    console.error('Error loading plans:', error);
  }
}

function renderPlans() {
  const grid = document.getElementById('plans-grid');

  if (filteredPlans.length == 0) {
    grid.innerHTML = `
      <div class="col-span-full empty-state">
        <div class="empty-state-icon">
          <span class="material-symbols-rounded">assignment</span>
        </div>
        <h3 class="empty-state-title">Keine Trainingsplaene gefunden</h3>
        <p class="empty-state-text">Erstelle deinen ersten Trainingsplan!</p>
        <button onclick="openAddPlanModal()" class="empty-state-btn">
          <span class="material-symbols-rounded">add_circle</span>
          <span>Plan erstellen</span>
        </button>
      </div>
    `;
    return;
  }

  grid.innerHTML = filteredPlans.map(plan => {
    const exerciseCount = plan.exercises ? plan.exercises.length : 0;
    const equipment = plan.requiredEquipment || [];
    const equipmentCount = equipment.length;
    const planType = plan.type || 'strength';
    const displayType = plan.displayType || planType;
    const typeLabel = getPlanTypeLabel(plan);
    const typeIcon = getPlanIconKey(plan, planType);
    const goalLabel = getPlanGoalLabel(plan);
    const metaParts = [
      `${exerciseCount} Uebungen`,
      `${plan.duration || 45} Min`,
      goalLabel
    ].filter(Boolean);

    return `
      <div class="plan-row-card" onclick="viewPlanDetails('${plan.id}')">
        <div class="plan-row-icon">
          <span class="material-symbols-rounded">${typeIcon}</span>
        </div>
        <div class="plan-row-content">
          <div class="plan-row-title">${plan.name}</div>
          <div class="plan-row-meta">${metaParts.join(' • ')}</div>
          <div class="plan-row-tags">
            <span class="plan-type-badge type-${displayType}">${typeLabel}</span>
            ${equipmentCount > 0 && equipment[0] !== 'none' ? `<span class="plan-row-tag"><span class="material-symbols-rounded">build</span>${equipmentCount}</span>` : ''}
          </div>
        </div>
        <div class="plan-row-actions">
          <button
            onclick="event.stopPropagation(); startWorkoutFromPlan('${plan.id}')"
            class="plan-row-start-btn"
            title="Workout starten"
          >
            <span class="material-symbols-rounded">play_arrow</span>
          </button>
          <button
            onclick="event.stopPropagation(); editPlan('${plan.id}')"
            class="plan-row-action-btn"
            title="Bearbeiten"
          >
            <span class="material-symbols-rounded">edit</span>
          </button>
        </div>
      </div>
    `;
  }).join('');
}


// ========================================
// MODAL MANAGEMENT
// ========================================

function openAddPlanModal() {
  editingPlanId = null;
  currentPlan = {
    exercises: []
  };
  document.getElementById('plan-modal-title').textContent = 'Neuer Trainingsplan';
  clearPlanForm();

  // Initialize multi-select inputs
  planTags = [];
  planTargetMuscles = [];
  renderPlanTagsInput();
  renderPlanTargetMusclesInput();

  document.getElementById('plan-modal').classList.add('active');
}

function editPlan(id) {
  editingPlanId = id;
  const plan = allPlans.find(p => p.id === id);

  if (!plan) return;

  currentPlan = { ...plan };
  document.getElementById('plan-modal-title').textContent = 'Plan bearbeiten';
  populatePlanForm(plan);
  document.getElementById('plan-modal').classList.add('active');
}

function closePlanModal() {
  document.getElementById('plan-modal').classList.remove('active');
  clearPlanForm();
  currentPlan = null;
}

function clearPlanForm() {
  document.getElementById('plan-name').value = '';
  document.getElementById('plan-type').value = 'strength';
  document.getElementById('plan-duration').value = '45';
  const notesEl = document.getElementById('plan-notes');
  if (notesEl) notesEl.value = '';

  // Clear multi-select inputs
  planTags = [];
  planTargetMuscles = [];

  setPlanDifficulty('intermediate');
  setPlanIcon('fitness_center');
  setPlanDiscipline('bodyweight');
  setCardioGoal('liss');

  // Trigger type change to show correct fields
  onPlanTypeChange('strength');

  // Clear exercises list
  if (currentPlan) {
    currentPlan.exercises = [];
  }
  renderPlanExercises();
}

function populatePlanForm(plan) {
  document.getElementById('plan-name').value = plan.name || '';
  document.getElementById('plan-type').value = plan.type || 'strength';
  document.getElementById('plan-duration').value = plan.duration || 45;
  const notesEl = document.getElementById('plan-notes');
  if (notesEl) notesEl.value = plan.notes || '';

  // Set tags and target muscles for multi-select
  planTags = plan.tags ? [...plan.tags] : [];
  planTargetMuscles = plan.targetMuscles ? [...plan.targetMuscles] : [];

  // Render multi-select inputs
  renderPlanTagsInput();
  renderPlanTargetMusclesInput();

  // Type-specific fields
  if (plan.type === 'strength') {
    const difficultyValue = convertPlanDifficultyToEnum(plan.difficulty);
    setPlanDifficulty(difficultyValue);
    setPlanDiscipline(plan.discipline || 'bodyweight');
  } else if (plan.type === 'cardio') {
    setCardioGoal(plan.cardioGoal || 'liss');
  }

  // Icon
  setPlanIcon(plan.iconKey || 'fitness_center');

  // Trigger type change to show correct fields
  onPlanTypeChange(plan.type || 'strength');

  // Load exercises
  if (plan.exercises) {
    currentPlan.exercises = [...plan.exercises];
    renderPlanExercises();
  }
}

// ========================================
// DIFFICULTY SELECTION (Enum-based)
// ========================================

// Difficulty enum mapping
const planDifficultyEnum = {
  beginner: { label: 'Anfaenger', value: 1 },
  intermediate: { label: 'Mittel', value: 2 },
  advanced: { label: 'Fortgeschritten', value: 3 },
  elite: { label: 'Elite', value: 4 }
};

function setPlanDifficulty(difficulty) {
  document.getElementById('plan-difficulty').value = difficulty;

  // Support both compact (.difficulty-pill) and full (.difficulty-pill-full) pills
  document.querySelectorAll('#plan-modal .difficulty-pill, #plan-modal .difficulty-pill-full').forEach(pill => {
    pill.classList.toggle('active', pill.dataset.difficulty === difficulty);
  });
}

// Convert old numeric difficulty to new enum
function convertPlanDifficultyToEnum(difficulty) {
  if (typeof difficulty === 'string') return difficulty;
  if (difficulty <= 1) return 'beginner';
  if (difficulty <= 2) return 'intermediate';
  if (difficulty <= 3) return 'advanced';
  return 'elite';
}

// ========================================
// PLAN ICON SELECTION
// ========================================

function setPlanIcon(icon) {
  const iconInput = document.getElementById('plan-icon');
  if (iconInput) iconInput.value = icon;

  document.querySelectorAll('#plan-icon-picker .icon-picker-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.icon === icon);
  });
}

// ========================================
// PLAN DISCIPLINE SELECTION (Bodyweight vs Weights)
// ========================================

function setPlanDiscipline(discipline) {
  const disciplineInput = document.getElementById('plan-discipline');
  if (disciplineInput) disciplineInput.value = discipline;

  document.querySelectorAll('.discipline-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.discipline === discipline);
  });
}

// ========================================
// WIZARD SECTION MANAGEMENT
// ========================================

/**
 * Toggle a collapsible wizard section
 */
function toggleWizardSection(sectionId) {
  const section = document.getElementById(sectionId);
  if (section) {
    section.classList.toggle('open');
  }
}

/**
 * Handle plan type change - adjust form visibility and defaults
 * Nur 3 Typen: strength, cardio, recovery
 */
function onPlanTypeChange(type) {
  const exercisesSection = document.getElementById('plan-exercises-section');
  const musclesSection = document.getElementById('plan-muscles-section');
  const tagsSection = document.getElementById('plan-tags-section');
  const detailsSection = document.getElementById('plan-details-section');
  const durationInput = document.getElementById('plan-duration');
  const disciplineSection = document.getElementById('plan-discipline-section');
  const difficultySection = document.getElementById('plan-difficulty-section');
  const cardioGoalSection = document.getElementById('plan-cardio-goal-section');

  // Helper to show/hide elements
  const show = (el) => { if (el) el.style.display = ''; };
  const hide = (el) => { if (el) el.style.display = 'none'; };

  // Hide all type-specific sections first
  hide(exercisesSection);
  hide(musclesSection);
  hide(tagsSection);
  hide(detailsSection);
  hide(disciplineSection);
  hide(difficultySection);
  hide(cardioGoalSection);

  // Apply type-specific visibility and defaults
  switch (type) {
    case 'cardio':
      // Cardio: Cardio-Ziel statt Schwierigkeit, keine Übungen
      show(cardioGoalSection);
      if (durationInput) durationInput.value = '30';
      break;

    case 'recovery':
      // Recovery: Nur Name, Dauer, Icon - keine Schwierigkeit, keine Übungen
      if (durationInput) durationInput.value = '20';
      break;

    case 'strength':
    default:
      // Strength: Alle Felder inkl. Übungen, Schwierigkeit, Discipline
      show(exercisesSection);
      show(musclesSection);
      show(tagsSection);
      show(detailsSection);
      show(disciplineSection);
      show(difficultySection);
      if (durationInput) durationInput.value = '45';
      break;
  }
}

/**
 * Set cardio goal (LISS, HIIT, Zone2, Tempo)
 */
function setCardioGoal(goal) {
  const input = document.getElementById('plan-cardio-goal');
  if (input) input.value = goal;

  document.querySelectorAll('.cardio-goal-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.goal === goal);
  });
}

// ========================================
// PLAN EXERCISES MANAGEMENT
// ========================================

function renderPlanExercises() {
  const container = document.getElementById('plan-exercises-list');

  if (!container) return;

  if (!currentPlan || !currentPlan.exercises || currentPlan.exercises.length === 0) {
    container.innerHTML = `
      <div class="text-center py-8 text-gray-400">
        <span class="material-symbols-rounded" style="font-size: 48px;">fitness_center</span>
        <p class="mt-2">Noch keine Übungen hinzugefügt</p>
        <p class="text-sm">Füge Übungen aus der Datenbank hinzu</p>
      </div>
    `;
    return;
  }

  // Safety check: ensure allExercises is available
  if (typeof allExercises === 'undefined' || !allExercises) {
    container.innerHTML = `
      <div class="text-center py-8 text-gray-400">
        <span class="material-symbols-rounded" style="font-size: 48px;">hourglass_empty</span>
        <p class="mt-2">Lade Übungen...</p>
      </div>
    `;
    return;
  }

  container.innerHTML = currentPlan.exercises.map((ex, index) => {
    const exercise = allExercises.find(e => e.id === ex.exerciseId);
    if (!exercise) return '';

    return `
      <div class="plan-exercise-item" draggable="true" data-index="${index}">
        <!-- Drag Handle -->
        <div class="plan-exercise-drag-handle">
          <span class="material-symbols-rounded">drag_indicator</span>
        </div>

        <!-- Exercise Info -->
        <div class="plan-exercise-info">
          <h4 class="font-semibold">${exercise.name}</h4>
          <p class="text-xs text-gray-400">${ex.sets} Sätze × ${ex.reps || ex.hold || '-'}</p>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-2">
          <button onclick="event.stopPropagation(); editPlanExercise(${index})" class="text-gray-400 hover:text-primary transition-colors">
            <span class="material-symbols-rounded" style="font-size: 20px;">edit</span>
          </button>
          <button onclick="event.stopPropagation(); removePlanExercise(${index})" class="text-gray-400 hover:text-red-500 transition-colors">
            <span class="material-symbols-rounded" style="font-size: 20px;">delete</span>
          </button>
        </div>
      </div>
    `;
  }).join('');

  // Setup drag and drop
  setupDragAndDrop();
}

// Exercise Picker Filter State
let exercisePickerSearchTerm = '';
let exercisePickerMuscleFilter = 'all';
let exercisePickerSearchDebounce = null;

function openAddExerciseToPlan() {
  // Reset filters
  exercisePickerSearchTerm = '';
  exercisePickerMuscleFilter = 'all';
  document.getElementById('exercise-picker-search').value = '';

  // Set active chip
  document.querySelectorAll('#exercise-picker-modal .filter-chip').forEach(chip => {
    chip.classList.toggle('active', chip.dataset.filter === 'all');
  });

  // Show exercise picker modal
  document.getElementById('exercise-picker-modal').classList.add('active');

  // Setup search input listener
  const searchInput = document.getElementById('exercise-picker-search');
  searchInput.removeEventListener('input', handleExercisePickerSearch);
  searchInput.addEventListener('input', handleExercisePickerSearch);

  renderExercisePicker();
}

function handleExercisePickerSearch(e) {
  const searchValue = e.target.value;
  const clearBtn = document.getElementById('exercise-picker-search-clear');

  // Show/hide clear button
  clearBtn.style.display = searchValue ? 'flex' : 'none';

  // Debounce search
  if (exercisePickerSearchDebounce) {
    clearTimeout(exercisePickerSearchDebounce);
  }

  exercisePickerSearchDebounce = setTimeout(() => {
    exercisePickerSearchTerm = searchValue.toLowerCase().trim();
    renderExercisePicker();
  }, 300);
}

function clearExercisePickerSearch() {
  const searchInput = document.getElementById('exercise-picker-search');
  searchInput.value = '';
  searchInput.focus();
  document.getElementById('exercise-picker-search-clear').style.display = 'none';
  exercisePickerSearchTerm = '';
  renderExercisePicker();
}

function setExercisePickerMuscleFilter(muscle) {
  exercisePickerMuscleFilter = muscle;

  // Update active chip
  document.querySelectorAll('#exercise-picker-modal .filter-chip').forEach(chip => {
    chip.classList.toggle('active', chip.dataset.filter === muscle);
  });

  renderExercisePicker();
}

function renderExercisePicker() {
  const container = document.getElementById('exercise-picker-list');
  const filterInfo = document.getElementById('exercise-picker-filter-info');

  if (!container) return;

  // Safety check: ensure allExercises is available
  if (typeof allExercises === 'undefined' || !allExercises || allExercises.length === 0) {
    container.innerHTML = `
      <div class="text-center py-8 text-gray-400">
        <span class="material-symbols-rounded" style="font-size: 48px;">fitness_center</span>
        <p class="mt-2">Keine Übungen verfügbar</p>
        <p class="text-sm">Erstelle zuerst Übungen in der Übungsdatenbank</p>
      </div>
    `;
    return;
  }

  // Filter exercises
  let filteredExercises = allExercises.filter(exercise => {
    // Search filter
    const matchesSearch = !exercisePickerSearchTerm ||
      exercise.name.toLowerCase().includes(exercisePickerSearchTerm) ||
      (exercise.description && exercise.description.toLowerCase().includes(exercisePickerSearchTerm));

    // Muscle group filter
    const matchesMuscle = exercisePickerMuscleFilter === 'all' ||
      exercise.muscleGroups.includes(exercisePickerMuscleFilter);

    return matchesSearch && matchesMuscle;
  });

  // Update filter info
  if (exercisePickerSearchTerm || exercisePickerMuscleFilter !== 'all') {
    const filterText = [];
    if (exercisePickerSearchTerm) {
      filterText.push(`Suche: "${exercisePickerSearchTerm}"`);
    }
    if (exercisePickerMuscleFilter !== 'all') {
      filterText.push(`Muskelgruppe: ${muscleNames[exercisePickerMuscleFilter]}`);
    }
    filterInfo.textContent = `${filteredExercises.length} von ${allExercises.length} Übungen gefunden (${filterText.join(', ')})`;
    filterInfo.style.display = 'block';
  } else {
    filterInfo.style.display = 'none';
  }

  // Render exercises
  if (filteredExercises.length === 0) {
    container.innerHTML = `
      <div class="text-center py-8 text-gray-400">
        <span class="material-symbols-rounded" style="font-size: 48px;">search_off</span>
        <p class="mt-2">Keine Übungen gefunden</p>
        <p class="text-sm">Versuche einen anderen Suchbegriff oder Filter</p>
      </div>
    `;
    return;
  }

  container.innerHTML = filteredExercises.map(exercise => {
    const equipmentList = (exercise.equipment || []).filter(eq => eq && eq !== 'none');
    const equipmentLabel = equipmentList.length > 0
      ? equipmentList.map(eq => equipmentNames[eq]).filter(Boolean).join(', ')
      : '';
    const primaryMuscle = exercise.muscleGroups[0];
    const muscleLabel = muscleNames[primaryMuscle] || 'Muskel';
    const iconKey = equipmentList[0] || 'none';
    const iconName = equipmentIcons[iconKey] || 'fitness_center';
    const discipline = exercise.discipline || 'calisthenics';
    const disciplineIcon = discipline === 'gym' ? 'fitness_center' : discipline === 'both' ? 'layers' : 'sports_gymnastics';

    return `
      <div class="exercise-row-card is-picker" onclick="selectExerciseForPlan('${exercise.id}')">
        <div class="exercise-row-accent muscle-${primaryMuscle || 'default'}"></div>
        <div class="exercise-row-icon">
          <span class="material-symbols-rounded">${iconName}</span>
        </div>
        <div class="exercise-row-content">
          <div class="exercise-row-title">${exercise.name}</div>
          <div class="exercise-row-meta">${muscleLabel}${equipmentLabel ? ` ? ${equipmentLabel}` : ''}</div>
        </div>
        <div class="exercise-row-discipline" title="${discipline}">
          <span class="material-symbols-rounded">${disciplineIcon}</span>
        </div>
        <button class="exercise-row-action" onclick="event.stopPropagation(); selectExerciseForPlan('${exercise.id}')">
          <span class="material-symbols-rounded">add_circle</span>
        </button>
      </div>
    `;
  }).join('');
}

function selectExerciseForPlan(exerciseId) {
  // Close picker
  document.getElementById('exercise-picker-modal').classList.remove('active');

  // Open exercise config modal
  openExerciseConfigModal(exerciseId);
}

function openExerciseConfigModal(exerciseId, editIndex = null) {
  const exercise = allExercises.find(e => e.id === exerciseId);
  if (!exercise) return;

  // Store for later
  document.getElementById('exercise-config-modal').dataset.exerciseId = exerciseId;
  document.getElementById('exercise-config-modal').dataset.editIndex = editIndex !== null ? editIndex : '';

  // Populate form
  document.getElementById('exercise-config-name').textContent = exercise.name;

  // If editing, load existing config
  if (editIndex !== null && currentPlan.exercises[editIndex]) {
    const ex = currentPlan.exercises[editIndex];
    document.getElementById('exercise-sets').value = ex.sets || 3;
    document.getElementById('exercise-reps').value = ex.reps || '';
    document.getElementById('exercise-hold').value = ex.hold || '';
    document.getElementById('exercise-rest').value = ex.rest || 90;
    document.getElementById('exercise-notes').value = ex.notes || '';
  } else {
    // Default values
    document.getElementById('exercise-sets').value = 3;
    document.getElementById('exercise-reps').value = '12';
    document.getElementById('exercise-hold').value = '';
    document.getElementById('exercise-rest').value = 90;
    document.getElementById('exercise-notes').value = '';
  }

  document.getElementById('exercise-config-modal').classList.add('active');
}

function saveExerciseConfig() {
  const modal = document.getElementById('exercise-config-modal');
  const exerciseId = modal.dataset.exerciseId;
  const editIndex = modal.dataset.editIndex;

  const exerciseConfig = {
    exerciseId,
    sets: parseInt(document.getElementById('exercise-sets').value) || 3,
    reps: document.getElementById('exercise-reps').value || null,
    hold: document.getElementById('exercise-hold').value || null,
    rest: parseInt(document.getElementById('exercise-rest').value) || 90,
    notes: document.getElementById('exercise-notes').value || ''
  };

  if (editIndex !== '') {
    // Update existing
    currentPlan.exercises[parseInt(editIndex)] = exerciseConfig;
  } else {
    // Add new
    if (!currentPlan.exercises) {
      currentPlan.exercises = [];
    }
    currentPlan.exercises.push(exerciseConfig);
  }

  closeExerciseConfigModal();
  renderPlanExercises();
}

function closeExerciseConfigModal() {
  document.getElementById('exercise-config-modal').classList.remove('active');
}

function editPlanExercise(index) {
  const ex = currentPlan.exercises[index];
  openExerciseConfigModal(ex.exerciseId, index);
}

function removePlanExercise(index) {
  if (confirm('Übung aus dem Plan entfernen?')) {
    currentPlan.exercises.splice(index, 1);
    renderPlanExercises();
  }
}

function closeExercisePicker() {
  document.getElementById('exercise-picker-modal').classList.remove('active');
}

// ========================================
// NATIVE MOBILE INPUT HELPERS
// ========================================

/**
 * Updates the rest time display when slider changes
 */
function updateRestDisplay(value) {
  const seconds = parseInt(value);
  const displaySpan = document.getElementById('exercise-rest-display');

  if (seconds === 0) {
    displaySpan.textContent = 'Keine Pause';
  } else if (seconds < 60) {
    displaySpan.textContent = `${seconds} Sek`;
  } else {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    if (remainingSeconds === 0) {
      displaySpan.textContent = `${minutes} Min`;
    } else {
      displaySpan.textContent = `${minutes}:${remainingSeconds.toString().padStart(2, '0')} Min`;
    }
  }

  // Trigger haptic feedback on value change
  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('light');
  }
}

// ========================================
// DRAG AND DROP
// ========================================

let draggedIndex = null;

function setupDragAndDrop() {
  const items = document.querySelectorAll('.plan-exercise-item');

  items.forEach((item, index) => {
    item.addEventListener('dragstart', (e) => {
      draggedIndex = index;
      item.classList.add('dragging');
    });

    item.addEventListener('dragend', (e) => {
      item.classList.remove('dragging');
      draggedIndex = null;
    });

    item.addEventListener('dragover', (e) => {
      e.preventDefault();
      const afterElement = getDragAfterElement(item.parentElement, e.clientY);
      const dragging = document.querySelector('.dragging');

      if (afterElement == null) {
        item.parentElement.appendChild(dragging);
      } else {
        item.parentElement.insertBefore(dragging, afterElement);
      }
    });

    item.addEventListener('drop', (e) => {
      e.preventDefault();
      if (draggedIndex !== null) {
        const targetIndex = parseInt(item.dataset.index);
        reorderPlanExercises(draggedIndex, targetIndex);
      }
    });
  });
}

function getDragAfterElement(container, y) {
  const draggableElements = [...container.querySelectorAll('.plan-exercise-item:not(.dragging)')];

  return draggableElements.reduce((closest, child) => {
    const box = child.getBoundingClientRect();
    const offset = y - box.top - box.height / 2;

    if (offset < 0 && offset > closest.offset) {
      return { offset: offset, element: child };
    } else {
      return closest;
    }
  }, { offset: Number.NEGATIVE_INFINITY }).element;
}

function reorderPlanExercises(fromIndex, toIndex) {
  const [removed] = currentPlan.exercises.splice(fromIndex, 1);
  currentPlan.exercises.splice(toIndex, 0, removed);
  renderPlanExercises();
}

// ========================================
// SAVE PLAN
// ========================================

async function savePlan() {
  const name = document.getElementById('plan-name').value.trim();
  const type = document.getElementById('plan-type').value;
  const duration = parseInt(document.getElementById('plan-duration').value);
  const notes = document.getElementById('plan-notes')?.value.trim() || '';
  const iconKey = document.getElementById('plan-icon')?.value || 'fitness_center';

  // Validation - Name ist immer erforderlich
  if (!name) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('errors.planNameRequired') || 'Bitte gib einen Namen fuer den Plan ein!');
    }
    return;
  }

  // Build plan data based on type
  const planData = {
    name,
    type,
    duration,
    iconKey
  };

  // Type-specific fields
  switch (type) {
    case 'strength':
      // Strength: exercises required, difficulty, discipline, tags, muscles
      if (!currentPlan.exercises || currentPlan.exercises.length === 0) {
        if (typeof showEdgeFeedback === 'function') {
          showEdgeFeedback('error', t('errors.planExercisesRequired') || 'Bitte fuege mindestens eine Uebung hinzu!');
        }
        return;
      }

      const difficulty = document.getElementById('plan-difficulty')?.value || 'intermediate';
      const discipline = document.getElementById('plan-discipline')?.value || 'bodyweight';

      // Calculate required equipment from exercises
      const requiredEquipment = new Set();
      if (typeof allExercises !== 'undefined' && allExercises && currentPlan.exercises) {
        currentPlan.exercises.forEach(ex => {
          const exercise = allExercises.find(e => e.id === ex.exerciseId);
          if (exercise && exercise.equipment) {
            exercise.equipment.forEach(eq => requiredEquipment.add(eq));
          }
        });
      }

      planData.difficulty = difficulty;
      planData.discipline = discipline;
      planData.tags = planTags || [];
      planData.targetMuscles = planTargetMuscles || [];
      planData.exercises = currentPlan.exercises || [];
      planData.requiredEquipment = Array.from(requiredEquipment);
      planData.notes = notes;
      break;

    case 'cardio':
      // Cardio: cardioGoal statt difficulty, keine exercises
      const cardioGoal = document.getElementById('plan-cardio-goal')?.value || 'liss';
      planData.cardioGoal = cardioGoal;
      planData.exercises = [];
      planData.notes = notes;
      break;

    case 'recovery':
      // Recovery: nur Basics - keine difficulty, keine exercises
      planData.exercises = [];
      planData.notes = notes;
      break;
  }

  try {
    if (editingPlanId) {
      await updateDoc(plansCollection, editingPlanId, planData);
      console.log('✅ Plan updated!');
    } else {
      await addDoc(plansCollection, planData);
      console.log('✅ Plan added!');
    }

    closePlanModal();
    await loadPlans();
  } catch (error) {
    console.error('Error saving plan:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Speichern des Plans.');
    }
  }
}

// ========================================
// VIEW PLAN DETAILS
// ========================================

function viewPlanDetails(id) {
  const plan = allPlans.find(p => p.id === id);
  if (!plan) return;

  // Safety check: ensure allExercises is available
  if (typeof allExercises === 'undefined' || !allExercises) {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Übungen werden noch geladen. Bitte versuche es gleich nochmal.');
  }
    return;
  }

  // Build exercises list HTML
  let exercisesHTML = '';
  if (plan.exercises && plan.exercises.length > 0) {
    exercisesHTML = plan.exercises.map((ex, index) => {
      const exercise = allExercises.find(e => e.id === ex.exerciseId);
      if (!exercise) return '';

      return `
        <div class="plan-detail-exercise-item">
          <div class="flex items-start gap-3">
            <div class="plan-exercise-number">${index + 1}</div>
            <div class="flex-1">
              <h4 class="font-semibold text-white">${exercise.name}</h4>
              <div class="flex flex-wrap gap-3 mt-2 text-sm text-gray-400">
                <span class="flex items-center gap-1">
                  <span class="material-symbols-rounded" style="font-size: 16px;">repeat</span>
                  ${ex.sets} Sätze
                </span>
                ${ex.reps ?
                  `<span class="flex items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 16px;">fitness_center</span>
                    ${ex.reps} Wdh
                  </span>`
                  : ''
                }
                ${ex.hold ?
                  `<span class="flex items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 16px;">timer</span>
                    ${ex.hold}
                  </span>`
                  : ''
                }
                ${ex.rest ?
                  `<span class="flex items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 16px;">hourglass_empty</span>
                    ${ex.rest}s Pause
                  </span>`
                  : ''
                }
              </div>
              ${ex.notes ?
                `<p class="text-xs text-gray-500 mt-2 italic">${ex.notes}</p>`
                : ''
              }
            </div>
          </div>
        </div>
      `;
    }).join('');
  }

  // Get difficulty info
  const difficultyValue = convertPlanDifficultyToEnum(plan.difficulty);
  const difficultyInfo = planDifficultyEnum[difficultyValue] || planDifficultyEnum.intermediate;

  // Modal content
  const modalContent = `
    <div class="space-y-4">
      <!-- Type & Duration -->
      <div class="flex items-center justify-between">
        <span class="plan-type-badge type-${plan.displayType || plan.type}">${getPlanTypeLabel(plan)}</span>
        <span class="text-sm text-gray-400">
          <span class="material-symbols-rounded" style="font-size: 16px; vertical-align: middle;">schedule</span>
          ${plan.duration || 45} Minuten
        </span>
      </div>

      <!-- Difficulty -->
      <div>
        <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
          <span class="material-symbols-rounded" style="font-size: 18px;">signal_cellular_alt</span>
          Schwierigkeit
        </label>
        <span class="difficulty-badge ${difficultyValue}">${difficultyInfo.label}</span>
      </div>

      <!-- Target Muscles -->
      ${plan.targetMuscles && plan.targetMuscles.length > 0 ?
        `<div>
          <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
            <span class="material-symbols-rounded" style="font-size: 18px;">sports_gymnastics</span>
            Trainierte Muskelgruppen
          </label>
          <div class="flex flex-wrap gap-2">
            ${plan.targetMuscles.map(muscle =>
              `<span class="muscle-tag">${muscleNames[muscle]}</span>`
            ).join('')}
          </div>
        </div>`
        : ''
      }

      <!-- Required Equipment -->
      ${plan.requiredEquipment && plan.requiredEquipment.length > 0 && plan.requiredEquipment[0] !== 'none' ?
        `<div>
          <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
            <span class="material-symbols-rounded" style="font-size: 18px;">build</span>
            Benötigtes Equipment
          </label>
          <div class="flex flex-wrap gap-2">
            ${plan.requiredEquipment.map(eq =>
              `<span class="inline-flex items-center gap-1 px-3 py-1 bg-gray-700 border border-gray-600 rounded-lg text-sm">
                <span class="material-symbols-rounded" style="font-size: 16px; color: var(--color-primary);">${equipmentIcons[eq]}</span>
                ${equipmentNames[eq]}
              </span>`
            ).join('')}
          </div>
        </div>`
        : ''
      }

      <!-- Notes -->
      ${plan.notes ?
        `<div>
          <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
            <span class="material-symbols-rounded" style="font-size: 18px;">description</span>
            Notizen
          </label>
          <p class="text-gray-300 leading-relaxed">${plan.notes}</p>
        </div>`
        : ''
      }

      <!-- Exercises -->
      <div>
        <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-3">
          <span class="material-symbols-rounded" style="font-size: 18px;">fitness_center</span>
          Übungen (${plan.exercises ? plan.exercises.length : 0})
        </label>
        <div class="space-y-2">
          ${exercisesHTML}
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex gap-3 pt-4">
        <button
          onclick="closeGenericModal(); editPlan('${plan.id}')"
          class="flex-1 bg-gradient-to-r from-pink-600 to-pink-700 hover:from-pink-500 hover:to-pink-600 py-3 rounded-xl font-semibold transition-all flex items-center justify-center gap-2"
        >
          <span class="material-symbols-rounded" style="font-size: 20px;">edit</span>
          Bearbeiten
        </button>
        <button
          onclick="closeGenericModal()"
          class="flex-1 bg-gray-700 hover:bg-gray-600 py-3 rounded-xl font-semibold transition-colors flex items-center justify-center gap-2"
        >
          <span class="material-symbols-rounded" style="font-size: 20px;">close</span>
          Schließen
        </button>
      </div>
    </div>
  `;

  openGenericModal(plan.name, modalContent);
}

// ========================================
// REAL-TIME LISTENER
// ========================================

function setupPlansListener() {
  onCollectionChange(plansCollection, (plans) => {
    allPlans = plans.map(normalizePlan);
    filteredPlans = [...allPlans];
    renderPlans();
  });
}

// ========================================
// BOTTOM SHEET INTEGRATION FOR PLANS
// ========================================

// State for multi-select inputs in plan modal
let planTags = [];
let planTargetMuscles = [];

/**
 * Opens plan tags bottom sheet
 */
function openPlanTagsBottomSheet() {
  const tagOptions = [
    { value: 'full-body', label: 'Ganzkörper', description: 'Training für den gesamten Körper' },
    { value: 'upper-body', label: 'Oberkörper', description: 'Fokus auf Oberkörper' },
    { value: 'lower-body', label: 'Unterkörper', description: 'Fokus auf Unterkörper' },
    { value: 'push', label: 'Push', description: 'Drückende Bewegungen' },
    { value: 'pull', label: 'Pull', description: 'Ziehende Bewegungen' },
    { value: 'legs', label: 'Beine', description: 'Bein-Training' },
    { value: 'core', label: 'Core', description: 'Rumpf-Training' }
  ];

  openBottomSheet({
    title: 'Tags auswählen',
    options: tagOptions,
    selectedValues: planTags,
    enableSearch: true,
    searchPlaceholder: 'Tags suchen...',
    fieldId: 'plan-tags-wrapper',
    onConfirm: (selectedValues) => {
      planTags = selectedValues;
      renderPlanTagsInput();
    }
  });
}

/**
 * Opens plan target muscles bottom sheet
 */
function openPlanTargetMusclesBottomSheet() {
  const muscleOptions = [
    { value: 'chest', label: 'Brust', description: 'Brustmuskulatur' },
    { value: 'back', label: 'Rücken', description: 'Rückenmuskulatur' },
    { value: 'shoulders', label: 'Schultern', description: 'Schultermuskulatur' },
    { value: 'arms', label: 'Arme', description: 'Bizeps, Trizeps, Unterarme' },
    { value: 'legs', label: 'Beine', description: 'Beinmuskulatur' },
    { value: 'core', label: 'Core', description: 'Bauch- und Rumpfmuskulatur' }
  ];

  openBottomSheet({
    title: 'Ziel-Muskelgruppen auswählen',
    options: muscleOptions,
    selectedValues: planTargetMuscles,
    enableSearch: true,
    searchPlaceholder: 'Muskelgruppe suchen...',
    fieldId: 'plan-target-muscles-wrapper',
    onConfirm: (selectedValues) => {
      planTargetMuscles = selectedValues;
      renderPlanTargetMusclesInput();
    }
  });
}

/**
 * Renders the plan tags multi-select input
 */
function renderPlanTagsInput() {
  renderMultiSelectInput('plan-tags-wrapper', {
    icon: 'label',
    placeholder: 'Tags auswählen...',
    selectedValues: planTags,
    valueLabels: tagNames
  });
}

/**
 * Renders the plan target muscles multi-select input
 */
function renderPlanTargetMusclesInput() {
  renderMultiSelectInput('plan-target-muscles-wrapper', {
    icon: 'fitness_center',
    placeholder: 'Ziel-Muskelgruppen auswählen...',
    selectedValues: planTargetMuscles,
    valueLabels: muscleNames
  });
}

/**
 * Global removeMultiSelectChip handler for plans
 * (extends the one in exercises.js)
 */
const originalRemoveMultiSelectChip = window.removeMultiSelectChip;
window.removeMultiSelectChip = function(containerId, value) {
  if (containerId === 'plan-tags-wrapper') {
    planTags = planTags.filter(v => v !== value);
    renderPlanTagsInput();
  } else if (containerId === 'plan-target-muscles-wrapper') {
    planTargetMuscles = planTargetMuscles.filter(v => v !== value);
    renderPlanTargetMusclesInput();
  } else if (originalRemoveMultiSelectChip) {
    originalRemoveMultiSelectChip(containerId, value);
  }
};
