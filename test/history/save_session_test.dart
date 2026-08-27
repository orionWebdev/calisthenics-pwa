import 'package:atem/features/history/data/firestore_session_repository.dart';
import 'package:atem/features/history/domain/session_draft.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/workout/application/workout_providers.dart';
import 'package:atem/features/workout/domain/workout_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSet _set({
  required String weight,
  required String reps,
  bool done = true,
  SetType type = SetType.normal,
}) =>
    WorkoutSet(
      id: '$weight-$reps-$done-${type.name}',
      type: type,
      previousLabel: '—',
      weight: weight,
      reps: reps,
      done: done,
    );

ActiveWorkout _workout(List<WorkoutSet> sets, {String sessionId = 'plan-1'}) =>
    ActiveWorkout(
      sessionId: sessionId,
      title: 'Push Day',
      notes: 'Fühlte sich gut an',
      exercises: [
        WorkoutExercise(
          id: 'bench_press',
          name: 'Bankdrücken',
          muscles: const ['CHEST'],
          recordLabel: 'PR 100 KG',
          sets: sets,
        ),
      ],
    );

void main() {
  final at = DateTime(2026, 5, 20, 18, 45);

  group('Abbildung von der laufenden Einheit zum Entwurf', () {
    test('nur abgehakte Sätze werden übernommen', () {
      final draft = WorkoutSessionController.toDraft(
        _workout([
          _set(weight: '80', reps: '10'),
          _set(weight: '85', reps: '8'),
          _set(weight: '90', reps: '6', done: false),
        ]),
        userId: 'u1',
        duration: const Duration(minutes: 52),
        at: at,
      );

      expect(draft!.exercises.single.sets, hasLength(2));
      expect(draft.exercises.single.sets.map((s) => s.reps), [10, 8]);
      expect(draft.exercises.single.sets.map((s) => s.weight), [80.0, 85.0]);
    });

    test('eine Übung ohne abgehakten Satz fällt ganz weg', () {
      final draft = WorkoutSessionController.toDraft(
        _workout([_set(weight: '80', reps: '10', done: false)]),
        userId: 'u1',
        duration: const Duration(minutes: 10),
        at: at,
      );

      // Nichts abgehakt heisst nichts passiert — kein leeres Dokument im
      // Bestand, das jede Auswertung verfälschte.
      expect(draft, isNull);
    });

    test('das Datum wird auf Mitternacht gesetzt', () {
      final draft = WorkoutSessionController.toDraft(
        _workout([_set(weight: '80', reps: '10')]),
        userId: 'u1',
        duration: const Duration(minutes: 52),
        at: at,
      );

      expect(draft!.date, DateTime(2026, 5, 20));
    });

    test('Komma als Dezimaltrennzeichen wird gelesen', () {
      final draft = WorkoutSessionController.toDraft(
        _workout([_set(weight: '82,5', reps: '8')]),
        userId: 'u1',
        duration: const Duration(minutes: 30),
        at: at,
      );

      expect(draft!.exercises.single.sets.single.weight, 82.5);
    });

    test('der Standardsatztyp wird nicht mitgeschrieben', () {
      final draft = WorkoutSessionController.toDraft(
        _workout([
          _set(weight: '80', reps: '10'),
          _set(weight: '60', reps: '12', type: SetType.warmup),
        ]),
        userId: 'u1',
        duration: const Duration(minutes: 30),
        at: at,
      );

      final sets = draft!.exercises.single.sets;
      expect(sets[0].rawType, isNull, reason: 'normal bleibt ungeschrieben');
      expect(sets[1].rawType, 'warmup');
    });

    test('die Termin-ID wandert mit, eine leere nicht', () {
      final withId = WorkoutSessionController.toDraft(
        _workout([_set(weight: '80', reps: '10')], sessionId: 'sched-9'),
        userId: 'u1',
        duration: const Duration(minutes: 30),
        at: at,
      );
      final without = WorkoutSessionController.toDraft(
        _workout([_set(weight: '80', reps: '10')], sessionId: ''),
        userId: 'u1',
        duration: const Duration(minutes: 30),
        at: at,
      );

      expect(withId!.scheduleId, 'sched-9');
      expect(without!.scheduleId, isNull);
    });
  });

  group('Schreiben nach Firestore', () {
    late FakeFirebaseFirestore db;
    late FirestoreSessionRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirestoreSessionRepository(db);
    });

    SessionDraft draft({
      String? scheduleId,
      String? notes,
      Duration duration = const Duration(minutes: 52),
    }) =>
        SessionDraft(
          userId: 'u1',
          kind: SessionKind.strength,
          date: DateTime(2026, 5, 20),
          duration: duration,
          notes: notes,
          planName: 'Push Day',
          scheduleId: scheduleId,
          exercises: const [
            LoggedExercise(
              exerciseId: 'bench_press',
              sets: [
                LoggedSet(reps: 10, weight: 80),
                LoggedSet(reps: 8, weight: 85, rawType: 'dropset'),
              ],
            ),
          ],
        );

    test('das Dokument trägt die Felder, die die Rules verlangen', () async {
      final id = await repo.saveSession(draft());
      final data = (await db.collection('sessions').doc(id).get()).data()!;

      // isOwner(request.resource.data.userId) und
      // keys().hasAll(['type', 'userId'])
      expect(data['userId'], 'u1');
      expect(data['type'], 'strength');
    });

    test('die Form entspricht der, die die PWA schreibt', () async {
      final id = await repo.saveSession(draft(notes: 'stark'));
      final data = (await db.collection('sessions').doc(id).get()).data()!;

      expect((data['date'] as Timestamp).toDate(), DateTime(2026, 5, 20));
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['duration'], 52);
      expect(data['notes'], 'stark');
      expect(data['planName'], 'Push Day');

      final exercises = data['exercises'] as List;
      expect(exercises, hasLength(1));
      final sets = (exercises.single as Map)['sets'] as List;
      expect(sets, hasLength(2));
      expect((sets[0] as Map)['reps'], 10);
      expect((sets[0] as Map)['weight'], 80);
      expect((sets[1] as Map)['type'], 'dropset');
      // Kein `type` am ersten Satz — es war ein normaler.
      expect((sets[0] as Map).containsKey('type'), isFalse);
    });

    test('leere Felder werden weggelassen, nicht auf null gesetzt', () async {
      final id = await repo.saveSession(draft());
      final data = (await db.collection('sessions').doc(id).get()).data()!;

      expect(data.containsKey('notes'), isFalse);
      expect(data.containsKey('scheduleId'), isFalse);
      expect(data.containsKey('planId'), isFalse);
    });

    test('das Geschriebene ist wieder lesbar', () async {
      await repo.saveSession(draft());
      final sessions = await repo.fetchSessions('u1');

      expect(sessions, hasLength(1));
      final session = sessions.single as StrengthSession;
      expect(session.duration, const Duration(minutes: 52));
      expect(session.planName, 'Push Day');
      expect(session.exercises.single.sets.map((s) => s.reps), [10, 8]);
      expect(session.exercises.single.sets[1].rawType, 'dropset');
    });

    test('der Termin wird als erledigt markiert — beide Felder', () async {
      await db.collection('schedule').doc('sched-9').set({
        'userId': 'u1',
        'date': '2026-05-20',
        'completed': false,
        'planName': 'Push Day',
      });

      final id = await repo.saveSession(draft(scheduleId: 'sched-9'));
      final entry =
          (await db.collection('schedule').doc('sched-9').get()).data()!;

      // `status` schreibt die PWA, `completed` liest sonst niemand richtig.
      expect(entry['status'], 'completed');
      expect(entry['completed'], isTrue);
      expect(entry['sessionId'], id);
      expect(entry['completedAt'], isA<Timestamp>());
    });

    test('ein fehlender Termin reisst die Einheit nicht mit', () async {
      // Die Einheit ist bereits geschrieben, wenn der zweite Schritt scheitert.
      // Sie darf dadurch nicht verlorengehen.
      final id = await repo.saveSession(draft(scheduleId: 'gibt-es-nicht'));

      expect((await db.collection('sessions').doc(id).get()).exists, isTrue);
    });

    test('die Dauer wird auf Minuten gerundet', () async {
      final id = await repo.saveSession(
        draft(duration: const Duration(minutes: 52, seconds: 40)),
      );
      final data = (await db.collection('sessions').doc(id).get()).data()!;

      expect(data['duration'], 53);
    });
  });
}
