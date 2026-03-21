// ========================================
// SESSION LOAD CALCULATOR
// Pure utility – no Firestore access
// ========================================

// ---------- Types ----------

export interface SessionSet {
  reps?: number | null;
  weight?: number | null;
}

export interface SessionExercise {
  exerciseId?: string;
  usesBodyweight?: boolean;
  sets?: SessionSet[];
}

export interface Session {
  type: 'strength' | 'cardio' | 'recovery';
  exercises?: SessionExercise[];
  rpe?: number | null;
  duration?: number | null;
}

export interface UserProfile {
  bodyWeight?: number | null;
}

export interface SessionLoadResult {
  rawLoad: number;
  type: Session['type'];
}

// ---------- RPE ----------

const RPE_FACTORS: Record<number, number> = {
  1: 0.6,
  2: 0.8,
  3: 1.0,
  4: 1.2,
  5: 1.4,
};

function getRpeFactor(rpe?: number | null): number {
  if (rpe == null) return 1.0;
  return RPE_FACTORS[rpe] ?? 1.0;
}

// ---------- Strength ----------

function calculateStrengthLoad(session: Session, userProfile: UserProfile): number {
  if (!session.exercises?.length) return 0;

  let totalVolume = 0;

  for (const exercise of session.exercises) {
    if (!exercise.sets?.length) continue;

    for (const set of exercise.sets) {
      const reps = set.reps ?? 0;
      if (reps <= 0) continue;

      const effectiveLoad = exercise.usesBodyweight
        ? (userProfile.bodyWeight ?? 0) + (set.weight ?? 0)
        : (set.weight ?? 0);

      totalVolume += effectiveLoad * reps;
    }
  }

  return totalVolume * getRpeFactor(session.rpe);
}

// ---------- Cardio ----------

function calculateCardioLoad(session: Session): number {
  const duration = session.duration ?? 0;
  if (duration <= 0) return 0;
  return duration * getRpeFactor(session.rpe) * 10;
}

// ---------- Main ----------

export function calculateSessionLoad(
  session: Session | null | undefined,
  userProfile: UserProfile | null | undefined,
): SessionLoadResult {
  const type = session?.type;

  if (!type) {
    return { rawLoad: 0, type: 'recovery' };
  }

  const safeProfile: UserProfile = userProfile ?? {};

  switch (type) {
    case 'strength':
      return { rawLoad: calculateStrengthLoad(session, safeProfile), type };
    case 'cardio':
      return { rawLoad: calculateCardioLoad(session), type };
    case 'recovery':
      return { rawLoad: 0, type };
    default:
      return { rawLoad: 0, type };
  }
}
