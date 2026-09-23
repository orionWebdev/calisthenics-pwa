@Tags(['a11y'])
library;

import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:atem/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:atem/features/auth/presentation/screens/splash_screen.dart';
import 'package:atem/features/auth/presentation/screens/waiting_room_screen.dart';
import 'package:atem/features/hybrid/presentation/screens/hybrid_screen.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_form_screen.dart';
import 'package:atem/features/history/presentation/widgets/analysis_section.dart';
import 'package:atem/features/history/presentation/widgets/history_section.dart';
import 'package:atem/features/history/presentation/screens/muscle_balance_screen.dart';
import 'package:atem/features/history/presentation/screens/session_detail_screen.dart';
import 'package:atem/features/history/presentation/screens/session_edit_screen.dart';
import 'package:atem/features/history/presentation/screens/session_list_screen.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_list_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_detail_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_form_screen.dart';
import 'package:atem/features/settings/presentation/screens/account_deletion_screen.dart';
import 'package:atem/features/settings/presentation/screens/export_screen.dart';
import 'package:atem/features/settings/presentation/screens/info_screen.dart';
import 'package:atem/features/settings/presentation/screens/settings_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_list_screen.dart';
import 'package:atem/features/weight/presentation/screens/weight_history_screen.dart';
import 'package:atem/features/workout/presentation/widgets/train_section.dart';
import 'package:atem/features/strength/presentation/screens/strength_form_screen.dart';
import 'package:atem/features/strength/presentation/screens/strength_screen.dart';
import 'package:atem/features/cardio/presentation/screens/cardio_screen.dart';
import 'package:atem/features/cardio/presentation/screens/cardio_form_screen.dart';
import 'package:atem/features/cardio/presentation/screens/cardio_live_screen.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:atem/features/workout/domain/workout_session.dart';
import 'package:atem/features/workout/presentation/widgets/set_effort.dart';
import 'package:atem/features/workout/presentation/widgets/set_row.dart';
import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/health_import/presentation/widgets/health_permissions.dart';
import 'package:atem/features/health_import/presentation/widgets/review_sheet.dart';
import 'package:atem/features/exercises/presentation/exercise_picker.dart';
import 'package:atem/features/planning/application/training_goal_providers.dart';
import 'package:atem/features/planning/domain/training_goal.dart';
import 'package:atem/features/planning/presentation/screens/training_goal_screen.dart';
import 'package:atem/features/planning/application/week_plan_providers.dart';
import 'package:atem/features/planning/domain/week_plan.dart';
import 'package:atem/features/planning/presentation/screens/week_screen.dart';
import 'package:atem/features/plans/presentation/widgets/plans_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';
import '../support/fake_training_goal.dart';
import '../support/fake_week_plan.dart';

