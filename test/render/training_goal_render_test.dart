@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/planning/application/training_goal_providers.dart';
import 'package:atem/features/planning/domain/training_goal.dart';
import 'package:atem/features/planning/presentation/screens/training_goal_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';
import '../support/fake_training_goal.dart';
import '../support/render.dart';

/// Sichtprüfung der Trainingsangaben (Board 18, A1–A7).
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/training_goal_render_test.dart
final _today = DateTime(2026, 9, 23);

final _half = TrainingGoal.empty
    .withLanes({Lane.strength, Lane.cardio})
    .withPerWeek(Lane.strength, 3)
    .withMultiPerDay(MultiPerDay.no)
    .withPlaces({Place.gym});

final _full = TrainingGoal.empty
    .withLanes({Lane.strength, Lane.cardio})
    .withWeekPattern(WeekPattern.same)
    .withPerWeek(Lane.strength, 3)
    .withPerWeek(Lane.cardio, 3)
    .withSchedule(DaySchedule.fixed)
    .withDays(Lane.strength, {1, 3, 5})
    .withDays(Lane.cardio, {2, 4, 6})
    .withMultiPerDay(MultiPerDay.no)
    .withPlaces({Place.gym, Place.outdoor})
    .withGoals({TrainingAim.endurance, TrainingAim.strength})
    .withDescribes(Describes.current);

Future<FakeTrainingGoalRepository> _render(
  WidgetTester tester, {
  required String name,
  TrainingGoal initial = TrainingGoal.empty,
  bool denied = false,
  double width = 361,
  double scale = 1.15,
  double height = 2400,
  Future<void> Function(WidgetTester, FakeTrainingGoalRepository)? act,
}) async {
  await loadRealFonts();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = FakeTrainingGoalRepository(
    initial: initial,
    denied: denied,
    clock: () => DateTime(2026, 9, 14, 8),
  );
  final key = GlobalKey();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
      ),
      trainingGoalRepositoryProvider.overrideWithValue(repo),
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
        home: TrainingGoalScreen(today: _today),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  if (act != null) {
    await act(tester, repo);
    await tester.pumpAndSettle();
  }
  await writePng(tester, key, name);
  // Snackbar-Timer auslaufen lassen.
  await tester.pump(const Duration(seconds: 7));
  return repo;
}

void main() {
  testWidgets('A1 erster Aufruf', (tester) async {
    if (!renderEnabled) return;
    await _render(tester, name: 'briefing_a1_leer', height: 2600);
  });

  testWidgets('A1 nach „Kraft und Cardio"', (tester) async {
    if (!renderEnabled) return;
    await _render(
      tester,
      name: 'briefing_a1_beides',
      height: 3200,
      act: (t, _) async {
        await t.tap(find.bySemanticsLabel('Kraft und Cardio'));
        await t.pumpAndSettle();
        await t.tap(find.bySemanticsLabel('Kraft, 3 Einheiten je Woche'));
      },
    );
  });

  testWidgets('A2 halb ausgefüllt', (tester) async {
    if (!renderEnabled) return;
    await _render(tester, name: 'briefing_a2_halb', initial: _half,
        height: 1100);
  });

  testWidgets('A3 vollständig, eine Zeile offen', (tester) async {
    if (!renderEnabled) return;
    await _render(
      tester,
      name: 'briefing_a3_offen',
      initial: _full,
      height: 1500,
      act: (t, _) => t.tap(find.bySemanticsLabel(
          RegExp(r'^Einheiten je Woche, .*Ändern$'))),
    );
  });

  testWidgets('A5 Ladefehler', (tester) async {
    if (!renderEnabled) return;
    await _render(tester, name: 'briefing_a5_ladefehler', denied: true,
        height: 900);
  });

  testWidgets('A6 Speicherfehler', (tester) async {
    if (!renderEnabled) return;
    await _render(
      tester,
      name: 'briefing_a6_speicherfehler',
      initial: _half,
      height: 1500,
      act: (t, repo) async {
        await t.tap(find.bySemanticsLabel(
            RegExp(r'^Einheiten je Woche, .*Ändern$')));
        await t.pumpAndSettle();
        repo.reject = true;
        await t.tap(find.bySemanticsLabel('Kraft, 4 Einheiten je Woche'));
      },
    );
  });

  testWidgets('A7 200 % auf 320 dp, feste Tage offen', (tester) async {
    if (!renderEnabled) return;
    await _render(
      tester,
      name: 'briefing_a7_320_200',
      initial: _full,
      width: 320,
      scale: 2.0,
      height: 3200,
      act: (t, _) => t.tap(find.bySemanticsLabel(
          RegExp(r'^Feste Tage, .*Ändern$'))),
    );
  });

  testWidgets('A1 Ziele bei 200 % auf 320 dp', (tester) async {
    if (!renderEnabled) return;
    await _render(tester,
        name: 'briefing_a1_320_200', width: 320, scale: 2.0, height: 6400);
  });
}
