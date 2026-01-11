// ========================================
// CALENDAR MANAGEMENT
// ========================================

// Calendar State
let currentCalendarView = 'month'; // 'month' or 'week'
let currentDate = new Date();
let scheduleData = []; // Alle geplanten Trainings
let selectedDateForPlan = null;

// Demo User ID (später wird das durch Firebase Auth ersetzt)
const CURRENT_USER_ID = 'demo-user-123';

// Month/Day Names
const monthNames = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
                    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
const dayNames = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];

// ========================================
// LOAD SCHEDULE DATA
// ========================================

async function loadSchedule() {
  try {
    // Später filtern wir hier nach userId
    // Für jetzt laden wir alle (da wir noch keine Auth haben)
    scheduleData = await getAllDocs(scheduleCollection);
    renderCalendar();
  } catch (error) {
    console.error('Error loading schedule:', error);
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
  updateCalendarTitle();
  
  if (currentCalendarView === 'month') {
    renderMonthView();
  } else {
    renderWeekView();
  }
}

function updateCalendarTitle() {
  const title = document.getElementById('calendar-title');
  
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
        <div class="calendar-plan" onclick="event.stopPropagation();">
          <span>${plan.planName}</span>
          <span class="calendar-plan-remove" onclick="removePlanFromDate('${plan.id}')">✕</span>
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
  const weekStart = getWeekStart(currentDate);
  const today = new Date();
  
  weekGrid.innerHTML = '';
  
  for (let i = 0; i < 7; i++) {
    const date = new Date(weekStart);
    date.setDate(date.getDate() + i);
    
    const isToday = date.toDateString() === today.toDateString();
    const dateStr = formatDate(date);
    const dayPlans = getPlansForDate(dateStr);
    
    const card = document.createElement('div');
    card.className = 'week-day-card';
    if (isToday) card.classList.add('today');
    if (dayPlans.length > 0) card.classList.add('has-plan');
    
    card.innerHTML = `
      <div class="flex items-center justify-between mb-3">
        <div>
          <div class="text-sm text-gray-400">${dayNames[i]}</div>
          <div class="text-xl font-bold">${date.getDate()}. ${monthNames[date.getMonth()]}</div>
        </div>
        <button 
          onclick="openAddPlanPanel('${dateStr}')"
          class="bg-blue-600 hover:bg-blue-700 px-3 py-1 rounded text-sm transition-colors"
        >
          ➕ Plan
        </button>
      </div>
      
      <div class="space-y-2">
        ${dayPlans.length === 0 ? 
          '<p class="text-gray-500 text-sm">Kein Training geplant</p>' :
          dayPlans.map(plan => `
            <div class="bg-gray-700 rounded-lg p-3 flex items-center justify-between">
              <div>
                <div class="font-semibold">${plan.planName}</div>
                <div class="text-xs text-gray-400">Geplant</div>
              </div>
              <button 
                onclick="removePlanFromDate('${plan.id}')"
                class="text-red-400 hover:text-red-300 transition-colors"
              >
                🗑️
              </button>
            </div>
          `).join('')
        }
      </div>
    `;
    
    weekGrid.appendChild(card);
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
  document.getElementById('plan-select').value = '';
}

function closeAddPlanPanel() {
  document.getElementById('add-plan-panel').classList.add('hidden');
  selectedDateForPlan = null;
}

async function addPlanToDate() {
  const planId = document.getElementById('plan-select').value;
  
  if (!planId || !selectedDateForPlan) {
    alert('Bitte wähle einen Plan!');
    return;
  }
  
  // Get plan name from select
  const planName = document.getElementById('plan-select').selectedOptions[0].text;
  
  const scheduleEntry = {
    userId: CURRENT_USER_ID, // Später durch echte User ID ersetzen
    planId: planId,
    planName: planName, // Denormalized für schnellere Anzeige
    date: selectedDateForPlan,
    completed: false
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

// ========================================
// HELPER FUNCTIONS
// ========================================

function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
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