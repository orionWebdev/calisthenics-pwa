import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../history/application/history_providers.dart';
import '../../history/domain/session_draft.dart';
import '../../history/domain/training_session.dart' as history;
import '../../exercises/application/exercise_providers.dart';
import '../../exercises/domain/exercise.dart';
import '../../plans/application/plan_providers.dart';
import '../data/plan_workout_repository.dart';
import '../domain/workout_repository.dart';
import '../domain/workout_session.dart';
import '../domain/workout_start.dart';

/// Setzt die Einheit aus Plan, Übungsbestand und Historie zusammen.
///
/// **Keine Überschreibung mehr im ProviderScope.** Bis hierher lag dort eine
/// Attrappe, die für jede Einheit dieselben drei Übungen lieferte — und der
/// echte Schreibpfad daneben schrieb sie in den Bestand. Ein Plan zu starten
/// hiess damit: eine erfundene Einheit speichern.
///
/// Ohne Anmeldung wirft es beim Laden. Das ist richtig so: Der Runner ist
/// hinter dem Anmeldetor erreichbar, und ein leeres Ergebnis sähe aus wie ein
/// Plan ohne Übungen.
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return PlanWorkoutRepository(
    userId: userId ?? '',
    plans: ref.watch(planRepositoryProvider),
    exercises: ref.watch(exerciseRepositoryProvider),
    sessions: ref.watch(sessionRepositoryProvider),
  );
});

/// Hält die laufende Einheit.
///
/// [build] übernimmt Laden, Fehlerbehandlung und Wiederholung — deshalb gibt es
/// hier kein eigenes `AsyncValue.guard` mehr. Ein Fehler beim Laden landet im
/// Provider, nicht in einem Zustand, den noch niemand beobachtet.
class WorkoutSessionController extends AsyncNotifier<ActiveWorkout> {
  WorkoutSessionController(this.start);

  final WorkoutStart start;

  @override
  Future<ActiveWorkout> build() {
    return ref.watch(workoutRepositoryProvider).loadWorkout(start);
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

  void updateHold(int exerciseIndex, String setId, String value) =>
      _mutateSet(exerciseIndex, setId, (s) => s.copyWith(hold: value));

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

          weight: last.weight,
          reps: last.reps,
        ),
      ],
    );
    state = AsyncData(w.copyWith(exercises: exercises));
  }

  /// Nimmt eine Übung in die laufende Einheit auf.
  ///
  /// **Der Runner ist die einzige Stelle, an der freies Training entsteht.**
  /// Ein Assistent vorweg („wähle erst Übungen") widerspräche seinem Zweck,
  /// nämlich sofort anzufangen — deshalb beginnt er leer und wächst.
  ///
  /// Der erste Satz ist leer und **nicht abgehakt**: Ein vorbelegter Satz wäre
  /// eine Leistungsangabe, die niemand gemacht hat.
  void addExercise(Exercise exercise) {
    final w = _workout;
    if (w == null) return;
    // Zweimal dieselbe Übung ist kein Fehler — ein Rundlauf macht genau das.
    // Die Kennung des Satzes trägt deshalb die Position, nicht nur die Übung.
    final position = w.exercises.length;
    state = AsyncData(w.copyWith(exercises: [
      ...w.exercises,
      WorkoutExercise(
        id: exercise.id,
        name: exercise.name,
        muscles: [for (final m in exercise.displayMuscles) m.wire],
        sets: [
          WorkoutSet(
            id: '${exercise.id}-$position-0',
            type: SetType.normal,
            weight: '',
            reps: '',
          ),
        ],
      ),
    ]));
  }

  /// Nimmt eine Übung wieder heraus — samt ihrer Sätze.
  void removeExercise(int index) {
    final w = _workout;
    if (w == null) return;
    if (index < 0 || index >= w.exercises.length) return;
    state = AsyncData(w.copyWith(exercises: [
      for (var i = 0; i < w.exercises.length; i++)
        if (i != index) w.exercises[i],
    ]));
  }

  /// Übernimmt einen gesicherten Zwischenstand.
  ///
  /// **Nur aus dem Zwischenstand-Speicher.** Der Zustand wird sonst
  /// ausschliesslich aus dem Repository geladen; ein zweiter Weg hinein wäre
  /// eine zweite Quelle für dasselbe.
  void restore(ActiveWorkout workout) => state = AsyncData(workout);

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

    // **Ergänzen statt anlegen**, wenn die Einheit schon existiert. Sonst
    // entstünde aus einem Nachtragen eine zweite Einheit am selben Tag —
    // und die Auswertung zählte sie doppelt.
    final amends = w.amendsSessionId;
    if (amends != null) {
      // **Nur die Sätze.** Datum und Dauer der bestehenden Einheit bleiben —
      // der Runner kennt nur den heutigen Tag und die Zeit seit dem Öffnen,
      // und beides gehört nicht zu einer Einheit von vorletzter Woche.
      await ref
          .read(sessionRepositoryProvider)
          .updateSessionExercises(amends, draft.exercises);
      return amends;
    }

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
          holdSeconds: set.holdValue,
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
      // Der Plan wandert in die Einheit — `planName` steht dabei **im
      // Dokument**, nicht als Verweis: So bleibt die Einheit vollständig
      // lesbar, auch wenn der Plan später gelöscht wird.
      planId: workout.planId,
      planName: workout.title,
      scheduleId: workout.sessionId.isEmpty ? null : workout.sessionId,
    );
  }
}

final workoutSessionProvider = AsyncNotifierProvider.autoDispose
    .family<WorkoutSessionController, ActiveWorkout, WorkoutStart>(
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

  /// Die Uhr gehört dem Notifier, nicht dem Repository.
  ///
  /// Vorher fragte er `startSession()` nach einem Startzeitpunkt — und bekam
  /// von der einzigen Implementierung `DateTime.now()` zurück. Ein Netzweg für
  /// einen Wert, der lokal entsteht: `stopSession()` war folgerichtig ein
  /// leerer Rumpf. Beide sind mit dem Anschluss an echte Daten entfallen.
  void start() {
    if (state.isRunning) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    state = SessionTimerState(startedAt: DateTime.now(), elapsed: Duration.zero);
  }

  void stop() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    _ticker = null;
    state = const SessionTimerState();
  }

  void toggle() => state.isRunning ? stop() : start();

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
