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

  // Intentionally NOT auto-focusing the name field — opening the editor should
  // not pop the keyboard (user taps the field when ready).
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

