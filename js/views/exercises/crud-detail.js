// ========================================

async function saveExercise() {
  const name = document.getElementById('exercise-name').value.trim();
  const type = document.getElementById('exercise-type')?.value || 'strength';
  const difficulty = document.getElementById('exercise-difficulty').value;
  const icon = document.getElementById('exercise-icon')?.value || 'fitness_center';

  // Get instructions as string[] (nummerierte Schritte)
  const instructionsSteps = getCleanInstructionSteps();
  const cues = getCleanInstructionList('cues');
  const commonMistakes = getCleanInstructionList('mistakes');
  const progressions = getCleanInstructionList('progressions');
  const setupNotesInput = document.getElementById('exercise-setup-notes');
  const setupNotes = setupNotesInput ? setupNotesInput.value.trim() : '';
  const variants = getCleanVariants();

  // Get selected muscle groups and equipment from state
  const muscleGroups = exerciseMuscleGroups;
  const equipment = exerciseEquipment.length > 0 ? exerciseEquipment : ['none'];

  // Validation - only name required in v3
  if (!name) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('errors.exerciseNameRequired') || 'Bitte gib einen Namen für die Übung ein!');
    }
    return;
  }

  // Build v3 data and map to Firestore format
  const v3Data = {
    name, type, difficulty, icon,
    instructions: instructionsSteps,
    muscleGroups, equipment,
    variants,
    setupNotes, cues, commonMistakes, progressions
  };

  const exerciseData = mapV3ToExerciseDoc(v3Data);

  try {
    if (editingExerciseId) {
      await updateDoc(exercisesCollection, editingExerciseId, exerciseData);
    } else {
      const newId = await addDoc(exercisesCollection, exerciseData);

      // Inline create callback (for plan integration)
      if (typeof exerciseCreateCallback === 'function') {
        const callbackFn = exerciseCreateCallback;
        exerciseCreateCallback = null;
        closeExerciseModal();
        await loadExercises();
        callbackFn(newId);
        return;
      }
    }

    closeExerciseModal();
    await loadExercises();
  } catch (error) {
    console.error('Error saving exercise:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('exercise.feedback.saveError'));
    }
  }
}

// ========================================
// DELETE EXERCISE
// ========================================

async function deleteExercise(exerciseId) {
  // Check if exercise is used in any plan
  const usedInPlans = (typeof allPlans !== 'undefined' ? allPlans : []).filter(plan => {
    const items = plan.items || plan.exercises || [];
    return items.some(item => item.exerciseId === exerciseId);
  });

  let confirmMessage = t('exercise.deleteConfirm');
  if (usedInPlans.length > 0) {
    const planNames = usedInPlans.map(p => p.name).join(', ');
    confirmMessage = t('exercise.deleteUsedInPlans', {
      count: usedInPlans.length,
      plans: planNames
    });
  }

  if (!confirm(confirmMessage)) return;

  try {
    await deleteDoc(exercisesCollection, exerciseId);
    closeGenericModal();
    await loadExercises();
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', t('exercise.deleted'));
    }
  } catch (error) {
    console.error('Error deleting exercise:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('exercise.deleteError'));
    }
  }
}

// ========================================
// EXERCISE DETAIL HELPERS
// ========================================

function getExerciseSetsFromSessions(exerciseId) {
  const sessions = typeof allSessions !== 'undefined' ? allSessions : [];
  const results = [];
  sessions.forEach(session => {
    if (!session.exercises || !Array.isArray(session.exercises)) return;
    session.exercises.forEach(ex => {
      if (ex.exerciseId !== exerciseId) return;
      if (!ex.sets || !Array.isArray(ex.sets)) return;
      let sessionDate;
      if (session.date && session.date.toDate) sessionDate = session.date.toDate();
      else if (session.date instanceof Date) sessionDate = session.date;
      else if (typeof session.date === 'string') sessionDate = new Date(session.date);
      else sessionDate = new Date();
      results.push({ sessionId: session.id, date: sessionDate, sets: ex.sets });
    });
  });
  return results;
}

