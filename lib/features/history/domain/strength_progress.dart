/// Kraftverlauf je Übung — geschätztes Einer-Maximum nach Epley.
///
/// ## Was hier gerechnet wird
///
/// Aus jedem Satz mit Gewicht und Wiederholungen folgt eine Schätzung des
/// Gewichts, das man genau einmal bewegen könnte: `w · (1 + n/30)`. Je Übung
/// und Einheit zählt der beste Satz; die Punkte ergeben eine Kurve über die
/// Zeit. Das ist der „Progressive Overload" aus dem Masterplan — eine Zahl,
/// die ihre Grundlage nennt (Gewicht und Wiederholungen des Satzes) und die
/// jeder mit dem Taschenrechner nachprüfen kann.
///
/// ## Was ausdrücklich nicht zählt
///
/// - Sätze ohne Gewicht: Bei Körpergewichtsübungen steht kein Wert im Satz,
///   und das Körpergewicht dazuzurechnen wäre eine Annahme über eine Zahl,
///   die im Satz nicht steht.
/// - Haltesätze (`holdSeconds`): Eine Haltezeit ist keine Wiederholung.
/// - Aufwärmsätze (`rawType == 'warmup'`, der Wert, den der Runner schreibt):
///   Sie sind absichtlich leichter als das, was man kann.
/// - Mehr als [StrengthProgress.maximumReps] Wiederholungen: Oberhalb von
///   etwa zwölf überschätzt Epley systematisch, weil die Formel linear
///   weiterläuft, während die Ausdauerkomponente den Satz trägt.
///
/// Kein Urteil, kein Soll: Die Kurve zeigt, was war, mit Nenner in
/// [ExerciseStrengthSeries.sessionCount].
library;

import 'training_session.dart';

/// Ein Punkt der Kurve: die beste Schätzung einer Einheit.
class StrengthPoint {
  const StrengthPoint({
    required this.date,
    required this.estimatedMax,
    required this.weight,
    required this.reps,
  });

  /// Datum der Einheit.
  final DateTime date;

  /// Geschätztes Einer-Maximum in Kilogramm.
  final double estimatedMax;

  /// Das Gewicht des Satzes, aus dem die Schätzung stammt.
  final double weight;

  /// Die Wiederholungen dieses Satzes.
  final int reps;
}

/// Die Kurve einer Übung — aufsteigend nach Datum, ein Punkt je Einheit.
class ExerciseStrengthSeries {
  const ExerciseStrengthSeries({
    required this.exerciseId,
    required this.points,
  });

  final String exerciseId;

  /// Aufsteigend nach Datum; bei zwei Einheiten am selben Tag beide.
  final List<StrengthPoint> points;

  /// Der Nenner: Wie viele Einheiten tragen einen gültigen Satz.
  int get sessionCount => points.length;

  /// Die Schätzung der jüngsten Einheit.
  double get latest => points.last.estimatedMax;

  /// Die höchste Schätzung im Verlauf.
  double get best =>
      points.fold(0, (max, p) => p.estimatedMax > max ? p.estimatedMax : max);

  /// Jüngste gegen erste Schätzung, in Kilogramm. `null` mit nur einem Punkt —
  /// ein Vergleich braucht zwei.
  double? get deltaSinceFirst =>
      points.length < 2 ? null : latest - points.first.estimatedMax;
}

abstract final class StrengthProgress {
  /// Ab so vielen Einheiten mit gültigem Satz erscheint eine Übung.
  ///
  /// Der Masterplan nennt fünf: Darunter ist eine Kurve zwei Punkte und eine
  /// Linie dazwischen, und die Linie behauptet einen Verlauf, den es nicht
  /// gibt.
  static const minimumSessions = 5;

  /// Oberhalb ist Epley unzuverlässig; solche Sätze zählen nicht.
  static const maximumReps = 12;

  /// Der Satztyp, den der Runner für Aufwärmsätze schreibt (`SetType.warmup`).
  static const _warmupType = 'warmup';

  /// Epley: `w · (1 + n/30)`. Eine Wiederholung ist das Gewicht selbst.
  static double epley(double weightKg, int reps) =>
      reps <= 1 ? weightKg : weightKg * (1 + reps / 30);

  /// Ob ein Satz in die Schätzung eingeht.
  static bool countsSet(LoggedSet set) {
    final weight = set.weight;
    final reps = set.reps;
    if (weight == null || weight <= 0) return false;
    if (reps == null || reps < 1 || reps > maximumReps) return false;
    if (set.holdSeconds != null) return false;
    if (set.rawType == _warmupType) return false;
    return true;
  }

  static List<ExerciseStrengthSeries> compute(
    List<TrainingSession> sessions, {
    int minimumSessions = minimumSessions,
  }) {
    // Je Übung: Einheit → bester Punkt. Der Schlüssel ist die Einheit, nicht
    // der Tag — zwei Einheiten am selben Tag sind zwei Punkte.
    final byExercise = <String, Map<String, StrengthPoint>>{};

    for (final session in sessions) {
      if (session is! StrengthSession) continue;
      for (final logged in session.exercises) {
        StrengthPoint? best;
        for (final set in logged.sets) {
          if (!countsSet(set)) continue;
          final estimate = epley(set.weight!, set.reps!);
          if (best == null || estimate > best.estimatedMax) {
            best = StrengthPoint(
              date: session.date,
              estimatedMax: estimate,
              weight: set.weight!,
              reps: set.reps!,
            );
          }
        }
        if (best == null) continue;
        final perSession = byExercise.putIfAbsent(logged.exerciseId, () => {});
        // Dieselbe Übung zweimal in einer Einheit: der bessere Satz gewinnt.
        final existing = perSession[session.id];
        if (existing == null || best.estimatedMax > existing.estimatedMax) {
          perSession[session.id] = best;
        }
      }
    }

    final result = <ExerciseStrengthSeries>[];
    for (final entry in byExercise.entries) {
      final points = entry.value.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (points.length < minimumSessions) continue;
      result.add(ExerciseStrengthSeries(
        exerciseId: entry.key,
        points: List.unmodifiable(points),
      ));
    }

    result.sort((a, b) {
      final byCount = b.sessionCount.compareTo(a.sessionCount);
      return byCount != 0 ? byCount : a.exerciseId.compareTo(b.exerciseId);
    });
    return result;
  }
}
