import 'comparison_basis.dart';
import 'training_load.dart';
import 'training_session.dart';

/// Die Kennzahlen einer Einheit, wie sie sich vergleichen lassen.
class SessionFigures {
  const SessionFigures({
    required this.duration,
    required this.load,
    required this.volume,
    required this.sets,
    required this.exercises,
    required this.distanceKm,
  });

  final Duration? duration;

  /// Trainingslast — die Zahl, die auch in ACWR und Form eingeht.
  final double load;

  /// Bewegtes Gewicht. `null` bei Einheiten ohne Satzdaten — **nicht 0**:
  /// „kein Volumen erfasst" und „nichts bewegt" sind verschiedene Aussagen.
  final double? volume;

  final int? sets;
  final int? exercises;
  final double? distanceKm;

  static SessionFigures of(TrainingSession session, LoadContext context) {
    int? sets;
    double? volume;
    int? exercises;

    if (session is StrengthSession && session.exercises.isNotEmpty) {
      exercises = session.exercises.length;
      var countedSets = 0;
      var moved = 0.0;
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          if (set.isEmpty) continue;
          countedSets++;
          final reps = set.reps;
          final weight = set.weight;
          if (reps != null && weight != null) moved += reps * weight;
        }
      }
      sets = countedSets;
      volume = moved;
    }

    return SessionFigures(
      duration: session.duration,
      load: TrainingLoad.of(session, context),
      volume: volume,
      sets: sets,
      exercises: exercises,
      distanceKm: session is CardioSession ? session.distanceKm : null,
    );
  }
}

/// Eine Einheit im Vergleich zu einer früheren.
///
/// ## Warum der Vergleich und nicht der Durchschnitt
///
/// „420 Volumen" sagt niemandem etwas. „420, letztes Mal 380" sagt alles —
/// und zwar ohne eine Bewertung zu behaupten. Ob mehr besser ist, hängt
/// davon ab, was jemand vorhat; die App weiß das nicht und soll es nicht
/// raten. Sie nennt beide Zahlen und lässt den Vergleich beim Leser.
///
/// Ein Durchschnitt über alle früheren Einheiten wäre glatter und weniger
/// nützlich: Er verschweigt, dass die letzte Einheit ein Ausreisser war.
///
/// ## Was „vergleichbar" heisst, steht nicht hier
///
/// Diese Klasse bekommt das Gegenstück gereicht. Ob es die letzte Einheit
/// desselben Plans ist, die letzte mit denselben Übungen oder die letzte
/// derselben Art, ist eine Gestaltungsfrage — und sie hat Folgen: Nur 52 der
/// 136 Einheiten tragen überhaupt eine Plan-Kennung.
///
/// [previousOf] bietet die Suche mit einem austauschbaren Kriterium an, damit
/// die Entscheidung an einer Stelle steht und nicht in der Rechnung steckt.
class SessionComparison {
  const SessionComparison({
    required this.session,
    required this.current,
    this.basis,
    this.reference,
    this.referenceDate,
    this.previous,
    this.medianCount = 0,
  });

  final TrainingSession session;
  final SessionFigures current;

  /// Auf welcher Stufe der Vergleich beruht. `null` heißt: keiner gefunden.
  final ComparisonBasis? basis;

  /// Das Datum des Bezugs — bei Stufe C das der jüngsten im Bündel.
  final DateTime? referenceDate;

  /// Wie viele Einheiten in den Median eingegangen sind. 0 außer bei Stufe C.
  final int medianCount;

  /// Die Einheit, mit der verglichen wird. `null`, wenn es keine gibt — bei
  /// der ersten Einheit eines Plans ist das immer so.
  final TrainingSession? reference;

  final SessionFigures? previous;

  bool get hasReference => previous != null;

  /// Trägt der Vergleich auch Volumen und Sätze?
  bool get comparesVolume => basis?.comparesVolume ?? false;

