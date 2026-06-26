// ========================================
// CALENDAR MANAGEMENT - Month Grid + Agenda List
// ========================================

// Calendar State
let currentDate = new Date();
let scheduleData = []; // Alle geplanten Trainings
let selectedDate = formatDate(new Date()); // Aktuell ausgewaehlter Tag


// ========================================
// CALENDAR EVENT VIEWMODEL (Sync-Ready)
// Prepared for Google Calendar, iOS Calendar,
// Outlook integration via originId + provider
// ========================================

/**
 * @typedef {'plan'|'quick'|'google'|'apple'|'outlook'|'external'} CalendarEventSource
 *
 * @typedef {Object} CalendarEvent
 * @property {string} id - Unique identifier
 * @property {CalendarEventSource} source - Where this event comes from
 * @property {string} title - Display title
 * @property {'strength'|'cardio'|'recovery'|'bodyweight'|'event'} type
 * @property {string} startDate - YYYY-MM-DD
 * @property {string|null} [startTime] - HH:mm (optional, for timed events)
 * @property {string|null} [endTime] - HH:mm (optional, for timed events)
 * @property {number|null} [durationMin] - Duration in minutes
 * @property {string|null} [originId] - External calendar event ID for sync
 * @property {string|null} [calendarId] - External calendar ID (e.g. Google Calendar ID)
 * @property {string|null} [provider] - 'google'|'apple'|'outlook' for external events
 * @property {string|null} [planId] - Reference to plans collection
 * @property {boolean} completed - Completion status
 * @property {string|null} [color] - Override color for external events
 * @property {Object} _original - Original Firestore entry
 */

/**
 * Maps a schedule entry from Firestore to CalendarEvent ViewModel
 * @param {Object} entry - Raw schedule entry from Firestore
 * @returns {CalendarEvent}
 */
function mapScheduleToCalendarEvent(entry) {
  let source = 'external';
  if (entry.planId) source = 'plan';
  else if (entry.isQuickEntry) source = 'quick';
  else if (entry.provider === 'google') source = 'google';
  else if (entry.provider === 'apple') source = 'apple';
  else if (entry.provider === 'outlook') source = 'outlook';

  return {
    id: entry.id,
    source: source,
    title: entry.planName || t('calendar.untitled'),
    type: entry.planType || 'strength',
    startDate: entry.date,
    startTime: entry.startTime || null,
    endTime: entry.endTime || null,
    durationMin: entry.planDuration || null,
    originId: entry.originId || null,
    calendarId: entry.calendarId || null,
    provider: entry.provider || null,
    planId: entry.planId || null,
    completed: entry.completed || false,
    color: entry.color || null,
    _original: entry
  };
}

/**
 * Maps a completed session to a CalendarEvent. Unified calendar: past days
 * show what was actually done.
 * @param {Object} session
 * @returns {CalendarEvent}
 */
function mapSessionToCalendarEvent(session) {
  const d = session?.date?.toDate ? session.date.toDate() : new Date(session?.date);
  const dateStr = formatDate(d);
  const raw = (session.type || '').toLowerCase().trim();
  let type = 'strength';
  if (raw === 'cardio' || session.activityType) type = 'cardio';
  else if (raw === 'recovery') type = 'recovery';
  else if (raw === 'bodyweight') type = 'bodyweight';
  const dur = (typeof getSessionDurationMinutesSafe === 'function')
    ? getSessionDurationMinutesSafe(session)
    : (session.durationMin || null);
  return {
    id: 'session-' + (session.id || dateStr),
    source: 'session',
    title: session.planName || session.name || (t('plan.types.' + type) || 'Training'),
    type: type,
    startDate: dateStr,
    startTime: null,
    durationMin: dur || null,
    planId: session.planId || null,
    completed: true,
    sessionId: session.id || null,
    _original: session
  };
}

/**
 * Completed sessions on a given date.
 * @param {string} dateStr - YYYY-MM-DD format
 * @returns {Object[]}
 */
function getSessionsForDate(dateStr) {
  const sessions = Array.isArray(allSessions) ? allSessions : [];
  return sessions.filter(s => {
    const d = s?.date?.toDate ? s.date.toDate() : new Date(s?.date);
    return d && !isNaN(d.getTime()) && formatDate(d) === dateStr;
  });
}

/**
 * Unified events for a date: completed sessions (past/today) + planned schedule
 * entries (future). Planned entries already marked completed are dropped — the
 * session row represents that completion, so we don't show both.
 * @param {string} dateStr - YYYY-MM-DD format
 * @returns {CalendarEvent[]}
 */
function getCalendarEventsForDate(dateStr) {
  const completed = getSessionsForDate(dateStr).map(mapSessionToCalendarEvent);
  const planned = getPlansForDate(dateStr)
    .map(mapScheduleToCalendarEvent)
    .filter(e => !e.completed);
  return [...completed, ...planned];
}


// ========================================
// LOAD SCHEDULE DATA
// ========================================

