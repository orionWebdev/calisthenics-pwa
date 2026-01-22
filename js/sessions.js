// ========================================
// SESSIONS - HYBRID STRENGTH + CARDIO TRACKING
// ========================================

/**
 * Session Data Model:
 *
 * Strength Session:
 * {
 *   id: string
 *   type: 'strength'
 *   date: timestamp
 *   exercises: [{
 *     exerciseId: string
 *     sets: [{ reps: number, weight?: number }]
 *   }]
 *   duration?: number (minutes)
 *   notes?: string
 *   createdAt: timestamp
 * }
 *
 * Cardio Session:
 * {
 *   id: string
 *   type: 'cardio'
 *   date: timestamp
 *   activityType: 'run' | 'bike' | 'swim' | 'row' | 'other'
 *   duration: number (minutes, required)
 *   distanceKm?: number (optional)
 *   pace?: number (computed: min/km, read-only)
 *   notes?: string
 *   createdAt: timestamp
 * }
 */

let allSessions = [];
let currentProgressTab = 'overview'; // 'overview', 'strength', 'cardio'
let selectedExerciseId = null;
let selectedActivityType = 'run';
let strengthMetric = 'volume'; // 'volume' or 'bestSet'
let cardioMetric = 'time'; // 'time' or 'distance'

// Activity Types Config
const ACTIVITY_TYPES = {
  run: { name: 'Laufen', icon: 'directions_run', color: '#3b82f6' },
  bike: { name: 'Radfahren', icon: 'directions_bike', color: '#10b981' },
  swim: { name: 'Schwimmen', icon: 'pool', color: '#06b6d4' },
  row: { name: 'Rudern', icon: 'rowing', color: '#8b5cf6' },
  other: { name: 'Sonstiges', icon: 'fitness_center', color: '#f59e0b' }
};

// ==================== DATA LOADING ====================

/**
 * Lädt alle Sessions
 */
async function loadSessions() {
  try {
    console.log('📊 Loading sessions...');
    allSessions = await getAllDocs(sessionsCollection);
    console.log(`✅ Loaded ${allSessions.length} sessions`);
    return allSessions;
  } catch (error) {
    console.error('❌ Error loading sessions:', error);
    return [];
  }
}

/**
 * Speichert letzten aktiven Tab in localStorage
 */
function saveLastProgressTab(tab) {
  localStorage.setItem('lastProgressTab', tab);
  currentProgressTab = tab;
}

/**
 * Lädt letzten aktiven Tab
 */
function loadLastProgressTab() {
  const saved = localStorage.getItem('lastProgressTab');
  if (saved && ['overview', 'strength', 'cardio'].includes(saved)) {
    currentProgressTab = saved;
  }
  return currentProgressTab;
}

// ==================== CARDIO CALCULATIONS ====================

/**
 * Berechnet Pace (min/km) aus Duration und Distance
 * @param {number} durationMinutes
 * @param {number} distanceKm
 * @returns {number|null} Pace in min/km
 */
function calculatePace(durationMinutes, distanceKm) {
  if (!distanceKm || distanceKm <= 0) return null;
  return durationMinutes / distanceKm;
}

/**
 * Formatiert Pace als "5:30 min/km"
 */
