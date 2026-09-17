import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/history/domain/muscle_balance.dart';
import 'package:atem/features/history/presentation/screens/muscle_balance_screen.dart';
import 'package:atem/features/history/presentation/widgets/muscle_balance_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:atem/features/exercises/application/exercise_providers.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MuscleShare _share(MuscleGroup muscle, int sets, int? days) => MuscleShare(
      muscle: muscle,
      sets: sets,
      volume: 0,
      exerciseIds: const {'x'},
      lastSetDaysAgo: days,
    );

const _enough = MuscleBalance(
  shares: [],
  windowDays: 56,
  sessionsInWindow: 18,
  sessionsCounted: 14,
  sessionsWithoutExercises: 4,
  unresolvedExerciseIds: {},
);

MuscleBalance _full() => MuscleBalance(
      shares: [
        _share(MuscleGroup.quads, 48, 5),
        _share(MuscleGroup.back, 46, 4),
        _share(MuscleGroup.chest, 40, 2),
        _share(MuscleGroup.core, 32, 3),
        _share(MuscleGroup.shoulders, 30, 6),
        _share(MuscleGroup.biceps, 21, 8),
        _share(MuscleGroup.triceps, 21, 8),
        _share(MuscleGroup.arms, 16, 12),
        _share(MuscleGroup.calves, 14, 23),
      ],
      windowDays: _enough.windowDays,
      sessionsInWindow: _enough.sessionsInWindow,
      sessionsCounted: _enough.sessionsCounted,
      sessionsWithoutExercises: _enough.sessionsWithoutExercises,
      unresolvedExerciseIds: const {},
    );

