import 'package:atem/features/history/data/firestore_session_repository.dart';
import 'package:atem/features/history/domain/session_patch.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreSessionRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreSessionRepository(db);
  });

  Future<String> seed({
    DateTime? date,
    int? duration,
    String? notes,
    String? scheduleId,
    List<Map<String, dynamic>>? exercises,
  }) async {
    final ref = await db.collection('sessions').add({
      'userId': 'u1',
      'type': 'strength',
      'date': Timestamp.fromDate(date ?? DateTime(2026, 8, 20)),
      'createdAt': Timestamp.fromDate(DateTime(2026, 8, 20, 19)),
      if (duration != null) 'duration': duration,
      if (notes != null) 'notes': notes,
      if (scheduleId != null) 'scheduleId': scheduleId,
      if (exercises != null) 'exercises': exercises,
    });
    return ref.id;
  }

  Future<Map<String, dynamic>?> read(String id) async =>
      (await db.collection('sessions').doc(id).get()).data();

  group('Ändern', () {
    test('setzt das Datum auf Mitternacht', () async {
      final id = await seed();
      await repo.updateSession(
        id,
        SessionPatch(date: DateTime(2026, 7, 3, 17, 42)),
      );

      final date = (await read(id))!['date'] as Timestamp;
      expect(date.toDate(), DateTime(2026, 7, 3));
    });

    test('rührt createdAt nicht an', () async {
      final id = await seed();
      await repo.updateSession(id, SessionPatch(date: DateTime(2026, 7, 3)));

      final created = (await read(id))!['createdAt'] as Timestamp;
      expect(created.toDate(), DateTime(2026, 8, 20, 19),
          reason: 'wann der Eintrag entstand, ist beim nachträglichen '
              'Verschieben gerade die Information');
    });

    test('entfernt die Dauer, statt sie auf null zu setzen', () async {
      final id = await seed(duration: 45);
      await repo.updateSession(id, SessionPatch(date: DateTime(2026, 8, 20)));

      final data = (await read(id))!;
      expect(data.containsKey('duration'), isFalse,
          reason: 'Vertrag 04, R2: fehlend und null sind derselbe Fall — '
              'dann soll auch nur eine Schreibweise entstehen');
    });

    test('entfernt eine geleerte Notiz', () async {
      final id = await seed(notes: 'war gut');
      await repo.updateSession(
        id,
        SessionPatch(date: DateTime(2026, 8, 20), notes: '   '),
      );
      expect((await read(id))!.containsKey('notes'), isFalse);
    });

    test('trimmt eine gesetzte Notiz', () async {
      final id = await seed();
      await repo.updateSession(
        id,
        SessionPatch(date: DateTime(2026, 8, 20), notes: '  schwer  '),
      );
      expect((await read(id))!['notes'], 'schwer');
    });

    test('rundet die Dauer auf Minuten, wie die Vorgänger-App', () async {
      final id = await seed();
      await repo.updateSession(
        id,
        SessionPatch(
          date: DateTime(2026, 8, 20),
          duration: const Duration(seconds: 100),
        ),
      );
      expect((await read(id))!['duration'], 2);
    });

    test('lässt Übungen unberührt, wenn der Patch keine trägt', () async {
      final id = await seed(exercises: [
        {
          'exerciseId': 'squat',
          'sets': [
            {'reps': 5, 'weight': 100},
          ],
        },
      ]);

      await repo.updateSession(id, SessionPatch(date: DateTime(2026, 8, 21)));

      final exercises = (await read(id))!['exercises'] as List;
      expect(exercises, hasLength(1),
          reason: 'null heisst unverändert, nicht leer — '
              'eine Cardio-Einheit hat gar kein Übungsfeld');
    });

    test('geänderte Einheiten sind wieder lesbar', () async {
      final id = await seed(duration: 45);
      await repo.updateSession(
        id,
        SessionPatch(
          date: DateTime(2026, 7, 3),
          duration: const Duration(minutes: 60),
          notes: 'verschoben',
        ),
      );

      final sessions = await repo.fetchSessions('u1');
      final session = sessions.firstWhere((s) => s.id == id);
      expect(session.date, DateTime(2026, 7, 3));
      expect(session.duration, const Duration(minutes: 60));
      expect(session.notes, 'verschoben');
    });
  });

  group('Löschen', () {
    test('entfernt das Dokument', () async {
      final id = await seed();
      await repo.deleteSession(id);
      expect(await read(id), isNull);
    });

    test('öffnet den zugehörigen Termin wieder', () async {
      await db.collection('schedule').doc('t1').set({
        'status': 'completed',
        'completed': true,
        'sessionId': 'egal',
        'completedAt': Timestamp.now(),
      });
      final id = await seed(scheduleId: 't1');

      await repo.deleteSession(id);

      final schedule =
          (await db.collection('schedule').doc('t1').get()).data()!;
      expect(schedule['status'], 'planned');
      expect(schedule['completed'], false);
      expect(schedule.containsKey('sessionId'), isFalse);
      expect(schedule.containsKey('completedAt'), isFalse);
    });

    test('ohne Termin passiert nichts weiter', () async {
      final id = await seed();
      await repo.deleteSession(id);
      expect((await db.collection('schedule').get()).docs, isEmpty);
    });

    test('ein fehlgeschlagener Termin reisst die Löschung nicht mit',
        () async {
      // Der Termin existiert gar nicht — das `update` scheitert.
      final id = await seed(scheduleId: 'gibtsnicht');
      await repo.deleteSession(id);
      expect(await read(id), isNull,
          reason: 'ein offener Termin ist der harmlosere Fehler');
    });
  });

  group('Anlegen bleibt unverändert', () {
    test('schreibt weiterhin die Pflichtfelder', () async {
      // Regressionsschutz: Das Zusammenlegen der Übungsabbildung darf den
      // Schreibpfad aus Stufe 6 nicht verändert haben.
      final id = await seed(exercises: [
        {
          'exerciseId': 'squat',
          'sets': [
            {'reps': 5, 'weight': 100.0, 'type': 'warmup'},
          ],
        },
      ]);
      final sessions = await repo.fetchSessions('u1');
      final session = sessions.firstWhere((s) => s.id == id);
      expect(session, isA<StrengthSession>());
      expect((session as StrengthSession).exercises.first.sets.first.reps, 5);
    });
  });
}
