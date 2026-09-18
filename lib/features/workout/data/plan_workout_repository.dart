import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/exercise_repository.dart';
import '../../history/domain/exercise_history.dart';
import '../../history/domain/session_repository.dart';
import '../../history/domain/training_session.dart';
import '../../plans/domain/plan.dart';
import '../../plans/domain/plan_repository.dart';
import '../domain/workout_repository.dart';
import '../domain/workout_session.dart';
import '../domain/workout_start.dart';

/// Baut die laufende Einheit aus Plan, Übungsbestand und Historie.
///
/// ## Warum kein eigener Firestore-Zugriff
///
/// Alle drei Quellen haben bereits ein Repository — mit Abbildung, mit den
/// Härtungen gegen den ungleichen Bestand (`duration` mal Ganzzahl, mal
/// Kommazahl; `reps` als Text), und mit dem Offline-Zwischenspeicher. Eine
/// vierte Klasse, die dieselben Sammlungen noch einmal roh liest, wäre eine
/// zweite Wahrheit über dieselben Daten.
///
/// Diese Klasse liest deshalb **nichts selbst**. Sie setzt zusammen.
///
/// ## Was aus der Historie kommt
///
/// Zu jeder Übung im Plan zwei Angaben:
///
/// * **Was beim letzten Mal stand** — Satz für Satz aus der jüngsten Einheit,
///   die diese Übung enthält. Nicht der Durchschnitt: Wer wissen will, wo er
///   ansetzt, will die letzte Zahl, nicht eine geglättete.
/// * **Das schwerste je protokollierte Gewicht.** `null`, wenn es keins gibt —
///   dann erscheint kein Chip, statt „PR —" zu behaupten.
class PlanWorkoutRepository implements WorkoutRepository {
  PlanWorkoutRepository({
    required this.userId,
    required PlanRepository plans,
    required ExerciseRepository exercises,
    required SessionRepository sessions,
  })  : _plans = plans,
        _exercises = exercises,
        _sessions = sessions;

  final String userId;
  final PlanRepository _plans;
  final ExerciseRepository _exercises;
  final SessionRepository _sessions;

  /// Ohne Angabe im Plan: drei Sätze. So rechnet auch [Plan.estimatedDuration].
  static const defaultSets = 3;

  @override
  Future<ActiveWorkout> loadWorkout(WorkoutStart start) async {
    if (start.sessionId case final id?) return _amend(id, start);

    final planId = start.planId;

    // Freies Training beginnt leer. Eine erfundene Übungsfolge wäre genau das,
    // was die Attrappe bisher tat — und was jede damit gespeicherte Einheit
    // verfälscht hat.
    if (planId == null) {
      return ActiveWorkout(
        // Auch ein freies Training kann aus einem Termin stammen — die
        // Vorgänger-App legt Schnelleinträge ohne Plan an.
        sessionId: start.scheduleId ?? '',
        exercises: const [],
        defaultRestSeconds: start.restSeconds,
      );
    }

    final all = await _plans.fetchPlans(userId);
    final plan = all.where((p) => p.id == planId).firstOrNull;
    if (plan == null) {
      throw StateError('Plan $planId nicht gefunden');
    }

    final exercises = await _exercises.fetchExercises(userId);
    final byId = {for (final e in exercises) e.id: e};

    final sessions = await _sessions.fetchSessions(userId);
    final history = ExerciseHistory.index(sessions);

    return ActiveWorkout(
      // Die Verbindung zum Kalender. Ohne sie bliebe der Termin nach dem
      // Speichern offen — `saveSession` hakt ihn über genau dieses Feld ab.
      sessionId: start.scheduleId ?? '',
      planId: plan.id,
      title: plan.name,
      defaultRestSeconds:
          plan.items.map((i) => i.restSeconds).whereType<int>().firstOrNull ??
              start.restSeconds,
      exercises: [
        for (var i = 0; i < plan.items.length; i++)
          _exercise(plan.items[i], i, byId[plan.items[i].exerciseId], history),
      ],
    );
  }

  /// Eine bestehende Einheit zum Ergänzen — **mit ihren Sätzen, abgehakt**.
  ///
  /// Was schon protokolliert ist, kommt als erledigt herein. Es unabgehakt zu
  /// zeigen hiesse, die geleistete Arbeit zur Absicht zu erklären; und beim
  /// Beenden würden nur die neuen Sätze übrig bleiben, weil der Entwurf nur
  /// Abgehaktes übernimmt.
  Future<ActiveWorkout> _amend(String sessionId, WorkoutStart start) async {
    final sessions = await _sessions.fetchSessions(userId);
    final session = sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session == null) {
      throw StateError('Einheit $sessionId nicht gefunden');
    }

    final exercises = await _exercises.fetchExercises(userId);
    final byId = {for (final e in exercises) e.id: e};
    final history = ExerciseHistory.index(sessions);

    final logged = session is StrengthSession
        ? session.exercises
        : const <LoggedExercise>[];

