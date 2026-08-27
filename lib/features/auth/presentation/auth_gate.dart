import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';
import '../domain/access.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/waiting_room_screen.dart';

/// Entscheidet, was die App überhaupt zeigt.
///
/// Kein `Navigator`-Wechsel: Der Zugangszustand ist ein Strom, und wer sich
/// abmeldet, soll nicht über einen Stapel zurückkommen können. Das Tor
/// **ersetzt** den Inhalt, statt etwas darüberzulegen.
///
/// Fünf Zustände, vier Bildschirme:
///
/// | Zustand | Bildschirm |
/// |---|---|
/// | unentschieden | [SplashScreen] |
/// | abgemeldet | [SignInScreen] |
/// | angemeldet, nicht freigeschaltet | [WaitingRoomScreen] |
/// | freigeschaltet, kein Körpergewicht | [OnboardingScreen] |
/// | freigeschaltet | die App |
///
/// Der unentschiedene Zustand ist **nicht** dasselbe wie abgemeldet. Stünde
/// hier die Anmeldung, blitzte sie bei jedem Start auf, obwohl der Nutzer
/// längst angemeldet ist.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(accessProvider).when(
          // Zugangsliste und Profil werden noch abgefragt.
          loading: () => const SplashScreen(),
          // Scheitert die Prüfung, führt der Weg zur Anmeldung — nicht auf
          // einen Fehlerbildschirm. Alles andere hiesse: App unbedienbar, ohne
          // Weg heraus.
          error: (_, __) => const SignInScreen(),
          data: (state) => switch (state.stage) {
            AccessStage.undecided => const SplashScreen(),
            AccessStage.signedOut => const SignInScreen(),
            AccessStage.waitlisted => WaitingRoomScreen(user: state.user!),
            AccessStage.onboarding => OnboardingScreen(user: state.user!),
            AccessStage.granted => child,
          },
        );
  }
}
