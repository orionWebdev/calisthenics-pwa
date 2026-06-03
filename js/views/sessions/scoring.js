// ==================== WEEKLY SCORE CALCULATIONS ====================

const LOAD_RPE_FACTORS = { 1: 0.6, 2: 0.8, 3: 1.0, 4: 1.2, 5: 1.4 };

function getLoadRpeFactor(rpe) {
  if (rpe == null) return 1.0;
  return LOAD_RPE_FACTORS[rpe] ?? 1.0;
}

// Cardio sport factors (mirrors calculateSessionLoad.ts)
const CARDIO_SPORT_FACTORS = {
  run: 1.0, bike: 0.85, swim: 0.9, hike: 0.4, row: 0.95, other: 1.0
};
const DEFAULT_SPORT_FACTOR = 1.0;
const STRENGTH_VOLUME_DIVISOR = 50;

function getLoadSportFactor(activityType) {
  if (!activityType) return DEFAULT_SPORT_FACTOR;
  return CARDIO_SPORT_FACTORS[activityType.toLowerCase()] ?? DEFAULT_SPORT_FACTOR;
}

// Duration dampening for long sessions (mirrors calculateSessionLoad.ts)
const DAMPENING_THRESHOLD = 120;
const DAMPENING_EXPONENT = 0.8;

function getEffectiveDuration(duration) {
  if (duration <= DAMPENING_THRESHOLD) return duration;
  const excess = duration - DAMPENING_THRESHOLD;
  return DAMPENING_THRESHOLD + Math.pow(excess, DAMPENING_EXPONENT);
}

/**
 * Calculates raw load for a session (ports calculateSessionLoad.ts)
 * @param {Object} session
 * @returns {{ rawLoad: number, type: string }}
 */
function calculateSessionLoadValue(session) {
  const type = session?.type;
  if (!type || type === 'recovery') return { rawLoad: 0, type: type || 'recovery' };

  if (type === 'strength' || type === 'bodyweight') {
    const bodyWeight = (typeof userProfile !== 'undefined' && userProfile?.bodyWeight) || 0;
    const rpe = session.rpe ?? 3;
    const rpeFactor = getLoadRpeFactor(rpe);

    // No exercises: duration-based fallback (Quick Log)
    if (!session.exercises || !Array.isArray(session.exercises) || session.exercises.length === 0) {
      const duration = session.duration || 0;
      if (duration <= 0) return { rawLoad: 0, type };
      const multiplier = session.discipline === 'bodyweight' ? 4.5 : 6;
      const rawLoad = Math.round(duration * rpeFactor * multiplier * 100) / 100;
      console.log('TEST LOAD:', { type, rawLoad, duration, exercises: 0, discipline: session.discipline });
      return { rawLoad, type };
    }

    // Has exercises: volume-based calculation
    let totalVolume = 0;
    for (const exercise of session.exercises) {
      if (!exercise.sets || !Array.isArray(exercise.sets)) continue;

      // Resolve usesBodyweight: stored flag, or fallback to exercise metadata
      let usesBodyweight = exercise.usesBodyweight;
      if (usesBodyweight === undefined && exercise.exerciseId
          && typeof allExercises !== 'undefined' && allExercises) {
        const exMeta = allExercises.find(e => e.id === exercise.exerciseId);
        if (exMeta?.usesBodyweight) usesBodyweight = true;
      }

      for (const set of exercise.sets) {
        const reps = set.reps || 0;
        if (reps <= 0) continue;
        const effectiveWeight = usesBodyweight
          ? bodyWeight
          : (set.weight || 0);
        if (effectiveWeight === 0) continue;
        totalVolume += effectiveWeight * reps;
      }
    }

    // Fallback: if all exercises had 0 effective weight (e.g. bodyweight without profile weight),
    // use duration-based calculation so the session still contributes to ACWR
    if (totalVolume === 0 && session.duration > 0) {
      const multiplier = session.discipline === 'bodyweight' ? 4.5 : 6;
      const rawLoad = Math.round(session.duration * rpeFactor * multiplier * 100) / 100;
      console.log('TEST LOAD (bw fallback):', { type, rawLoad, duration: session.duration, discipline: session.discipline });
      return { rawLoad, type };
    }

    const rawLoad = Math.round((totalVolume / STRENGTH_VOLUME_DIVISOR) * rpeFactor * 100) / 100;
    console.log('TEST LOAD:', { type, rawLoad, duration: session.duration, exercises: session.exercises?.length });
    return { rawLoad, type };
  }

  if (type === 'cardio') {
    const duration = session.duration || 0;
    if (duration <= 0) return { rawLoad: 0, type };
    const rpe = session.rpe ?? 3;
    const effectiveDuration = getEffectiveDuration(duration);
    const sportFactor = getLoadSportFactor(session.activityType);
    const rawLoad = Math.round(effectiveDuration * getLoadRpeFactor(rpe) * 4 * sportFactor * 100) / 100;
    return { rawLoad, type };
  }

  return { rawLoad: 0, type };
}

// ---------- Recovery Detection ----------

