// ========================================
// PROGRESS V3 - TABBED PROGRESS VIEW
// ========================================
// Tabs: Overview | Exercise Trends | Plan Progress
// Data source: allSessions (sessions.js)

const trV3 = (key, params) => (typeof t === 'function' ? t(key, params) : key);

// ==================== STATE ====================

let pv4Tab = 'overview'; // 'overview' | 'exercises' | 'plans'
let pv4Period = localStorage.getItem('progressPeriodKey') || '30D';
let pv4ExerciseDetailId = null;
let pv4PlanDetailId = null;
let progressV3Initialized = false;

// ==================== TYPE MAPPING ====================

const V3_TYPE_MAP = {
  strength: 'strength', kraft: 'strength', weights: 'strength', gym: 'strength',
  bodyweight: 'bodyweight', calisthenics: 'bodyweight', bw: 'bodyweight',
  cardio: 'cardio', running: 'cardio', laufen: 'cardio', run: 'cardio',
  bike: 'cardio', swim: 'cardio', row: 'cardio',
  recovery: 'recovery', stretching: 'recovery', mobility: 'recovery', yoga: 'recovery'
};

const V3_TYPE_COLORS = {
  strength: 'var(--color-category-strength)',
  bodyweight: 'var(--color-category-bodyweight)',
  cardio: 'var(--color-category-cardio)',
  recovery: 'var(--color-category-recovery)'
};

const V3_TYPE_ICONS = {
  strength: 'fitness_center',
  bodyweight: 'self_improvement',
  cardio: 'directions_run',
  recovery: 'spa'
};

function mapSessionType(session) {
  const raw = (session.type || '').toLowerCase().trim();
  if (V3_TYPE_MAP[raw]) return V3_TYPE_MAP[raw];
  if (session.activityType) return 'cardio';
  return null;
}

// ==================== DATE HELPERS (Europe/Berlin) ====================

function v3ToLocalDate(session) {
  const d = session.date?.toDate ? session.date.toDate() : new Date(session.date);
  const str = d.toLocaleDateString('en-CA', { timeZone: 'Europe/Berlin' });
  return new Date(str + 'T12:00:00');
}

function v3GetDurationMin(session) {
  return typeof getSessionDurationMinutesSafe === 'function' ? getSessionDurationMinutesSafe(session) : 0;
}

function v3PeriodDays(key) {
  return (typeof PERIOD_CONFIG !== 'undefined' && PERIOD_CONFIG[key]?.days) || 30;
}

function v3SessionsInRange(daysBack, fromDate) {
  const end = fromDate || new Date();
  const endLocal = new Date(end.toLocaleDateString('en-CA', { timeZone: 'Europe/Berlin' }) + 'T23:59:59');
  const startLocal = new Date(endLocal);
  startLocal.setDate(startLocal.getDate() - daysBack + 1);
  startLocal.setHours(0, 0, 0, 0);
  return allSessions.filter(s => {
    const d = v3ToLocalDate(s);
    return d >= startLocal && d <= endLocal;
  });
}

function v3FormatDate(date) {
  const d = date instanceof Date ? date : new Date(date);
  return d.toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: '2-digit', timeZone: 'Europe/Berlin' });
}

function v3FormatDateShort(date) {
  const d = date instanceof Date ? date : new Date(date);
  return d.toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', timeZone: 'Europe/Berlin' });
}

// ==================== INIT ====================

async function initProgressV3() {
  console.log('Initializing Progress V4...');
  const container = document.getElementById('progress-tab-content');
  if (!container) return;

  container.innerHTML = renderV3Skeleton();

  const segCtrl = document.getElementById('progress-segmented-control');
  if (segCtrl) segCtrl.style.display = 'none';

  if (!sessionsLoaded || !allSessions.length) {
    await loadSessions();
  }

  pv4Period = localStorage.getItem('progressPeriodKey')
    || (typeof getSettingValue === 'function' ? getSettingValue('defaultProgressPeriod') : '30D');

  renderProgressV4();
  progressV3Initialized = true;
}

// ==================== SKELETON ====================

function renderV3Skeleton() {
  const card = `<div class="pv3-card pv3-skeleton-card">
    <div class="pv3-skeleton-line pv3-skeleton-title"></div>
    <div class="pv3-skeleton-line pv3-skeleton-bar"></div>
    <div class="pv3-skeleton-line pv3-skeleton-bar short"></div>
  </div>`;
  return `<div class="pv3-scroll-view">${card.repeat(3)}</div>`;
}

// ==================== MAIN RENDER ====================

