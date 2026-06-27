// ========================================
// MULTI-SELECT EXERCISE PICKER
// ========================================

function toggleExercisePickerSelection(exerciseId) {
  if (exercisePickerSelectedIds.has(exerciseId)) {
    exercisePickerSelectedIds.delete(exerciseId);
  } else {
    exercisePickerSelectedIds.add(exerciseId);
  }
  renderExercisePicker();
  updateExercisePickerAddButton();
}

function updateExercisePickerAddButton() {
  const btn = document.getElementById('exercise-picker-add-btn');
  const btnLabel = document.getElementById('exercise-picker-add-btn-label');
  const footer = document.getElementById('exercise-picker-footer');
  if (!btn || !footer) return;

  // Hide footer in single-select mode
  if (exercisePickerMode === 'single') {
    footer.style.display = 'none';
    return;
  }

  footer.style.display = '';
  const count = exercisePickerSelectedIds.size;

  if (count === 0) {
    btnLabel.textContent = t('plan.exercisePicker.selectHint');
    btn.disabled = true;
  } else if (count === 1) {
    btnLabel.textContent = t('plan.exercisePicker.addSelectedOne');
    btn.disabled = false;
  } else {
    btnLabel.textContent = t('plan.exercisePicker.addSelected', { count });
    btn.disabled = false;
  }
}

function addSelectedExercisesToPlan() {
  if (exercisePickerSelectedIds.size === 0) return;

  const ids = Array.from(exercisePickerSelectedIds);
  exercisePickerSelectedIds.clear();
  closeExercisePicker();

  if (pendingBlockType === 'emom') {
    openEmomConfigModal(ids);
    pendingBlockType = null;
    return;
  }
  if (pendingBlockType === 'superset') {
    openSupersetConfigModal(ids);
    pendingBlockType = null;
    return;
  }

  pendingBlockType = null;
  if (!currentPlan.items) currentPlan.items = [];

  for (const exerciseId of ids) {
    if (!currentPlan.items.find(item => item.exerciseId === exerciseId)) {
      currentPlan.items.push({
        exerciseId,
        target: { sets: 3 },
        restSec: 90
      });
    }
  }

  renderPlanExercises();
}

function closeExercisePicker() {
  const pickerModal = document.getElementById('exercise-picker-modal');
  pickerModal.classList.remove('active');
  pickerModal.classList.remove('modal--elevated');
  document.body.classList.remove('modal-open');
}

// ========================================
// NATIVE MOBILE INPUT HELPERS
// ========================================

/**
 * Updates the rest time display when slider changes
 */
function updateRestDisplay(valueOrInput) {
  const slider = valueOrInput && typeof valueOrInput === 'object'
    ? valueOrInput
    : document.getElementById('exercise-rest');
  const rawValue = valueOrInput && typeof valueOrInput === 'object'
    ? valueOrInput.value
    : valueOrInput;
  const seconds = parseInt(rawValue);
  const displaySpan = document.getElementById('exercise-rest-display');
  const noneLabel = t('plan.exerciseConfig.restNone');
  const secLabel = t('plan.exerciseConfig.restSec');
  const minLabel = t('plan.exerciseConfig.restMin');

  if (seconds === 0) {
    displaySpan.textContent = noneLabel;
  } else if (seconds < 60) {
    displaySpan.textContent = `${seconds} ${secLabel}`;
  } else {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    if (remainingSeconds === 0) {
      displaySpan.textContent = `${minutes} ${minLabel}`;
    } else {
      displaySpan.textContent = `${minutes}:${remainingSeconds.toString().padStart(2, '0')} ${minLabel}`;
    }
  }

  updateRangeProgress(slider);

  // Trigger haptic feedback on value change
  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('light');
  }
}

function updateRangeProgress(slider) {
  if (!slider) return;
  const min = Number(slider.min || 0);
  const max = Number(slider.max || 100);
  const value = Number(slider.value || 0);
  const percent = max > min ? ((value - min) / (max - min)) * 100 : 0;
  slider.style.setProperty('--range-progress', `${percent}%`);
}

// ========================================
// EXERCISE REORDER
// ========================================

function movePlanExercise(index, direction) {
  const newIndex = index + direction;
  if (!currentPlan || !Array.isArray(currentPlan.items)) return;
  if (newIndex < 0 || newIndex >= currentPlan.items.length) return;
  reorderPlanExercises(index, newIndex);
}

