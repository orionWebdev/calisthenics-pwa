import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';

/// Eine Spur mit Füllung in der **Farbe ihrer Zone**.
///
/// Cyan, Grün, Gelb, Orange, Rot — Zone 1 bis 5. Das Board 16 wollte hier ein
/// einziges Material (Entscheidung 7), weil eine Skala von Grün nach Rot ein
/// Urteil ist; der Nutzer hat sich am 21.09.2026 für die Farben entschieden.
/// Was bleibt: **Farbe trägt nichts allein.** Neben jeder Spur stehen Name,
/// bpm-Bereich und Minuten, und die Verteilung ist auch bei Farbfehlsichtigkeit
/// vollständig lesbar. Kein Wort nennt eine Zone hoch, gut oder zu viel.
///
/// Die Farbe ist **Fläche, nie Text**: Diese Spur trägt keine Schrift.
///
/// ## Bewegung
///
/// Die Füllung wächst von 0 auf ihre Breite — alle fünf gleichzeitig, gleiche
/// Dauer (420 ms, `easeOutQuart`), einmal beim ersten Zeigen. Ändert sich der
/// Wert später (neue Grenzen), wandert sie von dort, wo sie steht. Bei
/// reduzierter Bewegung steht sie sofort am Ziel.
class ZoneTrack extends StatelessWidget {
  const ZoneTrack({
    super.key,
    required this.zone,
    required this.fraction,
    this.height = 10,
    this.duration = const Duration(milliseconds: 420),
  });

  /// Welche Zone die Spur trägt, 1 bis 5 — bestimmt die Farbe.
  final int zone;

  /// 0 bis 1 — der Anteil an der aufgezeichneten Zeit.
  final double fraction;
  final double height;

  /// Wie lange die Füllung braucht. Im Grenzen-Blatt 120 ms: Dort ist sie
  /// eine Rückmeldung auf einen Tipp, keine Einführung.
  final Duration duration;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction.clamp(0.0, 1.0)),
          duration: AtemMotion.reduced(context) ? Duration.zero : duration,
          curve: Curves.easeOutQuart,
          builder: (context, value, _) => LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Das Board nennt #14161F. Gemeint ist das Spur-Token
                  // `track` (#16161F): Ein Zwischenton daneben wäre genau die
                  // „vierte Farbebene", die es nicht geben darf.
                  color: AtemColors.track,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: constraints.maxWidth * value,
                    height: height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AtemColors.zone(zone),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
