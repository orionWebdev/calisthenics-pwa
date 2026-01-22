// ========================================
// DEMO SESSIONS DATA GENERATOR
// ========================================

/**
 * Erstellt Demo Sessions (Strength + Cardio) für Testing
 */
async function createDemoSessions() {
  console.log('🎲 Erstelle Demo Sessions...');

  try {
    // Hole Übungen
    const exercises = await getAllDocs(exercisesCollection);

    if (exercises.length === 0) {
      alert('❌ Keine Übungen gefunden! Erstelle zuerst ein paar Übungen.');
      return;
    }

    const demoExercises = exercises.slice(0, Math.min(5, exercises.length));
    const now = new Date();
    let totalSessions = 0;

    // Erstelle 15-20 zufällige Sessions über letzte 8 Wochen
    const sessionCount = 15 + Math.floor(Math.random() * 6);

    for (let i = 0; i < sessionCount; i++) {
      // Zufälliges Datum
      const daysAgo = Math.floor(Math.random() * 56);
      const date = new Date(now);
      date.setDate(date.getDate() - daysAgo);
      date.setHours(10 + Math.floor(Math.random() * 8), 0, 0, 0);

      // 60% Strength, 40% Cardio
      const isStrength = Math.random() > 0.4;

      if (isStrength) {
        // Strength Session
        const exerciseCount = 3 + Math.floor(Math.random() * 3); // 3-5 Übungen
        const selectedExercises = [];

        for (let j = 0; j < exerciseCount; j++) {
          const ex = demoExercises[Math.floor(Math.random() * demoExercises.length)];
          const setCount = 3 + Math.floor(Math.random() * 3); // 3-5 Sets
          const sets = [];

          const baseReps = 8 + Math.floor(Math.random() * 8); // 8-15 Reps

          for (let k = 0; k < setCount; k++) {
            const fatigueReduction = Math.floor(k * 1.5);
            const setReps = Math.max(5, baseReps - fatigueReduction + Math.floor(Math.random() * 3 - 1));
            sets.push({ reps: setReps, weight: 0 });
          }

          selectedExercises.push({
            exerciseId: ex.id,
            sets: sets
          });
        }

        const session = {
          type: 'strength',
          date: firebase.firestore.Timestamp.fromDate(date),
          exercises: selectedExercises,
          duration: 45 + Math.floor(Math.random() * 31) // 45-75 min
        };

        await addDoc(sessionsCollection, session);
        totalSessions++;
        console.log(`  ✅ Strength session ${i + 1}/${sessionCount}`);

      } else {
        // Cardio Session
        const activities = ['run', 'bike', 'swim', 'row'];
        const activityType = activities[Math.floor(Math.random() * activities.length)];

        let duration, distanceKm, pace;

        if (activityType === 'run') {
          duration = 20 + Math.floor(Math.random() * 41); // 20-60 min
          distanceKm = Math.round((duration / 5.5) * 10) / 10; // ca. 5:30 min/km
          pace = duration / distanceKm;
        } else if (activityType === 'bike') {
          duration = 30 + Math.floor(Math.random() * 61); // 30-90 min
          distanceKm = Math.round((duration / 2.5) * 10) / 10; // ca. 25 km/h
          pace = duration / distanceKm;
        } else if (activityType === 'swim') {
          duration = 20 + Math.floor(Math.random() * 31); // 20-50 min
          distanceKm = Math.round((duration / 30) * 10) / 10; // ca. 2 km/h
          pace = duration / distanceKm;
        } else {
          duration = 20 + Math.floor(Math.random() * 31); // 20-50 min
          distanceKm = Math.round((duration / 4) * 10) / 10;
          pace = duration / distanceKm;
        }

        const session = {
          type: 'cardio',
          date: firebase.firestore.Timestamp.fromDate(date),
          activityType: activityType,
          duration: duration,
          distanceKm: distanceKm,
          pace: pace
        };

        await addDoc(sessionsCollection, session);
        totalSessions++;
        console.log(`  ✅ Cardio session (${activityType}) ${i + 1}/${sessionCount}`);
      }
    }

    console.log(`\n🎉 ${totalSessions} Demo-Sessions erstellt!`);
    alert(`✅ Demo-Sessions erstellt!\n\n${totalSessions} Sessions (Strength + Cardio)\n\nGehe zur Progress-Seite!`);

    // Zur Progress-Seite wechseln
    if (typeof showView === 'function') {
      showView('progress');
    }

  } catch (error) {
    console.error('❌ Fehler beim Erstellen der Demo-Sessions:', error);
    alert('Fehler: ' + error.message);
  }
}

/**
 * Löscht ALLE Sessions
 */
async function deleteAllSessions() {
  const confirmed = confirm(
    '⚠️ ACHTUNG!\n\n' +
    'Möchtest du wirklich ALLE Sessions löschen?\n\n' +
    'Diese Aktion kann nicht rückgängig gemacht werden!'
  );

  if (!confirmed) {
    console.log('❌ Abgebrochen');
    return;
  }

  console.log('🗑️ Lösche alle Sessions...');

  try {
    const allSessions = await getAllDocs(sessionsCollection);
    console.log(`📊 Gefunden: ${allSessions.length} Sessions`);

    let deleted = 0;
    for (const session of allSessions) {
      await deleteDoc(sessionsCollection, session.id);
      deleted++;

      if (deleted % 5 === 0) {
        console.log(`  Gelöscht: ${deleted}/${allSessions.length}`);
      }
    }

    console.log(`✅ Alle ${deleted} Sessions gelöscht`);
    alert(`✅ Alle ${deleted} Sessions wurden gelöscht.`);

    // Progress neu laden
    if (typeof initProgressV2 === 'function') {
      initProgressV2();
    }

  } catch (error) {
    console.error('❌ Fehler beim Löschen:', error);
    alert('Fehler: ' + error.message);
  }
}

// Expose functions
window.createDemoSessions = createDemoSessions;
window.deleteAllSessions = deleteAllSessions;

console.log('✅ Demo Sessions Helper geladen');
console.log('💡 Kommandos:');
console.log('   createDemoSessions()  - Erstellt Demo Sessions (Strength + Cardio)');
console.log('   deleteAllSessions()   - Löscht alle Sessions');
