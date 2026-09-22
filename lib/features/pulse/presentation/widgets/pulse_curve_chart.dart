import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/heart_rate_zones.dart';

/// Der Pulsverlauf einer Einheit — bpm über die Zeit, in den Farben der
/// Zonen, mit ablesbarem Wert unter dem Finger.
///
/// Board 16, offene Frage 1, gelöst am 22.09.2026; Farben, Spanne, Zeitachse
/// und Schieber kamen am selben Tag dazu.
///
/// ## Ein Baustein, kein Bildschirmteil
///
/// Er kennt **keine Einheit, keinen Import und keinen Provider** — nur eine
/// Reihe bpm über Minuten, eine Länge und optional Zonengrenzen. Damit taugt
/// er für jeden Pulsverlauf, der später dazukommt: ein Tagesverlauf, ein
/// Ruhepuls über Wochen, eine Gesundheitsseite.
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
/// ## Die Farben
///
/// Jedes Minutenstück trägt die Farbe der Zone, in der sein Wert liegt
/// (`AtemColors.zone`). Dazu liegen Haarlinien auf den Zonengrenzen, damit
/// die Farbe nicht die einzige Auskunft ist — man sieht, **wo** die Grenze
/// verläuft, nicht nur dass sich etwas geändert hat. Ohne festgelegte Grenzen
/// bleibt die Linie einfarbig: ATEM rechnet keine Zonen, solange sie fehlen
/// (Board 16, Entscheidung 13).
///
/// **Die Auflösung ist eine Minute.** Feiner geht es nicht: `PulseProfile`
/// legt je Minute *einen* gemittelten Wert ab. Zwanzig Sekunden in einer
/// anderen Zone sind in dieser Minute mitgemittelt und erscheinen nicht als
/// eigener Abschnitt. Eine feinere Kurve wäre ein Schemawechsel, kein
/// Anzeigefehler.
///
/// ## Der Schieber
///
/// Ziehen über die Kurve setzt eine Marke auf die nächstgelegene **gemessene**
/// Minute — nie zwischen zwei Messungen, denn dort steht nichts. Der Wert
/// erscheint in der Zeile über der Kurve, an der Stelle, an der sonst die
/// Spanne steht: Dieselbe Zeile, dieselbe Höhe, kein Sprung im Aufbau
/// während man zieht.
///
/// Für Screenreader bleibt das Ganze **ein** Knoten mit Spanne und Dauer im
/// Label (CLAUDE.md), und zwar **ohne** Hinweis auf die Geste. Eine Ansage
/// „zum Ablesen ziehen" verspräche einen Weg, den TalkBack so nicht anbietet.
/// Der Schieber ist eine Zugabe fürs Auge; dieselben Tatsachen stehen als
/// Text im Block — Ø, Max und Min als Kacheln, die Minuten je Zone darunter.
class PulseCurveChart extends StatefulWidget {
  const PulseCurveChart({
    super.key,
    required this.bpmByMinute,
    required this.totalMinutes,
    required this.semanticLabel,
    this.zones,
    this.height = 96,
  });

  /// bpm je Minute seit Beginn — nur Minuten mit Messung.
  final Map<int, int> bpmByMinute;

  /// Die Länge der Einheit in Minuten — bestimmt die Breite der Zeitachse,
  /// nicht nur die Zahl der Messpunkte. So bleibt eine Lücke am Anfang oder
  /// Ende sichtbar, nicht nur eine mittendrin.
  final int totalMinutes;

  /// „Pulsverlauf, von 96 bis 172 bpm über 52 Minuten" — **ein** Knoten, wie
  /// jede Datenzeile in dieser App (CLAUDE.md, Barrierefreiheit).
  final String semanticLabel;

  /// Ohne Grenzen eine einfarbige Linie, keine geratenen Zonen.
  final HeartRateZones? zones;

  final double height;