function computeExerciseQuickStats(exerciseId) {
  const exerciseEntries = getExerciseSetsFromSessions(exerciseId);

  let bestReps = 0;
  let heaviestWeight = 0;
  let bestSetVolume = 0;

  exerciseEntries.forEach(entry => {
    entry.sets.forEach(s => {
      const reps = s.reps || 0;
      const weight = s.weight || 0;
      if (reps > bestReps) bestReps = reps;
      if (weight > heaviestWeight) heaviestWeight = weight;
      const volume = weight > 0 ? reps * weight : reps;
      if (volume > bestSetVolume) bestSetVolume = volume;
    });
  });

  return { bestReps, heaviestWeight, bestSetVolume };
}

function renderExerciseHistoryTab(exerciseId) {
  const exerciseEntries = getExerciseSetsFromSessions(exerciseId);

  if (exerciseEntries.length === 0) {
    return '<div class="exercise-history-empty"><span class="material-symbols-rounded" style="font-size:40px;display:block;margin-bottom:0.5rem;">history</span>Noch keine Historie vorhanden</div>';
  }

  // Sort descending by date
  exerciseEntries.sort((a, b) => b.date - a.date);

  // Group by date key
  const groups = {};
  exerciseEntries.forEach(e => {
    const key = e.date.toISOString().split('T')[0];
    if (!groups[key]) groups[key] = { date: e.date, entries: [] };
    groups[key].entries.push(e);
  });

  let html = '';
  Object.keys(groups).sort().reverse().forEach(key => {
    const g = groups[key];
    const dateStr = g.date.toLocaleDateString('de-DE', { weekday: 'short', day: '2-digit', month: '2-digit', year: 'numeric' });
    html += `<div class="exercise-history-date-group">
      <div class="exercise-history-date-header">${dateStr}</div>`;

    g.entries.forEach(entry => {
      const setsStr = entry.sets.map((s, i) =>
        `Satz ${i + 1}: ${s.reps || 0} Wdh${s.weight ? ' × ' + s.weight + ' kg' : ''}`
      ).join('<br>');

      html += `<div class="exercise-history-entry">
        <div class="exercise-history-sets">${setsStr}</div>
        <button class="exercise-history-delete" onclick="deleteExerciseFromSession('${entry.sessionId}', '${exerciseId}')" title="Eintrag löschen">
          <span class="material-symbols-rounded" style="font-size:20px;">delete</span>
        </button>
      </div>`;
    });

    html += '</div>';
  });

  return html;
}

async function deleteExerciseFromSession(sessionId, exerciseId) {
  if (!confirm('Diese Übung aus der Session löschen?')) return;

  try {
    const session = allSessions.find(s => s.id === sessionId);
    if (!session) return;

    // Remove exercise from session
    const updatedExercises = (session.exercises || []).filter(ex => ex.exerciseId !== exerciseId);

    if (updatedExercises.length === 0) {
      // No exercises left -> delete entire session
      await deleteDoc(sessionsCollection, sessionId);
      const idx = allSessions.findIndex(s => s.id === sessionId);
      if (idx !== -1) allSessions.splice(idx, 1);
    } else {
      // Update session with remaining exercises
      await updateDoc(sessionsCollection, sessionId, { exercises: updatedExercises });
      session.exercises = updatedExercises;
    }

    // Re-render history tab
    const historyPanel = document.querySelector('[data-panel="history"]');
    if (historyPanel) {
      historyPanel.innerHTML = renderExerciseHistoryTab(exerciseId);
    }
    // Re-render info tab stats
    const statsContainer = document.getElementById('exercise-detail-stats');
    if (statsContainer) {
      const stats = computeExerciseQuickStats(exerciseId);
      statsContainer.innerHTML = renderExerciseQuickStatsHTML(stats);
    }
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', t('exercise.feedback.deleted'));
    }
  } catch (error) {
    console.error('Error deleting exercise from session:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('exercise.feedback.deleteError'));
    }
  }
}

