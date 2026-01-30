// ========================================
// DEMO PROGRESS DATA GENERATOR
// ========================================

/**
 * Erstellt Demo Progress-Daten für Testing
 * Kann später einfach gelöscht werden
 */
async function createDemoProgressData() {
  console.log('🎲 Erstelle Demo Progress-Daten...');

  try {
    // Hole alle Übungen
    const exercises = await getAllDocs(exercisesCollection);

    if (exercises.length === 0) {
      console.error('❌ Keine Übungen gefunden! Erstelle zuerst Übungen.');
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', 'Keine Übungen gefunden! Bitte erstelle zuerst ein paar Übungen.');
  }
      return;
    }

    console.log(`✅ ${exercises.length} Übungen gefunden`);

    // Nimm die ersten 5 Übungen (oder alle, wenn weniger als 5)
    const demoExercises = exercises.slice(0, Math.min(5, exercises.length));
    const now = new Date();
    let totalEntries = 0;

    // Für jede Übung: 12-18 Einträge über 8 Wochen
    for (const exercise of demoExercises) {
      console.log(`📊 Erstelle Daten für: ${exercise.name}`);

      const entryCount = 12 + Math.floor(Math.random() * 7); // 12-18 Einträge
      let baseReps = 10 + Math.floor(Math.random() * 6); // Start: 10-15 Reps

      for (let i = 0; i < entryCount; i++) {
        // Datum: Zufällig in den letzten 56 Tagen (8 Wochen)
        const daysAgo = Math.floor(Math.random() * 56);
        const date = new Date(now);
        date.setDate(date.getDate() - daysAgo);
        date.setHours(10 + Math.floor(Math.random() * 8), 0, 0, 0); // Zwischen 10-18 Uhr

        // Leichte Progression: Reps steigen über Zeit
        const progression = Math.floor((entryCount - i) * 0.1); // Frühere Einträge haben weniger Reps
        const repsPerSet = Math.max(6, baseReps - progression + Math.floor(Math.random() * 4));

        // Sets: 3-5 Sets pro Training
        const setCount = 3 + Math.floor(Math.random() * 3);
        const sets = [];

        for (let j = 0; j < setCount; j++) {
          // Fatigue-Effekt: Spätere Sets haben etwas weniger Reps
          const fatigueReduction = Math.floor(j * 1.2);
          const setReps = Math.max(5, repsPerSet - fatigueReduction + Math.floor(Math.random() * 3 - 1));

          sets.push({
            reps: setReps,
            weight: 0 // Bodyweight
          });
        }

        // Progress Entry erstellen
        const progressEntry = {
          exerciseId: exercise.id,
          date: firebase.firestore.Timestamp.fromDate(date),
          sets: sets
        };

        await addDoc(progressCollection, progressEntry);
        totalEntries++;
      }

      console.log(`  ✅ ${entryCount} Einträge für ${exercise.name} erstellt`);
    }

    console.log(`\n🎉 Fertig! ${totalEntries} Demo-Einträge erstellt für ${demoExercises.length} Übungen`);
    console.log('\n📋 Übungen mit Demo-Daten:');
    demoExercises.forEach(ex => console.log(`  - ${ex.name}`));

if (typeof showEdgeFeedback === 'function') {
  showEdgeFeedback('success', `✅ Demo-Daten erstellt!\n\n${totalEntries} Trainings für ${demoExercises.length} Übungen.\n\nGehe jetzt zur Progress-Seite!`);
}

    // Automatisch zur Progress-Seite wechseln
    if (typeof showView === 'function') {
      showView('progress');
    }

  } catch (error) {
    console.error('❌ Fehler beim Erstellen der Demo-Daten:', error);
if (typeof showEdgeFeedback === 'function') {
  showEdgeFeedback('error', 'Fehler beim Erstellen der Demo-Daten:\n' + error.message);
}
  }
}

/**
 * Löscht ALLE Progress-Einträge (zum Aufräumen)
 */
async function deleteAllProgressData() {
  const confirmed = confirm(
    '⚠️ ACHTUNG!\n\n' +
    'Möchtest du wirklich ALLE Progress-Daten löschen?\n\n' +
    'Diese Aktion kann nicht rückgängig gemacht werden!'
  );

  if (!confirmed) {
    console.log('❌ Abgebrochen');
    return;
  }

  console.log('🗑️ Lösche alle Progress-Daten...');

  try {
    const allProgress = await getAllDocs(progressCollection);
    console.log(`📊 Gefunden: ${allProgress.length} Einträge`);

    let deleted = 0;
    for (const entry of allProgress) {
      await deleteDoc(progressCollection, entry.id);
      deleted++;

      // Fortschritt anzeigen bei vielen Einträgen
      if (deleted % 10 === 0) {
        console.log(`  Gelöscht: ${deleted}/${allProgress.length}`);
      }
    }

    console.log(`✅ Alle ${deleted} Progress-Einträge gelöscht`);
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('success', `✅ Alle ${deleted} Progress-Einträge wurden gelöscht.`);
  }

    // Progress-Seite neu laden
    if (typeof initProgress === 'function') {
      initProgress();
    }

  } catch (error) {
    console.error('❌ Fehler beim Löschen:', error);
if (typeof showEdgeFeedback === 'function') {
  showEdgeFeedback('error', 'Fehler beim Löschen:\n' + error.message);
}
  }
}

// Funktionen im Window-Scope verfügbar machen
window.createDemoProgressData = createDemoProgressData;
window.deleteAllProgressData = deleteAllProgressData;

console.log('✅ Demo Progress Helper geladen');
console.log('💡 Kommandos:');
console.log('   createDemoProgressData()  - Erstellt Demo-Daten');
console.log('   deleteAllProgressData()   - Löscht alle Progress-Daten');
