// ========================================
// I18N + FORMATTERS
// ========================================

const translations = {
  de: {
    common: {
      workout: 'Workout',
      strength: 'Kraft',
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
      optional: 'optional'
    },
    difficulty: {
      beginner: 'Anfaenger',
      intermediate: 'Mittel',
      advanced: 'Fortgeschritten',
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
        cardio: 'Cardio',
        recovery: 'Recovery',
        unknown: 'Unbekannter Typ'
      },
      filters: {
        all: 'Alle',
        strength: 'Kraft',
        cardio: 'Cardio',
        recovery: 'Recovery'
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
      name: 'Planname',
      namePlaceholder: 'z.B. Push Workout',
      type: 'Typ',
      duration: 'Dauer (Min)',
      icon: 'Plan-Icon',
      notes: 'Notizen',
      exercises: 'Uebungen',
      addExercise: 'Uebung hinzufuegen',
      deleteConfirm: 'Plan wirklich loeschen?',
      deleteSuccess: 'Plan geloescht.',
      deleteError: 'Fehler beim Loeschen des Plans.'
    },
    exercise: {
      title: 'Uebung',
      name: 'Uebungsname',
      namePlaceholder: 'z.B. Klimmzuege',
      muscleGroups: 'Muskelgruppen',
      equipment: 'Equipment',
      discipline: 'Disziplin',
      visual: 'Uebungs-Icon',
      selectIcon: 'Icon auswaehlen',
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
      }
    },
    workout: {
      quick: {
        title: 'Workout Schnell-Eintrag',
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
      }
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
      primary: {
        title: 'Workout',
        subtitleActive: 'Ein Workout ist aktiv.',
        subtitleInactive: 'Waehle Kraft, Cardio oder Recovery.',
        helper: 'Starte oder setze dein aktuelles Training fort.',
        start: 'Workout starten',
        resume: 'Workout fortsetzen'
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
        empty: 'Noch keine Sessions'
      }
    },
    progress: {
      tabs: {
        overview: 'Uebersicht',
        strength: 'Kraft',
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
      }
    },
    errors: {
      startUnavailable: 'Start-Auswahl ist nicht verfuegbar.',
      workoutNotFound: 'Workout nicht gefunden',
      sessionNotFound: 'Workout nicht gefunden',
      deleteFailed: 'Fehler beim Loeschen',
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
