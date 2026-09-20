import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/plans/presentation/screens/plan_detail_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_form_screen.dart';
import 'package:atem/features/plans/presentation/start_sheet.dart';
import 'package:atem/features/plans/presentation/widgets/plan_card.dart';
import 'package:atem/features/plans/presentation/widgets/plans_section.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Pläne-Repository ohne Pläne.
class _NoPlans extends FakePlanRepository {
  @override
  Stream<List<Plan>> watchPlans(String userId) => Stream.value(const []);

  @override
  Future<List<Plan>> fetchPlans(String userId) async => const [];
}

/// Der Abschnitt „Pläne" des One-Pagers (seit 20.09.2026): die eigenen Pläne
/// und die Ankündigung des ATEM-Katalogs an einem Ort.
void main() {
  late AppL10n l10n;

  Future<void> pump(
    WidgetTester tester, {
    List overrides = const [],
    ValueChanged<StartRequest>? onStart,
  }) async {
    tester.view.physicalSize = const Size(361, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        for (final o in fixtureOverrides)
          if (!overrides.any((x) => _providerOf(x) == _providerOf(o))) o,
        ...overrides,
      ],
      child: MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: AtemColors.base,
          body: SingleChildScrollView(
            child: PlansSection(onStart: onStart ?? (_) {}),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    l10n = AppL10n.of(tester.element(find.byType(PlansSection)));
  }

  testWidgets('die eigenen Pläne stehen oben, der Katalog darunter',
      (tester) async {
    await pump(tester);

    expect(find.text(l10n.plansOwnLabel.toUpperCase()), findsOneWidget);
    expect(find.byType(PlanCard), findsNWidgets(fixturePlans.length));
    expect(find.text(l10n.workoutsPlansAll(fixturePlans.length)),
        findsOneWidget);

    final own = tester.getTopLeft(find.byType(PlanCard).first).dy;
    final catalog = tester.getTopLeft(find.byType(PlanCatalogTeaser)).dy;
    expect(own, lessThan(catalog));
  });

  testWidgets('die Karten scrollen seitlich', (tester) async {
    await pump(tester);
    final scroller = tester.widget<SingleChildScrollView>(find
        .ancestor(
            of: find.byType(PlanCard).first,
            matching: find.byType(SingleChildScrollView))
        .first);
    expect(scroller.scrollDirection, Axis.horizontal);
  });

  testWidgets('Starten auf der Karte öffnet das Start-Blatt mit dem Plan',
      (tester) async {
    StartRequest? got;
    await pump(tester, onStart: (r) => got = r);
    final plan = fixturePlans.first;

    final startButton = find.descendant(
        of: find.byType(PlanCard), matching: find.text(l10n.sheetStart));
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text(l10n.sheetStartTitle(plan.name)), findsOneWidget);
    expect(find.byType(PlanDetailScreen), findsNothing,
        reason: 'Der Knopf darf nicht das Detail öffnen');

    await tester.tap(find.text(l10n.sheetStart).last);
    await tester.pumpAndSettle();
    expect(got?.plan?.id, plan.id);
  });

  testWidgets('die Karte öffnet das Plandetail', (tester) async {
    await pump(tester);
    final plan = fixturePlans.first;

    final title = find.descendant(
        of: find.byType(PlanCard), matching: find.text(plan.name));
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailScreen), findsOneWidget);
  });

  testWidgets('der Weg zum neuen Plan steht im Abschnitt', (tester) async {
    await pump(tester);
    await tester.tap(find.text(l10n.planFormNewTitle));
    await tester.pumpAndSettle();
    expect(find.byType(PlanFormScreen), findsOneWidget);
  });

  testWidgets('ohne Pläne der Leerzustand, der Katalog bleibt',
      (tester) async {
    await pump(tester, overrides: [
      planRepositoryProvider.overrideWithValue(_NoPlans()),
    ]);

    expect(find.byType(PlanCard), findsNothing);
    expect(find.byType(PlanCardRow), findsNothing);
    expect(find.text(l10n.workoutsTodayEmptyTitle), findsOneWidget);
    expect(find.text(l10n.plansAtemLabel.toUpperCase()), findsOneWidget);
  });

  testWidgets('der Katalog kündigt an und trägt keinen Knopf', (tester) async {
    await pump(tester);
    expect(find.text(l10n.planCatalogBody), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(PlanCatalogTeaser),
            matching: find.byType(GestureDetector)),
        findsNothing,
        reason: 'Kein Knopf ins Leere');
  });
}

/// Der Provider-Teil der Beschreibung, etwa `Provider<PlanRepository>`.
String _providerOf(Object override) => override.toString().split('#').first;
