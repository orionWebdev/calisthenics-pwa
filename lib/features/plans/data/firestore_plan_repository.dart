import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/plan.dart';
import '../domain/plan_draft.dart';
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

  @override
  Future<String> savePlan(PlanDraft draft) async {
    final data = _toDocument(draft);
    final id = draft.id;

    if (id == null) {
      final reference = await _db.collection(collection).add(data);
      return reference.id;
    }
    await _db.collection(collection).doc(id).update(data);
    return id;
  }

  @override
  Future<void> deletePlan(String id) =>
      _db.collection(collection).doc(id).delete();

  /// Baut das Dokument für `plans`.
  ///
  /// Der verschachtelte `target`-Aufbau ist der der Vorgänger-App. Er wird
  /// nicht begradigt: Beide Anwendungen lesen dieselben Pläne, und ein flaches
  /// Schema hier machte jeden neuen Plan für die PWA unlesbar.
  ///
  /// **`reps` bleibt eine Zeichenkette.** Im Bestand stehen Werte wie `25`,
  /// aber das Feld trägt auch Bereiche wie `8-12`. Es beim Schreiben in eine
  /// Zahl zu verwandeln, verlöre genau die.
  ///
  /// Zielwerte ohne Angabe werden **weggelassen**, nicht auf `null` gesetzt —
  /// Vertrag `04-firestore-schema.md`, R2.
  Map<String, dynamic> _toDocument(PlanDraft draft) => {
        'name': draft.name.trim(),
        'userId': draft.userId,
        'items': [
          for (final item in draft.items)
            {
              'exerciseId': item.exerciseId,
              'target': {
                if (item.sets != null) 'sets': item.sets,
                if (item.reps case final r? when r.trim().isNotEmpty)
                  'reps': r.trim(),
                if (item.holdSeconds != null) 'holdSec': item.holdSeconds,
              },
              if (item.restSeconds != null) 'restSec': item.restSeconds,
            },
        ],
        if (draft.icon != null) 'icon': draft.icon,
        if (draft.type != null) 'type': draft.type,
        if (draft.isNew) 'createdAt': Timestamp.now(),
      };

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
