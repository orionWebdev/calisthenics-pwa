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

  /// about.access
  ///
  /// In de, this message translates to:
  /// **'Zugang'**
  String get aboutAccess;

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

  /// about.appearance
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get aboutAppearance;

  /// about.appearance.value
  ///
  /// In de, this message translates to:
  /// **'Dunkel · keine helle Fassung'**
  String get aboutAppearanceValue;

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

  /// about.languages
  ///
  /// In de, this message translates to:
  /// **'Sprachen'**
  String get aboutLanguages;

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

  /// about.version
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// Board 08, ueber
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get aboutVersionLabel;

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

  /// account.delete2.confirm
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get accountDelete2Confirm;

  /// account.delete2.keep
  ///
  /// In de, this message translates to:
  /// **'Behalten'**
  String get accountDelete2Keep;

  /// account.delete2.title
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get accountDelete2Title;

  /// account.delete2.typeCount
  ///
  /// In de, this message translates to:
  /// **'{a} / {b} Zeichen'**
  String accountDelete2TypeCount(int a, String b);

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

  /// account.deleting.step
  ///
  /// In de, this message translates to:
  /// **'{name}'**
  String accountDeletingStep(String name);

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
  /// **'Deine Aktivitäten · {n, plural, one{1 Einheit} other{# Einheiten}}'**
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

  /// Achsenbeschriftung
  ///
  /// In de, this message translates to:
  /// **'Form 0–100'**
  String get analysisChartLabel;

  /// Komponente des Form-Werts
  ///
  /// In de, this message translates to:
  /// **'Konstanz'**
  String get analysisCompConsistency;

  /// Komponente des Form-Werts
  ///
  /// In de, this message translates to:
  /// **'Fitness ggü. Höchststand'**
  String get analysisCompFitness;

  /// Komponente des Form-Werts
  ///
  /// In de, this message translates to:
  /// **'Lastentwicklung'**
  String get analysisCompLoad;

  /// Wird getrennt ausgewiesen, nicht verrechnet
  ///
  /// In de, this message translates to:
  /// **'Abzug Untätigkeit'**
  String get analysisCompPenalty;

  /// Komponente des Form-Werts
  ///
  /// In de, this message translates to:
  /// **'Aktualität'**
  String get analysisCompRecency;

  /// Komponente des Form-Werts
  ///
  /// In de, this message translates to:
  /// **'Tageszuschlag'**
  String get analysisCompToday;

  /// Wert einer Komponente
  ///
  /// In de, this message translates to:
  /// **'{v} / {max}'**
  String analysisCompValue(int v, int max);

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

  /// Erklärt die Rechnung — ohne sie ist die Zerlegung eine Zahlenreihe
  ///
  /// In de, this message translates to:
  /// **'Fünf Bestandteile ergeben zusammen bis zu 103 Punkte, gedeckelt auf 100. Wer lange nicht trainiert, verliert zusätzlich — und zwar beschleunigt: drei Tage kosten 3 Punkte, sieben Tage 21, vierzehn Tage 70.'**
  String get analysisExplainBody;

  /// Überschrift der Erklärung
  ///
  /// In de, this message translates to:
  /// **'Wie sich die Form zusammensetzt'**
  String get analysisExplainTitle;

  /// Begründung unter der Zerlegung
  ///
  /// In de, this message translates to:
  /// **'Was fehlt, ist Aktualität — eine Einheit heute bringt sofort {n} Punkte.'**
  String analysisHintRecency(int n);

  /// analysis.legend.rug (Board 06)
  ///
  /// In de, this message translates to:
  /// **'Einheiten/Woche'**
  String get analysisLegendRug;

  /// Legende der Kurve
  ///
  /// In de, this message translates to:
  /// **'mit Training'**
  String get analysisLegendWith;

  /// Legende der Kurve — die Lücke
  ///
  /// In de, this message translates to:
  /// **'ohne Training'**
  String get analysisLegendWithout;

  /// analysis.pace.basis
  ///
  /// In de, this message translates to:
  /// **'gegen eigenen Schnitt {value} · {n, plural, one{1 Lauf} other{# Läufe}}'**
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
  /// **'{n, plural, one{Schneller als 1 deiner Läufe} other{Schneller als # von {total} deiner Läufe}}'**
  String analysisPctFaster(int n, int total);

  /// analysis.pct.noothers
  ///
  /// In de, this message translates to:
  /// **'Kein Vergleich mit anderen Menschen.'**
  String get analysisPctNoothers;

  /// Nennt die Schwellen aus DataSufficiency
  ///
  /// In de, this message translates to:
  /// **'Ein Trend braucht {n} Einheiten und {d} Tage Historie.'**
  String analysisThinBody(int n, int d);

  /// Überschrift über dem Vorhandenen
  ///
  /// In de, this message translates to:
  /// **'Was es schon gibt'**
  String get analysisThinHave;

  /// Fortschritt zur Schwelle
  ///
  /// In de, this message translates to:
  /// **'{cur} / {req}'**
  String analysisThinProgress(int cur, int req);

  /// Zustand bei zu dünner Datenlage
  ///
  /// In de, this message translates to:
  /// **'Noch zu wenig für einen Trend'**
  String get analysisThinTitle;

  /// Titel der Formkurve
  ///
  /// In de, this message translates to:
  /// **'Auswertung'**
  String get analysisTitle;

  /// Überschrift der Zerlegung
  ///
  /// In de, this message translates to:
  /// **'Form heute'**
  String get analysisToday;

  /// analysis.weekly.basis
  ///
  /// In de, this message translates to:
  /// **'Ø {value} km · {n, plural, one{1 Einheit} other{# Einheiten}}'**
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

  /// Begründung unter der Konstanz — zeigt, woraus die Punktzahl entsteht
  ///
  /// In de, this message translates to:
  /// **'{days} Trainingstage in {span}'**
  String analysisWhyConsistency(int days, int span);

  /// Begründung der Fitness gegenüber dem Höchststand
  ///
  /// In de, this message translates to:
  /// **'Anteil am eigenen Höchststand'**
  String get analysisWhyFitness;

  /// Begründung, wenn die Lastentwicklung bei null steht
  ///
  /// In de, this message translates to:
  /// **'Keine Last in den letzten 28 Tagen'**
  String get analysisWhyLoadNone;

  /// Begründung der Lastentwicklung
  ///
  /// In de, this message translates to:
  /// **'Letzte 14 Tage gegen die 14 davor'**
  String get analysisWhyLoadRatio;

  /// Begründung des Abzugs
  ///
  /// In de, this message translates to:
  /// **'{n, plural, other{# Tage ohne Training}}'**
  String analysisWhyPenalty(int n);

  /// Begründung der Aktualität
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{Heute trainiert} one{Letzte Einheit gestern} other{Letzte Einheit vor # Tagen}}'**
  String analysisWhyRecency(int n);

  /// Begründung der Aktualität, wenn die letzte Aktivität eine Regenerationseinheit war
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{Heute Regeneration} one{Gestern Regeneration} other{Letzte Aktivität vor # Tagen · Regeneration}}'**
  String analysisWhyRecencyRecovery(int n);

  /// Begründung des Tageszuschlags
  ///
  /// In de, this message translates to:
  /// **'Heute trainiert'**
  String get analysisWhyToday;

  /// Begründung, wenn der Tageszuschlag entfällt
  ///
  /// In de, this message translates to:
  /// **'Heute keine Einheit'**
  String get analysisWhyTodayNone;

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

  /// Abmelden
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get authSignOut;

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

  /// barrier.dialog (Board 02)
  ///
  /// In de, this message translates to:
  /// **'„{titel}\" — bitte eine Option wählen'**
  String barrierDialog(String titel);

  /// barrier.sheet (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Schließt „{titel}\"'**
  String barrierSheet(String titel);

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

  /// cardio.error.week
  ///
  /// In de, this message translates to:
  /// **'Wochenkilometer nicht berechenbar'**
  String get cardioErrorWeek;

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
  /// **'{n, plural, one{1 Einheit} other{# Einheiten}}'**
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
  String cardioWeekTitle(String kw);

  /// aus common.activity
  ///
  /// In de, this message translates to:
  /// **'Aktivität'**
  String get commonActivity;

  /// aus common.add
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get commonAdd;

  /// aus common.addSession
  ///
  /// In de, this message translates to:
  /// **'Session hinzufügen'**
  String get commonAddSession;

  /// Filterchip ohne Einschränkung
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get commonAll;

  /// aus common.back
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get commonBack;

  /// aus common.bodyweight
  ///
  /// In de, this message translates to:
  /// **'Bodyweight'**
  String get commonBodyweight;

  /// common.cancel
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// aus common.cardio
  ///
  /// In de, this message translates to:
  /// **'Cardio'**
  String get commonCardio;

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

  /// aus common.days
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get commonDays;

  /// aus common.delete
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// aus common.distance
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get commonDistance;

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

  /// aus common.editSession
  ///
  /// In de, this message translates to:
  /// **'Session bearbeiten'**
  String get commonEditSession;

  /// common.got_it (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get commonGotIt;

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

  /// aus common.next
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get commonNext;

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

  /// common.offline
  ///
  /// In de, this message translates to:
  /// **'Lokal gesichert · wird synchronisiert'**
  String get commonOffline;

  /// common.offline.sync
  ///
  /// In de, this message translates to:
  /// **'Lokal gesichert · wird synchronisiert'**
  String get commonOfflineSync;

  /// common.open
  ///
  /// In de, this message translates to:
  /// **'Öffnen'**
  String get commonOpen;

  /// aus common.optional
  ///
  /// In de, this message translates to:
  /// **'optional'**
  String get commonOptional;

  /// aus common.pace
  ///
  /// In de, this message translates to:
  /// **'Pace'**
  String get commonPace;

  /// Prozentzeichen, allein stehend
  ///
  /// In de, this message translates to:
  /// **'%'**
  String get commonPercentSign;

  /// aus common.recovery
  ///
  /// In de, this message translates to:
  /// **'Recovery'**
  String get commonRecovery;

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

  /// aus common.sessions
  ///
  /// In de, this message translates to:
  /// **'Sessions'**
  String get commonSessions;

  /// aus common.start
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get commonStart;

  /// aus common.startAgain
  ///
  /// In de, this message translates to:
  /// **'Erneut starten'**
  String get commonStartAgain;

  /// aus common.strength
  ///
  /// In de, this message translates to:
  /// **'Kraft'**
  String get commonStrength;

  /// aus common.time
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get commonTime;

  /// common.undo
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get commonUndo;

  /// aus common.view
  ///
  /// In de, this message translates to:
  /// **'Ansehen'**
  String get commonView;

  /// aus common.viewDetails
  ///
  /// In de, this message translates to:
  /// **'Details ansehen'**
  String get commonViewDetails;

  /// aus common.weeks
  ///
  /// In de, this message translates to:
  /// **'Wochen'**
  String get commonWeeks;

  /// aus common.workout
  ///
  /// In de, this message translates to:
  /// **'Workout'**
  String get commonWorkout;

  /// compare.basis.date
  ///
  /// In de, this message translates to:
  /// **'{date} · {n} Tage her'**
  String compareBasisDate(String date, int n);

  /// compare.basis.exercises
  ///
  /// In de, this message translates to:
  /// **'Gleiche Übungen'**
  String get compareBasisExercises;

  /// compare.basis.median
  ///
  /// In de, this message translates to:
  /// **'Mittel · {n} Einheiten'**
  String compareBasisMedian(int n);

  /// compare.basis.plan
  ///
  /// In de, this message translates to:
  /// **'Gleicher Plan'**
  String get compareBasisPlan;

  /// compare.empty.plan
  ///
  /// In de, this message translates to:
  /// **'Erste Einheit des Plans „{plan}\". Ab der nächsten steht hier der Vergleich.'**
  String compareEmptyPlan(String plan);

  /// compare.empty.type
  ///
  /// In de, this message translates to:
  /// **'Erste Einheit dieser Art. Ab der nächsten steht hier der Vergleich.'**
  String get compareEmptyType;

  /// compare.loading
  ///
  /// In de, this message translates to:
  /// **'Vergleich wird geladen'**
  String get compareLoading;

  /// compare.median
  ///
  /// In de, this message translates to:
  /// **'Mittel {value}'**
  String compareMedian(String value);

  /// compare.none.value
  ///
  /// In de, this message translates to:
  /// **'kein Bezug'**
  String get compareNoneValue;

  /// compare.note.median
  ///
  /// In de, this message translates to:
  /// **'Keine Plan-ID, keine Übungsüberdeckung. Verglichen wird nur, was von den Übungen unabhängig ist: Dauer und Last.'**
  String get compareNoteMedian;

  /// compare.note.plan
  ///
  /// In de, this message translates to:
  /// **'Beide Einheiten folgen Plan „{plan}\". Alle vier Werte sind vergleichbar.'**
  String compareNotePlan(String plan);

  /// compare.prev
  ///
  /// In de, this message translates to:
  /// **'vorher {value}'**
  String comparePrev(String value);

  /// Tage in der Folgentabelle
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Tag} other{{n} Tage}}'**
  String consequenceDays(int n);

  /// Zeile der Folgentabelle
  ///
  /// In de, this message translates to:
  /// **'Form'**
  String get consequenceForm;

  /// ACWR verschwindet
  ///
  /// In de, this message translates to:
  /// **'entfällt'**
  String get consequenceGone;

  /// Zeile der Folgentabelle: ACWR
  ///
  /// In de, this message translates to:
  /// **'Belastung'**
  String get consequenceLoad;

  /// ACWR erscheint
  ///
  /// In de, this message translates to:
  /// **'erscheint'**
  String get consequenceNew;

  /// Folgentabelle ohne Änderung
  ///
  /// In de, this message translates to:
  /// **'An deiner Auswertung ändert das nichts.'**
  String get consequenceNone;

  /// Zeile der Folgentabelle: Tage seit der letzten Einheit
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get consequencePause;

  /// Vorher-Nachher in der Folgentabelle
  ///
  /// In de, this message translates to:
  /// **'{from} → {to}'**
  String consequenceStep(String from, String to);

  /// Vorlesetext einer Folgenzeile
  ///
  /// In de, this message translates to:
  /// **'{label}: von {from} auf {to}'**
  String consequenceStepA11y(String label, String from, String to);

  /// Überschrift der Folgentabelle
  ///
  /// In de, this message translates to:
  /// **'Was sich ändert'**
  String get consequenceTitle;

  /// aus dashboard.activityCalendar.durationUnit
  ///
  /// In de, this message translates to:
  /// **'Bewegungsstunden'**
  String get dashboardActivityCalendarDurationUnit;

  /// aus dashboard.activityCalendar.emptyState
  ///
  /// In de, this message translates to:
  /// **'Noch keine Sessions in diesem Zeitraum'**
  String get dashboardActivityCalendarEmptyState;

  /// aus dashboard.activityCalendar.more
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get dashboardActivityCalendarMore;

  /// aus dashboard.activityCalendar.thisMonth
  ///
  /// In de, this message translates to:
  /// **'Diesen Monat'**
  String get dashboardActivityCalendarThisMonth;

  /// aus dashboard.addWorkout.title
  ///
  /// In de, this message translates to:
  /// **'Workout hinzufügen'**
  String get dashboardAddWorkoutTitle;

  /// aus dashboard.allSessions.earlier
  ///
  /// In de, this message translates to:
  /// **'Früher'**
  String get dashboardAllSessionsEarlier;

  /// aus dashboard.allSessions.empty
  ///
  /// In de, this message translates to:
  /// **'Noch keine Sessions vorhanden'**
  String get dashboardAllSessionsEmpty;

  /// aus dashboard.allSessions.title
  ///
  /// In de, this message translates to:
  /// **'Alle Sessions'**
  String get dashboardAllSessionsTitle;

  /// aus dashboard.allSessions.today
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get dashboardAllSessionsToday;

  /// aus dashboard.allSessions.yesterday
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get dashboardAllSessionsYesterday;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Profil von {name}'**
  String dashboardAvatarA11y(String name);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{n} Blocks'**
  String dashboardBlocks(int n);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'ATEM HYBRID'**
  String get dashboardBrand;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'System aktiv'**
  String get dashboardBrandA11y;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{n} Min Breathwork'**
  String dashboardBreathwork(int n);

  /// aus dashboard.calendar.addTraining
  ///
  /// In de, this message translates to:
  /// **'Training hinzufügen'**
  String get dashboardCalendarAddTraining;

  /// aus dashboard.calendar.nextMonth
  ///
  /// In de, this message translates to:
  /// **'Nächster Monat'**
  String get dashboardCalendarNextMonth;

  /// aus dashboard.calendar.prevMonth
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Monat'**
  String get dashboardCalendarPrevMonth;

  /// aus dashboard.calendar.tabActivity
  ///
  /// In de, this message translates to:
  /// **'Aktivität'**
  String get dashboardCalendarTabActivity;

  /// aus dashboard.calendar.tabPlan
  ///
  /// In de, this message translates to:
  /// **'Planen'**
  String get dashboardCalendarTabPlan;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Wochenverlauf: Load, Strain, Recovery, Montag bis Sonntag'**
  String get dashboardChartA11y;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'PERFORMANCE · 7 TAGE'**
  String get dashboardChartSection;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{day} · LOAD {load}'**
  String dashboardChartToday(String day, int load);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{n} Min'**
  String dashboardDurationMinutes(int n);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Guten Tag, {name}'**
  String dashboardGreetingDay(String name);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Guten Abend, {name}'**
  String dashboardGreetingEvening(String name);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Guten Morgen, {name}'**
  String dashboardGreetingMorning(String name);

  /// aus dashboard.hybridBalance.aria
  ///
  /// In de, this message translates to:
  /// **'Kraft {strength} Prozent, Cardio {cardio} Prozent'**
  String dashboardHybridBalanceAria(String strength, String cardio);

  /// aus dashboard.hybridBalance.description
  ///
  /// In de, this message translates to:
  /// **'Zeigt die Zeitverteilung zwischen Kraft und Cardio.'**
  String get dashboardHybridBalanceDescription;

  /// aus dashboard.hybridBalance.subtitle
  ///
  /// In de, this message translates to:
  /// **'Letzte {days} Tage'**
  String dashboardHybridBalanceSubtitle(int days);

  /// aus dashboard.hybridBalance.title
  ///
  /// In de, this message translates to:
  /// **'Hybrid Balance'**
  String get dashboardHybridBalanceTitle;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'LIVE'**
  String get dashboardLive;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Live HRV {hrv} ms · {n} Min Breathwork'**
  String dashboardLiveHrv(int hrv, int n);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Dashboard wird geladen'**
  String get dashboardLoadingA11y;

  /// aus dashboard.logWorkout.log
  ///
  /// In de, this message translates to:
  /// **'Workout loggen'**
  String get dashboardLogWorkoutLog;

  /// aus dashboard.logWorkout.logDesc
  ///
  /// In de, this message translates to:
  /// **'Erfasse ein abgeschlossenes Training'**
  String get dashboardLogWorkoutLogDesc;

  /// aus dashboard.logWorkout.plan
  ///
  /// In de, this message translates to:
  /// **'Workout planen'**
  String get dashboardLogWorkoutPlan;

  /// aus dashboard.logWorkout.planDesc
  ///
  /// In de, this message translates to:
  /// **'Plane ein Training im Kalender'**
  String get dashboardLogWorkoutPlanDesc;

  /// aus dashboard.logWorkout.start
  ///
  /// In de, this message translates to:
  /// **'Workout starten'**
  String get dashboardLogWorkoutStart;

  /// aus dashboard.logWorkout.startDesc
  ///
  /// In de, this message translates to:
  /// **'Starte ein Training aus deinen Plänen'**
  String get dashboardLogWorkoutStartDesc;

  /// aus dashboard.logWorkout.subtitle
  ///
  /// In de, this message translates to:
  /// **'Logge, starte oder plane ein Workout'**
  String get dashboardLogWorkoutSubtitle;

  /// aus dashboard.logWorkout.title
  ///
  /// In de, this message translates to:
  /// **'Workout erfassen'**
  String get dashboardLogWorkoutTitle;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{name}, Tab {n} von {total}'**
  String dashboardNavA11y(String name, int n, int total);

  /// Leistenbeschriftung. „Analyse" versprach nur die Auswertung — der Tab trägt aber den ganzen Verlauf, von dem sie ein Teil ist.
  ///
  /// In de, this message translates to:
  /// **'VERLAUF'**
  String get dashboardNavAnalytics;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'HOME'**
  String get dashboardNavHome;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'RECOVERY'**
  String get dashboardNavRecovery;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'WORKOUTS'**
  String get dashboardNavWorkouts;

  /// Steht in einer Kachel, für die es noch keine Datenquelle gibt
  ///
  /// In de, this message translates to:
  /// **'Noch keine Daten'**
  String get dashboardNoDataYet;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Daten nicht verfügbar'**
  String get dashboardNotAvailable;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{n} ungelesene Benachrichtigungen'**
  String dashboardNotificationsA11y(int n);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Woche {week} von {total}, Phase {phase}'**
  String dashboardPhaseA11y(int week, int total, String phase);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Woche {week} von {total} · {phase}'**
  String dashboardPhaseWeek(int week, int total, String phase);

  /// aus dashboard.planCalendar.title
  ///
  /// In de, this message translates to:
  /// **'Planungskalender'**
  String get dashboardPlanCalendarTitle;

  /// aus dashboard.primary.helper
  ///
  /// In de, this message translates to:
  /// **'Starte oder setze dein aktuelles Training fort.'**
  String get dashboardPrimaryHelper;

  /// aus dashboard.primary.resume
  ///
  /// In de, this message translates to:
  /// **'Workout fortsetzen'**
  String get dashboardPrimaryResume;

  /// aus dashboard.primary.start
  ///
  /// In de, this message translates to:
  /// **'Workout starten'**
  String get dashboardPrimaryStart;

  /// aus dashboard.primary.subtitleActive
  ///
  /// In de, this message translates to:
  /// **'Ein Workout ist aktiv.'**
  String get dashboardPrimarySubtitleActive;

  /// aus dashboard.primary.subtitleInactive
  ///
  /// In de, this message translates to:
  /// **'Wähle Kraft, Cardio oder Recovery.'**
  String get dashboardPrimarySubtitleInactive;

  /// aus dashboard.primary.title
  ///
  /// In de, this message translates to:
  /// **'Workout'**
  String get dashboardPrimaryTitle;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Ernährung, Protein {value} von {goal} Gramm'**
  String dashboardProteinA11y(int value, int goal);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **' / {goal}g Ziel'**
  String dashboardProteinGoal(int goal);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Protein {value}g'**
  String dashboardProteinOf(int value);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Nutrition & Fuel'**
  String get dashboardQuickNutrition;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Periodisierung'**
  String get dashboardQuickPeriod;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Recovery Scan'**
  String get dashboardQuickRecovery;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'{headline} · {sets} Sets'**
  String dashboardQuickSets(String headline, int sets);

  /// Sätze der letzten Einheit, ohne Planname
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Sätze erfasst} one{1 Satz zuletzt} other{{count} Sätze zuletzt}}'**
  String dashboardQuickSetsPlain(int count);

  /// Planname und Sätze der letzten Einheit
  ///
  /// In de, this message translates to:
  /// **'{plan} · {count, plural, one{1 Satz} other{{count} Sätze}}'**
  String dashboardQuickSetsPlan(String plan, int count);

  /// aus dashboard.quickStats.movementMinutes
  ///
  /// In de, this message translates to:
  /// **'Bewegungsmin.'**
  String get dashboardQuickStatsMovementMinutes;

  /// aus dashboard.quickStats.sessions
  ///
  /// In de, this message translates to:
  /// **'Sessions'**
  String get dashboardQuickStatsSessions;

  /// aus dashboard.quickStats.thisWeek
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get dashboardQuickStatsThisWeek;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Workout Log'**
  String get dashboardQuickWorkout;

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

  /// aus dashboard.recent.description
  ///
  /// In de, this message translates to:
  /// **'Die letzten Sessions in chronologischer Reihenfolge.'**
  String get dashboardRecentDescription;

  /// aus dashboard.recent.empty
  ///
  /// In de, this message translates to:
  /// **'Noch keine Sessions'**
  String get dashboardRecentEmpty;

  /// aus dashboard.recent.title
  ///
  /// In de, this message translates to:
  /// **'Letzte Sessions'**
  String get dashboardRecentTitle;

  /// aus dashboard.recent.viewAll
  ///
  /// In de, this message translates to:
  /// **'Alle anzeigen'**
  String get dashboardRecentViewAll;

  /// aus dashboard.scheduled.title
  ///
  /// In de, this message translates to:
  /// **'Geplant für heute'**
  String get dashboardScheduledTitle;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'LOAD'**
  String get dashboardSeriesLoad;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'RECOVERY'**
  String get dashboardSeriesRecovery;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'STRAIN'**
  String get dashboardSeriesStrain;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Für heute ist nichts geplant'**
  String get dashboardSessionNone;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Plane eine Einheit oder logge ein freies Workout.'**
  String get dashboardSessionNoneHint;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'SESSION LÄUFT · {time}'**
  String dashboardSessionRunning(String time);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Session läuft, {time}, tippen zum Stoppen'**
  String dashboardSessionRunningA11y(String time);

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'HEUTIGE SESSION'**
  String get dashboardSessionSection;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'SESSION STARTEN'**
  String get dashboardSessionStart;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Session starten'**
  String get dashboardSessionStartA11y;

  /// aus dashboard.startWorkout.newWorkout
  ///
  /// In de, this message translates to:
  /// **'Neues Training'**
  String get dashboardStartWorkoutNewWorkout;

  /// aus dashboard.startWorkout.newWorkoutDesc
  ///
  /// In de, this message translates to:
  /// **'Starte ein leeres Workout und füge Übungen hinzu'**
  String get dashboardStartWorkoutNewWorkoutDesc;

  /// aus dashboard.startWorkout.selectPlan
  ///
  /// In de, this message translates to:
  /// **'Plan auswählen'**
  String get dashboardStartWorkoutSelectPlan;

  /// aus dashboard.startWorkout.selectPlanDesc
  ///
  /// In de, this message translates to:
  /// **'Starte ein Training aus deinen Plänen'**
  String get dashboardStartWorkoutSelectPlanDesc;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'HRV'**
  String get dashboardStatHrv;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'RUHE-HF'**
  String get dashboardStatRhr;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'SCHLAF'**
  String get dashboardStatSleep;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Optimales System-Level erreicht'**
  String get dashboardSubtitle;

  /// aus dashboard.today
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get dashboardToday;

  /// aus dashboard.trainingTypes.bodyweight
  ///
  /// In de, this message translates to:
  /// **'Bodyweight'**
  String get dashboardTrainingTypesBodyweight;

  /// aus dashboard.trainingTypes.cardio
  ///
  /// In de, this message translates to:
  /// **'Cardio'**
  String get dashboardTrainingTypesCardio;

  /// aus dashboard.trainingTypes.recovery
  ///
  /// In de, this message translates to:
  /// **'Recovery'**
  String get dashboardTrainingTypesRecovery;

  /// aus dashboard.trainingTypes.strength
  ///
  /// In de, this message translates to:
  /// **'Krafttraining'**
  String get dashboardTrainingTypesStrength;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'MO,DI,MI,DO,FR,SA,SO'**
  String get dashboardWeekdays;

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

  /// Belastungsverhältnis mit Zone
  ///
  /// In de, this message translates to:
  /// **'ACWR {v} · {zone}'**
  String detailAcwrZone(String v, String zone);

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
  /// **'Dauer'**
  String get detailDuration;

  /// Kennzahl im Detail
  ///
  /// In de, this message translates to:
  /// **'Last'**
  String get detailLoad;

  /// detail.note.add (Board 06)
  ///
  /// In de, this message translates to:
  /// **'Notiz hinzufügen'**
  String get detailNoteAdd;

  /// Kennzahl im Detail
  ///
  /// In de, this message translates to:
  /// **'Pace /km'**
  String get detailPace;

  /// Hinweis bei Regeneration
  ///
  /// In de, this message translates to:
  /// **'Recovery hält die Kette, treibt aber die Lastentwicklung nicht.'**
  String get detailRecoveryBody;

  /// Hinweis bei Regeneration
  ///
  /// In de, this message translates to:
  /// **'Zählt für die Konstanz'**
  String get detailRecoveryTitle;

  /// detail.saveAsPlan (Board 06)
  ///
  /// In de, this message translates to:
  /// **'Als Plan speichern'**
  String get detailSaveAsPlan;

  /// Umfang der Einheit
  ///
  /// In de, this message translates to:
  /// **'{e} Übungen · {s} Sätze'**
  String detailSetsCount(int e, int s);

  /// Erklärt, warum eine Einheit ohne Sätze trotzdem zählt
  ///
  /// In de, this message translates to:
  /// **'Diese Einheit wurde als Dauer erfasst. Last und Konstanz zählen trotzdem, Volumen bleibt leer.'**
  String get detailSetsMissingBody;

  /// 16 der 63 Krafteinheiten im Bestand tragen keine Übungen
  ///
  /// In de, this message translates to:
  /// **'Keine Sätze aufgezeichnet'**
  String get detailSetsMissingTitle;

  /// Kennzahl im Detail
  ///
  /// In de, this message translates to:
  /// **'Volumen'**
  String get detailVolume;

  /// dialog.delete.title (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Verlauf löschen?'**
  String get dialogDeleteTitle;

  /// dialog.end.confirm (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Beenden & speichern'**
  String get dialogEndConfirm;

  /// dialog.end.title (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Workout beenden?'**
  String get dialogEndTitle;

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

  /// empty.today.body (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Ruhetag — oder Platz für eine freie Session.'**
  String get emptyTodayBody;

  /// empty.today.cta (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Session planen'**
  String get emptyTodayCta;

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

  /// error.back (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Dashboard'**
  String get errorBack;

  /// error.load.body (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Der Plan konnte nicht abgerufen werden. Deine bisherigen Daten sind sicher.'**
  String get errorLoadBody;

  /// error.load.title (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Workout nicht ladbar'**
  String get errorLoadTitle;

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

  /// aus errors.deleteFailed
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen'**
  String get errorsDeleteFailed;

  /// aus errors.exerciseNameRequired
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen für die Übung ein!'**
  String get errorsExerciseNameRequired;

  /// aus errors.exercisesLoading
  ///
  /// In de, this message translates to:
  /// **'Übungen werden noch geladen. Bitte versuche es gleich erneut.'**
  String get errorsExercisesLoading;

  /// Runner, Modul 2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Laden fehlgeschlagen. Bitte erneut versuchen.'**
  String get errorsLoadFailed;

  /// aus errors.muscleGroupsRequired
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle mindestens eine Muskelgruppe!'**
  String get errorsMuscleGroupsRequired;

  /// aus errors.planExercisesRequired
  ///
  /// In de, this message translates to:
  /// **'Bitte füge mindestens eine Übung hinzu!'**
  String get errorsPlanExercisesRequired;

  /// aus errors.planNameRequired
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen für den Plan ein!'**
  String get errorsPlanNameRequired;

  /// aus errors.planNotFound
  ///
  /// In de, this message translates to:
  /// **'Plan nicht gefunden'**
  String get errorsPlanNotFound;

  /// aus errors.saveFailed
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern.'**
  String get errorsSaveFailed;

  /// aus errors.sessionNotFound
  ///
  /// In de, this message translates to:
  /// **'Session nicht gefunden'**
  String get errorsSessionNotFound;

  /// aus errors.startUnavailable
  ///
  /// In de, this message translates to:
  /// **'Start-Auswahl ist nicht verfügbar.'**
  String get errorsStartUnavailable;

  /// aus errors.workoutNotFound
  ///
  /// In de, this message translates to:
  /// **'Workout nicht gefunden'**
  String get errorsWorkoutNotFound;

  /// aus errors.workoutStartFailed
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Starten des Workouts'**
  String get errorsWorkoutStartFailed;

  /// Hinweis im Formular der eigenen Fassung
  ///
  /// In de, this message translates to:
  /// **'Die kuratierte Übung bleibt bestehen. Deine Fassung steht daneben.'**
  String get exerciseCopyNotice;

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
  /// **'Die Übung steckt in {p, plural, one {# Plan} other {# Plänen}} und {s, plural, one {# Einheit} other {# Einheiten}}.'**
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

  /// Fehlermeldung beim Speichern
  ///
  /// In de, this message translates to:
  /// **'Übung nicht gespeichert'**
  String get exerciseFormSaveError;

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

  /// exercises.block.all
  ///
  /// In de, this message translates to:
  /// **'Alle ansehen'**
  String get exercisesBlockAll;

  /// exercises.block.byMuscle
  ///
  /// In de, this message translates to:
  /// **'Nach Muskel'**
  String get exercisesBlockByMuscle;

  /// exercises.block.search
  ///
  /// In de, this message translates to:
  /// **'Name oder Muskel'**
  String get exercisesBlockSearch;

  /// exercises.block.title
  ///
  /// In de, this message translates to:
  /// **'Übungen · {n}'**
  String exercisesBlockTitle(int n);

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

  /// Suche ohne Treffer, Text
  ///
  /// In de, this message translates to:
  /// **'Keine Übung passt zu „{q}“ — auch nicht auf Englisch.'**
  String exercisesEmptyBody(String q);

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

  /// Suche ohne Treffer
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden'**
  String get exercisesEmptyTitle;

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

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Als CSV erstellen'**
  String get exportCreateCsv;

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Als JSON erstellen'**
  String get exportCreateJson;

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

  /// export.offline
  ///
  /// In de, this message translates to:
  /// **'Offline nicht möglich'**
  String get exportOffline;

  /// export.progress
  ///
  /// In de, this message translates to:
  /// **'Einheiten {a}/{b} · Pläne {c}/{d} · Übungen {e}/{f}'**
  String exportProgress(int a, int b, int c, int d, int e, int f);

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
  /// **'Termine'**
  String get exportRowSchedule;

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

  /// Vorlesetext des Dialogschleiers
  ///
  /// In de, this message translates to:
  /// **'Änderungen verwerfen'**
  String get formDiscardBarrier;

  /// Dialogtext
  ///
  /// In de, this message translates to:
  /// **'Was du eingegeben hast, geht verloren.'**
  String get formDiscardBody;

  /// Dialogaktion
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get formDiscardConfirm;

  /// Dialogaktion, Abbruch
  ///
  /// In de, this message translates to:
  /// **'Weiter bearbeiten'**
  String get formDiscardKeep;

  /// Dialog beim Verlassen mit ungespeicherten Änderungen
  ///
  /// In de, this message translates to:
  /// **'Änderungen verwerfen?'**
  String get formDiscardTitle;

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

  /// form.note
  ///
  /// In de, this message translates to:
  /// **'Notiz · optional'**
  String get formNote;

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

  /// aus format.distanceKm
  ///
  /// In de, this message translates to:
  /// **'{distance} km'**
  String formatDistanceKm(num distance);

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

  /// aus format.duration.zero
  ///
  /// In de, this message translates to:
  /// **'0 min'**
  String get formatDurationZero;

  /// aus format.pace.na
  ///
  /// In de, this message translates to:
  /// **'-'**
  String get formatPaceNa;

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

  /// haptics.unavailable
  ///
  /// In de, this message translates to:
  /// **'Dein Gerät hat keinen Vibrationsmotor.'**
  String get hapticsUnavailable;

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

  /// Leerzustand des Verlaufs
  ///
  /// In de, this message translates to:
  /// **'Deine erste Einheit steht hier, sobald du sie beendet hast.'**
  String get historyEmptyBody;

  /// Leerzustand des Verlaufs
  ///
  /// In de, this message translates to:
  /// **'Noch nichts aufgezeichnet'**
  String get historyEmptyTitle;

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

  /// Beschriftung des Form-Werts
  ///
  /// In de, this message translates to:
  /// **'Form'**
  String get historyFormLabel;

  /// Form-Wert mit Maximum
  ///
  /// In de, this message translates to:
  /// **'{v}/100'**
  String historyFormOf(int v);

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
  /// **'{n, plural, one {# Tag} other {# Tage}} ohne Training'**
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

  /// Richtung der Formkurve
  ///
  /// In de, this message translates to:
  /// **'fallend'**
  String get historyTrendFalling;

  /// Richtung der Formkurve
  ///
  /// In de, this message translates to:
  /// **'steigend'**
  String get historyTrendRising;

  /// Richtung der Formkurve
  ///
  /// In de, this message translates to:
  /// **'stabil'**
  String get historyTrendStable;

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

  /// hybrid.week.thin
  ///
  /// In de, this message translates to:
  /// **'Bereitschaft und Formwert ab {min} Einheiten.'**
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
  /// **'Weder Puls noch RPE erfasst. Beurteilt wird über das Tempo gegen {n, plural, one{1 Lauf} other{# Läufe}}.'**
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
  /// **'{n, plural, one{Seit 1 Tag keine Einheit} other{Seit # Tagen keine Einheit}}'**
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

  /// legal.external
  ///
  /// In de, this message translates to:
  /// **'Extern öffnen'**
  String get legalExternal;

  /// legal.imprint
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get legalImprint;

  /// legal.imprint.body
  ///
  /// In de, this message translates to:
  /// **'Privates Projekt einer natürlichen Person. Angaben nach § 5 TMG: {betreiber}'**
  String legalImprintBody(String betreiber);

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
  /// **'{n, plural, one {# Tag} other {# Tage}} ohne Training'**
  String listGap(int n);

  /// Zusatz am längsten Lückenstreifen
  ///
  /// In de, this message translates to:
  /// **'längste Pause im Verlauf'**
  String get listGapLongest;

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

  /// loading.done (Board 02)
  ///
  /// In de, this message translates to:
  /// **'{sektion} geladen'**
  String loadingDone(String sektion);

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

  /// aus nav.calendar
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get navCalendar;

  /// aus nav.dashboard
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get navDashboard;

  /// aus nav.exercises
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get navExercises;

  /// aus nav.plans
  ///
  /// In de, this message translates to:
  /// **'Pläne'**
  String get navPlans;

  /// aus nav.profile
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// aus nav.progress
  ///
  /// In de, this message translates to:
  /// **'Fortschritt'**
  String get navProgress;

  /// aus nav.training
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get navTraining;

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

  /// onboarding.repeat.action
  ///
  /// In de, this message translates to:
  /// **'Ansehen'**
  String get onboardingRepeatAction;

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

  /// plan.broken.notice
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one {# Eintrag zeigt} other {# Einträge zeigen}} ins Leere.'**
  String planBrokenNotice(int n);

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

  /// Vorlesetext des Dialogschleiers
  ///
  /// In de, this message translates to:
  /// **'Plan löschen'**
  String get planDeleteBarrier;

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

  /// Aktion unter der Übungsliste
  ///
  /// In de, this message translates to:
  /// **'Übung hinzufügen'**
  String get planFormAdd;

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

  /// Text einer Lücke im Plan
  ///
  /// In de, this message translates to:
  /// **'Die Zielwerte bleiben stehen. Ersetze sie durch eine andere Übung.'**
  String get planFormGapBody;

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

  /// Fehler an der Übungsliste
  ///
  /// In de, this message translates to:
  /// **'Ein Plan braucht mindestens eine Übung.'**
  String get planFormItemsFault;

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

  /// Fehler am Namensfeld
  ///
  /// In de, this message translates to:
  /// **'Ein Plan braucht einen Namen.'**
  String get planFormNameFault;

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

  /// Titel des Auswahlblatts
  ///
  /// In de, this message translates to:
  /// **'Übung wählen'**
  String get planFormPickTitle;

  /// Aktion an einem Planeintrag
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get planFormRemove;

  /// Vorlesetext der Entfernen-Aktion
  ///
  /// In de, this message translates to:
  /// **'{name} aus dem Plan entfernen'**
  String planFormRemoveA11y(String name);

  /// Erste Aktion an einer Lücke
  ///
  /// In de, this message translates to:
  /// **'Ersetzen'**
  String get planFormReplace;

  /// Zielwert
  ///
  /// In de, this message translates to:
  /// **'Wdh.'**
  String get planFormReps;

  /// Platzhalter im Wiederholungsfeld — Bereiche sind erlaubt
  ///
  /// In de, this message translates to:
  /// **'8-12'**
  String get planFormRepsHint;

  /// Zielwert in Sekunden
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get planFormRest;

  /// Fehlermeldung
  ///
  /// In de, this message translates to:
  /// **'Plan nicht gespeichert'**
  String get planFormSaveError;

  /// Rückmeldung nach dem Speichern
  ///
  /// In de, this message translates to:
  /// **'Plan gespeichert'**
  String get planFormSaved;

  /// Zielwert
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get planFormSets;

  /// Steht statt des Namens, wenn die Übung gelöscht wurde
  ///
  /// In de, this message translates to:
  /// **'Nicht mehr vorhanden'**
  String get planItemMissing;

  /// Zweite Zeile einer Planzeile
  ///
  /// In de, this message translates to:
  /// **'{n} Übungen · {type}'**
  String planMeta(int n, String type);

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

  /// Kachelüberschrift
  ///
  /// In de, this message translates to:
  /// **'Form'**
  String get quickForm;

  /// Richtung des Formtrends
  ///
  /// In de, this message translates to:
  /// **'fallend'**
  String get quickFormFalling;

  /// Richtung des Formtrends
  ///
  /// In de, this message translates to:
  /// **'gleichbleibend'**
  String get quickFormFlat;

  /// Richtung des Formtrends
  ///
  /// In de, this message translates to:
  /// **'steigend'**
  String get quickFormRising;

  /// Formwert in der Kachel
  ///
  /// In de, this message translates to:
  /// **'{v} von 100'**
  String quickFormValue(int v);

  /// Kachelüberschrift
  ///
  /// In de, this message translates to:
  /// **'Letzte Einheit'**
  String get quickLast;

  /// Abstand zur letzten Einheit
  ///
  /// In de, this message translates to:
  /// **'vor {n, plural, one {einem Tag} other {{n} Tagen}}'**
  String quickLastDays(int n);

  /// Die letzte Einheit war heute
  ///
  /// In de, this message translates to:
  /// **'heute'**
  String get quickLastToday;

  /// Kachelüberschrift
  ///
  /// In de, this message translates to:
  /// **'Nächster Termin'**
  String get quickNext;

  /// Terminabstand
  ///
  /// In de, this message translates to:
  /// **'in {n} Tagen'**
  String quickNextDays(int n);

  /// Kein Termin in Sicht
  ///
  /// In de, this message translates to:
  /// **'Nichts geplant'**
  String get quickNextNone;

  /// Terminabstand
  ///
  /// In de, this message translates to:
  /// **'heute'**
  String get quickNextToday;

  /// Terminabstand
  ///
  /// In de, this message translates to:
  /// **'morgen'**
  String get quickNextTomorrow;

  /// Leerer Bestand
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einheit'**
  String get quickNoSessions;

  /// ratio.basis
  ///
  /// In de, this message translates to:
  /// **'Anteil an {min} Trainingsminuten · {n, plural, one{1 Einheit} other{# Einheiten}}'**
  String ratioBasis(int min, int n);

  /// ratio.noshift
  ///
  /// In de, this message translates to:
  /// **'kein 4-Wochen-Schnitt'**
  String get ratioNoshift;

  /// ratio.shift
  ///
  /// In de, this message translates to:
  /// **'{value} pp gegen 4-Wochen-Schnitt'**
  String ratioShift(String value);

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

  /// ratio.single.body
  ///
  /// In de, this message translates to:
  /// **'Ein Verhältnis braucht beide Spuren. Ab der ersten Ausdauereinheit steht es hier.'**
  String get ratioSingleBody;

  /// ratio.single.title
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausdauer'**
  String get ratioSingleTitle;

  /// ratio.title
  ///
  /// In de, this message translates to:
  /// **'Verhältnis'**
  String get ratioTitle;

  /// recovery.add
  ///
  /// In de, this message translates to:
  /// **'Erfassen'**
  String get recoveryAdd;

  /// recovery.gap
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{Seit 1 Tag keine Regeneration} other{Seit # Tagen keine Regeneration}}'**
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
  /// **'Vorher {date} · {n, plural, one {+# Tag} other {+# Tage}}'**
  String sessionDatePrevious(int n, String date);

  /// Vorlesetext des Dialogschleiers
  ///
  /// In de, this message translates to:
  /// **'Einheit löschen'**
  String get sessionDeleteBarrier;

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

  /// Bestätigung
  ///
  /// In de, this message translates to:
  /// **'Einheit löschen?'**
  String get sessionDeleteTitle;

  /// session.delete.window
  ///
  /// In de, this message translates to:
  /// **'30 Sekunden lang kannst du das rückgängig machen.'**
  String get sessionDeleteWindow;

  /// Widerrufshinweis, Text
  ///
  /// In de, this message translates to:
  /// **'Du kannst das {n} Sekunden lang zurücknehmen.'**
  String sessionDeletedBody(int n);

  /// session.deleted.snack
  ///
  /// In de, this message translates to:
  /// **'Einheit gelöscht · Form {alt} → {neu}'**
  String sessionDeletedSnack(String alt, String neu);

  /// Widerrufshinweis nach dem Löschen
  ///
  /// In de, this message translates to:
  /// **'{name} gelöscht'**
  String sessionDeletedTitle(String name);

  /// Aktion im Widerrufshinweis
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get sessionDeletedUndo;

  /// Feldbeschriftung
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get sessionEditDate;

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

  /// Rückmeldung
  ///
  /// In de, this message translates to:
  /// **'Einheit gespeichert'**
  String get sessionEditSaved;

  /// Abschnittslabel über den Sätzen
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get sessionEditSets;

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

  /// session.impact.form
  ///
  /// In de, this message translates to:
  /// **'Form heute'**
  String get sessionImpactForm;

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

  /// Zeile im Abschnitt ueber die App
  ///
  /// In de, this message translates to:
  /// **'Privates Projekt, keine kommerzielle Nutzung.'**
  String get settingsAboutPrivate;

  /// Die Tatsache an der Stelle, an der sonst ein Schalter stuende
  ///
  /// In de, this message translates to:
  /// **'Nur dunkel — ATEM ist für dunkle Umgebungen gebaut.'**
  String get settingsAboutTheme;

  /// Zeile im Abschnitt ueber die App
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String settingsAboutVersion(String version);

  /// Feldbeschriftung
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht'**
  String get settingsBodyWeight;

  /// Fehler am Gewichtsfeld
  ///
  /// In de, this message translates to:
  /// **'Zwischen {min} und {max} kg.'**
  String settingsBodyWeightFault(int min, int max);

  /// Hilfetext unter dem Gewichtsfeld
  ///
  /// In de, this message translates to:
  /// **'Rechnet jede Körpergewichtsübung neu — auch die von früher.'**
  String get settingsBodyWeightHint;

  /// Zustand ohne Körpergewicht
  ///
  /// In de, this message translates to:
  /// **'Noch nicht hinterlegt'**
  String get settingsBodyWeightNone;

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get settingsDelete;

  /// Vorlesetext des Dialogschleiers
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get settingsDeleteBarrier;

  /// Hilfetext am Bestätigungsfeld
  ///
  /// In de, this message translates to:
  /// **'Genau so, in Großbuchstaben.'**
  String get settingsDeleteConfirmHint;

  /// Das Wort, das getippt werden muss, in Grossbuchstaben
  ///
  /// In de, this message translates to:
  /// **'LÖSCHEN'**
  String get settingsDeleteConfirmWord;

  /// Was konkret verschwindet
  ///
  /// In de, this message translates to:
  /// **'{sessions} Einheiten · {plans} Pläne · {exercises} eigene Übungen'**
  String settingsDeleteCounts(int sessions, int plans, int exercises);

  /// Zweiter Ausgang der ersten Stufe
  ///
  /// In de, this message translates to:
  /// **'Daten vorher sichern'**
  String get settingsDeleteExport;

  /// Fehlermeldung
  ///
  /// In de, this message translates to:
  /// **'Löschen nicht abgeschlossen'**
  String get settingsDeleteFailed;

  /// Fehlermeldung, Text
  ///
  /// In de, this message translates to:
  /// **'Ein Teil deiner Daten ist noch da. Versuche es erneut, solange du angemeldet bist.'**
  String get settingsDeleteFailedBody;

  /// Gesperrt ohne Netz, Text
  ///
  /// In de, this message translates to:
  /// **'Löschen greift über mehrere Sammlungen. Ohne Verbindung bliebe die Hälfte stehen.'**
  String get settingsDeleteOfflineBody;

  /// Gesperrt ohne Netz
  ///
  /// In de, this message translates to:
  /// **'Ohne Verbindung nicht möglich'**
  String get settingsDeleteOfflineTitle;

  /// Ladezustand
  ///
  /// In de, this message translates to:
  /// **'Wird gelöscht …'**
  String get settingsDeleteRunning;

  /// Erste Stufe, Text
  ///
  /// In de, this message translates to:
  /// **'Einheiten, Pläne, eigene Übungen, Termine und dein Profil werden entfernt. Es gibt kein Zurück und kein Zeitfenster.'**
  String get settingsDeleteStep1Body;

  /// Erste Stufe
  ///
  /// In de, this message translates to:
  /// **'Konto und alle Daten löschen?'**
  String get settingsDeleteStep1Title;

  /// Zweite Stufe, Text
  ///
  /// In de, this message translates to:
  /// **'Tippe {word}, um zu bestätigen.'**
  String settingsDeleteStep2Body(String word);

  /// Zweite Stufe
  ///
  /// In de, this message translates to:
  /// **'Wirklich endgültig löschen?'**
  String get settingsDeleteStep2Title;

  /// Erklärung
  ///
  /// In de, this message translates to:
  /// **'ATEM ist geschlossen; die Freischaltung steht in einer Liste, die zum Programm gehört und nicht zum Konto. Meldest du dich erneut an, bist du wieder dabei — mit leerem Bestand.'**
  String get settingsDeletedAccessBody;

  /// Der erklärungsbedürftige Teil
  ///
  /// In de, this message translates to:
  /// **'Dein Zugang bleibt bestehen'**
  String get settingsDeletedAccessTitle;

  /// Abschlussbildschirm, Text
  ///
  /// In de, this message translates to:
  /// **'Deine Trainingsdaten sind entfernt.'**
  String get settingsDeletedBody;

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get settingsDeletedClose;

  /// Abschlussbildschirm
  ///
  /// In de, this message translates to:
  /// **'Konto gelöscht'**
  String get settingsDeletedTitle;

  /// settings.entry.a11y
  ///
  /// In de, this message translates to:
  /// **'Profil und Einstellungen'**
  String get settingsEntryA11y;

  /// Erklärung der beiden Formate
  ///
  /// In de, this message translates to:
  /// **'JSON enthält alles. CSV enthält deine Einheiten als Tabelle, eine Zeile je Satz.'**
  String get settingsExportBody;

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Einheiten als CSV'**
  String get settingsExportCsv;

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

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Alles als JSON'**
  String get settingsExportJson;

  /// Ladezustand
  ///
  /// In de, this message translates to:
  /// **'Wird gesammelt …'**
  String get settingsExportRunning;

  /// Titel
  ///
  /// In de, this message translates to:
  /// **'Daten sichern'**
  String get settingsExportTitle;

  /// Erklaerung am Profilkopf statt eines defekt wirkenden Formulars
  ///
  /// In de, this message translates to:
  /// **'Name und Bild kommen von deinem Google-Konto.'**
  String get settingsFromGoogle;

  /// Schalterbeschriftung
  ///
  /// In de, this message translates to:
  /// **'Vibration'**
  String get settingsHaptics;

  /// Hilfetext
  ///
  /// In de, this message translates to:
  /// **'Kurze Rückmeldung beim Antippen und am Pausenende.'**
  String get settingsHapticsHint;

  /// Vorlesetext, Zustand
  ///
  /// In de, this message translates to:
  /// **'Vibration aus'**
  String get settingsHapticsOff;

  /// Vorlesetext, Zustand
  ///
  /// In de, this message translates to:
  /// **'Vibration an'**
  String get settingsHapticsOn;

  /// Rechtlicher Weg
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get settingsImprint;

  /// Feldbeschriftung
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguage;

  /// Sprache
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get settingsLanguageEnglish;

  /// Sprache
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get settingsLanguageGerman;

  /// Hilfetext unter der Sprachwahl
  ///
  /// In de, this message translates to:
  /// **'Wirkt sofort.'**
  String get settingsLanguageHint;

  /// Fehlermeldung
  ///
  /// In de, this message translates to:
  /// **'Seite lässt sich nicht öffnen'**
  String get settingsLinkFailed;

  /// Vorlesetext des Profilbilds im Dashboard-Kopf
  ///
  /// In de, this message translates to:
  /// **'Einstellungen und Profil öffnen'**
  String get settingsOpenA11y;

  /// Hilfetext an den rechtlichen Wegen
  ///
  /// In de, this message translates to:
  /// **'Öffnet im Browser'**
  String get settingsOpensBrowser;

  /// Ladezustand der Vorschau
  ///
  /// In de, this message translates to:
  /// **'Wird gerechnet …'**
  String get settingsPreviewComputing;

  /// Zeile der Vorschau
  ///
  /// In de, this message translates to:
  /// **'Fitness ggü. Höchststand'**
  String get settingsPreviewFitness;

  /// Zeile der Vorschau
  ///
  /// In de, this message translates to:
  /// **'Last der letzten Einheit'**
  String get settingsPreviewLoad;

  /// Vorschau ohne Änderung
  ///
  /// In de, this message translates to:
  /// **'An deinen Auswertungen ändert das nichts.'**
  String get settingsPreviewNone;

  /// Überschrift der Vorschau
  ///
  /// In de, this message translates to:
  /// **'Was sich dadurch ändert'**
  String get settingsPreviewTitle;

  /// Rechtlicher Weg
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get settingsPrivacy;

  /// Aktion
  ///
  /// In de, this message translates to:
  /// **'Onboarding wiederholen'**
  String get settingsReplayOnboarding;

  /// Hilfetext
  ///
  /// In de, this message translates to:
  /// **'Fragt das Körpergewicht erneut ab.'**
  String get settingsReplayOnboardingHint;

  /// Feldbeschriftung
  ///
  /// In de, this message translates to:
  /// **'Pausenzeit'**
  String get settingsRest;

  /// Fehler an der Pausenzeit
  ///
  /// In de, this message translates to:
  /// **'Zwischen {min} und {max} Sekunden.'**
  String settingsRestFault(int min, int max);

  /// Hilfetext unter der Pausenzeit
  ///
  /// In de, this message translates to:
  /// **'Vorschlag beim Start einer Einheit. Im Training änderbar.'**
  String get settingsRestHint;

  /// Abschnitt
  ///
  /// In de, this message translates to:
  /// **'Über die App'**
  String get settingsSectionAbout;

  /// Abschnitt
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get settingsSectionAccount;

  /// Abschnitt
  ///
  /// In de, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// Abschnitt
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get settingsSectionLegal;

  /// Abschnitt
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get settingsSectionProfile;

  /// Abschnitt
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get settingsSectionTraining;

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

  /// Beschriftung am Konto
  ///
  /// In de, this message translates to:
  /// **'Angemeldet als'**
  String get settingsSignedInAs;

  /// Rechtlicher Weg
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen'**
  String get settingsTerms;

  /// settings.title
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// Feldbeschriftung
  ///
  /// In de, this message translates to:
  /// **'Einheiten'**
  String get settingsUnits;

  /// Hilfetext unter der Einheitenwahl
  ///
  /// In de, this message translates to:
  /// **'Gespeichert wird immer in Kilogramm.'**
  String get settingsUnitsHint;

  /// Einheitensystem
  ///
  /// In de, this message translates to:
  /// **'Imperial'**
  String get settingsUnitsImperial;

  /// Vorlesetext
  ///
  /// In de, this message translates to:
  /// **'Imperial, Pfund'**
  String get settingsUnitsImperialA11y;

  /// Einheitensystem
  ///
  /// In de, this message translates to:
  /// **'Metrisch'**
  String get settingsUnitsMetric;

  /// Vorlesetext
  ///
  /// In de, this message translates to:
  /// **'Metrisch, Kilogramm'**
  String get settingsUnitsMetricA11y;

  /// Widerrufshinweis
  ///
  /// In de, this message translates to:
  /// **'Körpergewicht auf {weight} kg geändert'**
  String settingsWeightChanged(String weight);

  /// Widerrufshinweis, Text
  ///
  /// In de, this message translates to:
  /// **'Du kannst das {n} Sekunden lang zurücknehmen.'**
  String settingsWeightChangedBody(int n);

  /// sheet.filter.active (Board 02)
  ///
  /// In de, this message translates to:
  /// **'{n} aktiv'**
  String sheetFilterActive(int n);

  /// sheet.filter.apply (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Anwenden'**
  String get sheetFilterApply;

  /// sheet.filter.title (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Filter'**
  String get sheetFilterTitle;

  /// Text im Start-Sheet beim freien Training
  ///
  /// In de, this message translates to:
  /// **'Ohne Plan starten — Übungen fügst du im Training hinzu.'**
  String get sheetFreeBody;

  /// sheet.grabber_hint (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Ziehen zum Schließen'**
  String get sheetGrabberHint;

  /// sheet.note.title (Board 02)
  ///
  /// In de, this message translates to:
  /// **'Notiz zum Satz'**
  String get sheetNoteTitle;

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

  /// signout
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signout;

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
  /// **'Du hast {c, plural, one {# Eintrag} other {# Einträge}} geändert und {a} hinzugefügt.'**
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

  /// weight.body
  ///
  /// In de, this message translates to:
  /// **'Bewertet jede Körpergewichtsübung in deinem Verlauf — heute und rückwirkend.'**
  String get weightBody;

  /// weight.delta
  ///
  /// In de, this message translates to:
  /// **'{sign}{kg} kg · {sign}{pct} %'**
  String weightDelta(String sign, String kg, String pct);

  /// weight.dir.down
  ///
  /// In de, this message translates to:
  /// **'niedriger'**
  String get weightDirDown;

  /// weight.dir.rescored
  ///
  /// In de, this message translates to:
  /// **'neu bewertet'**
  String get weightDirRescored;

  /// weight.dir.same
  ///
  /// In de, this message translates to:
  /// **'gleich'**
  String get weightDirSame;

  /// weight.dir.up
  ///
  /// In de, this message translates to:
  /// **'höher'**
  String get weightDirUp;

  /// weight.error.range
  ///
  /// In de, this message translates to:
  /// **'Zwischen 30 und 250 kg. Vorschau bleibt aus, bis der Wert stimmt.'**
  String get weightErrorRange;

  /// weight.hint
  ///
  /// In de, this message translates to:
  /// **'Eine Nachkommastelle · 30–250 kg'**
  String get weightHint;

  /// weight.impact.acwr
  ///
  /// In de, this message translates to:
  /// **'ACWR'**
  String get weightImpactAcwr;

  /// weight.impact.best
  ///
  /// In de, this message translates to:
  /// **'Bestwert {exercise}'**
  String weightImpactBest(String exercise);

  /// weight.impact.form
  ///
  /// In de, this message translates to:
  /// **'Formwert heute'**
  String get weightImpactForm;

  /// weight.impact.load
  ///
  /// In de, this message translates to:
  /// **'Trainingslast 7 T'**
  String get weightImpactLoad;

  /// weight.impact.note
  ///
  /// In de, this message translates to:
  /// **'Vorschau, noch nicht gespeichert. Deine Sätze, Gewichte und Wiederholungen bleiben unverändert — nur ihre Bewertung.'**
  String get weightImpactNote;

  /// Board 08, bwFolgen
  ///
  /// In de, this message translates to:
  /// **'Bestwert {exercise}'**
  String weightImpactRecord(String exercise);

  /// Board 08, bwFolgen — der Bestwert ändert sich nicht, seine Bewertung schon
  ///
  /// In de, this message translates to:
  /// **'neu bewertet'**
  String get weightImpactRescored;

  /// weight.impact.scope
  ///
  /// In de, this message translates to:
  /// **'{d} Tage · {n} Einheiten mit Körpergewichtsübungen'**
  String weightImpactScope(int d, int n);

  /// weight.impact.title
  ///
  /// In de, this message translates to:
  /// **'Was sich rückwirkend ändert'**
  String get weightImpactTitle;

  /// weight.previous
  ///
  /// In de, this message translates to:
  /// **'Vorher {alt} kg'**
  String weightPrevious(String alt);

  /// weight.save
  ///
  /// In de, this message translates to:
  /// **'Speichern und neu rechnen'**
  String get weightSave;

  /// weight.save.busy
  ///
  /// In de, this message translates to:
  /// **'Wird gerechnet'**
  String get weightSaveBusy;

  /// weight.save.none
  ///
  /// In de, this message translates to:
  /// **'Unverändert · nichts zu speichern'**
  String get weightSaveNone;

  /// weight.saved.snack
  ///
  /// In de, this message translates to:
  /// **'Gewicht {kg} kg · Form {alt} → {neu}'**
  String weightSavedSnack(String kg, String alt, String neu);

  /// weight.sub
  ///
  /// In de, this message translates to:
  /// **'Bewertet deinen ganzen Verlauf'**
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

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Form-Video zu {exercise} öffnen'**
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
  /// **'Session-Notizen öffnen'**
  String get workoutA11yNotes;

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

  /// aus workout.banner.active
  ///
  /// In de, this message translates to:
  /// **'Aktives Workout: {name}'**
  String workoutBannerActive(String name);

  /// aus workout.banner.cancel
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get workoutBannerCancel;

  /// aus workout.banner.cancelConfirm
  ///
  /// In de, this message translates to:
  /// **'Aktives Workout wirklich abbrechen? Alle Fortschritte gehen verloren.'**
  String get workoutBannerCancelConfirm;

  /// aus workout.banner.cancelWorkoutConfirm
  ///
  /// In de, this message translates to:
  /// **'Workout wirklich abbrechen? Alle Fortschritte gehen verloren.'**
  String get workoutBannerCancelWorkoutConfirm;

  /// aus workout.banner.resume
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get workoutBannerResume;

  /// aus workout.cardio.distance
  ///
  /// In de, this message translates to:
  /// **'Distanz (km)'**
  String get workoutCardioDistance;

  /// aus workout.cardio.duration
  ///
  /// In de, this message translates to:
  /// **'Dauer (Min.)'**
  String get workoutCardioDuration;

  /// aus workout.cardio.log
  ///
  /// In de, this message translates to:
  /// **'Cardio loggen'**
  String get workoutCardioLog;

  /// aus workout.cardio.pace
  ///
  /// In de, this message translates to:
  /// **'Pace'**
  String get workoutCardioPace;

  /// aus workout.cardio.rpe
  ///
  /// In de, this message translates to:
  /// **'Belastung (1–5)'**
  String get workoutCardioRpe;

  /// Spaltenkopf im Satzprotokoll
  ///
  /// In de, this message translates to:
  /// **'Halten'**
  String get workoutColHold;

  /// aus workout.copyLastSet
  ///
  /// In de, this message translates to:
  /// **'Letzten Satz kopieren'**
  String get workoutCopyLastSet;

  /// aus workout.editDate.error
  ///
  /// In de, this message translates to:
  /// **'Ungültiges Datumsformat. Bitte verwende YYYY-MM-DD'**
  String get workoutEditDateError;

  /// aus workout.editDate.prompt
  ///
  /// In de, this message translates to:
  /// **'Neues Datum (YYYY-MM-DD):'**
  String get workoutEditDatePrompt;

  /// aus workout.exercise.current
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Übung'**
  String get workoutExerciseCurrent;

  /// aus workout.exercise.finish
  ///
  /// In de, this message translates to:
  /// **'Workout beenden'**
  String get workoutExerciseFinish;

  /// aus workout.exercise.next
  ///
  /// In de, this message translates to:
  /// **'Nächste Übung'**
  String get workoutExerciseNext;

  /// aus workout.exercise.progress
  ///
  /// In de, this message translates to:
  /// **'{completed} / {total} Übungen'**
  String workoutExerciseProgress(String completed, int total);

  /// aus workout.feedback.enterDuration
  ///
  /// In de, this message translates to:
  /// **'Bitte Dauer eingeben'**
  String get workoutFeedbackEnterDuration;

  /// aus workout.feedback.exerciseComplete
  ///
  /// In de, this message translates to:
  /// **'Übung abgeschlossen!'**
  String get workoutFeedbackExerciseComplete;

  /// aus workout.feedback.restartError
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Neustarten des Workouts'**
  String get workoutFeedbackRestartError;

  /// aus workout.feedback.saveError
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern des Workouts'**
  String get workoutFeedbackSaveError;

  /// aus workout.feedback.saved
  ///
  /// In de, this message translates to:
  /// **'Workout gespeichert!'**
  String get workoutFeedbackSaved;

  /// Titel des Runners ohne Plan
  ///
  /// In de, this message translates to:
  /// **'Freies Training'**
  String get workoutFreeTitle;

  /// aus workout.hold
  ///
  /// In de, this message translates to:
  /// **'Halten'**
  String get workoutHold;

  /// aus workout.holdDurationLabel
  ///
  /// In de, this message translates to:
  /// **'Haltedauer (Sek.)'**
  String get workoutHoldDurationLabel;

  /// aus workout.lastPerformance
  ///
  /// In de, this message translates to:
  /// **'Letztes Mal'**
  String get workoutLastPerformance;

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

  /// aus workout.logging.exerciseAlreadyAdded
  ///
  /// In de, this message translates to:
  /// **'Übung bereits hinzugefügt'**
  String get workoutLoggingExerciseAlreadyAdded;

  /// aus workout.logging.exercisesOptional
  ///
  /// In de, this message translates to:
  /// **'Übungen (optional)'**
  String get workoutLoggingExercisesOptional;

  /// aus workout.logging.reps
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen pro Satz'**
  String get workoutLoggingReps;

  /// aus workout.logging.set
  ///
  /// In de, this message translates to:
  /// **'Satz'**
  String get workoutLoggingSet;

  /// aus workout.logging.sets
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get workoutLoggingSets;

  /// aus workout.logging.totalReps
  ///
  /// In de, this message translates to:
  /// **'Wdh.'**
  String get workoutLoggingTotalReps;

  /// aus workout.noPreviousData
  ///
  /// In de, this message translates to:
  /// **'Keine vorherigen Daten'**
  String get workoutNoPreviousData;

  /// aus workout.postWorkout.comparisonTitle
  ///
  /// In de, this message translates to:
  /// **'Vergleich zum letzten Mal'**
  String get workoutPostWorkoutComparisonTitle;

  /// aus workout.postWorkout.editDuration
  ///
  /// In de, this message translates to:
  /// **'Trainingszeit anpassen'**
  String get workoutPostWorkoutEditDuration;

  /// aus workout.postWorkout.exercises
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get workoutPostWorkoutExercises;

  /// aus workout.postWorkout.fallbackName
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get workoutPostWorkoutFallbackName;

  /// aus workout.postWorkout.minutes
  ///
  /// In de, this message translates to:
  /// **'Minuten'**
  String get workoutPostWorkoutMinutes;

  /// aus workout.postWorkout.sets
  ///
  /// In de, this message translates to:
  /// **'Sets'**
  String get workoutPostWorkoutSets;

  /// aus workout.postWorkout.time
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get workoutPostWorkoutTime;

  /// aus workout.postWorkout.title
  ///
  /// In de, this message translates to:
  /// **'Workout abgeschlossen!'**
  String get workoutPostWorkoutTitle;

  /// aus workout.postWorkout.toProgress
  ///
  /// In de, this message translates to:
  /// **'Zum Fortschritt'**
  String get workoutPostWorkoutToProgress;

  /// aus workout.postWorkout.volume
  ///
  /// In de, this message translates to:
  /// **'Volumen'**
  String get workoutPostWorkoutVolume;

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

  /// aus workout.quick.bodyweight
  ///
  /// In de, this message translates to:
  /// **'Bodyweight'**
  String get workoutQuickBodyweight;

  /// aus workout.quick.bodyweightDesc
  ///
  /// In de, this message translates to:
  /// **'Training mit Eigengewicht'**
  String get workoutQuickBodyweightDesc;

  /// aus workout.quick.date
  ///
  /// In de, this message translates to:
  /// **'Datum *'**
  String get workoutQuickDate;

  /// aus workout.quick.dateRequired
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle ein Datum'**
  String get workoutQuickDateRequired;

  /// aus workout.quick.difficulty
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit'**
  String get workoutQuickDifficulty;

  /// aus workout.quick.duration
  ///
  /// In de, this message translates to:
  /// **'Dauer (Minuten)'**
  String get workoutQuickDuration;

  /// aus workout.quick.durationRequired
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine gültige Dauer ein'**
  String get workoutQuickDurationRequired;

  /// aus workout.quick.name
  ///
  /// In de, this message translates to:
  /// **'Workout Name'**
  String get workoutQuickName;

  /// aus workout.quick.nameRequired
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Workout Namen ein'**
  String get workoutQuickNameRequired;

  /// aus workout.quick.saveError
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern des Workouts'**
  String get workoutQuickSaveError;

  /// aus workout.quick.title
  ///
  /// In de, this message translates to:
  /// **'Workout Schnell-Eintrag'**
  String get workoutQuickTitle;

  /// aus workout.quick.type
  ///
  /// In de, this message translates to:
  /// **'Typ'**
  String get workoutQuickType;

  /// aus workout.quick.weights
  ///
  /// In de, this message translates to:
  /// **'Gewichte'**
  String get workoutQuickWeights;

  /// aus workout.quick.weightsDesc
  ///
  /// In de, this message translates to:
  /// **'Gym / Hanteln'**
  String get workoutQuickWeightsDesc;

  /// Schwerstes je protokolliertes Gewicht dieser Übung
  ///
  /// In de, this message translates to:
  /// **'PR {weight} kg'**
  String workoutRecordKg(String weight);

  /// aus workout.recovery.duration
  ///
  /// In de, this message translates to:
  /// **'Dauer (Min.)'**
  String get workoutRecoveryDuration;

  /// aus workout.recovery.log
  ///
  /// In de, this message translates to:
  /// **'Recovery loggen'**
  String get workoutRecoveryLog;

  /// aus workout.relativeTime.daysAgo
  ///
  /// In de, this message translates to:
  /// **'vor {n} Tagen'**
  String workoutRelativeTimeDaysAgo(int n);

  /// aus workout.relativeTime.oneWeekAgo
  ///
  /// In de, this message translates to:
  /// **'vor 1 Woche'**
  String get workoutRelativeTimeOneWeekAgo;

  /// aus workout.relativeTime.today
  ///
  /// In de, this message translates to:
  /// **'heute'**
  String get workoutRelativeTimeToday;

  /// aus workout.relativeTime.weeksAgo
  ///
  /// In de, this message translates to:
  /// **'vor {n} Wochen'**
  String workoutRelativeTimeWeeksAgo(int n);

  /// aus workout.relativeTime.yesterday
  ///
  /// In de, this message translates to:
  /// **'gestern'**
  String get workoutRelativeTimeYesterday;

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

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get workoutRunnerBack;

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

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'FERTIG'**
  String get workoutRunnerNotesDone;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'Wie fühlt sich die Session an?'**
  String get workoutRunnerNotesHint;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'SESSION-NOTIZEN'**
  String get workoutRunnerNotesTitle;

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

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'−15s'**
  String get workoutRunnerRestMinus;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'+30s'**
  String get workoutRunnerRestPlus;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'SKIP →'**
  String get workoutRunnerRestSkip;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'SESSION LÄUFT · {time}'**
  String workoutRunnerRunning(String time);

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

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'LETZTES MAL'**
  String get workoutRunnerTableLast;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'WDH'**
  String get workoutRunnerTableReps;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'SATZ'**
  String get workoutRunnerTableSet;

  /// Runner, Modul 1/2 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'KG'**
  String get workoutRunnerTableWeight;

  /// aus workout.screen.addExercise
  ///
  /// In de, this message translates to:
  /// **'Übung hinzufügen'**
  String get workoutScreenAddExercise;

  /// aus workout.screen.addSet
  ///
  /// In de, this message translates to:
  /// **'Satz hinzufügen'**
  String get workoutScreenAddSet;

  /// aus workout.screen.bodyweight
  ///
  /// In de, this message translates to:
  /// **'Bodyweight'**
  String get workoutScreenBodyweight;

  /// aus workout.screen.cancelWorkout
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get workoutScreenCancelWorkout;

  /// aus workout.screen.cardio
  ///
  /// In de, this message translates to:
  /// **'Cardio'**
  String get workoutScreenCardio;

  /// aus workout.screen.currentExercise
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Übung'**
  String get workoutScreenCurrentExercise;

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

  /// aus workout.screen.emptyHint
  ///
  /// In de, this message translates to:
  /// **'Füge Übungen hinzu, um dein Workout zu starten'**
  String get workoutScreenEmptyHint;

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

  /// aus workout.screen.exercisesSheetTitle
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get workoutScreenExercisesSheetTitle;

  /// aus workout.screen.finishWorkout
  ///
  /// In de, this message translates to:
  /// **'Workout abschließen'**
  String get workoutScreenFinishWorkout;

  /// aus workout.screen.freeWorkout
  ///
  /// In de, this message translates to:
  /// **'Freies Workout'**
  String get workoutScreenFreeWorkout;

  /// aus workout.screen.goal
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get workoutScreenGoal;

  /// aus workout.screen.logWorkout
  ///
  /// In de, this message translates to:
  /// **'Workout erfassen'**
  String get workoutScreenLogWorkout;

  /// aus workout.screen.menu
  ///
  /// In de, this message translates to:
  /// **'Menü'**
  String get workoutScreenMenu;

  /// aus workout.screen.nextExercise
  ///
  /// In de, this message translates to:
  /// **'Nächste Übung'**
  String get workoutScreenNextExercise;

  /// aus workout.screen.noActiveWorkout
  ///
  /// In de, this message translates to:
  /// **'Kein aktives Workout'**
  String get workoutScreenNoActiveWorkout;

  /// aus workout.screen.noActiveWorkoutText
  ///
  /// In de, this message translates to:
  /// **'Starte ein Training aus dem Kalender oder einem Plan.'**
  String get workoutScreenNoActiveWorkoutText;

  /// aus workout.screen.noExercisesFound
  ///
  /// In de, this message translates to:
  /// **'Keine Übungen gefunden'**
  String get workoutScreenNoExercisesFound;

  /// aus workout.screen.recovery
  ///
  /// In de, this message translates to:
  /// **'Recovery'**
  String get workoutScreenRecovery;

  /// aus workout.screen.rest
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get workoutScreenRest;

  /// aus workout.screen.restTimer
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get workoutScreenRestTimer;

  /// aus workout.screen.saveWorkout
  ///
  /// In de, this message translates to:
  /// **'Workout speichern'**
  String get workoutScreenSaveWorkout;

  /// aus workout.screen.searchExercise
  ///
  /// In de, this message translates to:
  /// **'Übung suchen...'**
  String get workoutScreenSearchExercise;

  /// aus workout.screen.switchToExercise
  ///
  /// In de, this message translates to:
  /// **'Zu dieser Übung wechseln'**
  String get workoutScreenSwitchToExercise;

  /// aus workout.screen.timerAdd
  ///
  /// In de, this message translates to:
  /// **'+10s'**
  String get workoutScreenTimerAdd;

  /// aus workout.screen.timerDone
  ///
  /// In de, this message translates to:
  /// **'Pause vorbei!'**
  String get workoutScreenTimerDone;

  /// aus workout.screen.timerPause
  ///
  /// In de, this message translates to:
  /// **'Pausieren'**
  String get workoutScreenTimerPause;

  /// aus workout.screen.timerResume
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get workoutScreenTimerResume;

  /// aus workout.screen.timerSkip
  ///
  /// In de, this message translates to:
  /// **'Ueberspringen'**
  String get workoutScreenTimerSkip;

  /// aus workout.screen.timerStart
  ///
  /// In de, this message translates to:
  /// **'Timer starten'**
  String get workoutScreenTimerStart;

  /// aus workout.screen.timerSub
  ///
  /// In de, this message translates to:
  /// **'-10s'**
  String get workoutScreenTimerSub;

  /// aus workout.screen.toPlans
  ///
  /// In de, this message translates to:
  /// **'Zu den Plänen'**
  String get workoutScreenToPlans;

  /// aus workout.screen.weighted
  ///
  /// In de, this message translates to:
  /// **'Gewichte'**
  String get workoutScreenWeighted;

  /// aus workout.setLogger.addSet
  ///
  /// In de, this message translates to:
  /// **'Satz hinzufügen'**
  String get workoutSetLoggerAddSet;

  /// aus workout.setLogger.atLeastOneSet
  ///
  /// In de, this message translates to:
  /// **'Bitte logge mindestens einen Satz bevor du weitergehst'**
  String get workoutSetLoggerAtLeastOneSet;

  /// aus workout.setLogger.completedSets
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossene Sätze'**
  String get workoutSetLoggerCompletedSets;

  /// aus workout.setLogger.decreaseWeight
  ///
  /// In de, this message translates to:
  /// **'Gewicht verringern'**
  String get workoutSetLoggerDecreaseWeight;

  /// aus workout.setLogger.deleteSet
  ///
  /// In de, this message translates to:
  /// **'Satz löschen'**
  String get workoutSetLoggerDeleteSet;

  /// aus workout.setLogger.deleteSetConfirm
  ///
  /// In de, this message translates to:
  /// **'Diesen Satz wirklich löschen?'**
  String get workoutSetLoggerDeleteSetConfirm;

  /// aus workout.setLogger.duplicateLast
  ///
  /// In de, this message translates to:
  /// **'Letzten Satz kopieren'**
  String get workoutSetLoggerDuplicateLast;

  /// aus workout.setLogger.enterHold
  ///
  /// In de, this message translates to:
  /// **'Bitte gib die Haltedauer ein'**
  String get workoutSetLoggerEnterHold;

  /// aus workout.setLogger.enterReps
  ///
  /// In de, this message translates to:
  /// **'Bitte gib die Anzahl der Wiederholungen ein'**
  String get workoutSetLoggerEnterReps;

  /// aus workout.setLogger.increaseWeight
  ///
  /// In de, this message translates to:
  /// **'Gewicht erhöhen'**
  String get workoutSetLoggerIncreaseWeight;

  /// aus workout.setLogger.logSet
  ///
  /// In de, this message translates to:
  /// **'Satz loggen'**
  String get workoutSetLoggerLogSet;

  /// aus workout.setLogger.noSets
  ///
  /// In de, this message translates to:
  /// **'Noch keine Sätze geloggt'**
  String get workoutSetLoggerNoSets;

  /// aus workout.setLogger.reps
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen'**
  String get workoutSetLoggerReps;

  /// aus workout.setLogger.rest
  ///
  /// In de, this message translates to:
  /// **'{seconds}s Pause'**
  String workoutSetLoggerRest(int seconds);

  /// aus workout.setLogger.set
  ///
  /// In de, this message translates to:
  /// **'Satz'**
  String get workoutSetLoggerSet;

  /// aus workout.setLogger.stepModeChanged
  ///
  /// In de, this message translates to:
  /// **'Schrittweite: {step} {unit}'**
  String workoutSetLoggerStepModeChanged(int step, String unit);

  /// aus workout.setLogger.target
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get workoutSetLoggerTarget;

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

  /// aus workout.setLogger.weight
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get workoutSetLoggerWeight;

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

  /// Zielvorgabe aus dem Plan, als Referenz neben dem Feld
  ///
  /// In de, this message translates to:
  /// **'Ziel {sets}×{reps}'**
  String workoutTargetRef(int sets, String reps);

  /// Zielvorgabe aus dem Plan, neben dem Feld
  ///
  /// In de, this message translates to:
  /// **'Ziel {reps}'**
  String workoutTargetReps(String reps);

  /// Zielvorgabe ohne Wiederholungsangabe
  ///
  /// In de, this message translates to:
  /// **'Ziel {sets} Sätze'**
  String workoutTargetSets(int sets);

  /// Name des Trainings ohne Plan
  ///
  /// In de, this message translates to:
  /// **'Freies Training'**
  String get workoutsFree;

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

  /// Einstieg in die Übungsliste
  ///
  /// In de, this message translates to:
  /// **'{n} Übungen durchsuchen'**
  String workoutsSearchEntry(int n);

  /// Aktion auf der Session-Karte
  ///
  /// In de, this message translates to:
  /// **'Training starten'**
  String get workoutsStart;

  /// Titel des Tabs
  ///
  /// In de, this message translates to:
  /// **'Workouts'**
  String get workoutsTitle;

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
  /// **'gegen eigenen Schnitt {value} · {n, plural, one{1 Einheit} other{# Einheiten}}'**
  String analysisPaceBasisOther(String value, int n);

  /// analysis.pct.faster (Board 11) — Fassung für alle Aktivitäten außer Laufen
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{Schneller als 1 deiner Einheiten} other{Schneller als # von {total} deiner Einheiten}}'**
  String analysisPctFasterOther(int n, int total);

  /// intensity.fallback.note (Board 11) — Fassung für alle Aktivitäten außer Laufen
  ///
  /// In de, this message translates to:
  /// **'Weder Puls noch RPE erfasst. Beurteilt wird über das Tempo gegen {n, plural, one{1 Einheit} other{# Einheiten}} derselben Aktivität.'**
  String intensityFallbackNoteOther(int n);
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
