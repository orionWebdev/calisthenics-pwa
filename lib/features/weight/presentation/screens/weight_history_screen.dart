import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../application/weight_providers.dart';
import '../../domain/weight_entry.dart';
import '../../domain/weight_series.dart';
import '../weight_ui.dart';
import '../widgets/weight_chart.dart';
import '../widgets/weight_entry_sheet.dart';

/// Der Gewichtsverlauf (Board 14, Abschnitt C).
///
/// ## Der Nenner beschreibt das Fenster, nicht das Konto
///
/// „13 Einträge seit 21. Mär" ändert sich mit der Range-Pille. Eine Zahl, die
/// die Lebenszeit des Kontos nennt, während die Kurve sechs Monate zeigt, wäre
/// ein Nenner zum falschen Zähler.
class WeightHistoryScreen extends ConsumerStatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  ConsumerState<WeightHistoryScreen> createState() =>
      _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends ConsumerState<WeightHistoryScreen> {
  WeightRange _range = WeightRange.sixMonths;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(weightSeriesProvider);

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(backgroundColor: AtemColors.base),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtemSpacing.screenPadding),
            child: AtemSkeleton(
              semanticLabel: l10n.weightLoadingA11y,
              blocks: const [
                AtemSkeletonBlock(height: 28, radius: 8),
                AtemSkeletonBlock(height: 140),
                AtemSkeletonBlock(height: 180),
              ],
            ),
          ),
          error: (_, __) => AtemErrorState(
            title: l10n.weightHistoryTitle,
            body: l10n.weightLoadError,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(weightSeriesProvider),
          ),
          data: (series) => _content(context, l10n, series),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppL10n l10n, WeightSeries series) {
    final window = series.within(_range, ref.watch(historyReferenceProvider));
    final latest = window.latest ?? ref.watch(latestWeightProvider);
    // Neueste zuerst: Wer den Verlauf öffnet, sucht fast immer den letzten
    // Wert, nicht den ersten.
    final rows = window.entries.reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AtemSpacing.screenPadding, 0,
          AtemSpacing.screenPadding, 40),
      children: [
        AtemExplainHeader(
          title: l10n.weightBlockTitle,
          titleStyle: AtemType.titleLarge.of(context),
          explanation: [
            l10n.weightExplainBody,
            l10n.weightExplainChange,
            l10n.weightExplainGaps,
            l10n.weightExplainSources,
            l10n.weightExplainLoad,
          ],
        ),
        const SizedBox(height: 14),
        _RangePills(
          value: _range,
          onChanged: (range) => setState(() => _range = range),
        ),
        const SizedBox(height: 14),
        if (latest != null)
          AtemCard.list(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Headline(series: window, latest: latest),
                if (window.length >= 2) ...[
                  const SizedBox(height: 8),
                  WeightChart(
                    series: window,
                    height: WeightChart.fullHeight,
                    semanticLabel: WeightUi.chartLabel(context, l10n, window),
                  ),
                  if (window.namedGap case final gap?) ...[
                    const SizedBox(height: 6),
                    WeightGapNote(label: l10n.weightGapNote(gap.weeks)),
                  ],
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        AtemButton.outline(
          label: l10n.weightEnterCta,
          semanticLabel: l10n.weightEnterCta,
          onPressed: () => showWeightEntrySheet(context, ref),
        ),
        const SizedBox(height: 8),
        for (final entry in rows)
          _Row(
            entry: entry,
            onTap: () => showWeightEntrySheet(context, ref, entry: entry),
          ),
      ],
    );
  }
}

/// Wert und Grundlage — die Zahl nennt immer, worüber sie spricht.
class _Headline extends StatelessWidget {
  const _Headline({required this.series, required this.latest});

