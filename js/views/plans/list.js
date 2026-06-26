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
    const iconMarkup = renderPlanDustMarkup(plan, planType);
    const muscleDots = renderPlanMuscleDots(plan, planType);

    return `
      <div class="plan-grid-card plan-grid-card--${planType}" onclick="viewPlanDetails('${plan.id}')">
        <div class="plan-grid-card-accent">
          ${iconMarkup}
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
          ${muscleDots}
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
  const dot = (key) => (typeof getMuscleIcon === 'function' ? getMuscleIcon(key, 'muscle-icon--lg') : undefined);
  const filterOptions = [
    { value: '', label: t('exercise.filters.allMuscles'), description: '' },
    { value: 'chest', label: mn.chest, iconHtml: dot('chest') },
    { value: 'back', label: mn.back, iconHtml: dot('back') },
    { value: 'biceps', label: mn.biceps, iconHtml: dot('biceps') },
    { value: 'triceps', label: mn.triceps, iconHtml: dot('triceps') },
    { value: 'shoulders', label: mn.shoulders, iconHtml: dot('shoulders') },
    { value: 'core', label: mn.core, iconHtml: dot('core') },
    { value: 'legs', label: mn.legs, iconHtml: dot('legs') },
    { value: 'full-body', label: mn['full-body'], iconHtml: dot('full-body') }
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


