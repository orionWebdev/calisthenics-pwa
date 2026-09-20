import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/weight_entry.dart';
import '../domain/weight_repository.dart';
import '../domain/weight_series.dart';

/// Die Gewichtsreihe aus `userProfiles/{uid}/bodyWeights`.
///
/// ## Felder
///
/// `kg` (Zahl), `date` (Timestamp, lokale Mitternacht), `source`
/// (Zeichenkette, siehe [WeightSource]), `externalId` (Zeichenkette, nur bei
/// gemessenen Werten) und `updatedAt`.
///
/// `date` steht **zusätzlich** zur Dokumentkennung im Dokument. Die Kennung
/// macht den Tag eindeutig, das Feld macht ihn abfragbar — ohne es liesse sich
/// kein Fenster serverseitig begrenzen, und die App müsste immer alles lesen.
///
/// ## Die PWA liest weiter mit
///
/// Das Feld `bodyWeight` im Profil bleibt stehen und trägt weiterhin den
/// jüngsten Wert (siehe `WeightController`). Die Vorgänger-App kennt die
/// Unter-Sammlung nicht; sie darf davon nichts merken.
class FirestoreWeightRepository implements WeightRepository {
  FirestoreWeightRepository(this._db);

  final FirebaseFirestore _db;

  static const profiles = 'userProfiles';
  static const collection = 'bodyWeights';

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection(profiles).doc(userId).collection(collection);

  @override
  Stream<WeightSeries> watch(String userId) =>
      _col(userId).orderBy('date').snapshots().map(_series);

  @override
  Future<WeightSeries> fetch(String userId) async =>
      _series(await _col(userId).orderBy('date').get());

  @override
  Future<void> save(String userId, WeightEntry entry) =>
      _col(userId).doc(entry.documentId).set({
        'kg': entry.kg,
        'date': Timestamp.fromDate(entry.date),
        'source': entry.source.wire,
        if (entry.externalId != null) 'externalId': entry.externalId,
        'updatedAt': Timestamp.now(),
      });

  @override
  Future<void> delete(String userId, DateTime day) =>
      _col(userId).doc(WeightEntry.idFor(day)).delete();

  static WeightSeries _series(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      WeightSeries.of([
        for (final doc in snapshot.docs)
          if (_entry(doc.id, doc.data()) case final entry?) entry,
      ]);

  /// Ein Dokument zu einem Eintrag — oder `null`, wenn es keiner ist.
  ///
  /// Wie überall im Bestand steht die Zahl mal als `int`, mal als `double`
  /// (Vertrag 4, R1). Das Datum kommt aus dem Feld; fehlt es, aus der Kennung
  /// — die ist das Datum, und ein Dokument ohne Datum ist deshalb kein Grund,
  /// einen Wert wegzuwerfen.
  static WeightEntry? _entry(String id, Map<String, dynamic> data) {
    final kg = (data['kg'] as num?)?.toDouble();
    if (kg == null || kg <= 0) return null;

    final stamp = data['date'];
    final date = stamp is Timestamp ? stamp.toDate() : DateTime.tryParse(id);
    if (date == null) return null;

    return WeightEntry(
      date: date,
      kg: kg,
      source: WeightSource.fromWire(data['source']),
      externalId: data['externalId'] as String?,
    );
  }
}