void main() {
  testWidgets('Dashboard erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const HybridScreen());
  });

  testWidgets('Splash erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const SplashScreen());
  });

  testWidgets('Anmeldung erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const SignInScreen());
  });

  testWidgets('Warteraum erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(
      tester,
      const WaitingRoomScreen(
        user: AuthUser(uid: 'u', email: 'sehr.lange.adresse@beispiel.de'),
      ),
    );
  });

  testWidgets('Onboarding erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(
      tester,
      const OnboardingScreen(user: AuthUser(uid: 'u', email: 'a@b.c')),
    );
  });

  testWidgets('Abschnitt Trainieren erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, _scrolled(TrainSection(onStart: (_) {})));
  });

  testWidgets('Muskelbalance erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const MuscleBalanceScreen());
  });

  // ------------------------------------------------------------- Modul 14

  testWidgets('Gewichtsverlauf erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const WeightHistoryScreen());
  });

  // ------------------------------------------------------------- Modul 18

  testWidgets('Trainingsangaben, erster Aufruf, erfüllen den A11y-Vertrag',
      (tester) async {
    await expectA11y(tester, TrainingGoalScreen(today: DateTime(2026, 9, 23)));
  });

  testWidgets('Trainingsangaben, ausgefüllt, erfüllen den A11y-Vertrag',
      (tester) async {
    await expectA11y(
      tester,
      TrainingGoalScreen(today: DateTime(2026, 9, 23)),
      // Die Seite braucht nur Anmeldung und Angaben; die Fixtures setzen den
      // Angaben-Ersatz schon, ein zweites Überschreiben wäre verboten.
      baseOverrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
        ),
        trainingGoalRepositoryProvider.overrideWithValue(
          FakeTrainingGoalRepository(
            initial: TrainingGoal.empty
                .withLanes({Lane.strength, Lane.cardio})
                .withWeekPattern(WeekPattern.alternating)
                .withCurrentWeek(isA: true, today: DateTime(2026, 9, 23))
                .withPerWeek(Lane.strength, 3)
                .withPerWeek(Lane.cardio, 8, weekB: true)
                .withSchedule(DaySchedule.fixed)
                .withDays(Lane.strength, {1, 3, 5})
                .withMultiPerDay(MultiPerDay.most)
                .withDayparts(Lane.cardio, {Daypart.morning})
                .withGoals(TrainingAim.values.toSet())
                .withDescribes(Describes.intended),
          ),
        ),
      ],
    );
  });

  // ------------------------------------------------------------- Modul 19

  List<Object> weekBase(WeekPlan plan) => [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
        ),
        planRepositoryProvider.overrideWithValue(FakePlanRepository()),
        trainingGoalRepositoryProvider
            .overrideWithValue(FakeTrainingGoalRepository()),
        weekPlanRepositoryProvider
            .overrideWithValue(FakeWeekPlanRepository(initial: plan)),
        sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      ];

  testWidgets('Woche, leer, erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(
      tester,
      WeekScreen(today: DateTime(2026, 9, 23)),
      baseOverrides: weekBase(WeekPlan.empty),
    );
  });

  testWidgets('Woche, voll, erfüllt den A11y-Vertrag', (tester) async {
    var plan = WeekPlan.empty;
    for (final e in [
      const WeekEntry(id: 'a', weekday: 1, kind: WeekKind.strength, planId: 'p1'),
      const WeekEntry(
          id: 'b',
          weekday: 3,
          kind: WeekKind.cardio,
          activity: CardioActivity.run,
          durationMin: 45,
          daypart: WeekDaypart.morning),
      const WeekEntry(
          id: 'c',
          weekday: 3,
          kind: WeekKind.strength,
          daypart: WeekDaypart.evening),
      const WeekEntry(
          id: 'd',
          weekday: 5,
          kind: WeekKind.strength,
          planId: 'weg',
          planName: 'Alter Plan'),
      const WeekEntry(id: 'e', weekday: 7, kind: WeekKind.off),
    ]) {
      plan = plan.add(WeekSide.a, e).next;
    }
    await expectA11y(
      tester,
      WeekScreen(today: DateTime(2026, 9, 23)),
      baseOverrides: weekBase(plan),
    );
  });

  // ------------------------------------------------------------- Modul 11

  testWidgets('Kraft-Tab erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, StrengthScreen(onStart: (_) {}));
  });

  testWidgets('Cardio-Tab erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const CardioScreen());
  });

  testWidgets('Ausdauer erfassen erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const CardioFormScreen());
  });

  testWidgets('Kraft ohne Sätze erfassen erfüllt den A11y-Vertrag',
      (tester) async {
    await expectA11y(tester, const StrengthFormScreen());
  });

  testWidgets('Ausdauer erfassen, vorbefüllt, erfüllt den A11y-Vertrag',
      (tester) async {
    await expectA11y(
      tester,
      const CardioFormScreen(
        prefill: CardioPrefill(
          activity: CardioActivity.bikeIndoor,
          duration: Duration(minutes: 18, seconds: 42),
          distanceText: '6,4',
        ),
      ),
    );
  });

  testWidgets('Live-Uhr erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const CardioLiveScreen());
  });

  testWidgets('Übungsliste erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const ExerciseListScreen());
  });

  testWidgets('Übungsdetail, reich, erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(
        tester, ExerciseDetailScreen(exercise: fixtureExercises.first));
  });

  testWidgets('Übungsdetail, spärlich, erfüllt den A11y-Vertrag',
      (tester) async {
    await expectA11y(
        tester, ExerciseDetailScreen(exercise: fixtureExercises.last));
  });

  testWidgets('Planliste erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const PlanListScreen());
  });

  testWidgets('Plandetail mit Lücke erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, PlanDetailScreen(plan: fixturePlans.first));
  });

  testWidgets('Abschnitt Verlauf erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, _scrolled(const HistorySection()));
  });

  testWidgets('Einheitenliste erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const SessionListScreen());
  });

  // ------------------------------------------------------------- Modul 15

  testWidgets('Einheitenliste mit Eingang erfüllt den A11y-Vertrag',
      (tester) async {
    await expectA11y(tester, const SessionListScreen(),
        extraOverrides: healthOverrides);
  });

  testWidgets('Health-Connect-Zeilen erfüllen den A11y-Vertrag',
      (tester) async {
    await expectA11y(
      tester,
      const Scaffold(
        backgroundColor: AtemColors.base,
        body: SingleChildScrollView(child: HealthPermissionsSection()),
      ),
      extraOverrides: healthOverrides,
    );
  });

  testWidgets('Prüfblatt erfüllt den A11y-Vertrag', (tester) async {
    // `showModalBottomSheet` gibt dem Blatt sonst seine Höhe.
    await expectA11y(
      tester,
      Scaffold(
        backgroundColor: AtemColors.base,
        body: SizedBox.expand(
          child: HealthReviewSheet(pending: _healthPending),
        ),
      ),
      extraOverrides: healthOverrides,
    );
  });

  testWidgets('Einheitendetail erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(
        tester, SessionDetailScreen(session: fixtureSessions.first));
  });

  testWidgets('Abschnitt Auswertung erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, _scrolled(const AnalysisSection()));
  });

  testWidgets('Abschnitt Pläne erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, _scrolled(PlansSection(onStart: (_) {})));
  });

  testWidgets('Workout Runner aus einem Plan erfüllt den A11y-Vertrag',
      (tester) async {
    // Der Plan aus den Vorlagen trägt einen Eintrag auf eine gelöschte
    // Übung — der Runner muss ihn zeigen können, statt zu blockieren.
    await expectA11y(
      tester,
      const WorkoutRunnerScreen(start: WorkoutStart(planId: 'p1')),
    );
  });

  testWidgets('Workout Runner, freies Training, erfüllt den A11y-Vertrag',
      (tester) async {
    await expectA11y(
      tester,
      const WorkoutRunnerScreen(start: WorkoutStart.free()),
    );
  });

  // Seitengetrennte Zeilen und der Anstrengungs-Streifen (18.09.2026). Sie
  // erscheinen im Runner erst nach Eingaben — hier stehen sie direkt, damit
  // die Matrix sie bei 200 % auf 320 dp sieht.
  testWidgets(
      'Runner-Zeilen mit Seite, Anstrengung und Streifen erfüllen den '
      'A11y-Vertrag', (tester) async {
    await expectA11y(
      tester,
      Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SetRow(
              set: const WorkoutSet(
                id: 'a',
                type: SetType.normal,
                weight: '20',
                reps: '8',
                done: true,
                rpe: 8,
                side: SetSide.left,
              ),
              index: 1,
              unilateral: true,
              rpeOpen: true,
              onToggle: () {},
              onCycleType: () {},
              onToggleSide: () {},
              onOpenRpe: () {},
              onEdit: (_) {},
            ),
            RpeStrip(setNumber: 1, value: 8, onChanged: (_) {}),
            SetRow(
              set: const WorkoutSet(
                id: 'b',
                type: SetType.normal,
                weight: '20',
                reps: '8',
                carried: true,
                side: SetSide.right,
              ),
              index: 2,
              unilateral: true,
              onToggle: () {},
              onCycleType: () {},
              onToggleSide: () {},
              onEdit: (_) {},
            ),
            SetRow(
              set: const WorkoutSet(
                id: 'c',
                type: SetType.normal,
                weight: '60',
                reps: '5',
                done: true,
                rpe: 6,
              ),
              index: 3,
              onToggle: () {},
              onCycleType: () {},
              onOpenRpe: () {},
              onEdit: (_) {},
            ),
          ],
        ),
      ),
    );
  });

  // ------------------------------------------------------------- Modul 7
  //
  // Formulare sind der härteste Fall der Matrix: Neun Muskelschalter und fünf
  // Schwierigkeitssegmente stehen bei 200 % Schrift auf 320 dp nebeneinander,
  // und Eingabefelder werden von `androidTapTargetGuideline` nicht verschont.

  testWidgets('Übung anlegen erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const ExerciseFormScreen());
  });

  testWidgets('Übung bearbeiten erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(
        tester, ExerciseFormScreen(original: fixtureExercises.last));
  });

  testWidgets('Eigene Fassung anlegen erfüllt den A11y-Vertrag',
      (tester) async {
    await expectA11y(
        tester, ExerciseFormScreen(copyOf: fixtureExercises.first));
  });

  testWidgets('Plan anlegen erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const PlanFormScreen());
  });

  testWidgets('Plan bearbeiten mit Lücke erfüllt den A11y-Vertrag',
      (tester) async {
    // Der Plan aus den Vorlagen trägt bewusst einen Eintrag auf eine gelöschte
    // Übung — die gestrichelte Lücke gehört damit in jede Zelle der Matrix.
    await expectA11y(tester, PlanFormScreen(original: fixturePlans.first));
  });

  testWidgets('Einheit bearbeiten erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, SessionEditScreen(session: fixtureSessions.first));
  });

  // ------------------------------------------------------------- Modul 8

  testWidgets('Übungswähler erfüllt den A11y-Vertrag', (tester) async {
    // Mehrfachauswahl, Filterleiste und der Weg zum Anlegen — alles in
    // einem Blatt, das bei 200 % Schrift nicht überlaufen darf.
    await expectA11y(tester, const _Sheet(child: ExercisePicker()));
  });

  testWidgets('Einstellungen erfüllen den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const SettingsScreen());
  });

  testWidgets('Info erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const InfoScreen());
  });

  testWidgets('Daten ausgeben erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const ExportScreen());
  });

  testWidgets('Konto löschen erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const AccountDeletionScreen());
  });

  testWidgets('Konto gelöscht erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const AccountDeletedScreen());
  });
}

