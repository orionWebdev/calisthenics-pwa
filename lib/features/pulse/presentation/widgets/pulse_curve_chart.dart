import 'dart:math' as math;
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
/// ## Die Farben (Board 16, Nachtrag, O)
///
/// Jedes Stück trägt die Farbe der Zone, in der sein Wert liegt
/// (`AtemColors.zone`); der Wechsel liegt auf der **Mitte** des Stücks, nicht
/// an seinem Anfang — ein Wert gilt von der Mitte davor bis zur Mitte danach.
///
/// Die Zonengrenzen sind **neutrale Haarlinien** (`AtemColors.border`), nicht
/// farbig: Zwei Farbebenen im selben Plot — Linie und Gitter — stritten um
/// dieselbe Auskunft. Der Schlüssel zwischen Kurvenfarbe und Zonennamen liegt
/// stattdessen in den Zonenzeilen darunter, die seit dem Nachtrag einen Punkt
/// in der Zonenfarbe tragen.
///
/// **Keine Fläche unter der Kurve.** Sie stand hier am 22.09. zuerst und ist
/// mit dem Nachtrag entfallen: Der Plot trägt Linie, Punkte, Gitter, Ringe
/// und Taktstreifen — eine sechste Ebene aus eingefärbten Bändern machte ihn
/// laut, und die Zonenminuten stehen ohnehin als Zahl darunter.
///
/// Ohne festgelegte Grenzen bleibt die Linie einfarbig: ATEM rechnet keine
/// Zonen, solange sie fehlen (Board 16, Entscheidung 13).
///
/// ## Was sonst im Plot steht
///
/// * **Ein Punkt je gespeichertem Wert** (#CDD3EA). Bei feiner Ablage
///   verschmelzen sie zur dichten Spur — die Dichte selbst ist die Auskunft.
/// * **Ein Taktstreifen** unter dem Plot, ein Strich je gespeichertem Wert.
///   Er sagt dasselbe noch einmal, aber ohne die Kurve zu belasten.
/// * **Ringe auf höchstem und niedrigstem Wert**, weiss — nicht in der
///   Zonenfarbe: Sie markieren eine Stelle, sie benennen keine Zone.
/// * Das bpm-Fenster steht **fest** aus min/max plus 6 bpm Luft, damit die
///   Ringe nicht am Rand kleben.
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
    required this.bpmBySlot,
    required this.slotSeconds,
    required this.totalSeconds,
    required this.semanticLabel,
    required this.resolution,
    this.zones,
    this.gapSeconds = 60,
    this.changeSlot,
    this.height = 96,
  });

  /// bpm je Schlitz seit Beginn — nur Schlitze mit Messung.
  final Map<int, int> bpmBySlot;

  /// Wie lang ein Schlitz ist. Zehn Sekunden seit dem 22.09.2026, sechzig in
  /// allem, was vorher abgelegt wurde.
  final int slotSeconds;

  /// Die Länge der Einheit in Sekunden — bestimmt die Breite der Zeitachse,
  /// nicht nur die Zahl der Messpunkte. So bleibt eine Lücke am Anfang oder
  /// Ende sichtbar, nicht nur eine mittendrin.
  final int totalSeconds;

  /// „Pulsverlauf, von 96 bis 172 bpm über 52 Minuten" — **ein** Knoten, wie
  /// jede Datenzeile in dieser App (CLAUDE.md, Barrierefreiheit).
  final String semanticLabel;

  /// Ohne Grenzen eine einfarbige Linie, keine geratenen Zonen.
  final HeartRateZones? zones;

  /// Wie lange ein Wert höchstens gilt, ohne dass ein neuer kommt.
  ///
  /// **Darüber beginnt ein neuer Abschnitt, darunter läuft die Linie durch.**
  /// Das ist der Unterschied zwischen einer Lücke und einer gröberen Stelle
  /// (Board 16, Nachtrag, „Wechselmarke · Regel") — und der Grund, warum die
  /// Abschnitte nicht an der Schlitznachbarschaft hängen: Eine Uhr, die
  /// minütlich misst, füllt im Zehn-Sekunden-Raster jeden sechsten Schlitz,
  /// und ihre Kurve zerfiele sonst in lauter Einzelpunkte.
  final int gapSeconds;

  /// Der Schlitz, ab dem anders dicht gespeichert wurde — oder `null`.
  ///
  /// Dort steht eine gestrichelte Senkrechte (Board 16, Nachtrag). Sie ist
  /// **kein** Zeichen für eine Lücke: Über eine Lücke läuft die Linie nicht,
  /// durch die Marke läuft sie durch — daran sind beide zu unterscheiden.
  final int? changeSlot;

  /// Wie dicht gespeichert wurde, als Wort — „je Minute ein Wert".
  ///
  /// Der Baustein rechnet es nicht selbst aus: Ob eine Einheit minutengenau
  /// oder feiner abgelegt ist, weiss die Quelle, nicht der Graph. Er sagt es
  /// nur weiter — in der Zeile über der Kurve und im Vorlesetext.
  final String resolution;

  final double height;

  /// Unter zwei Minutenwerten zeichnet das Widget nichts — aus einem Punkt
  /// folgt keine Linie, und der Block rendert dann ohne diesen Teil weiter
  /// („ein Block ohne Daten rendert nicht", CLAUDE.md).
  bool get hasCurve => bpmBySlot.length >= 2 && totalSeconds > 0;

  /// Der letzte Schlitz der Einheit — die rechte Kante der Zeitachse.
  int get lastSlot => totalSeconds <= slotSeconds
      ? 0
      : (totalSeconds / slotSeconds).ceil() - 1;

  @override
  State<PulseCurveChart> createState() => _PulseCurveChartState();
}

