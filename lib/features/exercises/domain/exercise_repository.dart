import 'exercise.dart';
import 'exercise_draft.dart';

/// Zugriff auf den Übungsbestand.
abstract interface class ExerciseRepository {
  /// Alle Übungen: kuratierte und eigene, zusammengeführt und nach Namen
  /// sortiert.
  ///
  /// Die kuratierten sind für alle gleich und ändern sich fast nie; die eigenen
  /// gehören einem Konto. Beide werden hier zu **einer** Liste — die
  /// Unterscheidung interessiert nur die Anzeige, nicht die Suche.
  Stream<List<Exercise>> watchExercises(String userId);

  Future<List<Exercise>> fetchExercises(String userId);

  /// Legt eine eigene Übung an oder überschreibt sie. Liefert die Kennung.
  ///
  /// Schreibt **immer** nach `exercises`, nie nach `exercises_curated` — die
  /// Regeln lassen dort niemanden schreiben, und eine kuratierte Übung gehört
  /// allen gleichermaßen. Wer eine ändern will, legt eine eigene Fassung an;
  /// das ist ein Anlegen, kein Bearbeiten.
  Future<String> saveExercise(ExerciseDraft draft);

  /// Löscht eine eigene Übung.
  ///
  /// **Ohne Rückgängig, und das ist eine Entscheidung.** Eine gelöschte Übung
  /// hängt in Plänen, in absolvierten Einheiten und womöglich in mehreren
  /// zugleich. Ein Rückgängig müsste diese Kette zuverlässig zurückdrehen —
  /// kann es aber nicht, denn zwischen Löschen und Widerruf kann ein Plan
  /// bearbeitet worden sein.
  ///
  /// Ein Rückgängig, das manchmal nicht vollständig zurückdreht, ist schlimmer
  /// als keins: Es verspricht Sicherheit und liefert sie nicht. Stattdessen
  /// sagt die zweite Bestätigung ausdrücklich, dass es endgültig ist.
  Future<void> deleteExercise(String id);
}
