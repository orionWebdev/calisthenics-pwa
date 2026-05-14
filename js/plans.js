// ========================================
// PLANS MANAGEMENT
// ========================================

let allPlans = [];
let filteredPlans = [];
let editingPlanId = null;
let currentPlan = null; // Currently selected plan for editing
let planMuscleFilter = 'all';
let planEquipmentFilter = 'all';
let planTypeFilter = 'all';

let planIconSelection = null;
let planIconSelectionIsManual = false;

// ========================================
// EXECUTION TYPE HELPERS
// ========================================

const DEFAULT_EXECUTION_TYPE = 'normal';

/**
 * @param {PlanItem} item
 * @returns {ExecutionType}
 */
function getExecutionType(item) {
  return (item && item.executionType) || DEFAULT_EXECUTION_TYPE;
}

/**
 * Gruppiert PlanItems nach groupId. Items ohne groupId bilden Solo-Gruppen.
 * Reihenfolge bleibt erhalten; eine Gruppe erscheint an der Position ihres
 * ersten Items.
 *
 * @param {PlanItem[]} items
 * @returns {{ groupId: string|null, items: PlanItem[] }[]}
 */
function groupPlanItems(items) {
  const groups = [];
  const byId = new Map();
  for (const item of (items || [])) {
    if (item && item.groupId) {
      let group = byId.get(item.groupId);
      if (!group) {
        group = { groupId: item.groupId, items: [] };
        byId.set(item.groupId, group);
        groups.push(group);
      }
      group.items.push(item);
    } else {
      groups.push({ groupId: null, items: [item] });
    }
  }
  return groups;
}

// Workout Type Namen Mapping (4 Typen)
const workoutTypeNames = {
  strength: t('plan.types.strength'),
  bodyweight: t('plan.types.bodyweight'),
  cardio: t('plan.types.cardio'),
  recovery: t('plan.types.recovery'),
  unknown: t('plan.types.unknown')
};

const legacyCardioGoalMap = {
  liss: 'liss',
  hiit: 'hiit',
  zone2: 'liss',
  tempo: 'intervals',
  intervals: 'intervals',
  freestyle: 'freestyle'
};

const cardioGoalNames = {
  liss: t('plan.cardioGoalType.liss'),
  hiit: t('plan.cardioGoalType.hiit'),
  intervals: t('plan.cardioGoalType.intervals'),
  freestyle: t('plan.cardioGoalType.freestyle')
};

