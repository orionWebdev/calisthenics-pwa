import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/history_summary.dart';

/// Einheiten je Monat — **mit den leeren Monaten**.
///
/// ## Warum kein Durchschnitt
///
/// Im Bestand steht 1 Einheit im November und 30 im Mai. „Im Schnitt alle 2,2
/// Tage" beschreibt keinen einzigen realen Monat und verschweigt genau das,
/// was zählt: dass es Pausen gab.
///
/// Ein Streifen, der nur Monate mit Training zeigt, macht denselben Fehler
/// grafisch — er reiht die guten Monate aneinander und behauptet Gleichmaß.
/// Die leeren Monate stehen deshalb als leere Spalte mit.
class MonthStrip extends StatelessWidget {
  const MonthStrip({super.key, required this.summary});

  final HistorySummary summary;

  static const _maxHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final months = summary.months;
    if (months.isEmpty) return const SizedBox.shrink();

    final peak = months.fold<int>(0, (a, m) => math.max(a, m.count));
    final label =
        summary.medianGapDays != null && summary.longestGapDays != null
            ? l10n.historyMonthsMedian(
                summary.medianGapDays!, summary.longestGapDays!)
            : null;

    return Semantics(
      label: [
        l10n.historyMonthsLabel,
        for (final m in months) '${_monthName(context, m.month)} ${m.count}',
        if (label != null) label,
      ].join(', '),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.historyMonthsLabel,
                style: AtemType.labelMedium.of(context)),
            const SizedBox(height: 12),
            SizedBox(
              height: _maxHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < months.length; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(child: _Bar(month: months[i], peak: peak)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < months.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _monthInitial(context, months[i].month),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AtemType.labelDeco.of(context).copyWith(
                            color: months[i].isEmpty
                                ? AtemColors.border
                                : AtemColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(label, style: AtemType.labelMicro.of(context)),
            ],
          ],
        ),
      ),
    );
  }

  /// Der volle Monatsname für die Ansage.
  ///
  /// Über `intl` und das Gebietsschema, nicht über eine eigene Liste — sonst
  /// stünde eine zweite Übersetzung neben dem ARB.
  static String _monthName(BuildContext context, int month) =>
      DateFormat.MMMM(Localizations.localeOf(context).toLanguageTag())
          .format(DateTime(2026, month));

  /// Der Anfangsbuchstabe für die Achse. Er folgt derselben Quelle, damit
  /// Ansage und Beschriftung nicht auseinanderlaufen.
  static String _monthInitial(BuildContext context, int month) =>
      _monthName(context, month).characters.first.toUpperCase();
}

class _Bar extends StatelessWidget {
  const _Bar({required this.month, required this.peak});

  final MonthCount month;
  final int peak;

  @override
  Widget build(BuildContext context) {
    // Ein leerer Monat bekommt eine sichtbare Grundlinie, keinen Nullbalken:
    // Sonst sähe die Lücke aus wie fehlende Daten statt wie fehlendes Training.
    final fraction = peak <= 0 ? 0.0 : month.count / peak;
    final height =
        month.isEmpty ? 2.0 : math.max(4.0, fraction * MonthStrip._maxHeight);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: month.isEmpty ? AtemColors.border : AtemColors.cyan,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
