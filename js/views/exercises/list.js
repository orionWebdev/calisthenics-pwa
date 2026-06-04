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
    const initial = getExerciseInitial(getExerciseName(exercise));
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
  // Visual: muscle group icon instead of photo/icon
  const visualHTML = `<div class="exercise-list-visual-placeholder">
      ${getPrimaryMuscleIcon(exercise.muscleGroups, 'muscle-icon--md')}
    </div>`;

  // Meta line: muscle groups (replaces type · pattern)
  const names = getMuscleNames();
  const muscleLabel = (exercise.muscleGroups || [])
    .map(m => names[m]).filter(Boolean).slice(0, 3).join(', ');
  const metaText = muscleLabel || t('exercise.type.' + exercise.type) || '';

  // Difficulty stripe color
  const diffColor = {
    beginner: '#4CAF50',
    intermediate: '#FF9800',
    advanced: '#F44336',
    elite: '#9C27B0'
  }[exercise.difficulty] || 'transparent';

  return `
    <div class="exercise-list-row${isLast ? ' is-last' : ''}" onclick="viewExerciseDetails('${exercise.id}')">
      <div class="exercise-difficulty-stripe" style="background: ${diffColor}"></div>
      ${visualHTML}
      <div class="exercise-list-text">
        <span class="exercise-list-name">${getExerciseName(exercise)}</span>
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
  const equipmentFilter = exerciseEquipmentFilter;

  filteredExercises = allExercises.filter(exercise => {
    // Search filter – Name hat Prioritaet, dann type/difficulty
    let matchesSearch = true;
    if (searchLower) {
      const nameLower = (getExerciseName(exercise)).toLocaleLowerCase('de-DE');
      const nameEnLower = (exercise.name || '').toLocaleLowerCase('de-DE');
      if (nameLower.includes(searchLower) || nameEnLower.includes(searchLower)) {
        matchesSearch = true;
      } else {
        const typeLabel = (t('exercise.type.' + exercise.type) || '').toLocaleLowerCase('de-DE');
        const diffLabel = (t('difficulty.' + exercise.difficulty) || '').toLocaleLowerCase('de-DE');
        matchesSearch = typeLabel.includes(searchLower) ||
                        diffLabel.includes(searchLower);
      }
    }

    // Muscle filter — matches the exercise's PRIMARY muscle only
    const matchesMuscle = exercisePrimaryMatchesMuscle(exercise, muscleFilter);

    // Difficulty filter
    let matchesDifficulty = true;
    if (difficultyFilter) {
      const exerciseDiff = convertDifficultyToEnum(exercise.difficulty);
      matchesDifficulty = exerciseDiff === difficultyFilter;
    }

    // Equipment filter
    const matchesEquipment = !equipmentFilter || (exercise.equipment || []).includes(equipmentFilter);

    return matchesSearch && matchesMuscle && matchesDifficulty && matchesEquipment;
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

function setExerciseEquipmentFilter(value) {
  exerciseEquipmentFilter = value || '';
  updateExerciseFiltersUI();
  filterExercises();
}

/**
 * Opens muscle group filter as a bottom sheet (single-select)
 */
function openMuscleGroupFilterSheet() {
  const mn = getMuscleNames();
  const filterOptions = [
    { value: '', label: t('exercise.filters.allMuscles'), description: t('exercise.muscleDescriptions.all') },
    { value: 'chest', label: mn.chest, description: t('exercise.muscleDescriptions.chest'), icon: getMuscleIconPath('chest') },
    { value: 'back', label: mn.back, description: t('exercise.muscleDescriptions.back'), icon: getMuscleIconPath('back') },
    { value: 'biceps', label: mn.biceps, description: t('exercise.muscleDescriptions.biceps'), icon: getMuscleIconPath('biceps') },
    { value: 'triceps', label: mn.triceps, description: t('exercise.muscleDescriptions.triceps'), icon: getMuscleIconPath('triceps') },
    { value: 'shoulders', label: mn.shoulders, description: t('exercise.muscleDescriptions.shoulders'), icon: getMuscleIconPath('shoulders') },
    { value: 'core', label: mn.core, description: t('exercise.muscleDescriptions.core'), icon: getMuscleIconPath('core') },
    { value: 'legs', label: mn.legs, description: t('exercise.muscleDescriptions.legs'), icon: getMuscleIconPath('legs') },
    { value: 'full-body', label: mn['full-body'], description: t('exercise.muscleDescriptions.fullBody'), icon: getMuscleIconPath('full-body') }
  ];

  openBottomSheet({
    title: t('exercise.muscleFilter.title'),
    options: filterOptions,
    selectedValues: exerciseMuscleFilter ? [exerciseMuscleFilter] : [''],
    enableSearch: false,
    fieldId: 'exercise-muscle-filter-btn',
    onConfirm: (selectedValues) => {
      // Single-select: use the last selected value
      const selected = selectedValues.length > 0 ? selectedValues[selectedValues.length - 1] : '';
      setExerciseMuscleFilter(selected);
    }
  });
}

/**
 * Opens difficulty filter as a bottom sheet (single-select)
 */
function openDifficultyFilterSheet() {
  const filterOptions = [
    { value: '', label: t('exercise.filters.allDifficulties'), description: '' },
    { value: 'beginner', label: t('difficulty.beginner'), description: t('difficulty.descriptions.beginner') },
    { value: 'intermediate', label: t('difficulty.intermediate'), description: t('difficulty.descriptions.intermediate') },
    { value: 'advanced', label: t('difficulty.advanced'), description: t('difficulty.descriptions.advanced') },
    { value: 'elite', label: t('difficulty.elite'), description: t('difficulty.descriptions.elite') }
  ];

  openBottomSheet({
    title: t('exercise.difficultyFilter.title'),
    options: filterOptions,
    selectedValues: exerciseDifficultyFilter ? [exerciseDifficultyFilter] : [''],
    enableSearch: false,
    fieldId: 'exercise-difficulty-filter-btn',
    onConfirm: (selectedValues) => {
      const selected = selectedValues.length > 0 ? selectedValues[selectedValues.length - 1] : '';
      setExerciseDifficultyFilter(selected);
    }
  });
}

/**
 * Opens equipment filter as a bottom sheet (single-select)
 */
function openEquipmentFilterSheet() {
  const mainEquipment = ['bodyweight', 'pull-up-bar', 'parallettes', 'rings', 'dumbbell', 'barbell', 'resistance-bands', 'gym-machine', 'bench'];

  const filterOptions = [
    { value: '', label: t('plan.filters.all'), description: '' }
  ];

  mainEquipment.forEach(eq => {
    filterOptions.push({
      value: eq,
      label: equipmentNames[eq] || eq,
      description: ''
    });
  });

  openBottomSheet({
    title: t('exercise.equipmentFilter.title'),
    options: filterOptions,
    selectedValues: exerciseEquipmentFilter ? [exerciseEquipmentFilter] : [''],
    enableSearch: false,
    fieldId: 'exercise-equipment-filter-btn',
    onConfirm: (selectedValues) => {
      const selected = selectedValues.length > 0 ? selectedValues[selectedValues.length - 1] : '';
      setExerciseEquipmentFilter(selected);
    }
  });
}

function updateExerciseFiltersUI() {
  // Update muscle filter button label
  const muscleFilterLabel = document.getElementById('exercise-muscle-filter-label');
  const muscleFilterBtn = document.getElementById('exercise-muscle-filter-btn');
  if (muscleFilterLabel) {
    muscleFilterLabel.textContent = exerciseMuscleFilter
      ? (getMuscleNames()[exerciseMuscleFilter] || exerciseMuscleFilter)
      : t('exercise.filters.allMuscles');
  }
  if (muscleFilterBtn) {
    muscleFilterBtn.classList.toggle('active', !!exerciseMuscleFilter);
  }

  // Update difficulty filter button label
  const difficultyFilterLabel = document.getElementById('exercise-difficulty-filter-label');
  const difficultyFilterBtn = document.getElementById('exercise-difficulty-filter-btn');
  if (difficultyFilterLabel) {
    difficultyFilterLabel.textContent = exerciseDifficultyFilter
      ? (t('difficulty.' + exerciseDifficultyFilter) || exerciseDifficultyFilter)
      : t('exercise.filters.allDifficulties');
  }
  if (difficultyFilterBtn) {
    difficultyFilterBtn.classList.toggle('active', !!exerciseDifficultyFilter);
  }

  // Update equipment filter button label
  const equipmentFilterLabel = document.getElementById('exercise-equipment-filter-label');
  const equipmentFilterBtn = document.getElementById('exercise-equipment-filter-btn');
  if (equipmentFilterLabel) {
    equipmentFilterLabel.textContent = exerciseEquipmentFilter
      ? (equipmentNames[exerciseEquipmentFilter] || exerciseEquipmentFilter)
      : t('exercise.filters.allEquipment');
  }
  if (equipmentFilterBtn) {
    equipmentFilterBtn.classList.toggle('active', !!exerciseEquipmentFilter);
  }
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
  exerciseEquipmentFilter = '';
  updateExerciseFiltersUI();
  filterExercises();
}

// Active Filter Pills
function updateActiveFilters() {
  const searchInput = document.getElementById('search-input');
  const searchTerm = searchInput ? searchInput.value : '';
  const muscleFilter = exerciseMuscleFilter;
  const difficultyFilter = exerciseDifficultyFilter;
  const equipmentFilter = exerciseEquipmentFilter;

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
        <span>${getMuscleNames()[muscleFilter]}</span>
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

  if (equipmentFilter) {
    filterPills += `
      <div class="filter-pill">
        <span class="material-symbols-rounded">build</span>
        <span>${equipmentNames[equipmentFilter] || equipmentFilter}</span>
        <button onclick="setExerciseEquipmentFilter('')" class="filter-pill-remove">
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
