import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/history/domain/muscle_balance.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _heute = DateTime(2026, 8, 28);

const _catalogue = [
  Exercise(
    id: 'pull_up',
    name: 'Klimmzug',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.back],
    secondaryMuscles: [MuscleGroup.biceps],
  ),
  Exercise(
    id: 'squat',
    name: 'Kniebeuge',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.quads],
    secondaryMuscles: [MuscleGroup.glutes],
  ),
  Exercise(
    id: 'ohne_muskel',
    name: 'Eigene ohne Angabe',
    source: ExerciseSource.own,
  ),
];

StrengthSession _strength(
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

MuscleShare _share(MuscleBalance balance, MuscleGroup muscle) =>
    balance.shares.firstWhere((s) => s.muscle == muscle);

void main() {
  group('Zuordnung', () {
    test('ein Satz zählt für jeden Muskel der Übung', () {
      final balance = MuscleBalance.compute(
        [
          _strength('a', _heute, [
            const LoggedExercise(exerciseId: 'pull_up', sets: [
              LoggedSet(reps: 8),
              LoggedSet(reps: 6),
            ]),
          ]),
        ],
        _catalogue,
        _heute,
      );

      expect(_share(balance, MuscleGroup.back).sets, 2);
      expect(_share(balance, MuscleGroup.biceps).sets, 2,
          reason: 'nicht anteilig — eine Gewichtung hat niemand hinterlegt');
      expect(balance.totalSets, 4,
          reason: 'die Summe übersteigt die absolvierten Sätze, '
              'und genau deshalb ist sie kein Anteil eines Ganzen');
    });

    test('die Beinfamilie fällt auf einen Ton zusammen', () {
      final balance = MuscleBalance.compute(
        [
          _strength('a', _heute, [
            const LoggedExercise(exerciseId: 'squat', sets: [
              LoggedSet(reps: 5, weight: 100),
            ]),
          ]),
        ],
        _catalogue,
        _heute,
      );

      // Quadrizeps und Gesäß sind beide „Beine" — der Satz zählt trotzdem
      // nur einmal, weil die Menge dedupliziert.
      expect(_share(balance, MuscleGroup.legs).sets, 1);
      expect(balance.totalSets, 1);
    });

    test('es gibt genau neun Einträge, in der Reihenfolge der Filter', () {
      final balance = MuscleBalance.compute(const [], _catalogue, _heute);
      expect(balance.shares.map((s) => s.muscle), MuscleGroup.filters);
    });
  });

  group('Volumen', () {
    test('nur Sätze mit Gewicht und Wiederholungen', () {
      final balance = MuscleBalance.compute(
        [
          _strength('a', _heute, [
            const LoggedExercise(exerciseId: 'squat', sets: [
              LoggedSet(reps: 5, weight: 100),
              LoggedSet(reps: 5),
            ]),
          ]),
        ],
        _catalogue,
        _heute,
      );
      expect(_share(balance, MuscleGroup.legs).volume, 500);
      expect(_share(balance, MuscleGroup.legs).sets, 2,
          reason: 'gemacht wurden beide');
    });
  });

  group('Das Zeitfenster', () {
    test('schneidet ab, was älter ist', () {
      final balance = MuscleBalance.compute(
        [
          _strength('drin', _heute.subtract(const Duration(days: 10)), [
            const LoggedExercise(
                exerciseId: 'squat', sets: [LoggedSet(reps: 5)]),
          ]),
          _strength('draussen', _heute.subtract(const Duration(days: 40)), [
            const LoggedExercise(
                exerciseId: 'squat', sets: [LoggedSet(reps: 5)]),
          ]),
        ],
        _catalogue,
        _heute,
      );
      expect(balance.sessionsInWindow, 1);
      expect(_share(balance, MuscleGroup.legs).sets, 1);
    });

    test('der Bezugstag selbst zählt mit', () {
      final balance = MuscleBalance.compute(
        [
          _strength('heute', _heute, [
            const LoggedExercise(
                exerciseId: 'squat', sets: [LoggedSet(reps: 5)]),
          ]),
        ],
        _catalogue,
        _heute,
      );
      expect(balance.sessionsInWindow, 1);
    });
  });

  group('Was nicht abgebildet ist — und benannt wird', () {
    test('Krafteinheiten ohne Übungen werden gezählt', () {
      // Im Bestand 16 von 63. Sie verschwinden zu lassen hiesse, eine Balance
      // über die knappe Hälfte als Balance über das Training auszugeben.
      final balance = MuscleBalance.compute(
        [
          _strength('leer', _heute, const []),
          _strength('voll', _heute, [
            const LoggedExercise(
                exerciseId: 'squat', sets: [LoggedSet(reps: 5)]),
          ]),
        ],
        _catalogue,
        _heute,
      );
      expect(balance.sessionsInWindow, 2);
      expect(balance.sessionsWithoutExercises, 1);
      expect(balance.sessionsCounted, 1);
      expect(balance.coverage, 0.5);
    });

    test('Cardio zählt ins Fenster, aber nicht in die Balance', () {
      final balance = MuscleBalance.compute(
        [
          CardioSession(
              id: 'c', userId: 'u', date: _heute, createdAt: _heute),
          _strength('s', _heute, [
            const LoggedExercise(
                exerciseId: 'squat', sets: [LoggedSet(reps: 5)]),
          ]),
        ],
        _catalogue,
        _heute,
      );
      expect(balance.sessionsInWindow, 2);
      expect(balance.sessionsCounted, 1);
      expect(balance.coverage, 0.5,
          reason: 'die Zahl gehört an die Oberfläche — bei 0,5 ist jede '
              'Aussage über Balance eine Aussage über die Hälfte');
    });

    test('eine gelöschte Übung wird benannt, nicht verschluckt', () {
      final balance = MuscleBalance.compute(
        [
          _strength('a', _heute, [
            const LoggedExercise(
                exerciseId: 'geloescht', sets: [LoggedSet(reps: 5)]),
          ]),
        ],
        _catalogue,
        _heute,
      );
      expect(balance.unresolvedExerciseIds, {'geloescht'});
      expect(balance.isEmpty, isTrue);
      expect(balance.sessionsCounted, 0);
    });

    test('eine Übung ohne Muskelangabe trägt nichts bei', () {
      final balance = MuscleBalance.compute(
        [
          _strength('a', _heute, [
            const LoggedExercise(
                exerciseId: 'ohne_muskel', sets: [LoggedSet(reps: 5)]),
          ]),
        ],
        _catalogue,
        _heute,
      );
      expect(balance.isEmpty, isTrue);
      expect(balance.unresolvedExerciseIds, isEmpty,
          reason: 'sie existiert ja — ihr fehlt nur die Angabe');
    });

    test('ohne Einheiten im Fenster gibt es keine Abdeckung', () {
      final balance = MuscleBalance.compute(const [], _catalogue, _heute);
      expect(balance.coverage, isNull);
      expect(balance.isEmpty, isTrue);
      expect(balance.maxSets, 0);
    });
  });

  test('welche Übungen beigetragen haben, bleibt nachvollziehbar', () {
    final balance = MuscleBalance.compute(
      [
        _strength('a', _heute, [
          const LoggedExercise(
              exerciseId: 'pull_up', sets: [LoggedSet(reps: 8)]),
          const LoggedExercise(
              exerciseId: 'squat', sets: [LoggedSet(reps: 5)]),
        ]),
      ],
      _catalogue,
      _heute,
    );
    expect(_share(balance, MuscleGroup.back).exerciseIds, {'pull_up'});
    expect(_share(balance, MuscleGroup.legs).exerciseIds, {'squat'});
  });
}