  /// Unter zwei Minutenwerten zeichnet das Widget nichts — aus einem Punkt
  /// folgt keine Linie, und der Block rendert dann ohne diesen Teil weiter
  /// („ein Block ohne Daten rendert nicht", CLAUDE.md).
  bool get hasCurve => bpmByMinute.length >= 2 && totalMinutes > 0;

  @override
  State<PulseCurveChart> createState() => _PulseCurveChartState();
}

class _PulseCurveChartState extends State<PulseCurveChart> {
  /// Die Minute unter dem Finger, oder `null` — dann steht die Spanne da.
  int? _marked;

  List<int> get _minutes => widget.bpmByMinute.keys.toList()..sort();

  void _markAt(Offset local, double width) {
    if (width <= 0) return;
    final span = widget.totalMinutes <= 1 ? 1 : widget.totalMinutes - 1;
    final ratio = (local.dx / width).clamp(0.0, 1.0);
    final wanted = ratio * span;

    // Die **nächstgelegene gemessene** Minute, nicht die nächstgelegene
    // überhaupt: Zwischen zwei Messungen gibt es keinen Wert, und einen zu
    // zeigen wäre eine Interpolation über eine Lücke (CLAUDE.md).
    var best = _minutes.first;
    for (final m in _minutes) {
      if ((m - wanted).abs() < (best - wanted).abs()) best = m;
    }
    if (best != _marked) setState(() => _marked = best);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasCurve) return const SizedBox.shrink();

    final l10n = AppL10n.of(context);
    final values = widget.bpmByMinute.values;
    final minBpm = values.reduce((a, b) => a < b ? a : b);
    final maxBpm = values.reduce((a, b) => a > b ? a : b);

    return Semantics(
      container: true,
      image: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Readout(
            range: l10n.pulseCurveRange(minBpm, maxBpm),
            marked: _markedText(l10n),
            // Die Obergrenze für die Höhe: längste Zeit, grösster Wert,
            // letzte Zone. Gemessen wird sie, gezeichnet nie — eine zweite,
            // unsichtbare Zeile im Baum wäre ein doppelter Text.
            widest: _readoutText(
              l10n,
              l10n.durationMinutes(widget.totalMinutes),
              '$maxBpm ${l10n.detailUnitBpm}',
              HeartRateZones.zoneCount,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) =>
                // atem:geste-erlaubt
                GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _markAt(d.localPosition, constraints.maxWidth),
              onHorizontalDragStart: (d) =>
                  _markAt(d.localPosition, constraints.maxWidth),
              onHorizontalDragUpdate: (d) =>
                  _markAt(d.localPosition, constraints.maxWidth),
              onHorizontalDragEnd: (_) => setState(() => _marked = null),
              onHorizontalDragCancel: () => setState(() => _marked = null),
              child: SizedBox(
                height: widget.height,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: 1.0),
                  duration: AtemMotion.reduced(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 420),
                  curve: Curves.easeOutQuart,
                  builder: (context, progress, _) => CustomPaint(
                    painter: _PulseCurvePainter(
                      bpmByMinute: widget.bpmByMinute,
                      totalMinutes: widget.totalMinutes,
                      zones: widget.zones,
                      progress: progress,
                      marked: _marked,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _TimeAxis(
            start: l10n.pulseCurveStart,
            end: l10n.durationMinutes(widget.totalMinutes),
          ),
        ],
      ),
    );
  }

  /// „12 min · 152 bpm · Zone 3" — oder `null`, wenn niemand zieht.
  String? _markedText(AppL10n l10n) {
    final minute = _marked;
    if (minute == null) return null;
    final bpm = widget.bpmByMinute[minute];
    if (bpm == null) return null;

    return _readoutText(
      l10n,
      l10n.durationMinutes(minute),
      '$bpm ${l10n.detailUnitBpm}',
      widget.zones?.zoneOf(bpm),
    );
  }