class _PulseCurveChartState extends State<PulseCurveChart> {
  /// Die Minute unter dem Finger, oder `null` — dann steht die Spanne da.
  int? _marked;

  List<int> get _slots => widget.bpmBySlot.keys.toList()..sort();

  /// Die Zeit eines Schlitzes als Wort.
  ///
  /// Bei minutengenauer Ablage „12 min", bei feinerer „12:30" — eine Kurve,
  /// die alle zehn Sekunden einen Wert trägt, bräuchte sonst sechs gleich
  /// beschriftete Punkte je Minute.
  String _timeLabel(AppL10n l10n, int slot) {
    final seconds = slot * widget.slotSeconds;
    if (widget.slotSeconds >= 60) return l10n.durationMinutes(seconds ~/ 60);
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '${seconds ~/ 60}:$rest';
  }

  /// Einen gespeicherten Wert weiter — **oder in eine Lücke hinein**.
  ///
  /// Der Schieber am Finger rastet auf gespeicherte Werte; das Durchgehen
  /// mit dem Screenreader geht über **jede** Minute, auch die ohne Messung
  /// (Board 16, Nachtrag, nA11y). Eine Lücke zu überspringen hiesse, sie zu
  /// verschweigen — sie ist ein eigener Schritt, kein Sprung.
  /// Der Schlitz [delta] Schritte von der aktuellen Marke entfernt.
  int _at(int delta) =>
      ((_marked ?? _slots.first) + delta).clamp(0, widget.lastSlot);

  void _step(int delta) {
    final next = _at(delta);
    if (next != _marked) setState(() => _marked = next);
  }

  void _markAt(Offset local, double width) {
    if (width <= 0) return;
    final span = widget.lastSlot <= 0 ? 1 : widget.lastSlot;
    final ratio = (local.dx / width).clamp(0.0, 1.0);
    final wanted = ratio * span;

    // Der **nächstgelegene gemessene** Schlitz, nicht der nächstgelegene
    // überhaupt: Zwischen zwei Messungen gibt es keinen Wert, und einen zu
    // zeigen wäre eine Interpolation über eine Lücke (CLAUDE.md).
    var best = _slots.first;
    for (final m in _slots) {
      if ((m - wanted).abs() < (best - wanted).abs()) best = m;
    }
    if (best != _marked) setState(() => _marked = best);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasCurve) return const SizedBox.shrink();

    final l10n = AppL10n.of(context);
    final values = widget.bpmBySlot.values;
    final minBpm = values.reduce((a, b) => a < b ? a : b);
    final maxBpm = values.reduce((a, b) => a > b ? a : b);