  final WeightSeries series;
  final WeightEntry latest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final from = series.first;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      alignment: WrapAlignment.spaceBetween,
      spacing: 10,
      runSpacing: 2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(WeightUi.kg(context, latest.kg),
                style: AtemType.valueLarge.of(context)),
            const SizedBox(width: 5),
            Text(l10n.weightUnitKg, style: AtemType.labelMicro.of(context)),
          ],
        ),
        if (from != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              l10n
                  .weightBasis(series.length,
                      WeightUi.shortDate(context, from.date))
                  .toUpperCase(),
              style: AtemType.labelMicro.of(context),
            ),
          ),
      ],
    );
  }
}

/// Die vier Fenster. Eine Gruppe, genau eines ausgewählt.
class _RangePills extends StatelessWidget {
  const _RangePills({required this.value, required this.onChanged});

  final WeightRange value;
  final ValueChanged<WeightRange> onChanged;

  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    // **Gemessen, nicht geraten.** Vier Spalten, solange die Beschriftungen
    // nebeneinander passen; sonst zwei, sonst eine. Ein starres Vierer-Raster
    // zerlegte „3 Mon." bei 200 % Schrift auf 320 dp in vier Zeilen
    // („3 / M / on / ."), am Render gesehen — genau der Bruch, an dem jede
    // Reiterleiste scheitert.
    //
    // `AtemChoiceChip` füllt den Raum, den es bekommt; ohne feste Zellbreite
    // wird daraus in einem `Wrap` eine Kapsel je Zeile.
    final style = AtemType.labelSmall.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double widthOf(String text) => (TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout())
            .width;

    final widest = WeightRange.values
        .map((range) => widthOf(WeightUi.rangeLabel(l10n, range)))
        .reduce((a, b) => a > b ? a : b);
    // 28 dp Innenpolster der Kapsel, 20 dp für Häkchen und Abstand.
    final needed = widest + 28 + 20;

    return Semantics(
      container: true,
      label: l10n.weightRangeGroup,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var columns = 4;
          while (columns > 1 &&
              needed * columns + _gap * (columns - 1) > constraints.maxWidth) {
            columns = columns == 4 ? 2 : 1;
          }
          final cell =
              (constraints.maxWidth - _gap * (columns - 1)) / columns;

          return Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final range in WeightRange.values)
                SizedBox(
                  width: cell,
                  child: AtemChoiceChip(
                    label: WeightUi.rangeLabel(l10n, range),
                    semanticLabel:
                        l10n.weightRangeA11y(WeightUi.rangeLabel(l10n, range)),
                    selected: range == value,
                    onTap: () => onChanged(range),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Eine Zeile ist **ein** Knoten: Punkt, Datum, Wert, Pfeil — nicht vier
/// Werte, die ein Vorleseprogramm einzeln aufsagt.
class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.onTap});

  final WeightEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemTappable(
      onTap: onTap,
      semanticLabel: l10n.weightRowA11y(
        WeightUi.shortDate(context, entry.date),
        WeightUi.kg(context, entry.kg),
        WeightUi.source(l10n, entry.source),
      ),
      // Board 14, F nennt 44 dp. CLAUDE.md verlangt 48 dp Trefferfläche für
      // jedes Tap-Ziel und ist nicht verhandelbar — die Zeile ist 48.
      minTapSize: const Size(0, 48),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AtemColors.track)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ExcludeSemantics(
          child: Row(
            children: [
              _SourceDot(source: entry.source),
              const SizedBox(width: 10),
              Expanded(
                child: Text(WeightUi.shortDate(context, entry.date),
                    style: AtemType.labelSmall.of(context)),
              ),
              Text(WeightUi.kg(context, entry.kg),
                  style: AtemType.valueMedium.of(context)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 16, color: AtemColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gefüllt gegen hohl — **dieselbe Form, dieselbe Farbe**. Die Herkunft steht
/// im Label der Zeile, nicht am Punkt: Sonst wäre sie zweimal beschriftet.
class _SourceDot extends StatelessWidget {
  const _SourceDot({required this.source});

  final WeightSource source;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: source.isMeasured ? AtemColors.base : AtemColors.cyan,
            border: source.isMeasured
                ? Border.all(color: AtemColors.cyan, width: 2)
                : null,
          ),
        ),
      );
}