async function loadSchedule() {
  try {
    if (typeof scheduleCollection !== 'undefined') {
      scheduleData = await getAllDocsForUser(scheduleCollection);
    } else {
      console.warn('scheduleCollection not defined, using empty array');
      scheduleData = [];
    }
    renderCalendar();
    if (typeof refreshDashboard === 'function') {
      refreshDashboard();
    }
  } catch (error) {
    console.error('Error loading schedule:', error);
    scheduleData = [];
    renderCalendar();
    if (typeof refreshDashboard === 'function') {
      refreshDashboard();
    }
  }
}

// ========================================
// CALENDAR VIEW INITIALIZATION
// ========================================

function setCalendarView() {
  renderCalendar();
}

// ========================================
// NAVIGATION
// ========================================

function navigateCalendar(direction) {
  currentDate.setMonth(currentDate.getMonth() + (direction === 'next' ? 1 : -1));

  // Wenn selectedDate nicht mehr im sichtbaren Monat
  const selectedDateObj = new Date(`${selectedDate}T12:00:00`);
  if (selectedDateObj.getMonth() !== currentDate.getMonth() ||
      selectedDateObj.getFullYear() !== currentDate.getFullYear()) {
    selectedDate = formatDate(new Date(currentDate.getFullYear(), currentDate.getMonth(), 1));
  }

  renderCalendar();

  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('light');
  }
}

function goToToday() {
  currentDate = new Date();
  selectedDate = formatDate(currentDate);
  renderCalendar();

  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('selection');
  }
}

// ========================================
// RENDER CALENDAR
// ========================================

function renderCalendar() {
  // Only render if plan calendar elements exist in DOM (tab may not be active)
  if (!document.getElementById('calendar-grid')) return;
  try {
    updateCalendarTitle();
    renderMonthGrid();
    renderDayAgenda();
  } catch (error) {
    console.error('Error rendering calendar:', error);
  }
}

function updateCalendarTitle() {
  const title = document.getElementById('calendar-title');
  if (!title) return;

  const monthName = t(`calendar.monthNames.${getMonthKey(currentDate.getMonth())}`);
  title.textContent = `${monthName} ${currentDate.getFullYear()}`;
}

function getMonthKey(monthIndex) {
  const keys = ['january', 'february', 'march', 'april', 'may', 'june',
                'july', 'august', 'september', 'october', 'november', 'december'];
  return keys[monthIndex];
}

// ========================================
// MONTH GRID
// ========================================

function renderMonthGrid() {
  const grid = document.getElementById('calendar-grid');
  if (!grid) return;

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();
  const today = formatDate(new Date());

  // First day (Monday-based)
  const firstDay = new Date(year, month, 1);
  let startDay = firstDay.getDay();
  startDay = startDay === 0 ? 6 : startDay - 1;

  const daysInMonth = new Date(year, month + 1, 0).getDate();

  grid.innerHTML = '';

  // Previous month padding
  const prevMonthDays = new Date(year, month, 0).getDate();
  for (let i = startDay - 1; i >= 0; i--) {
    const day = prevMonthDays - i;
    const date = new Date(year, month - 1, day);
    grid.appendChild(createDayCell(date, { otherMonth: true }));
  }

  // Current month days
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const dateStr = formatDate(date);
    const isToday = dateStr === today;
    const isSelected = dateStr === selectedDate;
    grid.appendChild(createDayCell(date, { isToday, isSelected }));
  }

  // Next month padding (fill to 42 cells for 6 rows)
  const totalCells = grid.children.length;
  const remaining = 42 - totalCells;
  for (let day = 1; day <= remaining; day++) {
    const date = new Date(year, month + 1, day);
    grid.appendChild(createDayCell(date, { otherMonth: true }));
  }
}

function createDayCell(date, options = {}) {
  const { otherMonth = false, isToday = false, isSelected = false } = options;
  const dateStr = formatDate(date);
  const events = getCalendarEventsForDate(dateStr);

  const cell = document.createElement('div');
  cell.className = 'plan-calendar-day';
  cell.setAttribute('data-date', dateStr);
  cell.setAttribute('role', 'gridcell');

  if (otherMonth) cell.classList.add('other-month');
  if (isToday) cell.classList.add('is-today');
  if (isSelected) cell.classList.add('is-selected');
  if (events.length > 0) cell.classList.add('has-events');

  // Day number
  const dayNum = document.createElement('span');
  dayNum.className = 'plan-calendar-day-number';
  dayNum.textContent = date.getDate();
  cell.appendChild(dayNum);

  // Event dots (max 3 unique types). Completed = filled, planned = ghost outline.
  if (events.length > 0) {
    const dotsContainer = document.createElement('div');
    dotsContainer.className = 'plan-calendar-dots';

    const byType = {};
    events.forEach(e => {
      if (!byType[e.type]) byType[e.type] = { type: e.type, completed: false };
      if (e.completed) byType[e.type].completed = true;
    });
    Object.keys(byType).slice(0, 3).forEach(key => {
      const { type, completed } = byType[key];
      const dot = document.createElement('span');
      dot.className = `plan-calendar-dot plan-calendar-dot-${type}` + (completed ? '' : ' is-planned');
      dotsContainer.appendChild(dot);
    });

    cell.appendChild(dotsContainer);
  }

  // Click handler
  if (!otherMonth) {
    cell.onclick = () => selectDay(dateStr);
    cell.setAttribute('tabindex', '0');
    cell.onkeydown = (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        selectDay(dateStr);
      }
    };
  }

  return cell;
}

