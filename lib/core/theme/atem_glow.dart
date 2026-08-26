import 'package:flutter/widgets.dart';

import 'atem_colors.dart';

// ---------------------------------------------------------------------------
// NEON-GLOW
// ---------------------------------------------------------------------------

abstract final class AtemGlow {
  /// Weicher Halo hinter Cards und Icon-Boxen.
  static List<BoxShadow> soft(Color c, {double opacity = 0.5}) => [
        BoxShadow(
          color: c.withValues(alpha: opacity),
          blurRadius: 26,
          spreadRadius: -8,
        ),
      ];

  /// Harter kleiner Punkt-Glow (Live-Dots, Status-Indikatoren).
  static List<BoxShadow> dot(Color c) => [
        BoxShadow(color: c, blurRadius: 8),
      ];

  /// Text-Glow als Shadow-Liste für [TextStyle.shadows].
  static List<Shadow> text(Color c, {double opacity = 0.55}) => [
        Shadow(color: c.withValues(alpha: opacity), blurRadius: 14),
      ];

  /// Ambienter Grund-Schatten unter Glas-Flächen.
  static const List<BoxShadow> ambient = [
    BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, 10)),
  ];

  /// Pulsierender Primary-Button — Endzustände für einen AnimationController.
  static final List<BoxShadow> buttonPulseLow = [
    BoxShadow(
        color: AtemColors.magenta.withValues(alpha: 0.55),
        blurRadius: 18,
        spreadRadius: -2),
    BoxShadow(
        color: AtemColors.cyan.withValues(alpha: 0.40),
        blurRadius: 34,
        spreadRadius: -6),
  ];

  static final List<BoxShadow> buttonPulseHigh = [
    BoxShadow(
        color: AtemColors.magenta.withValues(alpha: 0.85),
        blurRadius: 32,
        spreadRadius: 2),
    BoxShadow(
        color: AtemColors.cyan.withValues(alpha: 0.65),
        blurRadius: 50,
        spreadRadius: -2),
  ];

  /// Floating Bottom-Nav.
  static final List<BoxShadow> nav = [
    const BoxShadow(
        color: Color(0xA6000000), blurRadius: 32, offset: Offset(0, 8)),
    BoxShadow(
        color: AtemColors.cyan.withValues(alpha: 0.40),
        blurRadius: 30,
        spreadRadius: -14),
  ];
}
