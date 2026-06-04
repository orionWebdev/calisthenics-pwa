// ==================== PROGRESS DATA QUERIES ====================

/**
 * Letzte N Sessions eines Plans, sortiert newest-first.
 */
function getSessionsForPlan(planId, limit = 5, excludeId = null) {
  if (!planId) return [];
  const sessions = typeof allSessions !== 'undefined' ? allSessions : [];
  const relevant = sessions.filter(s =>
    s.planId === planId && s.id !== excludeId
  );
  relevant.sort((a, b) => {
    const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return db - da;
  });
  return relevant.slice(0, limit);
}

/**
 * Gewichtetes Volumen einer einzelnen Exercise (reps*weight oder nur reps).
 */
function calculateExerciseWeightedVolume(exerciseEntry) {
  if (!exerciseEntry?.sets || !Array.isArray(exerciseEntry.sets)) return 0;
  return exerciseEntry.sets.reduce((sum, set) => {
    const reps = set.reps || 0;
    const weight = set.weight || 0;
    return sum + (weight > 0 ? reps * weight : reps);
  }, 0);
}

/**
 * Sparkline-Daten für eine Exercise aus gegebenen Sessions.
 * Return: Array oldest-first [12, 15, 14, 16, 18]
 */
function getExerciseSparklineData(sessions, exerciseId) {
  const values = [];
  sessions.forEach(s => {
    const ex = (s.exercises || []).find(e => e.exerciseId === exerciseId);
    if (ex) values.push(calculateExerciseWeightedVolume(ex));
  });
  return values.reverse(); // sessions are newest-first, sparkline needs oldest-first
}

/**
 * Sparkline-Daten für eine Exercise über alle Sessions (nicht plan-spezifisch).
 */
function getExerciseGlobalSparkline(exerciseId, limit = 8) {
  const sessions = (typeof allSessions !== 'undefined' ? allSessions : [])
    .filter(s => s.exercises?.some(e => e.exerciseId === exerciseId))
    .sort((a, b) => {
      const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
      const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
      return db - da;
    })
    .slice(0, limit);
  return getExerciseSparklineData(sessions, exerciseId);
}

window.getSessionsForPlan = getSessionsForPlan;
window.calculateExerciseWeightedVolume = calculateExerciseWeightedVolume;
window.getExerciseSparklineData = getExerciseSparklineData;
window.getExerciseGlobalSparkline = getExerciseGlobalSparkline;

