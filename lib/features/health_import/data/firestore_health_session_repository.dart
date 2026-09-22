import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/pulse_profile.dart';
import '../domain/health_session.dart';
import '../domain/health_session_repository.dart';

/// Die gelesenen Uhr-Einheiten aus `userProfiles/{uid}/healthSessions`.
///
/// ## Felder
///
/// `externalId`, `state`, `start`, `end`, `sourceId`, `seenAt` und die
/// gemessenen Werte `averageHeartRate`, `maxHeartRate`, `calories`,
/// `distanceKm`. Dazu `sessionId` und `decidedAt`, sobald entschieden wurde.
///
/// `externalId` steht **zusätzlich** zur Dokumentkennung im Dokument: Die
/// Kennung ist gesäubert (`/` ist in Firestore-Kennungen verboten), der Wert
/// nicht. Beim Abgleich mit Health Connect gilt der rohe Wert.
///
/// ## Die Lesemarke steht im Profil
///
/// `healthSessionsReadAt` — ein einzelner Zeitpunkt, überschreibbar, ohne
/// Vergangenheit. Genau das, wofür ein Profilfeld da ist. In einer
/// Unter-Sammlung wäre es ein Dokument, das nie mehr als eine Zeile trägt.
class FirestoreHealthSessionRepository implements HealthSessionRepository {
  FirestoreHealthSessionRepository(this._db);

  final FirebaseFirestore _db;

  static const profiles = 'userProfiles';
  static const collection = 'healthSessions';
  static const readMarkField = 'healthSessionsReadAt';

  DocumentReference<Map<String, dynamic>> _profile(String userId) =>
      _db.collection(profiles).doc(userId);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _profile(userId).collection(collection);

  @override
  Stream<List<HealthSession>> watch(String userId) =>
      _col(userId).orderBy('start').snapshots().map(_list);

  @override
  Future<List<HealthSession>> fetch(String userId) async =>
      _list(await _col(userId).orderBy('start').get());

  @override
  Future<void> save(String userId, HealthSession session) =>
      _col(userId).doc(session.documentId).set({
        'externalId': session.externalId,
        'state': session.state.wire,
        'start': Timestamp.fromDate(session.start),
        'end': Timestamp.fromDate(session.end),
        'sourceId': session.sourceId,
        'seenAt': Timestamp.fromDate(session.seenAt),
        if (session.activity != null) 'activity': session.activity,
        if (session.deviceName != null) 'deviceName': session.deviceName,
        if (session.averageHeartRate != null)
          'averageHeartRate': session.averageHeartRate,
        if (session.maxHeartRate != null) 'maxHeartRate': session.maxHeartRate,
        if (session.calories != null) 'calories': session.calories,
        if (session.distanceKm != null) 'distanceKm': session.distanceKm,
        // Der Pulsverlauf als Sekunden je bpm — Schlüssel sind Strings, weil
        // Firestore keine anderen kennt. Nicht die Punktwolke: Zonen werden
        // aus ihm immer neu gerechnet, und dafür zählt nur, wie lange welcher
        // Wert galt.
        if (session.pulse != null) ...{
          'pulse': session.pulse!.toWire(),
          'pulseWindowSeconds': session.pulse!.windowSeconds,
          // Die Zeitachse dazu: bpm je Schlitz, nur wo gemessen wurde. Leer
          // heisst „vor dem 22.09.2026 gelesen" — kein Feld, kein Wert.
          //
          // `pulseCurveSlot` sagt, wie lang ein Schlitz ist. Ohne das Feld
          // gilt die Minute; mit ihm zehn Sekunden. Es steht **neben** der
          // Kurve und nie ohne sie — ein Raster ohne Werte sagt nichts.
          if (session.pulse!.curve.isNotEmpty) ...{
            'pulseCurve': session.pulse!.curveToWire(),
            'pulseCurveSlot': session.pulse!.slotSeconds,
          },
        },
        if (session.decidedAt != null)
          'decidedAt': Timestamp.fromDate(session.decidedAt!),
        // Eine gelöste Verknüpfung muss das Feld wirklich **entfernen**:
        // `merge` liesse einen `null`-Wert sonst als alten Verweis stehen,
        // der auf eine Einheit zeigt, die den Datensatz nicht mehr kennt.
        'sessionId': session.sessionId ?? FieldValue.delete(),
      }, SetOptions(merge: true));

  @override
  Future<void> delete(String userId, String externalId) =>
      _col(userId).doc(HealthSession.idFor(externalId)).delete();

  @override
  Future<DateTime?> lastRead(String userId) async {
    final snapshot = await _profile(userId).get();
    final value = snapshot.data()?[readMarkField];
    return value is Timestamp ? value.toDate() : null;
  }

  @override
  Future<void> markRead(String userId, DateTime at) => _profile(userId)
      .set({readMarkField: Timestamp.fromDate(at)}, SetOptions(merge: true));

  static List<HealthSession> _list(
          QuerySnapshot<Map<String, dynamic>> snapshot) =>
      [
        for (final doc in snapshot.docs)
          if (_session(doc.id, doc.data()) case final session?) session,
      ];

  /// Ein Dokument zu einem Datensatz — oder `null`, wenn es keiner ist.
  ///
  /// Ohne Zeitraum ist er wertlos: Er könnte weder geprüft noch gepaart
  /// werden. Die Kennung fällt auf die Dokumentkennung zurück, weil die aus
  /// ihr entstanden ist.
  static HealthSession? _session(String id, Map<String, dynamic> data) {
    final start = data['start'];
    final end = data['end'];
    if (start is! Timestamp || end is! Timestamp) return null;
    if (!end.toDate().isAfter(start.toDate())) return null;

    final seen = data['seenAt'];
    final decided = data['decidedAt'];

    return HealthSession(
      externalId: (data['externalId'] as String?) ?? id,
      state: HealthSessionState.fromWire(data['state']),
      start: start.toDate(),
      end: end.toDate(),
      sourceId: (data['sourceId'] as String?) ?? '',
      seenAt: seen is Timestamp ? seen.toDate() : start.toDate(),
      activity: data['activity'] as String?,
      deviceName: data['deviceName'] as String?,
      averageHeartRate: (data['averageHeartRate'] as num?)?.round(),
      maxHeartRate: (data['maxHeartRate'] as num?)?.round(),
      calories: (data['calories'] as num?)?.round(),
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      pulse: PulseProfile.fromWire(data['pulse'], data['pulseWindowSeconds'],
          data['pulseCurve'], data['pulseCurveSlot']),
      sessionId: data['sessionId'] as String?,
      decidedAt: decided is Timestamp ? decided.toDate() : null,
    );
  }
}
