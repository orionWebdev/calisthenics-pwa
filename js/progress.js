// ========================================
// PROGRESS - VOLUME TRACKING & ANALYTICS
// ========================================

/**
 * Progress Entry Structure in Firestore:
 * {
 *   id: string (auto-generated)
 *   exerciseId: string
 *   date: timestamp (Firestore timestamp)
 *   sessionId?: string (optional, für mehrere Sessions am selben Tag)
 *   sets: [{ reps: number, weight?: number }]
 *   createdAt: timestamp
 * }
 */

let progressData = [];
let exercisesData = [];
let currentSelectedExerciseId = null;

// ==================== DATA LOADING ====================

/**
 * Progress-Daten laden
 */
async function loadProgressData() {
  try {
    console.log('📊 Loading progress data...');
    progressData = await getAllDocs(progressCollection);
    console.log(`✅ Loaded ${progressData.length} progress entries`);
    return progressData;
  } catch (error) {
    console.error('❌ Error loading progress data:', error);
    return [];
  }
}

/**
 * Exercises laden (für Selector)
 */
async function loadExercisesForProgress() {
  try {
    exercisesData = await getAllDocs(exercisesCollection);
    console.log(`✅ Loaded ${exercisesData.length} exercises for progress`);
    return exercisesData;
  } catch (error) {
    console.error('❌ Error loading exercises:', error);
    return [];
  }
}

// ==================== DATA AGGREGATION ====================

/**
 * Berechnet das Volumen (Summe aller Reps) für einen Progress-Entry
 * @param {Object} entry - Progress Entry mit sets Array
 * @returns {number} - Total Reps (Volumen)
 */
function calculateVolume(entry) {
  if (!entry.sets || !Array.isArray(entry.sets)) return 0;
  return entry.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
}

/**
 * Aggregiert Progress-Daten für eine bestimmte Übung
 * - Gruppiert nach Datum
 * - Summiert Volumen wenn mehrere Einträge am gleichen Tag existieren
 * @param {string} exerciseId
 * @param {number} weeks - Anzahl Wochen zurück (default: 8)
 * @returns {Array} - [{date: Date, volume: number, sessionCount: number}]
 */
function aggregateProgressByExercise(exerciseId, weeks = 8) {
  // Datum-Filter: letzte N Wochen
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - (weeks * 7));

  // Filter nach exerciseId und Zeitraum
  const filteredEntries = progressData.filter(entry => {
    if (entry.exerciseId !== exerciseId) return false;

    // Date handling - Firestore Timestamp oder Date Object
    let entryDate;
    if (entry.date && entry.date.toDate) {
      entryDate = entry.date.toDate(); // Firestore Timestamp
    } else if (entry.date instanceof Date) {
      entryDate = entry.date;
    } else if (typeof entry.date === 'string') {
      entryDate = new Date(entry.date);
    } else {
      return false;
    }

    return entryDate >= cutoffDate;
  });

  // Gruppierung nach Datum (YYYY-MM-DD)
  const groupedByDate = {};

  filteredEntries.forEach(entry => {
    let entryDate;
    if (entry.date && entry.date.toDate) {
      entryDate = entry.date.toDate();
    } else if (entry.date instanceof Date) {
      entryDate = entry.date;
    } else if (typeof entry.date === 'string') {
      entryDate = new Date(entry.date);
    }

    const dateKey = entryDate.toISOString().split('T')[0]; // YYYY-MM-DD
    const volume = calculateVolume(entry);

    if (!groupedByDate[dateKey]) {
      groupedByDate[dateKey] = {
        date: entryDate,
        volume: 0,
        sessionCount: 0
      };
    }

    groupedByDate[dateKey].volume += volume;
    groupedByDate[dateKey].sessionCount += 1;
  });

  // In Array umwandeln und nach Datum sortieren
  return Object.values(groupedByDate).sort((a, b) => a.date - b.date);
}

/**
 * Berechnet Stats für eine Übung
 * @param {Array} aggregatedData - Aggregierte Daten von aggregateProgressByExercise
 * @returns {Object} - {lastVolume, bestVolume, avgVolume, totalSessions}
 */
function calculateStats(aggregatedData) {
  if (!aggregatedData || aggregatedData.length === 0) {
    return {
      lastVolume: 0,
      bestVolume: 0,
      avgVolume: 0,
      totalSessions: 0
    };
  }

  const volumes = aggregatedData.map(d => d.volume);
  const lastVolume = volumes[volumes.length - 1] || 0;
  const bestVolume = Math.max(...volumes);
  const avgVolume = Math.round(volumes.reduce((sum, v) => sum + v, 0) / volumes.length);
  const totalSessions = aggregatedData.reduce((sum, d) => sum + d.sessionCount, 0);

  return {
    lastVolume,
    bestVolume,
    avgVolume,
    totalSessions
  };
}

