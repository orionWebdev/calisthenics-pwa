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
import 'package:atem/features/workout/presentation/widgets/train_section.dart';
import 'package:atem/features/strength/presentation/screens/strength_form_screen.dart';
import 'package:atem/features/strength/presentation/screens/strength_screen.dart';
import 'package:atem/features/cardio/presentation/screens/cardio_screen.dart';
import 'package:atem/features/cardio/presentation/screens/cardio_form_screen.dart';
import 'package:atem/features/cardio/presentation/screens/cardio_live_screen.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:atem/features/workout/domain/workout_session.dart';
import 'package:atem/features/workout/presentation/widgets/set_effort.dart';
import 'package:atem/features/workout/presentation/widgets/set_row.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/exercises/presentation/exercise_picker.dart';
import 'package:atem/features/plans/presentation/widgets/plans_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

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
