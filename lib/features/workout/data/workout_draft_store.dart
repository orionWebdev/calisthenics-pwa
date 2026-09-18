import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/workout_clock.dart';
import '../domain/workout_session.dart';
import '../domain/workout_start.dart';
import '../../history/domain/training_session.dart' show SetSide;

/// Der Zwischenstand einer laufenden Einheit — **auf der Platte, nicht im
/// Bildschirmzustand**.
///
/// ## Der Anlass
///
/// Eine Zurück-Geste beendete das Training vollständig: kein Zwischenstand,
/// keine Rückfrage, die abgehakten Sätze weg. Dasselbe passierte, wenn Android
/// die App im Hintergrund abräumte — bei einer Einheit über 45 Minuten ist das
/// kein Randfall.
///
/// ## Warum eine Datei und kein Firestore-Dokument
///
/// Ein Zwischenstand ist **kein Bestand**. Er gehört niemandem ausser dem
/// Gerät, auf dem gerade trainiert wird, er ändert sich alle paar Sekunden,
/// und er darf unter keinen Umständen in einer Auswertung auftauchen. Ihn nach
/// Firestore zu schreiben hiesse, Dutzende Schreibvorgänge je Einheit zu
/// erzeugen für Daten, die in dem Moment wertlos werden, in dem die Einheit
/// endet.
///
/// Eine einzelne JSON-Datei reicht: Es gibt genau einen laufenden Zwischenstand
/// je Gerät, und wer zwei Trainings gleichzeitig macht, hat ein anderes Problem.
///
/// ## Was beim Wiederfinden passiert
///
/// Nichts von allein. Der Runner fragt, ob fortgesetzt oder verworfen werden
/// soll — ein Zwischenstand, der sich selbst wieder öffnet, wäre eine
/// Überraschung, und ein alter von gestern eine falsche.
class WorkoutDraftStore {
  const WorkoutDraftStore();

  static const fileName = 'atem-workout-draft.json';

  /// Älter als das: Der Zwischenstand wird nicht mehr angeboten.
  ///
  /// Ein Training, das seit zwölf Stunden offen ist, ist keins mehr — es ist
  /// ein vergessener Bildschirm. Ihn anzubieten hiesse, jemandem eine Einheit
  /// von gestern als „läuft noch" zu verkaufen.
  static const maxAge = Duration(hours: 12);

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<void> save(WorkoutDraft draft) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(draft.toJson()));
  }

  /// Liest den Zwischenstand. `null`, wenn keiner da, er unlesbar oder zu alt
  /// ist — in allen drei Fällen gibt es nichts fortzusetzen.
  Future<WorkoutDraft?> read(DateTime now) async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, Object?>) return null;
      final draft = WorkoutDraft.fromJson(json);
      if (draft == null) return null;
      if (now.difference(draft.clock.startedAt) > maxAge) {
        await clear();
        return null;
      }
      return draft;
    } catch (_) {
      // Ein kaputter Zwischenstand ist kein Fehler, den jemand beheben kann.
      // Er wird verworfen, und das Training beginnt neu.
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Nichts zu tun: Bleibt die Datei liegen, wird sie beim nächsten Lesen
      // überschrieben oder als zu alt verworfen.
    }
  }
}

/// Was gesichert wird.
class WorkoutDraft {
  const WorkoutDraft({
    required this.start,
    required this.clock,
    required this.workout,
    required this.exerciseIndex,
  });

  final WorkoutStart start;
  final WorkoutClock clock;
  final ActiveWorkout workout;

  /// Bei welcher Übung man stand.
  final int exerciseIndex;

