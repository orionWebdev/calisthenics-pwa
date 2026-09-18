import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/history/domain/hard_sets.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _ref = DateTime(2026, 9, 18, 12);
DateTime _ago(int n) => DateTime(_ref.year, _ref.month, _ref.day - n, 18);

StrengthSession _s(int daysAgo, String exerciseId, List<LoggedSet> sets) =>
    StrengthSession(
      id: 's$daysAgo$exerciseId',
      userId: 'u',
      date: _ago(daysAgo),
      createdAt: _ago(daysAgo),
      bodyweight: false,
      exercises: [LoggedExercise(exerciseId: exerciseId, sets: sets)],
    );

const _pullUp = Exercise(
  id: 'pull_up',
  name: 'Klimmzug',
  source: ExerciseSource.curated,
  primaryMuscles: [MuscleGroup.back],
  secondaryMuscles: [MuscleGroup.biceps],
);
const _bench = Exercise(
  id: 'bench',
  name: 'Bankdrücken',
  source: ExerciseSource.curated,
  primaryMuscles: [MuscleGroup.chest],
);

LoggedSet _rpe(int rpe) => LoggedSet(reps: 8, rpe: rpe);

int _of(HardSets h, MuscleGroup m) => h.shares
    .firstWhere((s) => s.muscle == m.filter,
        orElse: () =>
            HardSetsShare(muscle: m.filter, current: 0, previous: 0))
    .current;

void main() {
  test('nur Sätze mit RPE ≥ 7 sind hart', () {
    final h = HardSets.compute([
      _s(0, 'bench', [_rpe(6), _rpe(7), _rpe(9), const LoggedSet(reps: 8)]),
    ], const [_bench], _ref);
    expect(h.hardTotal, 2);
    expect(h.setsWithRpe, 3);
    expect(h.setsTotal, 4);
    expect(_of(h, MuscleGroup.chest), 2);
  });

  test('eine Übung bucht auf alle ihre Muskeln, die Summe zählt einmal', () {
    final h = HardSets.compute([
      _s(1, 'pull_up', [_rpe(8), _rpe(8)]),
    ], const [_pullUp], _ref);
    expect(_of(h, MuscleGroup.back), 2);
    expect(_of(h, MuscleGroup.biceps), 2);
    expect(h.hardTotal, 2);
  });

  test('Aufwärmsätze zählen nie, auch mit hoher RPE', () {
    final h = HardSets.compute([
      _s(0, 'bench',
          [const LoggedSet(reps: 8, rpe: 9, rawType: 'warmup'), _rpe(8)]),
    ], const [_bench], _ref);
    expect(h.hardTotal, 1);
    expect(h.setsTotal, 1);
    expect(h.setsWithRpe, 1);
  });

  test('Fenster: Tag 0 bis 6 aktuell, 7 bis 13 davor, 14 gar nicht', () {
    final h = HardSets.compute([
      _s(0, 'bench', [_rpe(8)]),
      _s(6, 'bench', [_rpe(8)]),
      _s(7, 'bench', [_rpe(8), _rpe(8)]),
      _s(13, 'bench', [_rpe(8)]),
      _s(14, 'bench', [_rpe(8), _rpe(8), _rpe(8)]),
    ], const [_bench], _ref);
    expect(h.hardTotal, 2);
    expect(h.previousHardTotal, 3);
    final chest = h.shares.single;
    expect(chest.current, 2);
    expect(chest.previous, 3);
    expect(chest.shift, -1);
  });

  test('ein Satz nach dem Stichtag zählt nicht', () {
    final future = StrengthSession(
      id: 'f',
      userId: 'u',
      date: DateTime(_ref.year, _ref.month, _ref.day + 1, 8),
      createdAt: _ref,
      bodyweight: false,
      exercises: [LoggedExercise(exerciseId: 'bench', sets: [_rpe(9)])],
    );
    expect(HardSets.compute([future], const [_bench], _ref).hardTotal, 0);
  });

  test('Schwelle: ab 10 Sätzen mit Angabe', () {
    List<LoggedSet> n(int count) => [for (var i = 0; i < count; i++) _rpe(5)];
    expect(
        HardSets.compute([_s(0, 'bench', n(9))], const [_bench], _ref)
            .hasEnough,
        isFalse);
    expect(
        HardSets.compute([_s(0, 'bench', n(10))], const [_bench], _ref)
            .hasEnough,
        isTrue);
  });

  test('Seiten: ein Paar harter Sätze zählt einmal', () {
    final h = HardSets.compute([
      _s(0, 'bench', const [
        LoggedSet(reps: 8, rpe: 8, side: SetSide.left),
        LoggedSet(reps: 8, rpe: 8, side: SetSide.right),
      ]),
    ], const [_bench], _ref);
    expect(h.hardTotal, 1);
    expect(h.setsWithRpe, 1);
  });

  test('unbekannte Übung zählt in der Summe, aber auf keinen Muskel', () {
    final h = HardSets.compute([
      _s(0, 'fremd', [_rpe(9)]),
    ], const [_bench], _ref);
    expect(h.hardTotal, 1);
    expect(h.shares, isEmpty);
  });

  test('Sortierung: die meisten harten Sätze zuerst', () {
    final h = HardSets.compute([
      _s(0, 'bench', [_rpe(8)]),
      _s(1, 'pull_up', [_rpe(8), _rpe(8), _rpe(8)]),
    ], const [_bench, _pullUp], _ref);
    expect(h.shares.first.current, 3);
    expect(h.shares.last.muscle, MuscleGroup.chest.filter);
  });
}
