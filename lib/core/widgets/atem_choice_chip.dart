import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons;

import '../theme/theme.dart';
import 'atem_status_dot.dart';
import 'atem_tappable.dart';

/// Eine Kapsel, die man wählt — für Mengen, die zu gross für eine Skala und
/// zu klein für ein Blatt sind.
///
/// ## Farbe ist nie der einzige Träger
///
/// Gewählt heisst: Häkchen **und** getönte Fläche **und** kräftigerer Rand.
/// Wer die Tönung nicht sieht, sieht das Häkchen. Trägt die Kapsel zusätzlich
/// eine [color] — etwa einen Muskelton —, steht im **nicht** gewählten Zustand
/// ein Punkt davor: So ist die Zuordnung Farbe/Bedeutung lernbar, bevor man
/// tippt. Der Punkt ist dekorativ und aus den Semantics ausgeschlossen.
///
/// Sichtbar 36 dp hoch, Trefferfläche 48 — [AtemTappable] besorgt die
/// Differenz.
class AtemChoiceChip extends StatelessWidget {
  const AtemChoiceChip({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;

  /// Das vollständige Label. Es nennt auch den Zustand, wo die Fläche kürzt.
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  /// Ein eigener Ton für diese Kapsel. Ohne ihn Cyan wie überall.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AtemColors.cyan;

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        constraints: const BoxConstraints(minHeight: 36),
        decoration: BoxDecoration(
          color: selected ? AtemCategories.surface(tint) : AtemColors.card,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: selected ? AtemCategories.border(tint) : AtemColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Der Punkt zeigt die Farbe auch im nicht gewählten Zustand — so
            // ist die Zuordnung lernbar, bevor man tippt.
            if (color != null && !selected) ...[
              ExcludeSemantics(child: AtemStatusDot(color: tint)),
              const SizedBox(width: 8),
            ],
            if (selected) ...[
              Icon(Icons.check, size: 14, color: tint),
              const SizedBox(width: 6),
            ],
            // **Flexible, nicht fest.** Eine Kapsel in einem `Wrap` bekommt
            // die Zeilenbreite als Schranke, schrumpft aber nicht von selbst:
            // Ein langes Wort bei 200 % Schrift — „Unterkörper" — machte die
            // Kapsel breiter als die Zeile, und der `Wrap` lief über.
            //
            // Umbrechen statt kürzen: Kein `maxLines`, kein Ellipsis, kein
            // `FittedBox`. Die Kapsel wird höher, der Text bleibt ganz da.
            Flexible(
              child: Text(
                label,
                style: AtemType.labelSmall.of(context).copyWith(
                      color: selected ? tint : AtemColors.textPrimary,
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