function renderExerciseQuickStatsHTML(stats) {
  return `
    <div class="quick-stats-grid quick-stats-grid--3col">
      <div class="quick-stats-card">
        <div class="quick-stats-header">
          <span class="quick-stats-icon"><span class="material-symbols-rounded">repeat</span></span>
          <span class="quick-stats-label">Beste Wiederholungen</span>
        </div>
        <div class="quick-stats-value">${stats.bestReps || '–'}</div>
      </div>
      <div class="quick-stats-card">
        <div class="quick-stats-header">
          <span class="quick-stats-icon"><span class="material-symbols-rounded">fitness_center</span></span>
          <span class="quick-stats-label">Meistes Gewicht</span>
        </div>
        <div class="quick-stats-value">${stats.heaviestWeight ? stats.heaviestWeight + ' kg' : '–'}</div>
      </div>
      <div class="quick-stats-card">
        <div class="quick-stats-header">
          <span class="quick-stats-icon"><span class="material-symbols-rounded">speed</span></span>
          <span class="quick-stats-label">Bestes Satzvolumen</span>
        </div>
        <div class="quick-stats-value">${stats.bestSetVolume || '–'}</div>
      </div>
    </div>`;
}

function attachExerciseDetailTabListeners() {
  const control = document.querySelector('#generic-modal-body .cal-widget-segmented-control');
  const btns = document.querySelectorAll('#generic-modal-body [data-detail-tab]');
  btns.forEach((btn, idx) => {
    btn.addEventListener('click', () => {
      btns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      if (control) control.style.setProperty('--active-idx', idx);
      const tab = btn.dataset.detailTab;
      document.querySelectorAll('.exercise-detail-tab-panel').forEach(panel => {
        panel.classList.toggle('active', panel.dataset.panel === tab);
      });
    });
  });
}

// ========================================
// VIEW EXERCISE DETAILS
// ========================================

