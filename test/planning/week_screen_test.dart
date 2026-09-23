import 'package:atem/app/application/snackbar_providers.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/domain/dashboard_data.dart';
import 'package:atem/features/planning/application/training_goal_providers.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/planning/application/week_plan_providers.dart';
import 'package:atem/features/planning/domain/week_plan.dart';
import 'package:atem/features/planning/presentation/screens/week_screen.dart';
import 'package:atem/features/planning/presentation/widgets/today_widget.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';
import '../support/fake_training_goal.dart';
import '../support/fake_week_plan.dart';

/// Die Woche von Hand — Board 19, A–D.
late FakeWeekPlanRepository repo;
late ProviderContainer container;

final _wed = DateTime(2026, 9, 23);

const _mondayStrength = WeekEntry(id: 'm', weekday: 1, kind: WeekKind.strength);
const _wednesdayRun = WeekEntry(
  id: 'w',
  weekday: 3,
  kind: WeekKind.cardio,
  activity: CardioActivity.run,
  durationMin: 40,
  daypart: WeekDaypart.morning,
);

WeekPlan _plan(List<WeekEntry> entries) {
  var p = WeekPlan.empty;
  for (final e in entries) {
    p = p.add(WeekSide.a, e).next;
  }
  return p;
}

Future<void> _pump(
  WidgetTester tester, {
  WeekPlan initial = WeekPlan.empty,
  bool denied = false,
  List<TrainingSession>? sessions,
  Widget? home,
}) async {
  tester.view.physicalSize = const Size(420, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  repo = FakeWeekPlanRepository(initial: initial, denied: denied);
  await tester.pumpWidget(ProviderScope(
    // Eine eigene, knappe Basis: Die Fixtures setzen Woche und Stichtag
    // schon, und ihr Vorschau-Dashboard bringt einen Kraft-Termin für heute
    // mit, der die Woche im Widget überlagerte.
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
      ),
      planRepositoryProvider.overrideWithValue(FakePlanRepository()),
      trainingGoalRepositoryProvider
          .overrideWithValue(FakeTrainingGoalRepository()),
      weekPlanRepositoryProvider.overrideWithValue(repo),
      historyReferenceProvider.overrideWithValue(_wed),
      sessionsProvider.overrideWithValue(AsyncData(sessions ?? const [])),
      dashboardDataProvider.overrideWith(
          (ref) => Stream<DashboardData>.error(StateError('kein Termin'))),
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
      home: home ?? WeekScreen(today: _wed),
    ),
  ));
  await tester.pumpAndSettle();
  container = ProviderScope.containerOf(
      tester.element(find.byType(home == null ? WeekScreen : Scaffold).first));
}

Future<void> _drain(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 7));