const RECOVERY_MAX_RPE = 2;
const RECOVERY_MAX_DURATION = 60; // minutes

function isRecoverySession(session) {
  const rpe = session.rpe ?? 3;
  const duration = session.duration ?? 0;

  if (rpe > RECOVERY_MAX_RPE) return false;
  if (duration <= 0 || duration > RECOVERY_MAX_DURATION) return false;

  return session.type === 'cardio'
      || session.type === 'recovery'
      || session.type === 'strength';
}

/**
 * Computes weekly raw load for a 7-day window ending at referenceDate
 * @param {Date} referenceDate
 * @returns {{ rawLoad: number, strengthLoad: number, cardioLoad: number, sessionCount: number }}
 */
function computeWeeklyRawLoad(referenceDate) {
  const startDate = new Date(referenceDate);
  startDate.setDate(startDate.getDate() - 6);
  startDate.setHours(0, 0, 0, 0);

  const endDate = new Date(referenceDate);
  endDate.setHours(23, 59, 59, 999);

  let strengthLoad = 0;
  let cardioLoad = 0;
  let sessionCount = 0;

  console.log('WeeklyRawLoad sessions:', allSessions.filter(s => s.type === 'strength' || s.type === 'bodyweight' || s.type === 'cardio').length, 'strength+bodyweight+cardio of', allSessions.length, 'total');

  for (const s of allSessions) {
    if (s.type !== 'strength' && s.type !== 'bodyweight' && s.type !== 'cardio') continue;

    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) continue;
    if (sessionDate < startDate || sessionDate > endDate) continue;

    const result = calculateSessionLoadValue(s);
    if (result.type === 'strength' || result.type === 'bodyweight') {
      strengthLoad += result.rawLoad;
    } else if (result.type === 'cardio') {
      cardioLoad += result.rawLoad;
    }
    sessionCount++;
  }

  return { rawLoad: strengthLoad + cardioLoad, strengthLoad, cardioLoad, sessionCount };
}

/**
 * Computes weekly score (0-100) for a given reference date
 * @param {Date} referenceDate
 * @returns {{ weeklyScore: number, rawLoad: number, strengthLoad: number, cardioLoad: number, baseline: number, sessionCount: number }}
 */
function computeWeeklyScore(referenceDate) {
  const currentWeek = computeWeeklyRawLoad(referenceDate);

  // Previous 6 weeks for baseline
  const previousWeeks = [];
  for (let i = 1; i <= 6; i++) {
    const refDate = new Date(referenceDate);
    refDate.setDate(refDate.getDate() - i * 7);
    previousWeeks.push(computeWeeklyRawLoad(refDate));
  }

  const weeksWithData = previousWeeks.filter(w => w.rawLoad > 0);
  let baseline;

  if (weeksWithData.length < 2) {
    baseline = currentWeek.rawLoad;
  } else {
    const totalLoad = weeksWithData.reduce((sum, w) => sum + w.rawLoad, 0);
    baseline = totalLoad / weeksWithData.length;
  }

  const weeklyScore = baseline === 0
    ? 0
    : Math.min(100, Math.max(0, Math.round((currentWeek.rawLoad / baseline) * 70)));

  return {
    weeklyScore,
    rawLoad: currentWeek.rawLoad,
    strengthLoad: currentWeek.strengthLoad,
    cardioLoad: currentWeek.cardioLoad,
    baseline,
    sessionCount: currentWeek.sessionCount,
  };
}

/**
 * Maps ACWR ratio to a training-phase score (0–100) via continuous piecewise
 * linear interpolation. The curve peaks at ACWR ≈ 1.0 (optimal load balance)
 * and drops symmetrically for under- and over-training.
 */
function mapReadiness(acwr) {
  // Steeper curve with more differentiation in the normal 0.8-1.2 range.
  // Peak is narrower (only ACWR ≈ 0.95-1.05 scores above 85).
  const curve = [
    [0.0,  10],  // deep under-training
    [0.3,  22],
    [0.5,  38],
    [0.65, 50],
    [0.75, 60],
    [0.85, 72],
    [0.95, 85],
    [1.0,  90],  // optimal balance — narrow peak
    [1.05, 85],
    [1.15, 72],
    [1.25, 60],
    [1.35, 50],
    [1.5,  38],
    [1.7,  25],
    [2.0,  14],
    [2.5,  6],   // deep over-training
  ];

  const clamped = Math.max(0, Math.min(acwr, 2.5));

  // Below first point
  if (clamped <= curve[0][0]) return curve[0][1];

  for (let i = 0; i < curve.length - 1; i++) {
    const [x0, y0] = curve[i];
    const [x1, y1] = curve[i + 1];
    if (clamped >= x0 && clamped <= x1) {
      const t = (clamped - x0) / (x1 - x0);
      return Math.round(y0 + (y1 - y0) * t);
    }
  }

  return curve[curve.length - 1][1];
}

/**
 * Maps score + ACWR direction to a training zone.
 * Uses ACWR to distinguish under-training (form_loss) from over-training (overreaching).
 */
