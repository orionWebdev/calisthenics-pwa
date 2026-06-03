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

