import 'package:flutter/material.dart';

import 'atem_motion.dart';

/// Der Seitenübergang der App.
///
/// ## Warum nicht Zoom oder Cupertino
///
/// `ZoomPageTransitionsBuilder` skaliert die ganze Seite aus der Mitte heraus
/// und legt dabei einen weissen Schleier darüber — auf einem Grund von
/// `#050507` sieht das aus, als blitze der Bildschirm. Cupertino schiebt von
/// rechts, was eine iOS-Geste beschreibt, die es hier nicht gibt.
///
/// ## Was stattdessen passiert
///
/// Die neue Seite steigt 24 dp und blendet auf; die alte weicht 12 dp nach
/// oben und dimmt auf 40 Prozent, statt zu verschwinden. Der kurze Moment, in
/// dem beide sichtbar sind, ist das, was die Bewegung lesbar macht: Man sieht,
/// **woher** die Seite kommt.
///
/// Beide Kurven sind `easeOutCubic` — schnell heraus, weich hinein. Zurück
/// läuft dieselbe Bewegung rückwärts, es gibt keinen eigenen Rückweg.
class AtemPageTransitionsBuilder extends PageTransitionsBuilder {
  const AtemPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Abgeschaltete Animationen heisst: Ergebnis sofort. Ein Übergang von
    // null Sekunden ist kein Übergang, sondern ein Schnitt.
    if (AtemMotion.reduced(context)) return child;

    final enter = CurvedAnimation(parent: animation, curve: AtemMotion.curve);
    final leave =
        CurvedAnimation(parent: secondaryAnimation, curve: AtemMotion.curve);

    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(enter),
        // Die Seite, die zurückbleibt: leicht nach oben, deutlich gedimmt.
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.4).animate(leave),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0, -0.018),
            ).animate(leave),
            child: child,
          ),
        ),
      ),
    );
  }
}
