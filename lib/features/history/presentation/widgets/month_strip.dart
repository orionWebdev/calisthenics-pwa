import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/history_summary.dart';

/// Einheiten je Monat — **ein festes Fenster von bis zu sechs Monaten**.
///
/// ## Warum ein festes Fenster (seit 16.09.2026)
///
/// Vorher stand jeder Monat von der ersten bis zur letzten Einheit als
/// `Expanded`-Spalte. Nach einem Neubeginn mit einer einzigen Einheit füllte
/// ein Balken die ganze Kartenbreite — ein Trainingstag sah aus wie ein
/// Rekordmonat. Jetzt hat jeder der sechs Monate dieselbe Spalte und einen
/// schmalen Balken fester Breite; die Menge zeigt allein die Höhe.
///
/// ## Drei Zustände je Monat
///
/// * **Vor der ersten Einheit:** nicht gemessen — kein Balken, kein Strich,
///   nur das Kürzel. Ein Nullstrich behauptete dort ein Messergebnis.
/// * **Gemessen, ohne Einheit:** ein 2-dp-Strich in `border`. „Gemessen: 0"
///   ist eine Aussage, und die Pausen sind die eigentliche Information.
/// * **Mit Einheiten:** Balken, Höhe relativ zum Maximum des Fensters,
///   mindestens 6 dp, damit eine einzelne Einheit sichtbar bleibt. Der
///   aktuelle Monat trägt den Bereichston.
///
/// ## Keine glatte Zahl aus dünner Grundlage
///
/// Median-Abstand und längste Pause stehen erst ab drei Einheiten. Aus zwei
/// Einheiten wird ein „Median" eine einzelne Differenz, die wie eine
/// Gewohnheit aussieht.
class MonthStrip extends StatelessWidget {
  const MonthStrip({super.key, required this.summary, this.onSelect});

  final HistorySummary summary;

  /// Ein Monat wurde angetippt. `null` heisst: nur ansehen.
  final void Function(int year, int month)? onSelect;

  /// Höhe der Balkenfläche. Fest — die Schrift wächst darüber und darunter.
  static const chartHeight = 72.0;

  /// Breite eines gefüllten Balkens.
  static const barWidth = 18.0;

  static const _minBar = 6.0;

  /// Ab dieser effektiven Schriftgrösse wird das Monatskürzel einbuchstabig.
  static const _initialScale = 1.6;

  /// Ab so vielen Einheiten stehen Median und längste Pause.
  static const gapLineMinimum = 3;

  /// Kleinste Spaltenbreite — das Tap-Ziel eines Monats.
  static const _minColumn = 48.0;

  /// Mindestens so viele Monate, auch auf dem schmalsten Bildschirm.
  static const _minMonths = 3;

