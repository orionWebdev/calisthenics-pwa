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

// Activity calendar state (month-based, separate from period filter)
let pv4ActivityMonth = new Date();

// Full training-history sub-page state
// pv4HistoryView: false | 'enter' (animate in) | true (open, no re-animation)
let pv4HistoryView = false;
let pv4HistoryTypeFilter = 'all';
let pv4HistoryPeriodFilter = 'all';

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
  if (pv4HistoryView) {
    const animateEnter = pv4HistoryView === 'enter';
    container.innerHTML = renderV4FullHistory(animateEnter);
    pv4HistoryView = true;
    attachV4FullHistoryListeners();
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
    attachEnduranceSportToggle();
  }

  // Draw sparklines
  requestAnimationFrame(() => drawAllV4Sparklines());
}

// Keep old name for compatibility
function renderProgressV3() { renderProgressV4(); }

// ==================== TAB BAR ====================

// Redesign v3 (Chunk 4): no more Übersicht/Übungen/Pläne tabs — the overview is a
// single scroll page. Sub-views (exercise trends via "Alle anzeigen") get a back button.
function renderV4TabBar() {
  if (pv4Tab === 'overview') return '';
  return `
    <button class="pv4-back-btn" type="button" onclick="pv4BackToOverview()"
      style="display:inline-flex;align-items:center;gap:4px;background:none;border:none;color:var(--color-primary-light);font-family:inherit;font-size:14px;font-weight:600;padding:6px 2px 14px;cursor:pointer;">
      <span class="material-symbols-rounded" style="font-size:20px;">arrow_back</span>${trV3('progress.widgets.overview')}
    </button>`;
}

window.pv4BackToOverview = function () {
  try {
    pv4Tab = 'overview';
    pv4ExerciseDetailId = null;
    pv4PlanDetailId = null;
    renderProgressV4();
  } catch (e) {}
};

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
  // Plans are no longer a Progress sub-view (they live in Training).
  if (pv4Tab === 'exercises') return renderV4ExerciseTrends();
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
  // Scope to the period selector's sticky bar — the Training view reuses the
  // .pv3-segmented-control class and sits earlier in the DOM, so a bare
  // querySelector('.pv3-segmented-control') would bind these handlers to that
  // hidden control instead, leaving the period buttons dead.
  const control = document.querySelector('#progress-tab-content .pv3-sticky-bar .pv3-segmented-control')
    || document.querySelector('#progress-tab-content .pv3-segmented-control');
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
let enduranceDistanceChartInstance = null;
let endurancePaceChartInstance = null;
let enduranceDurationChartInstance = null;
let enduranceSessionsChartInstance = null;

// ==================== ACTIVITY CALENDAR (moved from Dashboard) ====================

function renderV4ActivityCalendar() {
  return `<div id="pv4-activity-calendar-card" class="pv3-card pv4-activity-calendar-card">
    <h3 class="dashboard-calendar-widget-title">${trV3('progress.overview.activityCalendarTitle')}</h3>
    <div id="pv4-activity-calendar-inner">${renderV4ActivityCalendarInner()}</div>
    ${renderV4CalendarLastSession()}
  </div>`;
}

// Most-recent session embedded in the activity-calendar card, with a link
// through to the full training-history sub-page.
function renderV4CalendarLastSession() {
  const sessions = Array.isArray(allSessions) ? allSessions : [];
  if (!sessions.length) return '';

  const last = [...sessions].sort((a, b) => {
    const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return db - da;
  })[0];
  if (!last) return '';

  return `
    <div class="pv4-calendar-history">
      <div class="pv4-calendar-history-head">
        <span class="pv4-calendar-history-label">${trV3('progress.v4.overview.lastSession')}</span>
        <button class="pv4-history-link-btn" type="button" onclick="openFullHistory()">
          <span>${trV3('progress.v4.overview.showAll')}</span>
          <span class="material-symbols-rounded">arrow_forward</span>
        </button>
      </div>
      ${renderV4SessionRow(last)}
    </div>
  `;
}

function renderV4ActivityCalendarInner() {
  const sessions = Array.isArray(allSessions) ? allSessions : [];
  const year = pv4ActivityMonth.getFullYear();
  const month = pv4ActivityMonth.getMonth();

  const sessionsByDate = (typeof getDashboardSessionsByDate === 'function')
    ? getDashboardSessionsByDate(sessions, year, month)
    : {};

  const monthKeys = ['january', 'february', 'march', 'april', 'may', 'june',
                     'july', 'august', 'september', 'october', 'november', 'december'];
  const monthDisplay = `${trV3('calendar.monthNames.' + monthKeys[month])} ${year}`;

  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  let startDay = firstDay.getDay();
  startDay = startDay === 0 ? 6 : startDay - 1;
  const daysInMonth = lastDay.getDate();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  const dayLabels = dayKeys.map(k => trV3('calendar.dayNamesShort.' + k));

  let calendarHTML = `<div class="dashboard-mini-calendar-expanded">`;
  calendarHTML += `<div class="mini-cal-header-expanded">`;
  calendarHTML += dayLabels.map(d => `<span class="mini-cal-day-label-expanded">${d}</span>`).join('');
  calendarHTML += `</div>`;
  calendarHTML += `<div class="mini-cal-grid-expanded">`;

  for (let i = 0; i < startDay; i++) {
    calendarHTML += `<div class="mini-cal-cell-expanded empty"></div>`;
  }

  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const dateKey = (typeof getBerlinDateKey === 'function') ? getBerlinDateKey(date) : date.toISOString().slice(0, 10);
    const isToday = date.toDateString() === today.toDateString();
    const daySessions = sessionsByDate[dateKey] || [];

    const aggregatedDots = (typeof aggregateDayByType === 'function') ? aggregateDayByType(daySessions) : [];
    const dotHTML = (typeof renderNestedDots === 'function') ? renderNestedDots(aggregatedDots) : '';

    const todayClass = isToday ? 'today' : '';
    const hasSessionsClass = daySessions.length > 0 ? 'has-sessions' : '';

    calendarHTML += `
      <div class="mini-cal-cell-expanded ${todayClass} ${hasSessionsClass}"
           onclick="openV4ActivityDaySheet('${dateKey}')"
           role="button"
           tabindex="0">
        <span class="mini-cal-day-number">${day}</span>
        ${dotHTML}
      </div>
    `;
  }

  calendarHTML += `</div></div>`;

  return `
    <div class="dashboard-activity-month-nav">
      <button class="activity-nav-btn" onclick="navigateV4ActivityMonth('prev')" aria-label="${trV3('dashboard.calendar.prevMonth')}">
        <span class="material-symbols-rounded">chevron_left</span>
      </button>
      <span class="activity-month-title">${monthDisplay}</span>
      <button class="activity-nav-btn" onclick="navigateV4ActivityMonth('next')" aria-label="${trV3('dashboard.calendar.nextMonth')}">
        <span class="material-symbols-rounded">chevron_right</span>
      </button>
    </div>
    ${calendarHTML}
  `;
}

function navigateV4ActivityMonth(direction) {
  pv4ActivityMonth.setMonth(pv4ActivityMonth.getMonth() + (direction === 'next' ? 1 : -1));
  const inner = document.getElementById('pv4-activity-calendar-inner');
  if (inner) inner.innerHTML = renderV4ActivityCalendarInner();
}

function openV4ActivityDaySheet(dateKey) {
  if (typeof openActivityDaySheet === 'function') {
    openActivityDaySheet(dateKey);
  }
}

window.navigateV4ActivityMonth = navigateV4ActivityMonth;
window.openV4ActivityDaySheet = openV4ActivityDaySheet;

// ==================== FULL TRAINING-HISTORY SUB-PAGE ====================

// Shared session-row markup (used by the calendar card + full history page).
function renderV4SessionRow(s) {
  const type = mapSessionType(s) || 'strength';
  const icon = V3_TYPE_ICONS[type] || 'fitness_center';
  const d = s.date?.toDate ? s.date.toDate() : new Date(s.date);
  const dur = v3GetDurationMin(s);
  const name = s.planName || s.name || trV3('progress.v3.types.' + type);
  const sessionId = s.id || '';
  return `
    <button class="pv4-session-row pv4-session-clickable" type="button" data-session-id="${sessionId}">
      <span class="material-symbols-rounded pv4-session-icon" style="color:${V3_TYPE_COLORS[type]}">${icon}</span>
      <div class="pv4-session-info">
        <div class="pv4-session-name">${name}</div>
        <div class="pv4-session-meta">${v3FormatDate(d)}${dur > 0 ? ` · ${dur} min` : ''}</div>
      </div>
      <span class="material-symbols-rounded pv4-session-chevron">chevron_right</span>
    </button>`;
}

