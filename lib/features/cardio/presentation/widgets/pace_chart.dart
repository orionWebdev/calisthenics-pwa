import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/atem_entrance.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/presentation/session_ui.dart';
import '../../domain/pace_series.dart';
import '../cardio_ui.dart';

/// Tempoentwicklung einer Aktivität — **die Formkurve aus Modul 6, mit Tempo
/// statt Formwert** (Board 11, B3/2). 66 dp statt 62, Rug 4 dp, Punkte r 3,5.
///
/// Ein Punkt je Lauf, **gleichmässig verteilt**. Der Rug-Plot darunter zeigt,
/// wo die Läufe wirklich lagen — die Kurve behauptet keinen Rhythmus. Keine
/// Linie über eine Lücke, die es nicht gibt: Die x-Achse ist die Reihenfolge,
/// nicht die Zeit.
///
/// Schneller ist oben — auch bei min/km, wo die Zahl dann kleiner ist. Die
/// Achse trägt keine Zahlen; der Satz darüber (Schnitt, Verschiebung) und die
/// Semantics-Zusammenfassung tragen die Werte.
class PaceChart extends StatelessWidget {
  const PaceChart({super.key, required this.series});

  final PaceSeries series;

  static const height = 66.0;
  static const _rug = 4.0;
  static const _radius = 3.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final points = series.points;
    if (points.length < 2) return const SizedBox.shrink();

    final tag = languageTag(context);
    final fmt = DateFormat.MMMd(tag);
    String v(double x) =>
        formatTempoValue(context, x, usesSpeed: series.usesSpeed);

    return Semantics(
      image: true,
      label: '${l10n.analysisPaceTitle}. '
          '${fmt.format(points.first.date)}: ${v(points.first.value)}. '
          '${fmt.format(points.last.date)}: ${v(points.last.value)}. '
          '${l10n.analysisPaceRange(v(series.median!), v(series.slowest!), v(series.fastest!))}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height + _rug + 6,
              child: AtemSweep(
                child: CustomPaint(painter: _Painter(series: series)),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fmt.format(points.first.date).toUpperCase(),
                    style: AtemType.labelDeco.of(context)),
                Text(fmt.format(points.last.date).toUpperCase(),
                    style: AtemType.labelDeco.of(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter({required this.series});

  final PaceSeries series;

  @override
  void paint(Canvas canvas, Size size) {
    final points = series.points;
    if (points.length < 2 || size.width <= 0) return;

    const chartHeight = PaceChart.height;
    final values = points.map((p) => p.value).toList();
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (hi == lo) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.12;
    lo -= pad;
    hi += pad;

    // Schneller ist oben: bei min/km ist das der kleinere Wert.
    double y(double value) {
      final t = (value - lo) / (hi - lo);
      final up = series.lowerIsBetter ? 1 - t : t;
      return chartHeight - up * (chartHeight - 2 * PaceChart._radius) -
          PaceChart._radius;
    }

    double x(int i) =>
        PaceChart._radius +
        (size.width - 2 * PaceChart._radius) * i / (points.length - 1);

    // Achsenlinie und Median als leise Referenz.
    final axis = Paint()
      ..color = AtemColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
        const Offset(0, chartHeight), Offset(size.width, chartHeight), axis);
    final median = series.median;
    if (median != null) {
      final my = y(median);
      var dx = 0.0;
      while (dx < size.width) {
        canvas.drawLine(Offset(dx, my), Offset(dx + 4, my), axis);
        dx += 8;
      }
    }

    final line = Paint()
      ..color = AtemColors.cyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < points.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = AtemColors.cyan;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(x(i), y(values[i])), PaceChart._radius, dot);
    }

    // Rug-Plot: wo die Läufe wirklich lagen, auf der Zeitachse.
    final first = points.first.date;
    final span = points.last.date.difference(first).inDays;
    final rug = Paint()
      ..color = AtemColors.cyan.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const top = chartHeight + 4;
    for (final p in points) {
      final offset = p.date.difference(first).inDays;
      final rx = span <= 0
          ? size.width / 2
          : PaceChart._radius +
              (size.width - 2 * PaceChart._radius) * offset / span;
      canvas.drawLine(Offset(rx, top), Offset(rx, top + PaceChart._rug), rug);
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.series != series;
}
