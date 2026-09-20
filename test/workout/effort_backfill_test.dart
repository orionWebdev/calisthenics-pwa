import 'dart:io';

import 'package:atem/core/theme/theme.dart';
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

/// Weiterspringen ohne Angabe und Nachtragen (20.09.2026).
///
/// Bis heute wartete der Runner nach dem letzten Satz einer Übung auf eine
/// Antwort, die **freiwillig** ist: Wer nichts angeben wollte, musste „keine
/// Angabe" tippen, um weiterzukommen. Jetzt springt er sofort weiter — und
/// damit die Frage dabei nicht verloren geht, steht sie als „Anstrengung
/// eintragen" unter dem Satz.
void main() {
  const start = WorkoutStart(planId: 'p1');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

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

  ActiveWorkout workout(ProviderContainer c) =>
      c.read(workoutSessionProvider(start)).value!;

  List<WorkoutSet> sets(ProviderContainer c, [int exercise = 0]) =>
      workout(c).exercises[exercise].sets;

  Future<void> tick(WidgetTester tester, ProviderContainer c, int i) async {
    c.read(workoutSessionProvider(start).notifier)
        .updateReps(0, sets(c)[i].id, '10');
    await tester.pumpAndSettle();
    final done = find.bySemanticsLabel('Satz ${i + 1} abschließen');
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done);
    await tester.pumpAndSettle();
  }

  testWidgets('der letzte Satz einer Übung springt ohne Angabe weiter',
      (tester) async {
    final handle = tester.ensureSemantics();
    final c = await pump(tester);
    final count = sets(c).length;

    for (var i = 0; i < count - 1; i++) {
      await tick(tester, c, i);
      // Zwischendurch fragt der Streifen weiter — dort zieht nichts weg.
      expect(find.text('Wie schwer war Satz ${i + 1}?'), findsOneWidget);
    }

    expect(find.bySemanticsLabel(RegExp('^Übung 1 von')), findsOneWidget);
    await tick(tester, c, count - 1);

    expect(find.bySemanticsLabel(RegExp('^Übung 2 von')), findsOneWidget,
        reason: 'ohne Angabe weiter zur nächsten Übung');
    expect(find.text('Wie schwer war Satz $count?'), findsNothing,
        reason: 'kein Streifen, der mit der Übung wegzieht');
    expect(sets(c)[count - 1].rpe, isNull);
    handle.dispose();
  });

  testWidgets('ein Satz ohne Angabe bietet das Nachtragen an', (tester) async {
    final handle = tester.ensureSemantics();
    final c = await pump(tester);

    expect(find.text('Anstrengung eintragen'), findsNothing,
        reason: 'vor dem Abhaken gibt es nichts nachzutragen');

    await tick(tester, c, 0);
    // Der Streifen steht offen; die Wahl „keine Angabe" schliesst ihn.
    await tester.tap(find.bySemanticsLabel('Keine Anstrengung angeben für '
        'Satz 1'));
    await tester.pumpAndSettle();

    final add = find.bySemanticsLabel('Satz 1, Anstrengung eintragen');
    expect(add, findsOneWidget);

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Wie schwer war Satz 1?'), findsOneWidget);

    await tester
        .tap(find.bySemanticsLabel('RPE 8, noch 2 Wiederholungen möglich'));
    await tester.pumpAndSettle();

    expect(sets(c)[0].rpe, 8);
    expect(find.text('Anstrengung eintragen'), findsNothing,
        reason: 'nachgetragen — jetzt steht die Angabe da');
    expect(find.text('RPE 8'), findsOneWidget);
    handle.dispose();
  });
}
