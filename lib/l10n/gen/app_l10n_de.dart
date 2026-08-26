// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppL10nDe extends AppL10n {
  AppL10nDe([String locale = 'de']) : super(locale);

  @override
  String get commonActivity => 'Aktivität';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonAddSession => 'Session hinzufügen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonBodyweight => 'Bodyweight';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonCardio => 'Cardio';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonDays => 'Tage';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonDistance => 'Distanz';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonDuration => 'Dauer';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonEditSession => 'Session bearbeiten';

  @override
  String get commonLoading => 'Lade Daten...';

  @override
  String get commonMinutes => 'Minuten';

  @override
  String get commonNext => 'Weiter';

  @override
  String get commonNotAvailable => '-';

  @override
  String get commonNotes => 'Notizen';

  @override
  String get commonOptional => 'optional';

  @override
  String get commonPace => 'Pace';

  @override
  String get commonRecovery => 'Recovery';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonSave => 'Speichern';

  @override
  String commonSecondsShort(int n) {
    return '${n}s';
  }

  @override
  String get commonSelect => 'Auswahl';

  @override
  String get commonSession => 'Session';

  @override
  String get commonSessions => 'Sessions';

  @override
  String get commonStart => 'Starten';

  @override
  String get commonStartAgain => 'Erneut starten';

  @override
  String get commonStrength => 'Kraft';

  @override
  String get commonTime => 'Zeit';

  @override
  String get commonView => 'Ansehen';

  @override
  String get commonViewDetails => 'Details ansehen';

  @override
  String get commonWeeks => 'Wochen';

  @override
  String get commonWorkout => 'Workout';

  @override
  String get dashboardActivityCalendarDurationUnit => 'Bewegungsstunden';

  @override
  String get dashboardActivityCalendarEmptyState =>
      'Noch keine Sessions in diesem Zeitraum';

  @override
  String get dashboardActivityCalendarMore => 'Mehr';

  @override
  String get dashboardActivityCalendarThisMonth => 'Diesen Monat';

  @override
  String get dashboardAddWorkoutTitle => 'Workout hinzufügen';

  @override
  String get dashboardAllSessionsEarlier => 'Früher';

  @override
  String get dashboardAllSessionsEmpty => 'Noch keine Sessions vorhanden';

  @override
  String get dashboardAllSessionsTitle => 'Alle Sessions';

  @override
  String get dashboardAllSessionsToday => 'Heute';

  @override
  String get dashboardAllSessionsYesterday => 'Gestern';

  @override
  String get dashboardCalendarAddTraining => 'Training hinzufügen';

  @override
  String get dashboardCalendarNextMonth => 'Nächster Monat';

  @override
  String get dashboardCalendarPrevMonth => 'Vorheriger Monat';

  @override
  String get dashboardCalendarTabActivity => 'Aktivität';

  @override
  String get dashboardCalendarTabPlan => 'Planen';

  @override
  String dashboardHybridBalanceAria(String strength, String cardio) {
    return 'Kraft $strength Prozent, Cardio $cardio Prozent';
  }

  @override
  String get dashboardHybridBalanceDescription =>
      'Zeigt die Zeitverteilung zwischen Kraft und Cardio.';

  @override
  String dashboardHybridBalanceSubtitle(int days) {
    return 'Letzte $days Tage';
  }

  @override
  String get dashboardHybridBalanceTitle => 'Hybrid Balance';

  @override
  String get dashboardLogWorkoutLog => 'Workout loggen';

  @override
  String get dashboardLogWorkoutLogDesc =>
      'Erfasse ein abgeschlossenes Training';

  @override
  String get dashboardLogWorkoutPlan => 'Workout planen';

  @override
  String get dashboardLogWorkoutPlanDesc => 'Plane ein Training im Kalender';

  @override
  String get dashboardLogWorkoutStart => 'Workout starten';

  @override
  String get dashboardLogWorkoutStartDesc =>
      'Starte ein Training aus deinen Plänen';

  @override
  String get dashboardLogWorkoutSubtitle =>
      'Logge, starte oder plane ein Workout';

  @override
  String get dashboardLogWorkoutTitle => 'Workout erfassen';

  @override
  String get dashboardPlanCalendarTitle => 'Planungskalender';

  @override
  String get dashboardPrimaryHelper =>
      'Starte oder setze dein aktuelles Training fort.';

  @override
  String get dashboardPrimaryResume => 'Workout fortsetzen';

  @override
  String get dashboardPrimaryStart => 'Workout starten';

  @override
  String get dashboardPrimarySubtitleActive => 'Ein Workout ist aktiv.';

  @override
  String get dashboardPrimarySubtitleInactive =>
      'Wähle Kraft, Cardio oder Recovery.';

  @override
  String get dashboardPrimaryTitle => 'Workout';

  @override
  String get dashboardQuickStatsMovementMinutes => 'Bewegungsmin.';

  @override
  String get dashboardQuickStatsSessions => 'Sessions';

  @override
  String get dashboardQuickStatsThisWeek => 'Diese Woche';

  @override
  String get dashboardReadinessLevelModerate => 'MODERATE LAST';

  @override
  String get dashboardReadinessLevelPeak => 'PEAK READINESS';

  @override
  String get dashboardReadinessLevelRecovery => 'FOKUS: REGENERATION';

  @override
  String get dashboardReadinessLevelSolid => 'SOLIDE FORM';

  @override
  String get dashboardReadinessTagModerate =>
      'Regeneration: Mittel • Volumen leicht reduzieren';

  @override
  String get dashboardReadinessTagPeak =>
      'Regeneration: Optimal • Bereit für Hyrox / Max Load';

  @override
  String get dashboardReadinessTagRecovery =>
      'Regeneration: Niedrig • Heute aktiv erholen';

  @override
  String get dashboardReadinessTagSolid =>
      'Regeneration: Gut • Normale Trainingslast fahren';

  @override
  String get dashboardRecentDescription =>
      'Die letzten Sessions in chronologischer Reihenfolge.';

  @override
  String get dashboardRecentEmpty => 'Noch keine Sessions';

  @override
  String get dashboardRecentTitle => 'Letzte Sessions';

  @override
  String get dashboardRecentViewAll => 'Alle anzeigen';

  @override
  String get dashboardScheduledTitle => 'Geplant für heute';

  @override
  String get dashboardStartWorkoutNewWorkout => 'Neues Training';

  @override
  String get dashboardStartWorkoutNewWorkoutDesc =>
      'Starte ein leeres Workout und füge Übungen hinzu';

  @override
  String get dashboardStartWorkoutSelectPlan => 'Plan auswählen';

  @override
  String get dashboardStartWorkoutSelectPlanDesc =>
      'Starte ein Training aus deinen Plänen';

  @override
  String get dashboardToday => 'Heute';

  @override
  String get dashboardTrainingTypesBodyweight => 'Bodyweight';

  @override
  String get dashboardTrainingTypesCardio => 'Cardio';

  @override
  String get dashboardTrainingTypesRecovery => 'Recovery';

  @override
  String get dashboardTrainingTypesStrength => 'Krafttraining';

  @override
  String get errorsDeleteFailed => 'Fehler beim Löschen';

  @override
  String get errorsExerciseNameRequired =>
      'Bitte gib einen Namen für die Übung ein!';

  @override
  String get errorsExercisesLoading =>
      'Übungen werden noch geladen. Bitte versuche es gleich erneut.';

  @override
  String get errorsLoadFailed =>
      'Laden fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get errorsMuscleGroupsRequired =>
      'Bitte wähle mindestens eine Muskelgruppe!';

  @override
  String get errorsPlanExercisesRequired =>
      'Bitte füge mindestens eine Übung hinzu!';

  @override
  String get errorsPlanNameRequired =>
      'Bitte gib einen Namen für den Plan ein!';

  @override
  String get errorsPlanNotFound => 'Plan nicht gefunden';

  @override
  String get errorsSaveFailed => 'Fehler beim Speichern.';

  @override
  String get errorsSessionNotFound => 'Session nicht gefunden';

  @override
  String get errorsStartUnavailable => 'Start-Auswahl ist nicht verfügbar.';

  @override
  String get errorsWorkoutNotFound => 'Workout nicht gefunden';

  @override
  String get errorsWorkoutStartFailed => 'Fehler beim Starten des Workouts';

  @override
  String formatDistanceKm(num distance) {
    final intl.NumberFormat distanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String distanceString = distanceNumberFormat.format(distance);

    return '$distanceString km';
  }

  @override
  String formatDurationHours(int hours) {
    return '${hours}h';
  }

  @override
  String formatDurationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String formatDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get formatDurationZero => '0 min';

  @override
  String get formatPaceNa => '-';

  @override
  String formatPaceValue(int min, int sec) {
    return '$min:$sec min/km';
  }

  @override
  String get navCalendar => 'Kalender';

  @override
  String get navDashboard => 'Heute';

  @override
  String get navExercises => 'Übungen';

  @override
  String get navPlans => 'Pläne';

  @override
  String get navProfile => 'Profil';

  @override
  String get navProgress => 'Fortschritt';

  @override
  String get navTraining => 'Training';

  @override
  String get workoutA11yEnd => 'Workout beenden';

  @override
  String workoutA11yFormGuide(String exercise) {
    return 'Form-Video zu $exercise öffnen';
  }

  @override
  String get workoutA11yLoading => 'Workout wird geladen';

  @override
  String get workoutA11yNextExercise => 'Nächste Übung';

  @override
  String get workoutA11yNotes => 'Session-Notizen öffnen';

  @override
  String get workoutA11yPause => 'Training pausieren';

  @override
  String get workoutA11yPrevExercise => 'Vorherige Übung';

  @override
  String workoutA11yRepsField(int n) {
    return 'Wiederholungen, Satz $n';
  }

  @override
  String get workoutA11yRestExtend => 'Pause um 30 Sekunden verlängern';

  @override
  String workoutA11yRestRemaining(String time) {
    return 'Pause: $time verbleibend';
  }

  @override
  String get workoutA11yRestShorten => 'Pause um 15 Sekunden verkürzen';

  @override
  String get workoutA11yRestSkip => 'Pause überspringen';

  @override
  String get workoutA11yResume => 'Training fortsetzen';

  @override
  String workoutA11ySetComplete(int n) {
    return 'Satz $n abschließen';
  }

  @override
  String workoutA11ySetType(String type) {
    return 'Satztyp: $type. Tippen zum Ändern';
  }

  @override
  String workoutA11ySetUnlock(int n) {
    return 'Satz $n entsperren';
  }

  @override
  String workoutA11yWeightField(int n) {
    return 'Gewicht in Kilogramm, Satz $n';
  }

  @override
  String workoutBannerActive(String name) {
    return 'Aktives Workout: $name';
  }

  @override
  String get workoutBannerCancel => 'Abbrechen';

  @override
  String get workoutBannerCancelConfirm =>
      'Aktives Workout wirklich abbrechen? Alle Fortschritte gehen verloren.';

  @override
  String get workoutBannerCancelWorkoutConfirm =>
      'Workout wirklich abbrechen? Alle Fortschritte gehen verloren.';

  @override
  String get workoutBannerResume => 'Fortsetzen';

  @override
  String get workoutCardioDistance => 'Distanz (km)';

  @override
  String get workoutCardioDuration => 'Dauer (Min.)';

  @override
  String get workoutCardioLog => 'Cardio loggen';

  @override
  String get workoutCardioPace => 'Pace';

  @override
  String get workoutCardioRpe => 'Belastung (1–5)';

  @override
  String get workoutCopyLastSet => 'Letzten Satz kopieren';

  @override
  String get workoutEditDateError =>
      'Ungültiges Datumsformat. Bitte verwende YYYY-MM-DD';

  @override
  String get workoutEditDatePrompt => 'Neues Datum (YYYY-MM-DD):';

  @override
  String get workoutExerciseCurrent => 'Aktuelle Übung';

  @override
  String get workoutExerciseFinish => 'Workout beenden';

  @override
  String get workoutExerciseNext => 'Nächste Übung';

  @override
  String workoutExerciseProgress(String completed, int total) {
    return '$completed / $total Übungen';
  }

  @override
  String get workoutFeedbackEnterDuration => 'Bitte Dauer eingeben';

  @override
  String get workoutFeedbackExerciseComplete => 'Übung abgeschlossen!';

  @override
  String get workoutFeedbackRestartError =>
      'Fehler beim Neustarten des Workouts';

  @override
  String get workoutFeedbackSaveError => 'Fehler beim Speichern des Workouts';

  @override
  String get workoutFeedbackSaved => 'Workout gespeichert!';

  @override
  String get workoutHold => 'Halten';

  @override
  String get workoutHoldDurationLabel => 'Haltedauer (Sek.)';

  @override
  String get workoutLastPerformance => 'Letztes Mal';

  @override
  String get workoutLoggingAddExercise => 'Übung hinzufügen';

  @override
  String get workoutLoggingExerciseAlreadyAdded => 'Übung bereits hinzugefügt';

  @override
  String get workoutLoggingExercisesOptional => 'Übungen (optional)';

  @override
  String get workoutLoggingReps => 'Wiederholungen pro Satz';

  @override
  String get workoutLoggingSet => 'Satz';

  @override
  String get workoutLoggingSets => 'Sätze';

  @override
  String get workoutLoggingTotalReps => 'Wdh.';

  @override
  String get workoutNoPreviousData => 'Keine vorherigen Daten';

  @override
  String get workoutPostWorkoutComparisonTitle => 'Vergleich zum letzten Mal';

  @override
  String get workoutPostWorkoutEditDuration => 'Trainingszeit anpassen';

  @override
  String get workoutPostWorkoutExercises => 'Übungen';

  @override
  String get workoutPostWorkoutFallbackName => 'Training';

  @override
  String get workoutPostWorkoutMinutes => 'Minuten';

  @override
  String get workoutPostWorkoutSets => 'Sets';

  @override
  String get workoutPostWorkoutTime => 'Zeit';

  @override
  String get workoutPostWorkoutTitle => 'Workout abgeschlossen!';

  @override
  String get workoutPostWorkoutToProgress => 'Zum Fortschritt';

  @override
  String get workoutPostWorkoutVolume => 'Volumen';

  @override
  String get workoutQuickBodyweight => 'Bodyweight';

  @override
  String get workoutQuickBodyweightDesc => 'Training mit Eigengewicht';

  @override
  String get workoutQuickDate => 'Datum *';

  @override
  String get workoutQuickDateRequired => 'Bitte wähle ein Datum';

  @override
  String get workoutQuickDifficulty => 'Schwierigkeit';

  @override
  String get workoutQuickDuration => 'Dauer (Minuten)';

  @override
  String get workoutQuickDurationRequired => 'Bitte gib eine gültige Dauer ein';

  @override
  String get workoutQuickName => 'Workout Name';

  @override
  String get workoutQuickNameRequired => 'Bitte gib einen Workout Namen ein';

  @override
  String get workoutQuickSaveError => 'Fehler beim Speichern des Workouts';

  @override
  String get workoutQuickTitle => 'Workout Schnell-Eintrag';

  @override
  String get workoutQuickType => 'Typ';

  @override
  String get workoutQuickWeights => 'Gewichte';

  @override
  String get workoutQuickWeightsDesc => 'Gym / Hanteln';

  @override
  String get workoutRecoveryDuration => 'Dauer (Min.)';

  @override
  String get workoutRecoveryLog => 'Recovery loggen';

  @override
  String workoutRelativeTimeDaysAgo(int n) {
    return 'vor $n Tagen';
  }

  @override
  String get workoutRelativeTimeOneWeekAgo => 'vor 1 Woche';

  @override
  String get workoutRelativeTimeToday => 'heute';

  @override
  String workoutRelativeTimeWeeksAgo(int n) {
    return 'vor $n Wochen';
  }

  @override
  String get workoutRelativeTimeYesterday => 'gestern';

  @override
  String get workoutRunnerAddSet => '+ SATZ HINZUFÜGEN';

  @override
  String get workoutRunnerBack => 'Zurück';

  @override
  String get workoutRunnerFormGuide => 'FORM GUIDE';

  @override
  String get workoutRunnerNotAvailable => 'Workout nicht verfügbar';

  @override
  String get workoutRunnerNotesDone => 'FERTIG';

  @override
  String get workoutRunnerNotesHint => 'Wie fühlt sich die Session an?';

  @override
  String get workoutRunnerNotesTitle => 'SESSION-NOTIZEN';

  @override
  String get workoutRunnerRestLabel => 'PAUSE';

  @override
  String get workoutRunnerRestMinus => '−15s';

  @override
  String get workoutRunnerRestPlus => '+30s';

  @override
  String get workoutRunnerRestSkip => 'SKIP →';

  @override
  String workoutRunnerRunning(String time) {
    return 'SESSION LÄUFT · $time';
  }

  @override
  String get workoutRunnerSaved => 'Session gespeichert';

  @override
  String get workoutRunnerSavedDone => 'FERTIG';

  @override
  String get workoutRunnerSavedFailed => 'Speichern fehlgeschlagen';

  @override
  String get workoutRunnerSessionLabel => 'SESSION';

  @override
  String workoutRunnerSetsCompleted(int done, int total) {
    return '$done VON $total SÄTZEN ABGESCHLOSSEN';
  }

  @override
  String workoutRunnerSummary(int sets, String time, String volume) {
    return '$sets Sätze · $time · $volume kg Volumen';
  }

  @override
  String get workoutRunnerTableDone => 'OK';

  @override
  String get workoutRunnerTableLast => 'LETZTES MAL';

  @override
  String get workoutRunnerTableReps => 'WDH';

  @override
  String get workoutRunnerTableSet => 'SATZ';

  @override
  String get workoutRunnerTableWeight => 'KG';

  @override
  String get workoutScreenAddExercise => 'Übung hinzufügen';

  @override
  String get workoutScreenAddSet => 'Satz hinzufügen';

  @override
  String get workoutScreenBodyweight => 'Bodyweight';

  @override
  String get workoutScreenCancelWorkout => 'Abbrechen';

  @override
  String get workoutScreenCardio => 'Cardio';

  @override
  String get workoutScreenCurrentExercise => 'Aktuelle Übung';

  @override
  String get workoutScreenDiscardConfirm =>
      'Workout wirklich verwerfen? Alle Fortschritte gehen verloren.';

  @override
  String get workoutScreenDiscardConfirmTitle => 'Workout verwerfen?';

  @override
  String get workoutScreenDiscardWorkout => 'Workout verwerfen';

  @override
  String get workoutScreenEmptyHint =>
      'Füge Übungen hinzu, um dein Workout zu starten';

  @override
  String get workoutScreenEndWorkout => 'Workout beenden';

  @override
  String get workoutScreenEndWorkoutAction => 'Beenden';

  @override
  String get workoutScreenEndWorkoutConfirm => 'Workout wirklich beenden?';

  @override
  String get workoutScreenEndWorkoutConfirmText =>
      'Alle bisherigen Sätze werden gespeichert.';

  @override
  String workoutScreenExerciseOf(int current, int total) {
    return 'Übung $current von $total';
  }

  @override
  String workoutScreenExerciseProgress(String completed, int total) {
    return '$completed / $total Übungen';
  }

  @override
  String workoutScreenExercisesButton(String completed, int total) {
    return 'Übungen ($completed/$total)';
  }

  @override
  String get workoutScreenExercisesSheetTitle => 'Übungen';

  @override
  String get workoutScreenFinishWorkout => 'Workout abschließen';

  @override
  String get workoutScreenFreeWorkout => 'Freies Workout';

  @override
  String get workoutScreenGoal => 'Ziel';

  @override
  String get workoutScreenLogWorkout => 'Workout erfassen';

  @override
  String get workoutScreenMenu => 'Menü';

  @override
  String get workoutScreenNextExercise => 'Nächste Übung';

  @override
  String get workoutScreenNoActiveWorkout => 'Kein aktives Workout';

  @override
  String get workoutScreenNoActiveWorkoutText =>
      'Starte ein Training aus dem Kalender oder einem Plan.';

  @override
  String get workoutScreenNoExercisesFound => 'Keine Übungen gefunden';

  @override
  String get workoutScreenRecovery => 'Recovery';

  @override
  String get workoutScreenRest => 'Pause';

  @override
  String get workoutScreenRestTimer => 'Pause';

  @override
  String get workoutScreenSaveWorkout => 'Workout speichern';

  @override
  String get workoutScreenSearchExercise => 'Übung suchen...';

  @override
  String get workoutScreenSwitchToExercise => 'Zu dieser Übung wechseln';

  @override
  String get workoutScreenTimerAdd => '+10s';

  @override
  String get workoutScreenTimerDone => 'Pause vorbei!';

  @override
  String get workoutScreenTimerPause => 'Pausieren';

  @override
  String get workoutScreenTimerResume => 'Fortsetzen';

  @override
  String get workoutScreenTimerSkip => 'Ueberspringen';

  @override
  String get workoutScreenTimerStart => 'Timer starten';

  @override
  String get workoutScreenTimerSub => '-10s';

  @override
  String get workoutScreenToPlans => 'Zu den Plänen';

  @override
  String get workoutScreenWeighted => 'Gewichte';

  @override
  String get workoutSetLoggerAddSet => 'Satz hinzufügen';

  @override
  String get workoutSetLoggerAtLeastOneSet =>
      'Bitte logge mindestens einen Satz bevor du weitergehst';

  @override
  String get workoutSetLoggerCompletedSets => 'Abgeschlossene Sätze';

  @override
  String get workoutSetLoggerDecreaseWeight => 'Gewicht verringern';

  @override
  String get workoutSetLoggerDeleteSet => 'Satz löschen';

  @override
  String get workoutSetLoggerDeleteSetConfirm =>
      'Diesen Satz wirklich löschen?';

  @override
  String get workoutSetLoggerDuplicateLast => 'Letzten Satz kopieren';

  @override
  String get workoutSetLoggerEnterHold => 'Bitte gib die Haltedauer ein';

  @override
  String get workoutSetLoggerEnterReps =>
      'Bitte gib die Anzahl der Wiederholungen ein';

  @override
  String get workoutSetLoggerIncreaseWeight => 'Gewicht erhöhen';

  @override
  String get workoutSetLoggerLogSet => 'Satz loggen';

  @override
  String get workoutSetLoggerNoSets => 'Noch keine Sätze geloggt';

  @override
  String get workoutSetLoggerReps => 'Wiederholungen';

  @override
  String workoutSetLoggerRest(int seconds) {
    return '${seconds}s Pause';
  }

  @override
  String get workoutSetLoggerSet => 'Satz';

  @override
  String workoutSetLoggerStepModeChanged(int step, String unit) {
    return 'Schrittweite: $step $unit';
  }

  @override
  String get workoutSetLoggerTarget => 'Ziel';

  @override
  String workoutSetLoggerTargetReps(int reps) {
    return '$reps Wdh';
  }

  @override
  String workoutSetLoggerTargetSets(int sets) {
    return '$sets Sätze';
  }

  @override
  String workoutSetLoggerTitle(int number) {
    return 'Satz $number loggen';
  }

  @override
  String get workoutSetLoggerWeight => 'Gewicht';

  @override
  String get workoutSetLoggerWeightUnit => 'kg';

  @override
  String get workoutSetTypeDropset => 'Dropsatz';

  @override
  String get workoutSetTypeFailure => 'Satz bis zum Muskelversagen';

  @override
  String get workoutSetTypeNormal => 'Normaler Satz';

  @override
  String get workoutSetTypeShortDropset => 'D';

  @override
  String get workoutSetTypeShortFailure => 'F';

  @override
  String get workoutSetTypeShortNormal => 'N';

  @override
  String get workoutSetTypeShortWarmup => 'W';

  @override
  String get workoutSetTypeWarmup => 'Aufwärmsatz';

  @override
  String workoutTargetHold(int seconds) {
    return 'Ziel: $seconds halten';
  }
}
