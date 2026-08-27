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

  /// Begründung unter der Zerlegung
  ///
  /// In de, this message translates to:
  /// **'Was fehlt, ist Aktualität — eine Einheit heute bringt sofort {n} Punkte.'**
  String analysisHintRecency(int n);

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

  /// aus common.cancel
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

  /// aus common.save
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get commonSave;

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

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'ANALYSE'**
  String get dashboardNavAnalytics;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'HOME'**
  String get dashboardNavHome;

  /// Dashboard, Modul 1 Spezifikation
  ///
  /// In de, this message translates to:
  /// **'PROFIL'**
  String get dashboardNavProfile;

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

  /// Kennzahl im Detail
  ///
  /// In de, this message translates to:
  /// **'Last'**
  String get detailLoad;

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

  /// Vorlesefassung der Segmentanzeige
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit {n} von 5'**
  String exerciseDifficultyA11y(int n);

  /// Abschnitt im Detail
  ///
  /// In de, this message translates to:
  /// **'Anleitung'**
  String get exerciseInstructions;

  /// Abschnitt im Detail
  ///
  /// In de, this message translates to:
  /// **'Häufige Fehler'**
  String get exerciseMistakes;

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

  /// Zählzeile über der Liste
  ///
  /// In de, this message translates to:
  /// **'{n} Übungen · {k} kuratiert · {e} eigene'**
  String exercisesCount(int n, int k, int e);

  /// Suche ohne Treffer, Text
  ///
  /// In de, this message translates to:
  /// **'Keine Übung passt zu „{q}“ — auch nicht auf Englisch.'**
  String exercisesEmptyBody(String q);

  /// Suche ohne Treffer
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden'**
  String get exercisesEmptyTitle;

  /// Erster Filter-Chip, steht fest an Position 1
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get exercisesFilterAll;

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

  /// Überschrift der Kurzliste
  ///
  /// In de, this message translates to:
  /// **'Letzte Einheiten'**
  String get historyRecentLabel;

  /// Titel des Tabs
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

  /// Platzhalter für einen noch nicht gebauten Bereich
  ///
  /// In de, this message translates to:
  /// **'Dieser Bereich ist noch nicht gebaut.'**
  String get navSoonBody;

  /// Platzhalter für einen noch nicht gebauten Bereich
  ///
  /// In de, this message translates to:
  /// **'Kommt noch'**
  String get navSoonTitle;

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

  /// Zählzeile der Planliste
  ///
  /// In de, this message translates to:
  /// **'{n} Pläne'**
  String planCount(int n);

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

  /// Pausenlänge in Sekunden
  ///
  /// In de, this message translates to:
  /// **'{n} s'**
  String restSeconds(int n);

  /// Text im Start-Sheet beim freien Training
  ///
  /// In de, this message translates to:
  /// **'Ohne Plan starten — Übungen fügst du im Training hinzu.'**
  String get sheetFreeBody;

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

  /// Ansage während des unentschiedenen ersten Moments
  ///
  /// In de, this message translates to:
  /// **'ATEM startet …'**
  String get splashStarting;

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

  /// aus workout.targetHold
  ///
  /// In de, this message translates to:
  /// **'Ziel: {seconds} halten'**
  String workoutTargetHold(int seconds);

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
