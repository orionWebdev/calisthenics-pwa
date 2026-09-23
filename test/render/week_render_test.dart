@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/domain/dashboard_data.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/planning/application/training_goal_providers.dart';
import 'package:atem/features/planning/application/week_plan_providers.dart';
import 'package:atem/features/planning/domain/training_goal.dart';
import 'package:atem/features/planning/domain/week_plan.dart';
import 'package:atem/features/planning/presentation/screens/week_screen.dart';
import 'package:atem/features/planning/presentation/widgets/today_widget.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';
import '../support/fake_training_goal.dart';
import '../support/fake_week_plan.dart';
import '../support/render.dart';

/// Sichtprüfung der Woche von Hand (Board 19, B und D).
final _wed = DateTime(2026, 9, 23);

WeekPlan _person1() {
  var p = WeekPlan.empty;
  for (final e in [
    const WeekEntry(id: 'a', weekday: 1, kind: WeekKind.strength, planId: 'p1'),
    const WeekEntry(
        id: 'b',
        weekday: 2,
        kind: WeekKind.cardio,
        activity: CardioActivity.run,
        durationMin: 40),
    const WeekEntry(
        id: 'c',
        weekday: 3,
        kind: WeekKind.cardio,
        activity: CardioActivity.run,
        durationMin: 30,
        daypart: WeekDaypart.morning),
    const WeekEntry(
        id: 'd',
        weekday: 3,
        kind: WeekKind.strength,
        planId: 'weg',
        planName: 'Unterkörper B',
        daypart: WeekDaypart.evening),
    const WeekEntry(
        id: 'e',
        weekday: 4,
        kind: WeekKind.cardio,
        activity: CardioActivity.bike,
        durationMin: 60),
    const WeekEntry(id: 'f', weekday: 5, kind: WeekKind.strength, planId: 'p1'),
    const WeekEntry(id: 'g', weekday: 7, kind: WeekKind.off),
  ]) {
    p = p.add(WeekSide.a, e).next;
  }
  return p;
}

Future<void> _render(
  WidgetTester tester, {
  required String name,
  required Widget home,
  WeekPlan plan = WeekPlan.empty,
  TrainingGoal goal = TrainingGoal.empty,
  double width = 361,
  double scale = 1.15,
  double height = 2400,
}) async {
  await loadRealFonts();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
      ),
      planRepositoryProvider.overrideWithValue(FakePlanRepository()),
      trainingGoalRepositoryProvider
          .overrideWithValue(FakeTrainingGoalRepository(initial: goal)),
      weekPlanRepositoryProvider
          .overrideWithValue(FakeWeekPlanRepository(initial: plan)),
      historyReferenceProvider.overrideWithValue(_wed),
      sessionsProvider.overrideWithValue(AsyncData([
        CardioSession(
          id: 's',
          userId: 'u',
          date: DateTime(2026, 9, 22),
          createdAt: DateTime(2026, 9, 22),
          activity: CardioActivity.run,
          duration: const Duration(minutes: 35),
        ),
      ])),
      dashboardDataProvider.overrideWith(
          (ref) => Stream<DashboardData>.error(StateError('kein Termin'))),
    ],
    child: RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
        home: home,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await writePng(tester, key, name);
}

void main() {
  testWidgets('B · leer', (tester) async {
    if (!renderEnabled) return;
    await _render(tester, name: 'week_leer', home: WeekScreen(today: _wed));
  });

  testWidgets('B · voll', (tester) async {
    if (!renderEnabled) return;
    await _render(tester,
        name: 'week_voll', plan: _person1(), home: WeekScreen(today: _wed));
  });

  testWidgets('B14 · 200 % auf 320 dp', (tester) async {
    if (!renderEnabled) return;
    await _render(tester,
        name: 'week_320_200',
        plan: _person1(),
        width: 320,
        scale: 2.0,
        height: 5200,
        home: WeekScreen(today: _wed));
  });

  for (final (width, scale) in [(361.0, 1.15), (320.0, 2.0)]) {
    testWidgets('D · Widget ${width.round()}', (tester) async {
      if (!renderEnabled) return;
      await _render(
        tester,
        name: 'today_widget_${width.round()}',
        plan: _person1(),
        width: width,
        scale: scale,
        height: 1000,
        home: const Scaffold(
          backgroundColor: AtemColors.base,
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(child: TodayWidget()),
          ),
        ),
      );
    });
  }
}
