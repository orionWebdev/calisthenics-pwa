import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_glow.dart';
import '../theme/atem_gradients.dart';

// ---------------------------------------------------------------------------
// GLASSMORPHISM
// ---------------------------------------------------------------------------

/// Rezepte für Dark Glassmorphism.
///
/// Der Effekt besteht immer aus drei Schichten:
///   1. `BackdropFilter` mit Blur (Milchglas)
///   2. halbtransparente Fläche in [AtemColors.card]
///   3. 1px Hairline-Border + optionaler Neon-Glow
///
/// Wichtig: `BackdropFilter` ist teuer. In langen Listen [AtemGlass.flat]
/// verwenden — visuell nah dran, aber ohne Blur-Pass.
abstract final class AtemGlass {
  static const blurSigma = 14.0;
  static const heavyBlurSigma = 28.0;

  /// Deckkraft der Glasfläche. Der Wert lebt bei den Farbtoken.
  static const tintAlpha = AtemColors.cardTintAlpha;

  /// Standard-Glasfläche.
  ///
  /// Enthält bewusst KEINEN Sheen-Gradient: In einer [BoxDecoration] gewinnt
  /// `gradient` gegen `color`, die Kartenfüllung würde also nie gemalt. Den
  /// Sheen als eigene Schicht darüberlegen — siehe [sheenOverlay].
  static BoxDecoration decoration({
    double radius = AtemRadii.card,
    Color? borderColor,
    Color? glow,
    double glowOpacity = 0.35,
  }) {
    return BoxDecoration(
      color: AtemColors.card.withValues(alpha: tintAlpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AtemColors.border, width: 1),
      boxShadow: [
        ...AtemGlow.ambient,
        if (glow != null) ...AtemGlow.soft(glow, opacity: glowOpacity),
      ],
    );
  }

  /// Lichtstreif-Schicht, die ÜBER die Glasfläche und UNTER den Inhalt gehört.
  static BoxDecoration sheenOverlay({double radius = AtemRadii.card}) {
    return BoxDecoration(
      gradient: AtemGradients.glassSheen,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Blurfreie Variante für Listen und Micro-Boxen.
  static BoxDecoration flat({
    double radius = AtemRadii.statBox,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: AtemColors.surfaceSolid,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AtemColors.border, width: 1),
    );
  }

  /// Getönte Akzent-Fläche (z. B. Recovery-Badge auf Green).
  static BoxDecoration tinted(
    Color accent, {
    double radius = AtemRadii.pill,
    double fill = 0.12,
    double borderAlpha = 0.35,
  }) {
    return BoxDecoration(
      color: accent.withValues(alpha: fill),
      borderRadius: BorderRadius.circular(radius),
      border:
          Border.all(color: accent.withValues(alpha: borderAlpha), width: 1),
    );
  }
}

/// Frosted-Glass-Card. Blur + Tint + Hairline-Border + optionaler Neon-Glow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtemSpacing.cardPadding),
    this.margin,
    this.radius = AtemRadii.card,
    this.blur = AtemGlass.blurSigma,
    this.glow,
    this.glowOpacity = 0.35,
    this.borderColor,
    this.sheen = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;

  /// Neon-Farbe für den Halo hinter der Card. `null` = kein Glow.
  final Color? glow;
  final double glowOpacity;
  final Color? borderColor;
  final bool sheen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    Widget content = DecoratedBox(
      // Schatten/Glow muss außerhalb des ClipRRect liegen.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          ...AtemGlow.ambient,
          if (glow != null) ...AtemGlow.soft(glow!, opacity: glowOpacity),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: AtemColors.card.withValues(alpha: AtemGlass.tintAlpha),
              borderRadius: borderRadius,
              border:
                  Border.all(color: borderColor ?? AtemColors.border, width: 1),
            ),
            // Sheen als eigene Schicht: in einer BoxDecoration würde ein
            // gradient die color verdrängen und die Füllung verschwinden.
            child: DecoratedBox(
              decoration: sheen
                  ? BoxDecoration(
                      gradient: AtemGradients.glassSheen,
                      borderRadius: borderRadius)
                  : const BoxDecoration(),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}

/// Glass-Card mit Neon-Gradient-Border — für die Hero-/Session-Card.
class GradientBorderGlassCard extends StatelessWidget {
  const GradientBorderGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtemSpacing.cardPadding),
    this.margin,
    this.radius = AtemRadii.card,
    this.borderWidth = 1.5,
    this.gradient = AtemGradients.cardBorder,
    this.blur = AtemGlass.blurSigma,
    this.glow = AtemColors.cyan,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double borderWidth;
  final Gradient gradient;
  final double blur;
  final Color? glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final outerRadius = BorderRadius.circular(radius + borderWidth);
    final innerRadius = BorderRadius.circular(radius);

    Widget content = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: outerRadius,
        boxShadow: [
          ...AtemGlow.ambient,
          if (glow != null) ...AtemGlow.soft(glow!, opacity: 0.30),
        ],
      ),
      padding: EdgeInsets.all(borderWidth),
      child: ClipRRect(
        borderRadius: innerRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              // Deckend: der Gradient-Rand darf nicht durch die Fläche bluten.
              color: const Color(0xFF07080D).withValues(alpha: 0.96),
              borderRadius: innerRadius,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: AtemGradients.glassSheen,
                  borderRadius: innerRadius),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
          onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
    }

    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}

/// Schwebende, milchige Bottom-Navigation / Toolbar.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.radius = AtemRadii.pill,
    this.blur = AtemGlass.heavyBlurSigma,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration:
          BoxDecoration(borderRadius: borderRadius, boxShadow: AtemGlow.nav),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AtemColors.card.withValues(alpha: 0.82),
              borderRadius: borderRadius,
              border: Border.all(
                  color: AtemColors.border.withValues(alpha: 0.9), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
