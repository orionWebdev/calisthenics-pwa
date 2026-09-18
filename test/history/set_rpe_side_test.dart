import 'package:atem/features/history/data/firestore_session_repository.dart';
import 'package:atem/features/history/data/session_mapper.dart';
import 'package:atem/features/history/domain/session_draft.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Satz-RPE und Körperseite (18.09.2026) — Draht, Lesen, Schreiben.
///
/// Beide Felder sind additiv: Die PWA kennt sie nicht, der ganze Bestand
/// trägt sie nicht. Sie dürfen also nichts am Lesen alter Dokumente ändern
/// und müssen fehlen, wenn niemand sie angegeben hat.
void main() {
  Map<String, dynamic> doc(List<Map<String, dynamic>> sets) => {
        'userId': 'u',
        'type': 'strength',
        'date': Timestamp.fromDate(DateTime(2026, 9, 18)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 18)),
        'exercises': [
          {'exerciseId': 'bicep_curl', 'sets': sets},
        ],
      };

  List<LoggedSet> setsOf(Map<String, dynamic> data) =>
      (SessionMapper.fromMap('s', data)! as StrengthSession)
          .exercises
          .single
          .sets;

  group('Lesen', () {
    test('rpe und side werden gelesen', () {
      final sets = setsOf(doc([
        {'reps': 10, 'weight': 12, 'rpe': 8, 'side': 'left'},
        {'reps': 10, 'weight': 12, 'rpe': 9, 'side': 'right'},
      ]));
      expect(sets[0].rpe, 8);
      expect(sets[0].side, SetSide.left);
      expect(sets[1].side, SetSide.right);
    });

    test('ohne Angabe: beidseitig und ohne RPE — wie der ganze Bestand', () {
      final set = setsOf(doc([{'reps': 10, 'weight': 12}])).single;
      expect(set.rpe, isNull);
      expect(set.side, isNull);
      expect(set.isHard, isFalse);
    });

    test('RPE ausserhalb 1–10 ist keine Angabe', () {
      final sets = setsOf(doc([
        {'reps': 5, 'rpe': 0},
        {'reps': 5, 'rpe': 11},
        {'reps': 5, 'rpe': 7.0},
      ]));
      expect(sets[0].rpe, isNull);
      expect(sets[1].rpe, isNull);
      expect(sets[2].rpe, 7, reason: 'Zahl als double ist erlaubt (R1)');
    });

    test('unbekannte Seite wird beidseitig, nicht erfunden', () {
      expect(setsOf(doc([{'reps': 5, 'side': 'both'}])).single.side, isNull);
    });
  });

  test('harter Satz ab RPE 7', () {
    expect(const LoggedSet(rpe: 6).isHard, isFalse);
    expect(const LoggedSet(rpe: 7).isHard, isTrue);
    expect(const LoggedSet(rpe: 10).isHard, isTrue);
  });

  group('Schreiben', () {
    late FakeFirebaseFirestore db;
    late FirestoreSessionRepository repo;
    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirestoreSessionRepository(db);
    });

    SessionDraft draft(List<LoggedSet> sets) => SessionDraft(
          userId: 'u',
          kind: SessionKind.strength,
          date: DateTime(2026, 9, 18),
          duration: const Duration(minutes: 30),
          exercises: [LoggedExercise(exerciseId: 'bicep_curl', sets: sets)],
        );

    Future<List<dynamic>> writtenSets(SessionDraft d) async {
      final id = await repo.saveSession(d);
      final snap = await db.collection('sessions').doc(id).get();
      return (snap.data()!['exercises'] as List).single['sets'] as List;
    }

    test('rpe und side landen im Dokument', () async {
      final sets = await writtenSets(draft(const [
        LoggedSet(reps: 10, weight: 12, rpe: 8, side: SetSide.left),
      ]));
      expect(sets.single['rpe'], 8);
      expect(sets.single['side'], 'left');
    });

    test('ohne Angabe fehlen beide Schlüssel ganz', () async {
      final sets = await writtenSets(draft(const [
        LoggedSet(reps: 10, weight: 12),
      ]));
      expect((sets.single as Map).containsKey('rpe'), isFalse);
      expect((sets.single as Map).containsKey('side'), isFalse);
    });

    test('Hin und zurück ergibt dieselben Werte', () async {
      final id = await repo.saveSession(draft(const [
        LoggedSet(reps: 8, weight: 14, rpe: 9, side: SetSide.right),
      ]));
      final snap = await db.collection('sessions').doc(id).get();
      final set = (SessionMapper.fromMap(id, snap.data()!)! as StrengthSession)
          .exercises
          .single
          .sets
          .single;
      expect(set.rpe, 9);
      expect(set.side, SetSide.right);
    });
  });
}
