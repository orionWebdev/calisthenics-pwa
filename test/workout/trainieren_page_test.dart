import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/dashboard/domain/dashboard_data.dart';
import 'package:atem/features/dashboard/domain/dashboard_repository.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_list_screen.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/plans/presentation/screens/plan_form_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_list_screen.dart';
import 'package:atem/features/plans/presentation/start_sheet.dart';
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

/// Der Plan liess sich nicht lesen.
class _FailingDashboard implements DashboardRepository {
  @override
  Stream<DashboardData> watchDashboard() =>
      Stream<DashboardData>.error(StateError('offline'));
}

/// Es lädt und lädt.
class _PendingDashboard implements DashboardRepository {
  @override
  Stream<DashboardData> watchDashboard() =>
      const Stream<DashboardData>.empty().asBroadcastStream();
}

Future<void> _pump(
  WidgetTester tester, {
  List overrides = const [],
  ValueChanged<StartRequest>? onStart,
  Size size = const Size(361, 900),
  double textScale = 1.0,
  bool settle = true,
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
  if (settle) await tester.pumpAndSettle();
}

/// Der Provider-Teil der Beschreibung, etwa `Provider<PlanRepository>`.
String _providerOf(Object override) => override.toString().split('#').first;

/// Ohne Verlauf: kein Termin, keine Einheit, kein Plan — die Erstöffnung.
final _blank = [
  dashboardRepositoryProvider.overrideWithValue(_NoSessionDashboard()),
  sessionStreamProvider
      .overrideWith((ref) => Stream.value(const <TrainingSession>[])),
  plansProvider.overrideWith((ref) => Stream.value(const <Plan>[])),
];

/// Das Thema „Trainieren" (Board 17, seit 21.09.2026): **ein Gegenstand mit
/// einem Knopf**, darunter das Kachelpaar.
void main() {
  AppL10n read(WidgetTester tester) =>
      AppL10n.of(tester.element(find.byType(TrainSection)));

  /// Der Knopf — in jedem Zustand genau einer.
  Finder cta(AppL10n l10n) => find.byType(AtemButton);

  group('die fünf Zustände tragen dieselbe Komposition', () {
    testWidgets('mit Plan: Kicker im Bereichston, Knopf „STARTEN"',
        (tester) async {
      await _pump(tester);
      final l10n = read(tester);

      expect(find.text(l10n.trainTodayKicker.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.sheetStart.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.trainStartFree.toUpperCase()), findsNothing);

      // Der Fuss wiederholt nie die Handlung des Knopfs: Der Knopf startet
      // den Plan, links steht deshalb das freie Starten.
      expect(find.text(l10n.trainFreeTitle), findsOneWidget);
      expect(find.text(l10n.trainFootLog), findsOneWidget);
    });

    testWidgets('ohne Plan: dieselbe Karte, Kicker „ZULETZT", Knopf „FREI"',
        (tester) async {
      await _pump(tester, overrides: [
        dashboardRepositoryProvider.overrideWithValue(_NoSessionDashboard()),
      ]);
      final l10n = read(tester);

      expect(find.text(l10n.trainLastKicker.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.trainTodayKicker.toUpperCase()), findsNothing);
      expect(find.text(l10n.trainStartFree.toUpperCase()), findsOneWidget);

      // Kein Mangel, kein Aufruf: Die Zeile ist eine Tatsache mit Datum.
      expect(find.text(l10n.emptyTodayTitle), findsNothing);
      expect(find.textContaining('!'), findsNothing);

      // Links steht jetzt, was der Knopf nicht tut.
      expect(find.text(l10n.workoutsPlanPick), findsOneWidget);
      expect(find.text(l10n.trainFootLog), findsOneWidget);
    });

    testWidgets('Erstöffnung: kein Kopf, die Karte beginnt beim Knopf',
        (tester) async {
      await _pump(tester, overrides: _blank);
      final l10n = read(tester);

      // Keiner der drei Kicker steht da — die Zone rendert nicht.
      for (final k in [
        l10n.trainTodayKicker,
        l10n.trainLastKicker,
        l10n.trainErrorKicker,
      ]) {
        expect(find.text(k.toUpperCase()), findsNothing, reason: k);
      }
      // Startbereit bleibt sie trotzdem, und der Fuss bietet den Plan an.
      expect(find.text(l10n.trainStartFree.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.trainFootNewPlan), findsOneWidget);
      expect(find.text(l10n.trainTilePlanMetaNone), findsOneWidget);
    });

    testWidgets('Fehler: nur der Kopf ist betroffen, der Knopf bleibt',
        (tester) async {
      await _pump(tester, overrides: [
        dashboardRepositoryProvider.overrideWithValue(_FailingDashboard()),
      ]);
      final l10n = read(tester);

      expect(find.text(l10n.trainErrorKicker.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.trainErrorTitle), findsOneWidget);
      expect(find.text(l10n.commonRetry), findsOneWidget);

      // Kein Vollbildfehler: Knopf, Fuss und Kacheln funktionieren weiter.
      expect(find.text(l10n.trainStartFree.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.trainTileExercises), findsOneWidget);
      expect(tester.widget<AtemButton>(cta(l10n)).onPressed, isNotNull);
    });

    testWidgets('Lädt: Skelett erst nach 300 ms, Knopf sofort bedienbar',
        (tester) async {
      await _pump(
        tester,
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(_PendingDashboard()),
        ],
        settle: false,
      );
      await tester.pump();

      final l10n = read(tester);
      // **Nie ausgegraut**: Frei starten braucht keine geladene Zeile.
      expect(tester.widget<AtemButton>(cta(l10n)).onPressed, isNotNull);
      // `AtemSkeleton` steht im Baum, zeigt aber noch nichts — geprüft wird
      // die Form, nicht das Widget.
      expect(find.byType(AtemPlaceholderShape), findsNothing,
          reason: 'wer schneller lädt, soll nicht flackern');

      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(AtemPlaceholderShape), findsOneWidget);
    });
  });

  testWidgets('genau eine Karte mit Gradient-Rand', (tester) async {
    await _pump(tester);
    // Zwei nähmen sich gegenseitig die Wirkung — die Kacheln sind K3.
    expect(find.byType(AtemStartBlock), findsOneWidget);
  });

  testWidgets('das Kachelpaar steht als Split-Card nebeneinander',
      (tester) async {
    await _pump(tester);
    final l10n = read(tester);

    expect(find.byType(AtemSplit), findsOneWidget);
    final exercises = tester.getRect(find.text(l10n.trainTileExercises));
    final plan = tester.getRect(find.text(l10n.trainTilePlan));
    // Oben bündig, nicht gleich hoch: Verglichen wird die Oberkante — der
    // zweizeilige Titel „Training planen" macht seine Kachel höher.
    expect(exercises.top, closeTo(plan.top, 0.5),
        reason: 'auf 361 dp nebeneinander');
    expect(exercises.center.dx, lessThan(plan.center.dx));

    // Jede Kachel nennt ihre Grundlage — aus den Fixtures gezählt, nicht
    // festgeschrieben.
    expect(
        find.text(l10n.trainTileExercisesMeta(fixtureExercises.length)),
        findsOneWidget);
    expect(find.text(l10n.trainTilePlanMeta(fixturePlans.length)),
        findsOneWidget);
  });

  group('die Wege', () {
    testWidgets('der Knopf startet den Termin von heute', (tester) async {
      await _pump(tester);
      final l10n = read(tester);

      await tester.tap(find.text(l10n.sheetStart.toUpperCase()));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(l10n.sheetRestLabel))),
        findsOneWidget,
      );
    });

    testWidgets('links im Fuss: frei starten', (tester) async {
      await _pump(tester);
      final l10n = read(tester);

      await tester.tap(find.text(l10n.trainFreeTitle));
      await tester.pumpAndSettle();
      expect(find.text(l10n.sheetFreeBody), findsOneWidget);
    });

    testWidgets('rechts im Fuss: nachtragen', (tester) async {
      await _pump(tester);
      final l10n = read(tester);

      await tester.tap(find.text(l10n.trainFootLog));
      await tester.pumpAndSettle();
      expect(find.byType(StrengthFormScreen), findsOneWidget);
    });

    testWidgets('die linke Kachel führt in den Katalog', (tester) async {
      await _pump(tester);
      final l10n = read(tester);

      await tester.tap(find.text(l10n.trainTileExercises));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseListScreen), findsOneWidget);
    });

    testWidgets('die rechte Kachel führt zu den Plänen', (tester) async {
      await _pump(tester);
      final l10n = read(tester);

      await tester.tap(find.text(l10n.trainTilePlan));
      await tester.pumpAndSettle();
      expect(find.byType(PlanListScreen), findsOneWidget);
    });

    testWidgets('ohne eigenen Plan führt sie ins Anlegen', (tester) async {
      await _pump(tester, overrides: _blank);
      final l10n = read(tester);

      await tester.tap(find.text(l10n.trainTilePlan));
      await tester.pumpAndSettle();
      expect(find.byType(PlanFormScreen), findsOneWidget);
    });
  });

  testWidgets('weder Plankarten noch Übungsblock stehen noch hier',
      (tester) async {
    await _pump(tester);
    final l10n = read(tester);

    expect(find.byType(PlanCard), findsNothing);
    expect(find.text(l10n.workoutsPlansLabel.toUpperCase()), findsNothing);
    expect(find.text(l10n.exercisesBlockByMuscle.toUpperCase()), findsNothing);
    expect(find.text(l10n.exercisesCreate), findsNothing);
    // Die Muskelbalance gehört in den Verlauf.
    expect(find.text(l10n.balanceTitle), findsNothing);
  });

  testWidgets('bei 200 % auf 320 dp stapeln Fuss und Kacheln',
      (tester) async {
    await _pump(tester, size: const Size(320, 2600), textScale: 2.0);
    expect(tester.takeException(), isNull);
    final l10n = read(tester);

    final free = tester.getRect(find.text(l10n.trainFreeTitle));
    final log = tester.getRect(find.text(l10n.trainFootLog));
    expect(free.bottom, lessThanOrEqualTo(log.top),
        reason: 'zwei Hälften nebeneinander gehen bei 24 sp nicht mehr');

    final exercises = tester.getRect(find.text(l10n.trainTileExercises));
    final plan = tester.getRect(find.text(l10n.trainTilePlan));
    expect(exercises.bottom, lessThanOrEqualTo(plan.top),
        reason: 'gleiche Schwelle, gleicher Messpunkt');
  });
}
