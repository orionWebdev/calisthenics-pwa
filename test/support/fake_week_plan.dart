import 'dart:async';

import 'package:atem/features/planning/domain/week_plan.dart';
import 'package:atem/features/planning/domain/week_plan_repository.dart';

/// Die Woche im Speicher — verhält sich wie Firestore, so weit es für
/// Board 19 zählt: Jeder Schreibvorgang erscheint sofort im Strom; [reject]
/// lässt den Server ablehnen, [denied] das Lesen scheitern, [hang] ewig
/// laden.
class FakeWeekPlanRepository implements WeekPlanRepository {
  FakeWeekPlanRepository({
    WeekPlan initial = WeekPlan.empty,
    this.denied = false,
    this.hang = false,
  }) : _plan = initial;

  WeekPlan _plan;
  bool reject = false;
  final bool denied;
  final bool hang;

  final writes = <Map<String, Object?>>[];
  final _changes = StreamController<WeekPlan>.broadcast();

  WeekPlan get plan => _plan;

  @override
  Stream<WeekPlan> watch(String userId) async* {
    if (hang) await Completer<void>().future;
    if (denied) throw StateError('PERMISSION_DENIED');
    yield _plan;
    yield* _changes.stream;
  }

  @override
  Future<void> write(String userId, Map<String, Object?> writes) async {
    this.writes.add(writes);
    if (reject) throw StateError('PERMISSION_DENIED');
    final data = _stored(_plan);
    for (final e in writes.entries) {
      final parts = e.key.split('.');
      var node = data;
      for (final p in parts.take(parts.length - 1)) {
        node = (node[p] ??= <String, Object?>{}) as Map<String, Object?>;
      }
      if (e.value == null) {
        node.remove(parts.last);
      } else if (e.value is Map) {
        node[parts.last] = {...(e.value! as Map).cast<String, Object?>()};
      } else {
        node[parts.last] = e.value;
      }
    }
    data['updatedAt'] = DateTime(2026, 9, 23, 9);
    _plan = WeekPlan.fromStored(data);
    _changes.add(_plan);
  }

  static Map<String, Object?> _stored(WeekPlan p) => {
        'a': {
          'entries': {for (final e in p.a.values) e.id: e.toStored()},
        },
        'b': {
          'entries': {for (final e in p.b.values) e.id: e.toStored()},
        },
      };
}