    return ActiveWorkout(
      sessionId: '',
      amendsSessionId: sessionId,
      defaultRestSeconds: start.restSeconds,
      exercises: [
        for (var i = 0; i < logged.length; i++)
          _fromLogged(logged[i], i, byId[logged[i].exerciseId], history),
      ],
    );
  }

  WorkoutExercise _fromLogged(
    LoggedExercise logged,
    int position,
    Exercise? exercise,
    Map<String, ExerciseHistory> history,
  ) {
    final entry = history[logged.exerciseId] ?? ExerciseHistory.empty;
    final filled = [
      for (final set in logged.sets)
        if (!set.isEmpty) set,
    ];

    return WorkoutExercise(
      id: logged.exerciseId,
      name: exercise?.name ?? logged.exerciseId,
      muscles: [for (final m in exercise?.displayMuscles ?? const []) m.wire],
      recordWeightKg: entry.recordWeightKg,
      // Beim Nachtragen zählt auch, was gespeichert ist: Trägt ein Satz eine
      // Seite, war die Übung seitengetrennt — gleich, was der Katalog heute
      // sagt.
      unilateral:
          (exercise?.unilateral ?? false) || filled.any((s) => s.side != null),
      sets: [
        for (var i = 0; i < filled.length; i++)
          WorkoutSet(
            id: '${logged.exerciseId}-$position-$i',
            type: SetType.normal,
            weight: filled[i].weight == null ? '' : '${filled[i].weight}',
            reps: filled[i].reps == null ? '' : '${filled[i].reps}',
            rpe: filled[i].rpe,
            side: filled[i].side,
            done: true,
          ),
      ],
    );
  }

  WorkoutExercise _exercise(
    PlanItem item,
    int position,
    Exercise? exercise,
    Map<String, ExerciseHistory> history,
  ) {
    final entry = history[item.exerciseId] ?? ExerciseHistory.empty;
    final previous = entry.lastSets;
    final count = item.sets ?? defaultSets;
    final unilateral = exercise?.unilateral ?? false;
    // Seitengetrennt beginnt links und wechselt ab — dieselbe Regel wie beim
    // Einschalten im Runner.
    SetSide? sideAt(int i) =>
        !unilateral ? null : (i.isEven ? SetSide.left : SetSide.right);

    return WorkoutExercise(
      id: item.exerciseId,
      // Fehlt die Übung — sie kann gelöscht worden sein —, steht die Kennung
      // da. Die Einheit bleibt startbar; ein blockierender Fehler bestrafte
      // für Datenpflege an anderer Stelle.
      name: exercise?.name ?? item.exerciseId,
      muscles: [for (final m in exercise?.displayMuscles ?? const []) m.wire],
      recordWeightKg: entry.recordWeightKg,
      // Die Zielvorgaben aus dem Plan. Sie standen bisher nur im Plan und
      // waren im Training unsichtbar — die Haltezeit vollständig.
      targetReps: item.reps,
      targetHoldSeconds: item.holdSeconds,
      unilateral: unilateral,
      sets: [
        for (var i = 0; i < count; i++)
          WorkoutSet(
            id: '${item.exerciseId}-$position-$i',
            type: SetType.normal,
            side: sideAt(i),
            // Der Satz an derselben Position vom letzten Mal. Gibt es ihn
            // nicht, bleibt die Zeile leer statt einen fremden Satz zu zeigen.
            previous: previousSet(previous, i, sideAt(i),
                [for (var j = 0; j < i; j++) sideAt(j)]),
            // **Die Zielvorgabe wird nicht vorbelegt.** Ein Feld, in dem schon
            // „8" steht, ist nach dem Abhaken eine Leistungsangabe — und zwar
            // eine, die niemand gemacht hat. Das Ziel steht daneben als
            // Referenz, nicht im Eingabefeld.
            weight: '',
            reps: '',
            hold: '',
          ),
      ],
    );
  }
}

/// Der Satz vom letzten Mal, mit dem Satz [index] verglichen wird.
///
/// Beidseitig — oder wenn das letzte Mal keine Seiten kannte — der Satz an
/// derselben Position. Seitengetrennt der k-te Satz **derselben Seite**: Der
/// zweite linke Satz heute steht neben dem zweiten linken vom letzten Mal,
/// nicht neben dem, der zufällig an derselben Stelle stand. Gibt es auf dieser
/// Seite keinen k-ten, bleibt die Zeile leer.
///
/// [before] sind die Seiten der Sätze vor [index] in der heutigen Einheit.
SetReference? previousSet(
  List<LoggedSet> last,
  int index,
  SetSide? side,
  List<SetSide?> before,
) {
  LoggedSet? match;
  if (side != null && last.any((s) => s.side != null)) {
    final k = before.where((s) => s == side).length;
    final sameSide = [
      for (final s in last)
        if (s.side == side) s
    ];
    match = k < sameSide.length ? sameSide[k] : null;
  } else {
    match = index < last.length ? last[index] : null;
  }
  if (match == null) return null;
  return SetReference(weightKg: match.weight, reps: match.reps);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
