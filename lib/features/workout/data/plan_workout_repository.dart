import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/exercise_repository.dart';
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
    final planId = start.planId;

    // Freies Training beginnt leer. Eine erfundene Übungsfolge wäre genau das,
    // was die Attrappe bisher tat — und was jede damit gespeicherte Einheit
    // verfälscht hat.
    if (planId == null) {
      return ActiveWorkout(
        sessionId: '',
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
    final history = _History.from(sessions);

    return ActiveWorkout(
      sessionId: '',
      planId: plan.id,
      title: plan.name,
      defaultRestSeconds: plan.items
              .map((i) => i.restSeconds)
              .whereType<int>()
              .firstOrNull ??
          start.restSeconds,
      exercises: [
        for (var i = 0; i < plan.items.length; i++)
          _exercise(plan.items[i], i, byId[plan.items[i].exerciseId], history),
      ],
    );
  }

  WorkoutExercise _exercise(
    PlanItem item,
    int position,
    Exercise? exercise,
    _History history,
  ) {
    final previous = history.lastSets(item.exerciseId);
    final count = item.sets ?? defaultSets;

    return WorkoutExercise(
      id: item.exerciseId,
      // Fehlt die Übung — sie kann gelöscht worden sein —, steht die Kennung
      // da. Die Einheit bleibt startbar; ein blockierender Fehler bestrafte
      // für Datenpflege an anderer Stelle.
      name: exercise?.name ?? item.exerciseId,
      muscles: [for (final m in exercise?.displayMuscles ?? const []) m.wire],
      recordWeightKg: history.record(item.exerciseId),
      sets: [
        for (var i = 0; i < count; i++)
          WorkoutSet(
            id: '${item.exerciseId}-$position-$i',
            type: SetType.normal,
            // Der Satz an derselben Position vom letzten Mal. Gibt es ihn
            // nicht, bleibt die Zeile leer statt einen fremden Satz zu zeigen.
            previous: i < previous.length ? previous[i] : null,
            // **Die Zielvorgabe wird nicht vorbelegt.** Ein Feld, in dem schon
            // „8" steht, ist nach dem Abhaken eine Leistungsangabe — und zwar
            // eine, die niemand gemacht hat. Das Ziel steht daneben als
            // Referenz, nicht im Eingabefeld.
            weight: '',
            reps: '',
          ),
      ],
    );
  }
}

/// Was die Historie über einzelne Übungen weiß.
///
/// Einmal vorgerechnet: Ein Plan mit acht Übungen liefe sonst achtmal über
/// alle 137 Einheiten.
class _History {
  const _History(this._lastSets, this._records);

  final Map<String, List<SetReference>> _lastSets;
  final Map<String, double> _records;

  List<SetReference> lastSets(String exerciseId) =>
      _lastSets[exerciseId] ?? const [];

  double? record(String exerciseId) => _records[exerciseId];

  static _History from(List<TrainingSession> sessions) {
    final lastSets = <String, List<SetReference>>{};
    final records = <String, double>{};

    // Neueste zuerst — so gewinnt beim ersten Treffer die jüngste Einheit.
    final sorted = [...sessions]..sort((a, b) => b.date.compareTo(a.date));

    for (final session in sorted) {
      if (session is! StrengthSession) continue;
      for (final exercise in session.exercises) {
        final sets = [
          for (final set in exercise.sets)
            if (!set.isEmpty)
              SetReference(weightKg: set.weight, reps: set.reps),
        ];
        if (sets.isEmpty) continue;

        lastSets.putIfAbsent(exercise.exerciseId, () => sets);

        for (final set in sets) {
          final weight = set.weightKg;
          if (weight == null) continue;
          final best = records[exercise.exerciseId];
          if (best == null || weight > best) {
            records[exercise.exerciseId] = weight;
          }
        }
      }
    }

    return _History(lastSets, records);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
