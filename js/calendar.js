// ========================================
// CALENDAR MANAGEMENT
// ========================================

// Calendar State
let currentCalendarView = 'month'; // 'month' or 'week' - Default: month
let currentDate = new Date();
let scheduleData = []; // Alle geplanten Trainings
let selectedDateForPlan = null;
let currentDayDetailDate = null;

// Demo User ID (später wird das durch Firebase Auth ersetzt)
const CURRENT_USER_ID = 'demo-user-123';

// Month/Day Names
const monthNames = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
                    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
const dayNames = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];

// Note: workoutTypeNames is defined in plans.js and shared globally

// ========================================
// LOAD SCHEDULE DATA
// ========================================

async function loadSchedule() {
  try {
    // Später filtern wir hier nach userId
    // Für jetzt laden wir alle (da wir noch keine Auth haben)
    if (typeof scheduleCollection !== 'undefined') {
      scheduleData = await getAllDocs(scheduleCollection);
    } else {
      console.warn('⚠️ scheduleCollection not defined, using empty array');
      scheduleData = [];
    }
    setCalendarView(currentCalendarView);
  } catch (error) {
    console.error('Error loading schedule:', error);
    // Render calendar anyway with empty data
    scheduleData = [];
    setCalendarView(currentCalendarView);
  }
}

// ========================================
// CALENDAR VIEW SWITCHING
// ========================================

function setCalendarView(view) {
  currentCalendarView = view;
  
  // Update buttons
  document.querySelectorAll('.calendar-segmented .segmented-btn').forEach(btn => {
    btn.classList.remove('active');
  });
  const activeBtn = document.querySelector(`.calendar-segmented [data-view="${view}"]`);
  if (activeBtn) activeBtn.classList.add('active');
  
  // Show/hide views
  document.getElementById('calendar-month-view').classList.toggle('active', view === 'month');
  document.getElementById('calendar-week-view').classList.toggle('active', view === 'week');
  
  renderCalendar();
}

// ========================================
// NAVIGATION
// ========================================

function navigateCalendar(direction) {
  if (currentCalendarView === 'month') {
    currentDate.setMonth(currentDate.getMonth() + (direction === 'next' ? 1 : -1));
  } else {
    currentDate.setDate(currentDate.getDate() + (direction === 'next' ? 7 : -7));
  }
  renderCalendar();
}

function goToToday() {
  currentDate = new Date();
  renderCalendar();
}

function openCalendarQuickPlan() {
  const todayKey = formatDate(new Date());
  openDayDetailModal(todayKey, true);
}

// ========================================
// RENDER CALENDAR
// ========================================

function renderCalendar() {
  try {
    updateCalendarTitle();

    if (currentCalendarView === 'month') {
      renderMonthView();
    } else {
      renderWeekView();
    }
  } catch (error) {
    console.error('Error rendering calendar:', error);
  }
}

function updateCalendarTitle() {
  const title = document.getElementById('calendar-title');

  if (!title) {
    console.warn('⚠️ calendar-title element not found');
    return;
  }

  if (currentCalendarView === 'month') {
    title.textContent = `${monthNames[currentDate.getMonth()]} ${currentDate.getFullYear()}`;
  } else {
    const weekStart = getWeekStart(currentDate);
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);

    title.textContent = `${weekStart.getDate()}. - ${weekEnd.getDate()}. ${monthNames[weekEnd.getMonth()]} ${weekEnd.getFullYear()}`;
  }
}

// ========================================
// MONTH VIEW
// ========================================

function renderMonthView() {
  const grid = document.getElementById('calendar-grid');

  if (!grid) {
    console.warn('⚠️ calendar-grid element not found');
    return;
  }

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();
  
  // First day of month (0 = Sunday, 6 = Saturday)
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  
  // Adjust to Monday-based week (1 = Monday, 0 = Sunday)
  let startDay = firstDay.getDay();
  startDay = startDay === 0 ? 6 : startDay - 1; // Convert to Monday = 0
  
  const daysInMonth = lastDay.getDate();
  const today = new Date();
  
  grid.innerHTML = '';
  
  // Previous month's days
  const prevMonthDays = new Date(year, month, 0).getDate();
  for (let i = startDay - 1; i >= 0; i--) {
    const day = prevMonthDays - i;
    const date = new Date(year, month - 1, day);
    grid.appendChild(createDayCell(date, true));
  }
  
  // Current month's days
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const isToday = date.toDateString() === today.toDateString();
    grid.appendChild(createDayCell(date, false, isToday));
  }
  
  // Next month's days to fill grid
  const totalCells = grid.children.length;
  const remainingCells = 42 - totalCells; // 6 rows × 7 days
  for (let day = 1; day <= remainingCells; day++) {
    const date = new Date(year, month + 1, day);
    grid.appendChild(createDayCell(date, true));
  }
}

