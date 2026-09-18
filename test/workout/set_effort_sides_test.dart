import 'dart:io';

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/workout/application/workout_providers.dart';
import 'package:atem/features/workout/domain/workout_session.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Anstrengung je Satz und seitengetrennte Sätze im Runner (18.09.2026).
void main() {
  const start = WorkoutStart(planId: 'p1');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  Future<(ProviderContainer, WorkoutSessionController)> loaded() async {
    final container = ProviderContainer(overrides: fixtureOverrides);
    addTearDown(container.dispose);
    await container.read(workoutSessionProvider(start).future);
    return (container, container.read(workoutSessionProvider(start).notifier));
  }

  ActiveWorkout workout(ProviderContainer c) =>
      c.read(workoutSessionProvider(start)).value!;

  List<WorkoutSet> sets(ProviderContainer c) => workout(c).exercises.first.sets;

  group('Anstrengung je Satz', () {
    test('setzt und löscht die Angabe', () async {
      final (c, n) = await loaded();
      final id = sets(c)[0].id;

      n.setRpe(0, id, 8);
      expect(sets(c)[0].rpe, 8);

      n.setRpe(0, id, null);
      expect(sets(c)[0].rpe, isNull, reason: '„keine Angabe" löscht');
    });

    test('wandert nicht in den nächsten Satz', () async {
      final (c, n) = await loaded();
      final id = sets(c)[0].id;

      n.updateWeight(0, id, '20');
      n.updateReps(0, id, '8');
      n.setRpe(0, id, 9);
      n.toggleSet(0, id);
      expect(sets(c)[1].weight, '20', reason: 'die Werte wandern weiter');
      expect(sets(c)[1].rpe, isNull, reason: 'die Anstrengung nicht');

      n.addSet(0);
      expect(sets(c).last.rpe, isNull);
    });

    test('landet im Entwurf für die Historie', () async {
      final (c, n) = await loaded();
      final id = sets(c)[0].id;

      n.updateReps(0, id, '8');
      n.toggleSet(0, id);
      n.setRpe(0, id, 8);

      final draft = WorkoutSessionController.toDraft(workout(c),
          userId: 'u', duration: const Duration(minutes: 30))!;
      expect(draft.exercises.first.sets.single.rpe, 8);
      expect(draft.exercises.first.sets.single.isHard, isTrue);
    });
  });

  group('Seiten getrennt', () {
    test('Einschalten belegt die offenen Sätze abwechselnd', () async {
      final (c, n) = await loaded();

      n.setUnilateral(0, true);

      expect(workout(c).exercises.first.unilateral, isTrue);
      expect([
        for (final s in sets(c)) s.side
      ], [
        SetSide.left,
        SetSide.right,
        SetSide.left,
        SetSide.right,
      ]);
    });

    test('abgehakte Sätze behalten, was sie haben', () async {
      final (c, n) = await loaded();
      final first = sets(c)[0].id;
      n.updateReps(0, first, '8');
      n.toggleSet(0, first);

      n.setUnilateral(0, true);

      expect(sets(c)[0].side, isNull,
          reason: 'eine Seite nachträglich zu behaupten wäre erfunden');
      // Die offenen beginnen links.
      expect(sets(c)[1].side, SetSide.left);
      expect(sets(c)[2].side, SetSide.right);
    });

    test('„+ Satz" wechselt die Seite', () async {
      final (c, n) = await loaded();
      n.setUnilateral(0, true);
      expect(sets(c).last.side, SetSide.right);

      n.addSet(0);
      expect(sets(c).last.side, SetSide.left);
      n.addSet(0);
      expect(sets(c).last.side, SetSide.right);
    });

    test('ohne „Seiten getrennt" trägt ein neuer Satz keine Seite', () async {
      final (c, n) = await loaded();
      n.addSet(0);
      expect(sets(c).last.side, isNull);
    });

    test('Tippen auf die Marke wechselt die Seite', () async {
      final (c, n) = await loaded();
      n.setUnilateral(0, true);
      final id = sets(c)[0].id;

      n.toggleSide(0, id);
      expect(sets(c)[0].side, SetSide.right);
      n.toggleSide(0, id);
      expect(sets(c)[0].side, SetSide.left);
    });

    test('die Übernahme geht auf die andere Seite', () async {
      final (c, n) = await loaded();
      n.setUnilateral(0, true);
      // L R L R — Satz 2 (rechts) steht vor Satz 3 (links).
      final ids = [for (final s in sets(c)) s.id];

      n.updateWeight(0, ids[0], '12');
      n.updateReps(0, ids[0], '10');
      // Satz 2 (rechts) schon getippt und abgehakt, bevor links fertig ist.
      n.updateReps(0, ids[1], '9');
      n.toggleSet(0, ids[1]);
      // Rechts fertig: die Werte gehen an den nächsten offenen **linken**
      // Satz — Satz 3, nicht an Satz 1 davor und nicht an Satz 4.
      expect(sets(c)[2].reps, '9');
      expect(sets(c)[3].reps, isEmpty);

      n.toggleSet(0, ids[0]);
      // Links fertig: an den nächsten offenen rechten — Satz 4.
      expect(sets(c)[3].weight, '12');
      expect(sets(c)[3].reps, '10');
      expect(sets(c)[3].carried, isTrue);
    });

    test('Ausschalten entfernt die Seite nur bei offenen Sätzen', () async {
      final (c, n) = await loaded();
      n.setUnilateral(0, true);
      final first = sets(c)[0].id;
      n.updateReps(0, first, '8');
      n.toggleSet(0, first);

      n.setUnilateral(0, false);

      expect(workout(c).exercises.first.unilateral, isFalse);
      expect(sets(c)[0].side, SetSide.left, reason: 'so wurde er absolviert');
      expect([for (final s in sets(c).skip(1)) s.side], everyElement(isNull));
    });

    test('toDraft schreibt die Seite', () async {
      final (c, n) = await loaded();
      n.setUnilateral(0, true);
      final ids = [for (final s in sets(c)) s.id];
      for (final id in ids.take(2)) {
        n.updateReps(0, id, '8');
        n.toggleSet(0, id);
      }

      final draft = WorkoutSessionController.toDraft(workout(c),
          userId: 'u', duration: const Duration(minutes: 30))!;
      expect([for (final s in draft.exercises.first.sets) s.side],
          [SetSide.left, SetSide.right]);
    });
  });

  group('Der Runner', () {
    Future<ProviderContainer> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: fixtureOverrides,
        child: MaterialApp(
          theme: AtemTheme.dark,
          locale: const Locale('de'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const WorkoutRunnerScreen(start: start),
        ),
      ));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
          tester.element(find.byType(WorkoutRunnerScreen)));
    }

    Future<void> fillAndTick(
        WidgetTester tester, ProviderContainer c, int index) async {
      final n = c.read(workoutSessionProvider(start).notifier);
      n.updateReps(0, sets(c)[index].id, '8');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Satz ${index + 1} abschließen'));
      await tester.pumpAndSettle();
    }

    testWidgets('fragt nach dem Abhaken, und eine Wahl schliesst',
        (tester) async {
      final handle = tester.ensureSemantics();
      final c = await pump(tester);
      expect(find.text('Wie schwer war Satz 1?'), findsNothing);

      await fillAndTick(tester, c, 0);
      expect(find.text('Wie schwer war Satz 1?'), findsOneWidget);
      expect(find.bySemanticsLabel('Anstrengung von Satz 1'), findsOneWidget);
      // Nichts vorgewählt.
      expect(sets(c)[0].rpe, isNull);

      await tester
          .tap(find.bySemanticsLabel('RPE 8, noch 2 Wiederholungen möglich'));
      await tester.pumpAndSettle();

      expect(sets(c)[0].rpe, 8);
      expect(find.text('Wie schwer war Satz 1?'), findsNothing);
      // Die Kapsel steht in der Zeile — mit dem Wort, nicht nur dem Punkt.
      expect(find.text('RPE 8'), findsOneWidget);
      expect(find.text('harter Satz'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('die Kapsel öffnet erneut, „keine Angabe" löscht',
        (tester) async {
      final handle = tester.ensureSemantics();
      final c = await pump(tester);
      await fillAndTick(tester, c, 0);
      await tester
          .tap(find.bySemanticsLabel('RPE 6, noch 4 Wiederholungen möglich'));
      await tester.pumpAndSettle();
      expect(find.text('harter Satz'), findsNothing, reason: 'unter 7');

      await tester
          .tap(find.bySemanticsLabel('Satz 1, RPE 6. Tippen zum Ändern'));
      await tester.pumpAndSettle();
      expect(find.text('Wie schwer war Satz 1?'), findsOneWidget);

      await tester
          .tap(find.bySemanticsLabel('Keine Anstrengung angeben für Satz 1'));
      await tester.pumpAndSettle();
      expect(sets(c)[0].rpe, isNull);
      expect(find.text('RPE 6'), findsNothing);
      handle.dispose();
    });

    testWidgets('1–5 klappen auf', (tester) async {
      final handle = tester.ensureSemantics();
      final c = await pump(tester);
      await fillAndTick(tester, c, 0);
      expect(find.bySemanticsLabel(RegExp('^RPE 3,')), findsNothing);

      await tester.tap(find.bySemanticsLabel('Stufen 1 bis 5 zeigen'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('^RPE 3,')));
      await tester.pumpAndSettle();
      expect(sets(c)[0].rpe, 3);
      handle.dispose();
    });

    testWidgets('der nächste Satz schliesst den Streifen ohne Angabe',
        (tester) async {
      final handle = tester.ensureSemantics();
      final c = await pump(tester);
      await fillAndTick(tester, c, 0);
      await fillAndTick(tester, c, 1);

      expect(find.text('Wie schwer war Satz 1?'), findsNothing);
      expect(find.text('Wie schwer war Satz 2?'), findsOneWidget);
      expect(sets(c)[0].rpe, isNull);
      handle.dispose();
    });

    testWidgets('der Schalter im Kopf zeigt L und R, Tippen wechselt',
        (tester) async {
      final handle = tester.ensureSemantics();
      final c = await pump(tester);

      await tester.tap(find.bySemanticsLabel('Seiten getrennt protokollieren'));
      await tester.pumpAndSettle();
      expect(workout(c).exercises.first.unilateral, isTrue);
      expect(find.text('L'), findsNWidgets(2));
      expect(find.text('R'), findsNWidgets(2));

      await tester.tap(find
          .bySemanticsLabel('Seite links, Satz 1. Tippen wechselt zu rechts'));
      await tester.pumpAndSettle();
      expect(sets(c)[0].side, SetSide.right);

      await tester.tap(find.bySemanticsLabel('Seiten getrennt protokollieren'));
      await tester.pumpAndSettle();
      expect(find.text('L'), findsNothing);
      handle.dispose();
    });
  });
}
