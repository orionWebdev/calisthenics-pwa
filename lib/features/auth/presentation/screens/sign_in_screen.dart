import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_user.dart';
import '../widgets/brand_block.dart';
import '../widgets/google_button.dart';

/// Anmeldung zur geschlossenen Beta.
///
/// Ein Layout trägt alle fünf Zustände ohne Sprung: Standard, Anmeldung läuft,
/// Abbruch, kein Netz, unbekannter Fehler. Die Statuszone über dem Knopf ist
/// ohne Meldung null Pixel hoch, der Markenblock sitzt auf derselben Achse wie
/// im Splash und bewegt sich nie.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  AuthFailure? _failure;

  /// Damit der Fokus nach einem Abbruch dorthin zurückkehrt, wo er war.
  final _buttonFocus = FocusNode();

  @override
  void dispose() {
    _buttonFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Kein Navigator-Aufruf: Der Zugangszustand trägt die App weiter.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        // **Der Abbruch bleibt still.** Wer die Kontoauswahl selbst schliesst,
        // hat eine Entscheidung getroffen, keinen Fehler gemacht. Jede Meldung
        // würde ihm einen zuweisen und einem Screenreader einen sinnlosen
        // Alert vorlesen.
        _failure = e.failure == AuthFailure.abgebrochen ? null : e.failure;
      });
      if (e.failure == AuthFailure.abgebrochen) {
        _buttonFocus.requestFocus();
      }
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
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(child: BrandBlock()),
                  const SizedBox(height: 20),
                  Align(
                    child: AtemBadge(
                      label: l10n.authBetaBadge,
                      accent: AtemColors.cyan,
                      leadingDot: true,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Statuszone: ohne Meldung null Pixel hoch, damit kein
                  // Leerraum entsteht, der wie ein Fehler aussieht, der noch
                  // kommt.
                  AtemNoticeSlot(notice: _notice(l10n)),

                  GoogleButton(
                    focusNode: _buttonFocus,
                    busy: _busy,
                    onPressed: _signIn,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.authLegal,
                    textAlign: TextAlign.center,
                    style: AtemType.labelSmall.of(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _notice(AppL10n l10n) {
    final failure = _failure;
    if (failure == null) return null;

    if (failure == AuthFailure.netzwerk) {
      return AtemNotice(
        title: l10n.authNetworkTitle,
        body: l10n.authNetworkBody,
        semanticLabel: '${l10n.authNetworkTitle}. ${l10n.authNetworkBody}',
      );
    }

    // Der Code gehört ins Vorlese-Label, nicht nur ins Bild: Beim Support-Anruf
    // ist genau er die Frage.
    final code = l10n.authErrorCode(_codeFor(failure));
    return AtemNotice(
      tone: AtemNoticeTone.error,
      title: l10n.authFailedTitle,
      body: l10n.authFailedBody,
      code: code,
      semanticLabel: '${l10n.authFailedTitle}. ${l10n.authFailedBody} $code',
    );
  }

  /// Ein stabiler, nennbarer Code je Fehlerart. Nicht die Rohmeldung des
  /// Anbieters — die wechselt und ist am Telefon nicht vorlesbar.
  String _codeFor(AuthFailure failure) => switch (failure) {
        AuthFailure.netzwerk => 'AUTH-503',
        AuthFailure.nichtFreigeschaltet => 'AUTH-403',
        _ => 'AUTH-500',
      };
}
