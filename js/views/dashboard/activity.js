// ========================================
// DASHBOARD ACTIVITY CALENDAR WIDGET (Suunto Style)
// ========================================

function getDashboardMonthDuration(sessions) {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();

  let totalMinutes = 0;

  sessions.forEach(session => {
    const date = getSessionDate(session);
    if (!date) return;
    if (date.getFullYear() !== year || date.getMonth() !== month) return;

    const durationSec = getSessionDurationSeconds(session);
    if (durationSec > 0) {
      totalMinutes += Math.round(durationSec / 60);
    }
  });

  return totalMinutes;
}

function getDashboardSessionsByDate(sessions, year, month) {
  const result = {};
  sessions.forEach(session => {
    const date = getSessionDate(session);
    if (!date) return;
    if (date.getFullYear() !== year || date.getMonth() !== month) return;
    const dateKey = getBerlinDateKey(date);
    if (!result[dateKey]) result[dateKey] = [];
    result[dateKey].push(session);
  });
  return result;
}

/**
 * Aggregiert Sessions pro Typ pro Tag und berechnet Dot-Größen
 * @param {Array} daySessions - Sessions eines Tages
 * @returns {Array} - Array von {type, size, rank, minutes} sortiert nach Größe (größte zuerst)
 */
function aggregateDayByType(daySessions) {
  // Summiere Minuten pro Typ
  const typeMinutes = {};
  daySessions.forEach(session => {
    const sType = session.type;
    const type = (sType === 'cardio' || sType === 'recovery' || sType === 'bodyweight')
      ? sType
      : 'strength';
    const durationSec = getSessionDurationSeconds(session);
    const minutes = Math.round(durationSec / 60);
    typeMinutes[type] = (typeMinutes[type] || 0) + minutes;
  });

  // Konvertiere zu Dot-Metadaten mit Größe basierend auf Gesamtdauer
  const dots = Object.entries(typeMinutes).map(([type, minutes]) => {
    const { size, rank } = getSizeFromMinutes(minutes);
    return { type, size, rank, minutes };
  });

  // Sortiere nach rank (größte zuerst für z-index Stacking)
  dots.sort((a, b) => b.rank - a.rank);

  return dots;
}

/**
 * Mappt Minuten zu Dot-Größe nach Spezifikation
 * < 15min => S, < 30min => M, < 45min => L, < 60min => XL, >= 60min => XXL
 */
function getSizeFromMinutes(minutes) {
  if (minutes >= 60) return { size: 'xxl', rank: 5 };
  if (minutes >= 45) return { size: 'xl', rank: 4 };
  if (minutes >= 30) return { size: 'l', rank: 3 };
  if (minutes >= 15) return { size: 'm', rank: 2 };
  return { size: 's', rank: 1 };
}

/**
 * Rendert nested Dots für einen Tag
 * - Größte Dots unten (niedrigster z-index), kleinste oben
 * - Micro-offset bei gleicher Größe
 */
function renderNestedDots(dots) {
  if (!dots || dots.length === 0) return '';

  // Erkenne Größen-Duplikate und markiere diese für offset
  const sizeCount = {};
  dots.forEach(dot => {
    sizeCount[dot.size] = (sizeCount[dot.size] || 0) + 1;
  });

  // Sortiere nach rank absteigend (größte zuerst für Rendering-Reihenfolge)
  // Größte werden zuerst gerendert = unterste Schicht
  const sortedDots = [...dots].sort((a, b) => b.rank - a.rank);

  const sizeOffsetUsed = {};
  const dotElements = sortedDots.map(dot => {
    let offsetClass = '';
    // Wenn es mehrere Dots mit dieser Größe gibt, gib dem zweiten/dritten ein offset
    if (sizeCount[dot.size] > 1) {
      if (!sizeOffsetUsed[dot.size]) {
        sizeOffsetUsed[dot.size] = true;
      } else {
        offsetClass = ' offset';
      }
    }
    return `<span class="mini-dot ${dot.type} size-${dot.size}${offsetClass}"></span>`;
  });

  return `<div class="mini-dot-stack">${dotElements.join('')}</div>`;
}

function formatDurationHoursMinutes(totalMinutes) {
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) {
    return `${hours}:${String(minutes).padStart(2, '0')}`;
  }
  if (hours > 0) {
    return `${hours}:00`;
  }
  return `0:${String(minutes).padStart(2, '0')}`;
}