MuscleBalance _thin() => MuscleBalance(
      shares: [_share(MuscleGroup.back, 10, 2)],
      windowDays: 56,
      sessionsInWindow: 6,
      sessionsCounted: 5,
      sessionsWithoutExercises: 1,
      unresolvedExerciseIds: const {},
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double scale = 1.0,
  double width = 361,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionsProvider.overrideWith((_) => const AsyncValue.data([])),
        exercisesProvider.overrideWith((_) => Stream.value(const [])),
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
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Kachel', () {
    testWidgets('zeigt Titel, Fenster und Grundlage als ein Knoten',
        (tester) async {
      final handle = tester.ensureSemantics();
      var opened = false;
      await _pump(
        tester,
        MuscleBalanceTile(balance: _full(), onOpen: () => opened = true),
      );

      expect(find.text('Muskelbalance'), findsOneWidget);
      expect(find.text('8 Wochen'), findsOneWidget);
      expect(
          find.text('268 Sätze · 14 von 18 Kraft-Einheiten'), findsOneWidget);
      // Die Tabelle steht nicht in der Kachel, nur auf der Unterseite.
      expect(find.text('Quadrizeps'), findsNothing);

      expect(
        find.bySemanticsLabel(
          'Muskelbalance, 268 Sätze · 14 von 18 Kraft-Einheiten, 8 Wochen, '
          'öffnet Details',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Muskelbalance'));
      expect(opened, isTrue);
      handle.dispose();
    });

    testWidgets('öffnet ohne Rückruf die Unterseite', (tester) async {
      await _pump(tester, MuscleBalanceTile(balance: _full()));
      await tester.tap(find.text('Muskelbalance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'MuscleBalanceScreen'),
        findsOneWidget,
      );
    });

    testWidgets('unter der Schwelle Fortschritt statt Verteilung',
        (tester) async {
      await _pump(tester, MuscleBalanceTile(balance: _thin()));
      expect(find.text('5 / 8 · noch 3 Einheiten'), findsOneWidget);
      expect(find.text('Muskelbalance'), findsOneWidget);
    });

    testWidgets('ohne Einheit im Fenster rendert sie nicht', (tester) async {
      const none = MuscleBalance(
        shares: [],
        windowDays: 56,
        sessionsInWindow: 0,
        sessionsCounted: 0,
        sessionsWithoutExercises: 0,
        unresolvedExerciseIds: {},
      );
      await _pump(tester, const MuscleBalanceTile(balance: none));
      expect(find.text('Muskelbalance'), findsNothing);
    });

    testWidgets('mit alwaysShow ohne Einheit der dünne Zustand 0 / 8',
        (tester) async {
      const none = MuscleBalance(
        shares: [],
        windowDays: 56,
        sessionsInWindow: 0,
        sessionsCounted: 0,
        sessionsWithoutExercises: 0,
        unresolvedExerciseIds: {},
      );
      await _pump(
          tester, const MuscleBalanceTile(balance: none, alwaysShow: true));
      expect(find.text('Muskelbalance'), findsOneWidget);
      expect(find.text('0 / 8 · noch 8 Einheiten'), findsOneWidget);
      // Weiter antippbar: öffnet die Unterseite.
      await tester.tap(find.text('Muskelbalance'));
      await tester.pumpAndSettle();
      expect(find.byType(MuscleBalanceScreen), findsOneWidget);
    });

    testWidgets('alwaysShow mit Daten ändert nichts', (tester) async {
      await _pump(
          tester, MuscleBalanceTile(balance: _thin(), alwaysShow: true));
      expect(find.text('5 / 8 · noch 3 Einheiten'), findsOneWidget);
    });

    testWidgets('alwaysShow ohne Einheit bei 200 % auf 320 dp', (tester) async {
      const none = MuscleBalance(
        shares: [],
        windowDays: 56,
        sessionsInWindow: 0,
        sessionsCounted: 0,
        sessionsWithoutExercises: 0,
        unresolvedExerciseIds: {},
      );
      await _pump(
          tester, const MuscleBalanceTile(balance: none, alwaysShow: true),
          scale: 2, width: 320);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bei 200 % auf 320 dp ohne Überlauf', (tester) async {
      await _pump(tester, MuscleBalanceTile(balance: _full()),
          scale: 2, width: 320);
      expect(tester.takeException(), isNull);
    });
  });

  group('Unterseite', () {
    testWidgets('eine Zeile je Muskel mit Anteil, Sätzen und Abstand',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, MuscleBalanceCard(balance: _full()));

      expect(find.text('Quadrizeps'), findsOneWidget);
      expect(find.text('48 S'), findsOneWidget);
      expect(find.text('23 T'), findsOneWidget);
      expect(find.text('ANTEIL   SÄTZE   ZULETZT VOR'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Quadrizeps, 18%, Sätze 48, zuletzt 5 T'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('längste Abstände in Tagen, längster zuerst', (tester) async {
      await _pump(tester, MuscleGapsCard(balance: _full()));
      expect(find.text('Längste Abstände'), findsOneWidget);
      final days = tester
          .widgetList<Text>(find.textContaining('Tage'))
          .map((t) => t.data)
          .toList();
      expect(days, ['23 Tage', '12 Tage', '8 Tage']);
    });

    testWidgets('zu wenig Daten: Satz, Fortschritt und Begründung',
        (tester) async {
      await _pump(tester, MuscleBalanceCard(balance: _thin()));
      expect(find.textContaining('Noch zu wenig Grundlage'), findsOneWidget);
      expect(find.text('5 / 8 · noch 3 Einheiten'), findsOneWidget);
      // Die Begründung steht seit 17.09.2026 hinter dem ⓘ.
      expect(find.textContaining('schwankt'), findsNothing);
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.textContaining('schwankt'), findsOneWidget);
      await _pump(tester, MuscleGapsCard(balance: _thin()));
      expect(find.text('Längste Abstände'), findsNothing);
    });

    testWidgets('ab 160 % wird die Zeile zweizeilig, ohne Überlauf',
        (tester) async {
      await _pump(
        tester,
        Column(children: [
          MuscleBalanceCard(balance: _full()),
          MuscleGapsCard(balance: _full()),
        ]),
        scale: 2,
        width: 320,
      );
      expect(tester.takeException(), isNull);
      final name = tester.getTopLeft(find.text('Rücken'));
      final percent = tester.getTopLeft(find.text('17%'));
      expect(percent.dy, greaterThan(name.dy),
          reason: 'Werte stehen unter dem Namen');
    });
  });
}
