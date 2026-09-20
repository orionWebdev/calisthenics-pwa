import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/dashboard/domain/dashboard_data.dart';
import 'package:atem/features/dashboard/domain/dashboard_repository.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_list_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_list_screen.dart';
import 'package:atem/features/plans/presentation/start_sheet.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/plans/presentation/widgets/plan_card.dart';
import 'package:atem/features/strength/presentation/screens/strength_form_screen.dart';
import 'package:atem/features/workout/presentation/widgets/train_section.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Dashboard ohne Termin für heute.
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

Future<void> _pump(
  WidgetTester tester, {
  List overrides = const [],
  ValueChanged<StartRequest>? onStart,
  Size size = const Size(361, 900),
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
      home: Scaffold(
        backgroundColor: AtemColors.base,
        body: SingleChildScrollView(
          child: TrainSection(onStart: onStart ?? (_) {}),
        ),
      ),
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

/// Das Thema „Trainieren" des One-Pagers (Board 13, seit 20.09.2026):
/// drei Gewichtsklassen, nach Häufigkeit belegt.
void main() {
  late AppL10n l10n;

  AppL10n read(WidgetTester tester) =>
      AppL10n.of(tester.element(find.byType(TrainSection)));

  testWidgets('drei Gewichtsklassen: Gradient-Karte, Halbkarten, Zeilen',
      (tester) async {
    await _pump(tester);
    l10n = read(tester);

    // K2 trägt den Termin von heute, samt Kicker und Startknopf.
    expect(find.text(l10n.trainTodayKicker.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.sheetStart.toUpperCase()), findsOneWidget);
    expect(find.byType(AtemCard), findsWidgets);

    // Halbkarten und Zeilen.
    expect(find.text(l10n.trainFreeTitle), findsOneWidget);
    expect(find.text(l10n.workoutsPlanPick), findsOneWidget);
    expect(find.text(l10n.trainCatalog), findsOneWidget);
    expect(find.text(l10n.trainLogLater), findsOneWidget);

    // Die Rangfolge steht auch in der Reihenfolge.
    final hero = tester.getTopLeft(find.text(l10n.sheetStart.toUpperCase())).dy;
    final half = tester.getTopLeft(find.text(l10n.workoutsPlanPick)).dy;
    final row = tester.getTopLeft(find.text(l10n.trainLogLater)).dy;
    expect(hero, lessThan(half));
    expect(half, lessThan(row));
  });

  testWidgets('ohne Termin rückt „Frei starten" auf die Gradient-Karte',
      (tester) async {
    await _pump(tester, overrides: [
      dashboardRepositoryProvider.overrideWithValue(_NoSessionDashboard()),
    ]);
    l10n = read(tester);

    // Keine Planungssprache im Kraft-Tab.
    expect(find.text(l10n.emptyTodayTitle), findsNothing);
    expect(find.text(l10n.workoutsTodayLabel.toUpperCase()), findsNothing);

    // Genau einmal: Es ist aus dem Raster gerückt, nicht verdoppelt.
    expect(find.text(l10n.trainFreeTitle), findsOneWidget);
    expect(find.text(l10n.trainFreeBody), findsOneWidget);
    expect(find.text(l10n.trainTodayKicker.toUpperCase()), findsNothing);
  });

  testWidgets('mit Termin bleibt „Frei starten" als Halbkarte erreichbar',
      (tester) async {
    await _pump(tester);
    l10n = read(tester);

    // Die Gradient-Karte führt zum Termin, das freie Training rückt in die
    // Halbkarten nach — ohne das wäre es an Trainingstagen unerreichbar.
    expect(find.text(l10n.trainTodayKicker.toUpperCase()), findsOneWidget);
    await tester.tap(find.text(l10n.trainFreeTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sheetFreeBody), findsOneWidget);
  });

  testWidgets('die Gradient-Karte startet den Termin von heute',
      (tester) async {
    await _pump(tester);
    l10n = read(tester);

    await tester.tap(find.text(l10n.sheetStart.toUpperCase()));
    await tester.pumpAndSettle();
    // Das Start-Blatt liegt oben — mit Plan, wenn der Termin einen trägt,
    // sonst als freies Training mit erhaltenem Termin.
    expect(
      find.bySemanticsLabel(RegExp(RegExp.escape(l10n.sheetRestLabel))),
      findsOneWidget,
    );
  });

  testWidgets('die Zeile führt in den Übungskatalog', (tester) async {
    await _pump(tester);
    l10n = read(tester);

    await tester.tap(find.text(l10n.trainCatalog));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseListScreen), findsOneWidget);
  });

  testWidgets('die Plankachel öffnet die Planliste', (tester) async {
    await _pump(tester);
    l10n = read(tester);

    await tester.tap(find.text(l10n.workoutsPlanPick));
    await tester.pumpAndSettle();
    expect(find.byType(PlanListScreen), findsOneWidget);
  });

  testWidgets('die Zeile führt zum Nachtragen ohne Sätze', (tester) async {
    await _pump(tester);
    l10n = read(tester);

    await tester.tap(find.text(l10n.trainLogLater));
    await tester.pumpAndSettle();
    expect(find.byType(StrengthFormScreen), findsOneWidget);
  });

  testWidgets('weder Plankarten noch Übungsblock stehen noch hier',
      (tester) async {
    await _pump(tester);
    l10n = read(tester);

    // Die Pläne stehen seit 20.09.2026 im Abschnitt „Pläne" …
    expect(find.byType(PlanCard), findsNothing);
    expect(find.text(l10n.workoutsPlansLabel.toUpperCase()), findsNothing);
    // … die Übungssuche auf ihrer eigenen Unterseite.
    expect(find.text(l10n.exercisesBlockByMuscle.toUpperCase()), findsNothing);
    expect(find.text(l10n.exercisesCreate), findsNothing);
    // Und die Muskelbalance gehört in den Verlauf.
    expect(find.text(l10n.balanceTitle), findsNothing);
  });

  testWidgets('bei 200 % auf 320 dp stehen die Kacheln untereinander',
      (tester) async {
    await _pump(tester, size: const Size(320, 2200), textScale: 2.0);
    expect(tester.takeException(), isNull);
    l10n = read(tester);

    final free = tester.getRect(find.text(l10n.trainFreeTitle));
    final plans = tester.getRect(find.text(l10n.workoutsPlanPick));
    expect(free.bottom, lessThanOrEqualTo(plans.top),
        reason: 'nebeneinander bliebe je Halbkarte zu wenig Breite');
  });
}
