import 'package:meta/meta.dart';

/// Satz-Typ. Tap auf den Chip zykliert W → N → D → F.
///
/// Reine Daten: Farbe und Beschriftung leben in
/// `presentation/set_type_ui.dart`. Das Kürzel ist NICHT sprachneutral —
/// „W" für Warmup funktioniert im Deutschen nur zufällig, „Aufwärmsatz" wäre
/// „A". Deshalb kommt es aus dem ARB, nicht aus dem Enum.
enum SetType {
  warmup('warmup'),
  normal('normal'),
  dropset('dropset'),
  failure('failure');

  const SetType(this.wire);

  /// Der Wert, unter dem der Satztyp gespeichert wird. Nie anzeigen — dafür
  /// gibt es das ARB.
  final String wire;

  SetType get next => switch (this) {
        SetType.warmup => SetType.normal,
        SetType.normal => SetType.dropset,
        SetType.dropset => SetType.failure,
        SetType.failure => SetType.warmup,
      };
}

/// Was beim letzten Mal an dieser Stelle stand.
///
/// **Zahlen, kein fertiger Satz.** Vorher hielt der Satz ein `previousLabel`
/// wie „80 kg × 10" — also übersetzten Text mitten in der Domäne, was Vertrag 3
/// verbietet und jede Lokalisierung unmöglich macht. Solange die Attrappe die
/// einzige Quelle war, fiel es nicht auf; sobald die Werte aus dem echten
/// Bestand kommen, müsste die Datenschicht deutsch schreiben.
@immutable
class SetReference {
  const SetReference({this.weightKg, this.reps});

  final double? weightKg;
  final int? reps;

  bool get isEmpty => weightKg == null && reps == null;
}

@immutable
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.type,
    this.previous,
    required this.weight,
    required this.reps,
    this.done = false,
  });

  final String id;
  final SetType type;

  /// Referenz aus der Historie. `null`, wenn es keine gibt.
  final SetReference? previous;

  /// Als Text gehalten: das Feld ist die Wahrheit, solange getippt wird.
  final String weight;
  final String reps;
  final bool done;

  WorkoutSet copyWith({
    SetType? type,
    String? weight,
    String? reps,
    bool? done,
  }) {
    return WorkoutSet(
      id: id,
      type: type ?? this.type,
      previous: previous,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      done: done ?? this.done,
    );
  }

  double? get weightValue =>
      double.tryParse(weight.replaceAll(',', '.').trim());
  int? get repsValue => int.tryParse(reps.trim());
}

@immutable
class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.muscles,
    this.recordWeightKg,
    required this.sets,
  });

  final String id;
  final String name;

  /// Muskelgruppen, roh — die Übersetzung steht in der Oberfläche.
  final List<String> muscles;

  /// Das schwerste je protokollierte Gewicht dieser Übung, in Kilogramm.
  /// `null`, wenn es keins gibt — dann erscheint kein Chip statt „PR —".
  final double? recordWeightKg;

  final List<WorkoutSet> sets;

  WorkoutExercise copyWith({List<WorkoutSet>? sets}) => WorkoutExercise(
        id: id,
        name: name,
        muscles: muscles,
        recordWeightKg: recordWeightKg,
        sets: sets ?? this.sets,
      );
}

/// Die laufende Trainingseinheit.
@immutable
class ActiveWorkout {
  const ActiveWorkout({
    required this.sessionId,
    this.planId,
    this.title,
    required this.exercises,
    this.notes = '',
    this.defaultRestSeconds = 90,
  });

  final String sessionId;

  /// Der Plan, aus dem die Einheit stammt. `null` beim freien Training.
  final String? planId;

  /// Der Planname. `null` beim freien Training — dann setzt die Oberfläche
  /// ihren eigenen Titel, statt einen erfundenen zu tragen.
  final String? title;
  final List<WorkoutExercise> exercises;
  final String notes;
  final int defaultRestSeconds;

  Iterable<WorkoutSet> get allSets => exercises.expand((e) => e.sets);
  int get completedSets => allSets.where((s) => s.done).length;
  int get totalSets => allSets.length;

  /// Bewegtes Gesamtvolumen in kg — Grundlage für den Load-Score.
  double get totalVolume {
    var v = 0.0;
    for (final s in allSets.where((s) => s.done)) {
      final w = s.weightValue, r = s.repsValue;
      if (w != null && r != null) v += w * r;
    }
    return v;
  }

  ActiveWorkout copyWith({
    List<WorkoutExercise>? exercises,
    String? notes,
  }) {
    return ActiveWorkout(
      sessionId: sessionId,
      planId: planId,
      title: title,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      defaultRestSeconds: defaultRestSeconds,
    );
  }
}
