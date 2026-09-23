import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Ein Bereich, der aufklappt — mit Höhenanimation oder, bei reduzierter
/// Bewegung, **hart**.
///
/// ## Warum nicht einfach `AnimatedSize`
///
/// Mit einer Dauer von null wirft `AnimatedSize` beim Umbauen eine Assertion
/// („mutated in its own performLayout"): Der Controller schliesst mitten im
/// Layout ab. Das ist genau der Fall „Animationen abgeschaltet" — der eine,
/// den die Barrierefreiheit verlangt. Deshalb steht hier der harte Wechsel
/// als eigener Zweig, nicht als Animation der Länge null (Board 16, Bewegungs-
/// tabelle: „harter Wechsel, keine Höhenanimation").
class AtemDisclosure extends StatelessWidget {
  const AtemDisclosure({
    super.key,
    required this.open,
    required this.child,
    this.duration = AtemMotion.dOpen,
    this.curve = AtemMotion.settle,
  });

  final bool open;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final content = open ? child : const SizedBox(width: double.infinity);
    if (AtemMotion.reduced(context)) return content;
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: Alignment.topCenter,
      child: content,
    );
  }
}