function reorderPlanExercises(fromIndex, toIndex) {
  if (!currentPlan || !Array.isArray(currentPlan.items)) return;
  if (fromIndex === toIndex) return;
  const [removed] = currentPlan.items.splice(fromIndex, 1);
  currentPlan.items.splice(toIndex, 0, removed);
  renderPlanExercises();
}

// ========================================
// BLOCK TRAINING — Plan Editor
// ========================================

let pendingBlockType = null;
let editingBlockGroupId = null;

function openBlockTypeSheet() {
  pendingBlockType = null;
  editingBlockGroupId = null;
  document.getElementById('block-type-sheet').classList.add('active');
}

function closeBlockTypeSheet() {
  document.getElementById('block-type-sheet').classList.remove('active');
}

function selectBlockType(type) {
  closeBlockTypeSheet();
  pendingBlockType = type;

  if (type === 'normal') {
    exercisePickerMode = 'multi';
    openAddExerciseToPlan();
    return;
  }

  exercisePickerSearchTerm = '';
  exercisePickerMuscleFilter = 'all';
  exercisePickerSelectedIds = new Set();
  exercisePickerMode = 'multi';

  const searchInput = document.getElementById('exercise-picker-search');
  if (searchInput) searchInput.value = '';

  document.querySelectorAll('#exercise-picker-modal .filter-chip').forEach(chip => {
    chip.classList.toggle('active', chip.dataset.filter === 'all');
  });

  document.getElementById('exercise-picker-modal').classList.add('active');
  document.body.classList.add('modal-open');

  if (searchInput) {
    searchInput.removeEventListener('input', handleExercisePickerSearch);
    searchInput.addEventListener('input', handleExercisePickerSearch);
  }

  renderExercisePicker();
  updateExercisePickerAddButton();
}

// --- EMOM Config ---

function openEmomConfigModal(exerciseIds, editGroupId) {
  editingBlockGroupId = editGroupId || null;
  const modal = document.getElementById('emom-config-modal');
  modal.dataset.exerciseIds = JSON.stringify(exerciseIds);

  const exercisesContainer = document.getElementById('emom-config-exercises');
  const repsSection = document.getElementById('emom-config-reps-section');

  const exercises = exerciseIds.map(id => allExercises.find(e => e.id === id)).filter(Boolean);

  exercisesContainer.innerHTML = `<h4>${t('block.emomConfig.repsLabel')}</h4>`;

  let existingItems = [];
  if (editGroupId && currentPlan && currentPlan.items) {
    existingItems = currentPlan.items.filter(it => it.groupId === editGroupId);
  }

  repsSection.innerHTML = exercises.map(ex => {
    const existing = existingItems.find(it => it.exerciseId === ex.id);
    const reps = existing?.target?.reps || '8';
    return `
      <div class="block-config-rep-row">
        <label>${getExerciseName(ex)}</label>
        <input type="number" data-exercise-id="${ex.id}" value="${reps}" min="1" max="100" inputmode="numeric" />
      </div>
    `;
  }).join('');

  if (editGroupId && existingItems.length > 0) {
    const first = existingItems[0];
    document.getElementById('emom-config-duration').value = Math.round((first.durationSec || 600) / 60);
    document.getElementById('emom-config-interval').value = first.intervalSec || 60;
    document.getElementById('emom-config-save-btn').textContent = t('block.emomConfig.update');
  } else {
    document.getElementById('emom-config-duration').value = 10;
    document.getElementById('emom-config-interval').value = 60;
    document.getElementById('emom-config-save-btn').textContent = t('block.emomConfig.save');
  }

  modal.classList.add('active');
}

function closeEmomConfigModal() {
  document.getElementById('emom-config-modal').classList.remove('active');
  editingBlockGroupId = null;
}

function saveEmomBlock() {
  const modal = document.getElementById('emom-config-modal');
  const exerciseIds = JSON.parse(modal.dataset.exerciseIds || '[]');
  const durationMin = parseInt(document.getElementById('emom-config-duration').value, 10) || 10;
  const intervalSec = parseInt(document.getElementById('emom-config-interval').value, 10) || 60;
  const durationSec = durationMin * 60;

  const repsInputs = document.querySelectorAll('#emom-config-reps-section input[data-exercise-id]');
  const repsMap = {};
  repsInputs.forEach(input => {
    repsMap[input.dataset.exerciseId] = input.value || '8';
  });

  if (!currentPlan.items) currentPlan.items = [];

  if (editingBlockGroupId) {
    currentPlan.items = currentPlan.items.filter(it => it.groupId !== editingBlockGroupId);
  }

  const groupId = editingBlockGroupId || ('emom-' + Date.now());

  exerciseIds.forEach(id => {
    currentPlan.items.push({
      exerciseId: id,
      executionType: 'emom',
      groupId,
      durationSec,
      intervalSec,
      target: { reps: repsMap[id] || '8' }
    });
  });

  closeEmomConfigModal();
  renderPlanExercises();
}

