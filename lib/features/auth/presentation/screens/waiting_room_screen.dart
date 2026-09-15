import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_user.dart';

/// Der Warteraum — angemeldet, aber noch kein Platz in der Beta.
///
/// ## Warum das ein eigener Bildschirm ist
///
/// Naheliegend wäre eine Meldung neben dem Anmeldeknopf gewesen. Sie hätte den
/// Zustand als Störung geparkt — obwohl die Anmeldung **erfolgreich war**. Hier
/// bekommt er eine eigene Adresse und einen Wiedereinstieg: Beim nächsten Start
/// landet dieselbe Person wieder hier, nicht auf dem Login.
///
/// **Cyan, nicht Magenta.** Cyan ist die Statusfarbe des Systems; Magenta hätte
/// gesagt „du hast etwas falsch gemacht".
class WaitingRoomScreen extends ConsumerStatefulWidget {
  const WaitingRoomScreen({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  bool _checking = false;

  /// Das Ergebnis der letzten Prüfung, oder `null`, wenn noch keine lief.
  String? _result;

  Future<void> _recheck() async {
    final l10n = AppL10n.of(context);
    setState(() {
      _checking = true;
      _result = null;
    });
    try {
      final allowed =
          await ref.read(allowlistRepositoryProvider).isAllowed(widget.user);
      if (!mounted) return;
      if (allowed) {
        // Freigeschaltet: Der Zugangszustand wird neu gebildet und trägt die
        // App weiter. Kein Navigator-Aufruf.
        ref.invalidate(accessProvider);
        return;
      }
      setState(() => _result = l10n.gateRecheckNegative);
    } catch (_) {
      if (!mounted) return;
      // Ohne Netz ist die Antwort unbekannt — und unbekannt darf nicht als
      // „nein" durchgehen.
      setState(() => _result = l10n.gateRecheckOffline);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _switchAccount() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final email = widget.user.email;

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
                  const Align(child: _WaitGlyph()),
                  const SizedBox(height: 20),
                  Align(
                    child: AtemBadge(
                      label: l10n.gateStatus,
                      // Klartext statt Grossbuchstaben-Kürzel: „WARTELISTE"
                      // buchstabiert ein Screenreader womöglich.
                      semanticLabel: l10n.gateStatusA11y,
                      accent: AtemColors.cyan,
                      leadingDot: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.gateTitle,
                    textAlign: TextAlign.center,
                    style: AtemType.titleLarge.of(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.gateBody,
                    textAlign: TextAlign.center,
                    style: AtemType.labelSmall.of(context),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      label: l10n.gateSignedInAs(email),
                      child: ExcludeSemantics(
                        child: AtemStatBox(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Text(
                            l10n.gateSignedInAs(email),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            // Die volle Adresse steckt im Semantics-Label —
                            // abgeschnitten ist sie nur im Bild.
                            overflow: TextOverflow.ellipsis,
                            style: AtemType.meta.of(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AtemButton.outline(
                    label: _checking ? l10n.gateRechecking : l10n.gateRecheck,
                    semanticLabel:
                        _checking ? l10n.gateRechecking : l10n.gateRecheckA11y,
                    accent: AtemColors.cyan,
                    leading: _checking ? const AtemButtonSpinner() : null,
                    onPressed: _checking ? null : _recheck,
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _result!,
                        textAlign: TextAlign.center,
                        style: AtemType.labelSmall.of(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  AtemButton.ghost(
                    label: l10n.gateSwitchAccount,
                    // Die Langform verschweigt das Abmelden nicht.
                    semanticLabel: l10n.gateSwitchAccountA11y,
                    size: AtemButtonSize.compact,
                    onPressed: _checking ? null : _switchAccount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sanduhr in getönter Icon-Box.
class _WaitGlyph extends StatelessWidget {
  const _WaitGlyph();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AtemColors.cyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AtemRadii.iconBox),
            border: Border.all(color: AtemColors.cyan.withValues(alpha: 0.35)),
          ),
          child: CustomPaint(
            size: const Size.square(22),
            painter: _HourglassPainter(),
          ),
        ),
      );
}

class _HourglassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AtemColors.cyan;

    canvas.drawLine(
        Offset(s * 0.22, s * 0.14), Offset(s * 0.78, s * 0.14), paint);
    canvas.drawLine(
        Offset(s * 0.22, s * 0.86), Offset(s * 0.78, s * 0.86), paint);
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.3, s * 0.14)
        ..lineTo(s * 0.3, s * 0.34)
        ..lineTo(s * 0.5, s * 0.5)
        ..lineTo(s * 0.7, s * 0.34)
        ..lineTo(s * 0.7, s * 0.14),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.3, s * 0.86)
        ..lineTo(s * 0.3, s * 0.66)
        ..lineTo(s * 0.5, s * 0.5)
        ..lineTo(s * 0.7, s * 0.66)
        ..lineTo(s * 0.7, s * 0.86),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HourglassPainter oldDelegate) => false;
}
