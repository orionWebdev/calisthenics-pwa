import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
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
///
/// ## Zahl über dem Balken, Kürzel darunter
///
/// Board 06, Spezifikation: Die Zahl steht über jedem Balken, beim Nullmonat
/// in Magenta — die Nullen sind die eigentliche Information. Und jeder
/// Balken ist ein 48-dp-Ziel (Entscheidung 08): Er öffnet die Einheitenliste
/// auf diesen Monat.
class MonthStrip extends StatelessWidget {
  const MonthStrip({super.key, required this.summary, this.onSelect});

  final HistorySummary summary;

  /// Ein Monat wurde angetippt. `null` heisst: nur ansehen.
  final void Function(int year, int month)? onSelect;

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

    final tappable = onSelect != null;
    // Zahl über dem Balken: Die Zeile wächst mit der Schrift, der Balken nicht.
    // Zeilenhöhe der Zahl (Faktor 1,5 auf die Schriftgrösse) plus Abstand.
    final stripHeight =
        _maxHeight + MediaQuery.textScalerOf(context).scale(10) * 1.5 + 8;

    return Semantics(
      // Ein Knoten für die Gruppe, solange es nichts zu tippen gibt. Mit
      // Tap-Zielen trägt jeder Balken seinen eigenen — sonst bliebe die
      // Sammelansage der einzige Weg hinein.
      label: tappable
          ? null
          : [
              l10n.historyMonthsLabel,
              for (final m in months)
                '${_monthName(context, m.month)} ${m.count}',
              if (label != null) label,
            ].join(', '),
      child: ExcludeSemantics(
        excluding: !tappable,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              excluding: !tappable,
              child: Semantics(
                label: [
                  l10n.historyMonthsLabel,
                  if (label != null) label,
                ].join(', '),
                child: ExcludeSemantics(
                  child: Text(l10n.historyMonthsLabel,
                      style: AtemType.labelMedium.of(context)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              // Zahl plus Balken — und mindestens ein 48-dp-Ziel.
              height: stripHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < months.length; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(
                      child: tappable
                          ? AtemTappable(
                              onTap: () => onSelect!(
                                  months[i].year, months[i].month),
                              semanticLabel: l10n.historyMonthOpenA11y(
                                  _monthName(context, months[i].month),
                                  months[i].count),
                              minTapSize: Size(0, stripHeight),
                              alignment: Alignment.bottomCenter,
                              child: _Bar(month: months[i], peak: peak, index: i),
                            )
                          : _Bar(month: months[i], peak: peak, index: i),
                    ),
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
              Text(label, style: AtemType.meta.of(context)),
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
  const _Bar({required this.month, required this.peak, required this.index});

  /// Position im Streifen — sie staffelt das Wachsen.
  final int index;

  final MonthCount month;
  final int peak;

  @override
  Widget build(BuildContext context) {
    // Ein leerer Monat bekommt eine sichtbare Grundlinie, keinen Nullbalken:
    // Sonst sähe die Lücke aus wie fehlende Daten statt wie fehlendes Training.
    final fraction = peak <= 0 ? 0.0 : month.count / peak;
    final height =
        month.isEmpty ? 2.0 : math.max(6.0, fraction * MonthStrip._maxHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Die Zahl über dem Balken; die Null in Magenta — sie ist die
        // Information, nicht der Balken.
        Text(
          '${month.count}',
          maxLines: 1,
          style: AtemType.labelDeco.of(context).copyWith(
                color: month.isEmpty ? AtemColors.magenta : AtemColors.textTertiary,
                letterSpacing: 0,
              ),
        ),
        const SizedBox(height: 3),
        // Der Balken wächst aus der Grundlinie — versetzt nach Monat, damit
        // der Streifen von links nach rechts entsteht.
        AtemReveal(
          delay: Duration(milliseconds: 30 * index),
          builder: (context, t) => Container(
            height: month.isEmpty ? height : math.max(2.0, height * t),
            width: double.infinity,
            decoration: BoxDecoration(
              color: month.isEmpty ? AtemColors.border : AtemColors.cyan,
              borderRadius: BorderRadius.circular(AtemRadii.pill),
            ),
          ),
        ),
      ],
    );
  }
}
