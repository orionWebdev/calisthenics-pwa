import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_motion.dart';
import '../theme/atem_type.dart';
import 'atem_tappable.dart';

/// Ein Eintrag der Segmentauswahl.
@immutable
class AtemSegment<T> {
  const AtemSegment({
    required this.value,
    required this.label,
    required this.semanticLabel,
  });

  final T value;
  final String label;

  /// Was ein Screenreader ansagt — meist ausführlicher als das Sichtbare.
  /// „kg" allein wäre vorgelesen sinnlos.
  final String semanticLabel;
}

/// Auswahl zwischen wenigen, gleichrangigen Möglichkeiten.
///
/// Für zwei bis fünf Einträge. Ab sechs ist es eine Liste, kein Segment.
///
/// **Der aktive Eintrag trägt einen Haken, nicht nur eine Farbe** — Vertrag R6:
/// Farbe ist nie der einzige Statusträger. Getönte Fläche und Rand sind
/// Verstärkung, der Haken ist die Aussage.
///
/// Die Rolle ist bewusst `radio` in einer benannten Gruppe und nicht `button`:
/// Ein Screenreader muss ansagen können, welcher von wie vielen gewählt ist.
class AtemSegmented<T> extends StatelessWidget {
  const AtemSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    required this.groupSemanticLabel,
    this.enabled = true,
  }) : assert(segments.length >= 2, 'Ein Segment allein ist keine Auswahl.');

  final List<AtemSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Benennt die Gruppe: „Gewichtseinheit wählen".
  final String groupSemanticLabel;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: groupSemanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        // **`Wrap`, nicht `Row`.** Fünf Segmente mit Wörtern darin passen bei
        // 200 % Schrift auf 320 dp nicht nebeneinander — eine Reihe liefe über
        // und schnitte das letzte Segment ab, samt seiner Trefferfläche.
        //
        // Solange Platz ist, verhält sich ein `Wrap` wie eine `Row`; erst wenn
        // keiner mehr da ist, unterscheiden sie sich. Genau dann soll es
        // umbrechen statt zu reißen.
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final segment in segments)
              _Segment<T>(
                segment: segment,
                selected: segment.value == value,
                enabled: enabled,
                onTap: () => onChanged(segment.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AtemSegment<T> segment;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AtemColors.cyan : AtemColors.textSecondary;

    return AtemTappable(
      onTap: enabled && !selected ? onTap : null,
      semanticLabel: segment.semanticLabel,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      pressScale: AtemPressScale.strong,
      child: AnimatedContainer(
        duration: AtemMotion.duration(context, AtemMotion.fast),
        curve: AtemMotion.curve,
        constraints: const BoxConstraints(minWidth: 72, minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AtemColors.cyan.withValues(alpha: 0.08)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: selected
                ? AtemColors.cyan.withValues(alpha: 0.4)
                : AtemColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const _Check(color: AtemColors.cyan),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.labelMedium.of(context).copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: const Size.square(12),
          painter: _CheckPainter(color),
        ),
      );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.16, s * 0.54)
        ..lineTo(s * 0.4, s * 0.78)
        ..lineTo(s * 0.84, s * 0.22),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
