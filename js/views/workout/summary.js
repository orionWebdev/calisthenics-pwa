// ==================== POST-WORKOUT SUMMARY ====================

/**
 * Gibt die letzte abgeschlossene Session für einen Plan zurück,
 * exklusive der gerade gespeicherten Session (per ID).
 */
function getPreviousSessionForPlan(planId, excludeId) {
  if (!planId) return null;
  const userId = typeof getActiveUserId === 'function' ? getActiveUserId() : null;
  const sessions = typeof allSessions !== 'undefined' ? allSessions : [];
  const relevant = sessions.filter(s =>
    s.planId === planId &&
    s.id !== excludeId &&
    (!userId || s.userId === userId)
  );
  if (!relevant.length) return null;
  relevant.sort((a, b) => {
    const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return db - da;
  });
  return relevant[0];
}

/**
 * Berechnet Gesamtvolumen einer Session: Σ (reps × weight) oder Σ reps falls kein Gewicht.
 */
function calcSessionVolume(session) {
  if (!session?.exercises) return 0;
  return session.exercises.reduce((total, ex) => {
    return total + (ex.sets || []).reduce((s, set) => {
      const reps = set.reps || 0;
      const weight = set.weight || 0;
      return s + (weight > 0 ? reps * weight : reps);
    }, 0);
  }, 0);
}

/**
 * Berechnet Gesamtanzahl Sätze einer Session.
 */
function calcSessionSets(session) {
  if (!session?.exercises) return 0;
  return session.exercises.reduce((total, ex) => total + (ex.sets?.length || 0), 0);
}

/**
 * Formatiert ein Delta für die Anzeige: +5%, −2 Min, etc.
 */
function formatDelta(current, previous, unit) {
  if (previous == null || previous === 0) return null;
  const diff = current - previous;
  if (diff === 0) return null;
  const pct = Math.round((diff / previous) * 100);
  const sign = diff > 0 ? '+' : '';
  if (unit === '%') return `${sign}${pct}%`;
  return `${sign}${diff} ${unit}`;
}

/**
 * Baut per-exercise Vergleich zwischen aktueller und vorheriger Session.
 */
function buildExerciseComparison(currentSession, prevSession, planSessions) {
  const currentExercises = currentSession?.exercises || [];
  const prevExercises = prevSession?.exercises || [];
  const prevMap = {};
  prevExercises.forEach(ex => { prevMap[ex.exerciseId] = ex; });
  const currentMap = {};
  currentExercises.forEach(ex => { currentMap[ex.exerciseId] = ex; });

  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
  const result = [];

  // Current exercises
  currentExercises.forEach(ex => {
    const prev = prevMap[ex.exerciseId];
    const exData = exercises.find(e => e.id === ex.exerciseId);
    const name = exData?.name || ex.exerciseId;
    const curVol = typeof calculateExerciseWeightedVolume === 'function'
      ? calculateExerciseWeightedVolume(ex) : (ex.sets || []).reduce((s, set) => s + (set.reps || 0), 0);
    const prevVol = prev ? (typeof calculateExerciseWeightedVolume === 'function'
      ? calculateExerciseWeightedVolume(prev) : (prev.sets || []).reduce((s, set) => s + (set.reps || 0), 0)) : null;

    const curSets = ex.sets?.length || 0;
    const curAvgReps = curSets > 0 ? Math.round((ex.sets || []).reduce((s, set) => s + (set.reps || 0), 0) / curSets) : 0;
    const prevSets = prev ? (prev.sets?.length || 0) : null;
    const prevAvgReps = prevSets > 0 ? Math.round((prev.sets || []).reduce((s, set) => s + (set.reps || 0), 0) / prevSets) : null;

    const sparkline = planSessions.length > 0 && typeof getExerciseSparklineData === 'function'
      ? getExerciseSparklineData(planSessions, ex.exerciseId) : [];

    result.push({
      exerciseId: ex.exerciseId, name,
      curSets, curAvgReps, prevSets, prevAvgReps,
      curVol, prevVol,
      isNew: !prev, isRemoved: false,
      sparkline,
      trend: prevVol !== null ? (curVol > prevVol ? 'up' : curVol < prevVol ? 'down' : 'same') : null
    });
  });

  // Removed exercises
  prevExercises.forEach(ex => {
    if (!currentMap[ex.exerciseId]) {
      const exData = exercises.find(e => e.id === ex.exerciseId);
      const name = exData?.name || ex.exerciseId;
      const prevSets = ex.sets?.length || 0;
      const prevAvgReps = prevSets > 0 ? Math.round((ex.sets || []).reduce((s, set) => s + (set.reps || 0), 0) / prevSets) : 0;
      result.push({
        exerciseId: ex.exerciseId, name,
        curSets: null, curAvgReps: null, prevSets, prevAvgReps,
        curVol: null, prevVol: typeof calculateExerciseWeightedVolume === 'function' ? calculateExerciseWeightedVolume(ex) : 0,
        isNew: false, isRemoved: true, sparkline: [], trend: null
      });
    }
  });

  return result;
}
window.buildExerciseComparison = buildExerciseComparison;

