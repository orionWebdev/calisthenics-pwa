// ========================================
// I18N + FORMATTERS
// ========================================

const translations = {
  de: {
    common: {
      workout: 'Workout',
      strength: 'Kraft',
      bodyweight: 'Bodyweight',
      cardio: 'Cardio',
      recovery: 'Recovery',
      session: 'Session',
      sessions: 'Sessions',
      days: 'Tage',
      weeks: 'Wochen',
      add: 'Hinzufügen',
      addSession: 'Session hinzufügen',
      view: 'Ansehen',
      viewDetails: 'Details ansehen',
      delete: 'Löschen',
      close: 'Schließen',
      select: 'Auswahl',
      start: 'Starten',
      startAgain: 'Erneut starten',
      editSession: 'Session bearbeiten',
      duration: 'Dauer',
      notes: 'Notizen',
      activity: 'Aktivität',
      time: 'Zeit',
      distance: 'Distanz',
      pace: 'Pace',
      loading: 'Lade Daten...',
      notAvailable: '-',
      save: 'Speichern',
      cancel: 'Abbrechen',
      edit: 'Bearbeiten',
      next: 'Weiter',
      back: 'Zurück',
      done: 'Fertig',
      optional: 'optional',
      minutes: 'Minuten',
      secondsShort: '{n}s'
    },
    nav: {
      dashboard: 'Home',
      progress: 'Progress',
      calendar: 'Kalender',
      training: 'Training',
      profile: 'Profil',
      plans: 'Pläne',
      exercises: 'Übungen'
    },
    difficulty: {
      beginner: 'Anfänger',
      intermediate: 'Fortgeschritten',
      advanced: 'Profi',
      elite: 'Elite',
      label: 'Schwierigkeit',
      descriptions: {
        beginner: 'Ideal für Einsteiger ohne Vorkenntnisse',
        intermediate: 'Für Trainierende mit Grundkenntnissen',
        advanced: 'Für erfahrene Athleten',
        elite: 'Für Profis mit mehrjähriger Erfahrung'
      }
    },
    plan: {
      types: {
        strength: 'Kraft',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio',
        recovery: 'Recovery',
        unknown: 'Unbekannter Typ'
      },
      typeOptions: {
        strength: 'Kraft (Gym)',
        bodyweight: 'Bodyweight (Calisthenics)',
        cardio: 'Cardio',
        recovery: 'Recovery'
      },
      filters: {
        all: 'Alle',
        strength: 'Kraft',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio',
        recovery: 'Recovery',
        difficultyAll: 'Alle Schwierigkeiten'
      },
      sections: {
        basics: 'Grundlagen',
        contentStrength: 'Übungen',
        contentBodyweight: 'Übungen',
        contentCardio: 'Cardio-Ziel',
        contentRecovery: 'Recovery-Ziel'
      },
      list: {
        emptyTitle: 'Keine Pläne gefunden',
        emptyBody: 'Erstelle deinen ersten Plan',
        emptyCta: 'Plan erstellen',
        loading: 'Lade Pläne...'
      },
      meta: {
        exercises: '{count} Übungen',
        goalPrefix: 'Ziel',
        duration: '{minutes} min',
        distance: '{distance} km',
        recoveryFallback: 'Ohne Ziel',
        cardioFallback: 'Cardio'
      },
      actions: {
        newPlan: 'Neuer Plan',
        create: 'Plan erstellen',
        start: 'Workout starten',
        edit: 'Bearbeiten',
        save: 'Speichern',
        cancel: 'Abbrechen',
        next: 'Weiter'
      },
      modal: {
        createTitle: 'Neuer Plan',
        editTitle: 'Plan bearbeiten'
      },
      cardioGoal: {
        label: 'Cardio-Ziel',
        liss: 'LISS',
        hiit: 'HIIT',
        zone2: 'Zone 2',
        tempo: 'Tempo',
        info: {
          liss: 'Low Intensity Steady State - Gleichmäßige niedrige Intensität',
          hiit: 'High Intensity Interval Training - Kurze intensive Intervalle',
          zone2: 'Aerobe Zone (60-70% HFmax) - Grundlagenausdauer',
          tempo: 'Mittlere bis hohe Intensität - Laktatschwelle'
        }
      },
      cardioGoalType: {
        label: 'Zieltyp',
        liss: 'LISS',
        hiit: 'HIIT',
        intervals: 'Intervals',
        freestyle: 'Freestyle',
        info: {
          liss: 'Gleichmäßige niedrige Intensität für Grundlagenausdauer.',
          hiit: 'Kurze, intensive Intervalle mit Pausen.',
          intervals: 'Wiederholte Belastungsblöcke mit definierten Pausen.',
          freestyle: 'Freies Cardio ohne festen Intensitätsplan.'
        }
      },
      cardio: {
        durationLabel: 'Dauer (Minuten)',
        distanceLabel: 'Distanz (km)',
        activityLabel: 'Aktivitätstyp',
        targetHint: 'Mind. Dauer oder Distanz empfohlen',
        activityOptions: {
          run: 'Laufen',
          bike: 'Radfahren',
          swim: 'Schwimmen',
          hike: 'Wandern',
          row: 'Rudern',
          other: 'Sonstiges'
        }
      },
      recovery: {
        durationLabel: 'Dauer (Minuten)',
        targetHint: 'Optional, aber empfohlen'
      },
      name: 'Planname',
      namePlaceholder: 'z.B. Push Workout',
      type: 'Typ',
      duration: 'Dauer (Min)',
      icon: 'Plan-Icon',
      notes: 'Notizen',
      notesPlaceholder: 'Zusätzliche Informationen...',
      exercises: 'Übungen',
      addExercise: 'Übung hinzufügen',
      exercisesHint: 'Füge Übungen zu deinem Plan hinzu',
      exercisesEmptyTitle: 'Noch keine Übungen hinzugefügt',
      exercisesEmptyBody: 'Füge Übungen aus der Datenbank hinzu',
      exerciseRemoveConfirm: 'Übung aus dem Plan entfernen?',
      exerciseConfig: {
        title: 'Übung konfigurieren',
        setsLabel: 'Sätze *',
        setsShort: 'Sätze',
        repsLabel: 'Wiederholungen',
        repsPlaceholder: 'z.B. 12 oder 8-10',
        holdLabel: 'Halten (Sek)',
        holdPlaceholder: 'z.B. 30',
        restLabel: 'Pause',
        restNone: 'Keine Pause',
        restMin: 'Min',
        restSec: 'Sek',
        notesLabel: 'Notizen',
        notesPlaceholder: 'z.B. Tempo, Progressionen...'
      },
      exercisePicker: {
        title: 'Übungen auswählen',
        searchPlaceholder: 'Übung suchen...',
        noExercisesTitle: 'Keine Übungen verfügbar',
        noExercisesBody: 'Erstelle zuerst Übungen in der Übungsdatenbank',
        noResultsTitle: 'Keine Übungen gefunden',
        noResultsBody: 'Versuche einen anderen Suchbegriff oder Filter',
        filterInfo: '{count} von {total} Übungen gefunden ({filters})',
        filterSearch: 'Suche: "{term}"',
        filterMuscle: 'Muskelgruppe: {muscle}',
        addSelected: '{count} Übungen hinzufügen',
        addSelectedOne: '1 Übung hinzufügen',
        selectHint: 'Übungen auswählen'
      },
      deleteConfirm: 'Plan wirklich löschen?',
      deleteSuccess: 'Plan gelöscht.',
      deleteError: 'Fehler beim Löschen des Plans.',
      picker: {
        title: 'Plan auswählen',
        searchPlaceholder: 'Plan suchen...',
        noPlans: 'Keine Pläne verfügbar',
        createFirst: 'Erstelle zuerst einen Trainingsplan',
        noResults: 'Keine Treffer'
      }
    },
    calendar: {
      quickEntry: {
        title: 'Schnell-Eintrag',
        name: 'Name',
        namePlaceholder: 'z.B. Morgenlauf',
        type: 'Trainingsart',
        duration: 'Dauer (Min)',
        durationOptional: 'optional',
        add: 'Hinzufügen',
        nameRequired: 'Bitte gib einen Namen ein'
      },
      addPlan: 'Plan hinzufügen',
      quickAdd: 'Schnell-Eintrag',
      orQuickEntry: 'Oder Schnell-Eintrag erstellen',
      orSelectPlan: 'oder Plan auswählen',
      today: 'Heute',
      noPlannedWorkouts: 'Keine Trainings geplant',
      entryAdded: 'Training hinzugefügt',
      saveError: 'Fehler beim Speichern',
      untitled: 'Unbenannt',
      confirmRemove: 'Training wirklich entfernen?',
      monthNames: {
        january: 'Januar',
        february: 'Februar',
        march: 'März',
        april: 'April',
        may: 'Mai',
        june: 'Juni',
        july: 'Juli',
        august: 'August',
        september: 'September',
        october: 'Oktober',
        november: 'November',
        december: 'Dezember'
      },
      dayNames: {
        monday: 'Montag',
        tuesday: 'Dienstag',
        wednesday: 'Mittwoch',
        thursday: 'Donnerstag',
        friday: 'Freitag',
        saturday: 'Samstag',
        sunday: 'Sonntag'
      },
      dayNamesShort: {
        mon: 'Mo',
        tue: 'Di',
        wed: 'Mi',
        thu: 'Do',
        fri: 'Fr',
        sat: 'Sa',
        sun: 'So'
      },
      agenda: {
        title: 'Geplante Trainings'
      },
      errors: {
        notFound: 'Training nicht gefunden',
        engineNotLoaded: 'Workout-Engine nicht geladen',
        modalNotAvailable: 'Erfassungsmodul nicht verfügbar'
      }
    },
    exercise: {
      title: 'Übung',
      name: 'Übungsname',
      namePlaceholder: 'z.B. Klimmzüge',
      muscleGroups: 'Muskelgruppen',
      muscles: {
        chest: 'Brust',
        back: 'Rücken',
        shoulders: 'Schultern',
        biceps: 'Bizeps',
        triceps: 'Trizeps',
        core: 'Core',
        legs: 'Beine',
        fullBody: 'Ganzkörper',
        arms: 'Arme',
        calf: 'Waden',
        cardio: 'Cardio',
        mobility: 'Mobility'
      },
      muscleDescriptions: {
        all: 'Alle Übungen anzeigen',
        chest: 'Brustmuskulatur',
        back: 'Rückenmuskulatur',
        biceps: 'Bizepsmuskulatur',
        triceps: 'Trizepsmuskulatur',
        shoulders: 'Schultermuskulatur',
        core: 'Bauch- und Rumpfmuskulatur',
        legs: 'Beinmuskulatur',
        fullBody: 'Ganzkörpertraining',
        arms: 'Bizeps, Trizeps, Unterarme',
        calf: 'Wadenmuskulatur'
      },
      muscleFilter: {
        title: 'Muskelgruppe filtern',
        selectTitle: 'Muskelgruppen auswählen',
        searchPlaceholder: 'Muskelgruppe suchen...',
        selectPlaceholder: 'Muskelgruppen auswählen...',
        required: 'Muskelgruppen *'
      },
      difficultyFilter: {
        title: 'Schwierigkeit filtern'
      },
      equipmentFilter: {
        title: 'Equipment filtern'
      },
      filters: {
        allMuscles: 'Alle Muskelgruppen',
        allDifficulties: 'Alle Schwierigkeiten'
      },
      equipment: 'Equipment',
      discipline: 'Disziplin',
      visual: 'Übungs-Icon',
      selectIcon: 'Icon auswählen',
      listSectionOther: '#',
      instructions: {
        title: 'Anleitung',
        hint: 'Beschreibe die Ausführung Schritt für Schritt.',
        stepTitle: 'Schritt {number}',
        stepPlaceholder: 'Beschreibe diesen Schritt...',
        addStep: 'Schritt hinzufügen',
        removeStep: 'Schritt entfernen',
        noSteps: 'Noch keine Schritte hinzugefügt',
        advanced: {
          title: 'Erweiterte Hinweise',
          add: 'Erweiterte Hinweise hinzufügen',
          hide: 'Erweiterte Hinweise ausblenden',
          emptyList: 'Noch keine Hinweise hinzugefügt',
          cues: 'Cues',
          cuesPlaceholder: 'Kurze Hinweise zur Ausführung...',
          cuesAdd: 'Cue hinzufügen',
          mistakes: 'Häufige Fehler',
          mistakesPlaceholder: 'Typische Fehler und wie man sie vermeidet...',
          mistakesAdd: 'Fehler hinzufügen',
          progressions: 'Progressionen',
          progressionsPlaceholder: 'Leichtere oder schwierigere Varianten...',
          progressionsAdd: 'Progression hinzufügen',
          setup: 'Vorbereitung',
          setupPlaceholder: 'Aufbau, Ausgangsposition und Vorbereitung...'
        },
        setup: 'Vorbereitung',
        setupPlaceholder: 'Ausgangsposition und Griffhaltung...',
        setupDefault: 'Finde eine stabile Ausgangsposition, aktiviere Core und halte Spannung.',
        execution: 'Ausführung',
        executionPlaceholder: 'Bewegungsablauf beschreiben...',
        executionDefault: 'Noch keine Ausführung hinterlegt.',
        cues: 'Cues',
        cuesPlaceholder: 'Wichtige Hinweise während der Ausführung...',
        cuesDefault: 'Achte auf kontrollierte Bewegung und stabile Körperspannung.',
        mistakes: 'Häufige Fehler',
        mistakesPlaceholder: 'Typische Fehler und wie man sie vermeidet...',
        mistakesDefault: 'Vermeide Schwung, unkontrollierte Endpositionen und instabile Gelenkwinkel.',
        progressions: 'Progressionen',
        progressionsPlaceholder: 'Leichtere und schwierigere Varianten...',
        progressionsDefault: 'Mehr Range, langsamere Exzentrik oder Zusatzgewicht erhöhen die Intensität.'
      },
      categories: {
        upper: 'Oberkörper',
        lower: 'Unterkörper',
        core: 'Core',
        fullBody: 'Ganzkörper',
        cardio: 'Cardio',
        mobility: 'Mobilität'
      },
      quickCreate: {
        title: 'Neue Übung',
        button: 'Neue Übung erstellen',
        hint: 'Übung fehlt? Erstelle sie hier schnell.',
        saved: 'Übung erstellt und hinzugefügt'
      },
      type: {
        label: 'Typ',
        strength: 'Kraft',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio',
        mobility: 'Mobilität',
        recovery: 'Recovery'
      },
      pattern: {
        label: 'Bewegungsmuster',
        push: 'Push',
        pull: 'Pull',
        legs: 'Beine',
        core: 'Core',
        full: 'Ganzkörper'
      },
      visualAdd: 'Visual hinzufügen',
      visualUrlPlaceholder: 'Bild-URL eingeben...',
      visualRemove: 'Visual entfernen',
      variants: {
        label: 'Varianten',
        add: 'Variante hinzufügen',
        namePlaceholder: 'Variantenname...',
        notePlaceholder: 'Kurze Notiz (optional)...',
        remove: 'Variante entfernen',
        empty: 'Noch keine Varianten'
      },
      notesLabel: 'Notizen',
      notesPlaceholder: 'Allgemeine Notizen zur Übung...',
      create: {
        title: 'Neue Übung',
        stepBasics: 'Grundlagen',
        stepDetails: 'Details',
        stepOptional: 'optional'
      },
      editTitle: 'Übung bearbeiten',
      loading: 'Lade Übungen...',
      feedback: {
        saveError: 'Fehler beim Speichern der Übung!',
        deleted: 'Eintrag gelöscht',
        deleteError: 'Fehler beim Löschen'
      },
      detail: {
        useInPlan: 'In Plan verwenden'
      },
      searchPlaceholder: 'Übungen suchen...',
      noResultsTitle: 'Keine Treffer',
      noResultsHint: 'Versuch einen anderen Begriff oder erstelle eine neue Übung.',
      createNew: 'Neue Übung erstellen',
      deleteConfirm: 'Übung wirklich löschen?',
      deleteUsedInPlans: 'Diese Übung wird in {count} Plänen verwendet ({plans}). Trotzdem löschen? Sie bleibt in bestehenden Sessions erhalten.',
      deleted: 'Übung gelöscht.',
      deleteError: 'Fehler beim Löschen der Übung.'
    },
    workout: {
      quick: {
        title: 'Workout Schnell-Eintrag',
        date: 'Datum *',
        dateRequired: 'Bitte wähle ein Datum',
        name: 'Workout Name',
        duration: 'Dauer (Minuten)',
        type: 'Typ',
        difficulty: 'Schwierigkeit',
        bodyweight: 'Bodyweight',
        bodyweightDesc: 'Training mit Eigengewicht',
        weights: 'Gewichte',
        weightsDesc: 'Gym / Hanteln',
        nameRequired: 'Bitte gib einen Workout Namen ein',
        durationRequired: 'Bitte gib eine gültige Dauer ein',
        saveError: 'Fehler beim Speichern des Workouts'
      },
      screen: {
        exercisesButton: 'Übungen ({completed}/{total})',
        exercisesSheetTitle: 'Übungen',
        cancelWorkout: 'Abbrechen',
        endWorkout: 'Workout beenden',
        endWorkoutConfirm: 'Workout wirklich beenden?',
        endWorkoutConfirmText: 'Alle bisherigen Sätze werden gespeichert.',
        nextExercise: 'Nächste Übung',
        finishWorkout: 'Workout abschließen',
        currentExercise: 'Aktuelle Übung',
        goal: 'Ziel',
        rest: 'Pause',
        exerciseOf: 'Übung {current} von {total}',
        noActiveWorkout: 'Kein aktives Workout',
        noActiveWorkoutText: 'Starte ein Training aus dem Kalender oder einem Plan.',
        toPlans: 'Zu den Plänen',
        switchToExercise: 'Zu dieser Übung wechseln',
        saveWorkout: 'Workout speichern',
        discardWorkout: 'Workout verwerfen',
        discardConfirm: 'Workout wirklich verwerfen? Alle Fortschritte gehen verloren.',
        restTimer: 'Pause',
        bodyweight: 'Bodyweight',
        weighted: 'Gewichte',
        cardio: 'Cardio',
        recovery: 'Recovery',
        addSet: 'Satz hinzufügen',
        exerciseProgress: '{completed} / {total} Übungen',
        timerPause: 'Pausieren',
        timerResume: 'Fortsetzen',
        timerSkip: 'Ueberspringen',
        timerStart: 'Timer starten',
        timerAdd: '+10s',
        timerSub: '-10s',
        timerDone: 'Pause vorbei!',
        discardConfirmTitle: 'Workout verwerfen?',
        endWorkoutAction: 'Beenden',
        logWorkout: 'Workout erfassen',
        emptyHint: 'Füge Übungen hinzu, um dein Workout zu starten',
        addExercise: 'Übung hinzufügen',
        searchExercise: 'Übung suchen...',
        noExercisesFound: 'Keine Übungen gefunden',
        freeWorkout: 'Freies Workout',
        menu: 'Menü'
      },
      banner: {
        active: 'Aktives Workout: {name}',
        resume: 'Fortsetzen',
        cancel: 'Abbrechen',
        cancelConfirm: 'Aktives Workout wirklich abbrechen? Alle Fortschritte gehen verloren.',
        cancelWorkoutConfirm: 'Workout wirklich abbrechen? Alle Fortschritte gehen verloren.'
      },
      targetHold: 'Ziel: {seconds} halten',
      holdDurationLabel: 'Haltedauer (Sek.)',
      hold: 'Halten',
      setLogger: {
        title: 'Satz {number} loggen',
        reps: 'Wiederholungen',
        weight: 'Gewicht',
        weightUnit: 'kg',
        logSet: 'Satz loggen',
        addSet: 'Satz hinzufügen',
        duplicateLast: 'Letzten Satz kopieren',
        completedSets: 'Abgeschlossene Sätze',
        set: 'Satz',
        target: 'Ziel',
        targetSets: '{sets} Sätze',
        targetReps: '{reps} Wdh',
        rest: '{seconds}s Pause',
        noSets: 'Noch keine Sätze geloggt',
        enterReps: 'Bitte gib die Anzahl der Wiederholungen ein',
        enterHold: 'Bitte gib die Haltedauer ein',
        atLeastOneSet: 'Bitte logge mindestens einen Satz bevor du weitergehst',
        deleteSet: 'Satz löschen',
        deleteSetConfirm: 'Diesen Satz wirklich löschen?',
        decreaseWeight: 'Gewicht verringern',
        increaseWeight: 'Gewicht erhöhen',
        stepModeChanged: 'Schrittweite: {step} {unit}'
      },
      exercise: {
        current: 'Aktuelle Übung',
        next: 'Nächste Übung',
        finish: 'Workout beenden',
        progress: '{completed} / {total} Übungen'
      },
      logging: {
        exercisesOptional: 'Übungen (optional)',
        addExercise: 'Übung hinzufügen',
        exerciseAlreadyAdded: 'Übung bereits hinzugefügt',
        sets: 'Sätze',
        reps: 'Wiederholungen pro Satz',
        set: 'Satz',
        totalReps: 'Wdh.'
      },
      lastPerformance: 'Letztes Mal',
      noPreviousData: 'Keine vorherigen Daten',
      copyLastSet: 'Letzten Satz kopieren',
      relativeTime: {
        today: 'heute',
        yesterday: 'gestern',
        daysAgo: 'vor {n} Tagen',
        oneWeekAgo: 'vor 1 Woche',
        weeksAgo: 'vor {n} Wochen'
      },
      cardio: {
        duration: 'Dauer (Min.)',
        distance: 'Distanz (km)',
        rpe: 'Belastung (1–5)',
        pace: 'Pace',
        log: 'Cardio loggen'
      },
      recovery: {
        duration: 'Dauer (Min.)',
        log: 'Recovery loggen'
      },
      postWorkout: {
        title: 'Workout abgeschlossen!',
        fallbackName: 'Training',
        minutes: 'Minuten',
        sets: 'Sets',
        exercises: 'Übungen',
        toProgress: 'Zum Fortschritt',
        comparisonTitle: 'Vergleich zum letzten Mal',
        time: 'Zeit',
        volume: 'Volumen'
      },
      feedback: {
        saved: 'Workout gespeichert!',
        saveError: 'Fehler beim Speichern des Workouts',
        restartError: 'Fehler beim Neustarten des Workouts',
        exerciseComplete: 'Übung abgeschlossen!',
        enterDuration: 'Bitte Dauer eingeben'
      },
      editDate: {
        prompt: 'Neues Datum (YYYY-MM-DD):',
        error: 'Ungültiges Datumsformat. Bitte verwende YYYY-MM-DD'
      }
    },
    workoutModal: {
      exercises: 'Übungen',
      sets: 'Sätze',
      noExercises: 'Keine Übungen',
      exercise: 'Übung',
      noSets: 'Keine Sätze',
      addSet: 'Satz hinzufügen',
      removeSet: 'Satz entfernen',
      reps: 'Wdh',
      deleteConfirm: 'Dieses Workout wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
      deleteError: 'Fehler beim Löschen',
      sessionNotFound: 'Session nicht gefunden.',
      invalidDuration: 'Bitte gib eine gültige Dauer ein.',
      saveError: 'Fehler beim Speichern'
    },
    bottomSheet: {
      title: 'Auswählen',
      searchPlaceholder: 'Suchen...',
      noOptions: 'Keine Optionen gefunden',
      selected: 'ausgewählt'
    },
    templateFeedback: {
      saved: 'Vorlage gespeichert',
      saveError: 'Fehler beim Speichern',
      deleted: 'Vorlage gelöscht',
      deleteError: 'Fehler beim Löschen',
      deleteConfirm: 'Diese Vorlage wirklich löschen?',
      notFound: 'Vorlage nicht gefunden',
      planned: 'Vorlage geplant',
      planError: 'Fehler beim Planen',
      nameRequired: 'Bitte gib einen Namen ein'
    },
    numberPicker: {
      repsTitle: 'Wiederholungen',
      setsTitle: 'Sätze',
      weightTitle: 'Gewicht',
      holdTitle: 'Haltedauer'
    },
    template: {
      sessionTemplate: 'Session-Vorlage',
      workoutTemplate: 'Workout-Vorlage',
      createTemplate: 'Vorlage erstellen',
      selectType: 'Typ auswählen',
      cardioTemplate: {
        title: 'Cardio-Vorlage',
        name: 'Name',
        namePlaceholder: 'z.B. Morgenlauf',
        targetDuration: 'Ziel-Dauer (Min)',
        targetDistance: 'Ziel-Distanz (km)',
        activityType: 'Aktivitätstyp',
        intervals: 'Intervalle',
        intervalsDescription: 'Optionale Intervall-Struktur',
        notes: 'Notizen',
        trainingType: 'Trainingsart',
        trainingTypes: {
          liss: 'LISS',
          zone2: 'Zone 2',
          hiit: 'HIIT',
          tempo: 'Tempo',
          intervals: 'Intervalle'
        },
        trainingTypeInfo: {
          liss: 'Low Intensity Steady State - Gleichmäßige, niedrige Intensität. Ideal für Grundlagenausdauer und aktive Erholung.',
          zone2: 'Training in der aeroben Zone (60-70% max. Herzfrequenz). Verbessert die Fettverbrennung und Grundlagenausdauer.',
          hiit: 'High Intensity Interval Training - Kurze, intensive Belastungsphasen mit Erholungspausen. Effizient für Fitness.',
          tempo: 'Gleichmäßiges Training bei mittlerer bis hoher Intensität. Verbessert die Laktatschwelle.',
          intervals: 'Wechsel zwischen Belastungs- und Erholungsphasen. Flexibel anpassbar.'
        }
      },
      recoveryTemplate: {
        title: 'Recovery-Vorlage',
        name: 'Name',
        namePlaceholder: 'z.B. Morgen-Yoga',
        targetDuration: 'Ziel-Dauer (Min)',
        focusArea: 'Fokusbereich',
        focusAreas: {
          fullBody: 'Ganzkörper',
          upperBody: 'Oberkörper',
          lowerBody: 'Unterkörper',
          back: 'Rücken',
          hips: 'Hüften',
          shoulders: 'Schultern'
        },
        notes: 'Notizen'
      },
      wizard: {
        step1: 'Typ',
        step2: 'Details',
        step3: 'Übungen',
        step4: 'Überprüfung'
      },
      strengthTemplate: {
        title: 'Kraft-Vorlage',
        discipline: 'Trainingsart',
        disciplines: {
          bodyweight: 'Bodyweight / Calisthenics',
          weights: 'Gewichte / Gym'
        },
        disciplineInfo: {
          bodyweight: 'Training mit dem eigenen Körpergewicht. Gewicht ist optional (z.B. Gewichtsweste).',
          weights: 'Training mit Hanteln, Maschinen oder Gewichten. Gewichtsangabe ist wichtig für Tracking.'
        }
      },
      planIcon: 'Plan-Icon',
      selectPlanIcon: 'Icon für diesen Plan wählen'
    },
    planner: {
      scheduleSession: 'Session planen',
      scheduleWorkout: 'Workout planen',
      selectTemplate: 'Vorlage auswählen',
      noTemplates: 'Keine Vorlagen verfügbar'
    },
    format: {
      duration: {
        zero: '0 min',
        minutes: '{minutes} min',
        hours: '{hours}h',
        hoursMinutes: '{hours}h {minutes}m'
      },
      distanceKm: '{distance} km',
      pace: {
        na: '-',
        value: '{min}:{sec} min/km'
      }
    },
    balance: {
      context: {
        balanced: 'ausgeglichen',
        strength: 'leicht kraftlastig',
        cardio: 'leicht cardio-fokussiert',
        lowData: 'Noch wenig Daten - einfach weitermachen'
      }
    },
    dashboard: {
      today: 'Heute',
      quickStats: {
        thisWeek: 'Diese Woche',
        sessions: 'Sessions',
        movementMinutes: 'Bewegungsmin.'
      },
      primary: {
        title: 'Workout',
        subtitleActive: 'Ein Workout ist aktiv.',
        subtitleInactive: 'Wähle Kraft, Cardio oder Recovery.',
        helper: 'Starte oder setze dein aktuelles Training fort.',
        start: 'Workout starten',
        resume: 'Workout fortsetzen'
      },
      scheduled: {
        title: 'Geplant für heute'
      },
      addWorkout: {
        title: 'Workout hinzufügen'
      },
      logWorkout: {
        title: 'Workout erfassen',
        subtitle: 'Logge, starte oder plane ein Workout',
        log: 'Workout loggen',
        logDesc: 'Erfasse ein abgeschlossenes Training',
        plan: 'Workout planen',
        planDesc: 'Plane ein Training im Kalender',
        start: 'Workout starten',
        startDesc: 'Starte ein Training aus deinen Plänen'
      },
      hybridBalance: {
        title: 'Hybrid Balance',
        subtitle: 'Letzte {days} Tage',
        description: 'Zeigt die Zeitverteilung zwischen Kraft und Cardio.',
        aria: 'Kraft {strength} Prozent, Cardio {cardio} Prozent'
      },
      recent: {
        title: 'Letzte Sessions',
        description: 'Die letzten Sessions in chronologischer Reihenfolge.',
        empty: 'Noch keine Sessions',
        viewAll: 'Alle anzeigen'
      },
      allSessions: {
        title: 'Alle Sessions',
        empty: 'Noch keine Sessions vorhanden',
        today: 'Heute',
        yesterday: 'Gestern',
        earlier: 'Früher'
      },
      activityCalendar: {
        thisMonth: 'Diesen Monat',
        durationUnit: 'Bewegungsstunden',
        emptyState: 'Noch keine Sessions in diesem Zeitraum',
        more: 'Mehr'
      },
      trainingTypes: {
        strength: 'Krafttraining',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio',
        recovery: 'Recovery'
      },
      calendar: {
        tabActivity: 'Aktivität',
        tabPlan: 'Planen',
        addTraining: 'Training hinzufügen',
        prevMonth: 'Vorheriger Monat',
        nextMonth: 'Nächster Monat'
      },
      planCalendar: {
        title: 'Planungskalender'
      },
      startWorkout: {
        selectPlan: 'Plan auswählen',
        selectPlanDesc: 'Starte ein Training aus deinen Plänen',
        newWorkout: 'Neues Training',
        newWorkoutDesc: 'Starte ein leeres Workout und füge Übungen hinzu'
      }
    },
    progress: {
      tabs: {
        overview: 'Übersicht',
        strength: 'Kraft',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio'
      },
      overview: {
        title: 'Fortschritt',
        subtitle: 'Kraft- und Cardio-Tracking',
        emptyTitle: 'Noch keine Trainings',
        emptyBody: 'Starte dein erstes Training oder logge eine Session, um deinen Fortschritt zu sehen',
        periodDays: '{days} Tage',
        stats: {
          strengthCount: 'Kraft-Sessions',
          cardioCount: 'Cardio-Sessions',
          totalTime: 'Trainingszeit',
          streak: 'Streak',
          streakUnit: 'Tage'
        },
        consistencyHelper: 'Konsistenz basiert auf deinen Trainings in diesem Zeitraum.',
        hybridBalanceHelper: 'Balance zeigt den Zeitanteil von Kraft und Cardio.',
        activityCalendarTitle: 'Aktivitätskalender',
        activityCalendarHelper: 'Tippe einen Tag, um Sessions zu sehen.',
        activityDayEmpty: 'Keine Sessions an diesem Tag',
        addSessionAria: 'Session hinzufügen'
      },
      hybridBalance: {
        title: 'Hybrid Balance',
        subtitle: 'Letzte {days} Tage',
        toggleLabel: 'Zeitraum',
        sevenDays: '7D',
        thirtyDays: '30D',
        metaStrength: 'Kraft {duration}',
        metaCardio: 'Cardio {duration}'
      },
      consistency: {
        title: 'Rhythmus & Konsistenz',
        sessionsPerWeek: 'Sessions/Woche',
        timePerWeek: 'Zeit/Woche',
        daysSinceLast: 'Seit letzter Session',
        daysSinceLastUnit: 'Tage',
        restDays: 'Ruhetage',
        trainingDays: 'Trainingstage'
      },
      insights: {
        noSessions: 'Noch keine Sessions in diesem Zeitraum.',
        balanced: 'Ausgewogene Mischung aus Kraft und Cardio.',
        strengthFocused: 'Fokus auf Krafttraining.',
        cardioFocused: 'Fokus auf Cardio.',
        restDay: 'Heute Ruhetag.',
        sessionsThisWeek: '{count} Trainingstage in diesem Zeitraum.'
      },
      form: {
        title: 'Trainingsphase',
        buildingBaseline: 'Baseline wird aufgebaut',
        zoneDetrained: 'Detrainiert',
        zoneDeclining: 'Formverlust',
        zoneRecovery: 'Erholung',
        zoneMaintaining: 'Formerhalt',
        zoneBuilding: 'Basis',
        zoneProductive: 'Formaufbau',
        zonePeakForm: 'Topform',
        trendRising: 'Trend steigend',
        trendStable: 'Trend stabil',
        trendFalling: 'Trend fallend',
        hintDetrained: 'Du bist lange inaktiv gewesen. Starte behutsam mit kurzen, leichten Einheiten.',
        hintDeclining: 'Deine Form nimmt ab. Trainiere bald wieder, um den Abwärtstrend zu stoppen.',
        hintRecovery: 'Dein Körper erholt sich. Nutze die Pause – bei Bedarf leichte aktive Erholung.',
        hintMaintaining: 'Du hältst dein aktuelles Niveau. Für Fortschritte steigere die Belastung.',
        hintBuilding: 'Du trainierst regelmäßig und baust eine solide Basis auf.',
        hintProductive: 'Dein Training zeigt starke Wirkung. Weiter so – du näherst dich der Topform!',
        hintPeakForm: 'Du bist in Topform! Ein seltener Zustand – nutze ihn für Bestleistungen.',
        phasesTitle: 'Was bedeuten die Phasen?',
        infoTitle: 'Was bedeutet Trainingsphase?',
        infoBody: 'Deine Trainingsphase zeigt deinen langfristigen Fitnesszustand. Regelmäßiges Training baut die Form auf. Bei Trainingspausen sinkt sie – erst langsam, dann schneller.',
        infoRecoveryCondition: '2–5 Tage Pause'
      },
      readiness: {
        title: 'Trainingsbereitschaft',
        lowLoad: 'Niedrige Belastung',
        balanced: 'Ausgewogen',
        highLoad: 'Hohe Belastung',
        descLow: 'Deine Trainingsbelastung liegt unter deinem Durchschnitt.',
        descBalanced: 'Deine Trainingsbelastung ist im optimalen Bereich.',
        descHigh: 'Deine Trainingsbelastung ist hoch. Achte auf Erholung.',
        zoneOverreaching: 'Überbelastet',
        zoneFatigued: 'Ermüdet',
        zoneMaintaining: 'Belastet',
        zoneBuilding: 'Bereit',
        zonePeak: 'Erholt',
        zoneFormLoss: 'Formverlust',
        buildingBaseline: 'Baseline wird aufgebaut',
        infoTitle: 'Was bedeutet Trainingsbereitschaft?',
        infoBody: 'Deine Trainingsbereitschaft zeigt das Verhältnis zwischen deiner kurzfristigen und langfristigen Trainingsbelastung. Sie sinkt nach dem Training und steigt mit Erholung.',
        infoZoneOverreaching: 'Dein aktuelles Trainingsvolumen ist deutlich höher als gewohnt. Achte auf Erholung.',
        infoZoneFatigued: 'Du trainierst etwas über deinem Durchschnitt. Trainiere klug und höre auf deinen Körper.',
        infoZoneMaintaining: 'Dein Körper verarbeitet die aktuelle Trainingsbelastung.',
        infoZoneBuilding: 'Du bist gut erholt und bereit für das nächste Training.',
        infoZonePeak: 'Du bist vollständig erholt. Idealer Zeitpunkt für intensive Einheiten.',
        infoZoneFormLoss: 'Eine längere Trainingspause wurde erkannt. Dein Fitnesslevel kann abnehmen.',
        subtitle: 'Basierend auf deinem Trainingsvolumen der letzten Wochen',
        subtitleFormLoss: 'Längere Trainingspause erkannt',
        noData: 'Noch nicht genug Trainingsdaten',
        windowLabel: '7/28 Tage',
        insightNoData: 'Starte mit dem Loggen deines Trainings, um eine Baseline aufzubauen.',
        insightZoneOverreaching: 'Deine Belastung ist aktuell sehr hoch. Plane ausreichend Erholung ein.',
        insightZoneFatigued: 'Du trainierst etwas mehr als gewohnt. Achte auf ausreichend Regeneration.',
        insightZoneMaintaining: 'Dein Training ist aktuell gut ausbalanciert.',
        insightZoneBuilding: 'Du bist gut erholt und bereit für dein nächstes Training.',
        insightZonePeak: 'Dein Körper ist vollständig regeneriert. Ideal für intensive Einheiten.',
        insightZoneFormLoss: 'Du hast in den letzten Tagen wenig trainiert. Dein Körper ist erholt.',
        hintLow: 'Du bist gut erholt. Idealer Zeitpunkt für ein intensives Training.',
        hintMaintaining: 'Moderate Belastung. Du kannst normal weitertrainieren.',
        hintBuilding: 'Du bist bereit für dein nächstes Training.',
        hintPeak: 'Vollständig erholt. Ideal für intensive Trainingseinheiten.',
        phasesTitle: 'Was bedeuten die Stufen?',
        changeNoData: 'Starte mit dem Training, um zu sehen, wie sich dein Erholungsstatus entwickelt.',
        changeNone: 'Dein Erholungsstatus hat sich nicht verändert.',
        changeUpTraining: 'Dein letztes Training hat die kurzfristige Belastung erhöht.',
        changeUpRecovery: 'Erholung hat die Ermüdung reduziert.',
        changeDownTraining: 'Dein letztes Training hat die Ermüdung erhöht.',
        changeDownRecovery: 'Reduziertes Training hat deine kurzfristige Belastung gesenkt.',
        changeBaseline: 'Deine langfristige Trainingsbaseline hat sich verschoben.',
        changeSubLoad: '+{load} Belastung durch dein letztes Training',
        changeSubRest: '\u2212{load} Belastung durch {days} Ruhetage',
        changeDriver: 'Haupttreiber: {name} ({duration} min)'
      },
      baseline: {
        days: 'Tage',
        noData: 'Logge dein erstes Training, um die Baseline aufzubauen',
        building: 'Baseline wird aufgebaut – noch {days} Tage nötig',
        complete: 'Baseline aufgebaut'
      },
      recommendation: {
        title: 'Heutige Empfehlung',
        noData: 'Logge regelmäßig dein Training, um personalisierte Empfehlungen zu erhalten.',
        intensityRest: 'Pause',
        intensityLow: 'Leicht',
        intensityModerate: 'Moderat',
        intensityHigh: 'Intensiv',
        overreaching: 'Dein Körper braucht Erholung. Heute Pause oder sehr leichtes Mobility-Training.',
        formLoss: 'Du warst länger inaktiv. Starte mit einer leichten Einheit, um den Wiedereinstieg zu schaffen.',
        formLossDetrained: 'Du bist schon länger nicht mehr aktiv. Beginne behutsam mit einer kurzen, leichten Einheit.',
        recoveryResting: 'Dein Körper erholt sich. Gönne dir Ruhe oder mache leichte aktive Erholung.',
        recoveryReady: 'Du bist erholt und bereit. Ein moderates Training wäre jetzt ideal.',
        fatiguedGoodForm: 'Trotz guter Form bist du ermüdet. Heute leichtes Training oder aktive Erholung.',
        fatiguedDefault: 'Du bist ermüdet. Heute leichtes Training oder Pause einlegen.',
        maintainingPeak: 'Stabile Belastung bei guter Form. Moderates Training nach Plan.',
        maintainingDefault: 'Normales Training nach Plan. Du verarbeitest die aktuelle Belastung gut.',
        buildingGoodForm: 'Guter Zeitpunkt für eine fordernde Einheit! Deine Form und Erholung passen.',
        buildingDefault: 'Du bist bereit fürs Training. Steigere progressiv.',
        peakGoodForm: 'Perfekter Tag für eine Topeinheit! Du bist erholt und in starker Form.',
        peakDetrained: 'Du bist gut erholt – nutze das für ein moderates Comeback-Training.',
        peakDefault: 'Du bist voll erholt. Guter Tag für eine intensive Einheit!'
      },
      bodyweight: {
        title: 'Bodyweight',
        emptyTitle: 'Noch keine Bodyweight-Sessions',
        emptyBody: 'Starte ein Training mit Körpergewichtsübungen, um deinen Fortschritt zu sehen.',
        intensityTitle: 'Intensitätsniveaus',
        intensityHint: 'Belastungsklasse pro Session basierend auf Wiederholungen und Übungsart.',
        effortTitle: 'Effort-Trend',
        effortHint: 'Relativer Aufwand über Zeit (Wdh x Belastungsfaktor).',
        intensityLow: 'Niedrig',
        intensityMedium: 'Mittel',
        intensityHigh: 'Hoch',
        stats: {
          lastWeek: 'Letzte Woche',
          bestWeek: 'Beste Woche',
          average: 'Durchschnitt',
          sessions: 'Sessions'
        },
        chartTitle: 'Bodyweight Effort - {period}',
        noData: 'Noch keine Bodyweight-Daten für diesen Zeitraum'
      },
      period: {
        '7d': '7 Tage',
        '30d': '30 Tage',
        '6m': '6 Monate',
        '1y': '1 Jahr',
        bucket: {
          day: 'Tage',
          week: 'Wochen'
        }
      },
      labels: {
        lastBucket: 'Letzte {bucket}',
        bestBucket: 'Beste {bucket}',
        fastestBucket: 'Schnellste {bucket}'
      },
      activityCalendar: {
        monthTitle: '{month}',
        sheetTitle: 'Sessions am {date}',
        prevMonth: 'Vorheriger Monat',
        nextMonth: 'Nächster Monat',
        dayLabel: '{day}. {count} Sessions',
        overflow: '+{count}',
        weekday: {
          mon: 'Mo',
          tue: 'Di',
          wed: 'Mi',
          thu: 'Do',
          fri: 'Fr',
          sat: 'Sa',
          sun: 'So'
        }
      },
      session: {
        typeStrength: 'Kraft',
        typeCardio: 'Cardio',
        typeRecovery: 'Recovery',
        durationNA: 'Dauer n/a'
      },
      cardio: {
        emptyTitle: 'Noch keine Cardio-Sessions',
        emptyBody: 'Logge deine erste Cardio-Session, um deinen Fortschritt zu sehen',
        add: 'Cardio-Session hinzufügen',
        activityPicker: 'Aktivität auswählen',
        activityPickerTitle: 'Aktivität auswählen',
        activityLabel: 'Aktivität',
        periodShort: '{weeks} Wochen',
        metricTime: 'Zeit',
        metricDistance: 'Distanz',
        metricPace: 'Pace',
        metricLabel: {
          time: 'Zeit (min)',
          distance: 'Distanz (km)',
          pace: 'Pace (min/km)'
        },
        metricUnit: {
          time: 'min',
          distance: 'km',
          pace: 'min/km'
        },
        metricHelper: 'Pace wird aus Zeit und Distanz berechnet.',
        helper: 'Die Werte basieren auf deinen Cardio-Sessions im gewählten Zeitraum.',
        paceEmptyTitle: 'Pace-Daten',
        paceEmptyValue: 'Nicht genug Daten',
        paceEmptyHint: 'Logge Sessions mit Distanz für Pace-Berechnung',
        stats: {
          lastWeek: 'Letzte Woche',
          bestWeek: 'Beste Woche',
          average: 'Durchschnitt',
          sessions: 'Sessions'
        },
        chartTitle: '{metric} - {period}',
        noData: 'Noch keine Daten für diese Aktivität',
        noPaceData: 'Logge Sessions mit Distanz für Pace-Daten'
      },
      strength: {
        emptyTitle: 'Noch keine Kraft-Trainings',
        emptyBody: 'Starte ein Training im Workout-Bereich, um deinen Fortschritt zu tracken',
        periodShort: '{weeks} Wochen',
        stats: {
          lastWeek: 'Letzte Woche',
          bestWeek: 'Beste Woche',
          average: 'Durchschnitt',
          sessions: 'Sessions'
        },
        chartTitle: 'Kraft-Volumen - {period}',
        noData: 'Noch keine Daten für diesen Zeitraum',
        helper: 'Volumen basiert auf deinen getrackten Kraft-Sessions.',
        summary: {
          exercises: 'Übungen',
          sets: 'Sätze',
          reps: 'Wiederholungen'
        },
        loadIndex: {
          title: 'Belastungsniveau',
          hint: 'Durchschnittliche Arbeitslast pro Session (Gewicht x Wdh).',
          chartTitle: 'Belastungsniveau - {period}',
          unit: 'kg',
          noData: 'Noch keine gewichteten Trainings in diesem Zeitraum'
        },
        variance: {
          title: 'Trainings-Varianz',
          hint: 'Wie abwechslungsreich dein Training ist.',
          low: 'Fokussiert',
          medium: 'Ausgeglichen',
          high: 'Abwechslungsreich'
        },
        structure: {
          title: 'Strukturverteilung',
          noData: 'Strukturdaten nicht verfügbar',
          hint: 'Push/Pull/Legs/Core basierend auf deinen Trainingsplänen.'
        },
        volume: {
          weighted: 'Gewichtetes Volumen',
          weightedShort: 'Gewichtet',
          weightedHint: 'Gewicht x Wdh (kg)',
          bodyweight: 'Bodyweight Volumen',
          bodyweightShort: 'Bodyweight',
          bodyweightHint: 'Wdh x Belastungsfaktor (Schätzung)',
          combined: 'Gesamt',
          metric: 'Metrik',
          infoTitle: 'Volumen-Berechnung',
          infoWeighted: 'Gewichtetes Volumen: Summe aus Gewicht x Wiederholungen für alle Sätze mit Gewicht.',
          infoBodyweight: 'Bodyweight Volumen: Wiederholungen x übungsspezifischer Belastungsfaktor. Pull-ups (1.5x) > Push-ups (1.0x). Eine grobe Schätzung zur Trend-Visualisierung.',
          noWeighted: 'Keine gewichteten Übungen in diesem Zeitraum',
          noBodyweight: 'Keine Bodyweight-Übungen in diesem Zeitraum',
          chartTitleWeighted: 'Gewichtetes Volumen - {period}',
          chartTitleBodyweight: 'Bodyweight Volumen - {period}'
        }
      },
      modals: {
        workoutNotFound: 'Workout nicht gefunden',
        deleteConfirm: 'Dieses Workout wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
        deleteCalendarConfirm: 'Diese Session wirklich löschen?',
        deleteError: 'Fehler beim Löschen: {message}',
        deleteErrorShort: 'Fehler beim Löschen',
        modalUnavailable: 'Modal nicht verfügbar',
        cardioModalUnavailable: 'Cardio-Modal nicht verfügbar',
        recoveryModalUnavailable: 'Recovery-Modal nicht verfügbar'
      },
      v3: {
        title: 'Progress',
        rhythm: {
          title: 'Trainingsrhythmus',
          subtitle: 'Letzte 12 Monate',
          subtitleDays: 'Letzte 7 Tage',
          subtitleWeeks: 'Letzte 5 Wochen',
          subtitle6m: 'Letzte 6 Monate',
          minutesPerWeek: 'min',
          noData: 'Noch keine Trainingsdaten vorhanden'
        },
        blockComparison: {
          title: 'Blockvergleich',
          last4w: 'Letzte 4 Wochen',
          prev4w: 'Vorherige 4 Wochen',
          sessionsPerWeek: 'Sessions / Woche',
          minutesPerWeek: 'Minuten / Woche',
          cardioShare: 'Cardio-Anteil',
          noChange: 'unverändert',
          noPrevData: 'Keine Vergleichsdaten'
        },
        mix: {
          title: 'Trainingsmix',
          noData: 'Keine Daten im Zeitraum'
        },
        cardioSnapshot: {
          title: 'Cardio',
          toggleTime: 'Zeit',
          toggleDistance: 'Distanz',
          togglePace: 'Pace',
          totalTime: 'Gesamtzeit',
          totalDistance: 'Gesamtdistanz',
          avgPace: 'Durchschn. Pace',
          noPaceData: 'Nicht genug Distanzdaten',
          noData: 'Keine Cardio-Daten im Zeitraum',
          weekLabel: 'KW {week}'
        },
        stories: {
          title: 'Zusammenfassung',
          sessionsSummary: 'Letzte {days} Tage: {count} Sessions (Ø {avg} min)',
          longestBreak: 'Längste Pause: {days} Tage',
          strengthWeeks: 'Krafttraining in {active} von {total} Wochen',
          noData: 'Noch keine Sessions vorhanden'
        },
        types: {
          strength: 'Kraft',
          bodyweight: 'Bodyweight',
          cardio: 'Cardio',
          recovery: 'Recovery'
        }
      },
      v4: {
        tabs: {
          overview: 'Übersicht',
          exercises: 'Übungen',
          plans: 'Pläne'
        },
        overview: {
          workouts: 'Workouts',
          trainingTime: 'Trainingszeit',
          totalVolume: 'Gesamtvolumen',
          activeDays: 'Aktive Tage',
          sessionHistory: 'Trainingshistorie',
          noSessions: 'Keine Sessions im Zeitraum',
          minutes: 'min',
          showMore: '{count} weitere anzeigen',
          showLess: 'Weniger anzeigen',
          runningStats: 'Laufstatistik',
          runs: 'Läufe',
          totalTime: 'Gesamtzeit',
          totalDistance: 'Distanz',
          avgPace: 'Pace',
          runCharts: 'Lauftrends',
          distancePerWeek: 'Distanz pro Woche',
          paceTrend: 'Pace-Verlauf',
          durationPerMonth: 'Trainingszeit pro Monat',
          sessionsPerMonth: 'Sessions pro Monat',
          runChartTooltipRuns: 'Läufe',
          enduranceTrends: 'Ausdauer-Trends',
          sportRun: 'Laufen',
          sportBike: 'Radfahren',
          sportSwim: 'Schwimmen',
          sportHike: 'Wandern',
          sessions: 'Sessions',
          avgSpeed: 'Geschwindigkeit',
          speedTrend: 'Speed-Verlauf',
          swimPace: 'Pace (100m)',
          noDataHint: 'Noch nicht genügend Daten vorhanden. Absolviere ein Training dieser Art, um Auswertungen zu sehen.',
        },
        exercises: {
          title: 'Übungs-Trends',
          sessions: '{count} Sessions',
          noExercises: 'Noch keine Übungen absolviert',
          noFilterResults: 'Keine Übungen gefunden',
          searchPlaceholder: 'Übung suchen...',
          allMuscles: 'Alle',
          detail: {
            pr: 'Bestleistung',
            average: 'Durchschnitt',
            lastSession: 'Letzte Session',
            history: 'Verlauf',
            sets: 'Sätze',
            volume: 'Volumen'
          }
        },
        plans: {
          title: 'Plan-Fortschritt',
          lastSession: 'Zuletzt: {date}',
          sessions: '{count} Sessions',
          noPlans: 'Noch keine Pläne absolviert',
          detail: {
            timeline: 'Zeitverlauf',
            vsLast: 'vs. letztes Mal',
            session: 'Session {num}',
            noComparison: 'Erste Session'
          }
        },
        postWorkout: {
          exercisesTitle: 'Übungen im Detail',
          badgeNew: 'Neu',
          badgeRemoved: 'Letztes Mal',
          noChange: 'gleich',
          improved: 'verbessert',
          declined: 'verschlechtert'
        }
      }
    },
    profile: {
      title: 'Profil',
      bodyWeight: 'Körpergewicht',
      bodyHeight: 'Körpergröße',
      trainingStyle: 'Trainingsart',
      gym: 'Gym',
      bodyweight: 'Bodyweight',
      hybrid: 'Hybrid',
      editName: 'Name bearbeiten',
      nameUpdated: 'Name aktualisiert',
      profileUpdated: 'Profil aktualisiert'
    },
    settings: {
      general: 'Allgemein',
      workout: 'Workout',
      progress: 'Fortschritt',
      integrations: 'Integrationen',
      account: 'Account',
      appInfo: 'App Information',
      language: 'Sprache',
      unitSystem: 'Einheiten',
      metric: 'KG',
      imperial: 'LBS',
      langDe: 'DE',
      langEn: 'EN',
      defaultRestTimer: 'Standard Pausenzeit',
      haptics: 'Haptisches Feedback',
      defaultPeriod: 'Standard Zeitraum',
      comingSoon: 'Demnächst',
      connect: 'Verbinden',
      connected: 'Verbunden',
      email: 'E-Mail',
      signOut: 'Abmelden',
      deleteAccount: 'Account löschen',
      deleteAccountConfirm: 'Account wirklich löschen?',
      deleteAccountConfirmText: 'Alle Daten werden unwiderruflich gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.',
      deleteAccountButton: 'Endgültig löschen',
      saved: 'Gespeichert',
      seconds: '{n}s',
      theme: 'Erscheinungsbild',
      themeDark: 'Dunkel',
      themeLight: 'Hell',
      version: 'Version',
      build: 'Build'
    },
    errors: {
      startUnavailable: 'Start-Auswahl ist nicht verfügbar.',
      workoutNotFound: 'Workout nicht gefunden',
      sessionNotFound: 'Session nicht gefunden',
      planNotFound: 'Plan nicht gefunden',
      workoutStartFailed: 'Fehler beim Starten des Workouts',
      deleteFailed: 'Fehler beim Löschen',
      saveFailed: 'Fehler beim Speichern.',
      exercisesLoading: 'Übungen werden noch geladen. Bitte versuche es gleich erneut.',
      planNameRequired: 'Bitte gib einen Namen für den Plan ein!',
      planExercisesRequired: 'Bitte füge mindestens eine Übung hinzu!',
      exerciseNameRequired: 'Bitte gib einen Namen für die Übung ein!',
      muscleGroupsRequired: 'Bitte wähle mindestens eine Muskelgruppe!'
    },
    feedback: {
      title: 'Wie war dein Training?',
      subtitle: 'Kurzes Feedback hilft dir, deinen Fortschritt besser zu verstehen.',
      preEnergy: 'Energie vor dem Training',
      postFeeling: 'Gefühl nach dem Training',
      rpeLabel: 'Anstrengung (RPE)',
      submit: 'Speichern',
      skip: 'Überspringen',
      energy: {
        1: 'Sehr niedrig',
        2: 'Niedrig',
        3: 'Normal',
        4: 'Hoch',
        5: 'Sehr hoch'
      },
      feeling: {
        1: 'Sehr schlecht',
        2: 'Schlecht',
        3: 'Okay',
        4: 'Gut',
        5: 'Sehr gut'
      },
      rpe: {
        1: 'Sehr leicht',
        2: 'Leicht',
        3: 'Moderat',
        4: 'Hart',
        5: 'Maximal'
      }
    },
    block: {
      typeSheet: {
        title: 'Block hinzufügen',
        normal: 'Einzelübung',
        normalDesc: 'Klassisch satz-basiert',
        superset: 'Superset',
        supersetDesc: '2–3 Übungen im Wechsel',
        emom: 'EMOM',
        emomDesc: 'Every Minute On the Minute'
      },
      emomConfig: {
        title: 'EMOM konfigurieren',
        duration: 'Dauer (min)',
        interval: 'Intervall (s)',
        repsLabel: 'Ziel pro Übung',
        reps: 'Reps',
        save: 'Block hinzufügen',
        update: 'Block aktualisieren'
      },
      supersetConfig: {
        title: 'Superset konfigurieren',
        sets: 'Sets',
        reps: 'Reps',
        restBetween: 'Pause zwischen Supersätzen',
        save: 'Block hinzufügen',
        update: 'Block aktualisieren'
      },
      planRender: {
        emomLabel: 'EMOM · {minutes} min',
        emomSub: 'Alle {interval}s · {count} Übungen',
        supersetLabel: 'Superset',
        supersetSub: '{count} Übungen im Wechsel',
        editBlock: 'Bearbeiten',
        deleteBlock: 'Löschen',
        deleteConfirm: 'Block wirklich löschen?'
      },
      workout: {
        emom: {
          prescreenTitle: 'EMOM',
          prescreenDuration: '{minutes} Minuten',
          prescreenEveryMinute: 'Jede Minute:',
          start: 'Start',
          skip: 'Block überspringen',
          minute: 'Minute {current} / {total}',
          remainingInMinute: 'Verbleibend in Minute',
          totalRemaining: '{time} verbleibend',
          next: 'Nächste: {name} ×{reps}',
          done: 'Geschafft',
          missed: 'Nicht geschafft',
          targetReps: 'Ziel: ×{reps}',
          actualReps: 'Tatsächliche Wiederholungen',
          logReps: 'Loggen',
          skipRound: 'Skip',
          loggedReps: '{reps} Wdh. geloggt',
          loggedTitle: '{reps} Wdh. geloggt',
          skippedTitle: 'Übersprungen',
          tapToUndo: 'Tippen zum Rückgängigmachen',
          undoLog: 'Eintrag rückgängig machen',
          blockComplete: 'EMOM abgeschlossen'
        },
        superset: {
          label: 'Superset',
          current: 'Aktuell: {label} {name}',
          restBetween: 'Pause: {seconds}s zwischen Supersätzen',
          roundComplete: 'Runde {round} abgeschlossen'
        },
        blockPill: {
          emom: 'EMOM {minutes}min',
          superset: 'Superset'
        }
      }
    }
  },
  en: {
    common: {
      workout: 'Workout',
      strength: 'Strength',
      bodyweight: 'Bodyweight',
      cardio: 'Cardio',
      recovery: 'Recovery',
      session: 'Session',
      sessions: 'Sessions',
      days: 'Days',
      weeks: 'Weeks',
      add: 'Add',
      addSession: 'Add session',
      view: 'View',
      viewDetails: 'View details',
      delete: 'Delete',
      close: 'Close',
      select: 'Select',
      start: 'Start',
      startAgain: 'Start again',
      editSession: 'Edit session',
      duration: 'Duration',
      notes: 'Notes',
      activity: 'Activity',
      time: 'Time',
      distance: 'Distance',
      pace: 'Pace',
      loading: 'Loading...',
      notAvailable: '-',
      save: 'Save',
      cancel: 'Cancel',
      edit: 'Edit',
      next: 'Next',
      back: 'Back',
      done: 'Done',
      optional: 'optional',
      minutes: 'Minutes',
      secondsShort: '{n}s'
    },
    nav: {
      dashboard: 'Home',
      progress: 'Progress',
      calendar: 'Calendar',
      training: 'Training',
      profile: 'Profile',
      plans: 'Plans',
      exercises: 'Exercises'
    },
    difficulty: {
      beginner: 'Beginner',
      intermediate: 'Intermediate',
      advanced: 'Advanced',
      elite: 'Elite',
      label: 'Difficulty',
      descriptions: {
        beginner: 'Ideal for beginners with no prior experience',
        intermediate: 'For trainees with basic knowledge',
        advanced: 'For experienced athletes',
        elite: 'For professionals with years of experience'
      }
    },
    plan: {
      types: {
        strength: 'Strength',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio',
        recovery: 'Recovery',
        unknown: 'Unknown type'
      },
      typeOptions: {
        strength: 'Strength (Gym)',
        bodyweight: 'Bodyweight (Calisthenics)',
        cardio: 'Cardio',
        recovery: 'Recovery'
      },
      filters: {
        all: 'All',
        strength: 'Strength',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio',
        recovery: 'Recovery',
        difficultyAll: 'All difficulties'
      },
      sections: {
        basics: 'Basics',
        contentStrength: 'Exercises',
        contentBodyweight: 'Exercises',
        contentCardio: 'Cardio goal',
        contentRecovery: 'Recovery goal'
      },
      list: {
        emptyTitle: 'No plans found',
        emptyBody: 'Create your first plan',
        emptyCta: 'Create plan',
        loading: 'Loading plans...'
      },
      meta: {
        exercises: '{count} exercises',
        goalPrefix: 'Goal',
        duration: '{minutes} min',
        distance: '{distance} km',
        recoveryFallback: 'No goal',
        cardioFallback: 'Cardio'
      },
      actions: {
        newPlan: 'New plan',
        create: 'Create plan',
        start: 'Start workout',
        edit: 'Edit',
        save: 'Save',
        cancel: 'Cancel',
        next: 'Next'
      },
      modal: {
        createTitle: 'New plan',
        editTitle: 'Edit plan'
      },
      cardioGoal: {
        label: 'Cardio goal',
        liss: 'LISS',
        hiit: 'HIIT',
        zone2: 'Zone 2',
        tempo: 'Tempo',
        info: {
          liss: 'Low Intensity Steady State - Consistent low intensity',
          hiit: 'High Intensity Interval Training - Short intense intervals',
          zone2: 'Aerobic zone (60-70% HRmax) - Base endurance',
          tempo: 'Medium to high intensity - Lactate threshold'
        }
      },
      cardioGoalType: {
        label: 'Goal type',
        liss: 'LISS',
        hiit: 'HIIT',
        intervals: 'Intervals',
        freestyle: 'Freestyle',
        info: {
          liss: 'Consistent low intensity for base endurance.',
          hiit: 'Short, intense intervals with rest periods.',
          intervals: 'Repeated work blocks with defined rest periods.',
          freestyle: 'Free cardio without a fixed intensity plan.'
        }
      },
      cardio: {
        durationLabel: 'Duration (minutes)',
        distanceLabel: 'Distance (km)',
        activityLabel: 'Activity type',
        targetHint: 'At least duration or distance recommended',
        activityOptions: {
          run: 'Running',
          bike: 'Cycling',
          swim: 'Swimming',
          hike: 'Hiking',
          row: 'Rowing',
          other: 'Other'
        }
      },
      recovery: {
        durationLabel: 'Duration (minutes)',
        targetHint: 'Optional but recommended'
      },
      name: 'Plan name',
      namePlaceholder: 'e.g. Push Workout',
      type: 'Type',
      duration: 'Duration (min)',
      icon: 'Plan icon',
      notes: 'Notes',
      notesPlaceholder: 'Additional information...',
      exercises: 'Exercises',
      addExercise: 'Add exercise',
      exercisesHint: 'Add exercises to your plan',
      exercisesEmptyTitle: 'No exercises added yet',
      exercisesEmptyBody: 'Add exercises from the database',
      exerciseRemoveConfirm: 'Remove exercise from plan?',
      exerciseConfig: {
        title: 'Configure exercise',
        setsLabel: 'Sets *',
        setsShort: 'Sets',
        repsLabel: 'Reps',
        repsPlaceholder: 'e.g. 12 or 8-10',
        holdLabel: 'Hold (sec)',
        holdPlaceholder: 'e.g. 30',
        restLabel: 'Rest',
        restNone: 'No rest',
        restMin: 'Min',
        restSec: 'Sec',
        notesLabel: 'Notes',
        notesPlaceholder: 'e.g. Tempo, progressions...'
      },
      exercisePicker: {
        title: 'Select exercises',
        searchPlaceholder: 'Search exercises...',
        noExercisesTitle: 'No exercises available',
        noExercisesBody: 'Create exercises in the exercise database first',
        noResultsTitle: 'No exercises found',
        noResultsBody: 'Try a different search term or filter',
        filterInfo: '{count} of {total} exercises found ({filters})',
        filterSearch: 'Search: "{term}"',
        filterMuscle: 'Muscle group: {muscle}',
        addSelected: 'Add {count} exercises',
        addSelectedOne: 'Add 1 exercise',
        selectHint: 'Select exercises'
      },
      deleteConfirm: 'Really delete this plan?',
      deleteSuccess: 'Plan deleted.',
      deleteError: 'Error deleting plan.',
      picker: {
        title: 'Select plan',
        searchPlaceholder: 'Search plans...',
        noPlans: 'No plans available',
        createFirst: 'Create a training plan first',
        noResults: 'No results'
      }
    },
    calendar: {
      quickEntry: {
        title: 'Quick entry',
        name: 'Name',
        namePlaceholder: 'e.g. Morning run',
        type: 'Training type',
        duration: 'Duration (min)',
        durationOptional: 'optional',
        add: 'Add',
        nameRequired: 'Please enter a name'
      },
      addPlan: 'Add plan',
      quickAdd: 'Quick entry',
      orQuickEntry: 'Or create quick entry',
      orSelectPlan: 'or select plan',
      today: 'Today',
      noPlannedWorkouts: 'No workouts planned',
      entryAdded: 'Workout added',
      saveError: 'Error saving',
      untitled: 'Untitled',
      confirmRemove: 'Really remove workout?',
      monthNames: {
        january: 'January',
        february: 'February',
        march: 'March',
        april: 'April',
        may: 'May',
        june: 'June',
        july: 'July',
        august: 'August',
        september: 'September',
        october: 'October',
        november: 'November',
        december: 'December'
      },
      dayNames: {
        monday: 'Monday',
        tuesday: 'Tuesday',
        wednesday: 'Wednesday',
        thursday: 'Thursday',
        friday: 'Friday',
        saturday: 'Saturday',
        sunday: 'Sunday'
      },
      dayNamesShort: {
        mon: 'Mo',
        tue: 'Tu',
        wed: 'We',
        thu: 'Th',
        fri: 'Fr',
        sat: 'Sa',
        sun: 'Su'
      },
      agenda: {
        title: 'Planned workouts'
      },
      errors: {
        notFound: 'Workout not found',
        engineNotLoaded: 'Workout engine not loaded',
        modalNotAvailable: 'Recording module not available'
      }
    },
    exercise: {
      title: 'Exercise',
      name: 'Exercise name',
      namePlaceholder: 'e.g. Pull-ups',
      muscleGroups: 'Muscle groups',
      muscles: {
        chest: 'Chest',
        back: 'Back',
        shoulders: 'Shoulders',
        biceps: 'Biceps',
        triceps: 'Triceps',
        core: 'Core',
        legs: 'Legs',
        fullBody: 'Full body',
        arms: 'Arms',
        calf: 'Calves',
        cardio: 'Cardio',
        mobility: 'Mobility'
      },
      muscleDescriptions: {
        all: 'Show all exercises',
        chest: 'Chest muscles',
        back: 'Back muscles',
        biceps: 'Biceps muscles',
        triceps: 'Triceps muscles',
        shoulders: 'Shoulder muscles',
        core: 'Abdominal and core muscles',
        legs: 'Leg muscles',
        fullBody: 'Full body training',
        arms: 'Biceps, triceps, forearms',
        calf: 'Calf muscles'
      },
      muscleFilter: {
        title: 'Filter by muscle group',
        selectTitle: 'Select muscle groups',
        searchPlaceholder: 'Search muscle group...',
        selectPlaceholder: 'Select muscle groups...',
        required: 'Muscle groups *'
      },
      difficultyFilter: {
        title: 'Filter by difficulty'
      },
      equipmentFilter: {
        title: 'Filter by equipment'
      },
      filters: {
        allMuscles: 'All muscle groups',
        allDifficulties: 'All difficulties'
      },
      equipment: 'Equipment',
      discipline: 'Discipline',
      visual: 'Exercise icon',
      selectIcon: 'Select icon',
      listSectionOther: '#',
      instructions: {
        title: 'Instructions',
        hint: 'Describe the execution step by step.',
        stepTitle: 'Step {number}',
        stepPlaceholder: 'Describe this step...',
        addStep: 'Add step',
        removeStep: 'Remove step',
        noSteps: 'No steps added yet',
        advanced: {
          title: 'Advanced notes',
          add: 'Add advanced notes',
          hide: 'Hide advanced notes',
          emptyList: 'No notes added yet',
          cues: 'Cues',
          cuesPlaceholder: 'Short execution cues...',
          cuesAdd: 'Add cue',
          mistakes: 'Common mistakes',
          mistakesPlaceholder: 'Typical mistakes and how to avoid them...',
          mistakesAdd: 'Add mistake',
          progressions: 'Progressions',
          progressionsPlaceholder: 'Easier or harder variants...',
          progressionsAdd: 'Add progression',
          setup: 'Setup',
          setupPlaceholder: 'Setup, starting position and preparation...'
        },
        setup: 'Setup',
        setupPlaceholder: 'Starting position and grip...',
        setupDefault: 'Find a stable starting position, engage core and maintain tension.',
        execution: 'Execution',
        executionPlaceholder: 'Describe the movement...',
        executionDefault: 'No execution details added yet.',
        cues: 'Cues',
        cuesPlaceholder: 'Important cues during execution...',
        cuesDefault: 'Focus on controlled movement and stable body tension.',
        mistakes: 'Common mistakes',
        mistakesPlaceholder: 'Typical mistakes and how to avoid them...',
        mistakesDefault: 'Avoid momentum, uncontrolled end positions and unstable joint angles.',
        progressions: 'Progressions',
        progressionsPlaceholder: 'Easier and harder variants...',
        progressionsDefault: 'More range, slower eccentric or added weight increase intensity.'
      },
      categories: {
        upper: 'Upper body',
        lower: 'Lower body',
        core: 'Core',
        fullBody: 'Full body',
        cardio: 'Cardio',
        mobility: 'Mobility'
      },
      quickCreate: {
        title: 'New exercise',
        button: 'Create new exercise',
        hint: 'Exercise missing? Create it here quickly.',
        saved: 'Exercise created and added'
      },
      type: {
        label: 'Type',
        strength: 'Strength',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio',
        mobility: 'Mobility',
        recovery: 'Recovery'
      },
      pattern: {
        label: 'Movement pattern',
        push: 'Push',
        pull: 'Pull',
        legs: 'Legs',
        core: 'Core',
        full: 'Full body'
      },
      visualAdd: 'Add visual',
      visualUrlPlaceholder: 'Enter image URL...',
      visualRemove: 'Remove visual',
      variants: {
        label: 'Variants',
        add: 'Add variant',
        namePlaceholder: 'Variant name...',
        notePlaceholder: 'Short note (optional)...',
        remove: 'Remove variant',
        empty: 'No variants yet'
      },
      notesLabel: 'Notes',
      notesPlaceholder: 'General notes about the exercise...',
      create: {
        title: 'New exercise',
        stepBasics: 'Basics',
        stepDetails: 'Details',
        stepOptional: 'optional'
      },
      editTitle: 'Edit exercise',
      loading: 'Loading exercises...',
      feedback: {
        saveError: 'Error saving exercise!',
        deleted: 'Entry deleted',
        deleteError: 'Error deleting'
      },
      detail: {
        useInPlan: 'Use in plan'
      },
      searchPlaceholder: 'Search exercises...',
      noResultsTitle: 'No results',
      noResultsHint: 'Try a different term or create a new exercise.',
      createNew: 'Create new exercise',
      deleteConfirm: 'Really delete this exercise?',
      deleteUsedInPlans: 'This exercise is used in {count} plans ({plans}). Delete anyway? It will remain in existing sessions.',
      deleted: 'Exercise deleted.',
      deleteError: 'Error deleting exercise.'
    },
    workout: {
      quick: {
        title: 'Quick workout entry',
        date: 'Date *',
        dateRequired: 'Please select a date',
        name: 'Workout name',
        duration: 'Duration (minutes)',
        type: 'Type',
        difficulty: 'Difficulty',
        bodyweight: 'Bodyweight',
        bodyweightDesc: 'Bodyweight training',
        weights: 'Weights',
        weightsDesc: 'Gym / Dumbbells',
        nameRequired: 'Please enter a workout name',
        durationRequired: 'Please enter a valid duration',
        saveError: 'Error saving workout'
      },
      screen: {
        exercisesButton: 'Exercises ({completed}/{total})',
        exercisesSheetTitle: 'Exercises',
        cancelWorkout: 'Cancel',
        endWorkout: 'End workout',
        endWorkoutConfirm: 'Really end workout?',
        endWorkoutConfirmText: 'All sets so far will be saved.',
        nextExercise: 'Next exercise',
        finishWorkout: 'Finish workout',
        currentExercise: 'Current exercise',
        goal: 'Goal',
        rest: 'Rest',
        exerciseOf: 'Exercise {current} of {total}',
        noActiveWorkout: 'No active workout',
        noActiveWorkoutText: 'Start a training from the calendar or a plan.',
        toPlans: 'Go to plans',
        switchToExercise: 'Switch to this exercise',
        saveWorkout: 'Save workout',
        discardWorkout: 'Discard workout',
        discardConfirm: 'Really discard workout? All progress will be lost.',
        restTimer: 'Rest',
        bodyweight: 'Bodyweight',
        weighted: 'Weighted',
        cardio: 'Cardio',
        recovery: 'Recovery',
        addSet: 'Add set',
        exerciseProgress: '{completed} / {total} exercises',
        timerPause: 'Pause',
        timerResume: 'Resume',
        timerSkip: 'Skip',
        timerStart: 'Start timer',
        timerAdd: '+10s',
        timerSub: '-10s',
        timerDone: 'Rest done!',
        discardConfirmTitle: 'Discard workout?',
        endWorkoutAction: 'End',
        logWorkout: 'Log workout',
        emptyHint: 'Add exercises to start your workout',
        addExercise: 'Add exercise',
        searchExercise: 'Search exercise...',
        noExercisesFound: 'No exercises found',
        freeWorkout: 'Free workout',
        menu: 'Menu'
      },
      banner: {
        active: 'Active workout: {name}',
        resume: 'Resume',
        cancel: 'Cancel',
        cancelConfirm: 'Really cancel active workout? All progress will be lost.',
        cancelWorkoutConfirm: 'Really cancel workout? All progress will be lost.'
      },
      targetHold: 'Goal: hold {seconds}',
      holdDurationLabel: 'Hold duration (sec)',
      hold: 'Hold',
      setLogger: {
        title: 'Log set {number}',
        reps: 'Reps',
        weight: 'Weight',
        weightUnit: 'kg',
        logSet: 'Log set',
        addSet: 'Add set',
        duplicateLast: 'Copy last set',
        completedSets: 'Completed sets',
        set: 'Set',
        target: 'Goal',
        targetSets: '{sets} sets',
        targetReps: '{reps} reps',
        rest: '{seconds}s rest',
        noSets: 'No sets logged yet',
        enterReps: 'Please enter the number of reps',
        enterHold: 'Please enter the hold duration',
        atLeastOneSet: 'Please log at least one set before continuing',
        deleteSet: 'Delete set',
        deleteSetConfirm: 'Really delete this set?',
        decreaseWeight: 'Decrease weight',
        increaseWeight: 'Increase weight',
        stepModeChanged: 'Step size: {step} {unit}'
      },
      exercise: {
        current: 'Current exercise',
        next: 'Next exercise',
        finish: 'End workout',
        progress: '{completed} / {total} exercises'
      },
      logging: {
        exercisesOptional: 'Exercises (optional)',
        addExercise: 'Add exercise',
        exerciseAlreadyAdded: 'Exercise already added',
        sets: 'Sets',
        reps: 'Reps per set',
        set: 'Set',
        totalReps: 'Reps'
      },
      lastPerformance: 'Last time',
      noPreviousData: 'No previous data',
      copyLastSet: 'Copy last set',
      relativeTime: {
        today: 'today',
        yesterday: 'yesterday',
        daysAgo: '{n} days ago',
        oneWeekAgo: '1 week ago',
        weeksAgo: '{n} weeks ago'
      },
      cardio: {
        duration: 'Duration (min)',
        distance: 'Distance (km)',
        rpe: 'Effort (1–5)',
        pace: 'Pace',
        log: 'Log cardio'
      },
      recovery: {
        duration: 'Duration (min)',
        log: 'Log recovery'
      },
      postWorkout: {
        title: 'Workout completed!',
        fallbackName: 'Training',
        minutes: 'Minutes',
        sets: 'Sets',
        exercises: 'Exercises',
        toProgress: 'View progress',
        comparisonTitle: 'Comparison to last time',
        time: 'Time',
        volume: 'Volume'
      },
      feedback: {
        saved: 'Workout saved!',
        saveError: 'Error saving workout',
        restartError: 'Error restarting workout',
        exerciseComplete: 'Exercise completed!',
        enterDuration: 'Please enter duration'
      },
      editDate: {
        prompt: 'New date (YYYY-MM-DD):',
        error: 'Invalid date format. Please use YYYY-MM-DD'
      }
    },
    workoutModal: {
      exercises: 'Exercises',
      sets: 'Sets',
      noExercises: 'No exercises',
      exercise: 'Exercise',
      noSets: 'No sets',
      addSet: 'Add set',
      removeSet: 'Remove set',
      reps: 'Reps',
      deleteConfirm: 'Really delete this workout? This action cannot be undone.',
      deleteError: 'Error deleting',
      sessionNotFound: 'Session not found.',
      invalidDuration: 'Please enter a valid duration.',
      saveError: 'Error saving'
    },
    bottomSheet: {
      title: 'Select',
      searchPlaceholder: 'Search...',
      noOptions: 'No options found',
      selected: 'selected'
    },
    templateFeedback: {
      saved: 'Template saved',
      saveError: 'Error saving',
      deleted: 'Template deleted',
      deleteError: 'Error deleting',
      deleteConfirm: 'Really delete this template?',
      notFound: 'Template not found',
      planned: 'Template scheduled',
      planError: 'Error scheduling',
      nameRequired: 'Please enter a name'
    },
    numberPicker: {
      repsTitle: 'Reps',
      setsTitle: 'Sets',
      weightTitle: 'Weight',
      holdTitle: 'Hold duration'
    },
    template: {
      sessionTemplate: 'Session template',
      workoutTemplate: 'Workout template',
      createTemplate: 'Create template',
      selectType: 'Select type',
      cardioTemplate: {
        title: 'Cardio template',
        name: 'Name',
        namePlaceholder: 'e.g. Morning run',
        targetDuration: 'Target duration (min)',
        targetDistance: 'Target distance (km)',
        activityType: 'Activity type',
        intervals: 'Intervals',
        intervalsDescription: 'Optional interval structure',
        notes: 'Notes',
        trainingType: 'Training type',
        trainingTypes: {
          liss: 'LISS',
          zone2: 'Zone 2',
          hiit: 'HIIT',
          tempo: 'Tempo',
          intervals: 'Intervals'
        },
        trainingTypeInfo: {
          liss: 'Low Intensity Steady State - Consistent low intensity. Ideal for base endurance and active recovery.',
          zone2: 'Training in the aerobic zone (60-70% max HR). Improves fat burning and base endurance.',
          hiit: 'High Intensity Interval Training - Short, intense work phases with recovery periods. Efficient for fitness.',
          tempo: 'Consistent training at medium to high intensity. Improves lactate threshold.',
          intervals: 'Alternating between work and recovery phases. Flexibly adjustable.'
        }
      },
      recoveryTemplate: {
        title: 'Recovery template',
        name: 'Name',
        namePlaceholder: 'e.g. Morning yoga',
        targetDuration: 'Target duration (min)',
        focusArea: 'Focus area',
        focusAreas: {
          fullBody: 'Full body',
          upperBody: 'Upper body',
          lowerBody: 'Lower body',
          back: 'Back',
          hips: 'Hips',
          shoulders: 'Shoulders'
        },
        notes: 'Notes'
      },
      wizard: {
        step1: 'Type',
        step2: 'Details',
        step3: 'Exercises',
        step4: 'Review'
      },
      strengthTemplate: {
        title: 'Strength template',
        discipline: 'Training type',
        disciplines: {
          bodyweight: 'Bodyweight / Calisthenics',
          weights: 'Weights / Gym'
        },
        disciplineInfo: {
          bodyweight: 'Training with your own bodyweight. Weight is optional (e.g. weight vest).',
          weights: 'Training with dumbbells, machines or weights. Weight tracking is important.'
        }
      },
      planIcon: 'Plan icon',
      selectPlanIcon: 'Choose an icon for this plan'
    },
    planner: {
      scheduleSession: 'Schedule session',
      scheduleWorkout: 'Schedule workout',
      selectTemplate: 'Select template',
      noTemplates: 'No templates available'
    },
    format: {
      duration: {
        zero: '0 min',
        minutes: '{minutes} min',
        hours: '{hours}h',
        hoursMinutes: '{hours}h {minutes}m'
      },
      distanceKm: '{distance} km',
      pace: {
        na: '-',
        value: '{min}:{sec} min/km'
      }
    },
    balance: {
      context: {
        balanced: 'balanced',
        strength: 'slightly strength-focused',
        cardio: 'slightly cardio-focused',
        lowData: 'Not enough data yet - just keep going'
      }
    },
    dashboard: {
      today: 'Today',
      quickStats: {
        thisWeek: 'This week',
        sessions: 'Sessions',
        movementMinutes: 'Movement min.'
      },
      primary: {
        title: 'Workout',
        subtitleActive: 'A workout is active.',
        subtitleInactive: 'Choose strength, cardio or recovery.',
        helper: 'Start or continue your current training.',
        start: 'Start workout',
        resume: 'Resume workout'
      },
      scheduled: {
        title: 'Planned for today'
      },
      addWorkout: {
        title: 'Add workout'
      },
      logWorkout: {
        title: 'Log workout',
        subtitle: 'Log, start or plan a workout',
        log: 'Log workout',
        logDesc: 'Record a completed training',
        plan: 'Plan workout',
        planDesc: 'Plan a training in the calendar',
        start: 'Start workout',
        startDesc: 'Start a training from your plans'
      },
      hybridBalance: {
        title: 'Hybrid Balance',
        subtitle: 'Last {days} days',
        description: 'Shows time distribution between strength and cardio.',
        aria: 'Strength {strength} percent, Cardio {cardio} percent'
      },
      recent: {
        title: 'Recent sessions',
        description: 'Last sessions in chronological order.',
        empty: 'No sessions yet',
        viewAll: 'View all'
      },
      allSessions: {
        title: 'All sessions',
        empty: 'No sessions yet',
        today: 'Today',
        yesterday: 'Yesterday',
        earlier: 'Earlier'
      },
      activityCalendar: {
        thisMonth: 'This month',
        durationUnit: 'Movement hours',
        emptyState: 'No sessions in this period yet',
        more: 'More'
      },
      trainingTypes: {
        strength: 'Strength training',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio',
        recovery: 'Recovery'
      },
      calendar: {
        tabActivity: 'Activity',
        tabPlan: 'Plan',
        addTraining: 'Add workout',
        prevMonth: 'Previous month',
        nextMonth: 'Next month'
      },
      planCalendar: {
        title: 'Plan calendar'
      },
      startWorkout: {
        selectPlan: 'Select plan',
        selectPlanDesc: 'Start a training from your plans',
        newWorkout: 'New workout',
        newWorkoutDesc: 'Start an empty workout and add exercises'
      }
    },
    progress: {
      tabs: {
        overview: 'Overview',
        strength: 'Strength',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio'
      },
      overview: {
        title: 'Progress',
        subtitle: 'Strength and cardio tracking',
        emptyTitle: 'No workouts yet',
        emptyBody: 'Start your first training or log a session to see your progress',
        periodDays: '{days} days',
        stats: {
          strengthCount: 'Strength sessions',
          cardioCount: 'Cardio sessions',
          totalTime: 'Training time',
          streak: 'Streak',
          streakUnit: 'days'
        },
        consistencyHelper: 'Consistency is based on your workouts in this period.',
        hybridBalanceHelper: 'Balance shows the time split between strength and cardio.',
        activityCalendarTitle: 'Activity calendar',
        activityCalendarHelper: 'Tap a day to see sessions.',
        activityDayEmpty: 'No sessions on this day',
        addSessionAria: 'Add session'
      },
      hybridBalance: {
        title: 'Hybrid Balance',
        subtitle: 'Last {days} days',
        toggleLabel: 'Period',
        sevenDays: '7D',
        thirtyDays: '30D',
        metaStrength: 'Strength {duration}',
        metaCardio: 'Cardio {duration}'
      },
      consistency: {
        title: 'Rhythm & Consistency',
        sessionsPerWeek: 'Sessions/week',
        timePerWeek: 'Time/week',
        daysSinceLast: 'Since last session',
        daysSinceLastUnit: 'days',
        restDays: 'Rest days',
        trainingDays: 'Training days'
      },
      insights: {
        noSessions: 'No sessions in this period yet.',
        balanced: 'Balanced mix of strength and cardio.',
        strengthFocused: 'Focus on strength training.',
        cardioFocused: 'Focus on cardio.',
        restDay: 'Rest day today.',
        sessionsThisWeek: '{count} training days in this period.'
      },
      form: {
        title: 'Training Phase',
        buildingBaseline: 'Building baseline',
        zoneDetrained: 'Detrained',
        zoneDeclining: 'Declining',
        zoneRecovery: 'Recovery',
        zoneMaintaining: 'Maintaining',
        zoneBuilding: 'Base',
        zoneProductive: 'Building',
        zonePeakForm: 'Peak Form',
        trendRising: 'Trend rising',
        trendStable: 'Trend stable',
        trendFalling: 'Trend falling',
        hintDetrained: 'You have been inactive for a while. Start gently with short, easy sessions.',
        hintDeclining: 'Your form is declining. Train again soon to stop the downward trend.',
        hintRecovery: 'Your body is recovering. Use the break – light active recovery if needed.',
        hintMaintaining: 'You are maintaining your current level. Increase load for further progress.',
        hintBuilding: 'You are training consistently and building a solid base.',
        hintProductive: 'Your training is paying off. Keep going – you are approaching peak form!',
        hintPeakForm: 'You are in peak form! A rare state – use it for peak performances.',
        phasesTitle: 'What do the phases mean?',
        infoTitle: 'What does Training Phase mean?',
        infoBody: 'Your training phase shows your long-term fitness status. Regular training builds form. During breaks it declines – slowly at first, then faster.',
        infoRecoveryCondition: '2–5 days rest'
      },
      readiness: {
        title: 'Training Readiness',
        lowLoad: 'Low Load',
        balanced: 'Balanced',
        highLoad: 'High Load',
        descLow: 'Your current training load is below your average.',
        descBalanced: 'Your training load is in the optimal range.',
        descHigh: 'Your training load is high. Make sure to recover.',
        zoneOverreaching: 'Overreached',
        zoneFatigued: 'Fatigued',
        zoneMaintaining: 'Loaded',
        zoneBuilding: 'Ready',
        zonePeak: 'Fresh',
        zoneFormLoss: 'Form Loss',
        buildingBaseline: 'Building baseline',
        infoTitle: 'What does Training Readiness mean?',
        infoBody: 'Your training readiness shows the ratio between your short-term and long-term training load. It drops after training and rises with recovery.',
        infoZoneOverreaching: 'Your current training volume is significantly higher than usual. Prioritize recovery.',
        infoZoneFatigued: 'You are training slightly above your average. Train smart and listen to your body.',
        infoZoneMaintaining: 'Your body is processing the current training load.',
        infoZoneBuilding: 'You are well recovered and ready for your next workout.',
        infoZonePeak: 'You are fully recovered. Ideal time for intense sessions.',
        infoZoneFormLoss: 'An extended training break has been detected. Your fitness level may decline.',
        subtitle: 'Based on your training volume over the past weeks',
        subtitleFormLoss: 'Extended training break detected',
        noData: 'Not enough training data yet',
        windowLabel: '7/28 days',
        insightNoData: 'Start logging training to build your baseline.',
        insightZoneOverreaching: 'Your training load is very high. Make sure to plan enough recovery.',
        insightZoneFatigued: 'You are training a bit more than usual. Pay attention to recovery.',
        insightZoneMaintaining: 'Your training is well balanced right now.',
        insightZoneBuilding: 'You are well recovered and ready for your next workout.',
        insightZonePeak: 'Your body is fully recovered. Ideal for intense sessions.',
        insightZoneFormLoss: 'You have trained little in recent days. Your body is recovered.',
        hintLow: 'You are well recovered. Ideal time for an intense workout.',
        hintMaintaining: 'Moderate load. You can continue training normally.',
        hintBuilding: 'You are ready for your next workout.',
        hintPeak: 'Fully recovered. Ideal for intense training sessions.',
        phasesTitle: 'What do the levels mean?',
        changeNoData: 'Start training to see how your recovery status evolves.',
        changeNone: "Your recovery status hasn't changed.",
        changeUpTraining: 'Your recent training increased short-term load.',
        changeUpRecovery: 'Recovery reduced fatigue.',
        changeDownTraining: 'Your recent training increased fatigue.',
        changeDownRecovery: 'Reduced training lowered your short-term load.',
        changeBaseline: 'Your long-term training baseline has shifted.',
        changeSubLoad: '+{load} load from your last workout',
        changeSubRest: '\u2212{load} load due to {days} rest days',
        changeDriver: 'Main driver: {name} ({duration} min)'
      },
      baseline: {
        days: 'days',
        noData: 'Log your first workout to start building your baseline',
        building: 'Building baseline – {days} more days needed',
        complete: 'Baseline built'
      },
      recommendation: {
        title: "Today's Recommendation",
        noData: 'Log your training regularly to receive personalized recommendations.',
        intensityRest: 'Rest',
        intensityLow: 'Light',
        intensityModerate: 'Moderate',
        intensityHigh: 'Intense',
        overreaching: 'Your body needs recovery. Take a rest day or do very light mobility work.',
        formLoss: "You've been inactive for a while. Start with a light session to ease back in.",
        formLossDetrained: "You've been inactive for a longer time. Start gently with a short, easy session.",
        recoveryResting: 'Your body is recovering. Rest up or do light active recovery.',
        recoveryReady: "You're recovered and ready. A moderate workout would be ideal now.",
        fatiguedGoodForm: "Despite good form, you're fatigued. Go light today or do active recovery.",
        fatiguedDefault: "You're fatigued. Take it easy today or rest.",
        maintainingPeak: 'Stable load with good form. Moderate training as planned.',
        maintainingDefault: "Train as planned. You're handling the current load well.",
        buildingGoodForm: 'Great time for a challenging workout! Your form and recovery align well.',
        buildingDefault: "You're ready to train. Progress gradually.",
        peakGoodForm: 'Perfect day for a top session! Fully recovered and in great form.',
        peakDetrained: "You're well recovered — use this for a moderate comeback workout.",
        peakDefault: "You're fully recovered. Great day for an intense session!"
      },
      bodyweight: {
        title: 'Bodyweight',
        emptyTitle: 'No bodyweight sessions yet',
        emptyBody: 'Start a bodyweight training to see your progress.',
        intensityTitle: 'Intensity levels',
        intensityHint: 'Load class per session based on reps and exercise type.',
        effortTitle: 'Effort trend',
        effortHint: 'Relative effort over time (reps x load factor).',
        intensityLow: 'Low',
        intensityMedium: 'Medium',
        intensityHigh: 'High',
        stats: {
          lastWeek: 'Last week',
          bestWeek: 'Best week',
          average: 'Average',
          sessions: 'Sessions'
        },
        chartTitle: 'Bodyweight Effort - {period}',
        noData: 'No bodyweight data for this period yet'
      },
      period: {
        '7d': '7 days',
        '30d': '30 days',
        '6m': '6 months',
        '1y': '1 year',
        bucket: {
          day: 'Days',
          week: 'Weeks'
        }
      },
      labels: {
        lastBucket: 'Last {bucket}',
        bestBucket: 'Best {bucket}',
        fastestBucket: 'Fastest {bucket}'
      },
      activityCalendar: {
        monthTitle: '{month}',
        sheetTitle: 'Sessions on {date}',
        prevMonth: 'Previous month',
        nextMonth: 'Next month',
        dayLabel: '{day}. {count} sessions',
        overflow: '+{count}',
        weekday: {
          mon: 'Mo',
          tue: 'Tu',
          wed: 'We',
          thu: 'Th',
          fri: 'Fr',
          sat: 'Sa',
          sun: 'Su'
        }
      },
      session: {
        typeStrength: 'Strength',
        typeCardio: 'Cardio',
        typeRecovery: 'Recovery',
        durationNA: 'Duration n/a'
      },
      cardio: {
        emptyTitle: 'No cardio sessions yet',
        emptyBody: 'Log your first cardio session to see your progress',
        add: 'Add cardio session',
        activityPicker: 'Select activity',
        activityPickerTitle: 'Select activity',
        activityLabel: 'Activity',
        periodShort: '{weeks} weeks',
        metricTime: 'Time',
        metricDistance: 'Distance',
        metricPace: 'Pace',
        metricLabel: {
          time: 'Time (min)',
          distance: 'Distance (km)',
          pace: 'Pace (min/km)'
        },
        metricUnit: {
          time: 'min',
          distance: 'km',
          pace: 'min/km'
        },
        metricHelper: 'Pace is calculated from time and distance.',
        helper: 'Values are based on your cardio sessions in the selected period.',
        paceEmptyTitle: 'Pace data',
        paceEmptyValue: 'Not enough data',
        paceEmptyHint: 'Log sessions with distance for pace calculation',
        stats: {
          lastWeek: 'Last week',
          bestWeek: 'Best week',
          average: 'Average',
          sessions: 'Sessions'
        },
        chartTitle: '{metric} - {period}',
        noData: 'No data for this activity yet',
        noPaceData: 'Log sessions with distance for pace data'
      },
      strength: {
        emptyTitle: 'No strength workouts yet',
        emptyBody: 'Start a workout to track your progress',
        periodShort: '{weeks} weeks',
        stats: {
          lastWeek: 'Last week',
          bestWeek: 'Best week',
          average: 'Average',
          sessions: 'Sessions'
        },
        chartTitle: 'Strength volume - {period}',
        noData: 'No data for this period yet',
        helper: 'Volume is based on your tracked strength sessions.',
        summary: {
          exercises: 'Exercises',
          sets: 'Sets',
          reps: 'Reps'
        },
        loadIndex: {
          title: 'Load level',
          hint: 'Average workload per session (weight x reps).',
          chartTitle: 'Load level - {period}',
          unit: 'kg',
          noData: 'No weighted workouts in this period yet'
        },
        variance: {
          title: 'Training variance',
          hint: 'How varied your training is.',
          low: 'Focused',
          medium: 'Balanced',
          high: 'Varied'
        },
        structure: {
          title: 'Structure distribution',
          noData: 'Structure data not available',
          hint: 'Push/Pull/Legs/Core based on your training plans.'
        },
        volume: {
          weighted: 'Weighted volume',
          weightedShort: 'Weighted',
          weightedHint: 'Weight x reps (kg)',
          bodyweight: 'Bodyweight volume',
          bodyweightShort: 'Bodyweight',
          bodyweightHint: 'Reps x load factor (estimate)',
          combined: 'Total',
          metric: 'Metric',
          infoTitle: 'Volume calculation',
          infoWeighted: 'Weighted volume: Sum of weight x reps for all weighted sets.',
          infoBodyweight: 'Bodyweight volume: Reps x exercise-specific load factor. Pull-ups (1.5x) > Push-ups (1.0x). A rough estimate for trend visualization.',
          noWeighted: 'No weighted exercises in this period',
          noBodyweight: 'No bodyweight exercises in this period',
          chartTitleWeighted: 'Weighted volume - {period}',
          chartTitleBodyweight: 'Bodyweight volume - {period}'
        }
      },
      modals: {
        workoutNotFound: 'Workout not found',
        deleteConfirm: 'Really delete this workout? This action cannot be undone.',
        deleteCalendarConfirm: 'Really delete this session?',
        deleteError: 'Error deleting: {message}',
        deleteErrorShort: 'Error deleting',
        modalUnavailable: 'Modal not available',
        cardioModalUnavailable: 'Cardio modal not available',
        recoveryModalUnavailable: 'Recovery modal not available'
      },
      v3: {
        title: 'Progress',
        rhythm: {
          title: 'Training rhythm',
          subtitle: 'Last 12 months',
          subtitleDays: 'Last 7 days',
          subtitleWeeks: 'Last 5 weeks',
          subtitle6m: 'Last 6 months',
          minutesPerWeek: 'min',
          noData: 'No training data yet'
        },
        blockComparison: {
          title: 'Block comparison',
          last4w: 'Last 4 weeks',
          prev4w: 'Previous 4 weeks',
          sessionsPerWeek: 'Sessions / week',
          minutesPerWeek: 'Minutes / week',
          cardioShare: 'Cardio share',
          noChange: 'unchanged',
          noPrevData: 'No comparison data'
        },
        mix: {
          title: 'Training mix',
          noData: 'No data in this period'
        },
        cardioSnapshot: {
          title: 'Cardio',
          toggleTime: 'Time',
          toggleDistance: 'Distance',
          togglePace: 'Pace',
          totalTime: 'Total time',
          totalDistance: 'Total distance',
          avgPace: 'Avg. pace',
          noPaceData: 'Not enough distance data',
          noData: 'No cardio data in this period',
          weekLabel: 'CW {week}'
        },
        stories: {
          title: 'Summary',
          sessionsSummary: 'Last {days} days: {count} sessions (avg {avg} min)',
          longestBreak: 'Longest break: {days} days',
          strengthWeeks: 'Strength training in {active} of {total} weeks',
          noData: 'No sessions yet'
        },
        types: {
          strength: 'Strength',
          bodyweight: 'Bodyweight',
          cardio: 'Cardio',
          recovery: 'Recovery'
        }
      },
      v4: {
        tabs: {
          overview: 'Overview',
          exercises: 'Exercises',
          plans: 'Plans'
        },
        overview: {
          workouts: 'Workouts',
          trainingTime: 'Training Time',
          totalVolume: 'Total Volume',
          activeDays: 'Active Days',
          sessionHistory: 'Session History',
          noSessions: 'No sessions in this period',
          minutes: 'min',
          showMore: 'Show {count} more',
          showLess: 'Show less',
          runningStats: 'Running Stats',
          runs: 'runs',
          totalTime: 'Total time',
          totalDistance: 'Distance',
          avgPace: 'Pace',
          runCharts: 'Run Trends',
          distancePerWeek: 'Distance per Week',
          paceTrend: 'Pace Trend',
          durationPerMonth: 'Duration per Month',
          sessionsPerMonth: 'Sessions per Month',
          runChartTooltipRuns: 'Runs',
          enduranceTrends: 'Endurance Trends',
          sportRun: 'Run',
          sportBike: 'Bike',
          sportSwim: 'Swim',
          sportHike: 'Hike',
          sessions: 'Sessions',
          avgSpeed: 'Speed',
          speedTrend: 'Speed Trend',
          swimPace: 'Pace (100m)',
          noDataHint: 'Not enough data yet. Complete a workout of this type to see insights.',
        },
        exercises: {
          title: 'Exercise Trends',
          sessions: '{count} sessions',
          noExercises: 'No exercises completed yet',
          noFilterResults: 'No exercises found',
          searchPlaceholder: 'Search exercise...',
          allMuscles: 'All',
          detail: {
            pr: 'Personal Record',
            average: 'Average',
            lastSession: 'Last Session',
            history: 'History',
            sets: 'Sets',
            volume: 'Volume'
          }
        },
        plans: {
          title: 'Plan Progress',
          lastSession: 'Last: {date}',
          sessions: '{count} sessions',
          noPlans: 'No plans completed yet',
          detail: {
            timeline: 'Timeline',
            vsLast: 'vs. last time',
            session: 'Session {num}',
            noComparison: 'First session'
          }
        },
        postWorkout: {
          exercisesTitle: 'Exercise Details',
          badgeNew: 'New',
          badgeRemoved: 'Last time',
          noChange: 'same',
          improved: 'improved',
          declined: 'declined'
        }
      }
    },
    profile: {
      title: 'Profile',
      bodyWeight: 'Body weight',
      bodyHeight: 'Height',
      trainingStyle: 'Training style',
      gym: 'Gym',
      bodyweight: 'Bodyweight',
      hybrid: 'Hybrid',
      editName: 'Edit name',
      nameUpdated: 'Name updated',
      profileUpdated: 'Profile updated'
    },
    settings: {
      general: 'General',
      workout: 'Workout',
      progress: 'Progress',
      integrations: 'Integrations',
      account: 'Account',
      appInfo: 'App Information',
      language: 'Language',
      unitSystem: 'Units',
      metric: 'KG',
      imperial: 'LBS',
      langDe: 'DE',
      langEn: 'EN',
      defaultRestTimer: 'Default rest timer',
      haptics: 'Haptic feedback',
      defaultPeriod: 'Default period',
      comingSoon: 'Coming soon',
      connect: 'Connect',
      connected: 'Connected',
      email: 'Email',
      signOut: 'Sign out',
      deleteAccount: 'Delete account',
      deleteAccountConfirm: 'Really delete account?',
      deleteAccountConfirmText: 'All data will be permanently deleted. This action cannot be undone.',
      deleteAccountButton: 'Delete permanently',
      saved: 'Saved',
      seconds: '{n}s',
      theme: 'Appearance',
      themeDark: 'Dark',
      themeLight: 'Light',
      version: 'Version',
      build: 'Build'
    },
    errors: {
      startUnavailable: 'Start selection is not available.',
      workoutNotFound: 'Workout not found',
      sessionNotFound: 'Session not found',
      planNotFound: 'Plan not found',
      workoutStartFailed: 'Error starting workout',
      deleteFailed: 'Error deleting',
      saveFailed: 'Error saving.',
      exercisesLoading: 'Exercises are still loading. Please try again shortly.',
      planNameRequired: 'Please enter a name for the plan!',
      planExercisesRequired: 'Please add at least one exercise!',
      exerciseNameRequired: 'Please enter a name for the exercise!',
      muscleGroupsRequired: 'Please select at least one muscle group!'
    },
    feedback: {
      title: 'How was your workout?',
      subtitle: 'Quick feedback helps you track your progress better.',
      preEnergy: 'Pre-workout energy',
      postFeeling: 'Post-workout feeling',
      rpeLabel: 'Effort (RPE)',
      submit: 'Save',
      skip: 'Skip',
      energy: {
        1: 'Very low',
        2: 'Low',
        3: 'Normal',
        4: 'High',
        5: 'Very high'
      },
      feeling: {
        1: 'Very bad',
        2: 'Bad',
        3: 'Okay',
        4: 'Good',
        5: 'Very good'
      },
      rpe: {
        1: 'Very easy',
        2: 'Easy',
        3: 'Moderate',
        4: 'Hard',
        5: 'Maximum'
      }
    },
    block: {
      typeSheet: {
        title: 'Add Block',
        normal: 'Single Exercise',
        normalDesc: 'Classic set-based',
        superset: 'Superset',
        supersetDesc: '2–3 exercises alternating',
        emom: 'EMOM',
        emomDesc: 'Every Minute On the Minute'
      },
      emomConfig: {
        title: 'Configure EMOM',
        duration: 'Duration (min)',
        interval: 'Interval (s)',
        repsLabel: 'Target per exercise',
        reps: 'Reps',
        save: 'Add Block',
        update: 'Update Block'
      },
      supersetConfig: {
        title: 'Configure Superset',
        sets: 'Sets',
        reps: 'Reps',
        restBetween: 'Rest between supersets',
        save: 'Add Block',
        update: 'Update Block'
      },
      planRender: {
        emomLabel: 'EMOM · {minutes} min',
        emomSub: 'Every {interval}s · {count} exercises',
        supersetLabel: 'Superset',
        supersetSub: '{count} exercises alternating',
        editBlock: 'Edit',
        deleteBlock: 'Delete',
        deleteConfirm: 'Really delete this block?'
      },
      workout: {
        emom: {
          prescreenTitle: 'EMOM',
          prescreenDuration: '{minutes} Minutes',
          prescreenEveryMinute: 'Every minute:',
          start: 'Start',
          skip: 'Skip Block',
          minute: 'Minute {current} / {total}',
          remainingInMinute: 'Remaining in minute',
          totalRemaining: '{time} remaining',
          next: 'Next: {name} ×{reps}',
          done: 'Done',
          missed: 'Missed',
          targetReps: 'Target: ×{reps}',
          actualReps: 'Actual reps',
          logReps: 'Log',
          skipRound: 'Skip',
          loggedReps: '{reps} reps logged',
          loggedTitle: '{reps} reps logged',
          skippedTitle: 'Skipped',
          tapToUndo: 'Tap to undo',
          undoLog: 'Undo entry',
          blockComplete: 'EMOM completed'
        },
        superset: {
          label: 'Superset',
          current: 'Current: {label} {name}',
          restBetween: 'Rest: {seconds}s between supersets',
          roundComplete: 'Round {round} completed'
        },
        blockPill: {
          emom: 'EMOM {minutes}min',
          superset: 'Superset'
        }
      }
    }
  }
};