function viewExerciseDetails(id) {
  const exercise = allExercises.find(ex => ex.id === id);
  if (!exercise) return;

  const difficultyValue = convertDifficultyToEnum(exercise.difficulty);
  const typeLabel = t('exercise.type.' + exercise.type) || exercise.type || '';
  const difficultyLabel = t('difficulty.' + difficultyValue) || difficultyValue;
  const normalizedInstructions = normalizeExerciseInstructions(exercise);

  // Difficulty color for subtle badge
  const diffColor = {
    beginner: '#4CAF50',
    intermediate: '#FF9800',
    advanced: '#F44336',
    elite: '#9C27B0'
  }[difficultyValue] || '#6b7280';

  // Muscle group label
  const muscleNamesMap = getMuscleNames();
  const muscleChipLabel = (exercise.muscleGroups || [])
    .map(m => muscleNamesMap[m]).filter(Boolean).join(', ');

  // Chips: Type + Muscle groups + difficulty
  const chipsHTML = `
    <div class="exercise-detail-chips">
      <span class="exercise-chip">${typeLabel}</span>
      ${muscleChipLabel ? `<span class="exercise-chip">${muscleChipLabel}</span>` : ''}
      <span class="exercise-chip exercise-chip--diff" style="border-color: ${diffColor}; color: ${diffColor}">${difficultyLabel}</span>
    </div>
  `;

  // Equipment label
  const equipmentLabel = (exercise.equipment || []).filter(eq => eq && eq !== 'none')
    .map(eq => equipmentNames[eq]).filter(Boolean).join(', ');

  const metaFooterHTML = (muscleChipLabel || equipmentLabel) ? `
    <div class="exercise-detail-meta-footer">
      ${muscleChipLabel ? '<div class="exercise-detail-chip"><span class="material-symbols-rounded">sports_gymnastics</span><span>' + muscleChipLabel + '</span></div>' : ''}
      ${equipmentLabel ? '<div class="exercise-detail-chip"><span class="material-symbols-rounded">build</span><span>' + equipmentLabel + '</span></div>' : ''}
    </div>` : '';

  // Quick stats
  const stats = computeExerciseQuickStats(exercise.id);

  // Only show edit/delete for user-created exercises
  const isCustomExercise = !exercise.source || exercise.source === 'user' || exercise.source === 'custom';

  // === TAB 1: INFO ===
  const infoTabHTML = `
    <div class="exercise-detail">
      <div class="exercise-detail-header">
        ${chipsHTML}
      </div>
      ${metaFooterHTML}
      <div id="exercise-detail-stats" style="margin-top: 1rem;">
        ${renderExerciseQuickStatsHTML(stats)}
      </div>
    </div>`;

  // === TAB 2: HISTORIE ===
  const historyTabHTML = renderExerciseHistoryTab(exercise.id);

  // === TAB 3: ANLEITUNG ===
  const stepsHtml = normalizedInstructions.instructionsSteps.length > 0
    ? `<ol class="instruction-steps-list">
        ${normalizedInstructions.instructionsSteps.map((step, index) => `
          <li>
            <span class="instruction-step-index">${index + 1}.</span>
            <span>${step}</span>
          </li>
        `).join('')}
      </ol>`
    : `<p class="instruction-empty">${t('exercise.instructions.noSteps')}</p>`;

  const variantsHTML = exercise.variants && exercise.variants.length > 0
    ? `<div class="exercise-detail-block">
        <div class="exercise-detail-block-title">
          <span class="material-symbols-rounded">swap_horiz</span>
          <span>${t('exercise.variants.label')}</span>
        </div>
        <ul class="exercise-variants-list">
          ${exercise.variants.map(v => `
            <li class="exercise-variant-item">
              <span class="exercise-variant-name">${v.name}</span>
              ${v.note ? '<span class="exercise-variant-note">' + v.note + '</span>' : ''}
            </li>
          `).join('')}
        </ul>
      </div>`
    : '';

  const notesHTML = exercise.notes
    ? `<div class="exercise-detail-block">
        <div class="exercise-detail-block-title">
          <span class="material-symbols-rounded">notes</span>
          <span>${t('exercise.notesLabel')}</span>
        </div>
        <p class="instruction-text">${exercise.notes}</p>
      </div>`
    : '';

  const advancedSections = [
    normalizedInstructions.cues.length > 0
      ? renderInstructionAccordionSection('tips_and_updates', t('exercise.instructions.advanced.cues'),
        '<ul class="instruction-list">' +
          normalizedInstructions.cues.map(item => '<li>' + item + '</li>').join('') +
        '</ul>')
      : '',
    normalizedInstructions.commonMistakes.length > 0
      ? renderInstructionAccordionSection('warning', t('exercise.instructions.advanced.mistakes'),
        '<ul class="instruction-list">' +
          normalizedInstructions.commonMistakes.map(item => '<li>' + item + '</li>').join('') +
        '</ul>')
      : '',
    normalizedInstructions.progressions.length > 0
      ? renderInstructionAccordionSection('trending_up', t('exercise.instructions.advanced.progressions'),
        '<ul class="instruction-list">' +
          normalizedInstructions.progressions.map(item => '<li>' + item + '</li>').join('') +
        '</ul>')
      : '',
    normalizedInstructions.setupNotes
      ? renderInstructionAccordionSection('tune', t('exercise.instructions.advanced.setup'),
        '<p class="instruction-text">' + normalizedInstructions.setupNotes + '</p>', true)
      : ''
  ].filter(Boolean);

  const instructionsTabHTML = `
    <div class="exercise-detail">
      <div class="exercise-detail-block">
        <div class="exercise-detail-block-title">
          <span class="material-symbols-rounded">format_list_numbered</span>
          <span>${t('exercise.instructions.title')}</span>
        </div>
        ${stepsHtml}
      </div>
      ${variantsHTML}
      ${notesHTML}
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
    </div>`;

  // Sticky action buttons (only for custom exercises)
  const actionsHTML = isCustomExercise ? `
    <div class="exercise-detail-actions exercise-detail-actions--sticky">
      <button onclick="closeGenericModal(); editExercise('${exercise.id}')" class="btn-edit">
        <span class="material-symbols-rounded">settings</span>
      </button>
      <button onclick="deleteExercise('${exercise.id}')" class="btn-danger">
        <span class="material-symbols-rounded">delete</span>
      </button>
    </div>` : '';

  // === MODAL CONTENT WITH TABS ===
  const modalContent = `
    <div class="cal-widget-segmented-control" style="--seg-count:3;--active-idx:0">
      <div class="cal-widget-seg-indicator"></div>
      <button class="cal-widget-seg-btn active" data-detail-tab="info">Info</button>
      <button class="cal-widget-seg-btn" data-detail-tab="history">Historie</button>
      <button class="cal-widget-seg-btn" data-detail-tab="instructions">Anleitung</button>
    </div>

    <div class="exercise-detail-tab-panel active" data-panel="info">
      ${infoTabHTML}
    </div>
    <div class="exercise-detail-tab-panel" data-panel="history">
      ${historyTabHTML}
    </div>
    <div class="exercise-detail-tab-panel" data-panel="instructions">
      ${instructionsTabHTML}
    </div>

    ${actionsHTML}
  `;

  openGenericModal(getExerciseName(exercise), modalContent);
  // Make modal full height
  const modalContentEl = document.querySelector('#generic-modal .modal-content');
  if (modalContentEl) modalContentEl.classList.add('modal-content--full-height');
  attachExerciseDetailTabListeners();
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
  const modalContentEl = document.querySelector('#generic-modal .modal-content');
  if (modalContentEl) modalContentEl.classList.remove('modal-content--full-height');
}

