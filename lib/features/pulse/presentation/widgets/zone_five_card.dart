import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../health_import/application/health_import_providers.dart';
import '../../../health_import/domain/health_session.dart';
import '../../../history/domain/training_session.dart';
import '../../application/pulse_providers.dart';
import '../../domain/heart_rate_zones.dart';
import '../../domain/zone_five_weeks.dart';

/// Zone 5 je Woche — **ein eigener Graph** in der Auswertung (auf Wunsch vom
/// 21.09.2026).
///
/// Oben die laufende Woche als Zahl, darunter acht Wochen als Streifen. Die
/// Zeit im obersten Pulsbereich hat damit ihren eigenen Ort, statt nur eine
/// von fünf Zeilen im Einheitendetail zu sein.
///
/// ## Was er sagt — und was nicht
///
/// Minuten, in denen der Puls über der fünften Grenze lag. Kein Schnitt, kein
/// Vergleich mit den Vorwochen, kein Sollwert: **Mehr ist nicht besser.** Die
/// App weiss nicht, wie viel Zone 5 für diesen Menschen richtig ist, und ein
/// Pfeil neben der Zahl wäre genau das Urteil, das sie nicht fällen darf.
///
/// ## Jede Zahl nennt ihre Grundlage
///
/// Puls gibt es nur für Einheiten aus der Uhr. Darum steht unter der Zahl,
/// aus wie vielen Einheiten sie gerechnet ist — „aus 4 von 14".
///
/// ## Drei Zeichen im Streifen
///
/// * **Mit Zeit in Zone 5** — ein Balken in der Farbe der Zone.
/// * **Gemessen, keine Zeit in Zone 5** — ein 2-dp-Strich. „Der Puls blieb
///   darunter" ist eine Tatsache und bekommt ein Zeichen.
/// * **Kein Puls in dieser Woche** — gar nichts. Ein Strich behauptete eine
///   Messung, die es nie gab.
///
/// Unter der Schwelle steht der [AtemThresholdBlock] — auf Auswertungs-
/// bildschirmen rendert jeder Block. Zwei Bedingungen, ein Nenner: festgelegte
/// Zonen und eine Einheit mit Puls.
class ZoneFiveCard extends ConsumerWidget {
  const ZoneFiveCard({
    super.key,
    required this.sessions,
    required this.reference,
  });

  final List<TrainingSession> sessions;
  final DateTime reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final zones = ref.watch(heartRateZonesProvider);
    final records = ref.watch(healthSessionsProvider).value ?? const [];

    // Nur Übernommenes zählt: Eine wartende Einheit ist „sichtbar, aber ohne
    // Wirkung auf eine einzige Zahl", und eine abgelehnte gehört nicht in
    // die Auswertung.
    final pulses = [
      for (final r in records)
        if (r.state == HealthSessionState.accepted && r.pulse != null)
          PulseRecord(start: r.start, pulse: r.pulse!),
    ];

    final result = zones == null
        ? null
        : ZoneFiveWeeks.compute(
            records: pulses,
            sessionDates: [for (final s in sessions) s.date],
            zones: zones,
            reference: reference,
          );

    if (zones == null || result == null || !result.hasPulse) {
      final hasPulse = pulses.isNotEmpty;
      final done = (zones != null ? 1 : 0) + (hasPulse ? 1 : 0);
      return AtemThresholdBlock(
        title: l10n.zoneFiveTitle,
        condition: zones == null
            ? l10n.zoneFiveConditionZones
            : l10n.zoneFiveConditionPulse,
        current: done,
        required: 2,
        accent: AtemColors.zone5,
        shape: AtemThresholdShape.bars,
      );
    }

