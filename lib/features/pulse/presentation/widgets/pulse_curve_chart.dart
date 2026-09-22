import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';

/// Der Pulsverlauf einer Einheit — bpm über die Zeit, echte Lücken als
/// Lücken (Board 16, offene Frage 1, gelöst am 22.09.2026).
///
/// ## Warum ein eigener Baustein statt `AtemChartCard`
///
/// `AtemChartCard` setzt einen Achsenpunkt je Wert und beschriftet jeden
/// einzelnen — bei fünf bis acht Wochenwerten lesbar, bei vierzig bis
/// neunzig Minutenwerten nicht mehr: Die Beschriftung fiele bei 200 % auf
/// 320 dp übereinander. Die Achse hier braucht deshalb Zeit statt Index:
/// Jeder Punkt steht an seiner tatsächlichen Minute, eine fehlende Minute
/// ist eine echte Lücke in der Linie — dieselbe Form wie beim Gewichtsverlauf
/// (Modul 9), nur mit Minuten statt Tagen als Abstand.
///
/// ## Bewegung
///
/// Die Linie zeichnet sich einmal von links nach rechts, 420 ms,
/// `easeOutQuart` — dieselbe Dauer wie die Zonenspuren im selben Block
/// (`ZoneTrack`). Bei reduzierter Bewegung steht sie sofort fertig da.
///
/// ## Was hier nicht steht
///
/// Keine Lückennotiz, kein zweiter Hinweissatz: Der Block trägt bereits die
/// Grundlage („268 Sätze · 14 von 18 …") als einzige sichtbare Hinweiszeile
/// (CLAUDE.md). Eine Lücke in der Kurve erklärt sich selbst — visuell für
/// sehende Nutzer, im Semantics-Label für alle anderen.
class PulseCurveChart extends StatelessWidget {
  const PulseCurveChart({
    super.key,
    required this.bpmByMinute,
    required this.totalMinutes,
    required this.semanticLabel,
    this.height = 96,
  });

  /// bpm je Minute seit Beginn der Einheit — nur Minuten mit Messung.
  final Map<int, int> bpmByMinute;

  /// Die Länge der Einheit in Minuten — bestimmt die Breite der Zeitachse,
  /// nicht nur die Zahl der Messpunkte. So bleibt eine Lücke am Anfang oder
  /// Ende sichtbar, nicht nur eine mittendrin.
  final int totalMinutes;

  /// „Pulsverlauf, von 96 bis 172 bpm über 52 Minuten" — **ein** Knoten, wie
  /// jede Datenzeile in dieser App (CLAUDE.md, Barrierefreiheit).
  final String semanticLabel;

  final double height;

  /// Unter zwei Minutenwerten zeichnet das Widget nichts — aus einem Punkt
  /// folgt keine Linie, und der Block rendert dann ohne diesen Teil weiter
  /// („ein Block ohne Daten rendert nicht", CLAUDE.md).
  bool get hasCurve => bpmByMinute.length >= 2 && totalMinutes > 0;

  @override
  Widget build(BuildContext context) {
    if (!hasCurve) return const SizedBox.shrink();

    return Semantics(
      container: true,
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: 1.0),
          duration: AtemMotion.reduced(context)
              ? Duration.zero
              : const Duration(milliseconds: 420),
          curve: Curves.easeOutQuart,
          builder: (context, progress, _) => CustomPaint(
            painter: _PulseCurvePainter(
              bpmByMinute: bpmByMinute,
              totalMinutes: totalMinutes,
              progress: progress,
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseCurvePainter extends CustomPainter {
  _PulseCurvePainter({
    required this.bpmByMinute,
    required this.totalMinutes,
    required this.progress,
  });

  final Map<int, int> bpmByMinute;
  final int totalMinutes;
  final double progress;

  static const _sidePad = 4.0;
  static const _topPad = 6.0;
  static const _bottomPad = 6.0;

  /// Unter 3 bpm Spanne wird mittig eine flache Linie gezeichnet statt sie
  /// auf volle Höhe zu spreizen — dieselbe Regel wie beim Gewichtsverlauf:
  /// Eine Skala, die kaum Unterschied über die volle Höhe verteilt, wäre
  /// eine Behauptung.
  static const _flatThreshold = 3;

  List<List<int>> _segments(List<int> sortedMinutes) {
    final segments = <List<int>>[];
    List<int>? current;
    for (final m in sortedMinutes) {
      if (current != null && m == current.last + 1) {
        current.add(m);
      } else {
        current = [m];
        segments.add(current);
      }
    }
    return segments;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || bpmByMinute.length < 2) return;

    final minutes = bpmByMinute.keys.toList()..sort();
    final values = bpmByMinute.values;
    final minBpm = values.reduce((a, b) => a < b ? a : b);
    final maxBpm = values.reduce((a, b) => a > b ? a : b);
    final range = (maxBpm - minBpm) < _flatThreshold ? null : (maxBpm - minBpm);

    const left = _sidePad;
    final right = size.width - _sidePad;
    const top = _topPad;
    final bottom = size.height - _bottomPad;
    final span = totalMinutes <= 1 ? 1 : totalMinutes - 1;

    Offset pointFor(int minute, int bpm) {
      final x = left + (right - left) * (minute / span).clamp(0.0, 1.0);
      final y = range == null
          ? (top + bottom) / 2
          : bottom - (bottom - top) * ((bpm - minBpm) / range);
      return Offset(x, y);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final line = Paint()
      ..color = AtemColors.violetLight
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final segment in _segments(minutes)) {
      if (segment.length < 2) continue;
      final path = Path()
        ..moveTo(pointFor(segment.first, bpmByMinute[segment.first]!).dx,
            pointFor(segment.first, bpmByMinute[segment.first]!).dy);
      for (final m in segment.skip(1)) {
        final p = pointFor(m, bpmByMinute[m]!);
        path.lineTo(p.dx, p.dy);
      }

      // Fläche nur unter der Linie, dieselbe Farbfolge wie AtemChartCard —
      // ein Rezept für „Wert über Zeit" statt eines zweiten.
      final area = Path.from(path)
        ..lineTo(pointFor(segment.last, bpmByMinute[segment.last]!).dx, bottom)
        ..lineTo(
            pointFor(segment.first, bpmByMinute[segment.first]!).dx, bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = AtemGradients.chartArea.createShader(Offset.zero & size),
      );

      canvas.drawPath(path, line);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PulseCurvePainter old) =>
      old.bpmByMinute != bpmByMinute ||
      old.totalMinutes != totalMinutes ||
      old.progress != progress;
}