// ========================================
// REAL-TIME LISTENER
// ========================================

// Übungen in Echtzeit synchronisieren (curated + user exercises)
function setupExercisesListener() {
  let curatedExercises = [];
  let userExercises = [];

  function mergeAndUpdate() {
    const exerciseMap = new Map();
    for (const ex of curatedExercises) {
      exerciseMap.set(ex.id, ex);
    }
    for (const ex of userExercises) {
      exerciseMap.set(ex.id, ex);
    }
    allExercises = Array.from(exerciseMap.values());
    filterExercises();
  }

  onCollectionChange(exercisesCuratedCollection, (exercises) => {
    curatedExercises = exercises.map(mapExerciseToV3);
    mergeAndUpdate();
  });

  onUserCollectionChange(exercisesCollection, (exercises) => {
    userExercises = exercises.map(mapExerciseToV3);
    mergeAndUpdate();
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
  const mn = getMuscleNames();
  const muscleOptions = [
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
    title: t('exercise.muscleFilter.selectTitle'),
    options: muscleOptions,
    selectedValues: exerciseMuscleGroups,
    enableSearch: true,
    searchPlaceholder: t('exercise.muscleFilter.searchPlaceholder'),
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
    { value: 'bodyweight', label: 'Bodyweight', description: 'Kein Equipment nötig' },
    { value: 'pull-up-bar', label: 'Klimmzugstange', description: 'Für Klimmzüge und Hanging-Übungen' },
    { value: 'barbell', label: 'Langhantel', description: 'Langhantel-Training' },
    { value: 'dumbbell', label: 'Kurzhantel', description: 'Kurzhantel-Training' },
    { value: 'resistance-bands', label: 'Widerstandsbänder', description: 'Für Assistance oder zusätzlichen Widerstand' },
    { value: 'gym-machine', label: 'Maschine', description: 'Geräte im Fitnessstudio' },
    { value: 'parallettes', label: 'Paralettes', description: 'Für L-Sits, Handstands und Push-Ups' },
    { value: 'rings', label: 'Ringe', description: 'Gymnastikringe für instabiles Training' },
    { value: 'bench', label: 'Bank', description: 'Flach-/Schrägbank' }
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
    placeholder: t('exercise.muscleFilter.selectPlaceholder'),
    selectedValues: exerciseMuscleGroups,
    valueLabels: getMuscleNames()
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
