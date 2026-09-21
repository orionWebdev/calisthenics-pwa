// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppL10nDe extends AppL10n {
  AppL10nDe([String locale = 'de']) : super(locale);

  @override
  String get aboutAccessLabel => 'Zugang';

  @override
  String get aboutAccessValue => 'Freigeschaltete Adresse';

  @override
  String get aboutDisplayLabel => 'Darstellung';

  @override
  String get aboutDisplayValue => 'Dunkel · keine helle Fassung';

  @override
  String get aboutLanguagesLabel => 'Sprachen';

  @override
  String get aboutLanguagesValue => 'Deutsch · English';

  @override
  String get accountDelete => 'Konto löschen';

  @override
  String accountDelete2Body(int y, int m, int n, int e) {
    return '$y Jahre $m Monate, $n Einheiten und $e eigene Übungen. Es gibt kein Rückgängig und kein Zeitfenster.';
  }

  @override
  String get accountDelete2Title => 'Endgültig löschen';

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
  String accountDeleteSpan(int y, int m) {
    return '$y J $m M';
  }

  @override
  String get accountRowProgress => 'Fortschritt und Bestwerte';

  @override
  String get accountRowProfile => 'Profil und Einstellungen';

  @override
  String get accountDeleteSub => 'Sechs Sammlungen · kein Widerruf';

  @override
  String get accountDeleting => 'Konto wird gelöscht';

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
      other: '$n Einheiten',
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
  String analysisPaceBasis(String value, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Läufe',
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
      other: 'Schneller als $n von $total deiner Läufe',
      one: 'Schneller als 1 deiner Läufe',
    );
    return '$_temp0';
  }

  @override
  String get analysisPctNoothers => 'Kein Vergleich mit anderen Menschen.';

  @override
  String analysisWeeklyBasis(String value, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return 'Ø $value km · $_temp0';
  }

  @override
  String get analysisWeeklyCurrent => 'laufend';

  @override
  String get analysisWeeklyTitle => 'Wochenkilometer';

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
  String get cardioAdd => 'Einheit erfassen';

  @override
  String get cardioAddFirst => 'Erste Einheit erfassen';

  @override
  String get cardioEmptyBody =>
      'Erfasse einen Lauf, eine Radfahrt oder eine Wanderung. Ab der zweiten Einheit derselben Aktivität steht hier die Tempoentwicklung.';

  @override
  String get cardioEmptyTitle => 'Noch keine Ausdauereinheit';

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
      other: '$n Einheiten',
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
  String get commonBack => 'Zurück';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonCreated => 'Übung angelegt';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonDuration => 'Dauer';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonLoading => 'Lade Daten...';

  @override
  String get commonMinutes => 'Minuten';

  @override
  String get commonNotAvailable => '-';

  @override
  String get commonNotes => 'Notizen';

  @override
  String get commonOf => 'von';

  @override
  String get commonOpen => 'Öffnen';

  @override
  String get commonPercentSign => '%';

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
  String get commonUndo => 'Rückgängig';

  @override
  String get commonWeeks => 'Wochen';

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
  String consequenceStepA11y(String label, String from, String to) {
    return '$label: von $from auf $to';
  }

  @override
  String dashboardHybridBalanceSubtitle(int days) {
    return 'Letzte $days Tage';
  }

  @override
  String get dashboardLoadingA11y => 'Dashboard wird geladen';

  @override
  String dashboardNavA11y(String name, int n, int total) {
    return '$name, Tab $n von $total';
  }

  @override
  String get dashboardNotAvailable => 'Daten nicht verfügbar';

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
  String get detailLoad => 'Last';

  @override
  String get detailSaveAsPlan => 'Als Plan speichern';

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
  String get errorsLoadFailed =>
      'Laden fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get errorsSaveFailed => 'Fehler beim Speichern.';

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
      other: '$p Plänen',
      one: '$p Plan',
    );
    String _temp1 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: '$s Einheiten',
      one: '$s Einheit',
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
  String get exerciseLevel1Short => 'EINST.';

  @override
  String get exerciseLevel2Short => 'LEICHT';

  @override
  String get exerciseLevel3Short => 'MITTEL';

  @override
  String get exerciseLevel4Short => 'FORTG.';

  @override
  String get exerciseLevel5Short => 'EXP.';

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
  String get exercisesBlockByMuscle => 'Nach Muskel';

  @override
  String exercisesCount(int n, int k, int e) {
    return '$n Übungen · $k kuratiert · $e eigene';
  }

  @override
  String get exercisesCreate => 'Eigene Übung anlegen';

  @override
  String get exercisesEmptyOwnBody =>
      'Name, Muskeln und eine Stufe genügen — der Rest ist freiwillig.';

  @override
  String get exercisesEmptyOwnTitle => 'Noch keine eigene Übung';

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
  String get exportDoneNote =>
      'Die Datei liegt im Downloads-Ordner. Die App verschickt nichts selbst.';

  @override
  String get exportDoneShare => 'Teilen';

  @override
  String get exportFormatNote =>
      'JSON enthält alles. CSV enthält deine Einheiten als Tabelle, eine Zeile je Satz.';

  @override
  String get exportFormatFull => 'Vollständig';

  @override
  String get exportFormatSessions => 'Einheiten';

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
  String get historyErrorBody =>
      'Deine Einheiten konnten nicht geladen werden.';

  @override
  String get historyErrorTitle => 'Verlauf nicht verfügbar';

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
      other: '$n Tage',
      one: '$n Tag',
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
    return 'Bereitschaft ab $min Einheiten.';
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
      other: '$n Läufe',
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
      other: 'Seit $n Tagen keine Einheit',
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
  String get legalImprint => 'Impressum';

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
      other: '$n Tage',
      one: '$n Tag',
    );
    return '$_temp0 ohne Training';
  }

  @override
  String get listGapLongest => 'längste Pause im Verlauf';

  @override
  String get listOpenDetail => 'öffnet Details';

  @override
  String listGapOpen(String from) {
    return '$from – heute';
  }

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
  String get navPlans => 'Pläne';

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
  String get planBrokenRemove => 'Entfernen';

  @override
  String get planBrokenReplace => 'Ersetzen';

  @override
  String planCount(int n) {
    return '$n Pläne';
  }

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
  String get planFormEditTitle => 'Plan bearbeiten';

  @override
  String planFormGapA11y(int n, String scheme) {
    return 'Lücke an Platz $n: gelöschte Übung, $scheme';
  }

  @override
  String get planFormGapTitle => 'Übung gelöscht';

  @override
  String get planFormHold => 'Halten';

  @override
  String get planFormItems => 'Übungen';

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
  String get planFormNameHint => 'z. B. Oberkörper A';

  @override
  String get planFormNewTitle => 'Neuer Plan';

  @override
  String planFormRemoveA11y(String name) {
    return '$name aus dem Plan entfernen';
  }

  @override
  String get planFormSaveError => 'Plan nicht gespeichert';

  @override
  String get planItemMissing => 'Nicht mehr vorhanden';

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
  String get ratioNoshift => 'kein 4-Wochen-Schnitt';

  @override
  String get ratioShiftDown => 'weniger';

  @override
  String get ratioShiftUp => 'mehr';

  @override
  String get recoveryAdd => 'Erfassen';

  @override
  String recoveryGap(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Seit $n Tagen keine Regeneration',
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
  String get recoveryTabEmptyTitle => 'Noch keine Regeneration';

  @override
  String get recoveryTabEmptyBody =>
      'Yoga, Sauna, Dehnen oder Mobility — sie bricht die Untätigkeit, ohne Last zu tragen.';

  @override
  String get recoveryTabKinds => 'Nach Art';

  @override
  String get recoveryTabAll => 'Alle Einheiten';

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
      other: '+$n Tage',
      one: '+$n Tag',
    );
    return 'Vorher $date · $_temp0';
  }

  @override
  String get sessionDeleteBody =>
      'Sie zählt in jede Auswertung. Danach steht dort:';

  @override
  String get sessionDeleteQ => 'Diese Einheit löschen?';

  @override
  String get sessionDeleteWindow =>
      '6 Sekunden lang kannst du das rückgängig machen.';

  @override
  String sessionDeletedSnack(String alt, String neu) {
    return 'Einheit gelöscht · Einheiten $alt → $neu';
  }

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
  String get sessionEditTitle => 'Einheit bearbeiten';

  @override
  String get sessionFieldDatetime => 'Datum und Zeit';

  @override
  String get sessionImpactCount => 'Einheiten gesamt';

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
  String get settingsDeletedAccessTitle => 'Dein Zugang bleibt bestehen';

  @override
  String get settingsEntryA11y => 'Profil und Einstellungen';

  @override
  String settingsExportDone(int n) {
    return '$n Dokumente gesichert';
  }

  @override
  String get settingsExportFailed => 'Sichern fehlgeschlagen';

  @override
  String get settingsExportRunning => 'Wird gesammelt …';

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
  String get settingsTitle => 'Einstellungen';

  @override
  String get sheetFreeBody =>
      'Ohne Plan starten — Übungen fügst du im Training hinzu.';

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
      other: '$c Einträge',
      one: '$c Eintrag',
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
  String get weightSub => 'Grundlage jeder Eigengewichts-Rechnung';

  @override
  String get weightTitle => 'Körpergewicht';

  @override
  String get workoutA11yEnd => 'Workout beenden';

  @override
  String workoutA11yFormGuide(String exercise) {
    return 'Anleitung zu $exercise öffnen';
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
  String get workoutColHold => 'Halten';

  @override
  String workoutExerciseProgress(String completed, int total) {
    return '$completed / $total Übungen';
  }

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
  String get workoutLoggingSets => 'Sätze';

  @override
  String get workoutPostWorkoutSets => 'Sets';

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
  String workoutRecordKg(String weight) {
    return 'PR $weight kg';
  }

  @override
  String workoutRelativeTimeDaysAgo(int n) {
    return 'vor $n Tagen';
  }

  @override
  String workoutRelativeTimeWeeksAgo(int n) {
    return 'vor $n Wochen';
  }

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
  String get workoutRunnerEmptyBody =>
      'Füge hinzu, was du machst. Die Einheit wächst mit.';

  @override
  String get workoutRunnerEmptyTitle => 'Noch keine Übung';

  @override
  String get workoutRunnerFormGuide => 'FORM GUIDE';

  @override
  String get workoutRunnerNotAvailable => 'Workout nicht verfügbar';

  @override
  String get workoutRunnerRemoveExercise => 'Übung entfernen';

  @override
  String workoutRunnerRemoveExerciseA11y(String name) {
    return '$name aus der Einheit entfernen';
  }

  @override
  String get workoutRunnerRestLabel => 'PAUSE';

  @override
  String get workoutRunnerRestMinus => '−15';

  @override
  String get workoutRunnerRestPlus => '+30';

  @override
  String get workoutRunnerRestSkip => 'WEITER';

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
  String get workoutScreenAddSet => 'Satz hinzufügen';

  @override
  String get workoutScreenDiscardConfirm =>
      'Workout wirklich verwerfen? Alle Fortschritte gehen verloren.';

  @override
  String get workoutScreenDiscardConfirmTitle => 'Workout verwerfen?';

  @override
  String get workoutScreenDiscardWorkout => 'Workout verwerfen';

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
  String workoutSetLoggerRest(int seconds) {
    return '${seconds}s Pause';
  }

  @override
  String workoutSetLoggerStepModeChanged(int step, String unit) {
    return 'Schrittweite: $step $unit';
  }

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
  String workoutTargetReps(String reps) {
    return 'Ziel $reps';
  }

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
  String get workoutsStart => 'Training starten';

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
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return 'gegen eigenen Schnitt $value · $_temp0';
  }

  @override
  String analysisPctFasterOther(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Schneller als $n von $total deiner Einheiten',
      one: 'Schneller als 1 deiner Einheiten',
    );
    return '$_temp0';
  }

  @override
  String intensityFallbackNoteOther(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
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
      other: '$n Einheiten',
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
      other: '$n Einheiten',
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
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$km Kilometer gesamt seit $date, aus $_temp0';
  }

  @override
  String hybridWeekSummary(int n, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0 · $min min';
  }

  @override
  String get ratioOpenStrength => 'Öffnet Kraft-Verlauf';

  @override
  String get ratioOpenCardio => 'Öffnet Ausdauer-Auswertung';

  @override
  String ratioShiftA11y(String value, String dir) {
    return '$value Prozentpunkte $dir als im 4-Wochen-Schnitt';
  }

  @override
  String get hybridEmptyStrength => 'Krafttraining starten';

  @override
  String get hybridEmptyCardio => 'Ausdauer erfassen';

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
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0';
  }

  @override
  String get intensityTitle => 'Intensität';

  @override
  String acwrLabel(String v) {
    return 'Belastung · ACWR $v';
  }

  @override
  String get acwrBandLow => 'unterfordert';

  @override
  String get acwrBandOptimal => 'optimal';

  @override
  String get acwrBandHigh => 'erhöht';

  @override
  String get acwrBandDanger => 'kritisch';

  @override
  String get acwrBandNoteLow =>
      'Zone unterfordert — akute Last liegt unter der chronischen.';

  @override
  String get acwrBandNoteOptimal =>
      'Zone optimal — akute Last passt zur chronischen.';

  @override
  String get acwrBandNoteHigh =>
      'Zone erhöht — akute Last übersteigt die chronische.';

  @override
  String get acwrBandNoteDanger =>
      'Zone kritisch — akute Last weit über der chronischen.';

  @override
  String acwrScaleA11y(String v, String zone, String from, String to) {
    return 'Belastung $v, Zone $zone, Bereich $from bis $to.';
  }

  @override
  String historyMonthOpenA11y(String month, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$month, $_temp0, öffnet die Liste';
  }

  @override
  String get exerciseAddToPlan => 'Zu Plan hinzufügen';

  @override
  String exerciseAddedToPlan(String plan) {
    return 'Zu „$plan\" hinzugefügt';
  }

  @override
  String exerciseRequiredA11y(int n) {
    return '$n von 3 Pflichtfeldern ausgefüllt';
  }

  @override
  String exerciseMoreFilled(int n) {
    return '$n gefüllt';
  }

  @override
  String get sessionFieldKind => 'Art';

  @override
  String get sessionKindNote => 'Die Art bestimmt, welche Werte unten stehen.';

  @override
  String get sessionPaceNote => 'Tempo wird berechnet und ist nicht eingebbar.';

  @override
  String get exercisesFilterOrigin => 'Herkunft';

  @override
  String get formReadiness => 'Bereitschaft';

  @override
  String get formReadinessHint => 'Vor dem Training. Freiwillig.';

  @override
  String get formReadiness1 => 'erschöpft';

  @override
  String get formReadiness2 => 'müde';

  @override
  String get formReadiness3 => 'okay';

  @override
  String get formReadiness4 => 'gut';

  @override
  String get formReadiness5 => 'frisch';

  @override
  String get formFeeling => 'Gefühl danach';

  @override
  String get formFeeling1 => 'platt';

  @override
  String get formFeeling2 => 'müde';

  @override
  String get formFeeling3 => 'okay';

  @override
  String get formFeeling4 => 'gut';

  @override
  String get formFeeling5 => 'stark';

  @override
  String get formFocus => 'Fokus';

  @override
  String get formFocusHint => 'Wogegen die Einheit ging. Ersetzt keine Sätze.';

  @override
  String get focusPush => 'Drücken';

  @override
  String get focusPull => 'Ziehen';

  @override
  String get focusLegs => 'Beine';

  @override
  String get focusUpperBody => 'Oberkörper';

  @override
  String get focusLowerBody => 'Unterkörper';

  @override
  String get focusFullBody => 'Ganzkörper';

  @override
  String get focusCore => 'Rumpf';

  @override
  String get focusOther => 'Sonstiges';

  @override
  String get strengthFormTitle => 'Krafteinheit erfassen';

  @override
  String get strengthFormNoSets =>
      'Diese Einheit trägt keine Sätze. Sie zählt in Minuten, nicht in Volumen — und erscheint in keiner Muskelverteilung.';

  @override
  String get strengthSavedSnack => 'Krafteinheit gespeichert';

  @override
  String get hybridTimeTitle => 'Trainingszeit';

  @override
  String get hybridTimeGroup => 'Zeitraum der Trainingszeit';

  @override
  String get hybridTimeDays28 => '28 Tage';

  @override
  String hybridTimeUnits(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0';
  }

  @override
  String hybridTimeWithoutDuration(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten ohne Dauer nicht enthalten',
      one: '1 Einheit ohne Dauer nicht enthalten',
    );
    return '$_temp0';
  }

  @override
  String get hybridTimeNote =>
      'Kein Sollverhältnis — die App weiss nicht, wie viel Ausdauer oder Regeneration richtig ist.';

  @override
  String hybridTimeRowA11y(String track, int minutes, int n, int percent) {
    return '$track: $minutes Minuten, $n Einheiten, $percent Prozent';
  }

  @override
  String hybridTimeEmpty(int days) {
    return 'Keine Einheit mit Dauer in den letzten $days Tagen.';
  }

  @override
  String get hybridHeatmapTitle => 'Trainingstage';

  @override
  String hybridHeatmapWindow(int weeks) {
    return '$weeks Wochen';
  }

  @override
  String hybridHeatmapBasis(int trained, int total) {
    return '$trained von $total Tagen trainiert';
  }

  @override
  String hybridHeatmapByTrack(int strength, int cardio, int recovery) {
    return '$strength Kraft · $cardio Cardio · $recovery Regeneration';
  }

  @override
  String get hybridHeatmapLegendNone => 'kein Training';

  @override
  String get hybridHeatmapLegendMixed => 'mehrere';

  @override
  String hybridHeatmapWeekA11y(int week, int days, String detail) {
    return 'KW $week: $days Trainingstage. $detail';
  }

  @override
  String hybridHeatmapWeekNoneA11y(int week) {
    return 'KW $week: kein Training';
  }

  @override
  String hybridHeatmapMixed(String weekday) {
    return '$weekday mehrere Arten';
  }

  @override
  String get analysisMaxTitle => 'Geschätztes Maximum';

  @override
  String get analysisMaxHint =>
      'Epley: Gewicht × (1 + Wdh ÷ 30), beste Schätzung je Einheit. Eine Schätzung, kein Test.';

  @override
  String analysisMaxBasis(int n, String best) {
    return '$n Einheiten · Bestwert $best kg';
  }

  @override
  String analysisMaxDelta(String delta) {
    return '$delta kg seit der ersten Einheit';
  }

  @override
  String analysisMaxDeltaA11y(String direction, String delta) {
    return '$direction $delta Kilogramm seit der ersten Einheit';
  }

  @override
  String get analysisMaxNoDelta => 'kein Vergleich verfügbar';

  @override
  String analysisMaxThinBody(int n, int reps) {
    return 'Ab $n Einheiten je Übung mit Gewicht und höchstens $reps Wiederholungen je Satz.';
  }

  @override
  String analysisMaxProgress(String name, int cur, int req) {
    return '$name: $cur von $req Einheiten';
  }

  @override
  String analysisMaxChartA11y(String name, String first, String last, int n) {
    return '$name: geschätztes Maximum von $first auf $last Kilogramm über $n Einheiten';
  }

  @override
  String get analysisMaxExerciseGroup => 'Übung für das geschätzte Maximum';

  @override
  String balanceSetsShort(int n) {
    return '$n S';
  }

  @override
  String balanceGapDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get balanceThinNote =>
      'Ein Anteil aus wenigen Einheiten schwankt um mehr, als er aussagt. Die Kachel zeigt deshalb, wie weit es noch ist, statt eine Verteilung zu zeichnen.';

  @override
  String balanceTileA11y(String title, String basis, String window) {
    return '$title, $basis, $window';
  }

  @override
  String get balanceLoading => 'Muskelbalance wird geladen';

  @override
  String get balanceErrorTitle => 'Muskelbalance nicht verfügbar';

  @override
  String get balanceErrorBody =>
      'Die Einheiten liessen sich gerade nicht laden.';

  @override
  String historyFreqBasis(int n, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks Wochen',
      one: '1 Woche',
    );
    return '$n× in $_temp0';
  }

  @override
  String get historyVolumeSub => 'letzte Einheit';

  @override
  String historyCurveCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0';
  }

  @override
  String get historyCurveRepsLabel => 'Wiederholungen je Einheit';

  @override
  String historyRepsValue(int n) {
    return '$n Wdh';
  }

  @override
  String historySetsA11y(int sets, int reps) {
    return '$sets mal $reps';
  }

  @override
  String historySetsOnlyA11y(int sets) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String historyKgA11y(String v) {
    return '$v Kilogramm';
  }

  @override
  String historyRepsA11y(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wiederholungen',
      one: '1 Wiederholung',
    );
    return '$_temp0';
  }

  @override
  String historyFreqA11y(String n) {
    return '$n pro Woche';
  }

  @override
  String historyDateA11y(String date) {
    return 'am $date';
  }

  @override
  String historyTileA11y(String label, String value, String detail) {
    return '$label, $value, $detail';
  }

  @override
  String historyCountA11y(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mal ausgeführt',
      one: 'einmal ausgeführt',
    );
    return '$_temp0';
  }

  @override
  String historyCurveBestA11y(String best) {
    return 'Bestwert $best';
  }

  @override
  String historyCurveRepsA11y(int n, String from, String to) {
    return 'Wiederholungen je Einheit über $n Einheiten, von $from auf $to';
  }

  @override
  String thresholdProgress(int cur, int req) {
    return '$cur von $req';
  }

  @override
  String get focusDistTitle => 'Fokus';

  @override
  String get focusDistWindow => '8 Wochen';

  @override
  String get focusDistWhat =>
      'Wogegen deine Krafteinheiten gingen — Drücken, Ziehen, Beine und mehr, als Anteil mit Nenner.';

  @override
  String focusDistCondition(int n) {
    return 'Ab $n Einheiten mit Fokus';
  }

  @override
  String focusDistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0';
  }

  @override
  String focusDistRowA11y(String focus, int n, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$focus, $_temp0, $percent Prozent';
  }

  @override
  String focusDistBasis(int withFocus, int total) {
    return '$withFocus von $total Einheiten mit Fokus';
  }

  @override
  String get progressTitle => 'Fortschritte';

  @override
  String get progressWindow => '4 Wochen';

  @override
  String get progressWhat =>
      'Hier stehen die Übungen, bei denen du in den letzten 4 Wochen einen neuen Bestwert gesetzt hast — an Gewicht, Wiederholungen oder Haltezeit.';

  @override
  String get progressCondition => 'Ab der zweiten Ausführung einer Übung';

  @override
  String get progressNone => 'Kein neuer Bestwert in den letzten 4 Wochen.';

  @override
  String progressBasis(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Übungen',
      one: '1 Übung',
    );
    String _temp1 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String progressOn(String date) {
    return 'am $date';
  }

  @override
  String progressReps(String v) {
    return '$v Wdh';
  }

  @override
  String progressSeconds(String v) {
    return '$v s';
  }

  @override
  String progressBefore(String v) {
    return 'vorher $v';
  }

  @override
  String progressRowA11y(
      String name, String value, String before, String delta, String date) {
    return '$name, $value, vorher $before, $delta mehr, am $date';
  }

  @override
  String get progressOpensExercise => 'öffnet Übung';

  @override
  String progressA11yReps(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wiederholungen',
      one: '1 Wiederholung',
    );
    return '$_temp0';
  }

  @override
  String progressA11ySeconds(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Sekunden',
      one: '1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String progressA11yKg(String v) {
    return '$v Kilogramm';
  }

  @override
  String get weeklySetsTitle => 'Sätze je Woche';

  @override
  String get weeklySetsWhat =>
      'Wie viele Sätze du Woche für Woche machst — und ob diese Woche mehr oder weniger ist als sonst.';

  @override
  String get weeklySetsCondition => 'Ab der ersten Einheit mit Sätzen';

  @override
  String weeklySetsSessions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sätze',
      one: 'Satz',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsPending(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Vergleich ab 2 vollen Wochen · noch $n',
      one: 'Vergleich ab 2 vollen Wochen · noch 1',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsWithoutSets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten ohne Sätze nicht gezählt',
      one: '1 Einheit ohne Sätze nicht gezählt',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsHeadA11y(String sets, String sessions) {
    return 'Diese Woche, $sets in $sessions';
  }

  @override
  String weeklySetsShiftA11y(String delta, String direction, String avg) {
    return '$delta $direction als der 4-Wochen-Schnitt von $avg';
  }

  @override
  String weeklySetsShiftEqualA11y(String avg) {
    return 'gleich viel wie der 4-Wochen-Schnitt von $avg';
  }

  @override
  String weeklySetsStripA11y(String weeks) {
    return 'Sätze je Woche: $weeks';
  }

  @override
  String weeklySetsWeekA11y(int week, int n) {
    return 'KW $week: $n';
  }

  @override
  String weeklySetsBeforeStartA11y(int week) {
    return 'KW $week: vor deiner ersten Einheit';
  }

  @override
  String weeklySetsAxis(int week) {
    return 'KW $week';
  }

  @override
  String get analysisMaxWhat =>
      'Die Entwicklung deiner stärksten Sätze je Übung, als Schätzung nach Epley.';

  @override
  String analysisMaxCondition(int n, int reps) {
    return 'Ab $n Einheiten mit Gewicht, bis $reps Wdh.';
  }

  @override
  String get analysisMaxBodyweightNote =>
      'Übungen mit Körpergewicht ohne Zusatzgewicht zählen hier nicht — ihre Fortschritte stehen unter „Fortschritte“.';

  @override
  String get wellnessTrendTitle => 'Vorher und nachher';

  @override
  String wellnessTrendWindow(int weeks) {
    return '$weeks Wochen';
  }

  @override
  String get wellnessTrendWhat =>
      'Bereitschaft vor und Gefühl nach jeder Krafteinheit nebeneinander.';

  @override
  String wellnessTrendCondition(int n) {
    return 'Ab $n Einheiten mit beiden Angaben';
  }

  @override
  String get wellnessTrendLegend => 'oben vorher · unten nachher';

  @override
  String wellnessTrendHigher(int n) {
    return '$n nachher höher';
  }

  @override
  String wellnessTrendSame(int n) {
    return '$n gleich';
  }

  @override
  String wellnessTrendLower(int n) {
    return '$n nachher niedriger';
  }

  @override
  String wellnessTrendCountsA11y(int higher, int same, int lower) {
    return 'Nachher höher: $higher. Gleich: $same. Nachher niedriger: $lower.';
  }

  @override
  String wellnessTrendBasis(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total Einheiten',
      one: '1 Einheit',
    );
    return '$n von $_temp0 mit beiden Angaben';
  }

  @override
  String wellnessTrendOnlyOne(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten mit nur einer Angabe sind nicht enthalten',
      one: '1 Einheit mit nur einer Angabe ist nicht enthalten',
    );
    return '$_temp0';
  }

  @override
  String wellnessTrendPair(
      String date, int before, String beforeWord, int after, String afterWord) {
    return '$date: vorher $before $beforeWord, nachher $after $afterWord';
  }

  @override
  String wellnessTrendRowA11y(String pairs) {
    return 'Vorher und nachher je Einheit, älteste zuerst. $pairs';
  }

  @override
  String wellnessTrendOpenExercise(String label) {
    return '$label, öffnet Übung';
  }

  @override
  String get segPlans => 'Pläne';

  @override
  String get planCatalogBody =>
      'Bald findest du hier Pläne von ATEM, frei und als Premium. Deine eigenen Pläne stehen darüber.';

  @override
  String monthsWindow(int n) {
    return '$n Monate';
  }

  @override
  String monthsBasis(int n, int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return '$_temp0 an $_temp1 · seit $date';
  }

  @override
  String monthsEntryA11y(String month, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
      zero: 'keine Einheit',
    );
    return '$month: $_temp0';
  }

  @override
  String monthsNotMeasuredA11y(String month) {
    return '$month: nicht erfasst';
  }

  @override
  String planCardA11y(String name, int n, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Übungen',
      one: '1 Übung',
    );
    return '$name, $_temp0, etwa $minutes Minuten, öffnet Plan';
  }

  @override
  String planCardStartA11y(String name) {
    return 'Starten: $name';
  }

  @override
  String explainOpenA11y(String title) {
    return 'Erklärung zu $title, aufklappen';
  }

  @override
  String explainCloseA11y(String title) {
    return 'Erklärung zu $title, zuklappen';
  }

  @override
  String get balanceExplain =>
      'Anteil der Sätze je Muskel in den letzten 8 Wochen, gezählt über Krafteinheiten mit Übungen. Cardio, Regeneration und Einheiten ohne Übungen tragen nichts bei. Kein Sollverhältnis — die App weiß nicht, wie viel Rücken richtig ist.';

  @override
  String get monthsExplain =>
      'Einheiten je Kalendermonat. Ein Strich heißt: gemessen, keine Einheit. Leer heißt: vor deiner ersten Einheit.';

  @override
  String get historyExplain =>
      'Zuletzt, Bestwert, Häufigkeit und Volumen aus deinen Einheiten mit dieser Übung. Die Kurve erscheint ab 5 Ausführungen — aus weniger Punkten sähe eine Gerade wie ein Trend aus.';

  @override
  String get progressExplainMeasure =>
      'Verglichen wird je Übung mit dem besten Wert aller früheren Ausführungen: Gewicht, wenn du je Zusatzlast hattest, sonst Wiederholungen, sonst Haltezeit. Aufwärmsätze zählen nicht.';

  @override
  String get weeklySetsExplainAverage =>
      'Verglichen wird mit dem Schnitt der 4 vollen Wochen davor — nur Wochen seit deiner ersten Krafteinheit zählen. Aufwärmsätze zählen nicht. Kein Sollwert.';

  @override
  String get focusDistExplainWithout =>
      'Der Anteil rechnet nur über Einheiten, bei denen du beim Start einen Fokus gewählt hast — Einheiten ohne Fokus zählen nicht mit. Kein Sollverhältnis.';

  @override
  String get wellnessTrendExplain =>
      'Oben steht deine Bereitschaft vor der Einheit, unten dein Gefühl danach, je von 1 bis 5. „Höher“ heisst nur höher, nicht besser. Einheiten mit nur einer der beiden Angaben sind nicht enthalten.';

  @override
  String get hybridTimeExplain =>
      'Wie sich deine Trainingsminuten auf Kraft, Cardio und Regeneration verteilen — in dieser Woche oder in den letzten 28 Tagen. Minuten sind die einzige Grösse, die alle drei Spuren teilen.';

  @override
  String get hybridHeatmapExplain =>
      'Jede Kachel ist ein Tag, jede Spalte eine Woche. Die Farbe zeigt, was du an dem Tag trainiert hast. Pausen werden nicht bestraft.';

  @override
  String hybridHeatmapOfDays(int total) {
    return 'von $total Tagen trainiert';
  }

  @override
  String get hybridTimeWeek => 'Diese Woche';

  @override
  String hybridTimeSets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String hybridTimeTonnage(String t) {
    return '$t t Volumen';
  }

  @override
  String hybridTimeBasisShort(int minutes, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return '$minutes min · $_temp0';
  }

  @override
  String get hybridTimeEmptyWeek => 'Diese Woche noch keine Einheit mit Dauer.';

  @override
  String get hybridTimeShiftExplain =>
      'Die Pfeile in „Diese Woche“ vergleichen den Anteil mit dem Schnitt der vier Wochen davor, in Prozentpunkten. Sie erscheinen, sobald deine Einheiten vier Wochen zurückreichen.';

  @override
  String hybridTimeRowShiftA11y(
      String track, int minutes, int n, int percent, String shift) {
    return '$track: $minutes Minuten, $n Einheiten, $percent Prozent, $shift';
  }

  @override
  String weeklySetsWindow(int weeks) {
    return '$weeks Wochen';
  }

  @override
  String get infoTitle => 'Info';

  @override
  String get infoSub => 'Rechtliches und Auskünfte zur App';

  @override
  String infoVersionLine(String version) {
    return 'Version $version';
  }

  @override
  String workoutPreviousShort(String weight, int reps) {
    return '$weight×$reps';
  }

  @override
  String workoutValueEditA11y(String field, int set, String value) {
    return '$field, Satz $set, $value, zum Ändern tippen';
  }

  @override
  String get workoutValueEmpty => 'keine Angabe';

  @override
  String get workoutSetTypeLegendTitle => 'Satztypen';

  @override
  String get workoutFormGuideDescription => 'Kurz gesagt';

  @override
  String get workoutRunnerTableHold => 'HALTEN';

  @override
  String stepPadTitleWeight(int n) {
    return 'GEWICHT · SATZ $n';
  }

  @override
  String stepPadTitleReps(int n) {
    return 'WIEDERHOLUNGEN · SATZ $n';
  }

  @override
  String stepPadTitleHold(int n) {
    return 'HALTEN · SATZ $n';
  }

  @override
  String get stepPadFieldWeight => 'Gewicht in Kilogramm';

  @override
  String get stepPadFieldReps => 'Wiederholungen';

  @override
  String get stepPadFieldHold => 'Haltezeit in Sekunden';

  @override
  String stepPadPrevious(String value) {
    return 'Letztes Mal: $value';
  }

  @override
  String stepPadDelta(String value, String unit) {
    return '$value $unit ZU LETZTEM MAL';
  }

  @override
  String stepPadDeltaA11y(String value, String unit) {
    return '$value $unit gegenüber dem letzten Mal';
  }

  @override
  String get stepPadKeyboard => 'TASTATUR';

  @override
  String get stepPadRuler => 'REGLER';

  @override
  String stepPadKeyboardA11y(String field) {
    return 'Tastatur statt Regler, $field';
  }

  @override
  String stepPadRulerA11y(String field) {
    return 'Regler statt Tastatur, $field';
  }

  @override
  String stepPadHint(String step) {
    return 'ZIEHEN ZUM EINSTELLEN · SCHRITT $step';
  }

  @override
  String get stepPadApply => 'ÜBERNEHMEN';

  @override
  String stepPadStepKg(String step) {
    return '$step kg';
  }

  @override
  String stepPadStepSeconds(String step) {
    return '$step s';
  }

  @override
  String stepPadStepPlain(String step) {
    return '$step';
  }

  @override
  String stepPadStepA11y(String step, String field) {
    return 'Schrittweite $step, $field';
  }

  @override
  String stepPadSliderA11y(String field) {
    return '$field, ziehen zum Einstellen';
  }

  @override
  String get stepPadIncrease => 'Wert erhöhen';

  @override
  String get stepPadDecrease => 'Wert verringern';

  @override
  String stepPadQuickA11y(String value) {
    return 'Um $value ändern';
  }

  @override
  String get stepPadClose => 'Eingabe schliessen';

  @override
  String get workoutRunnerTableSetShort => 'TYP';

  @override
  String get workoutRunnerTableLastShort => 'ZULETZT';

  @override
  String get workoutRunnerTableHoldShort => 'SEK';

  @override
  String get stepPadUnitWeight => 'KG';

  @override
  String get stepPadUnitReps => 'WDH';

  @override
  String get stepPadUnitHold => 'SEK';

  @override
  String get workoutValueNone => '—';

  @override
  String get exerciseUnilateralLabel => 'Je Seite trainiert';

  @override
  String get exerciseUnilateralHint =>
      'Für einseitige Übungen wie Bizeps-Curl mit einer Hantel oder Ausfallschritt — der Runner fragt dann je Satz nach links oder rechts.';

  @override
  String exerciseUnilateralA11y(String label, String state) {
    return '$label, $state';
  }

  @override
  String get exerciseUnilateralMeta => 'je Seite';

  @override
  String get hardSetsTitle => 'Harte Sätze';

  @override
  String hardSetsWindow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String hardSetsCondition(int n) {
    return 'Ab $n Sätzen mit Anstrengung';
  }

  @override
  String get hardSetsExplainWhat =>
      'Ein harter Satz ist einer mit Anstrengung 7 oder mehr auf der Skala 1 bis 10. Die Angabe ist freiwillig und wird beim Abhaken eines Satzes im Runner gewählt.';

  @override
  String get hardSetsExplainWhy =>
      'Gezählt werden Sätze, nicht Kilogramm: So zählt ein Klimmzug am eigenen Körper genauso wie ein Satz mit der Langhantel.';

  @override
  String get hardSetsExplainSides =>
      'Bei einseitigen Übungen sind ein Satz links und einer rechts zusammen ein Satz.';

  @override
  String hardSetsExplainNoTarget(int days) {
    return 'Kein Sollwert — die App weiss nicht, wie viele harte Sätze richtig sind. Die Pfeile vergleichen mit den $days Tagen davor.';
  }

  @override
  String hardSetsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'harte Sätze',
      one: 'harter Satz',
    );
    return '$_temp0';
  }

  @override
  String hardSetsBasis(int hard, int total, int rpe) {
    return '$hard harte von $total Sätzen · $rpe mit Angabe';
  }

  @override
  String hardSetsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n harte Sätze',
      one: '1 harter Satz',
    );
    return '$_temp0';
  }

  @override
  String hardSetsHeadA11y(String count, int days) {
    return '$count in $days Tagen';
  }

  @override
  String hardSetsShiftA11y(int n, String direction, int days) {
    return '$n $direction als in den $days Tagen davor';
  }

  @override
  String hardSetsShiftEqualA11y(int days) {
    return 'gleich viele wie in den $days Tagen davor';
  }

  @override
  String get workoutSideLeftShort => 'L';

  @override
  String get workoutSideRightShort => 'R';

  @override
  String get workoutSideLeft => 'links';

  @override
  String get workoutSideRight => 'rechts';

  @override
  String workoutSideA11y(String side, int n, String other) {
    return 'Seite $side, Satz $n. Tippen wechselt zu $other';
  }

  @override
  String workoutSideDoneA11y(String side, int n) {
    return 'Seite $side, Satz $n';
  }

  @override
  String workoutRpeQuestion(int n) {
    return 'Wie schwer war Satz $n?';
  }

  @override
  String workoutRpeGroupA11y(int n) {
    return 'Anstrengung von Satz $n';
  }

  @override
  String workoutRpeRangeA11y(int from, int to) {
    return 'RPE $from bis $to';
  }

  @override
  String get workoutRpeNone => 'keine Angabe';

  @override
  String workoutRpeNoneA11y(int n) {
    return 'Keine Anstrengung angeben für Satz $n';
  }

  @override
  String get workoutRpeShowLow => '1–5 zeigen';

  @override
  String get workoutRpeHideLow => '1–5 ausblenden';

  @override
  String get workoutRpeShowLowA11y => 'Stufen 1 bis 5 zeigen';

  @override
  String get workoutRpeHideLowA11y => 'Stufen 1 bis 5 ausblenden';

  @override
  String get workoutRpeWordMax => 'Max';

  @override
  String workoutRpeWordReserve(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'noch $n Wdh.',
      one: 'noch 1 Wdh.',
    );
    return '$_temp0';
  }

  @override
  String get workoutRpeWordReserveMany => 'noch 5+';

  @override
  String get workoutRpeWordEasy => 'leicht';

  @override
  String get workoutRpeMaxA11y => 'keine Wiederholung mehr möglich';

  @override
  String workoutRpeReserveA11y(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'noch $n Wiederholungen möglich',
      one: 'noch 1 Wiederholung möglich',
    );
    return '$_temp0';
  }

  @override
  String get workoutRpeReserveManyA11y =>
      'noch 5 oder mehr Wiederholungen möglich';

  @override
  String workoutRpeLevelA11y(int level, String word) {
    return 'RPE $level, $word';
  }

  @override
  String workoutRpeBadge(int rpe) {
    return 'RPE $rpe';
  }

  @override
  String get workoutHardSet => 'harter Satz';

  @override
  String workoutRpeBadgeA11y(int n, int rpe) {
    return 'Satz $n, RPE $rpe. Tippen zum Ändern';
  }

  @override
  String workoutRpeBadgeHardA11y(int n, int rpe) {
    return 'Satz $n, RPE $rpe, harter Satz. Tippen zum Ändern';
  }

  @override
  String get workoutSidesLabel => 'Seiten';

  @override
  String get workoutSidesBoth => 'Beidseitig';

  @override
  String get workoutSidesSplit => 'Getrennt';

  @override
  String get workoutSidesBothA11y => 'Beidseitig, Sätze ohne Seite';

  @override
  String get workoutSidesSplitA11y =>
      'Getrennt, links und rechts je eigene Sätze';

  @override
  String workoutSidesGroupA11y(String name) {
    return 'Seiten für Übung $name';
  }

  @override
  String get platesToggle => 'Scheiben';

  @override
  String get platesToggleShowA11y => 'Scheiben je Seite anzeigen';

  @override
  String get platesToggleHideA11y => 'Scheiben ausblenden';

  @override
  String get platesBarLabel => 'STANGE';

  @override
  String platesBarKg(String kg) {
    return '$kg kg';
  }

  @override
  String platesBarA11y(String kg) {
    return 'Stange $kg Kilogramm';
  }

  @override
  String platesTimes(String count, String plate) {
    return '$count × $plate';
  }

  @override
  String platesPerSide(String plates, String bar) {
    return 'je Seite: $plates · Stange $bar kg';
  }

  @override
  String platesEmptyBar(String bar) {
    return 'Leere Stange · $bar kg';
  }

  @override
  String platesBelowBar(String bar) {
    return 'Leichter als die Stange ($bar kg)';
  }

  @override
  String platesRemainder(String rest, String loaded) {
    return '$rest kg lässt sich nicht stecken — nächster Wert $loaded kg';
  }

  @override
  String platesA11yPlate(int count, String plate) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal $plate',
      one: 'eine $plate',
    );
    return '$_temp0';
  }

  @override
  String platesA11y(String plates, String bar) {
    return 'Scheiben je Seite: $plates. Stange $bar Kilogramm';
  }

  @override
  String platesA11yEmptyBar(String bar) {
    return 'Leere Stange, $bar Kilogramm, keine Scheiben';
  }

  @override
  String platesA11yBelowBar(String bar) {
    return 'Leichter als die Stange mit $bar Kilogramm, keine Scheiben möglich';
  }

  @override
  String platesA11yRemainder(String rest, String loaded) {
    return 'Rest $rest Kilogramm lässt sich nicht stecken, nächster Wert $loaded Kilogramm';
  }

  @override
  String get plansOwnLabel => 'Deine Pläne';

  @override
  String get trainFreeBody => 'Ohne Plan loslegen';

  @override
  String get trainPlanBody => 'Aus deinen Plänen';

  @override
  String workoutRirBadge(int rir) {
    return '$rir RIR';
  }

  @override
  String workoutRirBadgeA11y(int n, int rir) {
    String _temp0 = intl.Intl.pluralLogic(
      rir,
      locale: localeName,
      other: '$rir Wiederholungen in Reserve',
      one: '1 Wiederholung in Reserve',
      zero: 'keine Wiederholung in Reserve',
    );
    return 'Satz $n, $_temp0. Tippen zum Ändern';
  }

  @override
  String workoutRirBadgeHardA11y(int n, int rir) {
    String _temp0 = intl.Intl.pluralLogic(
      rir,
      locale: localeName,
      other: '$rir Wiederholungen in Reserve',
      one: '1 Wiederholung in Reserve',
      zero: 'keine Wiederholung in Reserve',
    );
    return 'Satz $n, $_temp0, harter Satz. Tippen zum Ändern';
  }

  @override
  String workoutRirLevelA11y(int level, String word) {
    return 'RIR $level, $word';
  }

  @override
  String workoutRirRangeA11y(int from, int to) {
    return 'RIR $from bis $to';
  }

  @override
  String get workoutRirShowLow => '5–9 zeigen';

  @override
  String get workoutRirHideLow => '5–9 ausblenden';

  @override
  String get workoutRirShowLowA11y => 'Stufen 5 bis 9 in Reserve zeigen';

  @override
  String get workoutRirHideLowA11y => 'Stufen 5 bis 9 in Reserve ausblenden';

  @override
  String get settingsEffortScale => 'Anstrengung je Satz';

  @override
  String get settingsEffortScaleRpe => 'RPE';

  @override
  String get settingsEffortScaleRir => 'RIR';

  @override
  String get settingsEffortScaleValue => 'RPE — hoch ist schwer';

  @override
  String get settingsEffortScaleValueRir => 'RIR — niedrig ist schwer';

  @override
  String get settingsEffortScaleGroupA11y =>
      'Skala für die Anstrengung je Satz';

  @override
  String get settingsEffortScaleRpeA11y =>
      'RPE, Anstrengung von 1 bis 10, je höher desto schwerer';

  @override
  String get settingsEffortScaleRirA11y =>
      'RIR, Wiederholungen in Reserve, je niedriger desto schwerer';

  @override
  String get settingsEffortScaleExplain =>
      'Dieselbe Angabe, andersherum gezählt. RPE 8 ist 2 RIR: zwei Wiederholungen wären noch drin gewesen. Gespeichert wird immer dasselbe — ein Wechsel ändert nur die Anzeige, auch rückwirkend, und geht jederzeit zurück.';

  @override
  String get hardSetsExplainWhatRir =>
      'Ein harter Satz ist einer mit höchstens 3 Wiederholungen in Reserve. Die Angabe ist freiwillig und wird beim Abhaken eines Satzes im Runner gewählt.';

  @override
  String get analysisLockedBadge => 'Gesperrt';

  @override
  String analysisLockedA11y(String title, String condition, int cur, int req) {
    return '$title: gesperrt. $condition. $cur von $req.';
  }

  @override
  String sectionBarA11y(String name, int n, int total) {
    return 'Thema $name, $n von $total. Öffnet die Themenliste.';
  }

  @override
  String get sectionJumpTitle => 'Springen zu';

  @override
  String sectionJumpA11y(String name, int n, int total) {
    return 'Zu $name springen, $n von $total';
  }

  @override
  String sectionArrivedA11y(String name, int n, int total) {
    return '$name, $n von $total';
  }

  @override
  String get sectionHere => 'HIER';

  @override
  String get trainTodayKicker => 'Heute geplant';

  @override
  String get trainCatalog => 'Übungskatalog';

  @override
  String get trainLogLater => 'Einheit nachtragen';

  @override
  String get historyTotalLabel => 'Erfasste Einheiten';

  @override
  String historyTotalSince(String date) {
    return 'seit $date';
  }

  @override
  String get plansAtemLabel => 'ATEM-Pläne';

  @override
  String get trainFreeTitle => 'Frei starten';

  @override
  String get workoutEffortAdd => 'Anstrengung eintragen';

  @override
  String workoutEffortAddA11y(int n) {
    return 'Satz $n, Anstrengung eintragen';
  }

  @override
  String get settingsEffortScaleRpeLong => 'RPE · Anstrengung';

  @override
  String get settingsEffortScaleRirLong => 'RIR · Wdh. in Reserve';

  @override
  String balanceCondition(int n) {
    return 'Ab $n Einheiten mit Übungen';
  }

  @override
  String get weightBlockTitle => 'Gewicht';

  @override
  String get weightUnitKg => 'KG';

  @override
  String weightEntries(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String weightBasis(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0 seit dem $date';
  }

  @override
  String weightChangeUp(String delta, String date, int days) {
    return '$delta kg seit dem $date · $days Tage her';
  }

  @override
  String weightChangeDown(String delta, String date, int days) {
    return '$delta kg seit dem $date · $days Tage her';
  }

  @override
  String weightChangeUpA11y(String delta, String date, int days) {
    return '$delta Kilogramm mehr seit dem $date, $days Tage her';
  }

  @override
  String weightChangeDownA11y(String delta, String date, int days) {
    return '$delta Kilogramm weniger seit dem $date, $days Tage her';
  }

  @override
  String weightAnchor(String date, String kg) {
    return '$date · $kg kg';
  }

  @override
  String weightLastEntryDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Letzter Eintrag vor $n Tagen',
      one: 'Letzter Eintrag gestern',
      zero: 'Letzter Eintrag heute',
    );
    return '$_temp0';
  }

  @override
  String get weightEnterCta => 'Eintragen';

  @override
  String get weightStartCta => 'Start';

  @override
  String get weightSingleValueTitle => 'Ersten Verlaufswert eintragen';

  @override
  String weightSingleValueNote(String date) {
    return 'Aus der Einrichtung, $date — noch kein zweiter Eintrag.';
  }

  @override
  String weightSingleValueFirst(String date) {
    return 'Erster Eintrag, $date — noch kein zweiter Eintrag.';
  }

  @override
  String get weightSingleValueSeed =>
      'Aus den Einstellungen übernommen — noch kein Verlaufseintrag.';

  @override
  String get weightSingleValueWhy =>
      'Kein Verlauf, keine Kurve: aus einem Wert folgt keine Reihe.';

  @override
  String weightGapNote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wochen ohne Eintrag',
      one: '1 Woche ohne Eintrag',
    );
    return '$_temp0';
  }

  @override
  String weightLastKnown(String date) {
    return 'ZULETZT BEKANNT · $date';
  }

  @override
  String get weightLoadError => 'Verlauf konnte nicht aktualisiert werden.';

  @override
  String get weightRange3m => '3 Mon.';

  @override
  String get weightRange6m => '6 Mon.';

  @override
  String get weightRange1y => '1 Jahr';

  @override
  String get weightRangeAll => 'Alle';

  @override
  String get weightRangeGroup => 'Zeitraum';

  @override
  String weightRangeA11y(String range) {
    return 'Zeitraum $range, ausgewählt';
  }

  @override
  String get weightSheetTitle => 'GEWICHT EINTRAGEN';

  @override
  String get weightSheetEditTitle => 'EINTRAG BEARBEITEN';

  @override
  String weightDateToday(String date) {
    return 'Heute · $date';
  }

  @override
  String get weightDatePick => 'Datum wählen';

  @override
  String weightDateChipA11y(String date) {
    return 'Datum, $date. Ändern.';
  }

  @override
  String weightSameDayNote(String kg) {
    return 'Heute bereits erfasst: $kg kg. Ein zweiter Eintrag ersetzt diesen Wert.';
  }

  @override
  String weightPadPrevious(String kg, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'VOR $days TAGEN',
      one: 'VOR 1 TAG',
      zero: 'HEUTE',
    );
    return 'ZULETZT $kg KG · $_temp0';
  }

  @override
  String get weightUpdateCta => 'Aktualisieren';

  @override
  String weightRetroTitle(String from, String to) {
    return 'WIRKT AUF $from – $to';
  }

  @override
  String get weightRetroScope =>
      'BIS ZUM NÄCHSTEN EINTRAG · NICHT DEN GANZEN VERLAUF';

  @override
  String weightRetroSets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Eigengewichts-Sätze',
      one: '1 Eigengewichts-Satz',
    );
    return '$_temp0';
  }

  @override
  String get weightRetroNone => 'Keine Eigengewichts-Sätze in dieser Spanne';

  @override
  String weightConfirmSnack(String kg, String date) {
    return 'Gewicht $kg kg · $date erfasst';
  }

  @override
  String get weightDeleteEntry => 'Eintrag löschen';

  @override
  String get weightDeleteTitle => 'Eintrag löschen?';

  @override
  String weightDeleteBody(String date, String kg) {
    return '$date · $kg kg. Für diese Tage gilt danach wieder der Wert davor.';
  }

  @override
  String get weightDeleteConfirm => 'Endgültig löschen';

  @override
  String weightDeletedSnack(String date) {
    return 'Eintrag vom $date gelöscht';
  }

  @override
  String get weightSourceTyped => 'Eigene Eingabe';

  @override
  String get weightSourceMeasured => 'Aus Health Connect';

  @override
  String get weightSourceSettings => 'Aus den Einstellungen übernommen';

  @override
  String get weightExplainBody =>
      'Zeigt dein Körpergewicht über Zeit — was war, kein Ziel.';

  @override
  String get weightExplainChange =>
      'Die Veränderung vergleicht immer mit dem letzten Eintrag.';

  @override
  String get weightExplainGaps =>
      'Lücken werden nicht überbrückt: keine Linie ohne einen echten Eintrag dahinter.';

  @override
  String get weightExplainSources =>
      'Gefüllter Punkt: eigene Eingabe. Hohler Punkt: aus Health Connect.';

  @override
  String get weightExplainLoad =>
      'Die Trainingslast einer Einheit rechnet mit dem Gewicht, das an ihrem Tag zuletzt bekannt war.';

  @override
  String get weightHistoryOpen => 'Verlauf öffnen';

  @override
  String weightRowA11y(String date, String kg, String source) {
    return '$date, $kg Kilogramm, $source. Bearbeiten.';
  }

  @override
  String weightChartA11y(int n, String from, String to) {
    return 'Verlauf über $n Einträge, von $from auf $to Kilogramm';
  }

  @override
  String weightChartGapA11y(int n, int weeks, String from, String to) {
    return 'Verlauf über $n Einträge mit einer Lücke von $weeks Wochen, von $from auf $to Kilogramm';
  }

  @override
  String weightChartThinA11y(int n, String from, String to) {
    return '$n Einträge ohne verbundene Kurve, von $from auf $to Kilogramm';
  }

  @override
  String weightCardA11y(String kg, String basis, String change) {
    return 'Gewicht, $kg Kilogramm, $basis, $change';
  }

  @override
  String weightCardSingleA11y(String kg) {
    return 'Gewicht, $kg Kilogramm, noch kein zweiter Eintrag';
  }

  @override
  String get weightCardOpenHint => 'Öffnet den Verlauf';

  @override
  String weightSettingsMeta(String date, String source) {
    return 'Zuletzt $date · $source';
  }

  @override
  String get weightHistoryTitle => 'Gewichtsverlauf';

  @override
  String get weightLoadingA11y => 'Gewichtsverlauf lädt';

  @override
  String hcInboxTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten aus Health Connect',
      one: '1 Einheit aus Health Connect',
    );
    return '$_temp0';
  }

  @override
  String hcInboxMeta(String time) {
    return 'Gelesen $time · warten auf Prüfung';
  }

  @override
  String get hcInboxAction => 'Prüfen';

  @override
  String get hcRowUnreviewed => 'Ungeprüft · zählt noch nicht';

  @override
  String hcSheetTitle(int i, int n) {
    return 'Einheit prüfen · $i von $n';
  }

  @override
  String get hcFieldDuration => 'Dauer';

  @override
  String get hcFieldHrAvg => 'Ø Puls';

  @override
  String get hcFieldHrMax => 'Max';

  @override
  String hcMoreDeviceValues(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Weitere Angaben vom Gerät · $n',
      one: '1 weitere Angabe vom Gerät',
    );
    return '$_temp0';
  }

  @override
  String get hcAccept => 'Übernehmen';

  @override
  String get hcAcceptWithoutEffort => 'Ohne Anstrengung übernehmen';

  @override
  String get hcDecline => 'Nicht übernehmen';

  @override
  String get hcNoEffortNote =>
      'Ohne Anstrengung fehlt diese Einheit in der Trainingslast — sie wird nicht geschätzt.';

  @override
  String get hcContinueLater => 'Später fortsetzen';

  @override
  String get hcDeclinedSection => 'Abgelehnt';

  @override
  String hcDeclinedMeta(String date) {
    return 'Abgelehnt am $date';
  }

  @override
  String get hcDeclinedRestore => 'Doch übernehmen';

  @override
  String get hcDeclinedNote =>
      'Wird beim nächsten Lesen nicht erneut vorgeschlagen.';

  @override
  String get hcOriginWatch => 'aus der Uhr';

  @override
  String get hcOriginBoth => 'App + Uhr';

  @override
  String get hcOriginMissingEffort => 'ohne Anstrengung';

  @override
  String get hcReadError => 'Health Connect nicht erreichbar';

  @override
  String hcReadErrorMeta(String date) {
    return 'Zuletzt gelesen $date';
  }

  @override
  String get hcRetry => 'Erneut';

  @override
  String get hcReading => 'Health Connect wird gelesen';

  @override
  String hcRowA11y(String title, String meta) {
    return '$title, $meta, aus der Uhr, ungeprüft, zählt noch nicht. Prüfen.';
  }

  @override
  String hcInboxA11y(String count, String time) {
    return '$count warten auf Prüfung, gelesen $time. Prüfen.';
  }

  @override
  String get hcPairQuestion => 'Gehört das zu deiner Krafteinheit?';

  @override
  String get hcPairAppRow => 'Deine App-Einheit';

  @override
  String get hcPairWatchRow => 'Aus der Uhr';

  @override
  String hcPairOverlap(int x, int y, int d) {
    return 'Überlappung $x von $y min der kürzeren Einheit · Start $d min auseinander';
  }

  @override
  String get hcPairMerge => 'Zusammenführen';

  @override
  String get hcPairKeepApart => 'Getrennt lassen';

  @override
  String get hcMergeStage1Title => 'Zusammenführen — das ändert sich';

  @override
  String get hcUnlinkStage1Title => 'Verbindung lösen — das ändert sich';

  @override
  String hcMergeStays(String value) {
    return '$value bleibt';
  }

  @override
  String hcMergeGains(String value) {
    return 'wird $value';
  }

  @override
  String get hcMergeLoses => 'entfällt';

  @override
  String hcMergeDurationNote(int app, int watch) {
    return 'Dauer bleibt bei der App: $app min. Die Uhr meldet $watch min.';
  }

  @override
  String get hcMergedSnack => 'Zusammengeführt · Puls übernommen';

  @override
  String get hcUnlinkedSnack =>
      'Verbindung gelöst · Uhr-Einheit zurück im Eingang';

  @override
  String get hcAmbiguousNote =>
      'Mehrere App-Einheiten liegen in diesem Zeitraum. ATEM ordnet nicht zu, wenn die Zuordnung nicht eindeutig ist.';

  @override
  String get hcAmbiguousPick => 'Wählen';

  @override
  String get hcAmbiguousStandalone => 'Als eigene Einheit prüfen';

  @override
  String get hcUnlink => 'Verbindung lösen';

  @override
  String get hcSourcesLabel => 'Quellen';

  @override
  String get hcSourceApp => 'App · Sätze, Dauer, Anstrengung';

  @override
  String hcSourceWatch(String device) {
    return '$device · Puls, Kalorien';
  }

  @override
  String hcWatchReports(String start, String end, int min) {
    return 'Uhr meldet $start–$end · $min min';
  }

  @override
  String get hcFieldSets => 'Sätze';

  @override
  String get hcFieldEffort => 'Anstrengung';

  @override
  String get hcFieldWatchSession => 'Uhr-Einheit';

  @override
  String get hcBackToInbox => 'zurück in den Eingang';

  @override
  String get hcPermSection => 'Health Connect';

  @override
  String get hcPermWeight => 'Körpergewicht';

  @override
  String get hcPermSessions => 'Trainingseinheiten';

  @override
  String get hcPermGrant => 'Freigeben';

  @override
  String get hcPermInstall => 'Installieren';

  @override
  String get hcStateDenied => 'Nicht freigegeben';

  @override
  String get hcPermMissingNote =>
      'Health Connect ist auf diesem Gerät nicht eingerichtet. ATEM funktioniert ohne — Gewicht und Einheiten werden von Hand geführt.';

  @override
  String get hcPermNoneNote =>
      'Nichts freigegeben. ATEM liest erst, wenn du es je Datentyp erlaubst.';

  @override
  String get hcPermPartialNote =>
      'Gewicht wird gelesen, Einheiten nicht. Der Eingang im Verlauf erscheint erst mit der zweiten Freigabe.';

  @override
  String hcPermRevokedNote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n übernommene Einheiten bleiben, wie sie sind.',
      one: '1 übernommene Einheit bleibt, wie sie ist.',
    );
    return '$_temp0 Neue werden nicht mehr gelesen.';
  }

  @override
  String get hcOriginBothSpoken => 'App und Uhr';

  @override
  String get hcUndatedQuestion => 'Gehört das zu einer deiner Einheiten?';

  @override
  String get hcUndatedNote =>
      'ATEM kennt die Uhrzeit dieser Einheiten nicht und vermutet deshalb nichts.';

  @override
  String get detailBack => 'Verlauf';

  @override
  String get detailKindStrength => 'Kraft';

  @override
  String get detailKindBodyweight => 'Körpergewicht';

  @override
  String get detailKindEndurance => 'Ausdauer';

  @override
  String get detailKindRecovery => 'Regeneration';

  @override
  String detailTimeRange(String day, String date, String start, String end) {
    return '$day $date · $start–$end';
  }

  @override
  String detailTimeNoDuration(String day, String date) {
    return '$day $date · keine Dauer erfasst';
  }

  @override
  String get detailLeadSets => 'Sätze';

  @override
  String get detailLeadVolume => 'kg';

  @override
  String get detailLeadDistance => 'km';

  @override
  String get detailLeadDuration => 'min';

  @override
  String detailBasisStrength(int n, int dur, int rpe) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Übungen',
      one: '$n Übung',
    );
    return '$_temp0 · $dur min · Anstrengung $rpe von 5';
  }

  @override
  String detailBasisRun(int dur, String pace) {
    return '$dur min · $pace /km im Schnitt';
  }

  @override
  String detailBasisRecovery(String name) {
    return 'ohne Last · $name';
  }

  @override
  String get detailBasisEmpty => 'Nur Art und Tag sind bekannt.';

  @override
  String get detailNoEffort => 'ohne Anstrengung';

  @override
  String get detailMetricDuration => 'Dauer';

  @override
  String get detailMetricVolume => 'Volumen';

  @override
  String get detailMetricHrAvg => 'Ø Puls';

  @override
  String get detailMetricCalories => 'Kalorien';

  @override
  String get detailMetricElevation => 'Höhenmeter';

  @override
  String detailBlockWorkStrength(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Übungen · $n',
      one: 'Übung · $n',
    );
    return '$_temp0';
  }

  @override
  String get detailBlockHr => 'Puls';

  @override
  String get detailBlockNote => 'Notiz';

  @override
  String detailDeltaVs(String glyph, String value, String date) {
    return '$glyph $value gegen $date';
  }

  @override
  String detailZonesBasis(int min, int total, String date) {
    return 'Aus $min von $total min Aufzeichnung · deine Zonen vom $date';
  }

  @override
  String detailZonesThin(int min, int total) {
    return 'Nur $min von $total min aufgezeichnet — die Verteilung beschreibt diesen Teil, nicht die Einheit.';
  }

  @override
  String get detailZonesUnset =>
      'Zonen sind nicht festgelegt. ATEM rechnet keine Verteilung, solange die Grenzen fehlen.';

  @override
  String get detailZonesSetAction => 'Zonen festlegen';

  @override
  String detailZoneName(int n) {
    return 'Zone $n';
  }

  @override
  String detailZoneRangeUpto(int bpm) {
    return 'bis $bpm bpm';
  }

  @override
  String detailZoneRangeFrom(int bpm) {
    return 'ab $bpm bpm';
  }

  @override
  String detailZoneRange(int from, int to) {
    return '$from–$to bpm';
  }

  @override
  String get detailExplainZones =>
      'Gerechnet aus dem Pulsverlauf der Uhr: jede Sekunde zählt in die Zone, in der sie liegt. Kein Sollwert — die Verteilung beschreibt, was war.';

  @override
  String get detailExplainVolume =>
      'Summe aus Wiederholungen × Gewicht aller Sätze mit Gewichtsangabe. Sätze ohne Gewicht fehlen im Volumen und stehen im Nenner.';

  @override
  String get detailErrorHr => 'Puls nicht lesbar';

  @override
  String get detailRetry => 'Erneut';

  @override
  String get detailEdit => 'Einheit bearbeiten';

  @override
  String get detailDelete => 'Einheit löschen';

  @override
  String get settingsZonesTitle => 'Herzfrequenzzonen';

  @override
  String settingsZonesStateSet(String date) {
    return 'Festgelegt am $date';
  }

  @override
  String get settingsZonesStateUnset => 'Offen';

  @override
  String settingsZonesBasisPct(int hrmax) {
    return '% von HFmax $hrmax';
  }

  @override
  String get settingsZonesBasisBpm => 'Absolute bpm';

  @override
  String get settingsZonesProposal => 'Vorschlag aus HFmax rechnen';

  @override
  String get settingsZonesProposalNote =>
      'Ein Startpunkt, keine Empfehlung. Jede Grenze bleibt einzeln änderbar.';

  @override
  String settingsZonesBoundary(int n, int a, int b) {
    return 'Grenze $n · zwischen Zone $a und Zone $b';
  }

  @override
  String settingsZonesBoundaryLimit(int bpm) {
    return 'Höchstens $bpm bpm — die nächste Grenze liegt darüber.';
  }

  @override
  String get settingsZonesRetro =>
      'Gilt auch für vergangene Einheiten: Zonen werden aus dem gespeicherten Pulsverlauf gerechnet, nicht beim Import festgeschrieben.';

  @override
  String get settingsZonesNoHrmax =>
      'HFmax fehlt. Prozentgrenzen brauchen einen Wert — oder du legst die Grenzen in bpm fest.';

  @override
  String get settingsZonesSaved => 'Zonen gespeichert';

  @override
  String get settingsZonesSetBounds => 'Grenzen in bpm festlegen';

  @override
  String get settingsZonesHrMaxEnter => 'HFmax eintragen';

  @override
  String settingsZonesHrMaxLine(int hrmax, String date) {
    return 'HFmax $hrmax · selbst eingetragen am $date';
  }

  @override
  String get settingsZonesUnsetNote =>
      'Nicht festgelegt. Ohne Grenzen zeigt eine Einheit ihren Puls, aber keine Verteilung.';

  @override
  String get settingsZonesKeepNote =>
      'Bestehende Grenzen bleiben unverändert, solange nichts gespeichert wird.';

  @override
  String settingsZonesBasisNotePct(int hrmax) {
    return 'HFmax $hrmax selbst eingetragen. Gespeichert werden immer bpm; die Prozente sind daraus gerechnet.';
  }

  @override
  String get settingsZonesBasisNoteBpm =>
      'Grenzen direkt in bpm. Ohne HFmax — nichts wird umgerechnet.';

  @override
  String settingsZonesBoundaryTitle(int n) {
    return 'Grenze $n';
  }

  @override
  String settingsZonesStepperCaption(int pct, int hrmax) {
    return 'bpm · $pct % von $hrmax';
  }

  @override
  String get settingsZonesStepperCaptionBpm => 'bpm';

  @override
  String get settingsZonesMinusA11y => 'Minus 1 bpm';

  @override
  String get settingsZonesPlusA11y => 'Plus 1 bpm';

  @override
  String settingsZonesLowerLimit(int bpm) {
    return 'Mindestens $bpm bpm — die vorige Grenze liegt darunter.';
  }

  @override
  String settingsZonesLastSession(String date) {
    return 'Minuten rechts: Einheit vom $date';
  }

  @override
  String settingsZonesRowA11y(String state) {
    return '$state. Öffnen.';
  }

  @override
  String get settingsZonesHrMaxTitle => 'Maximalpuls';

  @override
  String get settingsZonesHrMaxField => 'HFmax in bpm';

  @override
  String settingsZonesHrMaxRange(int min, int max) {
    return 'Zwischen $min und $max bpm. ATEM schätzt HFmax nicht aus dem Alter.';
  }

  @override
  String get settingsZonesHrMaxSave => 'HFmax speichern';

  @override
  String settingsZonesHrMaxInvalid(int min, int max) {
    return 'HFmax speichern, nicht möglich, Wert zwischen $min und $max nötig';
  }

  @override
  String settingsZonesHrMaxA11y(int hrmax, String date) {
    return 'HFmax $hrmax, selbst eingetragen am $date. Ändern.';
  }

  @override
  String get settingsZonesBoundsTitle => 'Grenzen festlegen';

  @override
  String get settingsZonesBoundsRule =>
      'Jede Grenze ist der erste Pulswert der oberen Zone und liegt über der vorigen.';

  @override
  String settingsZonesBoundsField(int n) {
    return 'Grenze $n in bpm';
  }

  @override
  String settingsZonesBoundsInvalid(int n, int m) {
    return 'Speichern, nicht möglich, Grenze $n muss über Grenze $m liegen';
  }

  @override
  String settingsZonesBoundsMissing(int n) {
    return 'Speichern, nicht möglich, noch $n Grenzen fehlen';
  }

  @override
  String get settingsZonesProposalDone =>
      'Vorschlag übernommen. Jede Grenze bleibt einzeln änderbar.';

  @override
  String settingsZonesBetween(int a, int b) {
    return 'zwischen Zone $a und Zone $b';
  }

  @override
  String get detailUnitBpm => 'bpm';

  @override
  String get detailUnitKcal => 'kcal';

  @override
  String get detailUnitHm => 'hm';

  @override
  String detailBasisExercises(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Übungen',
      one: '$n Übung',
    );
    return '$_temp0';
  }

  @override
  String detailBasisEffort(int rpe) {
    return 'Anstrengung $rpe von 5';
  }

  @override
  String get detailSpokenHrAvg => 'Durchschnittspuls';

  @override
  String get detailSpokenHrMax => 'Maximalpuls';

  @override
  String get detailSpokenHrMin => 'Minimalpuls';

  @override
  String get detailSpokenLoad => 'Last';

  @override
  String detailSpokenTile(
      String label, String value, String unit, String source) {
    return '$label $value $unit, $source';
  }

  @override
  String get detailSourceApp => 'aus der App';

  @override
  String get detailHrAvgShort => 'Ø';

  @override
  String get detailHrMaxShort => 'Max';

  @override
  String get detailHrMinShort => 'Min';

  @override
  String get detailBlockHrZones => 'Puls & Zonen';

  @override
  String detailZoneShort(int n) {
    return 'Z$n';
  }

  @override
  String detailZoneSpokenRange(int from, int to) {
    return '$from bis $to bpm';
  }

  @override
  String detailZoneA11y(int n, String range, String time, int total) {
    return 'Zone $n, $range, $time von $total Minuten';
  }

  @override
  String detailZoneTimeSpoken(int min, int sec) {
    return '$min Minuten $sec';
  }

  @override
  String detailZonesGroupA11y(int min, int total, String date) {
    return 'Zeit in Zonen, aus $min von $total Minuten Aufzeichnung, deine Zonen vom $date';
  }

  @override
  String detailHrBasisNoZones(int min, int total) {
    return 'Aus $min von $total min Aufzeichnung';
  }

  @override
  String get detailHrLoading => 'Puls wird geladen';

  @override
  String get detailErrorHrBody => 'Der Uhr-Datensatz antwortet nicht.';

  @override
  String detailHrLastRead(String date) {
    return 'Zuletzt gelesen $date';
  }

  @override
  String detailWorkMore(int n) {
    return '+ $n weitere';
  }

  @override
  String get detailWorkNoComparison => 'ohne Vergleich';

  @override
  String detailWorkSets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Sätze',
      one: '$n Satz',
    );
    return '$_temp0';
  }

  @override
  String detailDeltaWeight(String n) {
    return '$n kg';
  }

  @override
  String detailDeltaReps(String n) {
    return '$n Wdh';
  }

  @override
  String get detailDeltaSame => 'gleich';

  @override
  String detailDeltaSpokenMore(String value, String date) {
    return '$value mehr als am $date';
  }

  @override
  String detailDeltaSpokenLess(String value, String date) {
    return '$value weniger als am $date';
  }

  @override
  String detailDeltaSpokenSame(String date) {
    return 'gleich wie am $date';
  }

  @override
  String detailSpokenKg(String n) {
    return '$n Kilogramm';
  }

  @override
  String detailSpokenReps(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wiederholungen',
      one: '$n Wiederholung',
    );
    return '$_temp0';
  }

  @override
  String detailExerciseA11y(
      String name, String sets, String best, String delta) {
    return '$name, $sets, bestes $best$delta. Sätze anzeigen.';
  }

  @override
  String get detailExerciseHistory => 'Übungsverlauf';

  @override
  String detailSetRow(int n, String detail) {
    return 'Satz $n · $detail';
  }

  @override
  String get detailOriginApp => 'Selbst geführt';

  @override
  String get detailOriginWatch => 'Aus der Uhr übernommen';

  @override
  String get detailOriginBoth => 'App + Uhr · zusammengeführt';

  @override
  String get detailOriginMetaApp => 'App · alle Werte';

  @override
  String get detailOriginMetaEmpty => 'App · nur Art und Tag';

  @override
  String get detailOriginMetaMerged => 'App: Sätze, Dauer · Uhr: Puls, kcal';

  @override
  String detailOriginMetaWatch(String device) {
    return '$device · alle Werte';
  }

  @override
  String get detailOriginA11yBoth =>
      'Herkunft: App und Uhr, zusammengeführt. App liefert Sätze und Dauer, Uhr liefert Puls und Kalorien.';

  @override
  String get detailAddEffort => 'Anstrengung nachtragen';

  @override
  String get detailBackA11y => 'Zurück zum Verlauf';

  @override
  String get detailLoadingA11y => 'Einheit wird geladen';

  @override
  String detailTimeDayOnly(String day, String date) {
    return '$day $date';
  }

  @override
  String get detailBasisNoLoad => 'ohne Last';

  @override
  String get zoneFiveTitle => 'Zone 5 je Woche';

  @override
  String get zoneFiveConditionZones =>
      'Ab festgelegten Zonen und einer Einheit mit Puls';

  @override
  String get zoneFiveConditionPulse => 'Ab einer Einheit mit Puls aus der Uhr';

  @override
  String zoneFiveWhat(int bpm) {
    return 'Die Minuten, in denen dein Puls in Zone 5 lag — ab $bpm bpm, nach deinen Grenzen. Je Woche summiert, aus den Einheiten mit Puls aus der Uhr.';
  }

  @override
  String get zoneFiveExplainNoTarget =>
      'Kein Sollwert: Mehr Zeit in Zone 5 ist nicht besser, weniger nicht schlechter. Ändern sich deine Grenzen, rechnet sich jede Woche neu.';

  @override
  String zoneFiveHead(int week, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten mit Puls',
      one: '1 Einheit mit Puls',
    );
    return 'KW $week · $_temp0';
  }

  @override
  String zoneFiveBasis(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m Einheiten',
      one: '1 Einheit',
    );
    return 'aus $n von $_temp0 · Puls aus der Uhr';
  }

  @override
  String get zoneFiveNoPulseThisWeek => 'Diese Woche ohne Puls';

  @override
  String zoneFiveStripA11y(String weeks) {
    return 'Zone 5 je Woche: $weeks';
  }

  @override
  String zoneFiveWeekA11y(int week, int min) {
    return 'Kalenderwoche $week, $min Minuten in Zone 5';
  }

  @override
  String zoneFiveWeekZeroA11y(int week) {
    return 'Kalenderwoche $week, gemessen, keine Zeit in Zone 5';
  }

  @override
  String zoneFiveWeekNoneA11y(int week) {
    return 'Kalenderwoche $week, kein Puls aufgezeichnet';
  }

  @override
  String get balanceTitleShort => 'Balance';

  @override
  String weeklySetsLine(int week, int n, String avg) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return 'KW $week · $_temp0 · Ø $avg aus 4 Wochen';
  }

  @override
  String weeklySetsLinePending(int week, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einheiten',
      one: '1 Einheit',
    );
    return 'KW $week · $_temp0 · Vergleich ab 2 vollen Wochen';
  }
}
