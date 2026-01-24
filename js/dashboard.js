// ========================================
// DASHBOARD - DEMO DATA & RENDERING
// ========================================

// Demo-Daten (später aus Firebase berechnen)
const dashboardData = {
  nextAchievement: {
    name: "Gorilla Mode",
    description: "500 Pull-ups total",
    current: 420,
    target: 500
  }
};

let dashboardExercises = [];


// ========================================
// RENDER FUNCTIONS
// ========================================

function renderTodayWorkout() {
  const container = document.getElementById('today-workout-card');
  if (!container) return;

  const dateStr = getLocalDateString();
  const userId = typeof CURRENT_USER_ID !== 'undefined' ? CURRENT_USER_ID : 'demo-user-123';
  const todayEntry = typeof scheduleData !== 'undefined'
    ? scheduleData.find((item) => {
        const entryDate = getScheduleDateString(item);
        const matchesUser = !item.userId || item.userId === userId;
        return entryDate === dateStr && matchesUser;
      })
    : null;

  const plan = todayEntry && typeof allPlans !== 'undefined'
    ? allPlans.find((p) => p.id === todayEntry.planId)
    : null;

  if (todayEntry && plan) {
    const exerciseCount = plan.exercises ? plan.exercises.length : 0;
    container.innerHTML = `
      <div class="dashboard-today-card">
        <div class="flex items-center gap-2 mb-3">
          <span class="material-symbols-rounded" style="font-size: 24px; color: var(--color-primary);">today</span>
          <h3 class="text-lg font-bold">Heute geplant</h3>
        </div>

        <div class="dashboard-today-content">
          <div class="flex items-start justify-between mb-3">
            <div>
              <h4 class="text-xl font-bold mb-1">${plan.name}</h4>
              <div class="flex items-center gap-4 text-sm text-gray-400">
                <span class="flex items-center gap-1">
                  <span class="material-symbols-rounded" style="font-size: 16px;">fitness_center</span>
                  ${exerciseCount} Übungen
                </span>
                <span class="flex items-center gap-1">
                  <span class="material-symbols-rounded" style="font-size: 16px;">timer</span>
                  ~${plan.duration || 45} min
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
    const planName = todayEntry?.planName || 'Geplantes Training';
    const planDuration = todayEntry?.planDuration || 45;
    const planType = todayEntry?.planType || 'mixed';
    const hasPlanned = Boolean(todayEntry);
    const isPlanMissing = hasPlanned && !plan;

    if (isPlanMissing) {
      container.innerHTML = `
        <div class="dashboard-today-card">
          <div class="flex items-center gap-2 mb-3">
            <span class="material-symbols-rounded" style="font-size: 24px; color: var(--color-primary);">today</span>
            <h3 class="text-lg font-bold">Heute geplant</h3>
          </div>

          <div class="dashboard-today-content">
            <div class="flex items-start justify-between mb-3">
              <div>
                <h4 class="text-xl font-bold mb-1">${planName}</h4>
                <div class="flex items-center gap-4 text-sm text-gray-400">
                  <span class="flex items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 16px;">schedule</span>
                    ${planDuration} min
                  </span>
                  <span class="flex items-center gap-1">
                    <span class="material-symbols-rounded" style="font-size: 16px;">category</span>
                    ${planType}
                  </span>
                </div>
              </div>
            </div>

            <button onclick="showView('calendar')" class="dashboard-start-btn">
              <span class="material-symbols-rounded">calendar_month</span>
              <span>Zum Kalender</span>
            </button>
          </div>
        </div>
      `;
      return;
    }

    container.innerHTML = `
      <div class="dashboard-today-card dashboard-today-empty">
        <div class="flex items-center gap-2 mb-3">
          <span class="material-symbols-rounded" style="font-size: 24px; color: #6b7280;">today</span>
          <h3 class="text-lg font-bold">Heute geplant</h3>
        </div>
        <p class="text-gray-400 mb-3">Kein Training heute geplant</p>
        <div class="flex gap-2">
          <button onclick="showView('plans')" class="dashboard-secondary-btn">
            <span class="material-symbols-rounded">assignment</span>
            <span>Plan starten</span>
          </button>
          <button onclick="showView('calendar')" class="dashboard-secondary-btn">
            <span class="material-symbols-rounded">calendar_month</span>
            <span>Planen</span>
          </button>
        </div>
      </div>
    `;
  }
}

function renderStats() {
  const weeklyStats = typeof calculateOverviewStats === 'function'
    ? calculateOverviewStats(7)
    : { totalSessions: 0 };

  // Week Progress
  const weekProgressText = document.getElementById('week-progress-text');
  const weekProgressBar = document.querySelector('#week-progress-bar .dashboard-stat-progress-fill');
  if (weekProgressText && weekProgressBar) {
    const completed = weeklyStats.totalSessions || 0;
    const total = 7;
    const percentage = total > 0 ? (completed / total) * 100 : 0;
    weekProgressText.textContent = `${completed}/${total}`;
    weekProgressBar.style.width = `${Math.min(percentage, 100)}%`;
  }

  // Streak
  const streakCount = document.getElementById('streak-count');
  if (streakCount) {
    const streak = typeof calculateStreak === 'function' ? calculateStreak() : 0;
    streakCount.textContent = streak;
  }

  // Total Reps
  const totalReps = document.getElementById('total-reps');
  if (totalReps) {
    const reps = calculateTotalReps(allSessions || []);
    totalReps.textContent = reps.toLocaleString('de-DE');
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

  const exercises = calculateTopExercises(allSessions || [], dashboardExercises, 7);

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

    ${exercises.length ? `
      <div class="space-y-2">
        ${exercisesList}
      </div>
    ` : `
      <div class="text-sm text-gray-400">Noch keine Uebungsdaten diese Woche</div>
    `}

    <button onclick="showView('progress')" class="dashboard-link-btn mt-4">
      <span>Alle Stats anzeigen</span>
      <span class="material-symbols-rounded">arrow_forward</span>
    </button>
  `;
}

function renderHybridBalanceCard() {
  const container = document.getElementById('hybrid-balance-card');
  if (!container || typeof computeHybridBalance !== 'function') return;

  const days = 14;
  const balance = computeHybridBalance(days);

  if (balance.status === 'empty') {
    container.innerHTML = `
      <div class="hybrid-balance-card">
        <div class="hybrid-balance-header">
          <div>
            <h3 class="hybrid-balance-title">Hybrid Balance</h3>
            <p class="hybrid-balance-subtitle">Letzte ${days} Tage</p>
          </div>
        </div>
        <div class="hybrid-balance-empty">Noch keine Daten fuer Hybrid Balance</div>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="hybrid-balance-card">
      <div class="hybrid-balance-header">
        <div>
          <h3 class="hybrid-balance-title">Hybrid Balance</h3>
          <p class="hybrid-balance-subtitle">Letzte ${days} Tage</p>
        </div>
        <div class="hybrid-balance-label">${balance.label}</div>
      </div>
      <div class="hybrid-balance-bar" role="img" aria-label="Strength ${balance.strengthPct} Prozent, Cardio ${balance.cardioPct} Prozent">
        <div class="hybrid-balance-segment strength" style="width: ${balance.strengthPct}%"></div>
        <div class="hybrid-balance-segment cardio" style="width: ${balance.cardioPct}%"></div>
      </div>
      <div class="hybrid-balance-meta">
        <span>Strength ${balance.strengthPct}%</span>
        <span>Cardio ${balance.cardioPct}%</span>
      </div>
    </div>
  `;
}

// ========================================
// INITIALIZE DASHBOARD
// ========================================

async function initDashboard() {
  console.log('Initializing Dashboard...');

  await loadDashboardData();
  renderTodayWorkout();
  renderStats();
  renderHybridBalanceCard();
  renderAchievement();
  renderTopExercises();

  console.log('Dashboard initialized!');
}


// ========================================
// PLACEHOLDER FUNCTIONS
// ========================================

function startWorkout() {
  const dateStr = getLocalDateString();
  const userId = typeof CURRENT_USER_ID !== 'undefined' ? CURRENT_USER_ID : 'demo-user-123';

  if (typeof scheduleData !== 'undefined') {
    const todayEntry = scheduleData.find((item) => {
      const entryDate = getScheduleDateString(item);
      const matchesUser = !item.userId || item.userId === userId;
      return entryDate === dateStr && matchesUser;
    });
    if (todayEntry) {
      if (typeof startWorkoutFromPlan === 'function') {
        const entryDate = getScheduleDateString(todayEntry) || dateStr;
        startWorkoutFromPlan(todayEntry.planId, entryDate, todayEntry.id);
        return;
      }
    }
  }

  if (typeof showView === 'function') {
    showView('plans');
  } else {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Kein Training fuer heute geplant. Bitte starte einen Plan manuell.');
  }
  }
}

function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function getLocalDateString(baseDate = new Date()) {
  const local = new Date(baseDate);
  local.setHours(0, 0, 0, 0);
  return formatDate(local);
}

function getScheduleDateString(entry) {
  if (!entry || !entry.date) return null;
  if (typeof entry.date === 'string') return entry.date;
  if (entry.date?.toDate) {
    return getLocalDateString(entry.date.toDate());
  }
  const parsed = new Date(entry.date);
  if (Number.isNaN(parsed.getTime())) return null;
  return getLocalDateString(parsed);
}

async function loadDashboardData() {
  if (typeof loadSessions === 'function' && !sessionsLoaded) {
    await loadSessions();
  }

  if (typeof allExercises !== 'undefined' && allExercises.length) {
    dashboardExercises = allExercises;
    return;
  }

  if (typeof getAllDocs === 'function' && typeof exercisesCollection !== 'undefined') {
    try {
      dashboardExercises = await getAllDocs(exercisesCollection);
    } catch (error) {
      console.error('Error loading exercises for dashboard:', error);
    }
  }
}

function getSessionDate(session) {
  if (session?.date?.toDate) {
    return session.date.toDate();
  }
  return new Date(session.date);
}

function calculateTotalReps(sessions) {
  return sessions.reduce((sum, session) => {
    if (session.type !== 'strength') return sum;
    const sessionReps = session.exercises?.reduce((exerciseSum, exercise) => {
      const reps = exercise.sets?.reduce((setSum, set) => setSum + (set.reps || 0), 0) || 0;
      return exerciseSum + reps;
    }, 0) || 0;
    return sum + sessionReps;
  }, 0);
}

function calculateTopExercises(sessions, exercises, days = 7) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  const repsByExercise = new Map();

  sessions.forEach(session => {
    if (session.type !== 'strength') return;
    const sessionDate = getSessionDate(session);
    if (sessionDate < cutoffDate) return;

    session.exercises?.forEach(exercise => {
      const reps = exercise.sets?.reduce((sum, set) => sum + (set.reps || 0), 0) || 0;
      if (!reps) return;

      const current = repsByExercise.get(exercise.exerciseId) || 0;
      repsByExercise.set(exercise.exerciseId, current + reps);
    });
  });

  const exerciseMap = new Map();
  exercises.forEach(ex => exerciseMap.set(ex.id, ex.name));

  return Array.from(repsByExercise.entries())
    .map(([exerciseId, reps]) => ({
      name: exerciseMap.get(exerciseId) || 'Unbekannt',
      reps
    }))
    .sort((a, b) => b.reps - a.reps)
    .slice(0, 3);
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

