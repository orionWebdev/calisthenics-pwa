import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/exercise_history.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/workout/presentation/widgets/set_history_drop.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Satzhistorie im Runner (23.09.2026).
StrengthSession _session(String id, DateTime date, List<LoggedSet> sets) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      duration: const Duration(minutes: 40),
      exercises: [LoggedExercise(exerciseId: 'bench', sets: sets)],
    );

final _sessions = [
  _session('a', DateTime(2026, 9, 21), const [
    LoggedSet(reps: 8, weight: 80),
    LoggedSet(reps: 7, weight: 80),
    LoggedSet(reps: 6, weight: 80),
    LoggedSet(reps: 6, weight: 77.5),
  ]),
  _session('b', DateTime(2026, 9, 14), const [
    LoggedSet(reps: 8, weight: 77.5),
    LoggedSet(reps: 8, weight: 77.5),
    LoggedSet(reps: 7, weight: 77.5),
  ]),
];

Future<void> _pump(WidgetTester tester, List<TrainingSession> sessions,
    {bool reduced = false}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sessionsProvider.overrideWithValue(AsyncData(sessions)),
    ],
    child: MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      // Wie im Runner: Stufe Fokus.
      home: const AtemReceiptScope(
        stage: AtemReceiptStage.focus,
        child: Scaffold(
          body: SingleChildScrollView(
            child: SetHistoryDrop(exerciseId: 'bench', exerciseName: 'Bankdrücken'),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

bool _sweeping(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .any((p) => p.foregroundPainter.runtimeType.toString() == '_SweepPainter');

void main() {
  test('höchstens sechs Sätze, die jüngste Einheit ganz', () {
    final history = ExerciseHistory.of(_sessions, 'bench');
    final groups = recentSets(history, 6);
    expect(groups.map((g) => g.sets.length), [4, 2]);
    expect(groups.first.date, DateTime(2026, 9, 21));
  });

  testWidgets('ohne Verlauf kein Knopf', (tester) async {
    await _pump(tester, const []);
    expect(find.byType(AtemTappable), findsNothing);
  });

  testWidgets('der Knopf klappt die Sätze auf — mit Lichtkante, auch im Fokus',
      (tester) async {
    await _pump(tester, _sessions);
    expect(find.text('FRÜHERE SÄTZE'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Frühere Sätze zeigen: Bankdrücken'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_sweeping(tester), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('FRÜHERE SÄTZE'), findsOneWidget);
    expect(find.text('Satz 1 · 8 × 80 kg'), findsOneWidget);
    expect(find.text('Satz 2 · 8 × 77,5 kg'), findsOneWidget);
    // Die dritte Einheit vom 14. Sept. fällt weg: 4 + 2 = 6.
    expect(find.textContaining('7 × 77,5'), findsNothing);
    expect(_sweeping(tester), isFalse);
    expect(find.bySemanticsLabel('Frühere Sätze ausblenden: Bankdrücken'),
        findsOneWidget);
  });

  testWidgets('die Kante läuft bei jedem Öffnen, nicht nur beim ersten',
      (tester) async {
    await _pump(tester, _sessions);
    for (var round = 0; round < 2; round++) {
      await tester.tap(find.bySemanticsLabel(
          RegExp('^Frühere Sätze zeigen')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_sweeping(tester), isTrue, reason: 'Öffnen Nr. ${round + 1}');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(
          RegExp('^Frühere Sätze ausblenden')));
      await tester.pump();
      // Zuklappen hat keine Kante.
      expect(_sweeping(tester), isFalse);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('bei „Animationen reduzieren" keine Kante', (tester) async {
    await _pump(tester, _sessions, reduced: true);
    await tester.tap(find.bySemanticsLabel('Frühere Sätze zeigen: Bankdrücken'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_sweeping(tester), isFalse);
    expect(find.text('FRÜHERE SÄTZE'), findsOneWidget);
  });
}
