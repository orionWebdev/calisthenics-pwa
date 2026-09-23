import 'training_goal.dart';

/// Die Trainingsangaben unter `userProfiles/{uid}/planning/goal`.
///
/// Siehe `docs/contracts/04-firestore-schema.md`, § `planning`.
abstract interface class TrainingGoalRepository {
  /// Der gespeicherte Stand; ohne Dokument [TrainingGoal.empty].
  ///
  /// Firestore meldet eigene Schreibvorgänge sofort aus dem lokalen Cache
  /// und nimmt einen abgelehnten von selbst wieder zurück. Der Strom ist
  /// damit zugleich die optimistische Anzeige — es gibt keinen zweiten,
  /// lokalen Stand, der mit ihm auseinanderlaufen kann.
  Stream<TrainingGoal> watch(String userId);

  /// Schreibt genau diese Pfade (aus [TrainingGoal.diff]); `null` löscht.
  ///
  /// Jeder geschriebene Pfad bekommt sein `answeredAt` — die Serverzeit, oder
  /// den Wert aus [answeredAt], wenn ein Rückgängig ein altes Datum
  /// wiederherstellt. Ein gelöschter Pfad verliert es.
  Future<void> write(
    String userId,
    Map<String, Object?> changes, {
    Map<String, DateTime> answeredAt = const {},
  });

  /// Entfernt alle Angaben — das Dokument selbst.
  Future<void> clear(String userId);
}
