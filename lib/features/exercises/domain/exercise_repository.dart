import 'exercise.dart';

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
}
