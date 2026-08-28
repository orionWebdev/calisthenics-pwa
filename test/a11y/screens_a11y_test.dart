@Tags(['a11y'])
library;

import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:atem/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:atem/features/auth/presentation/screens/splash_screen.dart';
import 'package:atem/features/auth/presentation/screens/waiting_room_screen.dart';
import 'package:atem/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_form_screen.dart';
import 'package:atem/features/history/presentation/screens/analysis_screen.dart';
import 'package:atem/features/history/presentation/screens/history_screen.dart';
import 'package:atem/features/history/presentation/screens/session_detail_screen.dart';
import 'package:atem/features/history/presentation/screens/session_edit_screen.dart';
import 'package:atem/features/history/presentation/screens/session_list_screen.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_list_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_detail_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_form_screen.dart';
import 'package:atem/features/settings/presentation/screens/account_deletion_screen.dart';
import 'package:atem/features/settings/presentation/screens/settings_screen.dart';
import 'package:atem/features/plans/presentation/screens/plan_list_screen.dart';
import 'package:atem/features/workout/presentation/screens/workouts_screen.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/exercises/presentation/exercise_picker.dart';
import 'package:flutter/material.dart';
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

  testWidgets('Verlauf erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const HistoryScreen());
  });

  testWidgets('Einheitenliste erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const SessionListScreen());
  });

  testWidgets('Einheitendetail erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(
        tester, SessionDetailScreen(session: fixtureSessions.first));
  });

  testWidgets('Auswertung erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const AnalysisScreen());
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
    await expectA11y(
        tester, SessionEditScreen(session: fixtureSessions.first));
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