function renderProgressV4() {
  const container = document.getElementById('progress-tab-content');
  if (!container) return;

  // Detail views
  if (pv4ExerciseDetailId) {
    container.innerHTML = renderExerciseDetail(pv4ExerciseDetailId);
    requestAnimationFrame(() => drawExerciseDetailChart(pv4ExerciseDetailId));
    return;
  }
  if (pv4PlanDetailId) {
    container.innerHTML = renderPlanDetail(pv4PlanDetailId);
    return;
  }

  container.innerHTML = `
    <div class="pv3-sticky-bar">
      ${renderV4TabBar()}
    </div>
    <div class="pv3-scroll-view">
      ${renderV4TabContent()}
    </div>
  `;

  attachV4TabListeners();

  if (pv4Tab === 'overview') {
    attachV4PeriodListeners();
  }

  // Draw sparklines
  requestAnimationFrame(() => drawAllV4Sparklines());
}

// Keep old name for compatibility
function renderProgressV3() { renderProgressV4(); }

// ==================== TAB BAR ====================

function renderV4TabBar() {
  const tabs = [
    { key: 'overview', label: trV3('progress.v4.tabs.overview'), icon: 'dashboard' },
    { key: 'exercises', label: trV3('progress.v4.tabs.exercises'), icon: 'fitness_center' },
    { key: 'plans', label: trV3('progress.v4.tabs.plans'), icon: 'assignment' }
  ];
  return `
    <div class="pv4-tab-bar">
      ${tabs.map(tab => `
        <button class="pv4-tab-btn${tab.key === pv4Tab ? ' active' : ''}" data-tab="${tab.key}">
          <span class="material-symbols-rounded pv4-tab-icon">${tab.icon}</span>
          <span class="pv4-tab-label">${tab.label}</span>
        </button>
      `).join('')}
    </div>`;
}

function attachV4TabListeners() {
  document.querySelectorAll('.pv4-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      if (btn.dataset.tab === pv4Tab) return;
      pv4Tab = btn.dataset.tab;
      renderProgressV4();
    });
  });
}

// ==================== TAB CONTENT ROUTER ====================

function renderV4TabContent() {
  if (pv4Tab === 'exercises') return renderV4ExerciseTrends();
  if (pv4Tab === 'plans') return renderV4PlanProgress();
  return renderV4Overview();
}

// ==================== TAB 1: OVERVIEW ====================

function renderV4PeriodSelector() {
  const periods = [
    { key: '7D', label: trV3('progress.period.7d') },
    { key: '30D', label: trV3('progress.period.30d') },
    { key: '6M', label: trV3('progress.period.6m') },
    { key: '1Y', label: trV3('progress.period.1y') }
  ];
  const activeIndex = Math.max(0, periods.findIndex(p => p.key === pv4Period));
  return `
    <div class="pv3-segmented-control" style="--seg-count:${periods.length};--active-idx:${activeIndex}">
      <div class="pv3-seg-indicator"></div>
      ${periods.map(p =>
        `<button class="pv3-seg-btn${p.key === pv4Period ? ' active' : ''}" data-period="${p.key}">${p.label}</button>`
      ).join('')}
    </div>`;
}

function attachV4PeriodListeners() {
  const control = document.querySelector('.pv3-segmented-control');
  if (!control) return;
  control.querySelectorAll('.pv3-seg-btn').forEach((btn, idx) => {
    btn.addEventListener('click', () => {
      if (btn.dataset.period === pv4Period) return;
      pv4Period = btn.dataset.period;
      localStorage.setItem('progressPeriodKey', pv4Period);
      control.style.setProperty('--active-idx', idx);
      control.querySelectorAll('.pv3-seg-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      setTimeout(() => renderProgressV4(), 220);
    });
  });
}

// Kurze Labels fuer Rhythmus-Buckets
const V3_DAY_LABELS = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const V3_MONTH_LABELS = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

function v3WeekNumber(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7));
  const week1 = new Date(d.getFullYear(), 0, 4);
  return 1 + Math.round(((d - week1) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7);
}

const V3_KNOWN_TYPES = ['strength', 'bodyweight', 'cardio', 'recovery'];

