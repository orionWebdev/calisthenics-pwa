import 'package:flutter/widgets.dart';


/// Größe eines Statuspunkts.
///
/// **Zwei Größen, nicht vier.** Die Größe hängt an genau einer Sache: der
/// Schriftgröße des begleitenden Labels. Nicht am Kontext, nicht am Gefühl.
/// Damit ist jede künftige Stelle entscheidungsfrei — vorher gab es 4, 4,5, 5
/// und 6 dp ohne erkennbares System.
enum AtemDotSize {
  /// 6 dp — neben labelMicro und labelSmall (12 sp).
  medium(6),

  /// 4 dp — neben labelDeco (10 sp).
  small(4),

  /// 8 dp — in der Snackbar, wo der Punkt allein die Tonlage trägt und
  /// deshalb aus einem Meter Entfernung sichtbar sein muss (Modul 7, Spec).
  large(8);

  const AtemDotSize(this.diameter);
  final double diameter;
}

/// Farbiger Punkt, der einen Zustand anzeigt.
///
/// Skaliert bewusst **nicht** mit der Systemschrift — er ist dekorativ. Sein
/// Zustand steht immer zusätzlich im Text oder in den Semantics des
/// umgebenden Elements.
class AtemStatusDot extends StatelessWidget {
  const AtemStatusDot({
    super.key,
    required this.color,
    this.size = AtemDotSize.medium,
  });

  final Color color;
  final AtemDotSize size;

  // **Flach, ohne Schleife, ohne stehenden Schein** (Board 18b, K2 und G6).
  // Der Live-Puls fiel: Sekunden, die zählen, sagen „läuft" genauer als ein
  // Schein, und sie tun es auch bei „Animationen reduzieren". Ein Punkt mit
  // Glow leuchtete dauernd, ohne auf etwas zu antworten.
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: size.diameter,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      );
}
