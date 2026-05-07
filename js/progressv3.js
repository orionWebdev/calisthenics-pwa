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
let pv4EnduranceSport = localStorage.getItem('enduranceSportKey') || 'run';
let progressV3Initialized = false;

// Exercise filter state
let pv4ExerciseSearchTerm = '';
let pv4ExerciseMuscleFilter = '';
let _pv4ExerciseSearchTimer = null;

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

/**
 * Calculates baseline building status
 * @returns {{ status: string, daysElapsed: number, daysRemaining: number, percentage: number, message: string }}
 */
function getBaselineStatus() {
  if (!allSessions || !allSessions.length) {
    return {
      status: 'no_data',
      daysElapsed: 0,
      daysRemaining: 14,
      percentage: 0,
      message: trV3('progress.baseline.noData')
    };
  }

  const trainingSessions = allSessions.filter(s => {
    if (s.type !== 'strength' && s.type !== 'bodyweight' && s.type !== 'cardio') return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (isNaN(sessionDate.getTime())) return false;
    return true;
  });

  if (!trainingSessions.length) {
    return {
      status: 'no_data',
      daysElapsed: 0,
      daysRemaining: 14,
      percentage: 0,
      message: trV3('progress.baseline.noData')
    };
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let earliestDate = new Date();
  for (const s of trainingSessions) {
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (sessionDate < earliestDate) {
      earliestDate = sessionDate;
    }
  }

  const daysElapsed = Math.floor((today.getTime() - earliestDate.getTime()) / (1000 * 60 * 60 * 24));
  const daysRemaining = Math.max(0, 14 - daysElapsed);
  const percentage = Math.min(100, Math.round((daysElapsed / 14) * 100));

  if (daysRemaining === 0) {
    return {
      status: 'complete',
      daysElapsed,
      daysRemaining: 0,
      percentage: 100,
      message: trV3('progress.baseline.complete')
    };
  }

  return {
    status: 'building',
    daysElapsed,
    daysRemaining,
    percentage,
    message: trV3('progress.baseline.building', { days: daysRemaining })
  };
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

  const skeletonStart = Date.now();

  if (!sessionsLoaded || !allSessions.length) {
    await loadSessions();
  }

  pv4Period = localStorage.getItem('progressPeriodKey')
    || (typeof getSettingValue === 'function' ? getSettingValue('defaultProgressPeriod') : '30D');

  // Show skeleton for at least 1.5s so data can load without visual glitches
  const elapsed = Date.now() - skeletonStart;
  const remaining = Math.max(0, 1500 - elapsed);
  if (remaining > 0) {
    await new Promise(r => setTimeout(r, remaining));
  }

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
    ${renderV4TabBar()}
    <div class="pv3-scroll-view">
      ${renderV4TabContent()}
    </div>
  `;

  attachV4TabListeners();

  if (pv4Tab === 'overview') {
    attachV4PeriodListeners();
    // Initialize charts after DOM is ready
    setTimeout(() => {
      initWeeklyScoreChart();
      initEnduranceCharts();
      attachEnduranceSportListeners();
    }, 50);
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
    <div class="pv3-sticky-bar">
      <div class="pv3-segmented-control" style="--seg-count:${periods.length};--active-idx:${activeIndex}">
        <div class="pv3-seg-indicator"></div>
        ${periods.map(p =>
          `<button class="pv3-seg-btn${p.key === pv4Period ? ' active' : ''}" data-period="${p.key}">${p.label}</button>`
        ).join('')}
      </div>
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

// Kurze Labels für Rhythmus-Buckets
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

// ---- Chart instances (Chart.js) ----
let weeklyScoreChartInstance = null;
let enduranceDistanceChartInstance = null;
let endurancePaceChartInstance = null;
let enduranceDurationChartInstance = null;
let enduranceSessionsChartInstance = null;

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

  // Training Form (prominent) + Readiness (compact)
  const formHTML = renderFormWidget();
  const readinessHTML = renderReadinessWidget();
  const weeklyScoreChartHTML = renderV4WeeklyScoreChartHTML();

  // Training Rhythm widget
  const rhythmHTML = renderV4Rhythm(sessions);

  // Endurance Trends card (distance, pace, summary)
  const runningHTML = renderEnduranceCard(sessions);

  // Session history (collapsible)
  const historyHTML = renderV4SessionHistory(sessions);

  return `
    ${renderV4PeriodSelector()}
    ${formHTML}
    ${readinessHTML}
    <div class="pv4-summary-grid">${cardsHTML}</div>
    ${weeklyScoreChartHTML}
    ${rhythmHTML}
    ${runningHTML}
    ${historyHTML}
  `;
}

// ==================== TRAINING PHASE WIDGET (ACWR) ====================

function getZoneColor(zone) {
  const map = {
    overreaching: 'var(--zone-exhausted)',
    fatigued: 'var(--zone-fatigued)',
    maintaining: 'var(--zone-loaded)',
    building: 'var(--zone-ready)',
    peak: 'var(--zone-fresh)',
    form_loss: 'var(--zone-form-loss)'
  };
  return map[zone] || map.maintaining;
}

function getZoneBg(zone) {
  const map = {
    overreaching: 'var(--zone-exhausted-bg)',
    fatigued: 'var(--zone-fatigued-bg)',
    maintaining: 'var(--zone-loaded-bg)',
    building: 'var(--zone-ready-bg)',
    peak: 'var(--zone-fresh-bg)',
    form_loss: 'var(--zone-form-loss-bg)'
  };
  return map[zone] || map.maintaining;
}

function getPhaseFromZone(zone) {
  const zoneMap = {
    overreaching: { label: trV3('progress.readiness.zoneOverreaching') },
    fatigued: { label: trV3('progress.readiness.zoneFatigued') },
    maintaining: { label: trV3('progress.readiness.zoneMaintaining') },
    building: { label: trV3('progress.readiness.zoneBuilding') },
    peak: { label: trV3('progress.readiness.zonePeak') },
    form_loss: { label: trV3('progress.readiness.zoneFormLoss') }
  };
  const entry = zoneMap[zone] || zoneMap.maintaining;
  return {
    label: entry.label,
    color: getZoneColor(zone),
    bgTint: `linear-gradient(${getZoneBg(zone)}, ${getZoneBg(zone)}), var(--bg-card)`
  };
}

function getReadinessInsight(zone) {
  if (!zone) return trV3('progress.readiness.insightNoData');
  const map = {
    overreaching: 'insightZoneOverreaching',
    fatigued:     'insightZoneFatigued',
    maintaining:  'insightZoneMaintaining',
    building:     'insightZoneBuilding',
    peak:         'insightZonePeak',
    form_loss:    'insightZoneFormLoss'
  };
  return trV3('progress.readiness.' + (map[zone] || map.maintaining));
}

function getScoreChangeInsight(changeData) {
  if (!changeData || changeData.driver === null) {
    return { main: trV3('progress.readiness.changeNoData'), sub: null };
  }
  if (changeData.driver === 'none') {
    return { main: trV3('progress.readiness.changeNone'), sub: null };
  }

  const { scoreDelta, acuteDelta, driver, todayLoad, daysSinceLastSession, biggestSession } = changeData;
  let main = '';
  let sub = null;

  if (scoreDelta > 0 && driver === 'training') {
    main = trV3('progress.readiness.changeUpTraining');
    if (todayLoad > 0) sub = trV3('progress.readiness.changeSubLoad', { load: todayLoad });
  } else if (scoreDelta > 0 && driver === 'recovery') {
    main = trV3('progress.readiness.changeUpRecovery');
    sub = trV3('progress.readiness.changeSubRest', { load: Math.abs(Math.round(acuteDelta)), days: daysSinceLastSession });
  } else if (scoreDelta < 0 && driver === 'training') {
    main = trV3('progress.readiness.changeDownTraining');
    if (todayLoad > 0) sub = trV3('progress.readiness.changeSubLoad', { load: todayLoad });
  } else if (scoreDelta < 0 && driver === 'recovery') {
    main = trV3('progress.readiness.changeDownRecovery');
  } else if (driver === 'baseline_shift') {
    main = trV3('progress.readiness.changeBaseline');
  } else {
    main = trV3('progress.readiness.changeNone');
  }

  if (biggestSession && todayLoad > 0) {
    const driverText = trV3('progress.readiness.changeDriver', { name: biggestSession.name, duration: biggestSession.duration });
    sub = sub ? sub + ' \u00B7 ' + driverText : driverText;
  }

  return { main, sub };
}

function getPhaseHint(score) {
  if (score < 60) return trV3('progress.readiness.hintLow');
  if (score <= 75) return trV3('progress.readiness.hintMaintaining');
  if (score <= 90) return trV3('progress.readiness.hintBuilding');
  return trV3('progress.readiness.hintPeak');
}

function renderTrainingPhaseTimeline(days = 7) {
  if (typeof getACWR !== 'function' || !allSessions?.length) return '';

  const segments = [];
  const today = new Date();
  today.setHours(23, 59, 59, 999);

  for (let i = 0; i < days; i++) {
    const dayDate = new Date(today);
    dayDate.setDate(dayDate.getDate() - (days - 1 - i));

    const data = getACWR(allSessions, dayDate);
    const hasZone = data.zone !== null;
    const color = hasZone ? getZoneColor(data.zone) : 'var(--bg-surface-active)';
    const opacity = 0.5 + 0.5 * (i / (days - 1));

    segments.push(`<div class="acwr-timeline-segment" style="background: ${color}; opacity: ${opacity.toFixed(2)};"></div>`);
  }

  return `
    <div class="acwr-timeline">
      <div class="acwr-timeline-track">${segments.join('')}</div>
    </div>`;
}

// ─── FORM WIDGET (prominent) ───────────────────────────────────

function getFormZoneColor(zone) {
  const map = {
    detrained: 'var(--zone-form-loss)',
    declining: 'var(--zone-fatigued)',
    recovery: 'var(--zone-fresh)',
    maintaining: 'var(--zone-loaded)',
    building: 'var(--zone-ready-light)',
    productive: 'var(--zone-ready-dark)',
    peak_form: 'var(--zone-peak-form)'
  };
  return map[zone] || map.maintaining;
}

function getFormZoneBg(zone) {
  const map = {
    detrained: 'var(--zone-form-loss-bg)',
    declining: 'var(--zone-fatigued-bg)',
    recovery: 'var(--zone-fresh-bg)',
    maintaining: 'var(--zone-loaded-bg)',
    building: 'var(--zone-ready-light-bg)',
    productive: 'var(--zone-ready-dark-bg)',
    peak_form: 'var(--zone-peak-form-bg)'
  };
  return map[zone] || map.maintaining;
}

function getFormPhaseLabel(zone) {
  const map = {
    detrained: trV3('progress.form.zoneDetrained'),
    declining: trV3('progress.form.zoneDeclining'),
    recovery: trV3('progress.form.zoneRecovery'),
    maintaining: trV3('progress.form.zoneMaintaining'),
    building: trV3('progress.form.zoneBuilding'),
    productive: trV3('progress.form.zoneProductive'),
    peak_form: trV3('progress.form.zonePeakForm')
  };
  return map[zone] || map.maintaining;
}

function getFormHint(score, zone) {
  const hintMap = {
    recovery: 'progress.form.hintRecovery',
    detrained: 'progress.form.hintDetrained',
    declining: 'progress.form.hintDeclining',
    maintaining: 'progress.form.hintMaintaining',
    building: 'progress.form.hintBuilding',
    productive: 'progress.form.hintProductive',
    peak_form: 'progress.form.hintPeakForm'
  };
  return trV3(hintMap[zone] || 'progress.form.hintMaintaining');
}

function getFormTrendLabel(trend) {
  const map = {
    rising: trV3('progress.form.trendRising'),
    stable: trV3('progress.form.trendStable'),
    falling: trV3('progress.form.trendFalling')
  };
  return map[trend] || map.stable;
}

function getFormTrendIcon(trend) {
  if (trend === 'rising') return 'trending_up';
  if (trend === 'falling') return 'trending_down';
  return 'trending_flat';
}

function renderFormScale(score) {
  // Raw-score boundaries that correspond to the transformed phase thresholds
  // in mapFormZone (sessions.js). Dot is positioned by raw score, so segments
  // must use raw-score edges to match the visible phase label.
  const phases = [
    { zone: 'detrained', max: 22 },
    { zone: 'declining', max: 42 },
    { zone: 'maintaining', max: 66 },
    { zone: 'building', max: 83 },
    { zone: 'productive', max: 95 },
    { zone: 'peak_form', max: 100 }
  ];

  const segments = phases.map((p, i) => {
    const start = i === 0 ? 0 : phases[i - 1].max;
    const width = p.max - start;
    const color = getFormZoneColor(p.zone);
    const label = getFormPhaseLabel(p.zone);
    return `<div class="form-scale-segment" style="width: ${width}%; background: ${color};" title="${label} (${start}–${p.max})"></div>`;
  });

  const clampedScore = Math.max(0, Math.min(100, score));

  return `
    <div class="form-scale">
      <div class="form-scale-track">${segments.join('')}</div>
      <div class="form-scale-dot" style="left: ${clampedScore}%;"></div>
      <div class="form-scale-labels">
        <span>0</span>
        <span>100</span>
      </div>
    </div>`;
}

function renderFormWidget() {
  if (typeof computeFormScore !== 'function') return '';

  const data = computeFormScore(allSessions, new Date());

  if (data.formScore === null || data.zone === null) {
    const baselineStatus = getBaselineStatus();
    const progressBar = baselineStatus.status !== 'no_data' ? `
      <div class="baseline-progress-container">
        <div class="baseline-progress-bar">
          <div class="baseline-progress-fill" style="width: ${baselineStatus.percentage}%"></div>
        </div>
        <div class="baseline-progress-label">${baselineStatus.daysElapsed} / 14 ${trV3('progress.baseline.days')}</div>
      </div>
    ` : '';

    return `
      <div class="pv3-card acwr-widget">
        <div class="acwr-widget-header">
          <h3 class="pv3-card-title">${trV3('progress.form.title')}</h3>
        </div>
        <div class="acwr-score-section">
          <div class="acwr-zone-label" style="color: var(--text-tertiary);">--</div>
          <div class="acwr-score-display" style="color: var(--text-tertiary);">${baselineStatus.message}</div>
        </div>
        ${progressBar}
      </div>`;
  }

  const zoneColor = getFormZoneColor(data.zone);
  const zoneBg = getFormZoneBg(data.zone);
  const phaseLabel = getFormPhaseLabel(data.zone);
  const scaleHTML = renderFormScale(data.formScore);
  const hint = getFormHint(data.formScore, data.zone);
  const trendLabel = getFormTrendLabel(data.trend);
  const trendIcon = getFormTrendIcon(data.trend);

  // Delta vs yesterday
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const prevData = computeFormScore(allSessions, yesterday);
  const formDelta = prevData.formScore !== null ? data.formScore - prevData.formScore : null;
  const deltaHTML = formDelta !== null && formDelta !== 0
    ? `<span class="score-delta" style="color: ${formDelta > 0 ? 'var(--zone-fresh)' : 'var(--zone-fatigued)'};">${formDelta > 0 ? '+' : ''}${formDelta}</span>`
    : '';

  return `
    <div class="pv3-card acwr-widget" style="background: linear-gradient(${zoneBg}, ${zoneBg}), var(--bg-card);">
      <div class="acwr-widget-header">
        <h3 class="pv3-card-title">${trV3('progress.form.title')}</h3>
        <button class="acwr-info-btn" onclick="openFormInfoModal()" aria-label="Info">
          <span class="material-symbols-rounded">info</span>
        </button>
      </div>
      <div class="acwr-score-section">
        <div class="acwr-zone-label" style="color: ${zoneColor};">${phaseLabel}</div>
        <div class="acwr-score-display">${data.formScore} ${deltaHTML}</div>
      </div>
      ${scaleHTML}
      <div class="training-insight">
        <div class="insight-text">
          <span class="material-symbols-rounded" style="font-size: 16px; vertical-align: middle; margin-right: 4px; color: ${zoneColor};">${trendIcon}</span>
          ${trendLabel}
        </div>
      </div>
      <div class="training-phase-hint">${hint}</div>
    </div>`;
}

function openFormInfoModal() {
  if (typeof openGenericModal !== 'function') return;
  openGenericModal(
    trV3('progress.form.infoTitle'),
    `<div class="acwr-info-content">
      <p>${trV3('progress.form.infoBody')}</p>
      <div class="acwr-info-zones">
        <div class="acwr-info-zone"><span class="acwr-info-dot" style="background:${getFormZoneColor('peak_form')};"></span>${trV3('progress.form.zonePeakForm')} (96–100)</div>
        <div class="acwr-info-zone"><span class="acwr-info-dot" style="background:${getFormZoneColor('productive')};"></span>${trV3('progress.form.zoneProductive')} (84–95)</div>
        <div class="acwr-info-zone"><span class="acwr-info-dot" style="background:${getFormZoneColor('building')};"></span>${trV3('progress.form.zoneBuilding')} (67–83)</div>
        <div class="acwr-info-zone"><span class="acwr-info-dot" style="background:${getFormZoneColor('maintaining')};"></span>${trV3('progress.form.zoneMaintaining')} (43–66)</div>
        <div class="acwr-info-zone"><span class="acwr-info-dot" style="background:${getFormZoneColor('recovery')};"></span>${trV3('progress.form.zoneRecovery')} (${trV3('progress.form.infoRecoveryCondition')})</div>
        <div class="acwr-info-zone"><span class="acwr-info-dot" style="background:${getFormZoneColor('declining')};"></span>${trV3('progress.form.zoneDeclining')} (23–42)</div>
        <div class="acwr-info-zone"><span class="acwr-info-dot" style="background:${getFormZoneColor('detrained')};"></span>${trV3('progress.form.zoneDetrained')} (0–22)</div>
      </div>
    </div>`
  );
}

// ─── READINESS WIDGET (compact) ────────────────────────────────

function renderReadinessWidget() {
  if (typeof getACWR !== 'function') return '';

  const data = getACWR(allSessions, new Date(), { applyFatigue: true });

  if (data.readinessScore === null || data.zone === null) {
    const baselineStatus = getBaselineStatus();
    const progressBar = baselineStatus.status !== 'no_data' ? `
      <div class="baseline-progress-container">
        <div class="baseline-progress-bar">
          <div class="baseline-progress-fill" style="width: ${baselineStatus.percentage}%"></div>
        </div>
        <div class="baseline-progress-label">${baselineStatus.daysElapsed} / 14 ${trV3('progress.baseline.days')}</div>
      </div>
    ` : '';

    return `
      <div class="pv3-card readiness-compact">
        <div class="readiness-compact-header">
          <h3 class="pv3-card-title">${trV3('progress.readiness.title')}</h3>
        </div>
        <div class="readiness-compact-body">
          <span class="readiness-compact-label" style="color: var(--text-tertiary);">--</span>
          <span class="readiness-compact-score" style="color: var(--text-tertiary);">${baselineStatus.message}</span>
        </div>
        ${progressBar}
      </div>`;
  }

  const phase = getPhaseFromZone(data.zone);
  const zoneColor = getZoneColor(data.zone);
  const zoneBg = getZoneBg(data.zone);
  const insight = getReadinessInsight(data.zone);

  // Delta: fatigue-adjusted today vs raw yesterday
  const yesterdayData = getACWR(allSessions, (() => { const d = new Date(); d.setDate(d.getDate() - 1); return d; })());
  const readinessDelta = yesterdayData.readinessScore !== null
    ? data.readinessScore - yesterdayData.readinessScore
    : 0;
  const rDeltaHTML = readinessDelta !== 0
    ? `<span class="score-delta" style="color: ${readinessDelta > 0 ? 'var(--zone-fresh)' : 'var(--zone-fatigued)'};">${readinessDelta > 0 ? '+' : ''}${readinessDelta}</span>`
    : '';

  return `
    <div class="pv3-card readiness-compact" style="background: linear-gradient(${zoneBg}, ${zoneBg}), var(--bg-card);">
      <div class="readiness-compact-header">
        <h3 class="pv3-card-title">${trV3('progress.readiness.title')}</h3>
        <button class="acwr-info-btn" onclick="openACWRInfoModal()" aria-label="Info">
          <span class="material-symbols-rounded">info</span>
        </button>
      </div>
      <div class="readiness-compact-body">
        <div class="readiness-compact-left">
          <span class="readiness-compact-label" style="color: ${zoneColor};">${phase.label}</span>
          <span class="readiness-compact-score">${data.readinessScore} ${rDeltaHTML}</span>
        </div>
        <div class="readiness-compact-bar-track">
          <div class="acwr-bar-fill" style="width: ${data.readinessScore}%; background: ${zoneColor};"></div>
        </div>
      </div>
      <div class="readiness-compact-insight">${insight}</div>
    </div>`;
}

function openACWRInfoModal() {
  if (typeof openGenericModal !== 'function') return;

  const zones = [
    { label: 'zoneOverreaching', info: 'infoZoneOverreaching', color: getZoneColor('overreaching') },
    { label: 'zoneFatigued', info: 'infoZoneFatigued', color: getZoneColor('fatigued') },
    { label: 'zoneMaintaining', info: 'infoZoneMaintaining', color: getZoneColor('maintaining') },
    { label: 'zoneBuilding', info: 'infoZoneBuilding', color: getZoneColor('building') },
    { label: 'zonePeak', info: 'infoZonePeak', color: getZoneColor('peak') }
  ];

  const zonesHTML = zones.map(z => `
    <div class="acwr-info-zone">
      <span class="acwr-info-dot" style="background:${z.color};"></span>
      <span><strong>${trV3('progress.readiness.' + z.label)}</strong> – ${trV3('progress.readiness.' + z.info)}</span>
    </div>
  `).join('');

  openGenericModal(
    trV3('progress.readiness.infoTitle'),
    `<div class="acwr-info-content">
      <p>${trV3('progress.readiness.infoBody')}</p>
      <div class="acwr-info-zones">${zonesHTML}</div>
    </div>`
  );
}

function initReadinessWidget() {
  // No-op – exists for modularity / future extensibility
}

// ==================== WEEKLY SCORE CHART ====================

function renderV4WeeklyScoreChartHTML() {
  if (typeof aggregateWeeklyScoresByPeriod !== 'function') return '';

  const data = aggregateWeeklyScoresByPeriod(pv4Period);
  const hasData = data && data.length > 0 && data.some(d => d.weeklyScore > 0);

  if (!hasData) {
    return `
      <div class="pv3-card weekly-score-chart-card">
        <div class="card-header">
          <h3 class="card-title">${trV3('progress.weeklyScore.chartTitle')}</h3>
        </div>
        <div class="pv3-empty-state">
          <span class="material-symbols-rounded">info</span>
          ${trV3('progress.weeklyScore.noData')}
        </div>
      </div>
    `;
  }

  return `
    <div class="pv3-card weekly-score-chart-card">
      <h3 class="card-title" style="margin-bottom: 0.75rem;">${trV3('progress.weeklyScore.chartTitle')}</h3>
      <div class="weekly-score-legend">
        <span class="legend-item">
          <span class="legend-dot" style="background: var(--color-primary);"></span>
          ${trV3('progress.weeklyScore.legend.score')}
        </span>
        <span class="legend-item">
          <span class="legend-dot" style="background: var(--text-tertiary);"></span>
          ${trV3('progress.weeklyScore.legend.baseline')}
        </span>
      </div>
      <div class="weekly-score-chart-wrapper">
        <canvas id="weekly-score-canvas"></canvas>
      </div>
    </div>
  `;
}

function getCssVarValue(varName) {
  return getComputedStyle(document.documentElement).getPropertyValue(varName).trim();
}

function initWeeklyScoreChart() {
  if (typeof Chart === 'undefined' || typeof aggregateWeeklyScoresByPeriod !== 'function') return;

  const canvas = document.getElementById('weekly-score-canvas');
  if (!canvas) return;

  // Destroy previous instance
  if (weeklyScoreChartInstance) {
    weeklyScoreChartInstance.destroy();
    weeklyScoreChartInstance = null;
  }

  const data = aggregateWeeklyScoresByPeriod(pv4Period);
  if (!data || !data.length || data.every(d => d.weeklyScore === 0)) return;

  const ctx = canvas.getContext('2d');

  // Theme-aware colors
  const primaryColor = getCssVarValue('--color-primary') || '#F02277';
  const textSecondary = getCssVarValue('--text-secondary') || '#9ca3af';
  const textTertiary = getCssVarValue('--text-tertiary') || '#6b7280';
  const borderPrimary = getCssVarValue('--border-primary') || 'rgba(255,255,255,0.1)';
  const isDark = document.documentElement.getAttribute('data-theme') !== 'light';
  const zoneOpacity = isDark ? 0.06 : 0.08;

  const labels = data.map(d => d.label);
  const scores = data.map(d => d.weeklyScore);
  const baselineScores = data.map(() => 70);

  weeklyScoreChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels,
      datasets: [
        {
          label: trV3('progress.weeklyScore.legend.score'),
          data: scores,
          borderColor: primaryColor,
          backgroundColor: primaryColor,
          borderWidth: 2.5,
          pointRadius: 6,
          pointHoverRadius: 9,
          pointBackgroundColor: primaryColor,
          pointBorderColor: isDark ? '#161618' : '#ffffff',
          pointBorderWidth: 2,
          pointHitRadius: 12,
          tension: 0.3,
          fill: false,
          order: 1,
        },
        {
          label: trV3('progress.weeklyScore.legend.baseline'),
          data: baselineScores,
          borderColor: textTertiary,
          backgroundColor: 'transparent',
          borderWidth: 1,
          borderDash: [4, 4],
          pointRadius: 0,
          pointHoverRadius: 0,
          tension: 0,
          fill: false,
          order: 2,
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      layout: {
        padding: { left: 6, right: 6, top: 6, bottom: 0 },
      },
      interaction: {
        mode: 'index',
        intersect: false,
      },
      scales: {
        y: {
          min: 0,
          max: 105,
          grid: { color: borderPrimary },
          ticks: {
            color: textSecondary,
            font: { size: 11 },
            stepSize: 25,
            callback: function(val) { return val <= 100 ? val : ''; },
          },
          border: { display: false },
        },
        x: {
          grid: { display: false },
          ticks: {
            color: textSecondary,
            font: { size: 10 },
            maxRotation: 0,
            autoSkip: true,
            maxTicksLimit: 6,
          },
          border: { display: false },
        }
      },
      plugins: {
        legend: { display: false },
        annotation: {
          annotations: {
            zoneLow: {
              type: 'box',
              yMin: 0,
              yMax: 50,
              backgroundColor: `rgba(245, 158, 11, ${zoneOpacity})`,
              borderWidth: 0,
            },
            zoneOptimal: {
              type: 'box',
              yMin: 50,
              yMax: 85,
              backgroundColor: `rgba(34, 197, 94, ${zoneOpacity})`,
              borderWidth: 0,
            },
            zoneHigh: {
              type: 'box',
              yMin: 85,
              yMax: 100,
              backgroundColor: `rgba(239, 68, 68, ${zoneOpacity})`,
              borderWidth: 0,
            },
          }
        },
        tooltip: {
          backgroundColor: isDark ? '#1c1c1e' : '#ffffff',
          titleColor: isDark ? '#ffffff' : '#1C1C1E',
          bodyColor: isDark ? '#d1d5db' : '#6b7280',
          borderColor: borderPrimary,
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
          displayColors: false,
          callbacks: {
            title: function(tooltipItems) {
              const idx = tooltipItems[0].dataIndex;
              return data[idx].label;
            },
            label: function(context) {
              if (context.datasetIndex !== 0) return null;
              const idx = context.dataIndex;
              const d = data[idx];
              return [
                `${trV3('progress.weeklyScore.tooltip.score')}: ${d.weeklyScore}`,
                `${trV3('progress.weeklyScore.tooltip.strength')}: ${Math.round(d.strengthLoad)}`,
                `${trV3('progress.weeklyScore.tooltip.cardio')}: ${Math.round(d.cardioLoad)}`,
                `${trV3('progress.weeklyScore.tooltip.baseline')}: ${Math.round(d.baseline)}`,
              ];
            },
          }
        }
      }
    }
  });
}

// ==================== ENDURANCE TRENDS CARD ====================

const ENDURANCE_SPORT_CONFIG = {
  run: {
    iconKey: 'directions_run',
    labelKey: 'progress.v4.overview.sportRun',
    slides: [
      { type: 'chart', key: 'distance', labelKey: 'progress.v4.overview.distancePerWeek', canvasId: 'endurance-distance-canvas' },
      { type: 'chart', key: 'pace', labelKey: 'progress.v4.overview.paceTrend', canvasId: 'endurance-pace-canvas' },
      { type: 'chart', key: 'duration', labelKey: 'progress.v4.overview.durationPerMonth', canvasId: 'endurance-duration-canvas' },
      { type: 'chart', key: 'sessions', labelKey: 'progress.v4.overview.sessionsPerMonth', canvasId: 'endurance-sessions-canvas' },
    ]
  },
  bike: {
    iconKey: 'directions_bike',
    labelKey: 'progress.v4.overview.sportBike',
    slides: [
      { type: 'chart', key: 'distance', labelKey: 'progress.v4.overview.distancePerWeek', canvasId: 'endurance-distance-canvas' },
      { type: 'chart', key: 'speed', labelKey: 'progress.v4.overview.speedTrend', canvasId: 'endurance-pace-canvas' },
      { type: 'chart', key: 'duration', labelKey: 'progress.v4.overview.durationPerMonth', canvasId: 'endurance-duration-canvas' },
      { type: 'chart', key: 'sessions', labelKey: 'progress.v4.overview.sessionsPerMonth', canvasId: 'endurance-sessions-canvas' },
    ]
  },
  swim: {
    iconKey: 'pool',
    labelKey: 'progress.v4.overview.sportSwim',
    slides: [
      { type: 'chart', key: 'distance', labelKey: 'progress.v4.overview.distancePerWeek', canvasId: 'endurance-distance-canvas' },
      { type: 'chart', key: 'pace', labelKey: 'progress.v4.overview.swimPace', canvasId: 'endurance-pace-canvas' },
      { type: 'chart', key: 'duration', labelKey: 'progress.v4.overview.durationPerMonth', canvasId: 'endurance-duration-canvas' },
      { type: 'chart', key: 'sessions', labelKey: 'progress.v4.overview.sessionsPerMonth', canvasId: 'endurance-sessions-canvas' },
    ]
  },
};

const SPORT_COLOR_VARS = { run: '--sport-run', bike: '--sport-bike', swim: '--sport-swim' };

function getSportColor(sport) {
  return getCssVarValue(SPORT_COLOR_VARS[sport] || SPORT_COLOR_VARS.run) || '#1e3a8a';
}

function renderEnduranceCard(sessions) {
  if (typeof getAvailableEnduranceSports !== 'function') return '';

  const allSports = ['run', 'bike', 'swim'];
  const availableSports = getAvailableEnduranceSports(pv4Period);

  // Keep selected sport even if it has no data (skeleton will show)
  if (!allSports.includes(pv4EnduranceSport)) {
    pv4EnduranceSport = 'run';
  }

  const sportCfg = ENDURANCE_SPORT_CONFIG[pv4EnduranceSport] || ENDURANCE_SPORT_CONFIG.run;
  const sportColor = getSportColor(pv4EnduranceSport);
  const activeIdx = allSports.indexOf(pv4EnduranceSport);
  const hasData = availableSports.includes(pv4EnduranceSport);

  // --- Sport segmented toggle ---
  const toggleHTML = `
    <div class="endurance-sport-toggle" style="--active-idx:${activeIdx};--endurance-sport-color:${sportColor}">
      <div class="endurance-seg-indicator"></div>
      ${allSports.map(sport => {
        const cfg = ENDURANCE_SPORT_CONFIG[sport];
        const active = sport === pv4EnduranceSport ? ' active' : '';
        return `<button class="endurance-seg-btn${active}" data-sport="${sport}">
          <span class="material-symbols-rounded">${cfg.iconKey}</span>
          ${trV3(cfg.labelKey)}
        </button>`;
      }).join('')}
    </div>`;

  // --- Content: slides (charts + stats) OR skeleton ---
  let contentHTML;

  if (hasData) {
    const sportSessions = sessions.filter(s => {
      const type = (s.activityType || '').toLowerCase();
      const norm = ({ running: 'run', laufen: 'run', cycling: 'bike', radfahren: 'bike', swimming: 'swim', schwimmen: 'swim' })[type] || type;
      return norm === pv4EnduranceSport;
    });

    const totalTime = sportSessions.reduce((sum, s) => sum + v3GetDurationMin(s), 0);
    const totalDist = sportSessions.reduce((sum, s) => sum + (Number(s.distanceKm) || 0), 0);
    const sessionCount = sportSessions.length;

    // Compute sport-specific stat values
    const statValues = computeEnduranceStats(pv4EnduranceSport, totalDist, totalTime, sessionCount);

    // Build slides — charts and stats all inside the slider
    const slidesHTML = sportCfg.slides.map(slide => {
      if (slide.type === 'chart') {
        return `<div class="endurance-stat-slide endurance-chart-slide">
          <h4 class="run-chart-subtitle">${trV3(slide.labelKey)}</h4>
          <div class="run-chart-wrapper">
            <canvas id="${slide.canvasId}"></canvas>
          </div>
        </div>`;
      }
      const val = statValues[slide.key];
      const displayVal = val !== null && val !== undefined ? val : '-';
      return `<div class="endurance-stat-slide">
        <div class="endurance-stat-value">${displayVal}</div>
        <div class="endurance-stat-label">${trV3(slide.labelKey)}${slide.unit ? ' (' + slide.unit + ')' : ''}</div>
      </div>`;
    }).join('');

    const dotsHTML = sportCfg.slides.map((_, i) =>
      `<div class="endurance-stat-dot${i === 0 ? ' active' : ''}"></div>`
    ).join('');

    contentHTML = `
      <div class="endurance-stat-slider" style="--endurance-sport-color:${sportColor}">
        <div class="endurance-stat-track">${slidesHTML}</div>
      </div>
      <div class="endurance-stat-dots">${dotsHTML}</div>`;
  } else {
    // Skeleton state for sports with no data
    const sportLabel = trV3(sportCfg.labelKey);
    contentHTML = `
      <div class="endurance-skeleton">
        <p class="endurance-skeleton-hint">
          <span class="material-symbols-rounded" style="font-size:20px;display:block;margin-bottom:0.5rem">info</span>
          ${trV3('progress.v4.overview.noDataHint', { sport: sportLabel })}
        </p>
      </div>`;
  }

  return `
    <div class="pv3-card endurance-card" style="--endurance-sport-color:${sportColor}">
      <div class="pv3-card-header">
        <h3 class="pv3-card-title">
          <span class="material-symbols-rounded" style="font-size:18px;vertical-align:middle;margin-right:4px;color:${sportColor}">${sportCfg.iconKey}</span>
          ${trV3('progress.v4.overview.enduranceTrends')}
        </h3>
      </div>
      ${toggleHTML}
      ${contentHTML}
    </div>`;
}

function computeEnduranceStats(sport, totalDist, totalTime, sessionCount) {
  function fmtPace(p) {
    if (!p || p <= 0) return '-';
    const m = Math.floor(p);
    let sec = Math.round((p - m) * 60);
    if (sec >= 60) return `${m + 1}:00`;
    return `${m}:${String(sec).padStart(2, '0')}`;
  }

  const stats = {};

  // Distance
  if (sport === 'swim') {
    stats.distance = totalDist > 0 ? Math.round(totalDist * 1000) : '-';
  } else {
    stats.distance = totalDist > 0 ? totalDist.toFixed(1) : '-';
  }

  // Pace / Speed
  if (sport === 'run') {
    const pace = totalDist > 0 ? totalTime / totalDist : null;
    stats.pace = pace ? fmtPace(pace) : '-';
  } else if (sport === 'bike') {
    const speed = totalTime > 0 ? (totalDist / (totalTime / 60)) : null;
    stats.speed = speed ? speed.toFixed(1) : '-';
  } else if (sport === 'swim') {
    // min per 100m: totalTime / (totalDist * 10)
    const swimPace = totalDist > 0 ? totalTime / (totalDist * 10) : null;
    stats.pace = swimPace ? fmtPace(swimPace) : '-';
  }

  // Duration
  stats.duration = totalTime > 0 ? totalTime : '-';

  // Sessions
  stats.sessions = sessionCount;

  return stats;
}

function initEnduranceCharts() {
  if (typeof Chart === 'undefined' || typeof aggregateCardioByPeriod !== 'function') return;

  // Skip chart init when skeleton is showing (no canvas in DOM)
  if (!document.getElementById('endurance-distance-canvas')) return;

  const distData = aggregateCardioByPeriod('distance', pv4Period, pv4EnduranceSport);
  const paceData = aggregateCardioByPeriod('pace', pv4Period, pv4EnduranceSport);

  if (!distData || !distData.length) return;

  initEnduranceDistanceChart(distData);
  initEndurancePaceChart(paceData);

  // Duration & Sessions charts — aggregated by month
  if (document.getElementById('endurance-duration-canvas') || document.getElementById('endurance-sessions-canvas')) {
    const monthlyData = aggregateToMonthlyBuckets(distData);
    if (monthlyData.length) {
      if (document.getElementById('endurance-duration-canvas')) {
        initEnduranceDurationChart(monthlyData);
      }
      if (document.getElementById('endurance-sessions-canvas')) {
        initEnduranceSessionsChart(monthlyData);
      }
    }
  }
}

function aggregateToMonthlyBuckets(buckets) {
  const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  const map = new Map();

  buckets.forEach(b => {
    if (!b.date) return;
    const d = b.date instanceof Date ? b.date : new Date(b.date);
    const key = `${d.getFullYear()}-${d.getMonth()}`;
    if (!map.has(key)) {
      map.set(key, {
        label: `${months[d.getMonth()]} ${d.getFullYear()}`,
        date: new Date(d.getFullYear(), d.getMonth(), 1),
        totalDuration: 0,
        totalDistance: 0,
        sessionCount: 0,
      });
    }
    const m = map.get(key);
    m.totalDuration += (b.totalDuration || 0);
    m.totalDistance += (b.totalDistance || 0);
    m.sessionCount += (b.sessionCount || 0);
  });

  return Array.from(map.values()).sort((a, b) => a.date - b.date);
}

function initEnduranceDistanceChart(data) {
  const canvas = document.getElementById('endurance-distance-canvas');
  if (!canvas) return;

  if (enduranceDistanceChartInstance) {
    enduranceDistanceChartInstance.destroy();
    enduranceDistanceChartInstance = null;
  }

  const ctx = canvas.getContext('2d');
  const sportColor = getSportColor(pv4EnduranceSport);
  const textSecondary = getCssVarValue('--text-secondary') || '#9ca3af';
  const borderPrimary = getCssVarValue('--border-primary') || 'rgba(255,255,255,0.1)';
  const isDark = document.documentElement.getAttribute('data-theme') !== 'light';

  enduranceDistanceChartInstance = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: data.map(d => d.label),
      datasets: [{
        label: trV3('progress.v4.overview.totalDistance'),
        data: data.map(d => d.value),
        backgroundColor: sportColor,
        borderRadius: 4,
        maxBarThickness: 24,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      layout: {
        padding: { left: 6, right: 6, top: 6, bottom: 0 },
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: { color: borderPrimary },
          ticks: {
            color: textSecondary,
            font: { size: 11 },
            callback: function(val) { return val + ' km'; },
          },
          border: { display: false },
        },
        x: {
          grid: { display: false },
          ticks: {
            color: textSecondary,
            font: { size: 10 },
            maxRotation: 0,
            autoSkip: true,
            maxTicksLimit: 8,
          },
          border: { display: false },
        }
      },
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: isDark ? '#1c1c1e' : '#ffffff',
          titleColor: isDark ? '#ffffff' : '#1C1C1E',
          bodyColor: isDark ? '#d1d5db' : '#6b7280',
          borderColor: borderPrimary,
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
          displayColors: false,
          callbacks: {
            label: function(context) {
              const d = data[context.dataIndex];
              const lines = [`${trV3('progress.v4.overview.totalDistance')}: ${d.value} km`];
              lines.push(`${trV3('progress.v4.overview.sessions')}: ${d.sessionCount}`);
              if (d.totalDuration > 0) lines.push(`${trV3('progress.v4.overview.totalTime')}: ${Math.round(d.totalDuration)} min`);
              return lines;
            },
          }
        }
      }
    }
  });
}

function initEndurancePaceChart(data) {
  const canvas = document.getElementById('endurance-pace-canvas');
  if (!canvas) return;

  if (endurancePaceChartInstance) {
    endurancePaceChartInstance.destroy();
    endurancePaceChartInstance = null;
  }

  // Filter out buckets with no pace data
  const paceData = data.filter(d => d.value > 0);
  if (paceData.length < 1) {
    return;
  }

  const ctx = canvas.getContext('2d');
  const sportColor = getSportColor(pv4EnduranceSport);
  const textSecondary = getCssVarValue('--text-secondary') || '#9ca3af';
  const borderPrimary = getCssVarValue('--border-primary') || 'rgba(255,255,255,0.1)';
  const isDark = document.documentElement.getAttribute('data-theme') !== 'light';

  // Sport-specific pace/speed configuration
  // Raw data is always min/km from aggregateCardioByPeriod
  const isBike = pv4EnduranceSport === 'bike';
  const isSwim = pv4EnduranceSport === 'swim';

  const transformValue = (minPerKm) => {
    if (!minPerKm || minPerKm <= 0) return 0;
    if (isBike) return 60 / minPerKm;    // km/h
    if (isSwim) return minPerKm / 10;     // min/100m
    return minPerKm;                       // min/km (run)
  };

  const reverseY = !isBike; // Bike: higher = faster (normal), Run/Swim: lower = faster (reversed)
  const unitStr = isBike ? 'km/h' : (isSwim ? 'min/100m' : 'min/km');
  const labelKey = isBike ? 'progress.v4.overview.avgSpeed' : 'progress.v4.overview.avgPace';

  const fmtPace = (p) => {
    if (!p || p <= 0) return '-';
    const m = Math.floor(p);
    let sec = Math.round((p - m) * 60);
    if (sec >= 60) return `${m + 1}:00`;
    return `${m}:${String(sec).padStart(2, '0')}`;
  };

  const fmtValue = (val) => {
    if (isBike) return val > 0 ? val.toFixed(1) : '-';
    return fmtPace(val);
  };

  const fmtTickValue = (val) => {
    if (isBike) return val.toFixed(1) + ' km/h';
    return fmtPace(val);
  };

  endurancePaceChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: paceData.map(d => d.label),
      datasets: [{
        label: trV3(labelKey),
        data: paceData.map(d => transformValue(d.value)),
        borderColor: sportColor,
        backgroundColor: sportColor,
        borderWidth: 2.5,
        pointRadius: 6,
        pointHoverRadius: 9,
        pointBackgroundColor: sportColor,
        pointBorderColor: isDark ? '#161618' : '#ffffff',
        pointBorderWidth: 2,
        pointHitRadius: 12,
        tension: 0.3,
        fill: false,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      layout: {
        padding: { left: 6, right: 6, top: 6, bottom: 0 },
      },
      scales: {
        y: {
          reverse: reverseY,
          grid: { color: borderPrimary },
          ticks: {
            color: textSecondary,
            font: { size: 11 },
            callback: function(val) { return fmtTickValue(val); },
          },
          border: { display: false },
        },
        x: {
          grid: { display: false },
          ticks: {
            color: textSecondary,
            font: { size: 10 },
            maxRotation: 0,
            autoSkip: true,
            maxTicksLimit: 8,
          },
          border: { display: false },
        }
      },
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: isDark ? '#1c1c1e' : '#ffffff',
          titleColor: isDark ? '#ffffff' : '#1C1C1E',
          bodyColor: isDark ? '#d1d5db' : '#6b7280',
          borderColor: borderPrimary,
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
          displayColors: false,
          callbacks: {
            label: function(context) {
              const d = paceData[context.dataIndex];
              const displayVal = fmtValue(transformValue(d.value));
              return [
                `${trV3(labelKey)}: ${displayVal} ${unitStr}`,
                `${trV3('progress.v4.overview.totalDistance')}: ${d.totalDistance.toFixed(1)} km`,
                `${trV3('progress.v4.overview.sessions')}: ${d.sessionCount}`,
              ];
            },
          }
        }
      }
    }
  });
}

function initEnduranceDurationChart(data) {
  const canvas = document.getElementById('endurance-duration-canvas');
  if (!canvas) return;

  if (enduranceDurationChartInstance) {
    enduranceDurationChartInstance.destroy();
    enduranceDurationChartInstance = null;
  }

  const ctx = canvas.getContext('2d');
  const sportColor = getSportColor(pv4EnduranceSport);
  const textSecondary = getCssVarValue('--text-secondary') || '#9ca3af';
  const borderPrimary = getCssVarValue('--border-primary') || 'rgba(255,255,255,0.1)';
  const isDark = document.documentElement.getAttribute('data-theme') !== 'light';

  enduranceDurationChartInstance = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: data.map(d => d.label),
      datasets: [{
        label: trV3('progress.v4.overview.totalTime'),
        data: data.map(d => Math.round(d.totalDuration)),
        backgroundColor: sportColor,
        borderRadius: 4,
        maxBarThickness: 32,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      layout: {
        padding: { left: 6, right: 6, top: 6, bottom: 0 },
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: { color: borderPrimary },
          ticks: {
            color: textSecondary,
            font: { size: 11 },
            callback: function(val) { return val + ' min'; },
          },
          border: { display: false },
        },
        x: {
          grid: { display: false },
          ticks: {
            color: textSecondary,
            font: { size: 10 },
            maxRotation: 0,
            autoSkip: true,
            maxTicksLimit: 6,
          },
          border: { display: false },
        }
      },
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: isDark ? '#1c1c1e' : '#ffffff',
          titleColor: isDark ? '#ffffff' : '#1C1C1E',
          bodyColor: isDark ? '#d1d5db' : '#6b7280',
          borderColor: borderPrimary,
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
          displayColors: false,
          callbacks: {
            label: function(context) {
              const d = data[context.dataIndex];
              return [
                `${trV3('progress.v4.overview.totalTime')}: ${Math.round(d.totalDuration)} min`,
                `${trV3('progress.v4.overview.sessions')}: ${d.sessionCount}`,
              ];
            },
          }
        }
      }
    }
  });
}

function initEnduranceSessionsChart(data) {
  const canvas = document.getElementById('endurance-sessions-canvas');
  if (!canvas) return;

  if (enduranceSessionsChartInstance) {
    enduranceSessionsChartInstance.destroy();
    enduranceSessionsChartInstance = null;
  }

  const ctx = canvas.getContext('2d');
  const sportColor = getSportColor(pv4EnduranceSport);
  const textSecondary = getCssVarValue('--text-secondary') || '#9ca3af';
  const borderPrimary = getCssVarValue('--border-primary') || 'rgba(255,255,255,0.1)';
  const isDark = document.documentElement.getAttribute('data-theme') !== 'light';

  enduranceSessionsChartInstance = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: data.map(d => d.label),
      datasets: [{
        label: trV3('progress.v4.overview.sessions'),
        data: data.map(d => d.sessionCount),
        backgroundColor: sportColor,
        borderRadius: 4,
        maxBarThickness: 32,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      layout: {
        padding: { left: 6, right: 6, top: 6, bottom: 0 },
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: { color: borderPrimary },
          ticks: {
            color: textSecondary,
            font: { size: 11 },
            stepSize: 1,
            precision: 0,
          },
          border: { display: false },
        },
        x: {
          grid: { display: false },
          ticks: {
            color: textSecondary,
            font: { size: 10 },
            maxRotation: 0,
            autoSkip: true,
            maxTicksLimit: 6,
          },
          border: { display: false },
        }
      },
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: isDark ? '#1c1c1e' : '#ffffff',
          titleColor: isDark ? '#ffffff' : '#1C1C1E',
          bodyColor: isDark ? '#d1d5db' : '#6b7280',
          borderColor: borderPrimary,
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
          displayColors: false,
          callbacks: {
            label: function(context) {
              const d = data[context.dataIndex];
              return [
                `${trV3('progress.v4.overview.sessions')}: ${d.sessionCount}`,
                `${trV3('progress.v4.overview.totalTime')}: ${Math.round(d.totalDuration)} min`,
              ];
            },
          }
        }
      }
    }
  });
}

function attachEnduranceSportListeners() {
  const toggle = document.querySelector('.endurance-sport-toggle');
  if (!toggle) return;

  const allSports = ['run', 'bike', 'swim'];

  toggle.querySelectorAll('.endurance-seg-btn').forEach((btn, idx) => {
    btn.addEventListener('click', () => {
      const sport = btn.dataset.sport;
      if (sport === pv4EnduranceSport) return;
      pv4EnduranceSport = sport;
      localStorage.setItem('enduranceSportKey', sport);

      // Animate indicator
      const sportColor = getSportColor(sport);
      toggle.style.setProperty('--active-idx', idx);
      toggle.style.setProperty('--endurance-sport-color', sportColor);
      toggle.querySelectorAll('.endurance-seg-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      setTimeout(() => renderProgressV4(), 220);
    });
  });

  // Transform-based slider with swipe support and clickable dots
  const slider = document.querySelector('.endurance-stat-slider');
  const track = slider?.querySelector('.endurance-stat-track');
  const dots = document.querySelectorAll('.endurance-stat-dot');
  const slideCount = track?.children.length || 0;

  if (slider && track && slideCount > 0) {
    let currentSlide = 0;

    const goToSlide = (idx) => {
      currentSlide = Math.max(0, Math.min(idx, slideCount - 1));
      track.style.transform = `translateX(-${currentSlide * 100}%)`;
      dots.forEach((dot, i) => dot.classList.toggle('active', i === currentSlide));
    };

    // Clickable dots
    dots.forEach((dot, i) => {
      dot.addEventListener('click', () => goToSlide(i));
    });

    // Swipe detection
    let touchStartX = 0;
    let touchStartY = 0;

    slider.addEventListener('touchstart', (e) => {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
    }, { passive: true });

    slider.addEventListener('touchend', (e) => {
      const dx = e.changedTouches[0].clientX - touchStartX;
      const dy = e.changedTouches[0].clientY - touchStartY;
      // Only swipe if horizontal movement > 40px and dominant over vertical
      if (Math.abs(dx) > 40 && Math.abs(dx) > Math.abs(dy)) {
        if (dx < 0) goToSlide(currentSlide + 1);
        else goToSlide(currentSlide - 1);
      }
    }, { passive: true });
  }
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
        <div class="pv3-empty-state">
          <span class="material-symbols-rounded">info</span>
          ${trV3('progress.v3.rhythm.noData')}
        </div>
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

  const typeTotals = {};
  V3_KNOWN_TYPES.forEach(t => {
    typeTotals[t] = buckets.reduce((sum, b) => sum + b.data[t], 0);
  });

  const legendHtml = V3_KNOWN_TYPES
    .filter(t => buckets.some(b => b.data[t] > 0))
    .map(t => {
      const mins = typeTotals[t];
      const timeStr = mins >= 60
        ? `${Math.floor(mins / 60)}h ${mins % 60}min`
        : `${mins} min`;
      return `<span class="pv3-legend-item"><span class="pv3-legend-dot" style="background:${V3_TYPE_COLORS[t]}"></span>${trV3('progress.v3.types.' + t)}<span class="pv3-legend-time">${timeStr}</span></span>`;
    })
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

// ==================== SESSION HISTORY (COLLAPSIBLE) ====================

const PV4_HISTORY_COLLAPSED_LIMIT = 5;

function renderV4SessionHistory(sessions) {
  if (sessions.length === 0) {
    return `<div class="pv3-empty-state"><span class="material-symbols-rounded">info</span>${trV3('progress.v4.overview.noSessions')}</div>`;
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

function renderV4ExerciseFilterBar() {
  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
  const muscleKeys = ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'core', 'legs', 'full-body'];
  const names = typeof getMuscleNames === 'function' ? getMuscleNames() : {};

  const chips = muscleKeys.map(key => {
    const active = pv4ExerciseMuscleFilter === key ? ' active' : '';
    const icon = typeof getMuscleIcon === 'function' ? getMuscleIcon(key, 'muscle-icon--xs') : '';
    return `<button class="pv4-muscle-chip${active}" data-muscle="${key}" onclick="setPv4MuscleFilter('${key}')">${icon}<span>${names[key] || key}</span></button>`;
  }).join('');

  const allActive = !pv4ExerciseMuscleFilter ? ' active' : '';
  const clearVal = pv4ExerciseSearchTerm ? '' : ' hidden';

  return `
    <div class="pv4-exercise-filter-bar">
      <div class="exercise-search-bar">
        <span class="material-symbols-rounded exercise-search-icon">search</span>
        <input type="text" id="pv4-exercise-search" class="exercise-search-input"
               placeholder="${trV3('progress.v4.exercises.searchPlaceholder') || 'Übung suchen...'}"
               value="${pv4ExerciseSearchTerm}"
               oninput="onPv4ExerciseSearchInput()" />
        <button id="pv4-exercise-search-clear" class="exercise-search-clear${clearVal}" onclick="clearPv4ExerciseSearch()">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
      <div class="pv4-muscle-filter-chips">
        <button class="pv4-muscle-chip${allActive}" data-muscle="" onclick="setPv4MuscleFilter('')">
          <span>${trV3('progress.v4.exercises.allMuscles') || 'All'}</span>
        </button>
        ${chips}
      </div>
    </div>`;
}

function _computeLoadContributionMap() {
  const now = new Date();
  const weekAgo = new Date(now);
  weekAgo.setDate(weekAgo.getDate() - 6);
  weekAgo.setHours(0, 0, 0, 0);

  const weeklyLoad = typeof computeWeeklyRawLoad === 'function' ? computeWeeklyRawLoad(now) : null;
  if (!weeklyLoad || weeklyLoad.rawLoad <= 0) return {};

  const loadMap = {};
  allSessions.forEach(s => {
    if (s.type !== 'strength' || !s.exercises) return;
    const d = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    if (d < weekAgo || d > now) return;
    const totalVol = s.exercises.reduce((sum, e) => {
      return sum + (typeof calculateExerciseWeightedVolume === 'function' ? calculateExerciseWeightedVolume(e) : 0);
    }, 0);
    if (totalVol <= 0) return;
    const sessionLoad = typeof calculateSessionLoadValue === 'function' ? calculateSessionLoadValue(s).rawLoad : 0;
    s.exercises.forEach(e => {
      const exVol = typeof calculateExerciseWeightedVolume === 'function' ? calculateExerciseWeightedVolume(e) : 0;
      if (exVol <= 0) return;
      if (!loadMap[e.exerciseId]) loadMap[e.exerciseId] = 0;
      loadMap[e.exerciseId] += (exVol / totalVol) * sessionLoad;
    });
  });

  const result = {};
  Object.keys(loadMap).forEach(id => {
    const pct = Math.round((loadMap[id] / weeklyLoad.rawLoad) * 100);
    if (pct > 0) result[id] = pct;
  });
  return result;
}

function renderV4ExerciseTrends() {
  const exerciseMap = {};
  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
  const loadContributionMap = _computeLoadContributionMap();

  allSessions.forEach(session => {
    if (!session.exercises) return;
    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    session.exercises.forEach(ex => {
      if (!exerciseMap[ex.exerciseId]) {
        const data = exercises.find(e => e.id === ex.exerciseId);
        exerciseMap[ex.exerciseId] = {
          exerciseId: ex.exerciseId,
          name: data?.name || ex.exerciseId,
          muscleGroups: data?.muscleGroups || [],
          sessionCount: 0,
          sparklineData: [],
          trend: null,
          lastSessionSets: [],
          lastSessionDate: null,
          bestSet: 0,
          loadPct: loadContributionMap[ex.exerciseId] || null
        };
      }
      const entry = exerciseMap[ex.exerciseId];
      entry.sessionCount++;

      // Track most recent session's sets
      if (!entry.lastSessionDate || sessionDate > entry.lastSessionDate) {
        entry.lastSessionDate = sessionDate;
        entry.lastSessionSets = (ex.sets || []).map(s => s.reps || 0);
      }

      // Track best single-set reps
      const exBest = typeof calculateBestSet === 'function' ? calculateBestSet(ex) : 0;
      if (exBest > entry.bestSet) entry.bestSet = exBest;
    });
  });

  Object.values(exerciseMap).forEach(entry => {
    entry.sparklineData = typeof getExerciseGlobalSparkline === 'function'
      ? getExerciseGlobalSparkline(entry.exerciseId, 12) : [];
    if (entry.sparklineData.length >= 2) {
      const last = entry.sparklineData[entry.sparklineData.length - 1];
      const prev = entry.sparklineData[entry.sparklineData.length - 2];
      entry.trend = last > prev ? 'up' : last < prev ? 'down' : 'same';
    }
  });

  let filtered = Object.values(exerciseMap);

  // Apply search filter
  if (pv4ExerciseSearchTerm) {
    const searchLower = pv4ExerciseSearchTerm.toLocaleLowerCase('de-DE');
    filtered = filtered.filter(ex => ex.name.toLocaleLowerCase('de-DE').includes(searchLower));
  }

  // Apply muscle group filter
  if (pv4ExerciseMuscleFilter) {
    filtered = filtered.filter(ex => ex.muscleGroups.includes(pv4ExerciseMuscleFilter));
  }

  // Sort by session count, limit to top 20
  filtered.sort((a, b) => b.sessionCount - a.sessionCount);
  filtered = filtered.slice(0, 20);

  const filterBar = renderV4ExerciseFilterBar();

  if (Object.keys(exerciseMap).length === 0) {
    return `${filterBar}<div class="pv3-empty-state"><span class="material-symbols-rounded">info</span>${trV3('progress.v4.exercises.noExercises')}</div>`;
  }

  if (filtered.length === 0) {
    return `${filterBar}<div class="pv3-empty-state"><span class="material-symbols-rounded">search_off</span>${trV3('progress.v4.exercises.noFilterResults') || 'Keine Übungen gefunden'}</div>`;
  }

  const cards = filtered.map(ex => {
    const trendClass = ex.trend || 'same';
    const trendArrow = ex.trend === 'up' ? '↑' : ex.trend === 'down' ? '↓' : '→';
    const _t = (k, fb) => { const v = trV3(k); return v !== k ? v : fb; };
    const trendLabel = ex.trend === 'up' ? _t('progress.v4.exercises.trendUp', 'Improving')
      : ex.trend === 'down' ? _t('progress.v4.exercises.trendDown', 'Declining')
      : _t('progress.v4.exercises.trendSame', 'Stable');
    const hasSparkline = ex.sparklineData.length >= 2;
    const sparkId = `pv4-spark-${ex.exerciseId.replace(/[^a-zA-Z0-9]/g, '_')}`;

    const lastPerf = ex.lastSessionSets.length > 0 ? ex.lastSessionSets.join(' / ') : '-';
    const bestPerf = ex.bestSet > 0 ? `${ex.bestSet} reps` : '-';
    const loadMeta = ex.loadPct != null && ex.loadPct > 0
      ? `<div class="exercise-meta-load">~${ex.loadPct}% ${_t('progress.v4.exercises.loadContribution', 'deiner Wochenlast')}</div>`
      : '';

    return `
      <button class="pv4-exercise-card" data-exercise-id="${ex.exerciseId}">
        <div class="exercise-header">
          <span class="exercise-title">${ex.name}</span>
          <span class="exercise-trend-badge ${trendClass}">${trendArrow} ${trendLabel}</span>
        </div>
        <div class="exercise-stats">
          <div class="exercise-stat">
            <span class="exercise-stat-label">${_t('progress.v4.exercises.lastPerf', 'Letztes')}</span>
            <span class="exercise-stat-value">${lastPerf}</span>
          </div>
          <div class="exercise-stat">
            <span class="exercise-stat-label">${_t('progress.v4.exercises.bestPerf', 'Best')}</span>
            <span class="exercise-stat-value">${bestPerf}</span>
          </div>
          <div class="exercise-stat">
            <span class="exercise-stat-label">Sessions</span>
            <span class="exercise-stat-value">${ex.sessionCount}</span>
          </div>
        </div>
        ${hasSparkline
          ? `<div class="exercise-chart"><canvas id="${sparkId}"></canvas></div>`
          : `<div class="exercise-empty-state">${_t('progress.v4.exercises.emptyState', 'Starte mit dem Loggen, um Trends zu sehen.')}</div>`}
        ${loadMeta}
      </button>`;
  }).join('');

  return `${filterBar}<div class="pv4-exercise-grid">${cards}</div>`;
}

// Exercise filter & favorites event handlers
function onPv4ExerciseSearchInput() {
  const input = document.getElementById('pv4-exercise-search');
  const clearBtn = document.getElementById('pv4-exercise-search-clear');
  if (clearBtn) clearBtn.classList.toggle('hidden', !input?.value);

  clearTimeout(_pv4ExerciseSearchTimer);
  _pv4ExerciseSearchTimer = setTimeout(() => {
    pv4ExerciseSearchTerm = input ? input.value.trim() : '';
    rerenderV4ExerciseTab();
  }, 180);
}

function clearPv4ExerciseSearch() {
  pv4ExerciseSearchTerm = '';
  rerenderV4ExerciseTab();
}

function setPv4MuscleFilter(value) {
  pv4ExerciseMuscleFilter = (pv4ExerciseMuscleFilter === value) ? '' : value;
  rerenderV4ExerciseTab();
}

function rerenderV4ExerciseTab() {
  const savedSearch = pv4ExerciseSearchTerm;
  const savedMuscle = pv4ExerciseMuscleFilter;
  renderProgressV4();
  requestAnimationFrame(() => {
    const input = document.getElementById('pv4-exercise-search');
    if (input) {
      input.value = savedSearch;
      if (savedSearch) input.focus();
    }
    const clearBtn = document.getElementById('pv4-exercise-search-clear');
    if (clearBtn) clearBtn.classList.toggle('hidden', !savedSearch);
    drawAllV4Sparklines();
  });
}

// Expose to global scope for onclick handlers
window.onPv4ExerciseSearchInput = onPv4ExerciseSearchInput;
window.clearPv4ExerciseSearch = clearPv4ExerciseSearch;
window.setPv4MuscleFilter = setPv4MuscleFilter;

let _sparklineObserver = null;

function _drawSparklineForCanvas(canvas) {
  const id = canvas.id;
  if (!id || canvas.dataset.drawn) return;
  const exId = id.replace('pv4-spark-', '').replace(/_/g, '-');
  const sparkData = typeof getExerciseGlobalSparkline === 'function'
    ? getExerciseGlobalSparkline(exId, 12) : [];
  if (sparkData.length < 2) return;
  const last = sparkData[sparkData.length - 1];
  const prev = sparkData[sparkData.length - 2];
  const trend = last > prev ? 'up' : last < prev ? 'down' : 'same';
  const color = trend === 'up' ? '#22c55e' : trend === 'down' ? '#ef4444' : '#9ca3af';
  if (typeof drawMiniSparkline === 'function') {
    drawMiniSparkline(id, sparkData, color, { smooth: true, fill: true, lineWidth: 2 });
  }
  canvas.dataset.drawn = '1';
}

function drawAllV4Sparklines() {
  // Clean up previous observer
  if (_sparklineObserver) _sparklineObserver.disconnect();

  // Lazy render sparklines via IntersectionObserver
  const canvases = document.querySelectorAll('.exercise-chart canvas');
  if ('IntersectionObserver' in window && canvases.length > 0) {
    _sparklineObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) _drawSparklineForCanvas(entry.target);
      });
    }, { rootMargin: '100px' });
    canvases.forEach(canvas => _sparklineObserver.observe(canvas));
  } else {
    canvases.forEach(canvas => _drawSparklineForCanvas(canvas));
  }

  // Attach click listeners for exercise cards
  document.querySelectorAll('.pv4-exercise-card').forEach(row => {
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
      setReps: (ex.sets || []).map(s => s.reps || 0),
      planName: s.planName || ''
    };
  });

  // Stats
  const volumes = chartData.map(d => d.volume);
  const pr = volumes.length > 0 ? Math.max(...volumes) : 0;
  const avg = volumes.length > 0 ? Math.round(volumes.reduce((a, b) => a + b, 0) / volumes.length) : 0;
  const lastEntry = chartData.length > 0 ? chartData[chartData.length - 1] : null;

  // History (newest first)
  const historyRows = [...chartData].reverse().slice(0, 20).map(d => {
    const repsStr = d.setReps.length > 0 ? d.setReps.join(' / ') : '';
    return `
    <div class="pv4-session-row">
      <div class="pv4-session-info">
        <div class="pv4-session-name">${d.sets} ${trV3('progress.v4.exercises.detail.sets')} \u00B7 ${repsStr}${repsStr ? ` \u00B7 ` : ''}${trV3('progress.v4.exercises.detail.volume')}: ${d.volume}</div>
        <div class="pv4-session-meta">${v3FormatDate(d.date)}${d.planName ? ` \u00B7 ${d.planName}` : ''}</div>
      </div>
    </div>`;
  }).join('');

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

  const points = values.map((v, i) => ({
    x: padL + (i / (values.length - 1)) * chartW,
    y: padT + (1 - (v - min) / range) * chartH
  }));

  // Smooth curve with monotone cubic interpolation
  ctx.beginPath();
  ctx.strokeStyle = lineColor;
  ctx.lineWidth = 2;
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';

  if (points.length >= 3 && typeof _monotoneTangents === 'function') {
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
  ctx.lineTo(points[points.length - 1].x, padT + chartH);
  ctx.lineTo(points[0].x, padT + chartH);
  ctx.closePath();
  const grad = ctx.createLinearGradient(0, padT, 0, padT + chartH);
  grad.addColorStop(0, lineColor + '33');
  grad.addColorStop(1, lineColor + '00');
  ctx.fillStyle = grad;
  ctx.fill();

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
    return `<div class="pv3-empty-state"><span class="material-symbols-rounded">info</span>${trV3('progress.v4.plans.noPlans')}</div>`;
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
window.openACWRInfoModal = openACWRInfoModal;
window.pv4ExerciseDetailId = null;
window.pv4PlanDetailId = null;