function renderV4Overview() {
  const days = v3PeriodDays(pv4Period);
  const sessions = v3SessionsInRange(days);

  const totalSessions = sessions.length;
  const totalMinutes = sessions.reduce((s, sess) => s + v3GetDurationMin(sess), 0);
  const totalVolume = sessions.reduce((s, sess) => {
    return s + (typeof calcSessionVolume === 'function' ? calcSessionVolume(sess) : 0);
  }, 0);
  const activeDays = new Set(sessions.map(s => v3ToLocalDate(s).toISOString().slice(0, 10))).size;

  const cards = [
    { icon: 'exercise', value: totalSessions, label: trV3('progress.v4.overview.workouts') },
    { icon: 'schedule', value: `${totalMinutes} ${trV3('progress.v4.overview.minutes')}`, label: trV3('progress.v4.overview.trainingTime') },
    { icon: 'fitness_center', value: totalVolume > 0 ? totalVolume.toLocaleString('de-DE') : '0', label: trV3('progress.v4.overview.totalVolume') },
    { icon: 'calendar_month', value: activeDays, label: trV3('progress.v4.overview.activeDays') }
  ];

  const cardsHTML = cards.map(c => `
    <div class="pv4-summary-card">
      <span class="material-symbols-rounded pv4-summary-icon">${c.icon}</span>
      <div class="pv4-summary-value">${c.value}</div>
      <div class="pv4-summary-label">${c.label}</div>
    </div>
  `).join('');

  // Training Rhythm widget
  const rhythmHTML = renderV4Rhythm(sessions);

  // Running Stats widget
  const runningHTML = renderV4RunningStats(sessions);

  // Session history (collapsible)
  const historyHTML = renderV4SessionHistory(sessions);

  return `
    ${renderV4PeriodSelector()}
    <div class="pv4-summary-grid">${cardsHTML}</div>
    ${rhythmHTML}
    ${runningHTML}
    ${historyHTML}
  `;
}

// ==================== TRAINING RHYTHM WIDGET ====================

function v4BuildRhythmBuckets(periodKey) {
  const now = new Date();
  const nowLocal = new Date(now.toLocaleDateString('en-CA', { timeZone: 'Europe/Berlin' }) + 'T23:59:59');
  const emptyData = () => ({ strength: 0, bodyweight: 0, cardio: 0, recovery: 0 });

  if (periodKey === '7D') {
    const buckets = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(nowLocal); d.setDate(d.getDate() - i);
      const start = new Date(d); start.setHours(0, 0, 0, 0);
      const end = new Date(d); end.setHours(23, 59, 59);
      const dayIdx = (start.getDay() + 6) % 7;
      buckets.push({ start, end, data: emptyData(), label: V3_DAY_LABELS[dayIdx], isCurrent: i === 0 });
    }
    return buckets;
  }
  if (periodKey === '30D') {
    const buckets = [];
    for (let i = 4; i >= 0; i--) {
      const end = new Date(nowLocal); end.setDate(end.getDate() - i * 7);
      const start = new Date(end); start.setDate(start.getDate() - 6); start.setHours(0, 0, 0, 0);
      buckets.push({ start, end, data: emptyData(), label: `KW ${v3WeekNumber(end)}`, isCurrent: i === 0 });
    }
    return buckets;
  }
  const monthsBack = periodKey === '1Y' ? 12 : 6;
  const buckets = [];
  for (let i = monthsBack - 1; i >= 0; i--) {
    const ref = new Date(nowLocal.getFullYear(), nowLocal.getMonth() - i, 1);
    const start = new Date(ref.getFullYear(), ref.getMonth(), 1, 0, 0, 0);
    const end = new Date(ref.getFullYear(), ref.getMonth() + 1, 0, 23, 59, 59);
    buckets.push({ start, end, data: emptyData(), label: V3_MONTH_LABELS[ref.getMonth()], isCurrent: i === 0 });
  }
  return buckets;
}

