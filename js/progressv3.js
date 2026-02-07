// ========================================
// PROGRESS V3 - CALM SINGLE SCROLL VIEW
// ========================================
// Modules: Training Rhythm | Block Comparison | Training Mix | Cardio Snapshot | Session Stories
// Data source: allSessions (sessions.js)

const trV3 = (key, params) => (typeof t === 'function' ? t(key, params) : key);

// ==================== STATE ====================

let progressV3PeriodKey = localStorage.getItem('progressPeriodKey') || '30D';
let progressV3CardioMetric = 'time'; // 'time' | 'distance' | 'pace'
let progressV3Initialized = false;

// ==================== TYPE MAPPING ====================

const V3_TYPE_MAP = {
  strength: 'strength',
  kraft: 'strength',
  weights: 'strength',
  gym: 'strength',
  bodyweight: 'bodyweight',
  calisthenics: 'bodyweight',
  bw: 'bodyweight',
  cardio: 'cardio',
  running: 'cardio',
  laufen: 'cardio',
  run: 'cardio',
  bike: 'cardio',
  swim: 'cardio',
  row: 'cardio',
  recovery: 'recovery',
  stretching: 'recovery',
  mobility: 'recovery',
  yoga: 'recovery'
};

const V3_TYPE_COLORS = {
  strength: 'var(--color-category-strength)',
  bodyweight: 'var(--color-category-bodyweight)',
  cardio: 'var(--color-category-cardio)',
  recovery: 'var(--color-category-recovery)'
};

const V3_KNOWN_TYPES = ['strength', 'bodyweight', 'cardio', 'recovery'];

function mapSessionType(session) {
  const raw = (session.type || '').toLowerCase().trim();
  if (V3_TYPE_MAP[raw]) return V3_TYPE_MAP[raw];
  // Fallback: check activityType for cardio
  if (session.activityType) return 'cardio';
  return null; // ignore unknown
}

// ==================== DATE HELPERS (Europe/Berlin) ====================

function v3ToLocalDate(session) {
  const d = session.date?.toDate ? session.date.toDate() : new Date(session.date);
  // Convert to Europe/Berlin local date string then parse
  const str = d.toLocaleDateString('en-CA', { timeZone: 'Europe/Berlin' }); // YYYY-MM-DD
  return new Date(str + 'T12:00:00');
}

function v3GetDurationMin(session) {
  return getSessionDurationMinutesSafe(session);
}

function v3WeekNumber(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7));
  const week1 = new Date(d.getFullYear(), 0, 4);
  return 1 + Math.round(((d - week1) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7);
}

function v3WeekKey(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  // ISO week: get thursday of this week
  d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7));
  const year = d.getFullYear();
  const wn = v3WeekNumber(date);
  return `${year}-W${String(wn).padStart(2, '0')}`;
}

function v3DaysBetween(a, b) {
  const da = new Date(a); da.setHours(0, 0, 0, 0);
  const db = new Date(b); db.setHours(0, 0, 0, 0);
  return Math.round((db - da) / 86400000);
}

function v3PeriodDays(key) {
  return PERIOD_CONFIG[key]?.days || 30;
}

// ==================== SESSION FILTERING ====================

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

function v3SessionsInDateRange(startDate, endDate) {
  return allSessions.filter(s => {
    const d = v3ToLocalDate(s);
    return d >= startDate && d <= endDate;
  });
}

// ==================== INIT ====================

async function initProgressV3() {
  console.log('📊 Initializing Progress V3...');
  const container = document.getElementById('progress-tab-content');
  if (!container) return;

  // Show skeleton loading
  container.innerHTML = renderV3Skeleton();

  // Hide segmented control (V2 tabs)
  const segCtrl = document.getElementById('progress-segmented-control');
  if (segCtrl) segCtrl.style.display = 'none';

  // Load sessions if not yet loaded
  if (!sessionsLoaded || !allSessions.length) {
    await loadSessions();
  }

  // Load period from localStorage
  progressV3PeriodKey = localStorage.getItem('progressPeriodKey') || '30D';

  // Render all modules
  renderProgressV3();
  progressV3Initialized = true;
}

// ==================== MAIN RENDER ====================

