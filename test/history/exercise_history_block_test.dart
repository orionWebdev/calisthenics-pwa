import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:atem/features/history/domain/exercise_history.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/widgets/exercise_history_block.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

final _today = DateTime(2026, 8, 27);

StrengthSession _session(String id, DateTime date, List<LoggedSet> sets,
        {String exerciseId = 'bench'}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      exercises: [LoggedExercise(exerciseId: exerciseId, sets: sets)],
    );

/// [count] Ausführungen im Wochenabstand, die letzte am 24.08.; das
/// Gewicht steigt, die vorletzte ist der Bestwert.
ExerciseHistory _bench(int count) {
  final sessions = <TrainingSession>[
    for (var i = 0; i < count; i++)
      _session(
        's$i',
        DateTime(2026, 8, 24).subtract(Duration(days: 7 * (count - 1 - i))),
        [
          for (var s = 0; s < 4; s++)
            LoggedSet(
              reps: 8,
              weight: i == count - 2 ? 85 : 70.0 + i * 2.5,
            ),
        ],
      ),
  ];
  return ExerciseHistory.of(sessions, 'bench');
}

Future<void> _pump(WidgetTester tester, ExerciseHistory history,
    {double scale = 1.0, Size size = const Size(360, 800)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    locale: const Locale('de'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(scale),
        disableAnimations: true,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ExerciseHistoryBlock(
            history: history,
            reference: _today,
            languageTag: 'de',
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Stufen des Verlaufsblocks (Board 09, A4)', () {
    testWidgets('0 Ausführungen: der Block fehlt ganz', (tester) async {
      await _pump(tester, ExerciseHistory.of(const [], 'bench'));
      expect(find.text('Du mit dieser Übung'), findsNothing);
    });

    testWidgets('1 Ausführung: Damals, kein Bestwert, keine Kurve',
        (tester) async {
      await _pump(tester, _bench(1));
      expect(find.text('Du mit dieser Übung'), findsOneWidget);
      expect(find.text('1×'), findsOneWidget);
      expect(find.text('DAMALS'), findsOneWidget);
      expect(find.text('4 × 8 · 70 kg'), findsOneWidget);
      // Der Satz, warum es nichts davon gibt, steht seit 17.09.2026 hinter
      // dem ⓘ.
      expect(find.textContaining('aus einer Ausführung folgt keins davon'),
          findsNothing);
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.textContaining('aus einer Ausführung folgt keins davon'),
          findsOneWidget);
      expect(find.text('BESTWERT'), findsNothing);
      expect(find.text('HÄUFIGKEIT'), findsNothing);
      expect(find.text('BESTES SATZGEWICHT'), findsNothing);
    });

    testWidgets('2 bis 4 Ausführungen: Kacheln, keine Kurve', (tester) async {
      await _pump(tester, _bench(3));
      expect(find.text('ZULETZT'), findsOneWidget);
      expect(find.text('BESTWERT'), findsOneWidget);
      expect(find.text('HÄUFIGKEIT'), findsOneWidget);
      expect(find.text('VOLUMEN'), findsOneWidget);
      expect(find.text('3×'), findsOneWidget);
      expect(find.text('BESTES SATZGEWICHT'), findsNothing);
    });

    testWidgets('ab 5 Ausführungen: mit Kurve, Enden und Legende',
        (tester) async {
      await _pump(tester, _bench(6));
      expect(find.text('BESTES SATZGEWICHT'), findsOneWidget);
      expect(find.text('6 Einheiten'), findsOneWidget);
      expect(find.text('Ring markiert den Bestwert'), findsOneWidget);
      expect(find.textContaining('85 kg'), findsWidgets);
      // Nenner der Häufigkeit.
      expect(find.textContaining('6× in'), findsOneWidget);
    });
  });

  group('Vorlesen', () {
    testWidgets('jede Kachel ist ein Knoten mit ausgeschriebenen Einheiten',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _bench(6));

      final best = find.bySemanticsLabel(RegExp(r'^Bestwert, 85 Kilogramm'));
      expect(best, findsOneWidget);
      final label = tester.getSemantics(best).label;
      expect(label, contains('4 mal 8'));
      expect(label, contains('am '));
      expect(label, isNot(contains('×')));
      expect(label, isNot(contains('kg')));

      // Die Kurve: ein Knoten mit Anfang, Ende und Bestwert.
      final curve = find.bySemanticsLabel(RegExp('Verlauf des besten'));
      expect(curve, findsOneWidget);
      expect(
          tester.getSemantics(curve).label, contains('Bestwert 85 Kilogramm'));
      handle.dispose();
    });
  });

  group('Körpergewicht', () {
    testWidgets('ohne Gewicht nie „0 kg" und keine Volumenkachel',
        (tester) async {
      final sessions = <TrainingSession>[
        for (var i = 0; i < 5; i++)
          _session('b$i', DateTime(2026, 8, 1 + i * 5),
              [LoggedSet(reps: 8 + i), const LoggedSet(reps: 8)],
              exerciseId: 'push'),
      ];
      await _pump(tester, ExerciseHistory.of(sessions, 'push'));
      expect(find.textContaining('0 kg'), findsNothing);
      expect(find.text('VOLUMEN'), findsNothing);
      expect(find.text('WIEDERHOLUNGEN JE EINHEIT'), findsOneWidget);
      expect(find.text('20 Wdh'), findsOneWidget);
    });
  });

  group('Grosse Schrift', () {
    testWidgets('200 % auf 320 dp: einspaltig, kein Überlauf', (tester) async {
      await _pump(tester, _bench(6), scale: 2.0, size: const Size(320, 2400));
      expect(tester.takeException(), isNull);
      final last = tester.getTopLeft(find.text('ZULETZT'));
      final best = tester.getTopLeft(find.text('BESTWERT'));
      expect(best.dx, last.dx, reason: 'Kacheln stehen untereinander');
    });
  });

  group('Kopf des Übungsdetails', () {
    testWidgets('Zurück-Knopf, Name, Gerät · Schwierigkeit, Muskelpillen',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      const exercise = Exercise(
        id: 'bench_press',
        name: 'Bankdrücken',
        source: ExerciseSource.curated,
        primaryMuscles: [MuscleGroup.chest],
        secondaryMuscles: [MuscleGroup.triceps],
        equipment: ['Langhantel'],
        difficulty: 3,
      );
      await tester.pumpWidget(ProviderScope(
        overrides: fixtureOverrides,
        child: MaterialApp(
          theme: AtemTheme.dark,
          locale: const Locale('de'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          // Die Aurora hinter dem Kopf ist eine Dauerschleife (Board 18b);
          // ohne „Animationen reduzieren" käme pumpAndSettle nie zur Ruhe.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const ExerciseDetailScreen(exercise: exercise),
                    ),
                  ),
                  child: const Text('öffnen'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Bankdrücken'), findsOneWidget);
      expect(find.textContaining('Langhantel · '), findsOneWidget);
      expect(find.text('Brust'), findsOneWidget);
      expect(find.text('Trizeps'), findsOneWidget);

      final back = find.bySemanticsLabel(RegExp('^Zurück'));
      expect(back, findsOneWidget);
      expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Bankdrücken'), findsNothing);
      expect(find.text('öffnen'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Domäne', () {
    test('weeksSpan ist der Nenner der Häufigkeit', () {
      final history = _bench(6);
      // 35 Tage zwischen erster Ausführung und 24.08., Stichtag 27.08. → 38.
      expect(history.frequencyPerWeek(_today), isNotNull);
      expect(history.weeksSpan(_today), 5);
      expect(_bench(1).weeksSpan(_today), isNull);
    });
  });
}