function mapZone(score, acwr) {
  if (acwr !== undefined && acwr < 0.8 && score <= 55) return 'form_loss';
  if (score <= 30) return 'overreaching';
  if (score <= 50) return 'fatigued';
  if (score <= 68) return 'maintaining';
  if (score <= 82) return 'building';
  return 'peak';
}

/**
 * Computes Acute:Chronic Workload Ratio (ports getACWR.ts)
 * @param {Array} sessions
 * @param {Date} referenceDate
 * @param {{ applyFatigue?: boolean }} [options]
 * @returns {{ acuteLoad: number, chronicLoad: number, acwr: number|null, readinessScore: number|null, zone: string|null, daysSinceLastSession: number|null, todayLoad: number, fatiguePenalty: number }}
 */
function getACWR(sessions, referenceDate, options) {
  const applyFatigue = options?.applyFatigue ?? false;
  if (!sessions || !sessions.length) {
    return { acuteLoad: 0, chronicLoad: 0, acwr: null, readinessScore: null, zone: null, daysSinceLastSession: null, todayLoad: 0, fatiguePenalty: 0 };
  }

  const ACUTE_ALPHA = 0.22;   // ~5-day effective window (was 0.35 ~3d, too reactive)
  const CHRONIC_ALPHA = 0.07;  // ~14-day effective window (was 0.10 ~10d)
  const RECOVERY_BOOST_FACTOR = 0.05;

  // Use local date keys (YYYY-MM-DD) to avoid UTC/local timezone mismatch
  function toLocalDateKey(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${dd}`;
  }

  const end = new Date(referenceDate);
  end.setHours(23, 59, 59, 999);

  // Build daily load map (aggregate same-day sessions, skip recovery)
  const dailyLoads = new Map();
  const recoveryDays = new Set();

  for (const s of sessions) {
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) continue;
    if (sessionDate > end) continue;

    if (isRecoverySession(s)) {
      recoveryDays.add(toLocalDateKey(sessionDate));
    }

    if (s.type !== 'strength' && s.type !== 'bodyweight' && s.type !== 'cardio') continue;

    const { rawLoad } = calculateSessionLoadValue(s);
    if (rawLoad <= 0) continue;
    const key = toLocalDateKey(sessionDate);
    dailyLoads.set(key, (dailyLoads.get(key) ?? 0) + rawLoad);
  }

  if (dailyLoads.size === 0) {
    return { acuteLoad: 0, chronicLoad: 0, acwr: null, readinessScore: null, zone: null, daysSinceLastSession: null, todayLoad: 0, fatiguePenalty: 0 };
  }

  // Sort keys to find earliest session and compute day span
  const sortedKeys = [...dailyLoads.keys()].sort();
  const refDay = new Date(referenceDate);
  refDay.setHours(0, 0, 0, 0);
  const earliestDate = new Date(sortedKeys[0] + 'T00:00:00');
  const daySpan = Math.floor((refDay.getTime() - earliestDate.getTime()) / (1000 * 60 * 60 * 24));

  // Debug: log today's sessions
  const todayDbgKey = toLocalDateKey(refDay);
  const todayDbgLoad = dailyLoads.get(todayDbgKey);
  if (todayDbgLoad) {
    console.log('[READINESS DEBUG] today total load:', { todayKey: todayDbgKey, todayLoad: Math.round(todayDbgLoad * 100) / 100, totalDays: dailyLoads.size });
  }

  // Need at least 14 days of history
  if (daySpan < 14) {
    return { acuteLoad: 0, chronicLoad: 0, acwr: null, readinessScore: null, zone: null, daysSinceLastSession: null, todayLoad: 0, fatiguePenalty: 0 };
  }

  // daysSinceLastSession (for UI/insights only, not score manipulation)
  const lastSessionKey = sortedKeys[sortedKeys.length - 1];
  const lastSessionDate = new Date(lastSessionKey + 'T00:00:00');
  const daysSinceLastSession = Math.floor((refDay.getTime() - lastSessionDate.getTime()) / (1000 * 60 * 60 * 24));

  // Continuous EMA over ALL days (including rest days with load=0)
  const loopStart = new Date(Math.max(
    earliestDate.getTime(),
    refDay.getTime() - 56 * 24 * 60 * 60 * 1000
  ));

  let acuteEMA = 0;
  let chronicEMA = 0;
  const cursor = new Date(loopStart);

  while (cursor <= refDay) {
    const dateKey = toLocalDateKey(cursor);
    const dailyLoad = dailyLoads.get(dateKey) || 0;

    acuteEMA = ACUTE_ALPHA * dailyLoad + (1 - ACUTE_ALPHA) * acuteEMA;
    chronicEMA = CHRONIC_ALPHA * dailyLoad + (1 - CHRONIC_ALPHA) * chronicEMA;

    // Recovery Boost: aktive Erholung beschleunigt Acute-Abbau
    if (recoveryDays.has(dateKey)) {
      acuteEMA *= (1 - RECOVERY_BOOST_FACTOR);
    }

    cursor.setDate(cursor.getDate() + 1);
  }

  // When chronic load is negligible, there's no meaningful baseline for a ratio
  if (chronicEMA < 0.01) {
    return { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr: null, readinessScore: null, zone: null, daysSinceLastSession, todayLoad: 0, fatiguePenalty: 0 };
  }

  const acwr = Math.round((acuteEMA / chronicEMA) * 100) / 100;

  const rawReadinessScore = Math.round(mapReadiness(acwr));

  // Acute fatigue modifier: reduce readiness on days with training load.
  // Uses sqrt curve for diminishing returns so that:
  //   1 moderate session (~1x chronic) → ~10pt penalty
  //   1 hard session   (~2x chronic)  → ~14pt penalty
  //   2 sessions       (~3x chronic)  → ~17pt penalty
  //   extreme day      (~6x chronic)  → ~24pt penalty
  const todayKey = toLocalDateKey(refDay);
  const todayLoad = dailyLoads.get(todayKey) || 0;
  let fatiguePenalty = 0;

  if (applyFatigue && todayLoad > 0 && chronicEMA > 0.01) {
    const loadRatio = todayLoad / chronicEMA;
    fatiguePenalty = Math.min(35, Math.round(10 * Math.sqrt(loadRatio)));
    console.log('[READINESS DEBUG] fatigue calc:', {
      todayLoad: Math.round(todayLoad * 100) / 100,
      chronicEMA: Math.round(chronicEMA * 100) / 100,
      loadRatio: Math.round(loadRatio * 100) / 100,
      sqrtLoadRatio: Math.round(Math.sqrt(loadRatio) * 100) / 100,
      rawPenalty: Math.round(10 * Math.sqrt(loadRatio)),
      fatiguePenalty,
    });
  }

  const readinessScore = Math.max(5, rawReadinessScore - fatiguePenalty);
  const zone = mapZone(readinessScore, acwr);

  console.log('[READINESS DEBUG] final:', {
    acuteEMA: Math.round(acuteEMA * 100) / 100,
    chronicEMA: Math.round(chronicEMA * 100) / 100,
    acwr,
    rawReadinessScore,
    fatiguePenalty,
    readinessScore,
    zone,
    todayLoad: Math.round(todayLoad * 100) / 100,
    todayKey,
    applyFatigue,
  });

  return { acuteLoad: acuteEMA, chronicLoad: chronicEMA, acwr, readinessScore, zone, daysSinceLastSession, todayLoad, fatiguePenalty };
}

/**
 * Computes a Training Form score based on long-term chronic load (Fitness EMA).
 * Uses a slow EMA (~33 day effective window) to represent accumulated fitness,
 * normalized against a decaying personal peak.
 * @param {Array} sessions
 * @param {Date} referenceDate
 * @returns {{ formScore: number|null, zone: string|null, fitnessLoad: number, peakLoad: number, trend: string, daysSinceLastSession: number|null }}
 */
function computeFormScore(sessions, referenceDate) {
  if (!sessions || !sessions.length) {
    return { formScore: null, zone: null, consistency: 0, loadLevel: 0, recency: 0, trend: 'none', daysSinceLastSession: null };
  }

  function toLocalDateKey(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${dd}`;
  }

  const refDay = new Date(referenceDate);
  refDay.setHours(0, 0, 0, 0);
  const end = new Date(referenceDate);
  end.setHours(23, 59, 59, 999);

  // Build daily load map + collect training day keys
  const dailyLoads = new Map();
  for (const s of sessions) {
    if (s.type !== 'strength' && s.type !== 'bodyweight' && s.type !== 'cardio') continue;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) continue;
    if (sessionDate > end) continue;
    const { rawLoad } = calculateSessionLoadValue(s);
    if (rawLoad <= 0) continue; // Skip zero-load sessions
    const key = toLocalDateKey(sessionDate);
    dailyLoads.set(key, (dailyLoads.get(key) ?? 0) + rawLoad);
  }

  if (dailyLoads.size === 0) {
    return { formScore: null, zone: null, consistency: 0, loadLevel: 0, recency: 0, trend: 'none', daysSinceLastSession: null };
  }

  const sortedKeys = [...dailyLoads.keys()].sort();
  const earliestDate = new Date(sortedKeys[0] + 'T00:00:00');
  const daySpan = Math.floor((refDay.getTime() - earliestDate.getTime()) / (1000 * 60 * 60 * 24));

  // Need at least 14 days of history
  if (daySpan < 14) {
    return { formScore: null, zone: null, consistency: 0, loadLevel: 0, recency: 0, trend: 'none', daysSinceLastSession: null };
  }

  // ── Component 1: Training Consistency (0-35) ──
  // Count training days in last 28 days
  const last28Start = new Date(refDay);
  last28Start.setDate(last28Start.getDate() - 27);
  let trainingDays28 = 0;
  for (const key of dailyLoads.keys()) {
    const d = new Date(key + 'T00:00:00');
    if (d >= last28Start && d <= refDay) trainingDays28++;
  }
  // 16+ days in 28 (≥4x/week) = full 35 points
  const consistency = Math.min(35, Math.round((trainingDays28 / 16) * 35));

  // ── Component 2: Load Progression (0-35) ──
  // Compare recent 14-day load trend against prior 14-day period.
  // This measures whether training load is progressing, stable, or declining.
  const FITNESS_ALPHA = 0.03;
  const loopStart = new Date(Math.max(
    earliestDate.getTime(),
    refDay.getTime() - 120 * 24 * 60 * 60 * 1000
  ));

  let fitnessEMA = 0;
  let fitnessAt14DaysAgo = 0;
  let peakFitness = 0;

  // Collect recent-14d and prior-14d raw loads for direct comparison
  let recent14Load = 0;
  let prior14Load = 0;

  const cursor = new Date(loopStart);
  while (cursor <= refDay) {
    const dateKey = toLocalDateKey(cursor);
    const dailyLoad = dailyLoads.get(dateKey) || 0;
    fitnessEMA = FITNESS_ALPHA * dailyLoad + (1 - FITNESS_ALPHA) * fitnessEMA;
    if (fitnessEMA > peakFitness) peakFitness = fitnessEMA;

    const daysToRef = Math.floor((refDay.getTime() - cursor.getTime()) / (1000 * 60 * 60 * 24));
    if (daysToRef < 14) {
      recent14Load += dailyLoad;
    } else if (daysToRef < 28) {
      prior14Load += dailyLoad;
    }
    if (daysToRef === 14) {
      fitnessAt14DaysAgo = fitnessEMA;
    }

    cursor.setDate(cursor.getDate() + 1);
  }

  // Load progression: compare recent vs prior 14-day window
  // Ratio > 1 = progressing, < 1 = declining, ≈ 1 = maintaining
  // Cap ratio at 2.0 to prevent extreme spikes from low baselines
  let loadLevel = 0;
  if (prior14Load > 0) {
    const progressionRatio = Math.min(recent14Load / prior14Load, 2.0);
    // 0.0 → 0pts, 0.5 → 8pts, 0.8 → 15pts, 1.0 → 20pts, 1.5 → 25pts, 2.0 → 30pts
    if (progressionRatio <= 0.3) {
      loadLevel = 0;
    } else if (progressionRatio <= 1.0) {
      // Linear scale 0.3→5 to 1.0→20
      loadLevel = Math.round(5 + (progressionRatio - 0.3) / 0.7 * 15);
    } else {
      // Above baseline: 1.0→20 to 2.0→30 (gentler curve, capped at 30)
      loadLevel = Math.round(20 + Math.min(progressionRatio - 1.0, 1.0) * 10);
    }
  } else if (recent14Load > 0) {
    loadLevel = 12; // bootstrapping: training started recently
  }

  // ── Component 3: Training Recency (0-15) ──
  const lastSessionKey = sortedKeys[sortedKeys.length - 1];
  const lastSessionDate = new Date(lastSessionKey + 'T00:00:00');
  const daysSinceLastSession = Math.floor((refDay.getTime() - lastSessionDate.getTime()) / (1000 * 60 * 60 * 24));

  let recency = 0;
  if (daysSinceLastSession <= 1) recency = 15;
  else if (daysSinceLastSession <= 2) recency = 12;
  else if (daysSinceLastSession <= 3) recency = 8;
  else if (daysSinceLastSession <= 5) recency = 4;
  else if (daysSinceLastSession <= 7) recency = 1;

  // ── Component 4: Fitness vs Peak (0-15) ──
  // How close is current fitness EMA to all-time peak within the window?
  // This rewards sustained high load over time, not just showing up.
  let fitnessVsPeak = 0;
  if (peakFitness > 0) {
    const peakRatio = fitnessEMA / peakFitness;
    fitnessVsPeak = Math.round(Math.min(15, peakRatio * 15));
  }

  // ── Component 5: Session Impact Bonus (0-8) ──
  // Immediate boost when training was logged today. Uses sqrt curve so
  // multiple sessions or longer workouts keep increasing the bonus:
  //   1 moderate session (~1x avg) → ~4pt bonus
  //   1 hard session   (~2x avg)  → ~6pt bonus
  //   2 sessions       (~3x avg)  → ~7pt bonus
  //   extreme day      (~5x avg)  → ~8pt bonus (cap)
  const todayKey = toLocalDateKey(refDay);
  const todayLoad = dailyLoads.get(todayKey) || 0;
  let sessionBonus = 0;
  if (todayLoad > 0 && recent14Load > 0) {
    const avgDailyLoad = recent14Load / 14;
    sessionBonus = avgDailyLoad > 0
      ? Math.min(8, Math.round(4 * Math.sqrt(todayLoad / avgDailyLoad)))
      : 3;
  }

  // ── Combined Form Score (0-100) ──
  let formScore = Math.max(0, Math.min(100, consistency + loadLevel + recency + fitnessVsPeak + sessionBonus));

  console.log('[FORM DEBUG]', {
    consistency, loadLevel, recency, fitnessVsPeak, sessionBonus,
    formScore,
    todayLoad: Math.round(todayLoad * 100) / 100,
    avgDailyLoad: recent14Load > 0 ? Math.round((recent14Load / 14) * 100) / 100 : 0,
    loadRatio: recent14Load > 0 && (recent14Load / 14) > 0 ? Math.round((todayLoad / (recent14Load / 14)) * 100) / 100 : 'N/A',
    recent14Load: Math.round(recent14Load * 100) / 100,
    prior14Load: Math.round(prior14Load * 100) / 100,
    progressionRatio: prior14Load > 0 ? Math.round((recent14Load / prior14Load) * 100) / 100 : 'N/A',
    trainingDays28,
    daysSinceLastSession,
    fitnessEMA: Math.round(fitnessEMA * 100) / 100,
    peakFitness: Math.round(peakFitness * 100) / 100,
  });

  // ── Inactivity Decay (Garmin-like: fast and accelerating) ──
  // 2d rest: 0 (recovery phase), 3-4d: -3/day, 5-7d: -5/day, 8+d: -7/day
  //   3d → -3, 5d → -11, 7d → -21, 10d → -42, 14d → -70
  if (daysSinceLastSession > 2) {
    let inactivityPenalty = 0;
    if (daysSinceLastSession <= 4) {
      inactivityPenalty = (daysSinceLastSession - 2) * 3;
    } else if (daysSinceLastSession <= 7) {
      inactivityPenalty = 6 + (daysSinceLastSession - 4) * 5;
    } else {
      inactivityPenalty = 21 + (daysSinceLastSession - 7) * 7;
    }
    formScore = Math.max(0, formScore - inactivityPenalty);
  }

  // ── Trend ──
  let trend = 'stable';
  if (fitnessAt14DaysAgo > 0) {
    const trendRatio = fitnessEMA / fitnessAt14DaysAgo;
    if (trendRatio > 1.05) trend = 'rising';
    else if (trendRatio < 0.95) trend = 'falling';
  } else if (fitnessEMA > 0) {
    trend = 'rising';
  }

  const zone = mapFormZone(formScore, daysSinceLastSession);

  return { formScore, zone, consistency, loadLevel, recency, trend, daysSinceLastSession };
}

