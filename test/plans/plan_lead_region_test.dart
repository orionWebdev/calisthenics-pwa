import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/plans/presentation/widgets/plans_section.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Hauptregion einer Plankarte — sie färbt deren Aurora.
void main() {
  const bench = Exercise(
    id: 'bench',
    name: 'Bankdrücken',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
  );
  const pushdown = Exercise(
    id: 'pushdown',
    name: 'Trizepsdrücken',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.triceps],
  );
  const ownRow = Exercise(
    id: 'row',
    name: 'Rudern',
    source: ExerciseSource.own,
    muscleGroups: [MuscleGroup.back, MuscleGroup.biceps],
  );
  final byId = {for (final e in [bench, pushdown, ownRow]) e.id: e};

  MuscleRegion? lead(List<PlanItem> items) => planLeadRegion(
      Plan(id: 'p', name: 'P', items: items), byId);

  test('Hilfsmuskeln zählen nicht — Bankdrücken ist Brust', () {
    expect(lead(const [PlanItem(exerciseId: 'bench', sets: 4)]),
        MuscleRegion.chest);
  });

  test('gewichtet nach Sätzen, nicht nach Übungen', () {
    expect(
      lead(const [
        PlanItem(exerciseId: 'bench', sets: 4),
        PlanItem(exerciseId: 'pushdown', sets: 2),
        PlanItem(exerciseId: 'pushdown', sets: 1),
      ]),
      MuscleRegion.chest,
    );
    expect(
      lead(const [
        PlanItem(exerciseId: 'bench', sets: 2),
        PlanItem(exerciseId: 'pushdown', sets: 5),
      ]),
      MuscleRegion.arms,
    );
  });

  test('eigene Übung ohne Hauptmuskel: vorläufig der erste Muskel', () {
    expect(lead(const [PlanItem(exerciseId: 'row', sets: 3)]),
        MuscleRegion.back);
  });

  test('ohne bekannte Übung keine Region', () {
    expect(lead(const [PlanItem(exerciseId: 'gibtsnicht')]), isNull);
  });
}
