import 'dart:async';

import 'package:atem/features/planning/domain/training_goal.dart';
import 'package:atem/features/planning/domain/training_goal_repository.dart';

/// Die Trainingsangaben im Speicher — verhält sich wie Firestore, so weit
/// es für Board 18 zählt.
///
/// - Jeder Schreibvorgang erscheint sofort im Strom (lokaler Cache).
/// - [reject]: Der Server lehnt ab — der Strom bleibt beim alten Stand, der
///   Future scheitert. Genau das sieht die App auch bei Firestore.
/// - [denied]: Lesen scheitert (Regeln nicht ausgerollt).
/// - [hang]: Lesen liefert nie etwas — der Ladezustand.
class FakeTrainingGoalRepository implements TrainingGoalRepository {
  FakeTrainingGoalRepository({
    TrainingGoal initial = TrainingGoal.empty,
    this.denied = false,
    this.hang = false,
    this.clock,
  }) : _goal = initial;

  TrainingGoal _goal;
  bool reject = false;
  final bool denied;
  final bool hang;
  final DateTime Function()? clock;

  final writes = <Map<String, Object?>>[];
  final _changes = StreamController<TrainingGoal>.broadcast();

  TrainingGoal get goal => _goal;

  @override
  Stream<TrainingGoal> watch(String userId) async* {
    if (hang) await Completer<void>().future;
    if (denied) throw StateError('PERMISSION_DENIED');
    yield _goal;
    yield* _changes.stream;
  }

  @override
  Future<void> write(
    String userId,
    Map<String, Object?> changes, {
    Map<String, DateTime> answeredAt = const {},
  }) async {
    writes.add(changes);
    if (reject) throw StateError('PERMISSION_DENIED');
    final now = clock?.call() ?? DateTime(2026, 9, 23, 9);
    final fields = {..._goal.fields};
    final at = {..._goal.answeredAt};
    for (final e in changes.entries) {
      if (e.value == null) {
        fields.remove(e.key);
        at.remove(e.key);
      } else {
        fields[e.key] = e.value!;
        at[e.key] = answeredAt[e.key] ?? now;
      }
    }
    _goal = TrainingGoal.fromStored({
      ..._nest(fields),
      'answeredAt': _nest(at),
      'updatedAt': now,
    });
    _changes.add(_goal);
  }

  @override
  Future<void> clear(String userId) async {
    if (reject) throw StateError('PERMISSION_DENIED');
    _goal = TrainingGoal.empty;
    _changes.add(_goal);
  }

  static Map<String, Object?> _nest(Map<String, Object?> flat) {
    final out = <String, Object?>{};
    for (final e in flat.entries) {
      final parts = e.key.split('.');
      var node = out;
      for (final p in parts.take(parts.length - 1)) {
        node = (node[p] ??= <String, Object?>{}) as Map<String, Object?>;
      }
      node[parts.last] = e.value;
    }
    return out;
  }
}