  /// Tage zwischen den beiden Einheiten.
  int? get daysBetween => referenceDate == null
      ? null
      : session.date.difference(referenceDate!).inDays.abs();

  /// Relative Veränderung, oder `null`, wenn eine Seite fehlt oder die
  /// Bezugsgrösse null ist. **Kein Ersatzwert:** Eine Steigerung von null auf
  /// etwas ist keine Prozentzahl, sondern ein Anfang.
  static double? change(double? from, double? to) {
    if (from == null || to == null || from == 0) return null;
    return (to - from) / from;
  }

  double? get loadChange => change(previous?.load, current.load);
  double? get volumeChange => change(previous?.volume, current.volume);

  /// Sucht die jüngste frühere Einheit, die [matches] erfüllt.
  ///
  /// Bewusst mit gereichtem Kriterium: Die Entscheidung, was vergleichbar
  /// ist, gehört an eine Stelle — nicht in diese Suche.
  static TrainingSession? previousOf(
    TrainingSession session,
    List<TrainingSession> all, {
    required bool Function(TrainingSession candidate) matches,
  }) {
    TrainingSession? best;
    for (final candidate in all) {
      if (candidate.id == session.id) continue;
      // Nur zurück, nie vorwärts: Eine später erfasste Einheit ist kein
      // „letztes Mal", auch wenn sie im selben Plan steht.
      if (!candidate.date.isBefore(session.date)) continue;
      if (!matches(candidate)) continue;
      if (best == null || candidate.date.isAfter(best.date)) best = candidate;
    }
    return best;
  }

  /// Baut den Vergleich nach der Kaskade.
  ///
  /// Bei Stufe C ist der Bezug **kein Datensatz, sondern ein Median** über
  /// die letzten fünf Einheiten derselben Art. Der Median und nicht der
  /// Mittelwert: Eine einzelne Ausreisser-Einheit — vier Stunden Wandern
  /// unter fünf Läufen — verschöbe einen Mittelwert so weit, dass der
  /// Vergleich nichts mehr sagt.
  static SessionComparison forSession(
    TrainingSession session,
    List<TrainingSession> all, {
    LoadContext context = const LoadContext(),
  }) {
    final match = ComparisonResolver.resolve(session, all);
    final current = SessionFigures.of(session, context);

    if (match == null) {
      return SessionComparison(session: session, current: current);
    }

    if (match.reference case final reference?) {
      return SessionComparison(
        session: session,
        current: current,
        basis: match.basis,
        reference: reference,
        referenceDate: reference.date,
        previous: SessionFigures.of(reference, context),
      );
    }

    // Stufe C: Median über Dauer und Last. Volumen und Sätze bleiben leer —
    // sie hängen an den Übungen, und die sind hier gerade nicht vergleichbar.
    final durations = <int>[];
    final loads = <double>[];
    for (final session in match.median) {
      final minutes = session.duration?.inMinutes;
      if (minutes != null) durations.add(minutes);
      loads.add(TrainingLoad.of(session, context));
    }

    return SessionComparison(
      session: session,
      current: current,
      basis: match.basis,
      referenceDate: match.date,
      medianCount: match.median.length,
      previous: SessionFigures(
        duration: durations.isEmpty
            ? null
            : Duration(minutes: _median(durations).round()),
        load: loads.isEmpty ? 0 : _median(loads),
        volume: null,
        sets: null,
        exercises: null,
        distanceKm: null,
      ),
    );
  }

  /// Der Median einer Liste. Bei gerader Anzahl das Mittel der beiden mittleren.
  static double _median(List<num> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle].toDouble();
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static SessionComparison build(
    TrainingSession session,
    TrainingSession? reference, {
    LoadContext context = const LoadContext(),
  }) =>
      SessionComparison(
        session: session,
        current: SessionFigures.of(session, context),
        reference: reference,
        referenceDate: reference?.date,
        previous:
            reference == null ? null : SessionFigures.of(reference, context),
      );
}
