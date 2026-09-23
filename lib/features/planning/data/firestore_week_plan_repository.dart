import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/week_plan.dart';
import '../domain/week_plan_repository.dart';

/// `userProfiles/{uid}/planning/week` in Firestore.
///
/// Wie die Trainingsangaben: `set` mit `merge`, genau die Pfade einer
/// Handlung, `updatedAt` immer. Verschieben schreibt
/// `a.entries.<id>.weekday` und sonst nichts (Board 19, Schreibregel 1).
class FirestoreWeekPlanRepository implements WeekPlanRepository {
  FirestoreWeekPlanRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db
      .collection('userProfiles')
      .doc(uid)
      .collection('planning')
      .doc('week');

  @override
  Stream<WeekPlan> watch(String userId) =>
      _doc(userId).snapshots().map((snap) {
        final data = snap.data();
        if (data == null) return WeekPlan.empty;
        return WeekPlan.fromStored(_dates(data) as Map<String, Object?>);
      });

  @override
  Future<void> write(String userId, Map<String, Object?> writes) {
    if (writes.isEmpty) return Future.value();
    final data = <String, Object?>{};
    for (final e in writes.entries) {
      _put(data, e.key, e.value ?? FieldValue.delete());
    }
    data['updatedAt'] = FieldValue.serverTimestamp();
    return _doc(userId).set(data, SetOptions(merge: true));
  }

  static void _put(Map<String, Object?> into, String path, Object? value) {
    final parts = path.split('.');
    var node = into;
    for (final p in parts.take(parts.length - 1)) {
      node = (node[p] ??= <String, Object?>{}) as Map<String, Object?>;
    }
    node[parts.last] = value;
  }

  static Object? _dates(Object? node) => switch (node) {
        Timestamp() => node.toDate(),
        Map() => {for (final e in node.entries) '${e.key}': _dates(e.value)},
        List() => [for (final v in node) _dates(v)],
        _ => node,
      };
}
