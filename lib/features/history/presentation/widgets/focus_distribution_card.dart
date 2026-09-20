import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/focus_distribution.dart';
import '../../domain/training_session.dart';
import 'wellness_fields.dart';

/// Kraft-Auswertung: **Fokus** — wogegen die Krafteinheiten gingen.
///
/// Auf Auswertungsbildschirmen rendert der Block immer (CLAUDE.md). Unter
/// [FocusDistribution.minimumWithFocus] Einheiten mit Fokus steht der
/// Schwellen-Zustand, nie eine Verteilung aus ein oder zwei Einheiten.
///
/// Alle Balken tragen den Ton des Kraft-Bereichs. Eine Farbe je Fokus wäre
/// eine neue Farbfamilie neben den Muskelfarben — und Fokus ist keine
/// Muskelgruppe.
///
/// Seit 17.09.2026: Was der Block zeigt und dass Einheiten ohne Fokus nicht
/// mitzählen, steht hinter dem ⓘ. Der Nenner („5 von 7 Einheiten mit Fokus")
/// bleibt sichtbar — er verrät die fehlenden Einheiten ohnehin. Die
/// Prozentwerte tragen den Akzent Kraft, die Zahl der Einheiten ist
/// Beschriftung.
class FocusDistributionCard extends StatelessWidget {
  const FocusDistributionCard({
    super.key,
    required this.sessions,
    required this.reference,
  });

  final List<TrainingSession> sessions;
  final DateTime reference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final distribution = FocusDistribution.compute(sessions, reference);

    if (!distribution.hasEnough) {
      return AtemThresholdBlock(
        title: l10n.focusDistTitle,
        condition: l10n.focusDistCondition(FocusDistribution.minimumWithFocus),
        current: distribution.withFocus,
        required: FocusDistribution.minimumWithFocus,
        accent: AtemColors.tabStrength,
        shape: AtemThresholdShape.bars,
      );
    }

    return AtemAnalysisPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemExplainHeader(
            title: l10n.focusDistTitle,
            trailing: l10n.focusDistWindow,
            explanation: [l10n.focusDistWhat, l10n.focusDistExplainWithout],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < distribution.shares.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _Row(
              share: distribution.shares[i],
              percent: distribution.percentOf(distribution.shares[i]),
            ),
          ],
          const SizedBox(height: 14),
          const SizedBox(
              height: 1, child: ColoredBox(color: AtemColors.border)),
          const SizedBox(height: 12),
          Text(
            l10n.focusDistBasis(distribution.withFocus, distribution.total),
            style: AtemType.meta.of(context),
          ),
        ],
      ),
    );
  }
}

/// Eine Zeile: Name, Anzahl und Anteil, darunter der Balken.
/// Ein Semantics-Knoten.
class _Row extends StatelessWidget {
  const _Row({required this.share, required this.percent});

  final FocusShare share;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final name = workoutFocusName(l10n, share.focus);

    return Semantics(
      container: true,
      label: l10n.focusDistRowA11y(name, share.count, percent),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 2,
              children: [
                Text(name, style: AtemType.titleSmallOrDefault(context)),
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l10n.focusDistCount(share.count),
                        style: AtemType.meta.of(context)),
                    Text('$percent${l10n.commonPercentSign}',
                        style: AtemType.valueMedium
                            .of(context)
                            .copyWith(color: AtemColors.tabStrength)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            AtemProgressBar.share(
              value: percent / 100,
              semanticLabel: '',
              accent: AtemColors.tabStrength,
            ),
          ],
        ),
      ),
    );
  }
}
