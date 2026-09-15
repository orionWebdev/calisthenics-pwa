import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/comparison_basis.dart';

/// Die Bezugskapsel — **worauf ein Vergleich beruht, bevor man ihn liest**.
///
/// Der einzige neue Baustein aus Modul 9. Ein Chip mit der Grundlage, daneben
/// Datum und Abstand: „Gleicher Plan · 12. Aug · 12 Tage her".
///
/// ## Kein Tap-Ziel
///
/// Sie erklärt, sie navigiert nicht. Ein Chip, der wie ein Knopf aussieht und
/// keiner ist, wird angetippt — und das Ausbleiben einer Reaktion liest sich
/// als Fehler.
///
/// ## Warum Stufe C anders aussieht
///
/// A und B haben eine echte Bezugseinheit; ihr Chip ist cyan, wie alles
/// Datentragende. C ist ein Median über fünf Einheiten — gröber, also leiser:
/// Fläche und Rand neutral. Der Unterschied ist sichtbar, ohne dass man den
/// Text lesen muss.
class BasisCapsule extends StatelessWidget {
  const BasisCapsule({
    super.key,
    required this.basis,
    required this.dateLabel,
    required this.daysAgo,
    this.medianCount = 0,
  });

  final ComparisonBasis basis;

  /// Kurzdatum, bereits lokalisiert.
  final String dateLabel;

  final int daysAgo;

  /// Nur bei Stufe C: über wie viele Einheiten der Median geht.
  final int medianCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final strong = basis != ComparisonBasis.sameKind;

    final chip = switch (basis) {
      ComparisonBasis.samePlan => l10n.compareBasisPlan,
      ComparisonBasis.sameExercises => l10n.compareBasisExercises,
      ComparisonBasis.sameKind => l10n.compareBasisMedian(medianCount),
    };
    final meta = l10n.compareBasisDate(dateLabel, daysAgo);

    return Semantics(
      // Der Punkt nach der Grundlage erzwingt die Pause — sonst liest
      // TalkBack Chip und Datum in einem Zug.
      label: '$chip. $meta',
      child: ExcludeSemantics(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: strong
                    ? AtemCategories.surface(AtemColors.cyan)
                    : AtemColors.surfaceSolid,
                borderRadius: BorderRadius.circular(AtemRadii.pill),
                border: Border.all(
                  color: strong
                      ? AtemCategories.border(AtemColors.cyan)
                      : AtemColors.border,
                ),
              ),
              child: Text(
                chip,
                style: AtemType.labelUi.of(context).copyWith(
                      color:
                          strong ? AtemColors.cyan : AtemColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(meta, style: AtemType.meta.of(context)),
          ],
        ),
      ),
    );
  }
}

/// Die Delta-Kapsel: Richtung als **Zeichen und Wort**, nie als Farbe.
///
/// ## Warum hier keine Ampel
///
/// In der Folgenvorschau aus Modul 7 trägt die Richtung eine Farbe: Dort
/// entscheidet jemand über eine Änderung, und „kürzere Pause" ist die
/// gewünschte Richtung.
///
/// Hier liest jemand seine Geschichte. Ob mehr Volumen besser ist, hängt
/// davon ab, was er vorhatte — mehr Last kann Fortschritt sein oder Übermut,
/// und was davon zutrifft, sagt der ACWR daneben, nicht diese Kapsel.
class DeltaCapsule extends StatelessWidget {
  const DeltaCapsule({super.key, required this.delta, required this.rises});

  /// Bereits formatiert: „+32", „−1", „+8 %".
  final String delta;

  final bool rises;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AtemColors.surfaceSolid,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(color: AtemColors.border),
        ),
        child: Text(
          '${rises ? '▲' : '▼'} $delta',
          style: AtemType.labelMicro
              .of(context)
              .copyWith(color: AtemColors.textSecondary, letterSpacing: 0),
        ),
      ),
    );
  }
}