function formatPace(paceMinPerKm) {
  if (!paceMinPerKm) return '-';
  const minutes = Math.floor(paceMinPerKm);
  const seconds = Math.round((paceMinPerKm - minutes) * 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')} min/km`;
}

// ==================== STRENGTH CALCULATIONS ====================

/**
 * Berechnet Volumen (Summe aller Reps) für eine Exercise in einer Session
 */
function calculateExerciseVolume(exerciseEntry) {
  if (!exerciseEntry.sets || !Array.isArray(exerciseEntry.sets)) return 0;
  return exerciseEntry.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
}

/**
 * Findet Best Set (max Reps in einem Set) für eine Exercise in einer Session
 */
function calculateBestSet(exerciseEntry) {
  if (!exerciseEntry.sets || !Array.isArray(exerciseEntry.sets)) return 0;
  return Math.max(...exerciseEntry.sets.map(set => set.reps || 0));
}

// ==================== DATA AGGREGATION ====================

/**
 * Aggregiert Strength-Daten für eine Übung
 * @param {string} exerciseId
 * @param {string} metric - 'volume' or 'bestSet'
 * @param {number} weeks
 * @returns {Array} [{date, value, sessionCount}]
 */
function aggregateStrengthData(exerciseId, metric = 'volume', weeks = 8) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - (weeks * 7));

  const strengthSessions = allSessions.filter(s => {
    if (s.type !== 'strength') return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  const groupedByDate = {};

  strengthSessions.forEach(session => {
    const exercise = session.exercises?.find(ex => ex.exerciseId === exerciseId);
    if (!exercise) return;

    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    const dateKey = sessionDate.toISOString().split('T')[0];

    const value = metric === 'volume'
      ? calculateExerciseVolume(exercise)
      : calculateBestSet(exercise);

    if (!groupedByDate[dateKey]) {
      groupedByDate[dateKey] = {
        date: sessionDate,
        value: 0,
        sessionCount: 0
      };
    }

    groupedByDate[dateKey].value += value;
    groupedByDate[dateKey].sessionCount += 1;
  });

  return Object.values(groupedByDate).sort((a, b) => a.date - b.date);
}

/**
 * Aggregiert Cardio-Daten für eine Activity
 * @param {string} activityType
 * @param {string} metric - 'time' or 'distance'
 * @param {number} weeks
 * @returns {Array} [{date, value, sessionCount}]
 */
function aggregateCardioData(activityType, metric = 'time', weeks = 8) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - (weeks * 7));

  const cardioSessions = allSessions.filter(s => {
    if (s.type !== 'cardio') return false;
    if (s.activityType !== activityType) return false;
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  const groupedByDate = {};

  cardioSessions.forEach(session => {
    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    const dateKey = sessionDate.toISOString().split('T')[0];

    let value = 0;
    if (metric === 'time') {
      value = session.duration || 0;
    } else if (metric === 'distance') {
      value = session.distanceKm || 0;
    }

    if (!groupedByDate[dateKey]) {
      groupedByDate[dateKey] = {
        date: sessionDate,
        value: 0,
        sessionCount: 0
      };
    }

    groupedByDate[dateKey].value += value;
    groupedByDate[dateKey].sessionCount += 1;
  });

  return Object.values(groupedByDate).sort((a, b) => a.date - b.date);
}

/**
 * Berechnet Overview Stats (letzte N Tage)
 * @param {number} days
 * @returns {Object}
 */
function calculateOverviewStats(days = 7) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  const recentSessions = allSessions.filter(s => {
    const sessionDate = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    return sessionDate >= cutoffDate;
  });

  const strengthCount = recentSessions.filter(s => s.type === 'strength').length;
  const cardioCount = recentSessions.filter(s => s.type === 'cardio').length;

  // Total training time
  let totalTime = 0;
  recentSessions.forEach(s => {
    if (s.duration) {
      totalTime += s.duration;
    }
  });

  // Streak berechnen (vereinfacht: aufeinanderfolgende Tage mit Training)
  const streak = calculateStreak();

  return {
    strengthCount,
    cardioCount,
    totalSessions: recentSessions.length,
    totalTime,
    streak
  };
}

/**
 * Berechnet Training Streak
 */