// ==================== UI RENDERING ====================

/**
 * Initialisiert die Progress-Seite
 */
async function initProgress() {
  console.log('📊 Initializing progress page...');

  showProgressLoading();

  // Daten laden
  await Promise.all([
    loadProgressData(),
    loadExercisesForProgress()
  ]);

  // Exercise Selector rendern
  renderExerciseSelector();

  // Erste Übung auswählen (falls vorhanden)
  if (exercisesData.length > 0) {
    // Übung mit den meisten Progress-Einträgen finden
    const exerciseWithMostProgress = findExerciseWithMostProgress();
    selectExercise(exerciseWithMostProgress?.id || exercisesData[0].id);
  } else {
    showProgressEmpty();
  }

  hideProgressLoading();
}

/**
 * Findet die Übung mit den meisten Progress-Einträgen
 */
function findExerciseWithMostProgress() {
  const counts = {};
  progressData.forEach(entry => {
    counts[entry.exerciseId] = (counts[entry.exerciseId] || 0) + 1;
  });

  let maxCount = 0;
  let topExerciseId = null;

  Object.entries(counts).forEach(([exerciseId, count]) => {
    if (count > maxCount) {
      maxCount = count;
      topExerciseId = exerciseId;
    }
  });

  return exercisesData.find(ex => ex.id === topExerciseId);
}

/**
 * Rendert den Exercise Selector
 */
function renderExerciseSelector() {
  const container = document.getElementById('progress-exercise-selector');
  if (!container) return;

  if (exercisesData.length === 0) {
    container.innerHTML = '<p class="text-gray-400 text-sm">Keine Übungen verfügbar</p>';
    return;
  }

  // Sortiere nach Name
  const sortedExercises = [...exercisesData].sort((a, b) =>
    (a.name || '').localeCompare(b.name || '')
  );

  container.innerHTML = `
    <div class="progress-exercise-search">
      <span class="material-symbols-rounded progress-search-icon">search</span>
      <input
        type="text"
        id="exercise-search-input"
        placeholder="Übung suchen..."
        class="progress-search-input"
        oninput="filterExercises(this.value)"
      />
    </div>
    <div id="progress-exercise-list" class="progress-exercise-list">
      ${sortedExercises.map(ex => `
        <button
          class="progress-exercise-item ${ex.id === currentSelectedExerciseId ? 'active' : ''}"
          data-exercise-id="${ex.id}"
          onclick="selectExercise('${ex.id}')"
        >
          <span class="progress-exercise-name">${ex.name}</span>
          <span class="material-symbols-rounded">chevron_right</span>
        </button>
      `).join('')}
    </div>
  `;
}

/**
 * Filtert die Exercise-Liste basierend auf Suchbegriff
 */
function filterExercises(searchTerm) {
  const list = document.getElementById('progress-exercise-list');
  if (!list) return;

  const term = searchTerm.toLowerCase().trim();
  const items = list.querySelectorAll('.progress-exercise-item');

  items.forEach(item => {
    const name = item.querySelector('.progress-exercise-name').textContent.toLowerCase();
    if (name.includes(term)) {
      item.style.display = 'flex';
    } else {
      item.style.display = 'none';
    }
  });
}

/**
 * Wählt eine Übung aus und zeigt deren Progress
 */
function selectExercise(exerciseId) {
  console.log('📊 Selecting exercise:', exerciseId);

  currentSelectedExerciseId = exerciseId;

  // UI Update - aktive Markierung
  const items = document.querySelectorAll('.progress-exercise-item');
  items.forEach(item => {
    if (item.dataset.exerciseId === exerciseId) {
      item.classList.add('active');
    } else {
      item.classList.remove('active');
    }
  });

  // Chart und Stats rendern
  renderProgressChart(exerciseId);
  renderProgressStats(exerciseId);
}

/**
 * Rendert das Progress Chart für eine Übung
 */
function renderProgressChart(exerciseId) {
  const container = document.getElementById('progress-chart-container');
  if (!container) return;

  // Daten aggregieren
  const aggregatedData = aggregateProgressByExercise(exerciseId, 8);

  if (aggregatedData.length === 0) {
    container.innerHTML = `
      <div class="progress-empty-chart">
        <span class="material-symbols-rounded">insert_chart</span>
        <p>Noch keine Daten für diese Übung</p>
        <p class="text-sm text-gray-400">Starte ein Training, um deinen Fortschritt zu tracken</p>
      </div>
    `;
    return;
  }

  // Chart rendern
  container.innerHTML = `
    <div class="progress-chart-header">
      <h3 class="progress-chart-title">Volumen (Reps) - Letzte 8 Wochen</h3>
    </div>
    <div class="progress-chart-canvas-wrapper">
      <canvas id="progress-chart-canvas"></canvas>
    </div>
  `;

  // Canvas Chart zeichnen
  drawVolumeChart(aggregatedData);
}