  @override
  Widget build(BuildContext context) {
    final full = summary.monthWindow;
    if (full.slots.isEmpty) return const SizedBox.shrink();

    // **Nicht jede Breite trägt sechs 48-dp-Ziele.** Bei 320 dp bleiben in der
    // Karte rund 258 dp — sechs Spalten wären je 43 dp. Dann stehen die
    // letzten Monate, die voll antippbar sind; Kopf, Grundlage und Ansage
    // zählen genau diese.
    return AtemCard.list(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fit = (constraints.maxWidth / _minColumn).floor();
          final months = fit.clamp(_minMonths, full.slots.length);
          return _content(context, full.lastMonths(months));
        },
      ),
    );
  }

  Widget _content(BuildContext context, MonthWindow window) {
    final l10n = AppL10n.of(context);

    final tag = Localizations.localeOf(context).toLanguageTag();
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final peak = window.peak;

    final basis = window.firstDate == null
        ? null
        : l10n.monthsBasis(
            window.sessions,
            window.trainingDays,
            DateFormat.MMMd(tag).format(window.firstDate!),
          );
    final gapLine = summary.sessions >= gapLineMinimum &&
            summary.medianGapDays != null &&
            summary.longestGapDays != null
        ? l10n.historyMonthsMedian(
            summary.medianGapDays!, summary.longestGapDays!)
        : null;

    final sentence = [
      for (final slot in window.slots)
        slot.measured
            ? l10n.monthsEntryA11y(_monthName(tag, slot.month), slot.count)
            : l10n.monthsNotMeasuredA11y(_monthName(tag, slot.month)),
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ein Knoten für den ganzen Streifen: Titel, Fenster, Grundlage und
        // alle sichtbaren Monate als Satz. Die antippbaren Monate kommen danach
        // als eigene Knöpfe.
        Semantics(
          container: true,
          label: [
            l10n.historyMonthsLabel,
            l10n.monthsWindow(window.slots.length),
            if (basis != null) basis,
            sentence,
            if (gapLine != null) gapLine,
          ].join('. '),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(l10n.historyMonthsLabel,
                        style: AtemType.titleMedium.of(context)),
                    Text(l10n.monthsWindow(window.slots.length),
                        style: AtemType.meta.of(context)),
                  ],
                ),
                if (basis != null) ...[
                  const SizedBox(height: 4),
                  Text(basis, style: AtemType.meta.of(context)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < window.slots.length; i++)
              Expanded(
                child: _Column(
                  slot: window.slots[i],
                  peak: peak,
                  index: i,
                  label: scale >= _initialScale
                      ? _monthName(tag, window.slots[i].month)
                          .characters
                          .first
                          .toUpperCase()
                      : _monthShort(tag, window.slots[i].month),
                  onTap: onSelect == null || !window.slots[i].hasSessions
                      ? null
                      : () => onSelect!(
                          window.slots[i].year, window.slots[i].month),
                  semanticLabel: l10n.historyMonthOpenA11y(
                    _monthName(tag, window.slots[i].month),
                    window.slots[i].count,
                  ),
                ),
              ),
          ],
        ),
        if (gapLine != null) ...[
          const SizedBox(height: 14),
          ExcludeSemantics(
            child: Text(gapLine, style: AtemType.meta.of(context)),
          ),
        ],
      ],
    );
  }

  /// Der volle Monatsname — über `intl`, damit keine zweite Übersetzung
  /// neben dem ARB entsteht.
  static String _monthName(String tag, int month) =>
      DateFormat.MMMM(tag).format(DateTime(2026, month));

  /// Das Kürzel für die Achse, ohne Abkürzungspunkt.
  static String _monthShort(String tag, int month) =>
      DateFormat.MMM(tag).format(DateTime(2026, month)).replaceAll('.', '');
}

/// Eine Monatsspalte: Zahl, Balken oder Strich, Kürzel.
class _Column extends StatelessWidget {
  const _Column({
    required this.slot,
    required this.peak,
    required this.index,
    required this.label,
    required this.onTap,
    required this.semanticLabel,
  });

  final MonthSlot slot;
  final int peak;

  /// Position im Streifen — sie staffelt das Wachsen.
  final int index;

  final String label;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fraction = peak <= 0 ? 0.0 : slot.count / peak;
    final target =
        math.max(MonthStrip._minBar, fraction * MonthStrip.chartHeight);
    final barColor = slot.isCurrent
        ? AtemColors.tabStrength
        : AtemColors.cyan.withValues(alpha: 0.7);

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Die Zahl steht über dem Balken und wächst mit der Schrift; die
        // Balkenfläche darunter bleibt fest hoch.
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(12) * 1.4,
          child: slot.hasSessions
              ? Text(
                  '${slot.count}',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: AtemType.labelMicro.of(context).copyWith(
                        color: AtemColors.textTertiary,
                        letterSpacing: 0,
                      ),
                )
              : null,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: MonthStrip.chartHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: switch ((slot.measured, slot.hasSessions)) {
              // Nicht gemessen: nichts.
              (false, _) => const SizedBox(width: MonthStrip.barWidth),
              // Gemessen, keine Einheit: der Strich.
              (true, false) => Container(
                  key: const ValueKey('month-zero'),
                  width: MonthStrip.barWidth,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AtemColors.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              // Mit Einheiten: der Balken wächst aus der Grundlinie.
              (true, true) => AtemReveal(
                  delay: Duration(milliseconds: 40 * index),
                  builder: (context, t) => Container(
                    key: const ValueKey('month-bar'),
                    width: MonthStrip.barWidth,
                    height: math.max(2.0, target * t),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          textAlign: TextAlign.center,
          style: AtemType.labelMicro.of(context).copyWith(
                letterSpacing: 0,
                color: slot.measured
                    ? AtemColors.textTertiary
                    : AtemColors.textSecondary,
              ),
        ),
      ],
    );

    if (onTap == null) return ExcludeSemantics(child: column);

    return AtemTappable(
      onTap: onTap!,
      semanticLabel: semanticLabel,
      minTapSize: const Size(48, 48),
      child: ExcludeSemantics(child: column),
    );
  }
}