function getFilteredHistorySessions() {
  let sessions = Array.isArray(allSessions) ? [...allSessions] : [];
  if (pv4HistoryTypeFilter !== 'all') {
    sessions = sessions.filter(s => (mapSessionType(s) || 'strength') === pv4HistoryTypeFilter);
  }
  if (pv4HistoryPeriodFilter !== 'all') {
    const days = v3PeriodDays(pv4HistoryPeriodFilter);
    const cutoff = new Date();
    cutoff.setHours(0, 0, 0, 0);
    cutoff.setDate(cutoff.getDate() - days + 1);
    sessions = sessions.filter(s => v3ToLocalDate(s) >= cutoff);
  }
  return sessions;
}

// Renders the session list grouped into months with a divider per month.
function renderV4HistoryGrouped(sessions) {
  const sorted = [...sessions].sort((a, b) => {
    const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return db - da;
  });

  const monthKeys = ['january', 'february', 'march', 'april', 'may', 'june',
                     'july', 'august', 'september', 'october', 'november', 'december'];

  let html = '';
  let currentKey = null;
  sorted.forEach(s => {
    const d = v3ToLocalDate(s);
    const key = `${d.getFullYear()}-${d.getMonth()}`;
    if (key !== currentKey) {
      currentKey = key;
      const label = `${trV3('calendar.monthNames.' + monthKeys[d.getMonth()])} ${d.getFullYear()}`;
      html += `<div class="pv4-history-month-divider">${label}</div>`;
    }
    html += renderV4SessionRow(s);
  });
  return html;
}

function renderV4FullHistory(animateEnter) {
  const typeFilters = [
    { key: 'all', label: trV3('plan.filters.all') },
    { key: 'strength', label: trV3('plan.filters.strength') },
    { key: 'bodyweight', label: trV3('plan.filters.bodyweight') },
    { key: 'cardio', label: trV3('plan.filters.cardio') },
    { key: 'recovery', label: trV3('plan.filters.recovery') },
  ];
  const periods = [
    { key: 'all', label: trV3('plan.filters.all') },
    { key: '30D', label: trV3('progress.period.30d') },
    { key: '6M', label: trV3('progress.period.6m') },
    { key: '1Y', label: trV3('progress.period.1y') },
  ];

  const typeChips = typeFilters.map(f =>
    `<button class="pv4-hist-chip${f.key === pv4HistoryTypeFilter ? ' active' : ''}" type="button" data-hist-type="${f.key}">${f.label}</button>`
  ).join('');

  const periodActiveIdx = Math.max(0, periods.findIndex(p => p.key === pv4HistoryPeriodFilter));
  const periodSeg = `
    <div class="pv3-segmented-control pv4-hist-period" style="--seg-count:${periods.length};--active-idx:${periodActiveIdx}">
      <div class="pv3-seg-indicator"></div>
      ${periods.map(p =>
        `<button class="pv3-seg-btn${p.key === pv4HistoryPeriodFilter ? ' active' : ''}" type="button" data-hist-period="${p.key}">${p.label}</button>`
      ).join('')}
    </div>`;

  const sessions = getFilteredHistorySessions();
  const listHTML = sessions.length
    ? renderV4HistoryGrouped(sessions)
    : `<div class="pv3-empty-state"><span class="material-symbols-rounded">info</span>${trV3('progress.v4.overview.noSessions')}</div>`;

  return `
    <div class="pv4-history-page${animateEnter ? ' pv4-history-page--enter' : ''}">
      <div class="pv4-history-page-header">
        <button class="pv4-history-back-btn" type="button" id="pv4-history-back" aria-label="${trV3('common.back')}">
          <span class="material-symbols-rounded">arrow_back</span>
        </button>
        <h2 class="pv4-history-page-title">${trV3('progress.v4.overview.sessionHistory')}</h2>
      </div>
      <div class="pv4-history-filters">
        <div class="pv4-hist-chips">${typeChips}</div>
        ${periodSeg}
      </div>
      <div class="pv4-history-grouped">${listHTML}</div>
    </div>
  `;
}

function attachV4FullHistoryListeners() {
  const back = document.getElementById('pv4-history-back');
  if (back) back.addEventListener('click', closeFullHistory);

  document.querySelectorAll('[data-hist-type]').forEach(btn => {
    btn.addEventListener('click', () => {
      if (btn.dataset.histType === pv4HistoryTypeFilter) return;
      pv4HistoryTypeFilter = btn.dataset.histType;
      renderProgressV4();
    });
  });

  document.querySelectorAll('[data-hist-period]').forEach(btn => {
    btn.addEventListener('click', () => {
      if (btn.dataset.histPeriod === pv4HistoryPeriodFilter) return;
      pv4HistoryPeriodFilter = btn.dataset.histPeriod;
      renderProgressV4();
    });
  });

  document.querySelectorAll('.pv4-history-page .pv4-session-clickable').forEach(row => {
    row.addEventListener('click', () => {
      const sid = row.dataset.sessionId;
      if (sid && typeof openSessionDetail === 'function') openSessionDetail(sid);
    });
  });
}

function openFullHistory() {
  pv4HistoryView = 'enter';
  renderProgressV4();
  const scrollView = document.getElementById('progress-tab-content');
  if (scrollView) scrollView.scrollTop = 0;
}

function closeFullHistory() {
  pv4HistoryView = false;
  renderProgressV4();
}

window.openFullHistory = openFullHistory;
window.closeFullHistory = closeFullHistory;

// ==================== OVERVIEW ====================

// ==================== WOCHENVOLUMEN PRO MUSKELGRUPPE (Redesign v3, Chunk 2) ====================
// Sätze/Woche je primärer Muskelgruppe — der wissenschaftliche Standard (~10–20/Woche).
// Defensiv: alles in try/catch; bei Fehler/keinen Daten -> '' (bricht die Overview nie).
// Localized label for a primary muscle key. Grouping keys (quads/glutes/…) fold
// into the canonical i18n muscle names; unknowns fall back to a capitalized key.
function pv4MuscleLabel(key) {
  const mn = (typeof getMuscleNames === 'function') ? getMuscleNames() : {};
  const groupMap = { quads: 'legs', hamstrings: 'legs', glutes: 'legs', abs: 'core', fullbody: 'full-body' };
  return mn[key] || mn[groupMap[key]] || (key.charAt(0).toUpperCase() + key.slice(1));
}

function pv4MuscleWeeklySets(sessions, days) {
  const weeks = Math.max(1, (days || 7) / 7);
  const exById = {};
  if (typeof allExercises !== 'undefined' && Array.isArray(allExercises)) {
    allExercises.forEach(e => { if (e && e.id) exById[e.id] = e; });
  }
  const byMuscle = {};
  (sessions || []).forEach(s => {
    if (!s || s.type !== 'strength' || !Array.isArray(s.exercises)) return;
    s.exercises.forEach(ex => {
      const setCount = Array.isArray(ex.sets) ? ex.sets.length : 0;
      if (!setCount) return;
      const meta = exById[ex.exerciseId];
      const groups = (meta && Array.isArray(meta.muscleGroups) && meta.muscleGroups.length)
        ? meta.muscleGroups
        : (Array.isArray(ex.muscleGroups) ? ex.muscleGroups : []);
      const primary = groups[0];
      if (!primary) return;
      byMuscle[primary] = (byMuscle[primary] || 0) + setCount;
    });
  });
  return Object.keys(byMuscle)
    .map(key => ({ key, perWeek: byMuscle[key] / weeks }))
    .sort((a, b) => b.perWeek - a.perWeek);
}

