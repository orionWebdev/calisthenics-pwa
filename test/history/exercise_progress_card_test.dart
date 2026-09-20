import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/exercises/application/exercise_providers.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/widgets/exercise_progress_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _ref = DateTime(2026, 9, 16);
DateTime _daysAgo(int n) => DateTime(_ref.year, _ref.month, _ref.day - n, 10);

StrengthSession _s(String id, int daysAgo, Map<String, List<LoggedSet>> ex) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: _daysAgo(daysAgo),
      createdAt: _daysAgo(daysAgo),
      bodyweight: true,
      exercises: [
        for (final e in ex.entries)
          LoggedExercise(exerciseId: e.key, sets: e.value),
      ],
    );

const _pullUp =
    Exercise(id: 'pull_up', name: 'Klimmzug', source: ExerciseSource.curated);

Future<void> _pump(
  WidgetTester tester,
  List<TrainingSession> sessions, {
  double scale = 1.0,
  double width = 361,
  List<Exercise> exercises = const [_pullUp],
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionsProvider.overrideWith((_) => AsyncValue.data(sessions)),
        exercisesProvider.overrideWith((_) => Stream.value(exercises)),
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
            child: ExerciseProgressCard(sessions: sessions, reference: _ref),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _once = [
  _s('a', 2, {
    'pull_up': [
      const LoggedSet(reps: 8, rawType: 'warmup'),
      const LoggedSet(reps: 9)
    ]
  }),
];

final _flat = [
  _s('a', 10, {
    'pull_up': [const LoggedSet(reps: 9)]
  }),
  _s('b', 2, {
    'pull_up': [const LoggedSet(reps: 9)]
  }),
];

final _better = [
  _s('a', 10, {
    'pull_up': [const LoggedSet(reps: 8)]
  }),
  _s('b', 2, {
    'pull_up': [const LoggedSet(reps: 9)]
  }),
];

void main() {
  testWidgets('unter der Schwelle: Titel, Bedingung, Fortschritt, kein Wert',
      (tester) async {
    await _pump(tester, _once);
    expect(find.text('Fortschritte'), findsOneWidget);
    expect(find.text('Ab der zweiten Ausführung einer Übung'),
        findsOneWidget);
    expect(find.text('1 von 2'), findsOneWidget);
    expect(find.textContaining('Wdh'), findsNothing);
  });

  testWidgets('genug Daten, kein Bestwert: Satz und Grundlage', (tester) async {
    await _pump(tester, _flat);
    expect(find.text('Kein neuer Bestwert in den letzten 4 Wochen.'),
        findsOneWidget);
    expect(find.text('1 Übung · 2 Einheiten'), findsOneWidget);
  });

  testWidgets('Zeile mit Wert, Vorher und einem Semantics-Knoten',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _better);
    expect(find.text('Klimmzug'), findsOneWidget);
    expect(find.text('9 Wdh'), findsOneWidget);
    expect(find.textContaining('vorher 8 Wdh'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(
          r'^Klimmzug, 9 Wiederholungen, vorher 8, 1 mehr, am \d+\. September, öffnet Übung$')),
      findsOneWidget,
    );
    // Die Richtung steht als Wort im Label, nie als Glyph.
    expect(find.bySemanticsLabel(RegExp('▲')), findsNothing);
    handle.dispose();
  });

  testWidgets('Tippen öffnet die Übung', (tester) async {
    await _pump(tester, _better);
    await tester.tap(find.text('Klimmzug'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
  });

  testWidgets('unbekannte Übung: ID als Name, nicht antippbar', (tester) async {
    await _pump(tester, _better, exercises: const []);
    expect(find.text('pull_up'), findsOneWidget);
    await tester.tap(find.text('pull_up'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsNothing);
  });

  testWidgets('200 % auf 320 dp ohne Überlauf', (tester) async {
    await _pump(tester, _better, scale: 2.0, width: 320);
    expect(tester.takeException(), isNull);
    await _pump(tester, _once, scale: 2.0, width: 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Erklärung ist hinter dem ⓘ', (tester) async {
    await _pump(tester, _better);
    expect(find.textContaining('neuen Bestwert gesetzt'), findsNothing);
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.textContaining('neuen Bestwert gesetzt'), findsOneWidget);
    expect(find.textContaining('Aufwärmsätze zählen nicht'), findsOneWidget);
  });
}