// ========================================
// DAY AGENDA (Single Day View)
// ========================================

/**
 * Selects a day and updates the day agenda view
 */
function selectDay(dateStr) {
  selectedDate = dateStr;

  // Update grid selection
  document.querySelectorAll('.plan-calendar-day.is-selected')
    .forEach(el => el.classList.remove('is-selected'));

  const selectedCell = document.querySelector(`.plan-calendar-day[data-date="${dateStr}"]`);
  if (selectedCell) {
    selectedCell.classList.add('is-selected');
  }

  // Render day agenda
  renderDayAgenda();

  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('selection');
  }
}

/**
 * Renders the day agenda for the selected date
 */
function renderDayAgenda() {
  const container = document.getElementById('calendar-agenda-list');
  const titleEl = document.getElementById('agenda-list-title');
  if (!container) return;

  const date = new Date(`${selectedDate}T12:00:00`);
  const today = formatDate(new Date());
  const isToday = selectedDate === today;
  const isPast = selectedDate < today;
  const events = getCalendarEventsForDate(selectedDate);

  // Update title
  if (titleEl) {
    const dateLabel = formatAgendaDateLabel(date, isToday);
    titleEl.textContent = dateLabel;
  }

  // Empty state
  if (events.length === 0) {
    container.innerHTML = `
      <div class="calendar-agenda-empty">
        <span class="material-symbols-rounded">event_busy</span>
        <p>${t('calendar.noPlannedWorkouts')}</p>
      </div>
    `;
    return;
  }

  // Render events
  const eventRows = events.map(event => renderEventRow(event, isPast)).join('');

  container.innerHTML = `
    <div class="calendar-agenda-section ${isPast ? 'is-past' : ''} ${isToday ? 'is-today' : ''}" data-date="${selectedDate}">
      <div class="calendar-agenda-items">
        ${eventRows}
      </div>
    </div>
  `;
}

/**
 * Formats a date for the agenda section header
 * e.g. "Dienstag, 16. August" or "Do, 3. Maerz"
 */
function formatAgendaDateLabel(date, isToday) {
  if (typeof formatDateLongText === 'function') {
    return formatDateLongText(date, false);
  }
  // Fallback
  const dayIndex = date.getDay() === 0 ? 6 : date.getDay() - 1;
  const dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  const dayName = t(`calendar.dayNames.${dayKeys[dayIndex]}`);
  const monthName = t(`calendar.monthNames.${getMonthKey(date.getMonth())}`);
  return `${dayName}, ${date.getDate()}. ${monthName}`;
}

// ========================================
// CALENDAR EVENT ROW
// ========================================

function renderEventRow(event, isPast = false) {
  const typeColor = getEventColor(event);
  const typeLabel = getEventTypeLabel(event);
  const durationText = event.durationMin
    ? `${event.durationMin} ${t('common.minutes')}`
    : '';
  const timeText = event.startTime
    ? event.startTime
    : '';

  return `
    <div
      class="calendar-event-row ${event.completed ? 'is-completed' : ''} ${isPast ? 'is-past' : ''}"
      onclick="handleEventTap('${event.id}')"
      role="button"
      tabindex="0"
      data-source="${event.source}"
    >
      <div class="calendar-event-bar" style="background: ${typeColor};"></div>
      <div class="calendar-event-content">
        <span class="calendar-event-title">${event.title}</span>
        <div class="calendar-event-meta">
          ${timeText ? `<span class="calendar-event-time">${timeText}</span>` : ''}
          <span class="calendar-event-type" style="color: ${typeColor};">${typeLabel}</span>
          ${durationText ? `<span class="calendar-event-duration">${durationText}</span>` : ''}
        </div>
      </div>
      ${isLocalEvent(event) ? `
      <div class="calendar-event-actions">
        <button
          class="calendar-event-delete"
          onclick="event.stopPropagation(); removePlanFromDate('${event.id}')"
          aria-label="${t('common.delete')}"
        >
          <span class="material-symbols-rounded">delete</span>
        </button>
        <button
          class="calendar-event-play"
          onclick="event.stopPropagation(); startScheduledWorkout('${event.id}')"
          aria-label="${t('common.start')}"
        >
          <span class="material-symbols-rounded">play_arrow</span>
        </button>
      </div>` : ''}
    </div>
  `;
}

/**
 * Gets the display color for an event.
 * External calendar events can override with their own color.
 */
