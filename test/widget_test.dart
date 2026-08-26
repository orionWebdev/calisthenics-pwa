import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:atem/features/workout/application/workout_providers.dart';
import 'package:atem/features/workout/data/preview_workout_repository.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:atem/main.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _overrides = [
  dashboardRepositoryProvider.overrideWithValue(PreviewDashboardRepository()),
  workoutRepositoryProvider.overrideWithValue(PreviewWorkoutRepository()),
];

/// Hohe Testfläche: die ListView baut lazy, sonst liegt die Session-Card
/// unterhalb der Kante und existiert nicht im Baum.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumpt ein Widget mit abgeschalteten Animationen.
///
/// Das ist der Regelfall für Tests: Ohne `disableAnimations` laufen die
/// dekorativen Dauerschleifen endlos und `pumpAndSettle()` läuft in den Timeout.
Future<void> _pumpStill(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides,
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: home,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Dashboard rendert Readiness-Score und Session', (tester) async {
    _useTallSurface(tester);
    await _pumpStill(tester, const DashboardScreen());

    // Der eigentliche Beweis: mit abgeschalteten Animationen kommt der Baum
    // zur Ruhe. Vor der Einführung von AtemMotion.syncLoop hing das hier.
    await tester.pumpAndSettle();

    expect(find.text('ATEM READINESS'), findsOneWidget);
    expect(find.text('HEUTIGE SESSION'), findsOneWidget);
    expect(find.textContaining('SESSION STARTEN'), findsOneWidget);
    // Count-up ist ohne Animation sofort am Ziel.
    expect(find.text('89'), findsOneWidget);
  });

  testWidgets('Workout Runner rendert Sätze und startet den Pausen-Timer',
      (tester) async {
    _useTallSurface(tester);
    await _pumpStill(
      tester,
      const WorkoutRunnerScreen(sessionId: 'test-session'),
    );
    await tester.pump(); // Future des Repositories auflösen

    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('ÜBUNG 1 / 3'), findsOneWidget);
    expect(find.text('1 VON 10 SÄTZEN ABGESCHLOSSEN'), findsOneWidget);
    expect(find.text('PAUSE'), findsNothing);

    await tester.tap(find.byIcon(Icons.check_rounded).at(1));
    await tester.pump();

    expect(find.text('2 VON 10 SÄTZEN ABGESCHLOSSEN'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
  });

  testWidgets('AtemApp startet ohne Fehler', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides, child: const AtemApp()),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
