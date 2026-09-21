import 'package:atem/app/application/tab_providers.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/history/presentation/widgets/analysis_section.dart';
import 'package:atem/features/history/presentation/widgets/history_section.dart';
import 'package:atem/features/history/presentation/widgets/month_strip.dart';
import 'package:atem/features/history/presentation/widgets/statement_card.dart';
import 'package:atem/features/plans/presentation/widgets/plans_section.dart';
import 'package:atem/features/strength/presentation/screens/strength_screen.dart';
import 'package:atem/features/workout/presentation/widgets/train_section.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Der Kraft-Tab als One-Pager mit gehefteter Ortszeile (Board 13,
/// seit 20.09.2026).
void main() {
  late ProviderContainer container;

  Future<AppL10n> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(361, 780);
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
        home: StrengthScreen(onStart: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();
    final element = tester.element(find.byType(StrengthScreen));
    container = ProviderScope.containerOf(element);
    return AppL10n.of(element);
  }

  StrengthSegment segment() => container.read(appTabsProvider).strengthSegment;

  /// Die Unterkante der gehefteten Zeile — dort beginnt das Thema, in das
  /// gesprungen wurde.
  double barBottom(WidgetTester tester) =>
      tester.getRect(find.byType(AtemSectionBar)).bottom;

  /// Das eine Wort, das die Zeile gerade zeigt.
  String word(WidgetTester tester, AppL10n l10n) {
    for (final l in [
      l10n.segTrain,
      l10n.segHistory,
      l10n.segAnalysis,
      l10n.segPlans
    ]) {
      final finder = find.descendant(
          of: find.byType(AtemSectionBar), matching: find.text(l));
      if (finder.evaluate().isNotEmpty) return l;
    }
    return '';
  }

  /// Zeile antippen, Thema aus der Sprungliste wählen.
  Future<void> jumpTo(WidgetTester tester, String label) async {
    await tester.tap(find.byType(AtemSectionBar));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(AtemSectionJumpList), matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  Future<void> scrollBy(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(CustomScrollView), Offset(0, dy),
        warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('ein Wort, ein Zähler, kein Tab-Kopf', (tester) async {
    final l10n = await pump(tester);

    expect(word(tester, l10n), l10n.segTrain);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(segment(), StrengthSegment.train);

    // Die Zeile ist die Überschrift — ein Titel „Kraft" darüber wäre
    // derselbe Name zweimal (Board 13, Entscheidung 6).
    expect(find.text(l10n.tabStrength), findsNothing);
  });

  testWidgets('die vier Themen stehen vollständig in der Sprungliste',
      (tester) async {
    final l10n = await pump(tester);
    await tester.tap(find.byType(AtemSectionBar));
    await tester.pumpAndSettle();

    final ys = [
      for (final label in [
        l10n.segTrain,
        l10n.segHistory,
        l10n.segAnalysis,
        l10n.segPlans,
      ])
        tester
            .getTopLeft(find.descendant(
                of: find.byType(AtemSectionJumpList),
                matching: find.text(label)))
            .dy,
    ];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.text(l10n.sectionHere), findsOneWidget);
  });

  testWidgets('zwischen je zwei Themen liegt eine Fuge, am Ende der Abschluss',
      (tester) async {
    await pump(tester);
    // Drei Fugen zwischen den vier Themen, plus der Abschluss nach dem
    // letzten — Ende statt Ankündigung.
    expect(find.byType(AtemSectionSeam, skipOffstage: false), findsNWidgets(4));
  });

  testWidgets('eine Auswahl scrollt das Thema unter die Zeile', (tester) async {
    final l10n = await pump(tester);

    await jumpTo(tester, l10n.segAnalysis);
    expect(segment(), StrengthSegment.analysis);
    expect(word(tester, l10n), l10n.segAnalysis);
    expect(
      tester.getTopLeft(find.byType(AnalysisSection)).dy,
      closeTo(barBottom(tester), 1.5),
    );

    await jumpTo(tester, l10n.segTrain);
    expect(segment(), StrengthSegment.train);
    expect(
      tester.getTopLeft(find.byType(TrainSection)).dy,
      closeTo(barBottom(tester), 1.5),
    );
  });

  testWidgets('Scrollen wandert von Thema zu Thema', (tester) async {
    await pump(tester);
    expect(segment(), StrengthSegment.train);

    // Weit genug, damit der Verlauf unter der Leiste beginnt.
    for (var i = 0; i < 4 && segment() != StrengthSegment.history; i++) {
      await scrollBy(tester, -300);
    }
    expect(segment(), StrengthSegment.history);

    // Und wieder zurück nach oben.
    for (var i = 0; i < 6 && segment() != StrengthSegment.train; i++) {
      await scrollBy(tester, 300);
    }
    expect(segment(), StrengthSegment.train);
  });

  testWidgets('ein Sprung über den Provider scrollt an den Abschnitt',
      (tester) async {
    await pump(tester);
    // Wie die Kraft-Zeile im Hybrid-Tab.
    container
        .read(appTabsProvider.notifier)
        .jump(AppTab.strength, strengthSegment: StrengthSegment.history);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(HistorySection)).dy,
      closeTo(barBottom(tester), 1.5),
    );
  });

  testWidgets(
      'Verlauf: Einheitenzahl und Balance nebeneinander, dann Monate — '
      'ohne Aussagekarte', (tester) async {
    final l10n = await pump(tester);
    await jumpTo(tester, l10n.segHistory);

    expect(find.byType(StatementCard), findsNothing);
    expect(find.text(l10n.historyAnalysisOpen), findsNothing);

    expect(find.byType(HistorySection), findsOneWidget);
    // **Split-Card** (21.09.2026): Die Einheitenzahl und die Muskelbalance
    // teilen sich die erste Zeile, der Monatsstreifen kommt darunter. Vorher
    // standen alle drei untereinander.
    expect(find.byType(AtemSplit), findsOneWidget);
    final split = tester.getTopLeft(find.byType(AtemSplit)).dy;
    final month = tester.getTopLeft(find.byType(MonthStrip)).dy;
    expect(split, lessThan(month));
  });

  testWidgets('Pläne: die eigenen und die Ankündigung ohne Knopf',
      (tester) async {
    final l10n = await pump(tester);
    await jumpTo(tester, l10n.segPlans);

    expect(find.byType(PlansSection), findsOneWidget);
    expect(find.text(l10n.plansOwnLabel.toUpperCase()), findsOneWidget);
    await tester.ensureVisible(find.byType(PlanCatalogTeaser));
    await tester.pumpAndSettle();
    expect(find.text(l10n.plansAtemLabel.toUpperCase()), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(PlanCatalogTeaser),
            matching: find.byType(GestureDetector)),
        findsNothing,
        reason: 'Kein Knopf ins Leere');
  });

  testWidgets('Systemzurück wechselt keinen Abschnitt', (tester) async {
    final l10n = await pump(tester);
    await jumpTo(tester, l10n.segHistory);
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isFalse);
    expect(segment(), StrengthSegment.history);
  });
}
