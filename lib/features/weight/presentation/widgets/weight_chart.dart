import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/weight_entry.dart';
import '../../domain/weight_series.dart';

/// Die Gewichtskurve — **Zeit auf der Waagerechten, Lücken als Lücken**.
///
/// ## Warum nicht [AtemChartCard]
///
/// Die Formkurve aus Modul 9 setzt gleichmässig verteilte Stützstellen: Ihre
/// Werte stehen für Wochen, und jede Woche ist gleich breit. Hier steht jeder
/// Punkt für einen **Tag**, und die Abstände sind die Aussage. Zwei Einträge
/// im Abstand von zwei Tagen und zwei im Abstand von zwei Monaten dürfen nicht
/// gleich aussehen — sonst behauptet die Kurve einen Rhythmus, den es nicht
/// gab. Das Rezept (Grundlinie, Punkte, Von-Bis-Label) ist dasselbe, die
/// Achsenteilung nicht.
///
/// ## Drei Formen, keine zweite Farbe
///
/// Gefüllter Punkt: eigene Eingabe. Hohler Punkt: gemessen. Unterbrochene
/// Linie: Lücke. Alles drei sind **Formen** — ein zweites Farbwort neben Cyan
/// gäbe es hier nicht zu lernen (Board 14, Entscheidung 6).
///
/// ## Warum die Lückennotiz nicht hier steht
///
/// Das Board setzt sie mit 7 sp in `#4b5563` mitten in die Lücke. Beides
/// verbietet CLAUDE.md für informationstragenden Text (≥ 12 sp, `#94A3B8` als
/// dunkelste Farbe), und der Konventionsprüfer fängt die Schriftgrösse
/// ohnehin ab. In zulässiger Grösse passt der Satz in eine 56 dp hohe Kurve
/// fast nie hinein — am Render vom 20.09.2026 blieb er in jeder realistischen
/// Lage weg. Die Notiz steht deshalb als **eine** Zeile unter der Kurve
/// (`WeightGapNote`); hier bleibt der Bruch in der Linie, und das
/// Semantics-Label des Aufrufers nennt die Lücke.
class WeightChart extends StatefulWidget {
  const WeightChart({
    super.key,
    required this.series,
    required this.semanticLabel,
    this.height = compactHeight,
  });

  /// Die Reihe des gezeigten Fensters. Unter zwei Einträgen zeichnet das
  /// Widget nichts — aus einem Wert folgt keine Reihe.
  final WeightSeries series;

  /// Von-Bis-Label. Die Punkte selbst sind stumm; die Aussage steht hier.
  final String semanticLabel;

  final double height;

  /// Höhe in der Karte (Board 14, F).
  static const compactHeight = 56.0;

  /// Höhe in der Verlaufsansicht.
  static const fullHeight = 66.0;

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AtemMotion.latestPointPulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bei reduzierter Bewegung steht der Ring still statt halb eingefroren zu
    // pulsieren: `syncLoop` hält ihn auf dem Ruhewert 0 — kein Ring.
    AtemMotion.syncLoop(context, _pulse, restingValue: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.length < 2) return const SizedBox.shrink();

    return Semantics(
      image: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => CustomPaint(
            painter: _WeightChartPainter(
              series: widget.series,
              pulse: _pulse.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({required this.series, required this.pulse});

  final WeightSeries series;
  final double pulse;

  /// Seitlicher Rand, damit der erste und der letzte Punkt nicht am Rand
  /// kleben — sie sind die beiden Werte, die am häufigsten gelesen werden.
  static const _sidePad = 6.0;

  /// Abstand der Grundlinie vom unteren Rand.
  static const _baselineGap = 8.0;

  static const _dotRadius = 3.0;
  static const _latestRadius = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final baselineY = size.height - _baselineGap;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      Paint()
        ..color = AtemColors.border
        ..strokeWidth = 1,
    );

    final first = series.first!.date;
    final last = series.latest!.date;
    final span = last.difference(first).inDays;
    if (span <= 0) return;

    final minKg = series.minKg;
    final maxKg = series.maxKg;
    // Ein flacher Verlauf ist ein flacher Verlauf: Bei identischen Werten wird
    // die Linie mittig gezeichnet und nicht auf volle Höhe gespreizt. Eine
    // Skala, die 0,0 kg Unterschied über 40 dp verteilt, wäre eine Behauptung.
    final range = (maxKg - minKg).abs() < 0.05 ? null : maxKg - minKg;

    const left = _sidePad;
    final right = size.width - _sidePad;
    const top = _latestRadius + 2;
    final bottom = baselineY - 2;

    Offset pointFor(WeightEntry entry) {
      final t = entry.date.difference(first).inDays / span;
      final x = left + (right - left) * t;
      final y = range == null
          ? (top + bottom) / 2
          : bottom - (bottom - top) * ((entry.kg - minKg) / range);
      return Offset(x, y);
    }

    final line = Paint()
      ..color = AtemColors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final segment in series.segments) {
      if (segment.length < 2) continue;
      final path = Path()..moveTo(pointFor(segment.first).dx,
          pointFor(segment.first).dy);
      for (final entry in segment.skip(1)) {
        final p = pointFor(entry);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, line);
    }

    final filled = Paint()..color = AtemColors.cyan;
    final hollow = Paint()..color = AtemColors.surfaceSolid;
    final ring = Paint()
      ..color = AtemColors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final entry in series.entries) {
      final p = pointFor(entry);
      final isLatest = entry.documentId == series.latest!.documentId;
      final radius = isLatest ? _latestRadius : _dotRadius;
      if (entry.source.isMeasured) {
        canvas.drawCircle(p, radius, hollow);
        canvas.drawCircle(p, radius, ring);
      } else {
        canvas.drawCircle(p, radius, filled);
      }
      if (isLatest && pulse > 0) {
        canvas.drawCircle(
          p,
          _latestRadius + pulse * 5,
          Paint()
            ..color = AtemColors.cyan.withValues(alpha: (1 - pulse) * 0.55)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) =>
      old.pulse != pulse || old.series != series;
}

/// Die Lückennotiz — **eine** Zeile unter der Kurve.
///
/// Sie benennt die längste Lücke als Zeitspanne, nicht als Ereignis: reine
/// Information, kein Fehler, keine Farbe. Höchstens eine je Block; welche,
/// entscheidet [WeightSeries.namedGap].
class WeightGapNote extends StatelessWidget {
  const WeightGapNote({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: AtemType.meta.of(context),
      );
}
