import 'dart:async';

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/exercises/application/exercise_providers.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/exercise_draft.dart';
import 'package:atem/features/exercises/domain/exercise_repository.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/session_draft.dart';
import 'package:atem/features/history/domain/session_patch.dart';
import 'package:atem/features/history/domain/session_repository.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/plans/domain/plan_draft.dart';
import 'package:atem/features/plans/domain/plan_repository.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/settings/domain/settings_repository.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/weight/application/weight_providers.dart';
import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:atem/features/weight/domain/weight_repository.dart';
import 'package:atem/features/weight/domain/weight_series.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth.dart';

/// Fixture-Datenquellen für alle Tests.
///
/// Ohne Typannotation: `Override` wird von flutter_riverpod nicht exportiert,
/// der Typ wird aus dem Literal abgeleitet. Die Preview-Repositories sind
/// zustandslos, geteilte Instanzen sind also unbedenklich.
final fixtureOverrides = [
  // Mit angemeldetem Nutzer: Sonst liefern alle Provider leere Listen und die
  // Matrix prüfte überall nur den Leerzustand.
  authRepositoryProvider.overrideWithValue(
    FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
  ),
  allowlistRepositoryProvider.overrideWithValue(FakeAllowlistRepository()),
  profileRepositoryProvider
      .overrideWithValue(FakeProfileRepository(weightKg: 78)),
  dashboardRepositoryProvider.overrideWithValue(PreviewDashboardRepository()),
  exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository()),
  planRepositoryProvider.overrideWithValue(FakePlanRepository()),
  sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
  settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
  weightRepositoryProvider.overrideWithValue(FakeWeightRepository()),
  accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
  // Fester Stichtag: Sonst hinge die Aussage-Karte am Kalender des Rechners
  // und zeigte mal „Pause", mal „Untätig".
  historyReferenceProvider.overrideWithValue(fixtureToday),
];

/// Der 27.08.2026 — derselbe Stichtag wie im Bestand des Nutzers.
final fixtureToday = DateTime(2026, 8, 27);

/// Einheiten über ein halbes Jahr, mit einer langen Lücke am Ende: genau die
/// Lage, in der sich der einzige echte Nutzer befindet.
final fixtureSessions = <TrainingSession>[
  for (var i = 0; i < 40; i++)
    StrengthSession(
      id: 's$i',
      userId: 'u',
      date: DateTime(2026, 3, 1 + i * 3),
      createdAt: DateTime(2026, 3, 1 + i * 3),
      bodyweight: false,
      duration: const Duration(minutes: 45),
      rpe: 3,
      planId: 'p1',
      planName: 'Upper Body Power',
      // Übungen und Sätze, damit Modul 9 überhaupt etwas zu rechnen hat:
      // ohne sie blieben Muskelbalance und Übungsverlauf im dünnen Zustand,
      // und die Matrix prüfte nur Leerzustände.
      exercises: [
        LoggedExercise(
          exerciseId: 'archer_push_up',
          sets: [
            LoggedSet(reps: 8, weight: 60 + i.toDouble()),
            const LoggedSet(reps: 8, weight: 60),
          ],
        ),
        const LoggedExercise(
          exerciseId: 'pistol_squat',
          sets: [LoggedSet(reps: 6)],
        ),
      ],
    ),
];

class FakeSessionRepository implements SessionRepository {
  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(fixtureSessions);

  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async =>
      fixtureSessions;

  @override
  Future<String> saveSession(SessionDraft draft) async => 'neu';

  @override
  Stream<bool> watchFromCache(String userId) => Stream.value(false);

  /// Was geschrieben wurde — die Attrappen protokollieren, statt zu schweigen.
  /// Ein Test, der nur prüft, dass nichts abstürzt, prüft zu wenig.
  final patched = <String, SessionPatch>{};
  final deleted = <String>[];

  @override
  Future<void> updateSession(String id, SessionPatch patch) async {
    patched[id] = patch;
  }

  @override
  @override
  Future<void> updateSessionExercises(
      String id, List<LoggedExercise> exercises) async {}

  @override
  Future<void> deleteSession(String id) async => deleted.add(id);
}

/// Übungen für die Prüfmatrix — bewusst mit langen Namen und vielen Muskeln,
/// weil genau daran Layouts bei 200 % Schrift zerbrechen.
final fixtureExercises = <Exercise>[
  const Exercise(
    id: 'archer_push_up',
    name: 'Archer Push-up mit sehr langem Namen',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
    muscleGroups: [MuscleGroup.core, MuscleGroup.back],
    equipment: ['bodyweight'],
    difficulty: 4,
    instructions: ['Schritt eins', 'Schritt zwei'],
    cues: ['Brust raus'],
    commonMistakes: ['Hohlkreuz'],
  ),
  // Der Normalfall: nur ein Name.
  const Exercise(id: 'x1', name: 'Eigene Übung', source: ExerciseSource.own),
];

