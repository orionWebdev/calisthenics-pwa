import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/history/domain/muscle_balance.dart';
import 'package:atem/features/history/domain/set_counting.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/domain/weekly_strength_volume.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Zählregel für seitengetrennte Sätze (18.09.2026).
void main() {
  const l = LoggedSet(reps: 10, side: SetSide.left);
  const r = LoggedSet(reps: 10, side: SetSide.right);
  const b = LoggedSet(reps: 10);

  group('SetCounting.count', () {
    test('ohne Seiten: jeder Satz zählt — der ganze Bestand', () {
      expect(SetCounting.count(const [b, b, b]), 3);
    });

    test('Paare links/rechts: 3 + 3 → 3', () {
      expect(SetCounting.count(const [l, r, l, r, l, r]), 3);
    });

    test('ungleiche Seiten: 3 links, 2 rechts → 3', () {
      expect(SetCounting.count(const [l, r, l, r, l]), 3);
    });

    test('nur eine Seite: 2 links → 2', () {
      expect(SetCounting.count(const [l, l]), 2);
    });

    test('gemischt: 2 beidseitig + 3 links + 3 rechts → 5', () {
      expect(SetCounting.count(const [b, b, l, r, l, r, l, r]), 5);
    });

    test('Filter gilt vor der Paarbildung', () {
      const hardL = LoggedSet(reps: 8, rpe: 8, side: SetSide.left);
      const easyR = LoggedSet(reps: 8, rpe: 5, side: SetSide.right);
      const hardR = LoggedSet(reps: 8, rpe: 9, side: SetSide.right);
      expect(
        SetCounting.count(const [hardL, easyR, hardL, hardR],
            include: (s) => s.isHard),
        2,
      );
    });
  });

  final date = DateTime(2026, 9, 16);
  StrengthSession session(List<LoggedSet> sets) => StrengthSession(
        id: 's',
        userId: 'u',
        date: date,
        createdAt: date,
        bodyweight: false,
        exercises: [LoggedExercise(exerciseId: 'curl', sets: sets)],
      );
  const curl = Exercise(
    id: 'curl',
    name: 'Curl',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.biceps],
    unilateral: true,
  );

  test('Muskelbalance: ein Paar links/rechts ist ein Satz', () {
    final balance = MuscleBalance.compute(
        [session(const [l, r, l, r, l, r])], const [curl], date);
    final biceps =
        balance.shares.firstWhere((s) => s.muscle == MuscleGroup.biceps.filter);
    expect(biceps.sets, 3);
  });

  test('Muskelbalance: Volumen bleibt die Summe beider Seiten', () {
    const lw = LoggedSet(reps: 10, weight: 12, side: SetSide.left);
    const rw = LoggedSet(reps: 10, weight: 12, side: SetSide.right);
    final balance =
        MuscleBalance.compute([session(const [lw, rw])], const [curl], date);
    final biceps =
        balance.shares.firstWhere((s) => s.muscle == MuscleGroup.biceps.filter);
    expect(biceps.volume, 240);
    expect(biceps.sets, 1);
  });

  test('Sätze je Woche: Paare zählen einfach, Aufwärmsätze nie', () {
    const warmL = LoggedSet(reps: 10, side: SetSide.left, rawType: 'warmup');
    final volume = WeeklyStrengthVolume.compute(
        [session(const [warmL, l, r, l, r])], date);
    expect(volume.currentSets, 2);
  });

  test('Sätze je Woche: ohne Seiten unverändert', () {
    final volume = WeeklyStrengthVolume.compute([session(const [b, b, b])], date);
    expect(volume.currentSets, 3);
  });
}
