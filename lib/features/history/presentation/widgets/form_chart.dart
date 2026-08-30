import 'dart:math' as math;

import 'package:flutter/widgets.dart';
// `intl` exportiert eine eigene TextDirection und verdeckt damit die von
// Flutter, die der TextPainter erwartet.
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/atem_entrance.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/form_series.dart';
import '../session_ui.dart';

/// Die Formkurve über die Zeit.
///
/// ## Sechs Regeln aus der Spezifikation, alle mit Grund
///
/// **Feste Skala 0–100, kein Autoscaling.** Sonst sähe ein Absturz von 80 auf
/// 16 aus wie eine Delle.
///
/// **Die Lücke wird nicht interpoliert.** Die Form wird täglich gerechnet, auch
/// ohne Training — der Verlauf nach der letzten Einheit ist echt, aber
/// trainingsfrei. Die Linie wechselt dort auf gestrichelt und der Bereich
/// bekommt eine schwache Fläche: **zwei Träger, nicht nur Farbe** (Vertrag R6).
///
/// **Vier Achsenbeschriftungen, bei großer Schrift zwei.** Auf 320 dp
/// kollidieren mehr. Die Kurve behält ihre Breite, die Beschriftung wird
/// ausgedünnt — **nie gedreht**.
///
/// **Einheiten je Woche als Streifen unter der Achse.** Ein zweiter Datensatz
/// ohne zweite Y-Achse: Man sieht, dass die Kurve steigt, weil die Striche
/// dichter werden. Ursache und Wirkung in einem Bild.
///
/// **Kein Verlaufs-Fill, kein Blur.** Eine Fläche über 180 Punkte plus
/// BackdropFilter im Scrollbereich ist genau der Bildraten-Killer, den die
/// Randbedingung ausschließt.
///
/// **Kein Tooltip, ein Schieber.** Wischen setzt einen Cursor; Wert und Datum
/// erscheinen in der Kopfzeile, wo Platz garantiert ist, statt in einer Blase
/// unter dem Finger.
class FormChart extends StatefulWidget {
  const FormChart({super.key, required this.series});

  final FormSeries series;

  @override
  State<FormChart> createState() => _FormChartState();
}

class _FormChartState extends State<FormChart> {
  int? _cursor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final points = widget.series.points;
    if (points.isEmpty) return const SizedBox.shrink();

    final index = _cursor?.clamp(0, points.length - 1) ?? points.length - 1;
    final point = points[index];

    return Semantics(
      label: _summary(l10n, context),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kopfzeile: hier landet der Wert unter dem Finger.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    l10n.analysisChartLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.labelMicro.of(context),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '${point.value.round()} · '
                    '${DateFormat.MMMd(languageTag(context)).format(point.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AtemType.valueMedium.of(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                // Beschriftungen ausdünnen statt drehen.
                final labels =
                    MediaQuery.textScalerOf(context).scale(10) > 14 ? 2 : 4;

                // Ein Schieber ist kein Tap-Ziel: Es gibt nichts anzutippen,
                // nur eine Fläche zum Wischen. AtemTappable wäre hier das
                // falsche Werkzeug — es verlangt ein Label für eine Handlung,
                // die keine ist. Die Kurve selbst trägt ihre Ansage weiter
                // oben, als Satz statt als Linie.
                // atem:geste-erlaubt
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) => _scrub(
                      details.localPosition.dx,
                      constraints.maxWidth,
                      points.length),
                  onTapDown: (details) => _scrub(details.localPosition.dx,
                      constraints.maxWidth, points.length),
                  onHorizontalDragEnd: (_) => setState(() => _cursor = null),
                  child: SizedBox(
                    height: 168,
                    width: double.infinity,
                    // Die Kurve zeichnet sich in Richtung der Zeitachse.
                    child: AtemSweep(
                      child: CustomPaint(
                        painter: _ChartPainter(
                          series: widget.series,
                          cursor: _cursor == null ? null : index,
                          labelCount: labels,
                          labelFor: (date) =>
                              DateFormat.MMM(languageTag(context))
                                  .format(date)
                                  .toUpperCase(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _Legend(l10n: l10n, series: widget.series),
          ],
        ),
      ),
    );
  }

  void _scrub(double dx, double width, int count) {
    final fraction = (dx / width).clamp(0.0, 1.0);
    setState(() => _cursor = (fraction * (count - 1)).round());
  }

