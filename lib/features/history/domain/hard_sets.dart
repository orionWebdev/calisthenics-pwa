import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/muscle.dart';
import 'muscle_balance.dart';
import 'set_counting.dart';
import 'training_session.dart';

/// Harte Sätze einer Muskelgruppe in zwei gleich langen Fenstern.
class HardSetsShare {
  const HardSetsShare({
    required this.muscle,
    required this.current,
    required this.previous,
  });

  final MuscleGroup muscle;

  /// Harte Sätze im aktuellen Fenster.
  final int current;

  /// Harte Sätze im gleich langen Fenster davor.
  final int previous;

  /// Verschiebung in Sätzen. Eine Tatsache, kein Urteil: mehr ist nicht
  /// besser (CLAUDE.md).
  int get shift => current - previous;
}

/// Harte Sätze je Muskelgruppe — Sätze mit Satz-RPE ≥ 7 (`LoggedSet.isHard`).
///
/// ## Warum Sätze statt Tonnage
///
/// Ein Klimmzug ohne Zusatzgewicht bewegt keine Hantel; seine Tonnage hängt
/// am hinterlegten Körpergewicht. Ein harter Satz ist ein harter Satz, egal
/// ob mit Langhantel oder am eigenen Körper — die Zählung behandelt Kraft
/// und Calisthenics gleich.
///
/// ## Grundlage
///
/// Die Satz-RPE ist freiwillig. Deshalb trägt das Ergebnis immer seinen
/// Nenner: [setsTotal] (alle zählbaren Sätze im Fenster) und [setsWithRpe]
/// (davon mit Angabe). Unter [minimumSetsWithRpe] Sätzen mit Angabe sagt die
/// Zahl nichts — [hasEnough] ist dann `false`.
///
/// Gezählt wird nach [SetCounting] (ein Paar links/rechts ist ein Satz),
/// Aufwärmsätze nie. Die Muskelzuordnung ist [MuscleBalance.musclesOf] —
/// dieselbe wie in der Muskelbalance, keine zweite.
class HardSets {
  const HardSets({
    required this.shares,
    required this.windowDays,
    required this.hardTotal,
    required this.previousHardTotal,
    required this.setsWithRpe,
    required this.setsTotal,
  });

  static const defaultWindowDays = 7;

  /// Ab so vielen Sätzen mit RPE-Angabe im Fenster trägt der Block.
  static const minimumSetsWithRpe = 10;

  static const _warmupType = 'warmup';

  /// Nur Muskeln mit harten Sätzen in einem der beiden Fenster, die meisten
  /// zuerst.
  final List<HardSetsShare> shares;
  final int windowDays;

  /// Harte Sätze im aktuellen Fenster, über alle Übungen.
  ///
  /// **Nicht** die Summe von [shares]: Eine Übung, die auf zwei Muskeln bucht,
  /// zählt hier einmal.
  final int hardTotal;
  final int previousHardTotal;

  /// Sätze mit RPE-Angabe im aktuellen Fenster.
  final int setsWithRpe;

  /// Alle zählbaren Sätze im aktuellen Fenster.
  final int setsTotal;

  bool get hasEnough => setsWithRpe >= minimumSetsWithRpe;

  static bool _counts(LoggedSet set) =>
      !set.isEmpty && set.rawType != _warmupType;

  static HardSets compute(
    List<TrainingSession> sessions,
    List<Exercise> exercises,
    DateTime reference, {
    int windowDays = defaultWindowDays,
  }) {
    // Lokale Tagesgrenzen über den Kalender, nie über Millisekunden — sonst
    // verschiebt eine Zeitumstellung das Fenster um einen Tag.
    final refDay = DateTime(reference.year, reference.month, reference.day);
    final currentFrom =
        DateTime(refDay.year, refDay.month, refDay.day - (windowDays - 1));
    final previousFrom =
        DateTime(refDay.year, refDay.month, refDay.day - (2 * windowDays - 1));

    final byId = {for (final e in exercises) e.id: e};
    final current = <MuscleGroup, int>{};
    final previous = <MuscleGroup, int>{};
    var hardTotal = 0;
    var previousHardTotal = 0;
    var withRpe = 0;
    var total = 0;

    for (final session in sessions) {
      if (session is! StrengthSession) continue;
      final day =
          DateTime(session.date.year, session.date.month, session.date.day);
      if (day.isAfter(refDay) || day.isBefore(previousFrom)) continue;
      final inCurrent = !day.isBefore(currentFrom);

      for (final logged in session.exercises) {
        final hard = SetCounting.count(logged.sets,
            include: (s) => _counts(s) && s.isHard);

        if (inCurrent) {
          total += SetCounting.count(logged.sets, include: _counts);
          withRpe += SetCounting.count(logged.sets,
              include: (s) => _counts(s) && s.rpe != null);
          hardTotal += hard;
        } else {
          previousHardTotal += hard;
        }

        if (hard == 0) continue;
        final exercise = byId[logged.exerciseId];
        if (exercise == null) continue;
        final target = inCurrent ? current : previous;
        for (final muscle in MuscleBalance.musclesOf(exercise)) {
          target[muscle] = (target[muscle] ?? 0) + hard;
        }
      }
    }

    final shares = [
      for (final muscle in MuscleGroup.filters)
        if ((current[muscle] ?? 0) > 0 || (previous[muscle] ?? 0) > 0)
          HardSetsShare(
            muscle: muscle,
            current: current[muscle] ?? 0,
            previous: previous[muscle] ?? 0,
          ),
    ];
    // Stabil nach Anzahl, bei Gleichstand die feste Reihenfolge der Filter.
    final order = {
      for (var i = 0; i < MuscleGroup.filters.length; i++)
        MuscleGroup.filters[i]: i,
    };
    shares.sort((a, b) {
      final byCurrent = b.current.compareTo(a.current);
      if (byCurrent != 0) return byCurrent;
      final byPrevious = b.previous.compareTo(a.previous);
      if (byPrevious != 0) return byPrevious;
      return order[a.muscle]!.compareTo(order[b.muscle]!);
    });

    return HardSets(
      shares: shares,
      windowDays: windowDays,
      hardTotal: hardTotal,
      previousHardTotal: previousHardTotal,
      setsWithRpe: withRpe,
      setsTotal: total,
    );
  }
}
