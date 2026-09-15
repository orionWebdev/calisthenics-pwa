import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';

/// Das ACWR-Band, in dem ein Wert liegt.
///
/// Vier Bänder, wie die Skala aus Board 06 sie zeichnet: 0–0,8 · 0,8–1,3 ·
/// 1,3–1,5 · über 1,5. Die Grenzen sind die der Vorgänger-App.
enum AcwrBand {
  low(0, 0.8),
  optimal(0.8, 1.3),
  high(1.3, 1.5),
  danger(1.5, null);

  const AcwrBand(this.from, this.to);

  final double from;
  final double? to;

  /// Die Breite im Streifen: 8/5/2/5 laut Spezifikation.
  int get flex => switch (this) {
        AcwrBand.low => 8,
        AcwrBand.optimal => 5,
        AcwrBand.high => 2,
        AcwrBand.danger => 5,
      };

  static AcwrBand forValue(double acwr) {
    for (final band in values) {
      final to = band.to;
      if (acwr < band.from) continue;
      if (to == null || acwr < to) return band;
    }
    return AcwrBand.danger;
  }

  Color get color => switch (this) {
        AcwrBand.low => AtemColors.amber,
        AcwrBand.optimal => AtemColors.green,
        AcwrBand.high => AtemColors.amber,
        AcwrBand.danger => AtemColors.magenta,
      };

  String label(AppL10n l) => switch (this) {
        AcwrBand.low => l.acwrBandLow,
        AcwrBand.optimal => l.acwrBandOptimal,
        AcwrBand.high => l.acwrBandHigh,
        AcwrBand.danger => l.acwrBandDanger,
      };

  String note(AppL10n l) => switch (this) {
        AcwrBand.low => l.acwrBandNoteLow,
        AcwrBand.optimal => l.acwrBandNoteOptimal,
        AcwrBand.high => l.acwrBandNoteHigh,
        AcwrBand.danger => l.acwrBandNoteDanger,
      };
}

/// Die ACWR-Skala — **vier Segmente, eins in Zonenfarbe, die Zone als Wort**
/// (Board 06, Spezifikation).
///
/// Höhe 6 dp, Gap 2 dp; das aktive Segment in Zonenfarbe bei 55 %, die
/// anderen im Track. Die Zone steht zusätzlich als Wort im Fliesstext —
/// nie nur als Segmentposition. Unter 28 Tagen Historie ist das Element nicht
/// im Baum; das entscheidet der Aufrufer.
class AcwrScale extends StatelessWidget {
  const AcwrScale({super.key, required this.acwr});

  final double acwr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final band = AcwrBand.forValue(acwr);
    final value = acwr.toStringAsFixed(2);
    String edge(double? v) => v == null ? '∞' : v.toStringAsFixed(1);

    return Semantics(
      image: true,
      label: l10n.acwrScaleA11y(
          value, band.label(l10n), edge(band.from), edge(band.to)),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.acwrLabel(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.meta.of(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 6,
              child: Row(
                children: [
                  for (final b in AcwrBand.values) ...[
                    if (b != AcwrBand.low) const SizedBox(width: 2),
                    Expanded(
                      flex: b.flex,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: b == band
                              ? b.color.withValues(alpha: 0.55)
                              : AtemColors.track,
                          borderRadius: BorderRadius.circular(AtemRadii.pill),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final b in AcwrBand.values) ...[
                  if (b != AcwrBand.low) const SizedBox(width: 2),
                  Expanded(
                    flex: b.flex,
                    child: Text(
                      edge(b.from),
                      style: AtemType.labelDeco.of(context),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(band.note(l10n), style: AtemType.labelSmall.of(context)),
          ],
        ),
      ),
    );
  }
}