void main() {
  testWidgets('leer: sieben Tage mit Plus, keine Leerkarte, kein Aufruf',
      (tester) async {
    await _pump(tester);
    for (final day in [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ]) {
      expect(find.text(day), findsOneWidget, reason: day);
      expect(find.bySemanticsLabel('Eintrag am $day hinzufügen'), findsOne);
    }
    expect(find.text('HEUTE'), findsOneWidget);
    expect(find.text('Nicht angegeben — freiwillig'), findsOneWidget);
    expect(find.text('Woche leeren'), findsNothing);
  });

  testWidgets('anlegen: Plus → Kraft → Hinzufügen, mit Rückgängig',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.bySemanticsLabel('Eintrag am Montag hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.text('Eintrag am Montag'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Kraft'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hinzufügen'));
    await tester.tap(find.text('Hinzufügen'));
    await tester.pumpAndSettle();

    expect(repo.plan.day(WeekSide.a, 1).single.kind, WeekKind.strength);
    expect(repo.writes.single.keys.single, startsWith('a.entries.'));
    final snack = container.read(snackbarProvider)!;
    expect(snack.message, 'Krafttraining am Montag eingetragen');
    snack.onAction!();
    await tester.pumpAndSettle();
    expect(repo.plan.a, isEmpty);
    await _drain(tester);
  });

  testWidgets('Cardio ohne Aktivität lässt sich nicht hinzufügen',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.bySemanticsLabel('Eintrag am Dienstag hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Cardio'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Hinzufügen, nicht möglich: Aktivität wählen'),
      findsOneWidget,
    );
  });

  testWidgets('„Frei" ist an einem belegten Tag gesperrt und nennt den Grund',
      (tester) async {
    await _pump(tester, initial: _plan([_mondayStrength]));
    await tester.tap(find.bySemanticsLabel('Eintrag am Montag hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Frei, nur an Tagen ohne Eintrag'),
        findsOneWidget);
  });

  testWidgets('verschieben ohne Ziehen: Eintrag → Tag-Chip',
      (tester) async {
    await _pump(tester, initial: _plan([_mondayStrength]));
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Krafttraining, Kraft')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.bySemanticsLabel('Donnerstag'));
    await tester.tap(find.bySemanticsLabel('Donnerstag'));
    await tester.pumpAndSettle();

    expect(repo.writes.last,
        {'a.entries.m.weekday': 4, 'a.entries.m.order': 0});
    expect(repo.plan.day(WeekSide.a, 4).single.id, 'm');
    expect(container.read(snackbarProvider)?.message,
        'Krafttraining auf Donnerstag verschoben');
    await _drain(tester);
  });

  testWidgets('Ablehnung steht am Tag, nicht in einem Toast', (tester) async {
    await _pump(tester, initial: _plan([_mondayStrength]));
    repo.reject = true;
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Krafttraining, Kraft')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.bySemanticsLabel('Freitag'));
    await tester.tap(find.bySemanticsLabel('Freitag'));
    await tester.pumpAndSettle();

    expect(
      find.text('„Krafttraining“ nicht auf Freitag verschoben — der Server '
          'hat abgelehnt. Steht wieder am Montag.'),
      findsOneWidget,
    );
    expect(repo.plan.day(WeekSide.a, 1).single.id, 'm');
    await _drain(tester);
  });

  testWidgets('Ladefehler: keine Tage — sonst sähe die Seite leer aus',
      (tester) async {
    await _pump(tester, denied: true);
    expect(find.text('Woche konnte nicht geladen werden.'), findsOneWidget);
    expect(find.text('Montag'), findsNothing);
  });

  testWidgets('Tatsache neben dem Tag, nie am Eintrag; Bisher nach F3',
      (tester) async {
    await _pump(
      tester,
      initial: _plan([_mondayStrength]),
      sessions: [
        CardioSession(
          id: 'c',
          userId: 'u',
          date: DateTime(2026, 9, 21),
          createdAt: DateTime(2026, 9, 21),
          activity: CardioActivity.run,
          duration: const Duration(minutes: 35),
        ),
      ],
    );
    expect(find.textContaining('Trainiert · '), findsOneWidget);
    expect(find.text('0 Kraft-Einheiten · in deiner Woche 1'), findsOneWidget);
    expect(find.text('1 Cardio-Einheit'), findsOneWidget);
    // Kein Bruch, kein „noch", kein „verpasst".
    expect(find.textContaining('/'), findsNothing);
    expect(find.textContaining('verpasst'), findsNothing);
  });

  group('Hybrid-Widget', () {
    Widget host() => const Scaffold(
          body: SingleChildScrollView(child: TodayWidget()),
        );

    testWidgets('nie geplant: rendert nicht', (tester) async {
      await _pump(tester, home: host());
      expect(find.text('Deine Woche'), findsNothing);
    });

    testWidgets('heute mit Eintrag: Titel, Quelle, Streifen, ein Weg',
        (tester) async {
      await _pump(tester,
          initial: _plan([_mondayStrength, _wednesdayRun]), home: host());
      expect(find.text('HEUTE · MITTWOCH'), findsOneWidget);
      expect(find.text('Laufen'), findsOneWidget);
      expect(find.text('LAUT DEINER WOCHE'), findsOneWidget);
      expect(find.bySemanticsLabel('Deine Woche öffnen'), findsOneWidget);
      // Kein Startknopf im Widget (Entscheidung 15).
      expect(find.textContaining('STARTEN'), findsNothing);
    });

    testWidgets('heute ohne Eintrag: nur die Woche, kein „nichts geplant"',
        (tester) async {
      await _pump(tester, initial: _plan([_mondayStrength]), home: host());
      expect(find.text('DEINE WOCHE'), findsOneWidget);
      expect(find.textContaining('HEUTE'), findsNothing);
      expect(find.textContaining('nichts'), findsNothing);
    });
  });
}
