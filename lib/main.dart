import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/gen/app_l10n.dart';

import 'core/theme/theme.dart';
import 'app/app_shell.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/workout/application/workout_providers.dart';
import 'features/workout/data/preview_workout_repository.dart';
import 'features/workout/presentation/screens/workout_runner_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ohne Optionen: Auf Android liest firebase_core die
  // android/app/google-services.json, die das Gradle-Plugin einbettet. Eine
  // generierte firebase_options.dart bringt erst etwas, wenn eine zweite
  // Plattform dazukommt — bis dahin wäre sie eine zweite Wahrheit.
  await Firebase.initializeApp();

  // Offline-Persistenz ersetzt die lokale Datenbank, die im Gemini-Entwurf
  // stand (Vertrag 3, „Getroffene Entscheidungen"). Sie muss vor der ersten
  // Abfrage gesetzt werden, sonst greift sie nicht.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    ProviderScope(
      overrides: [
        // Das Dashboard liest seit Stufe 6 aus Firestore. Der Runner noch
        // nicht — sein Schreibpfad ist der nächste Schritt.
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
      // Das Tor entscheidet: ohne Anmeldung kommt niemand an Daten, weil die
      // Firestore-Regeln sie ohnehin verweigern würden. Dahinter trägt der
      // Rahmen die Tabs.
      home: const AuthGate(child: AppShell()),
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