const defaultLocale = 'de';
let currentLocale = defaultLocale;

function getTranslation(locale, keyPath) {
  return keyPath.reduce((obj, key) => (obj && obj[key] !== undefined ? obj[key] : undefined), translations[locale]);
}

/**
 * @typedef {keyof typeof translations['de']} TranslationKey
 */
function t(key, params = {}) {
  const path = key.split('.');
  let template = getTranslation(currentLocale, path);
  if (template === undefined) {
    template = getTranslation(defaultLocale, path);
  }
  if (template === undefined) return key;

  if (typeof template !== 'string') return key;

  return template.replace(/\{(\w+)\}/g, (match, p1) => {
    if (params[p1] === undefined || params[p1] === null) return '';
    return String(params[p1]);
  });
}

function setLocale(locale) {
  if (translations[locale]) {
    currentLocale = locale;
  }
}

function formatDurationText(totalSeconds) {
  const totalMinutes = Math.round((Number(totalSeconds) || 0) / 60);
  if (!totalMinutes) return t('format.duration.zero');
  if (totalMinutes < 60) return t('format.duration.minutes', { minutes: totalMinutes });
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (minutes) return t('format.duration.hoursMinutes', { hours, minutes });
  return t('format.duration.hours', { hours });
}

function formatDurationShortText(totalSeconds) {
  return formatDurationText(totalSeconds);
}

