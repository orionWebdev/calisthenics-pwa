// ========================================
// EXERCISES MANAGEMENT
// ========================================

let allExercises = [];
let filteredExercises = [];
let editingExerciseId = null;

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
// LOAD & DISPLAY EXERCISES
// ========================================

async function loadExercises() {
  try {
    allExercises = await getAllDocs(exercisesCollection);
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

  grid.innerHTML = filteredExercises.map(exercise => {
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

    // Difficulty filter
    const matchesDifficulty = !difficultyFilter || exercise.difficulty === parseInt(difficultyFilter);

    return matchesSearch && matchesMuscle && matchesDifficulty;
  });

  renderExercises();
  updateActiveFilters();
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

  document.getElementById('modal-title').textContent = 'Übung bearbeiten';
  document.getElementById('exercise-name').value = exercise.name;
  document.getElementById('exercise-description').value = exercise.description || '';
  document.getElementById('exercise-image').value = exercise.imageUrl || '';

  // Set muscle groups and equipment for multi-select
  exerciseMuscleGroups = [...exercise.muscleGroups];
  exerciseEquipment = exercise.equipment ? [...exercise.equipment] : [];

  // Render multi-select inputs
  renderExerciseMuscleGroupsInput();
  renderExerciseEquipmentInput();

  // Difficulty
  setDifficulty(exercise.difficulty);

  document.getElementById('exercise-modal').classList.add('active');
}

function closeExerciseModal() {
  document.getElementById('exercise-modal').classList.remove('active');
  clearExerciseForm();
}

function clearExerciseForm() {
  document.getElementById('exercise-name').value = '';
  document.getElementById('exercise-description').value = '';
  document.getElementById('exercise-image').value = '';

  // Clear multi-select inputs
  exerciseMuscleGroups = [];
  exerciseEquipment = [];

  setDifficulty(3);
}

// ========================================
// DIFFICULTY SELECTION
// ========================================

function setDifficulty(level) {
  document.getElementById('exercise-difficulty').value = level;
  
  document.querySelectorAll('.difficulty-btn').forEach(btn => {
    if (parseInt(btn.dataset.difficulty) === level) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });
}

// ========================================
// SAVE EXERCISE
// ========================================

async function saveExercise() {
  const name = document.getElementById('exercise-name').value.trim();
  const description = document.getElementById('exercise-description').value.trim();
  const imageUrl = document.getElementById('exercise-image').value.trim();
  const difficulty = parseInt(document.getElementById('exercise-difficulty').value);

  // Get selected muscle groups and equipment from state
  const muscleGroups = exerciseMuscleGroups;
  const equipment = exerciseEquipment.length > 0 ? exerciseEquipment : ['none'];

  // Validation
  if (!name) {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Bitte gib einen Namen für die Übung ein!');
  }
    return;
  }

  if (muscleGroups.length === 0) {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Bitte wähle mindestens eine Muskelgruppe!');
  }
    return;
  }

  const exerciseData = {
    name,
    description,
    imageUrl,
    muscleGroups,
    equipment,
    difficulty
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
  const executionText = exercise.description || 'Noch keine Ausfuehrung hinterlegt.';

  const modalContent = `
    <div class="exercise-detail">
      <div class="exercise-detail-hero">
        <div class="exercise-detail-icon">
          <span class="material-symbols-rounded">fitness_center</span>
        </div>
        <div>
          <div class="exercise-detail-title">${exercise.name}</div>
          <div class="exercise-detail-subtitle">${muscleLabel || 'Ganzkoerper'} ? ${equipmentLabel}</div>
        </div>
      </div>

      <div class="exercise-detail-meta">
        <div class="exercise-detail-chip">
          <span class="material-symbols-rounded">star</span>
          <span>Level ${exercise.difficulty || 3}</span>
        </div>
        <div class="exercise-detail-chip">
          <span class="material-symbols-rounded">sports_gymnastics</span>
          <span>${muscleLabel || 'Ganzkoerper'}</span>
        </div>
        <div class="exercise-detail-chip">
          <span class="material-symbols-rounded">build</span>
          <span>${equipmentLabel}</span>
        </div>
      </div>

      <div class="exercise-detail-grid">
        <div class="exercise-detail-block">
          <div class="exercise-detail-block-title">
            <span class="material-symbols-rounded">tune</span>
            <span>Setup</span>
          </div>
          <p>Finde eine stabile Ausgangsposition, aktiviere Core und halte Spannung.</p>
        </div>
        <div class="exercise-detail-block">
          <div class="exercise-detail-block-title">
            <span class="material-symbols-rounded">play_arrow</span>
            <span>Ausfuehrung</span>
          </div>
          <p>${executionText}</p>
        </div>
        <div class="exercise-detail-block">
          <div class="exercise-detail-block-title">
            <span class="material-symbols-rounded">error</span>
            <span>Haeufige Fehler</span>
          </div>
          <p>Vermeide Schwung, unkontrollierte Endpositionen und instabile Gelenkwinkel.</p>
        </div>
        <div class="exercise-detail-block">
          <div class="exercise-detail-block-title">
            <span class="material-symbols-rounded">trending_up</span>
            <span>Progressionen</span>
          </div>
          <p>Mehr Range, langsamere Exzentrik oder Zusatzgewicht erhoehen die Intensitaet.</p>
        </div>
      </div>

      <div class="exercise-detail-actions">
        <button
          onclick="closeGenericModal(); editExercise('${exercise.id}')"
          class="btn-primary"
        >
          <span class="material-symbols-rounded">edit</span>
          Bearbeiten
        </button>
        <button onclick="closeGenericModal()" class="btn-secondary">
          <span class="material-symbols-rounded">close</span>
          Schliessen
        </button>
      </div>
    </div>
  `;

  // Generic Modal ?ffnen öffnen
  openGenericModal(exercise.name, modalContent);
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
    allExercises = exercises;
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