function renderV4Rhythm(sessions) {
  const buckets = v4BuildRhythmBuckets(pv4Period);
  const cutoff = buckets[0].start;

  allSessions.forEach(s => {
    const d = v3ToLocalDate(s);
    if (d < cutoff) return;
    const type = mapSessionType(s);
    if (!type) return;
    const mins = v3GetDurationMin(s);
    for (const b of buckets) {
      if (d >= b.start && d <= b.end) { b.data[type] += mins; break; }
    }
  });

  const maxMin = Math.max(1, ...buckets.map(b => V3_KNOWN_TYPES.reduce((sum, t) => sum + b.data[t], 0)));
  const hasData = buckets.some(b => V3_KNOWN_TYPES.some(t => b.data[t] > 0));

  if (!hasData) {
    return `
      <div class="pv3-card">
        <div class="pv3-card-header"><h3 class="pv3-card-title">${trV3('progress.v3.rhythm.title')}</h3></div>
        <div class="pv3-empty-state">${trV3('progress.v3.rhythm.noData')}</div>
      </div>`;
  }

  const barsHtml = buckets.map(b => {
    const total = V3_KNOWN_TYPES.reduce((sum, t) => sum + b.data[t], 0);
    const heightPct = Math.max(0, (total / maxMin) * 100);
    const segments = V3_KNOWN_TYPES
      .filter(t => b.data[t] > 0)
      .map(t => `<div class="pv3-rhythm-seg" style="height:${(b.data[t] / total) * 100}%;background:${V3_TYPE_COLORS[t]}" title="${Math.round(b.data[t])} min"></div>`)
      .join('');
    return `
      <div class="pv3-rhythm-col${b.isCurrent ? ' current' : ''}">
        <div class="pv3-rhythm-bar" style="height:${heightPct}%">${segments}</div>
        <span class="pv3-rhythm-label">${b.label}</span>
      </div>`;
  }).join('');

  const legendHtml = V3_KNOWN_TYPES
    .filter(t => buckets.some(b => b.data[t] > 0))
    .map(t => `<span class="pv3-legend-item"><span class="pv3-legend-dot" style="background:${V3_TYPE_COLORS[t]}"></span>${trV3('progress.v3.types.' + t)}</span>`)
    .join('');

  return `
    <div class="pv3-card pv3-rhythm-card">
      <div class="pv3-card-header">
        <h3 class="pv3-card-title">${trV3('progress.v3.rhythm.title')}</h3>
      </div>
      <div class="pv3-rhythm-chart">${barsHtml}</div>
      <div class="pv3-legend">${legendHtml}</div>
    </div>`;
}

// ==================== RUNNING STATS WIDGET ====================

function renderV4RunningStats(sessions) {
  const runSessions = sessions.filter(s => {
    const type = (s.activityType || '').toLowerCase();
    return type === 'run' || type === 'running' || type === 'laufen';
  });

  if (runSessions.length === 0) return '';

  const totalTime = runSessions.reduce((sum, s) => sum + v3GetDurationMin(s), 0);
  const totalDist = runSessions.reduce((sum, s) => sum + (Number(s.distanceKm) || 0), 0);
  const avgPace = totalDist > 0 ? totalTime / totalDist : null;

  function fmtPace(p) {
    if (!p || p <= 0) return '-';
    const m = Math.floor(p);
    let sec = Math.round((p - m) * 60);
    if (sec >= 60) return `${m + 1}:00`;
    return `${m}:${String(sec).padStart(2, '0')}`;
  }

  return `
    <div class="pv3-card">
      <div class="pv3-card-header">
        <h3 class="pv3-card-title">
          <span class="material-symbols-rounded" style="font-size:18px;vertical-align:middle;margin-right:4px;color:var(--color-category-cardio)">directions_run</span>
          ${trV3('progress.v4.overview.runningStats')}
        </h3>
        <span class="pv3-card-subtitle">${runSessions.length} ${trV3('progress.v4.overview.runs')}</span>
      </div>
      <div class="pv4-running-stats">
        <div class="pv4-running-stat">
          <div class="pv4-running-stat-value">${totalTime} min</div>
          <div class="pv4-running-stat-label">${trV3('progress.v4.overview.totalTime')}</div>
        </div>
        <div class="pv4-running-stat">
          <div class="pv4-running-stat-value">${totalDist > 0 ? totalDist.toFixed(1) + ' km' : '-'}</div>
          <div class="pv4-running-stat-label">${trV3('progress.v4.overview.totalDistance')}</div>
        </div>
        <div class="pv4-running-stat">
          <div class="pv4-running-stat-value">${avgPace ? fmtPace(avgPace) : '-'}</div>
          <div class="pv4-running-stat-label">${trV3('progress.v4.overview.avgPace')}</div>
        </div>
      </div>
    </div>`;
}

// ==================== SESSION HISTORY (COLLAPSIBLE) ====================

const PV4_HISTORY_COLLAPSED_LIMIT = 5;

