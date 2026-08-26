import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_gradients.dart';
import '../theme/atem_type.dart';

/// Wie eine Datenreihe gezeichnet wird.
///
/// **Der Stil ist der Nicht-Farb-Träger.** Drei Reihen müssen auch ohne Farbe
/// unterscheidbar sein — vorher waren Load und Recovery beide durchgezogen und
/// unterschieden sich allein im Ton.
enum AtemSeriesStyle {
  /// Dicker Strich mit runden Punktmarkern. Die Primärreihe, einzige mit Glow.
  primary(strokeWidth: 2.4, marker: AtemSeriesMarker.dot, isDashed: false),

  /// Gestrichelt, ohne Marker.
  dashed(strokeWidth: 1.6, marker: AtemSeriesMarker.none, isDashed: true),

  /// Dünn durchgezogen, mit Winkelmarkern an jedem zweiten Punkt.
  angled(strokeWidth: 1.4, marker: AtemSeriesMarker.chevron, isDashed: false);

  const AtemSeriesStyle({
    required this.strokeWidth,
    required this.marker,
    required this.isDashed,
  });

  final double strokeWidth;
  final AtemSeriesMarker marker;
  final bool isDashed;
}

/// Das Formmerkmal einer Reihe. Zusammen mit Strichstärke und Strichelung
/// der eigentliche Nicht-Farb-Träger.
enum AtemSeriesMarker { none, dot, chevron }

/// Eine Datenreihe im Diagramm.
@immutable
class AtemChartSeries {
  const AtemChartSeries({
    required this.label,
    required this.values,
    required this.color,
    required this.style,
  });

  final String label;

  /// Werte 0..100, ein Eintrag je Achsenpunkt.
  final List<double> values;

  final Color color;
  final AtemSeriesStyle style;
}

/// Diagrammkarte mit fünf Zonen in fester Reihenfolge:
/// Kopfzeile, Legende, Zeichenfläche, Achse, Tooltip.
///
/// ## Alle Koordinaten leiten sich aus der Fläche ab
///
/// Der Vorgänger rechnete absolut für ein 358×152-Feld — also exakt ein
/// 390-dp-Gerät. Auf 320 dp war die Zeichenfläche nur rund 110 dp hoch, die
/// Achsenbeschriftung wurde aber bei y = 140 gemalt und weggeschnitten. Der
/// Painter warf dabei keine Exception, er malte ins Leere.
class AtemChartCard extends StatelessWidget {
  const AtemChartCard({
    super.key,
    required this.title,
    required this.series,
    required this.axisLabels,
    required this.semanticSummary,
    this.highlightIndex,
    this.tooltip,
    this.aspectRatio = 358 / 152,
  });

  final String title;
  final List<AtemChartSeries> series;

  /// Ein Kürzel je Datenpunkt, etwa MO bis SO.
  final List<String> axisLabels;

  /// Was ein Screenreader statt des Diagramms hört.
  final String semanticSummary;

  /// Der hervorgehobene Punkt — üblicherweise heute.
  final int? highlightIndex;

  /// Text der Sprechblase am hervorgehobenen Punkt. Informationstragend,
  /// deshalb [AtemType.labelSmall] und nicht die dekorative Größe.
  final String? tooltip;

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticSummary,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ① Kopfzeile und ② Legende
            //
            // Wrap statt Row: Bei 320 dp und großer Systemschrift passt die
            // Legende nicht mehr neben den Titel — sie rutscht dann eine Zeile
            // tiefer, statt die Karte zu sprengen. Der Vorgänger lief hier bei
            // Faktor 1,3 um 61 Pixel über.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.labelMicro.of(context),
                ),
                _Legend(series: series),
              ],
            ),
            const SizedBox(height: 10),
            // ③ Zeichenfläche, ④ Achse, ⑤ Tooltip
            AspectRatio(
              aspectRatio: aspectRatio,
              child: CustomPaint(
                painter: _ChartPainter(
                  series: series,
                  axisLabels: axisLabels,
                  highlightIndex: highlightIndex,
                  tooltip: tooltip,
                  axisStyle: AtemType.labelDeco.of(context),
                  axisHighlightStyle: AtemType.labelDeco.of(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AtemColors.textPrimary,
                      ),
                  tooltipStyle: AtemType.labelSmall.of(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legende aus Strich-Proben statt farbiger Punkte.
///
/// Farbpunkte binden die Legende ausschließlich über Farbe an die Reihen — bei
/// 10 sp und Farbenblindheit doppelt schwach. Die Proben machen das Muster
/// selbst zum Schlüssel.
class _Legend extends StatelessWidget {
  const _Legend({required this.series});
  final List<AtemChartSeries> series;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final s in series)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(14, 8),
                  painter: _SamplePainter(s),
                ),
                const SizedBox(width: 4),
                Text(s.label, style: AtemType.labelDeco.of(context)),
              ],
            ),
        ],
      );
}