  String _readoutText(AppL10n l10n, String time, String value, int? zone) =>
      zone == null
          ? l10n.pulseCurveReadoutPlain(time, value)
          : l10n.pulseCurveReadout(time, value, l10n.detailZoneName(zone));
}

/// Spanne oder abgelesener Wert — **immer dieselbe Höhe**.
///
/// Die Höhe kommt aus einer Messung, nicht aus einer zweiten, unsichtbaren
/// Zeile im Baum: Die stünde doppelt im Widget-Baum, und `find.text` fände
/// sie zweimal. Gemessen werden die Spanne und die **längstmögliche**
/// Ablesung ([widest]); die grössere gewinnt.
///
/// Bei 200 % auf 320 dp bricht die Ablesung um — die Zeile ist dann von
/// vornherein zwei Zeilen hoch, und der Aufbau springt nicht, während man
/// zieht.
class _Readout extends StatelessWidget {
  const _Readout({
    required this.range,
    required this.marked,
    required this.widest,
  });

  final String range;
  final String? marked;
  final String widest;

  @override
  Widget build(BuildContext context) {
    // Die Spanne ist eine Metazeile, der abgelesene Wert die Aussage —
    // deshalb steht er heller.
    final rangeStyle = AtemType.meta.of(context);
    final markedStyle = AtemType.body.of(context);
    final shown = marked;

    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        double heightOf(String text, TextStyle style) => (TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: direction,
              textScaler: scaler,
            )..layout(maxWidth: constraints.maxWidth))
                .height;

        return SizedBox(
          height: math.max(
            heightOf(range, rangeStyle),
            heightOf(widest, markedStyle),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: shown == null
                ? Text(range, style: rangeStyle)
                : Text(shown, style: markedStyle),
          ),
        );
      },
    );
  }
}

/// Anfang und Ende der Zeitachse. Passen beide nicht nebeneinander, bleibt
/// das Ende — der Anfang ist immer null und damit die verzichtbare Hälfte.
class _TimeAxis extends StatelessWidget {
  const _TimeAxis({required this.start, required this.end});

  final String start;
  final String end;

  @override
  Widget build(BuildContext context) {
    final style = AtemType.meta.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        double widthOf(String t) => (TextPainter(
              text: TextSpan(text: t, style: style),
              textDirection: direction,
              textScaler: scaler,
              maxLines: 1,
            )..layout())
                .width;

        final fits =
            widthOf(start) + 12 + widthOf(end) <= constraints.maxWidth;
        if (!fits) {
          return Align(
            alignment: Alignment.centerRight,
            child: Text(end, style: style),
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(start, style: style), Text(end, style: style)],
        );
      },
    );
  }
}

class _PulseCurvePainter extends CustomPainter {
  _PulseCurvePainter({
    required this.bpmByMinute,
    required this.totalMinutes,
    required this.zones,
    required this.progress,
    required this.marked,
  });

  final Map<int, int> bpmByMinute;
  final int totalMinutes;
  final HeartRateZones? zones;
  final double progress;
  final int? marked;

  static const _sidePad = 4.0;
  static const _topPad = 10.0;
  static const _bottomPad = 10.0;

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