/**
 * Maps form score to a training form zone (Garmin-inspired).
 * Applies a mild non-linear compression (exp 1.3) to reduce clustering
 * in the upper range, so "peak_form" becomes a rarer, special state.
 *
 * Zones: detrained, declining, recovery, maintaining, building, productive, peak_form
 * No "overload" zone – overreaching belongs to readiness (ACWR).
 */
function mapFormZone(score, daysSinceLastSession) {
  // Non-linear compression: pushes high scores down so peak_form is rare.
  const adjusted = Math.pow(Math.max(0, score) / 100, 1.3) * 100;

  // Recovery override: 2-5 days rest while form is still above detrained
  if (daysSinceLastSession >= 2 && daysSinceLastSession <= 5 && adjusted > 13) {
    return 'recovery';
  }
  if (adjusted <= 13) return 'detrained';
  if (adjusted <= 32) return 'declining';
  if (adjusted <= 58) return 'maintaining';
  if (adjusted <= 78) return 'building';
  if (adjusted <= 94) return 'productive';
  return 'peak_form';
}

/**
 * Combines training form zone (long-term) and readiness zone (short-term)
 * into a concrete training recommendation.
 * Readiness (acute) takes priority; form phase steers the direction.
 *
 * @param {string} formZone   – one of: detrained, declining, recovery, maintaining, building, productive, peak_form
 * @param {string} readinessZone – one of: overreaching, fatigued, maintaining, building, peak, form_loss
 * @returns {{ key: string, intensity: string }}
 */