function createDayCell(date, otherMonth = false, isToday = false) {
  const cell = document.createElement('div');
  cell.className = 'calendar-day';

  if (otherMonth) cell.classList.add('other-month');
  if (isToday) cell.classList.add('today');

  // Get plans for this day
  const dateStr = formatDate(date);
  const dayPlans = getPlansForDate(dateStr);

  if (dayPlans.length > 0) {
    cell.classList.add('has-plan');
  }

  cell.innerHTML = `
    <div class="calendar-day-number">${date.getDate()}</div>
    <div class="calendar-day-plans">
      ${dayPlans.map(plan => `
        <div class="calendar-plan calendar-plan-${plan.planType || 'mixed'}" title="${plan.planName} (${plan.planDuration || 45} Min)">
        </div>
      `).join('')}
    </div>
  `;

  // Click to open day detail modal
  if (!otherMonth) {
    cell.onclick = () => openDayDetailModal(dateStr);
  }

  return cell;
}

// ========================================
// WEEK VIEW
// ========================================

function renderWeekView() {
  const weekGrid = document.getElementById('week-grid');

  if (!weekGrid) {
    console.warn('⚠️ week-grid element not found');
    return;
  }

  const weekStart = getWeekStart(currentDate);
  const today = new Date();
  today.setHours(0, 0, 0, 0); // Reset time for accurate comparison

  weekGrid.innerHTML = '';

  for (let i = 0; i < 7; i++) {
    const date = new Date(weekStart);
    date.setDate(date.getDate() + i);
    date.setHours(0, 0, 0, 0); // Reset time for accurate comparison

    const isToday = date.toDateString() === today.toDateString();
    const isPast = date < today;
    const dateStr = formatDate(date);
    const dayPlans = getPlansForDate(dateStr);

    const card = document.createElement('div');
    card.className = 'week-day-card';
    if (isToday) card.classList.add('today');
    if (isPast && !isToday) card.classList.add('past');
    if (dayPlans.length > 0) card.classList.add('has-plan');

    card.innerHTML = `
      <div class="flex items-center justify-between mb-3">
        <div>
          <div class="text-sm ${isToday ? 'text-pink-400 font-bold' : 'text-gray-400'}">${dayNames[i]}</div>
          <div class="text-xl font-bold ${isToday ? 'text-pink-500' : ''}">${date.getDate()}. ${monthNames[date.getMonth()]}</div>
        </div>
        <button
          onclick="openDayDetailModal('${dateStr}', true)"
          class="bg-gradient-to-r from-pink-600 to-pink-700 hover:from-pink-500 hover:to-pink-600 px-3 py-2 rounded-lg text-sm transition-all flex items-center gap-1"
        >
          <span class="material-symbols-rounded" style="font-size: 16px;">add</span>
          <span class="hidden sm:inline">Plan</span>
        </button>
      </div>

      <div class="space-y-2">
        ${dayPlans.length === 0 ?
          '<p class="text-gray-500 text-sm italic">Kein Training geplant</p>' :
          dayPlans.map(plan => `
            <div class="bg-gray-700 rounded-lg p-3 flex items-center justify-between cursor-pointer hover:bg-gray-600 transition-colors" onclick="viewCalendarPlanDetails('${plan.id}')">
              <div class="flex-1">
                <div class="font-semibold">${plan.planName}</div>
                <div class="flex items-center gap-2 mt-1">
                  <span class="text-xs px-2 py-0.5 rounded" style="background: color-mix(in srgb, ${getPlanTypeColor(plan.planType)} 20%, transparent); color: ${getPlanTypeColor(plan.planType)};">
                    ${workoutTypeNames[plan.planType] || plan.planType}
                  </span>
                  <span class="text-xs text-gray-400">${plan.planDuration || 45} Min</span>
                </div>
              </div>
              <div class="flex items-center gap-2 ml-2">
                <button
                  onclick="event.stopPropagation(); startScheduledWorkout('${plan.id}')"
                  class="calendar-start-btn"
                  title="Workout starten"
                >
                  <span class="material-symbols-rounded" style="font-size: 20px;">play_arrow</span>
                </button>
                <button
                  onclick="event.stopPropagation(); removePlanFromDate('${plan.id}')"
                  class="text-red-400 hover:text-red-300 transition-colors"
                  title="Training entfernen"
                >
                  <span class="material-symbols-rounded" style="font-size: 20px;">delete</span>
                </button>
              </div>
            </div>
          `).join('')
        }
      </div>
    `;

    weekGrid.appendChild(card);
  }

  // Auto-scroll to today's card on initial load
  scrollToTodayCard();
}

