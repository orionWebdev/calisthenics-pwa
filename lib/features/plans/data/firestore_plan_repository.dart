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
        // `exercises` als zweiter Name der Liste — auch das kennt der
        // Normalisierer der Vorgänger-App (`getPlanItems`).
        items: _items(data['items'] ?? data['exercises']),
      ));
    }
    plans.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return plans;
  }

  /// Liest die Einträge — **in allen Schreibweisen, die der Bestand kennt**.
  ///
  /// ## Warum das nötig ist
  ///
  /// Die Vorgänger-App liest ihre eigenen Pläne durch einen Normalisierer
  /// (`js/views/plans/state-helpers.js`, `normalizePlanItems`), und der
  /// verrät, was über die Jahre geschrieben wurde: die Zielwerte mal
  /// verschachtelt unter `target`, mal **flach am Eintrag**; die Haltezeit
  /// als `holdSec` oder `hold`; die Pause als `restSec` oder `rest`; die
  /// Zahlen mal als Zahl, mal als Text (`Number(item.sets) || item.sets`).
  ///
  /// Diese Klasse kannte bis hierher genau eine Fassung — die verschachtelte
  /// mit echten Zahlen. Ein älterer Plan verlor damit still seine Vorgaben:
  /// Wer „2 Sätze, 14 Wiederholungen" hinterlegt hatte, bekam im Formular
  /// leere Felder und im Training drei Sätze ohne Ziel, weil `sets` hier
  /// `null` wurde und [PlanWorkoutRepository.defaultSets] einsprang.
  ///
  /// **Geschrieben wird weiter nur die verschachtelte Fassung** ([_toDocument]):
  /// Gelesen wird grosszügig, geschrieben eng — sonst wüchse die Zahl der
  /// Schreibweisen weiter.
  static List<PlanItem> _items(Object? value) {
    if (value is! List) return const [];
    final items = <PlanItem>[];
    for (final entry in value) {
      if (entry is! Map) continue;
      // `id` als zweiter Name der Übungskennung — auch das steht im
      // Normalisierer der Vorgänger-App.
      final id = _string(entry['exerciseId']) ?? _string(entry['id']);
      if (id == null) continue;

      final target = entry['target'];
      final fields = target is Map ? target : const {};

      items.add(PlanItem(
        exerciseId: id,
        sets: _int(fields['sets'] ?? entry['sets']),
        // Bleibt Text — siehe [PlanItem.reps].
        reps: _text(fields['reps'] ?? entry['reps']),
        holdSeconds: _int(
            fields['holdSec'] ?? fields['hold'] ?? entry['holdSec'] ??
                entry['hold']),
        restSeconds: _int(entry['restSec'] ?? entry['rest']),
      ));
    }
    return items;
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Ein Textfeld, das im Bestand auch als Zahl dastehen kann — `reps` ist
  /// mal `'8-12'`, mal `25`.
  static String? _text(Object? value) {
    if (value is num) return _number(value);
    return _string(value);
  }

  /// Eine Zahl, die im Bestand auch als Text dastehen kann.
  ///
  /// `'8-12'` bleibt dabei `null`: Ein Zielbereich ist keine Satzzahl und
  /// keine Sekundenangabe.
  static int? _int(Object? value) {
    if (value is num) return value.round();
    if (value is String) {
      final trimmed = value.trim();
      return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.round();
    }
    return null;
  }

  static String _number(num value) =>
      value is int || value == value.roundToDouble()
          ? value.round().toString()
          : value.toString();
}
