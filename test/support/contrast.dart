import 'dart:math' as math;
import 'dart:ui';

/// WCAG-Kontrastberechnung.
///
/// Bewusst eigenständig statt über `textContrastGuideline`: Dessen eigene
/// Dokumentation nennt das Verfahren „a very naive partitioning of the colors
/// into 'light' and 'dark'". Auf Glow, Blur und Verläufen liefert es falsche
/// Treffer in beide Richtungen. Diese Rechnung ist deterministisch und
/// vollständig — siehe `docs/contracts/01-accessibility.md`, Regel R4.
double _linear(int channel) {
  final c = channel / 255;
  return c <= 0.03928
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4) as double;
}

double relativeLuminance(Color c) {
  return 0.2126 * _linear((c.r * 255).round()) +
      0.7152 * _linear((c.g * 255).round()) +
      0.0722 * _linear((c.b * 255).round());
}

/// Kontrastverhältnis zweier deckender Farben, 1.0 bis 21.0.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// WCAG AA für Fließtext.
const aaNormalText = 4.5;

/// WCAG AA für großen Text: ab 18 sp, oder ab 14 sp fett.
const aaLargeText = 3.0;
