import 'package:flutter/widgets.dart';

import '../theme/atem_motion.dart';

/// Größe eines Statuspunkts.
///
/// **Zwei Größen, nicht vier.** Die Größe hängt an genau einer Sache: der
/// Schriftgröße des begleitenden Labels. Nicht am Kontext, nicht am Gefühl.
/// Damit ist jede künftige Stelle entscheidungsfrei — vorher gab es 4, 4,5, 5
/// und 6 dp ohne erkennbares System.
enum AtemDotSize {
  /// 6 dp — neben labelMicro und labelSmall (12 sp).
  medium(6, 8),

  /// 4 dp — neben labelDeco (10 sp).
  small(4, 6),

  /// 8 dp — in der Snackbar, wo der Punkt allein die Tonlage trägt und
  /// deshalb aus einem Meter Entfernung sichtbar sein muss (Modul 7, Spec).
  large(8, 10);

  const AtemDotSize(this.diameter, this.blur);
  final double diameter;
  final double blur;
}

/// Farbiger Punkt mit Glow, der einen Zustand anzeigt.
///
/// Skaliert bewusst **nicht** mit der Systemschrift — er ist dekorativ. Sein
/// Zustand steht immer zusätzlich im Text oder in den Semantics des
/// umgebenden Elements.
///
/// Pulsieren nur bei [AtemDotSize.medium] und nur für „läuft gerade" (LIVE,
/// laufende Session). Nie zwei Pulse im selben Bereich.
class AtemStatusDot extends StatefulWidget {
  const AtemStatusDot({
    super.key,
    required this.color,
    this.size = AtemDotSize.medium,
    this.pulsing = false,
  });

  final Color color;
  final AtemDotSize size;

  /// Dauerschleife für „läuft gerade". Steht bei reduzierter Bewegung still.
  final bool pulsing;

  @override
  State<AtemStatusDot> createState() => _AtemStatusDotState();
}

class _AtemStatusDotState extends State<AtemStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AtemMotion.livePulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.pulsing) {
      AtemMotion.syncLoop(context, _controller, reverse: true);
    }
  }

  @override
  void didUpdateWidget(AtemStatusDot old) {
    super.didUpdateWidget(old);
    if (widget.pulsing != old.pulsing) {
      if (widget.pulsing) {
        AtemMotion.syncLoop(context, _controller, reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = SizedBox.square(
      dimension: widget.size.diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: widget.color, blurRadius: widget.size.blur),
          ],
        ),
      ),
    );

    if (!widget.pulsing) return ExcludeSemantics(child: dot);

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Deckkraft 1 → 0,4 bei gleichzeitigem Schrumpfen auf 0,75.
          final t = _controller.value;
          return Opacity(
            opacity: 1.0 - 0.6 * t,
            child: Transform.scale(scale: 1.0 - 0.25 * t, child: child),
          );
        },
        child: dot,
      ),
    );
  }
}