// Scroll to today's card in week view
function scrollToTodayCard() {
  const weekGrid = document.getElementById('week-grid');
  if (!weekGrid) return;

  const todayCard = weekGrid.querySelector('.week-day-card.today');
  if (todayCard) {
    setTimeout(() => {
      todayCard.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
        inline: 'center'
      });
    }, 100);
  }
}

function getWeekStart(date) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day; // Monday as start
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

// ========================================
// ADD/REMOVE PLANS
// ========================================

function openAddPlanPanel(dateStr) {
  const targetDate = dateStr || currentDayDetailDate;
  if (!isValidDateString(targetDate)) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Ungueltiges Datum. Bitte Tag erneut waehlen.');
    }
    return;
  }

  selectedDateForPlan = targetDate;
  ensureDayDetailModalOpen(targetDate);

  const date = new Date(`${targetDate}T12:00:00`);
  const formatted = `${date.getDate()}. ${monthNames[date.getMonth()]} ${date.getFullYear()}`;

  document.getElementById('selected-date-display').textContent = formatted;
  document.getElementById('add-plan-panel').classList.remove('hidden');
}

function closeAddPlanPanel() {
  document.getElementById('add-plan-panel').classList.add('hidden');
  selectedDateForPlan = null;
}

// Open Plan Picker Bottom Sheet (replaces dropdown)
function openCalendarPlanPicker() {
  if (typeof openPlanPickerSheet !== 'function') {
    console.error('Plan picker not available');
    return;
  }

  openPlanPickerSheet((planId) => {
    addPlanToDateById(planId);
  });
}

async function addPlanToDateById(planId) {
  if (!planId) return;

  if (!selectedDateForPlan && currentDayDetailDate) {
    selectedDateForPlan = currentDayDetailDate;
  }

  if (!isValidDateString(selectedDateForPlan)) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Bitte waehle einen gueltigen Tag.');
    }
    return;
  }

  const plan = allPlans.find(p => p.id === planId);
  if (!plan) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Plan nicht gefunden.');
    }
    return;
  }

  const scheduleEntry = {
    userId: CURRENT_USER_ID,
    planId: planId,
    planName: plan.name,
    planType: plan.type,
    planDuration: plan.duration || 45,
    date: selectedDateForPlan,
    completed: false,
    createdAt: new Date().toISOString()
  };

  try {
    await addDoc(scheduleCollection, scheduleEntry);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', 'Plan zum Kalender hinzugefuegt.');
    }
    closeAddPlanPanel();
    await loadSchedule();
  } catch (error) {
    console.error('Error adding plan:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Hinzufuegen.');
    }
  }
}

// ========================================
// QUICK ENTRY (No Plan Template)
// ========================================

function openQuickEntryModal() {
  const modal = document.getElementById('calendar-quick-entry-modal');
  if (!modal) return;

  // Reset form
  document.getElementById('quick-entry-name').value = '';
  document.getElementById('quick-entry-duration').value = '';
  setQuickEntryType('strength');

  modal.classList.add('active');
  setTimeout(() => document.getElementById('quick-entry-name').focus(), 100);
}

function closeQuickEntryModal() {
  document.getElementById('calendar-quick-entry-modal').classList.remove('active');
}

function setQuickEntryType(type) {
  document.getElementById('quick-entry-type').value = type;

  document.querySelectorAll('#calendar-quick-entry-modal .type-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.type === type);
  });

  // Show/hide duration field based on type
  const durationSection = document.getElementById('quick-entry-duration-section');
  if (durationSection) {
    durationSection.style.display = type === 'strength' ? 'none' : '';
  }
}

