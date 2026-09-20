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
        condition: l10n.weeklySetsCondition,
        current: 0,
        required: 1,
        accent: AtemColors.tabStrength,
        shape: AtemThresholdShape.curve,
      );
    }

    return AtemAnalysisPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemExplainHeader(
            title: l10n.weeklySetsTitle,
            trailing: l10n.weeklySetsWindow(volume.weeks.length),
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
                    // Poppins hat kein ▲▼ — Mono springt ein.
                    child: AtemBadge(
                      label: pill,
                      style: AtemTextRole(
                        AtemType.labelUi.base.copyWith(
                            fontFamilyFallback: const ['JetBrainsMono']),
                        trackingEm: AtemType.labelUi.trackingEm,
                      ),
                    ),
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

  static const _maxHeight = 56.0;
  static const _minHeight = 6.0;
  static const _barWidth = 18.0;
  static const _gap = 4.0;

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
                    if (i > 0) const SizedBox(width: _gap),
                    // Feste schmale Balken, zentriert in der Spalte — wie im
                    // Monatsstreifen. Vorher füllte der Balken die Spalte,
                    // und eine einzige Woche wurde zum runden Klecks.
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: _barWidth,
                          child: _Bar(week: weeks[i], peak: peak, index: i),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Die Beschriftung steht **unter ihrer Spalte**: erste Woche
            // unter dem ersten Balken, letzte unter dem letzten — am Rand
            // festgehalten, damit sie nicht aus der Karte ragt.
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final column = (width - _gap * (weeks.length - 1)) / weeks.length;
              final first = l10n.weeklySetsAxis(weeks.first.isoWeek);
              final last = l10n.weeklySetsAxis(weeks.last.isoWeek);
              final firstStyle = AtemType.labelMicro.of(context);
              final lastStyle = AtemType.labelMicro
                  .of(context)
                  .copyWith(color: AtemColors.tabStrength);
              final scaler = MediaQuery.textScalerOf(context);
              Size measure(String t, TextStyle st) => (TextPainter(
                    text: TextSpan(text: t, style: st),
                    textDirection: TextDirection.ltr,
                    textScaler: scaler,
                    maxLines: 1,
                  )..layout())
                      .size;
              final firstSize = measure(first, firstStyle);
              final lastSize = measure(last, lastStyle);
              final firstLeft = (column / 2 - firstSize.width / 2)
                  .clamp(0.0, math.max(0.0, width - firstSize.width))
                  .toDouble();
              final lastLeft = (width - column / 2 - lastSize.width / 2)
                  .clamp(0.0, math.max(0.0, width - lastSize.width))
                  .toDouble();
              // Bei grosser Schrift überlappen die beiden — dann bleibt nur
              // die aktuelle Woche stehen.
              final overlap = firstLeft + firstSize.width + 8 > lastLeft;
              return SizedBox(
                height: math.max(firstSize.height, lastSize.height),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (!overlap)
                      Positioned(
                        left: firstLeft,
                        top: 0,
                        child: Text(first, maxLines: 1, style: firstStyle),
                      ),
                    Positioned(
                      left: lastLeft,
                      top: 0,
                      child: Text(last, maxLines: 1, style: lastStyle),
                    ),
                  ],
                ),
              );
            }),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}
