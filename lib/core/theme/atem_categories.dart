import 'package:flutter/widgets.dart';

/// Die gedämpfte Kategoriepalette — **unterhalb der Marke**.
///
/// ## Warum nicht Neon
///
/// Magenta ist Aktion, Cyan sind Daten. Zehn Muskelgruppen in Markenfarben
/// würden jede Liste anschreien und den CTA entwerten. Diese Töne bilden eine
/// eigene Klassifikationsschicht: laut genug zum Sortieren, leise genug, um der
/// Marke nicht ins Wort zu fallen. Übernommen aus der Vorgänger-App, wo sie
/// sich über Jahre bewährt haben.
///
/// ## Das Rezept
///
/// Jede Farbe wird dreifach benutzt und **nie anders**:
///
/// | Rolle | Deckkraft |
/// |---|---|
/// | Fläche | 20 % |
/// | Rand | 30 % |
/// | Text und Symbol | voll |
///
/// ## Zwei Töne fehlen mit Absicht
///
/// **Navy `#1e3a8a`** stand in der Vorgänger-App für „Laufen" — auf schwarzem
/// Grund sind das **1,77:1**, also unlesbar. Er ist nicht ersetzt, sondern
/// ersatzlos gestrichen: Der eigentliche Fehler war, der Sportart überhaupt
/// eine Farbe zu geben. Typ und Gerät bleiben graue Schrift.
///
/// **Violett `#8b5cf6`** liegt mit **4,32:1** auf Card unter der Grenze von
/// 4,5:1. „Nur für große Schrift" wäre eine Sonderregel mit Fußnote, und Chips
/// sind 11 sp. Lieber ein Ton weniger.
abstract final class AtemCategories {
  // ---------------------------------------------------------------- Muskeln
  //
  // Die tatsächlichen Muskelfarben der Vorgänger-App, aus
  // `css/views/exercise-cards.css`. Hellere Töne als die Zonen- und
  // Schwierigkeitsfarben, die anderswo in derselben Datei stehen — und darauf
  // kommt es an: **Alle neun halten den Kontrastvertrag auf jeder Fläche.**
  // Der schlechteste Wert liegt bei 6,33:1 auf Raised.
  //
  // Deshalb braucht es hier keine Zusammenlegung zu Regionen: Jeder Muskel,
  // den die Vorgänger-App unterscheidet, bekommt seine eigene Farbe.

  /// Brust. 6,91:1 auf Card.
  static const chest = Color(0xFFF472B6);

  /// Rücken. 7,20:1.
  static const back = Color(0xFF60A5FA);

  /// Schultern. 6,72:1.
  static const shoulders = Color(0xFFA78BFA);

  /// Arme, allgemein. 8,52:1.
  static const arms = Color(0xFFF59E0B);

  /// Bizeps. 10,96:1.
  static const biceps = Color(0xFFFBBF24);

  /// Trizeps. 7,44:1.
  static const triceps = Color(0xFFE879F9);

  /// Core. 9,52:1.
  static const core = Color(0xFF34D399);

  /// Beine. 8,09:1.
  static const legs = Color(0xFFFB923C);

  /// Waden. 9,83:1.
  static const calves = Color(0xFF2DD4BF);

  /// Neutralgrau — für „eigen" und anderes ohne Kategorie. 5,61:1.
  static const grey = Color(0xFF8E8E93);

  /// Die Fläche zu einer Kategoriefarbe.
  static Color surface(Color color) => color.withValues(alpha: 0.20);

  /// Der Rand zu einer Kategoriefarbe.
  static Color border(Color color) => color.withValues(alpha: 0.30);
}
