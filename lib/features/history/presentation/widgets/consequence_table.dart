import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/session_consequence.dart';

/// Was eine Änderung anrichtet — **in Zahlen, nicht als Warnung**.
///
/// Steht im Löschdialog und über dem Speichern-Knopf des Bearbeitens. Die
/// Begründung, warum gerechnet und nicht gewarnt wird, liegt an
/// [SessionConsequence].
///
/// ## Warum höchstens drei Zeilen
///
/// Es werden nur die Größen gezeigt, die sich **tatsächlich ändern**. Eine
/// Tabelle mit drei Zeilen „unverändert" behauptet Bedeutung, wo keine ist,
/// und macht die eine Zeile, auf die es ankommt, schwerer zu finden.
///
/// Ändert sich gar nichts, steht ein einzelner Satz da. Auch das ist eine
/// Auskunft: Wer eine Einheit von vor zwei Jahren löscht, soll erfahren, dass
/// es folgenlos ist.
class ConsequenceTable extends StatelessWidget {
  const ConsequenceTable({super.key, required this.consequence});

  final SessionConsequence consequence;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    if (!consequence.isVisible) {
      return Text(
        l10n.consequenceNone,
        style: AtemType.labelSmall.of(context),
      );
    }

    String days(int? value) =>
        value == null ? l10n.commonNotAvailable : l10n.consequenceDays(value);

    final rows = <(String, String, String)>[
      if (consequence.pauseChanges)
        (
          l10n.consequencePause,
          days(consequence.pauseBefore),
          days(consequence.pauseAfter),
        ),
      if (consequence.formChanges)
        (
          l10n.consequenceForm,
          consequence.formBefore?.toString() ?? l10n.commonNotAvailable,
          consequence.formAfter?.toString() ?? l10n.commonNotAvailable,
        ),
      if (consequence.acwrChanges)
        (
          l10n.consequenceLoad,
          consequence.acwrBefore?.toStringAsFixed(2) ?? l10n.consequenceGone,
          consequence.acwrAfter?.toStringAsFixed(2) ?? l10n.consequenceGone,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.consequenceTitle, style: AtemType.labelMedium.of(context)),
        const SizedBox(height: 10),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _Row(
            label: rows[i].$1,
            from: rows[i].$2,
            to: rows[i].$3,
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.from, required this.to});

  final String label;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Semantics(
      label: l10n.consequenceStepA11y(label, from, to),
      child: ExcludeSemantics(
        // Beide Seiten nachgiebig: „Belastung" und „1,37 → 0,00" nebeneinander
        // sprengen bei 200 % Schrift auf 320 dp jede feste Aufteilung.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: AtemType.labelSmall.of(context)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                // Der Pfeil trägt die Richtung, nicht die Farbe: Ob 16 → 14
                // gut oder schlecht ist, hängt daran, was jemand vorhat. Eine
                // rote Zahl behauptete eine Bewertung, die uns nicht zusteht.
                l10n.consequenceStep(from, to),
                textAlign: TextAlign.right,
                style: AtemType.labelMicro
                    .of(context)
                    .copyWith(color: AtemColors.cyan, letterSpacing: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
