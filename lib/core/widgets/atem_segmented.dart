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
    this.expand = false,
  }) : assert(segments.length >= 2, 'Ein Segment allein ist keine Auswahl.');

  final List<AtemSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Benennt die Gruppe: „Gewichtseinheit wählen".
  final String groupSemanticLabel;

  final bool enabled;

  /// Teilen sich die Segmente die ganze Breite, zu gleichen Teilen?
  ///
  /// Für eine Wahl, die eine eigene Zeile trägt — die Seitenwahl im Runner
  /// (18.09.2026). Passt eines der Segmente nicht in seinen Anteil, stehen
  /// alle untereinander, jedes über die volle Breite: gleich breit bleiben
  /// sie so oder so, und keines wird abgeschnitten. Ohne `expand` bleiben
  /// die Segmente so breit wie ihr Inhalt.
  final bool expand;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final segment in segments)
        _Segment<T>(
          segment: segment,
          selected: segment.value == value,
          enabled: enabled,
          expand: expand,
          onTap: () => onChanged(segment.value),
        ),
    ];

    return Semantics(
      container: true,
      label: groupSemanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: expand
            ? LayoutBuilder(
                builder: (context, constraints) => _fitsSideBySide(
                  context,
                  constraints.maxWidth,
                )
                    ? Row(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const SizedBox(width: _gap),
                            Expanded(child: items[i]),
                          ],
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const SizedBox(height: _gap),
                            items[i],
                          ],
                        ],
                      ),
              )
            // **`Wrap`, nicht `Row`.** Fünf Segmente mit Wörtern darin passen
            // bei 200 % Schrift auf 320 dp nicht nebeneinander — eine Reihe
            // liefe über und schnitte das letzte Segment ab, samt seiner
            // Trefferfläche.
            //
            // Solange Platz ist, verhält sich ein `Wrap` wie eine `Row`; erst
            // wenn keiner mehr da ist, unterscheiden sie sich. Genau dann soll
            // es umbrechen statt zu reißen.
            : Wrap(spacing: _gap, runSpacing: _gap, children: items),
      ),
    );
  }

  /// Passt jedes Segment — mit Haken, fett, also im breitesten Zustand — in
  /// seinen gleichen Anteil an [maxWidth]?
  bool _fitsSideBySide(BuildContext context, double maxWidth) {
    final share = (maxWidth - _gap * (segments.length - 1)) / segments.length;
    final style =
        AtemType.labelMedium.of(context).copyWith(fontWeight: FontWeight.w600);
    final scaler = MediaQuery.textScalerOf(context);
    for (final segment in segments) {
      final painter = TextPainter(
        text: TextSpan(text: segment.label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width + _Segment.chrome(expand: true);
      painter.dispose();
      if (width > share) return false;
    }
    return true;
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.enabled,
    required this.expand,
    required this.onTap,
  });

  final AtemSegment<T> segment;
  final bool selected;
  final bool enabled;
  final bool expand;
  final VoidCallback onTap;

  /// Seitlicher Innenabstand. Geteilt etwas enger: Die Breite ist dann
  /// knapp, und die Segmente stehen ohnehin nicht mehr eng am Text.
  static double _inset({required bool expand}) => expand ? 10 : 14;

  /// Alles ausser dem Text: Innenabstand, Haken samt Lücke, Rand.
  static double chrome({required bool expand}) =>
      _inset(expand: expand) * 2 + 12 + 6 + 2;

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
        // Geteilt füllt das Segment seinen Anteil — `AtemTappable` richtet
        // sein Kind sonst mittig aus und liesse es auf Textbreite schrumpfen.
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: _inset(expand: expand),
          vertical: 6,
        ),
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
              // Zwei Zeilen statt Auslassungspunkten: „Links / Rech…" bei
              // 200 % Schrift wäre eine abgeschnittene Wahl.
              child: Text(
                segment.label,
                maxLines: 2,
                textAlign: TextAlign.center,
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