const legacyPlanTypeMap = {
  strength: 'strength',
  weights: 'strength',
  gym: 'strength',
  kraft: 'strength',
  krafttraining: 'strength',
  strengthtraining: 'strength',
  bodyweight: 'bodyweight',
  calisthenics: 'bodyweight',
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
  bodyweight: 'sports_gymnastics',
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
  let normalizedType = typeInfo.type;
  let displayType = typeInfo.displayType;

  // Strength plans with bodyweight discipline should be treated as bodyweight
  if (normalizedType === 'strength') {
    const discipline = String(plan.discipline || '').toLowerCase();
    if (discipline === 'bodyweight' || discipline === 'calisthenics') {
      normalizedType = 'bodyweight';
      displayType = 'bodyweight';
    }
  }

  const normalizedItems = normalizePlanItems(plan.items || plan.exercises);
  const normalizedPlan = {
    ...plan,
    type: normalizedType,
    displayType: displayType,
    items: normalizedItems,
    typeLabel: displayType === 'unknown'
      ? workoutTypeNames.unknown
      : workoutTypeNames[displayType] || workoutTypeNames.strength
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

function normalizeIconValue(icon) {
  if (!icon) return null;
  if (typeof icon === 'string') {
    return { kind: 'preset', value: icon };
  }
  if (typeof icon === 'object' && icon.value) {
    return {
      kind: icon.kind === 'url' ? 'url' : 'preset',
      value: icon.value
    };
  }
  return null;
}

function getPlanIconValue(plan, fallbackType) {
  const fallback = {
    kind: 'preset',
    value: planTypeIconFallbacks[fallbackType] || planTypeIconFallbacks.strength
  };
  const icon = normalizeIconValue(plan.icon) || normalizeIconValue(plan.iconKey);
  return icon || fallback;
}

function renderPlanIconMarkup(plan, fallbackType, extraClass = '') {
  const icon = getPlanIconValue(plan, fallbackType);
  const className = extraClass ? ` ${extraClass}` : '';
  if (icon.kind === 'url') {
    return `<img src="${icon.value}" alt="" class="plan-icon-img${className}" loading="lazy" />`;
  }
  return `<span class="material-symbols-rounded${className}">${icon.value}</span>`;
}

function getPlanCardioGoalType(plan) {
  const raw = (plan.cardioGoalType || plan.cardioGoal || plan.goal || '').toString().toLowerCase().trim();
  if (!raw) return '';
  return legacyCardioGoalMap[raw] || raw;
}

function getPlanCardioGoalLabel(plan) {
  const goalType = getPlanCardioGoalType(plan);
  if (!goalType) return '';
  return cardioGoalNames[goalType] || goalType;
}

function getPlanTimestampValue(value) {
  if (!value) return 0;
  if (typeof value.toDate === 'function') {
    return value.toDate().getTime();
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? 0 : parsed.getTime();
}

function getPlanSortValue(plan) {
  const updated = getPlanTimestampValue(plan.updatedAt);
  if (updated) return updated;
  return getPlanTimestampValue(plan.createdAt);
}

function normalizePlanItems(rawItems) {
  if (!Array.isArray(rawItems)) return [];
  return rawItems.map(item => {
    if (!item || typeof item !== 'object') return null;
    const exerciseId = item.exerciseId || item.id;
    if (!exerciseId) return null;

    const target = isPlainObject(item.target) ? { ...item.target } : {};
    if (item.sets !== undefined && target.sets === undefined) {
      target.sets = Number(item.sets) || item.sets;
    }
    if (item.reps !== undefined && target.reps === undefined) {
      target.reps = item.reps;
    }
    if (item.holdSec !== undefined && target.holdSec === undefined) {
      target.holdSec = Number(item.holdSec) || item.holdSec;
    }
    if (item.hold !== undefined && target.holdSec === undefined) {
      const holdValue = Number(item.hold);
      target.holdSec = Number.isFinite(holdValue) ? holdValue : item.hold;
    }

    const restRaw = item.restSec !== undefined ? item.restSec : item.rest;
    const hasRest = restRaw !== undefined && restRaw !== null && restRaw !== '';
    const restSec = hasRest ? Number(restRaw) : NaN;

    const normalized = { exerciseId };
    if (Object.keys(target).length) {
      normalized.target = target;
    }
    if (Number.isFinite(restSec)) {
      normalized.restSec = restSec;
    }

    // Preserve block-grouping fields (EMOM / Superset). Without these the
    // workout tracker can't reconstruct the block and falls back to 'normal',
    // making the EMOM/Superset UI silently disappear.
    if (item.executionType && item.executionType !== 'normal') {
      normalized.executionType = item.executionType;
    }
    if (item.groupId) {
      normalized.groupId = item.groupId;
    }
    if (item.durationSec !== undefined && item.durationSec !== null) {
      const dur = Number(item.durationSec);
      if (Number.isFinite(dur)) normalized.durationSec = dur;
    }
    if (item.intervalSec !== undefined && item.intervalSec !== null) {
      const iv = Number(item.intervalSec);
      if (Number.isFinite(iv)) normalized.intervalSec = iv;
    }

    return normalized;
  }).filter(Boolean);
}

function getPlanItems(plan) {
  if (!plan) return [];
  if (Array.isArray(plan.items)) {
    return normalizePlanItems(plan.items);
  }
  if (Array.isArray(plan.exercises)) {
    return normalizePlanItems(plan.exercises);
  }
  return [];
}

function formatPlanMinutes(minutes) {
  const value = Number(minutes);
  if (!Number.isFinite(value) || value <= 0) return '';
  return t('format.duration.minutes', { minutes: value });
}

function formatPlanDistance(distanceKm) {
  const value = Number(distanceKm);
  if (!Number.isFinite(value) || value <= 0) return '';
  const formatted = value % 1 === 0 ? value.toFixed(0) : value.toFixed(1).replace('.', ',');
  return t('format.distanceKm', { distance: formatted });
}

function getPlanCardioMetaParts(plan) {
  const parts = [];
  const goalLabel = getPlanCardioGoalLabel(plan);
  if (goalLabel) {
    parts.push(`${t('plan.meta.goalPrefix')}: ${goalLabel}`);
  }
  const durationLabel = formatPlanMinutes(plan.targetDurationMin || plan.targetDuration || plan.duration);
  const distanceLabel = formatPlanDistance(plan.targetDistanceKm || plan.targetDistance || plan.distanceKm || plan.distance);
  if (durationLabel) parts.push(durationLabel);
  if (distanceLabel) parts.push(distanceLabel);
  if (!durationLabel && !distanceLabel && !goalLabel) {
    parts.push(t('plan.meta.cardioFallback'));
  }
  return parts;
}

function getPlanRecoveryMetaParts(plan) {
  const durationLabel = formatPlanMinutes(plan.targetDurationMin || plan.targetDuration || plan.duration);
  if (durationLabel) return [durationLabel];
  return [t('plan.meta.recoveryFallback')];
}

function getPlanPickerDescription(plan) {
  const typeLabel = getPlanTypeLabel(plan);
  const type = plan.type || 'strength';
  const meta = type === 'strength' || type === 'bodyweight'
    ? [t('plan.meta.exercises', { count: getPlanItems(plan).length })]
    : type === 'cardio'
      ? getPlanCardioMetaParts(plan)
      : getPlanRecoveryMetaParts(plan);
  return `${typeLabel} • ${meta.join(' · ')}`;
}

// ========================================
// LOAD & DISPLAY PLANS
// ========================================

async function loadPlans() {
  try {
    const plans = await getAllDocsForUser(plansCollection);
    allPlans = plans.map(normalizePlan);
    applyPlanFilters();
  } catch (error) {
    console.error('Error loading plans:', error);
  }
}

function renderPlans() {
  const grid = document.getElementById('plans-grid');
  if (!grid) return;

  if (filteredPlans.length == 0) {
    grid.innerHTML = `
      <div class="col-span-full empty-state">
        <div class="empty-state-icon">
          <span class="material-symbols-rounded">assignment</span>
        </div>
        <h3 class="empty-state-title">${t('plan.list.emptyTitle')}</h3>
        <p class="empty-state-text">${t('plan.list.emptyBody')}</p>
        <button onclick="openAddPlanModal()" class="empty-state-btn">
          <span class="material-symbols-rounded">add_circle</span>
          <span>${t('plan.list.emptyCta')}</span>
        </button>
      </div>
    `;
    return;
  }

  grid.innerHTML = filteredPlans.map(plan => {
    const items = getPlanItems(plan);
    const exerciseCount = items.length;
    const planType = plan.type || 'strength';
    const typeLabel = getPlanTypeLabel(plan);
    const metaParts = planType === 'strength' || planType === 'bodyweight'
      ? [t('plan.meta.exercises', { count: exerciseCount })]
      : planType === 'cardio'
        ? getPlanCardioMetaParts(plan)
        : getPlanRecoveryMetaParts(plan);

    const chips = metaParts
      .filter(Boolean)
      .map(m => `<span class="plan-grid-card-chip">${m}</span>`)
      .join('');
    const iconMarkup = renderPlanIconMarkup(plan, planType);

    return `
      <div class="plan-grid-card plan-grid-card--${planType}" onclick="viewPlanDetails('${plan.id}')">
        <div class="plan-grid-card-accent">
          <span class="plan-grid-card-icon">${iconMarkup}</span>
          <span class="plan-grid-card-type">${typeLabel}</span>
          <button
            type="button"
            onclick="event.stopPropagation(); editPlan('${plan.id}')"
            class="plan-grid-card-edit"
            title="${t('plan.actions.edit')}"
            aria-label="${t('plan.actions.edit')}"
          >
            <span class="material-symbols-rounded">edit</span>
          </button>
        </div>
        <div class="plan-grid-card-body">
          <div class="plan-grid-card-title">${plan.name}</div>
          <div class="plan-grid-card-meta">${chips}</div>
        </div>
        <button
          type="button"
          onclick="event.stopPropagation(); startWorkoutFromPlan('${plan.id}')"
          class="plan-grid-card-start"
        >
          <span class="material-symbols-rounded">play_arrow</span>
          <span>${t('plan.actions.startShort')}</span>
        </button>
      </div>
    `;
  }).join('');
}

function applyPlanFilters() {
  const list = Array.isArray(allPlans) ? allPlans : [];
  filteredPlans = list
    .filter(plan => {
      const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
      const items = getPlanItems(plan);

      if (planTypeFilter !== 'all' && (plan.type || 'strength') !== planTypeFilter) {
        return false;
      }

      if (planMuscleFilter !== 'all') {
        const hasMuscle = items.some(item => {
          const exercise = exercises.find(e => e.id === item.exerciseId);
          if (!exercise) return false;
          // A plan matches a muscle if it contains an exercise whose
          // PRIMARY muscle is that group.
          return exercisePrimaryMatchesMuscle(exercise, planMuscleFilter);
        });
        if (!hasMuscle) return false;
      }

      if (planEquipmentFilter !== 'all') {
        const hasEquipment = items.some(item => {
          const exercise = exercises.find(e => e.id === item.exerciseId);
          if (!exercise) return false;
          const eq = Array.isArray(exercise.equipment) ? exercise.equipment : [];
          return eq.includes(planEquipmentFilter);
        });
        if (!hasEquipment) return false;
      }

      return true;
    })
    .sort((a, b) => {
      const aTime = getPlanSortValue(a);
      const bTime = getPlanSortValue(b);
      if (aTime !== bTime) return bTime - aTime;
      const aName = (a.name || '').toString();
      const bName = (b.name || '').toString();
      return aName.localeCompare(bName, 'de', { sensitivity: 'base' });
    });
  updatePlanMuscleFilterUI();
  renderPlans();
}

function setPlanMuscleFilter(muscle) {
  planMuscleFilter = muscle || 'all';
  applyPlanFilters();
}

function setPlanEquipmentFilter(equipment) {
  planEquipmentFilter = equipment || 'all';
  applyPlanFilters();
}

function setPlanTypeFilter(type) {
  planTypeFilter = type || 'all';
  applyPlanFilters();
}

// Sync the filter-chip trigger buttons with the current filter state.
function updatePlanMuscleFilterUI() {
  const typeLabel = document.getElementById('plan-type-filter-label');
  const typeBtn = document.getElementById('plan-type-filter-btn');
  const typeActive = planTypeFilter && planTypeFilter !== 'all';
  if (typeLabel) {
    typeLabel.textContent = typeActive
      ? t('plan.filters.' + planTypeFilter)
      : t('plan.filters.allTypes');
  }
  if (typeBtn) typeBtn.classList.toggle('active', !!typeActive);

  const muscleLabel = document.getElementById('plan-muscle-filter-label');
  const muscleBtn = document.getElementById('plan-muscle-filter-btn');
  const muscleActive = planMuscleFilter && planMuscleFilter !== 'all';
  if (muscleLabel) {
    muscleLabel.textContent = muscleActive
      ? (getMuscleNames()[planMuscleFilter] || planMuscleFilter)
      : t('exercise.filters.allMuscles');
  }
  if (muscleBtn) muscleBtn.classList.toggle('active', !!muscleActive);

  const equipLabel = document.getElementById('plan-equipment-filter-label');
  const equipBtn = document.getElementById('plan-equipment-filter-btn');
  const equipActive = planEquipmentFilter && planEquipmentFilter !== 'all';
  if (equipLabel) {
    equipLabel.textContent = equipActive
      ? (equipmentNames[planEquipmentFilter] || planEquipmentFilter)
      : t('exercise.filters.allEquipment');
  }
  if (equipBtn) equipBtn.classList.toggle('active', !!equipActive);
}

// Plan filters open the shared multi-select bottom sheet (single-select use).
function openPlanTypeFilterSheet() {
  const filterOptions = [
    { value: '', label: t('plan.filters.allTypes'), description: '' },
    { value: 'strength', label: t('plan.filters.strength'), description: '' },
    { value: 'bodyweight', label: t('plan.filters.bodyweight'), description: '' },
    { value: 'cardio', label: t('plan.filters.cardio'), description: '' },
    { value: 'recovery', label: t('plan.filters.recovery'), description: '' }
  ];

  openBottomSheet({
    title: t('plan.type'),
    options: filterOptions,
    selectedValues: (planTypeFilter && planTypeFilter !== 'all') ? [planTypeFilter] : [''],
    enableSearch: false,
    fieldId: 'plan-type-filter-btn',
    onConfirm: (selectedValues) => {
      const selected = selectedValues.length > 0 ? selectedValues[selectedValues.length - 1] : '';
      setPlanTypeFilter(selected);
    }
  });
}

function openPlanMuscleFilterSheet() {
  const mn = typeof getMuscleNames === 'function' ? getMuscleNames() : {};
  const iconOf = (key) => (typeof getMuscleIconPath === 'function' ? getMuscleIconPath(key) : undefined);
  const filterOptions = [
    { value: '', label: t('exercise.filters.allMuscles'), description: '' },
    { value: 'chest', label: mn.chest, icon: iconOf('chest') },
    { value: 'back', label: mn.back, icon: iconOf('back') },
    { value: 'biceps', label: mn.biceps, icon: iconOf('biceps') },
    { value: 'triceps', label: mn.triceps, icon: iconOf('triceps') },
    { value: 'shoulders', label: mn.shoulders, icon: iconOf('shoulders') },
    { value: 'core', label: mn.core, icon: iconOf('core') },
    { value: 'legs', label: mn.legs, icon: iconOf('legs') },
    { value: 'full-body', label: mn['full-body'], icon: iconOf('full-body') }
  ];

  openBottomSheet({
    title: t('exercise.muscleFilter.title'),
    options: filterOptions,
    selectedValues: (planMuscleFilter && planMuscleFilter !== 'all') ? [planMuscleFilter] : [''],
    enableSearch: false,
    fieldId: 'plan-muscle-filter-btn',
    onConfirm: (selectedValues) => {
      const selected = selectedValues.length > 0 ? selectedValues[selectedValues.length - 1] : '';
      setPlanMuscleFilter(selected);
    }
  });
}

function openPlanEquipmentFilterSheet() {
  const mainEquipment = ['bodyweight', 'pull-up-bar', 'parallettes', 'rings', 'dumbbell', 'barbell', 'resistance-bands', 'gym-machine', 'bench'];
  const filterOptions = [{ value: '', label: t('exercise.filters.allEquipment'), description: '' }];
  mainEquipment.forEach(eq => {
    filterOptions.push({ value: eq, label: equipmentNames[eq] || eq, description: '' });
  });

  openBottomSheet({
    title: t('exercise.equipmentFilter.title'),
    options: filterOptions,
    selectedValues: (planEquipmentFilter && planEquipmentFilter !== 'all') ? [planEquipmentFilter] : [''],
    enableSearch: false,
    fieldId: 'plan-equipment-filter-btn',
    onConfirm: (selectedValues) => {
      const selected = selectedValues.length > 0 ? selectedValues[selectedValues.length - 1] : '';
      setPlanEquipmentFilter(selected);
    }
  });
}

function applyPlanI18n() {
  const setText = (id, text) => {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
  };
  const setPlaceholder = (id, text) => {
    const el = document.getElementById(id);
    if (el) el.placeholder = text;
  };
  const setAriaLabel = (id, text) => {
    const el = document.getElementById(id);
    if (el) el.setAttribute('aria-label', text);
  };

  setText('plan-add-btn-label', t('plan.actions.newPlan'));
  setText('plans-loading-text', t('plan.list.loading'));

  setText('plan-section-basics-title', t('plan.sections.basics'));
  setText('plan-name-label', `${t('plan.name')} *`);
  setPlaceholder('plan-name', t('plan.namePlaceholder'));
  setText('plan-type-label', `${t('plan.type')} *`);
  setText('plan-icon-label', t('plan.icon'));

  const planTypeSelect = document.getElementById('plan-type');
  if (planTypeSelect) {
    const optionLabels = {
      strength: t('plan.typeOptions.strength'),
      bodyweight: t('plan.typeOptions.bodyweight'),
      cardio: t('plan.typeOptions.cardio'),
      recovery: t('plan.typeOptions.recovery')
    };
    planTypeSelect.querySelectorAll('option').forEach(option => {
      const label = optionLabels[option.value];
      if (label) option.textContent = label;
    });
  }

  const currentType = document.getElementById('plan-type')?.value || 'strength';
  const exercisesTitleKey = currentType === 'bodyweight'
    ? 'plan.sections.contentBodyweight'
    : 'plan.sections.contentStrength';
  setText('plan-section-exercises-title', t(exercisesTitleKey));
  setText('plan-exercises-hint', t('plan.exercisesHint'));

  setText('plan-section-cardio-title', t('plan.sections.contentCardio'));
  setText('plan-cardio-goal-label', t('plan.cardioGoalType.label'));
  setText('plan-cardio-duration-label', t('plan.cardio.durationLabel'));
  setText('plan-cardio-distance-label', t('plan.cardio.distanceLabel'));
  setText('plan-cardio-activity-label', t('plan.cardio.activityLabel'));
  setText('plan-cardio-target-hint', t('plan.cardio.targetHint'));

  const cardioGoalLabels = {
    liss: t('plan.cardioGoalType.liss'),
    hiit: t('plan.cardioGoalType.hiit'),
    intervals: t('plan.cardioGoalType.intervals'),
    freestyle: t('plan.cardioGoalType.freestyle')
  };
  document.querySelectorAll('#plan-cardio-goal-selector .training-type-btn').forEach(btn => {
    const goal = btn.dataset.goal;
    const label = cardioGoalLabels[goal];
    const labelEl = btn.querySelector('.training-type-label');
    if (labelEl && label) labelEl.textContent = label;
  });

  const activityLabels = {
    run: t('plan.cardio.activityOptions.run'),
    bike: t('plan.cardio.activityOptions.bike'),
    swim: t('plan.cardio.activityOptions.swim'),
    row: t('plan.cardio.activityOptions.row'),
    other: t('plan.cardio.activityOptions.other')
  };
  const activitySelect = document.getElementById('plan-cardio-activity');
  if (activitySelect) {
    activitySelect.querySelectorAll('option').forEach(option => {
      const label = activityLabels[option.value];
      if (label) option.textContent = label;
    });
  }

  setText('plan-section-recovery-title', t('plan.sections.contentRecovery'));
  setText('plan-recovery-duration-label', t('plan.recovery.durationLabel'));
  setText('plan-recovery-target-hint', t('plan.recovery.targetHint'));


  setText('plan-save-btn-label', t('plan.actions.save'));
  setText('plan-delete-btn-label', t('common.delete'));
  setText('plan-cancel-btn-label', t('plan.actions.cancel'));

  setText('exercise-picker-title', t('plan.exercisePicker.title'));
  setPlaceholder('exercise-picker-search', t('plan.exercisePicker.searchPlaceholder'));

  const muscleLabelMap = typeof getMuscleNames === 'function' ? getMuscleNames() : {};
  setText('exercise-picker-filter-all-label', t('plan.filters.all'));
  ['chest', 'back', 'shoulders', 'arms', 'biceps', 'triceps', 'core', 'legs', 'calf'].forEach(m => {
    setText(`exercise-picker-filter-${m}-label`, muscleLabelMap[m] || '');
  });

  setText('quick-exercise-muscles-label', t('exercise.muscleFilter.required'));

  setText('exercise-config-title', t('plan.exerciseConfig.title'));
  setText('exercise-config-sets-label', t('plan.exerciseConfig.setsLabel'));
  setText('exercise-config-reps-label', t('plan.exerciseConfig.repsLabel'));
  setText('exercise-config-hold-label', t('plan.exerciseConfig.holdLabel'));
  setText('exercise-sets-unit', t('workout.logging.sets'));
  setText('exercise-reps-unit', t('workout.logging.totalReps'));
  setText('exercise-hold-unit', t('common.secondsShort', { n: '' }));
  setAriaLabel('exercise-sets-btn', t('plan.exerciseConfig.setsLabel'));
  setAriaLabel('exercise-reps-btn', t('plan.exerciseConfig.repsLabel'));
  setAriaLabel('exercise-hold-btn', t('plan.exerciseConfig.holdLabel'));
  setText('exercise-rest-label-text', t('plan.exerciseConfig.restLabel'));
  setText('exercise-rest-min-label', `0 ${t('plan.exerciseConfig.restSec')}`);
  setText('exercise-rest-max-label', `5 ${t('plan.exerciseConfig.restMin')}`);
  setText('exercise-config-save-label', t('common.add'));
  setText('exercise-config-cancel-label', t('common.cancel'));

  const restSlider = document.getElementById('exercise-rest');
  if (restSlider) {
    updateRestDisplay(restSlider);
  }

  // Block Training labels
  setText('block-type-sheet-title', t('block.typeSheet.title'));
  setText('block-type-normal-label', t('block.typeSheet.normal'));
  setText('block-type-normal-desc', t('block.typeSheet.normalDesc'));
  setText('block-type-superset-label', t('block.typeSheet.superset'));
  setText('block-type-superset-desc', t('block.typeSheet.supersetDesc'));
  setText('block-type-emom-label', t('block.typeSheet.emom'));
  setText('block-type-emom-desc', t('block.typeSheet.emomDesc'));
  setText('emom-config-title', t('block.emomConfig.title'));
  setText('emom-config-duration-label', t('block.emomConfig.duration'));
  setText('emom-config-interval-label', t('block.emomConfig.interval'));
  setText('emom-config-save-btn', t('block.emomConfig.save'));
  setText('superset-config-title', t('block.supersetConfig.title'));
  setText('superset-rest-label-text', t('block.supersetConfig.restBetween'));
  setText('superset-config-save-btn', t('block.supersetConfig.save'));

  const currentGoal = document.getElementById('plan-cardio-goal-type')?.value || 'liss';
  updatePlanCardioGoalInfo(currentGoal);

  // Refresh the plan filter-chip trigger labels for the active locale
  updatePlanMuscleFilterUI();
}


// ========================================
// MODAL MANAGEMENT
// ========================================

function openAddPlanModal() {
  editingPlanId = null;
  currentPlan = {
    items: [],
    icon: null
  };
  const titleEl = document.getElementById('plan-modal-title');
  if (titleEl) titleEl.textContent = t('plan.modal.createTitle');
  togglePlanDeleteButton(false);
  clearPlanForm();
  applyPlanI18n();
  document.getElementById('plan-modal').classList.add('active');
  resetPlanModalPosition();
}

function editPlan(id) {
  editingPlanId = id;
  const plan = allPlans.find(p => p.id === id);

  if (!plan) return;

  currentPlan = { ...plan };
  const titleEl = document.getElementById('plan-modal-title');
  if (titleEl) titleEl.textContent = t('plan.modal.editTitle');
  togglePlanDeleteButton(true);
  populatePlanForm(plan);
  applyPlanI18n();
  document.getElementById('plan-modal').classList.add('active');
  resetPlanModalPosition();
}

function closePlanModal() {
  document.getElementById('plan-modal').classList.remove('active');
  clearPlanForm();
  currentPlan = null;
  togglePlanDeleteButton(false);
}

function resetPlanModalPosition() {
  const modal = document.getElementById('plan-modal');
  if (!modal) return;
  const content = modal.querySelector('.modal-content');
  if (content) content.scrollTop = 0;

  const addBtn = document.getElementById('plan-add-exercise-btn');
  if (addBtn) {
    addBtn.setAttribute('aria-label', t('plan.addExercise'));
  }

  const firstField = document.getElementById('plan-name');
  if (!firstField) return;
  requestAnimationFrame(() => {
    try {
      firstField.focus({ preventScroll: true });
    } catch (error) {
      firstField.focus();
    }
  });
}

function clearPlanForm() {
  document.getElementById('plan-name').value = '';
  document.getElementById('plan-type').value = 'strength';
  planIconSelection = null;
  planIconSelectionIsManual = false;
  setPlanIcon(planTypeIconFallbacks.strength);
  setPlanCardioGoalType('liss');
  const cardioDuration = document.getElementById('plan-cardio-duration');
  if (cardioDuration) cardioDuration.value = '';
  const cardioDistance = document.getElementById('plan-cardio-distance');
  if (cardioDistance) cardioDistance.value = '';
  const cardioActivity = document.getElementById('plan-cardio-activity');
  if (cardioActivity) cardioActivity.value = 'run';
  const recoveryDuration = document.getElementById('plan-recovery-duration');
  if (recoveryDuration) recoveryDuration.value = '';

  // Trigger type change to show correct fields
  onPlanTypeChange('strength');

  // Clear exercises list
  if (currentPlan) {
    currentPlan.items = [];
  }
  renderPlanExercises();
}

function populatePlanForm(plan) {
  document.getElementById('plan-name').value = plan.name || '';
  document.getElementById('plan-type').value = plan.type || 'strength';

  // Type-specific fields
  if (plan.type === 'cardio') {
    const goalType = getPlanCardioGoalType(plan) || 'liss';
    setPlanCardioGoalType(goalType);
    const durationInput = document.getElementById('plan-cardio-duration');
    if (durationInput) durationInput.value = plan.targetDurationMin || plan.targetDuration || plan.duration || '';
    const distanceInput = document.getElementById('plan-cardio-distance');
    if (distanceInput) distanceInput.value = plan.targetDistanceKm || plan.targetDistance || plan.distanceKm || plan.distance || '';
    const activityInput = document.getElementById('plan-cardio-activity');
    if (activityInput) activityInput.value = plan.activityType || 'run';
  } else if (plan.type === 'recovery') {
    const recoveryInput = document.getElementById('plan-recovery-duration');
    if (recoveryInput) recoveryInput.value = plan.targetDurationMin || plan.targetDuration || plan.duration || '';
  }

  // Icon
  const icon = getPlanIconValue(plan, plan.type || 'strength');
  if (icon.kind === 'preset') {
    planIconSelectionIsManual = true;
    setPlanIcon(icon.value);
  } else {
    planIconSelectionIsManual = true;
    planIconSelection = icon;
    setPlanIcon(planTypeIconFallbacks[plan.type] || planTypeIconFallbacks.strength, { trackSelection: false });
  }

  // Trigger type change to show correct fields
  onPlanTypeChange(plan.type || 'strength');

  // Load exercises
  currentPlan.items = getPlanItems(plan);
  renderPlanExercises();
}

// ========================================
// PLAN ICON SELECTION
// ========================================

function setPlanIcon(icon, options = {}) {
  const iconInput = document.getElementById('plan-icon');
  if (iconInput) iconInput.value = icon;

  document.querySelectorAll('#plan-icon-picker .icon-picker-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.icon === icon);
  });

  const trackSelection = options.trackSelection !== false;
  if (trackSelection) {
    planIconSelection = icon;
  }
}

function selectPlanIcon(icon) {
  planIconSelectionIsManual = true;
  setPlanIcon(icon);
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
 * 4 Typen: strength, bodyweight, cardio, recovery
 */
function onPlanTypeChange(type) {
  const exercisesSection = document.getElementById('plan-exercises-section');
  const cardioSection = document.getElementById('plan-cardio-section');
  const recoverySection = document.getElementById('plan-recovery-section');

  // Helper to show/hide elements
  const show = (el) => { if (el) el.style.display = ''; };
  const hide = (el) => { if (el) el.style.display = 'none'; };

  // Hide all type-specific sections first
  hide(exercisesSection);
  hide(cardioSection);
  hide(recoverySection);

  // Apply type-specific visibility and defaults
  const applyDefaultIcon = (icon) => {
    if (!planIconSelectionIsManual) {
      setPlanIcon(icon);
    }
  };

  switch (type) {
    case 'cardio':
      show(cardioSection);
      applyDefaultIcon(planTypeIconFallbacks.cardio);
      break;

    case 'recovery':
      show(recoverySection);
      applyDefaultIcon(planTypeIconFallbacks.recovery);
      break;

    case 'bodyweight':
      show(exercisesSection);
      applyDefaultIcon(planTypeIconFallbacks.bodyweight);
      break;

    case 'strength':
    default:
      show(exercisesSection);
      applyDefaultIcon(planTypeIconFallbacks.strength);
      break;
  }

  applyPlanI18n();
}

function setPlanCardioGoalType(goal) {
  const input = document.getElementById('plan-cardio-goal-type');
  if (input) input.value = goal;

  document.querySelectorAll('#plan-cardio-goal-selector .training-type-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.goal === goal);
  });

  updatePlanCardioGoalInfo(goal);
}

function updatePlanCardioGoalInfo(goal) {
  const text = t(`plan.cardioGoalType.info.${goal}`);
  const infoText = document.getElementById('plan-cardio-goal-info-text');
  if (infoText) infoText.textContent = text;
}

function togglePlanCardioGoalInfo() {
  const panel = document.getElementById('plan-cardio-goal-info');
  if (!panel) return;
  const isVisible = panel.style.display !== 'none';
  panel.style.display = isVisible ? 'none' : 'block';
}

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
      showEdgeFeedback('error', 'Fehler beim Speichern');
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
        <button onclick="event.stopPropagation(); editPlanExercise(${index})" class="plan-item-action plan-item-action--edit" aria-label="${t('common.edit') || 'Bearbeiten'}">
          <span class="material-symbols-rounded">edit</span>
        </button>
        <button onclick="event.stopPropagation(); removePlanExercise(${index})" class="plan-item-action plan-item-action--delete" aria-label="${t('common.delete') || 'Löschen'}">
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
          <button onclick="event.stopPropagation(); editGroupBlock('${groupId}')" class="plan-block-action--edit" aria-label="${t('common.edit') || 'Bearbeiten'}">
            <span class="material-symbols-rounded">edit</span>
          </button>
          <button onclick="event.stopPropagation(); removeGroupBlock('${groupId}')" class="plan-block-action--delete" aria-label="${t('common.delete') || 'Löschen'}">
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

// ========================================
// SAVE PLAN
// ========================================

async function savePlan() {
  const name = document.getElementById('plan-name').value.trim();
  const type = document.getElementById('plan-type').value;
  const iconSelection = planIconSelection || document.getElementById('plan-icon')?.value;

  // Validation - Name ist immer erforderlich
  if (!name) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('errors.planNameRequired'));
    }
    return;
  }

  // Build plan data based on type
  const planData = {
    name,
    type
  };

  // Resolve icon (preset string or existing object)
  if (iconSelection) {
    planData.icon = iconSelection;
  } else if (currentPlan && currentPlan.icon) {
    planData.icon = currentPlan.icon;
  } else {
    planData.icon = planTypeIconFallbacks[type] || planTypeIconFallbacks.strength;
  }

  if (typeof firebase !== 'undefined' && firebase.firestore) {
    planData.updatedAt = firebase.firestore.FieldValue.serverTimestamp();
    if (!editingPlanId) {
      planData.createdAt = firebase.firestore.FieldValue.serverTimestamp();
    }
  }

  // Type-specific fields
  switch (type) {
    case 'strength':
    case 'bodyweight': {
      const items = normalizePlanItems(currentPlan && currentPlan.items ? currentPlan.items : []);
      if (items.length === 0) {
        if (typeof showEdgeFeedback === 'function') {
          showEdgeFeedback('error', t('errors.planExercisesRequired'));
        }
        return;
      }
      planData.items = items;
      break;
    }
    case 'cardio':
      // Cardio: goal type + optional duration/distance/activity
      planData.cardioGoalType = document.getElementById('plan-cardio-goal-type')?.value || 'liss';
      const cardioDuration = parseFloat(document.getElementById('plan-cardio-duration')?.value);
      const cardioDistance = parseFloat(document.getElementById('plan-cardio-distance')?.value);
      const activityType = document.getElementById('plan-cardio-activity')?.value;
      if (Number.isFinite(cardioDuration) && cardioDuration > 0) {
        planData.targetDurationMin = cardioDuration;
      }
      if (Number.isFinite(cardioDistance) && cardioDistance > 0) {
        planData.targetDistanceKm = cardioDistance;
      }
      if (activityType) {
        planData.activityType = activityType;
      }
      break;

    case 'recovery':
      // Recovery: optional duration
      const recoveryDuration = parseFloat(document.getElementById('plan-recovery-duration')?.value);
      if (Number.isFinite(recoveryDuration) && recoveryDuration > 0) {
        planData.targetDurationMin = recoveryDuration;
      }
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
      showEdgeFeedback('error', t('errors.saveFailed'));
    }
  }
}