async function saveQuickEntry() {
  const name = document.getElementById('quick-entry-name').value.trim();
  const type = document.getElementById('quick-entry-type').value;
  const duration = parseInt(document.getElementById('quick-entry-duration').value) || (type === 'cardio' ? 30 : type === 'recovery' ? 20 : 45);

  if (!name) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', t('calendar.quickEntry.nameRequired'));
    }
    return;
  }

  if (!selectedDateForPlan && currentDayDetailDate) {
    selectedDateForPlan = currentDayDetailDate;
  }

  if (!isValidDateString(selectedDateForPlan)) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Bitte waehle einen gueltigen Tag.');
    }
    return;
  }

  const scheduleEntry = {
    userId: CURRENT_USER_ID,
    planId: null, // No plan template
    planName: name,
    planType: type,
    planDuration: duration,
    date: selectedDateForPlan,
    completed: false,
    isQuickEntry: true, // Mark as quick entry
    createdAt: new Date().toISOString()
  };

  try {
    await addDoc(scheduleCollection, scheduleEntry);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', 'Training hinzugefuegt.');
    }
    closeQuickEntryModal();
    closeAddPlanPanel();
    await loadSchedule();

    // Refresh day detail modal if open
    if (currentDayDetailDate) {
      openDayDetailModal(currentDayDetailDate);
    }
  } catch (error) {
    console.error('Error saving quick entry:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Speichern.');
    }
  }
}


async function removePlanFromDate(scheduleId) {
  if (!confirm('Plan wirklich entfernen?')) return;

  try {
    await deleteDoc(scheduleCollection, scheduleId);
    console.log('✅ Plan removed from calendar!');
    await loadSchedule(); // Reload
  } catch (error) {
    console.error('Error removing plan:', error);
    if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Fehler beim Entfernen.');
  }
  }
}

function viewCalendarPlanDetails(scheduleId) {
  // Find the schedule entry
  const scheduleEntry = scheduleData.find(s => s.id === scheduleId);
  if (!scheduleEntry) return;

  // Find the actual plan
  const plan = allPlans.find(p => p.id === scheduleEntry.planId);

  if (!plan) {
    if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Plan nicht gefunden.');
  }
    return;
  }

  // Use the existing viewPlanDetails function from plans.js
  if (typeof viewPlanDetails === 'function') {
    viewPlanDetails(plan.id);
  } else {
    // Fallback: show basic info
    alert(`Plan: ${plan.name}\nTyp: ${workoutTypeNames[plan.type]}\nDauer: ${plan.duration} Min\nDatum: ${scheduleEntry.date}`);
  }
}

// ========================================
// HELPER FUNCTIONS
// ========================================

function ensureDayDetailModalOpen(dateStr) {
  const modal = document.getElementById('day-detail-modal');
  if (!modal) return;
  if (!modal.classList.contains('active')) {
    openDayDetailModal(dateStr);
  }
}

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
    mobility: '#22c55e',
    recovery: 'var(--color-category-recovery)',
    skill: '#a855f7',
    hiit: '#f97316',
    mixed: '#db2777'
  };
  return colors[type] || colors.mixed;
}

function getPlansForDate(dateStr) {
  return scheduleData.filter(item => 
    item.date === dateStr && 
    item.userId === CURRENT_USER_ID // Multi-user ready!
  );
}

function startScheduledWorkout(scheduleId) {
  const scheduleEntry = scheduleData.find(s => s.id === scheduleId);
  if (!scheduleEntry) {
    if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Training nicht gefunden');
  }
    return;
  }

  if (scheduleEntry.planType === 'recovery' && typeof openAddRecoveryModal === 'function') {
    if (document.getElementById('day-detail-modal')?.classList.contains('active')) {
      closeDayDetailModal();
    }
    openAddRecoveryModal(scheduleEntry.date);
    return;
  }

  if (typeof startWorkoutFromPlan !== 'function') {
    if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Workout-Engine nicht geladen');
  }
    return;
  }

  if (document.getElementById('day-detail-modal')?.classList.contains('active')) {
    closeDayDetailModal();
  }

  startWorkoutFromPlan(scheduleEntry.planId, scheduleEntry.date, scheduleEntry.id);
}

// ========================================
// REAL-TIME LISTENER
// ========================================