/**
 * Formatiert Dauer als "Xh Xm" String (für Activity Calendar)
 * Erwartet Minuten als Input
 */
function formatDurationMinutesText(totalMinutes) {
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) {
    return `${hours}h ${minutes}m`;
  }
  if (hours > 0) {
    return `${hours}h`;
  }
  return `${minutes}m`;
}

/**
 * Aggregiert Sessions pro Trainingstyp für einen Zeitraum
 * @returns {Array} [{type, minutes, color}] sortiert nach Minuten absteigend
 */
function aggregateSessionsByType(sessions, year, month) {
  const typeMinutes = {
    strength: 0,
    cardio: 0,
    recovery: 0
  };

  sessions.forEach(session => {
    const date = getSessionDate(session);
    if (!date) return;
    if (date.getFullYear() !== year || date.getMonth() !== month) return;

    const type = session.type === 'cardio' ? 'cardio' : session.type === 'recovery' ? 'recovery' : 'strength';
    const durationSec = getSessionDurationSeconds(session);
    typeMinutes[type] += Math.round(durationSec / 60);
  });

  // Konvertiere zu Array und sortiere nach Minuten absteigend
  const typeColors = {
    strength: 'var(--color-category-strength)',
    cardio: 'var(--color-category-cardio)',
    recovery: 'var(--color-category-recovery)'
  };

  return Object.entries(typeMinutes)
    .filter(([_, minutes]) => minutes > 0)
    .map(([type, minutes]) => ({
      type,
      minutes,
      color: typeColors[type]
    }))
    .sort((a, b) => b.minutes - a.minutes);
}

/**
 * Wiederverwendbare Activity Calendar Grid Komponente
 * @param {Object} options - { year, month, sessionsByDate, detailed, dayLabels }
 */
function renderActivityCalendarGrid(options) {
  const { year, month, sessionsByDate, detailed = false, dayLabels } = options;

  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  let startDay = firstDay.getDay();
  startDay = startDay === 0 ? 6 : startDay - 1; // Monday-based
  const daysInMonth = lastDay.getDate();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const cellClass = detailed ? 'activity-cal-cell' : 'mini-cal-cell';
  const gridClass = detailed ? 'activity-cal-grid' : 'mini-cal-grid';
  const headerClass = detailed ? 'activity-cal-header' : 'mini-cal-header';
  const labelClass = detailed ? 'activity-cal-day-label' : 'mini-cal-day-label';

  let html = `<div class="${headerClass}">`;
  html += dayLabels.map(d => `<span class="${labelClass}">${d}</span>`).join('');
  html += `</div>`;
  html += `<div class="${gridClass}">`;

  // Empty cells for previous month
  for (let i = 0; i < startDay; i++) {
    html += `<div class="${cellClass} empty"></div>`;
  }

  // Days of current month
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const dateKey = getBerlinDateKey(date);
    const isToday = date.toDateString() === today.toDateString();
    const daySessions = sessionsByDate[dateKey] || [];

    const aggregatedDots = aggregateDayByType(daySessions);
    const dotHTML = renderNestedDots(aggregatedDots);

    const todayClass = isToday ? 'today' : '';
    const dayNumberHTML = detailed ? `<span class="day-number">${day}</span>` : '';

    html += `
      <div class="${cellClass} ${todayClass}" data-date="${dateKey}">
        ${dayNumberHTML}
        ${dotHTML}
      </div>
    `;
  }

  html += `</div>`;
  return html;
}

