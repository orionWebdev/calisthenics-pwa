import 'dart:io';

import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
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

/// Der Session-Logger: übernommene Werte, Regler, Legende, Anleitung.
void main() {
  const start = WorkoutStart(planId: 'p1');

  setUp(() {
    // Der Zwischenstand-Speicher greift beim Abhaken auf `path_provider` zu.
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

  WorkoutExercise firstExercise(ProviderContainer c) =>
      c.read(workoutSessionProvider(start)).value!.exercises.first;

  group('Werte des letzten Satzes', () {
    test('wandern beim Abhaken in den nächsten Satz', () async {
      final (container, notifier) = await loaded();
      final sets = firstExercise(container).sets;

      notifier.updateWeight(0, sets[0].id, '62,5');
      notifier.updateReps(0, sets[0].id, '8');
      notifier.toggleSet(0, sets[0].id);

      final after = firstExercise(container).sets;
      expect(after[0].done, isTrue);
      expect(after[1].weight, '62,5');
      expect(after[1].reps, '8');
      // Übernächster Satz bleibt leer: übernommen wird einer weiter, nicht
      // in die ganze Übung.
      expect(after[2].weight, isEmpty);
    });

    test('überschreiben nie eine getippte Angabe', () async {
      final (container, notifier) = await loaded();
      final sets = firstExercise(container).sets;

      notifier.updateWeight(0, sets[1].id, '80');
      notifier.updateWeight(0, sets[0].id, '60');
      notifier.updateReps(0, sets[0].id, '8');
      notifier.toggleSet(0, sets[0].id);

      final after = firstExercise(container).sets;
      expect(after[1].weight, '80', reason: 'getippt schlägt übernommen');
      // Das leere Feld daneben wird trotzdem gefüllt.
      expect(after[1].reps, '8');
    });

    test('bleiben beim Entsperren stehen', () async {
      final (container, notifier) = await loaded();
      final sets = firstExercise(container).sets;

      notifier.updateWeight(0, sets[0].id, '60');
      notifier.toggleSet(0, sets[0].id);
      notifier.toggleSet(0, sets[0].id);

      final after = firstExercise(container).sets;
      expect(after[0].done, isFalse);
      expect(after[1].weight, '60');
    });

    test('sind als übernommen erkennbar, bis man sie anfasst', () async {
      final (container, notifier) = await loaded();
      final sets = firstExercise(container).sets;

      notifier.updateWeight(0, sets[0].id, '60');
      notifier.updateReps(0, sets[0].id, '8');
      expect(firstExercise(container).sets[0].carried, isFalse,
          reason: 'getippt ist nicht übernommen');

      notifier.toggleSet(0, sets[0].id);
      expect(firstExercise(container).sets[1].carried, isTrue);

      // Eine eigene Eingabe macht aus dem Vorschlag eine Angabe.
      notifier.updateWeight(0, sets[1].id, '65');
      expect(firstExercise(container).sets[1].carried, isFalse);
    });

    test('ein neuer Satz erbt auch die Haltezeit', () async {
      final (container, notifier) = await loaded();
      final sets = firstExercise(container).sets;

      notifier.updateHold(0, sets.last.id, '45');
      notifier.addSet(0);

      final after = firstExercise(container).sets;
      expect(after.length, sets.length + 1);
      expect(after.last.hold, '45');
    });
  });

  group('Der Runner', () {
    Future<void> pump(WidgetTester tester) async {
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
    }

    testWidgets('hat keinen Notizen-Knopf mehr', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(find.bySemanticsLabel('Session-Notizen öffnen'), findsNothing);
      // Pause und Beenden bleiben.
      expect(find.bySemanticsLabel('Training pausieren'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('öffnet das Eingabeblatt und übernimmt den Wert',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(find.byType(AtemStepPad), findsNothing);

      await tester.tap(find.bySemanticsLabel(RegExp('^KG, Satz 1')));
      await tester.pumpAndSettle();
      expect(find.byType(AtemStepPad), findsOneWidget);
      expect(find.text('GEWICHT · SATZ 1'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Wert erhöhen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ÜBERNEHMEN'));
      await tester.pumpAndSettle();

      expect(find.byType(AtemStepPad), findsNothing);
      // Der Wert steht jetzt in der Zeile, nicht mehr „—".
      expect(find.bySemanticsLabel(RegExp('^KG, Satz 1, keine Angabe')),
          findsNothing);
      handle.dispose();
    });

    testWidgets('ein leerer Satz wird nicht abgehakt, sondern geöffnet',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      await tester.tap(find.bySemanticsLabel('Satz 1 abschließen'));
      await tester.pumpAndSettle();

      // Statt eines Häkchens ohne Zahlen steht das Eingabeblatt da.
      expect(find.byType(AtemStepPad), findsOneWidget);
      expect(find.text('WIEDERHOLUNGEN · SATZ 1'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('erklärt die Satztypen als einzelne Pillen', (tester) async {
      await pump(tester);

      for (final label in [
        'Aufwärmsatz',
        'Normaler Satz',
        'Dropsatz',
        'Satz bis zum Muskelversagen',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('zeigt die Anleitung der Übung', (tester) async {
      await pump(tester);

      await tester.tap(find.text('FORM GUIDE'));
      await tester.pumpAndSettle();

      // Die Abschnitte aus dem Übungsbestand.
      expect(find.text('ANLEITUNG'), findsOneWidget);
      expect(find.text('Schritt eins'), findsOneWidget);
      expect(find.text('CUES'), findsOneWidget);
      expect(find.text('Brust raus'), findsOneWidget);
      expect(find.text('HÄUFIGE FEHLER'), findsOneWidget);
    });

    testWidgets('ohne Anleitung gibt es keinen Chip', (tester) async {
      await pump(tester);

      // Die zweite Übung des Plans zeigt auf eine Übung, die es nicht gibt —
      // und damit auf keine Anleitung.
      await tester.tap(find.bySemanticsLabel('Nächste Übung'));
      await tester.pumpAndSettle();

      expect(find.text('FORM GUIDE'), findsNothing);
    });
  });
}