function formatDateTimeText(date) {
  if (!date) return '';
  return new Intl.DateTimeFormat('de-DE', {
    timeZone: 'Europe/Berlin',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date);
}

function formatDateShortText(date) {
  if (!date) return '';
  return new Intl.DateTimeFormat('de-DE', {
    timeZone: 'Europe/Berlin',
    day: '2-digit',
    month: '2-digit'
  }).format(date);
}

function getIntlLocale() {
  return currentLocale === 'en' ? 'en-US' : 'de-DE';
}

function formatDateLongText(date, includeYear = true) {
  if (!date) return '';
  return new Intl.DateTimeFormat(getIntlLocale(), {
    timeZone: 'Europe/Berlin',
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: includeYear ? 'numeric' : undefined
  }).format(date);
}

function formatMonthYearText(date) {
  if (!date) return '';
  return new Intl.DateTimeFormat(getIntlLocale(), {
    timeZone: 'Europe/Berlin',
    month: 'long',
    year: 'numeric'
  }).format(date);
}

function formatPaceText(minutes, distanceKm) {
  const minValue = Number(minutes);
  const distValue = Number(distanceKm);
  if (!minValue || !distValue) return t('format.pace.na');
  const totalSeconds = Math.round((minValue * 60) / distValue);
  const paceMinutes = Math.floor(totalSeconds / 60);
  const paceSeconds = String(totalSeconds % 60).padStart(2, '0');
  return t('format.pace.value', { min: paceMinutes, sec: paceSeconds });
}

function formatPaceValueText(paceMinPerKm) {
  const value = Number(paceMinPerKm);
  if (!value || value <= 0) return t('format.pace.na');
  let minutes = Math.floor(value);
  let seconds = Math.round((value - minutes) * 60);
  if (seconds >= 60) {
    minutes += 1;
    seconds = 0;
  }
  return t('format.pace.value', { min: minutes, sec: String(seconds).padStart(2, '0') });
}

window.t = t;
window.setLocale = setLocale;
window.formatDurationText = formatDurationText;
window.formatDurationShortText = formatDurationShortText;
window.formatDateTimeText = formatDateTimeText;
window.formatDateShortText = formatDateShortText;
window.formatDateLongText = formatDateLongText;
window.formatMonthYearText = formatMonthYearText;
window.formatPaceText = formatPaceText;
window.formatPaceValueText = formatPaceValueText;