  Color _colorFor(int bpm) {
    final z = zones;
    return z == null ? AtemColors.violetLight : AtemColors.zone(z.zoneOf(bpm));
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

    double yFor(int bpm) => range == null
        ? (top + bottom) / 2
        : bottom - (bottom - top) * ((bpm - minBpm) / range);
    Offset pointFor(int minute) => Offset(
          left + (right - left) * (minute / span).clamp(0.0, 1.0),
          yFor(bpmByMinute[minute]!),
        );

    // ---- Haarlinien auf den Zonengrenzen. Sie stehen **hinter** der Kurve
    // und nur, wo sie in den gezeichneten Bereich fallen: Eine Grenze
    // ausserhalb der Spanne sagt nichts über diese Einheit.
    final z = zones;
    if (z != null && range != null) {
      for (var boundary = 1; boundary < HeartRateZones.zoneCount; boundary++) {
        final bpm = z.lowerOf(boundary + 1);
        if (bpm == null || bpm <= minBpm || bpm >= maxBpm) continue;
        canvas.drawLine(
          Offset(left, yFor(bpm)),
          Offset(right, yFor(bpm)),
          Paint()
            ..color = AtemColors.zone(boundary + 1).withValues(alpha: 0.28)
            ..strokeWidth = 1,
        );
      }
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    // ---- Die Linie, Minutenstück für Minutenstück in der Farbe seiner Zone.
    for (final segment in _segments(minutes)) {
      if (segment.length < 2) continue;

      final xs = [for (final m in segment) pointFor(m).dx];
      final first = xs.first;
      final last = xs.last;

      // Die Fläche darunter: **ein** Pfad je zusammenhängendem Stück, gefüllt
      // mit einem Verlauf aus harten Stopps.
      //
      // Vorher trug jede Minute ihr eigenes Viereck. Am Render standen dann
      // Nähte zwischen ihnen — zwei antialiaste Kanten nebeneinander lassen
      // eine helle Linie stehen, auch wenn die Farbe dieselbe ist. Ein Pfad
      // und ein Verlauf, dessen Farbe an der Minutengrenze **springt** statt
      // zu blenden: keine Naht, und die Zonen bleiben als Bänder lesbar
      // statt ineinanderzulaufen.
      if (last > first) {
        final colors = <Color>[];
        final stops = <double>[];
        for (var i = 0; i < segment.length - 1; i++) {
          final c = _colorFor(bpmByMinute[segment[i]]!).withValues(alpha: 0.14);
          colors.add(c);
          stops.add((xs[i] - first) / (last - first));
          colors.add(c);
          stops.add((xs[i + 1] - first) / (last - first));
        }

        final area = Path()..moveTo(xs.first, pointFor(segment.first).dy);
        for (var i = 1; i < segment.length; i++) {
          final p = pointFor(segment[i]);
          area.lineTo(p.dx, p.dy);
        }
        area
          ..lineTo(last, bottom)
          ..lineTo(first, bottom)
          ..close();

        canvas.drawPath(
          area,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(first, 0),
              Offset(last, 0),
              colors,
              stops,
            ),
        );
      }

      for (var i = 0; i < segment.length - 1; i++) {
        canvas.drawLine(
          pointFor(segment[i]),
          pointFor(segment[i + 1]),
          Paint()
            ..color = _colorFor(bpmByMinute[segment[i]]!)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    canvas.restore();

    if (progress < 1) return;

    // ---- Höchster und niedrigster Wert. Ein gefüllter Punkt mit Ring: Der
    // Ring hebt ihn von jedem anderen Punkt der Linie ab, auch wenn beide
    // dieselbe Zonenfarbe tragen.
    if (range != null) {
      for (final bpm in {maxBpm, minBpm}) {
        final minute =
            minutes.firstWhere((m) => bpmByMinute[m] == bpm);
        final p = pointFor(minute);
        canvas.drawCircle(p, 4.5, Paint()..color = AtemColors.base);
        canvas.drawCircle(
          p,
          4.5,
          Paint()
            ..color = _colorFor(bpm)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // ---- Die Marke unter dem Finger.
    final m = marked;
    if (m != null && bpmByMinute[m] != null) {
      final p = pointFor(m);
      canvas.drawLine(
        Offset(p.dx, top - 4),
        Offset(p.dx, bottom + 4),
        Paint()
          ..color = AtemColors.textSecondary.withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 5, Paint()..color = _colorFor(bpmByMinute[m]!));
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = AtemColors.base
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_PulseCurvePainter old) =>
      old.bpmByMinute != bpmByMinute ||
      old.totalMinutes != totalMinutes ||
      old.zones != zones ||
      old.progress != progress ||
      old.marked != marked;
}
