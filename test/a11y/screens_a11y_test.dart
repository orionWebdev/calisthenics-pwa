@Tags(['a11y'])
library;

import 'package:atem/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

void main() {
  testWidgets('Dashboard erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(tester, const DashboardScreen());
  });

  testWidgets('Workout Runner erfüllt den A11y-Vertrag', (tester) async {
    await expectA11y(
      tester,
      const WorkoutRunnerScreen(sessionId: 'test-session'),
    );
  });
}
