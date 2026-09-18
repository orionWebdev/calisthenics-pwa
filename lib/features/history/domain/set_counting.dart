import 'training_session.dart';

/// Wie viele Sätze eine Übung in einer Einheit **zählt** — mit Seiten.
///
/// ## Die Regel
///
/// Ein seitengetrennter Satz (`LoggedSet.side` gesetzt) ist Arbeit für **eine**
/// Seite. Drei Curls links und drei rechts sind trainingsseitig drei Sätze
/// für den Bizeps, nicht sechs — sonst zählte eine einseitige Übung doppelt
/// so viel wie dieselbe Übung beidseitig, und die Muskelbalance kippte zu
/// jeder Übung, die man zufällig einseitig macht.
///
///     gezählt = beidseitige Sätze + max(linke Sätze, rechte Sätze)
///
/// Ungleiche Seiten zählen nach der fleissigeren: 3× links, 2× rechts → 3.
/// Die fehlende Seite wird nicht erfunden, der Mehraufwand der einen Seite
/// aber auch nicht verdoppelt.
///
/// **Last und Tonnage bleiben die Summe aller Sätze** — dort ist jede Seite
/// echte bewegte Masse. Diese Regel betrifft nur *Satzzahlen*.
///
/// Für den Bestand bis 18.09.2026 ändert sich nichts: Dort trägt kein Satz
/// eine Seite, also ist `max(0, 0) = 0` und das Ergebnis die bisherige Zahl.
abstract final class SetCounting {
  /// Gezählte Sätze aus [sets], nur die, für die [include] `true` liefert.
  static int count(
    Iterable<LoggedSet> sets, {
    bool Function(LoggedSet set)? include,
  }) {
    var both = 0;
    var left = 0;
    var right = 0;
    for (final set in sets) {
      if (include != null && !include(set)) continue;
      switch (set.side) {
        case null:
          both++;
        case SetSide.left:
          left++;
        case SetSide.right:
          right++;
      }
    }
    return both + (left > right ? left : right);
  }
}
