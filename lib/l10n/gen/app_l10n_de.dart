// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppL10nDe extends AppL10n {
  AppL10nDe([String locale = 'de']) : super(locale);

  @override
  String get analysisChartLabel => 'Form 0–100';

  @override
  String get analysisCompConsistency => 'Konstanz';

  @override
  String get analysisCompFitness => 'Fitness ggü. Höchststand';

  @override
  String get analysisCompLoad => 'Lastentwicklung';

  @override
  String get analysisCompPenalty => 'Abzug Untätigkeit';

  @override
  String get analysisCompRecency => 'Aktualität';

  @override
  String get analysisCompToday => 'Tageszuschlag';

  @override
  String analysisCompValue(int v, int max) {
    return '$v / $max';
  }

  @override
  String analysisErrorBody(int n) {
    return 'Deine $n Einheiten sind vollständig da — nur die Auswertung fehlt.';
  }

  @override
  String get analysisErrorRetry => 'Neu berechnen';

  @override
  String get analysisErrorTitle => 'Form nicht berechenbar';

  @override
  String get analysisErrorToList => 'Zur Liste';

  @override
  String analysisHintRecency(int n) {
    return 'Was fehlt, ist Aktualität — eine Einheit heute bringt sofort $n Punkte.';
  }

  @override
  String get analysisLegendWith => 'mit Training';

  @override
  String get analysisLegendWithout => 'ohne Training';

  @override
  String analysisThinBody(int n, int d) {
    return 'Ein Trend braucht $n Einheiten und $d Tage Historie.';
  }

  @override
  String get analysisThinHave => 'Was es schon gibt';

  @override
  String analysisThinProgress(int cur, int req) {
    return '$cur / $req';
  }

  @override
  String get analysisThinTitle => 'Noch zu wenig für einen Trend';

  @override
  String get analysisTitle => 'Auswertung';

  @override
  String get analysisToday => 'Form heute';

  @override
  String get authBetaBadge => 'GESCHLOSSENE BETA';

  @override
  String authErrorCode(String code) {
    return 'CODE $code';
  }

  @override
  String get authFailedBody => 'Versuch es gleich noch einmal.';

  @override
  String get authFailedTitle => 'Das hat nicht geklappt';

  @override
  String get authGoogle => 'Mit Google anmelden';

  @override
  String get authLegal =>
      'Mit der Anmeldung akzeptierst du Nutzungsbedingungen und Datenschutzerklärung.';

  @override
  String get authNetworkBody => 'Anmeldung braucht Internet.';

  @override
  String get authNetworkTitle => 'Keine Verbindung';

  @override
  String get authSignOut => 'Abmelden';

  @override
  String get authSigningIn => 'Anmeldung läuft …';

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
  String get commonPercentSign => '%';

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
  String dashboardAvatarA11y(String name) {
    return 'Profil von $name';
  }

  @override
  String dashboardBlocks(int n) {
    return '$n Blocks';
  }

  @override
  String get dashboardBrand => 'ATEM HYBRID';

  @override
  String get dashboardBrandA11y => 'System aktiv';

  @override
  String dashboardBreathwork(int n) {
    return '$n Min Breathwork';
  }

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
  String get dashboardChartA11y =>
      'Wochenverlauf: Load, Strain, Recovery, Montag bis Sonntag';

  @override
  String get dashboardChartSection => 'PERFORMANCE · 7 TAGE';

  @override
  String dashboardChartToday(String day, int load) {
    return '$day · LOAD $load';
  }

  @override
  String dashboardDurationMinutes(int n) {
    return '$n Min';
  }

  @override
  String dashboardGreetingDay(String name) {
    return 'Guten Tag, $name';
  }

  @override
  String dashboardGreetingEvening(String name) {
    return 'Guten Abend, $name';
  }

  @override
  String dashboardGreetingMorning(String name) {
    return 'Guten Morgen, $name';
  }

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
  String get dashboardLive => 'LIVE';

  @override
  String dashboardLiveHrv(int hrv, int n) {
    return 'Live HRV $hrv ms · $n Min Breathwork';
  }

  @override
  String get dashboardLoadingA11y => 'Dashboard wird geladen';

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
  String dashboardNavA11y(String name, int n, int total) {
    return '$name, Tab $n von $total';
  }

  @override
  String get dashboardNavAnalytics => 'ANALYSE';

  @override
  String get dashboardNavHome => 'HOME';

  @override
  String get dashboardNavProfile => 'PROFIL';

  @override
  String get dashboardNavRecovery => 'RECOVERY';

  @override
  String get dashboardNavWorkouts => 'WORKOUTS';

  @override
  String get dashboardNoDataYet => 'Noch keine Daten';

  @override
  String get dashboardNotAvailable => 'Daten nicht verfügbar';

  @override
  String dashboardNotificationsA11y(int n) {
    return '$n ungelesene Benachrichtigungen';
  }

  @override
  String dashboardPhaseA11y(int week, int total, String phase) {
    return 'Woche $week von $total, Phase $phase';
  }

  @override
  String dashboardPhaseWeek(int week, int total, String phase) {
    return 'Woche $week von $total · $phase';
  }

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
  String dashboardProteinA11y(int value, int goal) {
    return 'Ernährung, Protein $value von $goal Gramm';
  }

  @override
  String dashboardProteinGoal(int goal) {
    return ' / ${goal}g Ziel';
  }

  @override
  String dashboardProteinOf(int value) {
    return 'Protein ${value}g';
  }

  @override
  String get dashboardQuickNutrition => 'Nutrition & Fuel';

  @override
  String get dashboardQuickPeriod => 'Periodisierung';

  @override
  String get dashboardQuickRecovery => 'Recovery Scan';

  @override
  String dashboardQuickSets(String headline, int sets) {
    return '$headline · $sets Sets';
  }

  @override
  String dashboardQuickSetsPlain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze zuletzt',
      one: '1 Satz zuletzt',
      zero: 'Keine Sätze erfasst',
    );
    return '$_temp0';
  }

  @override
  String dashboardQuickSetsPlan(String plan, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$plan · $_temp0';
  }

  @override
  String get dashboardQuickStatsMovementMinutes => 'Bewegungsmin.';

  @override
  String get dashboardQuickStatsSessions => 'Sessions';

  @override
  String get dashboardQuickStatsThisWeek => 'Diese Woche';

  @override
  String get dashboardQuickWorkout => 'Workout Log';

  @override
  String dashboardReadinessA11y(int percent, String status) {
    return 'Readiness $percent Prozent, $status';
  }

  @override
  String get dashboardReadinessLevelBuilding => 'AUFBAU';

  @override
  String get dashboardReadinessLevelFatigued => 'ERMÜDET';

  @override
  String get dashboardReadinessLevelFormLoss => 'FORMVERLUST';

  @override
  String get dashboardReadinessLevelModerate => 'MODERATE LAST';

  @override
  String get dashboardReadinessLevelOverreaching => 'ÜBERREIZT';

  @override
  String get dashboardReadinessLevelPeak => 'PEAK READINESS';

  @override
  String get dashboardReadinessLevelRecovery => 'FOKUS: REGENERATION';

  @override
  String get dashboardReadinessLevelSolid => 'SOLIDE FORM';

  @override
  String get dashboardReadinessSection => 'ATEM READINESS';

  @override
  String get dashboardReadinessTagFatigued =>
      'Regeneration: Niedrig • Volumen deutlich reduzieren';

  @override
  String get dashboardReadinessTagFormLoss =>
      'Regeneration: Ausgeruht • Wieder Volumen aufbauen';

  @override
  String get dashboardReadinessTagModerate =>
      'Regeneration: Mittel • Volumen leicht reduzieren';

  @override
  String get dashboardReadinessTagOverreaching =>
      'Regeneration: Kritisch • Heute nicht trainieren';

  @override
  String get dashboardReadinessTagPeak =>
      'Regeneration: Optimal • Bereit für maximale Last';

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
  String get dashboardSeriesLoad => 'LOAD';

  @override
  String get dashboardSeriesRecovery => 'RECOVERY';

  @override
  String get dashboardSeriesStrain => 'STRAIN';

  @override
  String get dashboardSessionNone => 'Für heute ist nichts geplant';

  @override
  String get dashboardSessionNoneHint =>
      'Plane eine Einheit oder logge ein freies Workout.';

  @override
  String dashboardSessionRunning(String time) {
    return 'SESSION LÄUFT · $time';
  }

  @override
  String dashboardSessionRunningA11y(String time) {
    return 'Session läuft, $time, tippen zum Stoppen';
  }

  @override
  String get dashboardSessionSection => 'HEUTIGE SESSION';

  @override
  String get dashboardSessionStart => 'SESSION STARTEN';

  @override
  String get dashboardSessionStartA11y => 'Session starten';

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
  String get dashboardStatHrv => 'HRV';

  @override
  String get dashboardStatRhr => 'RUHE-HF';

  @override
  String get dashboardStatSleep => 'SCHLAF';

  @override
  String get dashboardSubtitle => 'Optimales System-Level erreicht';

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
  String get dashboardWeekdays => 'MO,DI,MI,DO,FR,SA,SO';

  @override
  String get detailAcwrLabel => 'Belastung an diesem Tag';

  @override
  String detailAcwrZone(String v, String zone) {
    return 'ACWR $v · $zone';
  }

  @override
  String get detailLoad => 'Last';

  @override
  String get detailPace => 'Pace /km';

  @override
  String get detailRecoveryBody =>
      'Recovery hält die Kette, treibt aber die Lastentwicklung nicht.';

  @override
  String get detailRecoveryTitle => 'Zählt für die Konstanz';

  @override
  String detailSetsCount(int e, int s) {
    return '$e Übungen · $s Sätze';
  }

  @override
  String get detailSetsMissingBody =>
      'Diese Einheit wurde als Dauer erfasst. Last und Konstanz zählen trotzdem, Volumen bleibt leer.';

  @override
  String get detailSetsMissingTitle => 'Keine Sätze aufgezeichnet';

  @override
  String get detailVolume => 'Volumen';

  @override
  String durationApproxMinutes(int n) {
    return '~$n min';
  }

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

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
  String exerciseCountShort(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Übungen',
      one: '1 Übung',
    );
    return '$_temp0';
  }

  @override
  String get exerciseCues => 'Cues';

  @override
  String exerciseDifficultyA11y(int n) {
    return 'Schwierigkeit $n von 5';
  }

  @override
  String get exerciseInstructions => 'Anleitung';

  @override
  String get exerciseMistakes => 'Häufige Fehler';

  @override
  String get exerciseSparseBody => 'Diese Übung hast du selbst angelegt.';

  @override
  String get exerciseSparseTitle => 'Keine Anleitung hinterlegt';

  @override
  String exercisesCount(int n, int k, int e) {
    return '$n Übungen · $k kuratiert · $e eigene';
  }

  @override
  String exercisesEmptyBody(String q) {
    return 'Keine Übung passt zu „$q“ — auch nicht auf Englisch.';
  }

  @override
  String get exercisesEmptyTitle => 'Nichts gefunden';

  @override
  String get exercisesFilterAll => 'Alle';

  @override
  String get exercisesFilterReset => 'Zurücksetzen';

  @override
  String exercisesFilterResult(int n, String filter) {
    return '$n Übungen · $filter';
  }

  @override
  String get exercisesOwnTag => 'Eigen';

  @override
  String get exercisesSearchHint => 'Übung suchen …';

  @override
  String get exercisesTitle => 'Übungen';

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
  String get gateBody =>
      'Die Beta ist geschlossen, wir schalten laufend Plätze frei. Du bekommst eine E-Mail, sobald du dran bist.';

  @override
  String get gateRecheck => 'Status erneut prüfen';

  @override
  String get gateRecheckA11y => 'Beta-Status erneut prüfen';

  @override
  String get gateRecheckNegative => 'Geprüft — noch kein Platz frei.';

  @override
  String get gateRecheckOffline => 'Prüfung nicht möglich — kein Netz.';

  @override
  String get gateRechecking => 'Wird geprüft …';

  @override
  String gateSignedInAs(String email) {
    return 'Angemeldet als $email';
  }

  @override
  String get gateStatus => 'WARTELISTE';

  @override
  String get gateStatusA11y => 'Status: Warteliste';

  @override
  String get gateSwitchAccount => 'Anderes Konto verwenden';

  @override
  String get gateSwitchAccountA11y => 'Abmelden und mit anderem Konto anmelden';

  @override
  String get gateTitle => 'Du stehst auf der Liste';

  @override
  String historyAll(int n) {
    return 'Alle $n';
  }

  @override
  String get historyAnalysisOpen => 'Auswertung öffnen';

  @override
  String get historyEmptyBody =>
      'Deine erste Einheit steht hier, sobald du sie beendet hast.';

  @override
  String get historyEmptyTitle => 'Noch nichts aufgezeichnet';

  @override
  String get historyErrorBody =>
      'Deine Einheiten konnten nicht geladen werden.';

  @override
  String get historyErrorTitle => 'Verlauf nicht verfügbar';

  @override
  String get historyFormLabel => 'Form';

  @override
  String historyFormOf(int v) {
    return '$v/100';
  }

  @override
  String historyLeadFrequency(int n, int d) {
    return '$n Einheiten in $d Tagen';
  }

  @override
  String historyLeadGap(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Tage',
      one: '# Tag',
    );
    return '$_temp0 ohne Training';
  }

  @override
  String historyLeadLast(String weekday, String date, String name) {
    return 'Zuletzt $weekday $date · $name';
  }

  @override
  String get historyMonthsLabel => 'Einheiten je Monat';

  @override
  String historyMonthsMedian(int n, int max) {
    return 'Median $n Tage Abstand · längste Pause $max';
  }

  @override
  String get historyRecentLabel => 'Letzte Einheiten';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get historyTrendFalling => 'fallend';

  @override
  String get historyTrendRising => 'steigend';

  @override
  String get historyTrendStable => 'stabil';

  @override
  String get historyZoneInactive => 'Untätig';

  @override
  String get historyZonePause => 'Pause';

  @override
  String get historyZoneRecent => 'Dran geblieben';

  @override
  String get historyZoneRhythm => 'Im Rhythmus';

  @override
  String listEndBody(String date, int n) {
    return 'Erste Einheit am $date · $n Tage her.';
  }

  @override
  String get listEndTitle => 'Ende des Verlaufs';

  @override
  String get listErrorBody => 'Deine Workouts konnten nicht geladen werden.';

  @override
  String get listErrorTitle => 'Laden fehlgeschlagen';

  @override
  String listGap(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Tage',
      one: '# Tag',
    );
    return '$_temp0 ohne Training';
  }

  @override
  String get listGapLongest => 'längste Pause im Verlauf';

  @override
  String listGapRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String listMonthSummary(String n, int load) {
    return '$n · Last $load';
  }

  @override
  String listSecond(int n) {
    return '$n. Einheit';
  }

  @override
  String get listTitle => 'Einheiten';

  @override
  String get muscleArms => 'Arme';

  @override
  String get muscleBack => 'Rücken';

  @override
  String get muscleBiceps => 'Bizeps';

  @override
  String get muscleCalves => 'Waden';

  @override
  String get muscleChest => 'Brust';

  @override
  String get muscleCore => 'Core';

  @override
  String get muscleGlutes => 'Gesäß';

  @override
  String get muscleHamstrings => 'Beinbeuger';

  @override
  String get muscleLegs => 'Beine';

  @override
  String get muscleQuads => 'Quadrizeps';

  @override
  String get muscleShoulders => 'Schultern';

  @override
  String get muscleTriceps => 'Trizeps';

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
  String get navSoonBody => 'Dieser Bereich ist noch nicht gebaut.';

  @override
  String get navSoonTitle => 'Kommt noch';

  @override
  String get navTraining => 'Training';

  @override
  String get onbCta => 'Los geht’s';

  @override
  String get onbCtaLocked => 'Gib dein Gewicht ein, um zu starten.';

  @override
  String get onbCtaLockedA11y => 'Körpergewicht fehlt';

  @override
  String onbErrorRange(String min, String max, String unit) {
    return 'Bitte gib einen Wert zwischen $min und $max $unit ein.';
  }

  @override
  String onbFieldA11y(String unit) {
    return 'Körpergewicht in $unit';
  }

  @override
  String get onbHintSettings => 'Später änderbar unter Profil → Körperdaten.';

  @override
  String get onbKicker => 'FAST GESCHAFFT';

  @override
  String get onbSaving => 'Wird gespeichert …';

  @override
  String get onbTitle => 'Dein Körpergewicht';

  @override
  String get onbUnitGroupA11y => 'Gewichtseinheit wählen';

  @override
  String get onbUnitKg => 'kg';

  @override
  String get onbUnitKgA11y => 'Einheit: Kilogramm';

  @override
  String get onbUnitLbs => 'lbs';

  @override
  String get onbUnitLbsA11y => 'Einheit: Pfund';

  @override
  String get onbWhy =>
      'ATEM rechnet jede Übung in Trainingslast um — auch die ohne Gewichte. Dafür braucht es genau eine Zahl.';

  @override
  String planCount(int n) {
    return '$n Pläne';
  }

  @override
  String get planItemMissing => 'Nicht mehr vorhanden';

  @override
  String planMeta(int n, String type) {
    return '$n Übungen · $type';
  }

  @override
  String get planMissingBody =>
      'Sie wurden gelöscht. Der Plan startet ohne sie.';

  @override
  String planMissingTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Übungen fehlen',
      one: 'Eine Übung fehlt',
    );
    return '$_temp0';
  }

  @override
  String get regionArms => 'Arme';

  @override
  String get regionBack => 'Rücken';

  @override
  String get regionChest => 'Brust';

  @override
  String get regionCore => 'Core';

  @override
  String get regionLegs => 'Beine';

  @override
  String get regionShoulders => 'Schultern';

  @override
  String restSeconds(int n) {
    return '$n s';
  }

  @override
  String get sheetFreeBody =>
      'Ohne Plan starten — Übungen fügst du im Training hinzu.';

  @override
  String get sheetRestLabel => 'Standard-Pause';

  @override
  String get sheetStart => 'Starten';

  @override
  String sheetStartTitle(String plan) {
    return '$plan starten?';
  }

  @override
  String get splashStarting => 'ATEM startet …';

  @override
  String get typeBodyweight => 'Körpergewicht';

  @override
  String get typeCardio => 'Cardio';

  @override
  String get typeHybrid => 'Hybrid';

  @override
  String get typeRecovery => 'Regeneration';

  @override
  String get typeStrength => 'Kraft';

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

  @override
  String get workoutsFree => 'Freies Training';

  @override
  String get workoutsFreeStart => 'Freies Training starten';

  @override
  String get workoutsPlanPick => 'Plan wählen';

  @override
  String workoutsPlansAll(int n) {
    return 'Alle $n';
  }

  @override
  String get workoutsPlansLabel => 'Pläne';

  @override
  String workoutsSearchEntry(int n) {
    return '$n Übungen durchsuchen';
  }

  @override
  String get workoutsStart => 'Training starten';

  @override
  String get workoutsTitle => 'Workouts';

  @override
  String get workoutsTodayEmptyBody => 'Starte frei oder wähle einen Plan.';

  @override
  String get workoutsTodayEmptyTitle => 'Kein Training geplant';

  @override
  String get workoutsTodayLabel => 'Heute';
}
