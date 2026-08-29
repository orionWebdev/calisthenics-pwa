// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppL10nDe extends AppL10n {
  AppL10nDe([String locale = 'de']) : super(locale);

  @override
  String get aboutAccess => 'Zugang';

  @override
  String get aboutAccessLabel => 'Zugang';

  @override
  String get aboutAccessValue => 'Freigeschaltete Adresse';

  @override
  String get aboutAppearance => 'Darstellung';

  @override
  String get aboutAppearanceValue => 'Dunkel · keine helle Fassung';

  @override
  String get aboutDisplayLabel => 'Darstellung';

  @override
  String get aboutDisplayValue => 'Dunkel · keine helle Fassung';

  @override
  String get aboutLanguages => 'Sprachen';

  @override
  String get aboutLanguagesLabel => 'Sprachen';

  @override
  String get aboutLanguagesValue => 'Deutsch · English';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get accountDelete => 'Konto löschen';

  @override
  String accountDelete2Body(int y, int m, int n, int e) {
    return '$y Jahre $m Monate, $n Einheiten und $e eigene Übungen. Es gibt kein Rückgängig und kein Zeitfenster.';
  }

  @override
  String get accountDelete2Confirm => 'Konto löschen';

  @override
  String get accountDelete2Keep => 'Behalten';

  @override
  String get accountDelete2Title => 'Endgültig löschen';

  @override
  String accountDelete2TypeCount(int a, String b) {
    return '$a / $b Zeichen';
  }

  @override
  String get accountDelete2TypeLabel => 'Tippe „LÖSCHEN\", um zu bestätigen';

  @override
  String get accountDelete2TypeWord => 'LÖSCHEN';

  @override
  String get accountDeleteAccess =>
      'Dein Zugang bleibt. Du kannst dich danach wieder anmelden — die App startet dann leer und beim Onboarding.';

  @override
  String get accountDeleteBody =>
      'Das löscht deinen gesamten Bestand. Zahlen von heute:';

  @override
  String get accountDeleteContinue => 'Weiter zum Löschen';

  @override
  String get accountDeleteExport => 'Daten vorher ausgeben';

  @override
  String get accountDeleteRange => 'Zeitraum';

  @override
  String get accountDeleteSub => 'Sechs Sammlungen · kein Widerruf';

  @override
  String get accountDeleting => 'Konto wird gelöscht';

  @override
  String accountDeletingStep(String name) {
    return '$name';
  }

  @override
  String get accountDeletingWait =>
      'Nicht abbrechbar. Das dauert einen Moment.';

  @override
  String get accountDoneAccessBody =>
      'Deine Freischaltung für ATEM gilt weiter. Meldest du dich mit derselben Adresse neu an, bist du wieder drin — mit leerem Bestand und im Onboarding.';

  @override
  String get accountDoneAccessTitle => 'Eine Sache bleibt';

  @override
  String get accountDoneBody =>
      'Deine Einheiten, Pläne, Übungen, Termine und dein Fortschritt sind gelöscht. Das Anmeldekonto ist entfernt.';

  @override
  String get accountDoneTitle => 'Konto gelöscht';

  @override
  String get accountDoneToLogin => 'Zur Anmeldung';

  @override
  String accountPartialBody(int a, int b) {
    return '$a von $b Sammlungen sind weg, das Anmeldekonto besteht noch.';
  }

  @override
  String get accountPartialResume => 'Löschen fortsetzen';

  @override
  String get accountPartialTitle => 'Nicht vollständig gelöscht';

  @override
  String get activityBike => 'Rad';

  @override
  String get activityBikeIndoor => 'Indoor-Rad';

  @override
  String get activityHike => 'Wandern';

  @override
  String get activityMore => 'Weitere';

  @override
  String get activityOther => 'Sonstiges';

  @override
  String activityOwn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return 'Deine Aktivitäten · $_temp0';
  }

  @override
  String get activityRow => 'Rudern';

  @override
  String get activityRun => 'Laufen';

  @override
  String get activitySwim => 'Schwimmen';

  @override
  String get activityWalk => 'Gehen';

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
  String analysisDistBasis(int n, int total) {
    return '$n von $total Einheiten mit Distanz';
  }

  @override
  String get analysisDistTitle => 'Verteilung der Distanzen';

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
  String get analysisExplainBody =>
      'Fünf Bestandteile ergeben zusammen bis zu 103 Punkte, gedeckelt auf 100. Wer lange nicht trainiert, verliert zusätzlich — und zwar beschleunigt: drei Tage kosten 3 Punkte, sieben Tage 21, vierzehn Tage 70.';

  @override
  String get analysisExplainTitle => 'Wie sich die Form zusammensetzt';

  @override
  String analysisHintRecency(int n) {
    return 'Was fehlt, ist Aktualität — eine Einheit heute bringt sofort $n Punkte.';
  }

  @override
  String get analysisLegendRug => 'Einheiten/Woche';

  @override
  String get analysisLegendWith => 'mit Training';

  @override
  String get analysisLegendWithout => 'ohne Training';

  @override
  String analysisPaceBasis(String value, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Läufe',
      one: '1 Lauf',
    );
    return 'gegen eigenen Schnitt $value · $_temp0';
  }

  @override
  String analysisPaceThin(int min, String value, String from, String to) {
    return 'Keine Kurve unter $min Einheiten dieser Aktivität. Schnitt $value, Spanne $from bis $to.';
  }

  @override
  String get analysisPaceTitle => 'Tempoentwicklung';

  @override
  String analysisPctFaster(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Schneller als # von $total deiner Läufe',
      one: 'Schneller als 1 deiner Läufe',
    );
    return '$_temp0';
  }

  @override
  String get analysisPctNoothers => 'Kein Vergleich mit anderen Menschen.';

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
  String analysisWeeklyBasis(String value, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return 'Ø $value km · $_temp0';
  }

  @override
  String get analysisWeeklyCurrent => 'laufend';

  @override
  String get analysisWeeklyTitle => 'Wochenkilometer';

  @override
  String analysisWhyConsistency(int days, int span) {
    return '$days Trainingstage in $span';
  }

  @override
  String get analysisWhyFitness => 'Anteil am eigenen Höchststand';

  @override
  String get analysisWhyLoadNone => 'Keine Last in den letzten 28 Tagen';

  @override
  String get analysisWhyLoadRatio => 'Letzte 14 Tage gegen die 14 davor';

  @override
  String analysisWhyPenalty(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Tage ohne Training',
    );
    return '$_temp0';
  }

  @override
  String analysisWhyRecency(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Letzte Einheit vor # Tagen',
      one: 'Letzte Einheit gestern',
      zero: 'Heute trainiert',
    );
    return '$_temp0';
  }

  @override
  String analysisWhyRecencyRecovery(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Letzte Aktivität vor # Tagen · Regeneration',
      one: 'Gestern Regeneration',
      zero: 'Heute Regeneration',
    );
    return '$_temp0';
  }

  @override
  String get analysisWhyToday => 'Heute trainiert';

  @override
  String get analysisWhyTodayNone => 'Heute keine Einheit';

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
  String balanceBasis(int sets, int n, int total) {
    return '$sets Sätze · $n von $total Kraft-Einheiten';
  }

  @override
  String get balanceColLast => 'zuletzt vor';

  @override
  String get balanceColSets => 'Sätze';

  @override
  String get balanceColShare => 'Anteil';

  @override
  String get balanceGapsNote =>
      'Abstand seit dem letzten Satz auf diesen Muskel. Kein Sollwert — die App weiß nicht, wie oft er dran sein sollte.';

  @override
  String get balanceGapsTitle => 'Längste Abstände';

  @override
  String balanceLastDays(int n) {
    return '$n T';
  }

  @override
  String balanceLastDaysLong(int n) {
    return 'zuletzt $n T';
  }

  @override
  String balanceThin(int n, int min) {
    return 'Noch zu wenig Grundlage: $n von $min Krafteinheiten mit Übungen in den letzten 8 Wochen.';
  }

  @override
  String balanceThinProgress(int n, int min, int rest) {
    return '$n / $min · noch $rest Einheiten';
  }

  @override
  String get balanceTitle => 'Muskelbalance';

  @override
  String get balanceWindow => '8 Wochen';

  @override
  String barrierDialog(String titel) {
    return '„$titel\" — bitte eine Option wählen';
  }

  @override
  String barrierSheet(String titel) {
    return 'Schließt „$titel\"';
  }

  @override
  String get cardioAdd => 'Einheit erfassen';

  @override
  String get cardioAddFirst => 'Erste Einheit erfassen';

  @override
  String get cardioEmptyBody =>
      'Erfasse einen Lauf, eine Radfahrt oder eine Wanderung. Ab der zweiten Einheit derselben Aktivität steht hier die Tempoentwicklung.';

  @override
  String get cardioEmptyTitle => 'Noch keine Ausdauereinheit';

  @override
  String get cardioErrorWeek => 'Wochenkilometer nicht berechenbar';

  @override
  String get cardioLiveStart => 'Live mitlaufen lassen';

  @override
  String cardioTotalSince(String date) {
    return 'Gesamt · seit $date';
  }

  @override
  String cardioWeekBasis(String value) {
    return 'gegen 4-Wochen-Schnitt $value km';
  }

  @override
  String cardioWeekCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0';
  }

  @override
  String get cardioWeekThin =>
      'Wochenkilometer ab 3 Wochen mit Einheiten. Bis dahin steht hier die Gesamtstrecke.';

  @override
  String cardioWeekTitle(int kw) {
    return 'Diese Woche · KW $kw';
  }

  @override
  String get commonActivity => 'Aktivität';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonAddSession => 'Session hinzufügen';

  @override
  String get commonAll => 'Alle';

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
  String get commonCreated => 'Übung angelegt';

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
  String get commonGotIt => 'Verstanden';

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
  String get commonOf => 'von';

  @override
  String get commonOffline => 'Lokal gesichert · wird synchronisiert';

  @override
  String get commonOfflineSync => 'Lokal gesichert · wird synchronisiert';

  @override
  String get commonOpen => 'Öffnen';

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
  String get commonRetrySave => 'Erneut speichern';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonSaved => 'Änderung gespeichert';

  @override
  String get commonSaving => 'Wird gespeichert';

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
  String get commonUndo => 'Rückgängig';

  @override
  String get commonView => 'Ansehen';

  @override
  String get commonViewDetails => 'Details ansehen';

  @override
  String get commonWeeks => 'Wochen';

  @override
  String get commonWorkout => 'Workout';

  @override
  String compareBasisDate(String date, int n) {
    return '$date · $n Tage her';
  }

  @override
  String get compareBasisExercises => 'Gleiche Übungen';

  @override
  String compareBasisMedian(int n) {
    return 'Mittel · $n Einheiten';
  }

  @override
  String get compareBasisPlan => 'Gleicher Plan';

  @override
  String compareEmptyPlan(String plan) {
    return 'Erste Einheit des Plans „$plan\". Ab der nächsten steht hier der Vergleich.';
  }

  @override
  String get compareEmptyType =>
      'Erste Einheit dieser Art. Ab der nächsten steht hier der Vergleich.';

  @override
  String get compareLoading => 'Vergleich wird geladen';

  @override
  String compareMedian(String value) {
    return 'Mittel $value';
  }

  @override
  String get compareNoneValue => 'kein Bezug';

  @override
  String get compareNoteMedian =>
      'Keine Plan-ID, keine Übungsüberdeckung. Verglichen wird nur, was von den Übungen unabhängig ist: Dauer und Last.';

  @override
  String compareNotePlan(String plan) {
    return 'Beide Einheiten folgen Plan „$plan\". Alle vier Werte sind vergleichbar.';
  }

  @override
  String comparePrev(String value) {
    return 'vorher $value';
  }

  @override
  String consequenceDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get consequenceForm => 'Form';

  @override
  String get consequenceGone => 'entfällt';

  @override
  String get consequenceLoad => 'Belastung';

  @override
  String get consequenceNew => 'erscheint';

  @override
  String get consequenceNone => 'An deiner Auswertung ändert das nichts.';

  @override
  String get consequencePause => 'Pause';

  @override
  String consequenceStep(String from, String to) {
    return '$from → $to';
  }

  @override
  String consequenceStepA11y(String label, String from, String to) {
    return '$label: von $from auf $to';
  }

  @override
  String get consequenceTitle => 'Was sich ändert';

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
  String get dashboardNavAnalytics => 'VERLAUF';

  @override
  String get dashboardNavHome => 'HOME';

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
  String get deleteConfirm => 'Löschen';

  @override
  String get deleteKeep => 'Behalten';

  @override
  String get deleteStep1Continue => 'Weiter zum Löschen';

  @override
  String get deleteStep2NoUndo => 'Es gibt kein Rückgängig — nur neu anlegen.';

  @override
  String get deleteStep2Title => 'Endgültig löschen';

  @override
  String get detailAcwrLabel => 'Belastung an diesem Tag';

  @override
  String detailAcwrZone(String v, String zone) {
    return 'ACWR $v · $zone';
  }

  @override
  String get detailCompareMid => 'Mittelfeld';

  @override
  String detailCompareTitle(int n) {
    return 'Gegen deine $n Läufe';
  }

  @override
  String detailCompareTop(int p) {
    return 'Top $p %';
  }

  @override
  String get detailDistance => 'Strecke';

  @override
  String get detailDuration => 'Dauer';

  @override
  String get detailLoad => 'Last';

  @override
  String get detailNoteAdd => 'Notiz hinzufügen';

  @override
  String get detailPace => 'Pace /km';

  @override
  String get detailRecoveryBody =>
      'Recovery hält die Kette, treibt aber die Lastentwicklung nicht.';

  @override
  String get detailRecoveryTitle => 'Zählt für die Konstanz';

  @override
  String get detailSaveAsPlan => 'Als Plan speichern';

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
  String get dialogDeleteTitle => 'Verlauf löschen?';

  @override
  String get dialogEndConfirm => 'Beenden & speichern';

  @override
  String get dialogEndTitle => 'Workout beenden?';

  @override
  String get directionBetter => 'besser';

  @override
  String get directionLonger => 'länger';

  @override
  String get directionSame => 'unverändert';

  @override
  String get directionShorter => 'kürzer';

  @override
  String get directionWorse => 'schlechter';

  @override
  String durationApproxMinutes(int n) {
    return '~$n min';
  }

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

  @override
  String get emptyHistoryBody =>
      'Dein Verlauf entsteht mit der ersten abgeschlossenen Session.';

  @override
  String get emptyHistoryTitle => 'Noch kein Verlauf';

  @override
  String emptySearchBody(String begriff, int n) {
    return 'Für „$begriff\" mit $n aktiven Filtern gibt es keine Treffer.';
  }

  @override
  String get emptySearchCta => 'Filter zurücksetzen';

  @override
  String get emptySearchTitle => 'Keine Übung gefunden';

  @override
  String get emptyTodayBody => 'Ruhetag — oder Platz für eine freie Session.';

  @override
  String get emptyTodayCta => 'Session planen';

  @override
  String get emptyTodayTitle => 'Heute ist nichts geplant';

  @override
  String get entryCollapse => 'Zuklappen';

  @override
  String get entryExpand => 'Aufklappen';

  @override
  String get entryNoTarget => 'Kein Ziel gesetzt';

  @override
  String entrySummary(String sets, String reps, String rest) {
    return '$sets×$reps · $rest s Pause';
  }

  @override
  String get errorBack => 'Zurück zum Dashboard';

  @override
  String get errorLoadBody =>
      'Der Plan konnte nicht abgerufen werden. Deine bisherigen Daten sind sicher.';

  @override
  String get errorLoadTitle => 'Workout nicht ladbar';

  @override
  String get errorOfflineBanner =>
      'Offline — Änderungen werden lokal gespeichert';

  @override
  String get errorSectionBody => 'Alles andere ist aktuell.';

  @override
  String get errorSectionRetry => 'Neu laden';

  @override
  String errorSectionTitle(String sektion) {
    return '$sektion nicht ladbar';
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
  String get exerciseCopyNotice =>
      'Die kuratierte Übung bleibt bestehen. Deine Fassung steht daneben.';

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
  String get exerciseCuratedBadge => 'Kuratiert';

  @override
  String get exerciseCuratedBody =>
      'Diese Übung ist für alle gleich und bleibt unverändert. Willst du sie anders, leg dir eine eigene Fassung an.';

  @override
  String get exerciseCuratedCopy => 'Eigene Fassung anlegen';

  @override
  String get exerciseCuratedTitle => 'Gehört zur Bibliothek';

  @override
  String get exerciseDelete => 'Übung löschen';

  @override
  String exerciseDeleteKeepUnits(int n) {
    return 'Deine $n Einheiten bleiben vollständig — mit Sätzen, Gewichten und Last.';
  }

  @override
  String exerciseDeletePlansGap(int n) {
    return 'In den $n Plänen bleibt eine Lücke stehen, die du dort ersetzen kannst.';
  }

  @override
  String exerciseDeleteQ(String name) {
    return '„$name\" löschen?';
  }

  @override
  String exerciseDeleteUsage(int p, int s) {
    String _temp0 = intl.Intl.pluralLogic(
      p,
      locale: localeName,
      other: '# Plänen',
      one: '# Plan',
    );
    String _temp1 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: '# Einheiten',
      one: '# Einheit',
    );
    return 'Die Übung steckt in $_temp0 und $_temp1.';
  }

  @override
  String exerciseDifficultyA11y(int n) {
    return 'Schwierigkeit $n von 5';
  }

  @override
  String exerciseDuplicateBody(String name) {
    return 'Du hast schon eine Übung „$name\". Deine Eingaben stehen noch hier.';
  }

  @override
  String get exerciseDuplicateOpen => 'Vorhandene öffnen';

  @override
  String get exerciseDuplicateSuggest => 'Vorschlag nehmen';

  @override
  String get exerciseDuplicateTitle => 'Nicht gespeichert';

  @override
  String get exerciseEditTitle => 'Übung bearbeiten';

  @override
  String get exerciseFieldCues => 'Cues';

  @override
  String get exerciseFieldCuesHint => 'Kurze Merksätze, einer je Zeile';

  @override
  String get exerciseFieldEquipment => 'Gerät';

  @override
  String get exerciseFieldEquipmentHint => 'Freitext, keine feste Liste';

  @override
  String get exerciseFieldInstructions => 'Anleitung';

  @override
  String get exerciseFieldInstructionsHint => 'Freitext, bis 500 Zeichen';

  @override
  String get exerciseFieldLevel => 'Stufe';

  @override
  String get exerciseFieldMuscles => 'Muskeln';

  @override
  String exerciseFieldMusclesCount(int n) {
    return '$n gewählt';
  }

  @override
  String get exerciseFieldName => 'Name';

  @override
  String get exerciseFieldNameHint => 'z. B. Bulgarian Split Squat';

  @override
  String get exerciseFormSaveError => 'Übung nicht gespeichert';

  @override
  String get exerciseFormSaveErrorBody =>
      'Prüfe die Verbindung und versuche es erneut.';

  @override
  String get exerciseHistoryTitle => 'Du mit dieser Übung';

  @override
  String get exerciseInstructions => 'Anleitung';

  @override
  String get exerciseLevel1 => 'Einstieg';

  @override
  String get exerciseLevel2 => 'Leicht';

  @override
  String get exerciseLevel3 => 'Mittel';

  @override
  String get exerciseLevel4 => 'Fortgeschritten';

  @override
  String get exerciseLevel5 => 'Experte';

  @override
  String get exerciseLevelHint => 'Wird als Zahl 1–5 gespeichert.';

  @override
  String get exerciseMistakes => 'Häufige Fehler';

  @override
  String get exerciseMore => 'Mehr Angaben';

  @override
  String exerciseMoreCount(int n) {
    return '$n optional';
  }

  @override
  String get exerciseNewTitle => 'Neue Übung';

  @override
  String exerciseSaveBlocked(int n) {
    return 'Noch $n Angaben nötig';
  }

  @override
  String get exerciseSparseBody => 'Diese Übung hast du selbst angelegt.';

  @override
  String get exerciseSparseTitle => 'Keine Anleitung hinterlegt';

  @override
  String get exercisesBlockAll => 'Alle ansehen';

  @override
  String get exercisesBlockByMuscle => 'Nach Muskel';

  @override
  String get exercisesBlockSearch => 'Name oder Muskel';

  @override
  String exercisesBlockTitle(int n) {
    return 'Übungen · $n';
  }

  @override
  String exercisesCount(int n, int k, int e) {
    return '$n Übungen · $k kuratiert · $e eigene';
  }

  @override
  String get exercisesCreate => 'Eigene Übung anlegen';

  @override
  String exercisesEmptyBody(String q) {
    return 'Keine Übung passt zu „$q“ — auch nicht auf Englisch.';
  }

  @override
  String get exercisesEmptyOwnBody =>
      'Name, Muskeln und eine Stufe genügen — der Rest ist freiwillig.';

  @override
  String get exercisesEmptyOwnTitle => 'Noch keine eigene Übung';

  @override
  String get exercisesEmptyTitle => 'Nichts gefunden';

  @override
  String exercisesFilterActive(String muscle) {
    return '$muscle, Filter aktiv';
  }

  @override
  String get exercisesFilterAll => 'Alle';

  @override
  String exercisesFilterMuscle(String muscle) {
    return 'Nach $muscle filtern';
  }

  @override
  String get exercisesFilterReset => 'Zurücksetzen';

  @override
  String exercisesFilterResult(int n, String filter) {
    return '$n Übungen · $filter';
  }

  @override
  String get exercisesNoMatchBody => 'Ändere den Suchbegriff oder den Muskel.';

  @override
  String get exercisesNoMatchTitle => 'Keine Treffer';

  @override
  String get exercisesOwnTag => 'Eigen';

  @override
  String get exercisesSearchHint => 'Übung suchen …';

  @override
  String get exercisesTitle => 'Übungen';

  @override
  String get exportBody => 'Du wählst danach, wohin sie geht.';

  @override
  String get exportCreate => 'Datei erstellen';

  @override
  String get exportCreateCsv => 'Als CSV erstellen';

  @override
  String get exportCreateJson => 'Als JSON erstellen';

  @override
  String get exportDoneNote =>
      'Die Datei liegt im Downloads-Ordner. Die App verschickt nichts selbst.';

  @override
  String get exportDoneShare => 'Teilen';

  @override
  String get exportFormatNote =>
      'JSON enthält alles. CSV enthält deine Einheiten als Tabelle, eine Zeile je Satz.';

  @override
  String get exportOffline => 'Offline nicht möglich';

  @override
  String exportProgress(int a, int b, int c, int d, int e, int f) {
    return 'Einheiten $a/$b · Pläne $c/$d · Übungen $e/$f';
  }

  @override
  String exportRowDays(int n) {
    return '$n T';
  }

  @override
  String get exportRowExercises => 'Eigene Übungen';

  @override
  String get exportRowPlans => 'Pläne mit Einträgen';

  @override
  String get exportRowProfile => 'Profilangaben';

  @override
  String get exportRowSchedule => 'Termine';

  @override
  String get exportRowScores => 'Bestwerte und Formkurve';

  @override
  String get exportRowSessions => 'Einheiten mit Sätzen';

  @override
  String exportSize(String mb) {
    return 'ca. $mb MB · keine Bilder, keine Videos';
  }

  @override
  String get exportSub => 'Eine Datei mit allem, was dir gehört';

  @override
  String get exportTitle => 'Daten ausgeben';

  @override
  String get formActivity => 'Aktivität';

  @override
  String get formDate => 'Datum';

  @override
  String get formDiscardBarrier => 'Änderungen verwerfen';

  @override
  String get formDiscardBody => 'Was du eingegeben hast, geht verloren.';

  @override
  String get formDiscardConfirm => 'Verwerfen';

  @override
  String get formDiscardKeep => 'Weiter bearbeiten';

  @override
  String get formDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get formDistance => 'Distanz · km';

  @override
  String get formDuration => 'Dauer · min';

  @override
  String get formHrAvg => 'Ø Puls';

  @override
  String get formHrHint =>
      'Puls leer lassen ist der Normalfall. Die Auswertung setzt ihn nirgends voraus.';

  @override
  String get formHrMax => 'Max. Puls';

  @override
  String get formNote => 'Notiz · optional';

  @override
  String formOptionalCount(int n) {
    return 'Optional · $n Felder';
  }

  @override
  String get formPace => 'Tempo';

  @override
  String get formPaceComputed => 'gerechnet';

  @override
  String get formRpe => 'Anstrengung · RPE';

  @override
  String get formRpe1 => 'sehr leicht';

  @override
  String get formRpe3 => 'mittel';

  @override
  String get formRpe5 => 'maximal';

  @override
  String get formToday => 'Heute';

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
  String get hapticsSub => 'Kurzes Klopfen bei Satz und Pause';

  @override
  String get hapticsTitle => 'Haptik';

  @override
  String get hapticsUnavailable => 'Dein Gerät hat keinen Vibrationsmotor.';

  @override
  String historyAll(int n) {
    return 'Alle $n';
  }

  @override
  String get historyAnalysisOpen => 'Auswertung öffnen';

  @override
  String get historyBest => 'Bestwert';

  @override
  String historyCount(int n) {
    return '$n×';
  }

  @override
  String historyCurveA11y(int n, String from, String to) {
    return 'Verlauf des besten Satzgewichts über $n Einheiten, von $from auf $to';
  }

  @override
  String get historyCurveLabel => 'Bestes Satzgewicht';

  @override
  String get historyCurveLegend => 'Ring markiert den Bestwert';

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
  String get historyFreq => 'Häufigkeit';

  @override
  String historyFreqValue(String n) {
    return '$n / Wo';
  }

  @override
  String get historyLast => 'Zuletzt';

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
  String historyOnce(String date) {
    return 'ausgeführt · $date';
  }

  @override
  String get historyOnceLabel => 'Damals';

  @override
  String get historyOnceNote =>
      'Kein Bestwert, keine Kurve, keine Häufigkeit — aus einer Ausführung folgt keins davon.';

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
  String get historyVolume => 'Volumen';

  @override
  String get historyZoneInactive => 'Untätig';

  @override
  String get historyZonePause => 'Pause';

  @override
  String get historyZoneRecent => 'Dran geblieben';

  @override
  String get historyZoneRhythm => 'Im Rhythmus';

  @override
  String get hybridEmptyBody =>
      'Hier steht später, wie Kraft und Ausdauer bei dir zueinander stehen. Fang mit einer Seite an — welcher, ist gleich.';

  @override
  String get hybridEmptyTitle => 'Noch keine Einheit';

  @override
  String hybridWeekThin(int min) {
    return 'Bereitschaft und Formwert ab $min Einheiten.';
  }

  @override
  String get hybridWeekTitle => 'Deine Woche';

  @override
  String get intensityAbove => 'Über dem Schnitt';

  @override
  String get intensityBelow => 'Unter dem Schnitt';

  @override
  String intensityFallbackNote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Läufe',
      one: '1 Lauf',
    );
    return 'Weder Puls noch RPE erfasst. Beurteilt wird über das Tempo gegen $_temp0.';
  }

  @override
  String get intensityLevel1 => 'Ø Herzfrequenz · aus Uhrdaten';

  @override
  String get intensityLevel2 => 'Anstrengung · deine Angabe';

  @override
  String get intensityLevel3 => 'Tempo gegen eigenen Schnitt';

  @override
  String get intensityNoneA11y => 'nicht erfasst';

  @override
  String get intensityNoneValue => '—';

  @override
  String intensityZone(int n, String name) {
    return 'Zone $n · $name';
  }

  @override
  String get languageDe => 'Deutsch';

  @override
  String get languageEn => 'English';

  @override
  String get languageTitle => 'Sprache';

  @override
  String lastCardio(String activity, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Gestern $activity',
      zero: 'Heute $activity',
    );
    return '$_temp0';
  }

  @override
  String lastNone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Seit # Tagen keine Einheit',
      one: 'Seit 1 Tag keine Einheit',
    );
    return '$_temp0';
  }

  @override
  String lastRecovery(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Gestern Regeneration',
      zero: 'Heute Regeneration',
    );
    return '$_temp0';
  }

  @override
  String lastStrength(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Gestern Kraft',
      zero: 'Heute Kraft',
    );
    return '$_temp0';
  }

  @override
  String get legalError => 'Text nicht geladen';

  @override
  String get legalExternal => 'Extern öffnen';

  @override
  String get legalImprint => 'Impressum';

  @override
  String legalImprintBody(String betreiber) {
    return 'Privates Projekt einer natürlichen Person. Angaben nach § 5 TMG: $betreiber';
  }

  @override
  String get legalInapp => 'In der App';

  @override
  String get legalPrivacy => 'Datenschutz';

  @override
  String get legalRetry => 'Erneut versuchen';

  @override
  String get legalTerms => 'Nutzungsbedingungen';

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
  String get listFilterClear => 'Zeitraum aufheben';

  @override
  String listFilterEmptyBody(String typ, String zeitraum, int n) {
    return '$typ kommt im $zeitraum nicht vor — insgesamt gibt es $n.';
  }

  @override
  String get listFilterEmptyTitle => 'Keine Einheit in dieser Auswahl';

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
  String get liveDistanceManual => 'Distanz von Hand · km';

  @override
  String get liveDistanceSource => 'vom Display';

  @override
  String get liveNogps =>
      'Kein GPS, keine Standortabfrage. Die Distanz kommt vom Gerätedisplay und kann jederzeit korrigiert werden.';

  @override
  String get livePause => 'Pause';

  @override
  String liveStarted(String time) {
    return 'Gestartet $time';
  }

  @override
  String get liveStatePaused => 'Pausiert';

  @override
  String get liveStateRunning => 'Läuft';

  @override
  String get liveStop => 'Beenden';

  @override
  String loadingDone(String sektion) {
    return '$sektion geladen';
  }

  @override
  String get loadingLabel => 'Wird geladen …';

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
  String muscleFieldCount(int n, String names) {
    return '$n gewählt · $names';
  }

  @override
  String get muscleFieldEmpty => 'Keine gewählt';

  @override
  String get muscleGlutes => 'Gesäß';

  @override
  String get muscleHamstrings => 'Beinbeuger';

  @override
  String get muscleLegs => 'Beine';

  @override
  String get muscleQuads => 'Quadrizeps';

  @override
  String get muscleSheetHint => 'Mehrere möglich. Der erste gibt die Farbe.';

  @override
  String get muscleSheetTitle => 'Muskeln wählen';

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
  String get onboardingRepeat => 'Onboarding wiederholen';

  @override
  String get onboardingRepeatAction => 'Ansehen';

  @override
  String get onboardingRepeatSub => 'Die vier Einführungsseiten noch einmal';

  @override
  String pickerAdd(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Übungen hinzufügen',
      one: '1 Übung hinzufügen',
    );
    return '$_temp0';
  }

  @override
  String get pickerCreate => 'Übung fehlt? Anlegen';

  @override
  String get pickerNone => 'Nichts gewählt';

  @override
  String get pickerTitle => 'Übungen wählen';

  @override
  String get planBrokenEntry => 'Übung gelöscht';

  @override
  String planBrokenKeepTarget(String ziel) {
    return 'Ziel bleibt · $ziel';
  }

  @override
  String planBrokenNotice(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einträge zeigen',
      one: '# Eintrag zeigt',
    );
    return '$_temp0 ins Leere.';
  }

  @override
  String get planBrokenRemove => 'Entfernen';

  @override
  String get planBrokenReplace => 'Ersetzen';

  @override
  String planCount(int n) {
    return '$n Pläne';
  }

  @override
  String get planDeleteBarrier => 'Plan löschen';

  @override
  String get planDeleteBody =>
      'Deine absolvierten Einheiten bleiben unverändert — sie tragen den Plannamen bei sich.';

  @override
  String get planDeleteTitle => 'Plan löschen?';

  @override
  String get planEmptyAllowed =>
      'Der Plan existiert, sobald er einen Namen hat.';

  @override
  String get planEntryAdd => 'Übung hinzufügen';

  @override
  String get planEntryReps => 'Wdh';

  @override
  String get planEntryRepsHint => '„12\", „8-12\" und „max\" sind erlaubt.';

  @override
  String get planEntryRest => 'Pause';

  @override
  String get planEntrySets => 'Sätze';

  @override
  String get planFormAdd => 'Übung hinzufügen';

  @override
  String get planFormEditTitle => 'Plan bearbeiten';

  @override
  String planFormGapA11y(int n, String scheme) {
    return 'Lücke an Platz $n: gelöschte Übung, $scheme';
  }

  @override
  String get planFormGapBody =>
      'Die Zielwerte bleiben stehen. Ersetze sie durch eine andere Übung.';

  @override
  String get planFormGapTitle => 'Übung gelöscht';

  @override
  String get planFormHold => 'Halten';

  @override
  String get planFormItems => 'Übungen';

  @override
  String get planFormItemsFault => 'Ein Plan braucht mindestens eine Übung.';

  @override
  String planFormMoveA11y(String name, int n, int total) {
    return '$name, Platz $n von $total';
  }

  @override
  String get planFormMoveDown => 'Nach unten';

  @override
  String get planFormMoveUp => 'Nach oben';

  @override
  String get planFormName => 'Name';

  @override
  String get planFormNameFault => 'Ein Plan braucht einen Namen.';

  @override
  String get planFormNameHint => 'z. B. Oberkörper A';

  @override
  String get planFormNewTitle => 'Neuer Plan';

  @override
  String get planFormPickTitle => 'Übung wählen';

  @override
  String get planFormRemove => 'Entfernen';

  @override
  String planFormRemoveA11y(String name) {
    return '$name aus dem Plan entfernen';
  }

  @override
  String get planFormReplace => 'Ersetzen';

  @override
  String get planFormReps => 'Wdh.';

  @override
  String get planFormRepsHint => '8-12';

  @override
  String get planFormRest => 'Pause';

  @override
  String get planFormSaveError => 'Plan nicht gespeichert';

  @override
  String get planFormSaved => 'Plan gespeichert';

  @override
  String get planFormSets => 'Sätze';

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
  String get planNewTitle => 'Neuer Plan';

  @override
  String get profileLocked => 'Über Google · fest';

  @override
  String get profileLockedWhy =>
      'Name und E-Mail kommen aus deinem Google-Konto und werden hier nur angezeigt.';

  @override
  String get quickForm => 'Form';

  @override
  String get quickFormFalling => 'fallend';

  @override
  String get quickFormFlat => 'gleichbleibend';

  @override
  String get quickFormRising => 'steigend';

  @override
  String quickFormValue(int v) {
    return '$v von 100';
  }

  @override
  String get quickLast => 'Letzte Einheit';

  @override
  String quickLastDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tagen',
      one: 'einem Tag',
    );
    return 'vor $_temp0';
  }

  @override
  String get quickLastToday => 'heute';

  @override
  String get quickNext => 'Nächster Termin';

  @override
  String quickNextDays(int n) {
    return 'in $n Tagen';
  }

  @override
  String get quickNextNone => 'Nichts geplant';

  @override
  String get quickNextToday => 'heute';

  @override
  String get quickNextTomorrow => 'morgen';

  @override
  String get quickNoSessions => 'Noch keine Einheit';

  @override
  String ratioBasis(int min, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return 'Anteil an $min Trainingsminuten · $_temp0';
  }

  @override
  String get ratioNoshift => 'kein 4-Wochen-Schnitt';

  @override
  String ratioShift(String value) {
    return '$value pp gegen 4-Wochen-Schnitt';
  }

  @override
  String get ratioShiftDown => 'weniger';

  @override
  String get ratioShiftUp => 'mehr';

  @override
  String get ratioSingleBody =>
      'Ein Verhältnis braucht beide Spuren. Ab der ersten Ausdauereinheit steht es hier.';

  @override
  String get ratioSingleTitle => 'Noch keine Ausdauer';

  @override
  String get ratioTitle => 'Verhältnis';

  @override
  String get recoveryAdd => 'Erfassen';

  @override
  String recoveryGap(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Seit # Tagen keine Regeneration',
      one: 'Seit 1 Tag keine Regeneration',
    );
    return '$_temp0';
  }

  @override
  String get recoveryKindMobility => 'Mobility';

  @override
  String get recoveryKindSauna => 'Sauna';

  @override
  String get recoveryKindStretch => 'Dehnen';

  @override
  String get recoveryKindYoga => 'Yoga';

  @override
  String recoveryLast(String when, String kind, int n) {
    return '$when · $kind · $n min';
  }

  @override
  String get recoveryNever => 'Keine Regeneration erfasst';

  @override
  String get recoveryNoload =>
      'Bricht die Untätigkeitsstrafe, trägt aber keine Last. Der Formwert steigt davon nicht.';

  @override
  String get recoveryTitle => 'Regeneration';

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
  String get repsKeyboard => 'Tastatur';

  @override
  String get repsWheel => 'Rad';

  @override
  String get repsWheelHint =>
      'Das Rad kennt nur Zahlen. Für „8-12\" oder „max\" die Tastatur.';

  @override
  String get restBody =>
      'Gilt für Sätze ohne eigene Pause im Plan. Wirkt ab der nächsten Einheit.';

  @override
  String get restCustom => 'Eigener Wert';

  @override
  String get restRunning => 'Eine laufende Einheit behält ihre Pause.';

  @override
  String restSeconds(int n) {
    return '$n s';
  }

  @override
  String get restSub => 'Vorgabe beim Start einer Einheit';

  @override
  String get restTitle => 'Pausenzeit';

  @override
  String get sectionAbout => 'Über die App';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionData => 'Deine Daten';

  @override
  String get sectionLegal => 'Rechtliches';

  @override
  String get sectionTraining => 'Training';

  @override
  String get segAnalysis => 'Auswertung';

  @override
  String get segHistory => 'Verlauf';

  @override
  String get segSessions => 'Einheiten';

  @override
  String get segTrain => 'Trainieren';

  @override
  String get sessionDateAllowedBody =>
      'Verschiebst du den Tag, verschieben sich Lücken und Form-Kurve mit.';

  @override
  String get sessionDateAllowedTitle => 'Datum ändern ist erlaubt';

  @override
  String sessionDatePrevious(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+# Tage',
      one: '+# Tag',
    );
    return 'Vorher $date · $_temp0';
  }

  @override
  String get sessionDeleteBarrier => 'Einheit löschen';

  @override
  String get sessionDeleteBody =>
      'Sie zählt in jede Auswertung. Danach steht dort:';

  @override
  String get sessionDeleteQ => 'Diese Einheit löschen?';

  @override
  String get sessionDeleteTitle => 'Einheit löschen?';

  @override
  String get sessionDeleteWindow =>
      '30 Sekunden lang kannst du das rückgängig machen.';

  @override
  String sessionDeletedBody(int n) {
    return 'Du kannst das $n Sekunden lang zurücknehmen.';
  }

  @override
  String sessionDeletedSnack(String alt, String neu) {
    return 'Einheit gelöscht · Form $alt → $neu';
  }

  @override
  String sessionDeletedTitle(String name) {
    return '$name gelöscht';
  }

  @override
  String get sessionDeletedUndo => 'Rückgängig';

  @override
  String get sessionEditDate => 'Datum';

  @override
  String sessionEditDateA11y(String date) {
    return 'Datum ändern, aktuell $date';
  }

  @override
  String get sessionEditDuration => 'Dauer in Minuten';

  @override
  String get sessionEditNoChange => 'Nichts geändert';

  @override
  String get sessionEditSaveError => 'Einheit nicht gespeichert';

  @override
  String get sessionEditSaved => 'Einheit gespeichert';

  @override
  String get sessionEditSets => 'Sätze';

  @override
  String get sessionEditTitle => 'Einheit bearbeiten';

  @override
  String get sessionFieldDatetime => 'Datum und Zeit';

  @override
  String get sessionImpactCount => 'Einheiten gesamt';

  @override
  String get sessionImpactForm => 'Form heute';

  @override
  String get sessionImpactLongest => 'Längste Pause';

  @override
  String sessionImpactMonth(String month) {
    return 'Einheiten $month';
  }

  @override
  String sessionImpactOfKind(String kind) {
    return '$kind-Einheiten';
  }

  @override
  String get sessionImpactPause => 'Aktuelle Pause';

  @override
  String get sessionImpactPreview => 'Vorschau, noch nicht gespeichert.';

  @override
  String get sessionImpactTitle => 'Was sich dadurch ändert';

  @override
  String get setsAdd => 'Sätze nachtragen';

  @override
  String get settingsAboutPrivate =>
      'Privates Projekt, keine kommerzielle Nutzung.';

  @override
  String get settingsAboutTheme =>
      'Nur dunkel — ATEM ist für dunkle Umgebungen gebaut.';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsBodyWeight => 'Körpergewicht';

  @override
  String settingsBodyWeightFault(int min, int max) {
    return 'Zwischen $min und $max kg.';
  }

  @override
  String get settingsBodyWeightHint =>
      'Rechnet jede Körpergewichtsübung neu — auch die von früher.';

  @override
  String get settingsBodyWeightNone => 'Noch nicht hinterlegt';

  @override
  String get settingsDelete => 'Konto löschen';

  @override
  String get settingsDeleteBarrier => 'Konto löschen';

  @override
  String get settingsDeleteConfirmHint => 'Genau so, in Großbuchstaben.';

  @override
  String get settingsDeleteConfirmWord => 'LÖSCHEN';

  @override
  String settingsDeleteCounts(int sessions, int plans, int exercises) {
    return '$sessions Einheiten · $plans Pläne · $exercises eigene Übungen';
  }

  @override
  String get settingsDeleteExport => 'Daten vorher sichern';

  @override
  String get settingsDeleteFailed => 'Löschen nicht abgeschlossen';

  @override
  String get settingsDeleteFailedBody =>
      'Ein Teil deiner Daten ist noch da. Versuche es erneut, solange du angemeldet bist.';

  @override
  String get settingsDeleteOfflineBody =>
      'Löschen greift über mehrere Sammlungen. Ohne Verbindung bliebe die Hälfte stehen.';

  @override
  String get settingsDeleteOfflineTitle => 'Ohne Verbindung nicht möglich';

  @override
  String get settingsDeleteRunning => 'Wird gelöscht …';

  @override
  String get settingsDeleteStep1Body =>
      'Einheiten, Pläne, eigene Übungen, Termine und dein Profil werden entfernt. Es gibt kein Zurück und kein Zeitfenster.';

  @override
  String get settingsDeleteStep1Title => 'Konto und alle Daten löschen?';

  @override
  String settingsDeleteStep2Body(String word) {
    return 'Tippe $word, um zu bestätigen.';
  }

  @override
  String get settingsDeleteStep2Title => 'Wirklich endgültig löschen?';

  @override
  String get settingsDeletedAccessBody =>
      'ATEM ist geschlossen; die Freischaltung steht in einer Liste, die zum Programm gehört und nicht zum Konto. Meldest du dich erneut an, bist du wieder dabei — mit leerem Bestand.';

  @override
  String get settingsDeletedAccessTitle => 'Dein Zugang bleibt bestehen';

  @override
  String get settingsDeletedBody => 'Deine Trainingsdaten sind entfernt.';

  @override
  String get settingsDeletedClose => 'Schließen';

  @override
  String get settingsDeletedTitle => 'Konto gelöscht';

  @override
  String get settingsEntryA11y => 'Profil und Einstellungen';

  @override
  String get settingsExportBody =>
      'JSON enthält alles. CSV enthält deine Einheiten als Tabelle, eine Zeile je Satz.';

  @override
  String get settingsExportCsv => 'Einheiten als CSV';

  @override
  String settingsExportDone(int n) {
    return '$n Dokumente gesichert';
  }

  @override
  String get settingsExportFailed => 'Sichern fehlgeschlagen';

  @override
  String get settingsExportJson => 'Alles als JSON';

  @override
  String get settingsExportRunning => 'Wird gesammelt …';

  @override
  String get settingsExportTitle => 'Daten sichern';

  @override
  String get settingsFromGoogle =>
      'Name und Bild kommen von deinem Google-Konto.';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsHapticsHint =>
      'Kurze Rückmeldung beim Antippen und am Pausenende.';

  @override
  String get settingsHapticsOff => 'Vibration aus';

  @override
  String get settingsHapticsOn => 'Vibration an';

  @override
  String get settingsImprint => 'Impressum';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageEnglish => 'Englisch';

  @override
  String get settingsLanguageGerman => 'Deutsch';

  @override
  String get settingsLanguageHint => 'Wirkt sofort.';

  @override
  String get settingsLinkFailed => 'Seite lässt sich nicht öffnen';

  @override
  String get settingsOpenA11y => 'Einstellungen und Profil öffnen';

  @override
  String get settingsOpensBrowser => 'Öffnet im Browser';

  @override
  String get settingsPreviewComputing => 'Wird gerechnet …';

  @override
  String get settingsPreviewFitness => 'Fitness ggü. Höchststand';

  @override
  String get settingsPreviewLoad => 'Last der letzten Einheit';

  @override
  String get settingsPreviewNone => 'An deinen Auswertungen ändert das nichts.';

  @override
  String get settingsPreviewTitle => 'Was sich dadurch ändert';

  @override
  String get settingsPrivacy => 'Datenschutzerklärung';

  @override
  String get settingsReplayOnboarding => 'Onboarding wiederholen';

  @override
  String get settingsReplayOnboardingHint =>
      'Fragt das Körpergewicht erneut ab.';

  @override
  String get settingsRest => 'Pausenzeit';

  @override
  String settingsRestFault(int min, int max) {
    return 'Zwischen $min und $max Sekunden.';
  }

  @override
  String get settingsRestHint =>
      'Vorschlag beim Start einer Einheit. Im Training änderbar.';

  @override
  String get settingsSectionAbout => 'Über die App';

  @override
  String get settingsSectionAccount => 'Konto';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionLegal => 'Rechtliches';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsSectionTraining => 'Training';

  @override
  String get settingsSignOut => 'Abmelden';

  @override
  String get settingsSignOutBarrier => 'Abmelden';

  @override
  String get settingsSignOutBody =>
      'Deine Daten bleiben. Du kannst dich jederzeit wieder anmelden.';

  @override
  String get settingsSignOutTitle => 'Abmelden?';

  @override
  String get settingsSignedInAs => 'Angemeldet als';

  @override
  String get settingsTerms => 'Nutzungsbedingungen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsUnits => 'Einheiten';

  @override
  String get settingsUnitsHint => 'Gespeichert wird immer in Kilogramm.';

  @override
  String get settingsUnitsImperial => 'Imperial';

  @override
  String get settingsUnitsImperialA11y => 'Imperial, Pfund';

  @override
  String get settingsUnitsMetric => 'Metrisch';

  @override
  String get settingsUnitsMetricA11y => 'Metrisch, Kilogramm';

  @override
  String settingsWeightChanged(String weight) {
    return 'Körpergewicht auf $weight kg geändert';
  }

  @override
  String settingsWeightChangedBody(int n) {
    return 'Du kannst das $n Sekunden lang zurücknehmen.';
  }

  @override
  String sheetFilterActive(int n) {
    return '$n aktiv';
  }

  @override
  String get sheetFilterApply => 'Anwenden';

  @override
  String get sheetFilterTitle => 'Filter';

  @override
  String get sheetFreeBody =>
      'Ohne Plan starten — Übungen fügst du im Training hinzu.';

  @override
  String get sheetGrabberHint => 'Ziehen zum Schließen';

  @override
  String get sheetNoteTitle => 'Notiz zum Satz';

  @override
  String get sheetPickerApply => 'Übernehmen';

  @override
  String get sheetRestLabel => 'Standard-Pause';

  @override
  String get sheetStart => 'Starten';

  @override
  String sheetStartTitle(String plan) {
    return '$plan starten?';
  }

  @override
  String get signout => 'Abmelden';

  @override
  String get signoutKeep => 'Daten bleiben';

  @override
  String get splashStarting => 'ATEM startet …';

  @override
  String get switchOff => 'AUS';

  @override
  String get switchOn => 'AN';

  @override
  String get tabCardio => 'Cardio';

  @override
  String get tabHybrid => 'Hybrid';

  @override
  String get tabStrength => 'Kraft';

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
  String unitKilograms(String v) {
    return '$v kg';
  }

  @override
  String unitKilometers(String v) {
    return '$v km';
  }

  @override
  String get unitSuffixKilograms => 'kg';

  @override
  String get unitSuffixPounds => 'lb';

  @override
  String get unitSuffixSeconds => 's';

  @override
  String get unitsExample => 'So sieht es dann aus';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get unitsMetric => 'Metrisch';

  @override
  String get unitsNote =>
      'Gespeichert bleibt immer metrisch. Umgerechnet wird nur die Anzeige.';

  @override
  String get unitsTitle => 'Einheitensystem';

  @override
  String unsavedBody(int c, int a) {
    String _temp0 = intl.Intl.pluralLogic(
      c,
      locale: localeName,
      other: '# Einträge',
      one: '# Eintrag',
    );
    return 'Du hast $_temp0 geändert und $a hinzugefügt.';
  }

  @override
  String get unsavedContinue => 'Weiter bearbeiten';

  @override
  String get unsavedDiscard => 'Verwerfen';

  @override
  String get unsavedSave => 'Sichern und schließen';

  @override
  String get unsavedTitle => 'Änderungen behalten?';

  @override
  String get weightBody =>
      'Bewertet jede Körpergewichtsübung in deinem Verlauf — heute und rückwirkend.';

  @override
  String weightDelta(String sign, String kg, String pct) {
    return '$sign$kg kg · $sign$pct %';
  }

  @override
  String get weightDirDown => 'niedriger';

  @override
  String get weightDirRescored => 'neu bewertet';

  @override
  String get weightDirSame => 'gleich';

  @override
  String get weightDirUp => 'höher';

  @override
  String get weightErrorRange =>
      'Zwischen 30 und 250 kg. Vorschau bleibt aus, bis der Wert stimmt.';

  @override
  String get weightHint => 'Eine Nachkommastelle · 30–250 kg';

  @override
  String get weightImpactAcwr => 'ACWR';

  @override
  String weightImpactBest(String exercise) {
    return 'Bestwert $exercise';
  }

  @override
  String get weightImpactForm => 'Formwert heute';

  @override
  String get weightImpactLoad => 'Trainingslast 7 T';

  @override
  String get weightImpactNote =>
      'Vorschau, noch nicht gespeichert. Deine Sätze, Gewichte und Wiederholungen bleiben unverändert — nur ihre Bewertung.';

  @override
  String weightImpactRecord(String exercise) {
    return 'Bestwert $exercise';
  }

  @override
  String get weightImpactRescored => 'neu bewertet';

  @override
  String weightImpactScope(int d, int n) {
    return '$d Tage · $n Einheiten mit Körpergewichtsübungen';
  }

  @override
  String get weightImpactTitle => 'Was sich rückwirkend ändert';

  @override
  String weightPrevious(String alt) {
    return 'Vorher $alt kg';
  }

  @override
  String get weightSave => 'Speichern und neu rechnen';

  @override
  String get weightSaveBusy => 'Wird gerechnet';

  @override
  String get weightSaveNone => 'Unverändert · nichts zu speichern';

  @override
  String weightSavedSnack(String kg, String alt, String neu) {
    return 'Gewicht $kg kg · Form $alt → $neu';
  }

  @override
  String get weightSub => 'Bewertet deinen ganzen Verlauf';

  @override
  String get weightTitle => 'Körpergewicht';

  @override
  String get workoutA11yEnd => 'Workout beenden';

  @override
  String workoutA11yFormGuide(String exercise) {
    return 'Form-Video zu $exercise öffnen';
  }

  @override
  String workoutA11yHoldField(int n) {
    return 'Haltezeit in Sekunden, Satz $n';
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
  String get workoutColHold => 'Halten';

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
  String get workoutFreeTitle => 'Freies Training';

  @override
  String get workoutHold => 'Halten';

  @override
  String get workoutHoldDurationLabel => 'Haltedauer (Sek.)';

  @override
  String get workoutLastPerformance => 'Letztes Mal';

  @override
  String get workoutLeaveBody =>
      'Dein Stand bleibt gesichert. Du kannst später fortsetzen.';

  @override
  String get workoutLeaveKeep => 'Verlassen und sichern';

  @override
  String get workoutLeaveStay => 'Weiter trainieren';

  @override
  String get workoutLeaveTitle => 'Training verlassen?';

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
  String workoutPreviousReps(int reps) {
    return '$reps Wdh.';
  }

  @override
  String workoutPreviousSet(String weight, int reps) {
    return '$weight kg × $reps';
  }

  @override
  String workoutPreviousWeight(String weight) {
    return '$weight kg';
  }

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
  String workoutRecordKg(String weight) {
    return 'PR $weight kg';
  }

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
  String get workoutRemoveExerciseBody =>
      'Die abgehakten Sätze dieser Übung gehen verloren.';

  @override
  String workoutRemoveExerciseConfirm(String name) {
    return '$name entfernen?';
  }

  @override
  String workoutResumeBody(String n, int sets, int total) {
    return 'Du hast vor $n ein Training begonnen. $sets von $total Sätzen sind abgehakt.';
  }

  @override
  String get workoutResumeContinue => 'Fortsetzen';

  @override
  String get workoutResumeDiscard => 'Neu beginnen';

  @override
  String get workoutResumeTitle => 'Training fortsetzen?';

  @override
  String get workoutRunnerAddSet => '+ SATZ HINZUFÜGEN';

  @override
  String get workoutRunnerBack => 'Zurück';

  @override
  String get workoutRunnerEmptyBody =>
      'Füge hinzu, was du machst. Die Einheit wächst mit.';

  @override
  String get workoutRunnerEmptyTitle => 'Noch keine Übung';

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
  String get workoutRunnerRemoveExercise => 'Übung entfernen';

  @override
  String workoutRunnerRemoveExerciseA11y(String name) {
    return '$name aus der Einheit entfernen';
  }

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
  String workoutSetTypeLegend(String w, String n, String d, String f) {
    return '$w Aufwärmen · $n Normal · $d Dropsatz · $f Failure';
  }

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
  String workoutTargetHold(int n) {
    return 'Ziel $n s halten';
  }

  @override
  String workoutTargetRef(int sets, String reps) {
    return 'Ziel $sets×$reps';
  }

  @override
  String workoutTargetReps(String reps) {
    return 'Ziel $reps';
  }

  @override
  String workoutTargetSets(int sets) {
    return 'Ziel $sets Sätze';
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

  @override
  String analysisPaceBasisOther(String value, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return 'gegen eigenen Schnitt $value · $_temp0';
  }

  @override
  String analysisPctFasterOther(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Schneller als # von $total deiner Einheiten',
      one: 'Schneller als 1 deiner Einheiten',
    );
    return '$_temp0';
  }

  @override
  String intensityFallbackNoteOther(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return 'Weder Puls noch RPE erfasst. Beurteilt wird über das Tempo gegen $_temp0 derselben Aktivität.';
  }

  @override
  String get intensityZoneName1 => 'regenerativ';

  @override
  String get intensityZoneName2 => 'grundlagig';

  @override
  String get intensityZoneName3 => 'schwellig';

  @override
  String get intensityZoneName4 => 'hart';

  @override
  String get intensityZoneName5 => 'maximal';

  @override
  String intensityBasisA11y(String basis) {
    return 'Grundlage: $basis';
  }

  @override
  String intensityBasisPace(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return 'Tempo gegen eigenen Schnitt aus $_temp0';
  }

  @override
  String intensityRpeValue(int n) {
    return '$n / 5';
  }

  @override
  String get formRpe2 => 'leicht';

  @override
  String get formRpe4 => 'hart';

  @override
  String get formModeLog => 'Nacherfassen';

  @override
  String get formModeLive => 'Live';

  @override
  String get cardioFormTitle => 'Ausdauer erfassen';

  @override
  String get formKind => 'Art';

  @override
  String get formDurationRequired => 'Dauer fehlt';

  @override
  String get formActivityRequired => 'Aktivität fehlt';

  @override
  String get formDistanceInvalid => 'Distanz ungültig';

  @override
  String cardioSavedSnack(String activity) {
    return 'Einheit gespeichert · $activity';
  }

  @override
  String get recoverySavedSnack => 'Regeneration gespeichert';

  @override
  String get liveResume => 'Fortsetzen';

  @override
  String get liveStopTooShort =>
      'Beenden, nicht möglich — Einheit unter einer Minute.';

  @override
  String get livePaceRunning => 'läuft mit';

  @override
  String liveRunningNotice(String time) {
    return 'Live-Uhr läuft · $time';
  }

  @override
  String liveDurationA11y(String time, String state) {
    return 'Dauer $time, $state';
  }

  @override
  String analysisWeeklyA11y(String from, String to) {
    return 'Wochenkilometer der letzten 8 Wochen, von $from bis $to.';
  }

  @override
  String analysisWeeklyGapA11y(int kw) {
    return 'KW $kw ohne Einheit';
  }

  @override
  String analysisWeeklyWeek(int kw) {
    return 'KW $kw';
  }

  @override
  String analysisPctThis(String date) {
    return 'Diese Einheit · $date';
  }

  @override
  String get analysisPctSlowest => 'langsamster';

  @override
  String get analysisPctFastest => 'schnellster';

  @override
  String analysisPaceRange(String value, String from, String to) {
    return 'Schnitt $value · Spanne $from bis $to';
  }

  @override
  String distBucketBelow(String v) {
    return '< $v km';
  }

  @override
  String distBucketRange(String a, String b) {
    return '$a–$b km';
  }

  @override
  String distBucketAbove(String v) {
    return '> $v km';
  }

  @override
  String get cardioAllSessions => 'Alle Einheiten';

  @override
  String cardioWeekA11y(String km, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return '$km Kilometer diese Woche, aus $_temp0';
  }

  @override
  String cardioWeekShiftA11y(String delta, String dir, String avg) {
    return '$delta $dir als der 4-Wochen-Schnitt von $avg';
  }

  @override
  String cardioTotalA11y(String km, String date, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return '$km Kilometer gesamt seit $date, aus $_temp0';
  }

  @override
  String cardioActivityAverage(int n, String km) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0 Ø $km km';
  }

  @override
  String get ratioStrengthWeek => 'Kraft diese Woche';

  @override
  String ratioStrengthMeasure(String t, int s) {
    String _temp0 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: '# Sätze',
      one: '1 Satz',
    );
    return '$t t Volumen · $_temp0';
  }

  @override
  String hybridWeekSummary(int n, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0 · $min min';
  }

  @override
  String get ratioOpenStrength => 'Öffnet Kraft-Verlauf';

  @override
  String get ratioOpenCardio => 'Öffnet Ausdauer-Auswertung';

  @override
  String ratioA11y(int s, int c, int min, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return 'Verhältnis dieser Woche: $s Prozent Kraft, $c Prozent Ausdauer, Anteil an $min Trainingsminuten aus $_temp0.';
  }

  @override
  String ratioRowA11y(String track, int pct, int min) {
    return '$track, $pct Prozent, $min Minuten';
  }

  @override
  String ratioShiftA11y(String value, String dir) {
    return '$value Prozentpunkte $dir als im 4-Wochen-Schnitt';
  }

  @override
  String get hybridEmptyStrength => 'Krafttraining starten';

  @override
  String get hybridEmptyCardio => 'Ausdauer erfassen';

  @override
  String get hybridFormSection => 'Formwert · 4 Wochen';

  @override
  String get whenToday => 'Heute';

  @override
  String get whenYesterday => 'Gestern';

  @override
  String whenLast(String date) {
    return 'Zuletzt $date';
  }

  @override
  String get recoveryFormTitle => 'Regeneration erfassen';

  @override
  String tempoPerKm(String value) {
    return '$value /km';
  }

  @override
  String tempoKmh(String value) {
    return '$value km/h';
  }

  @override
  String cardioListCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0';
  }

  @override
  String get intensityTitle => 'Intensität';
}
