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
    // Hauptmuskel ist der erste in der Liste
    const primaryMuscle = exercise.muscleGroups[0];
    // Zusätzliche Muskelgruppen
    const additionalMuscles = exercise.muscleGroups.length - 1;

    return `
      <div class="exercise-card-compact" onclick="viewExerciseDetails('${exercise.id}')">
        ${exercise.imageUrl ?
          `<img src="${exercise.imageUrl}" alt="${exercise.name}" class="exercise-card-img" onerror="this.src='https://via.placeholder.com/400x100?text=No+Image'">`
          :
          `<div class="exercise-card-img-placeholder">
            <span class="material-symbols-rounded" style="font-size: 48px;">fitness_center</span>
          </div>`
        }

        <div class="exercise-card-content">
          <h3 class="exercise-card-title">${exercise.name}</h3>

          <div class="flex items-center justify-between">
            <span class="muscle-tag muscle-${primaryMuscle}">${muscleNames[primaryMuscle]}</span>
            ${additionalMuscles > 0 ?
              `<span class="exercise-card-badge">+${additionalMuscles}</span>`
              : ''
            }
          </div>
        </div>

        <!-- Edit Button (nur sichtbar on hover) -->
        <button
          onclick="event.stopPropagation(); editExercise('${exercise.id}')"
          class="exercise-card-edit-btn"
          title="Bearbeiten"
        >
          <span class="material-symbols-rounded" style="font-size: 18px;">edit</span>
        </button>
      </div>
    `;
  }).join('');
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
  
  // Muscle groups checkboxes
  document.querySelectorAll('.muscle-checkbox').forEach(checkbox => {
    checkbox.checked = exercise.muscleGroups.includes(checkbox.value);
  });
  
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
  document.querySelectorAll('.muscle-checkbox').forEach(cb => cb.checked = false);
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
  
  // Get selected muscle groups
  const muscleGroups = Array.from(document.querySelectorAll('.muscle-checkbox:checked'))
    .map(cb => cb.value);
  
  // Validation
  if (!name) {
    alert('Bitte gib einen Namen für die Übung ein!');
    return;
  }
  
  if (muscleGroups.length === 0) {
    alert('Bitte wähle mindestens eine Muskelgruppe!');
    return;
  }
  
  const exerciseData = {
    name,
    description,
    imageUrl,
    muscleGroups,
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
    alert('Fehler beim Speichern der Übung!');
  }
}

// ========================================
// VIEW EXERCISE DETAILS
// ========================================

function viewExerciseDetails(id) {
  const exercise = allExercises.find(ex => ex.id === id);
  if (!exercise) return;

  // Modal-Inhalt erstellen
  const modalContent = `
    <div class="space-y-4">
      <!-- Bild -->
      ${exercise.imageUrl ?
        `<img src="${exercise.imageUrl}" alt="${exercise.name}" class="w-full h-[200px] object-cover rounded-lg" onerror="this.src='https://via.placeholder.com/600x200?text=No+Image'">`
        :
        `<div class="w-full h-[200px] bg-gray-800 rounded-lg flex items-center justify-center">
          <span class="material-symbols-rounded" style="font-size: 80px; color: var(--color-primary);">fitness_center</span>
        </div>`
      }

      <!-- Schwierigkeit -->
      <div>
        <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
          <span class="material-symbols-rounded" style="font-size: 18px;">star</span>
          Schwierigkeit
        </label>
        <div class="flex gap-1">
          ${Array(5).fill(0).map((_, i) =>
            `<span class="material-symbols-rounded" style="font-size: 24px; color: ${i < exercise.difficulty ? 'var(--color-primary)' : '#374151'};">
              ${i < exercise.difficulty ? 'star' : 'star'}
            </span>`
          ).join('')}
        </div>
      </div>

      <!-- Muskelgruppen -->
      <div>
        <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
          <span class="material-symbols-rounded" style="font-size: 18px;">sports_gymnastics</span>
          Trainierte Muskelgruppen
        </label>
        <div class="flex flex-wrap gap-2">
          ${exercise.muscleGroups.map((muscle, index) =>
            `<span class="muscle-tag ${index === 0 ? 'muscle-primary' : ''}">
              ${index === 0 ? '<span class="material-symbols-rounded" style="font-size: 14px;">fiber_manual_record</span> ' : ''}${muscleNames[muscle]}
            </span>`
          ).join('')}
        </div>
        <p class="text-xs text-gray-500 mt-2 flex items-center gap-1">
          <span class="material-symbols-rounded" style="font-size: 12px;">fiber_manual_record</span>
          Hauptmuskel
        </p>
      </div>

      <!-- Beschreibung -->
      ${exercise.description ?
        `<div>
          <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
            <span class="material-symbols-rounded" style="font-size: 18px;">description</span>
            Anleitung
          </label>
          <p class="text-gray-300 leading-relaxed">${exercise.description}</p>
        </div>`
        :
        `<div class="text-gray-500 italic text-center py-4 flex flex-col items-center gap-2">
          <span class="material-symbols-rounded" style="font-size: 32px;">description</span>
          Keine Anleitung vorhanden
        </div>`
      }

      <!-- Action Buttons -->
      <div class="flex gap-3 pt-4">
        <button
          onclick="closeGenericModal(); editExercise('${exercise.id}')"
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

  // Generic Modal öffnen
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