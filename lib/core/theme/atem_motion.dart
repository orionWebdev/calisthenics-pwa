import 'package:flutter/widgets.dart';

/// Bewegungs-Token und die Steuerung dekorativer Animationen.
///
/// Siehe `docs/contracts/01-accessibility.md`, Regel R8: Dekorative
/// Dauerschleifen respektieren die Systemeinstellung „Animationen reduzieren".
///
/// Das ist nicht nur Rücksicht auf Nutzer mit vestibulären Beschwerden — es ist
/// die Voraussetzung dafür, dass `pumpAndSettle()` in Tests überhaupt
/// terminiert. Ein `AnimationController` mit `..repeat()` kommt sonst nie zur
/// Ruhe und lässt jeden Test in den Timeout laufen.
abstract final class AtemMotion {
  // --- Rohwerte -------------------------------------------------------------

  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);

  /// Score-Count-up beim Laden des Dashboards.
  static const countUp = Duration(milliseconds: 1400);

  /// Dauerschleifen aus den Design-Referenzen.
  static const brandDotFlicker = Duration(milliseconds: 2600);
  static const livePulse = Duration(milliseconds: 1800);
  static const buttonGlowPulse = Duration(milliseconds: 2200);

  /// Ruhepuls des jüngsten Punkts einer Kurve (Board 14, G).
  ///
  /// Deckkraft und Radius eines Rings, **kein Farbwechsel** — die Farbe trägt
  /// dort schon die Herkunft des Punktes.
  static const latestPointPulse = Duration(milliseconds: 2200);
  static const sessionDotPulse = Duration(milliseconds: 1200);

  static const curve = Curves.easeOutCubic;

  // --- Steuerung ------------------------------------------------------------

  /// Hat der Nutzer Animationen abgeschaltet?
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Dauer für eine einmalige Animation. Wird zu [Duration.zero], wenn
  /// Animationen abgeschaltet sind — das Ergebnis erscheint dann sofort.
  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;

  /// Startet oder stoppt eine dekorative Dauerschleife passend zur
  /// Systemeinstellung. Aus `didChangeDependencies` aufrufen — dort ist die
  /// `MediaQuery` verfügbar und Änderungen der Einstellung greifen sofort.
  ///
  /// Bewusst **kein** `Duration.zero`: Ein Controller mit Dauer null würde bei
  /// `repeat()` unendlich schnell rotieren, also das Gegenteil von Ruhe.
  /// Stattdessen wird die Schleife angehalten und auf einen stabilen Wert
  /// gesetzt.
  static void syncLoop(
    BuildContext context,
    AnimationController controller, {
    bool reverse = false,
    double restingValue = 1.0,
  }) {
    if (reduced(context)) {
      if (controller.isAnimating) controller.stop();
      controller.value = restingValue;
    } else if (!controller.isAnimating) {
      controller.repeat(reverse: reverse);
    }
  }
}