  /// Die Kurve als Satz — ein Screenreader kann keine Linie lesen.
  String _summary(AppL10n l10n, BuildContext context) {
    final points = widget.series.points;
    final first = points.first;
    final last = points.last;
    final peak = points.reduce((a, b) => a.value >= b.value ? a : b);
    final tag = languageTag(context);
    final fmt = DateFormat.MMMd(tag);

    return '${l10n.analysisChartLabel}. '
        '${fmt.format(first.date)}: ${first.value.round()}. '
        '${l10n.analysisToday}: ${last.value.round()}. '
        'Peak ${peak.value.round()} ${fmt.format(peak.date)}.';
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.l10n, required this.series});

  final AppL10n l10n;
  final FormSeries series;

  @override
  // Eine Reihe, die erst umbricht, wenn nichts mehr passt. Der Abstand ist
  // knapp gewählt, damit „mit" und „ohne Training" auf 360 dp nebeneinander
  // stehen bleiben.
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          _Item(color: AtemColors.cyan, label: l10n.analysisLegendWith),
          _Item(
            color: AtemColors.magenta,
            label: l10n.analysisLegendWithout,
            dashed: true,
          ),
          // Die Striche am unteren Rand standen bisher unbenannt da. Eine
          // Grafik, die etwas zeigt und nicht sagt was, ist ein Rätsel — und
          // die Balken sind genau die Erklärung dafür, warum die Kurve fällt.
          //
          // Der Eintrag erscheint nur, wenn auch Striche gezeichnet werden;
          // eine Legende zu einer leeren Fläche wäre eine Zeile über nichts.
          if (series.weeks.any((w) => w.count > 0))
            _Item(
              color: AtemColors.cyan.withValues(alpha: 0.55),
              label: l10n.analysisLegendRug,
              bars: true,
            ),
        ],
      );
}

class _Item extends StatelessWidget {
  const _Item({
    required this.color,
    required this.label,
    this.dashed = false,
    this.bars = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  /// Statt einer Linie drei stehende Striche — die Form des Rug-Plots.
  final bool bars;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        // Ein Wrap bricht zwischen seinen Kindern um, nicht innerhalb eines
        // Kindes. Ohne Obergrenze läuft ein einzelner Eintrag bei 200 % Schrift
        // über den Rand, statt umzubrechen.
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 80),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: bars ? const Size(16, 10) : const Size(16, 2),
              painter: bars
                  ? _BarSample(color: color)
                  : _LineSample(color: color, dashed: dashed),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.labelMicro.of(context),
              ),
            ),
          ],
        ),
      );
}

/// Drei stehende Striche in wechselnder Höhe — dieselbe Form wie im Chart.
class _BarSample extends CustomPainter {
  _BarSample({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const fractions = [0.5, 1.0, 0.7];
    for (var i = 0; i < fractions.length; i++) {
      final x = 1 + i * (size.width - 2) / (fractions.length - 1);
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height * (1 - fractions[i])),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarSample old) => old.color != color;
}

class _LineSample extends CustomPainter {
  _LineSample({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (!dashed) {
      canvas.drawLine(Offset(0, size.height / 2),
          Offset(size.width, size.height / 2), paint);
      return;
    }
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(math.min(x + 4, size.width), size.height / 2), paint);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(_LineSample old) =>
      old.color != color || old.dashed != dashed;
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.cursor,
    required this.labelCount,
    required this.labelFor,
  });

  final FormSeries series;
  final int? cursor;
  final int labelCount;
  final String Function(DateTime) labelFor;

  /// Anteile statt fester Koordinaten — der Chart im Dashboard hatte genau
  /// diesen Fehler und wurde auf 320 dp abgeschnitten.
  static const _plotTop = 0.04;
  static const _plotBottom = 0.68;
  static const _rugTop = 0.74;
  static const _rugBottom = 0.86;