    return Semantics(
      container: true,
      // **Ein Slider, kein Bild** (Board 16, Nachtrag, nA11y). TalkBack kann
      // einen Wert erhöhen und senken; damit ist die Kurve auch ohne Augen
      // begehbar. Ein Bild wäre eine Zahl weniger, die jemand erfährt.
      slider: true,
      // **Die Ringe sprechen mit** (Board 16, Nachtrag, nA11y): Sie sind
      // Teil des Kurvenlabels, kein eigener Knoten. Und sie sagen
      // ausdrücklich „gezeichnet" — Max und Min der Einheit stehen in den
      // Kacheln darüber und weichen ab, weil die Kurve Mittel zeichnet.
      label: '${widget.semanticLabel} '
          '${l10n.pulseCurveRingsA11y(maxBpm, minBpm)}.',
      // Flutter verlangt zu `increase`/`decrease` auch, wie der Wert danach
      // lautet — sonst kündigt der Screenreader den Schritt nicht an.
      value: _spokenPoint(l10n, _at(0)),
      increasedValue: _spokenPoint(l10n, _at(1)),
      decreasedValue: _spokenPoint(l10n, _at(-1)),
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Readout(
            marked: _markedText(l10n),
            // Die Obergrenze für die Höhe: längste Zeit, grösster Wert,
            // letzte Zone. Gemessen wird sie, gezeichnet nie — eine zweite,
            // unsichtbare Zeile im Baum wäre ein doppelter Text.
            widest: l10n.pulseCurveReadout(
              _timeLabel(l10n, widget.lastSlot),
              '$maxBpm ${l10n.detailUnitBpm}',
              l10n.detailZoneName(HeartRateZones.zoneCount),
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
                      bpmBySlot: widget.bpmBySlot,
                      lastSlot: widget.lastSlot,
                      zones: widget.zones,
                      slotSeconds: widget.slotSeconds,
                      gapSeconds: widget.gapSeconds,
                      changeSlot: widget.changeSlot,
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
            end: l10n.durationMinutes((widget.totalSeconds / 60).round()),
          ),
        ],
      ),
    );
  }

  /// „12 min · 152 bpm · Zone 3" — oder `null`, wenn niemand zieht.
  ///
  /// In einer Lücke steht „12 min · keine Aufzeichnung": Was nicht gemessen
  /// wurde, bekommt keinen geschätzten Wert.
  String? _markedText(AppL10n l10n) {
    final slot = _marked;
    if (slot == null) return null;
    final time = _timeLabel(l10n, slot);
    final bpm = widget.bpmBySlot[slot];
    if (bpm == null) return l10n.pulseCurveGap(time);

    final zone = widget.zones?.zoneOf(bpm);
    final value = '$bpm ${l10n.detailUnitBpm}';
    return zone == null
        ? l10n.pulseCurveReadoutPlain(time, value)
        : l10n.pulseCurveReadout(time, value, l10n.detailZoneName(zone));
  }

  /// Derselbe Punkt für den Screenreader — als Wert des Sliders.
  String _spokenPoint(AppL10n l10n, int slot) {
    final time = _timeLabel(l10n, slot);
    final bpm = widget.bpmBySlot[slot];
    if (bpm == null) return l10n.pulseCurveA11yGap(time);
    final zone = widget.zones?.zoneOf(bpm);
    return zone == null
        ? l10n.pulseCurveA11yPointPlain(time, bpm)
        : l10n.pulseCurveA11yPoint(time, bpm, zone);
  }
}

/// Der abgelesene Wert — und sonst nichts.
///
/// ## Warum hier keine Spanne mehr steht (Board 16, Nachtrag)
///
/// Bis zum 22.09.2026 abends stand hier „95–176 bpm". Daneben nennen die
/// Kacheln Ø, Max und Min **aus den Rohwerten** der Uhr, während die Kurve
/// Mittel zeichnet — zwei Zahlenpaare zur selben Frage, mit verschiedenen
/// Grundlagen. Am Gerät las man „Max 120" und einen Schritt darunter
/// „75–115 bpm"; wer das liest, sucht den Fehler bei sich.
///
/// Die Spanne ist deshalb entfallen. Die Ringe im Plot markieren weiter den
/// höchsten und niedrigsten **gezeichneten** Wert; dass er unter Max liegt,
/// sagt ein Satz im ⓘ.
///
/// ## Warum die Zeile trotzdem bleibt
///
/// Ihre Höhe kommt aus einer Messung der **längstmöglichen** Ablesung
/// ([widest]), nicht aus einer zweiten, unsichtbaren Zeile im Baum: Die
/// stünde doppelt darin, und `find.text` fände sie zweimal. So steht die
/// Höhe vorher fest, und der Aufbau springt nicht, während man zieht — auch
/// bei 200 %, wo die Ablesung umbricht.
class _Readout extends StatelessWidget {
  const _Readout({required this.marked, required this.widest});

  final String? marked;
  final String widest;