/**
 * Monotone cubic tangents (Fritsch-Carlson) for smooth sparkline curves.
 */
function _monotoneTangents(points) {
  const n = points.length;
  if (n < 2) return [];
  const d = [], m = [];
  for (let i = 0; i < n - 1; i++) {
    const dx = points[i + 1].x - points[i].x;
    d[i] = dx === 0 ? 0 : (points[i + 1].y - points[i].y) / dx;
  }
  m[0] = d[0];
  for (let i = 1; i < n - 1; i++) {
    if (d[i - 1] * d[i] <= 0) { m[i] = 0; }
    else { m[i] = (d[i - 1] + d[i]) / 2; }
  }
  m[n - 1] = d[n - 2];
  for (let i = 0; i < n - 1; i++) {
    if (Math.abs(d[i]) < 1e-6) { m[i] = m[i + 1] = 0; continue; }
    const a = m[i] / d[i], b = m[i + 1] / d[i];
    const s = a * a + b * b;
    if (s > 9) { const t = 3 / Math.sqrt(s); m[i] = t * a * d[i]; m[i + 1] = t * b * d[i]; }
  }
  return m;
}

/**
 * Zeichnet Mini-Sparkline in ein Canvas.
 * options: { smooth: bool, fill: bool, lineWidth: number }
 */
function drawMiniSparkline(canvasId, values, trendColor, options) {
  const canvas = document.getElementById(canvasId);
  if (!canvas || values.length < 2) return;
  const opts = options || {};
  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);
  const w = rect.width, h = rect.height, pad = 2;
  const max = Math.max(...values), min = Math.min(...values);
  const range = max - min || 1;

  // Compute point coordinates
  const points = values.map((v, i) => ({
    x: pad + (i / (values.length - 1)) * (w - 2 * pad),
    y: h - pad - ((v - min) / range) * (h - 2 * pad)
  }));

  // Draw line path
  ctx.beginPath();
  ctx.strokeStyle = trendColor;
  ctx.lineWidth = opts.lineWidth || 1.5;
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';

  if (opts.smooth && points.length >= 3) {
    const m = _monotoneTangents(points);
    ctx.moveTo(points[0].x, points[0].y);
    for (let i = 1; i < points.length; i++) {
      const prev = points[i - 1];
      const cur = points[i];
      const dx = (cur.x - prev.x) / 3;
      ctx.bezierCurveTo(
        prev.x + dx, prev.y + m[i - 1] * dx,
        cur.x - dx, cur.y - m[i] * dx,
        cur.x, cur.y
      );
    }
  } else {
    points.forEach((p, i) => {
      if (i === 0) ctx.moveTo(p.x, p.y); else ctx.lineTo(p.x, p.y);
    });
  }
  ctx.stroke();

  // Gradient fill under curve
  if (opts.fill) {
    ctx.lineTo(points[points.length - 1].x, h);
    ctx.lineTo(points[0].x, h);
    ctx.closePath();
    const grad = ctx.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, trendColor + '33'); // ~0.2 opacity
    grad.addColorStop(1, trendColor + '00'); // transparent
    ctx.fillStyle = grad;
    ctx.fill();
  }
}
window.drawMiniSparkline = drawMiniSparkline;
window._monotoneTangents = _monotoneTangents;

/**
 * Trend-Farbe bestimmen.
 */
function getTrendColor(trend) {
  if (trend === 'up') return '#22c55e';
  if (trend === 'down') return '#ef4444';
  return '#9ca3af';
}

