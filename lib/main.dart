import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/gen/app_l10n.dart';

import 'core/theme/theme.dart';
import 'core/widgets/widgets.dart';
import 'app/app_shell.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/settings/application/settings_providers.dart';
import 'features/workout/domain/workout_start.dart';
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

  // Keine Überschreibungen mehr: Jeder Bereich baut sein Repository selbst.
  runApp(const ProviderScope(child: AtemApp()));
}

/// Der Rahmen — und die eine Stelle, an der Einstellungen auf die ganze App
/// wirken.
///
/// Sprache und Haptik sind keine Bildschirmzustände, sondern Eigenschaften der
/// Anwendung. Sie werden deshalb hier abgegriffen und nicht dort, wo sie
/// benutzt werden.
class AtemApp extends ConsumerWidget {
  const AtemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prozessweit, wie die Schriftskalierung — die Begründung steht am
    // Schalter selbst (`AtemHaptic.enabled`).
    AtemHaptic.enabled = ref.watch(hapticsEnabledProvider);

    return MaterialApp(
      // Markenname, bewusst nicht lokalisiert.
      title: 'ATEM Hybrid',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      // `null` heisst: Das System entscheidet. Genau das soll gelten, solange
      // nichts hinterlegt ist — und nur solange.
      locale: ref.watch(localeProvider),
      theme: AtemTheme.dark,
      themeMode: ThemeMode.dark,
      // Das Tor entscheidet: ohne Anmeldung kommt niemand an Daten, weil die
      // Firestore-Regeln sie ohnehin verweigern würden. Dahinter trägt der
      // Rahmen die Tabs.
      home: const AuthGate(child: AppShell()),
      onGenerateRoute: (settings) {
        if (settings.name == WorkoutRunnerScreen.routeName) {
          // Ohne Argument: freies Training. Vorher stand hier eine
          // Zeichenkette, die mal Plan-Kennung und mal leer bedeutete.
          final launch = settings.arguments as WorkoutLaunch? ??
              const WorkoutLaunch(WorkoutStart.free());
          return MaterialPageRoute<void>(
            builder: (_) => WorkoutRunnerScreen(
              start: launch.start,
              readiness: launch.readiness,
            ),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