/**
 * Zeichnet ein Linien-Chart mit Canvas
 */
function drawVolumeChart(data) {
  const canvas = document.getElementById('progress-chart-canvas');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;

  // Canvas Größe setzen
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);

  const width = rect.width;
  const height = rect.height;

  // Chart-Bereich (mit Padding für Achsen)
  const padding = { top: 20, right: 20, bottom: 40, left: 50 };
  const chartWidth = width - padding.left - padding.right;
  const chartHeight = height - padding.top - padding.bottom;

  // Daten-Bereich
  const volumes = data.map(d => d.volume);
  const maxVolume = Math.max(...volumes);
  const minVolume = Math.min(...volumes);
  const volumeRange = maxVolume - minVolume || 1; // Avoid division by 0

  // Clear canvas
  ctx.clearRect(0, 0, width, height);

  // Dark Mode Farben
  const gridColor = 'rgba(75, 85, 99, 0.3)';
  const textColor = '#9ca3af';
  const lineColor = '#F02277';
  const pointColor = '#F02277';
  const pointHoverColor = '#FF3399';

  // Grid Lines (horizontal)
  ctx.strokeStyle = gridColor;
  ctx.lineWidth = 1;
  const gridLines = 5;
  for (let i = 0; i <= gridLines; i++) {
    const y = padding.top + (chartHeight / gridLines) * i;
    ctx.beginPath();
    ctx.moveTo(padding.left, y);
    ctx.lineTo(padding.left + chartWidth, y);
    ctx.stroke();
  }

  // Y-Achse Labels
  ctx.fillStyle = textColor;
  ctx.font = '11px Inter, sans-serif';
  ctx.textAlign = 'right';
  ctx.textBaseline = 'middle';
  for (let i = 0; i <= gridLines; i++) {
    const value = Math.round(maxVolume - (volumeRange / gridLines) * i);
    const y = padding.top + (chartHeight / gridLines) * i;
    ctx.fillText(value.toString(), padding.left - 10, y);
  }

  // Datenpunkte berechnen
  const points = data.map((d, i) => {
    const x = padding.left + (chartWidth / (data.length - 1 || 1)) * i;
    const y = padding.top + chartHeight - ((d.volume - minVolume) / volumeRange) * chartHeight;
    return { x, y, volume: d.volume, date: d.date };
  });

  // Linie zeichnen
  ctx.strokeStyle = lineColor;
  ctx.lineWidth = 3;
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';

  ctx.beginPath();
  points.forEach((point, i) => {
    if (i === 0) {
      ctx.moveTo(point.x, point.y);
    } else {
      ctx.lineTo(point.x, point.y);
    }
  });
  ctx.stroke();

  // Punkte zeichnen
  points.forEach(point => {
    // Outer glow
    ctx.beginPath();
    ctx.arc(point.x, point.y, 6, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(240, 34, 119, 0.2)';
    ctx.fill();

    // Main point
    ctx.beginPath();
    ctx.arc(point.x, point.y, 4, 0, Math.PI * 2);
    ctx.fillStyle = pointColor;
    ctx.fill();

    // Inner highlight
    ctx.beginPath();
    ctx.arc(point.x, point.y, 2, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
    ctx.fill();
  });

  // X-Achse Labels (Datum)
  ctx.fillStyle = textColor;
  ctx.font = '10px Inter, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';

  // Nur max 6 Labels zeigen
  const labelStep = Math.ceil(data.length / 6);
  data.forEach((d, i) => {
    if (i % labelStep === 0 || i === data.length - 1) {
      const point = points[i];
      const dateStr = formatShortDate(d.date);
      ctx.fillText(dateStr, point.x, padding.top + chartHeight + 10);
    }
  });
}

/**
 * Rendert die Progress Stats
 */
function renderProgressStats(exerciseId) {
  const container = document.getElementById('progress-stats-container');
  if (!container) return;

  // Daten aggregieren
  const aggregatedData = aggregateProgressByExercise(exerciseId, 8);
  const stats = calculateStats(aggregatedData);

  // Exercise Name
  const exercise = exercisesData.find(ex => ex.id === exerciseId);
  const exerciseName = exercise?.name || 'Übung';

  container.innerHTML = `
    <div class="progress-stats-header">
      <h3 class="progress-stats-title">${exerciseName}</h3>
    </div>
    <div class="progress-stats-grid">
      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(240, 34, 119, 0.1);">
          <span class="material-symbols-rounded" style="color: var(--color-primary);">trending_up</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Letztes Training</p>
          <p class="progress-stat-value">${stats.lastVolume} Reps</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(34, 197, 94, 0.1);">
          <span class="material-symbols-rounded" style="color: #22c55e;">emoji_events</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Bestes Training</p>
          <p class="progress-stat-value">${stats.bestVolume} Reps</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(59, 130, 246, 0.1);">
          <span class="material-symbols-rounded" style="color: #3b82f6;">analytics</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Durchschnitt</p>
          <p class="progress-stat-value">${stats.avgVolume} Reps</p>
        </div>
      </div>

      <div class="progress-stat-card">
        <div class="progress-stat-icon" style="background: rgba(168, 85, 247, 0.1);">
          <span class="material-symbols-rounded" style="color: #a855f7;">calendar_month</span>
        </div>
        <div class="progress-stat-content">
          <p class="progress-stat-label">Sessions</p>
          <p class="progress-stat-value">${stats.totalSessions}</p>
        </div>
      </div>
    </div>
  `;
}

// ==================== LOADING & EMPTY STATES ====================

function showProgressLoading() {
  const chartContainer = document.getElementById('progress-chart-container');
  const statsContainer = document.getElementById('progress-stats-container');

  if (chartContainer) {
    chartContainer.innerHTML = `
      <div class="progress-loading">
        <div class="spinner"></div>
        <p>Lade Progress-Daten...</p>
      </div>
    `;
  }

  if (statsContainer) {
    statsContainer.innerHTML = `
      <div class="progress-loading">
        <div class="spinner"></div>
      </div>
    `;
  }
}

function hideProgressLoading() {
  // Loading wird automatisch ersetzt durch Chart/Stats rendering
}

function showProgressEmpty() {
  const chartContainer = document.getElementById('progress-chart-container');
  const statsContainer = document.getElementById('progress-stats-container');

  if (chartContainer) {
    chartContainer.innerHTML = `
      <div class="progress-empty-state">
        <span class="material-symbols-rounded progress-empty-icon">insights</span>
        <h3>Noch keine Progress-Daten</h3>
        <p>Starte dein erstes Training, um deinen Fortschritt zu tracken</p>
        <button onclick="showView('calendar')" class="progress-empty-btn">
          <span class="material-symbols-rounded">calendar_month</span>
          <span>Zum Kalender</span>
        </button>
      </div>
    `;
  }

  if (statsContainer) {
    statsContainer.innerHTML = '';
  }
}

// ==================== HELPER FUNCTIONS ====================

/**
 * Formatiert Datum als kurze Version (z.B. "12. Jan")
 */
function formatShortDate(date) {
  const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  const day = date.getDate();
  const month = months[date.getMonth()];
  return `${day}. ${month}`;
}

/**
 * Demo-Daten Generator (für Testing)
 */
async function generateDemoProgressData() {
  console.log('🎲 Generating demo progress data...');

  // Hole erste 3 Übungen
  const exercises = await getAllDocs(exercisesCollection);
  if (exercises.length === 0) {
    console.log('⚠️ No exercises found. Create exercises first.');
    return;
  }

  const demoExercises = exercises.slice(0, 3);
  const now = new Date();

  // Erstelle für jede Übung 10-15 zufällige Einträge über letzte 8 Wochen
  for (const exercise of demoExercises) {
    const entryCount = 10 + Math.floor(Math.random() * 6); // 10-15 Einträge

    for (let i = 0; i < entryCount; i++) {
      // Zufälliges Datum in letzten 8 Wochen
      const daysAgo = Math.floor(Math.random() * 56); // 0-56 Tage
      const date = new Date(now);
      date.setDate(date.getDate() - daysAgo);

      // Zufällige Sets (3-5 Sets mit 8-15 Reps)
      const setCount = 3 + Math.floor(Math.random() * 3);
      const sets = [];
      for (let j = 0; j < setCount; j++) {
        sets.push({
          reps: 8 + Math.floor(Math.random() * 8) // 8-15 Reps
        });
      }

      const progressEntry = {
        exerciseId: exercise.id,
        date: firebase.firestore.Timestamp.fromDate(date),
        sets: sets
      };

      await addDoc(progressCollection, progressEntry);
    }
  }

  console.log('✅ Demo progress data generated!');
  alert('Demo-Daten erstellt! Lade die Seite neu.');
}

// Expose für Console-Testing
window.generateDemoProgressData = generateDemoProgressData;

console.log('📊 Progress module loaded');