/**
 * Trend-Icon bestimmen.
 */
function getTrendIcon(trend) {
  if (trend === 'up') return 'trending_up';
  if (trend === 'down') return 'trending_down';
  return 'trending_flat';
}

/**
 * Zeigt den Post-Workout Summary Screen.
 */
function showPostWorkoutSummary(savedSession, prevSession, durationMinutes, planSessions) {
  const modal = document.getElementById('post-workout-summary-modal');
  const body = document.getElementById('post-workout-summary-body');
  if (!modal || !body) {
    showView('progress');
    triggerSuccessGlow();
    return;
  }

  const tr = typeof t === 'function' ? t : (k) => k;
  const currentSets = savedSession.exercises
    ? savedSession.exercises.reduce((t, ex) => t + (ex.sets?.length || 0), 0)
    : 0;
  const currentVol = calcSessionVolume(savedSession);

  // Overall comparison
  let comparisonHTML = '';
  if (prevSession) {
    const prevDuration = prevSession.duration || 0;
    const prevSets = calcSessionSets(prevSession);
    const prevVol = calcSessionVolume(prevSession);
    const items = [];
    const durDelta = formatDelta(durationMinutes, prevDuration, 'Min');
    items.push({ icon: 'schedule', label: t('workout.postWorkout.time'), current: `${durationMinutes} Min`, delta: durDelta, positive: durationMinutes >= prevDuration });
    const setsDelta = formatDelta(currentSets, prevSets, 'Sets');
    items.push({ icon: 'repeat', label: t('workout.postWorkout.sets'), current: String(currentSets), delta: setsDelta, positive: currentSets >= prevSets });
    if (currentVol > 0 || prevVol > 0) {
      const volDelta = formatDelta(currentVol, prevVol, '%');
      items.push({ icon: 'fitness_center', label: t('workout.postWorkout.volume'), current: currentVol > 0 ? `${currentVol} ${getWeightUnit()}` : '\u2014', delta: volDelta, positive: currentVol >= prevVol });
    }
    comparisonHTML = `
      <div class="pws-section-title">${t('workout.postWorkout.comparisonTitle')}</div>
      <div class="pws-comparison-grid">
        ${items.map(item => `
          <div class="pws-stat-card">
            <span class="material-symbols-rounded pws-stat-icon">${item.icon}</span>
            <div class="pws-stat-value">${item.current}</div>
            <div class="pws-stat-label">${item.label}</div>
            ${item.delta ? `<div class="pws-stat-delta ${item.positive ? 'positive' : 'negative'}">${item.delta}</div>` : ''}
          </div>
        `).join('')}
      </div>
    `;
  }

  // Per-exercise comparison
  const exComparison = buildExerciseComparison(savedSession, prevSession, planSessions || []);
  let exercisesHTML = '';
  if (exComparison.length > 0) {
    const exTitle = tr('progress.v4.postWorkout.exercisesTitle') || 'Übungen im Detail';
    const badgeNew = tr('progress.v4.postWorkout.badgeNew') || 'Neu';
    const badgeRemoved = tr('progress.v4.postWorkout.badgeRemoved') || 'Letztes Mal';
    exercisesHTML = `
      <div class="pws-exercises-section">
        <div class="pws-section-title">${exTitle}</div>
        <div class="pws-exercise-list">
          ${exComparison.map(ex => {
            const curLabel = ex.curSets !== null ? `${ex.curSets}x${ex.curAvgReps}` : '\u2014';
            const prevLabel = ex.prevSets !== null ? `${ex.prevSets}x${ex.prevAvgReps}` : '';
            const badge = ex.isNew ? `<span class="pws-exercise-badge new">${badgeNew}</span>`
              : ex.isRemoved ? `<span class="pws-exercise-badge removed">${badgeRemoved}</span>` : '';
            const trendClass = ex.trend || 'same';
            const trendIcon = getTrendIcon(ex.trend);
            const hasSparkline = ex.sparkline && ex.sparkline.length >= 2;
            const sparkId = `pws-spark-${ex.exerciseId.replace(/[^a-zA-Z0-9]/g, '_')}`;
            return `
              <div class="pws-exercise-row${ex.isRemoved ? ' removed' : ''}">
                <div class="pws-exercise-info">
                  <div class="pws-exercise-name">${ex.name} ${badge}</div>
                  <div class="pws-exercise-sets">
                    ${curLabel}${prevLabel && !ex.isNew ? ` <span class="pws-exercise-vs">vs ${prevLabel}</span>` : ''}
                  </div>
                </div>
                ${hasSparkline ? `<canvas class="pws-exercise-sparkline" id="${sparkId}"></canvas>` : '<div class="pws-exercise-sparkline"></div>'}
                ${ex.trend ? `<span class="material-symbols-rounded pws-exercise-trend ${trendClass}">${trendIcon}</span>` : '<div style="width:20px"></div>'}
              </div>
            `;
          }).join('')}
        </div>
      </div>
    `;
  }

  body.innerHTML = `
    <div class="pws-header">
      <div class="pws-success-icon">
        <span class="material-symbols-rounded">check_circle</span>
      </div>
      <h2 class="pws-title">${t('workout.postWorkout.title')}</h2>
      <p class="pws-subtitle">${savedSession.planName || t('workout.postWorkout.fallbackName')}</p>
    </div>

    <div class="pws-stats-row">
      <button type="button" class="pws-quick-stat pws-quick-stat--editable"
        onclick="editPostWorkoutDuration('${savedSession.id || ''}', ${durationMinutes})"
        aria-label="${t('workout.postWorkout.editDuration')}">
        <div class="pws-quick-stat-value" id="pws-duration-value">${durationMinutes}</div>
        <div class="pws-quick-stat-label">${t('workout.postWorkout.minutes')}</div>
        <span class="material-symbols-rounded pws-quick-stat-edit">edit</span>
      </button>
      <div class="pws-quick-stat">
        <div class="pws-quick-stat-value">${currentSets}</div>
        <div class="pws-quick-stat-label">${t('workout.postWorkout.sets')}</div>
      </div>
      ${(savedSession.exercises || []).length > 0 ? `
      <div class="pws-quick-stat">
        <div class="pws-quick-stat-value">${savedSession.exercises.length}</div>
        <div class="pws-quick-stat-label">${t('workout.postWorkout.exercises')}</div>
      </div>
      ` : ''}
    </div>

    ${comparisonHTML}
    ${exercisesHTML}

    <button type="button" class="pws-dismiss-btn" onclick="dismissPostWorkoutSummary()">
      <span class="material-symbols-rounded">bar_chart</span>
      <span>${t('workout.postWorkout.toProgress')}</span>
    </button>
  `;

  modal.classList.add('active');

  // Draw sparklines after DOM is ready
  requestAnimationFrame(() => {
    exComparison.forEach(ex => {
      if (ex.sparkline && ex.sparkline.length >= 2) {
        const sparkId = `pws-spark-${ex.exerciseId.replace(/[^a-zA-Z0-9]/g, '_')}`;
        drawMiniSparkline(sparkId, ex.sparkline, getTrendColor(ex.trend));
      }
    });
  });
}