    return AtemAnalysisPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemExplainHeader(
            title: l10n.zoneFiveTitle,
            trailing: l10n.weeklySetsWindow(result.weeks.length),
            explanation: [
              l10n.zoneFiveWhat(zones.lowerOf(HeartRateZones.zoneCount)!),
              l10n.zoneFiveExplainNoTarget,
            ],
          ),
          const SizedBox(height: 6),
          _Head(result: result),
          const SizedBox(height: 16),
          _Strip(result: result),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.result});

  final ZoneFiveWeeks result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final current = result.current!;
    final basis =
        l10n.zoneFiveBasis(result.sessionsWithPulse, result.sessionsInWindow);

    // Ohne Puls in dieser Woche steht **keine Zahl** da: „0 min" behauptete,
    // der Puls sei unten geblieben, und gemessen wurde er gar nicht.
    final label = current.measured
        ? '${l10n.zoneFiveHead(current.isoWeek, current.sessions)}, '
            '${l10n.durationMinutes(current.minutes)}, $basis'
        : '${l10n.zoneFiveNoPulseThisWeek}, $basis';

    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              current.measured
                  ? l10n.zoneFiveHead(current.isoWeek, current.sessions)
                  : l10n.zoneFiveNoPulseThisWeek,
              style: AtemType.meta.of(context),
            ),
            if (current.measured) ...[
              const SizedBox(height: 6),
              // Wrap statt Row: Bei 200 % auf 320 dp passen Zahl und Einheit
              // nicht nebeneinander — die Einheit rutscht darunter.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 6,
                children: [
                  AtemAnimatedNumber(
                    value: current.minutes.toDouble(),
                    builder: (context, v) => Text(
                      '${v.round()}',
                      style: AtemType.valueLarge
                          .of(context)
                          .copyWith(fontSize: 28, color: AtemColors.zone5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(l10n.detailLeadDuration,
                        style: AtemType.meta.of(context)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(basis, style: AtemType.meta.of(context)),
          ],
        ),
      ),
    );
  }
}

/// Acht Wochen als Balken — ein Knoten, die Wochen als Satz vorgelesen.
class _Strip extends StatelessWidget {
  const _Strip({required this.result});

  final ZoneFiveWeeks result;

  static const _maxHeight = 56.0;
  static const _minHeight = 6.0;
  static const _barWidth = 18.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final weeks = result.weeks;

    final spoken = [
      for (final w in weeks)
        !w.measured
            ? l10n.zoneFiveWeekNoneA11y(w.isoWeek)
            : w.zone5Seconds == 0
                ? l10n.zoneFiveWeekZeroA11y(w.isoWeek)
                : l10n.zoneFiveWeekA11y(w.isoWeek, w.minutes),
    ].join(', ');

    return Semantics(
      container: true,
      label: l10n.zoneFiveStripA11y(spoken),
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
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: _barWidth,
                          child: _Bar(
                              week: weeks[i],
                              peak: result.peakSeconds,
                              index: i),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Erste und laufende Woche unter dem Streifen. Bei grosser Schrift
            // bliebe für beide nicht genug Platz — dann steht nur die laufende.
            LayoutBuilder(builder: (context, constraints) {
              final first = l10n.weeklySetsAxis(weeks.first.isoWeek);
              final last = l10n.weeklySetsAxis(weeks.last.isoWeek);
              final scaler = MediaQuery.textScalerOf(context);
              final style = AtemType.labelMicro.of(context);
              double width(String t) => (TextPainter(
                    text: TextSpan(text: t, style: style),
                    textDirection: TextDirection.ltr,
                    textScaler: scaler,
                    maxLines: 1,
                  )..layout())
                      .width;
              final both =
                  width(first) + width(last) + 8 <= constraints.maxWidth;
              return Row(
                mainAxisAlignment: both
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
                  if (both) Text(first, maxLines: 1, style: style),
                  Text(
                    last,
                    maxLines: 1,
                    style: style.copyWith(color: AtemColors.zone5),
                  ),
                ],
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

  final ZoneWeek week;
  final int peak;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Kein Puls: nichts. Die App hat diese Woche nicht gemessen.
    if (!week.measured) return const SizedBox(key: ValueKey('none'));

    // Gemessen, der Puls blieb unter Zone 5: der 2-dp-Strich.
    if (week.zone5Seconds == 0) {
      return Container(
        key: const ValueKey('zero'),
        height: 2,
        decoration: BoxDecoration(
          color: AtemColors.border,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
        ),
      );
    }

    final fraction = peak <= 0 ? 0.0 : week.zone5Seconds / peak;
    final height =
        _Strip._minHeight + (_Strip._maxHeight - _Strip._minHeight) * fraction;

    return AtemReveal(
      key: const ValueKey('filled'),
      delay: Duration(milliseconds: 30 * index),
      builder: (context, t) => Container(
        height: math.max(2.0, height * t),
        decoration: BoxDecoration(
          // Die laufende Woche in voller Farbe, die anderen gedämpft.
          color: week.isCurrent
              ? AtemColors.zone5
              : AtemColors.zone5.withValues(alpha: 0.45),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}