  Map<String, Object?> toJson() => {
        'start': {
          if (start.planId != null) 'planId': start.planId,
          if (start.scheduleId != null) 'scheduleId': start.scheduleId,
          if (start.sessionId != null) 'sessionId': start.sessionId,
          'restSeconds': start.restSeconds,
        },
        'clock': clock.toJson(),
        'exerciseIndex': exerciseIndex,
        'workout': {
          'sessionId': workout.sessionId,
          if (workout.amendsSessionId != null)
            'amendsSessionId': workout.amendsSessionId,
          if (workout.planId != null) 'planId': workout.planId,
          if (workout.title != null) 'title': workout.title,
          'notes': workout.notes,
          'defaultRestSeconds': workout.defaultRestSeconds,
          'exercises': [
            for (final exercise in workout.exercises)
              {
                'id': exercise.id,
                'name': exercise.name,
                'muscles': exercise.muscles,
                if (exercise.recordWeightKg != null)
                  'recordWeightKg': exercise.recordWeightKg,
                if (exercise.targetHoldSeconds != null)
                  'targetHoldSeconds': exercise.targetHoldSeconds,
                if (exercise.targetReps != null)
                  'targetReps': exercise.targetReps,
                'sets': [
                  for (final set in exercise.sets)
                    {
                      'id': set.id,
                      'type': set.type.wire,
                      'weight': set.weight,
                      'reps': set.reps,
                      'hold': set.hold,
                      'done': set.done,
                      if (set.rpe != null) 'rpe': set.rpe,
                      if (set.side != null) 'side': set.side!.wire,
                      if (set.previous != null)
                        'previous': {
                          if (set.previous!.weightKg != null)
                            'weightKg': set.previous!.weightKg,
                          if (set.previous!.reps != null)
                            'reps': set.previous!.reps,
                        },
                    },
                ],
              },
          ],
        },
      };

  static WorkoutDraft? fromJson(Map<String, Object?> json) {
    final clock = WorkoutClock.fromJson(
        (json['clock'] as Map?)?.cast<String, Object?>() ?? const {});
    final workout = (json['workout'] as Map?)?.cast<String, Object?>();
    final start = (json['start'] as Map?)?.cast<String, Object?>();
    if (clock == null || workout == null) return null;

    return WorkoutDraft(
      start: WorkoutStart(
        planId: start?['planId'] as String?,
        scheduleId: start?['scheduleId'] as String?,
        sessionId: start?['sessionId'] as String?,
        restSeconds: (start?['restSeconds'] as num?)?.round() ?? 90,
      ),
      clock: clock,
      exerciseIndex: (json['exerciseIndex'] as num?)?.round() ?? 0,
      workout: ActiveWorkout(
        sessionId: workout['sessionId'] as String? ?? '',
        amendsSessionId: workout['amendsSessionId'] as String?,
        planId: workout['planId'] as String?,
        title: workout['title'] as String?,
        notes: workout['notes'] as String? ?? '',
        defaultRestSeconds:
            (workout['defaultRestSeconds'] as num?)?.round() ?? 90,
        exercises: [
          for (final raw in (workout['exercises'] as List? ?? const []))
            if (raw is Map) _exercise(raw.cast<String, Object?>()),
        ],
      ),
    );
  }

  static WorkoutExercise _exercise(Map<String, Object?> json) =>
      WorkoutExercise(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        muscles: [
          for (final m in (json['muscles'] as List? ?? const [])) '$m',
        ],
        recordWeightKg: (json['recordWeightKg'] as num?)?.toDouble(),
        targetHoldSeconds: (json['targetHoldSeconds'] as num?)?.round(),
        targetReps: json['targetReps'] as String?,
        sets: [
          for (final raw in (json['sets'] as List? ?? const []))
            if (raw is Map) _set(raw.cast<String, Object?>()),
        ],
      );

  static WorkoutSet _set(Map<String, Object?> json) {
    final previous = (json['previous'] as Map?)?.cast<String, Object?>();
    return WorkoutSet(
      id: json['id'] as String? ?? '',
      type: SetType.values.firstWhere(
        (t) => t.wire == json['type'],
        orElse: () => SetType.normal,
      ),
      weight: json['weight'] as String? ?? '',
      reps: json['reps'] as String? ?? '',
      hold: json['hold'] as String? ?? '',
      done: json['done'] == true,
      rpe: (json['rpe'] as num?)?.round(),
      side: SetSide.fromWire(json['side']),
      previous: previous == null
          ? null
          : SetReference(
              weightKg: (previous['weightKg'] as num?)?.toDouble(),
              reps: (previous['reps'] as num?)?.round(),
            ),
    );
  }
}