  @override
  void paint(Canvas canvas, Size size) {
    final points = series.points;
    if (points.isEmpty) return;

    final top = size.height * _plotTop;
    final bottom = size.height * _plotBottom;

    double x(int i) =>
        points.length == 1 ? 0 : i / (points.length - 1) * size.width;
    double y(double value) => bottom - (value / 100) * (bottom - top);

    // Feste Skala: 0, 50, 100.
    final grid = Paint()..strokeWidth = 1;
    for (final value in [100.0, 50.0]) {
      grid.color = AtemColors.track;
      canvas.drawLine(Offset(0, y(value)), Offset(size.width, y(value)), grid);
    }
    grid.color = AtemColors.border;
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), grid);

    // Die Kurve, in Abschnitte zerlegt: durchgezogen mit Training, gestrichelt
    // ohne. Der Wechsel folgt den Daten, nicht einem festen Datum.
    _drawSegments(canvas, size, points, x, y);

    // Der Streifen unter der Achse.
    _drawRug(canvas, size, points, x);

    // Achsenbeschriftung.
    _drawLabels(canvas, size, points, x);

    if (cursor case final index?) {
      final cx = x(index);
      canvas.drawLine(
        Offset(cx, top),
        Offset(cx, bottom),
        Paint()
          ..color = AtemColors.textSecondary
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        Offset(cx, y(points[index].value)),
        4,
        Paint()..color = AtemColors.textPrimary,
      );
    }
  }

  void _drawSegments(
    Canvas canvas,
    Size size,
    List<FormPoint> points,
    double Function(int) x,
    double Function(double) y,
  ) {
    final solid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AtemColors.cyan;

    final dashed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AtemColors.magenta;

    // Ein Tag gilt als trainingsfrei, wenn weder er noch der Vortag Training
    // trug — sonst flackerte die Linie zwischen den Stilen.
    bool gapAt(int i) =>
        !points[i].hasTraining && (i == 0 || !points[i - 1].hasTraining);

    // Die Fläche unter den trainingsfreien Abschnitten: der zweite Träger.
    final fill = Paint()
      ..color = AtemColors.textPrimary.withValues(alpha: 0.03);
    var runStart = -1;
    for (var i = 0; i < points.length; i++) {
      final isGap = gapAt(i);
      if (isGap && runStart < 0) runStart = i;
      if ((!isGap || i == points.length - 1) && runStart >= 0) {
        final end = isGap ? i : i - 1;
        canvas.drawRect(
          Rect.fromLTRB(x(runStart), y(100), x(end), y(0)),
          fill,
        );
        runStart = -1;
      }
    }

    for (var i = 1; i < points.length; i++) {
      final from = Offset(x(i - 1), y(points[i - 1].value));
      final to = Offset(x(i), y(points[i].value));
      if (gapAt(i)) {
        _dashedLine(canvas, from, to, dashed);
      } else {
        canvas.drawLine(from, to, solid);
      }
    }
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final distance = (to - from).distance;
    if (distance == 0) return;
    final step = (to - from) / distance;
    var travelled = 0.0;
    while (travelled < distance) {
      final next = math.min(travelled + 3, distance);
      canvas.drawLine(
        from + step * travelled,
        from + step * next,
        paint,
      );
      travelled = next + 3;
    }
  }

  void _drawRug(
    Canvas canvas,
    Size size,
    List<FormPoint> points,
    double Function(int) x,
  ) {
    if (series.weeks.isEmpty || series.maxPerWeek <= 0) return;
    final top = size.height * _rugTop;
    final bottom = size.height * _rugBottom;
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final firstDay = points.first.date;
    final span = points.last.date.difference(firstDay).inDays;
    if (span <= 0) return;

    for (final week in series.weeks) {
      if (week.count == 0) continue;
      final offset = week.weekStart.difference(firstDay).inDays;
      if (offset < 0 || offset > span) continue;
      final cx = offset / span * size.width;
      final fraction = week.count / series.maxPerWeek;
      paint.color = AtemColors.cyan.withValues(alpha: 0.55);
      canvas.drawLine(
        Offset(cx, bottom),
        Offset(cx, bottom - fraction * (bottom - top)),
        paint,
      );
    }
  }

  void _drawLabels(
    Canvas canvas,
    Size size,
    List<FormPoint> points,
    double Function(int) x,
  ) {
    if (labelCount < 2) return;
    final style =
        AtemType.labelDeco.base.copyWith(color: AtemColors.textSecondary);

    for (var n = 0; n < labelCount; n++) {
      final index = (n / (labelCount - 1) * (points.length - 1)).round();
      final painter = TextPainter(
        text: TextSpan(text: labelFor(points[index].date), style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      final cx = (x(index) - painter.width / 2)
          .clamp(0.0, math.max(0.0, size.width - painter.width))
          .toDouble();
      painter.paint(canvas, Offset(cx, size.height - painter.height));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.series != series ||
      old.cursor != cursor ||
      old.labelCount != labelCount;
}
