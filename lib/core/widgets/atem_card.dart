import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_glow.dart';
import '../theme/atem_gradients.dart';
import 'atem_tappable.dart';

/// Die drei Kartenrezepte — und bewusst kein viertes.
///
/// Ein vierter Kandidat (StatBox als eigenständige Karte) wurde verworfen:
/// `#1A1A26` auf `#050507` hat zu wenig Abstand zur Listenkarte, und jede
/// weitere Variante verwässert die Frage „welche nehme ich?". Die StatBox
/// bleibt Einlage — siehe [AtemStatBox].
enum _CardRecipe { glass, gradientBorder, list }

class AtemCard extends StatelessWidget {
  /// **K1 — Glaskarte.** Milchglas über sichtbarem Hintergrund.
  ///
  /// `BackdropFilter` kostet je Aufruf einen eigenen Render-Durchgang.
  /// **Höchstens drei je Bildschirm**, und nur dort, wo tatsächlich etwas
  /// durchscheint. In Listen gehört [AtemCard.list] hin.
  const AtemCard.glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtemSpacing.cardPadding),
    this.glow,
    this.onTap,
    this.semanticLabel,
  })  : _recipe = _CardRecipe.glass,
        gradient = null;

  /// **K2 — Gradient-Rand.** Die eine hervorgehobene Karte.
  ///
  /// **Genau eine je Bildschirm.** Zwei nehmen sich gegenseitig die Wirkung.
  const AtemCard.gradientBorder({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.gradient = AtemGradients.cardBorder,
    this.glow = AtemColors.violet,
    this.onTap,
    this.semanticLabel,
  }) : _recipe = _CardRecipe.gradientBorder;

  /// **K3 — Listenkarte.** Deckend, kein Blur, kein Halo, kein Schatten.
  ///
  /// Der Standard ab vier Einträgen. Was hier blurrt, kostet Bildrate ohne
  /// sichtbaren Gewinn.
  const AtemCard.list({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtemSpacing.cardPadding),
    this.onTap,
    this.semanticLabel,
  })  : _recipe = _CardRecipe.list,
        gradient = null,
        glow = null;

  final _CardRecipe _recipe;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? glow;

  /// Antippbar? Dann ist [semanticLabel] Pflicht.
  final VoidCallback? onTap;
  final String? semanticLabel;

  static const _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final card = switch (_recipe) {
      _CardRecipe.glass => _glass(),
      _CardRecipe.gradientBorder => _gradientBorder(),
      _CardRecipe.list => _list(),
    };

    if (onTap == null) return card;
    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel!,
      excludeChildSemantics: false,
      minTapSize: Size.zero,
      child: card,
    );
  }

  Widget _glass() {
    const radius = AtemRadii.cardR;
    return DecoratedBox(
      // Schatten muss außerhalb des Clips liegen, sonst schneidet er ihn weg.
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          ...AtemGlow.ambient,
          if (glow != null) ...AtemGlow.soft(glow!, opacity: 0.28),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: AtemColors.cardTinted,
              borderRadius: radius,
              border: Border.all(color: AtemColors.border),
            ),
            // Sheen als eigene Schicht: in einer BoxDecoration verdrängt ein
            // gradient die color, und die Füllung verschwände.
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AtemGradients.glassSheen,
                borderRadius: radius,
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientBorder() {
    final outer = BorderRadius.circular(AtemRadii.card + _borderWidth);
    const inner = AtemRadii.cardR;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: outer,
        boxShadow: [
          ...AtemGlow.ambient,
          if (glow != null) ...AtemGlow.soft(glow!, opacity: 0.30),
        ],
      ),
      padding: const EdgeInsets.all(_borderWidth),
      child: Container(
        decoration: const BoxDecoration(
          // Deckend: der Rand darf nicht durch die Fläche bluten.
          color: Color(0xFF14141D),
          borderRadius: inner,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _list() => Container(
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: AtemRadii.cardR,
          border: Border.all(color: AtemColors.border),
        ),
        child: Padding(padding: padding, child: child),
      );
}

/// Einlage für Messwerte — **nie direkt auf dem Canvas**.
///
/// `#1A1A26` braucht eine Karte darunter, um sich abzuheben. Auf dem Canvas
/// sähe sie aus wie eine schlecht gemachte Listenkarte.
class AtemStatBox extends StatelessWidget {
  const AtemStatBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    this.glow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glow;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AtemColors.surfaceRaised,
          borderRadius: AtemRadii.statBoxR,
          border: Border.all(color: AtemColors.border),
          boxShadow: glow == null
              ? null
              : [
                  BoxShadow(
                    color: glow!.withValues(alpha: 0.28),
                    blurRadius: 20,
                    spreadRadius: -8,
                  ),
                ],
        ),
        child: child,
      );
}

/// Schwebende Leiste — Navigation, Pausen-Timer.
class AtemBar extends StatelessWidget {
  const AtemBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
    this.accent = AtemColors.cyan,
    this.radius = AtemRadii.pill,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color accent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: [
        const BoxShadow(
            color: Color(0xA6000000), blurRadius: 32, offset: Offset(0, 8)),
        BoxShadow(
          color: accent.withValues(alpha: 0.4),
          blurRadius: 30,
          spreadRadius: -14,
        ),
      ]),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AtemColors.surfaceSolid.withValues(alpha: 0.9),
              borderRadius: borderRadius,
              border:
                  Border.all(color: AtemColors.border.withValues(alpha: 0.95)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
