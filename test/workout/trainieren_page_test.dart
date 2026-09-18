import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/dashboard/domain/dashboard_data.dart';
import 'package:atem/features/dashboard/domain/dashboard_repository.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/plans/presentation/screens/plan_detail_screen.dart';
import 'package:atem/features/plans/presentation/start_sheet.dart';
import 'package:atem/features/plans/presentation/widgets/plan_card.dart';
import 'package:atem/features/workout/presentation/screens/workouts_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Dashboard ohne Termin für heute — für die leere Heute-Karte.
class _NoSessionDashboard implements DashboardRepository {
  @override
  Stream<DashboardData> watchDashboard() =>
      PreviewDashboardRepository().watchDashboard().map((d) => DashboardData(
            user: d.user,
            readiness: d.readiness,
            performance: d.performance,
            session: null,
            workoutLog: d.workoutLog,
            lastSession: d.lastSession,
            nextSession: d.nextSession,
          ));
}

/// Pläne-Repository ohne Pläne.
class _NoPlans extends FakePlanRepository {
  @override
  Stream<List<Plan>> watchPlans(String userId) => Stream.value(const []);

  @override
  Future<List<Plan>> fetchPlans(String userId) async => const [];
}

Future<void> _pump(
  WidgetTester tester, {
  List overrides = const [],
  ValueChanged<StartRequest>? onStart,
  Size size = const Size(361, 1400),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    // Eine Ersatz-Überschreibung verdrängt die gleichnamige aus den
    // Fixtures — Riverpod erlaubt dieselbe nur einmal je Container.
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
      home: WorkoutsScreen(onStart: onStart ?? (_) {}),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Der Provider-Teil der Beschreibung, etwa `Provider<PlanRepository>`.
String _providerOf(Object override) => override.toString().split('#').first;

AtemCard _cardAround(WidgetTester tester, Finder finder) =>
    tester.widget<AtemCard>(
        find.ancestor(of: finder, matching: find.byType(AtemCard)).first);

void main() {
  late AppL10n l10n;


  testWidgets('Startkarte trägt alle drei Wege, ohne Tagesplanung',
      (tester) async {
    await _pump(tester);
    l10n = AppL10n.of(tester.element(find.byType(WorkoutsScreen)));

    final start = find.text(l10n.workoutsStart);
    final free = find.text(l10n.workoutsFree);
    final log = find.text(l10n.strengthFormEntry);
    expect(start, findsOneWidget);
    expect(free, findsOneWidget);
    expect(log, findsOneWidget);
    // Alle drei stehen in derselben Karte …
    expect(identical(_cardAround(tester, start), _cardAround(tester, free)),
        isTrue);
    expect(identical(_cardAround(tester, start), _cardAround(tester, log)),
        isTrue);
    // … und die ist ein ruhiger Block: kein Gradient-Rand mehr
    // (seit 18.09.2026, der Tag steht auf dem Hybrid-Tab).
    expect(_cardAround(tester, start).gradient, isNull);
  });

  testWidgets('ohne Termin heisst der erste Weg „Freies Training starten"',
      (tester) async {
    await _pump(tester, overrides: [
      dashboardRepositoryProvider.overrideWithValue(_NoSessionDashboard()),
    ]);
    l10n = AppL10n.of(tester.element(find.byType(WorkoutsScreen)));

    // Keine Planungssprache mehr im Kraft-Tab.
    expect(find.text(l10n.emptyTodayTitle), findsNothing);
    expect(find.text(l10n.workoutsTodayLabel.toUpperCase()), findsNothing);

    final free = find.text(l10n.workoutsFreeStart);
    expect(free, findsOneWidget);
    expect(find.text(l10n.workoutsPlanPick), findsOneWidget);
    expect(_cardAround(tester, free).gradient, isNull);
    expect(find.text(l10n.strengthFormEntry), findsOneWidget);
  });

  testWidgets('Pläne stehen als seitlich scrollbare Karten', (tester) async {
    await _pump(tester);
    l10n = AppL10n.of(tester.element(find.byType(WorkoutsScreen)));

    expect(find.byType(PlanCard), findsNWidgets(fixturePlans.length));
    final scroller = tester.widget<SingleChildScrollView>(find
        .ancestor(
            of: find.byType(PlanCard).first,
            matching: find.byType(SingleChildScrollView))
        .first);
    expect(scroller.scrollDirection, Axis.horizontal);

    final plan = fixturePlans.first;
    expect(
      find.bySemanticsLabel(l10n.planCardA11y(
          plan.name, plan.exerciseCount, plan.estimatedDuration.inMinutes)),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(l10n.planCardStartA11y(plan.name)),
        findsOneWidget);
    // „Alle" bleibt im Kopf.
    expect(
        find.text(l10n.workoutsPlansAll(fixturePlans.length)), findsOneWidget);
  });

  testWidgets('Starten auf der Karte öffnet das Start-Blatt mit dem Plan',
      (tester) async {
    StartRequest? got;
    await _pump(tester, onStart: (r) => got = r);
    l10n = AppL10n.of(tester.element(find.byType(WorkoutsScreen)));
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
    expect(got, isNotNull);
    expect(got!.plan?.id, plan.id);
  });

  testWidgets('die Karte öffnet das Plandetail', (tester) async {
    await _pump(tester);
    final plan = fixturePlans.first;

    final title = find.descendant(
        of: find.byType(PlanCard), matching: find.text(plan.name));
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailScreen), findsOneWidget);
  });

  testWidgets('ohne Pläne keine Kartenreihe, sondern der Leerzustand',
      (tester) async {
    await _pump(tester, overrides: [
      planRepositoryProvider.overrideWithValue(_NoPlans()),
    ]);
    l10n = AppL10n.of(tester.element(find.byType(WorkoutsScreen)));

    expect(find.byType(PlanCard), findsNothing);
    expect(find.byType(PlanCardRow), findsNothing);
    expect(find.text(l10n.workoutsTodayEmptyTitle), findsOneWidget);
  });

  testWidgets('die Muskelbalance steht nicht mehr auf dieser Seite',
      (tester) async {
    await _pump(tester);
    l10n = AppL10n.of(tester.element(find.byType(WorkoutsScreen)));
    expect(find.text(l10n.balanceTitle), findsNothing);
  });

  testWidgets('200 % Schrift auf 320 dp ohne Überlauf', (tester) async {
    await _pump(tester, size: const Size(320, 2600), textScale: 2.0);
    expect(tester.takeException(), isNull);
    expect(find.byType(PlanCard), findsWidgets);
  });
}