final fixturePlans = <Plan>[
  const Plan(
    id: 'p1',
    name: 'Upper Body Power',
    type: 'strength',
    items: [
      PlanItem(exerciseId: 'archer_push_up', sets: 4, restSeconds: 90),
      // Zeigt auf eine Übung, die es nicht gibt — der kaputte Plan.
      PlanItem(exerciseId: 'geloescht', sets: 3, reps: '8-12'),
    ],
  ),
];

class FakeExerciseRepository implements ExerciseRepository {
  @override
  Stream<List<Exercise>> watchExercises(String userId) =>
      Stream.value(fixtureExercises);

  @override
  Future<List<Exercise>> fetchExercises(String userId) async =>
      fixtureExercises;

  final saved = <ExerciseDraft>[];
  final deleted = <String>[];

  @override
  Future<String> saveExercise(ExerciseDraft draft) async {
    saved.add(draft);
    return draft.id ?? 'neu';
  }

  @override
  Future<void> deleteExercise(String id) async => deleted.add(id);
}

class FakePlanRepository implements PlanRepository {
  @override
  Stream<List<Plan>> watchPlans(String userId) => Stream.value(fixturePlans);

  @override
  Future<List<Plan>> fetchPlans(String userId) async => fixturePlans;

  final saved = <PlanDraft>[];
  final deleted = <String>[];

  @override
  Future<String> savePlan(PlanDraft draft) async {
    saved.add(draft);
    return draft.id ?? 'neu';
  }

  @override
  Future<void> deletePlan(String id) async => deleted.add(id);
}

/// Die Prüfmatrix aus `docs/contracts/01-accessibility.md`.
///
/// Drei Schriftskalierungen mal drei Breiten. Das ist die einzige Prüfung, die
/// Überlauf zuverlässig fängt — ein Layout, das bei 390 dp und Faktor 1.0
/// funktioniert, sagt nichts über 320 dp bei Faktor 2.0.
const a11yTextScales = <double>[1.0, 1.3, 2.0];
const a11ySizes = <Size>[
  Size(320, 640), // schmalstes verbreitetes Android-Gerät
  Size(360, 800), // Median
  Size(412, 915), // Pixel-Klasse
];

/// Ergebnis einer einzelnen Matrixzelle.
class A11yFinding {
  A11yFinding(this.width, this.scale, this.rule, this.detail);

  final double width;
  final double scale;
  final String rule;
  final String detail;

  @override
  String toString() =>
      '${width.toInt()}dp @${scale}x  $rule\n      ${detail.split('\n').first}';
}

