import 'package:atem/app/application/tab_providers.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/presentation/screens/analysis_screen.dart';
import 'package:atem/features/history/presentation/widgets/month_strip.dart';
import 'package:atem/features/history/presentation/widgets/muscle_balance_card.dart';
import 'package:atem/features/history/presentation/widgets/statement_card.dart';
import 'package:atem/features/plans/presentation/screens/plan_catalog_page.dart';
import 'package:atem/features/strength/presentation/screens/strength_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Der Kraft-Tab mit vier wischbaren Seiten (seit 16.09.2026).
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
  double page(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView)).controller!.page!;

  Future<void> swipe(WidgetTester tester, double dx) async {
    // Unterhalb der Reiterleiste ansetzen, damit die Geste den PageView trifft.
    await tester.flingFrom(const Offset(180, 600), Offset(dx, 0), 1500);
    await tester.pumpAndSettle();
  }

  testWidgets('vier Reiter in der Reihenfolge der Vorgabe', (tester) async {
    final l10n = await pump(tester);
    final xs = [
      for (final label in [
        l10n.segTrain,
        l10n.segHistory,
        l10n.segAnalysis,
        l10n.segPlans,
      ])
        tester.getTopLeft(find.text(label).first).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));
    expect(segment(), StrengthSegment.train);
  });

  testWidgets('Wischen nach links und rechts wechselt Seite und Provider',
      (tester) async {
    await pump(tester);
    await swipe(tester, -300);
    expect(page(tester), 1);
    expect(segment(), StrengthSegment.history);

    await swipe(tester, -300);
    expect(page(tester), 2);
    expect(segment(), StrengthSegment.analysis);
    expect(find.byType(AnalysisScreen), findsOneWidget);

    await swipe(tester, 300);
    expect(page(tester), 1);
    expect(segment(), StrengthSegment.history);
  });

  testWidgets('ein Sprung über den Provider wirft die Seite an',
      (tester) async {
    await pump(tester);
    // Wie die Kraft-Zeile im Hybrid-Tab.
    container
        .read(appTabsProvider.notifier)
        .jump(AppTab.strength, strengthSegment: StrengthSegment.history);
    await tester.pumpAndSettle();
    expect(page(tester), 1);

    container
        .read(appTabsProvider.notifier)
        .setStrengthSegment(StrengthSegment.plans);
    await tester.pumpAndSettle();
    expect(page(tester), 3);
    expect(find.byType(PlanCatalogPage), findsOneWidget);
  });

  testWidgets(
      'Verlauf: Einheiten je Monat, Muskelbalance, letzte Einheiten — '
      'ohne Aussagekarte', (tester) async {
    final l10n = await pump(tester);
    await swipe(tester, -300);

    expect(find.byType(StatementCard), findsNothing);
    expect(find.text(l10n.historyAnalysisOpen), findsNothing);

    final month = tester.getTopLeft(find.byType(MonthStrip)).dy;
    final balance = tester.getTopLeft(find.byType(MuscleBalanceEntry)).dy;
    await tester.dragFrom(const Offset(180, 600), const Offset(0, -400));
    await tester.pumpAndSettle();
    final recentAfterScroll =
        tester.getTopLeft(find.text(l10n.historyRecentLabel)).dy;
    expect(month, lessThan(balance));
    // Nach 400 dp Scrollen liegt „Letzte Einheiten" immer noch unter der
    // ursprünglichen Position der Muskelbalance minus Scrollweg.
    expect(recentAfterScroll + 400, greaterThan(balance));
  });

  testWidgets('Pläne: ehrlicher Leerzustand ohne Knopf', (tester) async {
    final l10n = await pump(tester);
    container
        .read(appTabsProvider.notifier)
        .setStrengthSegment(StrengthSegment.plans);
    await tester.pumpAndSettle();

    expect(find.text(l10n.planCatalogTitle), findsOneWidget);
    expect(find.text(l10n.planCatalogBody), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(PlanCatalogPage),
            matching: find.byType(GestureDetector)),
        findsNothing,
        reason: 'Kein Knopf ins Leere');
  });

  testWidgets('Seiten behalten ihren Scrollstand beim Weiterwischen',
      (tester) async {
    final l10n = await pump(tester);
    await swipe(tester, -300);
    await tester.dragFrom(const Offset(180, 600), const Offset(0, -300));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text(l10n.historyRecentLabel)).dy;

    await swipe(tester, -300);
    await swipe(tester, 300);
    expect(tester.getTopLeft(find.text(l10n.historyRecentLabel)).dy,
        closeTo(before, 0.5));
  });

  testWidgets('Systemzurück wechselt keine Seite', (tester) async {
    await pump(tester);
    await swipe(tester, -300);
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isFalse);
    expect(page(tester), 1);
  });
}
