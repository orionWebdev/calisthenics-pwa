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
  discipline?: 'bodyweight' | 'weights' | string;
  activityType?: string;
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

// ---------- Cardio Sport Factors ----------

const CARDIO_SPORT_FACTORS: Record<string, number> = {
  run:   1.0,
  bike:  0.85,
  swim:  0.9,
  hike:  0.4,
  row:   0.95,
  other: 1.0,
};

const DEFAULT_SPORT_FACTOR = 1.0;

function getSportFactor(activityType?: string): number {
  if (!activityType) return DEFAULT_SPORT_FACTOR;
  return CARDIO_SPORT_FACTORS[activityType.toLowerCase()] ?? DEFAULT_SPORT_FACTOR;
}

// ---------- Duration Dampening ----------

const DAMPENING_THRESHOLD = 120; // minutes
const DAMPENING_EXPONENT = 0.8;

function getEffectiveDuration(duration: number): number {
  if (duration <= DAMPENING_THRESHOLD) return duration;
  const excess = duration - DAMPENING_THRESHOLD;
  return DAMPENING_THRESHOLD + Math.pow(excess, DAMPENING_EXPONENT);
}

// ---------- Strength ----------

const STRENGTH_VOLUME_DIVISOR = 50;

function calculateStrengthLoad(session: Session, userProfile: UserProfile): number {
  const rpe = session.rpe ?? 3;
  const rpeFactor = getRpeFactor(rpe);

  if (!session.exercises?.length) {
    const duration = session.duration ?? 0;
    if (duration <= 0) return 0;
    const multiplier = session.discipline === 'bodyweight' ? 4.5 : 6;
    return duration * rpeFactor * multiplier;
  }

  let sessionVolume = 0;

  for (const exercise of session.exercises) {
    if (!exercise.sets?.length) continue;

    for (const set of exercise.sets) {
      const reps = set.reps ?? 0;
      if (reps <= 0) continue;

      const effectiveWeight = exercise.usesBodyweight === true
        ? (userProfile.bodyWeight ?? 0)
        : (set.weight ?? 0);

      if (effectiveWeight === 0) continue;

      sessionVolume += reps * effectiveWeight;
    }
  }

  // Fallback: if all exercises had 0 effective weight (e.g. bodyweight without profile weight),
  // use duration-based calculation so the session still contributes to ACWR
  if (sessionVolume === 0 && (session.duration ?? 0) > 0) {
    const multiplier = session.discipline === 'bodyweight' ? 4.5 : 6;
    return (session.duration ?? 0) * rpeFactor * multiplier;
  }

  return (sessionVolume / STRENGTH_VOLUME_DIVISOR) * rpeFactor;
}

// ---------- Cardio ----------

function calculateCardioLoad(session: Session): number {
  const duration = session.duration ?? 0;
  if (duration <= 0) return 0;
  const rpe = session.rpe ?? 3;
  const effectiveDuration = getEffectiveDuration(duration);
  const sportFactor = getSportFactor(session.activityType);
  return effectiveDuration * getRpeFactor(rpe) * 4 * sportFactor;
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
  const round = (v: number) => Math.round(v * 100) / 100;

  switch (type) {
    case 'strength':
      return { rawLoad: round(calculateStrengthLoad(session, safeProfile)), type };
    case 'cardio':
      return { rawLoad: round(calculateCardioLoad(session)), type };
    case 'recovery':
      return { rawLoad: 0, type };
    default:
      return { rawLoad: 0, type };
  }
}
