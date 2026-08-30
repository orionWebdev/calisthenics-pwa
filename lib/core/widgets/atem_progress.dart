import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_gradients.dart';
import '../theme/atem_motion.dart';
import '../theme/atem_type.dart';

/// Wie ein Fortschritt gelesen wird.
///
/// Eine Familie, zwei Modi. Sie teilen Track-Farbe, Kappenlogik und Semantics,
/// aber **Richtung und Kurve sind bindend** — das ist der Kern der
/// Entscheidung Nr. 3 aus Modul 3.
enum AtemProgressMode {
  /// „Wie viel von X." Wächst von 0 auf den Wert, animiert mit derselben
  /// Kurve wie der Score-Count-up, damit es nach Messwert aussieht und nicht
  /// nach Ladebalken.
  share,

  /// „Wie viel Zeit bleibt." Schrumpft von 100 % auf 0, **streng linear**.
  /// Ein easender Countdown lügt über die Restzeit. Bleibt auch bei
  /// reduzierter Bewegung erhalten — er ist informationstragend.
  elapse,
}

/// Gemeinsame Regeln der Fortschrittsfamilie.
abstract final class AtemProgressRules {
  /// Unterhalb dieses Anteils wird ohne Kappen gezeichnet.
  ///
  /// Runde Kappen zeigen bei 0 % einen Punkt, der wie 2 % aussieht.
  static const roundCapThreshold = 0.03;

  /// Genau **eine** geblurrte Kopie unter dem Wertstrich, nie darüber.
  /// Der Track bleibt glowfrei. Ein zweiter Glow senkt den Kantenkontrast
  /// des Füllstands unter Ablesbarkeit — dann lieber gar keiner.
  static const glowBlur = 7.0;
  static const glowAlpha = 0.35;

  static const shareDuration = Duration(milliseconds: 600);
  static const indeterminateDuration = Duration(milliseconds: 2400);

  static StrokeCap capFor(double value) =>
      value < roundCapThreshold ? StrokeCap.butt : StrokeCap.round;

  /// Bei 100 % weicht der Verlauf der Erfolgs-Volltonfarbe.
  static bool isComplete(double value) => value >= 0.999;
}

/// Balken. 4 dp im Anteils-Modus, 5 dp im Ablauf-Modus.
///
/// Der Höhenunterschied ist ein Zweitmerkmal neben der Richtung — man erkennt
/// den Modus auch im Standbild. Und 4 statt der ursprünglich geplanten 3 dp,
/// weil bei 3 dp die runde Kappe auf mdpi unter einen physischen Pixel fällt
/// und der Kappenwechsel gegen den 0-%-Punktfehler nicht mehr greift.
class AtemProgressBar extends StatelessWidget {
  const AtemProgressBar.share({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.gradient,
    this.accent,
  })  : mode = AtemProgressMode.share,
        _height = 4;

  const AtemProgressBar.elapse({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.accent = AtemColors.cyan,
  })  : mode = AtemProgressMode.elapse,
        gradient = null,
        _height = 5;

  /// 0..1, oder `null` für unbestimmt.
  final double? value;
  final String semanticLabel;
  final AtemProgressMode mode;
  final Gradient? gradient;
  final Color? accent;
  final double _height;

  @override
  Widget build(BuildContext context) {
    return _ProgressSemantics(
      label: semanticLabel,
      value: value,
      // **Volle Breite, nicht die des Kindes.** In einer `Column` ohne
      // Streckung bekäme ein `SizedBox` ohne Breite null Pixel — der Balken
      // verschwand dann spurlos, statt sichtbar falsch zu sein. Zwei Stellen
      // im Verlauf haben genau das getan.
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: value == null
            ? _IndeterminateTrack(height: _height)
            : CustomPaint(
                painter: _BarPainter(
                  value: value!,
                  gradient: mode == AtemProgressMode.share ? gradient : null,
                  accent: accent ?? AtemColors.cyan,
                ),
              ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.value,
    required this.gradient,
    required this.accent,
  });

  final double value;
  final Gradient? gradient;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // In einer Column ohne Streckung kollabiert der Balken auf null Breite.
    // Dann sind die clamp-Grenzen vertauscht und es fliegt ein ArgumentError.
    if (size.width <= 0 || size.height <= 0) return;

    final radius = Radius.circular(size.height);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(track, Paint()..color = AtemColors.track);

    if (value <= 0) return;

    final complete = AtemProgressRules.isComplete(value);
    final minWidth = math.min(size.height, size.width);
    final width = (size.width * value.clamp(0.0, 1.0))
        // Mindestens so breit wie hoch, sonst verschwindet der Wert ganz —
        // aber nie breiter als die Fläche.
        .clamp(minWidth, size.width)
        .toDouble();
    final rect = Rect.fromLTWH(0, 0, width, size.height);
    final fill = RRect.fromRectAndRadius(
      rect,
      value < AtemProgressRules.roundCapThreshold ? Radius.zero : radius,
    );

    final paint = Paint();
    if (complete) {
      paint.color = AtemColors.green;
    } else if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = accent;
    }

