@Tags(['debt'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/a11y_audit.dart';

/// Erzeugt die Zahlen für docs/foundation_debt.md.
///
/// Bewusst kein Tor — dieser Test schlägt nie fehl. Er misst nur, damit der
/// Fortschritt in Stufe 5 überprüfbar ist.
Future<void> _report(WidgetTester tester, String name, Widget home) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final handle = tester.ensureSemantics();
  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides,
      child: MaterialApp(
        theme: AtemTheme.dark,
        home: home,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final violations = auditSemantics(tester);
  final counts = countByKind(violations);

  debugPrint('### $name');
  debugPrint('tap-target: ${counts['tap-target'] ?? 0}  '
      'label: ${counts['label'] ?? 0}');
  for (final v in violations) {
    debugPrint('  $v');
  }
  handle.dispose();
}

void main() {
  testWidgets('Schuldenbericht Dashboard', (tester) async {
    await _report(tester, 'Dashboard', const DashboardScreen());
  });

  testWidgets('Schuldenbericht Workout Runner', (tester) async {
    await _report(tester, 'Workout Runner',
        const WorkoutRunnerScreen(sessionId: 'test-session'));
  });
}