function calculateStreak() {
  if (allSessions.length === 0) return 0;

  // Sortiere Sessions nach Datum (neueste zuerst)
  const sorted = [...allSessions].sort((a, b) => {
    const dateA = a.date?.toDate ? a.date.toDate() : new Date(a.date);
    const dateB = b.date?.toDate ? b.date.toDate() : new Date(b.date);
    return dateB - dateA;
  });

  // Unique Dates
  const uniqueDates = new Set();
  sorted.forEach(s => {
    const date = s.date?.toDate ? s.date.toDate() : new Date(s.date);
    uniqueDates.add(date.toISOString().split('T')[0]);
  });

  const sortedDates = Array.from(uniqueDates).sort().reverse();

  let streak = 0;
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  for (let i = 0; i < sortedDates.length; i++) {
    const checkDate = new Date(today);
    checkDate.setDate(checkDate.getDate() - i);
    const checkDateStr = checkDate.toISOString().split('T')[0];

    if (sortedDates.includes(checkDateStr)) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}

/**
 * Berechnet Stats für aggregierte Daten
 */
function calculateStats(aggregatedData) {
  if (!aggregatedData || aggregatedData.length === 0) {
    return {
      lastValue: 0,
      bestValue: 0,
      avgValue: 0,
      totalSessions: 0
    };
  }

  const values = aggregatedData.map(d => d.value);
  const lastValue = values[values.length - 1] || 0;
  const bestValue = Math.max(...values);
  const avgValue = Math.round(values.reduce((sum, v) => sum + v, 0) / values.length);
  const totalSessions = aggregatedData.reduce((sum, d) => sum + d.sessionCount, 0);

  return {
    lastValue,
    bestValue,
    avgValue,
    totalSessions
  };
}

// ==================== CARDIO SESSION MODAL ====================

/**
 * Öffnet "Add Cardio Session" Modal
 */
function openAddCardioModal() {
  const modal = document.getElementById('add-cardio-modal');
  if (!modal) return;

  // Reset Form
  document.getElementById('cardio-activity-type').value = 'run';
  document.getElementById('cardio-duration').value = '';
  document.getElementById('cardio-distance').value = '';
  document.getElementById('cardio-computed-pace').textContent = '-';
  document.getElementById('cardio-notes').value = '';

  modal.classList.add('active');
  triggerHapticFeedback('light');
}

/**
 * Schließt Cardio Modal
 */
function closeAddCardioModal() {
  const modal = document.getElementById('add-cardio-modal');
  if (modal) {
    modal.classList.remove('active');
  }
}

/**
 * Live Pace Berechnung im Modal
 */
function updateCardioLivePace() {
  const duration = parseFloat(document.getElementById('cardio-duration').value) || 0;
  const distance = parseFloat(document.getElementById('cardio-distance').value) || 0;

  const paceDisplay = document.getElementById('cardio-computed-pace');
  if (!paceDisplay) return;

  if (duration > 0 && distance > 0) {
    const pace = calculatePace(duration, distance);
    paceDisplay.textContent = formatPace(pace);
    paceDisplay.classList.add('active');
  } else {
    paceDisplay.textContent = '-';
    paceDisplay.classList.remove('active');
  }
}

/**
 * Speichert neue Cardio Session
 */
async function saveCardioSession() {
  const activityType = document.getElementById('cardio-activity-type').value;
  const duration = parseFloat(document.getElementById('cardio-duration').value);
  const distance = parseFloat(document.getElementById('cardio-distance').value);
  const notes = document.getElementById('cardio-notes').value.trim();

  // Validation
  if (!duration || duration <= 0) {
    showToast('❌ Bitte gib eine gültige Dauer ein', 'error');
    return;
  }

  try {
    // Show loading
    const saveBtn = document.querySelector('#add-cardio-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<div class="spinner-small"></div><span>Speichert...</span>';
    }

    const pace = distance > 0 ? calculatePace(duration, distance) : null;

    const cardioSession = {
      type: 'cardio',
      date: firebase.firestore.Timestamp.now(),
      activityType,
      duration,
      distanceKm: distance || null,
      pace: pace,
      notes: notes || null
    };

    await addDoc(sessionsCollection, cardioSession);

    console.log('✅ Cardio session saved');
    showToast('✅ Cardio-Session gespeichert!', 'success');

    closeAddCardioModal();

    // Reload sessions and refresh current view
    await loadSessions();
    renderCurrentProgressTab();

  } catch (error) {
    console.error('❌ Error saving cardio session:', error);
    showToast('❌ Fehler beim Speichern', 'error');
  } finally {
    const saveBtn = document.querySelector('#add-cardio-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span class="material-symbols-rounded">check</span><span>Speichern</span>';
    }
  }
}

// ==================== UI HELPERS ====================

/**
 * Zeigt Toast Notification
 */
function showToast(message, type = 'info') {
  const toast = document.getElementById('session-toast');
  if (!toast) return;

  const iconMap = {
    success: 'check_circle',
    error: 'error',
    info: 'info'
  };

  toast.innerHTML = `
    <span class="material-symbols-rounded">${iconMap[type] || 'info'}</span>
    <span>${message}</span>
  `;

  toast.className = `session-toast ${type}`;
  toast.classList.add('active');

  setTimeout(() => {
    toast.classList.remove('active');
  }, 3000);
}

/**
 * Formatiert Datum als kurze Version
 */
function formatShortDate(date) {
  const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  const day = date.getDate();
  const month = months[date.getMonth()];
  return `${day}. ${month}`;
}

/**
 * Formatiert Duration als "1:30 h" oder "45 min"
 */
function formatDuration(minutes) {
  if (minutes >= 60) {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return mins > 0 ? `${hours}:${mins.toString().padStart(2, '0')} h` : `${hours} h`;
  }
  return `${minutes} min`;
}

// Expose functions
window.openAddCardioModal = openAddCardioModal;
window.closeAddCardioModal = closeAddCardioModal;
window.updateCardioLivePace = updateCardioLivePace;
window.saveCardioSession = saveCardioSession;

console.log('📊 Sessions module loaded');