function renderV4SessionHistory(sessions) {
  if (sessions.length === 0) {
    return `<div class="pv3-empty-state">${trV3('progress.v4.overview.noSessions')}</div>`;
  }

  const sorted = [...sessions].sort((a, b) => {
    const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return db - da;
  });

  const needsCollapse = sorted.length > PV4_HISTORY_COLLAPSED_LIMIT;

  const renderRow = (s) => {
    const type = mapSessionType(s) || 'strength';
    const icon = V3_TYPE_ICONS[type] || 'fitness_center';
    const d = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    const dur = v3GetDurationMin(s);
    const name = s.planName || trV3('progress.v3.types.' + type);
    const sessionId = s.id || '';
    return `
      <button class="pv4-session-row pv4-session-clickable" type="button" data-session-id="${sessionId}">
        <span class="material-symbols-rounded pv4-session-icon" style="color:${V3_TYPE_COLORS[type]}">${icon}</span>
        <div class="pv4-session-info">
          <div class="pv4-session-name">${name}</div>
          <div class="pv4-session-meta">${v3FormatDate(d)}${dur > 0 ? ` \u00B7 ${dur} min` : ''}</div>
        </div>
        <span class="material-symbols-rounded pv4-session-chevron">chevron_right</span>
      </button>`;
  };

  const visibleRows = sorted.slice(0, PV4_HISTORY_COLLAPSED_LIMIT).map(renderRow).join('');
  const hiddenRows = needsCollapse ? sorted.slice(PV4_HISTORY_COLLAPSED_LIMIT).map(renderRow).join('') : '';
  const remaining = sorted.length - PV4_HISTORY_COLLAPSED_LIMIT;

  const expandBtn = needsCollapse ? `
    <button class="pv4-history-expand-btn" id="pv4-history-toggle" type="button">
      <span class="material-symbols-rounded pv4-expand-icon">expand_more</span>
      <span class="pv4-expand-label">${trV3('progress.v4.overview.showMore', { count: remaining })}</span>
    </button>` : '';

  return `
    <div class="pv4-section-title">${trV3('progress.v4.overview.sessionHistory')}</div>
    <div class="pv4-session-list">
      ${visibleRows}
      ${needsCollapse ? `<div class="pv4-history-hidden" id="pv4-history-hidden" style="display:none">${hiddenRows}</div>` : ''}
      ${expandBtn}
    </div>`;
}

// ==================== TAB 2: EXERCISE TRENDS ====================

function renderV4ExerciseTrends() {
  const exerciseMap = {};
  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];

  allSessions.forEach(session => {
    if (!session.exercises) return;
    session.exercises.forEach(ex => {
      if (!exerciseMap[ex.exerciseId]) {
        const data = exercises.find(e => e.id === ex.exerciseId);
        exerciseMap[ex.exerciseId] = {
          exerciseId: ex.exerciseId,
          name: data?.name || ex.exerciseId,
          sessionCount: 0,
          sparklineData: [],
          trend: null
        };
      }
      exerciseMap[ex.exerciseId].sessionCount++;
    });
  });

  Object.values(exerciseMap).forEach(entry => {
    entry.sparklineData = typeof getExerciseGlobalSparkline === 'function'
      ? getExerciseGlobalSparkline(entry.exerciseId, 8) : [];
    if (entry.sparklineData.length >= 2) {
      const last = entry.sparklineData[entry.sparklineData.length - 1];
      const prev = entry.sparklineData[entry.sparklineData.length - 2];
      entry.trend = last > prev ? 'up' : last < prev ? 'down' : 'same';
    }
  });

  const sorted = Object.values(exerciseMap).sort((a, b) => b.sessionCount - a.sessionCount);

  if (sorted.length === 0) {
    return `<div class="pv3-empty-state">${trV3('progress.v4.exercises.noExercises')}</div>`;
  }

  const rows = sorted.map(ex => {
    const trendClass = ex.trend || 'same';
    const trendIcon = ex.trend === 'up' ? 'trending_up' : ex.trend === 'down' ? 'trending_down' : 'trending_flat';
    const hasSparkline = ex.sparklineData.length >= 2;
    const sparkId = `pv4-spark-${ex.exerciseId.replace(/[^a-zA-Z0-9]/g, '_')}`;
    return `
      <button class="pv4-exercise-row" data-exercise-id="${ex.exerciseId}">
        <div class="pv4-exercise-info">
          <div class="pv4-exercise-name">${ex.name}</div>
          <div class="pv4-exercise-meta">${trV3('progress.v4.exercises.sessions', { count: ex.sessionCount })}</div>
        </div>
        ${hasSparkline ? `<canvas class="pv4-sparkline-canvas" id="${sparkId}"></canvas>` : '<div class="pv4-sparkline-canvas"></div>'}
        <span class="material-symbols-rounded pv4-trend-indicator ${trendClass}">${trendIcon}</span>
      </button>`;
  }).join('');

  return `<div class="pv4-exercise-list">${rows}</div>`;
}