// --- Superset Config ---

function openSupersetConfigModal(exerciseIds, editGroupId) {
  editingBlockGroupId = editGroupId || null;
  const modal = document.getElementById('superset-config-modal');
  modal.dataset.exerciseIds = JSON.stringify(exerciseIds);

  const exercisesContainer = document.getElementById('superset-config-exercises');
  const exercises = exerciseIds.map(id => allExercises.find(e => e.id === id)).filter(Boolean);

  let existingItems = [];
  if (editGroupId && currentPlan && currentPlan.items) {
    existingItems = currentPlan.items.filter(it => it.groupId === editGroupId);
  }

  const labels = ['A1', 'A2', 'A3', 'A4'];
  exercisesContainer.innerHTML = exercises.map((ex, i) => {
    const existing = existingItems.find(it => it.exerciseId === ex.id);
    const sets = existing?.target?.sets || 3;
    const reps = existing?.target?.reps || '10';
    return `
      <div class="block-config-exercise-row">
        <span style="font-weight:700;color:#a78bfa;min-width:28px;">${labels[i] || 'A' + (i + 1)}</span>
        <span class="block-config-exercise-name">${getExerciseName(ex)}</span>
      </div>
      <div class="block-config-fields" style="margin-bottom:0.75rem;">
        <div class="block-config-field">
          <label>${t('block.supersetConfig.sets')}</label>
          <input type="number" data-exercise-id="${ex.id}" data-field="sets" value="${sets}" min="1" max="20" inputmode="numeric" />
        </div>
        <div class="block-config-field">
          <label>${t('block.supersetConfig.reps')}</label>
          <input type="text" data-exercise-id="${ex.id}" data-field="reps" value="${reps}" inputmode="text" />
        </div>
      </div>
    `;
  }).join('');

  const restSlider = document.getElementById('superset-config-rest');
  if (editGroupId && existingItems.length > 0) {
    const lastItem = existingItems[existingItems.length - 1];
    restSlider.value = lastItem.restSec || 90;
    document.getElementById('superset-config-save-btn').textContent = t('block.supersetConfig.update');
  } else {
    restSlider.value = 90;
    document.getElementById('superset-config-save-btn').textContent = t('block.supersetConfig.save');
  }
  updateSupersetRestDisplay(restSlider);

  modal.classList.add('active');
}

function closeSupersetConfigModal() {
  document.getElementById('superset-config-modal').classList.remove('active');
  editingBlockGroupId = null;
}

function updateSupersetRestDisplay(slider) {
  const seconds = parseInt(slider.value, 10);
  const display = document.getElementById('superset-rest-display');
  if (display) display.textContent = seconds + 's';
}

function saveSupersetBlock() {
  const modal = document.getElementById('superset-config-modal');
  const exerciseIds = JSON.parse(modal.dataset.exerciseIds || '[]');
  const restSec = parseInt(document.getElementById('superset-config-rest').value, 10) || 90;

  if (!currentPlan.items) currentPlan.items = [];

  if (editingBlockGroupId) {
    currentPlan.items = currentPlan.items.filter(it => it.groupId !== editingBlockGroupId);
  }

  const groupId = editingBlockGroupId || ('ss-' + Date.now());

  exerciseIds.forEach((id, i) => {
    const setsInput = document.querySelector(`#superset-config-exercises input[data-exercise-id="${id}"][data-field="sets"]`);
    const repsInput = document.querySelector(`#superset-config-exercises input[data-exercise-id="${id}"][data-field="reps"]`);
    const sets = parseInt(setsInput?.value, 10) || 3;
    const reps = repsInput?.value || '10';

    currentPlan.items.push({
      exerciseId: id,
      executionType: 'superset',
      groupId,
      target: { sets, reps },
      restSec: (i === exerciseIds.length - 1) ? restSec : 0
    });
  });

  closeSupersetConfigModal();
  renderPlanExercises();
}