function getTrainingRecommendation(formZone, readinessZone) {
  // --- Overreaching: always rest, regardless of phase ---
  if (readinessZone === 'overreaching') {
    return { key: 'overreaching', intensity: 'rest' };
  }

  // --- Form loss (long inactivity): special case ---
  if (readinessZone === 'form_loss') {
    if (formZone === 'detrained' || formZone === 'declining') {
      return { key: 'formLossDetrained', intensity: 'low' };
    }
    return { key: 'formLoss', intensity: 'moderate' };
  }

  // --- Recovery form phase: body is resting, be gentle ---
  if (formZone === 'recovery') {
    if (readinessZone === 'peak' || readinessZone === 'building') {
      return { key: 'recoveryReady', intensity: 'moderate' };
    }
    return { key: 'recoveryResting', intensity: 'low' };
  }

  // --- Fatigued: low intensity, phase adjusts nuance ---
  if (readinessZone === 'fatigued') {
    if (formZone === 'peak_form' || formZone === 'productive' || formZone === 'building') return { key: 'fatiguedGoodForm', intensity: 'low' };
    return { key: 'fatiguedDefault', intensity: 'low' };
  }

  // --- Maintaining: moderate, phase adjusts ---
  if (readinessZone === 'maintaining') {
    if (formZone === 'peak_form' || formZone === 'productive') return { key: 'maintainingPeak', intensity: 'moderate' };
    return { key: 'maintainingDefault', intensity: 'moderate' };
  }

  // --- Building: ready for normal to high training ---
  if (readinessZone === 'building') {
    if (formZone === 'peak_form' || formZone === 'productive' || formZone === 'building') return { key: 'buildingGoodForm', intensity: 'high' };
    return { key: 'buildingDefault', intensity: 'moderate' };
  }

  // --- Peak: fully recovered, can push ---
  if (readinessZone === 'peak') {
    if (formZone === 'peak_form' || formZone === 'productive' || formZone === 'building') return { key: 'peakGoodForm', intensity: 'high' };
    if (formZone === 'detrained') return { key: 'peakDetrained', intensity: 'moderate' };
    return { key: 'peakDefault', intensity: 'high' };
  }

  // Fallback
  return { key: 'maintainingDefault', intensity: 'moderate' };
}