function renderProgressV3() {
  const container = document.getElementById('progress-tab-content');
  if (!container) return;

  container.innerHTML = `
    <div class="pv3-scroll-view">
      ${renderV3PeriodSelector()}
      ${renderV3Rhythm()}
      ${renderV3BlockComparison()}
      ${renderV3Mix()}
      ${renderV3CardioSnapshot()}
      ${renderV3Stories()}
    </div>
  `;

  // Attach event listeners after render
  attachV3PeriodListeners();
  attachV3CardioToggleListeners();
}

// ==================== SKELETON ====================

function renderV3Skeleton() {
  const skeletonCard = `
    <div class="pv3-card pv3-skeleton-card">
      <div class="pv3-skeleton-line pv3-skeleton-title"></div>
      <div class="pv3-skeleton-line pv3-skeleton-bar"></div>
      <div class="pv3-skeleton-line pv3-skeleton-bar short"></div>
    </div>`;
  return `<div class="pv3-scroll-view">${skeletonCard.repeat(4)}</div>`;
}

// ==================== PERIOD SELECTOR ====================

function renderV3PeriodSelector() {
  const periods = [
    { key: '7D', label: trV3('progress.period.7d') },
    { key: '30D', label: trV3('progress.period.30d') },
    { key: '6M', label: trV3('progress.period.6m') },
    { key: '1Y', label: trV3('progress.period.1y') }
  ];
  const pills = periods.map(p =>
    `<button class="pv3-period-pill${p.key === progressV3PeriodKey ? ' active' : ''}" data-period="${p.key}">${p.label}</button>`
  ).join('');

  return `<div class="pv3-period-selector">${pills}</div>`;
}

function attachV3PeriodListeners() {
  document.querySelectorAll('.pv3-period-pill').forEach(btn => {
    btn.addEventListener('click', () => {
      progressV3PeriodKey = btn.dataset.period;
      localStorage.setItem('progressPeriodKey', progressV3PeriodKey);
      renderProgressV3();
    });
  });
}

// ==================== MODULE 1: TRAINING RHYTHM ====================

function renderV3Rhythm() {
  const WEEKS = 12;
  const now = new Date();
  const nowLocal = new Date(now.toLocaleDateString('en-CA', { timeZone: 'Europe/Berlin' }) + 'T23:59:59');

  // Build weekly buckets for last 12 weeks
  const weeks = [];
  for (let i = WEEKS - 1; i >= 0; i--) {
    const weekEnd = new Date(nowLocal);
    weekEnd.setDate(weekEnd.getDate() - i * 7);
    const weekStart = new Date(weekEnd);
    weekStart.setDate(weekStart.getDate() - 6);
    weekStart.setHours(0, 0, 0, 0);
    weeks.push({ start: weekStart, end: weekEnd, data: { strength: 0, bodyweight: 0, cardio: 0, recovery: 0 } });
  }

  // Fill buckets
  const cutoff = weeks[0].start;
  allSessions.forEach(s => {
    const d = v3ToLocalDate(s);
    if (d < cutoff) return;
    const type = mapSessionType(s);
    if (!type) return;
    const mins = v3GetDurationMin(s);
    for (const w of weeks) {
      if (d >= w.start && d <= w.end) {
        w.data[type] += mins;
        break;
      }
    }
  });

  // Find max for scaling
  const maxMin = Math.max(1, ...weeks.map(w => V3_KNOWN_TYPES.reduce((sum, t) => sum + w.data[t], 0)));

  // Check if any data
  const hasData = weeks.some(w => V3_KNOWN_TYPES.some(t => w.data[t] > 0));

  if (!hasData) {
    return `
      <div class="pv3-card">
        <div class="pv3-card-header">
          <h3 class="pv3-card-title">${trV3('progress.v3.rhythm.title')}</h3>
          <span class="pv3-card-subtitle">${trV3('progress.v3.rhythm.subtitle')}</span>
        </div>
        <div class="pv3-empty-state">${trV3('progress.v3.rhythm.noData')}</div>
      </div>`;
  }

  // Render stacked bars
  const barsHtml = weeks.map((w, idx) => {
    const total = V3_KNOWN_TYPES.reduce((sum, t) => sum + w.data[t], 0);
    const heightPct = Math.max(0, (total / maxMin) * 100);
    const segments = V3_KNOWN_TYPES
      .filter(t => w.data[t] > 0)
      .map(t => {
        const segPct = (w.data[t] / total) * 100;
        return `<div class="pv3-rhythm-seg" style="height:${segPct}%;background:${V3_TYPE_COLORS[t]}" title="${trV3('progress.v3.types.' + t)}: ${w.data[t]} min"></div>`;
      }).join('');

    const weekLabel = `${w.start.getDate()}.${w.start.getMonth() + 1}`;
    const isCurrentWeek = idx === weeks.length - 1;

    return `
      <div class="pv3-rhythm-col${isCurrentWeek ? ' current' : ''}">
        <div class="pv3-rhythm-bar" style="height:${heightPct}%">
          ${segments}
        </div>
        <span class="pv3-rhythm-label">${weekLabel}</span>
      </div>`;
  }).join('');

  // Legend
  const legendHtml = V3_KNOWN_TYPES
    .filter(t => weeks.some(w => w.data[t] > 0))
    .map(t => `<span class="pv3-legend-item"><span class="pv3-legend-dot" style="background:${V3_TYPE_COLORS[t]}"></span>${trV3('progress.v3.types.' + t)}</span>`)
    .join('');

  return `
    <div class="pv3-card pv3-rhythm-card">
      <div class="pv3-card-header">
        <h3 class="pv3-card-title">${trV3('progress.v3.rhythm.title')}</h3>
        <span class="pv3-card-subtitle">${trV3('progress.v3.rhythm.subtitle')}</span>
      </div>
      <div class="pv3-rhythm-chart">${barsHtml}</div>
      <div class="pv3-legend">${legendHtml}</div>
    </div>`;
}

