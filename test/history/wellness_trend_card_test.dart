import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/screens/session_detail_screen.dart';
import 'package:atem/features/history/presentation/widgets/wellness_trend_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

final _ref = DateTime(2026, 9, 16);

StrengthSession _s(int day, {int? before, int? after}) => StrengthSession(
      id: 's$day',
      userId: 'u',
      date: DateTime(2026, 9, day, 18),
      createdAt: DateTime(2026, 9, day, 18),
      bodyweight: true,
      preWorkoutReadiness: before,
      postWorkoutFeeling: after,
    );

Future<AppL10n> _pump(
  WidgetTester tester,
  Widget child, {
  double scale = 1.0,
  double width = 361,
  bool scroll = true,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides,
      child: MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: inner!,
        ),
        home: scroll
            ? Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [child],
                ),
              )
            : child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppL10n.of(tester.element(find.byType(Navigator).first));
}

void main() {
  group('WellnessTrendCard', () {
    testWidgets('unter fünf Paaren: Schwellen-Block, keine Punkte',
        (tester) async {
      final l10n = await _pump(
        tester,
        WellnessTrendCard(
          sessions: [
            _s(14, before: 2, after: 4),
            _s(15, before: 3),
          ],
          reference: _ref,
        ),
      );
      expect(find.byType(AtemThresholdBlock), findsOneWidget);
      expect(find.text(l10n.wellnessTrendTitle), findsOneWidget);
      expect(find.text(l10n.thresholdProgress(1, 5)), findsOneWidget);
      expect(find.text(l10n.wellnessTrendLegend), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('gefüllt: Punkte, Zählung, Grundlage mit Nenner',
        (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await _pump(
        tester,
        WellnessTrendCard(
          sessions: [
            _s(1, before: 2, after: 4),
            _s(2, before: 3, after: 5),
            _s(3, before: 3, after: 3),
            _s(4, before: 5, after: 2),
            _s(5, before: 1, after: 2),
            _s(6, before: 4),
            _s(7),
          ],
          reference: _ref,
        ),
      );
      expect(find.byType(AtemThresholdBlock), findsNothing);
      expect(find.text(l10n.wellnessTrendLegend), findsOneWidget);
      expect(find.text('▲ ${l10n.wellnessTrendHigher(3)}'), findsOneWidget);
      expect(find.text('▼ ${l10n.wellnessTrendLower(1)}'), findsOneWidget);
      expect(find.text(l10n.wellnessTrendBasis(5, 7)), findsOneWidget);
      // Seit 17.09.2026 hinter dem ⓘ: der Hinweis auf Einheiten mit nur
      // einer Angabe. Der Nenner verrät sie ohnehin.
      expect(find.text(l10n.wellnessTrendOnlyOne(1)), findsNothing);
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.text(l10n.wellnessTrendExplain), findsOneWidget);

      final labels = <String>[];
      void collect(SemanticsNode n) {
        labels.add(n.label);
        n.visitChildren((c) {
          collect(c);
          return true;
        });
      }

      collect(tester.getSemantics(find.byType(WellnessTrendCard)));
      expect(labels.any((l) => l.contains('▲') || l.contains('▼')), isFalse);
      // Die Zählzeile ist ein Knoten, ohne Glyphen.
      expect(find.bySemanticsLabel(l10n.wellnessTrendCountsA11y(3, 1, 1)),
          findsOneWidget);
      // Die Reihe ist ein Knoten mit den Paaren als Satz.
      final row = find.bySemanticsLabel(
          RegExp(r'^Vorher und nachher je Einheit, älteste zuerst\. '
              r'1\. September: vorher 2 müde, nachher 4 gut'));
      expect(row, findsOneWidget);
      handle.dispose();
    });

    testWidgets('200 % auf 320 dp ohne Überlauf, gefüllt und dünn',
        (tester) async {
      await _pump(
        tester,
        WellnessTrendCard(
          sessions: [
            for (var d = 1; d <= 14; d++) _s(d, before: (d % 5) + 1, after: 3),
          ],
          reference: _ref,
        ),
        scale: 2.0,
        width: 320,
      );
      expect(tester.takeException(), isNull);

      await _pump(
        tester,
        WellnessTrendCard(
            sessions: [_s(1, before: 2, after: 3)], reference: _ref),
        scale: 2.0,
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Einheitendetail', () {
    testWidgets('eine bekannte Übung öffnet das Übungsdetail', (tester) async {
      final handle = tester.ensureSemantics();
      final session = StrengthSession(
        id: 'x',
        userId: 'u',
        date: DateTime(2026, 8, 20, 18),
        createdAt: DateTime(2026, 8, 20, 18),
        bodyweight: true,
        duration: const Duration(minutes: 40),
        exercises: const [
          LoggedExercise(
            exerciseId: 'archer_push_up',
            sets: [LoggedSet(reps: 8), LoggedSet(reps: 7)],
          ),
          LoggedExercise(
            exerciseId: 'gibt_es_nicht',
            sets: [LoggedSet(reps: 5)],
          ),
        ],
      );
      final l10n = await _pump(tester, SessionDetailScreen(session: session),
          scroll: false);

      final name = find.text('Archer Push-up mit sehr langem Namen');
      await tester.scrollUntilVisible(name, 200,
          scrollable: find.byType(Scrollable).first);

      // Die Zeile öffnet ihre Sätze (Board 16, Platz 3). Der Weg zum
      // Übungsverlauf steht **in** der aufgeklappten Zeile — und nur bei einer
      // Übung, die der Bestand kennt.
      expect(find.text(l10n.detailExerciseHistory), findsNothing,
          reason: 'zugeklappt steht dort nur die Zeile');
      await tester.tap(name);
      await tester.pumpAndSettle();
      expect(find.text(l10n.detailExerciseHistory), findsOneWidget);
      expect(
        find.bySemanticsLabel(
            RegExp(r'^Archer Push-up mit sehr langem Namen, öffnet Übung')),
        findsOneWidget,
      );

      // Die unbekannte Übung bleibt Anzeige: ein Weg ins Leere wäre
      // schlimmer als keiner.
      await tester.tap(find.text('gibt_es_nicht'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.detailExerciseHistory), findsNothing,
          reason: 'es ist nur eine Zeile offen — und die kennt keinen Verlauf');

      await tester.tap(name);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.detailExerciseHistory));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseDetailScreen), findsOneWidget);
      expect(l10n.wellnessTrendOpenExercise('a'), 'a, öffnet Übung');
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });
}
