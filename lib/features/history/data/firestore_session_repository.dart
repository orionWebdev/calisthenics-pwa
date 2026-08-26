import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/session_repository.dart';
import '../domain/training_session.dart';
import 'session_mapper.dart';

/// Liest `sessions` aus Firestore.
///
/// Die Abfrage ist bewusst ein einzelner Gleichheitsfilter auf `userId` — die
/// Begründung steht am Vertrag in `domain/session_repository.dart`. Sortiert
/// wird in Dart, nicht in der Abfrage: Ein `orderBy` auf `date` neben dem
/// Filter verlangte einen zusammengesetzten Index, den niemand ausgerollt hat.
///
/// Die Regeln lassen nur eigene Dokumente durch (`isOwner`), und ohne
/// Anmeldung gar keine. Ein leeres Ergebnis kann also dreierlei heißen: keine
/// Einheiten, nicht angemeldet, nicht freigeschaltet. Der Aufrufer muss das
/// unterscheiden können — deshalb wirft diese Klasse Fehler weiter, statt sie
/// in eine leere Liste zu verwandeln.
class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository(this._db);

  final FirebaseFirestore _db;

  static const collection = 'sessions';

  /// Der letzte Lesebericht. Für Diagnose, nicht für die Oberfläche.
  SessionReadReport? get lastReport => _lastReport;
  SessionReadReport? _lastReport;

  Query<Map<String, dynamic>> _query(String userId) =>
      _db.collection(collection).where('userId', isEqualTo: userId);

  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      _query(userId).snapshots().map(_convert);

  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async =>
      _convert(await _query(userId).get());

  List<TrainingSession> _convert(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final sessions = <TrainingSession>[];
    var skipped = 0;

    for (final doc in snapshot.docs) {
      final session = SessionMapper.fromDoc(doc);
      if (session == null) {
        skipped++;
        // Der Mapper lässt nur Dokumente aus, denen Pflichtfelder fehlen. Das
        // ist kein erwarteter Betriebszustand, sondern ein Hinweis auf einen
        // fremden Schreiber — die Dokument-ID gehört deshalb ins Protokoll.
        developer.log(
          'Session ${doc.id} übersprungen: Pflichtfelder fehlen',
          name: 'atem.history',
        );
        continue;
      }
      sessions.add(session);
    }

    // Neueste zuerst. Bei gleichem Datum entscheidet der Erfassungszeitpunkt,
    // damit zwei Einheiten am selben Tag eine stabile Reihenfolge haben.
    sessions.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
    });

    _lastReport = SessionReadReport(read: sessions.length, skipped: skipped);
    return sessions;
  }
}
