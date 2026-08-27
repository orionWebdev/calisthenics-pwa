import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/body_weight_preview.dart';

/// Die Vorschau unter dem Gewichtsfeld — **rechnen statt warnen**.
///
/// Vier Zeilen, und nur die, die sich ändern. Die Begründung liegt an
/// [BodyWeightPreview]; die Darstellung folgt der Folgentabelle aus Modul 7,
/// damit „vorher → nachher" in der ganzen App dieselbe Form hat.
class WeightPreview extends StatelessWidget {
  const WeightPreview({
    super.key,
    required this.preview,
    required this.loadBefore,
    required this.loadAfter,
  });

  final BodyWeightPreview preview;
  final double loadBefore;
  final double loadAfter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    final loadChanges = (loadBefore - loadAfter).abs() >= 0.5;

    final rows = <(String, String, String)>[
      if (loadChanges)
        (
          l10n.settingsPreviewLoad,
          loadBefore.round().toString(),
          loadAfter.round().toString(),
        ),
      if (preview.acwrChanges)
        (
          l10n.consequenceLoad,
          preview.acwrBefore?.toStringAsFixed(2) ?? l10n.consequenceGone,
          preview.acwrAfter?.toStringAsFixed(2) ?? l10n.consequenceGone,
        ),
      if (preview.formChanges)
        (
          l10n.consequenceForm,
          preview.formBefore?.toString() ?? l10n.commonNotAvailable,
          preview.formAfter?.toString() ?? l10n.commonNotAvailable,
        ),
      if (preview.fitnessChanges)
        (
          l10n.settingsPreviewFitness,
          '${preview.fitnessBefore}',
          '${preview.fitnessAfter}',
        ),
    ];

    if (rows.isEmpty) {
      return Text(l10n.settingsPreviewNone,
          style: AtemType.labelSmall.of(context));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsPreviewTitle,
            style: AtemType.labelMedium.of(context)),
        const SizedBox(height: 10),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _Row(label: rows[i].$1, from: rows[i].$2, to: rows[i].$3),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: AtemType.labelSmall.of(context)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
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
