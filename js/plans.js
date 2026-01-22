// ========================================
// PLANS MANAGEMENT
// ========================================

let allPlans = [];
let filteredPlans = [];
let editingPlanId = null;
let currentPlan = null; // Currently selected plan for editing

// Workout Type Namen Mapping
const workoutTypeNames = {
  strength: 'Kraft',
  cardio: 'Cardio',
  mobility: 'Mobility',
  skill: 'Skill',
  hiit: 'HIIT',
  mixed: 'Mixed'
};

// Workout Goal Namen Mapping
const workoutGoalNames = {
  strength: 'Kraft',
  endurance: 'Ausdauer',
  hypertrophy: 'Muskelaufbau',
  skill: 'Skill',
  mixed: 'Gemischt'
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

// ========================================
// LOAD & DISPLAY PLANS
// ========================================

async function loadPlans() {
  try {
    allPlans = await getAllDocs(plansCollection);
    filteredPlans = [...allPlans];
    renderPlans();
  } catch (error) {
    console.error('Error loading plans:', error);
  }
}

function renderPlans() {
  const grid = document.getElementById('plans-grid');

  if (filteredPlans.length === 0) {
    grid.innerHTML = `
      <div class="col-span-full empty-state">
        <div class="empty-state-icon">
          <span class="material-symbols-rounded">assignment</span>
        </div>
        <h3 class="empty-state-title">Keine Trainingspläne gefunden</h3>
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
    // Calculate total exercises
    const exerciseCount = plan.exercises ? plan.exercises.length : 0;

    // Get required equipment (unique)
    const equipment = plan.requiredEquipment || [];
    const equipmentCount = equipment.length;

    return `
      <div class="plan-card" onclick="viewPlanDetails('${plan.id}')">
        <!-- Header -->
        <div class="plan-card-header">
          <div class="flex items-center justify-between">
            <span class="plan-type-badge type-${plan.type}">${workoutTypeNames[plan.type]}</span>
            <span class="text-xs text-gray-400">${plan.duration || 45} Min</span>
          </div>
        </div>

        <!-- Content -->
        <div class="plan-card-content">
          <h3 class="plan-card-title">${plan.name}</h3>

          <!-- Stats -->
          <div class="flex items-center gap-4 text-sm text-gray-400">
            <span class="flex items-center gap-1">
              <span class="material-symbols-rounded" style="font-size: 16px;">fitness_center</span>
              ${exerciseCount} Übungen
            </span>
            ${equipmentCount > 0 && equipment[0] !== 'none' ?
              `<span class="flex items-center gap-1">
                <span class="material-symbols-rounded" style="font-size: 16px;">build</span>
                ${equipmentCount}
              </span>`
              : ''
            }
          </div>

          <!-- Difficulty -->
          <div class="flex gap-1 mt-2">
            ${Array(5).fill(0).map((_, i) =>
              `<span class="material-symbols-rounded" style="font-size: 16px; color: ${i < (plan.difficulty || 3) ? 'var(--color-primary)' : '#374151'};">star</span>`
            ).join('')}
          </div>

          <!-- Tags -->
          ${plan.tags && plan.tags.length > 0 ?
            `<div class="flex flex-wrap gap-1 mt-3">
              ${plan.tags.map(tag =>
                `<span class="plan-tag">${tagNames[tag] || tag}</span>`
              ).join('')}
            </div>`
            : ''
          }
        </div>

        <!-- Actions -->
        <div class="plan-card-actions">
          <button
            onclick="event.stopPropagation(); startWorkoutFromPlan('${plan.id}')"
            class="plan-card-start-btn"
            title="Workout starten"
          >
            <span class="material-symbols-rounded" style="font-size: 18px;">play_arrow</span>
          </button>
        </div>

        <!-- Edit Button -->
        <button
          onclick="event.stopPropagation(); editPlan('${plan.id}')"
          class="plan-card-edit-btn"
          title="Bearbeiten"
        >
          <span class="material-symbols-rounded" style="font-size: 18px;">edit</span>
        </button>
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
  document.getElementById('plan-goal').value = 'strength';
  document.getElementById('plan-duration').value = '45';
  document.getElementById('plan-notes').value = '';

  // Clear multi-select inputs
  planTags = [];
  planTargetMuscles = [];

  setPlanDifficulty(3);

  // Clear exercises list
  if (currentPlan) {
    currentPlan.exercises = [];
  }
  renderPlanExercises();
}

function populatePlanForm(plan) {
  document.getElementById('plan-name').value = plan.name || '';
  document.getElementById('plan-type').value = plan.type || 'strength';
  document.getElementById('plan-goal').value = plan.goal || 'strength';
  document.getElementById('plan-duration').value = plan.duration || 45;
  document.getElementById('plan-notes').value = plan.notes || '';

  // Set tags and target muscles for multi-select
  planTags = plan.tags ? [...plan.tags] : [];
  planTargetMuscles = plan.targetMuscles ? [...plan.targetMuscles] : [];

  // Render multi-select inputs
  renderPlanTagsInput();
  renderPlanTargetMusclesInput();

  // Difficulty
  setPlanDifficulty(plan.difficulty || 3);

  // Load exercises
  if (plan.exercises) {
    currentPlan.exercises = [...plan.exercises];
    renderPlanExercises();
  }
}

// ========================================
// DIFFICULTY SELECTION
// ========================================

function setPlanDifficulty(level) {
  document.getElementById('plan-difficulty').value = level;

  document.querySelectorAll('.plan-difficulty-btn').forEach(btn => {
    if (parseInt(btn.dataset.difficulty) === level) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
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

  container.innerHTML = filteredExercises.map(exercise => `
    <div class="exercise-picker-item" onclick="selectExerciseForPlan('${exercise.id}')">
      <div class="flex items-center gap-3">
        ${exercise.imageUrl ?
          `<img src="${exercise.imageUrl}" alt="${exercise.name}" class="w-12 h-12 object-cover rounded" onerror="this.src='https://via.placeholder.com/48'">`
          :
          `<div class="w-12 h-12 bg-gray-700 rounded flex items-center justify-center">
            <span class="material-symbols-rounded" style="font-size: 24px;">fitness_center</span>
          </div>`
        }
        <div class="flex-1">
          <h4 class="font-semibold text-sm">${exercise.name}</h4>
          <p class="text-xs text-gray-400">${exercise.muscleGroups.map(m => muscleNames[m]).join(', ')}</p>
        </div>
        <span class="material-symbols-rounded text-primary">add_circle</span>
      </div>
    </div>
  `).join('');
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
  const goal = document.getElementById('plan-goal').value;
  const duration = parseInt(document.getElementById('plan-duration').value);
  const notes = document.getElementById('plan-notes').value.trim();
  const difficulty = parseInt(document.getElementById('plan-difficulty').value);

  // Get selected tags and target muscles from state
  const tags = planTags;
  const targetMuscles = planTargetMuscles;

  // Validation
  if (!name) {
    alert('Bitte gib einen Namen für den Plan ein!');
    return;
  }

  if (!currentPlan.exercises || currentPlan.exercises.length === 0) {
    alert('Bitte füge mindestens eine Übung hinzu!');
    return;
  }

  // Calculate required equipment from exercises
  const requiredEquipment = new Set();
  if (typeof allExercises !== 'undefined' && allExercises) {
    currentPlan.exercises.forEach(ex => {
      const exercise = allExercises.find(e => e.id === ex.exerciseId);
      if (exercise && exercise.equipment) {
        exercise.equipment.forEach(eq => requiredEquipment.add(eq));
      }
    });
  }

  const planData = {
    name,
    type,
    goal,
    duration,
    notes,
    difficulty,
    tags,
    targetMuscles,
    exercises: currentPlan.exercises,
    requiredEquipment: Array.from(requiredEquipment)
  };

  try {
    if (editingPlanId) {
      // Update existing
      await updateDoc(plansCollection, editingPlanId, planData);
      console.log('✅ Plan updated!');
    } else {
      // Add new
      await addDoc(plansCollection, planData);
      console.log('✅ Plan added!');
    }

    closePlanModal();
    await loadPlans();
  } catch (error) {
    console.error('Error saving plan:', error);
    alert('Fehler beim Speichern des Plans!');
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
    alert('Übungen werden noch geladen. Bitte versuche es gleich nochmal.');
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

  // Modal content
  const modalContent = `
    <div class="space-y-4">
      <!-- Type & Duration -->
      <div class="flex items-center justify-between">
        <span class="plan-type-badge type-${plan.type}">${workoutTypeNames[plan.type]}</span>
        <span class="text-sm text-gray-400">
          <span class="material-symbols-rounded" style="font-size: 16px; vertical-align: middle;">schedule</span>
          ${plan.duration || 45} Minuten
        </span>
      </div>

      <!-- Difficulty -->
      <div>
        <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
          <span class="material-symbols-rounded" style="font-size: 18px;">star</span>
          Schwierigkeit
        </label>
        <div class="flex gap-1">
          ${Array(5).fill(0).map((_, i) =>
            `<span class="material-symbols-rounded" style="font-size: 24px; color: ${i < (plan.difficulty || 3) ? 'var(--color-primary)' : '#374151'};">star</span>`
          ).join('')}
        </div>
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
    allPlans = plans;
    filteredPlans = [...plans];
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
