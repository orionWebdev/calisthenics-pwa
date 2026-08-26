import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../application/auth_providers.dart';
import 'screens/sign_in_screen.dart';

/// Entscheidet, was die App überhaupt zeigt.
///
/// Kein `Navigator`-Wechsel: Der Anmeldezustand ist ein Strom, und wer sich
/// abmeldet, soll nicht über einen Stapel zurückkommen können. Das Tor
/// **ersetzt** den Inhalt, statt etwas darüberzulegen.
///
/// Der erste Frame ist unentschieden — Firebase kennt den gespeicherten Nutzer
/// noch nicht. Solange steht hier ein Platzhalter und **nicht** der
/// Anmeldebildschirm: Sonst blitzte er bei jedem Start kurz auf, obwohl der
/// Nutzer längst angemeldet ist.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);

    return ref.watch(authStateProvider).when(
          loading: () => Scaffold(
            backgroundColor: AtemColors.base,
            body: Padding(
              padding: EdgeInsets.fromLTRB(
                AtemSpacing.screenPadding,
                MediaQuery.paddingOf(context).top + 16,
                AtemSpacing.screenPadding,
                130,
              ),
              child: AtemSkeleton(
                semanticLabel: l10n.dashboardLoadingA11y,
                blocks: const [
                  AtemSkeletonBlock(height: 64, radius: 14),
                  AtemSkeletonBlock(height: 360),
                ],
              ),
            ),
          ),
          // Auch ein Fehler im Anmeldestrom führt auf die Anmeldung. Alles
          // andere hiesse: App unbedienbar, ohne Weg heraus.
          error: (_, __) => const SignInScreen(),
          data: (user) => user == null ? const SignInScreen() : child,
        );
  }
}
