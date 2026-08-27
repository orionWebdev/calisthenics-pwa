import 'workout_session.dart';
import 'workout_start.dart';

/// Datenquelle und Lebenszyklus einer Trainingseinheit.
///
/// Die Implementierung gehört in `data/` und setzt auf den Repositories der
/// anderen Bereiche auf — Pläne, Übungen, Historie. [loadWorkout] füllt dabei
/// auch die Referenzen aus der Historie: was beim letzten Mal stand und was
/// das schwerste je protokollierte Gewicht ist.
abstract interface class WorkoutRepository {
  /// Baut die Einheit aus dem Plan, mit Zielwerten und Historien-Referenzen.
  ///
  /// Beim freien Training ([WorkoutStart.isFree]) kommt eine **leere** Einheit
  /// zurück, keine erfundene. Übungen kommen im Runner dazu.
  Future<ActiveWorkout> loadWorkout(WorkoutStart start);
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