class _SamplePainter extends CustomPainter {
  _SamplePainter(this.series);
  final AtemChartSeries series;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = series.style.strokeWidth
      ..color = series.color;

    final line = Path()
      ..moveTo(0, y)
      ..lineTo(size.width, y);
    canvas.drawPath(
      series.style.isDashed ? _dash(line, 3, 2.5) : line,
      paint,
    );

    switch (series.style.marker) {
      case AtemSeriesMarker.dot:
        canvas.drawCircle(
            Offset(size.width / 2, y), 2.5, Paint()..color = AtemColors.card);
        canvas.drawCircle(
          Offset(size.width / 2, y),
          2.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = series.color,
        );
      case AtemSeriesMarker.chevron:
        canvas.drawPath(
          Path()
            ..moveTo(size.width / 2 - 3, y)
            ..lineTo(size.width / 2, y - 3)
            ..lineTo(size.width / 2 + 3, y),
          paint..strokeWidth = 1.4,
        );
      case AtemSeriesMarker.none:
        break;
    }
  }

  @override
  bool shouldRepaint(_SamplePainter old) => old.series != series;
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.axisLabels,
    required this.highlightIndex,
    required this.tooltip,
    required this.axisStyle,
    required this.axisHighlightStyle,
    required this.tooltipStyle,
  });

  final List<AtemChartSeries> series;
  final List<String> axisLabels;
  final int? highlightIndex;
  final String? tooltip;
  final TextStyle axisStyle;
  final TextStyle axisHighlightStyle;
  final TextStyle tooltipStyle;

  // Zonen als Anteil der Höhe — nie absolut.
  static const _plotTop = 0.145;
  static const _plotBottom = 0.79;
  static const _axisBaseline = 0.92;
  static const _gridFractions = [0.25, 0.5, 0.75];

  double _y(Size size, double value) {
    final top = size.height * _plotTop;
    final bottom = size.height * _plotBottom;
    return top + (1 - value.clamp(0.0, 100.0) / 100) * (bottom - top);
  }

  double _padX(Size size) {
    // Aus der breitesten Achsenbeschriftung ableiten, nicht raten.
    var widest = 0.0;
    for (final label in axisLabels) {
      final tp = TextPainter(
        text: TextSpan(text: label, style: axisStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      widest = math.max(widest, tp.width);
    }
    return math.min(widest / 2 + 4, size.width / 4);
  }

  double _x(Size size, int i, double pad) {
    if (axisLabels.length < 2) return size.width / 2;
    return pad + i * (size.width - pad * 2) / (axisLabels.length - 1);
  }

  /// Catmull-Rom in Bézier, damit die Kurve weich läuft.
  Path _spline(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[0] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || series.isEmpty) return;
    final pad = _padX(size);

    // ③ Gridlines
    final top = size.height * _plotTop;
    final bottom = size.height * _plotBottom;
    final grid = Paint()
      ..color = AtemColors.gridLine
      ..strokeWidth = 1;
    for (final f in _gridFractions) {
      final y = top + (bottom - top) * f;
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), grid);
    }

    // Reihen: Primärreihe zuletzt, damit sie oben liegt.
    final ordered = [...series]..sort((a, b) =>
        (a.style == AtemSeriesStyle.primary ? 1 : 0) -
        (b.style == AtemSeriesStyle.primary ? 1 : 0));

    for (final s in ordered) {
      final pts = [
        for (var i = 0; i < s.values.length; i++)
          Offset(_x(size, i, pad), _y(size, s.values[i]))
      ];
      if (pts.length < 2) continue;
      _paintSeries(canvas, size, s, pts);
    }

    _paintAxis(canvas, size, pad);
    _paintHighlight(canvas, size, pad);
  }

  void _paintSeries(
      Canvas canvas, Size size, AtemChartSeries s, List<Offset> pts) {
    final path = _spline(pts);
    final isPrimary = s.style == AtemSeriesStyle.primary;

    if (isPrimary) {
      // Flächenfüllung nur unter der Primärreihe.
      final area = Path.from(path)
        ..lineTo(pts.last.dx, size.height * _plotBottom)
        ..lineTo(pts.first.dx, size.height * _plotBottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = AtemGradients.chartArea.createShader(Offset.zero & size),
      );

      // Genau eine Glow-Kopie — dieselbe Budget-Regel wie beim Fortschritt.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.style.strokeWidth * 2
          ..color = s.color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    canvas.drawPath(
      s.style.isDashed ? _dash(path, 4, 4) : path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.style.strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = s.color.withValues(alpha: isPrimary ? 1.0 : 0.8),
    );

    // Marker — der eigentliche Nicht-Farb-Träger.
    for (var i = 0; i < pts.length; i++) {
      if (i == highlightIndex && isPrimary) continue;
      switch (s.style.marker) {
        case AtemSeriesMarker.dot:
          canvas.drawCircle(
              pts[i], 3, Paint()..color = AtemColors.surfaceSolid);
          canvas.drawCircle(
            pts[i],
            3,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8
              ..color = s.color,
          );
        case AtemSeriesMarker.chevron:
          if (i.isOdd) continue; // jeder zweite Punkt
          canvas.drawPath(
            Path()
              ..moveTo(pts[i].dx - 4, pts[i].dy)
              ..lineTo(pts[i].dx, pts[i].dy - 4)
              ..lineTo(pts[i].dx + 4, pts[i].dy),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..strokeCap = StrokeCap.round
              ..color = s.color.withValues(alpha: 0.8),
          );
        case AtemSeriesMarker.none:
          break;
      }
    }
  }

  void _paintAxis(Canvas canvas, Size size, double pad) {
    final baseline = size.height * _axisBaseline;
    for (var i = 0; i < axisLabels.length; i++) {
      final isHighlight = i == highlightIndex;
      final tp = TextPainter(
        text: TextSpan(
          text: axisLabels[i],
          style: isHighlight ? axisHighlightStyle : axisStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final center = Offset(_x(size, i, pad), baseline);
      if (isHighlight) {
        // Umriss-Pille statt bloßer Weißfärbung — Form, nicht nur Farbe.
        final box = Rect.fromCenter(
          center: center,
          width: tp.width + 12,
          height: tp.height + 5,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, Radius.circular(box.height / 2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = AtemColors.magenta.withValues(alpha: 0.6),
        );
      }
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _paintHighlight(Canvas canvas, Size size, double pad) {
    final i = highlightIndex;
    if (i == null || i < 0) return;
    final primary = series.firstWhere(
      (s) => s.style == AtemSeriesStyle.primary,
      orElse: () => series.first,
    );
    if (i >= primary.values.length) return;

    final p = Offset(_x(size, i, pad), _y(size, primary.values[i]));

    canvas.drawPath(
      _dash(
        Path()
          ..moveTo(p.dx, size.height * _plotTop * 0.7)
          ..lineTo(p.dx, size.height * _plotBottom),
        3,
        4,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AtemColors.magenta.withValues(alpha: 0.6),
    );

    canvas.drawCircle(
        p, 6.5, Paint()..color = AtemColors.magenta.withValues(alpha: 0.25));
    canvas.drawCircle(p, 3.5, Paint()..color = AtemColors.textPrimary);
    canvas.drawCircle(
      p,
      3.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AtemColors.magenta,
    );

    final text = tooltip;
    if (text == null) return;

    final tp = TextPainter(
      text: TextSpan(text: text, style: tooltipStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - pad * 2);

    // Innerhalb der Fläche halten: an den Rändern würde eine zentrierte
    // Sprechblase hinausragen.
    final boxW = tp.width + 16;
    final cx = p.dx
        .clamp(boxW / 2 + 2, math.max(boxW / 2 + 2, size.width - boxW / 2 - 2))
        .toDouble();
    final box = Rect.fromCenter(
      center: Offset(cx, p.dy - tp.height - 14),
      width: boxW,
      height: tp.height + 10,
    );
    final rr = RRect.fromRectAndRadius(box, const Radius.circular(8));
    canvas.drawRRect(rr, Paint()..color = AtemColors.surfaceRaised);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AtemColors.magenta.withValues(alpha: 0.45),
    );
    tp.paint(canvas, Offset(box.left + 8, box.top + 5));
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.series != series ||
      old.highlightIndex != highlightIndex ||
      old.tooltip != tooltip;
}

/// Zerlegt einen Pfad in Striche — Flutter kennt kein dash-array.
Path _dash(Path source, double on, double off) {
  final out = Path();
  for (final metric in source.computeMetrics()) {
    var d = 0.0;
    while (d < metric.length) {
      out.addPath(
          metric.extractPath(d, math.min(d + on, metric.length)), Offset.zero);
      d += on + off;
    }
  }
  return out;
}
