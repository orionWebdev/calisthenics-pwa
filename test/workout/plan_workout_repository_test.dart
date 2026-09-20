import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/exercise_draft.dart';
import 'package:atem/features/exercises/domain/exercise_repository.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/history/domain/session_draft.dart';
import 'package:atem/features/history/domain/session_patch.dart';
import 'package:atem/features/history/domain/session_repository.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/plans/domain/plan_draft.dart';
import 'package:atem/features/plans/domain/plan_repository.dart';
import 'package:atem/features/workout/data/plan_workout_repository.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:flutter_test/flutter_test.dart';

class _Plans implements PlanRepository {
  _Plans(this.plans);
  final List<Plan> plans;
  @override
  Stream<List<Plan>> watchPlans(String u) => Stream.value(plans);
  @override
  Future<List<Plan>> fetchPlans(String u) async => plans;
  @override
  Future<String> savePlan(PlanDraft d) async => 'x';
  @override
  Future<void> deletePlan(String id) async {}
}

class _Exercises implements ExerciseRepository {
  _Exercises(this.exercises);
  final List<Exercise> exercises;
  @override
  Stream<List<Exercise>> watchExercises(String u) => Stream.value(exercises);
  @override
  Future<List<Exercise>> fetchExercises(String u) async => exercises;
  @override
  Future<String> saveExercise(ExerciseDraft d) async => 'x';
  @override
  Future<void> deleteExercise(String id) async {}
}

class _Sessions implements SessionRepository {
  /// Verweise auf Uhr-Einheiten — je Einheit höchstens einer.
  final links = <String, String?>{};

  _Sessions(this.sessions);
  final List<TrainingSession> sessions;
  @override
  Stream<List<TrainingSession>> watchSessions(String u) =>
      Stream.value(sessions);
  @override
  Future<List<TrainingSession>> fetchSessions(String u) async => sessions;
  @override
  Future<String> saveSession(SessionDraft d) async => 'x';

  @override
  Stream<bool> watchFromCache(String userId) => Stream.value(false);
  @override
  Future<void> updateSession(String id, SessionPatch p) async {}
  @override
  @override
  Future<void> updateSessionExercises(
      String id, List<LoggedExercise> exercises) async {}

  @override
  Future<void> linkHealthSession(String id, String? healthSessionId) async {
    links[id] = healthSessionId;
  }

  @override
  Future<void> deleteSession(String id) async {}
}

StrengthSession _session(
  String id,
  DateTime date,
  List<LoggedExercise> exercises,
) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      exercises: exercises,
    );

PlanWorkoutRepository _repo({
  List<Plan> plans = const [],
  List<Exercise> exercises = const [],
  List<TrainingSession> sessions = const [],
}) =>
    PlanWorkoutRepository(
      userId: 'u',
      plans: _Plans(plans),
      exercises: _Exercises(exercises),
      sessions: _Sessions(sessions),
    );

const _plan = Plan(
  id: 'p1',
  name: 'Oberkörper A',
  items: [
    PlanItem(exerciseId: 'bench', sets: 3, reps: '8-12', restSeconds: 120),
    PlanItem(exerciseId: 'row'),
  ],
);

const _exercises = [
  Exercise(
    id: 'bench',
    name: 'Bankdrücken',
    source: ExerciseSource.own,
    muscleGroups: [MuscleGroup.chest],
  ),
  Exercise(id: 'row', name: 'Rudern', source: ExerciseSource.own),
];