// ==================== MODULE 2: BLOCK COMPARISON ====================

function renderV3BlockComparison() {
  const now = new Date();
  const nowLocal = new Date(now.toLocaleDateString('en-CA', { timeZone: 'Europe/Berlin' }) + 'T23:59:59');

  const lastEnd = new Date(nowLocal);
  const lastStart = new Date(lastEnd);
  lastStart.setDate(lastStart.getDate() - 27);
  lastStart.setHours(0, 0, 0, 0);

  const prevEnd = new Date(lastStart);
  prevEnd.setDate(prevEnd.getDate() - 1);
  prevEnd.setHours(23, 59, 59);
  const prevStart = new Date(prevEnd);
  prevStart.setDate(prevStart.getDate() - 27);
  prevStart.setHours(0, 0, 0, 0);

  const lastSessions = v3SessionsInDateRange(lastStart, lastEnd);
  const prevSessions = v3SessionsInDateRange(prevStart, prevEnd);

  function blockStats(sessions) {
    let totalMin = 0;
    let cardioMin = 0;
    let count = 0;
    sessions.forEach(s => {
      const type = mapSessionType(s);
      if (!type) return;
      const mins = v3GetDurationMin(s);
      totalMin += mins;
      if (type === 'cardio') cardioMin += mins;
      count++;
    });
    return {
      sessionsPerWeek: count / 4,
      minutesPerWeek: totalMin / 4,
      cardioShare: totalMin > 0 ? (cardioMin / totalMin) * 100 : 0,
      totalSessions: count
    };
  }

  const last = blockStats(lastSessions);
  const prev = blockStats(prevSessions);

  function arrow(curr, prevVal) {
    if (prev.totalSessions === 0) return { icon: '–', cls: 'neutral', text: trV3('progress.v3.blockComparison.noPrevData') };
    const diff = curr - prevVal;
    if (Math.abs(diff) < 0.1) return { icon: '↔', cls: 'neutral', text: trV3('progress.v3.blockComparison.noChange') };
    if (diff > 0) return { icon: '↑', cls: 'up', text: `+${diff < 10 ? diff.toFixed(1) : Math.round(diff)}` };
    return { icon: '↓', cls: 'down', text: `${diff < -10 ? Math.round(diff) : diff.toFixed(1)}` };
  }

  const metrics = [
    {
      label: trV3('progress.v3.blockComparison.sessionsPerWeek'),
      value: last.sessionsPerWeek.toFixed(1),
      change: arrow(last.sessionsPerWeek, prev.sessionsPerWeek)
    },
    {
      label: trV3('progress.v3.blockComparison.minutesPerWeek'),
      value: Math.round(last.minutesPerWeek),
      change: arrow(last.minutesPerWeek, prev.minutesPerWeek)
    },
    {
      label: trV3('progress.v3.blockComparison.cardioShare'),
      value: `${Math.round(last.cardioShare)}%`,
      change: arrow(last.cardioShare, prev.cardioShare)
    }
  ];

  const metricsHtml = metrics.map(m => `
    <div class="pv3-block-metric">
      <span class="pv3-block-label">${m.label}</span>
      <div class="pv3-block-value-row">
        <span class="pv3-block-value">${m.value}</span>
        <span class="pv3-block-change ${m.change.cls}">
          <span class="pv3-block-arrow">${m.change.icon}</span>
          <span class="pv3-block-diff">${m.change.text}</span>
        </span>
      </div>
    </div>`).join('');

  return `
    <div class="pv3-card">
      <div class="pv3-card-header">
        <h3 class="pv3-card-title">${trV3('progress.v3.blockComparison.title')}</h3>
        <span class="pv3-card-subtitle">${trV3('progress.v3.blockComparison.last4w')} vs ${trV3('progress.v3.blockComparison.prev4w')}</span>
      </div>
      <div class="pv3-block-metrics">${metricsHtml}</div>
    </div>`;
}

