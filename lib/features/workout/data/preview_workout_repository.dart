import '../domain/workout_repository.dart';
import '../domain/workout_session.dart';

/// NUR FÜR DESIGN-PREVIEW — Werte aus „TEM Workout Runner.dc.html".
/// Beim Anschluss an Firestore ersatzlos ersetzen.
class PreviewWorkoutRepository implements WorkoutRepository {
  @override
  Future<ActiveWorkout> loadWorkout(String sessionId) async {
    WorkoutSet set(String id, SetType t, String prev, String w, String r,
            {bool done = false}) =>
        WorkoutSet(
            id: id,
            type: t,
            previousLabel: prev,
            weight: w,
            reps: r,
            done: done);

    return ActiveWorkout(
      sessionId: sessionId,
      title: 'ATEM Hybrid – Day 4: Upper Body & EMOM Finish',
      exercises: [
        WorkoutExercise(
          id: 'squat',
          name: 'Back Squat',
          muscles: const ['QUADS', 'GLUTES'],
          recordLabel: 'PR 140 KG',
          sets: [
            set('squat-1', SetType.warmup, '60 kg × 12', '60', '12', done: true),
            set('squat-2', SetType.normal, '100 kg × 8', '100', '8'),
            set('squat-3', SetType.normal, '105 kg × 6', '105', '6'),
            set('squat-4', SetType.dropset, '80 kg × 12', '80', '12'),
          ],
        ),
        WorkoutExercise(
          id: 'rdl',
          name: 'Romanian Deadlift',
          muscles: const ['HAMSTRINGS', 'GLUTES'],
          recordLabel: 'PR 120 KG',
          sets: [
            set('rdl-1', SetType.warmup, '50 kg × 12', '50', '12'),
            set('rdl-2', SetType.normal, '90 kg × 10', '90', '10'),
            set('rdl-3', SetType.normal, '95 kg × 8', '95', '8'),
          ],
        ),
        WorkoutExercise(
          id: 'lunges',
          name: 'Walking Lunges',
          muscles: const ['QUADS', 'CORE'],
          recordLabel: 'MAX 2×24 KG',
          sets: [
            set('lunges-1', SetType.normal, '2×20 kg × 20', '20', '20'),
            set('lunges-2', SetType.normal, '2×20 kg × 20', '20', '20'),
            set('lunges-3', SetType.failure, '2×16 kg × 24', '16', '24'),
          ],
        ),
      ],
    );
  }

  @override
  Future<void> saveWorkout(ActiveWorkout workout,
      {required Duration duration}) async {}
}
