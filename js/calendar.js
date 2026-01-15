// ========================================
// CALENDAR MANAGEMENT
// ========================================

// Calendar State
let currentCalendarView = 'week'; // 'month' or 'week' - Default: week
let currentDate = new Date();
let scheduleData = []; // Alle geplanten Trainings
let selectedDateForPlan = null;

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
    renderCalendar();
  } catch (error) {
    console.error('Error loading schedule:', error);
    // Render calendar anyway with empty data
    scheduleData = [];
    renderCalendar();
  }
}

// ========================================
// CALENDAR VIEW SWITCHING
// ========================================

function setCalendarView(view) {
  currentCalendarView = view;
  
  // Update buttons
  document.querySelectorAll('.calendar-view-btn').forEach(btn => {
    btn.classList.remove('active');
  });
  document.querySelector(`[data-view="${view}"]`).classList.add('active');
  
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
        <div class="calendar-plan calendar-plan-${plan.planType || 'mixed'}" onclick="event.stopPropagation(); viewCalendarPlanDetails('${plan.id}');" title="${plan.planName} (${plan.planDuration || 45} Min)">
          <span>${plan.planName}</span>
          <span class="calendar-plan-remove" onclick="event.stopPropagation(); removePlanFromDate('${plan.id}')">✕</span>
        </div>
      `).join('')}
    </div>
  `;
  
  // Click to add plan
  if (!otherMonth) {
    cell.onclick = () => openAddPlanPanel(dateStr);
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
          onclick="openAddPlanPanel('${dateStr}')"
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
                  <span class="text-xs px-2 py-0.5 rounded" style="background: ${getPlanTypeColor(plan.planType)}20; color: ${getPlanTypeColor(plan.planType)};">
                    ${workoutTypeNames[plan.planType] || plan.planType}
                  </span>
                  <span class="text-xs text-gray-400">${plan.planDuration || 45} Min</span>
                </div>
              </div>
              <button
                onclick="event.stopPropagation(); removePlanFromDate('${plan.id}')"
                class="text-red-400 hover:text-red-300 transition-colors ml-2"
              >
                <span class="material-symbols-rounded" style="font-size: 20px;">delete</span>
              </button>
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
  selectedDateForPlan = dateStr;

  const date = new Date(dateStr);
  const formatted = `${date.getDate()}. ${monthNames[date.getMonth()]} ${date.getFullYear()}`;

  document.getElementById('selected-date-display').textContent = formatted;
  document.getElementById('add-plan-panel').classList.remove('hidden');

  // Populate plan dropdown with real plans
  populatePlanSelect();
}

function closeAddPlanPanel() {
  document.getElementById('add-plan-panel').classList.add('hidden');
  selectedDateForPlan = null;
}

function populatePlanSelect() {
  const select = document.getElementById('plan-select');

  // Clear existing options except the first one
  select.innerHTML = '<option value="">Wähle einen Plan...</option>';

  // Check if allPlans is available (from plans.js)
  if (typeof allPlans === 'undefined' || !allPlans || allPlans.length === 0) {
    select.innerHTML += '<option value="" disabled>Keine Pläne verfügbar - Erstelle zuerst einen Plan</option>';
    return;
  }

  // Add real plans from the database
  allPlans.forEach(plan => {
    const option = document.createElement('option');
    option.value = plan.id;
    option.textContent = `${plan.name} (${workoutTypeNames[plan.type] || plan.type}, ${plan.duration || 45} Min)`;
    select.appendChild(option);
  });
}

async function addPlanToDate() {
  const planId = document.getElementById('plan-select').value;

  if (!planId || !selectedDateForPlan) {
    alert('Bitte wähle einen Plan!');
    return;
  }

  // Get plan details from allPlans array
  const plan = allPlans.find(p => p.id === planId);

  if (!plan) {
    alert('Plan nicht gefunden!');
    return;
  }

  const scheduleEntry = {
    userId: CURRENT_USER_ID, // Später durch echte User ID ersetzen
    planId: planId,
    planName: plan.name, // Denormalized für schnellere Anzeige
    planType: plan.type, // Store type for styling
    planDuration: plan.duration || 45, // Store duration
    date: selectedDateForPlan,
    completed: false,
    createdAt: new Date().toISOString()
  };

  try {
    await addDoc(scheduleCollection, scheduleEntry);
    console.log('✅ Plan added to calendar!');
    closeAddPlanPanel();
    await loadSchedule(); // Reload
  } catch (error) {
    console.error('Error adding plan:', error);
    alert('Fehler beim Hinzufügen!');
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
    alert('Fehler beim Entfernen!');
  }
}

function viewCalendarPlanDetails(scheduleId) {
  // Find the schedule entry
  const scheduleEntry = scheduleData.find(s => s.id === scheduleId);
  if (!scheduleEntry) return;

  // Find the actual plan
  const plan = allPlans.find(p => p.id === scheduleEntry.planId);

  if (!plan) {
    alert('Plan nicht gefunden!');
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

function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function getPlanTypeColor(type) {
  const colors = {
    strength: '#ef4444',
    cardio: '#3b82f6',
    mobility: '#22c55e',
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

// ========================================
// REAL-TIME LISTENER
// ========================================

function setupScheduleListener() {
  onCollectionChange(scheduleCollection, (schedule) => {
    scheduleData = schedule;
    renderCalendar();
  });
}

console.log('📅 Calendar module loaded!');