import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/training_session.dart';
import '../../domain/weekly_strength_volume.dart';

/// Sätze je Woche — **die Wochenkachel aus Cardio, auf Sätze** (Kraft-
/// Auswertung, 16.09.2026).
///
/// Oben die laufende Woche als Zahl, daneben die Verschiebung gegen den
/// 4-Wochen-Schnitt, darunter acht Wochen als Streifen. Die laufende Woche
/// trägt den Bereichston Kraft; die anderen stehen gedämpft in Cyan.
///
/// ## Drei Arten Woche, drei Zeichen
///
/// * **Mit Sätzen** — ein Balken, Höhe relativ zum Maximum des Streifens.
/// * **Gemessen, ohne Satz** — ein 2-dp-Strich in `#232334`. „Gemessen: 0"
///   ist etwas anderes als „nichts gemessen" und bekommt deshalb ein Zeichen.
/// * **Vor der ersten Krafteinheit** — gar nichts. Diese Woche hat die App
///   nicht gesehen; ein Strich behauptete eine Pause, die es nicht gab.
///
/// Unter der Schwelle (keine Einheit mit Sätzen) steht der
/// [AtemThresholdBlock] — auf Auswertungsbildschirmen rendert jeder Block.
///
/// Seit 17.09.2026: Was der Block zeigt und wie der Schnitt gerechnet wird,
/// steht hinter dem ⓘ. Die Sätze dieser Woche sind die Hauptzahl und tragen
/// den Akzent Kraft; alles andere ist Beschriftung in der dritten Textstufe.
class WeeklySetsCard extends StatelessWidget {
  const WeeklySetsCard({
    super.key,
    required this.sessions,
    required this.reference,
  });

  final List<TrainingSession> sessions;
  final DateTime reference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final volume = WeeklyStrengthVolume.compute(sessions, reference);

    if (!volume.hasSets) {
      return AtemThresholdBlock(
        title: l10n.weeklySetsTitle,
        what: l10n.weeklySetsWhat,
        condition: l10n.weeklySetsCondition,
        current: 0,
        required: 1,
        accent: AtemColors.tabStrength,
      );
    }

    return AtemCard.list(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemExplainHeader(
            title: l10n.weeklySetsTitle,
            explanation: [l10n.weeklySetsWhat, l10n.weeklySetsExplainAverage],
          ),
          const SizedBox(height: 6),
          _Head(volume: volume),
          const SizedBox(height: 16),
          _Strip(volume: volume),
          if (volume.sessionsWithoutSets > 0) ...[
            const SizedBox(height: 10),
            // Die eine sichtbare Hinweiszeile: eine Tatsache über genau
            // diese Daten, deshalb Beschriftung, kein Lesetext.
            Text(
              l10n.weeklySetsWithoutSets(volume.sessionsWithoutSets),
              style: AtemType.meta.of(context),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kopfzeile, Zahl der Woche, Verschiebung und Grundlage — ein Knoten.
class _Head extends StatelessWidget {
  const _Head({required this.volume});

  final WeeklyStrengthVolume volume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final current = volume.current!;
    final sets = volume.currentSets;
    final shift = volume.shift;
    final avg = volume.fourWeekAverage;
    final avgText =
        avg == null ? null : AtemNumberField.format(context, _oneDecimal(avg));

    final rounded = shift?.round();
    final pill = rounded == null
        ? null
        : rounded == 0
            ? '— 0'
            : '${rounded > 0 ? '▲' : '▼'} ${rounded > 0 ? '+' : '−'}${rounded.abs()}';

    final label = [
      l10n.weeklySetsHeadA11y(
        l10n.weeklySetsCount(sets),
        l10n.weeklySetsSessions(volume.currentSessions),
      ),
      if (rounded != null && avgText != null)
        rounded == 0
            ? l10n.weeklySetsShiftEqualA11y(avgText)
            : l10n.weeklySetsShiftA11y(
                '${rounded.abs()}',
                rounded > 0 ? l10n.ratioShiftUp : l10n.ratioShiftDown,
                avgText,
              )
      else
        l10n.weeklySetsPending(volume.weeksUntilComparison),
    ].join(', ');

    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.weeklySetsWeek(current.isoWeek)} · '
              '${l10n.weeklySetsSessions(volume.currentSessions)}',
              style: AtemType.meta.of(context),
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 10,
              runSpacing: 6,
              children: [
                // Wrap statt Row: Bei 200 % auf 320 dp passen Zahl und
                // Einheit nicht nebeneinander — die Einheit rutscht darunter.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    AtemAnimatedNumber(
                      value: sets.toDouble(),
                      builder: (context, v) => Text(
                        '${v.round()}',
                        style: AtemType.valueLarge.of(context).copyWith(
                            fontSize: 28, color: AtemColors.tabStrength),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 5),
                      child: Text(l10n.weeklySetsUnit(sets),
                          style: AtemType.meta.of(context)),
                    ),
                  ],
                ),
                if (pill != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: AtemBadge(label: pill),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              avgText == null
                  ? l10n.weeklySetsPending(volume.weeksUntilComparison)
                  : l10n.weeklySetsBasis(avgText),
              style: AtemType.meta.of(context),
            ),
          ],
        ),
      ),
    );
  }

  static double _oneDecimal(double v) => (v * 10).round() / 10;
}

/// Acht Wochen als Balken — ein Knoten, die Wochen als Satz vorgelesen.
class _Strip extends StatelessWidget {
  const _Strip({required this.volume});

  final WeeklyStrengthVolume volume;

  static const _maxHeight = 64.0;
  static const _minHeight = 10.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final weeks = volume.weeks;
    final peak = volume.peakSets;

    final spoken = [
      for (final w in weeks)
        w.beforeStart
            ? l10n.weeklySetsBeforeStartA11y(w.isoWeek)
            : l10n.weeklySetsWeekA11y(w.isoWeek, w.sets),
    ].join(', ');

    return Semantics(
      container: true,
      label: l10n.weeklySetsStripA11y(spoken),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _maxHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < weeks.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: _Bar(week: weeks[i], peak: peak, index: i),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.weeklySetsAxis(weeks.first.isoWeek),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.labelMicro.of(context),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    l10n.weeklySetsAxis(weeks.last.isoWeek),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(color: AtemColors.tabStrength),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.week, required this.peak, required this.index});

  final WeekSets week;
  final int peak;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Vor dem Beginn: nichts. Die App hat diese Woche nicht gesehen.
    if (week.beforeStart) return const SizedBox(key: ValueKey('before'));

    if (week.isEmpty) {
      return Container(
        key: const ValueKey('empty'),
        height: 2,
        decoration: BoxDecoration(
          color: AtemColors.border,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
        ),
      );
    }

    final fraction = peak <= 0 ? 0.0 : week.sets / peak;
    final height =
        _Strip._minHeight + (_Strip._maxHeight - _Strip._minHeight) * fraction;

    // Der Balken wächst aus der Grundlinie, von links nach rechts versetzt.
    return AtemReveal(
      key: const ValueKey('filled'),
      delay: Duration(milliseconds: 30 * index),
      builder: (context, t) => Container(
        height: math.max(2.0, height * t),
        decoration: BoxDecoration(
          color: week.isCurrent
              ? AtemColors.tabStrength
              : AtemColors.cyan.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AtemRadii.pill),
        ),
      ),
    );
  }
}