function renderV4MuscleVolume(sessions, days) {
  try {
    const data = pv4MuscleWeeklySets(sessions, days);
    if (!data.length) return '';
    const rows = data.map(d => {
      const name = pv4MuscleLabel(d.key);
      const val = Math.round(d.perWeek);
      const pct = Math.max(6, Math.min(100, (d.perWeek / 20) * 100));
      return `
        <div style="display:flex;align-items:center;gap:10px;margin-top:10px;">
          <span style="width:84px;font-size:13px;color:var(--text-secondary);flex-shrink:0;">${name}</span>
          <span style="flex:1;height:8px;border-radius:999px;background:rgba(255,255,255,.07);overflow:hidden;">
            <span style="display:block;height:100%;border-radius:999px;width:${pct}%;background:linear-gradient(90deg,#C01963,#F02277);"></span>
          </span>
          <span style="width:42px;text-align:right;font-size:12px;color:var(--text-tertiary);font-variant-numeric:tabular-nums;">${val}</span>
        </div>`;
    }).join('');
    return `
      <div class="pv3-card">
        <div style="display:flex;align-items:center;gap:8px;font-size:13px;font-weight:600;text-transform:uppercase;letter-spacing:.06em;color:var(--text-secondary);margin-bottom:6px;">
          <span class="material-symbols-rounded" style="font-size:18px;color:var(--color-primary-light);">exercise</span>${t('progress.v3.weekVolumeTitle')}
        </div>
        <p style="font-size:13px;color:var(--text-secondary);margin:0;">${t('progress.v3.weekVolumeHint')}</p>
        ${rows}
      </div>`;
  } catch (e) {
    return '';
  }
}

// ==================== ÜBUNGS-PROGRESSION (Redesign v3, Chunk 3) ====================
// Kompakt: die aktivsten Übungen mit gegl. Trend + PR (Bestwert) + Sparkline.
// "Alle anzeigen" -> bestehender Übungen-Tab. Trend nie rot (Philosophie).
// Favoriten-Pinning & e1RM sind spätere Refinements. Alles defensiv geguarded.

function pv4TopExercises(sessions, limit) {
  const exById = {};
  if (typeof allExercises !== 'undefined' && Array.isArray(allExercises)) {
    allExercises.forEach(e => { if (e && e.id) exById[e.id] = e; });
  }
  const agg = {};
  (sessions || []).forEach(s => {
    if (!s || s.type !== 'strength' || !Array.isArray(s.exercises)) return;
    s.exercises.forEach(ex => {
      if (!ex || !ex.exerciseId || !Array.isArray(ex.sets) || !ex.sets.length) return;
      const id = ex.exerciseId;
      if (!agg[id]) {
        const meta = exById[id];
        const name = (meta && (meta.name_de || meta.name)) || ex.name || id;
        agg[id] = { id, name, sessions: 0 };
      }
      agg[id].sessions += 1;
    });
  });
  return Object.keys(agg).map(k => agg[k]).sort((a, b) => b.sessions - a.sessions).slice(0, limit || 3);
}

function pv4Sparkline(series, color) {
  const vals = (series || []).map(p => p.value).filter(v => typeof v === 'number');
  if (vals.length < 2) return '';
  const max = Math.max.apply(null, vals), min = Math.min.apply(null, vals);
  const range = (max - min) || 1;
  const W = 92, H = 34, n = vals.length;
  const pts = vals.map((v, i) => {
    const x = (i / (n - 1)) * (W - 4) + 2;
    const y = H - 3 - ((v - min) / range) * (H - 8);
    return x.toFixed(1) + ',' + y.toFixed(1);
  }).join(' ');
  return '<svg width="' + W + '" height="' + H + '" viewBox="0 0 ' + W + ' ' + H + '"><polyline fill="none" stroke="' + color + '" stroke-width="2.75" stroke-linecap="round" stroke-linejoin="round" points="' + pts + '"/></svg>';
}

// Per-exercise progression series. Weighted exercises -> e1RM (Epley:
// weight*(1+reps/30)); bodyweight -> max reps. Returns { series, weighted }.
function pv4ExerciseProgressionSeries(exerciseId, weeks) {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - (weeks || 8) * 7);
  let weighted = false;
  (typeof allSessions !== 'undefined' ? allSessions : []).forEach(function (s) {
    if (!s || s.type !== 'strength' || !Array.isArray(s.exercises)) return;
    const ex = s.exercises.find(function (e) { return e && e.exerciseId === exerciseId; });
    if (!ex || !Array.isArray(ex.sets)) return;
    ex.sets.forEach(function (set) { if ((Number(set.weight) || 0) > 0) weighted = true; });
  });
  const series = [];
  (typeof allSessions !== 'undefined' ? allSessions : []).forEach(function (s) {
    if (!s || s.type !== 'strength' || !Array.isArray(s.exercises)) return;
    const d = (s.date && s.date.toDate) ? s.date.toDate() : new Date(s.date);
    if (!(d >= cutoff)) return;
    const ex = s.exercises.find(function (e) { return e && e.exerciseId === exerciseId; });
    if (!ex || !Array.isArray(ex.sets) || !ex.sets.length) return;
    let best = 0;
    ex.sets.forEach(function (set) {
      const reps = Number(set.reps) || 0;
      const w = Number(set.weight) || 0;
      const v = (weighted && w > 0) ? (w * (1 + reps / 30)) : reps;
      if (v > best) best = v;
    });
    series.push({ date: d, value: Math.round(best) });
  });
  series.sort(function (a, b) { return a.date - b.date; });
  return { series: series, weighted: weighted };
}

function renderV4ExerciseProgression(sessions, days) {
  try {
    const weeks = Math.max(4, Math.round((days || 30) / 7));
    const top = pv4TopExercises(sessions, 3);
    if (!top.length) return '';
    const rows = top.map(ex => {
      let data = { series: [], weighted: false };
      try { data = pv4ExerciseProgressionSeries(ex.id, weeks); } catch (_) { data = { series: [], weighted: false }; }
      const series = data.series;
      const weighted = data.weighted;
      const vals = series.map(p => p.value).filter(v => typeof v === 'number');
      const first = vals.length ? vals[0] : 0;
      const last = vals.length ? vals[vals.length - 1] : 0;
      const delta = Math.round(last - first);
      const up = delta > 0;
      const unit = weighted ? 'kg' : trV3('progress.widgets.repsShort');
      const sinceMonth = series.length ? series[0].date.toLocaleDateString(getIntlLocale(), { month: 'short' }) : '';
      // Steigt → grün (Mockup); gehalten → neutral. Nie rot.
      const GREEN = '#22c55e';
      const lineColor = up ? GREEN : '#9ca3af';
      const deltaHTML = up
        ? '<span style="display:inline-flex;align-items:center;gap:2px;color:' + GREEN + ';font-weight:700;"><span class="material-symbols-rounded" style="font-size:14px;">arrow_upward</span>+' + delta + '</span>'
          + (sinceMonth ? '<span style="color:var(--text-tertiary);">· ' + trV3('progress.widgets.since', { month: sinceMonth }) + '</span>' : '')
        : '<span style="color:var(--text-secondary);font-weight:600;">' + trV3('progress.widgets.held') + '</span>';
      const spark = pv4Sparkline(series, lineColor);
      return '<div style="display:flex;align-items:center;gap:12px;padding:13px 0;border-bottom:1px solid var(--ui-card-border);">'
        + '<div style="min-width:0;flex:1;">'
        + '<div style="font-size:15px;font-weight:600;">' + ex.name + '</div>'
        + '<div style="font-size:12px;margin-top:3px;display:flex;align-items:center;gap:6px;flex-wrap:wrap;">'
        + '<span style="color:var(--text-secondary);font-weight:600;">' + last + ' ' + unit + '</span>'
        + deltaHTML
        + '</div></div>' + spark + '</div>';
    }).join('');
    return '<div class="pv3-card">'
      + '<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;">'
      + '<div style="display:flex;align-items:center;gap:8px;font-size:13px;font-weight:600;text-transform:uppercase;letter-spacing:.06em;color:var(--text-secondary);">'
      + '<span class="material-symbols-rounded" style="font-size:18px;color:var(--color-primary-light);">trending_up</span>' + trV3('progress.widgets.exerciseProgression') + '</div>'
      + '<button onclick="pv4ShowAllExercises()" style="background:none;border:none;font-family:inherit;font-size:12px;font-weight:600;color:var(--color-primary-light);display:inline-flex;align-items:center;gap:1px;cursor:pointer;">' + trV3('progress.widgets.showAll') + '<span class="material-symbols-rounded" style="font-size:16px;">chevron_right</span></button>'
      + '</div>' + rows + '</div>';
  } catch (e) {
    return '';
  }
}

