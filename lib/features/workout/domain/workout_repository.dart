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
}

/// **Das Speichern liegt bewusst nicht hier.**
///
/// Eine abgeschlossene Einheit gehört in die Historie, nicht zum Runner. Der
/// Runner steuert ein laufendes Workout; was danach im Bestand landet, ist
/// Sache von `features/history`. Die Übersetzung von [ActiveWorkout] in einen
/// `SessionDraft` steht in `application/workout_providers.dart` — sie kennt
/// beide Seiten, weil sie beide Seiten verbinden muss.
///
/// Vorher stand hier ein `saveWorkout`, das in der einzigen Implementierung
/// ein leerer Rumpf war: Jede beendete Einheit ging verloren.
