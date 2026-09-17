import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/presentation/session_ui.dart';
import '../../domain/time_split.dart';
import '../../domain/training_heatmap.dart';
import 'track_ui.dart';

/// Trainingstage der letzten zwölf Wochen als Kachelraster — **Konsistenz
/// zeigen, ohne Pausen zu bestrafen** (Masterplan, Phase 1).
///
/// Zwölf Spalten (Wochen, die älteste links), sieben Zeilen (Montag oben).
/// Eine Kachel trägt die Spur des Tages als Farbe; ein Tag mit mehreren
/// Spuren den Hybrid-Ton, ein Tag ohne Training die Spurfarbe `track`, ein
/// Tag in der Zukunft nur einen Rand. Darunter steht die Zählung: „34 von 84
/// Tagen trainiert", aufgeschlüsselt je Spur. Kein Streak, kein Ziel, kein
/// Abzug — die App weiss nicht, wie viele Tage richtig sind.
///
/// ## Vorlesen
///
/// Eine Woche ist **ein** Semantics-Knoten: „KW 36: 3 Trainingstage. Mo
/// Kraft, Mi Ausdauer, Sa mehrere Arten". 84 einzelne Kacheln wären 84
/// Stopps, von denen 50 „kein Training" sagen. Die Kacheln selbst sind
/// stumm; Farbe ist nie der einzige Träger, das Wort steht im Label und in
/// der Legende.
///
/// ## Bewegung
///
/// Die Spalten erscheinen von links nach rechts mit 20 ms Versatz — in der
/// Richtung, in der die Zeit läuft. Ruhelage ist das vollständige Raster;
/// bei „Animationen reduzieren" steht es sofort.
class TrainingHeatmapCard extends StatelessWidget {
  const TrainingHeatmapCard({super.key, required this.heatmap});

  final TrainingHeatmap heatmap;

  static const minCell = 14.0;
  static const gap = 3.0;
  static const _radius = 3.0;
  static const _columnDelay = Duration(milliseconds: 20);

