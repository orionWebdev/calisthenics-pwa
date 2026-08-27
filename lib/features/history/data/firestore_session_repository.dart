import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/session_draft.dart';
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

  @override
  Future<String> saveSession(SessionDraft draft) async {
    final reference = await _db.collection(collection).add(_toDocument(draft));

    final scheduleId = draft.scheduleId;
    if (scheduleId != null) {
      try {
        await _db.collection('schedule').doc(scheduleId).update({
          // `status`, nicht `completed`: Im Produktivbestand steht `completed`
          // in allen 77 Dokumenten auf `false`, die PWA setzt es nie. Sie
          // schreibt ausschliesslich `status: 'completed'`. Wir schreiben
          // beides, damit auch ein Leser, der nur `completed` kennt, richtig
          // liegt.
          'status': 'completed',
          'completed': true,
          'sessionId': reference.id,
          'completedAt': Timestamp.now(),
        });
      } catch (error, stack) {
        // Bewusst geschluckt: Die Einheit ist bereits gespeichert. Ein Fehler
        // hier darf sie nicht nachträglich entwerten.
        developer.log(
          'Termin $scheduleId liess sich nicht als erledigt markieren',
          name: 'atem.history',
          error: error,
          stackTrace: stack,
        );
      }
    }

    return reference.id;
  }

  /// Baut das Firestore-Dokument.
  ///
  /// Die Feldnamen folgen der PWA (`js/views/workout/lifecycle.js`), damit
  /// beide Anwendungen dieselben Einheiten lesen. Felder ohne Wert werden
  /// **weggelassen** statt auf `null` gesetzt: Der Bestand kennt zwar beides,
  /// aber ein fehlendes Feld ist die sauberere Aussage.
  Map<String, dynamic> _toDocument(SessionDraft draft) {
    final exercises = <Map<String, dynamic>>[];
    for (final exercise in draft.exercises) {
      if (exercise.sets.isEmpty) continue;
      exercises.add({
        'exerciseId': exercise.exerciseId,
        if (exercise.usesBodyweight == true) 'usesBodyweight': true,
        'sets': [
          for (final set in exercise.sets)
            {
              if (set.reps != null) 'reps': set.reps,
              if (set.weight != null) 'weight': set.weight,
              if (set.holdSeconds != null) 'holdSec': set.holdSeconds,
              if (set.rawType != null) 'type': set.rawType,
            },
        ],
      });
    }

    return {
      // Die Rules verlangen genau diese beiden Felder beim Anlegen.
      'type': draft.kind.wire,
      'userId': draft.userId,
      'date': Timestamp.fromDate(
        DateTime(draft.date.year, draft.date.month, draft.date.day),
      ),
      // Nicht `serverTimestamp()`: Der lokale Zwischenspeicher trüge das Feld
      // dann bis zur Antwort des Servers als `null`, und der Mapper fiele
      // solange auf `date` zurück. Ein echter Zeitpunkt ist ehrlicher.
      'createdAt': Timestamp.now(),
      // Minuten, gerundet — so schreibt und liest es die PWA.
      'duration': (draft.duration.inSeconds / 60).round(),
      if (exercises.isNotEmpty) 'exercises': exercises,
      if (draft.notes != null && draft.notes!.trim().isNotEmpty)
        'notes': draft.notes!.trim(),
      if (draft.planId != null) 'planId': draft.planId,
      if (draft.planName != null) 'planName': draft.planName,
      if (draft.scheduleId != null) 'scheduleId': draft.scheduleId,
      if (draft.rpe != null) 'rpe': draft.rpe,
    };
  }

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

    final report = SessionReadReport(read: sessions.length, skipped: skipped);
    _lastReport = report;
    // Eine Zeile je Momentaufnahme: die einzige Stelle, an der sich erkennen
    // lässt, ob die Regeln greifen und wie viel ankommt.
    //
    // Sichtbar in DevTools und unter `flutter run`, **nicht im Logcat** —
    // `developer.log` schreibt in den Dart-VM-Dienst, nicht in das
    // Android-Protokoll. Wer über `adb logcat` mitliest, sieht hier nichts.
    developer.log('sessions gelesen — $report', name: 'atem.history');
    return sessions;
  }
}
