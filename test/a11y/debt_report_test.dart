@Tags(['debt'])
library;

import 'package:atem/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Erzeugt die Zahlen für docs/foundation_debt.md.
///
/// Bewusst kein Tor — dieser Test schlägt nie fehl. Er misst nur.
///
/// **Er misst dieselbe Matrix wie das Tor.** Die erste Fassung lief gegen eine
/// einzelne Zelle von 390x1400 dp bei Skalierung 1,0 — ein Bildschirm, der
/// höher ist als jedes echte Gerät. Dort läuft nichts über, nichts wird am
/// `ClipRRect` beschnitten, und der Bericht meldete null, während das Tor rot
/// war. Ein Messgerät, das lockerer misst als die Prüfung, ist schlimmer als
/// keines: Es meldet Entwarnung. Beide teilen sich jetzt
/// [collectA11yFindings] als einzige Quelle.
Future<void> _report(WidgetTester tester, String name, Widget home) async {
  final findings = await collectA11yFindings(tester, home);

  final counts = <String, int>{};
  for (final f in findings) {
    counts[f.rule] = (counts[f.rule] ?? 0) + 1;
  }

  debugPrint('### $name  (${a11ySizes.length} Breiten x '
      '${a11yTextScales.length} Skalierungen)');
  debugPrint('layout: ${counts['layout'] ?? 0}  '
      'tap-target: ${counts['tap-target'] ?? 0}  '
      'label: ${counts['label'] ?? 0}');
  for (final f in findings) {
    debugPrint('  $f');
  }
}

void main() {
  testWidgets('Schuldenbericht Dashboard', (tester) async {
    await _report(tester, 'Dashboard', const DashboardScreen());
  });

  testWidgets('Schuldenbericht Workout Runner', (tester) async {
    await _report(tester, 'Workout Runner',
        const WorkoutRunnerScreen(start: WorkoutStart(planId: 'p1')));
  });
}
