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
      add: 'Hinzufuegen',
      addSession: 'Session hinzufuegen',
      view: 'Ansehen',
      viewDetails: 'Details ansehen',
      delete: 'Loeschen',
      close: 'Schliessen',
      select: 'Auswahl',
      start: 'Starten',
      startAgain: 'Erneut starten',
      editSession: 'Session bearbeiten',
      duration: 'Dauer',
      notes: 'Notizen',
      activity: 'Aktivitaet',
      time: 'Zeit',
      distance: 'Distanz',
      pace: 'Pace',
      loading: 'Lade Daten...',
      notAvailable: '-',
      save: 'Speichern',
      cancel: 'Abbrechen',
      edit: 'Bearbeiten',
      next: 'Weiter',
      back: 'Zurueck',
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
      profile: 'Profil'
    },
    difficulty: {
      beginner: 'Anfaenger',
      intermediate: 'Fortgeschritten',
      advanced: 'Profi',
      elite: 'Elite',
      label: 'Schwierigkeit',
      descriptions: {
        beginner: 'Ideal fuer Einsteiger ohne Vorkenntnisse',
        intermediate: 'Fuer Trainierende mit Grundkenntnissen',
        advanced: 'Fuer erfahrene Athleten',
        elite: 'Fuer Profis mit mehrjaehriger Erfahrung'
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
        contentStrength: 'Uebungen',
        contentBodyweight: 'Uebungen',
        contentCardio: 'Cardio-Ziel',
        contentRecovery: 'Recovery-Ziel'
      },
      list: {
        emptyTitle: 'Keine Plaene gefunden',
        emptyBody: 'Erstelle deinen ersten Plan',
        emptyCta: 'Plan erstellen',
        loading: 'Lade Plaene...'
      },
      meta: {
        exercises: '{count} Uebungen',
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
          liss: 'Low Intensity Steady State - Gleichmaessige niedrige Intensitaet',
          hiit: 'High Intensity Interval Training - Kurze intensive Intervalle',
          zone2: 'Aerobe Zone (60-70% HFmax) - Grundlagenausdauer',
          tempo: 'Mittlere bis hohe Intensitaet - Laktatschwelle'
        }
      },
      cardioGoalType: {
        label: 'Zieltyp',
        liss: 'LISS',
        hiit: 'HIIT',
        intervals: 'Intervals',
        freestyle: 'Freestyle',
        info: {
          liss: 'Gleichmaessige niedrige Intensitaet fuer Grundlagenausdauer.',
          hiit: 'Kurze, intensive Intervalle mit Pausen.',
          intervals: 'Wiederholte Belastungsbloecke mit definierten Pausen.',
          freestyle: 'Freies Cardio ohne festen Intensitaetsplan.'
        }
      },
      cardio: {
        durationLabel: 'Dauer (Minuten)',
        distanceLabel: 'Distanz (km)',
        activityLabel: 'Aktivitaetstyp',
        targetHint: 'Mind. Dauer oder Distanz empfohlen',
        activityOptions: {
          run: 'Laufen',
          bike: 'Radfahren',
          swim: 'Schwimmen',
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
      notesPlaceholder: 'Zusaetzliche Informationen...',
      exercises: 'Uebungen',
      addExercise: 'Uebung hinzufuegen',
      exercisesHint: 'Fuege Uebungen zu deinem Plan hinzu',
      exercisesEmptyTitle: 'Noch keine Uebungen hinzugefuegt',
      exercisesEmptyBody: 'Fuege Uebungen aus der Datenbank hinzu',
      exerciseRemoveConfirm: 'Uebung aus dem Plan entfernen?',
      exerciseConfig: {
        title: 'Uebung konfigurieren',
        setsLabel: 'Saetze *',
        setsShort: 'Saetze',
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
        title: 'Uebungen auswaehlen',
        searchPlaceholder: 'Uebung suchen...',
        noExercisesTitle: 'Keine Uebungen verfuegbar',
        noExercisesBody: 'Erstelle zuerst Uebungen in der Uebungsdatenbank',
        noResultsTitle: 'Keine Uebungen gefunden',
        noResultsBody: 'Versuche einen anderen Suchbegriff oder Filter',
        filterInfo: '{count} von {total} Uebungen gefunden ({filters})',
        filterSearch: 'Suche: "{term}"',
        filterMuscle: 'Muskelgruppe: {muscle}',
        addSelected: '{count} Uebungen hinzufuegen',
        addSelectedOne: '1 Uebung hinzufuegen',
        selectHint: 'Uebungen auswaehlen'
      },
      deleteConfirm: 'Plan wirklich loeschen?',
      deleteSuccess: 'Plan geloescht.',
      deleteError: 'Fehler beim Loeschen des Plans.',
      picker: {
        title: 'Plan auswaehlen',
        searchPlaceholder: 'Plan suchen...',
        noPlans: 'Keine Plaene verfuegbar',
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
        add: 'Hinzufuegen',
        nameRequired: 'Bitte gib einen Namen ein'
      },
      addPlan: 'Plan hinzufuegen',
      quickAdd: 'Schnell-Eintrag',
      orQuickEntry: 'Oder Schnell-Eintrag erstellen',
      orSelectPlan: 'oder Plan auswaehlen',
      today: 'Heute',
      noPlannedWorkouts: 'Keine Trainings geplant',
      entryAdded: 'Training hinzugefuegt',
      saveError: 'Fehler beim Speichern',
      untitled: 'Unbenannt',
      confirmRemove: 'Training wirklich entfernen?',
      monthNames: {
        january: 'Januar',
        february: 'Februar',
        march: 'Maerz',
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
        modalNotAvailable: 'Erfassungsmodul nicht verfuegbar'
      }
    },
    exercise: {
      title: 'Uebung',
      name: 'Uebungsname',
      namePlaceholder: 'z.B. Klimmzuege',
      muscleGroups: 'Muskelgruppen',
      filters: {
        allMuscles: 'Alle Muskelgruppen',
        allDifficulties: 'Alle Schwierigkeiten'
      },
      equipment: 'Equipment',
      discipline: 'Disziplin',
      visual: 'Uebungs-Icon',
      selectIcon: 'Icon auswaehlen',
      listSectionOther: '#',
      instructions: {
        title: 'Anleitung',
        hint: 'Beschreibe die Ausfuehrung Schritt fuer Schritt.',
        stepTitle: 'Schritt {number}',
        stepPlaceholder: 'Beschreibe diesen Schritt...',
        addStep: 'Schritt hinzufuegen',
        removeStep: 'Schritt entfernen',
        noSteps: 'Noch keine Schritte hinzugefuegt',
        advanced: {
          title: 'Erweiterte Hinweise',
          add: 'Erweiterte Hinweise hinzufuegen',
          hide: 'Erweiterte Hinweise ausblenden',
          emptyList: 'Noch keine Hinweise hinzugefuegt',
          cues: 'Cues',
          cuesPlaceholder: 'Kurze Hinweise zur Ausfuehrung...',
          cuesAdd: 'Cue hinzufuegen',
          mistakes: 'Haeufige Fehler',
          mistakesPlaceholder: 'Typische Fehler und wie man sie vermeidet...',
          mistakesAdd: 'Fehler hinzufuegen',
          progressions: 'Progressionen',
          progressionsPlaceholder: 'Leichtere oder schwierigere Varianten...',
          progressionsAdd: 'Progression hinzufuegen',
          setup: 'Vorbereitung',
          setupPlaceholder: 'Aufbau, Ausgangsposition und Vorbereitung...'
        },
        setup: 'Vorbereitung',
        setupPlaceholder: 'Ausgangsposition und Griffhaltung...',
        setupDefault: 'Finde eine stabile Ausgangsposition, aktiviere Core und halte Spannung.',
        execution: 'Ausfuehrung',
        executionPlaceholder: 'Bewegungsablauf beschreiben...',
        executionDefault: 'Noch keine Ausfuehrung hinterlegt.',
        cues: 'Cues',
        cuesPlaceholder: 'Wichtige Hinweise waehrend der Ausfuehrung...',
        cuesDefault: 'Achte auf kontrollierte Bewegung und stabile Koerperspannung.',
        mistakes: 'Haeufige Fehler',
        mistakesPlaceholder: 'Typische Fehler und wie man sie vermeidet...',
        mistakesDefault: 'Vermeide Schwung, unkontrollierte Endpositionen und instabile Gelenkwinkel.',
        progressions: 'Progressionen',
        progressionsPlaceholder: 'Leichtere und schwierigere Varianten...',
        progressionsDefault: 'Mehr Range, langsamere Exzentrik oder Zusatzgewicht erhoehen die Intensitaet.'
      },
      categories: {
        upper: 'Oberkoerper',
        lower: 'Unterkoerper',
        core: 'Core',
        fullBody: 'Ganzkoerper',
        cardio: 'Cardio',
        mobility: 'Mobilitaet'
      },
      quickCreate: {
        title: 'Neue Uebung',
        button: 'Neue Uebung erstellen',
        hint: 'Uebung fehlt? Erstelle sie hier schnell.',
        saved: 'Uebung erstellt und hinzugefuegt'
      },
      type: {
        label: 'Typ',
        strength: 'Kraft',
        bodyweight: 'Bodyweight',
        cardio: 'Cardio',
        mobility: 'Mobilitaet',
        recovery: 'Recovery'
      },
      pattern: {
        label: 'Bewegungsmuster',
        push: 'Push',
        pull: 'Pull',
        legs: 'Beine',
        core: 'Core',
        full: 'Ganzkoerper'
      },
      visualAdd: 'Visual hinzufuegen',
      visualUrlPlaceholder: 'Bild-URL eingeben...',
      visualRemove: 'Visual entfernen',
      variants: {
        label: 'Varianten',
        add: 'Variante hinzufuegen',
        namePlaceholder: 'Variantenname...',
        notePlaceholder: 'Kurze Notiz (optional)...',
        remove: 'Variante entfernen',
        empty: 'Noch keine Varianten'
      },
      notesLabel: 'Notizen',
      notesPlaceholder: 'Allgemeine Notizen zur Uebung...',
      create: {
        title: 'Neue Uebung',
        stepBasics: 'Grundlagen',
        stepDetails: 'Details',
        stepOptional: 'optional'
      },
      detail: {
        useInPlan: 'In Plan verwenden'
      },
      searchPlaceholder: 'Uebungen suchen...',
      noResultsTitle: 'Keine Treffer',
      noResultsHint: 'Versuch einen anderen Begriff oder erstelle eine neue Uebung.',
      createNew: 'Neue Uebung erstellen',
      deleteConfirm: 'Uebung wirklich loeschen?',
      deleteUsedInPlans: 'Diese Uebung wird in {count} Plaenen verwendet ({plans}). Trotzdem loeschen? Sie bleibt in bestehenden Sessions erhalten.',
      deleted: 'Uebung geloescht.',
      deleteError: 'Fehler beim Loeschen der Uebung.'
    },
    workout: {
      quick: {
        title: 'Workout Schnell-Eintrag',
        date: 'Datum *',
        dateRequired: 'Bitte waehle ein Datum',
        name: 'Workout Name',
        duration: 'Dauer (Minuten)',
        type: 'Typ',
        difficulty: 'Schwierigkeit',
        bodyweight: 'Bodyweight',
        bodyweightDesc: 'Training mit Eigengewicht',
        weights: 'Gewichte',
        weightsDesc: 'Gym / Hanteln',
        nameRequired: 'Bitte gib einen Workout Namen ein',
        durationRequired: 'Bitte gib eine gueltige Dauer ein',
        saveError: 'Fehler beim Speichern des Workouts'
      },
      screen: {
        exercisesButton: 'Uebungen ({completed}/{total})',
        exercisesSheetTitle: 'Uebungen',
        cancelWorkout: 'Abbrechen',
        endWorkout: 'Workout beenden',
        endWorkoutConfirm: 'Workout wirklich beenden?',
        endWorkoutConfirmText: 'Alle bisherigen Saetze werden gespeichert.',
        nextExercise: 'Naechste Uebung',
        finishWorkout: 'Workout abschliessen',
        currentExercise: 'Aktuelle Uebung',
        goal: 'Ziel',
        rest: 'Pause',
        exerciseOf: 'Uebung {current} von {total}',
        noActiveWorkout: 'Kein aktives Workout',
        noActiveWorkoutText: 'Starte ein Training aus dem Kalender oder einem Plan.',
        toPlans: 'Zu den Plaenen',
        switchToExercise: 'Zu dieser Uebung wechseln',
        saveWorkout: 'Workout speichern',
        discardWorkout: 'Workout verwerfen',
        discardConfirm: 'Workout wirklich verwerfen? Alle Fortschritte gehen verloren.',
        restTimer: 'Pause',
        bodyweight: 'Bodyweight',
        weighted: 'Gewichte',
        addSet: 'Satz hinzufuegen',
        exerciseProgress: '{completed} / {total} Uebungen',
        timerPause: 'Pausieren',
        timerResume: 'Fortsetzen',
        timerSkip: 'Ueberspringen',
        timerStart: 'Timer starten',
        timerAdd: '+10s',
        timerSub: '-10s',
        timerDone: 'Pause vorbei!',
        discardConfirmTitle: 'Workout verwerfen?',
        endWorkoutAction: 'Beenden'
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
        addSet: 'Satz hinzufuegen',
        duplicateLast: 'Letzten Satz kopieren',
        completedSets: 'Abgeschlossene Saetze',
        set: 'Satz',
        target: 'Ziel',
        targetSets: '{sets} Saetze',
        targetReps: '{reps} Wdh',
        rest: '{seconds}s Pause',
        noSets: 'Noch keine Saetze geloggt',
        enterReps: 'Bitte gib die Anzahl der Wiederholungen ein',
        enterHold: 'Bitte gib die Haltedauer ein',
        atLeastOneSet: 'Bitte logge mindestens einen Satz bevor du weitergehst',
        deleteSet: 'Satz loeschen',
        deleteSetConfirm: 'Diesen Satz wirklich loeschen?'
      },
      exercise: {
        current: 'Aktuelle Uebung',
        next: 'Naechste Uebung',
        finish: 'Workout beenden',
        progress: '{completed} / {total} Uebungen'
      },
      logging: {
        exercisesOptional: 'Uebungen (optional)',
        addExercise: 'Uebung hinzufuegen',
        exerciseAlreadyAdded: 'Uebung bereits hinzugefuegt',
        sets: 'Saetze',
        reps: 'Wiederholungen pro Satz',
        set: 'Satz',
        totalReps: 'Wdh.'
      }
    },
    numberPicker: {
      repsTitle: 'Wiederholungen',
      weightTitle: 'Gewicht',
      holdTitle: 'Haltedauer'
    },
    template: {
      sessionTemplate: 'Session-Vorlage',
      workoutTemplate: 'Workout-Vorlage',
      createTemplate: 'Vorlage erstellen',
      selectType: 'Typ auswaehlen',
      cardioTemplate: {
        title: 'Cardio-Vorlage',
        name: 'Name',
        namePlaceholder: 'z.B. Morgenlauf',
        targetDuration: 'Ziel-Dauer (Min)',
        targetDistance: 'Ziel-Distanz (km)',
        activityType: 'Aktivitaetstyp',
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
          liss: 'Low Intensity Steady State - Gleichmaessige, niedrige Intensitaet. Ideal fuer Grundlagenausdauer und aktive Erholung.',
          zone2: 'Training in der aeroben Zone (60-70% max. Herzfrequenz). Verbessert die Fettverbrennung und Grundlagenausdauer.',
          hiit: 'High Intensity Interval Training - Kurze, intensive Belastungsphasen mit Erholungspausen. Effizient fuer Fitness.',
          tempo: 'Gleichmaessiges Training bei mittlerer bis hoher Intensitaet. Verbessert die Laktatschwelle.',
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
          fullBody: 'Ganzkoerper',
          upperBody: 'Oberkoerper',
          lowerBody: 'Unterkoerper',
          back: 'Ruecken',
          hips: 'Hueften',
          shoulders: 'Schultern'
        },
        notes: 'Notizen'
      },
      wizard: {
        step1: 'Typ',
        step2: 'Details',
        step3: 'Uebungen',
        step4: 'Ueberpruefung'
      },
      strengthTemplate: {
        title: 'Kraft-Vorlage',
        discipline: 'Trainingsart',
        disciplines: {
          bodyweight: 'Bodyweight / Calisthenics',
          weights: 'Gewichte / Gym'
        },
        disciplineInfo: {
          bodyweight: 'Training mit dem eigenen Koerpergewicht. Gewicht ist optional (z.B. Gewichtsweste).',
          weights: 'Training mit Hanteln, Maschinen oder Gewichten. Gewichtsangabe ist wichtig fuer Tracking.'
        }
      },
      planIcon: 'Plan-Icon',
      selectPlanIcon: 'Icon fuer diesen Plan waehlen'
    },
    planner: {
      scheduleSession: 'Session planen',
      scheduleWorkout: 'Workout planen',
      selectTemplate: 'Vorlage auswaehlen',
      noTemplates: 'Keine Vorlagen verfuegbar'
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
        subtitleInactive: 'Waehle Kraft, Cardio oder Recovery.',
        helper: 'Starte oder setze dein aktuelles Training fort.',
        start: 'Workout starten',
        resume: 'Workout fortsetzen'
      },
      scheduled: {
        title: 'Geplant fuer heute'
      },
      addWorkout: {
        title: 'Workout hinzufuegen'
      },
      logWorkout: {
        title: 'Workout erfassen',
        subtitle: 'Logge, starte oder plane ein Workout',
        log: 'Workout loggen',
        logDesc: 'Erfasse ein abgeschlossenes Training',
        plan: 'Workout planen',
        planDesc: 'Plane ein Training im Kalender',
        start: 'Workout starten',
        startDesc: 'Starte ein Training aus deinen Plaenen'
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
        earlier: 'Frueher'
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
      }
    },
    progress: {
      tabs: {
        overview: 'Uebersicht',
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
        activityCalendarTitle: 'Aktivitaetskalender',
        activityCalendarHelper: 'Tippe einen Tag, um Sessions zu sehen.',
        activityDayEmpty: 'Keine Sessions an diesem Tag',
        addSessionAria: 'Session hinzufuegen'
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
      bodyweight: {
        title: 'Bodyweight',
        emptyTitle: 'Noch keine Bodyweight-Sessions',
        emptyBody: 'Starte ein Training mit Koerpergewichtsuebungen, um deinen Fortschritt zu sehen.',
        intensityTitle: 'Intensitaetsniveaus',
        intensityHint: 'Belastungsklasse pro Session basierend auf Wiederholungen und Uebungsart.',
        effortTitle: 'Effort-Trend',
        effortHint: 'Relativer Aufwand ueber Zeit (Wdh x Belastungsfaktor).',
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
        noData: 'Noch keine Bodyweight-Daten fuer diesen Zeitraum'
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
        nextMonth: 'Naechster Monat',
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
        add: 'Cardio-Session hinzufuegen',
        activityPicker: 'Aktivitaet auswaehlen',
        activityPickerTitle: 'Aktivitaet auswaehlen',
        activityLabel: 'Aktivitaet',
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
        helper: 'Die Werte basieren auf deinen Cardio-Sessions im gewaehlten Zeitraum.',
        paceEmptyTitle: 'Pace-Daten',
        paceEmptyValue: 'Nicht genug Daten',
        paceEmptyHint: 'Logge Sessions mit Distanz fuer Pace-Berechnung',
        stats: {
          lastWeek: 'Letzte Woche',
          bestWeek: 'Beste Woche',
          average: 'Durchschnitt',
          sessions: 'Sessions'
        },
        chartTitle: '{metric} - {period}',
        noData: 'Noch keine Daten fuer diese Aktivitaet',
        noPaceData: 'Logge Sessions mit Distanz fuer Pace-Daten'
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
        noData: 'Noch keine Daten fuer diesen Zeitraum',
        helper: 'Volumen basiert auf deinen getrackten Kraft-Sessions.',
        summary: {
          exercises: 'Uebungen',
          sets: 'Saetze',
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
          noData: 'Strukturdaten nicht verfuegbar',
          hint: 'Push/Pull/Legs/Core basierend auf deinen Trainingsplaenen.'
        },
        volume: {
          weighted: 'Gewichtetes Volumen',
          weightedShort: 'Gewichtet',
          weightedHint: 'Gewicht x Wdh (kg)',
          bodyweight: 'Bodyweight Volumen',
          bodyweightShort: 'Bodyweight',
          bodyweightHint: 'Wdh x Belastungsfaktor (Schaetzung)',
          combined: 'Gesamt',
          metric: 'Metrik',
          infoTitle: 'Volumen-Berechnung',
          infoWeighted: 'Gewichtetes Volumen: Summe aus Gewicht x Wiederholungen fuer alle Saetze mit Gewicht.',
          infoBodyweight: 'Bodyweight Volumen: Wiederholungen x uebungsspezifischer Belastungsfaktor. Pull-ups (1.5x) > Push-ups (1.0x). Eine grobe Schaetzung zur Trend-Visualisierung.',
          noWeighted: 'Keine gewichteten Uebungen in diesem Zeitraum',
          noBodyweight: 'Keine Bodyweight-Uebungen in diesem Zeitraum',
          chartTitleWeighted: 'Gewichtetes Volumen - {period}',
          chartTitleBodyweight: 'Bodyweight Volumen - {period}'
        }
      },
      modals: {
        workoutNotFound: 'Workout nicht gefunden',
        deleteConfirm: 'Dieses Workout wirklich loeschen? Diese Aktion kann nicht rueckgaengig gemacht werden.',
        deleteCalendarConfirm: 'Diese Session wirklich loeschen?',
        deleteError: 'Fehler beim Loeschen: {message}',
        deleteErrorShort: 'Fehler beim Loeschen',
        modalUnavailable: 'Modal nicht verfuegbar',
        cardioModalUnavailable: 'Cardio-Modal nicht verfuegbar',
        recoveryModalUnavailable: 'Recovery-Modal nicht verfuegbar'
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
          noChange: 'unveraendert',
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
          longestBreak: 'Laengste Pause: {days} Tage',
          strengthWeeks: 'Krafttraining in {active} von {total} Wochen',
          noData: 'Noch keine Sessions vorhanden'
        },
        types: {
          strength: 'Kraft',
          bodyweight: 'Bodyweight',
          cardio: 'Cardio',
          recovery: 'Recovery'
        }
      }
    },
    profile: {
      title: 'Profil',
      bodyWeight: 'Koerpergewicht',
      bodyHeight: 'Koerpergroesse',
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
      comingSoon: 'Demnaechst',
      connect: 'Verbinden',
      connected: 'Verbunden',
      email: 'E-Mail',
      signOut: 'Abmelden',
      deleteAccount: 'Account loeschen',
      deleteAccountConfirm: 'Account wirklich loeschen?',
      deleteAccountConfirmText: 'Alle Daten werden unwiderruflich geloescht. Diese Aktion kann nicht rueckgaengig gemacht werden.',
      deleteAccountButton: 'Endgueltig loeschen',
      saved: 'Gespeichert',
      seconds: '{n}s',
      version: 'Version',
      build: 'Build'
    },
    errors: {
      startUnavailable: 'Start-Auswahl ist nicht verfuegbar.',
      workoutNotFound: 'Workout nicht gefunden',
      sessionNotFound: 'Session nicht gefunden',
      planNotFound: 'Plan nicht gefunden',
      workoutStartFailed: 'Fehler beim Starten des Workouts',
      deleteFailed: 'Fehler beim Loeschen',
      saveFailed: 'Fehler beim Speichern.',
      exercisesLoading: 'Uebungen werden noch geladen. Bitte versuche es gleich erneut.',
      planNameRequired: 'Bitte gib einen Namen fuer den Plan ein!',
      planExercisesRequired: 'Bitte fuege mindestens eine Uebung hinzu!',
      exerciseNameRequired: 'Bitte gib einen Namen fuer die Uebung ein!',
      muscleGroupsRequired: 'Bitte waehle mindestens eine Muskelgruppe!'
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
      profile: 'Profile'
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
        endWorkoutAction: 'End'
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
        deleteSetConfirm: 'Really delete this set?'
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
      }
    },
    numberPicker: {
      repsTitle: 'Reps',
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

function formatDateLongText(date, includeYear = true) {
  if (!date) return '';
  return new Intl.DateTimeFormat('de-DE', {
    timeZone: 'Europe/Berlin',
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: includeYear ? 'numeric' : undefined
  }).format(date);
}

function formatMonthYearText(date) {
  if (!date) return '';
  return new Intl.DateTimeFormat('de-DE', {
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
