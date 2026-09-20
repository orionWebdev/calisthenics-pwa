import 'package:flutter/widgets.dart';

/// Die Zusammenführung als Bewegung (Board 15, B6) — **drei Phasen, 420 ms**.
///
/// ## Warum sie orchestriert ist und nicht verstreut
///
/// Es ist die einzige Bewegung im Modul, die etwas behauptet: *zwei Dinge
/// werden eins.* Drei unabhängige Übergänge, die zufällig gleichzeitig
/// liefen, behaupteten nichts — sie sähen aus wie drei Dinge, die sich
/// ändern. Deshalb eine Zeitachse, drei Abschnitte, ein Ziel.
///
/// ## Was die Phasen tun
///
/// 1. **Sammeln, 0–140 ms.** Die beiden Zeilen rücken 6 dp aufeinander zu —
///    je 3 dp, als reine Malverschiebung. Alles andere in der Liste weicht
///    nicht: Die Zeilen behalten ihre Höhe, also verschiebt sich nichts
///    darunter.
/// 2. **Verschmelzen, 140–320 ms.** Die Uhr-Zeile fällt auf Höhe 0 und
///    blendet aus. Hier — und nur hier — rückt die Liste darunter nach, und
///    zwar gleitend über 180 ms statt in einem Sprung.
/// 3. **Setzen, 320–420 ms.** Der Herkunftspunkt stellt sich von „gefüllt"
///    auf „Ring mit Kern" um. Danach Ruhelage, kein Nachpulsen.
///
/// ## Abweichung vom Board, ausdrücklich
///
/// Das Board schreibt zu Phase 2: „die obere wächst um exakt dieselbe Höhe —
/// die Liste darunter bewegt sich kein Pixel." Das geht nicht auf: Am Ende
/// steht **eine** Zeile normaler Höhe, nicht eine doppelt hohe. Zwei Zeilen
/// werden zu einer, also muss die Liste um genau eine Zeilenhöhe nachrücken.
/// Gewählt ist deshalb die Lesart, die der Leitsatz trägt: Nichts springt.
/// Das Nachrücken ist die Bewegung der zweiten Phase selbst, keine Reflow
/// hinterher.
class AtemMergeMotion {
  const AtemMergeMotion._();

  static const duration = Duration(milliseconds: 420);

  /// Bei reduzierter Bewegung entfällt die Choreografie vollständig: Der
  /// Endzustand blendet in 120 ms ein, und was geschehen ist, sagt die
  /// Meldung in Worten. Eine halb eingefrorene Fassung wäre schlimmer als
  /// keine — sie behauptete dann nur noch die Hälfte.
  static const reducedDuration = Duration(milliseconds: 120);

  /// Wie weit die beiden Zeilen aufeinander zu rücken — **je** Zeile.
  static const approach = 3.0;

  static const _gather = Interval(0, 140 / 420, curve: Curves.easeOut);
  static const _fuse = Interval(140 / 420, 320 / 420, curve: Curves.easeInOut);
  static const _settle = Interval(320 / 420, 1, curve: Curves.easeOut);

  /// Phase 1 — 0 bis 1 über die ersten 140 ms.
  static double gather(double t) => _gather.transform(t);

  /// Phase 2 — 0 bis 1 zwischen 140 und 320 ms.
  static double fuse(double t) => _fuse.transform(t);

  /// Phase 3 — 0 bis 1 zwischen 320 und 420 ms.
  static double settle(double t) => _settle.transform(t);
}

/// Die Uhr-Zeile, während sie in die App-Zeile läuft.
///
/// [towards] ist `1`, wenn die App-Zeile **unter** ihr liegt, und `-1`, wenn
/// darüber. Die Reihenfolge steht nicht fest: Eine Uhr-Einheit, die wenige
/// Minuten vor der App-Einheit beginnt, steht in der Liste davor.
class AtemMergingWatchRow extends StatelessWidget {
  const AtemMergingWatchRow({
    super.key,
    required this.animation,
    required this.towards,
    required this.child,
  });

  final Animation<double> animation;
  final double towards;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (context, inner) {
          final t = animation.value;
          final left = 1 - AtemMergeMotion.fuse(t);
          return ClipRect(
            child: Align(
              // Aufgezehrt wird die Zeile **von der Seite her, an der die
              // andere liegt**: Liegt die App-Zeile darunter, bleibt der
              // Kopf stehen und der Fuss verschwindet zuerst.
              alignment:
                  towards > 0 ? Alignment.topCenter : Alignment.bottomCenter,
              // Die Höhe ist das, was die Liste darunter spürt — deshalb
              // steht hier Phase 2 und nur sie. Phase 1 ist reine Malerei.
              heightFactor: left,
              child: Opacity(
                opacity: left,
                child: Transform.translate(
                  offset: Offset(
                      0,
                      AtemMergeMotion.approach *
                          AtemMergeMotion.gather(t) *
                          towards),
                  child: inner,
                ),
              ),
            ),
          );
        },
        child: child,
      );
}
