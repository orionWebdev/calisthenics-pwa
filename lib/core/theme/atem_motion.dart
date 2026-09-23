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

  // Dauerschleifen gibt es seit Board 18b nur noch zwei: die Aurora
  // (dAurora) und das Ladeskelett. Live-Puls, Markenflackern, CTA-Puls,
  // Sitzungspunkt und der Ruhepuls der Gewichtskurve sind gefallen.

  static const curve = Curves.easeOutCubic;

  // --- Die Bewegungsgrammatik (Board 18b, F) ---------------------------------
  //
  // Acht Kurven, je eine Bedeutung. Wer eine neue Bewegung baut, wählt die
  // Kurve nach dem, was sie sagt — nicht nach dem, was schön aussieht.

  /// Gedrückt, Farbwechsel, Querblenden.
  static const press = Curves.easeOut;

  /// Alles, was ausklingt: Bloom, Scan, Segment-Schieber, Aufklappen, Ring.
  static const settle = Cubic(0.22, 1, 0.36, 1);

  /// Kern, Häkchen-Ecke, Kurvenpunkt, Rücksprung — der Überschwinger heisst
  /// „du".
  static const pop = Cubic(0.34, 1.56, 0.64, 1);

  /// Striche, die sich ziehen: Häkchen, Kurvensegment.
  static const draw = Cubic(0.65, 0, 0.35, 1);

  /// Licht, das eine Strecke zurücklegt: Lichtkante, Titelglanz.
  static const travel = Cubic(0.45, 0, 0.2, 1);

  /// Eintrittskaskade, Einfügen mehrerer Neuer, Blatt.
  static const enter = Cubic(0.33, 1, 0.68, 1);

  /// Zuklappen, Entfernen — Wegfallendes nur bemerkbar.
  static const exit = Cubic(0.4, 0, 1, 1);

  /// Die Aurora — die einzige dekorative Schleife der App.
  static const drift = Curves.easeInOutSine;

  static const dPress = Duration(milliseconds: 200);
  static const dKern = Duration(milliseconds: 220);
  static const dCorner = Duration(milliseconds: 380);
  static const dCheckStroke = Duration(milliseconds: 360);
  static const dRunnerCheck = Duration(milliseconds: 240);
  static const dBloom = Duration(milliseconds: 620);
  static const dCtaBloom = Duration(milliseconds: 420);
  static const dScan = Duration(milliseconds: 760);

  /// Der Scan startet so viel später, wenn ein Bloom derselben Handlung
  /// läuft — zwei Orte, nacheinander (Board 18b, Lichtbudget 01).
  static const dScanAfterBloom = Duration(milliseconds: 280);
  static const dEdge = Duration(milliseconds: 1200);
  static const dSheen = Duration(milliseconds: 1400);
  static const dSheenDelay = Duration(milliseconds: 250);
  static const dFlicker = Duration(milliseconds: 320);
  static const dOpen = Duration(milliseconds: 320);
  static const dCloseFade = Duration(milliseconds: 120);
  static const dCloseShrink = Duration(milliseconds: 240);
  static const dOff = Duration(milliseconds: 160);
  static const dSegment = Duration(milliseconds: 240);
  static const dPointRing = Duration(milliseconds: 700);
  static const dAurora = Duration(seconds: 16);

  /// Dieselbe Art binnen dieses Fensters erneut ausgelöst → leise Stufe.
  static const tempoWindow = Duration(milliseconds: 700);

  /// Erscheinen gilt als Folge einer Handlung, wenn es so kurz danach kommt.
  static const causalWindow = Duration(milliseconds: 1000);

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
