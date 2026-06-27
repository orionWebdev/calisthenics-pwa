// ========================================
// EXERCISE LOCALE HELPERS
// ========================================

function getExerciseName(exercise) {
  if (!exercise) return '';
  if (currentLocale === 'de' && exercise.name_de) return exercise.name_de;
  return exercise.name || '';
}

function applyExerciseLocale(exercise) {
  const localeData = exercise.i18n?.[currentLocale];
  if (!localeData) return exercise;
  return { ...exercise, ...localeData };
}

// ========================================
// EXERCISE V3 TYPE & PATTERN CONSTANTS
// ========================================

const exerciseTypes = {
  strength: { icon: 'fitness_center' },
  bodyweight: { icon: 'sports_gymnastics' },
  cardio: { icon: 'directions_run' },
  recovery: { icon: 'spa' },
  // Legacy – hidden from UI, still valid in data
  mobility: { icon: 'self_improvement', hidden: true }
};

const exercisePatterns = {
  push: { icon: 'arrow_upward' },
  pull: { icon: 'arrow_downward' },
  legs: { icon: 'directions_walk' },
  core: { icon: 'self_improvement' },
  full: { icon: 'accessibility_new' }
};

// ========================================
// INSTRUCTIONS NORMALIZATION (Legacy Support)
// ========================================

function splitInstructionText(text) {
  if (!text || typeof text !== 'string') return [];
  const trimmed = text.trim();
  if (!trimmed) return [];

  const lineSplit = trimmed
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(Boolean);

  if (lineSplit.length > 1) return lineSplit;

  const bulletSplit = trimmed
    .split(/•|â€¢|-|\u2022/)
    .map(part => part.trim())
    .filter(Boolean);

  if (bulletSplit.length > 1) return bulletSplit;

  return [trimmed];
}

function normalizeInstructionList(value) {
  if (Array.isArray(value)) {
    return value.map(item => String(item || '').trim()).filter(Boolean);
  }
  if (typeof value === 'string') {
    return splitInstructionText(value);
  }
  return [];
}

function normalizeExerciseInstructions(exercise) {
  const normalized = {
    instructionsSteps: [],
    setupNotes: '',
    cues: [],
    commonMistakes: [],
    progressions: []
  };

  const steps = normalizeInstructionList(exercise.instructionsSteps);
  if (steps.length > 0) {
    normalized.instructionsSteps = steps;
  } else if (Array.isArray(exercise.instructions)) {
    normalized.instructionsSteps = normalizeInstructionList(exercise.instructions);
  } else if (exercise.instructions && typeof exercise.instructions === 'object') {
    const legacySteps = normalizeInstructionList(exercise.instructions.execution || exercise.instructions.setup);
    normalized.instructionsSteps = legacySteps;
    normalized.setupNotes = typeof exercise.instructions.setup === 'string' ? exercise.instructions.setup.trim() : '';
    normalized.cues = normalizeInstructionList(exercise.instructions.cues);
    normalized.commonMistakes = normalizeInstructionList(exercise.instructions.mistakes);
    normalized.progressions = normalizeInstructionList(exercise.instructions.progressions);
  }

  if (normalized.instructionsSteps.length === 0) {
    const legacyText = exercise.instructionsText || exercise.description || '';
    normalized.instructionsSteps = normalizeInstructionList(legacyText);
  }

  if (typeof exercise.setupNotes === 'string' && exercise.setupNotes.trim()) {
    normalized.setupNotes = exercise.setupNotes.trim();
  } else if (Array.isArray(exercise.setupSteps) && exercise.setupSteps.length > 0) {
    normalized.setupNotes = normalizeInstructionList(exercise.setupSteps).join('\n');
  }

  if (Array.isArray(exercise.cues) || typeof exercise.cues === 'string') {
    normalized.cues = normalizeInstructionList(exercise.cues);
  }

  if (Array.isArray(exercise.commonMistakes) || typeof exercise.commonMistakes === 'string') {
    normalized.commonMistakes = normalizeInstructionList(exercise.commonMistakes);
  } else if (Array.isArray(exercise.mistakes) || typeof exercise.mistakes === 'string') {
    normalized.commonMistakes = normalizeInstructionList(exercise.mistakes);
  }

  if (Array.isArray(exercise.progressions) || typeof exercise.progressions === 'string') {
    normalized.progressions = normalizeInstructionList(exercise.progressions);
  }

  return normalized;
}

function normalizeExerciseForRuntime(exercise) {
  const normalized = normalizeExerciseInstructions(exercise);
  return {
    ...exercise,
    instructionsSteps: normalized.instructionsSteps,
    setupNotes: normalized.setupNotes,
    cues: normalized.cues,
    commonMistakes: normalized.commonMistakes,
    progressions: normalized.progressions
  };
}

// ========================================
// EXERCISE V3 MAPPERS
// ========================================

