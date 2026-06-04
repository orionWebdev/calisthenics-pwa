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
    } else {
      await addDoc(plansCollection, planData);
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