function drawAllV4Sparklines() {
  document.querySelectorAll('.pv4-sparkline-canvas').forEach(canvas => {
    const id = canvas.id;
    if (!id) return;
    const exId = id.replace('pv4-spark-', '').replace(/_/g, '-');
    // Find matching exercise data
    const sparkData = typeof getExerciseGlobalSparkline === 'function'
      ? getExerciseGlobalSparkline(exId, 8) : [];
    if (sparkData.length < 2) return;
    const last = sparkData[sparkData.length - 1];
    const prev = sparkData[sparkData.length - 2];
    const trend = last > prev ? 'up' : last < prev ? 'down' : 'same';
    const color = trend === 'up' ? '#22c55e' : trend === 'down' ? '#ef4444' : '#9ca3af';
    if (typeof drawMiniSparkline === 'function') {
      drawMiniSparkline(id, sparkData, color);
    }
  });

  // Attach click listeners for exercise rows
  document.querySelectorAll('.pv4-exercise-row').forEach(row => {
    row.addEventListener('click', () => {
      pv4ExerciseDetailId = row.dataset.exerciseId;
      renderProgressV4();
    });
  });

  // Attach click listeners for plan rows
  document.querySelectorAll('.pv4-plan-row').forEach(row => {
    row.addEventListener('click', () => {
      pv4PlanDetailId = row.dataset.planId;
      renderProgressV4();
    });
  });

  // Attach click listeners for session rows (open detail/edit)
  document.querySelectorAll('.pv4-session-clickable').forEach(row => {
    row.addEventListener('click', () => {
      const sid = row.dataset.sessionId;
      if (sid && typeof openSessionDetail === 'function') {
        openSessionDetail(sid);
      }
    });
  });

  // Attach accordion toggle for session history
  const toggleBtn = document.getElementById('pv4-history-toggle');
  const hiddenBlock = document.getElementById('pv4-history-hidden');
  if (toggleBtn && hiddenBlock) {
    toggleBtn.addEventListener('click', () => {
      const isHidden = hiddenBlock.style.display === 'none';
      hiddenBlock.style.display = isHidden ? 'block' : 'none';
      toggleBtn.querySelector('.pv4-expand-icon').textContent = isHidden ? 'expand_less' : 'expand_more';
      toggleBtn.querySelector('.pv4-expand-label').textContent = isHidden
        ? trV3('progress.v4.overview.showLess')
        : trV3('progress.v4.overview.showMore', { count: hiddenBlock.children.length });
    });
  }
}

// ==================== EXERCISE DETAIL ====================

function renderExerciseDetail(exerciseId) {
  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
  const exData = exercises.find(e => e.id === exerciseId);
  const name = exData?.name || exerciseId;

  const relevantSessions = allSessions
    .filter(s => s.exercises?.some(ex => ex.exerciseId === exerciseId))
    .sort((a, b) => {
      const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
      const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
      return da - db;
    });

  const chartData = relevantSessions.map(s => {
    const ex = s.exercises.find(e => e.exerciseId === exerciseId);
    const vol = typeof calculateExerciseWeightedVolume === 'function'
      ? calculateExerciseWeightedVolume(ex) : (ex.sets || []).reduce((sum, set) => sum + (set.reps || 0), 0);
    const bestSet = typeof calculateBestSet === 'function' ? calculateBestSet(ex) : 0;
    return {
      date: s.date?.toDate ? s.date.toDate() : new Date(s.date),
      volume: vol,
      bestSet,
      sets: ex.sets?.length || 0,
      planName: s.planName || ''
    };
  });

  // Stats
  const volumes = chartData.map(d => d.volume);
  const pr = volumes.length > 0 ? Math.max(...volumes) : 0;
  const avg = volumes.length > 0 ? Math.round(volumes.reduce((a, b) => a + b, 0) / volumes.length) : 0;
  const lastEntry = chartData.length > 0 ? chartData[chartData.length - 1] : null;

  // History (newest first)
  const historyRows = [...chartData].reverse().slice(0, 20).map(d => `
    <div class="pv4-session-row">
      <div class="pv4-session-info">
        <div class="pv4-session-name">${d.sets} ${trV3('progress.v4.exercises.detail.sets')} \u00B7 ${trV3('progress.v4.exercises.detail.volume')}: ${d.volume}</div>
        <div class="pv4-session-meta">${v3FormatDate(d.date)}${d.planName ? ` \u00B7 ${d.planName}` : ''}</div>
      </div>
    </div>
  `).join('');

  return `
    <div class="pv4-detail-view">
      <div class="pv4-detail-header">
        <button class="pv4-back-btn" onclick="pv4ExerciseDetailId=null;renderProgressV4()">
          <span class="material-symbols-rounded">arrow_back</span>
        </button>
        <h3 class="pv4-detail-title">${name}</h3>
      </div>
      <div class="pv4-detail-chart-wrapper">
        <canvas id="pv4-exercise-chart"></canvas>
      </div>
      <div class="pv4-detail-stats">
        <div class="pv4-summary-card">
          <div class="pv4-summary-value">${pr}</div>
          <div class="pv4-summary-label">${trV3('progress.v4.exercises.detail.pr')}</div>
        </div>
        <div class="pv4-summary-card">
          <div class="pv4-summary-value">${avg}</div>
          <div class="pv4-summary-label">${trV3('progress.v4.exercises.detail.average')}</div>
        </div>
        <div class="pv4-summary-card">
          <div class="pv4-summary-value">${lastEntry ? lastEntry.volume : '-'}</div>
          <div class="pv4-summary-label">${trV3('progress.v4.exercises.detail.lastSession')}</div>
        </div>
      </div>
      <div class="pv4-section-title">${trV3('progress.v4.exercises.detail.history')}</div>
      <div class="pv4-session-list">${historyRows}</div>
    </div>
  `;
}