// ==================== MODULE 3: TRAINING MIX ====================

function renderV3Mix() {
  const days = v3PeriodDays(progressV3PeriodKey);
  const sessions = v3SessionsInRange(days);

  const typeMins = { strength: 0, bodyweight: 0, cardio: 0, recovery: 0 };
  sessions.forEach(s => {
    const type = mapSessionType(s);
    if (!type) return;
    typeMins[type] += v3GetDurationMin(s);
  });

  const totalMin = Object.values(typeMins).reduce((a, b) => a + b, 0);

  if (totalMin === 0) {
    return `
      <div class="pv3-card">
        <div class="pv3-card-header">
          <h3 class="pv3-card-title">${trV3('progress.v3.mix.title')}</h3>
        </div>
        <div class="pv3-empty-state">${trV3('progress.v3.mix.noData')}</div>
      </div>`;
  }

  // Sort by minutes descending
  const sorted = V3_KNOWN_TYPES
    .filter(t => typeMins[t] > 0)
    .sort((a, b) => typeMins[b] - typeMins[a]);

  const maxMins = typeMins[sorted[0]] || 1;

  const barsHtml = sorted.map(t => {
    const pct = ((typeMins[t] / totalMin) * 100);
    const barWidth = ((typeMins[t] / maxMins) * 100);
    return `
      <div class="pv3-mix-row">
        <span class="pv3-mix-label">${trV3('progress.v3.types.' + t)}</span>
        <div class="pv3-mix-bar-track">
          <div class="pv3-mix-bar-fill" style="width:${barWidth}%;background:${V3_TYPE_COLORS[t]}"></div>
        </div>
        <span class="pv3-mix-pct">${Math.round(pct)}%</span>
      </div>`;
  }).join('');

  return `
    <div class="pv3-card">
      <div class="pv3-card-header">
        <h3 class="pv3-card-title">${trV3('progress.v3.mix.title')}</h3>
      </div>
      ${barsHtml}
    </div>`;
}

// ==================== MODULE 4: CARDIO SNAPSHOT ====================