function togglePlanDeleteButton(visible) {
  const btn = document.getElementById('plan-delete-btn');
  if (!btn) return;
  btn.classList.toggle('hidden', !visible);
  const label = document.getElementById('plan-delete-btn-label');
  if (label) label.textContent = t('common.delete');
}

async function deletePlan() {
  if (!editingPlanId) return;
  if (!confirm(t('plan.deleteConfirm'))) return;

  try {
    await deleteDoc(plansCollection, editingPlanId);
    closePlanModal();
    await loadPlans();
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', t('plan.deleteSuccess'));
    }
  } catch (error) {
    console.error('Error deleting plan:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('plan.deleteError'));
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
      showEdgeFeedback('error', t('errors.exercisesLoading'));
    }
    return;
  }

  const planType = plan.type || 'strength';
  const typeLabel = getPlanTypeLabel(plan);
  const metaParts = planType === 'strength' || planType === 'bodyweight'
    ? [t('plan.meta.exercises', { count: getPlanItems(plan).length })]
    : planType === 'cardio'
      ? getPlanCardioMetaParts(plan)
      : getPlanRecoveryMetaParts(plan);

  const items = getPlanItems(plan);
  let exercisesHTML = '';
  if ((planType === 'strength' || planType === 'bodyweight') && items.length > 0) {
    exercisesHTML = items.map((item, index) => {
      const exercise = allExercises.find(e => e.id === item.exerciseId);
      if (!exercise) return '';
      const target = item.target || {};
      const sets = target.sets !== undefined && target.sets !== null ? target.sets : '-';
      const reps = target.reps ? target.reps : '';
      const holdSec = target.holdSec ? `${target.holdSec} ${t('plan.exerciseConfig.restSec')}` : '';
      const targetValue = reps || holdSec || '-';
      const restValue = item.restSec !== undefined && item.restSec !== null
        ? `${item.restSec} ${t('plan.exerciseConfig.restSec')}`
        : '';

      return `
        <div class="plan-detail-exercise-item">
          <div class="flex items-start gap-3">
            <div class="plan-exercise-number">${index + 1}</div>
            <div class="flex-1">
              <h4 class="font-semibold text-white">${getExerciseName(exercise)}</h4>
              <div class="flex flex-wrap gap-3 mt-2 text-sm text-gray-400">
                <span class="flex items-center gap-1">
                  <span class="material-symbols-rounded" style="font-size: 16px;">repeat</span>
                  ${sets} ${t('plan.exerciseConfig.setsShort')}
                </span>
                <span class="flex items-center gap-1">
                  <span class="material-symbols-rounded" style="font-size: 16px;">fitness_center</span>
                  ${targetValue}
                </span>
                ${restValue ? `
                  <span class="flex items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 16px;">hourglass_empty</span>
                    ${restValue}
                  </span>
                ` : ''}
              </div>
            </div>
          </div>
        </div>
      `;
    }).join('');
  }

  // Modal content
  const modalContent = `
    <div class="space-y-4">
      <div class="flex flex-col gap-1">
        <span class="plan-type-badge plan-type-badge--neutral">${typeLabel}</span>
        <span class="text-sm text-gray-400">${metaParts.join(' · ')}</span>
      </div>

      <!-- Notes -->
      ${plan.notes ?
        `<div>
          <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
            <span class="material-symbols-rounded" style="font-size: 18px;">description</span>
            ${t('plan.notes')}
          </label>
          <p class="text-gray-300 leading-relaxed">${plan.notes}</p>
        </div>`
        : ''
      }

      ${planType === 'strength' || planType === 'bodyweight' ? `
        <div>
          <label class="flex items-center gap-2 text-sm font-medium text-gray-400 mb-3">
            <span class="material-symbols-rounded" style="font-size: 18px;">fitness_center</span>
            ${t('plan.exercises')} (${items.length})
          </label>
          <div class="space-y-2">
            ${exercisesHTML}
          </div>
        </div>
      ` : `
        <div class="text-sm text-gray-400">
          ${metaParts.join(' · ')}
        </div>
      `}

      <!-- Action Buttons -->
      <div class="flex gap-3 pt-4">
        <button
          onclick="closeGenericModal(); editPlan('${plan.id}')"
          class="flex-1 bg-gradient-to-r from-pink-600 to-pink-700 hover:from-pink-500 hover:to-pink-600 py-3 rounded-xl font-semibold transition-all flex items-center justify-center gap-2"
        >
          <span class="material-symbols-rounded" style="font-size: 20px;">edit</span>
          ${t('plan.actions.edit')}
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
  onUserCollectionChange(plansCollection, (plans) => {
    allPlans = plans.map(normalizePlan);
    applyPlanFilters();
  });
}

// Export Plan Picker functions globally
window.openPlanPickerSheet = openPlanPickerSheet;
window.closePlanPickerSheet = closePlanPickerSheet;
window.selectPlanFromPicker = selectPlanFromPicker;
window.filterPlanPicker = filterPlanPicker;
window.setPlanCardioGoalType = setPlanCardioGoalType;
window.togglePlanCardioGoalInfo = togglePlanCardioGoalInfo;
window.selectPlanIcon = selectPlanIcon;

applyPlanI18n();
