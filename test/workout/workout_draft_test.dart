import 'package:atem/features/workout/data/workout_draft_store.dart';
import 'package:atem/features/workout/domain/workout_clock.dart';
import 'package:atem/features/workout/domain/workout_session.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime(2026, 8, 28, 18, 0);

WorkoutDraft _draft() => WorkoutDraft(
      start: const WorkoutStart(planId: 'p1', scheduleId: 't1'),
      clock: WorkoutClock.startingAt(_start)
          .startRest(_start, const Duration(seconds: 90)),
      exerciseIndex: 1,
      workout: const ActiveWorkout(
        sessionId: 't1',
        planId: 'p1',
        title: 'Oberkörper A',
        notes: 'schwer',
        defaultRestSeconds: 90,
        exercises: [
          WorkoutExercise(
            id: 'bench',
            name: 'Bankdrücken',
            muscles: ['chest', 'triceps'],
            recordWeightKg: 100,
            targetReps: '8-12',
            sets: [
              WorkoutSet(
                id: 'bench-0-0',
                type: SetType.warmup,
                weight: '60',
                reps: '10',
                done: true,
                previous: SetReference(weightKg: 55, reps: 10),
              ),
              WorkoutSet(
                id: 'bench-0-1',
                type: SetType.normal,
                weight: '',
                reps: '',
              ),
            ],
          ),
          WorkoutExercise(
            id: 'plank',
            name: 'Unterarmstütz',
            muscles: ['core'],
            targetHoldSeconds: 45,
            sets: [
              WorkoutSet(
                id: 'plank-1-0',
                type: SetType.normal,
                weight: '',
                reps: '',
                hold: '40',
                done: true,
              ),
            ],
          ),
        ],
      ),
    );

void main() {
  test('überlebt den Weg durch JSON vollständig', () {
    final back = WorkoutDraft.fromJson(_draft().toJson())!;

    expect(back.start.planId, 'p1');
    expect(back.start.scheduleId, 't1',
        reason: 'ohne ihn bliebe der Kalendertermin nach dem Fortsetzen offen');
    expect(back.exerciseIndex, 1);
    expect(back.clock.startedAt, _start);
    expect(back.clock.isResting, isTrue);

    expect(back.workout.title, 'Oberkörper A');
    expect(back.workout.notes, 'schwer');
    expect(back.workout.exercises, hasLength(2));
  });

  test('abgehakte Sätze bleiben abgehakt', () {
    // Der Sinn der ganzen Sache: Was schon geleistet ist, darf ein Wisch
    // nach hinten nicht vernichten.
    final back = WorkoutDraft.fromJson(_draft().toJson())!;
    expect(back.workout.completedSets, 2);
    expect(back.workout.exercises.first.sets.first.done, isTrue);
    expect(back.workout.exercises.first.sets.first.weight, '60');
    expect(back.workout.exercises.first.sets.last.done, isFalse);
  });

  test('Satztypen und Historien-Referenzen überleben', () {
    final back = WorkoutDraft.fromJson(_draft().toJson())!;
    final first = back.workout.exercises.first.sets.first;
    expect(first.type, SetType.warmup);
    expect(first.previous?.weightKg, 55);
    expect(first.previous?.reps, 10);
  });

  test('Zielvorgaben und Haltezeiten überleben', () {
    final back = WorkoutDraft.fromJson(_draft().toJson())!;
    expect(back.workout.exercises.first.targetReps, '8-12');
    expect(back.workout.exercises.first.recordWeightKg, 100);

    final plank = back.workout.exercises.last;
    expect(plank.targetHoldSeconds, 45);
    expect(plank.isHold, isTrue);
    expect(plank.sets.first.hold, '40');
  });

  test('ein unbekannter Satztyp fällt auf normal zurück', () {
    final json = _draft().toJson();
    final exercises = (json['workout'] as Map)['exercises'] as List;
    (((exercises.first as Map)['sets'] as List).first as Map)['type'] =
        'irgendwas';

    final back = WorkoutDraft.fromJson(json)!;
    expect(back.workout.exercises.first.sets.first.type, SetType.normal,
        reason: 'ein neuer Typ aus einer späteren Fassung darf den '
            'Zwischenstand nicht unlesbar machen');
  });

  test('ohne Uhr gibt es nichts wiederherzustellen', () {
    final json = _draft().toJson()..remove('clock');
    expect(WorkoutDraft.fromJson(json), isNull);
  });

  test('das Höchstalter ist zwölf Stunden', () {
    // Ein Training, das seit zwölf Stunden offen ist, ist keins mehr.
    expect(WorkoutDraftStore.maxAge, const Duration(hours: 12));
  });
}
