import 'weight_entry.dart';
import 'weight_series.dart';

/// Liest und schreibt die Gewichtsreihe eines Kontos.
///
/// ## Warum eine eigene Sammlung und kein Feld mehr im Profil
///
/// Das Profil führt genau **einen** `bodyWeight`-Wert, überschreibbar und ohne
/// Vergangenheit. Eine Kurve braucht eine Reihe, und eine Reihe in einem Feld
/// wäre eine Liste in einem Dokument: Sie wächst unbegrenzt, lässt sich nicht
/// nach Zeitraum abfragen und wird bei jedem Eintrag ganz neu geschrieben.
///
/// Die Reihe liegt deshalb in `userProfiles/{uid}/bodyWeights/{yyyy-MM-dd}` —
/// unter dem Profil, weil sie dazugehört, und mit dem Datum als Kennung, weil
/// damit „ein Tag, ein Wert" keine Regel im Code mehr ist, sondern die Form
/// der Daten.
abstract interface class WeightRepository {
  Stream<WeightSeries> watch(String userId);

  Future<WeightSeries> fetch(String userId);

  /// Legt an oder ersetzt — beides derselbe Vorgang, weil die Kennung das
  /// Datum ist. Ein zweiter Eintrag am selben Tag ist nie ein zweiter Punkt.
  Future<void> save(String userId, WeightEntry entry);

  Future<void> delete(String userId, DateTime day);
}
