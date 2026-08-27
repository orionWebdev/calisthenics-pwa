import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/history_summary.dart';
import '../history_zone_ui.dart';

/// Die Aussage-Karte: **ein Satz zuerst**, die Zahlen als Begründung darunter.
///
/// Sie ist die einzige hervorgehobene Karte des Bildschirms. Der Satz kommt aus
/// dem Abstand zur letzten Einheit, nicht aus dem Form-Wert: Der Abstand ist
/// eine gemessene Tatsache, der Form-Wert eine Rechnung mit fünf Bestandteilen.
/// Wer seit fünfzig Tagen nicht trainiert hat, soll das lesen und nicht erst
/// eine 16 deuten müssen.
///
/// ## Gleiche Höhe über alle vier Zonen
///
/// Die Karte darf beim Zonenwechsel nicht springen. Eine **feste Pixelhöhe**
/// wäre dafür der falsche Weg: Bei 200 % Systemschrift schnitte sie den Text ab
/// und verstieße gegen den A11y-Vertrag, der feste Höhen um Text verbietet.
///
/// Stattdessen wird der längste der vier Sätze **gemessen** und seine Höhe
/// reserviert. Ergebnis: über die Zonen stabil, mit der Schriftgröße wachsend.
/// Dasselbe Verfahren wie bei den Beschriftungen der Navigation.
class StatementCard extends StatelessWidget {
  const StatementCard({super.key, required this.summary});

  final HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final zone = summary.zone;
    final days = summary.daysSinceLast ?? 0;

    final statement = summary.showsFrequency
        ? l10n.historyLeadFrequency(
            summary.sessionsInWindow!, summary.windowDays!)
        : l10n.historyLeadGap(days);

    return AtemCard.gradientBorder(
      glow: zone.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AtemStatusDot(color: zone.color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  zone.label(l10n).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.labelMicro.of(context).copyWith(
                        color: zone.color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FixedHeightStatement(
            text: statement,
            style: AtemType.titleLarge.of(context),
            // Alle vier Möglichkeiten, damit die Höhe nicht an der aktuellen
            // Zone hängt.
            candidates: [
              statement,
              l10n.historyLeadGap(999),
              l10n.historyLeadGap(1),
              l10n.historyLeadFrequency(99, 14),
            ],
          ),
          if (summary.form.hasScore) ...[
            const SizedBox(height: 10),
            _FormLine(summary: summary),
          ],
        ],
      ),
    );
  }
}

/// Reserviert die Höhe des längsten Kandidaten.
class _FixedHeightStatement extends StatelessWidget {
  const _FixedHeightStatement({
    required this.text,
    required this.style,
    required this.candidates,
  });

  final String text;
  final TextStyle style;
  final List<String> candidates;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        var tallest = 0.0;

        for (final candidate in candidates) {
          final painter = TextPainter(
            text: TextSpan(text: candidate, style: style),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
            maxLines: 2,
          )..layout(maxWidth: constraints.maxWidth);
          tallest = math.max(tallest, painter.height);
        }

        return SizedBox(
          height: tallest,
          width: double.infinity,
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        );
      },
    );
  }
}

class _FormLine extends StatelessWidget {
  const _FormLine({required this.summary});

  final HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final form = summary.form;
    final trend = form.trend.label(l10n);

    final parts = <String>[
      '${l10n.historyFormLabel} ${l10n.historyFormOf(form.score!)}',
      if (trend != null) trend,
      if (summary.acwr?.acwr case final v?) 'ACWR ${v.toStringAsFixed(2)}',
    ];

    return Text(
      parts.join(' · '),
      style: AtemType.labelSmall.of(context),
    );
  }
}
