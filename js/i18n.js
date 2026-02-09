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
      minutes: 'Minuten'
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
        title: 'Uebung auswaehlen',
        searchPlaceholder: 'Uebung suchen...',
        noExercisesTitle: 'Keine Uebungen verfuegbar',
        noExercisesBody: 'Erstelle zuerst Uebungen in der Uebungsdatenbank',
        noResultsTitle: 'Keine Uebungen gefunden',
        noResultsBody: 'Versuche einen anderen Suchbegriff oder Filter',
        filterInfo: '{count} von {total} Uebungen gefunden ({filters})',
        filterSearch: 'Suche: "{term}"',
        filterMuscle: 'Muskelgruppe: {muscle}'
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
      createNew: 'Neue Uebung erstellen'
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
      weightTitle: 'Gewicht'
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