function drawExerciseDetailChart(exerciseId) {
  const canvas = document.getElementById('pv4-exercise-chart');
  if (!canvas) return;

  const relevantSessions = allSessions
    .filter(s => s.exercises?.some(ex => ex.exerciseId === exerciseId))
    .sort((a, b) => {
      const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
      const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
      return da - db;
    });

  const values = relevantSessions.map(s => {
    const ex = s.exercises.find(e => e.exerciseId === exerciseId);
    return typeof calculateExerciseWeightedVolume === 'function'
      ? calculateExerciseWeightedVolume(ex) : (ex.sets || []).reduce((sum, set) => sum + (set.reps || 0), 0);
  });

  if (values.length < 2) return;

  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.parentElement.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  canvas.style.width = rect.width + 'px';
  canvas.style.height = rect.height + 'px';
  ctx.scale(dpr, dpr);

  const w = rect.width, h = rect.height;
  const padL = 40, padR = 12, padT = 12, padB = 24;
  const chartW = w - padL - padR, chartH = h - padT - padB;

  const max = Math.max(...values);
  const min = Math.min(...values);
  const range = max - min || 1;

  // Grid lines
  ctx.strokeStyle = 'rgba(255,255,255,0.06)';
  ctx.lineWidth = 1;
  for (let i = 0; i <= 3; i++) {
    const y = padT + (i / 3) * chartH;
    ctx.beginPath();
    ctx.moveTo(padL, y);
    ctx.lineTo(w - padR, y);
    ctx.stroke();

    const val = Math.round(max - (i / 3) * range);
    ctx.fillStyle = '#9ca3af';
    ctx.font = '10px system-ui';
    ctx.textAlign = 'right';
    ctx.fillText(String(val), padL - 6, y + 3);
  }

  // Data line
  const last = values[values.length - 1];
  const prev = values[values.length - 2];
  const lineColor = last >= prev ? '#22c55e' : '#ef4444';

  ctx.beginPath();
  ctx.strokeStyle = lineColor;
  ctx.lineWidth = 2;
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';

  const points = values.map((v, i) => ({
    x: padL + (i / (values.length - 1)) * chartW,
    y: padT + (1 - (v - min) / range) * chartH
  }));

  points.forEach((p, i) => {
    if (i === 0) ctx.moveTo(p.x, p.y); else ctx.lineTo(p.x, p.y);
  });
  ctx.stroke();

  // Data points
  points.forEach(p => {
    ctx.beginPath();
    ctx.arc(p.x, p.y, 3, 0, Math.PI * 2);
    ctx.fillStyle = lineColor;
    ctx.fill();
  });

  // Date labels
  ctx.fillStyle = '#9ca3af';
  ctx.font = '9px system-ui';
  ctx.textAlign = 'center';
  const labelStep = Math.max(1, Math.floor(values.length / 5));
  relevantSessions.forEach((s, i) => {
    if (i % labelStep !== 0 && i !== values.length - 1) return;
    const d = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    ctx.fillText(v3FormatDateShort(d), points[i].x, h - 4);
  });
}

// ==================== TAB 3: PLAN PROGRESS ====================

