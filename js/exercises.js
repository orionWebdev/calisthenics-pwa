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
      <div class="col-span-full text-center py-12 text-gray-400">
        <div class="text-5xl mb-4">🔍</div>
        <p>Keine Übungen gefunden</p>
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
          `<div class="exercise-card-img-placeholder">🏋️</div>`
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
          ✏️
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
        `<div class="w-full h-[200px] bg-gray-800 rounded-lg flex items-center justify-center text-6xl">🏋️</div>`
      }

      <!-- Schwierigkeit -->
      <div>
        <label class="block text-sm font-medium text-gray-400 mb-2">Schwierigkeit</label>
        <div class="text-2xl text-yellow-400">
          ${'⭐'.repeat(exercise.difficulty)}
        </div>
      </div>

      <!-- Muskelgruppen -->
      <div>
        <label class="block text-sm font-medium text-gray-400 mb-2">Trainierte Muskelgruppen</label>
        <div class="flex flex-wrap gap-2">
          ${exercise.muscleGroups.map((muscle, index) =>
            `<span class="muscle-tag muscle-${muscle}">
              ${index === 0 ? '🎯 ' : ''}${muscleNames[muscle]}
            </span>`
          ).join('')}
        </div>
        <p class="text-xs text-gray-500 mt-2">🎯 = Hauptmuskel</p>
      </div>

      <!-- Beschreibung -->
      ${exercise.description ?
        `<div>
          <label class="block text-sm font-medium text-gray-400 mb-2">Anleitung</label>
          <p class="text-gray-300 leading-relaxed">${exercise.description}</p>
        </div>`
        :
        `<div class="text-gray-500 italic text-center py-4">Keine Anleitung vorhanden</div>`
      }

      <!-- Action Buttons -->
      <div class="flex gap-3 pt-4">
        <button
          onclick="closeGenericModal(); editExercise('${exercise.id}')"
          class="flex-1 bg-blue-600 hover:bg-blue-700 py-3 rounded-lg font-semibold transition-colors"
        >
          ✏️ Bearbeiten
        </button>
        <button
          onclick="closeGenericModal()"
          class="flex-1 bg-gray-700 hover:bg-gray-600 py-3 rounded-lg font-semibold transition-colors"
        >
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