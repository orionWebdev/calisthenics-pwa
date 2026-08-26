import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_type.dart';
import 'atem_status_dot.dart';
import 'atem_tappable.dart';

/// Wie eine Pille gefüllt ist.
enum AtemBadgeFill {
  /// Nur Rand. Der Normalfall.
  outline,

  /// Akzent bei 8 % Deckkraft.
  tinted,

  /// Volle Akzentfläche. **Höchstens eine pro Karte** — Zählern und Alarmen
  /// vorbehalten.
  solid,
}

/// Statusträger und Chips der App.
///
/// Ersetzt sechs fast identische Rezepte, die sich nur in Polsterung und
/// Randfarbe unterschieden. Vier Achsen: Füllung, Akzent, Führung, antippbar.
///
/// ## Statusträger oder Chip — sichtbar, nicht nur im Verhalten
///
/// Antippbares trägt **immer** ein nachgestelltes Chevron. Eine Pille ohne
/// Nachlauf-Symbol ist nie antippbar. Damit hängt die Unterscheidung an der
/// Form, nicht an der Farbe.
///
/// ## Akzent ist keine Information
///
/// Jede akzentuierte Pille trägt zusätzlich ein führendes Element oder
/// unterscheidenden Text. „High Intensity" bekommt deshalb eine Raute — ein
/// stärkerer Rand wäre wieder nur ein Farbkontrast-Fix und fiele beim
/// Farbenblinden-Test durch.
class AtemBadge extends StatelessWidget {
  const AtemBadge({
    super.key,
    required this.label,
    this.semanticLabel,
    this.fill = AtemBadgeFill.outline,
    this.accent,
    this.leadingDot = false,
    this.pulsingDot = false,
    this.leadingIcon,
    this.style,
  })  : onTap = null,
        _isCounter = false;

  /// Antippbar. Trägt automatisch ein nachgestelltes Chevron.
  const AtemBadge.chip({
    super.key,
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    this.fill = AtemBadgeFill.tinted,
    this.accent,
    this.leadingIcon,
    this.style,
  })  : leadingDot = false,
        pulsingDot = false,
        _isCounter = false;

  /// Der Benachrichtigungszähler — die einzige volle Pille im System.
  const AtemBadge.counter({
    super.key,
    required this.label,
    required this.semanticLabel,
  })  : fill = AtemBadgeFill.solid,
        accent = AtemColors.magenta,
        leadingDot = false,
        pulsingDot = false,
        leadingIcon = null,
        onTap = null,
        style = null,
        _isCounter = true;

  final String label;

  /// Was ein Screenreader ansagt. Ohne Angabe wird [label] gelesen — was oft
  /// falsch ist: „ATEM HYBRID" plus Punkt sagt weniger als „System aktiv".
  final String? semanticLabel;

  final AtemBadgeFill fill;
  final Color? accent;

  /// Führender Statuspunkt. Pflicht bei Akzent, sofern kein [leadingIcon].
  final bool leadingDot;
  final bool pulsingDot;

  /// Führendes Symbol, 12 dp. Punkt zeigt Zustand, Symbol zeigt Kategorie.
  final Widget? leadingIcon;

  final VoidCallback? onTap;

  /// Abweichender Textstil. Standard ist [AtemType.labelMicro]; die
  /// Empfehlungs-Pille nutzt [AtemType.labelSmall], weil sie Fließtext trägt.
  final AtemTextRole? style;

  final bool _isCounter;

  static const _height = 24.0;
  static const _counterHeight = 20.0;

  /// Violett erreicht auf keiner Fläche AA (2,8:1, violetLight 3,98:1).
  /// Als Rand und Fläche ist es zulässig, als Beschriftung nie — dann tritt
  /// der neutrale Ton an seine Stelle.
  ///
  /// Vertrag `docs/contracts/01-accessibility.md`, R4.
  static Color _safeTextColor(Color accent) =>
      accent == AtemColors.violet || accent == AtemColors.violetLight
          ? AtemColors.textTertiary
          : accent;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AtemColors.border;
    final isAccented = accent != null;
    final role = style ?? AtemType.labelMicro;

    final textColor = switch (fill) {
      AtemBadgeFill.solid => AtemColors.textPrimary,
      _ when isAccented => _safeTextColor(tint),
      _ => AtemColors.textTertiary,
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingDot) ...[
          AtemStatusDot(color: tint, pulsing: pulsingDot),
          const SizedBox(width: 6),
        ] else if (leadingIcon != null) ...[
          ExcludeSemantics(child: leadingIcon!),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            // Nie umbrechen: die Pille kürzt, der volle Text steht in Semantics.
            overflow: TextOverflow.ellipsis,
            style: role.of(context).copyWith(color: textColor),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          _Chevron(color: textColor),
        ],
      ],
    );

    final pill = Container(
      constraints: BoxConstraints(
        minHeight: _isCounter ? _counterHeight : _height,
        minWidth: _isCounter ? 20 : 0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: _isCounter ? 6 : 12,
        vertical: _isCounter ? 0 : 5,
      ),
      // KEIN alignment: Ein Container mit alignment dehnt sich auf den
      // verfügbaren Raum aus — in einem Wrap wird daraus eine Pille über die
      // volle Breite. Die Zeile darin zentriert bereits.
      decoration: BoxDecoration(
        borderRadius: AtemRadii.pillR,
        color: switch (fill) {
          AtemBadgeFill.solid => tint,
          AtemBadgeFill.tinted => tint.withValues(alpha: 0.08),
          AtemBadgeFill.outline => null,
        },
        border: Border.all(
          color: switch (fill) {
            // Der Zähler grenzt sich gegen die Fläche darunter ab.
            AtemBadgeFill.solid => AtemColors.base,
            _ when isAccented => tint.withValues(alpha: 0.4),
            _ => AtemColors.border,
          },
          width: fill == AtemBadgeFill.solid ? 1.5 : 1,
        ),
      ),
      child: content,
    );

    if (onTap == null) {
      return Semantics(
        label: semanticLabel ?? label,
        child: ExcludeSemantics(child: pill),
      );
    }

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel!,
      // Sichtbar bleiben 24 dp, die Trefferfläche wächst unsichtbar.
      pressScale: AtemPressScale.normal,
      child: pill,
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(7, 11),
        painter: _ChevronPainter(color),
      );
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * 0.15, 0)
      ..lineTo(size.width * 0.85, size.height / 2)
      ..lineTo(size.width * 0.15, size.height);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