function setupScheduleListener() {
  onCollectionChange(scheduleCollection, (schedule) => {
    scheduleData = schedule;
    renderCalendar();
  });
}

// ========================================
// DAY DETAIL MODAL
// ========================================

function openDayDetailModal(dateStr, openAddPanel = false) {
  currentDayDetailDate = dateStr;
  selectedDateForPlan = dateStr;
  const date = new Date(`${dateStr}T12:00:00`);
  const dayPlans = getPlansForDate(dateStr);

  // Update modal title
  document.getElementById('day-detail-title').textContent = `Trainings am ${dayNames[date.getDay() === 0 ? 6 : date.getDay() - 1]}`;
  document.getElementById('day-detail-date').textContent = `${date.getDate()}. ${monthNames[date.getMonth()]} ${date.getFullYear()}`;

  // Render plans
  const container = document.getElementById('day-detail-plans');

  if (dayPlans.length === 0) {
    container.innerHTML = `
      <div class="text-center py-8 text-gray-400">
        <span class="material-symbols-rounded" style="font-size: 48px; display: block; margin: 0 auto 1rem;">event_busy</span>
        <p>Keine Trainings an diesem Tag geplant</p>
      </div>
    `;
  } else {
    container.innerHTML = dayPlans.map(plan => `
      <div class="bg-gray-700 rounded-lg p-4 flex items-center justify-between cursor-pointer hover:bg-gray-600 transition-colors" onclick="viewCalendarPlanDetails('${plan.id}')">
        <div class="flex-1">
          <div class="font-semibold text-lg mb-1">${plan.planName}</div>
          <div class="flex items-center gap-3">
            <span class="text-xs px-2 py-1 rounded" style="background: color-mix(in srgb, ${getPlanTypeColor(plan.planType)} 25%, transparent); color: ${getPlanTypeColor(plan.planType)};">
              ${workoutTypeNames[plan.planType] || plan.planType}
            </span>
            <span class="text-xs text-gray-400 flex items-center gap-1">
              <span class="material-symbols-rounded" style="font-size: 14px;">schedule</span>
              ${plan.planDuration || 45} Min
            </span>
          </div>
        </div>
        <div class="flex items-center gap-2 ml-3">
          <button
            onclick="event.stopPropagation(); startScheduledWorkout('${plan.id}')"
            class="calendar-start-btn"
            title="Workout starten"
          >
            <span class="material-symbols-rounded" style="font-size: 20px;">play_arrow</span>
          </button>
          <button
            onclick="event.stopPropagation(); removePlanFromDayDetail('${plan.id}')"
            class="text-red-400 hover:text-red-300 hover:bg-red-400/10 transition-all p-2 rounded-lg"
            title="Training entfernen"
          >
            <span class="material-symbols-rounded" style="font-size: 24px;">delete</span>
          </button>
        </div>
      </div>
    `).join('');
  }

  closeAddPlanPanel();

  // Show modal
  document.getElementById('day-detail-modal').classList.add('active');

  if (openAddPanel) {
    openAddPlanPanel(dateStr);
  }
}


function closeDayDetailModal() {
  document.getElementById('day-detail-modal').classList.remove('active');
  currentDayDetailDate = null;
  selectedDateForPlan = null;
  closeAddPlanPanel();
}


function openAddPlanFromDayDetail() {
  if (currentDayDetailDate) {
    openAddPlanPanel(currentDayDetailDate);
  }
}


async function removePlanFromDayDetail(scheduleId) {
  if (!confirm('Training wirklich von diesem Tag entfernen?')) return;

  try {
    await deleteDoc(scheduleCollection, scheduleId);
    console.log('✅ Plan removed from day!');

    // Reload schedule and refresh modal
    await loadSchedule();

    // Refresh modal if still open
    if (currentDayDetailDate) {
      openDayDetailModal(currentDayDetailDate);
    }
  } catch (error) {
    console.error('Error removing plan:', error);
    if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Fehler beim Entfernen.');
  }
  }
}

// Close modal on escape key
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    closeDayDetailModal();
  }
});

// Close modal on outside click
document.addEventListener('click', (e) => {
  const modal = document.getElementById('day-detail-modal');
  if (e.target === modal) {
    closeDayDetailModal();
  }
});

console.log('📅 Calendar module loaded!');