/**
 * Maps any exercise document (legacy or new) to v3 runtime shape.
 * Adds defaults for missing v3 fields, maps imageUrl to visual.
 */
function mapExerciseToV3(exercise) {
  const localized = applyExerciseLocale(exercise);
  const normalized = normalizeExerciseInstructions(localized);

  // Type: default 'strength' for legacy; map removed types to bodyweight
  let type = exercise.type && exerciseTypes[exercise.type] ? exercise.type : 'strength';
  if (type === 'mobility') type = 'bodyweight';

  // Pattern: default 'full' for legacy
  const pattern = exercise.pattern && exercisePatterns[exercise.pattern] ? exercise.pattern : 'full';

  // Difficulty: ensure enum string
  const difficulty = convertDifficultyToEnum(exercise.difficulty) || 'intermediate';

  // Instructions: use normalized
  const instructions = normalized.instructionsSteps;

  // Visual: map from legacy imageUrl if needed
  let visual = exercise.visual || null;
  if (!visual && exercise.imageUrl) {
    visual = { kind: 'url', value: exercise.imageUrl };
  }

  // Variants: keep if array, default empty
  const variants = Array.isArray(exercise.variants) ? exercise.variants : [];

  // Notes
  const notes = exercise.notes || '';

  // Muscle model: prefer explicit primary/secondary (curated dataset). Derive the
  // flat `muscleGroups` (primary first) for all legacy consumers when missing.
  const primaryMuscles = Array.isArray(exercise.primaryMuscles) ? exercise.primaryMuscles.filter(Boolean) : [];
  const secondaryMuscles = Array.isArray(exercise.secondaryMuscles) ? exercise.secondaryMuscles.filter(Boolean) : [];
  let muscleGroups;
  if (primaryMuscles.length || secondaryMuscles.length) {
    muscleGroups = [...new Set([...primaryMuscles, ...secondaryMuscles])];
  } else {
    muscleGroups = Array.isArray(exercise.muscleGroups) ? exercise.muscleGroups : [];
  }

  return {
    ...exercise,
    type,
    pattern,
    difficulty,
    instructions,
    instructionsSteps: instructions,
    visual,
    variants,
    notes,
    setupNotes: normalized.setupNotes,
    cues: normalized.cues,
    commonMistakes: normalized.commonMistakes,
    progressions: normalized.progressions,
    primaryMuscles,
    secondaryMuscles,
    muscleGroups,
    equipment: exercise.equipment || ['none'],
    icon: exercise.icon || 'fitness_center',
    // Bodyweight flag for load calculation
    usesBodyweight: exercise.usesBodyweight ?? (type === 'bodyweight'),
    // Additive fields (Phase 5)
    parentId: exercise.parentId || null,
    source: exercise.source || 'user',
    progressionLinks: exercise.progressionLinks || null
  };
}

/**
 * Maps v3 runtime shape to Firestore document for saving.
 * Writes both new and legacy fields for backward compat.
 */
function mapV3ToExerciseDoc(v3) {
  const doc = {
    name: v3.name,
    type: v3.type || 'strength',
    difficulty: v3.difficulty || 'intermediate',
    instructionsSteps: v3.instructions || [],
    muscleGroups: v3.muscleGroups || [],
    equipment: v3.equipment?.length ? v3.equipment : ['none'],
    icon: v3.icon || 'fitness_center'
  };

  // Optional fields - only write if non-empty
  if (v3.variants?.length) doc.variants = v3.variants;
  if (v3.notes) doc.notes = v3.notes;
  if (v3.setupNotes) doc.setupNotes = v3.setupNotes;
  if (v3.cues?.length) doc.cues = v3.cues;
  if (v3.commonMistakes?.length) doc.commonMistakes = v3.commonMistakes;
  if (v3.progressions?.length) doc.progressions = v3.progressions;

  // Additive fields (Phase 5)
  if (v3.parentId) doc.parentId = v3.parentId;
  if (v3.source) doc.source = v3.source;
  if (v3.progressionLinks) doc.progressionLinks = v3.progressionLinks;

  return doc;
}

// ========================================
// LOAD & DISPLAY EXERCISES
// ========================================

async function loadExercises() {
  try {
    // Load curated (read-only) and user exercises in parallel
    const [curatedRaw, userRaw] = await Promise.all([
      getAllDocs(exercisesCuratedCollection),
      getAllDocsForUser(exercisesCollection)
    ]);

    // Curated first, then user exercises override by ID
    const exerciseMap = new Map();
    for (const ex of curatedRaw) {
      exerciseMap.set(ex.id, mapExerciseToV3(ex));
    }
    for (const ex of userRaw) {
      exerciseMap.set(ex.id, mapExerciseToV3(ex));
    }

    allExercises = Array.from(exerciseMap.values());
    filteredExercises = [...allExercises];
    applyExerciseSearchI18n();
    renderExercises();
    updateExerciseFiltersUI();
  } catch (error) {
    console.error('Error loading exercises:', error);
  }
}

