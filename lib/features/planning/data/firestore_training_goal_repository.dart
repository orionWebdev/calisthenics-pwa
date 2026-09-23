import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/training_goal.dart';
import '../domain/training_goal_repository.dart';

/// `userProfiles/{uid}/planning/goal` in Firestore.
///
/// ## Warum `set` mit `merge` und nicht `update`
///
/// `update` scheitert, solange das Dokument nicht existiert — die erste
/// Antwort überhaupt müsste einen anderen Weg nehmen als jede weitere. `set`
/// mit `merge: true` verschmilzt verschachtelte Maps und nimmt
/// `FieldValue.delete()` an. Ein Weg für alles.
///
/// ## Warum nie das ganze Dokument
///
/// Jede Antwort ist ein eigener Schreibvorgang über genau ihre Pfade (Board
/// 18, Schreibregel 3). Lehnt der Server einen ab, nimmt Firestore genau
/// diesen zurück — nie das Dokument, nie die Antwort, die jemand eine
/// Sekunde vorher gegeben hat.
class FirestoreTrainingGoalRepository implements TrainingGoalRepository {
  FirestoreTrainingGoalRepository(this._db);

  final FirebaseFirestore _db;

  static const profiles = 'userProfiles';
  static const collection = 'planning';
  static const document = 'goal';

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(profiles).doc(uid).collection(collection).doc(document);

  @override
  Stream<TrainingGoal> watch(String userId) =>
      _doc(userId).snapshots().map((snap) {
        final data = snap.data();
        if (data == null) return TrainingGoal.empty;
        return TrainingGoal.fromStored(_dates(data) as Map<String, Object?>);
      });

  @override
  Future<void> write(
    String userId,
    Map<String, Object?> changes, {
    Map<String, DateTime> answeredAt = const {},
  }) {
    if (changes.isEmpty) return Future.value();
    final data = <String, Object?>{};
    for (final e in changes.entries) {
      final set = e.value != null;
      _put(data, e.key, set ? e.value : FieldValue.delete());
      final at = answeredAt[e.key];
      _put(
        data,
        'answeredAt.${e.key}',
        !set
            ? FieldValue.delete()
            : at != null
                ? Timestamp.fromDate(at)
                : FieldValue.serverTimestamp(),
      );
    }
    data['updatedAt'] = FieldValue.serverTimestamp();
    return _doc(userId).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> clear(String userId) => _doc(userId).delete();

  /// Legt `a.b.c` als verschachtelte Map ab.
  static void _put(Map<String, Object?> into, String path, Object? value) {
    final parts = path.split('.');
    var node = into;
    for (final p in parts.take(parts.length - 1)) {
      node = (node[p] ??= <String, Object?>{}) as Map<String, Object?>;
    }
    node[parts.last] = value;
  }

  /// Wandelt jeden [Timestamp] im Baum in ein [DateTime].
  static Object? _dates(Object? node) => switch (node) {
        Timestamp() => node.toDate(),
        Map() => {for (final e in node.entries) '${e.key}': _dates(e.value)},
        List() => [for (final v in node) _dates(v)],
        _ => node,
      };
}