void main() {
  group('Freies Training', () {
    test('beginnt leer statt erfunden', () async {
      final w = await _repo().loadWorkout(const WorkoutStart.free());
      expect(w.exercises, isEmpty);
      expect(w.planId, isNull);
      expect(w.title, isNull,
          reason: 'ein erfundener Titel landete im Bestand');
    });

    test('übernimmt die gewählte Pausenzeit', () async {
      final w =
          await _repo().loadWorkout(const WorkoutStart.free(restSeconds: 45));
      expect(w.defaultRestSeconds, 45);
    });
  });

  group('Aus einem Plan', () {
    test('trägt Name und Kennung des Plans', () async {
      final w = await _repo(plans: [_plan], exercises: _exercises)
          .loadWorkout(const WorkoutStart(planId: 'p1'));
      expect(w.title, 'Oberkörper A');
      expect(w.planId, 'p1');
    });

    test('erzeugt so viele Sätze wie der Plan verlangt', () async {
      final w = await _repo(plans: [_plan], exercises: _exercises)
          .loadWorkout(const WorkoutStart(planId: 'p1'));
      expect(w.exercises.first.sets, hasLength(3));
      expect(
        w.exercises.last.sets,
        hasLength(PlanWorkoutRepository.defaultSets),
        reason: 'ohne Angabe im Plan: drei, wie in der Dauerschätzung',
      );
    });

    test('belegt keine Felder vor', () async {
      final w = await _repo(plans: [_plan], exercises: _exercises)
          .loadWorkout(const WorkoutStart(planId: 'p1'));
      for (final set in w.allSets) {
        expect(set.weight, isEmpty);
        expect(set.reps, isEmpty,
            reason: 'ein vorbelegtes Feld wäre nach dem Abhaken eine '
                'Leistungsangabe, die niemand gemacht hat');
        expect(set.done, isFalse);
      }
    });

    test('übernimmt die Pausenzeit des Plans', () async {
      final w = await _repo(plans: [_plan], exercises: _exercises)
          .loadWorkout(const WorkoutStart(planId: 'p1', restSeconds: 90));
      expect(w.defaultRestSeconds, 120);
    });

    test('löst Übungsnamen auf', () async {
      final w = await _repo(plans: [_plan], exercises: _exercises)
          .loadWorkout(const WorkoutStart(planId: 'p1'));
      expect(w.exercises.first.name, 'Bankdrücken');
    });

    test('eine gelöschte Übung blockiert nicht', () async {
      final w = await _repo(plans: [_plan], exercises: const [])
          .loadWorkout(const WorkoutStart(planId: 'p1'));
      expect(w.exercises.first.name, 'bench',
          reason: 'die Kennung tritt an die Stelle des Namens');
      expect(w.exercises, hasLength(2));
    });

    test('ein unbekannter Plan ist ein Fehler, keine leere Einheit', () async {
      expect(
        () =>
            _repo(plans: [_plan]).loadWorkout(const WorkoutStart(planId: 'x')),
        throwsStateError,
      );
    });
  });

  group('Referenzen aus der Historie', () {
    final sessions = [
      _session('alt', DateTime(2026, 5, 1), [
        const LoggedExercise(exerciseId: 'bench', sets: [
          LoggedSet(reps: 8, weight: 95),
        ]),
      ]),
      _session('neu', DateTime(2026, 8, 1), [
        const LoggedExercise(exerciseId: 'bench', sets: [
          LoggedSet(reps: 10, weight: 80),
          LoggedSet(reps: 8, weight: 85),
        ]),
      ]),
    ];

    test('zeigt die jüngste Einheit, nicht den Durchschnitt', () async {
      final w = await _repo(
        plans: [_plan],
        exercises: _exercises,
        sessions: sessions,
      ).loadWorkout(const WorkoutStart(planId: 'p1'));

      final sets = w.exercises.first.sets;
      expect(sets[0].previous?.weightKg, 80);
      expect(sets[0].previous?.reps, 10);
      expect(sets[1].previous?.weightKg, 85);
    });

    test('ein Satz ohne Gegenstück bleibt leer', () async {
      final w = await _repo(
        plans: [_plan],
        exercises: _exercises,
        sessions: sessions,
      ).loadWorkout(const WorkoutStart(planId: 'p1'));

      expect(w.exercises.first.sets[2].previous, isNull,
          reason: 'ein fremder Satz an dieser Stelle wäre eine Erfindung');
    });

    test('der Bestwert kommt aus der ganzen Historie', () async {
      final w = await _repo(
        plans: [_plan],
        exercises: _exercises,
        sessions: sessions,
      ).loadWorkout(const WorkoutStart(planId: 'p1'));

      expect(w.exercises.first.recordWeightKg, 95,
          reason: 'aus der älteren Einheit — nicht nur aus der jüngsten');
    });

    test('ohne Historie gibt es keinen Bestwert', () async {
      final w = await _repo(plans: [_plan], exercises: _exercises)
          .loadWorkout(const WorkoutStart(planId: 'p1'));
      expect(w.exercises.first.recordWeightKg, isNull,
          reason: 'kein Chip statt „PR —"');
      expect(w.exercises.first.sets.first.previous, isNull);
    });

    test('leere Sätze zählen nicht als Referenz', () async {
      final w = await _repo(
        plans: [_plan],
        exercises: _exercises,
        sessions: [
          _session('leer', DateTime(2026, 8, 2), [
            const LoggedExercise(exerciseId: 'bench', sets: [LoggedSet()]),
          ]),
          ...sessions,
        ],
      ).loadWorkout(const WorkoutStart(planId: 'p1'));

      expect(w.exercises.first.sets.first.previous?.weightKg, 80,
          reason: 'die leere Einheit wird übersprungen');
    });
  });

  group('Der Kalendertermin', () {
    test('wandert in die Einheit — sonst bleibt er für immer offen', () async {
      final w = await _repo(plans: [_plan], exercises: _exercises).loadWorkout(
        const WorkoutStart(planId: 'p1', scheduleId: 't1'),
      );
      expect(w.sessionId, 't1',
          reason: '`saveSession` hakt den Termin über genau dieses Feld ab');
    });

    test('gilt auch ohne Plan — Schnelleinträge haben keinen', () async {
      final w = await _repo().loadWorkout(const WorkoutStart(scheduleId: 't1'));
      expect(w.sessionId, 't1');
      expect(w.exercises, isEmpty);
    });

    test('ohne Termin bleibt das Feld leer', () async {
      final w = await _repo(plans: [_plan], exercises: _exercises)
          .loadWorkout(const WorkoutStart(planId: 'p1'));
      expect(w.sessionId, isEmpty);
    });
  });

  group('Seitengetrennte Übungen', () {
    const exercises = [
      Exercise(
        id: 'bench',
        name: 'Einarmiges Rudern',
        source: ExerciseSource.own,
        unilateral: true,
      ),
      Exercise(id: 'row', name: 'Rudern', source: ExerciseSource.own),
    ];

    test('beginnen links und wechseln ab', () async {
      final w = await _repo(plans: [_plan], exercises: exercises)
          .loadWorkout(const WorkoutStart(planId: 'p1'));

      expect(w.exercises.first.unilateral, isTrue);
      expect([for (final s in w.exercises.first.sets) s.side],
          [SetSide.left, SetSide.right, SetSide.left]);
      expect(w.exercises.last.unilateral, isFalse);
      expect(w.exercises.last.sets.first.side, isNull);
    });

    test('vergleichen mit derselben Seite vom letzten Mal', () async {
      final sessions = [
        _session('neu', DateTime(2026, 8, 1), [
          const LoggedExercise(exerciseId: 'bench', sets: [
            LoggedSet(reps: 10, weight: 20, side: SetSide.left),
            LoggedSet(reps: 9, weight: 20, side: SetSide.left),
            LoggedSet(reps: 8, weight: 22, side: SetSide.right),
          ]),
        ]),
      ];
      final w = await _repo(
        plans: [_plan],
        exercises: exercises,
        sessions: sessions,
      ).loadWorkout(const WorkoutStart(planId: 'p1'));

      final sets = w.exercises.first.sets;
      // Satz 1 links ↔ erster linker, Satz 2 rechts ↔ erster rechter,
      // Satz 3 links ↔ zweiter linker — nicht der an derselben Position.
      expect(sets[0].previous?.reps, 10);
      expect(sets[1].previous?.weightKg, 22);
      expect(sets[2].previous?.reps, 9);
    });

    test('ohne Seiten vom letzten Mal gilt die Position', () async {
      final sessions = [
        _session('neu', DateTime(2026, 8, 1), [
          const LoggedExercise(exerciseId: 'bench', sets: [
            LoggedSet(reps: 10, weight: 20),
            LoggedSet(reps: 8, weight: 22),
          ]),
        ]),
      ];
      final w = await _repo(
        plans: [_plan],
        exercises: exercises,
        sessions: sessions,
      ).loadWorkout(const WorkoutStart(planId: 'p1'));

      expect(w.exercises.first.sets[1].previous?.weightKg, 22);
      expect(w.exercises.first.sets[2].previous, isNull);
    });

    test('Nachtragen bringt Seite und Anstrengung mit', () async {
      final session = StrengthSession(
        id: 'alt',
        userId: 'u',
        date: DateTime(2026, 7, 3),
        createdAt: DateTime(2026, 7, 3),
        bodyweight: false,
        exercises: const [
          LoggedExercise(exerciseId: 'row', sets: [
            LoggedSet(reps: 8, weight: 30, rpe: 8, side: SetSide.right),
          ]),
        ],
      );
      final w = await _repo(exercises: exercises, sessions: [session])
          .loadWorkout(const WorkoutStart.session('alt'));

      final ex = w.exercises.single;
      expect(ex.unilateral, isTrue,
          reason: 'ein Satz mit Seite war seitengetrennt, gleich was der '
              'Katalog heute sagt');
      expect(ex.sets.single.side, SetSide.right);
      expect(ex.sets.single.rpe, 8);
    });
  });

  group('Sätze nachtragen', () {
    final session = StrengthSession(
      id: 'alt',
      userId: 'u',
      date: DateTime(2026, 7, 3),
      createdAt: DateTime(2026, 7, 3),
      bodyweight: false,
      exercises: const [
        LoggedExercise(exerciseId: 'bench', sets: [
          LoggedSet(reps: 8, weight: 80),
          LoggedSet(),
        ]),
      ],
    );

    test('bringt die vorhandenen Sätze abgehakt herein', () async {
      final w = await _repo(exercises: _exercises, sessions: [session])
          .loadWorkout(const WorkoutStart.session('alt'));

      expect(w.amendsSessionId, 'alt');
      expect(w.exercises, hasLength(1));
      expect(w.exercises.first.name, 'Bankdrücken');
      // Der leere Satz fällt weg, der gefüllte kommt erledigt herein.
      expect(w.exercises.first.sets, hasLength(1));
      expect(w.exercises.first.sets.first.done, isTrue,
          reason: 'unabgehakt bliebe beim Beenden nichts davon übrig');
      expect(w.exercises.first.sets.first.weight, '80.0');
      expect(w.exercises.first.sets.first.reps, '8');
    });

    test('eine Einheit ohne Übungen beginnt leer, aber ergänzend', () async {
      // 16 der 63 Krafteinheiten im Bestand sind so.
      final leer = StrengthSession(
        id: 'leer',
        userId: 'u',
        date: DateTime(2026, 7, 3),
        createdAt: DateTime(2026, 7, 3),
        bodyweight: false,
      );
      final w = await _repo(sessions: [leer])
          .loadWorkout(const WorkoutStart.session('leer'));

      expect(w.exercises, isEmpty);
      expect(w.amendsSessionId, 'leer',
          reason: 'sonst entstünde beim Speichern eine zweite Einheit');
    });

    test('eine unbekannte Einheit ist ein Fehler', () {
      expect(
        () => _repo().loadWorkout(const WorkoutStart.session('gibtsnicht')),
        throwsStateError,
      );
    });

    test('ergänzen ist kein freies Training', () {
      expect(const WorkoutStart.session('x').isFree, isFalse);
      expect(const WorkoutStart.session('x').amends, isTrue);
      expect(const WorkoutStart.free().amends, isFalse);
    });
  });

  group('WorkoutStart', () {
    test('gleiche Werte sind gleich — sonst legte Riverpod zwei Einheiten an',
        () {
      expect(const WorkoutStart(planId: 'p1', restSeconds: 90),
          const WorkoutStart(planId: 'p1', restSeconds: 90));
      expect(const WorkoutStart(planId: 'p1').hashCode,
          const WorkoutStart(planId: 'p1').hashCode);
    });

    test('freies Training unterscheidet sich von einem Plan', () {
      expect(const WorkoutStart.free(), isNot(const WorkoutStart(planId: '')));
      expect(const WorkoutStart.free().isFree, isTrue);
    });

    test('der Termin gehört zur Gleichheit', () {
      // Sonst zeigte Riverpod für zwei verschiedene Termine dieselbe Einheit.
      expect(const WorkoutStart(planId: 'p', scheduleId: 'a'),
          isNot(const WorkoutStart(planId: 'p', scheduleId: 'b')));
    });
  });
}
