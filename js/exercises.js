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
  
  grid.innerHTML = filteredExercises.map(exercise => `
    <div class="exercise-card" onclick="viewExerciseDetails('${exercise.id}')">
      ${exercise.imageUrl ? 
        `<img src="${exercise.imageUrl}" alt="${exercise.name}" onerror="this.src='https://via.placeholder.com/400x150?text=No+Image'">` 
        : 
        `<div class="w-full h-[150px] bg-gray-800 rounded-lg flex items-center justify-center text-4xl mb-4">🏋️</div>`
      }
      
      <h3 class="text-xl font-bold mb-2">${exercise.name}</h3>
      
      <div class="flex flex-wrap gap-1 mb-3">
        ${exercise.muscleGroups.map(muscle => 
          `<span class="muscle-tag muscle-${muscle}">${muscleNames[muscle]}</span>`
        ).join('')}
      </div>
      
      <div class="flex items-center justify-between text-sm">
        <div class="text-yellow-400">
          ${'⭐'.repeat(exercise.difficulty)}
        </div>
        <button 
          onclick="event.stopPropagation(); editExercise('${exercise.id}')"
          class="text-blue-400 hover:text-blue-300"
        >
          ✏️ Bearbeiten
        </button>
      </div>
      
      ${exercise.description ? 
        `<p class="text-gray-400 text-sm mt-3 line-clamp-2">${exercise.description}</p>` 
        : ''
      }
    </div>
  `).join('');
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
  
  alert(`
${exercise.name}

Schwierigkeit: ${'⭐'.repeat(exercise.difficulty)}
Muskelgruppen: ${exercise.muscleGroups.map(m => muscleNames[m]).join(', ')}

${exercise.description || 'Keine Beschreibung vorhanden'}
  `);
  
  // TODO: Später eine schöne Detail-Modal erstellen
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