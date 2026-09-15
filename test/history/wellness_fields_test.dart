import 'package:atem/features/history/data/firestore_session_repository.dart';
import 'package:atem/features/history/data/session_mapper.dart';
import 'package:atem/features/history/domain/session_draft.dart';
import 'package:atem/features/history/domain/session_patch.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Selbstauskunft und Fokus — Lesen, Schreiben, und das Bearbeiten, das
/// nichts wegnehmen darf.
void main() {
  late FakeFirebaseFirestore db;
  late FirestoreSessionRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreSessionRepository(db);
  });

  Future<Map<String, dynamic>?> read(String id) async =>
      (await db.collection('sessions').doc(id).get()).data();

  Map<String, dynamic> doc(Map<String, dynamic> extra) => {
        'userId': 'u1',
        'type': 'strength',
        'date': Timestamp.fromDate(DateTime(2026, 8, 20)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 8, 20, 19)),
        ...extra,
      };

  group('Lesen', () {
    test('der Draht heisst preWorkoutEnergy, das Feld preWorkoutReadiness', () {
      final session = SessionMapper.fromMap(
        's1',
        doc({'preWorkoutEnergy': 4, 'postWorkoutFeeling': 2}),
      );
      expect(session!.preWorkoutReadiness, 4);
      expect(session.postWorkoutFeeling, 2);
    });

    test('workoutFocus kommt aus dem Draht', () {
      final session =
          SessionMapper.fromMap('s1', doc({'workoutFocus': 'upper_body'}));
      expect(
          (session! as StrengthSession).workoutFocus, WorkoutFocus.upperBody);
    });

    test('ein unbekannter Fokus wird null, nicht other', () {
      final session =
          SessionMapper.fromMap('s1', doc({'workoutFocus': 'kniebeugentag'}));
      expect((session! as StrengthSession).workoutFocus, isNull);
    });

    test('R1 gilt auch hier: 4.0 wird 4, nicht 3', () {
      final session =
          SessionMapper.fromMap('s1', doc({'preWorkoutEnergy': 4.0}));
      expect(session!.preWorkoutReadiness, 4);
    });
  });

  group('Anlegen', () {
    test('schreibt die Selbstauskunft unter den alten Feldnamen', () async {
      final id = await repo.saveSession(SessionDraft(
        userId: 'u1',
        kind: SessionKind.strength,
        date: DateTime(2026, 8, 20),
        duration: const Duration(minutes: 50),
        preWorkoutReadiness: 5,
        postWorkoutFeeling: 3,
        workoutFocus: WorkoutFocus.push,
      ));

      final data = await read(id);
      expect(data!['preWorkoutEnergy'], 5);
      expect(data['postWorkoutFeeling'], 3);
      expect(data['workoutFocus'], 'push');
      // Der neue Name darf nicht zusätzlich entstehen — sonst gäbe es zwei
      // Felder für dieselbe Frage.
      expect(data.containsKey('preWorkoutReadiness'), isFalse);
    });

    test('ohne Antwort entsteht kein Feld', () async {
      final id = await repo.saveSession(SessionDraft(
        userId: 'u1',
        kind: SessionKind.strength,
        date: DateTime(2026, 8, 20),
        duration: const Duration(minutes: 50),
      ));

      final data = await read(id);
      expect(data!.containsKey('preWorkoutEnergy'), isFalse);
      expect(data.containsKey('postWorkoutFeeling'), isFalse);
      expect(data.containsKey('workoutFocus'), isFalse);
    });

    test(
        'eine Ausdauereinheit bekommt keinen Fokus, auch wenn er im '
        'Entwurf steht', () async {
      final id = await repo.saveSession(SessionDraft(
        userId: 'u1',
        kind: SessionKind.cardio,
        date: DateTime(2026, 8, 20),
        duration: const Duration(minutes: 30),
        activity: CardioActivity.run,
        workoutFocus: WorkoutFocus.push,
      ));

      expect((await read(id))!.containsKey('workoutFocus'), isFalse);
    });

    test('eine Krafteinheit ohne Sätze ist gültig — der Fokus trägt sie',
        () async {
      final id = await repo.saveSession(SessionDraft(
        userId: 'u1',
        kind: SessionKind.strength,
        date: DateTime(2026, 8, 20),
        duration: const Duration(minutes: 45),
        workoutFocus: WorkoutFocus.pull,
      ));

      final data = await read(id);
      expect(data!.containsKey('exercises'), isFalse);
      expect(data['workoutFocus'], 'pull');

      final session = SessionMapper.fromMap(id, data)! as StrengthSession;
      expect(session.hasExerciseData, isFalse);
      expect(session.workoutFocus, WorkoutFocus.pull);
    });
  });

  group('Ändern', () {
    Future<String> seed(Map<String, dynamic> extra) async =>
        (await db.collection('sessions').add(doc(extra))).id;

    test('ein Patch, der die Antworten mitführt, behält sie', () async {
      final id = await seed({
        'duration': 50,
        'notes': 'schwer',
        'preWorkoutEnergy': 4,
        'postWorkoutFeeling': 2,
      });

      await repo.updateSession(
        id,
        SessionPatch(
          date: DateTime(2026, 8, 21),
          duration: const Duration(minutes: 50),
          notes: 'schwer',
          preWorkoutReadiness: 4,
          postWorkoutFeeling: 2,
        ),
      );

      final data = await read(id);
      expect(data!['preWorkoutEnergy'], 4);
      expect(data['postWorkoutFeeling'], 2);
    });

    test('null nimmt die Antwort zurück — das Feld verschwindet', () async {
      final id = await seed({'duration': 50, 'preWorkoutEnergy': 4});

      await repo.updateSession(
        id,
        SessionPatch(
          date: DateTime(2026, 8, 20),
          duration: const Duration(minutes: 50),
        ),
      );

      expect((await read(id))!.containsKey('preWorkoutEnergy'), isFalse);
    });

    test('ohne StrengthPatch bleibt ein bestehender Fokus unangetastet',
        () async {
      final id = await seed({'duration': 50, 'workoutFocus': 'legs'});

      await repo.updateSession(
        id,
        SessionPatch(
          date: DateTime(2026, 8, 20),
          duration: const Duration(minutes: 50),
        ),
      );

      // Das ist der Unterschied zur Selbstauskunft: Eine Ausdauereinheit
      // kennt die Frage nicht, deshalb steckt der Fokus in einer Hülle, und
      // eine fehlende Hülle heisst „nicht anfassen".
      expect((await read(id))!['workoutFocus'], 'legs');
    });

    test('ein leerer StrengthPatch löscht den Fokus', () async {
      final id = await seed({'duration': 50, 'workoutFocus': 'legs'});

      await repo.updateSession(
        id,
        SessionPatch(
          date: DateTime(2026, 8, 20),
          duration: const Duration(minutes: 50),
          strength: const StrengthPatch(),
        ),
      );

      expect((await read(id))!.containsKey('workoutFocus'), isFalse);
    });
  });
}
