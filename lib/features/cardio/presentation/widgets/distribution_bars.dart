import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/distance_distribution.dart';

/// Verteilung der Distanzen — fünf Klassen, ein Nenner (Board 11, B3/1).
class DistributionBars extends StatelessWidget {
  const DistributionBars({super.key, required this.distribution});

  final DistanceDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final max = distribution.maxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final bucket in distribution.buckets) ...[
          Semantics(
            // Eine Zeile ist ein Knoten: „5–8 km, 21".
            label: '${_label(context, l10n, bucket)}, ${bucket.count}',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(_label(context, l10n, bucket),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtemType.meta.of(context)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AtemProgressBar.share(
                      value: max == 0 ? 0 : bucket.count / max,
                      semanticLabel: '',
                      accent: AtemColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text('${bucket.count}',
                        textAlign: TextAlign.right,
                        style: AtemType.valueMedium
                            .of(context)
                            .copyWith(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  static String _label(
      BuildContext context, AppL10n l10n, DistanceBucket bucket) {
    String km(double v) => AtemNumberField.format(context, v);
    if (bucket.fromKm == 0) return l10n.distBucketBelow(km(bucket.toKm!));
    if (bucket.toKm == null) return l10n.distBucketAbove(km(bucket.fromKm));
    return l10n.distBucketRange(km(bucket.fromKm), km(bucket.toKm!));
  }
}
