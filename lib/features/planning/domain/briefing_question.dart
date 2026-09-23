import 'training_goal.dart';

/// Die acht Fragen des Zielbriefings — **in dieser Reihenfolge**, weil
/// Abhängigkeiten nur nach unten zeigen (Board 18, Entscheidung 21).
///
/// Art → Muster → Anzahl → Tage → mehrmals; Ort und Ziele sind unabhängig;
/// „Jetzt oder Vorhaben" steht am Ende, weil es alles davor einordnet. Keine
/// Antwort verändert eine Frage oberhalb.
enum BriefingQuestion {
  lanes(['modalities']),
  pattern(['weekPattern', 'anchorWeekStart']),
  perWeek([
    'perWeek.strength',
    'perWeek.cardio',
    'perWeekB.strength',
    'perWeekB.cardio',
  ]),
  days(['schedule', 'days.strength', 'days.cardio']),
  multi(['multiPerDay', 'dayparts.strength', 'dayparts.cardio']),
  places(['places']),
  goals(['goals']),
  describes(['describes']);

  const BriefingQuestion(this.paths);

  /// Die Feldpfade, die zu dieser Frage gehören.
  final List<String> paths;

  /// Ob die Frage überhaupt gestellt wird. Anzahl und Tage fragen je Art —
  /// ohne Art gibt es nichts zu fragen.
  bool isAsked(TrainingGoal goal) => switch (this) {
        perWeek || days => goal.lanes != null,
        _ => true,
      };

  /// Ob die Frage beantwortet ist. Eine Teilantwort („Kraft 3×, Cardio
  /// offen") zählt als beantwortet; das Offene steht in der Antwort selbst.
  bool isAnswered(TrainingGoal goal) {
    final fields = goal.fields;
    return paths.any(fields.containsKey);
  }

  /// Nimmt die Antwort zurück — samt allem, was an ihr hängt.
  TrainingGoal clear(TrainingGoal goal) => switch (this) {
        lanes => goal.withLanes(null),
        pattern => goal.withWeekPattern(null),
        perWeek => goal.withoutPerWeek(),
        days => goal.withSchedule(null),
        multi => goal.withMultiPerDay(null),
        places => goal.withPlaces(null),
        goals => goal.withGoals(null),
        describes => goal.withDescribes(null),
      };
}
