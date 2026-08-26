import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/workout_repository.dart';
import '../domain/workout_session.dart';

/// Wie [dashboardRepositoryProvider] im ProviderScope überschreiben.
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  throw UnimplementedError(
    'workoutRepositoryProvider muss im ProviderScope überschrieben werden.',
  );
});

/// Hält die laufende Einheit.
///
/// [build] übernimmt Laden, Fehlerbehandlung und Wiederholung — deshalb gibt es
/// hier kein eigenes `AsyncValue.guard` mehr. Ein Fehler beim Laden landet im
/// Provider, nicht in einem Zustand, den noch niemand beobachtet.
class WorkoutSessionController extends AsyncNotifier<ActiveWorkout> {
  WorkoutSessionController(this.sessionId);

  final String sessionId;

  @override
  Future<ActiveWorkout> build() {
    return ref.watch(workoutRepositoryProvider).loadWorkout(sessionId);
  }

  ActiveWorkout? get _workout => state.value;

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
    state = AsyncData(w.copyWith(exercises: exercises));
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
          id: '${ex.id}-${ex.sets.length}-${last.id}',
          type: last.type,
          previousLabel: '—',
          weight: last.weight,
          reps: last.reps,
        ),
      ],
    );
    state = AsyncData(w.copyWith(exercises: exercises));
  }

  void setNotes(String notes) {
    final w = _workout;
    if (w == null) return;
    state = AsyncData(w.copyWith(notes: notes));
  }

  Future<void> finish(Duration duration) async {
    final w = _workout;
    if (w == null) return;
    await ref
        .read(workoutRepositoryProvider)
        .saveWorkout(w, duration: duration);
  }
}

final workoutSessionProvider = AsyncNotifierProvider.autoDispose
    .family<WorkoutSessionController, ActiveWorkout, String>(
  WorkoutSessionController.new,
);

/// Zustand der laufenden Session. Der Timer liegt im Notifier, nicht im Screen —
/// damit gehört ihm sein eigener Lebenszyklus und er ist ohne Widget testbar.
class SessionTimerState {
  const SessionTimerState({this.startedAt, this.elapsed});

  final DateTime? startedAt;
  final Duration? elapsed;

  bool get isRunning => startedAt != null;
}

class SessionTimerController extends Notifier<SessionTimerState> {
  Timer? _ticker;

  @override
  SessionTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const SessionTimerState();
  }

  Future<void> start(String sessionId) async {
    if (state.isRunning) return;
    final startedAt =
        await ref.read(workoutRepositoryProvider).startSession(sessionId);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    state = SessionTimerState(startedAt: startedAt, elapsed: Duration.zero);
  }

  Future<void> stop(String sessionId) async {
    if (!state.isRunning) return;
    _ticker?.cancel();
    _ticker = null;
    await ref.read(workoutRepositoryProvider).stopSession(sessionId);
    state = const SessionTimerState();
  }

  Future<void> toggle(String sessionId) =>
      state.isRunning ? stop(sessionId) : start(sessionId);

  void _tick() {
    final startedAt = state.startedAt;
    if (startedAt == null) return;
    state = SessionTimerState(
      startedAt: startedAt,
      elapsed: DateTime.now().difference(startedAt),
    );
  }
}

final sessionTimerProvider =
    NotifierProvider<SessionTimerController, SessionTimerState>(
  SessionTimerController.new,
);
