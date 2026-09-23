import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'atem_answer.dart' show AtemCheckCorner, AtemSelectBloom;
import 'atem_status_dot.dart';
import 'atem_tappable.dart';

/// Was ein Chip quittiert (Board 18b, C1).
enum AtemChipReceipt {
  /// Der Chip hält etwas fest — eine Angabe, eine Zuordnung: Bloom und
  /// Häkchen-Ecke.
  choice,

  /// Der Chip filtert oder schaltet eine Ansicht um: nur die Häkchen-Ecke.
  /// Der gefilterte Inhalt ist seine Quittung.
  none,
}

/// Eine Kapsel, die man wählt — für Mengen, die zu gross für eine Skala und
/// zu klein für ein Blatt sind.
///
/// ## Farbe ist nie der einzige Träger
///
/// Gewählt heisst: Häkchen **und** getönte Fläche **und** kräftigerer Rand.
/// Wer die Tönung nicht sieht, sieht das Häkchen. Seit Board 18b sitzt es
/// als Ecke oben rechts, poppt und zieht sich als Strich — wie in Board 18.
/// Die Ecke ragt 6 dp heraus; die Reihe, in der Chips stehen, braucht oben
/// und rechts 6 dp Innenrand und darf nicht abschneiden. Trägt die Kapsel zusätzlich
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
    this.receipt = AtemChipReceipt.none,
  });

  final String label;

  /// Das vollständige Label. Es nennt auch den Zustand, wo die Fläche kürzt.
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  /// Ein eigener Ton für diese Kapsel. Ohne ihn Cyan wie überall.
  final Color? color;

  /// Filter und Ansicht: [AtemChipReceipt.none]. Hält der Chip etwas fest:
  /// [AtemChipReceipt.choice].
  final AtemChipReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AtemColors.cyan;

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      // Eine Raste unter dem Finger, in beide Richtungen (Board 18b, G).
      haptic: AtemHaptic.selection,
      child: AtemCheckCorner(
        selected: selected,
        size: 16,
        child: AtemSelectBloom(
          active: selected && receipt == AtemChipReceipt.choice,
          radius: AtemRadii.pill,
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
        ),
      ),
    );
  }
}
