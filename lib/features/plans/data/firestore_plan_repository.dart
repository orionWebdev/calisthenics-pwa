import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/plan.dart';
import '../domain/plan_repository.dart';

class FirestorePlanRepository implements PlanRepository {
  FirestorePlanRepository(this._db);

  final FirebaseFirestore _db;

  static const collection = 'plans';

  Query<Map<String, dynamic>> _query(String userId) =>
      _db.collection(collection).where('userId', isEqualTo: userId);

  @override
  Stream<List<Plan>> watchPlans(String userId) =>
      _query(userId).snapshots().map(_convert);

  @override
  Future<List<Plan>> fetchPlans(String userId) async =>
      _convert(await _query(userId).get());

  List<Plan> _convert(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final plans = <Plan>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = _string(data['name']);
      if (name == null) continue;
      plans.add(Plan(
        id: doc.id,
        name: name,
        icon: _string(data['icon']),
        type: _string(data['type']),
        items: _items(data['items']),
      ));
    }
    plans.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return plans;
  }

  static List<PlanItem> _items(Object? value) {
    if (value is! List) return const [];
    final items = <PlanItem>[];
    for (final entry in value) {
      if (entry is! Map) continue;
      final id = _string(entry['exerciseId']);
      if (id == null) continue;

      final target = entry['target'];
      final fields = target is Map ? target : const {};

      items.add(PlanItem(
        exerciseId: id,
        sets: _int(fields['sets']),
        // Bleibt Text — siehe [PlanItem.reps].
        reps: _string(fields['reps']) ?? _int(fields['reps'])?.toString(),
        holdSeconds: _int(fields['holdSec']),
        restSeconds: _int(entry['restSec']),
      ));
    }
    return items;
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _int(Object? value) => value is num ? value.round() : null;
}
