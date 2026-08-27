@Tags(['a11y'])
library;

import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:atem/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:atem/features/auth/presentation/screens/splash_screen.dart';
import 'package:atem/features/auth/presentation/screens/waiting_room_screen.dart';
import 'package:atem/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_list_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_detail_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_list_screen.dart';
import 'package:atem/features/workout/presentation/screens/workouts_screen.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

void main() {
  testWidgets('Dashboard erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, DashboardScreen(onSelectTab: (_) {}));
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

  testWidgets('Workouts-Tab erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, WorkoutsScreen(onStart: (_) {}));
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

  testWidgets('Workout Runner erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(
      tester,
      const WorkoutRunnerScreen(sessionId: 'test-session'),
    );
  });
}
