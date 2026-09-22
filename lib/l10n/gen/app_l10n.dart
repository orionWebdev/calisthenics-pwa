import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_l10n_de.dart';
import 'app_l10n_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Board 08, ueber
  ///
  /// In de, this message translates to:
  /// **'Zugang'**
  String get aboutAccessLabel;

  /// about.access.value
  ///
  /// In de, this message translates to:
  /// **'Freigeschaltete Adresse'**
  String get aboutAccessValue;

  /// Board 08, ueber
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get aboutDisplayLabel;

  /// Board 08, ueber — steht dort, wo sonst ein Schalter wäre
  ///
  /// In de, this message translates to:
  /// **'Dunkel · keine helle Fassung'**
  String get aboutDisplayValue;

  /// Board 08, ueber
  ///
  /// In de, this message translates to:
  /// **'Sprachen'**
  String get aboutLanguagesLabel;

  /// Board 08, ueber
  ///
  /// In de, this message translates to:
  /// **'Deutsch · English'**
  String get aboutLanguagesValue;

  /// account.delete
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get accountDelete;

  /// account.delete2.body
  ///
  /// In de, this message translates to:
  /// **'{y} Jahre {m} Monate, {n} Einheiten und {e} eigene Übungen. Es gibt kein Rückgängig und kein Zeitfenster.'**
  String accountDelete2Body(int y, int m, int n, int e);

  /// account.delete2.title
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get accountDelete2Title;

  /// account.delete2.typeLabel
  ///
  /// In de, this message translates to:
  /// **'Tippe „LÖSCHEN\", um zu bestätigen'**
  String get accountDelete2TypeLabel;

  /// account.delete2.typeWord
  ///
  /// In de, this message translates to:
  /// **'LÖSCHEN'**
  String get accountDelete2TypeWord;

  /// account.delete.access
  ///
  /// In de, this message translates to:
  /// **'Dein Zugang bleibt. Du kannst dich danach wieder anmelden — die App startet dann leer und beim Onboarding.'**
  String get accountDeleteAccess;

  /// account.delete.body
  ///
  /// In de, this message translates to:
  /// **'Das löscht deinen gesamten Bestand. Zahlen von heute:'**
  String get accountDeleteBody;

  /// account.delete.continue
  ///
  /// In de, this message translates to:
  /// **'Weiter zum Löschen'**
  String get accountDeleteContinue;

  /// account.delete.export
  ///
  /// In de, this message translates to:
  /// **'Daten vorher ausgeben'**
  String get accountDeleteExport;

  /// account.delete.range
  ///
  /// In de, this message translates to:
  /// **'Zeitraum'**
  String get accountDeleteRange;

  /// Zeitraum des Bestands: Jahre und Monate
  ///
  /// In de, this message translates to:
  /// **'{y} J {m} M'**
  String accountDeleteSpan(int y, int m);

  /// Zeile in der Folgenliste der Kontolöschung
  ///
  /// In de, this message translates to:
  /// **'Fortschritt und Bestwerte'**
  String get accountRowProgress;

  /// Zeile in der Folgenliste der Kontolöschung
  ///
  /// In de, this message translates to:
  /// **'Profil und Einstellungen'**
  String get accountRowProfile;

  /// account.delete.sub
  ///
  /// In de, this message translates to:
  /// **'Sechs Sammlungen · kein Widerruf'**
  String get accountDeleteSub;

  /// account.deleting
  ///
  /// In de, this message translates to:
  /// **'Konto wird gelöscht'**
  String get accountDeleting;

  /// account.deleting.wait
  ///
  /// In de, this message translates to:
  /// **'Nicht abbrechbar. Das dauert einen Moment.'**
  String get accountDeletingWait;

  /// account.done.access.body
  ///
  /// In de, this message translates to:
  /// **'Deine Freischaltung für ATEM gilt weiter. Meldest du dich mit derselben Adresse neu an, bist du wieder drin — mit leerem Bestand und im Onboarding.'**
  String get accountDoneAccessBody;

  /// account.done.access.title
  ///
  /// In de, this message translates to:
  /// **'Eine Sache bleibt'**
  String get accountDoneAccessTitle;

  /// account.done.body
  ///
  /// In de, this message translates to:
  /// **'Deine Einheiten, Pläne, Übungen, Termine und dein Fortschritt sind gelöscht. Das Anmeldekonto ist entfernt.'**
  String get accountDoneBody;

  /// account.done.title
  ///
  /// In de, this message translates to:
  /// **'Konto gelöscht'**
  String get accountDoneTitle;

  /// account.done.toLogin
  ///
  /// In de, this message translates to:
  /// **'Zur Anmeldung'**
  String get accountDoneToLogin;

  /// account.partial.body
  ///
  /// In de, this message translates to:
  /// **'{a} von {b} Sammlungen sind weg, das Anmeldekonto besteht noch.'**
  String accountPartialBody(int a, int b);

  /// account.partial.resume
  ///
  /// In de, this message translates to:
  /// **'Löschen fortsetzen'**
  String get accountPartialResume;

  /// account.partial.title
  ///
  /// In de, this message translates to:
  /// **'Nicht vollständig gelöscht'**
  String get accountPartialTitle;

  /// activity.bike
  ///
  /// In de, this message translates to:
  /// **'Rad'**
  String get activityBike;

  /// activity.bike.indoor
  ///
  /// In de, this message translates to:
  /// **'Indoor-Rad'**
  String get activityBikeIndoor;

  /// activity.hike
  ///
  /// In de, this message translates to:
  /// **'Wandern'**
  String get activityHike;

  /// activity.more
  ///
  /// In de, this message translates to:
  /// **'Weitere'**
  String get activityMore;

  /// activity.other
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get activityOther;

  /// activity.own
  ///
  /// In de, this message translates to:
  /// **'Deine Aktivitäten · {n, plural, one{1 Einheit} other{{n} Einheiten}}'**
  String activityOwn(int n);

  /// activity.row
  ///
  /// In de, this message translates to:
  /// **'Rudern'**
  String get activityRow;

  /// activity.run
  ///
  /// In de, this message translates to:
  /// **'Laufen'**
  String get activityRun;

  /// activity.swim
  ///
  /// In de, this message translates to:
  /// **'Schwimmen'**
  String get activitySwim;

  /// activity.walk
  ///
  /// In de, this message translates to:
  /// **'Gehen'**
  String get activityWalk;

  /// analysis.dist.basis
  ///
  /// In de, this message translates to:
  /// **'{n} von {total} Einheiten mit Distanz'**
  String analysisDistBasis(int n, int total);

  /// analysis.dist.title
  ///
  /// In de, this message translates to:
  /// **'Verteilung der Distanzen'**
  String get analysisDistTitle;

  /// Erfasstes und Abgeleitetes fallen getrennt aus
  ///
  /// In de, this message translates to:
  /// **'Deine {n} Einheiten sind vollständig da — nur die Auswertung fehlt.'**
  String analysisErrorBody(int n);

  /// Aktion im Fehlerzustand
  ///
  /// In de, this message translates to:
  /// **'Neu berechnen'**
  String get analysisErrorRetry;

  /// Erfasstes und Abgeleitetes fallen getrennt aus
  ///
  /// In de, this message translates to:
  /// **'Form nicht berechenbar'**
  String get analysisErrorTitle;

  /// Ausweg im Fehlerzustand
  ///
  /// In de, this message translates to:
  /// **'Zur Liste'**
  String get analysisErrorToList;

  /// analysis.pace.basis
  ///
  /// In de, this message translates to:
  /// **'gegen eigenen Schnitt {value} · {n, plural, one{1 Lauf} other{{n} Läufe}}'**
  String analysisPaceBasis(String value, int n);

  /// analysis.pace.thin
  ///
  /// In de, this message translates to:
  /// **'Keine Kurve unter {min} Einheiten dieser Aktivität. Schnitt {value}, Spanne {from} bis {to}.'**
  String analysisPaceThin(int min, String value, String from, String to);

  /// analysis.pace.title
  ///
  /// In de, this message translates to:
  /// **'Tempoentwicklung'**
  String get analysisPaceTitle;

  /// analysis.pct.faster
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{Schneller als 1 deiner Läufe} other{Schneller als {n} von {total} deiner Läufe}}'**
  String analysisPctFaster(int n, int total);

  /// analysis.pct.noothers
  ///
  /// In de, this message translates to:
  /// **'Kein Vergleich mit anderen Menschen.'**
  String get analysisPctNoothers;

  /// analysis.weekly.basis
  ///
  /// In de, this message translates to:
  /// **'Ø {value} km · {n, plural, one{1 Einheit} other{{n} Einheiten}}'**
  String analysisWeeklyBasis(String value, int n);

  /// analysis.weekly.current
  ///
  /// In de, this message translates to:
  /// **'laufend'**
  String get analysisWeeklyCurrent;

  /// analysis.weekly.title
  ///
  /// In de, this message translates to:
  /// **'Wochenkilometer'**
  String get analysisWeeklyTitle;

  /// Pille über dem Anmeldeknopf
  ///
  /// In de, this message translates to:
  /// **'GESCHLOSSENE BETA'**
  String get authBetaBadge;

  /// Fehlercode in der Notice — gehört ins Semantics-Label, damit er am Telefon vorlesbar ist
  ///
  /// In de, this message translates to:
  /// **'CODE {code}'**
  String authErrorCode(String code);

  /// Notice-Text bei unbekanntem Fehler
  ///
  /// In de, this message translates to:
  /// **'Versuch es gleich noch einmal.'**
  String get authFailedBody;

  /// Notice-Titel bei unbekanntem Fehler
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt'**
  String get authFailedTitle;

  /// Beschriftung des Anmeldeknopfes
  ///
  /// In de, this message translates to:
  /// **'Mit Google anmelden'**
  String get authGoogle;

  /// Rechtlicher Hinweis unter dem Anmeldeknopf
  ///
  /// In de, this message translates to:
  /// **'Mit der Anmeldung akzeptierst du Nutzungsbedingungen und Datenschutzerklärung.'**
  String get authLegal;

  /// Notice-Text ohne Netz
  ///
  /// In de, this message translates to:
  /// **'Anmeldung braucht Internet.'**
  String get authNetworkBody;

  /// Notice-Titel ohne Netz
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung'**
  String get authNetworkTitle;

  /// Zustand während der Anmeldung
  ///
  /// In de, this message translates to:
  /// **'Anmeldung läuft …'**
  String get authSigningIn;

  /// balance.basis
  ///
  /// In de, this message translates to:
  /// **'{sets} Sätze · {n} von {total} Kraft-Einheiten'**
  String balanceBasis(int sets, int n, int total);

  /// balance.col.last
  ///
  /// In de, this message translates to:
  /// **'zuletzt vor'**
  String get balanceColLast;

  /// balance.col.sets
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get balanceColSets;

  /// balance.col.share
  ///
  /// In de, this message translates to:
  /// **'Anteil'**
  String get balanceColShare;

  /// balance.gaps.note
  ///
  /// In de, this message translates to:
  /// **'Abstand seit dem letzten Satz auf diesen Muskel. Kein Sollwert — die App weiß nicht, wie oft er dran sein sollte.'**
  String get balanceGapsNote;

  /// balance.gaps.title
  ///
  /// In de, this message translates to:
  /// **'Längste Abstände'**
  String get balanceGapsTitle;

  /// balance.last.days
  ///
  /// In de, this message translates to:
  /// **'{n} T'**
  String balanceLastDays(int n);

  /// balance.last.days.long
  ///
  /// In de, this message translates to:
  /// **'zuletzt {n} T'**
  String balanceLastDaysLong(int n);

  /// balance.thin
  ///
  /// In de, this message translates to:
  /// **'Noch zu wenig Grundlage: {n} von {min} Krafteinheiten mit Übungen in den letzten 8 Wochen.'**
  String balanceThin(int n, int min);

  /// balance.thin.progress
  ///
  /// In de, this message translates to:
  /// **'{n} / {min} · noch {rest} Einheiten'**
  String balanceThinProgress(int n, int min, int rest);

  /// balance.title
  ///
  /// In de, this message translates to:
  /// **'Muskelbalance'**
  String get balanceTitle;

  /// balance.window
  ///
  /// In de, this message translates to:
  /// **'8 Wochen'**
  String get balanceWindow;

  /// cardio.add
  ///
  /// In de, this message translates to:
  /// **'Einheit erfassen'**
  String get cardioAdd;

  /// cardio.add.first
  ///
  /// In de, this message translates to:
  /// **'Erste Einheit erfassen'**
  String get cardioAddFirst;

  /// cardio.empty.body
  ///
  /// In de, this message translates to:
  /// **'Erfasse einen Lauf, eine Radfahrt oder eine Wanderung. Ab der zweiten Einheit derselben Aktivität steht hier die Tempoentwicklung.'**
  String get cardioEmptyBody;

  /// cardio.empty.title
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausdauereinheit'**
  String get cardioEmptyTitle;

  /// cardio.live.start
  ///
  /// In de, this message translates to:
  /// **'Live mitlaufen lassen'**
  String get cardioLiveStart;

  /// cardio.total.since
  ///
  /// In de, this message translates to:
  /// **'Gesamt · seit {date}'**
  String cardioTotalSince(String date);

  /// cardio.week.basis
  ///
  /// In de, this message translates to:
  /// **'gegen 4-Wochen-Schnitt {value} km'**
  String cardioWeekBasis(String value);

  /// cardio.week.count
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Einheit} other{{n} Einheiten}}'**
  String cardioWeekCount(int n);

  /// cardio.week.thin
  ///
  /// In de, this message translates to:
  /// **'Wochenkilometer ab 3 Wochen mit Einheiten. Bis dahin steht hier die Gesamtstrecke.'**
  String get cardioWeekThin;

  /// cardio.week.title
  ///
  /// In de, this message translates to:
  /// **'Diese Woche · KW {kw}'**
  String cardioWeekTitle(int kw);

  /// aus common.back
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get commonBack;

  /// common.cancel
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// aus common.close
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get commonClose;

  /// common.created
  ///
  /// In de, this message translates to:
  /// **'Übung angelegt'**
  String get commonCreated;

  /// aus common.delete
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// aus common.done
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get commonDone;

  /// aus common.duration
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get commonDuration;

  /// aus common.edit
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get commonEdit;

  /// aus common.loading
  ///
  /// In de, this message translates to:
  /// **'Lade Daten...'**
  String get commonLoading;

  /// aus common.minutes
  ///
  /// In de, this message translates to:
  /// **'Minuten'**
  String get commonMinutes;

  /// aus common.notAvailable
  ///
  /// In de, this message translates to:
  /// **'-'**
  String get commonNotAvailable;

  /// aus common.notes
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get commonNotes;

  /// Verbindungswort in Vorlesetexten: 4 von 5
  ///
  /// In de, this message translates to:
  /// **'von'**
  String get commonOf;

  /// common.open
  ///
  /// In de, this message translates to:
  /// **'Öffnen'**
  String get commonOpen;

  /// Prozentzeichen, allein stehend
  ///
  /// In de, this message translates to:
  /// **'%'**
  String get commonPercentSign;

  /// Runner, Modul 2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get commonRetry;

  /// common.retry.save
  ///
  /// In de, this message translates to:
  /// **'Erneut speichern'**
  String get commonRetrySave;

  /// aus common.save
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get commonSave;

  /// common.saved
  ///
  /// In de, this message translates to:
  /// **'Änderung gespeichert'**
  String get commonSaved;

  /// common.saving
  ///
  /// In de, this message translates to:
  /// **'Wird gespeichert'**
  String get commonSaving;

  /// aus common.secondsShort
  ///
  /// In de, this message translates to:
  /// **'{n}s'**
  String commonSecondsShort(int n);

  /// aus common.select
  ///
  /// In de, this message translates to:
  /// **'Auswahl'**
  String get commonSelect;

  /// aus common.session
  ///
  /// In de, this message translates to:
  /// **'Session'**
  String get commonSession;

  /// common.undo
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get commonUndo;

  /// aus common.weeks
  ///
  /// In de, this message translates to:
  /// **'Wochen'**
  String get commonWeeks;

  /// Tage in der Folgentabelle
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Tag} other{{n} Tage}}'**
  String consequenceDays(int n);

  /// Vorlesetext einer Folgenzeile
  ///
  /// In de, this message translates to:
  /// **'{label}: von {from} auf {to}'**
  String consequenceStepA11y(String label, String from, String to);

  /// aus dashboard.hybridBalance.subtitle
  ///
  /// In de, this message translates to:
  /// **'Letzte {days} Tage'**
  String dashboardHybridBalanceSubtitle(int days);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Dashboard wird geladen'**
  String get dashboardLoadingA11y;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{name}, Tab {n} von {total}'**
  String dashboardNavA11y(String name, int n, int total);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Daten nicht verfügbar'**
  String get dashboardNotAvailable;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Readiness {percent} Prozent, {status}'**
  String dashboardReadinessA11y(int percent, String status);

  /// Zonenname: produktiver Aufbau
  ///
  /// In de, this message translates to:
  /// **'AUFBAU'**
  String get dashboardReadinessLevelBuilding;

  /// Zonenname: erhöhte Belastung
  ///
  /// In de, this message translates to:
  /// **'ERMÜDET'**
  String get dashboardReadinessLevelFatigued;

  /// Zonenname: zu wenig Training, nicht zu viel
  ///
  /// In de, this message translates to:
  /// **'FORMVERLUST'**
  String get dashboardReadinessLevelFormLoss;

  /// Aus dem Design-Handoff ATEM Dashboard, nicht aus der PWA
  ///
  /// In de, this message translates to:
  /// **'MODERATE LAST'**
  String get dashboardReadinessLevelModerate;

  /// Zonenname: deutlich zu viel
  ///
  /// In de, this message translates to:
  /// **'ÜBERREIZT'**
  String get dashboardReadinessLevelOverreaching;

  /// Aus dem Design-Handoff ATEM Dashboard, nicht aus der PWA
  ///
  /// In de, this message translates to:
  /// **'PEAK READINESS'**
  String get dashboardReadinessLevelPeak;

  /// Aus dem Design-Handoff ATEM Dashboard, nicht aus der PWA
  ///
  /// In de, this message translates to:
  /// **'FOKUS: REGENERATION'**
  String get dashboardReadinessLevelRecovery;

  /// Aus dem Design-Handoff ATEM Dashboard, nicht aus der PWA
  ///
  /// In de, this message translates to:
  /// **'SOLIDE FORM'**
  String get dashboardReadinessLevelSolid;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'ATEM READINESS'**
  String get dashboardReadinessSection;

  /// Empfehlung bei Ermüdung
  ///
  /// In de, this message translates to:
  /// **'Regeneration: Niedrig • Volumen deutlich reduzieren'**
  String get dashboardReadinessTagFatigued;

  /// Empfehlung bei Formverlust — ausgeruht, aber zu wenig Reiz
  ///
  /// In de, this message translates to:
  /// **'Regeneration: Ausgeruht • Wieder Volumen aufbauen'**
  String get dashboardReadinessTagFormLoss;

  /// Aus dem Design-Handoff ATEM Dashboard, nicht aus der PWA
  ///
  /// In de, this message translates to:
  /// **'Regeneration: Mittel • Volumen leicht reduzieren'**
  String get dashboardReadinessTagModerate;

  /// Empfehlung bei Überreizung
  ///
  /// In de, this message translates to:
  /// **'Regeneration: Kritisch • Heute nicht trainieren'**
  String get dashboardReadinessTagOverreaching;

  /// Aus dem Design-Handoff ATEM Dashboard, nicht aus der PWA
  ///
  /// In de, this message translates to:
  /// **'Regeneration: Optimal • Bereit für maximale Last'**
  String get dashboardReadinessTagPeak;

  /// Aus dem Design-Handoff ATEM Dashboard, nicht aus der PWA
  ///
  /// In de, this message translates to:
  /// **'Regeneration: Niedrig • Heute aktiv erholen'**
  String get dashboardReadinessTagRecovery;

  /// Aus dem Design-Handoff ATEM Dashboard, nicht aus der PWA
  ///
  /// In de, this message translates to:
  /// **'Regeneration: Gut • Normale Trainingslast fahren'**
  String get dashboardReadinessTagSolid;

  /// delete.confirm
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get deleteConfirm;

  /// delete.keep
  ///
  /// In de, this message translates to:
  /// **'Behalten'**
  String get deleteKeep;

  /// delete.step1.continue
  ///
  /// In de, this message translates to:
  /// **'Weiter zum Löschen'**
  String get deleteStep1Continue;

  /// delete.step2.noUndo
  ///
  /// In de, this message translates to:
  /// **'Es gibt kein Rückgängig — nur neu anlegen.'**
  String get deleteStep2NoUndo;

  /// delete.step2.title
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get deleteStep2Title;

  /// Überschrift im Detail
  ///
  /// In de, this message translates to:
  /// **'Belastung an diesem Tag'**
  String get detailAcwrLabel;

  /// detail.compare.mid (Board 06)
  ///
  /// In de, this message translates to:
  /// **'Mittelfeld'**
  String get detailCompareMid;

  /// detail.compare.title (Board 06)
  ///
  /// In de, this message translates to:
  /// **'Gegen deine {n} Läufe'**
  String detailCompareTitle(int n);

  /// detail.compare.top (Board 06)
  ///
  /// In de, this message translates to:
  /// **'Top {p} %'**
  String detailCompareTop(int p);

  /// Kennzahl im Detail
  ///
  /// In de, this message translates to:
  /// **'Strecke'**
  String get detailDistance;

  /// Kennzahl im Detail
  ///
  /// In de, this message translates to:
  /// **'Last'**
  String get detailLoad;

  /// detail.saveAsPlan (Board 06)
  ///
  /// In de, this message translates to:
  /// **'Als Plan speichern'**
  String get detailSaveAsPlan;

  /// Richtungswort im Vorlesetext — die Farbe trägt sie nie allein
  ///
  /// In de, this message translates to:
  /// **'besser'**
  String get directionBetter;

  /// Richtungswort bei Zeitspannen
  ///
  /// In de, this message translates to:
  /// **'länger'**
  String get directionLonger;

  /// Richtungswort ohne Änderung
  ///
  /// In de, this message translates to:
  /// **'unverändert'**
  String get directionSame;

  /// Richtungswort bei Zeitspannen
  ///
  /// In de, this message translates to:
  /// **'kürzer'**
  String get directionShorter;

  /// Richtungswort im Vorlesetext
  ///
  /// In de, this message translates to:
  /// **'schlechter'**
  String get directionWorse;

  /// Geschätzte Dauer. Die Tilde ist wichtig: Die Daten geben keine genaue Zahl her.
  ///
  /// In de, this message translates to:
  /// **'~{n} min'**
  String durationApproxMinutes(int n);

  /// Dauer in Minuten, ohne Tilde — hier ist der Wert gemessen
  ///
  /// In de, this message translates to:
  /// **'{n} min'**
  String durationMinutes(int n);

  /// empty.history.body (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Dein Verlauf entsteht mit der ersten abgeschlossenen Session.'**
  String get emptyHistoryBody;

  /// empty.history.title (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Noch kein Verlauf'**
  String get emptyHistoryTitle;

  /// empty.search.body (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Für „{begriff}\" mit {n} aktiven Filtern gibt es keine Treffer.'**
  String emptySearchBody(String begriff, int n);

  /// empty.search.cta (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get emptySearchCta;

  /// empty.search.title (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Keine Übung gefunden'**
  String get emptySearchTitle;

  /// empty.today.title (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Heute ist nichts geplant'**
  String get emptyTodayTitle;

  /// Planeintrag
  ///
  /// In de, this message translates to:
  /// **'Zuklappen'**
  String get entryCollapse;

  /// Planeintrag
  ///
  /// In de, this message translates to:
  /// **'Aufklappen'**
  String get entryExpand;

  /// Zugeklappt ohne Zielwerte
  ///
  /// In de, this message translates to:
  /// **'Kein Ziel gesetzt'**
  String get entryNoTarget;

  /// Zusammenfassung eines zugeklappten Eintrags
  ///
  /// In de, this message translates to:
  /// **'{sets}×{reps} · {rest} s Pause'**
  String entrySummary(String sets, String reps, String rest);

  /// error.offline.banner (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Offline — Änderungen werden lokal gespeichert'**
  String get errorOfflineBanner;

  /// error.section.body (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Alles andere ist aktuell.'**
  String get errorSectionBody;

  /// error.section.retry (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Neu laden'**
  String get errorSectionRetry;

  /// error.section.title (Board 02)
  ///
  /// In de, this message translates to:
  /// **'{sektion} nicht ladbar'**
  String errorSectionTitle(String sektion);

  /// Runner, Modul 2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Laden fehlgeschlagen. Bitte erneut versuchen.'**
  String get errorsLoadFailed;

  /// aus errors.saveFailed
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern.'**
  String get errorsSaveFailed;

  /// Anzahl Übungen, kurz
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Übung} other{{n} Übungen}}'**
  String exerciseCountShort(int n);

  /// Abschnitt im Detail
  ///
  /// In de, this message translates to:
  /// **'Cues'**
  String get exerciseCues;

  /// exercise.curated.badge
  ///
  /// In de, this message translates to:
  /// **'Kuratiert'**
  String get exerciseCuratedBadge;

  /// exercise.curated.body
  ///
  /// In de, this message translates to:
  /// **'Diese Übung ist für alle gleich und bleibt unverändert. Willst du sie anders, leg dir eine eigene Fassung an.'**
  String get exerciseCuratedBody;

  /// exercise.curated.copy
  ///
  /// In de, this message translates to:
  /// **'Eigene Fassung anlegen'**
  String get exerciseCuratedCopy;

  /// exercise.curated.title
  ///
  /// In de, this message translates to:
  /// **'Gehört zur Bibliothek'**
  String get exerciseCuratedTitle;

  /// exercise.delete
  ///
  /// In de, this message translates to:
  /// **'Übung löschen'**
  String get exerciseDelete;

  /// exercise.delete.keepUnits
  ///
  /// In de, this message translates to:
  /// **'Deine {n} Einheiten bleiben vollständig — mit Sätzen, Gewichten und Last.'**
  String exerciseDeleteKeepUnits(int n);

  /// exercise.delete.plansGap
  ///
  /// In de, this message translates to:
  /// **'In den {n} Plänen bleibt eine Lücke stehen, die du dort ersetzen kannst.'**
  String exerciseDeletePlansGap(int n);

  /// exercise.delete.q
  ///
  /// In de, this message translates to:
  /// **'„{name}\" löschen?'**
  String exerciseDeleteQ(String name);

  /// exercise.delete.usage
  ///
  /// In de, this message translates to:
  /// **'Die Übung steckt in {p, plural, one {{p} Plan} other {{p} Plänen}} und {s, plural, one {{s} Einheit} other {{s} Einheiten}}.'**
  String exerciseDeleteUsage(int p, int s);

  /// Vorlesefassung der Segmentanzeige
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit {n} von 5'**
  String exerciseDifficultyA11y(int n);

  /// exercise.duplicate.body
  ///
  /// In de, this message translates to:
  /// **'Du hast schon eine Übung „{name}\". Deine Eingaben stehen noch hier.'**
  String exerciseDuplicateBody(String name);

  /// exercise.duplicate.open
  ///
  /// In de, this message translates to:
  /// **'Vorhandene öffnen'**
  String get exerciseDuplicateOpen;

  /// exercise.duplicate.suggest
  ///
  /// In de, this message translates to:
  /// **'Vorschlag nehmen'**
  String get exerciseDuplicateSuggest;

  /// exercise.duplicate.title
  ///
  /// In de, this message translates to:
  /// **'Nicht gespeichert'**
  String get exerciseDuplicateTitle;

  /// exercise.edit.title
  ///
  /// In de, this message translates to:
  /// **'Übung bearbeiten'**
  String get exerciseEditTitle;

  /// Board 07, optFelder
  ///
  /// In de, this message translates to:
  /// **'Cues'**
  String get exerciseFieldCues;

  /// Board 07, optFelder
  ///
  /// In de, this message translates to:
  /// **'Kurze Merksätze, einer je Zeile'**
  String get exerciseFieldCuesHint;

  /// Board 07, optFelder
  ///
  /// In de, this message translates to:
  /// **'Gerät'**
  String get exerciseFieldEquipment;

  /// Board 07, optFelder
  ///
  /// In de, this message translates to:
  /// **'Freitext, keine feste Liste'**
  String get exerciseFieldEquipmentHint;

  /// Board 07, optFelder
  ///
  /// In de, this message translates to:
  /// **'Anleitung'**
  String get exerciseFieldInstructions;

  /// Board 07, optFelder
  ///
  /// In de, this message translates to:
  /// **'Freitext, bis 500 Zeichen'**
  String get exerciseFieldInstructionsHint;

  /// exercise.field.level
  ///
  /// In de, this message translates to:
  /// **'Stufe'**
  String get exerciseFieldLevel;

  /// exercise.field.muscles
  ///
  /// In de, this message translates to:
  /// **'Muskeln'**
  String get exerciseFieldMuscles;

  /// exercise.field.muscles.count
  ///
  /// In de, this message translates to:
  /// **'{n} gewählt'**
  String exerciseFieldMusclesCount(int n);

  /// exercise.field.name
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get exerciseFieldName;

  /// exercise.field.name.hint
  ///
  /// In de, this message translates to:
  /// **'z. B. Bulgarian Split Squat'**
  String get exerciseFieldNameHint;

  /// Fehlermeldung, Text
  ///
  /// In de, this message translates to:
  /// **'Prüfe die Verbindung und versuche es erneut.'**
  String get exerciseFormSaveErrorBody;

  /// history.title (Modul 9) — umbenannt: Modul 6 und 9 benutzen denselben Punktpfad für Verschiedenes
  ///
  /// In de, this message translates to:
  /// **'Du mit dieser Übung'**
  String get exerciseHistoryTitle;

  /// Abschnitt im Detail
  ///
  /// In de, this message translates to:
  /// **'Anleitung'**
  String get exerciseInstructions;

  /// exercise.level.1
  ///
  /// In de, this message translates to:
  /// **'Einstieg'**
  String get exerciseLevel1;

  /// exercise.level.2
  ///
  /// In de, this message translates to:
  /// **'Leicht'**
  String get exerciseLevel2;

  /// exercise.level.3
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get exerciseLevel3;

  /// exercise.level.4
  ///
  /// In de, this message translates to:
  /// **'Fortgeschritten'**
  String get exerciseLevel4;

  /// exercise.level.5
  ///
  /// In de, this message translates to:
  /// **'Experte'**
  String get exerciseLevel5;

  /// Kurzform der Stufe 1 fuer die Auswahlreihe
  ///
  /// In de, this message translates to:
  /// **'EINST.'**
  String get exerciseLevel1Short;

  /// Kurzform der Stufe 2 fuer die Auswahlreihe
  ///
  /// In de, this message translates to:
  /// **'LEICHT'**
  String get exerciseLevel2Short;

  /// Kurzform der Stufe 3 fuer die Auswahlreihe
  ///
  /// In de, this message translates to:
  /// **'MITTEL'**
  String get exerciseLevel3Short;

  /// Kurzform der Stufe 4 fuer die Auswahlreihe
  ///
  /// In de, this message translates to:
  /// **'FORTG.'**
  String get exerciseLevel4Short;

  /// Kurzform der Stufe 5 fuer die Auswahlreihe
  ///
  /// In de, this message translates to:
  /// **'EXP.'**
  String get exerciseLevel5Short;

  /// exercise.level.hint
  ///
  /// In de, this message translates to:
  /// **'Wird als Zahl 1–5 gespeichert.'**
  String get exerciseLevelHint;

  /// Abschnitt im Detail
  ///
  /// In de, this message translates to:
  /// **'Häufige Fehler'**
  String get exerciseMistakes;

  /// exercise.more
  ///
  /// In de, this message translates to:
  /// **'Mehr Angaben'**
  String get exerciseMore;

  /// exercise.more.count
  ///
  /// In de, this message translates to:
  /// **'{n} optional'**
  String exerciseMoreCount(int n);

  /// exercise.new.title
  ///
  /// In de, this message translates to:
  /// **'Neue Übung'**
  String get exerciseNewTitle;

  /// exercise.save.blocked
  ///
  /// In de, this message translates to:
  /// **'Noch {n} Angaben nötig'**
  String exerciseSaveBlocked(int n);

  /// Nur bei eigenen Übungen ohne Inhalt
  ///
  /// In de, this message translates to:
  /// **'Diese Übung hast du selbst angelegt.'**
  String get exerciseSparseBody;

  /// Nur bei eigenen Übungen ohne Inhalt
  ///
  /// In de, this message translates to:
  /// **'Keine Anleitung hinterlegt'**
  String get exerciseSparseTitle;

  /// exercises.block.byMuscle
  ///
  /// In de, this message translates to:
  /// **'Nach Muskel'**
  String get exercisesBlockByMuscle;

  /// Zählzeile über der Liste
  ///
  /// In de, this message translates to:
  /// **'{n} Übungen · {k} kuratiert · {e} eigene'**
  String exercisesCount(int n, int k, int e);

  /// exercises.create
  ///
  /// In de, this message translates to:
  /// **'Eigene Übung anlegen'**
  String get exercisesCreate;

  /// exercises.empty.own.body
  ///
  /// In de, this message translates to:
  /// **'Name, Muskeln und eine Stufe genügen — der Rest ist freiwillig.'**
  String get exercisesEmptyOwnBody;

  /// exercises.empty.own.title
  ///
  /// In de, this message translates to:
  /// **'Noch keine eigene Übung'**
  String get exercisesEmptyOwnTitle;

  /// Vorlesetext eines gewählten Muskelfilters
  ///
  /// In de, this message translates to:
  /// **'{muscle}, Filter aktiv'**
  String exercisesFilterActive(String muscle);

  /// Erster Filter-Chip, steht fest an Position 1
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get exercisesFilterAll;

  /// Vorlesetext eines Muskelfilters
  ///
  /// In de, this message translates to:
  /// **'Nach {muscle} filtern'**
  String exercisesFilterMuscle(String muscle);

  /// Hebt den Filter auf
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get exercisesFilterReset;

  /// Zählzeile bei aktivem Filter
  ///
  /// In de, this message translates to:
  /// **'{n} Übungen · {filter}'**
  String exercisesFilterResult(int n, String filter);

  /// Leerzustand der Suche, Text
  ///
  /// In de, this message translates to:
  /// **'Ändere den Suchbegriff oder den Muskel.'**
  String get exercisesNoMatchBody;

  /// Leerzustand der Suche
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer'**
  String get exercisesNoMatchTitle;

  /// Kennzeichnet selbst angelegte Übungen
  ///
  /// In de, this message translates to:
  /// **'Eigen'**
  String get exercisesOwnTag;

  /// Platzhalter im Suchfeld
  ///
  /// In de, this message translates to:
  /// **'Übung suchen …'**
  String get exercisesSearchHint;

  /// Titel der Übungsliste
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get exercisesTitle;

  /// export.body
  ///
  /// In de, this message translates to:
  /// **'Du wählst danach, wohin sie geht.'**
  String get exportBody;

  /// export.create
  ///
  /// In de, this message translates to:
  /// **'Datei erstellen'**
  String get exportCreate;

  /// export.done.note
  ///
  /// In de, this message translates to:
  /// **'Die Datei liegt im Downloads-Ordner. Die App verschickt nichts selbst.'**
  String get exportDoneNote;

  /// export.done.share
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get exportDoneShare;

  /// Welche Datei wofür — die offene Frage aus Modul 8, Abschnitt K
  ///
  /// In de, this message translates to:
  /// **'JSON enthält alles. CSV enthält deine Einheiten als Tabelle, eine Zeile je Satz.'**
  String get exportFormatNote;

  /// Umfang des Ausgabeformats
  ///
  /// In de, this message translates to:
  /// **'Vollständig'**
  String get exportFormatFull;

  /// Umfang des Ausgabeformats
  ///
  /// In de, this message translates to:
  /// **'Einheiten'**
  String get exportFormatSessions;

  /// Zeitraum in der Inhaltsliste
  ///
  /// In de, this message translates to:
  /// **'{n} T'**
  String exportRowDays(int n);

  /// Board 08, exportInhalt
  ///
  /// In de, this message translates to:
  /// **'Eigene Übungen'**
  String get exportRowExercises;

  /// Board 08, exportInhalt
  ///
  /// In de, this message translates to:
  /// **'Pläne mit Einträgen'**
  String get exportRowPlans;

  /// Board 08, exportInhalt
  ///
  /// In de, this message translates to:
  /// **'Profilangaben'**
  String get exportRowProfile;

  /// Board 08, exportInhalt
  ///
  /// In de, this message translates to:
  /// **'Bestwerte und Formkurve'**
  String get exportRowScores;

  /// Board 08, exportInhalt
  ///
  /// In de, this message translates to:
  /// **'Einheiten mit Sätzen'**
  String get exportRowSessions;

  /// export.size
  ///
  /// In de, this message translates to:
  /// **'ca. {mb} MB · keine Bilder, keine Videos'**
  String exportSize(String mb);

  /// export.sub
  ///
  /// In de, this message translates to:
  /// **'Eine Datei mit allem, was dir gehört'**
  String get exportSub;

  /// export.title
  ///
  /// In de, this message translates to:
  /// **'Daten ausgeben'**
  String get exportTitle;

  /// form.activity
  ///
  /// In de, this message translates to:
  /// **'Aktivität'**
  String get formActivity;

  /// form.date
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get formDate;

  /// form.distance
  ///
  /// In de, this message translates to:
  /// **'Distanz · km'**
  String get formDistance;

  /// form.duration
  ///
  /// In de, this message translates to:
  /// **'Dauer · min'**
  String get formDuration;

  /// form.hr.avg
  ///
  /// In de, this message translates to:
  /// **'Ø Puls'**
  String get formHrAvg;

  /// form.hr.hint
  ///
  /// In de, this message translates to:
  /// **'Puls leer lassen ist der Normalfall. Die Auswertung setzt ihn nirgends voraus.'**
  String get formHrHint;

  /// form.hr.max
  ///
  /// In de, this message translates to:
  /// **'Max. Puls'**
  String get formHrMax;

  /// form.optional.count
  ///
  /// In de, this message translates to:
  /// **'Optional · {n} Felder'**
  String formOptionalCount(int n);

  /// form.pace
  ///
  /// In de, this message translates to:
  /// **'Tempo'**
  String get formPace;

  /// form.pace.computed
  ///
  /// In de, this message translates to:
  /// **'gerechnet'**
  String get formPaceComputed;

  /// form.rpe
  ///
  /// In de, this message translates to:
  /// **'Anstrengung · RPE'**
  String get formRpe;

  /// form.rpe.1
  ///
  /// In de, this message translates to:
  /// **'sehr leicht'**
  String get formRpe1;

  /// form.rpe.3
  ///
  /// In de, this message translates to:
  /// **'mittel'**
  String get formRpe3;

  /// form.rpe.5
  ///
  /// In de, this message translates to:
  /// **'maximal'**
  String get formRpe5;

  /// form.today
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get formToday;

  /// aus format.duration.hours
  ///
  /// In de, this message translates to:
  /// **'{hours}h'**
  String formatDurationHours(int hours);

  /// aus format.duration.hoursMinutes
  ///
  /// In de, this message translates to:
  /// **'{hours}h {minutes}m'**
  String formatDurationHoursMinutes(int hours, int minutes);

  /// aus format.duration.minutes
  ///
  /// In de, this message translates to:
  /// **'{minutes} min'**
  String formatDurationMinutes(int minutes);

  /// aus format.pace.value
  ///
  /// In de, this message translates to:
  /// **'{min}:{sec} min/km'**
  String formatPaceValue(int min, int sec);

  /// Erklärtext im Warteraum
  ///
  /// In de, this message translates to:
  /// **'Die Beta ist geschlossen, wir schalten laufend Plätze frei. Du bekommst eine E-Mail, sobald du dran bist.'**
  String get gateBody;

  /// Knopf im Warteraum
  ///
  /// In de, this message translates to:
  /// **'Status erneut prüfen'**
  String get gateRecheck;

  /// Semantics-Label des Prüfknopfes
  ///
  /// In de, this message translates to:
  /// **'Beta-Status erneut prüfen'**
  String get gateRecheckA11y;

  /// Ergebniszeile nach der Prüfung
  ///
  /// In de, this message translates to:
  /// **'Geprüft — noch kein Platz frei.'**
  String get gateRecheckNegative;

  /// Ergebniszeile ohne Netz
  ///
  /// In de, this message translates to:
  /// **'Prüfung nicht möglich — kein Netz.'**
  String get gateRecheckOffline;

  /// Zustand während der Prüfung
  ///
  /// In de, this message translates to:
  /// **'Wird geprüft …'**
  String get gateRechecking;

  /// Kontozeile im Warteraum
  ///
  /// In de, this message translates to:
  /// **'Angemeldet als {email}'**
  String gateSignedInAs(String email);

  /// Statuspille im Warteraum
  ///
  /// In de, this message translates to:
  /// **'WARTELISTE'**
  String get gateStatus;

  /// Vorlesefassung der Statuspille — „WARTELISTE" in Grossbuchstaben buchstabiert ein Screenreader womöglich
  ///
  /// In de, this message translates to:
  /// **'Status: Warteliste'**
  String get gateStatusA11y;

  /// Knopf im Warteraum
  ///
  /// In de, this message translates to:
  /// **'Anderes Konto verwenden'**
  String get gateSwitchAccount;

  /// Semantics-Label — die Kurzform verschweigt das Abmelden nicht
  ///
  /// In de, this message translates to:
  /// **'Abmelden und mit anderem Konto anmelden'**
  String get gateSwitchAccountA11y;

  /// Überschrift des Warteraums
  ///
  /// In de, this message translates to:
  /// **'Du stehst auf der Liste'**
  String get gateTitle;

  /// haptics.sub
  ///
  /// In de, this message translates to:
  /// **'Kurzes Klopfen bei Satz und Pause'**
  String get hapticsSub;

  /// haptics.title
  ///
  /// In de, this message translates to:
  /// **'Haptik'**
  String get hapticsTitle;

  /// Öffnet die vollständige Liste
  ///
  /// In de, this message translates to:
  /// **'Alle {n}'**
  String historyAll(int n);

  /// Führt zur Formkurve
  ///
  /// In de, this message translates to:
  /// **'Auswertung öffnen'**
  String get historyAnalysisOpen;

  /// history.best
  ///
  /// In de, this message translates to:
  /// **'Bestwert'**
  String get historyBest;

  /// history.count
  ///
  /// In de, this message translates to:
  /// **'{n}×'**
  String historyCount(int n);

  /// history.curve.a11y
  ///
  /// In de, this message translates to:
  /// **'Verlauf des besten Satzgewichts über {n} Einheiten, von {from} auf {to}'**
  String historyCurveA11y(int n, String from, String to);

  /// history.curve.label
  ///
  /// In de, this message translates to:
  /// **'Bestes Satzgewicht'**
  String get historyCurveLabel;

  /// history.curve.legend
  ///
  /// In de, this message translates to:
  /// **'Ring markiert den Bestwert'**
  String get historyCurveLegend;

  /// Fehlerzustand
  ///
  /// In de, this message translates to:
  /// **'Deine Einheiten konnten nicht geladen werden.'**
  String get historyErrorBody;

  /// Fehlerzustand
  ///
  /// In de, this message translates to:
  /// **'Verlauf nicht verfügbar'**
  String get historyErrorTitle;

  /// history.freq
  ///
  /// In de, this message translates to:
  /// **'Häufigkeit'**
  String get historyFreq;

  /// history.freq.value
  ///
  /// In de, this message translates to:
  /// **'{n} / Wo'**
  String historyFreqValue(String n);

  /// history.last
  ///
  /// In de, this message translates to:
  /// **'Zuletzt'**
  String get historyLast;

  /// Der Satz der Aussage-Karte im Rhythmus
  ///
  /// In de, this message translates to:
  /// **'{n} Einheiten in {d} Tagen'**
  String historyLeadFrequency(int n, int d);

  /// Der Satz der Aussage-Karte bei Pause und Untätigkeit
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one {{n} Tag} other {{n} Tage}} ohne Training'**
  String historyLeadGap(int n);

  /// Zweite Zeile der Aussage-Karte
  ///
  /// In de, this message translates to:
  /// **'Zuletzt {weekday} {date} · {name}'**
  String historyLeadLast(String weekday, String date, String name);

  /// Überschrift des Monatsstreifens
  ///
  /// In de, this message translates to:
  /// **'Einheiten je Monat'**
  String get historyMonthsLabel;

  /// Verteilung statt Durchschnitt — der Durchschnitt lügt bei diesem Bestand
  ///
  /// In de, this message translates to:
  /// **'Median {n} Tage Abstand · längste Pause {max}'**
  String historyMonthsMedian(int n, int max);

  /// history.once
  ///
  /// In de, this message translates to:
  /// **'ausgeführt · {date}'**
  String historyOnce(String date);

  /// history.once.label
  ///
  /// In de, this message translates to:
  /// **'Damals'**
  String get historyOnceLabel;

  /// history.once.note
  ///
  /// In de, this message translates to:
  /// **'Kein Bestwert, keine Kurve, keine Häufigkeit — aus einer Ausführung folgt keins davon.'**
  String get historyOnceNote;

  /// Überschrift der Kurzliste
  ///
  /// In de, this message translates to:
  /// **'Letzte Einheiten'**
  String get historyRecentLabel;

  /// history.title (Modul 6)
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get historyTitle;

  /// history.volume
  ///
  /// In de, this message translates to:
  /// **'Volumen'**
  String get historyVolume;

  /// Zustandszone: ab 28 Tagen
  ///
  /// In de, this message translates to:
  /// **'Untätig'**
  String get historyZoneInactive;

  /// Zustandszone: 7 bis 27 Tage
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get historyZonePause;

  /// Zustandszone: 4 bis 6 Tage
  ///
  /// In de, this message translates to:
  /// **'Dran geblieben'**
  String get historyZoneRecent;

  /// Zustandszone: bis 3 Tage Abstand
  ///
  /// In de, this message translates to:
  /// **'Im Rhythmus'**
  String get historyZoneRhythm;

  /// hybrid.empty.body
  ///
  /// In de, this message translates to:
  /// **'Hier steht später, wie Kraft und Ausdauer bei dir zueinander stehen. Fang mit einer Seite an — welcher, ist gleich.'**
  String get hybridEmptyBody;

  /// hybrid.empty.title
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einheit'**
  String get hybridEmptyTitle;

  /// Dünner Wochenblock — der Formwert ist seit 16.09.2026 entfernt
  ///
  /// In de, this message translates to:
  /// **'Bereitschaft ab {min} Einheiten.'**
  String hybridWeekThin(int min);

  /// hybrid.week.title
  ///
  /// In de, this message translates to:
  /// **'Deine Woche'**
  String get hybridWeekTitle;

  /// intensity.above
  ///
  /// In de, this message translates to:
  /// **'Über dem Schnitt'**
  String get intensityAbove;

  /// intensity.below
  ///
  /// In de, this message translates to:
  /// **'Unter dem Schnitt'**
  String get intensityBelow;

  /// intensity.fallback.note
  ///
  /// In de, this message translates to:
  /// **'Weder Puls noch RPE erfasst. Beurteilt wird über das Tempo gegen {n, plural, one{1 Lauf} other{{n} Läufe}}.'**
  String intensityFallbackNote(int n);

  /// intensity.level1
  ///
  /// In de, this message translates to:
  /// **'Ø Herzfrequenz · aus Uhrdaten'**
  String get intensityLevel1;

  /// intensity.level2
  ///
  /// In de, this message translates to:
  /// **'Anstrengung · deine Angabe'**
  String get intensityLevel2;

  /// intensity.level3
  ///
  /// In de, this message translates to:
  /// **'Tempo gegen eigenen Schnitt'**
  String get intensityLevel3;

  /// intensity.none.a11y
  ///
  /// In de, this message translates to:
  /// **'nicht erfasst'**
  String get intensityNoneA11y;

  /// intensity.none.value
  ///
  /// In de, this message translates to:
  /// **'—'**
  String get intensityNoneValue;

  /// intensity.zone
  ///
  /// In de, this message translates to:
  /// **'Zone {n} · {name}'**
  String intensityZone(int n, String name);

  /// language.de
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageDe;

  /// language.en
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get languageEn;

  /// language.title
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get languageTitle;

  /// last.cardio
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{Heute {activity}} other{Gestern {activity}}}'**
  String lastCardio(String activity, int n);

  /// last.none
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{Seit 1 Tag keine Einheit} other{Seit {n} Tagen keine Einheit}}'**
  String lastNone(int n);

  /// last.recovery
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{Heute Regeneration} other{Gestern Regeneration}}'**
  String lastRecovery(int n);

  /// last.strength
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{Heute Kraft} other{Gestern Kraft}}'**
  String lastStrength(int n);

  /// legal.error
  ///
  /// In de, this message translates to:
  /// **'Text nicht geladen'**
  String get legalError;

  /// legal.imprint
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get legalImprint;

  /// legal.inapp
  ///
  /// In de, this message translates to:
  /// **'In der App'**
  String get legalInapp;

  /// legal.privacy
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get legalPrivacy;

  /// legal.retry
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get legalRetry;

  /// legal.terms
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen'**
  String get legalTerms;

  /// Abschluss der Liste
  ///
  /// In de, this message translates to:
  /// **'Erste Einheit am {date} · {n} Tage her.'**
  String listEndBody(String date, int n);

  /// Abschluss der Liste
  ///
  /// In de, this message translates to:
  /// **'Ende des Verlaufs'**
  String get listEndTitle;

  /// Fehlerzustand der Listen
  ///
  /// In de, this message translates to:
  /// **'Deine Workouts konnten nicht geladen werden.'**
  String get listErrorBody;

  /// Fehlerzustand der Listen
  ///
  /// In de, this message translates to:
  /// **'Laden fehlgeschlagen'**
  String get listErrorTitle;

  /// list.filter.clear (Board 06)
  ///
  /// In de, this message translates to:
  /// **'Zeitraum aufheben'**
  String get listFilterClear;

  /// list.filter.empty.body (Board 06)
  ///
  /// In de, this message translates to:
  /// **'{typ} kommt im {zeitraum} nicht vor — insgesamt gibt es {n}.'**
  String listFilterEmptyBody(String typ, String zeitraum, int n);

  /// list.filter.empty.title (Board 06)
  ///
  /// In de, this message translates to:
  /// **'Keine Einheit in dieser Auswahl'**
  String get listFilterEmptyTitle;

  /// Lückenstreifen zwischen zwei Einheiten
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one {{n} Tag} other {{n} Tage}} ohne Training'**
  String listGap(int n);

  /// Zusatz am längsten Lückenstreifen
  ///
  /// In de, this message translates to:
  /// **'längste Pause im Verlauf'**
  String get listGapLongest;

  /// Semantics-Zusatz einer Verlaufszeile, die ins Einheitendetail führt
  ///
  /// In de, this message translates to:
  /// **'öffnet Details'**
  String get listOpenDetail;

  /// Board 06 A2 — Zeitraum der offenen Lücke seit der letzten Einheit bis heute
  ///
  /// In de, this message translates to:
  /// **'{from} – heute'**
  String listGapOpen(String from);

  /// Zeitraum der Lücke
  ///
  /// In de, this message translates to:
  /// **'{from} – {to}'**
  String listGapRange(String from, String to);

  /// Kopfzeile eines Monats in der Liste
  ///
  /// In de, this message translates to:
  /// **'{n} · Last {load}'**
  String listMonthSummary(String n, int load);

  /// Kennzeichnet die zweite Einheit an einem Tag
  ///
  /// In de, this message translates to:
  /// **'{n}. Einheit'**
  String listSecond(int n);

  /// Titel der vollständigen Liste
  ///
  /// In de, this message translates to:
  /// **'Einheiten'**
  String get listTitle;

  /// live.distance.manual
  ///
  /// In de, this message translates to:
  /// **'Distanz von Hand · km'**
  String get liveDistanceManual;

  /// live.distance.source
  ///
  /// In de, this message translates to:
  /// **'vom Display'**
  String get liveDistanceSource;

  /// live.nogps
  ///
  /// In de, this message translates to:
  /// **'Kein GPS, keine Standortabfrage. Die Distanz kommt vom Gerätedisplay und kann jederzeit korrigiert werden.'**
  String get liveNogps;

  /// live.pause
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get livePause;

  /// live.started
  ///
  /// In de, this message translates to:
  /// **'Gestartet {time}'**
  String liveStarted(String time);

  /// live.state.paused
  ///
  /// In de, this message translates to:
  /// **'Pausiert'**
  String get liveStatePaused;

  /// live.state.running
  ///
  /// In de, this message translates to:
  /// **'Läuft'**
  String get liveStateRunning;

  /// live.stop
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get liveStop;

  /// loading.label (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Wird geladen …'**
  String get loadingLabel;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Arme'**
  String get muscleArms;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Rücken'**
  String get muscleBack;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Bizeps'**
  String get muscleBiceps;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Waden'**
  String get muscleCalves;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Brust'**
  String get muscleChest;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Core'**
  String get muscleCore;

  /// Zusammenfassung im Auswahlfeld
  ///
  /// In de, this message translates to:
  /// **'{n} gewählt · {names}'**
  String muscleFieldCount(int n, String names);

  /// Zustand des Auswahlfelds
  ///
  /// In de, this message translates to:
  /// **'Keine gewählt'**
  String get muscleFieldEmpty;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Gesäß'**
  String get muscleGlutes;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Beinbeuger'**
  String get muscleHamstrings;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Beine'**
  String get muscleLegs;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Quadrizeps'**
  String get muscleQuads;

  /// Hilfetext im Auswahlblatt
  ///
  /// In de, this message translates to:
  /// **'Mehrere möglich. Der erste gibt die Farbe.'**
  String get muscleSheetHint;

  /// Abweichung vom Board auf Nutzerwunsch: Auswahl in einem Blatt statt neun Chips im Formular
  ///
  /// In de, this message translates to:
  /// **'Muskeln wählen'**
  String get muscleSheetTitle;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Schultern'**
  String get muscleShoulders;

  /// Muskelgruppe
  ///
  /// In de, this message translates to:
  /// **'Trizeps'**
  String get muscleTriceps;

  /// aus nav.plans
  ///
  /// In de, this message translates to:
  /// **'Pläne'**
  String get navPlans;

  /// Abschlussknopf des Onboardings
  ///
  /// In de, this message translates to:
  /// **'Los geht’s'**
  String get onbCta;

  /// Hinweis am gesperrten Knopf
  ///
  /// In de, this message translates to:
  /// **'Gib dein Gewicht ein, um zu starten.'**
  String get onbCtaLocked;

  /// Semantics-Hinweis am gesperrten Knopf
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht fehlt'**
  String get onbCtaLockedA11y;

  /// Validierungsfehler ausserhalb des Bereichs
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Wert zwischen {min} und {max} {unit} ein.'**
  String onbErrorRange(String min, String max, String unit);

  /// Semantics-Label des Eingabefelds
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht in {unit}'**
  String onbFieldA11y(String unit);

  /// Hinweis unter dem Feld
  ///
  /// In de, this message translates to:
  /// **'Später änderbar unter Profil → Körperdaten.'**
  String get onbHintSettings;

  /// Kicker über dem Onboarding-Titel
  ///
  /// In de, this message translates to:
  /// **'FAST GESCHAFFT'**
  String get onbKicker;

  /// Zustand während des Speicherns
  ///
  /// In de, this message translates to:
  /// **'Wird gespeichert …'**
  String get onbSaving;

  /// Überschrift des Onboardings
  ///
  /// In de, this message translates to:
  /// **'Dein Körpergewicht'**
  String get onbTitle;

  /// Semantics-Label der Segmentgruppe
  ///
  /// In de, this message translates to:
  /// **'Gewichtseinheit wählen'**
  String get onbUnitGroupA11y;

  /// Einheit Kilogramm
  ///
  /// In de, this message translates to:
  /// **'kg'**
  String get onbUnitKg;

  /// Semantics-Label des kg-Segments
  ///
  /// In de, this message translates to:
  /// **'Einheit: Kilogramm'**
  String get onbUnitKgA11y;

  /// Einheit Pfund
  ///
  /// In de, this message translates to:
  /// **'lbs'**
  String get onbUnitLbs;

  /// Semantics-Label des lbs-Segments
  ///
  /// In de, this message translates to:
  /// **'Einheit: Pfund'**
  String get onbUnitLbsA11y;

  /// Begründung, warum diese eine Angabe nötig ist
  ///
  /// In de, this message translates to:
  /// **'ATEM rechnet jede Übung in Trainingslast um — auch die ohne Gewichte. Dafür braucht es genau eine Zahl.'**
  String get onbWhy;

  /// onboarding.repeat
  ///
  /// In de, this message translates to:
  /// **'Onboarding wiederholen'**
  String get onboardingRepeat;

  /// onboarding.repeat.sub
  ///
  /// In de, this message translates to:
  /// **'Die vier Einführungsseiten noch einmal'**
  String get onboardingRepeatSub;

  /// Aktion im Auswahlblatt
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one {1 Übung hinzufügen} other {{n} Übungen hinzufügen}}'**
  String pickerAdd(int n);

  /// Weg aus dem Auswahlblatt heraus — vorher eine Sackgasse
  ///
  /// In de, this message translates to:
  /// **'Übung fehlt? Anlegen'**
  String get pickerCreate;

  /// Gesperrte Aktion mit Grund
  ///
  /// In de, this message translates to:
  /// **'Nichts gewählt'**
  String get pickerNone;

  /// Mehrfachauswahl auf Nutzerwunsch
  ///
  /// In de, this message translates to:
  /// **'Übungen wählen'**
  String get pickerTitle;

  /// plan.broken.entry
  ///
  /// In de, this message translates to:
  /// **'Übung gelöscht'**
  String get planBrokenEntry;

  /// plan.broken.keepTarget
  ///
  /// In de, this message translates to:
  /// **'Ziel bleibt · {ziel}'**
  String planBrokenKeepTarget(String ziel);

  /// plan.broken.remove
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get planBrokenRemove;

  /// plan.broken.replace
  ///
  /// In de, this message translates to:
  /// **'Ersetzen'**
  String get planBrokenReplace;

  /// Zählzeile der Planliste
  ///
  /// In de, this message translates to:
  /// **'{n} Pläne'**
  String planCount(int n);

  /// Bestätigung, Text
  ///
  /// In de, this message translates to:
  /// **'Deine absolvierten Einheiten bleiben unverändert — sie tragen den Plannamen bei sich.'**
  String get planDeleteBody;

  /// Bestätigung
  ///
  /// In de, this message translates to:
  /// **'Plan löschen?'**
  String get planDeleteTitle;

  /// plan.empty.allowed
  ///
  /// In de, this message translates to:
  /// **'Der Plan existiert, sobald er einen Namen hat.'**
  String get planEmptyAllowed;

  /// plan.entry.add
  ///
  /// In de, this message translates to:
  /// **'Übung hinzufügen'**
  String get planEntryAdd;

  /// plan.entry.reps
  ///
  /// In de, this message translates to:
  /// **'Wdh'**
  String get planEntryReps;

  /// plan.entry.reps.hint
  ///
  /// In de, this message translates to:
  /// **'„12\", „8-12\" und „max\" sind erlaubt.'**
  String get planEntryRepsHint;

  /// plan.entry.rest
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get planEntryRest;

  /// plan.entry.sets
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get planEntrySets;

  /// Titel beim Ändern
  ///
  /// In de, this message translates to:
  /// **'Plan bearbeiten'**
  String get planFormEditTitle;

  /// Vorlesetext einer Lücke
  ///
  /// In de, this message translates to:
  /// **'Lücke an Platz {n}: gelöschte Übung, {scheme}'**
  String planFormGapA11y(int n, String scheme);

  /// Titel einer Lücke im Plan
  ///
  /// In de, this message translates to:
  /// **'Übung gelöscht'**
  String get planFormGapTitle;

  /// Zielwert in Sekunden
  ///
  /// In de, this message translates to:
  /// **'Halten'**
  String get planFormHold;

  /// Abschnittslabel
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get planFormItems;

  /// Vorlesetext eines Planeintrags
  ///
  /// In de, this message translates to:
  /// **'{name}, Platz {n} von {total}'**
  String planFormMoveA11y(String name, int n, int total);

  /// Aktion an einem Planeintrag
  ///
  /// In de, this message translates to:
  /// **'Nach unten'**
  String get planFormMoveDown;

  /// Aktion an einem Planeintrag
  ///
  /// In de, this message translates to:
  /// **'Nach oben'**
  String get planFormMoveUp;

  /// Feldbeschriftung
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get planFormName;

  /// Platzhalter im Namensfeld
  ///
  /// In de, this message translates to:
  /// **'z. B. Oberkörper A'**
  String get planFormNameHint;

  /// Titel beim Anlegen
  ///
  /// In de, this message translates to:
  /// **'Neuer Plan'**
  String get planFormNewTitle;

  /// Vorlesetext der Entfernen-Aktion
  ///
  /// In de, this message translates to:
  /// **'{name} aus dem Plan entfernen'**
  String planFormRemoveA11y(String name);

  /// Fehlermeldung
  ///
  /// In de, this message translates to:
  /// **'Plan nicht gespeichert'**
  String get planFormSaveError;

  /// Steht statt des Namens, wenn die Übung gelöscht wurde
  ///
  /// In de, this message translates to:
  /// **'Nicht mehr vorhanden'**
  String get planItemMissing;

  /// Hinweis über einem Plan mit gelöschten Übungen
  ///
  /// In de, this message translates to:
  /// **'Sie wurden gelöscht. Der Plan startet ohne sie.'**
  String get planMissingBody;

  /// Hinweis über einem Plan mit gelöschten Übungen
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{Eine Übung fehlt} other{{n} Übungen fehlen}}'**
  String planMissingTitle(int n);

  /// plan.new.title
  ///
  /// In de, this message translates to:
  /// **'Neuer Plan'**
  String get planNewTitle;

  /// profile.locked
  ///
  /// In de, this message translates to:
  /// **'Über Google · fest'**
  String get profileLocked;

  /// profile.locked.why
  ///
  /// In de, this message translates to:
  /// **'Name und E-Mail kommen aus deinem Google-Konto und werden hier nur angezeigt.'**
  String get profileLockedWhy;

  /// ratio.noshift
  ///
  /// In de, this message translates to:
  /// **'kein 4-Wochen-Schnitt'**
  String get ratioNoshift;

  /// ratio.shift.down
  ///
  /// In de, this message translates to:
  /// **'weniger'**
  String get ratioShiftDown;

  /// ratio.shift.up
  ///
  /// In de, this message translates to:
  /// **'mehr'**
  String get ratioShiftUp;

  /// recovery.add
  ///
  /// In de, this message translates to:
  /// **'Erfassen'**
  String get recoveryAdd;

  /// recovery.gap
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{Seit 1 Tag keine Regeneration} other{Seit {n} Tagen keine Regeneration}}'**
  String recoveryGap(int n);

  /// recovery.kind.mobility
  ///
  /// In de, this message translates to:
  /// **'Mobility'**
  String get recoveryKindMobility;

  /// recovery.kind.sauna
  ///
  /// In de, this message translates to:
  /// **'Sauna'**
  String get recoveryKindSauna;

  /// recovery.kind.stretch
  ///
  /// In de, this message translates to:
  /// **'Dehnen'**
  String get recoveryKindStretch;

  /// recovery.kind.yoga
  ///
  /// In de, this message translates to:
  /// **'Yoga'**
  String get recoveryKindYoga;

  /// recovery.last
  ///
  /// In de, this message translates to:
  /// **'{when} · {kind} · {n} min'**
  String recoveryLast(String when, String kind, int n);

  /// recovery.never
  ///
  /// In de, this message translates to:
  /// **'Keine Regeneration erfasst'**
  String get recoveryNever;

  /// recovery.noload
  ///
  /// In de, this message translates to:
  /// **'Bricht die Untätigkeitsstrafe, trägt aber keine Last. Der Formwert steigt davon nicht.'**
  String get recoveryNoload;

  /// recovery.title
  ///
  /// In de, this message translates to:
  /// **'Regeneration'**
  String get recoveryTitle;

  /// Regenerations-Tab
  ///
  /// In de, this message translates to:
  /// **'Noch keine Regeneration'**
  String get recoveryTabEmptyTitle;

  /// Regenerations-Tab
  ///
  /// In de, this message translates to:
  /// **'Yoga, Sauna, Dehnen oder Mobility — sie bricht die Untätigkeit, ohne Last zu tragen.'**
  String get recoveryTabEmptyBody;

  /// Regenerations-Tab
  ///
  /// In de, this message translates to:
  /// **'Nach Art'**
  String get recoveryTabKinds;

  /// Regenerations-Tab
  ///
  /// In de, this message translates to:
  /// **'Alle Einheiten'**
  String get recoveryTabAll;

  /// Körperregion, Filter
  ///
  /// In de, this message translates to:
  /// **'Arme'**
  String get regionArms;

  /// Körperregion, Filter
  ///
  /// In de, this message translates to:
  /// **'Rücken'**
  String get regionBack;

  /// Körperregion, Filter
  ///
  /// In de, this message translates to:
  /// **'Brust'**
  String get regionChest;

  /// Körperregion, Filter
  ///
  /// In de, this message translates to:
  /// **'Core'**
  String get regionCore;

  /// Körperregion, Filter
  ///
  /// In de, this message translates to:
  /// **'Beine'**
  String get regionLegs;

  /// Körperregion, Filter
  ///
  /// In de, this message translates to:
  /// **'Schultern'**
  String get regionShoulders;

  /// Eingabeart für Wiederholungen
  ///
  /// In de, this message translates to:
  /// **'Tastatur'**
  String get repsKeyboard;

  /// Eingabeart für Wiederholungen
  ///
  /// In de, this message translates to:
  /// **'Rad'**
  String get repsWheel;

  /// Warum es zwei Eingabearten gibt
  ///
  /// In de, this message translates to:
  /// **'Das Rad kennt nur Zahlen. Für „8-12\" oder „max\" die Tastatur.'**
  String get repsWheelHint;

  /// rest.body
  ///
  /// In de, this message translates to:
  /// **'Gilt für Sätze ohne eigene Pause im Plan. Wirkt ab der nächsten Einheit.'**
  String get restBody;

  /// rest.custom
  ///
  /// In de, this message translates to:
  /// **'Eigener Wert'**
  String get restCustom;

  /// rest.running
  ///
  /// In de, this message translates to:
  /// **'Eine laufende Einheit behält ihre Pause.'**
  String get restRunning;

  /// Pausenlänge in Sekunden
  ///
  /// In de, this message translates to:
  /// **'{n} s'**
  String restSeconds(int n);

  /// rest.sub
  ///
  /// In de, this message translates to:
  /// **'Vorgabe beim Start einer Einheit'**
  String get restSub;

  /// rest.title
  ///
  /// In de, this message translates to:
  /// **'Pausenzeit'**
  String get restTitle;

  /// section.about
  ///
  /// In de, this message translates to:
  /// **'Über die App'**
  String get sectionAbout;

  /// section.app
  ///
  /// In de, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// section.data
  ///
  /// In de, this message translates to:
  /// **'Deine Daten'**
  String get sectionData;

  /// section.legal
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get sectionLegal;

  /// section.training
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get sectionTraining;

  /// seg.analysis
  ///
  /// In de, this message translates to:
  /// **'Auswertung'**
  String get segAnalysis;

  /// seg.history
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get segHistory;

  /// seg.sessions
  ///
  /// In de, this message translates to:
  /// **'Einheiten'**
  String get segSessions;

  /// seg.train
  ///
  /// In de, this message translates to:
  /// **'Trainieren'**
  String get segTrain;

  /// session.date.allowed.body
  ///
  /// In de, this message translates to:
  /// **'Verschiebst du den Tag, verschieben sich Lücken und Form-Kurve mit.'**
  String get sessionDateAllowedBody;

  /// session.date.allowed.title
  ///
  /// In de, this message translates to:
  /// **'Datum ändern ist erlaubt'**
  String get sessionDateAllowedTitle;

  /// session.date.previous
  ///
  /// In de, this message translates to:
  /// **'Vorher {date} · {n, plural, one {+{n} Tag} other {+{n} Tage}}'**
  String sessionDatePrevious(int n, String date);

  /// session.delete.body
  ///
  /// In de, this message translates to:
  /// **'Sie zählt in jede Auswertung. Danach steht dort:'**
  String get sessionDeleteBody;

  /// session.delete.q
  ///
  /// In de, this message translates to:
  /// **'Diese Einheit löschen?'**
  String get sessionDeleteQ;

  /// session.delete.window
  ///
  /// In de, this message translates to:
  /// **'6 Sekunden lang kannst du das rückgängig machen.'**
  String get sessionDeleteWindow;

  /// session.deleted.snack
  ///
  /// In de, this message translates to:
  /// **'Einheit gelöscht · Einheiten {alt} → {neu}'**
  String sessionDeletedSnack(String alt, String neu);

  /// Vorlesetext des Datumsfelds
  ///
  /// In de, this message translates to:
  /// **'Datum ändern, aktuell {date}'**
  String sessionEditDateA11y(String date);

  /// Feldbeschriftung
  ///
  /// In de, this message translates to:
  /// **'Dauer in Minuten'**
  String get sessionEditDuration;

  /// Zustand des Speichern-Knopfs ohne Änderung
  ///
  /// In de, this message translates to:
  /// **'Nichts geändert'**
  String get sessionEditNoChange;

  /// Fehlermeldung
  ///
  /// In de, this message translates to:
  /// **'Einheit nicht gespeichert'**
  String get sessionEditSaveError;

  /// session.edit.title
  ///
  /// In de, this message translates to:
  /// **'Einheit bearbeiten'**
  String get sessionEditTitle;

  /// session.field.datetime
  ///
  /// In de, this message translates to:
  /// **'Datum und Zeit'**
  String get sessionFieldDatetime;

  /// session.impact.count
  ///
  /// In de, this message translates to:
  /// **'Einheiten gesamt'**
  String get sessionImpactCount;

  /// Board 07, folgen
  ///
  /// In de, this message translates to:
  /// **'Längste Pause'**
  String get sessionImpactLongest;

  /// Board 07, folgen
  ///
  /// In de, this message translates to:
  /// **'Einheiten {month}'**
  String sessionImpactMonth(String month);

  /// Board 07, loeschFolgen
  ///
  /// In de, this message translates to:
  /// **'{kind}-Einheiten'**
  String sessionImpactOfKind(String kind);

  /// session.impact.pause
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Pause'**
  String get sessionImpactPause;

  /// session.impact.preview
  ///
  /// In de, this message translates to:
  /// **'Vorschau, noch nicht gespeichert.'**
  String get sessionImpactPreview;

  /// session.impact.title
  ///
  /// In de, this message translates to:
  /// **'Was sich dadurch ändert'**
  String get sessionImpactTitle;

  /// sets.add
  ///
  /// In de, this message translates to:
  /// **'Sätze nachtragen'**
  String get setsAdd;

  /// Der erklärungsbedürftige Teil
  ///
  /// In de, this message translates to:
  /// **'Dein Zugang bleibt bestehen'**
  String get settingsDeletedAccessTitle;

  /// settings.entry.a11y
  ///
  /// In de, this message translates to:
  /// **'Profil und Einstellungen'**
  String get settingsEntryA11y;

  /// Rückmeldung
  ///
  /// In de, this message translates to:
  /// **'{n} Dokumente gesichert'**
  String settingsExportDone(int n);

  /// Fehlermeldung
  ///
  /// In de, this message translates to:
  /// **'Sichern fehlgeschlagen'**
  String get settingsExportFailed;

  /// Ladezustand
  ///
  /// In de, this message translates to:
  /// **'Wird gesammelt …'**
  String get settingsExportRunning;

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get settingsSignOut;

  /// Vorlesetext des Dialogschleiers
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get settingsSignOutBarrier;

  /// Bestätigung, Text
  ///
  /// In de, this message translates to:
  /// **'Deine Daten bleiben. Du kannst dich jederzeit wieder anmelden.'**
  String get settingsSignOutBody;

  /// Bestätigung
  ///
  /// In de, this message translates to:
  /// **'Abmelden?'**
  String get settingsSignOutTitle;

  /// settings.title
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// Text im Start-Sheet beim freien Training
  ///
  /// In de, this message translates to:
  /// **'Ohne Plan starten — Übungen fügst du im Training hinzu.'**
  String get sheetFreeBody;

  /// sheet.picker.apply (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get sheetPickerApply;

  /// Zeile im Start-Sheet
  ///
  /// In de, this message translates to:
  /// **'Standard-Pause'**
  String get sheetRestLabel;

  /// Bestätigung im Start-Sheet
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get sheetStart;

  /// Titel des Start-Sheets
  ///
  /// In de, this message translates to:
  /// **'{plan} starten?'**
  String sheetStartTitle(String plan);

  /// signout.keep
  ///
  /// In de, this message translates to:
  /// **'Daten bleiben'**
  String get signoutKeep;

  /// Ansage während des unentschiedenen ersten Moments
  ///
  /// In de, this message translates to:
  /// **'ATEM startet …'**
  String get splashStarting;

  /// switch.off
  ///
  /// In de, this message translates to:
  /// **'AUS'**
  String get switchOff;

  /// switch.on
  ///
  /// In de, this message translates to:
  /// **'AN'**
  String get switchOn;

  /// tab.cardio
  ///
  /// In de, this message translates to:
  /// **'Cardio'**
  String get tabCardio;

  /// tab.hybrid
  ///
  /// In de, this message translates to:
  /// **'Hybrid'**
  String get tabHybrid;

  /// tab.strength
  ///
  /// In de, this message translates to:
  /// **'Kraft'**
  String get tabStrength;

  /// Trainingsart eines Plans
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht'**
  String get typeBodyweight;

  /// Trainingsart
  ///
  /// In de, this message translates to:
  /// **'Cardio'**
  String get typeCardio;

  /// Trainingsart eines Plans
  ///
  /// In de, this message translates to:
  /// **'Hybrid'**
  String get typeHybrid;

  /// Trainingsart
  ///
  /// In de, this message translates to:
  /// **'Regeneration'**
  String get typeRecovery;

  /// Trainingsart eines Plans
  ///
  /// In de, this message translates to:
  /// **'Kraft'**
  String get typeStrength;

  /// Gewicht mit Einheit
  ///
  /// In de, this message translates to:
  /// **'{v} kg'**
  String unitKilograms(String v);

  /// Strecke mit Einheit
  ///
  /// In de, this message translates to:
  /// **'{v} km'**
  String unitKilometers(String v);

  /// Einheit hinter einem Zahlenfeld
  ///
  /// In de, this message translates to:
  /// **'kg'**
  String get unitSuffixKilograms;

  /// Einheit hinter einem Zahlenfeld
  ///
  /// In de, this message translates to:
  /// **'lb'**
  String get unitSuffixPounds;

  /// Einheit hinter einem Zahlenfeld
  ///
  /// In de, this message translates to:
  /// **'s'**
  String get unitSuffixSeconds;

  /// units.example
  ///
  /// In de, this message translates to:
  /// **'So sieht es dann aus'**
  String get unitsExample;

  /// units.imperial
  ///
  /// In de, this message translates to:
  /// **'Imperial'**
  String get unitsImperial;

  /// units.metric
  ///
  /// In de, this message translates to:
  /// **'Metrisch'**
  String get unitsMetric;

  /// units.note
  ///
  /// In de, this message translates to:
  /// **'Gespeichert bleibt immer metrisch. Umgerechnet wird nur die Anzeige.'**
  String get unitsNote;

  /// units.title
  ///
  /// In de, this message translates to:
  /// **'Einheitensystem'**
  String get unitsTitle;

  /// unsaved.body
  ///
  /// In de, this message translates to:
  /// **'Du hast {c, plural, one {{c} Eintrag} other {{c} Einträge}} geändert und {a} hinzugefügt.'**
  String unsavedBody(int c, int a);

  /// unsaved.continue
  ///
  /// In de, this message translates to:
  /// **'Weiter bearbeiten'**
  String get unsavedContinue;

  /// unsaved.discard
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get unsavedDiscard;

  /// unsaved.save
  ///
  /// In de, this message translates to:
  /// **'Sichern und schließen'**
  String get unsavedSave;

  /// unsaved.title
  ///
  /// In de, this message translates to:
  /// **'Änderungen behalten?'**
  String get unsavedTitle;

  /// Board 14 (20.09.2026): Der Wert bewertet nicht mehr den ganzen Verlauf neu, sondern je Einheit den Tag, an dem sie stattfand
  ///
  /// In de, this message translates to:
  /// **'Grundlage jeder Eigengewichts-Rechnung'**
  String get weightSub;

  /// weight.title
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht'**
  String get weightTitle;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Workout beenden'**
  String get workoutA11yEnd;

  /// Runner 18.09.2026 — der Chip öffnet die Anleitung der Übung, kein Video
  ///
  /// In de, this message translates to:
  /// **'Anleitung zu {exercise} öffnen'**
  String workoutA11yFormGuide(String exercise);

  /// Vorlesetext
  ///
  /// In de, this message translates to:
  /// **'Haltezeit in Sekunden, Satz {n}'**
  String workoutA11yHoldField(int n);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Workout wird geladen'**
  String get workoutA11yLoading;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Nächste Übung'**
  String get workoutA11yNextExercise;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Training pausieren'**
  String get workoutA11yPause;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Vorherige Übung'**
  String get workoutA11yPrevExercise;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen, Satz {n}'**
  String workoutA11yRepsField(int n);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Pause um 30 Sekunden verlängern'**
  String get workoutA11yRestExtend;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Pause: {time} verbleibend'**
  String workoutA11yRestRemaining(String time);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Pause um 15 Sekunden verkürzen'**
  String get workoutA11yRestShorten;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Pause überspringen'**
  String get workoutA11yRestSkip;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Training fortsetzen'**
  String get workoutA11yResume;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Satz {n} abschließen'**
  String workoutA11ySetComplete(int n);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Satztyp: {type}. Tippen zum Ändern'**
  String workoutA11ySetType(String type);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Satz {n} entsperren'**
  String workoutA11ySetUnlock(int n);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Gewicht in Kilogramm, Satz {n}'**
  String workoutA11yWeightField(int n);

  /// Spaltenkopf im Satzprotokoll
  ///
  /// In de, this message translates to:
  /// **'Halten'**
  String get workoutColHold;

  /// aus workout.exercise.progress
  ///
  /// In de, this message translates to:
  /// **'{completed} / {total} Übungen'**
  String workoutExerciseProgress(String completed, int total);

  /// Zurück-Geste, Text
  ///
  /// In de, this message translates to:
  /// **'Dein Stand bleibt gesichert. Du kannst später fortsetzen.'**
  String get workoutLeaveBody;

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Verlassen und sichern'**
  String get workoutLeaveKeep;

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Weiter trainieren'**
  String get workoutLeaveStay;

  /// Zurück-Geste im Runner
  ///
  /// In de, this message translates to:
  /// **'Training verlassen?'**
  String get workoutLeaveTitle;

  /// aus workout.logging.addExercise
  ///
  /// In de, this message translates to:
  /// **'Übung hinzufügen'**
  String get workoutLoggingAddExercise;

  /// aus workout.logging.sets
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get workoutLoggingSets;

  /// aus workout.postWorkout.sets
  ///
  /// In de, this message translates to:
  /// **'Sets'**
  String get workoutPostWorkoutSets;

  /// Letztes Mal, ohne Gewicht — Körpergewichtsübung
  ///
  /// In de, this message translates to:
  /// **'{reps} Wdh.'**
  String workoutPreviousReps(int reps);

  /// Was beim letzten Mal an dieser Stelle stand
  ///
  /// In de, this message translates to:
  /// **'{weight} kg × {reps}'**
  String workoutPreviousSet(String weight, int reps);

  /// Letztes Mal, ohne Wiederholungszahl
  ///
  /// In de, this message translates to:
  /// **'{weight} kg'**
  String workoutPreviousWeight(String weight);

  /// Schwerstes je protokolliertes Gewicht dieser Übung
  ///
  /// In de, this message translates to:
  /// **'PR {weight} kg'**
  String workoutRecordKg(String weight);

  /// aus workout.relativeTime.daysAgo
  ///
  /// In de, this message translates to:
  /// **'vor {n} Tagen'**
  String workoutRelativeTimeDaysAgo(int n);

  /// aus workout.relativeTime.weeksAgo
  ///
  /// In de, this message translates to:
  /// **'vor {n} Wochen'**
  String workoutRelativeTimeWeeksAgo(int n);

  /// Bestätigung, Text
  ///
  /// In de, this message translates to:
  /// **'Die abgehakten Sätze dieser Übung gehen verloren.'**
  String get workoutRemoveExerciseBody;

  /// Bestätigung beim Entfernen im Training
  ///
  /// In de, this message translates to:
  /// **'{name} entfernen?'**
  String workoutRemoveExerciseConfirm(String name);

  /// Zwischenstand, Text
  ///
  /// In de, this message translates to:
  /// **'Du hast vor {n} ein Training begonnen. {sets} von {total} Sätzen sind abgehakt.'**
  String workoutResumeBody(String n, int sets, int total);

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get workoutResumeContinue;

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Neu beginnen'**
  String get workoutResumeDiscard;

  /// Zwischenstand gefunden
  ///
  /// In de, this message translates to:
  /// **'Training fortsetzen?'**
  String get workoutResumeTitle;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'+ SATZ HINZUFÜGEN'**
  String get workoutRunnerAddSet;

  /// Leerer Runner, Text
  ///
  /// In de, this message translates to:
  /// **'Füge hinzu, was du machst. Die Einheit wächst mit.'**
  String get workoutRunnerEmptyBody;

  /// Leerer Runner beim freien Training
  ///
  /// In de, this message translates to:
  /// **'Noch keine Übung'**
  String get workoutRunnerEmptyTitle;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'FORM GUIDE'**
  String get workoutRunnerFormGuide;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Workout nicht verfügbar'**
  String get workoutRunnerNotAvailable;

  /// Aktion am Übungskopf im Runner
  ///
  /// In de, this message translates to:
  /// **'Übung entfernen'**
  String get workoutRunnerRemoveExercise;

  /// Vorlesetext der Entfernen-Aktion
  ///
  /// In de, this message translates to:
  /// **'{name} aus der Einheit entfernen'**
  String workoutRunnerRemoveExerciseA11y(String name);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'PAUSE'**
  String get workoutRunnerRestLabel;

  /// Runner 18.09.2026 — ohne Einheit: Auf dem 70-dp-Knopf brach „−15 s“ zeichenweise um; die Sekunde steht im Vorlese-Label
  ///
  /// In de, this message translates to:
  /// **'−15'**
  String get workoutRunnerRestMinus;

  /// Runner 18.09.2026 — ohne Einheit: Auf dem 70-dp-Knopf brach „+30 s“ zeichenweise um; die Sekunde steht im Vorlese-Label
  ///
  /// In de, this message translates to:
  /// **'+30'**
  String get workoutRunnerRestPlus;

  /// Runner 18.09.2026 — ohne Pfeil: Poppins zeichnet → nicht, auf dem Gerät stand ein leeres Kästchen
  ///
  /// In de, this message translates to:
  /// **'WEITER'**
  String get workoutRunnerRestSkip;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Session gespeichert'**
  String get workoutRunnerSaved;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'FERTIG'**
  String get workoutRunnerSavedDone;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Speichern fehlgeschlagen'**
  String get workoutRunnerSavedFailed;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'SESSION'**
  String get workoutRunnerSessionLabel;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{done} VON {total} SÄTZEN ABGESCHLOSSEN'**
  String workoutRunnerSetsCompleted(int done, int total);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{sets} Sätze · {time} · {volume} kg Volumen'**
  String workoutRunnerSummary(int sets, String time, String volume);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get workoutRunnerTableDone;

  /// Runner, Tabellenkopf Spalte 2 (Vorlage TEM Workout Runner)
  ///
  /// In de, this message translates to:
  /// **'LETZTES MAL'**
  String get workoutRunnerTableLast;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'WDH'**
  String get workoutRunnerTableReps;

  /// Runner, Tabellenkopf Spalte 1 (Vorlage TEM Workout Runner)
  ///
  /// In de, this message translates to:
  /// **'SATZ'**
  String get workoutRunnerTableSet;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'KG'**
  String get workoutRunnerTableWeight;

  /// aus workout.screen.addSet
  ///
  /// In de, this message translates to:
  /// **'Satz hinzufügen'**
  String get workoutScreenAddSet;

  /// aus workout.screen.discardConfirm
  ///
  /// In de, this message translates to:
  /// **'Workout wirklich verwerfen? Alle Fortschritte gehen verloren.'**
  String get workoutScreenDiscardConfirm;

  /// aus workout.screen.discardConfirmTitle
  ///
  /// In de, this message translates to:
  /// **'Workout verwerfen?'**
  String get workoutScreenDiscardConfirmTitle;

  /// aus workout.screen.discardWorkout
  ///
  /// In de, this message translates to:
  /// **'Workout verwerfen'**
  String get workoutScreenDiscardWorkout;

  /// aus workout.screen.endWorkout
  ///
  /// In de, this message translates to:
  /// **'Workout beenden'**
  String get workoutScreenEndWorkout;

  /// aus workout.screen.endWorkoutAction
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get workoutScreenEndWorkoutAction;

  /// aus workout.screen.endWorkoutConfirm
  ///
  /// In de, this message translates to:
  /// **'Workout wirklich beenden?'**
  String get workoutScreenEndWorkoutConfirm;

  /// aus workout.screen.endWorkoutConfirmText
  ///
  /// In de, this message translates to:
  /// **'Alle bisherigen Sätze werden gespeichert.'**
  String get workoutScreenEndWorkoutConfirmText;

  /// aus workout.screen.exerciseOf
  ///
  /// In de, this message translates to:
  /// **'Übung {current} von {total}'**
  String workoutScreenExerciseOf(int current, int total);

  /// aus workout.screen.exerciseProgress
  ///
  /// In de, this message translates to:
  /// **'{completed} / {total} Übungen'**
  String workoutScreenExerciseProgress(String completed, int total);

  /// aus workout.screen.exercisesButton
  ///
  /// In de, this message translates to:
  /// **'Übungen ({completed}/{total})'**
  String workoutScreenExercisesButton(String completed, int total);

  /// aus workout.setLogger.rest
  ///
  /// In de, this message translates to:
  /// **'{seconds}s Pause'**
  String workoutSetLoggerRest(int seconds);

  /// aus workout.setLogger.stepModeChanged
  ///
  /// In de, this message translates to:
  /// **'Schrittweite: {step} {unit}'**
  String workoutSetLoggerStepModeChanged(int step, String unit);

  /// aus workout.setLogger.targetReps
  ///
  /// In de, this message translates to:
  /// **'{reps} Wdh'**
  String workoutSetLoggerTargetReps(int reps);

  /// aus workout.setLogger.targetSets
  ///
  /// In de, this message translates to:
  /// **'{sets} Sätze'**
  String workoutSetLoggerTargetSets(int sets);

  /// aus workout.setLogger.title
  ///
  /// In de, this message translates to:
  /// **'Satz {number} loggen'**
  String workoutSetLoggerTitle(int number);

  /// aus workout.setLogger.weightUnit
  ///
  /// In de, this message translates to:
  /// **'kg'**
  String get workoutSetLoggerWeightUnit;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Dropsatz'**
  String get workoutSetTypeDropset;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Satz bis zum Muskelversagen'**
  String get workoutSetTypeFailure;

  /// Legende der Satz-Kürzel — sie stehen sonst unerklärt in der Zeile
  ///
  /// In de, this message translates to:
  /// **'{w} Aufwärmen · {n} Normal · {d} Dropsatz · {f} Failure'**
  String workoutSetTypeLegend(String w, String n, String d, String f);

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Normaler Satz'**
  String get workoutSetTypeNormal;

  /// Einbuchstabiges Kürzel im Satz-Chip. Sprachabhängig: DE Aufwärmsatz/Normal/Dropsatz/Failure.
  ///
  /// In de, this message translates to:
  /// **'D'**
  String get workoutSetTypeShortDropset;

  /// Einbuchstabiges Kürzel im Satz-Chip. Sprachabhängig: DE Aufwärmsatz/Normal/Dropsatz/Failure.
  ///
  /// In de, this message translates to:
  /// **'F'**
  String get workoutSetTypeShortFailure;

  /// Einbuchstabiges Kürzel im Satz-Chip. Sprachabhängig: DE Aufwärmsatz/Normal/Dropsatz/Failure.
  ///
  /// In de, this message translates to:
  /// **'N'**
  String get workoutSetTypeShortNormal;

  /// Einbuchstabiges Kürzel im Satz-Chip. Sprachabhängig: DE Aufwärmsatz/Normal/Dropsatz/Failure.
  ///
  /// In de, this message translates to:
  /// **'W'**
  String get workoutSetTypeShortWarmup;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Aufwärmsatz'**
  String get workoutSetTypeWarmup;

  /// Haltevorgabe aus dem Plan
  ///
  /// In de, this message translates to:
  /// **'Ziel {n} s halten'**
  String workoutTargetHold(int n);

  /// Zielvorgabe aus dem Plan, neben dem Feld
  ///
  /// In de, this message translates to:
  /// **'Ziel {reps}'**
  String workoutTargetReps(String reps);

  /// Aktion für Training ohne Plan
  ///
  /// In de, this message translates to:
  /// **'Freies Training starten'**
  String get workoutsFreeStart;

  /// Aktion im Leerzustand
  ///
  /// In de, this message translates to:
  /// **'Plan wählen'**
  String get workoutsPlanPick;

  /// Öffnet die vollständige Planliste
  ///
  /// In de, this message translates to:
  /// **'Alle {n}'**
  String workoutsPlansAll(int n);

  /// Abschnittslabel Pläne
  ///
  /// In de, this message translates to:
  /// **'Pläne'**
  String get workoutsPlansLabel;

  /// Aktion auf der Session-Karte
  ///
  /// In de, this message translates to:
  /// **'Training starten'**
  String get workoutsStart;

  /// Leerzustand, Text
  ///
  /// In de, this message translates to:
  /// **'Starte frei oder wähle einen Plan.'**
  String get workoutsTodayEmptyBody;

  /// Leerzustand für heute
  ///
  /// In de, this message translates to:
  /// **'Kein Training geplant'**
  String get workoutsTodayEmptyTitle;

  /// Abschnittslabel über der Session-Karte
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get workoutsTodayLabel;

  /// analysis.pace.basis (Board 11) — Fassung für alle Aktivitäten außer Laufen
  ///
  /// In de, this message translates to:
  /// **'gegen eigenen Schnitt {value} · {n, plural, one{1 Einheit} other{{n} Einheiten}}'**
  String analysisPaceBasisOther(String value, int n);

  /// analysis.pct.faster (Board 11) — Fassung für alle Aktivitäten außer Laufen
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{Schneller als 1 deiner Einheiten} other{Schneller als {n} von {total} deiner Einheiten}}'**
  String analysisPctFasterOther(int n, int total);

  /// intensity.fallback.note (Board 11) — Fassung für alle Aktivitäten außer Laufen
  ///
  /// In de, this message translates to:
  /// **'Weder Puls noch RPE erfasst. Beurteilt wird über das Tempo gegen {n, plural, one{1 Einheit} other{{n} Einheiten}} derselben Aktivität.'**
  String intensityFallbackNoteOther(int n);

  /// Ergänzung zu Board 11 — Zonenname Stufe 1; das Board nennt nur „schwellig" als Beispiel
  ///
  /// In de, this message translates to:
  /// **'regenerativ'**
  String get intensityZoneName1;

  /// Ergänzung zu Board 11 — Zonenname
  ///
  /// In de, this message translates to:
  /// **'grundlagig'**
  String get intensityZoneName2;

  /// Ergänzung zu Board 11 — Zonenname, Beispiel aus B4/B
  ///
  /// In de, this message translates to:
  /// **'schwellig'**
  String get intensityZoneName3;

  /// Ergänzung zu Board 11 — Zonenname
  ///
  /// In de, this message translates to:
  /// **'hart'**
  String get intensityZoneName4;

  /// Ergänzung zu Board 11 — Zonenname
  ///
  /// In de, this message translates to:
  /// **'maximal'**
  String get intensityZoneName5;

  /// Ergänzung zu Board 11 — Vorlesetext der Intensitätskapsel (H)
  ///
  /// In de, this message translates to:
  /// **'Grundlage: {basis}'**
  String intensityBasisA11y(String basis);

  /// Ergänzung zu Board 11 — Grundlage der Stufe 3 mit Nenner
  ///
  /// In de, this message translates to:
  /// **'Tempo gegen eigenen Schnitt aus {n, plural, one{1 Einheit} other{{n} Einheiten}}'**
  String intensityBasisPace(int n);

  /// Ergänzung zu Board 11 — RPE als Bruch, nie in Prozent (J)
  ///
  /// In de, this message translates to:
  /// **'{n} / 5'**
  String intensityRpeValue(int n);

  /// Ergänzung zu Board 11 — RPE-Wort, das Board nennt 1, 3 und 5
  ///
  /// In de, this message translates to:
  /// **'leicht'**
  String get formRpe2;

  /// Ergänzung zu Board 11 — RPE-Wort
  ///
  /// In de, this message translates to:
  /// **'hart'**
  String get formRpe4;

  /// Ergänzung zu Board 11 — Segment im Formular (B2/1)
  ///
  /// In de, this message translates to:
  /// **'Nacherfassen'**
  String get formModeLog;

  /// Ergänzung zu Board 11 — Segment im Formular (B2/1)
  ///
  /// In de, this message translates to:
  /// **'Live'**
  String get formModeLive;

  /// Ergänzung zu Board 11 — Titel des Formulars (B2/1)
  ///
  /// In de, this message translates to:
  /// **'Ausdauer erfassen'**
  String get cardioFormTitle;

  /// Ergänzung zu Board 11 — Feldlabel im Regenerationssheet (C2/2)
  ///
  /// In de, this message translates to:
  /// **'Art'**
  String get formKind;

  /// Ergänzung zu Board 11 — Feldfehler inline
  ///
  /// In de, this message translates to:
  /// **'Dauer fehlt'**
  String get formDurationRequired;

  /// Ergänzung zu Board 11 — Feldfehler inline
  ///
  /// In de, this message translates to:
  /// **'Aktivität fehlt'**
  String get formActivityRequired;

  /// Ergänzung zu Board 11 — Feldfehler inline
  ///
  /// In de, this message translates to:
  /// **'Distanz ungültig'**
  String get formDistanceInvalid;

  /// Ergänzung zu Board 11 — Meldung mit 30-s-Widerruf (I, Modul 7)
  ///
  /// In de, this message translates to:
  /// **'Einheit gespeichert · {activity}'**
  String cardioSavedSnack(String activity);

  /// Ergänzung zu Board 11 — Meldung mit 30-s-Widerruf
  ///
  /// In de, this message translates to:
  /// **'Regeneration gespeichert'**
  String get recoverySavedSnack;

  /// Ergänzung zu Board 11 — Knopf der Live-Uhr im pausierten Zustand
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get liveResume;

  /// Ergänzung zu Board 11 — Vorlesetext des gesperrten Knopfs (H)
  ///
  /// In de, this message translates to:
  /// **'Beenden, nicht möglich — Einheit unter einer Minute.'**
  String get liveStopTooShort;

  /// Ergänzung zu Board 11 — Zusatz am Tempo der Live-Uhr (B2/3)
  ///
  /// In de, this message translates to:
  /// **'läuft mit'**
  String get livePaceRunning;

  /// Ergänzung zu Board 11 — Wiederaufnahme aus der Persistenz (Matrix: Erfassen · Live)
  ///
  /// In de, this message translates to:
  /// **'Live-Uhr läuft · {time}'**
  String liveRunningNotice(String time);

  /// Ergänzung zu Board 11 — Vorlesetext der Uhr (H)
  ///
  /// In de, this message translates to:
  /// **'Dauer {time}, {state}'**
  String liveDurationA11y(String time, String state);

  /// Ergänzung zu Board 11 — Vorlesetext des Wochenstreifens (H)
  ///
  /// In de, this message translates to:
  /// **'Wochenkilometer der letzten 8 Wochen, von {from} bis {to}.'**
  String analysisWeeklyA11y(String from, String to);

  /// Ergänzung zu Board 11 — Die Lücke wird genannt (H)
  ///
  /// In de, this message translates to:
  /// **'KW {kw} ohne Einheit'**
  String analysisWeeklyGapA11y(int kw);

  /// Ergänzung zu Board 11 — Beschriftung eines Balkens
  ///
  /// In de, this message translates to:
  /// **'KW {kw}'**
  String analysisWeeklyWeek(int kw);

  /// Ergänzung zu Board 11 — Kopf der Perzentilkarte (B3/3)
  ///
  /// In de, this message translates to:
  /// **'Diese Einheit · {date}'**
  String analysisPctThis(String date);

  /// Ergänzung zu Board 11 — Spanne (B3/3)
  ///
  /// In de, this message translates to:
  /// **'langsamster'**
  String get analysisPctSlowest;

  /// Ergänzung zu Board 11 — Spanne (B3/3)
  ///
  /// In de, this message translates to:
  /// **'schnellster'**
  String get analysisPctFastest;

  /// Ergänzung zu Board 11 — Schnitt und Spanne, wenn Perzentil fehlt
  ///
  /// In de, this message translates to:
  /// **'Schnitt {value} · Spanne {from} bis {to}'**
  String analysisPaceRange(String value, String from, String to);

  /// Ergänzung zu Board 11 — Verteilungsklasse
  ///
  /// In de, this message translates to:
  /// **'< {v} km'**
  String distBucketBelow(String v);

  /// Ergänzung zu Board 11 — Verteilungsklasse
  ///
  /// In de, this message translates to:
  /// **'{a}–{b} km'**
  String distBucketRange(String a, String b);

  /// Ergänzung zu Board 11 — Verteilungsklasse
  ///
  /// In de, this message translates to:
  /// **'> {v} km'**
  String distBucketAbove(String v);

  /// Ergänzung zu Board 11 — Listenkopf im dünnen Zustand (B1/1)
  ///
  /// In de, this message translates to:
  /// **'Alle Einheiten'**
  String get cardioAllSessions;

  /// Ergänzung zu Board 11 — Vorlesetext der Wochenzahl (H)
  ///
  /// In de, this message translates to:
  /// **'{km} Kilometer diese Woche, aus {n, plural, one{1 Einheit} other{{n} Einheiten}}'**
  String cardioWeekA11y(String km, int n);

  /// Ergänzung zu Board 11 — Vorlesetext der Verschiebung; dir ist „mehr"/„weniger"
  ///
  /// In de, this message translates to:
  /// **'{delta} {dir} als der 4-Wochen-Schnitt von {avg}'**
  String cardioWeekShiftA11y(String delta, String dir, String avg);

  /// Ergänzung zu Board 11 — Vorlesetext im dünnen Zustand
  ///
  /// In de, this message translates to:
  /// **'{km} Kilometer gesamt seit {date}, aus {n, plural, one{1 Einheit} other{{n} Einheiten}}'**
  String cardioTotalA11y(String km, String date, int n);

  /// Ergänzung zu Board 11 — „3 Einheiten · 128 min"
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Einheit} other{{n} Einheiten}} · {min} min'**
  String hybridWeekSummary(int n, int min);

  /// Ergänzung zu Board 11 — Zielort im Label (H)
  ///
  /// In de, this message translates to:
  /// **'Öffnet Kraft-Verlauf'**
  String get ratioOpenStrength;

  /// Ergänzung zu Board 11 — Zielort im Label (H)
  ///
  /// In de, this message translates to:
  /// **'Öffnet Ausdauer-Auswertung'**
  String get ratioOpenCardio;

  /// Ergänzung zu Board 11 — Vorlesetext der Verschiebung
  ///
  /// In de, this message translates to:
  /// **'{value} Prozentpunkte {dir} als im 4-Wochen-Schnitt'**
  String ratioShiftA11y(String value, String dir);

  /// Ergänzung zu Board 11 — Leerer Hybrid-Tab (C3/2)
  ///
  /// In de, this message translates to:
  /// **'Krafttraining starten'**
  String get hybridEmptyStrength;

  /// Ergänzung zu Board 11 — Leerer Hybrid-Tab und Hinweiszeile (C1/2, C3/2)
  ///
  /// In de, this message translates to:
  /// **'Ausdauer erfassen'**
  String get hybridEmptyCardio;

  /// Ergänzung zu Board 11 — Zeitwort in der Regenerationszeile
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get whenToday;

  /// Ergänzung zu Board 11 — Zeitwort in der Regenerationszeile
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get whenYesterday;

  /// Ergänzung zu Board 11 — Zeitwort in der Regenerationszeile (C2/1)
  ///
  /// In de, this message translates to:
  /// **'Zuletzt {date}'**
  String whenLast(String date);

  /// Ergänzung zu Board 11 — Titel des Sheets (C2/2)
  ///
  /// In de, this message translates to:
  /// **'Regeneration erfassen'**
  String get recoveryFormTitle;

  /// Ergänzung zu Board 11 — Tempo in min/km — die Einheit steht im Wert
  ///
  /// In de, this message translates to:
  /// **'{value} /km'**
  String tempoPerKm(String value);

  /// Ergänzung zu Board 11 — Tempo in km/h
  ///
  /// In de, this message translates to:
  /// **'{value} km/h'**
  String tempoKmh(String value);

  /// Ergänzung zu Board 11 — Zahl in der Aktivitätskapsel
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Einheit} other{{n} Einheiten}}'**
  String cardioListCount(int n);

  /// Ergänzung zu Board 11 — Beschriftung im Intensitätskasten (B4)
  ///
  /// In de, this message translates to:
  /// **'Intensität'**
  String get intensityTitle;

  /// Board 06 — ACWR-Skala, Kopfzeile (A1/2)
  ///
  /// In de, this message translates to:
  /// **'Belastung · ACWR {v}'**
  String acwrLabel(String v);

  /// Board 06 — ACWR-Band 0–0,8
  ///
  /// In de, this message translates to:
  /// **'unterfordert'**
  String get acwrBandLow;

  /// Board 06 — ACWR-Band 0,8–1,3
  ///
  /// In de, this message translates to:
  /// **'optimal'**
  String get acwrBandOptimal;

  /// Board 06 — ACWR-Band 1,3–1,5
  ///
  /// In de, this message translates to:
  /// **'erhöht'**
  String get acwrBandHigh;

  /// Board 06 — ACWR-Band über 1,5
  ///
  /// In de, this message translates to:
  /// **'kritisch'**
  String get acwrBandDanger;

  /// Board 06 — Satz zur Zone
  ///
  /// In de, this message translates to:
  /// **'Zone unterfordert — akute Last liegt unter der chronischen.'**
  String get acwrBandNoteLow;

  /// Board 06 — Satz zur Zone (A1/2)
  ///
  /// In de, this message translates to:
  /// **'Zone optimal — akute Last passt zur chronischen.'**
  String get acwrBandNoteOptimal;

  /// Board 06 — Satz zur Zone
  ///
  /// In de, this message translates to:
  /// **'Zone erhöht — akute Last übersteigt die chronische.'**
  String get acwrBandNoteHigh;

  /// Board 06 — Satz zur Zone
  ///
  /// In de, this message translates to:
  /// **'Zone kritisch — akute Last weit über der chronischen.'**
  String get acwrBandNoteDanger;

  /// Board 06 — Vorlesetext der ACWR-Skala (G)
  ///
  /// In de, this message translates to:
  /// **'Belastung {v}, Zone {zone}, Bereich {from} bis {to}.'**
  String acwrScaleA11y(String v, String zone, String from, String to);

  /// Board 06 — Monatsbalken, 48-dp-Treffer (I/08)
  ///
  /// In de, this message translates to:
  /// **'{month}, {n, plural, one{1 Einheit} other{{n} Einheiten}}, öffnet die Liste'**
  String historyMonthOpenA11y(String month, int n);

  /// Board 07 A3/1 — Hauptaktion im Übungsdetail
  ///
  /// In de, this message translates to:
  /// **'Zu Plan hinzufügen'**
  String get exerciseAddToPlan;

  /// Board 07 — Meldung nach dem Hinzufügen
  ///
  /// In de, this message translates to:
  /// **'Zu „{plan}\" hinzugefügt'**
  String exerciseAddedToPlan(String plan);

  /// Board 07 A2 — Zähler im Kopf, vorgelesen
  ///
  /// In de, this message translates to:
  /// **'{n} von 3 Pflichtfeldern ausgefüllt'**
  String exerciseRequiredA11y(int n);

  /// Board 07 A2/2 — „Mehr Angaben 2 GEFÜLLT"
  ///
  /// In de, this message translates to:
  /// **'{n} gefüllt'**
  String exerciseMoreFilled(int n);

  /// Board 07 A5/1 — Feldlabel
  ///
  /// In de, this message translates to:
  /// **'Art'**
  String get sessionFieldKind;

  /// Board 07 A5/1
  ///
  /// In de, this message translates to:
  /// **'Die Art bestimmt, welche Werte unten stehen.'**
  String get sessionKindNote;

  /// Board 07 A5/1
  ///
  /// In de, this message translates to:
  /// **'Tempo wird berechnet und ist nicht eingebbar.'**
  String get sessionPaceNote;

  /// Board 07 A1/3 — Gruppe der Herkunftsfilter
  ///
  /// In de, this message translates to:
  /// **'Herkunft'**
  String get exercisesFilterOrigin;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Gruppenlabel der Selbstauskunft vor der Einheit
  ///
  /// In de, this message translates to:
  /// **'Bereitschaft'**
  String get formReadiness;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Hinweis unter der Bereitschaftsauswahl
  ///
  /// In de, this message translates to:
  /// **'Vor dem Training. Freiwillig.'**
  String get formReadinessHint;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Bereitschaft, Stufe 1
  ///
  /// In de, this message translates to:
  /// **'erschöpft'**
  String get formReadiness1;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Bereitschaft, Stufe 2
  ///
  /// In de, this message translates to:
  /// **'müde'**
  String get formReadiness2;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Bereitschaft, Stufe 3
  ///
  /// In de, this message translates to:
  /// **'okay'**
  String get formReadiness3;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Bereitschaft, Stufe 4
  ///
  /// In de, this message translates to:
  /// **'gut'**
  String get formReadiness4;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Bereitschaft, Stufe 5
  ///
  /// In de, this message translates to:
  /// **'frisch'**
  String get formReadiness5;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Gruppenlabel der Selbstauskunft nach der Einheit
  ///
  /// In de, this message translates to:
  /// **'Gefühl danach'**
  String get formFeeling;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Gefühl danach, Stufe 1
  ///
  /// In de, this message translates to:
  /// **'platt'**
  String get formFeeling1;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Gefühl danach, Stufe 2
  ///
  /// In de, this message translates to:
  /// **'müde'**
  String get formFeeling2;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Gefühl danach, Stufe 3
  ///
  /// In de, this message translates to:
  /// **'okay'**
  String get formFeeling3;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Gefühl danach, Stufe 4
  ///
  /// In de, this message translates to:
  /// **'gut'**
  String get formFeeling4;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Gefühl danach, Stufe 5
  ///
  /// In de, this message translates to:
  /// **'stark'**
  String get formFeeling5;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Gruppenlabel der Fokusauswahl einer Krafteinheit
  ///
  /// In de, this message translates to:
  /// **'Fokus'**
  String get formFocus;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Hinweis unter der Fokusauswahl
  ///
  /// In de, this message translates to:
  /// **'Wogegen die Einheit ging. Ersetzt keine Sätze.'**
  String get formFocusHint;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — WorkoutFocus.push
  ///
  /// In de, this message translates to:
  /// **'Drücken'**
  String get focusPush;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — WorkoutFocus.pull
  ///
  /// In de, this message translates to:
  /// **'Ziehen'**
  String get focusPull;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — WorkoutFocus.legs
  ///
  /// In de, this message translates to:
  /// **'Beine'**
  String get focusLegs;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — WorkoutFocus.upperBody
  ///
  /// In de, this message translates to:
  /// **'Oberkörper'**
  String get focusUpperBody;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — WorkoutFocus.lowerBody
  ///
  /// In de, this message translates to:
  /// **'Unterkörper'**
  String get focusLowerBody;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — WorkoutFocus.fullBody
  ///
  /// In de, this message translates to:
  /// **'Ganzkörper'**
  String get focusFullBody;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — WorkoutFocus.core
  ///
  /// In de, this message translates to:
  /// **'Rumpf'**
  String get focusCore;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — WorkoutFocus.other
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get focusOther;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Titel des Nacherfassungs-Formulars
  ///
  /// In de, this message translates to:
  /// **'Krafteinheit erfassen'**
  String get strengthFormTitle;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Hinweis oben im Formular
  ///
  /// In de, this message translates to:
  /// **'Diese Einheit trägt keine Sätze. Sie zählt in Minuten, nicht in Volumen — und erscheint in keiner Muskelverteilung.'**
  String get strengthFormNoSets;

  /// Phase 1 (Masterplan) — kein Board, aus Tokens gebaut — Bestätigung nach dem Speichern
  ///
  /// In de, this message translates to:
  /// **'Krafteinheit gespeichert'**
  String get strengthSavedSnack;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridTimeTitle
  ///
  /// In de, this message translates to:
  /// **'Trainingszeit'**
  String get hybridTimeTitle;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridTimeGroup
  ///
  /// In de, this message translates to:
  /// **'Zeitraum der Trainingszeit'**
  String get hybridTimeGroup;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridTimeDays28
  ///
  /// In de, this message translates to:
  /// **'28 Tage'**
  String get hybridTimeDays28;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridTimeUnits
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Einheit} other{{n} Einheiten}}'**
  String hybridTimeUnits(int n);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridTimeWithoutDuration
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Einheit ohne Dauer nicht enthalten} other{{n} Einheiten ohne Dauer nicht enthalten}}'**
  String hybridTimeWithoutDuration(int n);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridTimeNote
  ///
  /// In de, this message translates to:
  /// **'Kein Sollverhältnis — die App weiss nicht, wie viel Ausdauer oder Regeneration richtig ist.'**
  String get hybridTimeNote;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridTimeRowA11y
  ///
  /// In de, this message translates to:
  /// **'{track}: {minutes} Minuten, {n} Einheiten, {percent} Prozent'**
  String hybridTimeRowA11y(String track, int minutes, int n, int percent);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridTimeEmpty
  ///
  /// In de, this message translates to:
  /// **'Keine Einheit mit Dauer in den letzten {days} Tagen.'**
  String hybridTimeEmpty(int days);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridHeatmapTitle
  ///
  /// In de, this message translates to:
  /// **'Trainingstage'**
  String get hybridHeatmapTitle;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridHeatmapWindow
  ///
  /// In de, this message translates to:
  /// **'{weeks} Wochen'**
  String hybridHeatmapWindow(int weeks);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridHeatmapBasis
  ///
  /// In de, this message translates to:
  /// **'{trained} von {total} Tagen trainiert'**
  String hybridHeatmapBasis(int trained, int total);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridHeatmapByTrack
  ///
  /// In de, this message translates to:
  /// **'{strength} Kraft · {cardio} Cardio · {recovery} Regeneration'**
  String hybridHeatmapByTrack(int strength, int cardio, int recovery);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridHeatmapLegendNone
  ///
  /// In de, this message translates to:
  /// **'kein Training'**
  String get hybridHeatmapLegendNone;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridHeatmapLegendMixed
  ///
  /// In de, this message translates to:
  /// **'mehrere'**
  String get hybridHeatmapLegendMixed;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridHeatmapWeekA11y
  ///
  /// In de, this message translates to:
  /// **'KW {week}: {days} Trainingstage. {detail}'**
  String hybridHeatmapWeekA11y(int week, int days, String detail);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridHeatmapWeekNoneA11y
  ///
  /// In de, this message translates to:
  /// **'KW {week}: kein Training'**
  String hybridHeatmapWeekNoneA11y(int week);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — hybridHeatmapMixed
  ///
  /// In de, this message translates to:
  /// **'{weekday} mehrere Arten'**
  String hybridHeatmapMixed(String weekday);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — analysisMaxTitle
  ///
  /// In de, this message translates to:
  /// **'Geschätztes Maximum'**
  String get analysisMaxTitle;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — analysisMaxHint
  ///
  /// In de, this message translates to:
  /// **'Epley: Gewicht × (1 + Wdh ÷ 30), beste Schätzung je Einheit. Eine Schätzung, kein Test.'**
  String get analysisMaxHint;

  /// Kraft-Auswertung, Geschätztes Maximum — Grundlage, gekürzt am 17.09.2026 (der letzte Wert steht gross darüber)
  ///
  /// In de, this message translates to:
  /// **'{n} Einheiten · Bestwert {best} kg'**
  String analysisMaxBasis(int n, String best);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — analysisMaxDelta
  ///
  /// In de, this message translates to:
  /// **'{delta} kg seit der ersten Einheit'**
  String analysisMaxDelta(String delta);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — analysisMaxDeltaA11y
  ///
  /// In de, this message translates to:
  /// **'{direction} {delta} Kilogramm seit der ersten Einheit'**
  String analysisMaxDeltaA11y(String direction, String delta);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — analysisMaxNoDelta
  ///
  /// In de, this message translates to:
  /// **'kein Vergleich verfügbar'**
  String get analysisMaxNoDelta;

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — analysisMaxThinBody
  ///
  /// In de, this message translates to:
  /// **'Ab {n} Einheiten je Übung mit Gewicht und höchstens {reps} Wiederholungen je Satz.'**
  String analysisMaxThinBody(int n, int reps);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — analysisMaxProgress
  ///
  /// In de, this message translates to:
  /// **'{name}: {cur} von {req} Einheiten'**
  String analysisMaxProgress(String name, int cur, int req);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — analysisMaxChartA11y
  ///
  /// In de, this message translates to:
  /// **'{name}: geschätztes Maximum von {first} auf {last} Kilogramm über {n} Einheiten'**
  String analysisMaxChartA11y(String name, String first, String last, int n);

  /// Auswertung nach Masterplan (16.09.2026) — kein Board, aus Tokens gebaut — analysisMaxExerciseGroup
  ///
  /// In de, this message translates to:
  /// **'Übung für das geschätzte Maximum'**
  String get analysisMaxExerciseGroup;

  /// Board 09 A3 — Muskelbalance-Unterseite (16.09.2026) — balanceSetsShort
  ///
  /// In de, this message translates to:
  /// **'{n} S'**
  String balanceSetsShort(int n);

  /// Board 09 A3 — Muskelbalance-Unterseite (16.09.2026) — balanceGapDays
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Tag} other{{n} Tage}}'**
  String balanceGapDays(int n);

  /// Board 09 A3 — Muskelbalance-Unterseite (16.09.2026) — balanceThinNote
  ///
  /// In de, this message translates to:
  /// **'Ein Anteil aus wenigen Einheiten schwankt um mehr, als er aussagt. Die Kachel zeigt deshalb, wie weit es noch ist, statt eine Verteilung zu zeichnen.'**
  String get balanceThinNote;

  /// Board 09 A3 — Muskelbalance-Unterseite (16.09.2026) — balanceTileA11y
  ///
  /// In de, this message translates to:
  /// **'{title}, {basis}, {window}'**
  String balanceTileA11y(String title, String basis, String window);

  /// Board 09 A3 — Muskelbalance-Unterseite (16.09.2026) — balanceLoading
  ///
  /// In de, this message translates to:
  /// **'Muskelbalance wird geladen'**
  String get balanceLoading;

  /// Board 09 A3 — Muskelbalance-Unterseite (16.09.2026) — balanceErrorTitle
  ///
  /// In de, this message translates to:
  /// **'Muskelbalance nicht verfügbar'**
  String get balanceErrorTitle;

  /// Board 09 A3 — Muskelbalance-Unterseite (16.09.2026) — balanceErrorBody
  ///
  /// In de, this message translates to:
  /// **'Die Einheiten liessen sich gerade nicht laden.'**
  String get balanceErrorBody;

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyFreqBasis
  ///
  /// In de, this message translates to:
  /// **'{n}× in {weeks, plural, =1{1 Woche} other{{weeks} Wochen}}'**
  String historyFreqBasis(int n, int weeks);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyVolumeSub
  ///
  /// In de, this message translates to:
  /// **'letzte Einheit'**
  String get historyVolumeSub;

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyCurveCount
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Einheit} other{{n} Einheiten}}'**
  String historyCurveCount(int n);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyCurveRepsLabel
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen je Einheit'**
  String get historyCurveRepsLabel;

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyRepsValue
  ///
  /// In de, this message translates to:
  /// **'{n} Wdh'**
  String historyRepsValue(int n);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historySetsA11y
  ///
  /// In de, this message translates to:
  /// **'{sets} mal {reps}'**
  String historySetsA11y(int sets, int reps);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historySetsOnlyA11y
  ///
  /// In de, this message translates to:
  /// **'{sets, plural, =1{1 Satz} other{{sets} Sätze}}'**
  String historySetsOnlyA11y(int sets);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyKgA11y
  ///
  /// In de, this message translates to:
  /// **'{v} Kilogramm'**
  String historyKgA11y(String v);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyRepsA11y
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Wiederholung} other{{n} Wiederholungen}}'**
  String historyRepsA11y(int n);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyFreqA11y
  ///
  /// In de, this message translates to:
  /// **'{n} pro Woche'**
  String historyFreqA11y(String n);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyDateA11y
  ///
  /// In de, this message translates to:
  /// **'am {date}'**
  String historyDateA11y(String date);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyTileA11y
  ///
  /// In de, this message translates to:
  /// **'{label}, {value}, {detail}'**
  String historyTileA11y(String label, String value, String detail);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyCountA11y
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{einmal ausgeführt} other{{n} mal ausgeführt}}'**
  String historyCountA11y(int n);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyCurveBestA11y
  ///
  /// In de, this message translates to:
  /// **'Bestwert {best}'**
  String historyCurveBestA11y(String best);

  /// Board 09 A4 (16.09.2026 nachgezogen) — historyCurveRepsA11y
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen je Einheit über {n} Einheiten, von {from} auf {to}'**
  String historyCurveRepsA11y(int n, String from, String to);

  /// Schwellen-Zustand auf Auswertungsbildschirmen (16.09.2026) — kein Board, aus Tokens gebaut — thresholdProgress
  ///
  /// In de, this message translates to:
  /// **'{cur} von {req}'**
  String thresholdProgress(int cur, int req);

  /// Kraft-Auswertung, Block Fokus-Verteilung (16.09.2026) — kein Board, aus Tokens gebaut — Titel
  ///
  /// In de, this message translates to:
  /// **'Fokus'**
  String get focusDistTitle;

  /// Kraft-Auswertung, Block Fokus-Verteilung (16.09.2026) — kein Board, aus Tokens gebaut — Fenster rechts neben dem Titel
  ///
  /// In de, this message translates to:
  /// **'8 Wochen'**
  String get focusDistWindow;

  /// Kraft-Auswertung, Block Fokus-Verteilung (16.09.2026) — kein Board, aus Tokens gebaut — Schwellen-Zustand: was der Block zeigen wird
  ///
  /// In de, this message translates to:
  /// **'Wogegen deine Krafteinheiten gingen — Drücken, Ziehen, Beine und mehr, als Anteil mit Nenner.'**
  String get focusDistWhat;

  /// Kraft-Auswertung, Block Fokus-Verteilung (16.09.2026) — kein Board, aus Tokens gebaut — Schwellen-Zustand: Bedingung
  ///
  /// In de, this message translates to:
  /// **'Ab {n} Einheiten mit Fokus'**
  String focusDistCondition(int n);

  /// Kraft-Auswertung, Block Fokus-Verteilung (16.09.2026) — kein Board, aus Tokens gebaut — Anzahl je Zeile
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Einheit} other{{n} Einheiten}}'**
  String focusDistCount(int n);

  /// Kraft-Auswertung, Block Fokus-Verteilung (16.09.2026) — kein Board, aus Tokens gebaut — eine Zeile als ein Semantics-Knoten
  ///
  /// In de, this message translates to:
  /// **'{focus}, {n, plural, =1{1 Einheit} other{{n} Einheiten}}, {percent} Prozent'**
  String focusDistRowA11y(String focus, int n, int percent);

  /// Kraft-Auswertung, Fokus — Grundlage mit Nenner, gekürzt am 17.09.2026 (Fenster steht im Kopf)
  ///
  /// In de, this message translates to:
  /// **'{withFocus} von {total} Einheiten mit Fokus'**
  String focusDistBasis(int withFocus, int total);

  /// Kraft-Auswertung, Block Fortschritte je Übung (16.09.2026) — Titel
  ///
  /// In de, this message translates to:
  /// **'Fortschritte'**
  String get progressTitle;

  /// Kraft-Auswertung, Fortschritte — Fenster rechts neben dem Titel
  ///
  /// In de, this message translates to:
  /// **'4 Wochen'**
  String get progressWindow;

  /// Kraft-Auswertung, Fortschritte — was der Block zeigen wird (Schwelle)
  ///
  /// In de, this message translates to:
  /// **'Hier stehen die Übungen, bei denen du in den letzten 4 Wochen einen neuen Bestwert gesetzt hast — an Gewicht, Wiederholungen oder Haltezeit.'**
  String get progressWhat;

  /// Kraft-Auswertung, Fortschritte — Bedingung der Schwelle
  ///
  /// In de, this message translates to:
  /// **'Ab der zweiten Ausführung einer Übung'**
  String get progressCondition;

  /// Kraft-Auswertung, Fortschritte — gefüllt, aber ohne Bestwert im Fenster
  ///
  /// In de, this message translates to:
  /// **'Kein neuer Bestwert in den letzten 4 Wochen.'**
  String get progressNone;

  /// Kraft-Auswertung, Fortschritte — Grundlage, gekürzt am 17.09.2026 (Fenster steht im Kopf)
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Übung} other{{n} Übungen}} · {m, plural, =1{1 Einheit} other{{m} Einheiten}}'**
  String progressBasis(int n, int m);

  /// Kraft-Auswertung, Fortschritte — Datum der Zeile
  ///
  /// In de, this message translates to:
  /// **'am {date}'**
  String progressOn(String date);

  /// Kraft-Auswertung, Fortschritte — Wert in Wiederholungen
  ///
  /// In de, this message translates to:
  /// **'{v} Wdh'**
  String progressReps(String v);

  /// Kraft-Auswertung, Fortschritte — Wert in Sekunden
  ///
  /// In de, this message translates to:
  /// **'{v} s'**
  String progressSeconds(String v);

  /// Kraft-Auswertung, Fortschritte — vorheriger Bestwert
  ///
  /// In de, this message translates to:
  /// **'vorher {v}'**
  String progressBefore(String v);

  /// Kraft-Auswertung, Fortschritte — Vorlesetext einer Zeile
  ///
  /// In de, this message translates to:
  /// **'{name}, {value}, vorher {before}, {delta} mehr, am {date}'**
  String progressRowA11y(
      String name, String value, String before, String delta, String date);

  /// Kraft-Auswertung, Fortschritte — Zusatz im Vorlesetext einer antippbaren Zeile
  ///
  /// In de, this message translates to:
  /// **'öffnet Übung'**
  String get progressOpensExercise;

  /// Kraft-Auswertung, Fortschritte — Wiederholungen ausgeschrieben
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Wiederholung} other{{n} Wiederholungen}}'**
  String progressA11yReps(int n);

  /// Kraft-Auswertung, Fortschritte — Sekunden ausgeschrieben
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Sekunde} other{{n} Sekunden}}'**
  String progressA11ySeconds(int n);

  /// Kraft-Auswertung, Fortschritte — Kilogramm ausgeschrieben
  ///
  /// In de, this message translates to:
  /// **'{v} Kilogramm'**
  String progressA11yKg(String v);

  /// Kraft-Auswertung (16.09.2026) — Titel des Blocks Sätze je Woche
  ///
  /// In de, this message translates to:
  /// **'Sätze je Woche'**
  String get weeklySetsTitle;

  /// Kraft-Auswertung — Satz unter dem Titel im Schwellen-Zustand
  ///
  /// In de, this message translates to:
  /// **'Wie viele Sätze du Woche für Woche machst — und ob diese Woche mehr oder weniger ist als sonst.'**
  String get weeklySetsWhat;

  /// Kraft-Auswertung — Bedingung im Schwellen-Zustand
  ///
  /// In de, this message translates to:
  /// **'Ab der ersten Einheit mit Sätzen'**
  String get weeklySetsCondition;

  /// Kraft-Auswertung — Kopfzeile, Teil 2
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Einheit} other{{n} Einheiten}}'**
  String weeklySetsSessions(int n);

  /// Kraft-Auswertung — Einheit neben der grossen Zahl
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{Satz} other{Sätze}}'**
  String weeklySetsUnit(int n);

  /// Kraft-Auswertung — Satzzahl im Vorlese-Label
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Satz} other{{n} Sätze}}'**
  String weeklySetsCount(int n);

  /// Kraft-Auswertung — statt der Grundlage, solange kein Vergleich möglich ist
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{Vergleich ab 2 vollen Wochen · noch 1} other{Vergleich ab 2 vollen Wochen · noch {n}}}'**
  String weeklySetsPending(int n);

  /// Kraft-Auswertung — Hinweis auf Einheiten ohne Sätze im Streifen
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Einheit ohne Sätze nicht gezählt} other{{n} Einheiten ohne Sätze nicht gezählt}}'**
  String weeklySetsWithoutSets(int n);

  /// Kraft-Auswertung — Vorlese-Label von Kopf und Wert
  ///
  /// In de, this message translates to:
  /// **'Diese Woche, {sets} in {sessions}'**
  String weeklySetsHeadA11y(String sets, String sessions);

  /// Kraft-Auswertung — Verschiebung im Vorlese-Label; direction ist ratioShiftUp oder ratioShiftDown
  ///
  /// In de, this message translates to:
  /// **'{delta} {direction} als der 4-Wochen-Schnitt von {avg}'**
  String weeklySetsShiftA11y(String delta, String direction, String avg);

  /// Kraft-Auswertung — keine Verschiebung im Vorlese-Label
  ///
  /// In de, this message translates to:
  /// **'gleich viel wie der 4-Wochen-Schnitt von {avg}'**
  String weeklySetsShiftEqualA11y(String avg);

  /// Kraft-Auswertung — Vorlese-Label des Streifens
  ///
  /// In de, this message translates to:
  /// **'Sätze je Woche: {weeks}'**
  String weeklySetsStripA11y(String weeks);

  /// Kraft-Auswertung — eine Woche im Vorlese-Label des Streifens
  ///
  /// In de, this message translates to:
  /// **'KW {week}: {n}'**
  String weeklySetsWeekA11y(int week, int n);

  /// Kraft-Auswertung — Woche vor Beginn im Vorlese-Label
  ///
  /// In de, this message translates to:
  /// **'KW {week}: vor deiner ersten Einheit'**
  String weeklySetsBeforeStartA11y(int week);

  /// Kraft-Auswertung — Achsenbeschriftung unter dem Streifen
  ///
  /// In de, this message translates to:
  /// **'KW {week}'**
  String weeklySetsAxis(int week);

  /// Schwellen-Zustand Geschätztes Maximum (16.09.2026) — was der Block zeigen wird
  ///
  /// In de, this message translates to:
  /// **'Die Entwicklung deiner stärksten Sätze je Übung, als Schätzung nach Epley.'**
  String get analysisMaxWhat;

  /// Schwellen-Zustand Geschätztes Maximum (16.09.2026) — Bedingung
  ///
  /// In de, this message translates to:
  /// **'Ab {n} Einheiten mit Gewicht, bis {reps} Wdh.'**
  String analysisMaxCondition(int n, int reps);

  /// Schwellen-Zustand Geschätztes Maximum (16.09.2026) — ehrlicher Hinweis zu Körpergewicht
  ///
  /// In de, this message translates to:
  /// **'Übungen mit Körpergewicht ohne Zusatzgewicht zählen hier nicht — ihre Fortschritte stehen unter „Fortschritte“.'**
  String get analysisMaxBodyweightNote;

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Titel
  ///
  /// In de, this message translates to:
  /// **'Vorher und nachher'**
  String get wellnessTrendTitle;

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Fenster rechts neben dem Titel
  ///
  /// In de, this message translates to:
  /// **'{weeks} Wochen'**
  String wellnessTrendWindow(int weeks);

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Was der Block zeigt, im Schwellen-Zustand
  ///
  /// In de, this message translates to:
  /// **'Bereitschaft vor und Gefühl nach jeder Krafteinheit nebeneinander.'**
  String get wellnessTrendWhat;

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Bedingung im Schwellen-Zustand
  ///
  /// In de, this message translates to:
  /// **'Ab {n} Einheiten mit beiden Angaben'**
  String wellnessTrendCondition(int n);

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Legende über der Punktreihe
  ///
  /// In de, this message translates to:
  /// **'oben vorher · unten nachher'**
  String get wellnessTrendLegend;

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Zählung: Gefühl nachher höher als Bereitschaft vorher; wertfrei
  ///
  /// In de, this message translates to:
  /// **'{n} nachher höher'**
  String wellnessTrendHigher(int n);

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Zählung: gleich
  ///
  /// In de, this message translates to:
  /// **'{n} gleich'**
  String wellnessTrendSame(int n);

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Zählung: nachher niedriger; wertfrei
  ///
  /// In de, this message translates to:
  /// **'{n} nachher niedriger'**
  String wellnessTrendLower(int n);

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Vorlesetext der Zählzeile, ohne Glyphen
  ///
  /// In de, this message translates to:
  /// **'Nachher höher: {higher}. Gleich: {same}. Nachher niedriger: {lower}.'**
  String wellnessTrendCountsA11y(int higher, int same, int lower);

  /// Kraft-Auswertung, Vorher und nachher — Grundlage mit Nenner, gekürzt am 17.09.2026 (Fenster steht im Kopf)
  ///
  /// In de, this message translates to:
  /// **'{n} von {total, plural, =1{1 Einheit} other{{total} Einheiten}} mit beiden Angaben'**
  String wellnessTrendBasis(int n, int total);

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Hinweis auf ausgelassene Einheiten
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Einheit mit nur einer Angabe ist nicht enthalten} other{{n} Einheiten mit nur einer Angabe sind nicht enthalten}}'**
  String wellnessTrendOnlyOne(int n);

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Ein Paar im Vorlesetext
  ///
  /// In de, this message translates to:
  /// **'{date}: vorher {before} {beforeWord}, nachher {after} {afterWord}'**
  String wellnessTrendPair(
      String date, int before, String beforeWord, int after, String afterWord);

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Vorlesetext der Punktreihe
  ///
  /// In de, this message translates to:
  /// **'Vorher und nachher je Einheit, älteste zuerst. {pairs}'**
  String wellnessTrendRowA11y(String pairs);

  /// Auswertung Kraft, Block Vorher und nachher (16.09.2026) — kein Board, aus Tokens gebaut — Übungszeile im Einheitendetail öffnet das Übungsdetail
  ///
  /// In de, this message translates to:
  /// **'{label}, öffnet Übung'**
  String wellnessTrendOpenExercise(String label);

  /// Kraft-Tab mit vier Seiten (16.09.2026) — kein Board — Reiter der Seite mit ATEM-Plänen
  ///
  /// In de, this message translates to:
  /// **'Pläne'**
  String get segPlans;

  /// Kraft-Tab Seite Pläne (16.09.2026), gekürzt 17.09.2026
  ///
  /// In de, this message translates to:
  /// **'Bald findest du hier Pläne von ATEM, frei und als Premium. Deine eigenen Pläne stehen darüber.'**
  String get planCatalogBody;

  /// Einheiten je Monat (16.09.2026) — Fenster rechts im Kopf
  ///
  /// In de, this message translates to:
  /// **'{n} Monate'**
  String monthsWindow(int n);

  /// Einheiten je Monat (16.09.2026) — Grundlage im Fenster
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Einheit} other{{n} Einheiten}} an {days, plural, =1{1 Tag} other{{days} Tagen}} · seit {date}'**
  String monthsBasis(int n, int days, String date);

  /// Einheiten je Monat (16.09.2026) — ein Monat in der Sammelansage
  ///
  /// In de, this message translates to:
  /// **'{month}: {n, plural, =0{keine Einheit} =1{1 Einheit} other{{n} Einheiten}}'**
  String monthsEntryA11y(String month, int n);

  /// Einheiten je Monat (16.09.2026) — Monat vor Beginn in der Sammelansage
  ///
  /// In de, this message translates to:
  /// **'{month}: nicht erfasst'**
  String monthsNotMeasuredA11y(String month);

  /// Plan-Karte im Kraft-Tab (16.09.2026) — kein Board, aus Tokens gebaut — Vorlesetext der ganzen Karte
  ///
  /// In de, this message translates to:
  /// **'{name}, {n, plural, =1{1 Übung} other{{n} Übungen}}, etwa {minutes} Minuten, öffnet Plan'**
  String planCardA11y(String name, int n, int minutes);

  /// Plan-Karte im Kraft-Tab (16.09.2026) — kein Board, aus Tokens gebaut — Vorlesetext des Startknopfs
  ///
  /// In de, this message translates to:
  /// **'Starten: {name}'**
  String planCardStartA11y(String name);

  /// AtemExplainHeader (17.09.2026) — ⓘ zugeklappt
  ///
  /// In de, this message translates to:
  /// **'Erklärung zu {title}, aufklappen'**
  String explainOpenA11y(String title);

  /// AtemExplainHeader (17.09.2026) — ⓘ aufgeklappt
  ///
  /// In de, this message translates to:
  /// **'Erklärung zu {title}, zuklappen'**
  String explainCloseA11y(String title);

  /// Muskelbalance-Karte — Erklärung hinter dem ⓘ (17.09.2026)
  ///
  /// In de, this message translates to:
  /// **'Anteil der Sätze je Muskel in den letzten 8 Wochen, gezählt über Krafteinheiten mit Übungen. Cardio, Regeneration und Einheiten ohne Übungen tragen nichts bei. Kein Sollverhältnis — die App weiß nicht, wie viel Rücken richtig ist.'**
  String get balanceExplain;

  /// Monatsstreifen — Erklärung hinter dem ⓘ (17.09.2026)
  ///
  /// In de, this message translates to:
  /// **'Einheiten je Kalendermonat. Ein Strich heißt: gemessen, keine Einheit. Leer heißt: vor deiner ersten Einheit.'**
  String get monthsExplain;

  /// Übungsverlauf — Erklärung hinter dem ⓘ (17.09.2026)
  ///
  /// In de, this message translates to:
  /// **'Zuletzt, Bestwert, Häufigkeit und Volumen aus deinen Einheiten mit dieser Übung. Die Kurve erscheint ab 5 Ausführungen — aus weniger Punkten sähe eine Gerade wie ein Trend aus.'**
  String get historyExplain;

  /// Kraft-Auswertung, Fortschritte — Erklärung hinter dem ⓘ (17.09.2026)
  ///
  /// In de, this message translates to:
  /// **'Verglichen wird je Übung mit dem besten Wert aller früheren Ausführungen: Gewicht, wenn du je Zusatzlast hattest, sonst Wiederholungen, sonst Haltezeit. Aufwärmsätze zählen nicht.'**
  String get progressExplainMeasure;

  /// Kraft-Auswertung, Sätze je Woche — Erklärung hinter dem ⓘ (17.09.2026)
  ///
  /// In de, this message translates to:
  /// **'Verglichen wird mit dem Schnitt der 4 vollen Wochen davor — nur Wochen seit deiner ersten Krafteinheit zählen. Aufwärmsätze zählen nicht. Kein Sollwert.'**
  String get weeklySetsExplainAverage;

  /// Kraft-Auswertung, Fokus — Erklärung hinter dem ⓘ (17.09.2026)
  ///
  /// In de, this message translates to:
  /// **'Der Anteil rechnet nur über Einheiten, bei denen du beim Start einen Fokus gewählt hast — Einheiten ohne Fokus zählen nicht mit. Kein Sollverhältnis.'**
  String get focusDistExplainWithout;

  /// Kraft-Auswertung, Vorher und nachher — Erklärung hinter dem ⓘ (17.09.2026)
  ///
  /// In de, this message translates to:
  /// **'Oben steht deine Bereitschaft vor der Einheit, unten dein Gefühl danach, je von 1 bis 5. „Höher“ heisst nur höher, nicht besser. Einheiten mit nur einer der beiden Angaben sind nicht enthalten.'**
  String get wellnessTrendExplain;

  /// Trainingszeit — Erklärung hinter dem ⓘ
  ///
  /// In de, this message translates to:
  /// **'Wie sich deine Trainingsminuten auf Kraft, Cardio und Regeneration verteilen — in dieser Woche oder in den letzten 28 Tagen. Minuten sind die einzige Grösse, die alle drei Spuren teilen.'**
  String get hybridTimeExplain;

  /// Text und Erklärungen (17.09.2026) — Erklärung hinter dem ⓘ der Trainingstage
  ///
  /// In de, this message translates to:
  /// **'Jede Kachel ist ein Tag, jede Spalte eine Woche. Die Farbe zeigt, was du an dem Tag trainiert hast. Pausen werden nicht bestraft.'**
  String get hybridHeatmapExplain;

  /// Text und Erklärungen (17.09.2026) — neben der Hauptzahl der Trainingstage
  ///
  /// In de, this message translates to:
  /// **'von {total} Tagen trainiert'**
  String hybridHeatmapOfDays(int total);

  /// Trainingszeit (17.09.2026, Verhältnis und Trainingszeit zusammengeführt) — Segment Woche
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get hybridTimeWeek;

  /// Trainingszeit — Kraft-Metazeile, Arbeitssätze ohne Aufwärmen
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Satz} other{{n} Sätze}}'**
  String hybridTimeSets(int n);

  /// Trainingszeit — Kraft-Metazeile, nur wenn > 0
  ///
  /// In de, this message translates to:
  /// **'{t} t Volumen'**
  String hybridTimeTonnage(String t);

  /// Trainingszeit — Grundlage unter den Zeilen
  ///
  /// In de, this message translates to:
  /// **'{minutes} min · {n, plural, =1{1 Einheit} other{{n} Einheiten}}'**
  String hybridTimeBasisShort(int minutes, int n);

  /// Trainingszeit — Wochenfenster ohne Minuten
  ///
  /// In de, this message translates to:
  /// **'Diese Woche noch keine Einheit mit Dauer.'**
  String get hybridTimeEmptyWeek;

  /// Trainingszeit — Erklärung der Verschiebung hinter dem ⓘ
  ///
  /// In de, this message translates to:
  /// **'Die Pfeile in „Diese Woche“ vergleichen den Anteil mit dem Schnitt der vier Wochen davor, in Prozentpunkten. Sie erscheinen, sobald deine Einheiten vier Wochen zurückreichen.'**
  String get hybridTimeShiftExplain;

  /// Trainingszeit — Zeile mit Verschiebung
  ///
  /// In de, this message translates to:
  /// **'{track}: {minutes} Minuten, {n} Einheiten, {percent} Prozent, {shift}'**
  String hybridTimeRowShiftA11y(
      String track, int minutes, int n, int percent, String shift);

  /// Sätze je Woche — Zeitraum rechts im Kopf (17.09.2026)
  ///
  /// In de, this message translates to:
  /// **'{weeks} Wochen'**
  String weeklySetsWindow(int weeks);

  /// Profilseite (17.09.2026) — Zeile und Titel der Unterseite mit Rechtlichem und Auskünften
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get infoTitle;

  /// Profilseite (17.09.2026) — Unterzeile der Info-Zeile
  ///
  /// In de, this message translates to:
  /// **'Rechtliches und Auskünfte zur App'**
  String get infoSub;

  /// Profilseite (17.09.2026) — Versionszeile ganz unten, zurückhaltend
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String infoVersionLine(String version);

  /// Runner 18.09.2026 — „letztes Mal“ in der Satzzeile, kurz; die lange Fassung steht im Vorlese-Label
  ///
  /// In de, this message translates to:
  /// **'{weight}×{reps}'**
  String workoutPreviousShort(String weight, int reps);

  /// Runner 18.09.2026 — Wert in der Satzzeile öffnet den Regler
  ///
  /// In de, this message translates to:
  /// **'{field}, Satz {set}, {value}, zum Ändern tippen'**
  String workoutValueEditA11y(String field, int set, String value);

  /// Runner 18.09.2026 — leerer Wert im Vorlese-Label
  ///
  /// In de, this message translates to:
  /// **'keine Angabe'**
  String get workoutValueEmpty;

  /// Runner 18.09.2026 — Vorlese-Kopf über den farbigen Typ-Pillen
  ///
  /// In de, this message translates to:
  /// **'Satztypen'**
  String get workoutSetTypeLegendTitle;

  /// Runner 18.09.2026 — Abschnitt der Beschreibung im Anleitungs-Blatt
  ///
  /// In de, this message translates to:
  /// **'Kurz gesagt'**
  String get workoutFormGuideDescription;

  /// Runner, Tabellenkopf Haltespalte (Vorlage TEM Workout Runner)
  ///
  /// In de, this message translates to:
  /// **'HALTEN'**
  String get workoutRunnerTableHold;

  /// Eingabe-Blatt im Runner (18.09.2026, Claude-Design) — Titel über dem Gewichtsregler
  ///
  /// In de, this message translates to:
  /// **'GEWICHT · SATZ {n}'**
  String stepPadTitleWeight(int n);

  /// Eingabe-Blatt im Runner — Titel über dem Wiederholungsregler
  ///
  /// In de, this message translates to:
  /// **'WIEDERHOLUNGEN · SATZ {n}'**
  String stepPadTitleReps(int n);

  /// Eingabe-Blatt im Runner — Titel über dem Haltezeitregler
  ///
  /// In de, this message translates to:
  /// **'HALTEN · SATZ {n}'**
  String stepPadTitleHold(int n);

  /// Eingabe-Blatt im Runner — Feldname für Screenreader
  ///
  /// In de, this message translates to:
  /// **'Gewicht in Kilogramm'**
  String get stepPadFieldWeight;

  /// Eingabe-Blatt im Runner — Feldname für Screenreader
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen'**
  String get stepPadFieldReps;

  /// Eingabe-Blatt im Runner — Feldname für Screenreader
  ///
  /// In de, this message translates to:
  /// **'Haltezeit in Sekunden'**
  String get stepPadFieldHold;

  /// Eingabe-Blatt im Runner — Vorwert unter dem Titel
  ///
  /// In de, this message translates to:
  /// **'Letztes Mal: {value}'**
  String stepPadPrevious(String value);

  /// Eingabe-Blatt im Runner — Unterschied zum Vorwert
  ///
  /// In de, this message translates to:
  /// **'{value} {unit} ZU LETZTEM MAL'**
  String stepPadDelta(String value, String unit);

  /// Eingabe-Blatt im Runner — Unterschied für Screenreader, ohne Glyph
  ///
  /// In de, this message translates to:
  /// **'{value} {unit} gegenüber dem letzten Mal'**
  String stepPadDeltaA11y(String value, String unit);

  /// Eingabe-Blatt im Runner — Umschalter auf die Tastatur
  ///
  /// In de, this message translates to:
  /// **'TASTATUR'**
  String get stepPadKeyboard;

  /// Eingabe-Blatt im Runner — Umschalter zurück auf den Regler
  ///
  /// In de, this message translates to:
  /// **'REGLER'**
  String get stepPadRuler;

  /// Eingabe-Blatt im Runner — Vorlese-Label des Umschalters
  ///
  /// In de, this message translates to:
  /// **'Tastatur statt Regler, {field}'**
  String stepPadKeyboardA11y(String field);

  /// Eingabe-Blatt im Runner — Vorlese-Label des Umschalters
  ///
  /// In de, this message translates to:
  /// **'Regler statt Tastatur, {field}'**
  String stepPadRulerA11y(String field);

  /// Eingabe-Blatt im Runner — Hinweiszeile unter dem Band
  ///
  /// In de, this message translates to:
  /// **'ZIEHEN ZUM EINSTELLEN · SCHRITT {step}'**
  String stepPadHint(String step);

  /// Eingabe-Blatt im Runner — Knopf, der den Wert übernimmt
  ///
  /// In de, this message translates to:
  /// **'ÜBERNEHMEN'**
  String get stepPadApply;

  /// Eingabe-Blatt im Runner — Schrittweite beim Gewicht
  ///
  /// In de, this message translates to:
  /// **'{step} kg'**
  String stepPadStepKg(String step);

  /// Eingabe-Blatt im Runner — Schrittweite bei der Haltezeit
  ///
  /// In de, this message translates to:
  /// **'{step} s'**
  String stepPadStepSeconds(String step);

  /// Eingabe-Blatt im Runner — Schrittweite bei den Wiederholungen
  ///
  /// In de, this message translates to:
  /// **'{step}'**
  String stepPadStepPlain(String step);

  /// Eingabe-Blatt im Runner — Vorlese-Label einer Schrittkapsel
  ///
  /// In de, this message translates to:
  /// **'Schrittweite {step}, {field}'**
  String stepPadStepA11y(String step, String field);

  /// Eingabe-Blatt im Runner — Vorlese-Label des Bandes
  ///
  /// In de, this message translates to:
  /// **'{field}, ziehen zum Einstellen'**
  String stepPadSliderA11y(String field);

  /// Eingabe-Blatt im Runner — Plus-Knopf
  ///
  /// In de, this message translates to:
  /// **'Wert erhöhen'**
  String get stepPadIncrease;

  /// Eingabe-Blatt im Runner — Minus-Knopf
  ///
  /// In de, this message translates to:
  /// **'Wert verringern'**
  String get stepPadDecrease;

  /// Eingabe-Blatt im Runner — Vorlese-Label eines Schnellknopfs
  ///
  /// In de, this message translates to:
  /// **'Um {value} ändern'**
  String stepPadQuickA11y(String value);

  /// Eingabe-Blatt im Runner — Verdunkler und Zurück-Geste
  ///
  /// In de, this message translates to:
  /// **'Eingabe schliessen'**
  String get stepPadClose;

  /// Runner, Tabellenkopf Spalte 1, wenn SATZ nicht in 32 dp passt
  ///
  /// In de, this message translates to:
  /// **'TYP'**
  String get workoutRunnerTableSetShort;

  /// Runner, Tabellenkopf Spalte 2, wenn LETZTES MAL nicht passt
  ///
  /// In de, this message translates to:
  /// **'ZULETZT'**
  String get workoutRunnerTableLastShort;

  /// Runner, Tabellenkopf Haltespalte, wenn HALTEN nicht passt
  ///
  /// In de, this message translates to:
  /// **'SEK'**
  String get workoutRunnerTableHoldShort;

  /// Eingabe-Blatt im Runner — Einheit neben der grossen Zahl
  ///
  /// In de, this message translates to:
  /// **'KG'**
  String get stepPadUnitWeight;

  /// Eingabe-Blatt im Runner — Einheit neben der grossen Zahl
  ///
  /// In de, this message translates to:
  /// **'WDH'**
  String get stepPadUnitReps;

  /// Eingabe-Blatt im Runner — Einheit neben der grossen Zahl
  ///
  /// In de, this message translates to:
  /// **'SEK'**
  String get stepPadUnitHold;

  /// Runner, leeres Wertfeld in der Satzzeile (Geviertstrich wie in der Vorlage)
  ///
  /// In de, this message translates to:
  /// **'—'**
  String get workoutValueNone;

  /// Übungsformular (18.09.2026, kein Board) — Schalter für einseitige Übungen
  ///
  /// In de, this message translates to:
  /// **'Je Seite trainiert'**
  String get exerciseUnilateralLabel;

  /// Übungsformular (18.09.2026, kein Board) — Erklärung unter dem Einseitig-Schalter
  ///
  /// In de, this message translates to:
  /// **'Für einseitige Übungen wie Bizeps-Curl mit einer Hantel oder Ausfallschritt — der Runner fragt dann je Satz nach links oder rechts.'**
  String get exerciseUnilateralHint;

  /// Übungsformular — Vorlesetext des Einseitig-Schalters mit Zustand
  ///
  /// In de, this message translates to:
  /// **'{label}, {state}'**
  String exerciseUnilateralA11y(String label, String state);

  /// Übungsdetail — Zusatz in der Metazeile bei einseitigen Übungen
  ///
  /// In de, this message translates to:
  /// **'je Seite'**
  String get exerciseUnilateralMeta;

  /// Harte Sätze (18.09.2026) — Titel des Auswertungsblocks
  ///
  /// In de, this message translates to:
  /// **'Harte Sätze'**
  String get hardSetsTitle;

  /// Harte Sätze — Zeitraum rechts im Kopf
  ///
  /// In de, this message translates to:
  /// **'{days, plural, =1{1 Tag} other{{days} Tage}}'**
  String hardSetsWindow(int days);

  /// Harte Sätze — Bedingung im Schwellen-Zustand
  ///
  /// In de, this message translates to:
  /// **'Ab {n} Sätzen mit Anstrengung'**
  String hardSetsCondition(int n);

  /// Harte Sätze — Erklärung hinter dem ⓘ: was ein harter Satz ist
  ///
  /// In de, this message translates to:
  /// **'Ein harter Satz ist einer mit Anstrengung 7 oder mehr auf der Skala 1 bis 10. Die Angabe ist freiwillig und wird beim Abhaken eines Satzes im Runner gewählt.'**
  String get hardSetsExplainWhat;

  /// Harte Sätze — Erklärung hinter dem ⓘ: warum Sätze statt Tonnage
  ///
  /// In de, this message translates to:
  /// **'Gezählt werden Sätze, nicht Kilogramm: So zählt ein Klimmzug am eigenen Körper genauso wie ein Satz mit der Langhantel.'**
  String get hardSetsExplainWhy;

  /// Harte Sätze — Erklärung hinter dem ⓘ: Seitenregel
  ///
  /// In de, this message translates to:
  /// **'Bei einseitigen Übungen sind ein Satz links und einer rechts zusammen ein Satz.'**
  String get hardSetsExplainSides;

  /// Harte Sätze — Erklärung hinter dem ⓘ: kein Sollwert, Vergleichsfenster
  ///
  /// In de, this message translates to:
  /// **'Kein Sollwert — die App weiss nicht, wie viele harte Sätze richtig sind. Die Pfeile vergleichen mit den {days} Tagen davor.'**
  String hardSetsExplainNoTarget(int days);

  /// Harte Sätze — Einheit neben der Hauptzahl
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{harter Satz} other{harte Sätze}}'**
  String hardSetsUnit(int n);

  /// Harte Sätze — Grundlage mit Nenner
  ///
  /// In de, this message translates to:
  /// **'{hard} harte von {total} Sätzen · {rpe} mit Angabe'**
  String hardSetsBasis(int hard, int total, int rpe);

  /// Harte Sätze — Zählform für Vorlesetexte
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 harter Satz} other{{n} harte Sätze}}'**
  String hardSetsCount(int n);

  /// Harte Sätze — Vorlesetext der Hauptzahl; count ist hardSetsCount
  ///
  /// In de, this message translates to:
  /// **'{count} in {days} Tagen'**
  String hardSetsHeadA11y(String count, int days);

  /// Harte Sätze — Verschiebung im Vorlesetext; direction ist ratioShiftUp/ratioShiftDown
  ///
  /// In de, this message translates to:
  /// **'{n} {direction} als in den {days} Tagen davor'**
  String hardSetsShiftA11y(int n, String direction, int days);

  /// Harte Sätze — keine Verschiebung im Vorlesetext
  ///
  /// In de, this message translates to:
  /// **'gleich viele wie in den {days} Tagen davor'**
  String hardSetsShiftEqualA11y(int days);

  /// Runner — Seitenmarke in der Satzzeile, links
  ///
  /// In de, this message translates to:
  /// **'L'**
  String get workoutSideLeftShort;

  /// Runner — Seitenmarke in der Satzzeile, rechts
  ///
  /// In de, this message translates to:
  /// **'R'**
  String get workoutSideRightShort;

  /// Runner — Seite ausgeschrieben, für Vorlese-Labels
  ///
  /// In de, this message translates to:
  /// **'links'**
  String get workoutSideLeft;

  /// Runner — Seite ausgeschrieben, für Vorlese-Labels
  ///
  /// In de, this message translates to:
  /// **'rechts'**
  String get workoutSideRight;

  /// Runner — Seitenmarke eines offenen Satzes
  ///
  /// In de, this message translates to:
  /// **'Seite {side}, Satz {n}. Tippen wechselt zu {other}'**
  String workoutSideA11y(String side, int n, String other);

  /// Runner — Seitenmarke eines abgehakten Satzes (gesperrt, erst entsperren)
  ///
  /// In de, this message translates to:
  /// **'Seite {side}, Satz {n}'**
  String workoutSideDoneA11y(String side, int n);

  /// Runner — Kopf des RPE-Streifens nach dem Abhaken
  ///
  /// In de, this message translates to:
  /// **'Wie schwer war Satz {n}?'**
  String workoutRpeQuestion(int n);

  /// Runner — Semantics-Gruppe des RPE-Streifens
  ///
  /// In de, this message translates to:
  /// **'Anstrengung von Satz {n}'**
  String workoutRpeGroupA11y(int n);

  /// Runner — Gruppe einer Reihe im RPE-Streifen
  ///
  /// In de, this message translates to:
  /// **'RPE {from} bis {to}'**
  String workoutRpeRangeA11y(int from, int to);

  /// Runner — löscht die Anstrengung des Satzes und schließt den Streifen
  ///
  /// In de, this message translates to:
  /// **'keine Angabe'**
  String get workoutRpeNone;

  /// Runner — Vorlese-Label zu „keine Angabe“
  ///
  /// In de, this message translates to:
  /// **'Keine Anstrengung angeben für Satz {n}'**
  String workoutRpeNoneA11y(int n);

  /// Runner — blendet die Stufen 1 bis 5 im RPE-Streifen ein
  ///
  /// In de, this message translates to:
  /// **'1–5 zeigen'**
  String get workoutRpeShowLow;

  /// Runner — blendet die Stufen 1 bis 5 wieder aus
  ///
  /// In de, this message translates to:
  /// **'1–5 ausblenden'**
  String get workoutRpeHideLow;

  /// Runner — Vorlese-Label zu „1–5 zeigen“
  ///
  /// In de, this message translates to:
  /// **'Stufen 1 bis 5 zeigen'**
  String get workoutRpeShowLowA11y;

  /// Runner — Vorlese-Label zu „1–5 ausblenden“
  ///
  /// In de, this message translates to:
  /// **'Stufen 1 bis 5 ausblenden'**
  String get workoutRpeHideLowA11y;

  /// Runner — Wort zu RPE 10 unter der Reihe. Kurz, weil „noch 4 Wdh. … Max“ bei 200 % auf 320 dp in eine Zeile passen muss
  ///
  /// In de, this message translates to:
  /// **'Max'**
  String get workoutRpeWordMax;

  /// Runner — Wort zu RPE 6–9: Wiederholungen in Reserve (RPE 9 = 1)
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{noch 1 Wdh.} other{noch {n} Wdh.}}'**
  String workoutRpeWordReserve(int n);

  /// Runner — Wort zu RPE 5. Kurz, weil „leicht … noch 5+“ bei 200 % auf 320 dp in eine Zeile passen muss
  ///
  /// In de, this message translates to:
  /// **'noch 5+'**
  String get workoutRpeWordReserveMany;

  /// Runner — Wort zu RPE 1–4
  ///
  /// In de, this message translates to:
  /// **'leicht'**
  String get workoutRpeWordEasy;

  /// Runner — Vorlese-Fassung von RPE 10
  ///
  /// In de, this message translates to:
  /// **'keine Wiederholung mehr möglich'**
  String get workoutRpeMaxA11y;

  /// Runner — Vorlese-Fassung von RPE 6–9
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{noch 1 Wiederholung möglich} other{noch {n} Wiederholungen möglich}}'**
  String workoutRpeReserveA11y(int n);

  /// Runner — Vorlese-Fassung von RPE 5
  ///
  /// In de, this message translates to:
  /// **'noch 5 oder mehr Wiederholungen möglich'**
  String get workoutRpeReserveManyA11y;

  /// Runner — Vorlese-Label eines Feldes im RPE-Streifen
  ///
  /// In de, this message translates to:
  /// **'RPE {level}, {word}'**
  String workoutRpeLevelA11y(int level, String word);

  /// Runner — Kapsel in der Satzzeile nach der Angabe
  ///
  /// In de, this message translates to:
  /// **'RPE {rpe}'**
  String workoutRpeBadge(int rpe);

  /// Runner — steht ab RPE 7 an der Kapsel, neben dem Punkt
  ///
  /// In de, this message translates to:
  /// **'harter Satz'**
  String get workoutHardSet;

  /// Runner — Vorlese-Label der RPE-Kapsel unter 7
  ///
  /// In de, this message translates to:
  /// **'Satz {n}, RPE {rpe}. Tippen zum Ändern'**
  String workoutRpeBadgeA11y(int n, int rpe);

  /// Runner — Vorlese-Label der RPE-Kapsel ab 7
  ///
  /// In de, this message translates to:
  /// **'Satz {n}, RPE {rpe}, harter Satz. Tippen zum Ändern'**
  String workoutRpeBadgeHardA11y(int n, int rpe);

  /// Runner, Übungskopf: Beschriftung vor der Seitenwahl
  ///
  /// In de, this message translates to:
  /// **'Seiten'**
  String get workoutSidesLabel;

  /// Runner, Seitenwahl: Sätze ohne Körperseite
  ///
  /// In de, this message translates to:
  /// **'Beidseitig'**
  String get workoutSidesBoth;

  /// Runner, Seitenwahl: Sätze je Körperseite, mit L/R-Marke
  ///
  /// In de, this message translates to:
  /// **'Getrennt'**
  String get workoutSidesSplit;

  /// Runner, Seitenwahl: Vorlese-Label Beidseitig
  ///
  /// In de, this message translates to:
  /// **'Beidseitig, Sätze ohne Seite'**
  String get workoutSidesBothA11y;

  /// Runner, Seitenwahl: Vorlese-Label Getrennt
  ///
  /// In de, this message translates to:
  /// **'Getrennt, links und rechts je eigene Sätze'**
  String get workoutSidesSplitA11y;

  /// Runner, Seitenwahl: Gruppen-Label
  ///
  /// In de, this message translates to:
  /// **'Seiten für Übung {name}'**
  String workoutSidesGroupA11y(String name);

  /// Eingabeblatt Gewicht — Kapsel, die den Scheibenrechner aufklappt
  ///
  /// In de, this message translates to:
  /// **'Scheiben'**
  String get platesToggle;

  /// Eingabeblatt — Vorlese-Label der Scheiben-Kapsel, eingeklappt
  ///
  /// In de, this message translates to:
  /// **'Scheiben je Seite anzeigen'**
  String get platesToggleShowA11y;

  /// Eingabeblatt — Vorlese-Label der Scheiben-Kapsel, aufgeklappt
  ///
  /// In de, this message translates to:
  /// **'Scheiben ausblenden'**
  String get platesToggleHideA11y;

  /// Scheibenrechner — Kopf vor den Stangen-Kapseln (Mono-Versalien)
  ///
  /// In de, this message translates to:
  /// **'STANGE'**
  String get platesBarLabel;

  /// Scheibenrechner — Stangen-Kapsel
  ///
  /// In de, this message translates to:
  /// **'{kg} kg'**
  String platesBarKg(String kg);

  /// Scheibenrechner — Vorlese-Label einer Stangen-Kapsel
  ///
  /// In de, this message translates to:
  /// **'Stange {kg} Kilogramm'**
  String platesBarA11y(String kg);

  /// Scheibenrechner — mehrere gleiche Scheiben je Seite, sichtbar
  ///
  /// In de, this message translates to:
  /// **'{count} × {plate}'**
  String platesTimes(String count, String plate);

  /// Scheibenrechner — Belegung einer Stangenhälfte
  ///
  /// In de, this message translates to:
  /// **'je Seite: {plates} · Stange {bar} kg'**
  String platesPerSide(String plates, String bar);

  /// Scheibenrechner — Zielgewicht gleich Stange
  ///
  /// In de, this message translates to:
  /// **'Leere Stange · {bar} kg'**
  String platesEmptyBar(String bar);

  /// Scheibenrechner — Zielgewicht unter der Stange
  ///
  /// In de, this message translates to:
  /// **'Leichter als die Stange ({bar} kg)'**
  String platesBelowBar(String bar);

  /// Scheibenrechner — Rest, der mit den Scheiben nicht aufgeht
  ///
  /// In de, this message translates to:
  /// **'{rest} kg lässt sich nicht stecken — nächster Wert {loaded} kg'**
  String platesRemainder(String rest, String loaded);

  /// Scheibenrechner — eine Scheibengrösse im Vorlese-Label
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{eine {plate}} other{{count}-mal {plate}}}'**
  String platesA11yPlate(int count, String plate);

  /// Scheibenrechner — ein Vorlese-Knoten für Grafik und Zeile
  ///
  /// In de, this message translates to:
  /// **'Scheiben je Seite: {plates}. Stange {bar} Kilogramm'**
  String platesA11y(String plates, String bar);

  /// Scheibenrechner — Vorlese-Label bei leerer Stange
  ///
  /// In de, this message translates to:
  /// **'Leere Stange, {bar} Kilogramm, keine Scheiben'**
  String platesA11yEmptyBar(String bar);

  /// Scheibenrechner — Vorlese-Label unter der Stange
  ///
  /// In de, this message translates to:
  /// **'Leichter als die Stange mit {bar} Kilogramm, keine Scheiben möglich'**
  String platesA11yBelowBar(String bar);

  /// Scheibenrechner — Vorlese-Zusatz bei Rest
  ///
  /// In de, this message translates to:
  /// **'Rest {rest} Kilogramm lässt sich nicht stecken, nächster Wert {loaded} Kilogramm'**
  String platesA11yRemainder(String rest, String loaded);

  /// One-Pager (20.09.2026) — kein Board — Kopf über den eigenen Plänen im Abschnitt Pläne
  ///
  /// In de, this message translates to:
  /// **'Deine Pläne'**
  String get plansOwnLabel;

  /// One-Pager (20.09.2026) — kein Board — Unterzeile der Hauptkachel ohne Termin
  ///
  /// In de, this message translates to:
  /// **'Ohne Plan loslegen'**
  String get trainFreeBody;

  /// One-Pager (20.09.2026) — kein Board — Unterzeile der Kachel „Plan wählen“
  ///
  /// In de, this message translates to:
  /// **'Aus deinen Plänen'**
  String get trainPlanBody;

  /// workoutRirBadge
  ///
  /// In de, this message translates to:
  /// **'{rir} RIR'**
  String workoutRirBadge(int rir);

  /// workoutRirBadgeA11y
  ///
  /// In de, this message translates to:
  /// **'Satz {n}, {rir, plural, =0{keine Wiederholung in Reserve} one{1 Wiederholung in Reserve} other{{rir} Wiederholungen in Reserve}}. Tippen zum Ändern'**
  String workoutRirBadgeA11y(int n, int rir);

  /// workoutRirBadgeHardA11y
  ///
  /// In de, this message translates to:
  /// **'Satz {n}, {rir, plural, =0{keine Wiederholung in Reserve} one{1 Wiederholung in Reserve} other{{rir} Wiederholungen in Reserve}}, harter Satz. Tippen zum Ändern'**
  String workoutRirBadgeHardA11y(int n, int rir);

  /// workoutRirLevelA11y
  ///
  /// In de, this message translates to:
  /// **'RIR {level}, {word}'**
  String workoutRirLevelA11y(int level, String word);

  /// workoutRirRangeA11y
  ///
  /// In de, this message translates to:
  /// **'RIR {from} bis {to}'**
  String workoutRirRangeA11y(int from, int to);

  /// workoutRirShowLow
  ///
  /// In de, this message translates to:
  /// **'5–9 zeigen'**
  String get workoutRirShowLow;

  /// workoutRirHideLow
  ///
  /// In de, this message translates to:
  /// **'5–9 ausblenden'**
  String get workoutRirHideLow;

  /// workoutRirShowLowA11y
  ///
  /// In de, this message translates to:
  /// **'Stufen 5 bis 9 in Reserve zeigen'**
  String get workoutRirShowLowA11y;

  /// workoutRirHideLowA11y
  ///
  /// In de, this message translates to:
  /// **'Stufen 5 bis 9 in Reserve ausblenden'**
  String get workoutRirHideLowA11y;

  /// settingsEffortScale
  ///
  /// In de, this message translates to:
  /// **'Anstrengung je Satz'**
  String get settingsEffortScale;

  /// settingsEffortScaleRpe
  ///
  /// In de, this message translates to:
  /// **'RPE'**
  String get settingsEffortScaleRpe;

  /// settingsEffortScaleRir
  ///
  /// In de, this message translates to:
  /// **'RIR'**
  String get settingsEffortScaleRir;

  /// settingsEffortScaleValue
  ///
  /// In de, this message translates to:
  /// **'RPE — hoch ist schwer'**
  String get settingsEffortScaleValue;

  /// settingsEffortScaleValueRir
  ///
  /// In de, this message translates to:
  /// **'RIR — niedrig ist schwer'**
  String get settingsEffortScaleValueRir;

  /// settingsEffortScaleGroupA11y
  ///
  /// In de, this message translates to:
  /// **'Skala für die Anstrengung je Satz'**
  String get settingsEffortScaleGroupA11y;

  /// settingsEffortScaleRpeA11y
  ///
  /// In de, this message translates to:
  /// **'RPE, Anstrengung von 1 bis 10, je höher desto schwerer'**
  String get settingsEffortScaleRpeA11y;

  /// settingsEffortScaleRirA11y
  ///
  /// In de, this message translates to:
  /// **'RIR, Wiederholungen in Reserve, je niedriger desto schwerer'**
  String get settingsEffortScaleRirA11y;

  /// settingsEffortScaleExplain
  ///
  /// In de, this message translates to:
  /// **'Dieselbe Angabe, andersherum gezählt. RPE 8 ist 2 RIR: zwei Wiederholungen wären noch drin gewesen. Gespeichert wird immer dasselbe — ein Wechsel ändert nur die Anzeige, auch rückwirkend, und geht jederzeit zurück.'**
  String get settingsEffortScaleExplain;

  /// hardSetsExplainWhatRir
  ///
  /// In de, this message translates to:
  /// **'Ein harter Satz ist einer mit höchstens 3 Wiederholungen in Reserve. Die Angabe ist freiwillig und wird beim Abhaken eines Satzes im Runner gewählt.'**
  String get hardSetsExplainWhatRir;

  /// Board 13 (20.09.2026) — Marke über dem Namen eines gesperrten Auswertungsblocks
  ///
  /// In de, this message translates to:
  /// **'Gesperrt'**
  String get analysisLockedBadge;

  /// Board 13 (20.09.2026) — Vorlesetext eines gesperrten Auswertungsblocks (Boardschlüssel analysis.locked_a11y)
  ///
  /// In de, this message translates to:
  /// **'{title}: gesperrt. {condition}. {cur} von {req}.'**
  String analysisLockedA11y(String title, String condition, int cur, int req);

  /// Board 13 (20.09.2026) — Vorlesetext der Ortszeile (Boardschlüssel sectionbar.a11y)
  ///
  /// In de, this message translates to:
  /// **'Thema {name}, {n} von {total}. Öffnet die Themenliste.'**
  String sectionBarA11y(String name, int n, int total);

  /// Board 13 (20.09.2026) — Gruppenlabel der Sprungliste (Boardschlüssel sectionbar.list_title)
  ///
  /// In de, this message translates to:
  /// **'Springen zu'**
  String get sectionJumpTitle;

  /// Board 13 (20.09.2026) — Vorlesetext einer Zeile der Sprungliste (Boardschlüssel sectionbar.jump_a11y)
  ///
  /// In de, this message translates to:
  /// **'Zu {name} springen, {n} von {total}'**
  String sectionJumpA11y(String name, int n, int total);

  /// Board 13 (20.09.2026) — Ansage nach einem erscrollten Themenwechsel (Boardschlüssel sectionbar.arrived_a11y)
  ///
  /// In de, this message translates to:
  /// **'{name}, {n} von {total}'**
  String sectionArrivedA11y(String name, int n, int total);

  /// Board 13 (20.09.2026) — Marke der aktuellen Zeile in der Sprungliste (Boardschlüssel sectionbar.here)
  ///
  /// In de, this message translates to:
  /// **'HIER'**
  String get sectionHere;

  /// Board 13 (20.09.2026) — Kicker der Startkarte (Boardschlüssel train.today_kicker)
  ///
  /// In de, this message translates to:
  /// **'Heute geplant'**
  String get trainTodayKicker;

  /// Board 13 (20.09.2026) — Zeile zum Übungskatalog (Boardschlüssel train.catalog)
  ///
  /// In de, this message translates to:
  /// **'Übungskatalog'**
  String get trainCatalog;

  /// Board 13 (20.09.2026) — Zeile zum Nachtragen (Boardschlüssel train.log_later)
  ///
  /// In de, this message translates to:
  /// **'Einheit nachtragen'**
  String get trainLogLater;

  /// Board 13 (20.09.2026) — Blockkopf über der Gesamtzahl (Boardschlüssel history.total_label)
  ///
  /// In de, this message translates to:
  /// **'Erfasste Einheiten'**
  String get historyTotalLabel;

  /// Board 13 (20.09.2026) — Grundlage der Gesamtzahl (Boardschlüssel history.total_since)
  ///
  /// In de, this message translates to:
  /// **'seit {date}'**
  String historyTotalSince(String date);

  /// Board 13 (20.09.2026) — Blockkopf über der Katalog-Ankündigung (Boardschlüssel plans.atem_label)
  ///
  /// In de, this message translates to:
  /// **'ATEM-Pläne'**
  String get plansAtemLabel;

  /// Board 13 (20.09.2026) — Titel des freien Starts (Boardschlüssel train.free_title)
  ///
  /// In de, this message translates to:
  /// **'Frei starten'**
  String get trainFreeTitle;

  /// workoutEffortAdd
  ///
  /// In de, this message translates to:
  /// **'Anstrengung eintragen'**
  String get workoutEffortAdd;

  /// workoutEffortAddA11y
  ///
  /// In de, this message translates to:
  /// **'Satz {n}, Anstrengung eintragen'**
  String workoutEffortAddA11y(int n);

  /// settingsEffortScaleRpeLong
  ///
  /// In de, this message translates to:
  /// **'RPE · Anstrengung'**
  String get settingsEffortScaleRpeLong;

  /// settingsEffortScaleRirLong
  ///
  /// In de, this message translates to:
  /// **'RIR · Wdh. in Reserve'**
  String get settingsEffortScaleRirLong;

  /// Board 13 (20.09.2026) — kurze Bedingung des gesperrten Muskelbalance-Blocks; der ganze Satz steht weiter als balanceThin auf der Unterseite
  ///
  /// In de, this message translates to:
  /// **'Ab {n} Einheiten mit Übungen'**
  String balanceCondition(int n);

  /// Board 14 · weight.title — Titel des Blocks. Nicht weightTitle: das ist seit Modul 8 die Einstellung 'Körpergewicht'.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get weightBlockTitle;

  /// Board 14 · weight.unit
  ///
  /// In de, this message translates to:
  /// **'KG'**
  String get weightUnitKg;

  /// Board 14 · A1 — die Zählung neben dem Wert
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Eintrag} other{{n} Einträge}}'**
  String weightEntries(int n);

  /// Board 14 · weight.basis — die Grundlage mit Nenner
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Eintrag} other{{n} Einträge}} seit dem {date}'**
  String weightBasis(int n, String date);

  /// Board 14 · weight.change_up — sichtbarer Text, Richtung trägt der Glyph
  ///
  /// In de, this message translates to:
  /// **'{delta} kg seit dem {date} · {days} Tage her'**
  String weightChangeUp(String delta, String date, int days);

  /// Board 14 · weight.change_down — gleicher Satz, anderer Glyph; getrennter Schlüssel, damit eine Sprache die Richtung im Satz führen kann
  ///
  /// In de, this message translates to:
  /// **'{delta} kg seit dem {date} · {days} Tage her'**
  String weightChangeDown(String delta, String date, int days);

  /// Board 14 · A11y — Richtung als Wort, nie nur der Glyph
  ///
  /// In de, this message translates to:
  /// **'{delta} Kilogramm mehr seit dem {date}, {days} Tage her'**
  String weightChangeUpA11y(String delta, String date, int days);

  /// Board 14 · A11y — Richtung als Wort, nie nur der Glyph
  ///
  /// In de, this message translates to:
  /// **'{delta} Kilogramm weniger seit dem {date}, {days} Tage her'**
  String weightChangeDownA11y(String delta, String date, int days);

  /// Board 14 · A1 — die beiden Datumsanker unter der Kurve
  ///
  /// In de, this message translates to:
  /// **'{date} · {kg} kg'**
  String weightAnchor(String date, String kg);

  /// Board 14 · A1 — die Zeile über 'Eintragen'
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{Letzter Eintrag heute} one{Letzter Eintrag gestern} other{Letzter Eintrag vor {n} Tagen}}'**
  String weightLastEntryDays(int n);

  /// Board 14 · weight.enter_cta
  ///
  /// In de, this message translates to:
  /// **'Eintragen'**
  String get weightEnterCta;

  /// Board 14 · A2 — die Marke rechts in der betonten Zeile
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get weightStartCta;

  /// Board 14 · weight.single_value_title
  ///
  /// In de, this message translates to:
  /// **'Ersten Verlaufswert eintragen'**
  String get weightSingleValueTitle;

  /// Board 14 · weight.single_value_note
  ///
  /// In de, this message translates to:
  /// **'Aus der Einrichtung, {date} — noch kein zweiter Eintrag.'**
  String weightSingleValueNote(String date);

  /// Board 14 · A2, selbst eingetragener erster Wert
  ///
  /// In de, this message translates to:
  /// **'Erster Eintrag, {date} — noch kein zweiter Eintrag.'**
  String weightSingleValueFirst(String date);

  /// Board 14 · E — der Profilwert eines Kontos von vor dem 20.09.2026, ohne Ursprungsdatum
  ///
  /// In de, this message translates to:
  /// **'Aus den Einstellungen übernommen — noch kein Verlaufseintrag.'**
  String get weightSingleValueSeed;

  /// Board 14 · A2
  ///
  /// In de, this message translates to:
  /// **'Kein Verlauf, keine Kurve: aus einem Wert folgt keine Reihe.'**
  String get weightSingleValueWhy;

  /// Board 14 · weight.gap_note — Bodennotiz in der Lücke
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Woche ohne Eintrag} other{{n} Wochen ohne Eintrag}}'**
  String weightGapNote(int n);

  /// Board 14 · A6 — der gedimmte Wert im Fehlerfall
  ///
  /// In de, this message translates to:
  /// **'ZULETZT BEKANNT · {date}'**
  String weightLastKnown(String date);

  /// Board 14 · weight.load_error
  ///
  /// In de, this message translates to:
  /// **'Verlauf konnte nicht aktualisiert werden.'**
  String get weightLoadError;

  /// Board 14 · weight.range_3m
  ///
  /// In de, this message translates to:
  /// **'3 Mon.'**
  String get weightRange3m;

  /// Board 14 · weight.range_6m
  ///
  /// In de, this message translates to:
  /// **'6 Mon.'**
  String get weightRange6m;

  /// Board 14 · weight.range_1y
  ///
  /// In de, this message translates to:
  /// **'1 Jahr'**
  String get weightRange1y;

  /// Board 14 · weight.range_all
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get weightRangeAll;

  /// Board 14 · A11y — Gruppenname der Range-Pillen
  ///
  /// In de, this message translates to:
  /// **'Zeitraum'**
  String get weightRangeGroup;

  /// Board 14 · A11y — Range-Pille
  ///
  /// In de, this message translates to:
  /// **'Zeitraum {range}, ausgewählt'**
  String weightRangeA11y(String range);

  /// Board 14 · weight.sheet_title — Kicker im Eingabeblatt, Versalien wie im Runner
  ///
  /// In de, this message translates to:
  /// **'GEWICHT EINTRAGEN'**
  String get weightSheetTitle;

  /// Board 14 · weight.sheet_edit_title
  ///
  /// In de, this message translates to:
  /// **'EINTRAG BEARBEITEN'**
  String get weightSheetEditTitle;

  /// Board 14 · weight.date_today
  ///
  /// In de, this message translates to:
  /// **'Heute · {date}'**
  String weightDateToday(String date);

  /// Board 14 · weight.date_pick
  ///
  /// In de, this message translates to:
  /// **'Datum wählen'**
  String get weightDatePick;

  /// Board 14 · A11y — Datums-Chip öffnet den Systemkalender
  ///
  /// In de, this message translates to:
  /// **'Datum, {date}. Ändern.'**
  String weightDateChipA11y(String date);

  /// Board 14 · weight.same_day_note — informiert, blockiert nichts
  ///
  /// In de, this message translates to:
  /// **'Heute bereits erfasst: {kg} kg. Ein zweiter Eintrag ersetzt diesen Wert.'**
  String weightSameDayNote(String kg);

  /// Board 14 · B1 — der Vorwert unter der grossen Zahl
  ///
  /// In de, this message translates to:
  /// **'ZULETZT {kg} KG · {days, plural, =0{HEUTE} one{VOR 1 TAG} other{VOR {days} TAGEN}}'**
  String weightPadPrevious(String kg, int days);

  /// Board 14 · weight.update_cta
  ///
  /// In de, this message translates to:
  /// **'Aktualisieren'**
  String get weightUpdateCta;

  /// Board 14 · weight.retro_title
  ///
  /// In de, this message translates to:
  /// **'WIRKT AUF {from} – {to}'**
  String weightRetroTitle(String from, String to);

  /// Board 14 · weight.retro_scope
  ///
  /// In de, this message translates to:
  /// **'BIS ZUM NÄCHSTEN EINTRAG · NICHT DEN GANZEN VERLAUF'**
  String get weightRetroScope;

  /// Board 14 · C2 — worauf die Änderung wirkt
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Eigengewichts-Satz} other{{n} Eigengewichts-Sätze}}'**
  String weightRetroSets(int n);

  /// Board 14 · C2 — der Nenner ist null, und das steht da statt einer leeren Zeile
  ///
  /// In de, this message translates to:
  /// **'Keine Eigengewichts-Sätze in dieser Spanne'**
  String get weightRetroNone;

  /// Board 14 · weight.confirm_snackbar
  ///
  /// In de, this message translates to:
  /// **'Gewicht {kg} kg · {date} erfasst'**
  String weightConfirmSnack(String kg, String date);

  /// Board 14 · weight.delete_entry
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen'**
  String get weightDeleteEntry;

  /// Board 14 · C2 — Stufe 2 der Löschbestätigung aus Modul 2
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen?'**
  String get weightDeleteTitle;

  /// Board 14 · C2 — nennt die Folge, nicht nur die Frage
  ///
  /// In de, this message translates to:
  /// **'{date} · {kg} kg. Für diese Tage gilt danach wieder der Wert davor.'**
  String weightDeleteBody(String date, String kg);

  /// Board 14 · C2
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get weightDeleteConfirm;

  /// Board 14 · C2
  ///
  /// In de, this message translates to:
  /// **'Eintrag vom {date} gelöscht'**
  String weightDeletedSnack(String date);

  /// Board 14 · weight.source_typed
  ///
  /// In de, this message translates to:
  /// **'Eigene Eingabe'**
  String get weightSourceTyped;

  /// Board 14 · weight.source_measured
  ///
  /// In de, this message translates to:
  /// **'Aus Health Connect'**
  String get weightSourceMeasured;

  /// Board 14 · E
  ///
  /// In de, this message translates to:
  /// **'Aus den Einstellungen übernommen'**
  String get weightSourceSettings;

  /// Board 14 · weight.explain_body
  ///
  /// In de, this message translates to:
  /// **'Zeigt dein Körpergewicht über Zeit — was war, kein Ziel.'**
  String get weightExplainBody;

  /// Board 14 · hinter dem ⓘ
  ///
  /// In de, this message translates to:
  /// **'Die Veränderung vergleicht immer mit dem letzten Eintrag.'**
  String get weightExplainChange;

  /// Board 14 · hinter dem ⓘ
  ///
  /// In de, this message translates to:
  /// **'Lücken werden nicht überbrückt: keine Linie ohne einen echten Eintrag dahinter.'**
  String get weightExplainGaps;

  /// Board 14 · hinter dem ⓘ — die Legende steht hier, nicht dauerhaft auf dem Schirm
  ///
  /// In de, this message translates to:
  /// **'Gefüllter Punkt: eigene Eingabe. Hohler Punkt: aus Health Connect.'**
  String get weightExplainSources;

  /// Board 14 · E — hinter dem ⓘ
  ///
  /// In de, this message translates to:
  /// **'Die Trainingslast einer Einheit rechnet mit dem Gewicht, das an ihrem Tag zuletzt bekannt war.'**
  String get weightExplainLoad;

  /// Board 14 · weight.history_open
  ///
  /// In de, this message translates to:
  /// **'Verlauf öffnen'**
  String get weightHistoryOpen;

  /// Board 14 · A11y — eine Zeile ist ein Knoten, nicht vier
  ///
  /// In de, this message translates to:
  /// **'{date}, {kg} Kilogramm, {source}. Bearbeiten.'**
  String weightRowA11y(String date, String kg, String source);

  /// Board 14 · A11y — die Kurve ist ein img mit Von-Bis-Label
  ///
  /// In de, this message translates to:
  /// **'Verlauf über {n} Einträge, von {from} auf {to} Kilogramm'**
  String weightChartA11y(int n, String from, String to);

  /// Board 14 · A11y — ein '—' ist nie stumm, eine Lücke auch nicht
  ///
  /// In de, this message translates to:
  /// **'Verlauf über {n} Einträge mit einer Lücke von {weeks} Wochen, von {from} auf {to} Kilogramm'**
  String weightChartGapA11y(int n, int weeks, String from, String to);

  /// Board 14 · A3 — Punktwolke statt Linie
  ///
  /// In de, this message translates to:
  /// **'{n} Einträge ohne verbundene Kurve, von {from} auf {to} Kilogramm'**
  String weightChartThinA11y(int n, String from, String to);

  /// Board 14 · A11y — die Karte ist ein Knoten, nicht vier
  ///
  /// In de, this message translates to:
  /// **'Gewicht, {kg} Kilogramm, {basis}, {change}'**
  String weightCardA11y(String kg, String basis, String change);

  /// Board 14 · A2, A11y
  ///
  /// In de, this message translates to:
  /// **'Gewicht, {kg} Kilogramm, noch kein zweiter Eintrag'**
  String weightCardSingleA11y(String kg);

  /// Board 14 · A11y — Hinweis auf der Karte
  ///
  /// In de, this message translates to:
  /// **'Öffnet den Verlauf'**
  String get weightCardOpenHint;

  /// Board 14 · weight.settings_row_meta
  ///
  /// In de, this message translates to:
  /// **'Zuletzt {date} · {source}'**
  String weightSettingsMeta(String date, String source);

  /// Board 14 · C1 — Titel des Bildschirms für Vorleseprogramme
  ///
  /// In de, this message translates to:
  /// **'Gewichtsverlauf'**
  String get weightHistoryTitle;

  /// Board 14 · A5 — Ladezustand, liveRegion polite
  ///
  /// In de, this message translates to:
  /// **'Gewichtsverlauf lädt'**
  String get weightLoadingA11y;

  /// Board 15 · hc.inbox_title — Kopf des Eingangs mit Zähler
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Einheit aus Health Connect} other{{n} Einheiten aus Health Connect}}'**
  String hcInboxTitle(int n);

  /// Board 15 · hc.inbox_meta
  ///
  /// In de, this message translates to:
  /// **'Gelesen {time} · warten auf Prüfung'**
  String hcInboxMeta(String time);

  /// Board 15 · hc.inbox_action
  ///
  /// In de, this message translates to:
  /// **'Prüfen'**
  String get hcInboxAction;

  /// Board 15 · hc.row_unreviewed — Metazeile der wartenden Zeile
  ///
  /// In de, this message translates to:
  /// **'Ungeprüft · zählt noch nicht'**
  String get hcRowUnreviewed;

  /// Board 15 · Titel des Prüfblatts. Das Board setzt „Einheit aus Health Connect prüfen, 1 von 3" — bei 200 % Systemschrift auf 320 dp läuft das Blatt damit über, und Kürzen ist verboten. „Aus Health Connect" sagen die HC-Kapsel und der Inhalt ohnehin.
  ///
  /// In de, this message translates to:
  /// **'Einheit prüfen · {i} von {n}'**
  String hcSheetTitle(int i, int n);

  /// Board 15 · hc.field_duration
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get hcFieldDuration;

  /// Board 15 · hc.field_hr_avg
  ///
  /// In de, this message translates to:
  /// **'Ø Puls'**
  String get hcFieldHrAvg;

  /// Board 15 · hc.field_hr_max
  ///
  /// In de, this message translates to:
  /// **'Max'**
  String get hcFieldHrMax;

  /// Board 15 · hc.more_device_values
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 weitere Angabe vom Gerät} other{Weitere Angaben vom Gerät · {n}}}'**
  String hcMoreDeviceValues(int n);

  /// Board 15 · hc.accept
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get hcAccept;

  /// Board 15 · hc.accept_without_effort — das Label ist die Warnung
  ///
  /// In de, this message translates to:
  /// **'Ohne Anstrengung übernehmen'**
  String get hcAcceptWithoutEffort;

  /// Board 15 · hc.decline
  ///
  /// In de, this message translates to:
  /// **'Nicht übernehmen'**
  String get hcDecline;

  /// Board 15 · hc.no_effort_note — die eine erlaubte Hinweiszeile
  ///
  /// In de, this message translates to:
  /// **'Ohne Anstrengung fehlt diese Einheit in der Trainingslast — sie wird nicht geschätzt.'**
  String get hcNoEffortNote;

  /// Board 15 · hc.continue_later
  ///
  /// In de, this message translates to:
  /// **'Später fortsetzen'**
  String get hcContinueLater;

  /// Board 15 · hc.declined_section
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get hcDeclinedSection;

  /// Board 15 · hc.declined_meta
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt am {date}'**
  String hcDeclinedMeta(String date);

  /// Board 15 · hc.declined_restore
  ///
  /// In de, this message translates to:
  /// **'Doch übernehmen'**
  String get hcDeclinedRestore;

  /// Board 15 · hc.declined_note
  ///
  /// In de, this message translates to:
  /// **'Wird beim nächsten Lesen nicht erneut vorgeschlagen.'**
  String get hcDeclinedNote;

  /// Board 15 · hc.origin_watch — Herkunft als Wort ab 130 % Schrift
  ///
  /// In de, this message translates to:
  /// **'aus der Uhr'**
  String get hcOriginWatch;

  /// Board 15 · hc.origin_both
  ///
  /// In de, this message translates to:
  /// **'App + Uhr'**
  String get hcOriginBoth;

  /// Board 15 · hc.origin_missing_effort — Tatsache, keine Mahnung
  ///
  /// In de, this message translates to:
  /// **'ohne Anstrengung'**
  String get hcOriginMissingEffort;

  /// Board 15 · hc.read_error
  ///
  /// In de, this message translates to:
  /// **'Health Connect nicht erreichbar'**
  String get hcReadError;

  /// Board 15 · hc.read_error_meta
  ///
  /// In de, this message translates to:
  /// **'Zuletzt gelesen {date}'**
  String hcReadErrorMeta(String date);

  /// Board 15 · hc.retry
  ///
  /// In de, this message translates to:
  /// **'Erneut'**
  String get hcRetry;

  /// Board 15 · hc.reading
  ///
  /// In de, this message translates to:
  /// **'Health Connect wird gelesen'**
  String get hcReading;

  /// Board 15 · A11y der wartenden Zeile — ein Knoten
  ///
  /// In de, this message translates to:
  /// **'{title}, {meta}, aus der Uhr, ungeprüft, zählt noch nicht. Prüfen.'**
  String hcRowA11y(String title, String meta);

  /// Board 15 · A11y des Eingangskopfs
  ///
  /// In de, this message translates to:
  /// **'{count} warten auf Prüfung, gelesen {time}. Prüfen.'**
  String hcInboxA11y(String count, String time);

  /// Board 15 · hc.pair_question — die Vermutung wird als Frage gestellt
  ///
  /// In de, this message translates to:
  /// **'Gehört das zu deiner Krafteinheit?'**
  String get hcPairQuestion;

  /// Board 15 · hc.pair_app_row
  ///
  /// In de, this message translates to:
  /// **'Deine App-Einheit'**
  String get hcPairAppRow;

  /// Board 15 · hc.pair_watch_row
  ///
  /// In de, this message translates to:
  /// **'Aus der Uhr'**
  String get hcPairWatchRow;

  /// Board 15 · hc.pair_overlap — die Begründung der Vermutung, in Zahlen
  ///
  /// In de, this message translates to:
  /// **'Überlappung {x} von {y} min der kürzeren Einheit · Start {d} min auseinander'**
  String hcPairOverlap(int x, int y, int d);

  /// Board 15 · hc.pair_merge
  ///
  /// In de, this message translates to:
  /// **'Zusammenführen'**
  String get hcPairMerge;

  /// Board 15 · hc.pair_keep_apart
  ///
  /// In de, this message translates to:
  /// **'Getrennt lassen'**
  String get hcPairKeepApart;

  /// Board 15 · hc.merge_stage1_title
  ///
  /// In de, this message translates to:
  /// **'Zusammenführen — das ändert sich'**
  String get hcMergeStage1Title;

  /// Board 15 · hc.unlink_stage1_title
  ///
  /// In de, this message translates to:
  /// **'Verbindung lösen — das ändert sich'**
  String get hcUnlinkStage1Title;

  /// Board 15 · hc.merge_stays — die Zeilen, die sagen, was gleich bleibt
  ///
  /// In de, this message translates to:
  /// **'{value} bleibt'**
  String hcMergeStays(String value);

  /// Board 15 · eine Grösse, die hinzukommt; der Pfeil wird nie vorgelesen
  ///
  /// In de, this message translates to:
  /// **'wird {value}'**
  String hcMergeGains(String value);

  /// Board 15 · eine Grösse, die beim Lösen wegfällt
  ///
  /// In de, this message translates to:
  /// **'entfällt'**
  String get hcMergeLoses;

  /// Board 15 · hc.merge_duration_note — bei Widerspruch gewinnt die App
  ///
  /// In de, this message translates to:
  /// **'Dauer bleibt bei der App: {app} min. Die Uhr meldet {watch} min.'**
  String hcMergeDurationNote(int app, int watch);

  /// Board 15 · hc.merged_snack
  ///
  /// In de, this message translates to:
  /// **'Zusammengeführt · Puls übernommen'**
  String get hcMergedSnack;

  /// Board 15 · Meldung nach dem Lösen
  ///
  /// In de, this message translates to:
  /// **'Verbindung gelöst · Uhr-Einheit zurück im Eingang'**
  String get hcUnlinkedSnack;

  /// Board 15 · hc.ambiguous_note
  ///
  /// In de, this message translates to:
  /// **'Mehrere App-Einheiten liegen in diesem Zeitraum. ATEM ordnet nicht zu, wenn die Zuordnung nicht eindeutig ist.'**
  String get hcAmbiguousNote;

  /// Board 15 · hc.ambiguous_pick
  ///
  /// In de, this message translates to:
  /// **'Wählen'**
  String get hcAmbiguousPick;

  /// Board 15 · hc.ambiguous_standalone
  ///
  /// In de, this message translates to:
  /// **'Als eigene Einheit prüfen'**
  String get hcAmbiguousStandalone;

  /// Board 15 · hc.unlink
  ///
  /// In de, this message translates to:
  /// **'Verbindung lösen'**
  String get hcUnlink;

  /// Board 15 · hc.sources_label
  ///
  /// In de, this message translates to:
  /// **'Quellen'**
  String get hcSourcesLabel;

  /// Board 15 · hc.source_app
  ///
  /// In de, this message translates to:
  /// **'App · Sätze, Dauer, Anstrengung'**
  String get hcSourceApp;

  /// Board 15 · hc.source_watch
  ///
  /// In de, this message translates to:
  /// **'{device} · Puls, Kalorien'**
  String hcSourceWatch(String device);

  /// Board 15 · hc.watch_reports — der abweichende Fremdwert, violett hinterlegt
  ///
  /// In de, this message translates to:
  /// **'Uhr meldet {start}–{end} · {min} min'**
  String hcWatchReports(String start, String end, int min);

  /// Board 15 · Beschriftung im Folgen-Panel
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get hcFieldSets;

  /// Board 15 · Beschriftung im Folgen-Panel
  ///
  /// In de, this message translates to:
  /// **'Anstrengung'**
  String get hcFieldEffort;

  /// Board 15 · hc.unlink_back_to_inbox, als Zeile im Folgen-Panel
  ///
  /// In de, this message translates to:
  /// **'Uhr-Einheit'**
  String get hcFieldWatchSession;

  /// Board 15 · hc.unlink_back_to_inbox
  ///
  /// In de, this message translates to:
  /// **'zurück in den Eingang'**
  String get hcBackToInbox;

  /// Board 15 · hc.perm_section — Abschnitt in den Einstellungen
  ///
  /// In de, this message translates to:
  /// **'Health Connect'**
  String get hcPermSection;

  /// Board 15 · hc.perm_weight
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht'**
  String get hcPermWeight;

  /// Board 15 · hc.perm_sessions
  ///
  /// In de, this message translates to:
  /// **'Trainingseinheiten'**
  String get hcPermSessions;

  /// Board 15 · hc.perm_grant
  ///
  /// In de, this message translates to:
  /// **'Freigeben'**
  String get hcPermGrant;

  /// Board 15 · D1 — führt in den Play Store, ohne Ausrufezeichen
  ///
  /// In de, this message translates to:
  /// **'Installieren'**
  String get hcPermInstall;

  /// Board 15 · D2 — Zustand einer Zeile
  ///
  /// In de, this message translates to:
  /// **'Nicht freigegeben'**
  String get hcStateDenied;

  /// Board 15 · hc.perm_missing
  ///
  /// In de, this message translates to:
  /// **'Health Connect ist auf diesem Gerät nicht eingerichtet. ATEM funktioniert ohne — Gewicht und Einheiten werden von Hand geführt.'**
  String get hcPermMissingNote;

  /// Board 15 · hc.perm_none
  ///
  /// In de, this message translates to:
  /// **'Nichts freigegeben. ATEM liest erst, wenn du es je Datentyp erlaubst.'**
  String get hcPermNoneNote;

  /// Board 15 · hc.perm_partial
  ///
  /// In de, this message translates to:
  /// **'Gewicht wird gelesen, Einheiten nicht. Der Eingang im Verlauf erscheint erst mit der zweiten Freigabe.'**
  String get hcPermPartialNote;

  /// Board 15 · hc.perm_revoked — kein Countdown, kein Ausrufezeichen
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 übernommene Einheit bleibt, wie sie ist.} other{{n} übernommene Einheiten bleiben, wie sie sind.}} Neue werden nicht mehr gelesen.'**
  String hcPermRevokedNote(int n);

  /// Board 15 · H · gesprochene Fassung von hcOriginBoth. Ein Vorleser liest das Pluszeichen je nach Stimme als "plus" oder gar nicht; die Reihenfolge App zuerst ist fest, damit das Muster hoerbar bleibt.
  ///
  /// In de, this message translates to:
  /// **'App und Uhr'**
  String get hcOriginBothSpoken;

  /// Board 15 · B5, Fall ohne Uhrzeit. Frage statt Vermutung — ATEM hat hier keine Zahl, mit der es etwas begruenden koennte.
  ///
  /// In de, this message translates to:
  /// **'Gehört das zu einer deiner Einheiten?'**
  String get hcUndatedQuestion;

  /// Board 15 · B5, Fall ohne Uhrzeit. Nennt den Grund, nicht die Schuld: Einheiten aus der Vorgaenger-App und nachgetragene tragen keine Startzeit.
  ///
  /// In de, this message translates to:
  /// **'ATEM kennt die Uhrzeit dieser Einheiten nicht und vermutet deshalb nichts.'**
  String get hcUndatedNote;

  /// Board 16 · detail.back
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get detailBack;

  /// Board 16 · detail.kind.strength
  ///
  /// In de, this message translates to:
  /// **'Kraft'**
  String get detailKindStrength;

  /// Board 16 · detail.kind.bodyweight
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht'**
  String get detailKindBodyweight;

  /// Board 16 · detail.kind.endurance
  ///
  /// In de, this message translates to:
  /// **'Ausdauer'**
  String get detailKindEndurance;

  /// Board 16 · detail.kind.recovery
  ///
  /// In de, this message translates to:
  /// **'Regeneration'**
  String get detailKindRecovery;

  /// Board 16 · detail.time_range
  ///
  /// In de, this message translates to:
  /// **'{day} {date} · {start}–{end}'**
  String detailTimeRange(String day, String date, String start, String end);

  /// Board 16 · detail.time_no_duration
  ///
  /// In de, this message translates to:
  /// **'{day} {date} · keine Dauer erfasst'**
  String detailTimeNoDuration(String day, String date);

  /// Board 16 · detail.lead.sets
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get detailLeadSets;

  /// Board 16 · detail.lead.volume
  ///
  /// In de, this message translates to:
  /// **'kg'**
  String get detailLeadVolume;

  /// Board 16 · detail.lead.distance
  ///
  /// In de, this message translates to:
  /// **'km'**
  String get detailLeadDistance;

  /// Board 16 · detail.lead.duration
  ///
  /// In de, this message translates to:
  /// **'min'**
  String get detailLeadDuration;

  /// Board 16 · detail.basis.strength
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{{n} Übung} other{{n} Übungen}} · {dur} min · Anstrengung {rpe} von 5'**
  String detailBasisStrength(int n, int dur, int rpe);

  /// Board 16 · detail.basis.run
  ///
  /// In de, this message translates to:
  /// **'{dur} min · {pace} /km im Schnitt'**
  String detailBasisRun(int dur, String pace);

  /// Board 16 · detail.basis.recovery
  ///
  /// In de, this message translates to:
  /// **'ohne Last · {name}'**
  String detailBasisRecovery(String name);

  /// Board 16 · detail.basis.empty
  ///
  /// In de, this message translates to:
  /// **'Nur Art und Tag sind bekannt.'**
  String get detailBasisEmpty;

  /// Board 16 · detail.no_effort
  ///
  /// In de, this message translates to:
  /// **'ohne Anstrengung'**
  String get detailNoEffort;

  /// Board 16 · detail.metric.duration
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get detailMetricDuration;

  /// Board 16 · detail.metric.volume
  ///
  /// In de, this message translates to:
  /// **'Volumen'**
  String get detailMetricVolume;

  /// Board 16 · detail.metric.hr_avg
  ///
  /// In de, this message translates to:
  /// **'Ø Puls'**
  String get detailMetricHrAvg;

  /// Board 16 · detail.metric.calories
  ///
  /// In de, this message translates to:
  /// **'Kalorien'**
  String get detailMetricCalories;

  /// Board 16 · detail.metric.elevation
  ///
  /// In de, this message translates to:
  /// **'Höhenmeter'**
  String get detailMetricElevation;

  /// Board 16 · detail.block.work.strength
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{Übung · {n}} other{Übungen · {n}}}'**
  String detailBlockWorkStrength(int n);

  /// Board 16 · detail.block.hr
  ///
  /// In de, this message translates to:
  /// **'Puls'**
  String get detailBlockHr;

  /// Board 16 · detail.block.note
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get detailBlockNote;

  /// Board 16 · detail.delta_vs
  ///
  /// In de, this message translates to:
  /// **'{glyph} {value} gegen {date}'**
  String detailDeltaVs(String glyph, String value, String date);

  /// Board 16 · detail.zones_basis
  ///
  /// In de, this message translates to:
  /// **'Aus {min} von {total} min Aufzeichnung · deine Zonen vom {date}'**
  String detailZonesBasis(int min, int total, String date);

  /// Board 16 · detail.zones_thin
  ///
  /// In de, this message translates to:
  /// **'Nur {min} von {total} min aufgezeichnet — die Verteilung beschreibt diesen Teil, nicht die Einheit.'**
  String detailZonesThin(int min, int total);

  /// Board 16 · detail.zones_unset
  ///
  /// In de, this message translates to:
  /// **'Zonen sind nicht festgelegt. ATEM rechnet keine Verteilung, solange die Grenzen fehlen.'**
  String get detailZonesUnset;

  /// Board 16 · detail.zones_set_action
  ///
  /// In de, this message translates to:
  /// **'Zonen festlegen'**
  String get detailZonesSetAction;

  /// Board 16 · detail.zone_name
  ///
  /// In de, this message translates to:
  /// **'Zone {n}'**
  String detailZoneName(int n);

  /// Board 16 · detail.zone_range_upto
  ///
  /// In de, this message translates to:
  /// **'bis {bpm} bpm'**
  String detailZoneRangeUpto(int bpm);

  /// Board 16 · detail.zone_range_from
  ///
  /// In de, this message translates to:
  /// **'ab {bpm} bpm'**
  String detailZoneRangeFrom(int bpm);

  /// Board 16 · detail.zone_range
  ///
  /// In de, this message translates to:
  /// **'{from}–{to} bpm'**
  String detailZoneRange(int from, int to);

  /// Board 16 · detail.explain.zones
  ///
  /// In de, this message translates to:
  /// **'Gerechnet aus dem Pulsverlauf der Uhr: jede Sekunde zählt in die Zone, in der sie liegt. Kein Sollwert — die Verteilung beschreibt, was war.'**
  String get detailExplainZones;

  /// Board 16 · detail.explain.volume
  ///
  /// In de, this message translates to:
  /// **'Summe aus Wiederholungen × Gewicht aller Sätze mit Gewichtsangabe. Sätze ohne Gewicht fehlen im Volumen und stehen im Nenner.'**
  String get detailExplainVolume;

  /// Board 16 · detail.error.hr
  ///
  /// In de, this message translates to:
  /// **'Puls nicht lesbar'**
  String get detailErrorHr;

  /// Board 16 · detail.retry
  ///
  /// In de, this message translates to:
  /// **'Erneut'**
  String get detailRetry;

  /// Board 16 · detail.edit
  ///
  /// In de, this message translates to:
  /// **'Einheit bearbeiten'**
  String get detailEdit;

  /// Board 16 · detail.delete
  ///
  /// In de, this message translates to:
  /// **'Einheit löschen'**
  String get detailDelete;

  /// Board 16 · settings.zones_title
  ///
  /// In de, this message translates to:
  /// **'Herzfrequenzzonen'**
  String get settingsZonesTitle;

  /// Board 16 · settings.zones_state_set
  ///
  /// In de, this message translates to:
  /// **'Festgelegt am {date}'**
  String settingsZonesStateSet(String date);

  /// Board 16 · settings.zones_state_unset. Das Board sagt „Nicht festgelegt“ — auf 361 dp brach der Wert damit unter die Beschriftung und machte die Zeile unruhiger als die Nachbarn; „Offen“ steht daneben (auf Wunsch, 21.09.2026). Nur Deutsch: „Not set“ passt in die Zeile.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get settingsZonesStateUnset;

  /// Board 16 · settings.zones_basis_pct
  ///
  /// In de, this message translates to:
  /// **'% von HFmax {hrmax}'**
  String settingsZonesBasisPct(int hrmax);

  /// Board 16 · settings.zones_basis_bpm
  ///
  /// In de, this message translates to:
  /// **'Absolute bpm'**
  String get settingsZonesBasisBpm;

  /// Board 16 · settings.zones_proposal
  ///
  /// In de, this message translates to:
  /// **'Vorschlag aus HFmax rechnen'**
  String get settingsZonesProposal;

  /// Board 16 · settings.zones_proposal_note
  ///
  /// In de, this message translates to:
  /// **'Ein Startpunkt, keine Empfehlung. Jede Grenze bleibt einzeln änderbar.'**
  String get settingsZonesProposalNote;

  /// Board 16 · settings.zones_boundary
  ///
  /// In de, this message translates to:
  /// **'Grenze {n} · zwischen Zone {a} und Zone {b}'**
  String settingsZonesBoundary(int n, int a, int b);

  /// Board 16 · settings.zones_boundary_limit
  ///
  /// In de, this message translates to:
  /// **'Höchstens {bpm} bpm — die nächste Grenze liegt darüber.'**
  String settingsZonesBoundaryLimit(int bpm);

  /// Board 16 · settings.zones_retro
  ///
  /// In de, this message translates to:
  /// **'Gilt auch für vergangene Einheiten: Zonen werden aus dem gespeicherten Pulsverlauf gerechnet, nicht beim Import festgeschrieben.'**
  String get settingsZonesRetro;

  /// Board 16 · settings.zones_no_hrmax
  ///
  /// In de, this message translates to:
  /// **'HFmax fehlt. Prozentgrenzen brauchen einen Wert — oder du legst die Grenzen in bpm fest.'**
  String get settingsZonesNoHrmax;

  /// Board 16 · settings.zones_saved
  ///
  /// In de, this message translates to:
  /// **'Zonen gespeichert'**
  String get settingsZonesSaved;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Grenzen in bpm festlegen'**
  String get settingsZonesSetBounds;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'HFmax eintragen'**
  String get settingsZonesHrMaxEnter;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'HFmax {hrmax} · selbst eingetragen am {date}'**
  String settingsZonesHrMaxLine(int hrmax, String date);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Nicht festgelegt. Ohne Grenzen zeigt eine Einheit ihren Puls, aber keine Verteilung.'**
  String get settingsZonesUnsetNote;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Bestehende Grenzen bleiben unverändert, solange nichts gespeichert wird.'**
  String get settingsZonesKeepNote;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'HFmax {hrmax} selbst eingetragen. Gespeichert werden immer bpm; die Prozente sind daraus gerechnet.'**
  String settingsZonesBasisNotePct(int hrmax);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Grenzen direkt in bpm. Ohne HFmax — nichts wird umgerechnet.'**
  String get settingsZonesBasisNoteBpm;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Grenze {n}'**
  String settingsZonesBoundaryTitle(int n);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'bpm · {pct} % von {hrmax}'**
  String settingsZonesStepperCaption(int pct, int hrmax);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'bpm'**
  String get settingsZonesStepperCaptionBpm;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Minus 1 bpm'**
  String get settingsZonesMinusA11y;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Plus 1 bpm'**
  String get settingsZonesPlusA11y;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Mindestens {bpm} bpm — die vorige Grenze liegt darunter.'**
  String settingsZonesLowerLimit(int bpm);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Minuten rechts: Einheit vom {date}'**
  String settingsZonesLastSession(String date);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{state}. Öffnen.'**
  String settingsZonesRowA11y(String state);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Maximalpuls'**
  String get settingsZonesHrMaxTitle;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'HFmax in bpm'**
  String get settingsZonesHrMaxField;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Zwischen {min} und {max} bpm. ATEM schätzt HFmax nicht aus dem Alter.'**
  String settingsZonesHrMaxRange(int min, int max);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'HFmax speichern'**
  String get settingsZonesHrMaxSave;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'HFmax speichern, nicht möglich, Wert zwischen {min} und {max} nötig'**
  String settingsZonesHrMaxInvalid(int min, int max);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'HFmax {hrmax}, selbst eingetragen am {date}. Ändern.'**
  String settingsZonesHrMaxA11y(int hrmax, String date);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Grenzen festlegen'**
  String get settingsZonesBoundsTitle;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Jede Grenze ist der erste Pulswert der oberen Zone und liegt über der vorigen.'**
  String get settingsZonesBoundsRule;

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Grenze {n} in bpm'**
  String settingsZonesBoundsField(int n);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Speichern, nicht möglich, Grenze {n} muss über Grenze {m} liegen'**
  String settingsZonesBoundsInvalid(int n, int m);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Speichern, nicht möglich, noch {n} Grenzen fehlen'**
  String settingsZonesBoundsMissing(int n);

  /// Board 16 · D · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Vorschlag übernommen. Jede Grenze bleibt einzeln änderbar.'**
  String get settingsZonesProposalDone;

  /// Board 16 · D3 · Untertitel des Grenzen-Blatts — der Titel nennt die Grenze schon, der Untertitel wiederholt sie nicht
  ///
  /// In de, this message translates to:
  /// **'zwischen Zone {a} und Zone {b}'**
  String settingsZonesBetween(int a, int b);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'bpm'**
  String get detailUnitBpm;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'kcal'**
  String get detailUnitKcal;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'hm'**
  String get detailUnitHm;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{{n} Übung} other{{n} Übungen}}'**
  String detailBasisExercises(int n);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Anstrengung {rpe} von 5'**
  String detailBasisEffort(int rpe);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Durchschnittspuls'**
  String get detailSpokenHrAvg;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Maximalpuls'**
  String get detailSpokenHrMax;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Minimalpuls'**
  String get detailSpokenHrMin;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Last'**
  String get detailSpokenLoad;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{label} {value} {unit}, {source}'**
  String detailSpokenTile(
      String label, String value, String unit, String source);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'aus der App'**
  String get detailSourceApp;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Ø'**
  String get detailHrAvgShort;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Max'**
  String get detailHrMaxShort;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Min'**
  String get detailHrMinShort;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Puls & Zonen'**
  String get detailBlockHrZones;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Z{n}'**
  String detailZoneShort(int n);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{from} bis {to} bpm'**
  String detailZoneSpokenRange(int from, int to);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Zone {n}, {range}, {time} von {total} Minuten'**
  String detailZoneA11y(int n, String range, String time, int total);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{min} Minuten {sec}'**
  String detailZoneTimeSpoken(int min, int sec);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Zeit in Zonen, aus {min} von {total} Minuten Aufzeichnung, deine Zonen vom {date}'**
  String detailZonesGroupA11y(int min, int total, String date);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Aus {min} von {total} min Aufzeichnung'**
  String detailHrBasisNoZones(int min, int total);

  /// Board 16 · offene Frage 1, gelöst am 22.09.2026 — Unterüberschrift über der Verlaufskurve, labelMicro in Versalien
  ///
  /// In de, this message translates to:
  /// **'Pulsverlauf'**
  String get detailPulseCurveTitle;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Puls wird geladen'**
  String get detailHrLoading;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Der Uhr-Datensatz antwortet nicht.'**
  String get detailErrorHrBody;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Zuletzt gelesen {date}'**
  String detailHrLastRead(String date);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'+ {n} weitere'**
  String detailWorkMore(int n);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'ohne Vergleich'**
  String get detailWorkNoComparison;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{{n} Satz} other{{n} Sätze}}'**
  String detailWorkSets(int n);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{n} kg'**
  String detailDeltaWeight(String n);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{n} Wdh'**
  String detailDeltaReps(String n);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'gleich'**
  String get detailDeltaSame;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{value} mehr als am {date}'**
  String detailDeltaSpokenMore(String value, String date);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{value} weniger als am {date}'**
  String detailDeltaSpokenLess(String value, String date);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'gleich wie am {date}'**
  String detailDeltaSpokenSame(String date);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{n} Kilogramm'**
  String detailSpokenKg(String n);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{{n} Wiederholung} other{{n} Wiederholungen}}'**
  String detailSpokenReps(int n);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{name}, {sets}, bestes {best}{delta}. Sätze anzeigen.'**
  String detailExerciseA11y(
      String name, String sets, String best, String delta);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Übungsverlauf'**
  String get detailExerciseHistory;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Satz {n} · {detail}'**
  String detailSetRow(int n, String detail);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Selbst geführt'**
  String get detailOriginApp;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Aus der Uhr übernommen'**
  String get detailOriginWatch;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'App + Uhr · zusammengeführt'**
  String get detailOriginBoth;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'App · alle Werte'**
  String get detailOriginMetaApp;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'App · nur Art und Tag'**
  String get detailOriginMetaEmpty;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'App: Sätze, Dauer · Uhr: Puls, kcal'**
  String get detailOriginMetaMerged;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{device} · alle Werte'**
  String detailOriginMetaWatch(String device);

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Herkunft: App und Uhr, zusammengeführt. App liefert Sätze und Dauer, Uhr liefert Puls und Kalorien.'**
  String get detailOriginA11yBoth;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Anstrengung nachtragen'**
  String get detailAddEffort;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Verlauf'**
  String get detailBackA11y;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'Einheit wird geladen'**
  String get detailLoadingA11y;

  /// Board 16 · Ergänzung — steht nicht in der Stringtabelle des Boards, folgt aber den Artboards
  ///
  /// In de, this message translates to:
  /// **'{day} {date}'**
  String detailTimeDayOnly(String day, String date);

  /// Board 16 · Ergänzung — „ohne Last · {name}" ohne Namen: Regeneration ohne bekannte Art
  ///
  /// In de, this message translates to:
  /// **'ohne Last'**
  String get detailBasisNoLoad;

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Zone 5 je Woche'**
  String get zoneFiveTitle;

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Ab festgelegten Zonen und einer Einheit mit Puls'**
  String get zoneFiveConditionZones;

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Ab einer Einheit mit Puls aus der Uhr'**
  String get zoneFiveConditionPulse;

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Die Minuten, in denen dein Puls in Zone 5 lag — ab {bpm} bpm, nach deinen Grenzen. Je Woche summiert, aus den Einheiten mit Puls aus der Uhr.'**
  String zoneFiveWhat(int bpm);

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Kein Sollwert: Mehr Zeit in Zone 5 ist nicht besser, weniger nicht schlechter. Ändern sich deine Grenzen, rechnet sich jede Woche neu.'**
  String get zoneFiveExplainNoTarget;

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'KW {week} · {n, plural, one{1 Einheit mit Puls} other{{n} Einheiten mit Puls}}'**
  String zoneFiveHead(int week, int n);

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'aus {n} von {m, plural, one{1 Einheit} other{{m} Einheiten}} · Puls aus der Uhr'**
  String zoneFiveBasis(int n, int m);

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Diese Woche ohne Puls'**
  String get zoneFiveNoPulseThisWeek;

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Zone 5 je Woche: {weeks}'**
  String zoneFiveStripA11y(String weeks);

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Kalenderwoche {week}, {min} Minuten in Zone 5'**
  String zoneFiveWeekA11y(int week, int min);

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Kalenderwoche {week}, gemessen, keine Zeit in Zone 5'**
  String zoneFiveWeekZeroA11y(int week);

  /// Auswertung · Zone 5 je Woche — auf Wunsch vom 21.09.2026, ohne Board (Ergänzung)
  ///
  /// In de, this message translates to:
  /// **'Kalenderwoche {week}, kein Puls aufgezeichnet'**
  String zoneFiveWeekNoneA11y(int week);

  /// Board 09 · Kurztitel der Muskelbalance für die halbe Breite (Split-Card, 21.09.2026). „MUSKELBALANCE" bricht dort in Versalien mitten im Wort; der volle Name steht weiter in der Ansage und im Kopf der Unterseite.
  ///
  /// In de, this message translates to:
  /// **'Balance'**
  String get balanceTitleShort;

  /// Auswertung · „Sätze je Woche": Woche, Einheiten und Schnitt in einer Zeile statt in dreien (21.09.2026, auf Rückmeldung „viel zu viel Text"). Der Nenner bleibt — nur die Zeilen werden zu einer.
  ///
  /// In de, this message translates to:
  /// **'KW {week} · {n, plural, =1{1 Einheit} other{{n} Einheiten}} · Ø {avg} aus 4 Wochen'**
  String weeklySetsLine(int week, int n, String avg);

  /// Dieselbe Zeile, solange der Schnitt noch nicht trägt.
  ///
  /// In de, this message translates to:
  /// **'KW {week} · {n, plural, =1{1 Einheit} other{{n} Einheiten}} · Vergleich ab 2 vollen Wochen'**
  String weeklySetsLinePending(int week, int n);

  /// Board 17 · train.last_kicker — Kicker des Faktenkopfs, ohne Plan für heute
  ///
  /// In de, this message translates to:
  /// **'Zuletzt'**
  String get trainLastKicker;

  /// Board 17 · train.last_meta
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{heute · {e} Übungen · {min} Min} one{gestern · {e} Übungen · {min} Min} other{vor {n} Tagen · {e} Übungen · {min} Min}}'**
  String trainLastMeta(int n, int e, int min);

  /// Board 17 · train.start_free — Knopfbeschriftung ohne Plan
  ///
  /// In de, this message translates to:
  /// **'Frei starten'**
  String get trainStartFree;

  /// Board 17 · train.foot_new_plan
  ///
  /// In de, this message translates to:
  /// **'Plan anlegen'**
  String get trainFootNewPlan;

  /// Board 17 · train.foot_log
  ///
  /// In de, this message translates to:
  /// **'Nachtragen'**
  String get trainFootLog;

  /// Board 17 · train.tile_exercises — gekürzt, damit der Titel auch bei 200 % einzeilig bleibt
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get trainTileExercises;

  /// Board 17 · train.tile_exercises_meta
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 im Katalog} other{{n} im Katalog}}'**
  String trainTileExercisesMeta(int n);

  /// Board 17 · train.tile_plan
  ///
  /// In de, this message translates to:
  /// **'Training planen'**
  String get trainTilePlan;

  /// Board 17 · train.tile_plan_meta
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 eigener Plan} other{{n} eigene Pläne}}'**
  String trainTilePlanMeta(int n);

  /// Board 17 · train.tile_plan_meta_none
  ///
  /// In de, this message translates to:
  /// **'Noch kein eigener Plan'**
  String get trainTilePlanMetaNone;

  /// Board 17 · train.error_kicker
  ///
  /// In de, this message translates to:
  /// **'Nicht geladen'**
  String get trainErrorKicker;

  /// Board 17 · train.error_title
  ///
  /// In de, this message translates to:
  /// **'Heutiger Plan nicht verfügbar'**
  String get trainErrorTitle;

  /// Board 17 · train.error_meta
  ///
  /// In de, this message translates to:
  /// **'Zuletzt geprüft {time}'**
  String trainErrorMeta(String time);

  /// Board 17 · train.loading_a11y
  ///
  /// In de, this message translates to:
  /// **'Heutiger Plan wird geladen'**
  String get trainLoadingA11y;

  /// Board 17 · train.block_a11y_planned — ein Knoten für Kicker, Titel und Meta
  ///
  /// In de, this message translates to:
  /// **'Heute geplant: {name}, {n} Übungen, etwa {min} Minuten'**
  String trainBlockA11yPlanned(String name, int n, int min);

  /// Board 17 · train.block_a11y_planned ohne bekannten Plan — keine erfundene Zählung
  ///
  /// In de, this message translates to:
  /// **'Heute geplant: {name}'**
  String trainBlockA11yPlannedPlain(String name);

  /// Board 17 · train.block_a11y_last
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{Zuletzt: {name}, heute} one{Zuletzt: {name}, gestern} other{Zuletzt: {name}, vor {n} Tagen}}'**
  String trainBlockA11yLast(String name, int n);

  /// Board 17 · train.start_a11y_planned
  ///
  /// In de, this message translates to:
  /// **'{name} starten'**
  String trainStartA11yPlanned(String name);

  /// Board 17 · train.start_a11y_free
  ///
  /// In de, this message translates to:
  /// **'Freie Einheit starten'**
  String get trainStartA11yFree;

  /// Board 17 · Kachel: Titel und Zahl als ein Knoten
  ///
  /// In de, this message translates to:
  /// **'{title}, {meta}'**
  String trainTileExercisesA11y(String title, String meta);

  /// Board 17 · train.last_meta ohne bekannte Übungszahl — keine erfundene Null
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{heute · {min} Min} one{gestern · {min} Min} other{vor {n} Tagen · {min} Min}}'**
  String trainLastMetaShort(int n, int min);

  /// Board 17 · train.last_meta ohne Dauer und ohne Übungszahl
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{heute} one{gestern} other{vor {n} Tagen}}'**
  String trainLastMetaBare(int n);

  /// Board 16 · pulse.curve.range — die Spanne über der Kurve, solange niemand schiebt
  ///
  /// In de, this message translates to:
  /// **'{from}–{to} bpm'**
  String pulseCurveRange(int from, int to);

  /// Board 16 · pulse.curve.readout — was unter dem Finger steht, mit Zone
  ///
  /// In de, this message translates to:
  /// **'{time} · {value} · {zone}'**
  String pulseCurveReadout(Object time, Object value, Object zone);

  /// Board 16 · pulse.curve.readout.plain — dasselbe ohne festgelegte Zonen
  ///
  /// In de, this message translates to:
  /// **'{time} · {value}'**
  String pulseCurveReadoutPlain(Object time, Object value);

  /// Board 16 · pulse.curve.axis.start — der linke Rand der Zeitachse
  ///
  /// In de, this message translates to:
  /// **'0 min'**
  String get pulseCurveStart;

  /// Board 16 Nachtrag · detail.load.basis.entered
  ///
  /// In de, this message translates to:
  /// **'gerechnet · eingetragen {rpe} von 5'**
  String detailLoadBasisEntered(int rpe);

  /// Board 16 Nachtrag · detail.load.basis.measured — {ring} ist die Stelle des Ring-Glyphs, nicht Text. Er qualifiziert die Eingangsgrösse, deshalb steht er unmittelbar vor dem Wort, das sie benennt.
  ///
  /// In de, this message translates to:
  /// **'gerechnet · {ring}gemessen {rpe} von 5'**
  String detailLoadBasisMeasured(String ring, int rpe);

  /// Board 16 Nachtrag · detail.load.basis.fallback
  ///
  /// In de, this message translates to:
  /// **'gerechnet · Ersatzwert {rpe} von 5'**
  String detailLoadBasisFallback(int rpe);

  /// Board 16 Nachtrag · detail.load.a11y.entered
  ///
  /// In de, this message translates to:
  /// **'Last {value}, gerechnet aus eingetragener Anstrengung {rpe} von 5'**
  String detailLoadA11yEntered(String value, int rpe);

  /// Board 16 Nachtrag · detail.load.a11y.measured
  ///
  /// In de, this message translates to:
  /// **'Last {value}, gerechnet aus gemessener Anstrengung {rpe} von 5, aus der Uhr'**
  String detailLoadA11yMeasured(String value, int rpe);

  /// Board 16 Nachtrag · detail.load.a11y.fallback
  ///
  /// In de, this message translates to:
  /// **'Last {value}, gerechnet mit Ersatzwert {rpe} von 5'**
  String detailLoadA11yFallback(String value, int rpe);

  /// Board 16 Nachtrag · detail.load.explain.title
  ///
  /// In de, this message translates to:
  /// **'Wie die Last gerechnet wird'**
  String get detailLoadExplainTitle;

  /// Board 16 Nachtrag · detail.load.explain.formula.endurance — volle Formel statt der verkürzten aus dem Board
  ///
  /// In de, this message translates to:
  /// **'Dauer in Minuten × Anstrengung (1–5) × 4 × Faktor der Sportart. Ab zwei Stunden zählt jede weitere Minute weniger.'**
  String get detailLoadExplainFormulaEndurance;

  /// Board 16 Nachtrag · detail.load.explain.formula.strength — Teiler 50 wie in der Rechnung
  ///
  /// In de, this message translates to:
  /// **'Volumen in Kilogramm × Anstrengung (1–5), geteilt durch 50. Ohne Sätze zählt die Dauer.'**
  String get detailLoadExplainFormulaStrength;

  /// Board 16 Nachtrag · detail.load.explain.entered
  ///
  /// In de, this message translates to:
  /// **'Anstrengung {rpe} von 5 — von dir eingetragen.'**
  String detailLoadExplainEntered(int rpe);

  /// Board 16 Nachtrag · detail.load.explain.measured
  ///
  /// In de, this message translates to:
  /// **'Keine Anstrengung eingetragen. An ihre Stelle tritt der gemessene Schnitt aus dem Pulsverlauf: {rpe} von 5, zeitgewichtet aus {n, plural, one{1 Minute} other{{n} Minuten}} Aufzeichnung.'**
  String detailLoadExplainMeasured(int rpe, int n);

  /// Board 16 Nachtrag · detail.load.explain.entered_wins
  ///
  /// In de, this message translates to:
  /// **'Eingetragen gilt: {entered} von 5. Aus dem Pulsverlauf gemessen: {measured} von 5.'**
  String detailLoadExplainEnteredWins(int entered, int measured);

  /// Board 16 Nachtrag · detail.load.explain.fallback
  ///
  /// In de, this message translates to:
  /// **'Weder eingetragen noch gemessen. Gerechnet wird mit {rpe} von 5.'**
  String detailLoadExplainFallback(int rpe);

  /// Board 16 Nachtrag · detail.hr.resolution.minute
  ///
  /// In de, this message translates to:
  /// **'je Minute ein Wert'**
  String get pulseCurveResolutionMinute;

  /// Board 16 Nachtrag · detail.hr.resolution.ten
  ///
  /// In de, this message translates to:
  /// **'je 10 Sekunden ein Wert'**
  String get pulseCurveResolutionTen;

  /// Board 16 Nachtrag · detail.hr.basis — die Grundlage unter der Kurve
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{Aus 1 Minute} other{Aus {n} Minuten}} von {total} Aufzeichnung · {resolution}'**
  String pulseCurveBasis(int n, int total, String resolution);

  /// Board 16 Nachtrag · detail.hr.a11y.curve — die Kurve ist ein Slider-Knoten
  ///
  /// In de, this message translates to:
  /// **'Pulsverlauf, {dur} Minuten, {min} bis {max} bpm, {resolution}. Zum Durchgehen wischen.'**
  String pulseCurveA11ySlider(int dur, int min, int max, String resolution);

  /// Board 16 Nachtrag · detail.hr.a11y.point — der Wert des Sliders
  ///
  /// In de, this message translates to:
  /// **'{time}, {bpm} bpm, Zone {zone}'**
  String pulseCurveA11yPoint(String time, int bpm, int zone);

  /// Board 16 Nachtrag · dasselbe ohne festgelegte Zonen
  ///
  /// In de, this message translates to:
  /// **'{time}, {bpm} bpm'**
  String pulseCurveA11yPointPlain(String time, int bpm);

  /// Board 16 Nachtrag · was abgelesen wird, wo die Uhr nichts gemessen hat
  ///
  /// In de, this message translates to:
  /// **'{time} · keine Aufzeichnung'**
  String pulseCurveGap(Object time);

  /// Board 16 Nachtrag · detail.hr.a11y.gap — die Lücke ist ein eigener Schritt
  ///
  /// In de, this message translates to:
  /// **'{time}, keine Aufzeichnung'**
  String pulseCurveA11yGap(Object time);

  /// Board 16 Nachtrag · Spanne und Auflösung in einer Zeile über der Kurve. Platzhalter ausdrücklich erklärt: Ohne das ordnet gen-l10n die Parameter alphabetisch, und {resolution} stünde vor {span}.
  ///
  /// In de, this message translates to:
  /// **'{span} · {resolution}'**
  String pulseCurveSpan(String span, String resolution);

  /// Board 16 Nachtrag · detail.hr.sections — nur wenn grösser als 1
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{in 1 Abschnitt} other{in {n} Abschnitten}}'**
  String pulseCurveSections(int n);

  /// Board 16 Nachtrag · detail.hr.basis — drei Glieder in einer Zeile
  ///
  /// In de, this message translates to:
  /// **'Aus {min} von {total} min Aufzeichnung · {sections} · {resolution}'**
  String pulseCurveBlockBasis(
      int min, int total, String sections, String resolution);

  /// Board 16 Nachtrag · dieselbe Zeile ohne Abschnittsglied, wenn es nur einen gibt
  ///
  /// In de, this message translates to:
  /// **'Aus {min} von {total} min Aufzeichnung · {resolution}'**
  String pulseCurveBlockBasisWhole(int min, int total, String resolution);

  /// Board 16 Nachtrag · detail.hr.rings.a11y — ausdrücklich gezeichnet, nicht gemessen
  ///
  /// In de, this message translates to:
  /// **'höchster gezeichneter Wert {max} bpm, niedrigster {min} bpm'**
  String pulseCurveRingsA11y(int max, int min);

  /// Board 16 Nachtrag · nA11y „Kurve mit Lücken" — die Abschnittszahl steht im Label, nicht nur im Bild
  ///
  /// In de, this message translates to:
  /// **'Pulsverlauf, {dur} Minuten, aufgezeichnet {rec} Minuten {sections}, {resolution}'**
  String pulseCurveA11yCurve(
      int dur, int rec, String sections, String resolution);

  /// Board 16 Nachtrag · detail.hr.explain.raw_vs_curve
  ///
  /// In de, this message translates to:
  /// **'Die Kacheln nennen die Rohwerte der Uhr. Die Kurve zeichnet Mittel über je {interval}; ihr höchster Punkt liegt deshalb unter Max.'**
  String pulseCurveExplainRawVsCurve(String interval);

  /// Board 16 Nachtrag · das Mittelungsfenster als Wort, für den Erklärsatz
  ///
  /// In de, this message translates to:
  /// **'10 Sekunden'**
  String get pulseCurveIntervalTen;

  /// Board 16 Nachtrag · dasselbe für die alte Ablage
  ///
  /// In de, this message translates to:
  /// **'eine Minute'**
  String get pulseCurveIntervalMinute;

  /// Board 16 Nachtrag · der Zonenstichtag zog aus der Grundlage ins ⓘ, weil die Zeile nur drei Glieder trägt. **Ohne Schlusspunkt**: Ein abgekürztes Datum endet selbst auf einen Punkt („12. Sept."), und zwei nebeneinander sind ein sichtbarer Fehler.
  ///
  /// In de, this message translates to:
  /// **'Deine Zonen vom {date}'**
  String detailZonesSetOn(Object date);
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppL10nDe();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
