import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../domain/hard_sets.dart';
import '../../domain/training_session.dart';

/// Harte Sätze je Muskelgruppe — ein Block der Kraft-Auswertung (18.09.2026).
///
/// Rendert immer (Auswertungsbildschirm, CLAUDE.md): Unter
/// [HardSets.minimumSetsWithRpe] Sätzen mit Angabe steht der
/// [AtemThresholdBlock] mit Bedingung und Fortschritt, nie eine Zahl.
///
/// Gefüllt trägt der Block **eine** Hauptzahl im Kraft-Akzent — die Summe der
/// harten Sätze —, darunter je Muskel eine Zeile mit neutraler Zahl und der
/// Verschiebung zum Fenster davor. Die Verschiebung ist eine Tatsache in
/// `textTertiary`, kein Urteil und keine Ampel.
class HardSetsCard extends ConsumerWidget {
  const HardSetsCard({
    super.key,
    required this.sessions,
    required this.reference,
  });

  final List<TrainingSession> sessions;
  final DateTime reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final exercises = ref.watch(exercisesProvider).value ?? const [];
    final hard = HardSets.compute(sessions, exercises, reference);
    final days = hard.windowDays;

    if (!hard.hasEnough) {
      return AtemThresholdBlock(
        title: l10n.hardSetsTitle,
        trailing: l10n.hardSetsWindow(days),
        what: l10n.hardSetsWhat,
        condition: l10n.hardSetsCondition(HardSets.minimumSetsWithRpe),
        current: hard.setsWithRpe,
        required: HardSets.minimumSetsWithRpe,
        accent: AtemColors.tabStrength,
      );
    }

    final totalShift = hard.hardTotal - hard.previousHardTotal;

    return AtemCard.list(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemExplainHeader(
            title: l10n.hardSetsTitle,
            trailing: l10n.hardSetsWindow(days),
            explanation: [
              l10n.hardSetsExplainWhat,
              l10n.hardSetsExplainWhy,
              l10n.hardSetsExplainSides,
              l10n.hardSetsExplainNoTarget(days),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            container: true,
            label: [
              l10n.hardSetsHeadA11y(l10n.hardSetsCount(hard.hardTotal), days),
              _shiftA11y(l10n, totalShift, days),
            ].join(', '),
            child: ExcludeSemantics(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        '${hard.hardTotal}',
                        style: AtemType.valueLarge.of(context).copyWith(
                            fontSize: 28, color: AtemColors.tabStrength),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 5),
                        child: Text(l10n.hardSetsUnit(hard.hardTotal),
                            style: AtemType.meta.of(context)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _Delta(shift: totalShift),
                  ),
                ],
              ),
            ),
          ),
          if (hard.shares.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (var i = 0; i < hard.shares.length; i++) ...[
              if (i > 0)
                const SizedBox(
                    height: 1, child: ColoredBox(color: AtemColors.border)),
              _Row(share: hard.shares[i], days: days),
            ],
          ],
          const SizedBox(height: 12),
          Text(
            l10n.hardSetsBasis(
                hard.hardTotal, hard.setsTotal, hard.setsWithRpe),
            style: AtemType.meta.of(context),
          ),
        ],
      ),
    );
  }
}

String _shiftA11y(AppL10n l10n, int shift, int days) => shift == 0
    ? l10n.hardSetsShiftEqualA11y(days)
    : l10n.hardSetsShiftA11y(
        shift.abs(),
        shift > 0 ? l10n.ratioShiftUp : l10n.ratioShiftDown,
        days,
      );

/// „▲ 2", „▼ 1" oder „— 0". Nur sichtbar — das Wort steht im Label.
class _Delta extends StatelessWidget {
  const _Delta({required this.shift});

  final int shift;

  @override
  Widget build(BuildContext context) {
    final text = shift == 0
        ? '— 0'
        : '${shift > 0 ? '▲' : '▼'} ${shift.abs()}';
    return Text(
      text,
      softWrap: false,
      style: AtemType.labelUi.of(context).copyWith(
            color: AtemColors.textTertiary,
            // Poppins hat kein ▲▼ — Mono springt ein.
            fontFamilyFallback: const ['JetBrainsMono'],
          ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.share, required this.days});

  final HardSetsShare share;
  final int days;

  /// Ab hier stehen Name und Werte untereinander.
  static const _stackedFromScale = 1.6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final name = share.muscle.label(l10n);
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) >= _stackedFromScale;

    final dot = ExcludeSemantics(
      child: AtemStatusDot(color: share.muscle.color),
    );
    final nameText = Text(
      name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AtemType.titleSmallOrDefault(context),
    );
    final values = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('${share.current}',
            softWrap: false, style: AtemType.valueMedium.of(context)),
        const SizedBox(width: 10),
        _Delta(shift: share.shift),
      ],
    );

    return Semantics(
      // Eine Zeile ist ein Knoten.
      container: true,
      label: '$name, ${l10n.hardSetsCount(share.current)}, '
          '${_shiftA11y(l10n, share.shift, days)}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        dot,
                        const SizedBox(width: 10),
                        Expanded(child: nameText),
                      ]),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: values,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      dot,
                      const SizedBox(width: 10),
                      Expanded(child: nameText),
                      const SizedBox(width: 12),
                      values,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
