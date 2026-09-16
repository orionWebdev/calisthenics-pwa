import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/domain/history_summary.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/widgets/month_strip.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Einheiten je Monat (16.09.2026): festes Fenster von sechs Monaten,
/// schmale Balken, nicht gemessen ≠ gemessen 0.
final _ref = DateTime(2026, 9, 16, 15);

StrengthSession _s(String id, DateTime date) => StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: true,
      exercises: const [
        LoggedExercise(exerciseId: 'pull_up', sets: [LoggedSet(reps: 8)]),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  List<TrainingSession> sessions, {
  double scale = 1.0,
  double width = 361,
  void Function(int, int)? onSelect,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
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
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MonthStrip(
            summary: HistorySummary.from(sessions, _ref),
            onSelect: onSelect,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MonthWindow', () {
    test('sechs Monate bis einschliesslich des Stichtags, älteste zuerst', () {
      final w = MonthWindow.compute([_s('a', DateTime(2026, 9, 14))], _ref);
      expect(w.slots.map((s) => s.month), [4, 5, 6, 7, 8, 9]);
      expect(w.slots.last.isCurrent, isTrue);
      expect(w.sessions, 1);
      expect(w.trainingDays, 1);
    });

    test('Monate vor der ersten Einheit sind nicht gemessen', () {
      final w = MonthWindow.compute([
        _s('a', DateTime(2026, 7, 3)),
        _s('b', DateTime(2026, 9, 14)),
      ], _ref);
      expect([for (final s in w.slots) s.measured],
          [false, false, false, true, true, true]);
      expect(w.slots[4].count, 0, reason: 'August gemessen, aber leer');
    });

    test('Jahreswechsel im Fenster', () {
      final w = MonthWindow.compute(
          [_s('a', DateTime(2026, 1, 5))], DateTime(2026, 2, 10));
      expect(w.slots.map((s) => '${s.year}-${s.month}'),
          ['2025-9', '2025-10', '2025-11', '2025-12', '2026-1', '2026-2']);
    });

    test('zwei Einheiten am selben Tag sind ein Trainingstag', () {
      final w = MonthWindow.compute([
        _s('a', DateTime(2026, 9, 14, 8)),
        _s('b', DateTime(2026, 9, 14, 18)),
      ], _ref);
      expect(w.sessions, 2);
      expect(w.trainingDays, 1);
    });
  });

  group('MonthStrip', () {
    testWidgets('ein einziger Tag: schmaler Balken, nicht die volle Breite',
        (tester) async {
      await _pump(tester, [_s('a', DateTime(2026, 9, 14))]);
      final bar = find.byKey(const ValueKey('month-bar'));
      expect(bar, findsOneWidget);
      expect(tester.getSize(bar).width, MonthStrip.barWidth);
      expect(tester.getSize(bar).height, MonthStrip.chartHeight,
          reason: 'Der einzige Monat ist das Maximum');
      // Vor der ersten Einheit: weder Balken noch Strich.
      expect(find.byKey(const ValueKey('month-zero')), findsNothing);
    });

    testWidgets('gemessene Leermonate als Strich, Höhe relativ zum Maximum',
        (tester) async {
      await _pump(tester, [
        _s('a', DateTime(2026, 7, 3)),
        _s('b', DateTime(2026, 7, 10)),
        _s('c', DateTime(2026, 7, 20)),
        _s('d', DateTime(2026, 7, 28)),
        _s('e', DateTime(2026, 9, 14)),
      ]);
      expect(find.byKey(const ValueKey('month-zero')), findsOneWidget,
          reason: 'August');
      final bars = find.byKey(const ValueKey('month-bar'));
      expect(bars, findsNWidgets(2));
      final heights = [
        for (final e in bars.evaluate())
          tester.getSize(find.byWidget(e.widget)).height
      ]..sort();
      expect(heights.last, MonthStrip.chartHeight);
      expect(heights.first, MonthStrip.chartHeight / 4);
    });

    testWidgets('Tap nur auf Monate mit Einheiten', (tester) async {
      final taps = <String>[];
      await _pump(
        tester,
        [_s('a', DateTime(2026, 7, 3)), _s('b', DateTime(2026, 9, 14))],
        onSelect: (y, m) => taps.add('$y-$m'),
      );
      final l10n = AppL10n.of(tester.element(find.byType(MonthStrip)));
      expect(find.bySemanticsLabel(l10n.historyMonthOpenA11y('September', 1)),
          findsOneWidget);
      expect(find.bySemanticsLabel(l10n.historyMonthOpenA11y('August', 0)),
          findsNothing);

      await tester.tap(
          find.bySemanticsLabel(l10n.historyMonthOpenA11y('September', 1)));
      expect(taps, ['2026-9']);
    });

    testWidgets('der Streifen ist ein Knoten mit allen sechs Monaten',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, [_s('a', DateTime(2026, 9, 14))]);
      final l10n = AppL10n.of(tester.element(find.byType(MonthStrip)));
      final node = find.bySemanticsLabel(RegExp(
          '${l10n.historyMonthsLabel}.*April: nicht erfasst.*September: 1 Einheit'));
      expect(node, findsOneWidget);
      handle.dispose();
    });

    testWidgets('dünne Grundlage: kein Median, keine längste Pause',
        (tester) async {
      await _pump(tester, [
        _s('a', DateTime(2026, 9, 1)),
        _s('b', DateTime(2026, 9, 14)),
      ]);
      expect(find.textContaining('Median'), findsNothing);

      await _pump(tester, [
        _s('a', DateTime(2026, 8, 1)),
        _s('b', DateTime(2026, 8, 20)),
        _s('c', DateTime(2026, 9, 14)),
      ]);
      expect(find.textContaining('Median'), findsOneWidget);
    });

    testWidgets('auf 320 dp nur so viele Monate, wie 48-dp-Ziele passen',
        (tester) async {
      await _pump(
        tester,
        [_s('a', DateTime(2026, 9, 14))],
        width: 320,
        onSelect: (_, __) {},
      );
      final l10n = AppL10n.of(tester.element(find.byType(MonthStrip)));
      final shown = find.textContaining(RegExp(r'^\d Monate$'));
      expect(shown, findsOneWidget);
      final n = int.parse(tester.widget<Text>(shown).data!.split(' ').first);
      expect(n, lessThan(6));
      final button =
          find.bySemanticsLabel(l10n.historyMonthOpenA11y('September', 1));
      expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    });

    testWidgets('200 % Schrift auf 320 dp ohne Überlauf', (tester) async {
      await _pump(
        tester,
        [_s('a', DateTime(2026, 5, 3)), _s('b', DateTime(2026, 9, 14))],
        scale: 2.0,
        width: 320,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