window.pv4ShowAllExercises = function () {
  try { pv4Tab = 'exercises'; renderProgressV4(); } catch (e) {}
};

// ==================== KONSISTENZ-HERO (Redesign v3 — Mockup-aligned) ====================
// Hero ist der Held: Streak · Ø Sessions/Woche · Ø Stunden/Woche + 12-Wochen-Balken.

// Wöchentliches Trainingsvolumen (Last/Volumen, sonst Minuten) der letzten N Wochen.
function pv4WeeklyVolume(weeks) {
  weeks = weeks || 8;
  const vols = new Array(weeks).fill(0);
  const today = new Date(); today.setHours(0, 0, 0, 0);
  (Array.isArray(allSessions) ? allSessions : []).forEach(s => {
    const d = v3ToLocalDate(s);
    const daysAgo = Math.floor((today - d) / 86400000);
    if (daysAgo < 0) return;
    const wi = Math.floor(daysAgo / 7); // 0 = this week
    if (wi >= 0 && wi < weeks) {
      const vol = (typeof calcSessionVolume === 'function') ? calcSessionVolume(s) : 0;
      vols[wi] += vol > 0 ? vol : (v3GetDurationMin(s) || 0);
    }
  });
  return vols.reverse(); // oldest -> newest (left -> right)
}

function renderV4ConsistencyHero(sessions, days) {
  try {
    const totalSessions = sessions.length;
    const totalMinutes = sessions.reduce((s, x) => s + v3GetDurationMin(x), 0);
    const weeksSpan = Math.max(1, days / 7);
    const perWeek = totalSessions / weeksSpan;
    const streak = typeof calculateStreak === 'function' ? calculateStreak() : 0;
    const perWeekStr = perWeek.toFixed(1).replace('.', ',');

    const vols = pv4WeeklyVolume(8);
    const maxVol = Math.max.apply(null, vols.concat(1));
    const currentHighest = vols.length > 1 && vols[vols.length - 1] >= maxVol && maxVol > 0;
    const volBars = vols.map((v, i) => {
      const h = Math.max(6, Math.round((v / maxVol) * 100));
      const isCurrent = i === vols.length - 1;
      return `<span class="pv4-volbar${isCurrent ? ' current' : ''}" style="height:${h}%"></span>`;
    }).join('');
    const caption = `${trV3('progress.widgets.weeklyVolumeCaption')}${currentHighest ? ` · <b>${trV3('progress.widgets.highestThisWeek')}</b>` : ''}`;

    return `
      <section class="pv3-card pv4-konsistenz-hero">
        <div class="pv4-sec-title"><span class="material-symbols-rounded">local_fire_department</span>${trV3('progress.widgets.consistencyTitle')}</div>
        <div class="pv4-stat3">
          <div class="pv4-mini"><div class="v">${streak} <small>${trV3('progress.widgets.daysShort')}</small></div><div class="l">${trV3('progress.widgets.streak')}</div></div>
          <div class="pv4-mini"><div class="v">${perWeekStr}</div><div class="l">${trV3('progress.widgets.sessionsPerWeek')}</div></div>
          <div class="pv4-mini"><div class="v">${totalMinutes} <small>min</small></div><div class="l">${trV3('progress.widgets.movement')}</div></div>
        </div>
        <div class="pv4-volbars">${volBars}</div>
        <p class="pv4-lead pv4-muted pv4-vol-caption">${caption}</p>
      </section>`;
  } catch (e) { return ''; }
}

// ==================== FORM & BEREITSCHAFT (Redesign v3 — eine Mockup-Karte) ====================
// Geglätteter Form-Score + Zone + Trend-Linie + Bereitschafts-Pills (Belastung/Erholung · ACWR).

function pv4FormTrendPoints(n) {
  n = n || 8;
  if (typeof computeFormScore !== 'function') return [];
  const pts = [];
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(); d.setHours(12, 0, 0, 0); d.setDate(d.getDate() - i * 7);
    let v = null;
    try { v = computeFormScore(allSessions, d).formScore; } catch (e) {}
    if (typeof v === 'number') pts.push(v);
  }
  return pts;
}

function pv4SmoothLineSVG(values, w, h) {
  if (!values || values.length < 2) return '';
  const max = Math.max.apply(null, values), min = Math.min.apply(null, values);
  const range = (max - min) || 1;
  const pad = 8, n = values.length;
  const coords = values.map((v, i) => {
    const x = (i / (n - 1)) * (w - pad * 2) + pad;
    const y = h - pad - ((v - min) / range) * (h - pad * 2);
    return [x, y];
  });
  const linePts = coords.map(c => c[0].toFixed(1) + ',' + c[1].toFixed(1)).join(' ');
  const areaPath = 'M' + coords[0][0].toFixed(1) + ',' + coords[0][1].toFixed(1) + ' '
    + coords.slice(1).map(c => 'L' + c[0].toFixed(1) + ',' + c[1].toFixed(1)).join(' ')
    + ' L' + coords[n - 1][0].toFixed(1) + ',' + h.toFixed(1)
    + ' L' + coords[0][0].toFixed(1) + ',' + h.toFixed(1) + ' Z';
  const last = coords[n - 1];
  return `<svg class="pv4-form-chart" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">
    <defs>
      <linearGradient id="pv4formline" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C01963"/><stop offset="1" stop-color="#F02277"/></linearGradient>
      <linearGradient id="pv4formarea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F02277" stop-opacity="0.35"/><stop offset="1" stop-color="#F02277" stop-opacity="0"/></linearGradient>
    </defs>
    <path d="${areaPath}" fill="url(#pv4formarea)" stroke="none"/>
    <polyline fill="none" stroke="url(#pv4formline)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" points="${linePts}"/>
    <circle cx="${last[0].toFixed(1)}" cy="${last[1].toFixed(1)}" r="4.5" fill="#fff"/>
  </svg>`;
}

function renderV4FormReadiness() {
  if (typeof computeFormScore !== 'function') return '';
  const form = computeFormScore(allSessions, new Date());

  if (form.formScore === null || form.zone === null) {
    const b = getBaselineStatus();
    const bar = b.status !== 'no_data'
      ? `<div class="baseline-progress-container"><div class="baseline-progress-bar"><div class="baseline-progress-fill" style="width:${b.percentage}%"></div></div><div class="baseline-progress-label">${b.daysElapsed} / 14 ${trV3('progress.baseline.days')}</div></div>`
      : '';
    return `
      <section class="pv3-card">
        <div class="pv4-sec-title"><span class="material-symbols-rounded">monitoring</span>${trV3('progress.form.title')}</div>
        <p class="pv4-lead pv4-muted">${b.message}</p>${bar}
      </section>`;
  }

  const zoneColor = getFormZoneColor(form.zone);
  const phaseLabel = getFormPhaseLabel(form.zone);
  const trendIcon = (typeof getFormTrendIcon === 'function') ? getFormTrendIcon(form.trend) : 'trending_up';
  const series = pv4FormTrendPoints(8);
  const chart = pv4SmoothLineSVG(series, 320, 84);

  // Delta seit Periodenbeginn (oben rechts), grün bei positiv — kein Rot.
  let deltaHTML = '';
  if (series.length >= 2) {
    const delta = Math.round(series[series.length - 1] - series[0]);
    if (delta !== 0) {
      const dc = delta > 0 ? 'var(--zone-fresh, #22c55e)' : 'var(--text-secondary)';
      deltaHTML = `<div class="pv4-form-delta" style="color:${dc}">${delta > 0 ? '+' : ''}${delta}<span>${trV3('progress.widgets.vsStart')}</span></div>`;
    }
  }

  // Belastung / Erholung als Inline-Text (keine Kacheln) — wie im Mockup.
  let loadHTML = '';
  if (typeof getACWR === 'function') {
    const r = getACWR(allSessions, new Date(), { applyFatigue: true });
    if (r.zone) {
      const rPhase = getPhaseFromZone(r.zone);
      const acwrStr = (r.acwr != null) ? r.acwr.toFixed(1).replace('.', ',') : '–';
      loadHTML = `<div class="pv4-form-load"><span class="pv4-ready-dot" style="background:${getZoneColor(r.zone)}"></span>${trV3('progress.widgets.loadRecovery')}: <b style="color:${getZoneColor(r.zone)}">${rPhase.label}</b> · ACWR ${acwrStr}</div>`;
    }
  }

  return `
    <section class="pv3-card">
      <div class="pv4-form-head">
        <div>
          <div class="pv4-sec-title" style="margin-bottom:8px;"><span class="material-symbols-rounded">monitoring</span>${trV3('progress.widgets.formLoadTitle')}</div>
          <div class="pv4-form-score">${form.formScore}</div>
          <div class="pv4-form-zone" style="color:${zoneColor}"><span class="material-symbols-rounded">${trendIcon}</span>${phaseLabel}</div>
        </div>
        ${deltaHTML}
      </div>
      <div class="pv4-form-chart-wrap" style="--form-zone-color:${zoneColor}">${chart}</div>
      ${loadHTML}
    </section>`;
}