function renderV4PlanProgress() {
  const planMap = {};

  allSessions.forEach(session => {
    if (!session.planId) return;
    if (!planMap[session.planId]) {
      planMap[session.planId] = {
        planId: session.planId,
        planName: session.planName || session.planId,
        sessions: [],
        lastDate: null
      };
    }
    planMap[session.planId].sessions.push(session);
    const d = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    if (!planMap[session.planId].lastDate || d > planMap[session.planId].lastDate) {
      planMap[session.planId].lastDate = d;
    }
  });

  const sorted = Object.values(planMap).sort((a, b) => (b.lastDate || 0) - (a.lastDate || 0));

  if (sorted.length === 0) {
    return `<div class="pv3-empty-state">${trV3('progress.v4.plans.noPlans')}</div>`;
  }

  const rows = sorted.map(plan => {
    const lastDateStr = plan.lastDate ? v3FormatDate(plan.lastDate) : '-';
    const count = plan.sessions.length;
    return `
      <button class="pv4-plan-row" data-plan-id="${plan.planId}">
        <div class="pv4-plan-info">
          <div class="pv4-plan-name">${plan.planName}</div>
          <div class="pv4-plan-meta">${trV3('progress.v4.plans.sessions', { count })} \u00B7 ${trV3('progress.v4.plans.lastSession', { date: lastDateStr })}</div>
        </div>
        <span class="material-symbols-rounded pv4-plan-chevron">chevron_right</span>
      </button>`;
  }).join('');

  return `<div class="pv4-plan-list">${rows}</div>`;
}

// ==================== PLAN DETAIL ====================

function renderPlanDetail(planId) {
  const sessions = allSessions
    .filter(s => s.planId === planId)
    .sort((a, b) => {
      const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
      const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
      return db - da;
    });

  const planName = sessions[0]?.planName || planId;

  const entries = sessions.map((session, idx) => {
    const prevSession = sessions[idx + 1] || null;
    const d = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    const sessionNum = sessions.length - idx;
    const dur = v3GetDurationMin(session);

    // Build exercise comparison
    const comparison = typeof buildExerciseComparison === 'function'
      ? buildExerciseComparison(session, prevSession, [])
      : [];

    const exRows = comparison.map(ex => {
      if (ex.isNew) {
        return `<div class="pv4-timeline-ex"><span class="pv4-timeline-ex-name">${ex.name}</span><span class="pws-exercise-badge new">${trV3('progress.v4.postWorkout.badgeNew')}</span></div>`;
      }
      if (ex.isRemoved) {
        return `<div class="pv4-timeline-ex removed"><span class="pv4-timeline-ex-name">${ex.name}</span><span class="pws-exercise-badge removed">${trV3('progress.v4.postWorkout.badgeRemoved')}</span></div>`;
      }
      let deltaText = trV3('progress.v4.postWorkout.noChange');
      let deltaClass = 'same';
      if (ex.prevVol !== null && ex.curVol !== null) {
        const diff = ex.curVol - ex.prevVol;
        if (diff > 0) { deltaText = `+${diff}`; deltaClass = 'up'; }
        else if (diff < 0) { deltaText = `${diff}`; deltaClass = 'down'; }
      }
      return `
        <div class="pv4-timeline-ex">
          <span class="pv4-timeline-ex-name">${ex.name}</span>
          <span class="pv4-timeline-ex-delta ${deltaClass}">${deltaText}</span>
        </div>`;
    }).join('');

    const headerLabel = trV3('progress.v4.plans.detail.session', { num: sessionNum });
    const vsLabel = prevSession ? trV3('progress.v4.plans.detail.vsLast') : trV3('progress.v4.plans.detail.noComparison');

    return `
      <div class="pv4-timeline-entry">
        <div class="pv4-timeline-header">
          <div class="pv4-timeline-session">${headerLabel}</div>
          <div class="pv4-timeline-date">${v3FormatDate(d)}${dur > 0 ? ` \u00B7 ${dur} min` : ''}</div>
        </div>
        <div class="pv4-timeline-vs">${vsLabel}</div>
        <div class="pv4-timeline-exercises">${exRows}</div>
      </div>`;
  }).join('');

  return `
    <div class="pv4-detail-view">
      <div class="pv4-detail-header">
        <button class="pv4-back-btn" onclick="pv4PlanDetailId=null;renderProgressV4()">
          <span class="material-symbols-rounded">arrow_back</span>
        </button>
        <h3 class="pv4-detail-title">${planName}</h3>
      </div>
      <div class="pv4-plan-timeline">${entries}</div>
    </div>
  `;
}

// ==================== EXPOSE GLOBALLY ====================

window.initProgressV3 = initProgressV3;
window.renderProgressV3 = renderProgressV3;
window.renderProgressV4 = renderProgressV4;
window.pv4ExerciseDetailId = null;
window.pv4PlanDetailId = null;