function getEventColor(event) {
  if (event.color) return event.color;
  return getPlanTypeColor(event.type);
}

/**
 * Gets the type label for an event.
 * External events show provider name.
 */
function getEventTypeLabel(event) {
  if (event.source === 'google') return 'Google';
  if (event.source === 'apple') return 'Apple';
  if (event.source === 'outlook') return 'Outlook';
  return t(`plan.types.${event.type}`) || event.type;
}

/**
 * Checks if event is local (plan/quick) vs external (synced)
 * Only local events can be started as workouts.
 */
function isLocalEvent(event) {
  return event.source === 'plan' || event.source === 'quick';
}

function handleEventTap(eventId) {
  // Completed session row → open the session detail (unified calendar: past).
  if (typeof eventId === 'string' && eventId.indexOf('session-') === 0) {
    const sid = eventId.slice('session-'.length);
    if (sid && typeof openSessionDetail === 'function') openSessionDetail(sid);
    return;
  }

  const entry = scheduleData.find(s => s.id === eventId);
  if (!entry) return;

  if (entry.planId && typeof viewPlanDetails === 'function') {
    viewPlanDetails(entry.planId);
  }
}

// ========================================
// QUICK ADD SHEET
// ========================================

let quickAddSelectedType = 'strength';

function openQuickAddSheet() {
  if (typeof openSheet !== 'function') {
    console.error('openSheet not available');
    return;
  }

  openSheet({
    title: t('calendar.quickEntry.title'),
    render: (container) => {
      container.innerHTML = `
        <div class="quick-add-form">
          <!-- Name Input -->
          <div class="quick-add-field">
            <label class="quick-add-label" for="quick-add-name">
              ${t('calendar.quickEntry.name')}
            </label>
            <input
              type="text"
              id="quick-add-name"
              class="quick-add-input"
              placeholder="${t('calendar.quickEntry.namePlaceholder')}"
              autocomplete="off"
            />
          </div>

          <!-- Type Selection -->
          <div class="quick-add-field">
            <label class="quick-add-label">${t('calendar.quickEntry.type')}</label>
            <div class="quick-add-type-buttons">
              <button
                type="button"
                class="type-select-btn active"
                data-type="strength"
                onclick="setQuickAddType('strength')"
              >
                <span class="material-symbols-rounded">fitness_center</span>
                <span>${t('plan.types.strength')}</span>
              </button>
              <button
                type="button"
                class="type-select-btn"
                data-type="cardio"
                onclick="setQuickAddType('cardio')"
              >
                <span class="material-symbols-rounded">directions_run</span>
                <span>${t('plan.types.cardio')}</span>
              </button>
              <button
                type="button"
                class="type-select-btn"
                data-type="recovery"
                onclick="setQuickAddType('recovery')"
              >
                <span class="material-symbols-rounded">self_improvement</span>
                <span>${t('plan.types.recovery')}</span>
              </button>
            </div>
          </div>

          <!-- Duration (Optional) -->
          <div class="quick-add-field">
            <label class="quick-add-label" for="quick-add-duration">
              ${t('calendar.quickEntry.duration')}
              <span class="quick-add-optional">(${t('common.optional')})</span>
            </label>
            <input
              type="number"
              id="quick-add-duration"
              class="quick-add-input"
              placeholder="45"
              min="1"
              max="300"
            />
          </div>

          <!-- Divider -->
          <div class="quick-add-divider">
            <span>${t('calendar.orSelectPlan')}</span>
          </div>

          <!-- Select Plan Button -->
          <button
            type="button"
            class="quick-add-plan-btn"
            onclick="openCalendarPlanPicker()"
          >
            <span class="material-symbols-rounded">assignment</span>
            <span>${t('calendar.addPlan')}</span>
            <span class="material-symbols-rounded">chevron_right</span>
          </button>

          <!-- Submit Button -->
          <button
            type="button"
            class="btn-primary quick-add-submit"
            onclick="saveQuickAddEntry()"
          >
            ${t('calendar.quickEntry.add')}
          </button>
        </div>
      `;

      // Reset type
      quickAddSelectedType = 'strength';

      // Focus name input after render
      setTimeout(() => {
        document.getElementById('quick-add-name')?.focus();
      }, 300);
    }
  });
}

function setQuickAddType(type) {
  quickAddSelectedType = type;

  document.querySelectorAll('.quick-add-type-buttons .type-select-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.type === type);
  });

  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('selection');
  }
}

async function saveQuickAddEntry() {
  const name = document.getElementById('quick-add-name')?.value.trim();
  const duration = parseInt(document.getElementById('quick-add-duration')?.value) || null;

  if (!name) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('calendar.quickEntry.nameRequired'));
    }
    return;
  }

  const entry = {
    planId: null,
    planName: name,
    planType: quickAddSelectedType,
    planDuration: duration || getDefaultDuration(quickAddSelectedType),
    date: selectedDate,
    completed: false,
    isQuickEntry: true,
    createdAt: new Date().toISOString()
  };

  try {
    await addDoc(scheduleCollection, entry);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', t('calendar.entryAdded'));
    }
    if (typeof closeSheet === 'function') {
      closeSheet();
    }
    await loadSchedule();
  } catch (error) {
    console.error('Error saving quick entry:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('calendar.saveError'));
    }
  }
}