// ==================== HYBRID-BALANCE (Strength / Cardio / Recovery) ====================

function renderV4HybridBalance(sessions) {
  try {
    const buckets = { strength: 0, cardio: 0, recovery: 0 };
    (sessions || []).forEach(s => {
      const t = mapSessionType(s);
      const w = (v3GetDurationMin(s) || 0) > 0 ? v3GetDurationMin(s) : 1;
      if (t === 'strength' || t === 'bodyweight') buckets.strength += w;
      else if (t === 'cardio') buckets.cardio += w;
      else if (t === 'recovery') buckets.recovery += w;
    });
    const total = buckets.strength + buckets.cardio + buckets.recovery;
    if (total <= 0) return '';
    const segs = [
      { k: 'strength', label: trV3('progress.v3.types.strength'), color: 'var(--color-category-strength)' },
      { k: 'cardio', label: trV3('progress.v3.types.cardio'), color: 'var(--color-category-cardio)' },
      { k: 'recovery', label: trV3('progress.v3.types.recovery'), color: 'var(--color-category-recovery)' }
    ];
    const bar = segs.map(s => buckets[s.k] > 0 ? `<i style="width:${(buckets[s.k] / total) * 100}%;background:${s.color}"></i>` : '').join('');
    const legend = segs.map(s => `<div class="pv4-bal-item"><span class="pv4-bal-dot" style="background:${s.color}"></span>${s.label}<span class="pct">${Math.round((buckets[s.k] / total) * 100)} %</span></div>`).join('');
    return `
      <section class="pv3-card">
        <div class="pv4-sec-title"><span class="material-symbols-rounded">balance</span>${trV3('progress.widgets.hybridBalance')}</div>
        <div class="pv4-bal-bar">${bar}</div>
        <div class="pv4-bal-legend">${legend}</div>
      </section>`;
  } catch (e) { return ''; }
}

// ==================== VERLAUF-LINK (schlank — Browsing lebt im Training-Kalender) ====================

function renderV4HistoryCard() {
  const sessions = Array.isArray(allSessions) ? allSessions : [];
  if (!sessions.length) return '';
  const last = [...sessions].sort((a, b) => {
    const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return db - da;
  })[0];
  if (!last) return '';
  return `
    <section class="pv3-card">
      <div class="pv4-sec-head">
        <div class="pv4-sec-title" style="margin-bottom:0;"><span class="material-symbols-rounded">history</span>${trV3('progress.v4.overview.lastSession')}</div>
        <button class="pv4-sec-action" type="button" onclick="openFullHistory()">${trV3('progress.v4.overview.showAll')}<span class="material-symbols-rounded">chevron_right</span></button>
      </div>
      ${renderV4SessionRow(last)}
    </section>`;
}

