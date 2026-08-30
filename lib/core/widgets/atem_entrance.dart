import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Der Auftritt eines Blocks — **steigen und aufblenden, versetzt**.
///
/// ## Warum überhaupt
///
/// Ein Bildschirm, der fertig dasteht, sobald er da ist, sagt nichts darüber,
/// wie er gebaut ist. Läuft er in Stufen ein, liest man die Reihenfolge, bevor
/// man den Inhalt liest: erst die Aussage, dann die Zahlen, dann die Liste.
/// Das ist keine Zierde, sondern die Hierarchie in der Zeit.
///
/// ## Warum so wenig
///
/// 14 dp Weg, 320 ms, 55 ms Versatz je Position — und nach der sechsten
/// Position kein weiterer Versatz mehr. Eine Kaskade, die bis zur zwölften
/// Karte durchzählt, lässt den Bildschirm langsam wirken; ab der sechsten
/// sieht ohnehin niemand mehr hin, weil er scrollen muss, um dort
/// anzukommen.
///
/// Die Bewegung läuft **einmal**, beim ersten Bauen. Sie wiederholt sich nicht
/// beim Scrollen und nicht bei jeder Datenänderung: Ein Wert, der sich ändert,
/// soll auffallen — nicht die Karte, in der er steht.
///
/// Bei abgeschalteten Animationen erscheint der Block sofort und vollständig.
class AtemEntrance extends StatefulWidget {
  const AtemEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.axis = AtemEntranceAxis.up,
  });

  final Widget child;

  /// Position in der Kaskade. Der Versatz wird bei [maxStaggered] gedeckelt.
  final int index;

  final AtemEntranceAxis axis;

  static const _duration = Duration(milliseconds: 320);
  static const _step = Duration(milliseconds: 55);
  static const _distance = 14.0;

  /// Ab hier bekommt keine Position mehr Versatz.
  static const maxStaggered = 6;

  @override
  State<AtemEntrance> createState() => _AtemEntranceState();
}

/// Woher der Block kommt.
enum AtemEntranceAxis {
  /// Von unten — die Vorgabe für gestapelte Blöcke.
  up,

  /// Von rechts — für Zeilen, die seitlich in eine Reihe laufen.
  right,
}

class _AtemEntranceState extends State<AtemEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AtemEntrance._duration,
  );

  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: AtemMotion.curve);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (AtemMotion.reduced(context)) {
      _c.value = 1;
      return;
    }

    final steps = widget.index.clamp(0, AtemEntrance.maxStaggered);
    final delay = AtemEntrance._step * steps;
    if (delay == Duration.zero) {
      _c.forward();
    } else {
      // `forward` nach einer Verzögerung, aber nur wenn der Block dann noch
      // da ist — sonst ruft man auf einem entsorgten Controller.
      Future<void>.delayed(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = switch (widget.axis) {
      AtemEntranceAxis.up => const Offset(0, AtemEntrance._distance),
      AtemEntranceAxis.right => const Offset(AtemEntrance._distance, 0),
    };

    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: offset * (1 - _t.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Nummeriert eine Liste von Blöcken für die Kaskade.
///
/// Spart das Mitzählen an der Aufrufstelle — und damit den häufigsten Fehler
/// dabei, nämlich zwei Blöcke mit demselben Index.
List<Widget> atemEntranceList(List<Widget> children, {int from = 0}) => [
      for (var i = 0; i < children.length; i++)
        AtemEntrance(index: from + i, child: children[i]),
    ];

/// Ein Fortschritt von 0 auf 1, einmal beim ersten Bauen.
///
/// Für Diagramme: Der Balken wächst aus der Grundlinie, die Kurve zeichnet
/// sich von links nach rechts. Das ist keine Zierde — es sagt, in welcher
/// Richtung die Achse läuft, bevor man die Beschriftung gelesen hat.
///
/// Wie [AtemEntrance] läuft es **einmal**. Ein Diagramm, das sich bei jeder
/// Datenänderung neu aufbaut, verdeckt genau die Änderung, die es zeigen soll.
class AtemReveal extends StatefulWidget {
  const AtemReveal({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 620),
    this.delay = Duration.zero,
  });

  /// Bekommt den Fortschritt 0..1.
  final Widget Function(BuildContext context, double t) builder;

  final Duration duration;
  final Duration delay;

  @override
  State<AtemReveal> createState() => _AtemRevealState();
}

class _AtemRevealState extends State<AtemReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: AtemMotion.curve);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (AtemMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        builder: (context, _) => widget.builder(context, _t.value),
      );
}

/// Zeichnet seinen Inhalt einmal von links nach rechts frei.
///
/// Für Diagramme mit einer Zeitachse: Die Kurve erscheint in der Richtung, in
/// der die Zeit läuft. Ein Diagramm, das komplett dasteht, muss man erst
/// lesen, um zu wissen, wo es anfängt.
class AtemSweep extends StatelessWidget {
  const AtemSweep({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => AtemReveal(
        duration: duration,
        builder: (context, t) => ClipRect(
          clipper: _SweepClipper(t),
          child: child,
        ),
      );
}

class _SweepClipper extends CustomClipper<Rect> {
  const _SweepClipper(this.t);

  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_SweepClipper old) => old.t != t;
}
