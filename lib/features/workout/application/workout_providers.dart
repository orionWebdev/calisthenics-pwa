import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/workout_repository.dart';
import '../domain/workout_session.dart';

/// Wie [dashboardRepositoryProvider] im ProviderScope überschreiben.
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  throw UnimplementedError(
    'workoutRepositoryProvider muss im ProviderScope überschrieben werden.',
  );
});

/// Hält die laufende Einheit. Die Timer selbst leben im Screen — sie hängen am
/// Widget-Lebenszyklus. Hier liegt nur, was am Ende gespeichert wird.
class WorkoutSessionController extends StateNotifier<AsyncValue<ActiveWorkout>> {
  WorkoutSessionController(this._ref, this._sessionId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;
  final String _sessionId;

  Future<void> _load() async {
    state = await AsyncValue.guard(
      () => _ref.read(workoutRepositoryProvider).loadWorkout(_sessionId),
    );
  }

  ActiveWorkout? get _workout => state.valueOrNull;

  void _mutateSet(
    int exerciseIndex,
    String setId,
    WorkoutSet Function(WorkoutSet) transform,
  ) {
    final w = _workout;
    if (w == null) return;
    final exercises = [...w.exercises];
    final ex = exercises[exerciseIndex];
    exercises[exerciseIndex] = ex.copyWith(
      sets: [
        for (final s in ex.sets) s.id == setId ? transform(s) : s,
      ],
    );
    state = AsyncValue.data(w.copyWith(exercises: exercises));
  }

  /// Hakt ab oder entsperrt wieder — bewusst reversibel (Fehlertoleranz).
  /// Gibt zurück, ob der Satz jetzt abgeschlossen ist.
  bool toggleSet(int exerciseIndex, String setId) {
    final w = _workout;
    if (w == null) return false;
    final set = w.exercises[exerciseIndex].sets.firstWhere((s) => s.id == setId);
    final nowDone = !set.done;
    _mutateSet(exerciseIndex, setId, (s) => s.copyWith(done: nowDone));
    return nowDone;
  }

  void cycleType(int exerciseIndex, String setId) =>
      _mutateSet(exerciseIndex, setId, (s) => s.copyWith(type: s.type.next));

  void updateWeight(int exerciseIndex, String setId, String value) =>
      _mutateSet(exerciseIndex, setId, (s) => s.copyWith(weight: value));

  void updateReps(int exerciseIndex, String setId, String value) =>
      _mutateSet(exerciseIndex, setId, (s) => s.copyWith(reps: value));

  /// Dupliziert die Werte des letzten Satzes.
  void addSet(int exerciseIndex) {
    final w = _workout;
    if (w == null) return;
    final exercises = [...w.exercises];
    final ex = exercises[exerciseIndex];
    if (ex.sets.isEmpty) return;
    final last = ex.sets.last;
    exercises[exerciseIndex] = ex.copyWith(
      sets: [
        ...ex.sets,
        WorkoutSet(
          id: '${ex.id}-${DateTime.now().microsecondsSinceEpoch}',
          type: last.type,
          previousLabel: '—',
          weight: last.weight,
          reps: last.reps,
        ),
      ],
    );
    state = AsyncValue.data(w.copyWith(exercises: exercises));
  }

  void setNotes(String notes) {
    final w = _workout;
    if (w == null) return;
    state = AsyncValue.data(w.copyWith(notes: notes));
  }

  Future<void> finish(Duration duration) async {
    final w = _workout;
    if (w == null) return;
    await _ref
        .read(workoutRepositoryProvider)
        .saveWorkout(w, duration: duration);
  }
}

final workoutSessionProvider = StateNotifierProvider.autoDispose
    .family<WorkoutSessionController, AsyncValue<ActiveWorkout>, String>(
  WorkoutSessionController.new,
);
