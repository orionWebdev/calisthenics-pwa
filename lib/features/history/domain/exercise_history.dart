import 'training_session.dart';

/// Eine Ausführung einer Übung — eine Übung an einem Tag.
class ExerciseOccurrence {
  const ExerciseOccurrence({
    required this.sessionId,
    required this.date,
    required this.sets,
  });

  final String sessionId;
  final DateTime date;

  /// Nur die Sätze mit Inhalt. Leere sind beim Bauen ausgefallen.
  final List<LoggedSet> sets;

  /// Das schwerste Gewicht dieser Ausführung.
  double? get bestWeightKg {
    double? best;
    for (final set in sets) {
      final weight = set.weight;
      if (weight == null) continue;
      if (best == null || weight > best) best = weight;
    }
    return best;
  }

  /// Wiederholungen zusammen. `null`, wenn kein Satz welche trägt — eine
  /// Halteübung hat keine.
  int? get totalReps {
    var total = 0;
    var found = false;
    for (final set in sets) {
      final reps = set.reps;
      if (reps == null) continue;
      total += reps;
      found = true;
    }
    return found ? total : null;
  }

  /// Bewegtes Gewicht. Nur Sätze mit **beidem** zählen — Wiederholungen ohne
  /// Gewicht sind kein Volumen von null, sondern gar kein Volumen.
  double get volume {
    var total = 0.0;
    for (final set in sets) {
      final reps = set.reps;
      final weight = set.weight;
      if (reps == null || weight == null) continue;
      total += reps * weight;
    }
    return total;
  }

  int get setCount => sets.length;
}

/// Was die Historie über **eine** Übung weiß.
///
/// ## Warum das ein eigener Typ ist
///
/// Diese Rechnung gab es schon — versteckt als private Klasse im Repository
/// des Runners, wo sie die letzten Sätze und den Bestwert für die Satzzeilen
/// lieferte. Sobald das Übungsdetail denselben Verlauf zeigt, gäbe es sie
/// zweimal, und zwei Fassungen driften auseinander: Eine zählt leere Sätze
/// mit, die andere nicht.
///
/// ## Was hier **nicht** steht
///
/// Keine Bewertung. Kein „Fortschritt", kein „Stagnation", kein Sollwert.
/// Der Bestand gibt her, was wann gemacht wurde — was das bedeutet, hängt
/// davon ab, was jemand vorhat, und das weiß die App nicht.
class ExerciseHistory {
  const ExerciseHistory({required this.exerciseId, required this.occurrences});

  static const empty = ExerciseHistory(exerciseId: '', occurrences: []);

  final String exerciseId;

  /// **Neueste zuerst.** Die Reihenfolge ist Teil des Vertrags: Der Runner
  /// liest den ersten Eintrag als „letztes Mal".
  final List<ExerciseOccurrence> occurrences;

  bool get isEmpty => occurrences.isEmpty;

  int get sessionCount => occurrences.length;

  DateTime? get lastDate =>
      occurrences.isEmpty ? null : occurrences.first.date;

  DateTime? get firstDate => occurrences.isEmpty ? null : occurrences.last.date;

  /// Die Sätze der jüngsten Ausführung.
  List<LoggedSet> get lastSets =>
      occurrences.isEmpty ? const [] : occurrences.first.sets;

  /// Das schwerste je protokollierte Gewicht.
  double? get recordWeightKg {
    double? best;
    for (final occurrence in occurrences) {
      final weight = occurrence.bestWeightKg;
      if (weight == null) continue;
      if (best == null || weight > best) best = weight;
    }
    return best;
  }

  /// Die Ausführung, in der der Bestwert erreicht wurde — für „wann war das".
  ExerciseOccurrence? get recordOccurrence {
    final record = recordWeightKg;
    if (record == null) return null;
    for (final occurrence in occurrences.reversed) {
      if (occurrence.bestWeightKg == record) return occurrence;
    }
    return null;
  }

  int get totalSets =>
      occurrences.fold(0, (total, o) => total + o.setCount);

  /// Alle Übungen des Bestands auf einmal.
  ///
  /// Einmal über alle Einheiten statt einmal je Übung: Ein Plan mit acht
  /// Einträgen liefe sonst achtmal über 136 Dokumente.
  static Map<String, ExerciseHistory> index(List<TrainingSession> sessions) {
    final byId = <String, List<ExerciseOccurrence>>{};

    // Neueste zuerst — die Reihenfolge der Ausführungen erbt davon.
    final sorted = [...sessions]..sort((a, b) => b.date.compareTo(a.date));

    for (final session in sorted) {
      if (session is! StrengthSession) continue;
      for (final exercise in session.exercises) {
        final sets = [
          for (final set in exercise.sets)
            if (!set.isEmpty) set,
        ];
        // Eine Übung ohne einen einzigen inhaltlichen Satz ist keine
        // Ausführung. Sie zu zählen machte aus „nie gemacht" ein „einmal
        // gemacht, ohne Werte".
        if (sets.isEmpty) continue;

        byId.putIfAbsent(exercise.exerciseId, () => []).add(
              ExerciseOccurrence(
                sessionId: session.id,
                date: session.date,
                sets: sets,
              ),
            );
      }
    }

    return {
      for (final entry in byId.entries)
        entry.key:
            ExerciseHistory(exerciseId: entry.key, occurrences: entry.value),
    };
  }

  /// Eine einzelne Übung. Nie `null` — „nie gemacht" ist ein gültiges
  /// Ergebnis und soll kein Sonderfall an jeder Aufrufstelle sein.
  static ExerciseHistory of(List<TrainingSession> sessions, String exerciseId) =>
      index(sessions)[exerciseId] ??
      ExerciseHistory(exerciseId: exerciseId, occurrences: const []);
}
