# Kandidaten für ICU-Plurale

Automatisch erkannt an numerischen Platzhaltern. Das Skript wandelt sie
NICHT selbst um — welcher Fall wirklich einen Plural braucht, entscheidet
die Sprache, nicht der Datentyp.

Zielform:
```
"{count, plural, =0{Keine Übungen} one{{count} Übung} other{{count} Übungen}}"
```

18 Kandidaten:

- commonSecondsShort  (common.secondsShort)
    DE: {n}s
    EN: {n}s

- dashboardHybridBalanceSubtitle  (dashboard.hybridBalance.subtitle)
    DE: Letzte {days} Tage
    EN: Last {days} days

- formatDurationHours  (format.duration.hours)
    DE: {hours}h
    EN: {hours}h

- formatDurationHoursMinutes  (format.duration.hoursMinutes)
    DE: {hours}h {minutes}m
    EN: {hours}h {minutes}m

- formatDurationMinutes  (format.duration.minutes)
    DE: {minutes} min
    EN: {minutes} min

- formatPaceValue  (format.pace.value)
    DE: {min}:{sec} min/km
    EN: {min}:{sec} min/km

- workoutExerciseProgress  (workout.exercise.progress)
    DE: {completed} / {total} Übungen
    EN: {completed} / {total} exercises

- workoutRelativeTimeDaysAgo  (workout.relativeTime.daysAgo)
    DE: vor {n} Tagen
    EN: {n} days ago

- workoutRelativeTimeWeeksAgo  (workout.relativeTime.weeksAgo)
    DE: vor {n} Wochen
    EN: {n} weeks ago

- workoutScreenExerciseOf  (workout.screen.exerciseOf)
    DE: Übung {current} von {total}
    EN: Exercise {current} of {total}

- workoutScreenExerciseProgress  (workout.screen.exerciseProgress)
    DE: {completed} / {total} Übungen
    EN: {completed} / {total} exercises

- workoutScreenExercisesButton  (workout.screen.exercisesButton)
    DE: Übungen ({completed}/{total})
    EN: Exercises ({completed}/{total})

- workoutSetLoggerRest  (workout.setLogger.rest)
    DE: {seconds}s Pause
    EN: {seconds}s rest

- workoutSetLoggerStepModeChanged  (workout.setLogger.stepModeChanged)
    DE: Schrittweite: {step} {unit}
    EN: Step size: {step} {unit}

- workoutSetLoggerTargetReps  (workout.setLogger.targetReps)
    DE: {reps} Wdh
    EN: {reps} reps

- workoutSetLoggerTargetSets  (workout.setLogger.targetSets)
    DE: {sets} Sätze
    EN: {sets} sets

- workoutSetLoggerTitle  (workout.setLogger.title)
    DE: Satz {number} loggen
    EN: Log set {number}

- workoutTargetHold  (workout.targetHold)
    DE: Ziel: {seconds} halten
    EN: Goal: hold {seconds}
