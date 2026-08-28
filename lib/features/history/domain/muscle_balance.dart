import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/muscle.dart';
import 'training_session.dart';

/// Was ein Muskel in einem Zeitraum abbekommen hat.
class MuscleShare {
  const MuscleShare({
    required this.muscle,
    required this.sets,
    required this.volume,
    required this.exerciseIds,
  });

  final MuscleGroup muscle;

  /// Sätze, die auf diesen Muskel gebucht wurden.
  final int sets;

  /// Bewegtes Gewicht. Nur Sätze mit Gewicht **und** Wiederholungen.
  final double volume;

  /// Welche Übungen dazu beigetragen haben.
  final Set<String> exerciseIds;

  bool get isEmpty => sets == 0;
}

/// Wie sich das Training der letzten Wochen auf die Muskeln verteilt.
///
/// ## Die Zuordnung
///
/// Einheit → Übungseintrag → `exerciseId` → Muskelgruppen des Katalogs →
/// Filtermuskel. Ein Satz zählt für **jeden** Muskel der Übung, nicht
/// anteilig: Ein Klimmzug trainiert Rücken und Bizeps, und ihn zu halbieren
/// wäre eine Gewichtung, die niemand hinterlegt hat.
///
/// Damit summieren sich die Sätze über alle Muskeln auf **mehr** als die
/// tatsächlich absolvierten. Das ist kein Fehler, aber es heißt: Die Zahlen
/// sind untereinander vergleichbar und nicht als Anteil eines Ganzen lesbar.
///
/// ## Was die Rechnung nicht erfasst
///
/// Drei Lücken, alle im Bestand belegt und keine davon behebbar:
///
/// * **Einheiten ohne Übungen.** 16 der 63 Krafteinheiten tragen keine.
/// * **Cardio und Regeneration** tragen nie welche — 63 der 136 Einheiten.
/// * **Übungen ohne Muskelangabe.** Eigene Übungen sind oft spärlich.
///
/// Alle drei werden **gezählt und mitgeliefert**, statt stillschweigend zu
/// verschwinden. Eine Balance über die knappe Hälfte des Trainings, die sich
/// als Balance über das Training ausgibt, wäre eine Behauptung.
class MuscleBalance {
  const MuscleBalance({
    required this.shares,
    required this.windowDays,
    required this.sessionsInWindow,
    required this.sessionsCounted,
    required this.sessionsWithoutExercises,
    required this.unresolvedExerciseIds,
  });

  static const defaultWindowDays = 28;

  /// Je Filtermuskel ein Eintrag, in der Reihenfolge von
  /// [MuscleGroup.filters] — also am Körper entlang, nicht nach Größe
  /// sortiert. Wer sucht, denkt an einer Körperregion entlang.
  final List<MuscleShare> shares;

  final int windowDays;

  /// Einheiten im Zeitfenster, alle Arten.
  final int sessionsInWindow;

  /// Davon solche, aus denen tatsächlich etwas gezählt werden konnte.
  final int sessionsCounted;

  /// Krafteinheiten im Fenster ohne einen einzigen Übungseintrag.
  final int sessionsWithoutExercises;

  /// Kennungen, zu denen es keine Übung im Katalog gibt — gelöscht oder
  /// nie vorhanden. Sie fallen aus der Rechnung und werden hier benannt.
  final Set<String> unresolvedExerciseIds;

  bool get isEmpty => shares.every((s) => s.isEmpty);

  /// Wie viel vom Training im Fenster überhaupt abgebildet ist.
  ///
  /// `null`, wenn es nichts abzubilden gab. Sonst zwischen 0 und 1 — und die
  /// Zahl gehört an die Oberfläche: Bei 0,4 ist jede Aussage über Balance
  /// eine Aussage über zwei Fünftel.
  double? get coverage =>
      sessionsInWindow == 0 ? null : sessionsCounted / sessionsInWindow;

  int get totalSets => shares.fold(0, (total, s) => total + s.sets);

  /// Der höchste Satzwert — Bezugsgröße für einen Balken.
  int get maxSets =>
      shares.fold(0, (best, s) => s.sets > best ? s.sets : best);

  static MuscleBalance compute(
    List<TrainingSession> sessions,
    List<Exercise> exercises,
    DateTime reference, {
    int windowDays = defaultWindowDays,
  }) {
    final from = DateTime(
      reference.year,
      reference.month,
      reference.day - (windowDays - 1),
    );

    final byId = {for (final exercise in exercises) exercise.id: exercise};

    final sets = <MuscleGroup, int>{};
    final volume = <MuscleGroup, double>{};
    final contributors = <MuscleGroup, Set<String>>{};
    final unresolved = <String>{};

    var inWindow = 0;
    var counted = 0;
    var withoutExercises = 0;

    for (final session in sessions) {
      if (session.date.isBefore(from)) continue;
      if (session.date.isAfter(reference)) continue;
      inWindow++;

      if (session is! StrengthSession) continue;
      if (session.exercises.isEmpty) {
        withoutExercises++;
        continue;
      }

      var contributed = false;

      for (final logged in session.exercises) {
        final exercise = byId[logged.exerciseId];
        if (exercise == null) {
          unresolved.add(logged.exerciseId);
          continue;
        }

        // Über `filter` gebündelt: Eine Übung mit `quads` zählt auf „Beine",
        // sonst fiele sie aus jeder Darstellung — die Palette kennt neun Töne.
        final muscles = {
          for (final muscle in exercise.displayMuscles) muscle.filter,
        };
        if (muscles.isEmpty) continue;

        final filled = [
          for (final set in logged.sets)
            if (!set.isEmpty) set,
        ];
        if (filled.isEmpty) continue;

        var moved = 0.0;
        for (final set in filled) {
          final reps = set.reps;
          final weight = set.weight;
          if (reps != null && weight != null) moved += reps * weight;
        }

        for (final muscle in muscles) {
          sets[muscle] = (sets[muscle] ?? 0) + filled.length;
          volume[muscle] = (volume[muscle] ?? 0) + moved;
          contributors.putIfAbsent(muscle, () => {}).add(logged.exerciseId);
        }
        contributed = true;
      }

      if (contributed) counted++;
    }

    return MuscleBalance(
      windowDays: windowDays,
      sessionsInWindow: inWindow,
      sessionsCounted: counted,
      sessionsWithoutExercises: withoutExercises,
      unresolvedExerciseIds: unresolved,
      shares: [
        for (final muscle in MuscleGroup.filters)
          MuscleShare(
            muscle: muscle,
            sets: sets[muscle] ?? 0,
            volume: volume[muscle] ?? 0,
            exerciseIds: contributors[muscle] ?? const {},
          ),
      ],
    );
  }
}
