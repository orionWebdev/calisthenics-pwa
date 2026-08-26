import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_user.dart';

/// Anmeldung — ein Knopf, kein Entwurf.
///
/// Der gestaltete Bildschirm kommt in Stufe 7 aus dem Design-Gespräch. Bis
/// dahin steht hier das Nötigste, aber **aus den Primitiven** und mit allen
/// Verträgen: kein Textliteral, Trefferflächen über [AtemTappable], Fehler als
/// Live-Region. Ein Wegwerfbildschirm hätte genau die Muster erzeugt, die
/// Stufe 5 gerade beseitigt hat.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  AuthFailure? _failure;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Kein Navigator-Aufruf: Der Anmeldezustand trägt die App weiter.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        // Abbruch durch den Nutzer ist keine Störung und bekommt keine Meldung.
        _failure = e.failure == AuthFailure.abgebrochen ? null : e.failure;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AtemSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.authWelcome,
                    textAlign: TextAlign.center,
                    style: AtemType.titleLarge.of(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.authIntro,
                    textAlign: TextAlign.center,
                    style: AtemType.body.of(context),
                  ),
                  const SizedBox(height: AtemSpacing.cardGap),
                  if (_failure != null) ...[
                    AtemErrorState(
                      title: _failureTitle(l10n, _failure!),
                      body: _failureBody(l10n, _failure!),
                    ),
                    const SizedBox(height: AtemSpacing.cardGap),
                  ],
                  AtemButton.gradient(
                    label: _busy ? l10n.authSigningIn : l10n.authGoogle,
                    semanticLabel: _busy ? l10n.authSigningIn : l10n.authGoogle,
                    // Der Kreisel gehört laut Zustandsvertrag in den
                    // auslösenden Knopf, nicht über den ganzen Bildschirm.
                    leading: _busy ? const AtemButtonSpinner() : null,
                    onPressed: _busy ? null : _signIn,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _failureTitle(AppL10n l10n, AuthFailure failure) => switch (failure) {
        AuthFailure.netzwerk => l10n.authNetworkTitle,
        AuthFailure.nichtFreigeschaltet => l10n.authNotAllowedTitle,
        _ => l10n.authFailedTitle,
      };

  String _failureBody(AppL10n l10n, AuthFailure failure) => switch (failure) {
        AuthFailure.netzwerk => l10n.authNetworkBody,
        AuthFailure.nichtFreigeschaltet => l10n.authNotAllowedBody,
        _ => l10n.authFailedBody,
      };
}