/**
 * Compares today's ACWR with yesterday's to explain why the readiness score changed.
 * @param {Array} sessions
 * @param {Date} referenceDate
 * @returns {{ scoreDelta: number, acuteDelta: number, chronicDelta: number, daysSinceLastSession: number|null, driver: string|null, todayLoad: number, biggestSession: object|null, previous: object|null, current: object|null }}
 */
function getScoreChange(sessions, referenceDate) {
  const nullResult = { scoreDelta: 0, acuteDelta: 0, chronicDelta: 0, daysSinceLastSession: null, driver: null, todayLoad: 0, biggestSession: null, previous: null, current: null };

  const current = getACWR(sessions, referenceDate);
  if (current.readinessScore === null) return nullResult;

  const yesterday = new Date(referenceDate);
  yesterday.setDate(yesterday.getDate() - 1);
  const previous = getACWR(sessions, yesterday);
  if (previous.readinessScore === null) return nullResult;

  const scoreDelta = current.readinessScore - previous.readinessScore;
  const acuteDelta = current.acuteLoad - previous.acuteLoad;
  const chronicDelta = current.chronicLoad - previous.chronicLoad;
  const daysSinceLastSession = current.daysSinceLastSession;

  // Determine primary driver
  let driver = 'none';
  if (scoreDelta !== 0) {
    if (acuteDelta > 0.5) {
      driver = 'training';
    } else if (acuteDelta <= 0 && daysSinceLastSession >= 1) {
      driver = 'recovery';
    } else if (Math.abs(chronicDelta) > 1) {
      driver = 'baseline_shift';
    }
  }

  // Find sessions from last 24h for load context
  const refEnd = new Date(referenceDate);
  refEnd.setHours(23, 59, 59, 999);
  const refStart = new Date(referenceDate);
  refStart.setHours(0, 0, 0, 0);

  let todayLoad = 0;
  let biggestSession = null;
  let biggestLoad = 0;

  for (const s of (sessions || [])) {
    if (s.type !== 'strength' && s.type !== 'bodyweight' && s.type !== 'cardio') continue;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) continue;
    if (sessionDate < refStart || sessionDate > refEnd) continue;

    const { rawLoad } = calculateSessionLoadValue(s);
    todayLoad += rawLoad;

    if (rawLoad > biggestLoad) {
      biggestLoad = rawLoad;
      biggestSession = {
        name: s.planName || s.activityType || s.type,
        duration: s.duration || 0,
        load: rawLoad
      };
    }
  }

  return {
    scoreDelta,
    acuteDelta,
    chronicDelta,
    daysSinceLastSession,
    driver,
    todayLoad: Math.round(todayLoad),
    biggestSession,
    previous: { readinessScore: previous.readinessScore, acuteLoad: previous.acuteLoad, chronicLoad: previous.chronicLoad },
    current: { readinessScore: current.readinessScore, acuteLoad: current.acuteLoad, chronicLoad: current.chronicLoad }
  };
}

