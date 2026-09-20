import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/exercises/application/exercise_providers.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/widgets/hard_sets_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _ref = DateTime(2026, 9, 18, 12);
DateTime _ago(int n) => DateTime(_ref.year, _ref.month, _ref.day - n, 18);

StrengthSession _s(int daysAgo, String id, List<LoggedSet> sets) =>
    StrengthSession(
      id: 's$daysAgo$id',
      userId: 'u',
      date: _ago(daysAgo),
      createdAt: _ago(daysAgo),
      bodyweight: false,
      exercises: [LoggedExercise(exerciseId: id, sets: sets)],
    );

const _bench = Exercise(
  id: 'bench',
  name: 'Bankdrücken',
  source: ExerciseSource.curated,
  primaryMuscles: [MuscleGroup.chest],
);
const _pullUp = Exercise(
  id: 'pull_up',
  name: 'Klimmzug',
  source: ExerciseSource.curated,
  primaryMuscles: [MuscleGroup.back],
);

LoggedSet _rpe(int rpe) => LoggedSet(reps: 8, rpe: rpe);

Future<void> _pump(
  WidgetTester tester,
  List<TrainingSession> sessions, {
  double scale = 1.0,
  double width = 361,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionsProvider.overrideWith((_) => AsyncValue.data(sessions)),
        exercisesProvider
            .overrideWith((_) => Stream.value(const [_bench, _pullUp])),
      ],
      child: MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: c!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HardSetsCard(sessions: sessions, reference: _ref),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 12 Sätze mit Angabe: 4 harte Brust, 3 harte Rücken, Rest leicht.
/// Davor: 2 harte Brust.
final _filled = [
  _s(0, 'bench', [_rpe(8), _rpe(8), _rpe(9), _rpe(7), _rpe(5), _rpe(5)]),
  _s(1, 'pull_up', [_rpe(8), _rpe(8), _rpe(8), _rpe(4), _rpe(4), _rpe(4)]),
  _s(8, 'bench', [_rpe(8), _rpe(8)]),
];

void main() {
  testWidgets('unter der Schwelle: Schwellenblock mit Fortschritt, keine Zahl',
      (tester) async {
    await _pump(tester, [
      _s(0, 'bench', [_rpe(8), _rpe(8), _rpe(6)]),
    ]);
    expect(find.byType(AtemThresholdBlock), findsOneWidget);
    expect(find.text('3 von 10'), findsOneWidget);
    expect(find.textContaining('Ab 10 Sätzen'), findsOneWidget);
  });

  testWidgets('gefüllt: Summe, Zeilen je Muskel, Grundlage mit Nenner',
      (tester) async {
    await _pump(tester, _filled);
    expect(find.byType(AtemThresholdBlock), findsNothing);
    expect(find.text('Harte Sätze'), findsOneWidget);
    expect(find.text('7'), findsOneWidget, reason: 'Summe 4 + 3');
    expect(find.text('4'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('7 harte von 12 Sätzen · 12 mit Angabe'), findsOneWidget);
  });

  testWidgets('Zeile ist ein Knoten, Richtung als Wort, kein Glyph im Label',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _filled);
    expect(
      find.bySemanticsLabel(
          RegExp(r'^Brust, 4 harte Sätze, 2 mehr als in den 7 Tagen davor$')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('[▲▼]')), findsNothing);
    handle.dispose();
  });

  testWidgets('Erklärung steht hinter dem ⓘ', (tester) async {
    await _pump(tester, _filled);
    expect(find.textContaining('Anstrengung 7 oder mehr auf der Skala'),
        findsNothing);
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.textContaining('Anstrengung 7 oder mehr auf der Skala'),
        findsOneWidget);
  });

  testWidgets('200 % Schrift auf 320 dp ohne Überlauf', (tester) async {
    await _pump(tester, _filled, scale: 2.0, width: 320);
    expect(tester.takeException(), isNull);
  });
}
