import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/session_percentile.dart';
import '../../domain/training_session.dart';

/// „Gegen deine 51 Läufe" — **wo diese Einheit im eigenen Bestand steht**.
///
/// Nur für Cardio: Strecke und Pace sind die beiden Werte, die sich über
/// Einheiten hinweg vergleichen lassen, ohne dass die Übungen dazwischenkommen.
///
/// Die Begründung für das Perzentil statt eines Durchschnitts steht am
/// [SessionPercentile]. Der Balken zeigt denselben Wert noch einmal als Länge
/// — er ist Vergleich, nicht Messwert, und trägt deshalb keine eigene Ansage.
class PercentileCard extends StatelessWidget {
  const PercentileCard({
    super.key,
    required this.session,
    required this.sessions,
  });

  final CardioSession session;
  final List<TrainingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    final distance = SessionPercentile.of(
      session.distanceKm,
      sessions,
      session.activity,
      select: (s) => s.distanceKm,
      higherIsBetter: true,
    );
    // Bei der Pace ist weniger besser — Minuten je Kilometer.
    final pace = SessionPercentile.of(
      session.pace,
      sessions,
      session.activity,
      select: (s) => s.pace,
      higherIsBetter: false,
    );

    if (distance == null && pace == null) return const SizedBox.shrink();

    final total = (distance ?? pace)!.total;

    return AtemCard.list(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.detailCompareTitle(total),
            style: AtemType.labelMedium.of(context),
          ),
          const SizedBox(height: 12),
          if (distance != null)
            _Row(
              label: l10n.detailDistance,
              value: l10n.unitKilometers(
                  session.distanceKm!.toStringAsFixed(1)),
              percentile: distance,
            ),
          if (pace != null) ...[
            if (distance != null) const SizedBox(height: 12),
            _Row(
              label: l10n.detailPace,
              value: session.pace!.toStringAsFixed(2),
              percentile: pace,
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.percentile,
  });

  final String label;
  final String value;
  final SessionPercentile percentile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final rank = percentile.isTop
        ? l10n.detailCompareTop(percentile.topPercent)
        : l10n.detailCompareMid;

    return Semantics(
      // Eine Zeile ist ein Knoten: Wert und Einordnung gehören zusammen.
      label: '$label $value, $rank',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('$label $value',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelSmall.of(context)),
                ),
                const SizedBox(width: 10),
                Text(
                  rank,
                  style: AtemType.labelMicro.of(context).copyWith(
                        letterSpacing: 0,
                        fontWeight: FontWeight.w700,
                        color: percentile.isTop
                            ? AtemColors.cyan
                            : AtemColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: AtemProgressBar.share(
                value: percentile.share.clamp(0.0, 1.0),
                semanticLabel: '',
                accent: percentile.isTop
                    ? AtemColors.cyan
                    : AtemColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