/**
 * Aggregates weekly scores by period for chart data
 * @param {string} periodKey - '7D', '30D', '6M', '1Y'
 * @returns {Array<{ label: string, date: Date, weeklyScore: number, baseline: number, strengthLoad: number, cardioLoad: number, sessionCount: number }>}
 */
function aggregateWeeklyScoresByPeriod(periodKey) {
  const WEEKS_FOR_PERIOD = { '7D': 4, '30D': 4, '6M': 26, '1Y': 52 };
  const numWeeks = WEEKS_FOR_PERIOD[periodKey] || 4;

  const result = [];
  const now = new Date();
  const currentWeekEnd = new Date(now);
  currentWeekEnd.setHours(23, 59, 59, 999);

  for (let i = numWeeks - 1; i >= 0; i--) {
    const weekEnd = new Date(currentWeekEnd);
    weekEnd.setDate(weekEnd.getDate() - i * 7);

    const weekStart = new Date(weekEnd);
    weekStart.setDate(weekStart.getDate() - 6);

    const score = computeWeeklyScore(weekEnd);

    result.push({
      label: formatWeekLabel(weekStart),
      date: weekStart,
      weeklyScore: score.weeklyScore,
      baseline: score.baseline,
      strengthLoad: score.strengthLoad,
      cardioLoad: score.cardioLoad,
      sessionCount: score.sessionCount,
    });
  }

  return result;
}

