import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/gen/app_l10n.dart';

import 'core/theme/theme.dart';
import 'features/dashboard/application/dashboard_providers.dart';
import 'features/dashboard/data/preview_dashboard_repository.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/workout/application/workout_providers.dart';
import 'features/workout/data/preview_workout_repository.dart';
import 'features/workout/presentation/screens/workout_runner_screen.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // TODO: Gegen die Firestore-Implementierungen tauschen, sobald die
        // Datenanbindung steht.
        dashboardRepositoryProvider
            .overrideWithValue(PreviewDashboardRepository()),
        workoutRepositoryProvider.overrideWithValue(PreviewWorkoutRepository()),
      ],
      child: const AtemApp(),
    ),
  );
}

class AtemApp extends StatelessWidget {
  const AtemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Markenname, bewusst nicht lokalisiert.
      title: 'ATEM Hybrid',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: AtemTheme.dark,
      themeMode: ThemeMode.dark,
      home: const DashboardScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == WorkoutRunnerScreen.routeName) {
          final sessionId = settings.arguments as String? ?? '';
          return MaterialPageRoute<void>(
            builder: (_) => WorkoutRunnerScreen(sessionId: sessionId),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
