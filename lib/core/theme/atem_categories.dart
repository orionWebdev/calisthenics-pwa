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
  /// Bernstein. Kontrast 8,52:1 auf Card.
  static const amber = Color(0xFFF59E0B);

  /// Blau. 4,98:1.
  static const blue = Color(0xFF3B82F6);

  /// Rot. 4,86:1.
  static const red = Color(0xFFEF4444);

  /// Orange. 6,53:1.
  static const orange = Color(0xFFF97316);

  /// Türkis. 7,35:1.
  static const teal = Color(0xFF14B8A6);

  /// Grün. 8,03:1.
  static const green = Color(0xFF22C55E);

  /// Neutralgrau — für „eigen" und anderes ohne Kategorie. 5,61:1.
  static const grey = Color(0xFF8E8E93);

  /// Die Fläche zu einer Kategoriefarbe.
  static Color surface(Color color) => color.withValues(alpha: 0.20);

  /// Der Rand zu einer Kategoriefarbe.
  static Color border(Color color) => color.withValues(alpha: 0.30);
}