    // Genau eine Glow-Kopie, unter dem Wertstrich.
    canvas.drawRRect(
      fill,
      Paint()
        ..color = (complete ? AtemColors.green : accent)
            .withValues(alpha: AtemProgressRules.glowAlpha)
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, AtemProgressRules.glowBlur),
    );
    canvas.drawRRect(fill, paint);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.value != value || old.accent != accent;
}

/// Kleiner Ring für Anteile, 38 dp.
///
/// Einfarbig, nie mit Verlauf — auf dieser Größe ist ein Verlauf nicht mehr
/// als Verlauf lesbar. Die Zahl steht innen nur ab 38 dp, darunter daneben.
class AtemProgressRing extends StatelessWidget {
  const AtemProgressRing({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.accent = AtemColors.magenta,
    this.diameter = 38,
    this.label,
  });

  final double? value;
  final String semanticLabel;
  final Color accent;
  final double diameter;

  /// Dekorativer Text in der Mitte. Sein Wert steht bereits in [semanticLabel].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final complete = value != null && AtemProgressRules.isComplete(value!);

    return _ProgressSemantics(
      label: semanticLabel,
      value: value,
      child: SizedBox.square(
        dimension: diameter,
        child: CustomPaint(
          painter: _RingPainter(value: value ?? 0, accent: accent),
          child: Center(
            child: ExcludeSemantics(
              child: complete
                  // Haken ersetzt die Zahl — Form, nicht nur Farbe.
                  ? _Checkmark(color: AtemColors.green, size: diameter * 0.4)
                  : Text(
                      value == null ? '—' : (label ?? ''),
                      style: AtemType.labelDeco.of(context).copyWith(
                            color: AtemColors.textPrimary,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.accent});

  final double value;
  final Color accent;

  static const _stroke = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - _stroke / 2,
    );

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = AtemColors.track,
    );

    if (value <= 0) return;
    final complete = AtemProgressRules.isComplete(value);
    final color = complete ? AtemColors.green : accent;
    final sweep = 2 * math.pi * value.clamp(0.0, 1.0);

    for (final isGlow in [true, false]) {
      canvas.drawArc(
        rect,
        -math.pi / 2, // Start bei 12 Uhr.
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = AtemProgressRules.capFor(value)
          ..color = isGlow
              ? color.withValues(alpha: AtemProgressRules.glowAlpha)
              : color
          ..maskFilter = isGlow
              ? const MaskFilter.blur(
                  BlurStyle.normal, AtemProgressRules.glowBlur)
              : null,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.accent != accent;
}

/// Der große Bogen — Readiness und andere Leitwerte.
///
/// 260°, Lücke unten zentriert. Die Zahl in der Mitte darf bei 1,3× begrenzt
/// werden, weil Stufenlabel und Empfehlung darunter voll mitskalieren und
/// Semantics den exakten Wert meldet. **Fällt eine der beiden Redundanzen weg,
/// muss die Zahl mitwachsen und der Bogen weichen.**
class AtemArcGauge extends StatelessWidget {
  const AtemArcGauge({
    super.key,
    required this.value,
    required this.semanticLabel,
    required this.center,
    this.gradient = AtemGradients.neonWave,
    this.size = 224,
  });

  /// 0..1, oder `null` für unbestimmt.
  final double? value;
  final String semanticLabel;

  /// Was in der Mitte steht. Dekorativ — der Wert steckt in [semanticLabel].
  final Widget center;

  final Gradient gradient;
  final double size;

  /// Über diesem Faktor wird die Zahl im Bogen nicht weiter vergrößert.
  static const numberScaleCap = 1.3;

  @override
  Widget build(BuildContext context) {
    return _ProgressSemantics(
      label: semanticLabel,
      value: value,
      child: SizedBox(
        width: size,
        height: size * 0.857,
        child: CustomPaint(
          painter: _ArcPainter(value: value ?? 0, gradient: gradient),
          child: Center(
            child: MediaQuery.withClampedTextScaling(
              // Der Bogen ist Geometrie, kein Text. Die Zahl darin darf
              // begrenzt werden — die Statuszeile darunter skaliert voll.
              maxScaleFactor: numberScaleCap,
              child: ExcludeSemantics(child: center),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.value, required this.gradient});

  final double value;
  final Gradient gradient;

  /// 140° Start, 260° Sweep — die Lücke liegt damit mittig unten.
  static const _start = 140 * math.pi / 180;
  static const _sweep = 260 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Radius und Strichstärke aus der Fläche ableiten, nicht absolut setzen.
    final stroke = size.width * 0.058;
    final radius = size.width / 2 - stroke / 2 - 2;
    final center = Offset(size.width / 2, size.height / 2 + size.height * 0.03);
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AtemColors.track,
    );

    if (value <= 0) return;
    final complete = AtemProgressRules.isComplete(value);
    final sweep = _sweep * value.clamp(0.0, 1.0);
    final shader = gradient.createShader(rect);

    // Genau eine Glow-Kopie, unter dem Wertstrich.
    canvas.saveLayer(
      rect.inflate(stroke * 2),
      Paint()
        ..color = const Color(0xFFFFFFFF)
            .withValues(alpha: AtemProgressRules.glowAlpha),
    );
    canvas.drawArc(
      rect,
      _start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = AtemProgressRules.capFor(value)
        ..shader = complete ? null : shader
        ..color = complete ? AtemColors.green : const Color(0xFFFFFFFF)
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, AtemProgressRules.glowBlur),
    );
    canvas.restore();

    canvas.drawArc(
      rect,
      _start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = AtemProgressRules.capFor(value)
        ..shader = complete ? null : shader
        ..color = complete ? AtemColors.green : const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.value != value;
}

/// Ein grau wanderndes Segment für „Wert wird ermittelt".
///
/// Bewusst **kein** rotierender Kreisel und **kein** Akzent: Ein akzentfarbenes
/// Segment sähe aus wie Fortschritt und weckte Erwartung. Grau plus langsames
/// Tempo signalisiert „System misst", nicht „System lädt".
class _IndeterminateTrack extends StatefulWidget {
  const _IndeterminateTrack({required this.height});
  final double height;

  @override
  State<_IndeterminateTrack> createState() => _IndeterminateTrackState();
}

class _IndeterminateTrackState extends State<_IndeterminateTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AtemProgressRules.indeterminateDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AtemMotion.syncLoop(context, _controller, restingValue: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.height);
    final still = AtemMotion.reduced(context);

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AtemColors.track,
          borderRadius: radius,
        ),
        child: still
            // Statisch gepunkteter Track statt Schleife.
            ? CustomPaint(
                painter: _DottedTrackPainter(), child: const SizedBox.expand())
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => FractionallySizedBox(
                  alignment: Alignment(-1 + 2.6 * _controller.value, 0),
                  widthFactor: 0.34,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: const LinearGradient(colors: [
                        AtemColors.track,
                        AtemColors.border,
                        AtemColors.track,
                      ]),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _DottedTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AtemColors.border;
    const step = 6.0;
    for (var x = 2.0; x < size.width; x += step) {
      canvas.drawCircle(
          Offset(x, size.height / 2), size.height / 2 * 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _Checkmark extends StatelessWidget {
  const _Checkmark({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _CheckPainter(color));
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * 0.15, size.height * 0.55)
      ..lineTo(size.width * 0.4, size.height * 0.8)
      ..lineTo(size.width * 0.85, size.height * 0.22);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

/// Meldet Wert statt bloßer Existenz.
class _ProgressSemantics extends StatelessWidget {
  const _ProgressSemantics({
    required this.label,
    required this.value,
    required this.child,
  });

  final String label;
  final double? value;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        value: value == null
            ? null
            : '${(value!.clamp(0.0, 1.0) * 100).round()} %',
        child: ExcludeSemantics(child: child),
      );
}
