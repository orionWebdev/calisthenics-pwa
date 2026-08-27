import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../history/application/history_providers.dart';
import '../../history/domain/session_draft.dart';
import '../../history/domain/training_session.dart' as history;
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
    final set =
        w.exercises[exerciseIndex].sets.firstWhere((s) => s.id == setId);
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

  /// Schliesst die Einheit ab und schreibt sie in die Historie.
  ///
  /// Liefert die Dokument-ID der gespeicherten Einheit, oder `null`, wenn es
  /// nichts zu speichern gab. Fehler werden **weitergereicht** — eine verlorene
  /// Trainingseinheit darf nicht stillschweigend verschwinden, und der Screen
  /// muss sie melden können.
  Future<String?> finish(Duration duration, {DateTime? at}) async {
    final w = _workout;
    if (w == null) return null;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Kein angemeldeter Nutzer — Einheit nicht speicherbar');
    }

    final draft = toDraft(w, userId: userId, duration: duration, at: at);
    // Nichts abgehakt heisst: nichts passiert. Ein leeres Dokument im Bestand
    // verfälschte jede Auswertung.
    if (draft == null) return null;

    return ref.read(sessionRepositoryProvider).saveSession(draft);
  }

  /// Übersetzt die laufende Einheit in einen Entwurf für die Historie.
  ///
  /// Öffentlich und ohne `ref`, damit die Abbildung ohne Provider prüfbar ist —
  /// sie ist die Stelle, an der Daten verlorengehen können.
  ///
  /// **Nur abgehakte Sätze** werden übernommen: Ein angelegter, aber nie
  /// ausgeführter Satz ist keine Leistung. Übungen ohne abgehakten Satz fallen
  /// ganz weg, genau wie in der PWA.
  static SessionDraft? toDraft(
    ActiveWorkout workout, {
    required String userId,
    required Duration duration,
    DateTime? at,
  }) {
    final exercises = <history.LoggedExercise>[];

    for (final exercise in workout.exercises) {
      final sets = <history.LoggedSet>[];
      for (final set in exercise.sets) {
        if (!set.done) continue;
        sets.add(history.LoggedSet(
          reps: set.repsValue,
          weight: set.weightValue,
          // Der Standardtyp wird nicht geschrieben. Das Feld `type` am Satz
          // trägt im Bestand ausschliesslich `hold`; jeder weitere Wert ist
          // eine Erweiterung, die die PWA nicht kennt. Sie nur dann zu
          // schreiben, wenn der Nutzer sie ausdrücklich gesetzt hat, hält den
          // Bestand sauber, ohne seine Eingabe zu verlieren.
          rawType: set.type == SetType.normal ? null : set.type.wire,
        ));
      }
      if (sets.isEmpty) continue;
      exercises
          .add(history.LoggedExercise(exerciseId: exercise.id, sets: sets));
    }

    if (exercises.isEmpty) return null;

    final now = at ?? DateTime.now();
    return SessionDraft(
      userId: userId,
      kind: history.SessionKind.strength,
      date: DateTime(now.year, now.month, now.day),
      duration: duration,
      exercises: exercises,
      notes: workout.notes,
      // Der Runner bekommt heute eine Termin-ID als sessionId. Bis der
      // Planbuilder da ist, ist das die einzige Verbindung zum Kalender.
      scheduleId: workout.sessionId.isEmpty ? null : workout.sessionId,
    );
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