function getDefaultDuration(type) {
  const defaults = { strength: 45, cardio: 30, recovery: 20 };
  return defaults[type] || 45;
}

// ========================================
// PLAN PICKER
// ========================================

function openCalendarPlanPicker() {
  if (typeof openPlanPickerSheet !== 'function') {
    console.error('Plan picker not available');
    return;
  }

  if (typeof closeSheet === 'function') {
    closeSheet();
  }

  openPlanPickerSheet((planId) => {
    addPlanToDateById(planId);
  });
}

async function addPlanToDateById(planId) {
  if (!planId) return;

  const plan = allPlans.find(p => p.id === planId);
  if (!plan) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('calendar.errors.notFound'));
    }
    return;
  }

  const scheduleEntry = {
    planId: planId,
    planName: plan.name,
    planType: plan.type,
    planDuration: plan.type === 'cardio' || plan.type === 'recovery'
      ? (plan.targetDurationMin || plan.targetDuration || plan.duration || 45)
      : (plan.duration || 45),
    date: selectedDate,
    completed: false,
    createdAt: new Date().toISOString()
  };

  try {
    await addDoc(scheduleCollection, scheduleEntry);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', t('calendar.entryAdded'));
    }
    await loadSchedule();
  } catch (error) {
    console.error('Error adding plan:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('calendar.saveError'));
    }
  }
}

// ========================================
// REMOVE/DELETE PLAN
// ========================================

async function removePlanFromDate(scheduleId) {
  if (!confirm(t('calendar.confirmRemove'))) return;

  try {
    await deleteDoc(scheduleCollection, scheduleId);
    await loadSchedule();
  } catch (error) {
    console.error('Error removing plan:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('calendar.saveError'));
    }
  }
}

// ========================================
// START WORKOUT
// ========================================

function startScheduledWorkout(scheduleId) {
  const scheduleEntry = scheduleData.find(s => s.id === scheduleId);
  if (!scheduleEntry) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('calendar.errors.notFound'));
    }
    return;
  }

  // Handle Quick Entries (no plan template)
  if (scheduleEntry.isQuickEntry || !scheduleEntry.planId) {
    startQuickEntrySession(scheduleEntry);
    return;
  }

  // Handle Recovery type
  if (scheduleEntry.planType === 'recovery' && typeof openAddRecoveryModal === 'function') {
    window.pendingScheduledEntry = scheduleEntry;
    openAddRecoveryModal(scheduleEntry.date);
    return;
  }

  // Handle regular plan-based workouts
  if (typeof startWorkoutFromPlan !== 'function') {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('calendar.errors.engineNotLoaded'));
    }
    return;
  }

  startWorkoutFromPlan(scheduleEntry.planId, scheduleEntry.date, scheduleEntry.id);
}

function startQuickEntrySession(scheduleEntry) {
  window.pendingScheduledEntry = scheduleEntry;

  const type = scheduleEntry.planType;

  if (type === 'cardio' && typeof openAddCardioModal === 'function') {
    openAddCardioModal(scheduleEntry.date);
    setTimeout(() => {
      const durationInput = document.getElementById('cardio-duration');
      if (durationInput && scheduleEntry.planDuration) {
        durationInput.value = scheduleEntry.planDuration;
      }
    }, 100);
    return;
  }

  if (type === 'recovery' && typeof openAddRecoveryModal === 'function') {
    openAddRecoveryModal(scheduleEntry.date);
    setTimeout(() => {
      const durationInput = document.getElementById('recovery-duration');
      if (durationInput && scheduleEntry.planDuration) {
        durationInput.value = scheduleEntry.planDuration;
      }
    }, 100);
    return;
  }

  if (type === 'strength' && typeof openAddStrengthModal === 'function') {
    openAddStrengthModal(scheduleEntry.date);
    setTimeout(() => {
      const nameInput = document.getElementById('strength-workout-name');
      const durationInput = document.getElementById('strength-duration');
      if (nameInput && scheduleEntry.planName) {
        nameInput.value = scheduleEntry.planName;
      }
      if (durationInput && scheduleEntry.planDuration) {
        durationInput.value = scheduleEntry.planDuration;
      }
    }, 100);
    return;
  }

  window.pendingScheduledEntry = null;
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', t('calendar.errors.modalNotAvailable'));
  }
}

// ========================================
// HELPER FUNCTIONS
// ========================================

function isValidDateString(dateStr) {
  if (!dateStr || typeof dateStr !== 'string') return false;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return false;
  const date = new Date(`${dateStr}T12:00:00`);
  return !isNaN(date.getTime());
}