function renderV3CardioSnapshot() {
  const days = v3PeriodDays(progressV3PeriodKey);
  const sessions = v3SessionsInRange(days).filter(s => mapSessionType(s) === 'cardio');

  if (sessions.length === 0) {
    return `
      <div class="pv3-card">
        <div class="pv3-card-header">
          <h3 class="pv3-card-title">${trV3('progress.v3.cardioSnapshot.title')}</h3>
        </div>
        <div class="pv3-empty-state">${trV3('progress.v3.cardioSnapshot.noData')}</div>
      </div>`;
  }

  // Check if distance data exists
  const hasDistance = sessions.some(s => (s.distanceKm || 0) > 0);

  // Build weekly buckets
  const weekMap = {};
  const weekOrder = [];
  sessions.forEach(s => {
    const d = v3ToLocalDate(s);
    const wk = v3WeekKey(d);
    if (!weekMap[wk]) {
      weekMap[wk] = { time: 0, distance: 0, sessionsWithDist: 0, weekNum: v3WeekNumber(d) };
      weekOrder.push(wk);
    }
    const mins = v3GetDurationMin(s);
    weekMap[wk].time += mins;
    const dist = Number(s.distanceKm) || 0;
    if (dist > 0) {
      weekMap[wk].distance += dist;
      weekMap[wk].sessionsWithDist++;
    }
  });

  // Calculate pace per week (distance-weighted)
  weekOrder.forEach(wk => {
    const w = weekMap[wk];
    w.pace = w.distance > 0 ? w.time / w.distance : null; // min/km
  });

  // Determine if pace toggle is disabled
  const paceDisabled = !hasDistance;

  // Effective metric (fallback if pace disabled)
  let metric = progressV3CardioMetric;
  if (metric === 'pace' && paceDisabled) metric = 'time';

  // Chart data
  const chartValues = weekOrder.map(wk => {
    const w = weekMap[wk];
    if (metric === 'time') return w.time;
    if (metric === 'distance') return w.distance;
    if (metric === 'pace') return w.pace || 0;
    return 0;
  });

  const chartLabels = weekOrder.map(wk => {
    const w = weekMap[wk];
    return trV3('progress.v3.cardioSnapshot.weekLabel', { week: w.weekNum });
  });

  const maxVal = Math.max(1, ...chartValues);

  // For pace: lower is better, invert bar heights
  const isPace = metric === 'pace';

  const barsHtml = chartValues.map((val, i) => {
    let heightPct;
    if (isPace) {
      // Invert: longest pace = shortest bar, shortest pace = tallest bar
      heightPct = val > 0 ? Math.max(10, (1 - (val - Math.min(...chartValues.filter(v => v > 0))) / (maxVal - Math.min(...chartValues.filter(v => v > 0)) + 0.01)) * 100) : 0;
    } else {
      heightPct = (val / maxVal) * 100;
    }

    let displayVal;
    if (metric === 'time') displayVal = `${Math.round(val)}`;
    else if (metric === 'distance') displayVal = val.toFixed(1);
    else displayVal = val > 0 ? formatPaceVal(val) : '-';

    return `
      <div class="pv3-cardio-col">
        <span class="pv3-cardio-val">${displayVal}</span>
        <div class="pv3-cardio-bar" style="height:${Math.max(2, heightPct)}%;background:var(--color-category-cardio)"></div>
        <span class="pv3-cardio-label">${chartLabels[i]}</span>
      </div>`;
  }).join('');

  // Totals
  const totalTime = sessions.reduce((sum, s) => sum + v3GetDurationMin(s), 0);
  const totalDist = sessions.reduce((sum, s) => sum + (Number(s.distanceKm) || 0), 0);
  const avgPace = totalDist > 0 ? totalTime / totalDist : null;

  // Toggle
  const toggles = [
    { key: 'time', label: trV3('progress.v3.cardioSnapshot.toggleTime'), disabled: false },
    { key: 'distance', label: trV3('progress.v3.cardioSnapshot.toggleDistance'), disabled: false },
    { key: 'pace', label: trV3('progress.v3.cardioSnapshot.togglePace'), disabled: paceDisabled }
  ];

  const toggleHtml = toggles.map(tog =>
    `<button class="pv3-cardio-toggle-btn${progressV3CardioMetric === tog.key ? ' active' : ''}${tog.disabled ? ' disabled' : ''}" data-metric="${tog.key}" ${tog.disabled ? 'disabled' : ''}>${tog.label}</button>`
  ).join('');

  // Totals row
  const totalsHtml = `
    <div class="pv3-cardio-totals">
      <div class="pv3-cardio-total">
        <span class="pv3-cardio-total-label">${trV3('progress.v3.cardioSnapshot.totalTime')}</span>
        <span class="pv3-cardio-total-value">${totalTime} min</span>
      </div>
      <div class="pv3-cardio-total">
        <span class="pv3-cardio-total-label">${trV3('progress.v3.cardioSnapshot.totalDistance')}</span>
        <span class="pv3-cardio-total-value">${totalDist > 0 ? totalDist.toFixed(1) + ' km' : '-'}</span>
      </div>
      <div class="pv3-cardio-total">
        <span class="pv3-cardio-total-label">${trV3('progress.v3.cardioSnapshot.avgPace')}</span>
        <span class="pv3-cardio-total-value">${avgPace ? formatPaceVal(avgPace) + ' min/km' : '-'}</span>
      </div>
    </div>`;

  const paceHint = paceDisabled ? `<div class="pv3-pace-hint">${trV3('progress.v3.cardioSnapshot.noPaceData')}</div>` : '';

  return `
    <div class="pv3-card">
      <div class="pv3-card-header">
        <h3 class="pv3-card-title">${trV3('progress.v3.cardioSnapshot.title')}</h3>
      </div>
      <div class="pv3-cardio-toggle">${toggleHtml}</div>
      ${paceHint}
      <div class="pv3-cardio-chart">${barsHtml}</div>
      ${totalsHtml}
    </div>`;
}

