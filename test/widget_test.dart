
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/workout/application/workout_providers.dart';
import 'package:atem/features/workout/data/preview_workout_repository.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:atem/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dashboard rendert Readiness-Score und Session', (tester) async {
    // Hohe Testfläche: die ListView baut lazy, sonst liegt die Session-Card
    // im 800x600-Default unterhalb der Kante und existiert nicht im Baum.
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider
              .overrideWithValue(PreviewDashboardRepository()),
          workoutRepositoryProvider
              .overrideWithValue(PreviewWorkoutRepository()),
        ],
        child: const AtemApp(),
      ),
    );

    // Kein pumpAndSettle: Brand-Dot, LIVE-Puls und Button-Glow laufen als
    // Endlosschleifen, der Baum kommt nie zur Ruhe. Stattdessen gezielt
    // vorspulen, bis der Score-Count-up (1400 ms) durch ist.
    await tester.pump(); // Stream auflösen
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('ATEM READINESS'), findsOneWidget);
    expect(find.text('HEUTIGE SESSION'), findsOneWidget);
    expect(find.textContaining('SESSION STARTEN'), findsOneWidget);
  });

  testWidgets('Workout Runner rendert Sätze und startet den Pausen-Timer',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutRepositoryProvider
              .overrideWithValue(PreviewWorkoutRepository()),
        ],
        child: const MaterialApp(
          home: WorkoutRunnerScreen(sessionId: 'test-session'),
        ),
      ),
    );
    await tester.pump(); // Future des Repositories auflösen

    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('ÜBUNG 1 / 3'), findsOneWidget);
    // Ein Satz ist in der Fixture bereits abgehakt.
    expect(find.text('1 VON 10 SÄTZEN ABGESCHLOSSEN'), findsOneWidget);
    // Pausen-Timer erscheint erst nach dem Abhaken.
    expect(find.text('PAUSE'), findsNothing);

    await tester.tap(find.byIcon(Icons.check_rounded).at(1));
    await tester.pump();

    expect(find.text('2 VON 10 SÄTZEN ABGESCHLOSSEN'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
  });
}
