// ========================================
// PREDEFINED EXERCISES DATA (CURATED CORE)
// ========================================
// ~60 curated exercises covering all muscle groups and difficulty levels.
// source: 'curated' marks these as read-only default exercises.

const defaultExercises = [
  // === CHEST / PUSH ===
  {
    name: 'Push-ups',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['chest', 'arms', 'shoulders'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Decline Push-ups',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['chest', 'shoulders', 'arms'],
    equipment: ['box'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Diamond Push-ups',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['chest', 'arms'],
    equipment: ['none'], difficulty: 2, source: 'curated',
    parentId: null
  },
  {
    name: 'Archer Push-ups',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['chest', 'shoulders', 'arms'],
    equipment: ['none'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Pseudo Planche Push-ups',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['chest', 'shoulders', 'core'],
    equipment: ['none'], difficulty: 4, source: 'curated'
  },
  {
    name: 'Dips',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['chest', 'arms', 'shoulders'],
    equipment: ['dip-bars'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Ring Dips',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['chest', 'arms', 'shoulders'],
    equipment: ['rings'], difficulty: 4, source: 'curated'
  },

  // === BACK / PULL ===
  {
    name: 'Pull-ups',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'arms'],
    equipment: ['pull-up-bar'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Chin-ups',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'arms'],
    equipment: ['pull-up-bar'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Negative Pull-ups',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'arms'],
    equipment: ['pull-up-bar'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Wide Grip Pull-ups',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'shoulders'],
    equipment: ['pull-up-bar'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Typewriter Pull-ups',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'arms'],
    equipment: ['pull-up-bar'], difficulty: 4, source: 'curated'
  },
  {
    name: 'Muscle-up',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'chest', 'arms', 'shoulders'],
    equipment: ['pull-up-bar'], difficulty: 5, source: 'curated'
  },
  {
    name: 'Ring Muscle-up',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'chest', 'arms', 'shoulders'],
    equipment: ['rings'], difficulty: 5, source: 'curated'
  },
  {
    name: 'Australian Pull-ups',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'arms'],
    equipment: ['pull-up-bar'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Front Lever',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'core'],
    equipment: ['pull-up-bar'], difficulty: 5, source: 'curated'
  },
  {
    name: 'Front Lever Raises',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'core'],
    equipment: ['pull-up-bar'], difficulty: 4, source: 'curated'
  },

  // === SHOULDERS ===
  {
    name: 'Pike Push-ups',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['shoulders', 'arms'],
    equipment: ['none'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Handstand Push-ups',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['shoulders', 'arms'],
    equipment: ['wall'], difficulty: 4, source: 'curated'
  },
  {
    name: 'Handstand Hold',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['shoulders', 'core'],
    equipment: ['wall'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Freestanding Handstand',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['shoulders', 'core'],
    equipment: ['none'], difficulty: 5, source: 'curated'
  },

  // === CORE ===
  {
    name: 'Plank',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Side Plank',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Hollow Body Hold',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core'],
    equipment: ['mat'], difficulty: 2, source: 'curated'
  },
  {
    name: 'L-Sit',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core', 'arms'],
    equipment: ['parallettes'], difficulty: 3, source: 'curated'
  },
  {
    name: 'V-Sit',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core', 'arms'],
    equipment: ['parallettes'], difficulty: 5, source: 'curated'
  },
  {
    name: 'Hanging Leg Raises',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core'],
    equipment: ['pull-up-bar'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Toes to Bar',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core'],
    equipment: ['pull-up-bar'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Dragon Flag',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core'],
    equipment: ['box'], difficulty: 4, source: 'curated'
  },
  {
    name: 'Ab Wheel Rollout',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core', 'shoulders'],
    equipment: ['none'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Human Flag',
    type: 'bodyweight', pattern: 'core',
    muscleGroups: ['core', 'shoulders', 'back'],
    equipment: ['pull-up-bar'], difficulty: 5, source: 'curated'
  },

  // === LEGS ===
  {
    name: 'Air Squats',
    type: 'bodyweight', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Bulgarian Split Squats',
    type: 'bodyweight', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['box'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Pistol Squats',
    type: 'bodyweight', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['none'], difficulty: 4, source: 'curated'
  },
  {
    name: 'Shrimp Squats',
    type: 'bodyweight', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['none'], difficulty: 4, source: 'curated'
  },
  {
    name: 'Jump Squats',
    type: 'bodyweight', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['none'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Nordic Hamstring Curl',
    type: 'bodyweight', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['none'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Calf Raises',
    type: 'bodyweight', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Step-ups',
    type: 'bodyweight', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['box'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Lunges',
    type: 'bodyweight', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  },

  // === FULL BODY / STATICS ===
  {
    name: 'Planche',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['shoulders', 'core', 'chest'],
    equipment: ['parallettes'], difficulty: 5, source: 'curated'
  },
  {
    name: 'Tuck Planche',
    type: 'bodyweight', pattern: 'push',
    muscleGroups: ['shoulders', 'core'],
    equipment: ['parallettes'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Back Lever',
    type: 'bodyweight', pattern: 'pull',
    muscleGroups: ['back', 'shoulders', 'core'],
    equipment: ['rings'], difficulty: 4, source: 'curated'
  },
  {
    name: 'Burpees',
    type: 'bodyweight', pattern: 'full',
    muscleGroups: ['chest', 'legs', 'core'],
    equipment: ['none'], difficulty: 2, source: 'curated'
  },

  // === STRENGTH (GYM) ===
  {
    name: 'Bench Press',
    type: 'strength', pattern: 'push',
    muscleGroups: ['chest', 'arms', 'shoulders'],
    equipment: ['weights'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Overhead Press',
    type: 'strength', pattern: 'push',
    muscleGroups: ['shoulders', 'arms'],
    equipment: ['weights'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Barbell Row',
    type: 'strength', pattern: 'pull',
    muscleGroups: ['back', 'arms'],
    equipment: ['weights'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Deadlift',
    type: 'strength', pattern: 'pull',
    muscleGroups: ['back', 'legs', 'core'],
    equipment: ['weights'], difficulty: 3, source: 'curated'
  },
  {
    name: 'Barbell Squat',
    type: 'strength', pattern: 'legs',
    muscleGroups: ['legs', 'core'],
    equipment: ['weights'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Dumbbell Curl',
    type: 'strength', pattern: 'pull',
    muscleGroups: ['arms'],
    equipment: ['weights'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Tricep Extension',
    type: 'strength', pattern: 'push',
    muscleGroups: ['arms'],
    equipment: ['weights'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Lateral Raises',
    type: 'strength', pattern: 'push',
    muscleGroups: ['shoulders'],
    equipment: ['weights'], difficulty: 1, source: 'curated'
  },

  // === CARDIO ===
  {
    name: 'Laufen',
    type: 'cardio', pattern: 'full',
    muscleGroups: ['legs', 'core'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Seilspringen',
    type: 'cardio', pattern: 'full',
    muscleGroups: ['legs', 'shoulders'],
    equipment: ['none'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Radfahren',
    type: 'cardio', pattern: 'legs',
    muscleGroups: ['legs'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  },
  {
    name: 'Schwimmen',
    type: 'cardio', pattern: 'full',
    muscleGroups: ['back', 'shoulders', 'legs'],
    equipment: ['none'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Rudern',
    type: 'cardio', pattern: 'pull',
    muscleGroups: ['back', 'legs', 'arms'],
    equipment: ['none'], difficulty: 2, source: 'curated'
  },
  {
    name: 'Mountain Climbers',
    type: 'cardio', pattern: 'full',
    muscleGroups: ['core', 'legs'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  },
  {
    name: 'High Knees',
    type: 'cardio', pattern: 'full',
    muscleGroups: ['legs', 'core'],
    equipment: ['none'], difficulty: 1, source: 'curated'
  }
];

// ========================================
// INITIALIZE DEFAULT EXERCISES
// ========================================

// Wird beim ersten Laden aufgerufen
async function initializeDefaultExercises() {
  try {
    // Check ob schon curated Übungen existieren
    const existing = await getAllDocs(exercisesCuratedCollection);

    if (existing.length === 0) {

      // Alle default Übungen in die curated Collection hinzufügen (global, kein userId)
      for (const exercise of defaultExercises) {
        await addDoc(exercisesCuratedCollection, exercise, { scoped: false });
      }

    } else {
    }
  } catch (error) {
    console.error('Error initializing exercises:', error);
  }
}