function formatPaceVal(paceMinPerKm) {
  if (!paceMinPerKm || paceMinPerKm <= 0) return '-';
  const minutes = Math.floor(paceMinPerKm);
  let seconds = Math.round((paceMinPerKm - minutes) * 60);
  if (seconds >= 60) { return `${minutes + 1}:00`; }
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
}

function attachV3CardioToggleListeners() {
  document.querySelectorAll('.pv3-cardio-toggle-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      if (btn.disabled) return;
      progressV3CardioMetric = btn.dataset.metric;
      renderProgressV3();
    });
  });
}

// ==================== MODULE 5: SESSION STORIES ====================

function renderV3Stories() {
  const days = v3PeriodDays(progressV3PeriodKey);
  const sessions = v3SessionsInRange(days);

  if (sessions.length === 0) {
    return `
      <div class="pv3-card">
        <div class="pv3-card-header">
          <h3 class="pv3-card-title">${trV3('progress.v3.stories.title')}</h3>
        </div>
        <div class="pv3-empty-state">${trV3('progress.v3.stories.noData')}</div>
      </div>`;
  }

  const bullets = [];

  // 1) Sessions summary
  const totalMin = sessions.reduce((sum, s) => sum + v3GetDurationMin(s), 0);
  const avgMin = sessions.length > 0 ? Math.round(totalMin / sessions.length) : 0;
  bullets.push(trV3('progress.v3.stories.sessionsSummary', {
    days: days,
    count: sessions.length,
    avg: avgMin
  }));

  // 2) Longest break
  const sortedDates = sessions
    .map(s => v3ToLocalDate(s))
    .sort((a, b) => a - b);

  let maxGap = 0;
  for (let i = 1; i < sortedDates.length; i++) {
    const gap = v3DaysBetween(sortedDates[i - 1], sortedDates[i]);
    if (gap > maxGap) maxGap = gap;
  }
  if (maxGap > 0) {
    bullets.push(trV3('progress.v3.stories.longestBreak', { days: maxGap }));
  }

  // 3) Strength weeks
  const strengthSessions = sessions.filter(s => {
    const t = mapSessionType(s);
    return t === 'strength' || t === 'bodyweight';
  });
  if (strengthSessions.length > 0) {
    const activeWeeks = new Set(strengthSessions.map(s => v3WeekKey(v3ToLocalDate(s)))).size;
    const totalWeeks = Math.max(1, Math.ceil(days / 7));
    bullets.push(trV3('progress.v3.stories.strengthWeeks', { active: activeWeeks, total: totalWeeks }));
  }

  const bulletsHtml = bullets.slice(0, 3).map(b =>
    `<li class="pv3-story-bullet">${b}</li>`
  ).join('');

  return `
    <div class="pv3-card">
      <div class="pv3-card-header">
        <h3 class="pv3-card-title">${trV3('progress.v3.stories.title')}</h3>
      </div>
      <ul class="pv3-stories-list">${bulletsHtml}</ul>
    </div>`;
}

// ==================== EXPOSE GLOBALLY ====================

window.initProgressV3 = initProgressV3;
window.renderProgressV3 = renderProgressV3;
