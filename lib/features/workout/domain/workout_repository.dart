import 'workout_session.dart';

/// Datenquelle und Lebenszyklus einer Trainingseinheit.
///
/// Die Implementierung gehört in `data/` und liest denselben Firestore-Bestand
/// wie die bestehende PWA (`plans`, `sessions`, `workouts`). [loadWorkout]
/// füllt dabei auch `previousLabel` und `recordLabel` aus der Historie.
abstract interface class WorkoutRepository {
  /// Lädt die geplante Einheit inklusive Zielwerten und Historien-Referenzen.
  Future<ActiveWorkout> loadWorkout(String sessionId);

  /// Startet die Einheit und liefert deren Startzeitpunkt.
  Future<DateTime> startSession(String sessionId);

  /// Bricht eine laufende Einheit ab, ohne sie zu speichern.
  Future<void> stopSession(String sessionId);

  /// Speichert die abgeschlossene Einheit.
  Future<void> saveWorkout(
    ActiveWorkout workout, {
    required Duration duration,
  });
}
