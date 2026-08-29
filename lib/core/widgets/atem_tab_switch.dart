import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_motion.dart';
import '../theme/atem_type.dart';
import 'atem_tappable.dart';

/// Ein Segment des Umschalters.
@immutable
class AtemTabSegment<T> {
  const AtemTabSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// Der Segment-Umschalter — **zwei Sichten auf denselben Tab**.
///
/// Board 11, Sektion A: Kraft trägt „Trainieren | Verlauf", Cardio
/// „Einheiten | Auswertung". Der Wechsel ersetzt den Inhalt, er öffnet keinen
/// Bildschirm — deshalb Rolle `tab`, nicht `button` (Sektion H).
///
/// ## Warum nicht [AtemSegmented]
///
/// Die Segmentauswahl aus Modul 2 ist ein Formularfeld: Sie wählt einen
/// **Wert** und trägt ihn mit einem Haken. Hier wird keine Angabe gemacht,
/// sondern ein Bildschirmteil gewählt. Das Aussehen ist die Pille mit vier
/// Achsen aus Modul 3: 32 dp sichtbar, 48 dp Trefferfläche, Radius 30, aktiv
/// mit Cyan-Rand bei 35 %, inaktiv Card auf Border.
class AtemTabSwitch<T> extends StatelessWidget {
  const AtemTabSwitch({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    required this.groupSemanticLabel,
  }) : assert(segments.length == 2, 'Ein Umschalter hat genau zwei Seiten.');

  final List<AtemTabSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Benennt die Gruppe: „Kraft-Ansicht wählen".
  final String groupSemanticLabel;

  static const visibleHeight = 32.0;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: groupSemanticLabel,
        // Wrap, nicht Row: Bei 200 % Schrift auf 320 dp passen „Trainieren"
        // und „Verlauf" nicht nebeneinander. Dann stehen sie untereinander —
        // ganz, statt mit Auslassungspunkten. Ein Umschalter, dessen Wort
        // fehlt, schaltet ins Ungewisse.
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var i = 0; i < segments.length; i++)
              _Segment<T>(
                segment: segments[i],
                selected: segments[i].value == value,
                index: i,
                count: segments.length,
                onTap: () => onChanged(segments[i].value),
              ),
          ],
        ),
      );
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.index,
    required this.count,
    required this.onTap,
  });

  final AtemTabSegment<T> segment;
  final bool selected;
  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Rolle Tab: „Verlauf, Tab 2 von 2, ausgewählt". Der Zustand steckt in
    // `selected`, nicht in der Farbe allein — und das Wort ist das Label.
    return AtemTappable(
      onTap: selected ? null : onTap,
      semanticLabel: segment.label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      minTapSize: const Size(48, 48),
      child: AnimatedContainer(
        duration: AtemMotion.duration(context, AtemMotion.fast),
        curve: AtemMotion.curve,
        constraints:
            const BoxConstraints(minHeight: AtemTabSwitch.visibleHeight),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AtemColors.cyan.withValues(alpha: 0.08)
              : AtemColors.card,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: selected
                ? AtemColors.cyan.withValues(alpha: 0.35)
                : AtemColors.border,
          ),
        ),
        child: Text(
          segment.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AtemType.labelMicro.of(context).copyWith(
                color: selected ? AtemColors.cyan : AtemColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
