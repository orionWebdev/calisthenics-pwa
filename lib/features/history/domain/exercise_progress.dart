import 'exercise_history.dart';
import 'training_session.dart';

/// Woran eine Übung gemessen wird.
///
/// Genau **ein** Mass je Übung, gewählt über ihren ganzen Verlauf: Gewicht,
/// sobald je eine Ausführung Zusatzlast trug, sonst Wiederholungen, sonst
/// Haltezeit. Ein Wechsel des Masses innerhalb einer Übung ergäbe Vergleiche
/// zwischen Kilogramm und Wiederholungen — und damit keine.
enum ProgressMeasure { weight, reps, hold }

/// Ein neuer Bestwert: eine Ausführung, die alles davor übertrifft.
class ExerciseProgressEntry {
  const ExerciseProgressEntry({
    required this.exerciseId,
    required this.measure,
    required this.value,
    required this.previousBest,
    required this.date,
  });

  final String exerciseId;
  final ProgressMeasure measure;

  /// Der neue Wert — kg, Wiederholungen oder Sekunden je nach [measure].
  final double value;

  /// Der beste Wert **aller** Ausführungen vor dieser.
  final double previousBest;

  final DateTime date;

  double get delta => value - previousBest;
}

/// „Wo bin ich in den letzten vier Wochen besser geworden?"
///
/// ## Was als Fortschritt zählt
///
/// Eine Ausführung im Fenster, deren Wert den besten Wert aller Ausführungen
/// **davor** übertrifft — echt übertrifft. Gleichstand ist kein Fortschritt,
/// und die erste Ausführung einer Übung auch nicht: Ohne Vorher gibt es kein
/// Besser.
///
/// ## Warum Körpergewicht voll zählt
///
/// Das geschätzte Maximum nach Epley rechnet nur Sätze mit Gewicht. Wer
/// Calisthenics trainiert, sähe dort nie etwas. Hier wird jede Übung an dem
/// gemessen, was sie tatsächlich trägt: Klimmzüge an Wiederholungen,
/// Planks an Sekunden.
///
/// ## Was hier nicht steht
///
/// Kein Urteil über Übungen **ohne** Fortschritt. „Kein neuer Bestwert" ist
/// eine Tatsache, keine Stagnation — die App weiss nicht, was jemand vorhat.
class ExerciseProgress {
  const ExerciseProgress({
    required this.entries,
    required this.windowDays,
    required this.exercisesWithTwoOrMore,
    required this.exercisesCompared,
    required this.sessionsInWindow,
    required this.mostOccurrences,
  });

  /// Ab so vielen Ausführungen **einer** Übung trägt der Block.
  static const minimumOccurrences = 2;

  /// Neueste zuerst. Höchstens ein Eintrag je Übung — der jüngste Bestwert.
  final List<ExerciseProgressEntry> entries;

  final int windowDays;

  /// Übungen mit mindestens zwei Ausführungen im ganzen Bestand.
  final int exercisesWithTwoOrMore;

  /// Übungen, die im Fenster ausgeführt wurden **und** eine frühere
  /// Ausführung zum Vergleich haben — der Nenner von „n Übungen verglichen".
  final int exercisesCompared;

  /// Krafteinheiten mit Übungen im Fenster.
  final int sessionsInWindow;

  /// Die höchste Ausführungszahl einer einzelnen Übung — der Fortschritt zur
  /// Schwelle.
  final int mostOccurrences;

  bool get hasEnough => exercisesWithTwoOrMore > 0;

  /// Zählt ein Satz für die Leistung? Aufwärmsätze nicht — sie sind mit
  /// Absicht leichter und wären sonst ein Rückschritt, den es nie gab.
  static bool countsSet(LoggedSet set) => set.rawType != 'warmup';

  static ProgressMeasure? _measureOf(ExerciseHistory history) {
    var reps = false;
    var hold = false;
    for (final occurrence in history.occurrences) {
      for (final set in occurrence.sets) {
        if (!countsSet(set)) continue;
        if ((set.weight ?? 0) > 0) return ProgressMeasure.weight;
        if ((set.reps ?? 0) > 0) reps = true;
        if ((set.holdSeconds ?? 0) > 0) hold = true;
      }
    }
    if (reps) return ProgressMeasure.reps;
    if (hold) return ProgressMeasure.hold;
    return null;
  }

  static double? _valueOf(
      ExerciseOccurrence occurrence, ProgressMeasure measure) {
    double? best;
    for (final set in occurrence.sets) {
      if (!countsSet(set)) continue;
      final value = switch (measure) {
        ProgressMeasure.weight => set.weight,
        ProgressMeasure.reps => set.reps?.toDouble(),
        ProgressMeasure.hold => set.holdSeconds?.toDouble(),
      };
      if (value == null || value <= 0) continue;
      if (best == null || value > best) best = value;
    }
    return best;
  }

  static ExerciseProgress compute(
    List<TrainingSession> sessions,
    DateTime reference, {
    int windowDays = 28,
  }) {
    final refDay = DateTime(reference.year, reference.month, reference.day);
    // Fenster über Kalendertage, nie über Millisekunden: Zwischen zwei
    // lokalen Mitternächten liegen bei der Zeitumstellung 23 oder 25 Stunden.
    final from =
        DateTime(refDay.year, refDay.month, refDay.day - windowDays + 1);
    final end = DateTime(refDay.year, refDay.month, refDay.day + 1);
    bool inWindow(DateTime date) => !date.isBefore(from) && date.isBefore(end);

    final index = ExerciseHistory.index(sessions);
    final entries = <ExerciseProgressEntry>[];
    var withTwo = 0;
    var compared = 0;
    var most = 0;

    for (final history in index.values) {
      if (history.sessionCount > most) most = history.sessionCount;
      if (history.sessionCount < minimumOccurrences) continue;
      withTwo++;

      final measure = _measureOf(history);
      if (measure == null) continue;

      // Älteste zuerst — „davor" heisst dann: alles links vom Punkt.
      final ordered = history.occurrences.reversed.toList();
      double? bestBefore;
      ExerciseProgressEntry? latest;
      var hadComparison = false;

      for (final occurrence in ordered) {
        if (!occurrence.date.isBefore(end)) break;
        final value = _valueOf(occurrence, measure);
        if (value == null) continue;
        if (inWindow(occurrence.date) && bestBefore != null) {
          hadComparison = true;
          if (value > bestBefore) {
            latest = ExerciseProgressEntry(
              exerciseId: history.exerciseId,
              measure: measure,
              value: value,
              previousBest: bestBefore,
              date: occurrence.date,
            );
          }
        }
        if (bestBefore == null || value > bestBefore) bestBefore = value;
      }

      if (hadComparison) compared++;
      if (latest != null) entries.add(latest);
    }

    entries.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : a.exerciseId.compareTo(b.exerciseId);
    });

    final sessionsInWindow = sessions
        .whereType<StrengthSession>()
        .where((s) => s.exercises.isNotEmpty && inWindow(s.date))
        .length;

    return ExerciseProgress(
      entries: entries,
      windowDays: windowDays,
      exercisesWithTwoOrMore: withTwo,
      exercisesCompared: compared,
      sessionsInWindow: sessionsInWindow,
      mostOccurrences: most,
    );
  }
}
