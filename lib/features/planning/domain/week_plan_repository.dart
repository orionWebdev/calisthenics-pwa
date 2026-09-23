import 'week_plan.dart';

/// Die Woche unter `userProfiles/{uid}/planning/week` (Board 19, L).
abstract interface class WeekPlanRepository {
  /// Der gespeicherte Stand; ohne Dokument [WeekPlan.empty]. Wie bei den
  /// Trainingsangaben ist der Strom zugleich die optimistische Anzeige.
  Stream<WeekPlan> watch(String userId);

  /// Schreibt genau diese Feldpfade (aus [WeekChange.writes]); `null` löscht.
  Future<void> write(String userId, Map<String, Object?> writes);
}