// --- Block-aware renderPlanExercises ---

function renderPlanExercises() {
  const container = document.getElementById('plan-exercises-list');
  if (!container) return;

  const items = currentPlan && Array.isArray(currentPlan.items) ? currentPlan.items : [];

  if (!items || items.length === 0) {
    container.innerHTML = `
      <div class="text-center py-8 text-gray-400">
        <span class="material-symbols-rounded" style="font-size: 48px;">fitness_center</span>
        <p class="mt-2">${t('plan.exercisesEmptyTitle')}</p>
        <p class="text-sm">${t('plan.exercisesEmptyBody')}</p>
      </div>
    `;
    return;
  }

  if (typeof allExercises === 'undefined' || !allExercises) {
    container.innerHTML = `
      <div class="text-center py-8 text-gray-400">
        <span class="material-symbols-rounded" style="font-size: 48px;">hourglass_empty</span>
        <p class="mt-2">${t('common.loading')}</p>
      </div>
    `;
    return;
  }

  const blocks = groupPlanItems(items);
  container.innerHTML = blocks.map((block, blockIdx) => {
    if (block.groupId) {
      return renderGroupBlock(block, blockIdx, blocks.length);
    }
    const itemIndex = items.indexOf(block.items[0]);
    return renderSingleExerciseItem(block.items[0], itemIndex, items.length);
  }).join('');
}

function renderSingleExerciseItem(item, index, totalItems) {
  if (!item) return '';
  const exercise = allExercises.find(e => e.id === item.exerciseId);
  if (!exercise) return '';

  const target = item.target || {};
  const sets = target.sets !== undefined && target.sets !== null ? target.sets : '-';
  const reps = target.reps ? target.reps : '';
  const holdSec = target.holdSec ? `${target.holdSec} ${t('plan.exerciseConfig.restSec')}` : '';
  const targetValue = reps || holdSec || '-';
  const setsLabel = t('plan.exerciseConfig.setsShort');

  return `
    <div class="plan-exercise-item" data-index="${index}">
      <div class="plan-exercise-reorder">
        <button onclick="event.stopPropagation(); movePlanBlock(${index}, -1)" class="plan-exercise-reorder-btn" ${index === 0 ? 'disabled' : ''} aria-label="Move up">
          <span class="material-symbols-rounded">arrow_upward</span>
        </button>
        <button onclick="event.stopPropagation(); movePlanBlock(${index}, 1)" class="plan-exercise-reorder-btn" ${index === totalItems - 1 ? 'disabled' : ''} aria-label="Move down">
          <span class="material-symbols-rounded">arrow_downward</span>
        </button>
      </div>
      <div class="plan-exercise-info">
        <h4 class="font-semibold">${getExerciseName(exercise)}</h4>
        <p class="text-xs text-gray-400">${sets} ${setsLabel} × ${targetValue}</p>
      </div>
      <div class="plan-exercise-actions">
        <button onclick="event.stopPropagation(); editPlanExercise(${index})" class="plan-item-action plan-item-action--edit" aria-label="${t('common.edit')}">
          <span class="material-symbols-rounded">edit</span>
        </button>
        <button onclick="event.stopPropagation(); removePlanExercise(${index})" class="plan-item-action plan-item-action--delete" aria-label="${t('common.delete')}">
          <span class="material-symbols-rounded">delete</span>
        </button>
      </div>
    </div>
  `;
}