function renderV4Overview() {
  const days = v3PeriodDays(pv4Period);
  const sessions = v3SessionsInRange(days);

  // Mockup-Reihenfolge: Konsistenz → Form & Bereitschaft → Wochenvolumen →
  // Übungs-Progression → Ausdauer → Hybrid-Balance → Verlauf.
  // (4er-Summary-Grid, Rhythmus-Widget und Aktivitätskalender entfallen —
  //  Browsing zieht in den vereinten Training-Kalender, Zahlen leben im Hero.)
  return `
    ${renderV4PeriodSelector()}
    ${renderV4ConsistencyHero(sessions, days)}
    ${renderV4FormReadiness()}
    ${renderV4ExerciseProgression(sessions, days)}
    ${renderEnduranceCard(sessions)}
    ${renderHeartRateCard(sessions)}
    ${renderV4HybridBalance(sessions)}
    ${renderV4HistoryCard()}
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

function getCssVarValue(varName) {
  return getComputedStyle(document.documentElement).getPropertyValue(varName).trim();
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

// Ausdauer (Strava-inspiriert): großes Distanz-Total + Stat-Grid (Ø/Woche · Ø-Pace ·
// Einheiten) + Wochendistanz-Balkenchart + Pro-Sport-Zeilen. Bewusst präsenter und
// optisch distinkt von den dünnen Progressions-Zeilen.
function pv4NormalizeSport(t) {
  return ({ running: 'run', laufen: 'run', cycling: 'bike', radfahren: 'bike', swimming: 'swim', schwimmen: 'swim', rowing: 'row', rudern: 'row', hiking: 'hike', walking: 'hike', wandern: 'hike' })[t] || t;
}
function pv4SportMeta(sp) {
  const M = {
    run:  { label: trV3('progress.widgets.sportRun'), icon: 'directions_run', metric: 'pace' },
    bike: { label: trV3('progress.widgets.sportBike'), icon: 'directions_bike', metric: 'speed' },
    swim: { label: trV3('progress.widgets.sportSwim'), icon: 'pool', metric: 'swim' },
    hike: { label: trV3('progress.widgets.sportHike'), icon: 'hiking', metric: 'pace' },
    row:  { label: trV3('progress.widgets.sportRow'), icon: 'rowing', metric: 'speed' },
    other:{ label: trV3('progress.widgets.sportOther'), icon: 'exercise', metric: 'none' }
  };
  return M[sp] || { label: sp ? (sp.charAt(0).toUpperCase() + sp.slice(1)) : 'Cardio', icon: 'fitness_center', metric: 'none' };
}

// Ausdauer — PRO SPORTART (Toggle), da Pace/km von Laufen ≠ Rad ≠ Schwimmen.
function renderEnduranceCard(sessions) {
  try {
    const cardio = (sessions || []).filter(s => mapSessionType(s) === 'cardio');
    if (!cardio.length) return '';

    // Welche Sportarten kommen vor? (nach Häufigkeit)
    const counts = {};
    cardio.forEach(s => { const sp = pv4NormalizeSport((s.activityType || 'other').toLowerCase()) || 'other'; counts[sp] = (counts[sp] || 0) + 1; });
    const sports = Object.keys(counts).sort((a, b) => counts[b] - counts[a]);
    let sel = pv4EnduranceSport;
    if (!sports.includes(sel)) { sel = sports[0]; pv4EnduranceSport = sel; }

    const meta = pv4SportMeta(sel);
    const isDistanceSport = meta.metric !== 'none';
    const list = cardio.filter(s => (pv4NormalizeSport((s.activityType || 'other').toLowerCase()) || 'other') === sel);

    const days = v3PeriodDays(pv4Period);
    const weeksSpan = Math.max(1, days / 7);
    const totalDist = list.reduce((a, s) => a + (Number(s.distanceKm) || 0), 0);
    const totalTime = list.reduce((a, s) => a + v3GetDurationMin(s), 0);
    const n = list.length;

    const fmtKm = v => v.toFixed(v >= 10 ? 0 : 1).replace('.', ',');
    const fmtPace = p => { let m = Math.floor(p); let s = Math.round((p - m) * 60); if (s >= 60) { m += 1; s = 0; } return m + ':' + String(s).padStart(2, '0'); };

    // Sport-passende Kernmetrik
    let metricVal, metricLabel;
    if (meta.metric === 'pace') { metricVal = totalDist > 0 ? fmtPace(totalTime / totalDist) : '–'; metricLabel = trV3('progress.widgets.avgPaceKm'); }
    else if (meta.metric === 'speed') { metricVal = totalTime > 0 ? (totalDist / (totalTime / 60)).toFixed(1).replace('.', ',') : '–'; metricLabel = trV3('progress.widgets.avgSpeedKmh'); }
    else if (meta.metric === 'swim') { metricVal = totalDist > 0 ? fmtPace(totalTime / (totalDist * 10)) : '–'; metricLabel = trV3('progress.widgets.avgPace100m'); }
    else { metricVal = n ? Math.round(totalTime / n) : '–'; metricLabel = trV3('progress.widgets.avgMin'); }

    const weeklyVal = isDistanceSport ? fmtKm(totalDist / weeksSpan) : Math.round(totalTime / weeksSpan);
    const totalDisplay = isDistanceSport ? `${fmtKm(totalDist)} km` : `${Math.round(totalTime)} min`;

    // 8-Wochen-Balken (Distanz, bzw. Zeit bei sport ohne Distanz) — nur die Sportart
    const W = 8;
    const wk = new Array(W).fill(0);
    const today = new Date(); today.setHours(0, 0, 0, 0);
    list.forEach(s => {
      const d = v3ToLocalDate(s);
      const wi = Math.floor((today - d) / 86400000 / 7);
      if (wi >= 0 && wi < W) wk[wi] += isDistanceSport ? (Number(s.distanceKm) || 0) : v3GetDurationMin(s);
    });
    wk.reverse();
    const maxW = Math.max.apply(null, wk.concat(0.1));
    const bars = wk.map((v, i) => `<span class="pv4-volbar${i === W - 1 ? ' current' : ''}" style="height:${Math.max(6, Math.round((v / maxW) * 100))}%"></span>`).join('');

    // Sport-Toggle (nur wenn >1 Sportart)
    const idx = sports.indexOf(sel);
    const toggle = sports.length > 1
      ? `<div class="pv3-segmented-control endurance-sport-toggle" style="--seg-count:${sports.length};--active-idx:${idx}">
          <div class="pv3-seg-indicator"></div>
          ${sports.map(sp => `<button class="pv3-seg-btn${sp === sel ? ' active' : ''}" data-sport="${sp}">${pv4SportMeta(sp).label}</button>`).join('')}
        </div>`
      : '';

    return `
      <section class="pv3-card pv4-endurance-card">
        <div class="pv4-sec-head">
          <div class="pv4-sec-title" style="margin-bottom:0;"><span class="material-symbols-rounded">${meta.icon}</span>${meta.label}</div>
          <span class="pv4-endurance-total">${totalDisplay}</span>
        </div>
        ${toggle}
        <div class="pv4-stat3 pv4-endurance-stats">
          <div class="pv4-mini"><div class="v">${weeklyVal} <small>${isDistanceSport ? 'km' : 'min'}</small></div><div class="l">${trV3('progress.widgets.perWeek')}</div></div>
          <div class="pv4-mini"><div class="v">${metricVal}</div><div class="l">${metricLabel}</div></div>
          <div class="pv4-mini"><div class="v">${n}</div><div class="l">${trV3('progress.widgets.sessionsUnit')}</div></div>
        </div>
        <div class="pv4-volbars pv4-endurance-bars">${bars}</div>
        <p class="pv4-lead pv4-muted pv4-vol-caption">${isDistanceSport ? trV3('progress.widgets.distance') : trV3('progress.widgets.durationWord')} · ${trV3('progress.widgets.last8Weeks')}</p>
      </section>`;
  } catch (e) {
    return '';
  }
}

// Eigenständige HF-Karte: Ø/Max + Zonen-Dust (Verteilung folgt mit Garmin-Samples).
function renderHeartRateCard(sessions) {
  try {
    const cardio = (sessions || []).filter(s => mapSessionType(s) === 'cardio');
    const hr = cardio.filter(s => s.avgHr);
    if (!hr.length) return '';
    const avgHr = Math.round(hr.reduce((a, s) => a + Number(s.avgHr), 0) / hr.length);
    const maxHr = cardio.reduce((a, s) => Math.max(a, Number(s.maxHr) || 0), 0);
    const zoneDots = ['Z1', 'Z2', 'Z3', 'Z4', 'Z5'].map((z, i) =>
      `<span class="pv4-hrz"><span class="muscle-dust muscle-icon--sm hz-${i + 1}"></span><span class="pv4-hrz-l">${z}</span></span>`
    ).join('');
    return `
      <section class="pv3-card pv4-hr-card">
        <div class="pv4-sec-title" style="margin-bottom:0.7rem;"><span class="material-symbols-rounded">cardiology</span>${trV3('progress.widgets.heartRate')}</div>
        <div class="pv4-hr-sum">
          <span class="pv4-hrsum-item"><span class="material-symbols-rounded">favorite</span>Ø ${avgHr} bpm</span>
          ${maxHr ? `<span class="pv4-hrsum-item"><span class="material-symbols-rounded">cardiology</span>Max ${maxHr} bpm</span>` : ''}
        </div>
        <div class="pv4-hrzones">${zoneDots}</div>
        <p class="pv4-lead pv4-muted pv4-vol-caption">${trV3('progress.widgets.hrZonesCaption')}</p>
      </section>`;
  } catch (e) {
    return '';
  }
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
  const locale = (typeof getIntlLocale === 'function') ? getIntlLocale() : 'de-DE';
  const map = new Map();

  buckets.forEach(b => {
    if (!b.date) return;
    const d = b.date instanceof Date ? b.date : new Date(b.date);
    const key = `${d.getFullYear()}-${d.getMonth()}`;
    if (!map.has(key)) {
      map.set(key, {
        label: new Date(d.getFullYear(), d.getMonth(), 1).toLocaleDateString(locale, { month: 'short', year: 'numeric' }),
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
        maxBarThickness: 40,
        minBarLength: 4,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
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
      interaction: { mode: 'index', intersect: false },
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
      interaction: { mode: 'index', intersect: false },
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
      interaction: { mode: 'index', intersect: false },
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

function rerenderEnduranceCard() {
  const oldCard = document.querySelector('.pv4-endurance-card');
  if (!oldCard) return;

  const days = v3PeriodDays(pv4Period);
  const sessions = v3SessionsInRange(days);
  const tmp = document.createElement('div');
  tmp.innerHTML = renderEnduranceCard(sessions).trim();
  const newCard = tmp.firstElementChild;
  if (!newCard) return;

  oldCard.replaceWith(newCard);
  attachEnduranceSportToggle();
}

// Per-sport toggle for the endurance card (run/bike/swim/…); swaps only that card.
function attachEnduranceSportToggle() {
  const toggle = document.querySelector('.endurance-sport-toggle');
  if (!toggle) return;
  toggle.querySelectorAll('.pv3-seg-btn').forEach((btn, idx) => {
    btn.addEventListener('click', () => {
      const sport = btn.dataset.sport;
      if (sport === pv4EnduranceSport) return;
      pv4EnduranceSport = sport;
      try { localStorage.setItem('enduranceSportKey', sport); } catch (e) {}
      toggle.style.setProperty('--active-idx', idx);
      toggle.querySelectorAll('.pv3-seg-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      setTimeout(() => rerenderEnduranceCard(), 200);
    });
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

      // Only swap out the endurance card — leave the rest of the page (rhythm
      // widget, summary cards, calendar etc.) untouched so their entry
      // animations don't replay on every sport switch.
      setTimeout(() => rerenderEnduranceCard(), 220);
    });
  });

  // Transform-based slider with swipe support, clickable dots and arrows
  const slider = document.querySelector('.endurance-stat-slider');
  const track = slider?.querySelector('.endurance-stat-track');
  const dots = document.querySelectorAll('.endurance-stat-dot');
  const prevArrow = document.querySelector('.endurance-stat-arrow--prev');
  const nextArrow = document.querySelector('.endurance-stat-arrow--next');
  const slideCount = track?.children.length || 0;

  if (slider && track && slideCount > 0) {
    let currentSlide = 0;

    const goToSlide = (idx) => {
      currentSlide = Math.max(0, Math.min(idx, slideCount - 1));
      track.style.transition = 'transform 0.3s cubic-bezier(0.4, 0.0, 0.2, 1)';
      track.style.transform = `translateX(-${currentSlide * 100}%)`;
      dots.forEach((dot, i) => dot.classList.toggle('active', i === currentSlide));
      if (prevArrow) prevArrow.disabled = currentSlide === 0;
      if (nextArrow) nextArrow.disabled = currentSlide === slideCount - 1;
    };

    goToSlide(0);

    // Clickable dots + arrows
    dots.forEach((dot, i) => {
      dot.addEventListener('click', () => goToSlide(i));
    });
    prevArrow?.addEventListener('click', () => goToSlide(currentSlide - 1));
    nextArrow?.addEventListener('click', () => goToSlide(currentSlide + 1));

    // Swipe with live drag-follow
    let touchStartX = 0;
    let touchStartY = 0;
    let dragging = false;
    let axisLocked = false;

    slider.addEventListener('touchstart', (e) => {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
      dragging = true;
      axisLocked = false;
      track.style.transition = 'none';
    }, { passive: true });

    slider.addEventListener('touchmove', (e) => {
      if (!dragging) return;
      const dx = e.touches[0].clientX - touchStartX;
      const dy = e.touches[0].clientY - touchStartY;
      if (!axisLocked) {
        if (Math.abs(dx) < 8 && Math.abs(dy) < 8) return;
        axisLocked = true;
        // Vertical scroll wins — abort the drag
        if (Math.abs(dy) > Math.abs(dx)) {
          dragging = false;
          goToSlide(currentSlide);
          return;
        }
      }
      const base = -currentSlide * slider.offsetWidth;
      // Rubber-band at the edges
      let offset = dx;
      if ((currentSlide === 0 && dx > 0) ||
          (currentSlide === slideCount - 1 && dx < 0)) {
        offset = dx * 0.3;
      }
      track.style.transform = `translateX(${base + offset}px)`;
    }, { passive: true });

    slider.addEventListener('touchend', (e) => {
      if (!dragging) return;
      dragging = false;
      const dx = e.changedTouches[0].clientX - touchStartX;
      if (Math.abs(dx) > slider.offsetWidth * 0.18) {
        goToSlide(currentSlide + (dx < 0 ? 1 : -1));
      } else {
        goToSlide(currentSlide);
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

function getRhythmSubtitleKey(periodKey) {
  if (periodKey === '7D') return 'progress.v3.rhythm.subtitleDays';
  if (periodKey === '30D') return 'progress.v3.rhythm.subtitleWeeks';
  if (periodKey === '6M') return 'progress.v3.rhythm.subtitle6m';
  return 'progress.v3.rhythm.subtitle';
}

function formatTotalMinutes(mins) {
  if (mins <= 0) return '0 min';
  if (mins < 60) return `${mins} min`;
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  return m === 0 ? `${h}h` : `${h}h ${m}min`;
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

  const totalsPerBucket = buckets.map(b => V3_KNOWN_TYPES.reduce((sum, t) => sum + b.data[t], 0));
  const maxMin = Math.max(1, ...totalsPerBucket);
  const grandTotal = totalsPerBucket.reduce((a, b) => a + b, 0);
  const hasData = grandTotal > 0;

  const subtitle = trV3(getRhythmSubtitleKey(pv4Period));

  if (!hasData) {
    return `
      <div class="pv3-card pv3-rhythm-card">
        <div class="pv3-card-header pv3-rhythm-header">
          <div class="pv3-rhythm-header-text">
            <h3 class="pv3-card-title">${trV3('progress.v3.rhythm.title')}</h3>
            <span class="pv3-card-subtitle">${subtitle}</span>
          </div>
        </div>
        <div class="pv3-empty-state">
          <span class="material-symbols-rounded">info</span>
          ${trV3('progress.v3.rhythm.noData')}
        </div>
      </div>`;
  }

  const barsHtml = buckets.map((b, idx) => {
    const total = totalsPerBucket[idx];
    const heightPct = Math.max(0, (total / maxMin) * 100);
    const segments = V3_KNOWN_TYPES
      .filter(t => b.data[t] > 0)
      .map(t => `<div class="pv3-rhythm-seg" style="height:${(b.data[t] / total) * 100}%;background:${V3_TYPE_COLORS[t]}" title="${Math.round(b.data[t])} min"></div>`)
      .join('');
    const isEmpty = total === 0;
    const colClasses = ['pv3-rhythm-col'];
    if (b.isCurrent) colClasses.push('current');
    if (isEmpty) colClasses.push('empty');
    return `
      <div class="${colClasses.join(' ')}" style="--bar-delay:${idx * 30}ms">
        <div class="pv3-rhythm-bar-wrap" aria-hidden="true">
          ${isEmpty ? '<div class="pv3-rhythm-bar-empty"></div>' : `<div class="pv3-rhythm-bar" style="height:${heightPct}%">${segments}</div>`}
        </div>
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
      return `
        <span class="pv3-legend-item">
          <span class="pv3-legend-dot" style="background:${V3_TYPE_COLORS[t]}"></span>
          <span class="pv3-legend-text">${trV3('progress.v3.types.' + t)}</span>
          <span class="pv3-legend-time">${timeStr}</span>
        </span>`;
    })
    .join('');

  return `
    <div class="pv3-card pv3-rhythm-card">
      <div class="pv3-card-header pv3-rhythm-header">
        <div class="pv3-rhythm-header-text">
          <h3 class="pv3-card-title">${trV3('progress.v3.rhythm.title')}</h3>
          <span class="pv3-card-subtitle">${subtitle}</span>
        </div>
        <div class="pv3-rhythm-total" aria-label="Gesamt">
          <span class="pv3-rhythm-total-value">${formatTotalMinutes(grandTotal)}</span>
        </div>
      </div>
      <div class="pv3-rhythm-chart" role="img" aria-label="${trV3('progress.v3.rhythm.title')}">
        <div class="pv3-rhythm-grid" aria-hidden="true">
          <span class="pv3-rhythm-gridline"></span>
          <span class="pv3-rhythm-gridline"></span>
          <span class="pv3-rhythm-gridline"></span>
        </div>
        ${barsHtml}
      </div>
      <div class="pv3-legend">${legendHtml}</div>
    </div>`;
}

