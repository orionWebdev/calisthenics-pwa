@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/exercises/application/exercise_providers.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Sichtprüfung des Session-Loggers mit echten Schriften.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/runner_render_test.dart
///
/// Drei Lagen: Gewichtsübung mit drei Sätzen, Halteübung, laufende Pause —
/// je auf Honor-Breite (361 dp, Schrift 1,15) und im Extremfall
/// (320 dp, Schrift 2,0).

/// Ein Plan mit beidem: Sätzen mit Gewicht und einer Halteübung.
final _plans = <Plan>[
  const Plan(
    id: 'p1',
    name: 'Upper Body Power',
    type: 'strength',
    items: [
      PlanItem(
          exerciseId: 'archer_push_up', sets: 3, reps: '8-12', restSeconds: 90),
      PlanItem(exerciseId: 'plank', sets: 2, holdSeconds: 45, restSeconds: 60),
    ],
  ),
];

final _exercises = <Exercise>[
  const Exercise(
    id: 'archer_push_up',
    name: 'Archer Push-up mit sehr langem Namen',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps],
    muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
    equipment: ['bodyweight'],
    difficulty: 4,
    instructions: ['Schritt eins', 'Schritt zwei'],
    cues: ['Brust raus'],
    commonMistakes: ['Hohlkreuz'],
  ),
  const Exercise(
    id: 'plank',
    name: 'Unterarmstütz',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.core],
    muscleGroups: [MuscleGroup.core],
    equipment: ['bodyweight'],
    instructions: ['Körper gerade halten'],
  ),
];

class _Plans extends FakePlanRepository {
  @override
  Stream<List<Plan>> watchPlans(String userId) => Stream.value(_plans);

  @override
  Future<List<Plan>> fetchPlans(String userId) async => _plans;
}

class _Exercises extends FakeExerciseRepository {
  @override
  Stream<List<Exercise>> watchExercises(String userId) =>
      Stream.value(_exercises);

  @override
  Future<List<Exercise>> fetchExercises(String userId) async => _exercises;
}

/// Wie `writePng`, aber mit Wiederholung: `toByteData` liefert im Testbinding
/// gelegentlich `null`, wenn der Frame noch nicht gezeichnet ist.
Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  final dir = Platform.environment['ATEM_RENDER_DIR']!;
  for (var attempt = 0; attempt < 4; attempt++) {
    await tester.pump();
    final ok = await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return false;
      Directory(dir).createSync(recursive: true);
      File('$dir/$name.png').writeAsBytesSync(data.buffer.asUint8List());
      return true;
    });
    if (ok == true) return;
  }
}

void main() {
  // Der Runner sichert beim Abhaken einen Zwischenstand über `path_provider`.
  // Im Test gibt es kein Plugin — ein Verzeichnis aus dem Systemtemp genügt.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.createTempSync('atem_render').path,
    );
  });

  // Ersetzen statt ergänzen: Riverpod lässt eine Überschreibung je Provider zu.
  // 4 ist der Übungsbestand, 5 die Pläne (Reihenfolge in `fixtureOverrides`).
  final overrides = [
    for (var i = 0; i < fixtureOverrides.length; i++)
      switch (i) {
        4 => exerciseRepositoryProvider.overrideWithValue(_Exercises()),
        5 => planRepositoryProvider.overrideWithValue(_Plans()),
        _ => fixtureOverrides[i],
      },
  ];

  Future<GlobalKey> pumpRunner(
    WidgetTester tester, {
    required Size size,
    required double scale,
  }) async {
    await loadRealFonts();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AtemTheme.dark,
          locale: const Locale('de'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const WorkoutRunnerScreen(start: WorkoutStart(planId: 'p1')),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return key;
  }

  testWidgets('rendert den Runner auf Honor-Breite', (tester) async {
    if (!renderEnabled) return;
    final key = await pumpRunner(tester,
        size: const Size(361, 780), scale: 1.15);

    await _shot(tester, key, 'runner_gewicht');

    // Zweite Übung: Halten statt Wiederholungen.
    await tester.tap(find.bySemanticsLabel('Nächste Übung'));
    await tester.pumpAndSettle();
    await _shot(tester, key, 'runner_halten');

    // Zurück und das Eingabeblatt über Satz 1 öffnen.
    await tester.tap(find.bySemanticsLabel('Vorherige Übung'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^KG, Satz 1')));
    await tester.pumpAndSettle();
    await _shot(tester, key, 'runner_regler');

    // Gewicht und Wiederholungen übernehmen …
    await tester.tap(find.text('ÜBERNEHMEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^WDH, Satz 1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ÜBERNEHMEN'));
    await tester.pumpAndSettle();
    await _shot(tester, key, 'runner_werte');

    // … und abhaken: Pausenleiste, und Satz 2 trägt die übernommenen Werte
    // in Cyan.
    await tester.tap(find.bySemanticsLabel('Satz 1 abschließen'));
    await tester.pumpAndSettle();
    await _shot(tester, key, 'runner_pause');
  });

  testWidgets('rendert den Runner bei 320 dp und 200 Prozent', (tester) async {
    if (!renderEnabled) return;
    final key =
        await pumpRunner(tester, size: const Size(320, 800), scale: 2.0);

    await _shot(tester, key, 'runner_320_0');

    final scrollables = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    for (var shot = 1; shot < 4; shot++) {
      if (scrollables.evaluate().isEmpty) break;
      final state = tester.state<ScrollableState>(scrollables.first);
      final before = state.position.pixels;
      state.position.jumpTo(
          (before + 700).clamp(0, state.position.maxScrollExtent).toDouble());
      await tester.pumpAndSettle();
      if (state.position.pixels == before) break;
      await _shot(tester, key, 'runner_320_$shot');
    }
  });
}
