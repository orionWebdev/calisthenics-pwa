import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/exercises/application/exercise_providers.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_form_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Stelle von `exerciseRepositoryProvider` in `fixtureOverrides`.
const _exerciseOverrideIndex = 4;

/// „Je Seite trainiert" (18.09.2026) — Schalter im Formular, Zusatz im Detail.
void main() {
  const own = Exercise(
    id: 'curl',
    name: 'Kurzhantel-Curl',
    source: ExerciseSource.own,
    muscleGroups: [MuscleGroup.biceps],
    equipment: ['Kurzhantel'],
    difficulty: 2,
  );
  const ownOneSided = Exercise(
    id: 'curl1',
    name: 'Einarmiger Curl',
    source: ExerciseSource.own,
    muscleGroups: [MuscleGroup.biceps],
    equipment: ['Kurzhantel'],
    difficulty: 2,
    unilateral: true,
  );

  Future<FakeExerciseRepository> pump(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(361, 900),
    double scale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repo = FakeExerciseRepository();
    await tester.pumpWidget(ProviderScope(
      // fixtureOverrides trägt schon ein FakeExerciseRepository — ersetzt,
      // nicht doppelt, damit die gespeicherten Entwürfe hier ankommen.
      overrides: [
        for (final o in fixtureOverrides)
          if (fixtureOverrides.indexOf(o) != _exerciseOverrideIndex) o,
        exerciseRepositoryProvider.overrideWithValue(repo),
        // Der Auth-Strom hat beim ersten `ref.read` im Speichern noch keinen
        // Wert — ohne diese Festlegung bräche `_save` still ab.
        currentUserIdProvider.overrideWithValue('u'),
      ],
      child: MaterialApp(
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
        home: home,
      ),
    ));
    await tester.pumpAndSettle();
    return repo;
  }

  /// Das Formular ist ein ListView — was unterhalb liegt, wird erst gebaut,
  /// wenn es in Sicht kommt.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) =>
      tapVisible(tester, find.text('Speichern').last);

  group('Formular', () {
    testWidgets('Einschalten landet als unilateral: true im Entwurf',
        (tester) async {
      final repo = await pump(tester, const ExerciseFormScreen(original: own));
      await reveal(tester, find.text('Je Seite trainiert'));
      expect(find.text('Je Seite trainiert'), findsOneWidget,
          reason: 'Ausrüstung ist gefüllt, die Zusatzangaben also offen');
      await tapVisible(tester, find.text('Je Seite trainiert'));
      await save(tester);
      expect(repo.saved.single.unilateral, isTrue);
    });

    testWidgets('Vorbelegung beim Bearbeiten und Ausschalten wird gespeichert',
        (tester) async {
      final repo =
          await pump(tester, const ExerciseFormScreen(original: ownOneSided));
      await reveal(tester, find.text('Je Seite trainiert'));
      expect(
        find.bySemanticsLabel('Je Seite trainiert, AN'),
        findsOneWidget,
        reason: 'Vorbelegt aus der bearbeiteten Übung',
      );
      await tapVisible(tester, find.text('Je Seite trainiert'));
      expect(find.bySemanticsLabel('Je Seite trainiert, AUS'), findsOneWidget);
      await save(tester);
      expect(repo.saved.single.unilateral, isFalse);
    });

    testWidgets('ohne Berühren bleibt es aus', (tester) async {
      final repo = await pump(tester, const ExerciseFormScreen(original: own));
      await save(tester);
      expect(repo.saved.single.unilateral, isFalse);
    });

    testWidgets('200 % auf 320 dp läuft nicht über', (tester) async {
      await pump(tester, const ExerciseFormScreen(original: ownOneSided),
          size: const Size(320, 800), scale: 2.0);
      await reveal(tester, find.text('Je Seite trainiert'));
      expect(tester.takeException(), isNull);
    });
  });

  group('Detail', () {
    testWidgets('einseitige Übung trägt „je Seite" in der Metazeile',
        (tester) async {
      await pump(tester, const ExerciseDetailScreen(exercise: ownOneSided));
      expect(find.textContaining('je Seite'), findsOneWidget);
    });

    testWidgets('beidseitige und kuratierte Übungen zeigen nichts',
        (tester) async {
      await pump(tester, const ExerciseDetailScreen(exercise: own));
      expect(find.textContaining('je Seite'), findsNothing);
      await pump(
          tester, ExerciseDetailScreen(exercise: fixtureExercises.first));
      expect(find.textContaining('je Seite'), findsNothing);
    });
  });
}