/**
 * Lets the user correct the auto-tracked training time straight from the
 * post-workout summary — opens the number picker and patches the session.
 */
function editPostWorkoutDuration(sessionId, currentMinutes) {
  if (typeof openNumberPicker !== 'function') return;
  openNumberPicker({
    type: 'workoutDuration',
    initialValue: currentMinutes,
    onConfirm: async (newValue) => {
      const valEl = document.getElementById('pws-duration-value');
      if (valEl) valEl.textContent = newValue;
      if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('light');
      if (!sessionId) return;
      try {
        if (typeof updateDoc === 'function' && typeof sessionsCollection !== 'undefined') {
          await updateDoc(sessionsCollection, sessionId, {
            duration: newValue,
            durationSec: newValue * 60,
          });
          if (typeof loadSessions === 'function') await loadSessions();
          if (typeof renderProgressV4 === 'function') renderProgressV4();
        }
      } catch (error) {
        console.error('❌ Error updating workout duration:', error);
      }
    }
  });
}
window.editPostWorkoutDuration = editPostWorkoutDuration;

/**
 * Schließt den Summary Screen und navigiert zum Fortschritt.
 */
function dismissPostWorkoutSummary() {
  const modal = document.getElementById('post-workout-summary-modal');
  if (modal) modal.classList.remove('active');
  showView('progress');
  triggerSuccessGlow();
}

window.dismissPostWorkoutSummary = dismissPostWorkoutSummary;

