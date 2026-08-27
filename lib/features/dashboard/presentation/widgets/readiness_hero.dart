import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/dashboard_data.dart';
import '../../domain/readiness_level.dart';
import '../readiness_zone_ui.dart';
import '../readiness_level_ui.dart';

/// Die Readiness-Karte mit Bogen, Empfehlung und drei Messwerten.
class ReadinessHero extends StatelessWidget {
  const ReadinessHero({
    super.key,
    required this.readiness,
    required this.scoreAnimation,
  });

  final ReadinessSnapshot readiness;
  final Animation<double> scoreAnimation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemCard.glass(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      glow: AtemColors.cyan,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.dashboardReadinessSection,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.labelMicro.of(context),
                ),
              ),
              if (readiness.isLive)
                AtemBadge(
                  label: l10n.dashboardLive,
                  accent: AtemColors.green,
                  leadingDot: true,
                  pulsingDot: true,
                ),
            ],
          ),
          AnimatedBuilder(
            animation: scoreAnimation,
            builder: (context, _) {
              final value = scoreAnimation.value;
              // Die Zone hat Vorrang: Sie kennt die Richtung, der Punktwert
              // allein nicht. Ohne Zone — etwa in der Design-Vorschau — bleibt
              // die Ableitung aus dem Wert.
              final zone = readiness.zone;
              final level = ReadinessLevel.fromScore(value);
              final color = zone?.color ?? level.color;
              final labelText = zone?.label(l10n) ?? level.label(l10n);
              final tagText = zone?.tag(l10n) ?? level.tag(l10n);
              return Column(
                children: [
                  AtemArcGauge(
                    value: value / 100,
                    semanticLabel:
                        l10n.dashboardReadinessA11y(value.round(), labelText),
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${value.round()}',
                              style: AtemType.display.of(context).copyWith(
                                    shadows: AtemGlow.text(AtemColors.cyan),
                                  ),
                            ),
                            Text(l10n.commonPercentSign,
                                style: AtemType.titleLarge.of(context).copyWith(
                                      color: AtemColors.textSecondary,
                                    )),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          labelText,
                          textAlign: TextAlign.center,
                          style: AtemType.labelMicro.of(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: color,
                                shadows: AtemGlow.text(color),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Skaliert voll mit — die Bedingung dafür, dass die Zahl im
                  // Bogen begrenzt werden darf.
                  AtemBadge(
                    label: tagText,
                    fill: AtemBadgeFill.tinted,
                    style: AtemType.labelSmall,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 15),
          // IntrinsicHeight statt stretch: Eine Row mit stretch verlangt eine
          // begrenzte Höhe, in einer Spalte gibt es die nicht. So bekommen die
          // drei Boxen trotzdem dieselbe Höhe.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Stat(
                    value:
                        readiness.hrvMs == null ? '–' : '${readiness.hrvMs} ms',
                    label: l10n.dashboardStatHrv,
                    accent: AtemColors.green,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _Stat(
                    value: readiness.restingHeartRate == null
                        ? '–'
                        : '${readiness.restingHeartRate} bpm',
                    label: l10n.dashboardStatRhr,
                    accent: AtemColors.cyan,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _Stat(
                    value: readiness.sleepLabel,
                    label: l10n.dashboardStatSleep,
                    accent: AtemColors.violetLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Semantics(
        // Wert und Beschriftung zu EINEM Knoten: "HRV 82 ms" statt "82 ms",
        // dann "HRV".
        label: '$label $value',
        child: ExcludeSemantics(
          child: AtemStatBox(
            glow: accent,
            child: Column(
              children: [
                // Kein FittedBox: das machte die Schriftskalierung des Nutzers
                // stillschweigend rückgängig.
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: AtemType.valueMedium.of(context).copyWith(
                        shadows: AtemGlow.text(accent, opacity: 0.6),
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AtemType.labelMicro.of(context),
                ),
              ],
            ),
          ),
        ),
      );
}