  @override
  Widget build(BuildContext context) {
    // Ohne einen einzigen Trainingstag im Fenster gibt es nichts zu zählen.
    if (heatmap.trainedDays == 0) return const SizedBox.shrink();
    final l10n = AppL10n.of(context);

    return AtemCard.list(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Was das Raster zeigt und die Aufteilung je Spur stehen hinter
          // dem ⓘ (seit 17.09.2026); sichtbar bleiben Raster, Legende und die
          // Zählung mit Nenner.
          AtemExplainHeader(
            title: l10n.hybridHeatmapTitle,
            trailing: l10n.hybridHeatmapWindow(heatmap.weekCount),
            explanation: [
              l10n.hybridHeatmapExplain,
              l10n.hybridHeatmapByTrack(
                heatmap.trainedDaysOf(TrainingTrack.strength),
                heatmap.trainedDaysOf(TrainingTrack.cardio),
                heatmap.trainedDaysOf(TrainingTrack.recovery),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Grid(heatmap: heatmap),
          const SizedBox(height: 12),
          const _Legend(),
          const SizedBox(height: 12),
          // Die Hauptzahl des Blocks im Hybrid-Ton, der Nenner daneben in
          // der dritten Textstufe. Ein Knoten: „34 von 84 Tagen trainiert".
          Semantics(
            label:
                l10n.hybridHeatmapBasis(heatmap.trainedDays, heatmap.totalDays),
            child: ExcludeSemantics(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  Text(
                    '${heatmap.trainedDays}',
                    style: AtemType.valueMedium
                        .of(context)
                        .copyWith(color: AtemColors.tabHybrid),
                  ),
                  Text(
                    l10n.hybridHeatmapOfDays(heatmap.totalDays),
                    style: AtemType.meta.of(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Farbe einer Kachel. Zukunft hat keine Fläche, nur einen Rand.
  static Color? cellColor(HeatmapDay day) {
    if (day.isFuture) return null;
    if (day.tracks.isEmpty) return AtemColors.track;
    if (day.tracks.length > 1) return AtemColors.tabHybrid;
    return trackColor(day.tracks.single);
  }
}

/// Das Raster: links die Tageskürzel, dann eine Spalte je Woche.
///
/// Die Kachelgrösse kommt aus der Breite, nie unter [TrainingHeatmapCard.minCell].
/// Reicht die Breite selbst dafür nicht — 200 % Schrift auf 320 dp mit breiten
/// Kürzeln —, scrollt das Raster seitlich, statt überzulaufen.
class _Grid extends StatelessWidget {
  const _Grid({required this.heatmap});

  final TrainingHeatmap heatmap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final labelStyle = AtemType.labelMicro.of(context);
    // Breite der Kürzelspalte gemessen, nicht geraten: „Mo" wächst mit.
    final labelWidth = _widestLabel(context, labelStyle) + 6;
    const gap = TrainingHeatmapCard.gap;
    final weeks = heatmap.weeks;

    return LayoutBuilder(
      builder: (context, constraints) {
        final free = constraints.maxWidth - labelWidth - gap * weeks.length;
        final cell = math.max(
            TrainingHeatmapCard.minCell, (free / weeks.length).floorToDouble());
        final gridWidth = labelWidth + weeks.length * (cell + gap);

        final labels = ExcludeSemantics(
          child: SizedBox(
            width: labelWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var d = 0; d < 7; d++)
                  SizedBox(
                    height: cell + (d < 6 ? gap : 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: d.isEven && d < 6
                          ? Text(
                              _weekdayShort(tag, d),
                              maxLines: 1,
                              style: labelStyle,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        );

        final columns = [
          for (final (i, week) in weeks.indexed)
            _WeekColumn(
              week: week,
              cell: cell,
              index: i,
              label: _weekLabel(l10n, tag, week),
            ),
        ];

        final grid = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labels,
            for (final (i, c) in columns.indexed) ...[
              if (i > 0) const SizedBox(width: gap),
              c,
            ],
          ],
        );

        if (gridWidth <= constraints.maxWidth) return grid;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: gridWidth, child: grid),
        );
      },
    );
  }

  /// Mo, Mi, Fr — jede zweite Zeile, damit die Spalte bei grosser Schrift
  /// nicht dichter steht als die Kacheln.
  static String _weekdayShort(String tag, int dayIndex) {
    final monday = DateTime(2026, 9, 14); // ein Montag
    final day = DateTime(monday.year, monday.month, monday.day + dayIndex);
    return DateFormat.E(tag).format(day);
  }

  static double _widestLabel(BuildContext context, TextStyle style) {
    final tag = languageTag(context);
    var widest = 0.0;
    for (final d in [0, 2, 4]) {
      final painter = TextPainter(
        text: TextSpan(text: _weekdayShort(tag, d), style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
    }
    return widest;
  }

  /// „KW 36: 3 Trainingstage. Mo Kraft, Mi Ausdauer, Sa mehrere Arten".
  static String _weekLabel(AppL10n l10n, String tag, HeatmapWeek week) {
    final trained = week.days.where((d) => d.trained).toList();
    if (trained.isEmpty) return l10n.hybridHeatmapWeekNoneA11y(week.isoWeek);
    final parts = [
      for (final day in trained)
        day.tracks.length > 1
            ? l10n.hybridHeatmapMixed(DateFormat.E(tag).format(day.date))
            : '${DateFormat.E(tag).format(day.date)} ${trackName(l10n, day.tracks.single)}',
    ];
    return l10n.hybridHeatmapWeekA11y(
        week.isoWeek, trained.length, parts.join(', '));
  }
}

/// Eine Woche: sieben Kacheln, ein Semantics-Knoten, ein Eintritt.
class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.week,
    required this.cell,
    required this.index,
    required this.label,
  });

  final HeatmapWeek week;
  final double cell;
  final int index;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: ExcludeSemantics(
          child: AtemReveal(
            duration: AtemMotion.slow,
            delay: TrainingHeatmapCard._columnDelay * index,
            builder: (context, t) => Opacity(
              opacity: t,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (d, day) in week.days.indexed) ...[
                    if (d > 0) const SizedBox(height: TrainingHeatmapCard.gap),
                    _Cell(day: day, size: cell),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.day, required this.size});

  final HeatmapDay day;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = TrainingHeatmapCard.cellColor(day);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        border: color == null ? Border.all(color: AtemColors.border) : null,
        borderRadius: BorderRadius.circular(TrainingHeatmapCard._radius),
      ),
    );
  }
}

/// Punkt und Wort je Farbe — das Wort ist der Träger, der Punkt zeigt nur.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final items = <(Color, String)>[
      (AtemColors.cyan, l10n.typeStrength),
      (AtemColors.violet, l10n.typeCardio),
      (AtemColors.green, l10n.recoveryTitle),
      (AtemColors.tabHybrid, l10n.hybridHeatmapLegendMixed),
      (AtemColors.track, l10n.hybridHeatmapLegendNone),
    ];
    return Semantics(
      label: items.map((e) => e.$2).join(', '),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final (color, word) in items)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AtemStatusDot(color: color),
                  const SizedBox(width: 6),
                  // Flexible: „Regeneration" bei 200 % auf 320 dp bricht um,
                  // statt die Zeile zu sprengen.
                  Flexible(
                    child: Text(word, style: AtemType.meta.of(context)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
