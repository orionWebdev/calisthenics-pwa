import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_glow.dart';
import '../theme/atem_gradients.dart';
import '../theme/atem_type.dart';
import 'atem_tappable.dart';

/// Höhe eines Buttons.
enum AtemButtonSize {
  /// 52 dp — die primäre Aktion eines Screens.
  regular(52),

  /// 48 dp — Aktionen in Leisten, Dialogen und Zeilen. Das Minimum.
  compact(48);

  const AtemButtonSize(this.height);
  final double height;
}

/// Buttons der App.
///
/// Ersetzt fünf handgebaute Gradient-Pillen und vier Outline-Varianten.
/// Beschriftung immer [AtemType.labelMedium] — bewusst 14 sp und nicht 12:
/// Auf einem Gradient wäre 12 sp schwächer als die Unterzeilen daneben, und
/// die CTA-Hierarchie kippt (Entscheidungsprotokoll Nr. 4).
///
/// Die Höhe ist eine Untergrenze, keine feste Größe — bei großer Systemschrift
/// wächst der Button mit, statt den Text zu beschneiden.
class AtemButton extends StatelessWidget {
  /// Verlaufsgefüllt. Die primäre Aktion.
  const AtemButton.gradient({
    super.key,
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.gradient = AtemGradients.neonWave,
    this.leading,
    this.size = AtemButtonSize.regular,
    this.expand = true,
    this.glow,
    this.haptic = AtemHaptic.medium,
  })  : _variant = _Variant.gradient,
        accent = null;

  /// Umrandet. Sekundäre Aktionen, Abbrechen, laufende Zustände.
  const AtemButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.accent,
    this.leading,
    this.size = AtemButtonSize.compact,
    this.expand = true,
    this.glow,
    this.haptic = AtemHaptic.selection,
  })  : _variant = _Variant.outline,
        gradient = null;

  /// Ohne Rahmen und Fläche. Für nachgeordnete Aktionen.
  const AtemButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.accent,
    this.leading,
    this.size = AtemButtonSize.compact,
    this.expand = false,
    this.haptic = AtemHaptic.selection,
  })  : _variant = _Variant.ghost,
        gradient = null,
        glow = null;

  final _Variant _variant;

  final String label;

  /// `null` deaktiviert den Button — Semantics meldet das mit.
  final VoidCallback? onPressed;

  /// Was ein Screenreader ansagt. Oft identisch mit [label], aber nicht immer:
  /// „SESSION LÄUFT · 04:12" liest sich besser als
  /// „Session läuft, 4 Minuten 12 Sekunden, tippen zum Stoppen".
  final String semanticLabel;

  /// Ergänzt das Label um das Warum — vor allem bei gesperrten Knöpfen.
  /// „Körpergewicht fehlt" beantwortet die Frage, die ein toter Knopf sonst
  /// offenlässt.
  final String? semanticHint;

  final Gradient? gradient;

  /// Akzentfarbe für Rand und Beschriftung bei Outline und Ghost.
  final Color? accent;

  final Widget? leading;
  final AtemButtonSize size;

  /// Volle Breite einnehmen.
  final bool expand;

  /// Farbe für einen Halo hinter dem Button.
  final Color? glow;

  final AtemHaptic haptic;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AtemColors.cyan;
    final labelColor = switch (_variant) {
      _Variant.gradient => AtemColors.textPrimary,
      _Variant.outline || _Variant.ghost => tint,
    };

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 9)],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AtemType.labelMedium.of(context).copyWith(
                  color: _enabled ? labelColor : AtemColors.textDisabled,
                ),
          ),
        ),
      ],
    );

    final decorated = Container(
      // Untergrenze statt fester Höhe: bei großer Schrift wächst der Button.
      constraints: BoxConstraints(minHeight: size.height),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AtemRadii.pillR,
        gradient: _enabled && _variant == _Variant.gradient ? gradient : null,
        color: switch (_variant) {
          _Variant.gradient when !_enabled => AtemColors.surfaceRaised,
          _Variant.outline => AtemColors.surfaceSolid,
          _ => null,
        },
        border: _variant == _Variant.outline
            ? Border.all(
                color:
                    _enabled ? tint.withValues(alpha: 0.6) : AtemColors.border,
              )
            : null,
        boxShadow: _enabled && glow != null
            ? AtemGlow.soft(glow!, opacity: 0.35)
            : null,
      ),
      child: content,
    );

    return AtemTappable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      haptic: haptic,
      minTapSize: Size(0, size.height),
      alignment: Alignment.center,
      child: expand
          ? SizedBox(width: double.infinity, child: decorated)
          : decorated,
    );
  }
}

enum _Variant { gradient, outline, ghost }