/**
 * Returns training status based on weekly score
 * @param {number} weeklyScore - Score 0-100
 * @returns {{ label: string, color: string, description: string }}
 */
function getTrainingStatus(weeklyScore) {
  const tr = typeof t === 'function' ? t : (key) => key;

  if (weeklyScore < 50) {
    return {
      label: tr('progress.readiness.lowLoad'),
      color: 'var(--color-category-strength)',
      description: tr('progress.readiness.descLow'),
    };
  } else if (weeklyScore <= 85) {
    return {
      label: tr('progress.readiness.balanced'),
      color: 'var(--color-category-recovery)',
      description: tr('progress.readiness.descBalanced'),
    };
  } else {
    return {
      label: tr('progress.readiness.highLoad'),
      color: 'var(--color-primary)',
      description: tr('progress.readiness.descHigh'),
    };
  }
}

// Expose functions
window.openAddCardioModal = openAddCardioModal;
window.closeAddCardioModal = closeAddCardioModal;
window.updateCardioLivePace = updateCardioLivePace;
window.saveCardioSession = saveCardioSession;
window.handleModalBackdropClick = handleModalBackdropClick;
window.triggerSuccessGlow = triggerSuccessGlow;
window.showErrorMessage = showErrorMessage;
window.openAddRecoveryModal = openAddRecoveryModal;
window.closeAddRecoveryModal = closeAddRecoveryModal;
window.saveRecoverySession = saveRecoverySession;
window.openAddStrengthModal = openAddStrengthModal;
window.closeAddStrengthModal = closeAddStrengthModal;
window.saveStrengthSession = saveStrengthSession;
window.setStrengthType = setStrengthType;
window.setStrengthDifficulty = setStrengthDifficulty;
window.openExercisePickerForLogging = openExercisePickerForLogging;
window.addExerciseToStrengthLogging = addExerciseToStrengthLogging;
window.removeExerciseFromLogging = removeExerciseFromLogging;
window.editExerciseSets = editExerciseSets;
window.saveExerciseSets = saveExerciseSets;
window.renderStrengthExercisesList = renderStrengthExercisesList;
window.calculateSessionStrengthVolume = calculateSessionStrengthVolume;
window.aggregateWeeklyStrengthVolume = aggregateWeeklyStrengthVolume;
window.aggregateWeeklyCardio = aggregateWeeklyCardio;
window.getSessionsByDate = getSessionsByDate;
window.getSessionsForDate = getSessionsForDate;
window.formatDateToYYYYMMDD = formatDateToYYYYMMDD;

// New period-based aggregation functions
window.PERIOD_CONFIG = PERIOD_CONFIG;
window.ACTIVITY_TYPES = ACTIVITY_TYPES;
window.RECOVERY_TYPES = RECOVERY_TYPES;
window.aggregateCardioByPeriod = aggregateCardioByPeriod;
window.getAvailableEnduranceSports = getAvailableEnduranceSports;
window.aggregateStrengthByPeriod = aggregateStrengthByPeriod;
window.calculateCardioStats = calculateCardioStats;
window.calculateStrengthStats = calculateStrengthStats;
window.formatPaceShort = formatPaceShort;

// Dual volume (weighted + bodyweight) functions
window.EXERCISE_LOAD_FACTORS = EXERCISE_LOAD_FACTORS;
window.getExerciseLoadFactor = getExerciseLoadFactor;
window.calculateWeightedVolume = calculateWeightedVolume;
window.calculateBodyweightVolume = calculateBodyweightVolume;
window.calculateDualVolume = calculateDualVolume;
window.aggregateDualStrengthByPeriod = aggregateDualStrengthByPeriod;
window.calculateDualStrengthStats = calculateDualStrengthStats;

// Training Character Progress functions
window.INTENSITY_THRESHOLDS = INTENSITY_THRESHOLDS;
window.calculateConsistencyStats = calculateConsistencyStats;
window.generateCalmInsight = generateCalmInsight;
window.calculateWeightedLoadIndex = calculateWeightedLoadIndex;
window.aggregateWeightedLoadByPeriod = aggregateWeightedLoadByPeriod;
window.calculateWeightedLoadStats = calculateWeightedLoadStats;
window.calculateTrainingVariance = calculateTrainingVariance;
window.classifyBodyweightIntensity = classifyBodyweightIntensity;
window.aggregateBodyweightByPeriod = aggregateBodyweightByPeriod;
window.calculateBodyweightStats = calculateBodyweightStats;
window.computeHybridBalance = computeHybridBalance;

// Weekly score functions
window.calculateSessionLoadValue = calculateSessionLoadValue;
window.computeWeeklyRawLoad = computeWeeklyRawLoad;
window.computeWeeklyScore = computeWeeklyScore;
window.aggregateWeeklyScoresByPeriod = aggregateWeeklyScoresByPeriod;
window.getTrainingStatus = getTrainingStatus;

// ACWR
window.getACWR = getACWR;
window.getScoreChange = getScoreChange;

// Training Form
window.computeFormScore = computeFormScore;
window.mapFormZone = mapFormZone;

// Run analytics
window.aggregateRunByPeriod = aggregateRunByPeriod;

