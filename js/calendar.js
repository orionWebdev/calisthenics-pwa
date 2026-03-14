// ========================================
// CALENDAR MANAGEMENT - Month Grid + Agenda List
// ========================================

// Calendar State
let currentDate = new Date();
let scheduleData = []; // Alle geplanten Trainings
let selectedDate = formatDate(new Date()); // Aktuell ausgewaehlter Tag

// Demo User ID (spaeter wird das durch Firebase Auth ersetzt)
const CURRENT_USER_ID = 'demo-user-123';

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
 * Gets CalendarEvents for a specific date
 * @param {string} dateStr - YYYY-MM-DD format
 * @returns {CalendarEvent[]}
 */
function getCalendarEventsForDate(dateStr) {
  const plans = getPlansForDate(dateStr);
  return plans.map(mapScheduleToCalendarEvent);
}


// ========================================
// LOAD SCHEDULE DATA
// ========================================

async function loadSchedule() {
  try {
    if (typeof scheduleCollection !== 'undefined') {
      scheduleData = await getAllDocs(scheduleCollection);
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

  // Event dots (max 3 unique types)
  if (events.length > 0) {
    const dotsContainer = document.createElement('div');
    dotsContainer.className = 'plan-calendar-dots';

    const uniqueTypes = [...new Set(events.map(e => e.type))].slice(0, 3);
    uniqueTypes.forEach(type => {
      const dot = document.createElement('span');
      dot.className = `plan-calendar-dot plan-calendar-dot-${type}`;
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
    userId: CURRENT_USER_ID,
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
    userId: CURRENT_USER_ID,
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
  return scheduleData.filter(item =>
    item.date === dateStr &&
    item.userId === CURRENT_USER_ID
  );
}

// ========================================
// REAL-TIME LISTENER
// ========================================

function setupScheduleListener() {
  if (typeof onCollectionChange === 'function' && typeof scheduleCollection !== 'undefined') {
    onCollectionChange(scheduleCollection, (schedule) => {
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
// EXPOSE FUNCTIONS GLOBALLY
// ========================================

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

console.log('Calendar module loaded!');
