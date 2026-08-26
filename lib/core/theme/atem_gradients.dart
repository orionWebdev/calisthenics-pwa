import 'package:flutter/widgets.dart';

import 'atem_colors.dart';

/// Material's `Colors` gehört nicht in eine Token-Datei.
const _white = Color(0xFFFFFFFF);

// ---------------------------------------------------------------------------
// GRADIENTEN
// ---------------------------------------------------------------------------

abstract final class AtemGradients {
  /// Cyan → Violet → Magenta. Arc-Gauge, Chart-Linie, Primary Button.
  static const neonWave = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AtemColors.cyan, AtemColors.violetLight, AtemColors.magenta],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gradient-Border der Hero-/Session-Card (135°).
  static const cardBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AtemColors.cyan, AtemColors.violet, AtemColors.magenta],
    stops: [0.0, 0.55, 1.0],
  );

  /// Marken-CTA: Deep Rose → Magenta.
  static const brandCta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AtemColors.magentaDeep, AtemColors.magenta],
  );

  /// Recovery-Verlauf — Green → Cyan.
  static const recovery = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AtemColors.green, AtemColors.cyan],
  );

  /// Avatar-Ring (SweepGradient als Ersatz für CSS conic-gradient).
  static const avatarRing = SweepGradient(
    colors: [
      AtemColors.cyan,
      AtemColors.violetLight,
      AtemColors.magenta,
      AtemColors.green,
      AtemColors.cyan,
    ],
  );

  /// Glas-Highlight: heller Lichtstreif von oben links über die Card.
  static final glassSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      _white.withValues(alpha: 0.06),
      _white.withValues(alpha: 0.015),
      _white.withValues(alpha: 0.0),
    ],
    stops: const [0.0, 0.45, 1.0],
  );

  /// Chart-Area-Fill (vertikal auslaufend).
  static final chartArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AtemColors.cyan.withValues(alpha: 0.22),
      AtemColors.violet.withValues(alpha: 0.08),
      AtemColors.base.withValues(alpha: 0.0),
    ],
    stops: const [0.0, 0.6, 1.0],
  );

  /// Verlauf für einen einzelnen Akzent (Buttons, Fortschrittsbalken).
  static LinearGradient accent(Color c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c, Color.lerp(c, AtemColors.violet, 0.45)!],
      );
}
