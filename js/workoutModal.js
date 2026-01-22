// ========================================
// WORKOUT MODAL - VIEW & MANAGE WORKOUTS
// ========================================

/**
 * Open workout detail modal
 */
function openWorkoutDetailModal(sessionId) {
  const session = allSessions.find(s => s.id === sessionId);
  if (!session) {
    console.error('Session not found:', sessionId);
    return;
  }

  const date = session.date?.toDate ? session.date.toDate() : new Date(session.date);
  const totalSets = calculateTotalSets(session);
  const totalVolume = calculateTotalVolume(session);

  const modalContent = `
    <div class="workout-detail-modal">
      <!-- Header -->
      <div class="workout-detail-header">
        <div class="workout-type-badge type-strength">Kraft</div>
        <div class="workout-date" style="font-size: 0.875rem; color: #9ca3af;">
          ${formatFullDate(date)}
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="workout-stats-grid">
        <div class="workout-stat">
          <span class="material-symbols-rounded">schedule</span>
          <div class="workout-stat-value">${session.duration || '-'}</div>
          <div class="workout-stat-label">Minuten</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">fitness_center</span>
          <div class="workout-stat-value">${session.exercises?.length || 0}</div>
          <div class="workout-stat-label">Übungen</div>
        </div>
        <div class="workout-stat">
          <span class="material-symbols-rounded">repeat</span>
          <div class="workout-stat-value">${totalSets}</div>
          <div class="workout-stat-label">Sätze</div>
        </div>
      </div>

      <!-- Exercises List -->
      <div class="workout-exercises">
        <h4 class="workout-section-title">Übungen</h4>
        ${renderWorkoutExercises(session)}
      </div>

      <!-- Notes -->
      ${session.notes ? `
        <div class="workout-notes" style="margin-bottom: 1.5rem;">
          <h4 class="workout-section-title">Notizen</h4>
          <p style="color: #d1d5db; font-size: 0.875rem;">${session.notes}</p>
        </div>
      ` : ''}

      <!-- Actions -->
      <div class="workout-modal-actions">
        <button onclick="startWorkoutFromSession('${session.id}'); closeWorkoutDetailModal();" class="btn-primary">
          <span class="material-symbols-rounded">play_arrow</span>
          <span>Erneut starten</span>
        </button>
        <button onclick="confirmDeleteWorkout('${session.id}')" class="btn-danger">
          <span class="material-symbols-rounded">delete</span>
          <span>Löschen</span>
        </button>
      </div>
    </div>
  `;

  openGenericModal(session.planName || 'Workout Details', modalContent);
}

/**
 * Render workout exercises
 */
function renderWorkoutExercises(session) {
  if (!session.exercises || session.exercises.length === 0) {
    return '<p style="color: #9ca3af;">Keine Übungen</p>';
  }

  return session.exercises.map((ex, index) => {
    const exercise = allExercises.find(e => e.id === ex.exerciseId);
    const exerciseName = exercise ? exercise.name : 'Übung';

    return `
      <div class="workout-exercise-item">
        <div class="exercise-number">${index + 1}</div>
        <div class="exercise-info" style="flex: 1;">
          <h5 style="font-size: 1rem; font-weight: 600; color: white; margin-bottom: 0.5rem;">
            ${exerciseName}
          </h5>
          <div class="exercise-sets">
            ${ex.sets && ex.sets.length > 0 ? ex.sets.map((set, i) => `
              <span class="set-badge">
                ${i + 1}: ${set.reps} reps${set.weight ? ` @ ${set.weight}kg` : ''}
              </span>
            `).join('') : '<span class="set-badge">Keine Sätze</span>'}
          </div>
        </div>
      </div>
    `;
  }).join('');
}

/**
 * Calculate total sets in a session
 */
function calculateTotalSets(session) {
  if (!session.exercises) return 0;
  return session.exercises.reduce((sum, ex) => sum + (ex.sets?.length || 0), 0);
}

/**
 * Calculate total volume (total reps) in a session
 */
function calculateTotalVolume(session) {
  if (!session.exercises) return 0;
  return session.exercises.reduce((total, ex) => {
    if (!ex.sets) return total;
    return total + ex.sets.reduce((sum, set) => sum + (set.reps || 0), 0);
  }, 0);
}

/**
 * Confirm and delete workout
 */
async function confirmDeleteWorkout(sessionId) {
  if (!confirm('Dieses Workout wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.')) {
    return;
  }

  try {
    const session = allSessions.find(s => s.id === sessionId);
    await deleteDoc(sessionsCollection, sessionId);

    if (session?.scheduleId) {
      const updatePayload = {
        completed: false,
        completedAt: null,
        sessionId: null
      };
      try {
        await updateDoc(scheduleCollection, session.scheduleId, updatePayload);
      } catch (error) {
        console.error('❌ Error clearing schedule reference:', error);
      }
    }
    closeWorkoutDetailModal();
    await loadSessions();

    // Re-render progress if we're on that view
    if (currentView === 'progress') {
      renderCurrentProgressTab();
    }

    triggerSuccessGlow();
    console.log('✅ Workout deleted');
  } catch (error) {
    console.error('❌ Error deleting workout:', error);
    alert('Fehler beim Löschen: ' + error.message);
  }
}

/**
 * Close workout detail modal
 */
function closeWorkoutDetailModal() {
  closeGenericModal();
}

/**
 * Format date (short): "22. Jan"
 */
function formatShortDate(date) {
  const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  const day = date.getDate();
  const month = months[date.getMonth()];
  return `${day}. ${month}`;
}

/**
 * Format date (full): "Montag, 22. Januar 2026"
 */
function formatFullDate(date) {
  const days = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
  const months = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

  const dayName = days[date.getDay()];
  const day = date.getDate();
  const month = months[date.getMonth()];
  const year = date.getFullYear();

  return `${dayName}, ${day}. ${month} ${year}`;
}

console.log('✅ Workout modal loaded');