/// Prüft ein Widget über die gesamte Matrix gegen den A11y-Vertrag.
///
/// Sammelt **alle** Befunde statt beim ersten abzubrechen — beim Aufräumen
/// technischer Schuld ist die vollständige Liste mehr wert als der erste Treffer.
///
/// Animationen sind abgeschaltet: Ohne das laufen die dekorativen Dauerschleifen
/// endlos und `pumpAndSettle()` läuft in den Timeout (Vertrag R8).
Future<List<A11yFinding>> collectA11yFindings(
  WidgetTester tester,
  Widget home, {
  List<double> textScales = a11yTextScales,
  List<Size> sizes = a11ySizes,
}) async {
  final findings = <A11yFinding>[];

  for (final size in sizes) {
    for (final scale in textScales) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          overrides: fixtureOverrides,
          child: MaterialApp(
            theme: AtemTheme.dark,
            locale: const Locale('de'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: home,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Überlauf und Layoutfehler schlagen als Exception auf.
      final rendered = tester.takeException();
      if (rendered != null) {
        findings
            .add(A11yFinding(size.width, scale, 'layout', rendered.toString()));
      }

      for (final entry in <String, AccessibilityGuideline>{
        'tap-target': androidTapTargetGuideline,
        'label': labeledTapTargetGuideline,
      }.entries) {
        final result = await entry.value.evaluate(tester);
        if (!result.passed) {
          findings.add(
              A11yFinding(size.width, scale, entry.key, result.reason ?? ''));
        }
      }

      handle.dispose();
    }
  }

  return findings;
}

/// Das eigentliche Tor. Schlägt fehl, sobald irgendeine Zelle einen Befund hat.
Future<void> expectA11y(
  WidgetTester tester,
  Widget home, {
  List<double> textScales = a11yTextScales,
  List<Size> sizes = a11ySizes,
}) async {
  final findings = await collectA11yFindings(
    tester,
    home,
    textScales: textScales,
    sizes: sizes,
  );
  expect(
    findings,
    isEmpty,
    reason: 'Verstöße gegen docs/contracts/01-accessibility.md:\n'
        '${findings.map((f) => '  $f').join('\n')}',
  );
}

/// Eine Gewichtsreihe über drei Monate, mit einer Lücke und einem gemessenen
/// Wert — sonst prüfte die Matrix nur die Punktwolke und nie die Kurve.
class FakeWeightRepository implements WeightRepository {
  FakeWeightRepository({List<WeightEntry>? entries})
      : entries = entries ?? List.of(fixtureWeights);

  final List<WeightEntry> entries;

  /// **Der Strom meldet jede Änderung nach**, wie Firestore es tut. Ein Fake,
  /// der nur einmal liefert, lässt jeden Ablauf mit zwei Schreibvorgängen
  /// gegen einen veralteten Stand rechnen — und der zweite Lauf eines
  /// Abgleichs sähe aus, als hätte der erste nichts bewirkt.
  final _changes = StreamController<WeightSeries>.broadcast();

  @override
  Stream<WeightSeries> watch(String userId) async* {
    yield WeightSeries.of(entries);
    yield* _changes.stream;
  }

  @override
  Future<WeightSeries> fetch(String userId) async => WeightSeries.of(entries);

  @override
  Future<void> save(String userId, WeightEntry entry) async {
    entries.removeWhere((e) => e.documentId == entry.documentId);
    entries.add(entry);
    _changes.add(WeightSeries.of(entries));
  }

  @override
  Future<void> delete(String userId, DateTime day) async {
    entries.removeWhere((e) => e.documentId == WeightEntry.idFor(day));
    _changes.add(WeightSeries.of(entries));
  }
}

/// Neun Einträge bis zum [fixtureToday], darin eine Lücke von sechs Wochen
/// und zwei gemessene Werte.
final fixtureWeights = <WeightEntry>[
  WeightEntry(
      date: DateTime(2026, 5, 20), kg: 80.9, source: WeightSource.settings),
  WeightEntry(
      date: DateTime(2026, 5, 27), kg: 80.6, source: WeightSource.manual),
  WeightEntry(
      date: DateTime(2026, 6, 3), kg: 80.3, source: WeightSource.healthConnect),
  // Sechs Wochen ohne Eintrag — der Bruch in der Kurve.
  WeightEntry(
      date: DateTime(2026, 7, 16), kg: 79.8, source: WeightSource.manual),
  WeightEntry(
      date: DateTime(2026, 7, 26), kg: 79.6, source: WeightSource.manual),
  WeightEntry(
      date: DateTime(2026, 8, 4), kg: 79.3, source: WeightSource.healthConnect),
  WeightEntry(
      date: DateTime(2026, 8, 13), kg: 79.1, source: WeightSource.manual),
  WeightEntry(
      date: DateTime(2026, 8, 20), kg: 78.9, source: WeightSource.manual),
  WeightEntry(
      date: DateTime(2026, 8, 25), kg: 78.5, source: WeightSource.manual),
];

/// Einstellungen mit hinterlegtem Gewicht — sonst prüfte die Matrix nur den
/// Zustand „noch nichts eingetragen".
class FakeSettingsRepository implements SettingsRepository {
  /// Ohne Angabe die [fixture]; mit Angabe ein abweichender Stand, etwa für
  /// die RIR-Skala.
  FakeSettingsRepository({UserSettings? settings})
      : settings = settings ?? fixture;

  final UserSettings settings;
  final saved = <UserSettings>[];

  static const fixture = UserSettings(
    bodyWeightKg: 78,
    language: AppLanguage.german,
    restSeconds: 90,
  );

  @override
  Stream<UserSettings> watch(String userId) => Stream.value(settings);

  @override
  Future<UserSettings> fetch(String userId) async => settings;

  @override
  Future<void> save(String userId, UserSettings settings) async =>
      saved.add(settings);
}

class FakeAccountRepository implements AccountRepository {
  final deletedData = <String>[];
  var accountDeleted = false;

  @override
  Future<void> deleteData(
    String userId, {
    void Function(int done, int total, String collection)? onProgress,
  }) async {
    deletedData.add(userId);
    onProgress?.call(1, 1, 'sessions');
  }

  @override
  Future<void> deleteAccount() async => accountDeleted = true;

  @override
  Future<AccountExport> export(String userId) async =>
      const AccountExport(collections: {});
}
