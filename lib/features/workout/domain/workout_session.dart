import 'package:flutter/widgets.dart';

import '../../../theme/app_theme.dart';

/// Satz-Typ. Tap auf den Chip zykliert W → N → D → F.
enum SetType {
  warmup('W', AtemColors.cyan),
  normal('N', AtemColors.textPrimary),
  dropset('D', AtemColors.violet),
  failure('F', AtemColors.magenta);

  const SetType(this.label, this.color);

  final String label;
  final Color color;

  SetType get next => switch (this) {
        SetType.warmup => SetType.normal,
        SetType.normal => SetType.dropset,
        SetType.dropset => SetType.failure,
        SetType.failure => SetType.warmup,
      };
}

@immutable
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.type,
    required this.previousLabel,
    required this.weight,
    required this.reps,
    this.done = false,
  });

  final String id;
  final SetType type;

  /// Referenz aus der Historie, z. B. „80 kg × 10". „—" wenn keine vorliegt.
  final String previousLabel;

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
      previousLabel: previousLabel,
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
    required this.recordLabel,
    required this.sets,
  });

  final String id;
  final String name;

  /// Muskelgruppen als Chips, z. B. ['QUADS', 'GLUTES'].
  final List<String> muscles;

  /// PR-/1RM-Referenz, z. B. „PR 140 KG".
  final String recordLabel;

  final List<WorkoutSet> sets;

  WorkoutExercise copyWith({List<WorkoutSet>? sets}) => WorkoutExercise(
        id: id,
        name: name,
        muscles: muscles,
        recordLabel: recordLabel,
        sets: sets ?? this.sets,
      );
}

/// Die laufende Trainingseinheit.
@immutable
class ActiveWorkout {
  const ActiveWorkout({
    required this.sessionId,
    required this.title,
    required this.exercises,
    this.notes = '',
    this.defaultRestSeconds = 90,
  });

  final String sessionId;
  final String title;
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
      title: title,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      defaultRestSeconds: defaultRestSeconds,
    );
  }
}