// ==================== SESSION HISTORY (COLLAPSIBLE) ====================

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
               placeholder="${trV3('progress.v4.exercises.searchPlaceholder')}"
               value="${pv4ExerciseSearchTerm}"
               oninput="onPv4ExerciseSearchInput()" />
        <button id="pv4-exercise-search-clear" class="exercise-search-clear${clearVal}" onclick="clearPv4ExerciseSearch()">
          <span class="material-symbols-rounded">close</span>
        </button>
      </div>
      <div class="pv4-muscle-filter-chips">
        <button class="pv4-muscle-chip${allActive}" data-muscle="" onclick="setPv4MuscleFilter('')">
          <span>${trV3('progress.v4.exercises.allMuscles')}</span>
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

// "Alle anzeigen" — Übungsliste im Mockup-Zeilenstil (konsistent mit der Overview-
// Progression): Name · Ø/e1RM · gegl. Trend (nie rot) · PR · Sparkline. Klick → Detail.
function renderV4ExerciseTrends() {
  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
  const exById = {};
  exercises.forEach(e => { if (e && e.id) exById[e.id] = e; });

  const agg = {};
  (Array.isArray(allSessions) ? allSessions : []).forEach(s => {
    if (!s || !Array.isArray(s.exercises)) return;
    s.exercises.forEach(ex => {
      if (!ex || !ex.exerciseId) return;
      if (!agg[ex.exerciseId]) {
        const meta = exById[ex.exerciseId];
        agg[ex.exerciseId] = {
          exerciseId: ex.exerciseId,
          name: (meta && (meta.name_de || meta.name)) || ex.name || ex.exerciseId,
          muscleGroups: (meta && meta.muscleGroups) || ex.muscleGroups || [],
          sessionCount: 0
        };
      }
      agg[ex.exerciseId].sessionCount++;
    });
  });

  let filtered = Object.values(agg);

  if (pv4ExerciseSearchTerm) {
    const q = pv4ExerciseSearchTerm.toLocaleLowerCase('de-DE');
    filtered = filtered.filter(ex => ex.name.toLocaleLowerCase('de-DE').includes(q));
  }
  if (pv4ExerciseMuscleFilter) {
    filtered = filtered.filter(ex => exercisePrimaryMatchesMuscle(ex, pv4ExerciseMuscleFilter));
  }
  filtered.sort((a, b) => b.sessionCount - a.sessionCount);

  const filterBar = renderV4ExerciseFilterBar();

  if (Object.keys(agg).length === 0) {
    return `${filterBar}<div class="pv3-empty-state"><span class="material-symbols-rounded">info</span>${trV3('progress.v4.exercises.noExercises')}</div>`;
  }
  if (filtered.length === 0) {
    return `${filterBar}<div class="pv3-empty-state"><span class="material-symbols-rounded">search_off</span>${trV3('progress.v4.exercises.noFilterResults')}</div>`;
  }

  const rows = filtered.map(ex => {
    let data = { series: [], weighted: false };
    try { data = pv4ExerciseProgressionSeries(ex.exerciseId, 12); } catch (_) {}
    const vals = data.series.map(p => p.value).filter(v => typeof v === 'number');
    const pr = vals.length ? Math.max.apply(null, vals) : 0;
    const avg = vals.length ? Math.round(vals.reduce((a, b) => a + b, 0) / vals.length) : 0;
    const first = vals.length ? vals[0] : 0;
    const last = vals.length ? vals[vals.length - 1] : 0;
    const up = last > first + 0.5;
    const trendIcon = up ? 'trending_up' : 'trending_flat';
    const trendColor = up ? 'var(--color-primary-light)' : 'var(--text-secondary)';
    const trendText = up ? trV3('progress.widgets.rising') : trV3('progress.widgets.held');
    const avgStr = vals.length ? (data.weighted ? ('e1RM Ø ' + avg + ' kg') : ('Ø ' + avg + ' ' + trV3('progress.widgets.repsShort'))) : trV3('progress.widgets.trained', { count: ex.sessionCount });
    const prStr = pr > 0 ? (data.weighted ? ('PR ' + pr + ' kg') : ('PR ' + pr)) : '';
    const spark = pv4Sparkline(data.series, up ? '#F02277' : '#9ca3af');
    return `
      <button class="pv4-ex-row pv4-ex-row-btn" type="button" data-exercise-id="${ex.exerciseId}">
        <div class="pv4-ex-info">
          <div class="pv4-ex-n">${ex.name}</div>
          <div class="pv4-ex-sub">
            <span class="pv4-ex-avg">${avgStr}</span>
            ${vals.length ? `<span class="pv4-ex-trend" style="color:${trendColor}"><span class="material-symbols-rounded">${trendIcon}</span>${trendText}</span>` : ''}
            ${prStr ? `<span class="pv4-pr"><span class="material-symbols-rounded">emoji_events</span>${prStr}</span>` : ''}
          </div>
        </div>
        ${spark || '<span class="material-symbols-rounded pv4-ex-chevron">chevron_right</span>'}
      </button>`;
  }).join('');

  return `${filterBar}<div class="pv3-card pv4-ex-list">${rows}</div>`;
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

  // Attach click listeners for exercise cards / rows
  document.querySelectorAll('.pv4-exercise-card, .pv4-ex-row-btn[data-exercise-id]').forEach(row => {
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

  // Attach click listeners for session rows (open detail/edit).
  // Covers the last-session row inside the activity-calendar card.
  document.querySelectorAll('.pv4-session-clickable').forEach(row => {
    row.addEventListener('click', () => {
      const sid = row.dataset.sessionId;
      if (sid && typeof openSessionDetail === 'function') {
        openSessionDetail(sid);
      }
    });
  });
}

// ==================== EXERCISE DETAIL ====================

// Epley estimated 1RM \u2014 only meaningful when a set carries weight.
function pv4Est1RM(weight, reps) {
  if (!weight || weight <= 0) return 0;
  return weight * (1 + (reps || 0) / 30);
}

// Shared per-session series for the exercise detail. Chart, summary cards and the
// history table all read from this, so they can never disagree. Primary metric is
// the estimated 1RM (best set, Epley) for weighted exercises, falling back to
// weighted volume for bodyweight exercises (where 1RM is meaningless).
function getExerciseDetailSeries(exerciseId) {
  const sessions = (typeof allSessions !== 'undefined' ? allSessions : [])
    .filter(s => s.exercises?.some(ex => ex.exerciseId === exerciseId))
    .sort((a, b) => {
      const da = a.date?.toDate ? a.date.toDate() : new Date(a.date);
      const db = b.date?.toDate ? b.date.toDate() : new Date(b.date);
      return da - db;
    });

  let hasWeight = false;
  const rows = sessions.map(s => {
    const ex = s.exercises.find(e => e.exerciseId === exerciseId);
    const sets = Array.isArray(ex.sets) ? ex.sets : [];
    const vol = typeof calculateExerciseWeightedVolume === 'function'
      ? calculateExerciseWeightedVolume(ex)
      : sets.reduce((sum, set) => sum + (set.reps || 0), 0);

    let best1RM = 0, topSet = null, bestReps = 0;
    sets.forEach(set => {
      const w = set.weight || 0;
      const reps = set.reps || 0;
      if (w > 0) hasWeight = true;
      if (reps > bestReps) bestReps = reps;
      const e = pv4Est1RM(w, reps);
      if (e > best1RM) { best1RM = e; topSet = { weight: w, reps: reps }; }
    });

    return {
      date: s.date?.toDate ? s.date.toDate() : new Date(s.date),
      sets: sets.length,
      setReps: sets.map(x => x.reps || 0),
      volume: vol,
      best1RM: Math.round(best1RM),
      topSet, bestReps,
      planName: s.planName || ''
    };
  });

  rows.forEach(r => { r.value = hasWeight ? r.best1RM : r.volume; });
  return { rows, hasWeight, unit: hasWeight ? 'kg' : '' };
}

function renderExerciseDetail(exerciseId) {
  const exercises = typeof allExercises !== 'undefined' ? allExercises : [];
  const exData = exercises.find(e => e.id === exerciseId);
  const name = exData?.name || exerciseId;

  const { rows, hasWeight, unit } = getExerciseDetailSeries(exerciseId);

  const values = rows.map(r => r.value);
  const pr = values.length ? Math.max(...values) : 0;
  const avg = values.length ? Math.round(values.reduce((a, b) => a + b, 0) / values.length) : 0;
  const last = values.length ? values[values.length - 1] : 0;
  const prIdx = values.length ? values.indexOf(pr) : -1;
  const u = unit ? `<span class="pv4-summary-unit">${unit}</span>` : '';

  // History table, newest first; the PR session is flagged.
  const histRows = rows.map((r, i) => ({ r, i })).reverse().slice(0, 30).map(({ r, i }) => {
    const dd = `${String(r.date.getDate()).padStart(2, '0')}.${String(r.date.getMonth() + 1).padStart(2, '0')}.`;
    const best = hasWeight
      ? (r.topSet ? `${r.topSet.weight}\u00D7${r.topSet.reps}` : '\u2013')
      : (r.bestReps ? `${r.bestReps}` : '\u2013');
    const isPR = i === prIdx && pr > 0;
    return `
      <div class="pv4-hist-row${isPR ? ' is-pr' : ''}">
        <span class="pv4-hist-date">${dd}${isPR ? '<span class="pv4-hist-pr">PR</span>' : ''}</span>
        <span class="pv4-hist-sets">${r.sets}</span>
        <span class="pv4-hist-best">${best}</span>
        <span class="pv4-hist-vol">${r.volume}</span>
      </div>`;
  }).join('');

  const bestHead = hasWeight ? 'Bestes Set' : 'Wdh.';

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
          <div class="pv4-summary-value">${pr}${u}</div>
          <div class="pv4-summary-label">${trV3('progress.v4.exercises.detail.pr')}</div>
        </div>
        <div class="pv4-summary-card">
          <div class="pv4-summary-value">${avg}${u}</div>
          <div class="pv4-summary-label">${trV3('progress.v4.exercises.detail.average')}</div>
        </div>
        <div class="pv4-summary-card">
          <div class="pv4-summary-value">${last || '-'}${last ? u : ''}</div>
          <div class="pv4-summary-label">${trV3('progress.v4.exercises.detail.lastSession')}</div>
        </div>
      </div>
      <div class="pv4-section-title">${trV3('progress.v4.exercises.detail.history')}</div>
      <div class="pv4-hist-table">
        <div class="pv4-hist-head">
          <span>Datum</span><span class="pv4-hist-sets">S\u00E4tze</span><span>${bestHead}</span><span class="pv4-hist-vol">Vol.</span>
        </div>
        ${histRows}
      </div>
    </div>
  `;
}

function drawExerciseDetailChart(exerciseId) {
  const canvas = document.getElementById('pv4-exercise-chart');
  if (!canvas) return;

  // Same series as the cards/table (estimated 1RM, or volume for bodyweight).
  const values = getExerciseDetailSeries(exerciseId).rows.map(r => r.value);

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

  // Data line — immer grün (Fortschritt = Trend, kein Rot bei Tagesschwankung)
  const lineColor = '#22c55e';

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