function renderDashboardPlanCalendar(state) {
  const container = document.getElementById('dashboard-plan-calendar');
  if (!container) return;

  if (state.loading) {
    container.innerHTML = `
      <div class="dashboard-activity-widget-expanded">
        <div class="dashboard-activity-loading">${tr('common.loading')}</div>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="dashboard-activity-widget-expanded">
      <h3 class="dashboard-calendar-widget-title">${tr('dashboard.planCalendar.title')}</h3>
      <div class="plan-calendar-widget-wrapper">
        <div class="calendar-month-section">
          <div class="dashboard-activity-month-nav">
            <button class="activity-nav-btn" onclick="navigateCalendar('prev')" aria-label="${tr('dashboard.calendar.prevMonth')}">
              <span class="material-symbols-rounded">chevron_left</span>
            </button>
            <span class="activity-month-title" id="calendar-title"></span>
            <button class="activity-nav-btn" onclick="navigateCalendar('next')" aria-label="${tr('dashboard.calendar.nextMonth')}">
              <span class="material-symbols-rounded">chevron_right</span>
            </button>
          </div>
          <div class="plan-calendar-weekdays">
            ${['mon','tue','wed','thu','fri','sat','sun'].map(k => `<span>${tr('calendar.dayNamesShort.' + k)}</span>`).join('')}
          </div>
          <div id="calendar-grid" class="plan-calendar-grid"></div>
        </div>
        <div class="calendar-agenda-container">
          <div class="calendar-agenda-list-header">
            <h3 class="calendar-agenda-list-title" id="agenda-list-title"></h3>
            <button class="agenda-add-btn" onclick="openQuickAddSheet()" aria-label="${tr('dashboard.calendar.addTraining')}">
              <span class="material-symbols-rounded">add</span>
            </button>
          </div>
          <div id="calendar-agenda-list" class="calendar-agenda-list"></div>
        </div>
      </div>
    </div>
  `;

  // Load schedule data if not yet loaded
  if (typeof loadSchedule === 'function' && (!Array.isArray(scheduleData) || scheduleData.length === 0)) {
    loadSchedule().then(() => {
      if (typeof renderCalendar === 'function') renderCalendar();
    });
  } else {
    if (typeof renderCalendar === 'function') renderCalendar();
  }
}

function renderDashboardTrainingTypesList(sessions, year, month) {
  const typeData = aggregateSessionsByType(sessions, year, month);

  if (typeData.length === 0) {
    return '';
  }

  const maxMinutes = typeData[0]?.minutes || 1;

  const typeConfig = {
    strength: {
      label: tr('dashboard.trainingTypes.strength') || 'Krafttraining',
      icon: 'fitness_center'
    },
    cardio: {
      label: tr('dashboard.trainingTypes.cardio') || 'Cardio',
      icon: 'directions_run'
    },
    recovery: {
      label: tr('dashboard.trainingTypes.recovery') || 'Recovery',
      icon: 'self_improvement'
    }
  };

  const items = typeData.map((item, idx) => {
    const config = typeConfig[item.type] || { label: item.type, icon: 'fitness_center' };
    const durationText = formatDurationMinutesText(item.minutes);
    const percentage = Math.round((item.minutes / maxMinutes) * 100);

    return `
      <div class="dashboard-training-type-item" style="--bar-delay:${idx * 80}ms">
        <div class="dashboard-training-type-header">
          <span class="dashboard-training-type-icon" style="color: ${item.color};">
            <span class="material-symbols-rounded">${config.icon}</span>
          </span>
          <span class="dashboard-training-type-label">${config.label}</span>
          <span class="dashboard-training-type-duration">${durationText}</span>
        </div>
        <div class="dashboard-training-type-bar-bg">
          <div class="dashboard-training-type-bar" style="width: ${percentage}%; background: ${item.color};"></div>
        </div>
      </div>
    `;
  }).join('');

  return `
    <div class="dashboard-training-types-list">
      ${items}
    </div>
  `;
}

// ========================================
// RECOMMENDATION WIDGET (moved from Progress)
// ========================================

function getIntensityMeta(intensity) {
  const map = {
    rest:     { label: tr('progress.recommendation.intensityRest'),     color: 'var(--zone-exhausted)',  dots: 0 },
    low:      { label: tr('progress.recommendation.intensityLow'),      color: 'var(--zone-fatigued)',   dots: 1 },
    moderate: { label: tr('progress.recommendation.intensityModerate'), color: 'var(--zone-loaded)',     dots: 2 },
    high:     { label: tr('progress.recommendation.intensityHigh'),     color: 'var(--zone-ready)',      dots: 3 }
  };
  return map[intensity] || map.moderate;
}

function renderDashboardRecommendation() {
  const container = document.getElementById('dashboard-recommendation');
  if (!container) return;

  if (typeof getTrainingRecommendation !== 'function' ||
      typeof computeFormScore !== 'function' ||
      typeof getACWR !== 'function' ||
      !sessionsLoaded) {
    container.innerHTML = '';
    return;
  }

  const formData = computeFormScore(allSessions, new Date());
  const readinessData = getACWR(allSessions, new Date());

  // Both null: show "no data"
  if ((formData.formScore === null || formData.zone === null) &&
      (readinessData.readinessScore === null || readinessData.zone === null)) {
    container.innerHTML = `
      <div class="dashboard-card recommendation-widget">
        <div class="recommendation-header">
          <span class="material-symbols-rounded recommendation-icon">tips_and_updates</span>
          <h3 class="pv3-card-title">${tr('progress.recommendation.title')}</h3>
        </div>
        <div class="recommendation-body">
          <p class="recommendation-text" style="color: var(--text-tertiary);">${tr('progress.recommendation.noData')}</p>
        </div>
      </div>`;
    return;
  }

  // If readiness is null but form exists, infer a readiness zone from form state
  const effectiveFormZone = formData.zone || 'maintaining';
  let effectiveReadinessZone = readinessData.zone;
  if (!effectiveReadinessZone) {
    // No readiness data means no recent acute/chronic baseline.
    // Use form-based fallback: detrained/declining → form_loss, else maintaining
    if (effectiveFormZone === 'detrained' || effectiveFormZone === 'declining') {
      effectiveReadinessZone = 'form_loss';
    } else {
      effectiveReadinessZone = 'maintaining';
    }
  }

  const rec = getTrainingRecommendation(effectiveFormZone, effectiveReadinessZone);
  const meta = getIntensityMeta(rec.intensity);
  const text = tr('progress.recommendation.' + rec.key);

  const dotsHTML = [1, 2, 3].map(i =>
    `<span class="recommendation-dot${i <= meta.dots ? ' active' : ''}" style="${i <= meta.dots ? 'background:' + meta.color : ''}"></span>`
  ).join('');

  container.innerHTML = `
    <div class="dashboard-card recommendation-widget">
      <div class="recommendation-header">
        <span class="material-symbols-rounded recommendation-icon" style="color: ${meta.color};">tips_and_updates</span>
        <h3 class="pv3-card-title">${tr('progress.recommendation.title')}</h3>
      </div>
      <div class="recommendation-body">
        <p class="recommendation-text">${text}</p>
      </div>
      <div class="recommendation-footer">
        <div class="recommendation-intensity">
          <div class="recommendation-dots">${dotsHTML}</div>
          <span class="recommendation-intensity-label" style="color: ${meta.color};">${meta.label}</span>
        </div>
      </div>
    </div>`;
}

// ========================================
// FORM-STATUS HERO (Dashboard "Heute")
// Visueller Form-Score-Ring (WHOOP/Oura-Stil), angedockt an computeFormScore().
// Additiv — bestehende Widgets bleiben unberührt.
// ========================================

function getFormZoneLabel(zone) {
  const map = {
    detrained: 'progress.form.zoneDetrained',
    declining: 'progress.form.zoneDeclining',
    recovery: 'progress.form.zoneRecovery',
    maintaining: 'progress.form.zoneMaintaining',
    building: 'progress.form.zoneBuilding',
    productive: 'progress.form.zoneProductive',
    peak_form: 'progress.form.zonePeakForm'
  };
  const key = map[zone] || map.maintaining;
  const label = tr(key);
  // Fallback, falls i18n-Key fehlt (tr gibt dann den Key zurück)
  return (label && label !== key) ? label : (zone || 'maintaining');
}

// Tägliche Bereitschaft (ACWR-Zone) — kurze deutsche Labels.
function readinessZoneLabel(zone) {
  const m = {
    overreaching: 'Überlastet', fatigued: 'Ermüdet', maintaining: 'Bereit',
    building: 'Aufbauend', peak: 'Topform', form_loss: 'Formverlust', fresh: 'Erholt'
  };
  return m[zone] || 'Bereit';
}

function renderDashboardFormHero() {
  const container = document.getElementById('dashboard-form-hero');
  if (!container) return;

  // Kein Form-Score verfügbar oder noch keine Daten → Hero ausblenden
  if (typeof computeFormScore !== 'function' || !sessionsLoaded) {
    container.style.display = 'none';
    container.innerHTML = '';
    return;
  }

  const data = computeFormScore(allSessions, new Date());
  if (!data || data.formScore === null || data.zone === null) {
    container.style.display = 'none';
    container.innerHTML = '';
    return;
  }

  container.style.display = 'block';

  const score = Math.round(data.formScore);
  const zone = data.zone;
  const color = (typeof getFormZoneColor === 'function')
    ? getFormZoneColor(zone)
    : 'var(--zone-loaded)';
  const label = getFormZoneLabel(zone);
  const hint = (typeof getFormHint === 'function') ? getFormHint(data.formScore, zone) : '';
  const trendIcon = (typeof getFormTrendIcon === 'function') ? getFormTrendIcon(data.trend) : 'trending_flat';

  // Mockup (heute): nur Ring + Form-Erklärtext. Die Tages-Bereitschaft wurde
  // bewusst aus dem Trainingsform-Widget entfernt.

  // Ring-Geometrie (viewBox 160×160, r=66)
  const r = 66;
  const circ = 2 * Math.PI * r;
  const clamped = Math.max(0, Math.min(100, score));
  const offset = circ * (1 - clamped / 100);

  // Mockup (heute): das Widget heißt "Trainingsform".
  const heroTitle = tr('recent.dashboard.formHeroTitle');

  container.innerHTML = `
    <div class="dashboard-card dashboard-form-hero-card" role="button" tabindex="0" onclick="openProgressOverview()">
      <span class="form-hero-label">${heroTitle}</span>
      <div class="form-hero-ring-wrap">
        <svg class="form-hero-ring" viewBox="0 0 160 160" width="160" height="160" aria-hidden="true">
          <circle cx="80" cy="80" r="${r}" fill="none" stroke="var(--bg-card-elevated)" stroke-width="12" />
          <circle class="form-hero-ring-fill" cx="80" cy="80" r="${r}" fill="none" stroke="${color}" stroke-width="12"
                  stroke-linecap="round" stroke-dasharray="${circ.toFixed(1)}" stroke-dashoffset="${offset.toFixed(1)}"
                  transform="rotate(-90 80 80)" />
        </svg>
        <div class="form-hero-center">
          <div class="form-hero-score">${score}</div>
          <div class="form-hero-zone" style="color:${color};">
            <span class="material-symbols-rounded">${trendIcon}</span>${label}
          </div>
        </div>
      </div>
      ${hint ? `<p class="form-hero-hint">${hint}</p>` : ''}
    </div>
  `;
}

async function refreshDashboard() {
  if (dashboardIsLoading) return;
  dashboardIsLoading = true;

  const data = await useDashboardData();
  renderQuickStatsWidget(data);
  renderLogWorkoutCard(data);
  renderDashboardFormHero();
  renderScheduledWorkoutsCard(data);
  renderDashboardRecommendation();
  if (typeof renderDashboardCalendar === 'function') renderDashboardCalendar();
  // Recent sessions removed - now in Progress > Overview
  // Activity calendar moved to Progress > Overview

  dashboardIsLoading = false;
}

async function initDashboard() {
  if (typeof onUserCollectionChange === 'function' && typeof sessionsCollection !== 'undefined') {
    onUserCollectionChange(sessionsCollection, (sessions) => {
      allSessions = sessions;
      sessionsLoaded = true;
      refreshDashboard();
    });
  }
  // Listen to schedule changes for scheduled workouts display
  if (typeof onUserCollectionChange === 'function' && typeof scheduleCollection !== 'undefined') {
    onUserCollectionChange(scheduleCollection, () => {
      refreshDashboard();
    });
  }
  // Pre-load schedule data for plan calendar tab
  if (typeof loadSchedule === 'function') {
    loadSchedule();
  }
  await refreshDashboard();
}

// Expose functions
window.refreshDashboard = refreshDashboard;
window.openStartWorkoutSheet = openStartWorkoutSheet;
window.startManualWorkout = startManualWorkout;
window.resumeWorkoutFromDashboard = resumeWorkoutFromDashboard;
window.openAddWorkoutSheet = openAddWorkoutSheet;
window.addWorkoutOfType = addWorkoutOfType;
window.openLogWorkoutTypeSheet = openLogWorkoutTypeSheet;
window.openPlanWorkoutSheet = openPlanWorkoutSheet;
window.openStartWorkoutFromPlanSheet = openStartWorkoutFromPlanSheet;
window.navigateToAllSessions = navigateToAllSessions;

// Shared Activity Calendar functions (used by calendar.js)
window.aggregateDayByType = aggregateDayByType;
window.getSizeFromMinutes = getSizeFromMinutes;
window.renderNestedDots = renderNestedDots;
window.aggregateSessionsByType = aggregateSessionsByType;
window.formatDurationMinutesText = formatDurationMinutesText;
window.renderActivityCalendarGrid = renderActivityCalendarGrid;
window.getDashboardSessionsByDate = getDashboardSessionsByDate;
window.getSessionDurationSeconds = getSessionDurationSeconds;
window.getSessionDate = getSessionDate;
window.getBerlinDateKey = getBerlinDateKey;

// ========================================
// AUTO-INITIALIZE
// ========================================

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDashboard);
} else {
  initDashboard();
}