function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function getPlanTypeColor(type) {
  const colors = {
    strength: 'var(--color-category-strength)',
    cardio: 'var(--color-category-cardio)',
    recovery: 'var(--color-category-recovery)',
    bodyweight: 'var(--color-category-bodyweight)',
    event: 'var(--accent-primary)',
    mixed: 'var(--accent-primary)'
  };
  return colors[type] || colors.mixed;
}

function getPlansForDate(dateStr) {
  return scheduleData.filter(item => item.date === dateStr);
}

// ========================================
// REAL-TIME LISTENER
// ========================================

function setupScheduleListener() {
  if (typeof onUserCollectionChange === 'function' && typeof scheduleCollection !== 'undefined') {
    onUserCollectionChange(scheduleCollection, (schedule) => {
      scheduleData = schedule;
      renderCalendar();
      if (typeof refreshDashboard === 'function') {
        refreshDashboard();
      }
    });
  }
}

// ========================================
// ACTIVITY CALENDAR (Dashboard Integration)
// ========================================

let calendarActivityDate = new Date();

function getCalendarSessionsByDateLocal(year, month) {
  if (typeof getDashboardSessionsByDate === 'function') {
    const sessions = Array.isArray(allSessions) ? allSessions : [];
    return getDashboardSessionsByDate(sessions, year, month);
  }
  const sessions = Array.isArray(allSessions) ? allSessions : [];
  const result = {};
  sessions.forEach(session => {
    const date = session?.date?.toDate ? session.date.toDate() : new Date(session?.date);
    if (!date || isNaN(date.getTime())) return;
    if (date.getFullYear() !== year || date.getMonth() !== month) return;
    const dateKey = formatDate(date);
    if (!result[dateKey]) result[dateKey] = [];
    result[dateKey].push(session);
  });
  return result;
}

// ========================================
// UNIFIED CALENDAR (Training tab)
// ========================================
// Mounts the calendar shell into the Training "Kalender" tab. One calendar:
// past = done (filled dots), future = planned (ghost dots), today = pivot.

function renderTrainingCalendar() {
  const mount = document.getElementById('training-calendar-mount');
  if (!mount) return;

  const dayShort = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
    .map(k => `<span>${t('calendar.dayNamesShort.' + k)}</span>`).join('');

  mount.innerHTML = `
    <div class="plan-calendar-widget-wrapper">
      <div class="calendar-month-section">
        <div class="dashboard-activity-month-nav">
          <button class="activity-nav-btn" onclick="navigateCalendar('prev')" aria-label="${t('dashboard.calendar.prevMonth')}">
            <span class="material-symbols-rounded">chevron_left</span>
          </button>
          <span class="activity-month-title" id="calendar-title"></span>
          <button class="activity-nav-btn" onclick="goToToday()" aria-label="Heute">
            <span class="material-symbols-rounded">today</span>
          </button>
          <button class="activity-nav-btn" onclick="navigateCalendar('next')" aria-label="${t('dashboard.calendar.nextMonth')}">
            <span class="material-symbols-rounded">chevron_right</span>
          </button>
        </div>
        <div class="plan-calendar-legend">
          <span class="cal-legend-item"><span class="cal-legend-dot completed"></span>Erledigt</span>
          <span class="cal-legend-item"><span class="cal-legend-dot planned"></span>Geplant</span>
        </div>
        <div class="plan-calendar-weekdays">${dayShort}</div>
        <div id="calendar-grid" class="plan-calendar-grid"></div>
      </div>
      <div class="calendar-agenda-container">
        <div class="calendar-agenda-list-header">
          <h3 class="calendar-agenda-list-title" id="agenda-list-title"></h3>
          <button class="agenda-add-btn" onclick="openQuickAddSheet()" aria-label="${t('dashboard.calendar.addTraining')}">
            <span class="material-symbols-rounded">add</span>
          </button>
        </div>
        <div id="calendar-agenda-list" class="calendar-agenda-list"></div>
      </div>
    </div>`;

  if (typeof loadSchedule === 'function' && (!Array.isArray(scheduleData) || scheduleData.length === 0)) {
    loadSchedule().then(() => { if (typeof renderCalendar === 'function') renderCalendar(); });
  } else if (typeof renderCalendar === 'function') {
    renderCalendar();
  }
}

// ========================================
// EXPOSE FUNCTIONS GLOBALLY
// ========================================

// ========================================
// COMPACT DASHBOARD CALENDAR (Home)
// ========================================
// Wochen-Strip mit Akkordeon-Ausklappung zum Monatsgrid + Wochen-/Monats-
// Navigation (Pfeile + Swipe). Wiederverwendet getCalendarEventsForDate
// (Sessions + Planung) und renderEventRow.

const DASH_CAL_DOW = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
let dashCalSelected = formatDate(new Date());
let dashCalExpanded = false;
let dashCalWeekStart = dashCalStartOfWeek(new Date());
let dashCalMonth = dashCalFirstOfMonth(new Date());