/// Rahmt ein Blatt, damit die Matrix es wie einen Bildschirm prüfen kann.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AtemColors.base,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AtemSpacing.screenPadding),
            child: SingleChildScrollView(child: child),
          ),
        ),
      );
}

/// Ein Abschnitt des One-Pagers steht für sich in keinem Scroll-Container —
/// die Seite scrollt als Ganzes. Für die Prüfmatrix bekommt er einen, sonst
/// läuft er auf 320x640 über und jeder Befund wäre ein Layoutfehler.
Widget _scrolled(Widget section) => Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(child: SingleChildScrollView(child: section)),
    );

/// Eine Uhr-Quelle im Speicher — nur so weit, wie die Prüfmatrix sie braucht.
class _HealthRepo implements HealthSessionRepository {
  _HealthRepo(this.sessions);

  final List<HealthSession> sessions;

  @override
  Stream<List<HealthSession>> watch(String userId) => Stream.value(sessions);
  @override
  Future<List<HealthSession>> fetch(String userId) async => sessions;
  @override
  Future<void> save(String userId, HealthSession session) async {}
  @override
  Future<void> delete(String userId, String externalId) async {}
  @override
  Future<DateTime?> lastRead(String userId) async =>
      DateTime(2026, 9, 20, 7, 12);
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

final _healthPending = [
  HealthSession.pending(
    MeasuredSession(
      id: 'hc-1',
      start: DateTime(2026, 9, 20, 9, 14),
      end: DateTime(2026, 9, 20, 9, 56),
      sourceId: 'com.garmin.android.apps.connectmobile',
      activity: 'RUNNING',
      deviceName: 'Garmin',
      averageHeartRate: 148,
      maxHeartRate: 171,
      calories: 412,
    ),
    DateTime(2026, 9, 20, 7, 12),
  ),
];

/// Die Überschreibungen, die den Eingang füllen.
final healthOverrides = [
  healthSessionRepositoryProvider.overrideWithValue(_HealthRepo(_healthPending)),
  currentUserIdProvider.overrideWithValue('u'),
];
