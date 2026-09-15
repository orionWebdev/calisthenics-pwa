import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/cardio_intensity.dart';
import '../cardio_ui.dart';

/// Der Intensitätskasten — **eine Kapsel urteilt, drei Zeilen zeigen**
/// (Board 11, B4).
///
/// Dasselbe Muster wie die Vergleichsgrundlage-Kapsel aus Modul 6: benannte
/// Stufe, sichtbare Herkunft, gröbere Grundlage ergibt kleineren Vergleich.
/// Stufe 1 trägt den Cyan-Rand, Stufe 2 die Betonung ohne Rand, Stufe 3 steht
/// in Grau — gültig, aber die gröbste.
///
/// Die nicht belegten Stufen stehen als „—" mit Namen da, vorgelesen als
/// „nicht erfasst": nur so ist erkennbar, dass es eine feinere Stufe gibt und
/// woran sie hängt.
class IntensityBox extends StatelessWidget {
  const IntensityBox({
    super.key,
    required this.intensity,
    required this.isRun,
  });

  final CardioIntensity intensity;

  /// Die Board-Texte sagen „Läufe" — für andere Aktivitäten die neutrale
  /// Fassung.
  final bool isRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final i = intensity;

    final (capsule, verdict, basis) = switch (i.level) {
      IntensityLevel.heartRate => (
          l10n.intensityLevel1,
          l10n.intensityZone(i.zone!, _zoneName(l10n, i.zone!)),
          l10n.intensityLevel1,
        ),
      IntensityLevel.rpe => (
          l10n.intensityLevel2,
          '${l10n.intensityRpeValue(i.rpe!)} · ${rpeWord(l10n, i.rpe!)}',
          l10n.intensityLevel2,
        ),
      IntensityLevel.pace => (
          l10n.intensityLevel3,
          i.aboveAverage == null
              ? l10n.intensityLevel3
              : (i.aboveAverage! ? l10n.intensityAbove : l10n.intensityBelow),
          l10n.intensityBasisPace(i.basisCount),
        ),
    };

    final strong = i.level == IntensityLevel.heartRate;
    final neutral = i.level == IntensityLevel.pace;

    final hrValue = i.avgHr == null
        ? null
        : i.percentOfMax == null
            ? '${i.avgHr} bpm'
            : '${i.avgHr} bpm · ${i.percentOfMax} % max';
    final rpeValue = i.rpe == null ? null : l10n.intensityRpeValue(i.rpe!);
    final tempoValue = i.tempoValue == null
        ? null
        : formatTempoValue(context, i.tempoValue!, usesSpeed: i.usesSpeed);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtemColors.card,
        borderRadius: AtemRadii.cardR,
        border: Border.all(
          color: strong
              ? AtemColors.cyan.withValues(alpha: 0.35)
              : AtemColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Die Kapsel erklärt, sie navigiert nicht: kein Knopf. Der Punkt
          // nach „Grundlage" erzwingt die Pause vor dem Wert.
          Semantics(
            label: '${l10n.intensityBasisA11y(basis)}. $verdict',
            child: ExcludeSemantics(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: neutral
                          ? AtemColors.card
                          : AtemColors.cyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AtemRadii.pill),
                      border: Border.all(
                        color: strong
                            ? AtemColors.cyan.withValues(alpha: 0.35)
                            : AtemColors.border,
                      ),
                    ),
                    child: Text(
                      capsule,
                      style: AtemType.labelUi.of(context).copyWith(
                            color: neutral
                                ? AtemColors.textTertiary
                                : AtemColors.cyan,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: verdict,
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(l10n.intensityTitle.toUpperCase(),
                      style: AtemType.labelMicro.of(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(verdict,
                        style: AtemType.titleMedium.of(context)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Row(
            label: l10n.formHrAvg,
            value: hrValue,
            leading: i.level == IntensityLevel.heartRate,
          ),
          _Row(
            label: 'RPE',
            value: rpeValue,
            leading: i.level == IntensityLevel.rpe,
          ),
          _Row(
            label: l10n.formPace,
            value: tempoValue,
            leading: i.level == IntensityLevel.pace,
            last: true,
          ),
          if (i.level == IntensityLevel.pace) ...[
            const SizedBox(height: 10),
            Text(
              isRun
                  ? l10n.intensityFallbackNote(i.basisCount)
                  : l10n.intensityFallbackNoteOther(i.basisCount),
              style: AtemType.meta.of(context),
            ),
          ],
        ],
      ),
    );
  }

  static String _zoneName(AppL10n l10n, int zone) => switch (zone) {
        1 => l10n.intensityZoneName1,
        2 => l10n.intensityZoneName2,
        3 => l10n.intensityZoneName3,
        4 => l10n.intensityZoneName4,
        _ => l10n.intensityZoneName5,
      };
}

/// Eine der drei Zeilen, 28 dp. Die führende steht in Weiss, die anderen
/// als Zahl ohne Bewertung. „—" ist nie stumm.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.leading,
    this.last = false,
  });

  final String label;
  final String? value;
  final bool leading;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Semantics(
      label: value == null
          ? '$label, ${l10n.intensityNoneA11y}'
          : '$label $value',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 28),
          decoration: last
              ? null
              : const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AtemColors.border)),
                ),
          child: Row(
            children: [
              Expanded(
                child: Text(label.toUpperCase(),
                    style: AtemType.labelMicro.of(context)),
              ),
              const SizedBox(width: 10),
              Text(
                value ?? l10n.intensityNoneValue,
                style: AtemType.valueMedium.of(context).copyWith(
                      fontSize: 13,
                      color: value == null
                          ? AtemColors.textSecondary
                          : (leading
                              ? AtemColors.textPrimary
                              : AtemColors.textTertiary),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
