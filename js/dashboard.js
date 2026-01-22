// ========================================
// DASHBOARD - DEMO DATA & RENDERING
// ========================================

// Demo-Daten (später aus Firebase berechnen)
const dashboardData = {
  todayWorkout: {
    hasWorkout: true,
    name: "Pull Day",
    time: "18:00",
    exerciseCount: 5,
    duration: 45,
    planId: null // später aus calendar
  },
  weekProgress: {
    completed: 4,
    total: 6
  },
  streak: 12,
  totalReps: 1250,
  nextAchievement: {
    name: "Gorilla Mode",
    description: "500 Pull-ups total",
    current: 420,
    target: 500
  },
  topExercises: [
    { name: "Pull-ups", reps: 120 },
    { name: "Push-ups", reps: 180 },
    { name: "Dips", reps: 90 }
  ]
};

// ========================================
// RENDER FUNCTIONS
// ========================================

function renderTodayWorkout() {
  const container = document.getElementById('today-workout-card');
  if (!container) return;

  const data = dashboardData.todayWorkout;

  if (data.hasWorkout) {
    container.innerHTML = `
      <div class="dashboard-today-card">
        <div class="flex items-center gap-2 mb-3">
          <span class="material-symbols-rounded" style="font-size: 24px; color: var(--color-primary);">today</span>
          <h3 class="text-lg font-bold">Heute geplant</h3>
        </div>

        <div class="dashboard-today-content">
          <div class="flex items-start justify-between mb-3">
            <div>
              <h4 class="text-xl font-bold mb-1">${data.name}</h4>
              <div class="flex items-center gap-4 text-sm text-gray-400">
                <span class="flex items-center gap-1">
                  <span class="material-symbols-rounded" style="font-size: 16px;">schedule</span>
                  ${data.time} Uhr
                </span>
                <span class="flex items-center gap-1">
                  <span class="material-symbols-rounded" style="font-size: 16px;">fitness_center</span>
                  ${data.exerciseCount} Übungen
                </span>
                <span class="flex items-center gap-1">
                  <span class="material-symbols-rounded" style="font-size: 16px;">timer</span>
                  ~${data.duration} min
                </span>
              </div>
            </div>
          </div>

          <button onclick="startWorkout()" class="dashboard-start-btn">
            <span class="material-symbols-rounded">play_arrow</span>
            <span>Workout starten</span>
          </button>
        </div>
      </div>
    `;
  } else {
    container.innerHTML = `
      <div class="dashboard-today-card dashboard-today-empty">
        <div class="flex items-center gap-2 mb-3">
          <span class="material-symbols-rounded" style="font-size: 24px; color: #6b7280;">today</span>
          <h3 class="text-lg font-bold">Heute geplant</h3>
        </div>
        <p class="text-gray-400 mb-3">Kein Training heute geplant</p>
        <button onclick="showView('calendar')" class="dashboard-secondary-btn">
          <span class="material-symbols-rounded">calendar_month</span>
          <span>Zum Kalender</span>
        </button>
      </div>
    `;
  }
}

function renderStats() {
  // Week Progress
  const weekProgressText = document.getElementById('week-progress-text');
  const weekProgressBar = document.querySelector('#week-progress-bar .dashboard-stat-progress-fill');
  if (weekProgressText && weekProgressBar) {
    const { completed, total } = dashboardData.weekProgress;
    const percentage = total > 0 ? (completed / total) * 100 : 0;
    weekProgressText.textContent = `${completed}/${total}`;
    weekProgressBar.style.width = `${percentage}%`;
  }

  // Streak
  const streakCount = document.getElementById('streak-count');
  if (streakCount) {
    streakCount.textContent = dashboardData.streak;
  }

  // Total Reps
  const totalReps = document.getElementById('total-reps');
  if (totalReps) {
    totalReps.textContent = dashboardData.totalReps.toLocaleString('de-DE');
  }
}

function renderAchievement() {
  const container = document.getElementById('achievement-card');
  if (!container) return;

  const achievement = dashboardData.nextAchievement;
  const percentage = (achievement.current / achievement.target) * 100;

  container.innerHTML = `
    <div class="flex items-center gap-2 mb-3">
      <span class="material-symbols-rounded" style="font-size: 24px; color: #fbbf24;">emoji_events</span>
      <h3 class="text-lg font-bold">Nächstes Achievement</h3>
    </div>

    <div class="mb-3">
      <h4 class="text-xl font-bold text-yellow-400 mb-1">${achievement.name}</h4>
      <p class="text-sm text-gray-400">${achievement.description}</p>
    </div>

    <div class="dashboard-achievement-progress">
      <div class="dashboard-achievement-progress-fill" style="width: ${percentage}%"></div>
    </div>

    <div class="flex items-center justify-between mt-2 text-sm">
      <span class="text-gray-400">${achievement.current} / ${achievement.target}</span>
      <span class="text-yellow-400 font-semibold">${Math.round(percentage)}%</span>
    </div>
  `;
}

function renderTopExercises() {
  const container = document.getElementById('top-exercises-card');
  if (!container) return;

  const exercises = dashboardData.topExercises;

  const exercisesList = exercises.map((exercise, index) => `
    <div class="dashboard-exercise-item">
      <div class="dashboard-exercise-rank">${index + 1}</div>
      <div class="flex-1">
        <div class="font-semibold">${exercise.name}</div>
        <div class="text-xs text-gray-400">${exercise.reps} Wiederholungen</div>
      </div>
      <div class="dashboard-exercise-reps">${exercise.reps}</div>
    </div>
  `).join('');

  container.innerHTML = `
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center gap-2">
        <span class="material-symbols-rounded" style="font-size: 24px; color: var(--color-primary);">local_fire_department</span>
        <h3 class="text-lg font-bold">Top-Übungen diese Woche</h3>
      </div>
    </div>

    <div class="space-y-2">
      ${exercisesList}
    </div>

    <button onclick="showView('progress')" class="dashboard-link-btn mt-4">
      <span>Alle Stats anzeigen</span>
      <span class="material-symbols-rounded">arrow_forward</span>
    </button>
  `;
}

// ========================================
// INITIALIZE DASHBOARD
// ========================================

function initDashboard() {
  console.log('📊 Initializing Dashboard...');

  renderTodayWorkout();
  renderStats();
  renderAchievement();
  renderTopExercises();

  console.log('✅ Dashboard initialized!');
}

// ========================================
// PLACEHOLDER FUNCTIONS
// ========================================

function startWorkout() {
  const today = new Date();
  const dateStr = formatDate(today);
  const userId = typeof CURRENT_USER_ID !== 'undefined' ? CURRENT_USER_ID : 'demo-user-123';

  if (typeof scheduleData !== 'undefined') {
    const todayEntry = scheduleData.find((item) => item.date === dateStr && item.userId === userId);
    if (todayEntry) {
      if (typeof startWorkoutFromPlan === 'function') {
        startWorkoutFromPlan(todayEntry.planId, todayEntry.date, todayEntry.id);
        return;
      }
    }
  }

  if (typeof showView === 'function') {
    showView('plans');
  } else {
    alert('Kein Training fuer heute geplant. Bitte starte einen Plan manuell.');
  }
}

// ========================================
// AUTO-INITIALIZE
// ========================================

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDashboard);
} else {
  initDashboard();
}