  @override
  Widget build(BuildContext context) {
    final style = AtemType.body.of(context);
    final shown = marked;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (TextPainter(
          text: TextSpan(text: widest, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth))
            .height;

        return SizedBox(
          height: height,
          child: Align(
            alignment: Alignment.centerLeft,
            child: shown == null
                ? const SizedBox.shrink()
                : Text(shown, style: style),
          ),
        );
      },
    );
  }
}

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
    required this.bpmBySlot,
    required this.lastSlot,
    required this.zones,
    required this.slotSeconds,
    required this.gapSeconds,
    required this.changeSlot,
    required this.progress,
    required this.marked,
  });

  final Map<int, int> bpmBySlot;
  final int lastSlot;
  final HeartRateZones? zones;
  final int slotSeconds;
  final int gapSeconds;
  final int? changeSlot;
  final double progress;
  final int? marked;

  static const _sidePad = 4.0;
  static const _topPad = 10.0;

  /// Unter dem Plot bleibt Platz für den Taktstreifen.
  static const _bottomPad = 10.0;
  static const _tickGap = 5.0;
  static const _tickLength = 5.0;

  /// Ab welchem Abstand zwei Wertpunkte noch als zwei zu erkennen sind.
  ///
  /// Etwas mehr als ihr Durchmesser (2,6 dp). Darunter wären sie eine Fläche,
  /// und eine Fläche sagt nichts, was der Taktstreifen nicht besser sagt.
  static const _pointGap = 3.5;

  /// Luft über dem höchsten und unter dem niedrigsten Wert, in bpm.
  ///
  /// Ohne sie klebte der Ring des Höchstwerts an der Oberkante und wäre zur
  /// Hälfte abgeschnitten (Board 16, Nachtrag, O).
  static const _headroom = 6;

  /// Unter 3 bpm Spanne wird mittig eine flache Linie gezeichnet statt sie
  /// auf volle Höhe zu spreizen — dieselbe Regel wie beim Gewichtsverlauf:
  /// Eine Skala, die kaum Unterschied über die volle Höhe verteilt, wäre
  /// eine Behauptung.
  static const _flatThreshold = 3;

  /// Die zusammenhängenden Abschnitte — **zeitlich**, nicht schlitzweise.
  ///
  /// Zwei Werte sechzig Sekunden auseinander sind kein Loch: Der erste gilt
  /// bis zum zweiten, die Linie läuft durch. Erst über [gapSeconds] beginnt
  /// ein neuer Abschnitt. Hinge das an der Schlitznachbarschaft, zerfiele
  /// eine minütlich gemessene Kurve im Zehn-Sekunden-Raster in lauter
  /// Einzelpunkte — und würde gar nicht gezeichnet.
  List<List<int>> _segments(List<int> sortedSlots) {
    final segments = <List<int>>[];
    List<int>? current;
    for (final m in sortedSlots) {
      if (current != null && (m - current.last) * slotSeconds <= gapSeconds) {
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
    if (size.width <= 0 || size.height <= 0 || bpmBySlot.length < 2) return;

    final slots = bpmBySlot.keys.toList()..sort();
    final values = bpmBySlot.values;
    final minBpm = values.reduce((a, b) => a < b ? a : b);
    final maxBpm = values.reduce((a, b) => a > b ? a : b);
    final flat = (maxBpm - minBpm) < _flatThreshold;

    // Das feste Fenster: min/max plus Luft. Es gilt für die ganze Einheit,
    // damit derselbe bpm-Wert überall auf derselben Höhe liegt.
    final low = minBpm - _headroom;
    final high = maxBpm + _headroom;

    const left = _sidePad;
    final right = size.width - _sidePad;
    const top = _topPad;
    final bottom = size.height - _bottomPad - _tickGap - _tickLength;
    final span = lastSlot <= 0 ? 1 : lastSlot;

    double yFor(int bpm) => flat
        ? (top + bottom) / 2
        : bottom - (bottom - top) * ((bpm - low) / (high - low));
    double xFor(int slot) =>
        left + (right - left) * (slot / span).clamp(0.0, 1.0);
    Offset pointFor(int slot) => Offset(xFor(slot), yFor(bpmBySlot[slot]!));

    // ---- Das Gitter: Haarlinien auf den Zonengrenzen, neutral. Nur, wo sie
    // in das Fenster fallen — eine Grenze ausserhalb sagt nichts über diese
    // Einheit.
    final z = zones;
    if (z != null && !flat) {
      for (var boundary = 1; boundary < HeartRateZones.zoneCount; boundary++) {
        final bpm = z.lowerOf(boundary + 1);
        if (bpm == null || bpm <= low || bpm >= high) continue;
        canvas.drawLine(
          Offset(left, yFor(bpm)),
          Offset(right, yFor(bpm)),
          Paint()
            ..color = AtemColors.border
            ..strokeWidth = 1,
        );
      }
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    // ---- Die Linie. **Der Farbwechsel liegt auf der Mitte** eines Stücks:
    // Ein Wert gilt von der Mitte davor bis zur Mitte danach, nicht erst ab
    // seinem eigenen Punkt. Sonst begänne die neue Zone eine halbe Minute zu
    // spät.
    final line = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final segment in _segments(slots)) {
      if (segment.length < 2) continue;
      for (var i = 0; i < segment.length - 1; i++) {
        final a = pointFor(segment[i]);
        final b = pointFor(segment[i + 1]);
        final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        canvas.drawLine(
            a, mid, line..color = _colorFor(bpmBySlot[segment[i]]!));
        canvas.drawLine(
            mid, b, line..color = _colorFor(bpmBySlot[segment[i + 1]]!));
      }
    }

    // ---- Ein Punkt je gespeichertem Wert, 2,6 dp in `#CDD3EA`.
    //
    // Er liegt auf der 2 dp breiten Linie und unterbricht sie sichtbar —
    // genau das ist gemeint: Man sieht, **wo** gespeichert wurde.
    //
    // **Nur solange sie sich nicht berühren.** Das Board rechnet damit, dass
    // sie bei feiner Ablage „zur dichten Spur verschmelzen"; am Render war zu
    // sehen, was das kostet: Bei zehn Sekunden über 36 Minuten liegen sie
    // enger als ihr eigener Durchmesser und überdecken die Linie
    // vollständig — die Zonenfarben, also die eigentliche Auskunft, waren
    // weg. Rücken sie enger als [_pointGap] zusammen, trägt der Taktstreifen
    // die Dichte allein; er ist genau dafür da.
    final perSlot = (right - left) / span;
    if (perSlot >= _pointGap) {
      for (final m in slots) {
        canvas.drawCircle(
            pointFor(m), 1.3, Paint()..color = AtemColors.textTertiary);
      }
    }

    // ---- Der Taktstreifen: ein Strich je gespeichertem Wert, unter dem
    // Plot. Lücken tragen keinen Strich — die Dichte ist die Auskunft.
    final tickTop = bottom + _tickGap;
    for (final m in slots) {
      canvas.drawLine(
        Offset(xFor(m), tickTop),
        Offset(xFor(m), tickTop + _tickLength),
        Paint()
          ..color = AtemColors.textSecondary
          ..strokeWidth = 1,
      );
    }

    // ---- Die Wechselmarke: gestrichelt, neutral, über die ganze Plothöhe.
    // Sie liegt **innerhalb** des Laufs, damit sie mit der Front erscheint
    // und nicht vorher aufblitzt.
    final change = changeSlot;
    if (change != null && change > 0 && change <= lastSlot) {
      final x = xFor(change);
      const dash = 3.0;
      for (var y = top; y < bottom; y += dash * 2) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + dash, bottom)),
          Paint()
            ..color = AtemColors.border
            ..strokeWidth = 1,
        );
      }
    }

    canvas.restore();

    if (progress < 1) return;

    // ---- Höchster und niedrigster Wert, weiss geringt. Nicht in der
    // Zonenfarbe: Der Ring markiert eine Stelle, er benennt keine Zone.
    if (!flat) {
      for (final bpm in {maxBpm, minBpm}) {
        final slot = slots.firstWhere((m) => bpmBySlot[m] == bpm);
        canvas.drawCircle(
          pointFor(slot),
          4,
          Paint()
            ..color = AtemColors.textPrimary
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // ---- Die Marke unter dem Finger.
    final m = marked;
    if (m != null && bpmBySlot[m] != null) {
      final p = pointFor(m);
      canvas.drawLine(
        Offset(p.dx, top - 4),
        Offset(p.dx, bottom + 4),
        Paint()
          ..color = AtemColors.textSecondary.withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 5, Paint()..color = _colorFor(bpmBySlot[m]!));
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
      old.bpmBySlot != bpmBySlot ||
      old.lastSlot != lastSlot ||
      old.zones != zones ||
      old.slotSeconds != slotSeconds ||
      old.gapSeconds != gapSeconds ||
      old.changeSlot != changeSlot ||
      old.progress != progress ||
      old.marked != marked;
}