function dashCalStartOfWeek(date) {
  const d = new Date(date); d.setHours(0, 0, 0, 0);
  const wd = (d.getDay() + 6) % 7; // 0 = Monday
  d.setDate(d.getDate() - wd);
  return d;
}

function dashCalFirstOfMonth(date) {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function dashCalDateFromKey(ds) {
  return new Date(`${ds}T12:00:00`);
}

// Dots for a date: up to 3 unique types, filled = completed, ghost = planned.
function dashCalDotsHTML(ds) {
  const byType = {};
  getCalendarEventsForDate(ds).forEach(e => {
    if (!byType[e.type]) byType[e.type] = { type: e.type, completed: false };
    if (e.completed) byType[e.type].completed = true;
  });
  return Object.keys(byType).slice(0, 3).map(k =>
    `<span class="dash-cal-dot plan-calendar-dot-${byType[k].type}${byType[k].completed ? '' : ' is-planned'}"></span>`
  ).join('');
}

function dashCalBuildWeek(todayKey) {
  let html = '';
  for (let i = 0; i < 7; i++) {
    const d = new Date(dashCalWeekStart); d.setDate(d.getDate() + i);
    const ds = formatDate(d);
    html += `<button type="button" class="dash-cal-day${ds === todayKey ? ' is-today' : ''}${ds === dashCalSelected ? ' is-selected' : ''}" onclick="dashCalSelect('${ds}')">
      <span class="dash-cal-dow">${DASH_CAL_DOW[i]}</span>
      <span class="dash-cal-num">${d.getDate()}</span>
      <span class="dash-cal-dots">${dashCalDotsHTML(ds)}</span>
    </button>`;
  }
  return `<div class="dash-cal-strip">${html}</div>`;
}

function dashCalMonthCell(d, ds, todayKey, other) {
  return `<button type="button" class="dash-cal-mday${other ? ' is-other' : ''}${ds === todayKey ? ' is-today' : ''}${ds === dashCalSelected ? ' is-selected' : ''}" onclick="dashCalSelect('${ds}')">
    <span class="dash-cal-num">${d.getDate()}</span>
    <span class="dash-cal-dots">${dashCalDotsHTML(ds)}</span>
  </button>`;
}

function dashCalBuildMonth(todayKey) {
  const year = dashCalMonth.getFullYear();
  const month = dashCalMonth.getMonth();
  const lead = (new Date(year, month, 1).getDay() + 6) % 7; // Monday-based leading blanks
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const prevDays = new Date(year, month, 0).getDate();

  const head = DASH_CAL_DOW.map(x => `<span class="dash-cal-mhead">${x}</span>`).join('');
  let cells = '';
  for (let i = lead - 1; i >= 0; i--) {
    const d = new Date(year, month - 1, prevDays - i);
    cells += dashCalMonthCell(d, formatDate(d), todayKey, true);
  }
  for (let day = 1; day <= daysInMonth; day++) {
    const d = new Date(year, month, day);
    cells += dashCalMonthCell(d, formatDate(d), todayKey, false);
  }
  const trail = (7 - ((lead + daysInMonth) % 7)) % 7;
  for (let i = 1; i <= trail; i++) {
    const d = new Date(year, month + 1, i);
    cells += dashCalMonthCell(d, formatDate(d), todayKey, true);
  }
  return `<div class="dash-cal-month"><div class="dash-cal-mheadrow">${head}</div><div class="dash-cal-mgrid">${cells}</div></div>`;
}

function dashCalPeriodLabel() {
  if (dashCalExpanded) {
    const name = t(`calendar.monthNames.${getMonthKey(dashCalMonth.getMonth())}`) || '';
    return `${name} ${dashCalMonth.getFullYear()}`.trim();
  }
  const e = new Date(dashCalWeekStart); e.setDate(e.getDate() + 6);
  return `${dashCalWeekStart.getDate()}.${dashCalWeekStart.getMonth() + 1}. – ${e.getDate()}.${e.getMonth() + 1}.`;
}

function renderDashboardCalendar() {
  const container = document.getElementById('dashboard-calendar');
  if (!container) return;

  const todayKey = formatDate(new Date());
  const grid = dashCalExpanded ? dashCalBuildMonth(todayKey) : dashCalBuildWeek(todayKey);

  const selEvents = getCalendarEventsForDate(dashCalSelected);
  const isPast = dashCalSelected < todayKey;
  const agenda = selEvents.length
    ? selEvents.map(e => renderEventRow(e, isPast)).join('')
    : `<div class="dash-cal-empty"><span class="material-symbols-rounded">event_available</span>${t('calendar.noPlannedWorkouts') || 'Nichts geplant'}</div>`;

  container.innerHTML = `
    <div class="dash-cal-card">
      <div class="dash-cal-head">
        <span class="dash-cal-title"><span class="material-symbols-rounded">calendar_month</span>${t('nav.calendar') || 'Kalender'}</span>
        <div class="dash-cal-head-actions">
          <button type="button" class="dash-cal-add" onclick="openQuickAddSheet()" aria-label="${t('dashboard.calendar.addTraining') || 'Training planen'}"><span class="material-symbols-rounded">add</span></button>
          <button type="button" class="dash-cal-toggle${dashCalExpanded ? ' is-expanded' : ''}" onclick="dashCalToggleExpand()" aria-label="${dashCalExpanded ? 'Monat einklappen' : 'Monat ausklappen'}"><span class="material-symbols-rounded">expand_more</span></button>
        </div>
      </div>
      <div class="dash-cal-nav">
        <button type="button" class="dash-cal-nav-btn" onclick="dashCalShift(-1)" aria-label="Zurück"><span class="material-symbols-rounded">chevron_left</span></button>
        <span class="dash-cal-period">${dashCalPeriodLabel()}</span>
        <button type="button" class="dash-cal-nav-btn" onclick="dashCalShift(1)" aria-label="Weiter"><span class="material-symbols-rounded">chevron_right</span></button>
      </div>
      <div class="dash-cal-body${dashCalExpanded ? ' is-expanded' : ''}" id="dash-cal-body">${grid}</div>
      <div class="dash-cal-agenda">${agenda}</div>
    </div>`;

  dashCalBindSwipe();
}

function dashCalSelect(ds) {
  dashCalSelected = ds;
  // Quick-Add (openQuickAddSheet/saveQuickAddEntry) writes to the shared
  // `selectedDate`. Sync it so a training planned from the dashboard lands on the
  // day the user actually tapped, not always today.
  selectedDate = ds;
  // Keep the visible week & month anchored on the picked day
  const sd = dashCalDateFromKey(ds);
  dashCalWeekStart = dashCalStartOfWeek(sd);
  dashCalMonth = dashCalFirstOfMonth(sd);
  renderDashboardCalendar();
}

// Prev/next: shifts the month when expanded, otherwise the week.
function dashCalShift(dir) {
  if (dashCalExpanded) {
    dashCalMonth = new Date(dashCalMonth.getFullYear(), dashCalMonth.getMonth() + dir, 1);
  } else {
    const ws = new Date(dashCalWeekStart);
    ws.setDate(ws.getDate() + dir * 7);
    dashCalWeekStart = ws;
  }
  renderDashboardCalendar();
}

// Accordion toggle with a height animation. On collapse we keep the month
// content during the height transition, then swap to the week strip.
function dashCalToggleExpand() {
  dashCalExpanded = !dashCalExpanded;
  const todayKey = formatDate(new Date());
  const sd = dashCalDateFromKey(dashCalSelected);
  if (dashCalExpanded) dashCalMonth = dashCalFirstOfMonth(sd);
  else dashCalWeekStart = dashCalStartOfWeek(sd);

  const body = document.getElementById('dash-cal-body');
  const period = document.querySelector('#dashboard-calendar .dash-cal-period');
  const toggle = document.querySelector('#dashboard-calendar .dash-cal-toggle');
  if (!body) { renderDashboardCalendar(); return; }
  if (period) period.textContent = dashCalPeriodLabel();
  if (toggle) toggle.classList.toggle('is-expanded', dashCalExpanded);

  if (dashCalExpanded) {
    body.innerHTML = dashCalBuildMonth(todayKey);
    body.classList.add('is-expanded');
    dashCalBindSwipe();
  } else {
    body.classList.remove('is-expanded'); // animate height down with month still inside
    setTimeout(() => {
      body.innerHTML = dashCalBuildWeek(todayKey);
      dashCalBindSwipe();
    }, 300);
  }
}

function dashCalBindSwipe() {
  if (typeof initSwipeGesture !== 'function') return;
  initSwipeGesture({
    containerId: 'dash-cal-body',
    tabs: ['prev', 'current', 'next'],
    getCurrentTab: () => 'current',
    onSwipe: (tab) => { if (tab === 'next') dashCalShift(1); else if (tab === 'prev') dashCalShift(-1); }
  });
}

window.renderDashboardCalendar = renderDashboardCalendar;
window.dashCalSelect = dashCalSelect;
window.dashCalShift = dashCalShift;
window.dashCalToggleExpand = dashCalToggleExpand;
window.renderTrainingCalendar = renderTrainingCalendar;
window.startScheduledWorkout = startScheduledWorkout;
window.goToToday = goToToday;
window.navigateCalendar = navigateCalendar;
window.openQuickAddSheet = openQuickAddSheet;
window.setQuickAddType = setQuickAddType;
window.saveQuickAddEntry = saveQuickAddEntry;
window.openCalendarPlanPicker = openCalendarPlanPicker;
window.handleEventTap = handleEventTap;
window.removePlanFromDate = removePlanFromDate;
window.renderCalendar = renderCalendar;
window.loadSchedule = loadSchedule;
window.setupScheduleListener = setupScheduleListener;

