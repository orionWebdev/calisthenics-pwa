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
let sessionsLoaded = false;
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
    console.log('Loading sessions...');
    sessionsLoaded = false;
    allSessions = await getAllDocs(sessionsCollection);
    sessionsLoaded = true;
    console.log(`Loaded ${allSessions.length} sessions`);
    return allSessions;
  } catch (error) {
    console.error('Error loading sessions:', error);
    sessionsLoaded = false;
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

function computeHybridBalance(days = 14) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  let strengthMinutes = 0;
  let cardioMinutes = 0;

  allSessions.forEach(session => {
    const sessionDate = session.date?.toDate ? session.date.toDate() : new Date(session.date);
    if (sessionDate < cutoffDate) return;

    const minutes = Number(session.duration || 0);
    if (!minutes) return;

    if (session.type === 'strength') {
      strengthMinutes += minutes;
    } else if (session.type === 'cardio') {
      cardioMinutes += minutes;
    }
  });

  const totalMinutes = strengthMinutes + cardioMinutes;
  if (!totalMinutes) {
    return {
      strengthMinutes: 0,
      cardioMinutes: 0,
      strengthPct: 0,
      cardioPct: 0,
      label: 'Keine Daten',
      status: 'empty'
    };
  }

  const strengthPct = Math.round((strengthMinutes / totalMinutes) * 100);
  const cardioPct = 100 - strengthPct;

  let label = 'Balanced';
  if (strengthPct >= 60) {
    label = 'Strength-leaning';
  } else if (cardioPct >= 60) {
    label = 'Cardio-leaning';
  }

  return {
    strengthMinutes,
    cardioMinutes,
    strengthPct,
    cardioPct,
    label,
    status: 'ok'
  };
}

// ==================== CARDIO SESSION MODAL ====================

/**
 * Öffnet "Add Cardio Session" Modal
 */
function openAddCardioModal() {
  const modal = document.getElementById('add-cardio-modal');
  if (!modal) return;

  console.log('🔓 Opening cardio modal...');

  // Reset inline styles
  modal.style.display = '';

  // Reset Form
  const today = new Date().toISOString().split('T')[0];
  const dateInput = document.getElementById('cardio-date');
  const activityInput = document.getElementById('cardio-activity-type');
  const durationInput = document.getElementById('cardio-duration');
  const distanceInput = document.getElementById('cardio-distance');
  const paceDisplay = document.getElementById('cardio-computed-pace');
  const notesInput = document.getElementById('cardio-notes');

  if (dateInput) dateInput.value = today;
  if (activityInput) activityInput.value = 'run';
  if (durationInput) durationInput.value = '';
  if (distanceInput) distanceInput.value = '';
  if (paceDisplay) {
    paceDisplay.textContent = '-';
    paceDisplay.classList.remove('active');
  }
  if (notesInput) notesInput.value = '';

  // Add active class
  modal.classList.add('active');
  triggerHapticFeedback('light');

  console.log('✅ Modal opened');
}

/**
 * Schließt Cardio Modal
 */
function closeAddCardioModal() {
  const modal = document.getElementById('add-cardio-modal');
  if (!modal) return;

  console.log('🔒 Closing cardio modal...');

  // Remove active class immediately
  modal.classList.remove('active');

  // Force display none after animation
  setTimeout(() => {
    modal.style.display = 'none';
  }, 300);

  // Reset form after animation completes
  setTimeout(() => {
    const dateInput = document.getElementById('cardio-date');
    const activityInput = document.getElementById('cardio-activity-type');
    const durationInput = document.getElementById('cardio-duration');
    const distanceInput = document.getElementById('cardio-distance');
    const paceDisplay = document.getElementById('cardio-computed-pace');
    const notesInput = document.getElementById('cardio-notes');

    if (dateInput) dateInput.value = '';
    if (activityInput) activityInput.value = 'run';
    if (durationInput) durationInput.value = '';
    if (distanceInput) distanceInput.value = '';
    if (paceDisplay) {
      paceDisplay.textContent = '-';
      paceDisplay.classList.remove('active');
    }
    if (notesInput) notesInput.value = '';

    console.log('✅ Modal closed and form reset');
  }, 300);
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
  const dateInput = document.getElementById('cardio-date').value;
  const activityType = document.getElementById('cardio-activity-type').value;
  const duration = parseFloat(document.getElementById('cardio-duration').value);
  const distance = parseFloat(document.getElementById('cardio-distance').value);
  const notes = document.getElementById('cardio-notes').value.trim();

  // Validation
  if (!dateInput) {
    showErrorMessage('Bitte wähle ein Datum');
    return;
  }

  if (!duration || duration <= 0) {
    showErrorMessage('Bitte gib eine gültige Dauer ein');
    return;
  }

  try {
    // Show loading
    const saveBtn = document.querySelector('#add-cardio-modal .modal-save-btn');
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<div class="spinner-small"></div><span>Speichert...</span>';
    }

    // Parse date from input (YYYY-MM-DD)
    const selectedDate = new Date(dateInput + 'T12:00:00');
    const pace = distance > 0 ? calculatePace(duration, distance) : null;

    const cardioSession = {
      type: 'cardio',
      date: firebase.firestore.Timestamp.fromDate(selectedDate),
      activityType,
      duration,
      distanceKm: distance || null,
      pace: pace,
      notes: notes || null,
      createdAt: firebase.firestore.Timestamp.now()
    };

    await addDoc(sessionsCollection, cardioSession);

    console.log('✅ Cardio session saved');

    // Close modal FIRST (before reload)
    closeAddCardioModal();

    // Then reload sessions and refresh view
    await loadSessions();
    if (typeof renderCurrentProgressTab === 'function') {
      renderCurrentProgressTab();
    }

    // Trigger success glow animation
    triggerSuccessGlow();

  } catch (error) {
    console.error('❌ Error saving cardio session:', error);
    showErrorMessage('Fehler beim Speichern: ' + error.message);
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
 * Triggert Screen Edge Glow Animation (Apple Intelligence Style)
 */
function triggerSuccessGlow() {
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('success');
  }
}

/**
 * Zeigt Fehler-Toast (nur für Fehler behalten wir eine Text-Notification)
 */
function showErrorMessage(message) {
  console.error('❌', message);
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', message);
  }
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

/**
 * Handles backdrop click to close modal
 */
function handleModalBackdropClick(event, modalId) {
  if (event.target.id === modalId) {
    if (modalId === 'add-cardio-modal') {
      closeAddCardioModal();
    }
  }
}

// Expose functions
window.openAddCardioModal = openAddCardioModal;
window.closeAddCardioModal = closeAddCardioModal;
window.updateCardioLivePace = updateCardioLivePace;
window.saveCardioSession = saveCardioSession;
window.handleModalBackdropClick = handleModalBackdropClick;
window.triggerSuccessGlow = triggerSuccessGlow;
window.showErrorMessage = showErrorMessage;

console.log('📊 Sessions module loaded');