function renderGroupBlock(block, blockIdx, totalBlocks) {
  const firstItem = block.items[0];
  const execType = getExecutionType(firstItem);
  const isEmom = execType === 'emom';
  const typeClass = isEmom ? 'plan-block--emom' : 'plan-block--superset';
  const badgeClass = isEmom ? 'plan-block-badge--emom' : 'plan-block-badge--superset';

  let headerLabel = '';
  let headerSub = '';

  if (isEmom) {
    const durationMin = Math.round((firstItem.durationSec || 600) / 60);
    headerLabel = t('block.planRender.emomLabel', { minutes: durationMin });
    headerSub = t('block.planRender.emomSub', { interval: firstItem.intervalSec || 60, count: block.items.length });
  } else {
    headerLabel = t('block.planRender.supersetLabel');
    headerSub = t('block.planRender.supersetSub', { count: block.items.length });
  }

  const badgeText = isEmom ? 'EMOM' : 'Superset';

  const exerciseRows = block.items.map((item, i) => {
    const exercise = allExercises.find(e => e.id === item.exerciseId);
    if (!exercise) return '';
    const target = item.target || {};
    let targetText = '';
    if (isEmom) {
      targetText = target.reps ? `×${target.reps}` : '';
    } else {
      const labels = ['A1', 'A2', 'A3', 'A4'];
      const label = labels[i] || ('A' + (i + 1));
      targetText = `${label} · ${target.sets || 3} × ${target.reps || '-'}`;
    }
    return `
      <div class="plan-block-exercise">
        <span class="plan-block-exercise-name">${getExerciseName(exercise)}</span>
        <span class="plan-block-exercise-target">${targetText}</span>
      </div>
    `;
  }).join('');

  const groupId = block.groupId;
  const firstFlatIndex = currentPlan.items.indexOf(firstItem);

  return `
    <div class="plan-block ${typeClass}">
      <div class="plan-block-header">
        <div class="plan-block-header-left">
          <span class="plan-block-badge ${badgeClass}">${badgeText}</span>
          <span class="plan-block-sub">${headerSub}</span>
        </div>
        <div class="plan-block-actions">
          <button onclick="event.stopPropagation(); movePlanBlock(${firstFlatIndex}, -1)" ${blockIdx === 0 ? 'disabled' : ''} aria-label="Move up">
            <span class="material-symbols-rounded">arrow_upward</span>
          </button>
          <button onclick="event.stopPropagation(); movePlanBlock(${firstFlatIndex}, 1)" ${blockIdx === totalBlocks - 1 ? 'disabled' : ''} aria-label="Move down">
            <span class="material-symbols-rounded">arrow_downward</span>
          </button>
          <span class="plan-block-actions-divider"></span>
          <button onclick="event.stopPropagation(); editGroupBlock('${groupId}')" class="plan-block-action--edit" aria-label="${t('common.edit')}">
            <span class="material-symbols-rounded">edit</span>
          </button>
          <button onclick="event.stopPropagation(); removeGroupBlock('${groupId}')" class="plan-block-action--delete" aria-label="${t('common.delete')}">
            <span class="material-symbols-rounded">delete</span>
          </button>
        </div>
      </div>
      <div class="plan-block-exercises">
        ${exerciseRows}
      </div>
    </div>
  `;
}

function editGroupBlock(groupId) {
  if (!currentPlan || !currentPlan.items) return;
  const groupItems = currentPlan.items.filter(it => it.groupId === groupId);
  if (groupItems.length === 0) return;

  const exerciseIds = groupItems.map(it => it.exerciseId);
  const execType = getExecutionType(groupItems[0]);

  if (execType === 'emom') {
    openEmomConfigModal(exerciseIds, groupId);
  } else if (execType === 'superset') {
    openSupersetConfigModal(exerciseIds, groupId);
  }
}

function removeGroupBlock(groupId) {
  if (!confirm(t('block.planRender.deleteConfirm'))) return;
  if (!currentPlan || !currentPlan.items) return;
  currentPlan.items = currentPlan.items.filter(it => it.groupId !== groupId);
  renderPlanExercises();
}

// Block-aware reorder: moves a block (single item or entire group) up/down
function movePlanBlock(flatIndex, direction) {
  if (!currentPlan || !Array.isArray(currentPlan.items)) return;
  const item = currentPlan.items[flatIndex];
  if (!item) return;

  const blocks = groupPlanItems(currentPlan.items);

  // Find which block this index belongs to
  let currentBlockIdx = -1;
  let blockStartIndices = [];
  let pos = 0;
  for (let i = 0; i < blocks.length; i++) {
    blockStartIndices.push(pos);
    for (let j = 0; j < blocks[i].items.length; j++) {
      if (currentPlan.items[pos + j] === item) {
        currentBlockIdx = i;
      }
    }
    pos += blocks[i].items.length;
  }

  if (currentBlockIdx < 0) return;
  const targetBlockIdx = currentBlockIdx + direction;
  if (targetBlockIdx < 0 || targetBlockIdx >= blocks.length) return;

  // Rebuild items with the two blocks swapped
  const newBlocks = [...blocks];
  const temp = newBlocks[currentBlockIdx];
  newBlocks[currentBlockIdx] = newBlocks[targetBlockIdx];
  newBlocks[targetBlockIdx] = temp;

  currentPlan.items = newBlocks.flatMap(b => b.items);
  renderPlanExercises();
}

