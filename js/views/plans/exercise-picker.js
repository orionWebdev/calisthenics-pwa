// ========================================
// PLAN EXERCISES MANAGEMENT
// ========================================

// Exercise Picker Filter State
let exercisePickerSearchTerm = '';
let exercisePickerMuscleFilter = 'all';
let exercisePickerSearchDebounce = null;
let exercisePickerSelectedIds = new Set();
let exercisePickerMode = 'multi'; // 'multi' for plans, 'single' for sessions

function openAddExerciseToPlan() {
  // Reset filters and selection
  exercisePickerSearchTerm = '';
  exercisePickerMuscleFilter = 'all';
  exercisePickerSelectedIds = new Set();
  exercisePickerMode = 'multi';
  document.getElementById('exercise-picker-search').value = '';

  // Set active chip
  document.querySelectorAll('#exercise-picker-modal .filter-chip').forEach(chip => {
    chip.classList.toggle('active', chip.dataset.filter === 'all');
  });

  // Show exercise picker modal
  document.getElementById('exercise-picker-modal').classList.add('active');
  document.body.classList.add('modal-open');

  // Setup search input listener
  const searchInput = document.getElementById('exercise-picker-search');
  searchInput.removeEventListener('input', handleExercisePickerSearch);
  searchInput.addEventListener('input', handleExercisePickerSearch);

  renderExercisePicker();
  updateExercisePickerAddButton();
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
        <p class="mt-2">${t('plan.exercisePicker.noExercisesTitle')}</p>
        <p class="text-sm">${t('plan.exercisePicker.noExercisesBody')}</p>
        <button onclick="openQuickExerciseCreate()" class="btn-primary mt-4">
          <span class="material-symbols-rounded">add_circle</span>
          <span>${t('exercise.quickCreate.button')}</span>
        </button>
      </div>
    `;
    return;
  }

  // Filter exercises
  let filteredExercises = allExercises.filter(exercise => {
    // Search filter
    const matchesSearch = !exercisePickerSearchTerm ||
      getExerciseName(exercise).toLowerCase().includes(exercisePickerSearchTerm) ||
      (exercise.name && exercise.name.toLowerCase().includes(exercisePickerSearchTerm)) ||
      (exercise.description && exercise.description.toLowerCase().includes(exercisePickerSearchTerm));

    // Muscle group filter — matches the exercise's PRIMARY muscle only
    const matchesMuscle = exercisePrimaryMatchesMuscle(exercise, exercisePickerMuscleFilter);

    return matchesSearch && matchesMuscle;
  });

  // Update filter info
  if (exercisePickerSearchTerm || exercisePickerMuscleFilter !== 'all') {
    const filterText = [];
    if (exercisePickerSearchTerm) {
      filterText.push(t('plan.exercisePicker.filterSearch', { term: exercisePickerSearchTerm }));
    }
    if (exercisePickerMuscleFilter !== 'all') {
      const mnMap = typeof getMuscleNames === 'function' ? getMuscleNames() : {};
      const muscleLabel = mnMap[exercisePickerMuscleFilter] || exercisePickerMuscleFilter;
      filterText.push(t('plan.exercisePicker.filterMuscle', { muscle: muscleLabel }));
    }
    filterInfo.textContent = t('plan.exercisePicker.filterInfo', {
      count: filteredExercises.length,
      total: allExercises.length,
      filters: filterText.join(', ')
    });
    filterInfo.style.display = 'block';
  } else {
    filterInfo.style.display = 'none';
  }

  // Render exercises
  if (filteredExercises.length === 0) {
    container.innerHTML = `
      <div class="text-center py-8 text-gray-400">
        <span class="material-symbols-rounded" style="font-size: 48px;">search_off</span>
        <p class="mt-2">${t('plan.exercisePicker.noResultsTitle')}</p>
        <p class="text-sm">${t('plan.exercisePicker.noResultsBody')}</p>
      </div>
    `;
    return;
  }

  const mnNames = typeof getMuscleNames === 'function' ? getMuscleNames() : {};
  const exerciseRows = filteredExercises.map(exercise => {
    const muscleLabel = (exercise.muscleGroups || [])
      .map(m => mnNames[m]).filter(Boolean).slice(0, 2).join(', ');
    const metaText = muscleLabel || t('exercise.type.' + (exercise.type || 'strength')) || '';

    if (exercisePickerMode === 'multi') {
      const isSelected = exercisePickerSelectedIds.has(exercise.id);
      return `
        <div class="exercise-row-card is-picker ${isSelected ? 'is-selected' : ''}" onclick="toggleExercisePickerSelection('${exercise.id}')">
          <div class="exercise-row-icon">
            ${getPrimaryMuscleIcon(exercise.muscleGroups, 'muscle-icon--md')}
          </div>
          <div class="exercise-row-content">
            <div class="exercise-row-title">${getExerciseName(exercise)}</div>
            <div class="exercise-row-meta">${metaText}</div>
          </div>
          <div class="exercise-picker-checkbox ${isSelected ? 'checked' : ''}">
            <span class="material-symbols-rounded">${isSelected ? 'check_circle' : 'radio_button_unchecked'}</span>
          </div>
        </div>
      `;
    } else {
      // Single-select mode (for sessions)
      return `
        <div class="exercise-row-card is-picker" onclick="selectExerciseForPlan('${exercise.id}')">
          <div class="exercise-row-icon">
            ${getPrimaryMuscleIcon(exercise.muscleGroups, 'muscle-icon--md')}
          </div>
          <div class="exercise-row-content">
            <div class="exercise-row-title">${getExerciseName(exercise)}</div>
            <div class="exercise-row-meta">${metaText}</div>
          </div>
          <button class="exercise-row-action" onclick="event.stopPropagation(); selectExerciseForPlan('${exercise.id}')">
            <span class="material-symbols-rounded">add_circle</span>
          </button>
        </div>
      `;
    }
  }).join('');

  // Add "Create new exercise" button at the TOP
  const createNewBtn = `
    <div class="exercise-picker-create-new" onclick="openQuickExerciseCreate()">
      <div class="exercise-picker-create-icon">
        <span class="material-symbols-rounded">add_circle</span>
      </div>
      <div class="exercise-picker-create-content">
        <div class="exercise-picker-create-title">${t('exercise.quickCreate.button')}</div>
        <div class="exercise-picker-create-hint">${t('exercise.quickCreate.hint')}</div>
      </div>
      <span class="material-symbols-rounded exercise-picker-create-chevron">chevron_right</span>
    </div>
  `;

  container.innerHTML = createNewBtn + exerciseRows;
}

// ========================================
// QUICK EXERCISE CREATE (Inline from Plan)
// ========================================

let quickExerciseCallback = null;

function openQuickExerciseCreate() {
  // V3: Delegate to shared exercise create flow with callback
  openExerciseCreateSheet({
    onCreated: (exerciseId) => {
      renderExercisePicker();
      if (exercisePickerMode === 'multi') {
        // Auto-select the newly created exercise
        exercisePickerSelectedIds.add(exerciseId);
        renderExercisePicker();
        updateExercisePickerAddButton();
      } else {
        selectExerciseForPlan(exerciseId);
      }
    }
  });
}

function closeQuickExerciseModal() {
  document.getElementById('quick-exercise-modal').classList.remove('active');
  quickExerciseCallback = null;
}

let quickExerciseMuscleGroups = [];

function openQuickExerciseMuscleSheet() {
  const mn = getMuscleNames();
  const muscleOptions = [
    { value: 'chest', label: mn.chest, description: t('exercise.muscleDescriptions.chest') },
    { value: 'back', label: mn.back, description: t('exercise.muscleDescriptions.back') },
    { value: 'shoulders', label: mn.shoulders, description: t('exercise.muscleDescriptions.shoulders') },
    { value: 'arms', label: mn.arms, description: t('exercise.muscleDescriptions.arms') },
    { value: 'biceps', label: mn.biceps, description: t('exercise.muscleDescriptions.biceps') },
    { value: 'triceps', label: mn.triceps, description: t('exercise.muscleDescriptions.triceps') },
    { value: 'core', label: mn.core, description: t('exercise.muscleDescriptions.core') },
    { value: 'legs', label: mn.legs, description: t('exercise.muscleDescriptions.legs') },
    { value: 'calf', label: mn.calf, description: t('exercise.muscleDescriptions.calf') }
  ];

  openBottomSheet({
    title: t('exercise.muscleGroups'),
    options: muscleOptions,
    selectedValues: quickExerciseMuscleGroups,
    enableSearch: false,
    fieldId: 'quick-exercise-muscles-wrapper',
    onConfirm: (selectedValues) => {
      quickExerciseMuscleGroups = selectedValues;
      renderQuickExerciseMuscleInput();
    }
  });
}

function renderQuickExerciseMuscleInput() {
  renderMultiSelectInput('quick-exercise-muscles-wrapper', {
    icon: 'fitness_center',
    placeholder: t('exercise.muscleGroups') + '...',
    selectedValues: quickExerciseMuscleGroups,
    valueLabels: getMuscleNames()
  });
}

function setQuickExerciseDifficulty(difficulty) {
  document.getElementById('quick-exercise-difficulty').value = difficulty;
  document.querySelectorAll('#quick-exercise-modal .difficulty-pill').forEach(pill => {
    pill.classList.toggle('active', pill.dataset.difficulty === difficulty);
  });
}

async function saveQuickExercise() {
  const name = document.getElementById('quick-exercise-name').value.trim();
  const difficulty = document.getElementById('quick-exercise-difficulty').value;

  if (!name) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('errors.exerciseNameRequired'));
    }
    return;
  }

  if (quickExerciseMuscleGroups.length === 0) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('errors.muscleGroupsRequired'));
    }
    return;
  }

  const exerciseData = {
    name,
    muscleGroups: quickExerciseMuscleGroups,
    equipment: ['none'],
    difficulty,
    icon: 'fitness_center',
    instructionsSteps: [],
    discipline: 'calisthenics'
  };

  try {
    const docRef = await addDoc(exercisesCollection, exerciseData);
    const newExerciseId = docRef.id;

    // Reload exercises
    await loadExercises();

    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', t('exercise.quickCreate.saved'));
    }

    closeQuickExerciseModal();

    // Execute callback to add to plan
    if (quickExerciseCallback) {
      quickExerciseCallback(newExerciseId);
    }
  } catch (error) {
    console.error('Error saving quick exercise:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('workoutModal.saveError'));
    }
  }
}

// Extend removeMultiSelectChip for quick exercise modal
const _originalRemoveMultiSelectChip = window.removeMultiSelectChip;
window.removeMultiSelectChip = function(containerId, value) {
  if (containerId === 'quick-exercise-muscles-wrapper') {
    quickExerciseMuscleGroups = quickExerciseMuscleGroups.filter(v => v !== value);
    renderQuickExerciseMuscleInput();
  } else if (_originalRemoveMultiSelectChip) {
    _originalRemoveMultiSelectChip(containerId, value);
  }
};

// ========================================
// PLAN PICKER BOTTOM SHEET
// ========================================

let planPickerCallback = null;
let planPickerTypeFilter = 'all';

function openPlanPickerSheet(onSelect) {
  planPickerCallback = onSelect;

  const planOptions = (allPlans || []).map(plan => ({
    value: plan.id,
    label: plan.name,
    type: normalizePlanType(plan.type).type,
    description: getPlanPickerDescription(plan),
    icon: getPlanIconValue(plan, plan.type)
  }));

  // Use custom rendering for plan picker
  openPlanPickerBottomSheet({
    title: t('plan.picker.title'),
    options: planOptions,
    searchPlaceholder: t('plan.picker.searchPlaceholder'),
    onSelect: (planId) => {
      if (planPickerCallback) {
        planPickerCallback(planId);
        planPickerCallback = null;
      }
    }
  });
}

function openPlanPickerBottomSheet(config) {
  const overlay = document.getElementById('plan-picker-overlay');
  const sheet = document.getElementById('plan-picker-sheet');
  const titleEl = document.getElementById('plan-picker-title');
  const searchInput = document.getElementById('plan-picker-search');
  const listEl = document.getElementById('plan-picker-list');

  if (!overlay || !sheet) return;

  // Store config
  sheet.dataset.config = JSON.stringify(config);

  // Set title
  titleEl.textContent = config.title || t('plan.picker.title');
  searchInput.placeholder = config.searchPlaceholder || t('plan.picker.searchPlaceholder');
  searchInput.value = '';

  // Reset type filter
  planPickerTypeFilter = 'all';
  const filterBtns = document.querySelectorAll('.plan-picker-filter-btn');
  filterBtns.forEach(btn => {
    btn.classList.toggle('active', btn.dataset.type === 'all');
    if (btn.dataset.i18n) btn.textContent = t(btn.dataset.i18n);
  });

  // Render options
  renderPlanPickerOptions(config.options, '', 'all');

  // Setup search
  searchInput.oninput = (e) => {
    const term = e.target.value.toLowerCase().trim();
    renderPlanPickerOptions(config.options, term, planPickerTypeFilter);
  };

  // Show
  overlay.classList.add('active');
  document.body.style.overflow = 'hidden';

  setTimeout(() => searchInput.focus(), 100);
}

function renderPlanPickerOptions(options, searchTerm, typeFilter) {
  const listEl = document.getElementById('plan-picker-list');
  typeFilter = typeFilter || 'all';

  // Handle empty plans list
  if (!options || options.length === 0) {
    listEl.innerHTML = `
      <div class="plan-picker-empty">
        <span class="material-symbols-rounded">assignment</span>
        <p>${t('plan.picker.noPlans')}</p>
        <p class="plan-picker-empty-hint">${t('plan.picker.createFirst')}</p>
        <button class="btn-primary mt-4" onclick="closePlanPickerSheet(); openAddPlanModal();">
          <span class="material-symbols-rounded">add_circle</span>
          <span>${t('plan.actions.create')}</span>
        </button>
      </div>
    `;
    return;
  }

  let filtered = options;
  if (typeFilter !== 'all') {
    filtered = filtered.filter(opt => opt.type === typeFilter);
  }
  filtered = filtered.filter(opt =>
    opt.label.toLowerCase().includes(searchTerm) ||
    opt.description.toLowerCase().includes(searchTerm)
  );

  if (filtered.length === 0) {
    listEl.innerHTML = `
      <div class="plan-picker-empty">
        <span class="material-symbols-rounded">search_off</span>
        <p>${t('plan.picker.noResults')}</p>
      </div>
    `;
    return;
  }

  listEl.innerHTML = filtered.map(opt => {
    const iconMarkup = opt.icon && opt.icon.kind === 'url'
      ? `<img src="${opt.icon.value}" alt="" class="plan-icon-img" loading="lazy" />`
      : `<span class="material-symbols-rounded">${opt.icon?.value || opt.icon || 'fitness_center'}</span>`;
    return `
      <button class="plan-picker-option" onclick="selectPlanFromPicker('${opt.value}')">
        <div class="plan-picker-option-icon">
          ${iconMarkup}
        </div>
        <div class="plan-picker-option-content">
          <div class="plan-picker-option-label">${opt.label}</div>
          <div class="plan-picker-option-desc">${opt.description}</div>
        </div>
        <span class="material-symbols-rounded plan-picker-option-chevron">chevron_right</span>
      </button>
    `;
  }).join('');
}

function selectPlanFromPicker(planId) {
  // Store callback before closing (closePlanPickerSheet clears it)
  const callback = planPickerCallback;

  closePlanPickerSheet();

  // Use the stored callback (functions can't be serialized to JSON)
  if (callback) {
    callback(planId);
  }
}

function closePlanPickerSheet() {
  const overlay = document.getElementById('plan-picker-overlay');
  overlay.classList.remove('active');
  document.body.style.overflow = '';
  planPickerCallback = null;
}

function filterPlanPicker(type) {
  planPickerTypeFilter = type;

  // Update active state on filter buttons
  document.querySelectorAll('.plan-picker-filter-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.type === type);
  });

  // Re-render with current search term and new type filter
  const sheet = document.getElementById('plan-picker-sheet');
  const searchInput = document.getElementById('plan-picker-search');
  if (!sheet) return;

  const config = JSON.parse(sheet.dataset.config || '{}');
  const term = searchInput ? searchInput.value.toLowerCase().trim() : '';
  renderPlanPickerOptions(config.options, term, type);
}

function selectExerciseForPlan(exerciseId) {
  // Close picker
  document.getElementById('exercise-picker-modal').classList.remove('active');

  // Open exercise config modal
  openExerciseConfigModal(exerciseId);
}

function setExerciseConfigValue(type, value) {
  const input = document.getElementById(`exercise-${type}`);
  const valueEl = document.getElementById(`exercise-${type}-value`);
  if (!input || !valueEl) return;

  const rawValue = value ?? '';
  input.value = rawValue === null || rawValue === undefined ? '' : String(rawValue);

  let display = input.value;
  const numericValue = Number(display);
  if (!display || ((type === 'reps' || type === 'hold') && Number.isFinite(numericValue) && numericValue <= 0)) {
    display = '—';
  }
  valueEl.textContent = display;
}

function openExerciseConfigPicker(type) {
  const input = document.getElementById(`exercise-${type}`);
  if (!input || typeof openNumberPicker !== 'function') return;

  const raw = input.value.trim();
  const parsed = Number(raw);
  const initialValue = Number.isFinite(parsed) ? parsed : (type === 'sets' ? 3 : 0);
  const pickerType = type === 'sets' ? 'sets' : type;

  openNumberPicker({
    type: pickerType,
    initialValue,
    onConfirm: (value) => setExerciseConfigValue(type, value)
  });
}

function openExerciseConfigModal(exerciseId, editIndex = null) {
  const exercise = allExercises.find(e => e.id === exerciseId);
  if (!exercise) return;

  // Store for later
  document.getElementById('exercise-config-modal').dataset.exerciseId = exerciseId;
  document.getElementById('exercise-config-modal').dataset.editIndex = editIndex !== null ? editIndex : '';

  // Populate form
  document.getElementById('exercise-config-name').textContent = getExerciseName(exercise);

  // If editing, load existing config
  if (editIndex !== null && currentPlan.items && currentPlan.items[editIndex]) {
    const item = currentPlan.items[editIndex];
    const target = item.target || {};
    setExerciseConfigValue('sets', target.sets || 3);
    setExerciseConfigValue('reps', target.reps || '');
    setExerciseConfigValue('hold', target.holdSec || '');
    document.getElementById('exercise-rest').value = item.restSec !== undefined ? item.restSec : 90;
  } else {
    // Default values
    setExerciseConfigValue('sets', 3);
    setExerciseConfigValue('reps', '');
    setExerciseConfigValue('hold', '');
    document.getElementById('exercise-rest').value = 90;
  }

  document.getElementById('exercise-config-modal').classList.add('active');
  updateRestDisplay(document.getElementById('exercise-rest'));
}

function saveExerciseConfig() {
  const modal = document.getElementById('exercise-config-modal');
  const exerciseId = modal.dataset.exerciseId;
  const editIndex = modal.dataset.editIndex;

  const setsValue = parseInt(document.getElementById('exercise-sets').value, 10);
  const repsValue = document.getElementById('exercise-reps').value.trim();
  const holdValue = parseInt(document.getElementById('exercise-hold').value, 10);
  const restValue = parseInt(document.getElementById('exercise-rest').value, 10);

  const target = {};
  if (Number.isFinite(setsValue) && setsValue > 0) target.sets = setsValue;
  if (repsValue) {
    const repsNum = Number(repsValue);
    if (!Number.isFinite(repsNum) || repsNum > 0) {
      target.reps = repsValue;
    }
  }
  if (Number.isFinite(holdValue) && holdValue > 0) target.holdSec = holdValue;

  const exerciseConfig = {
    exerciseId,
    target: Object.keys(target).length ? target : undefined,
    restSec: Number.isFinite(restValue) ? restValue : undefined
  };

  if (editIndex !== '') {
    // Update existing
    currentPlan.items[parseInt(editIndex, 10)] = exerciseConfig;
  } else {
    // Add new
    if (!currentPlan.items) {
      currentPlan.items = [];
    }
    currentPlan.items.push(exerciseConfig);
  }

  closeExerciseConfigModal();
  renderPlanExercises();
}

function closeExerciseConfigModal() {
  document.getElementById('exercise-config-modal').classList.remove('active');
}

function editPlanExercise(index) {
  const item = currentPlan.items[index];
  if (!item) return;
  openExerciseConfigModal(item.exerciseId, index);
}

function removePlanExercise(index) {
  if (confirm(t('plan.exerciseRemoveConfirm'))) {
    currentPlan.items.splice(index, 1);
    renderPlanExercises();
  }
}

