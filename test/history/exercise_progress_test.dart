import 'package:atem/features/history/domain/exercise_progress.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _ref = DateTime(2026, 9, 16);

StrengthSession _s(
  String id,
  DateTime date,
  Map<String, List<LoggedSet>> exercises,
) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      exercises: [
        for (final e in exercises.entries)
          LoggedExercise(exerciseId: e.key, sets: e.value),
      ],
    );

DateTime _daysAgo(int n) => DateTime(_ref.year, _ref.month, _ref.day - n, 10);

void main() {
  group('Mass', () {
    test('Gewicht, sobald eine Ausführung Zusatzlast trägt', () {
      final p = ExerciseProgress.compute([
        _s('a', _daysAgo(20), {
          'dip': [const LoggedSet(reps: 8, weight: 10)]
        }),
        _s('b', _daysAgo(2), {
          'dip': [const LoggedSet(reps: 6, weight: 12.5)]
        }),
      ], _ref);
      expect(p.entries.single.measure, ProgressMeasure.weight);
      expect(p.entries.single.value, 12.5);
      expect(p.entries.single.previousBest, 10);
    });

    test('Wiederholungen bei Körpergewicht — bester Einzelsatz', () {
      final p = ExerciseProgress.compute([
        _s('a', _daysAgo(10), {
          'pull_up': [const LoggedSet(reps: 8), const LoggedSet(reps: 7)]
        }),
        _s('b', _daysAgo(1), {
          'pull_up': [const LoggedSet(reps: 6), const LoggedSet(reps: 9)]
        }),
      ], _ref);
      final e = p.entries.single;
      expect(e.measure, ProgressMeasure.reps);
      expect(e.value, 9);
      expect(e.previousBest, 8);
      expect(e.delta, 1);
    });

    test('Haltezeit, wenn weder Gewicht noch Wiederholungen', () {
      final p = ExerciseProgress.compute([
        _s('a', _daysAgo(10), {
          'plank': [const LoggedSet(holdSeconds: 40, rawType: 'hold')]
        }),
        _s('b', _daysAgo(1), {
          'plank': [const LoggedSet(holdSeconds: 45, rawType: 'hold')]
        }),
      ], _ref);
      expect(p.entries.single.measure, ProgressMeasure.hold);
      expect(p.entries.single.value, 45);
    });
  });

  test('Aufwärmsätze zählen nicht', () {
    final p = ExerciseProgress.compute([
      _s('a', _daysAgo(10), {
        'pull_up': [const LoggedSet(reps: 8)]
      }),
      _s('b', _daysAgo(1), {
        'pull_up': [
          const LoggedSet(reps: 12, rawType: 'warmup'),
          const LoggedSet(reps: 8),
        ]
      }),
    ], _ref);
    expect(p.entries, isEmpty,
        reason: '12 Wdh im Aufwärmsatz sind kein Bestwert');
    expect(p.exercisesCompared, 1);
  });

  test('die erste Ausführung ist kein Fortschritt', () {
    final p = ExerciseProgress.compute([
      _s('a', _daysAgo(1), {
        'pull_up': [const LoggedSet(reps: 8)]
      }),
    ], _ref);
    expect(p.entries, isEmpty);
    expect(p.hasEnough, isFalse);
    expect(p.mostOccurrences, 1);
  });

  test('Gleichstand ist kein Fortschritt', () {
    final p = ExerciseProgress.compute([
      _s('a', _daysAgo(10), {
        'pull_up': [const LoggedSet(reps: 8)]
      }),
      _s('b', _daysAgo(1), {
        'pull_up': [const LoggedSet(reps: 8)]
      }),
    ], _ref);
    expect(p.hasEnough, isTrue);
    expect(p.entries, isEmpty);
    expect(p.exercisesCompared, 1);
  });

  group('Fenstergrenze', () {
    test('vor 27 Tagen zählt (28. Kalendertag), vor 28 nicht', () {
      List<TrainingSession> at(int daysAgo) => [
            _s('a', _daysAgo(60), {
              'pull_up': [const LoggedSet(reps: 5)]
            }),
            _s('b', _daysAgo(daysAgo), {
              'pull_up': [const LoggedSet(reps: 9)]
            }),
          ];
      expect(ExerciseProgress.compute(at(27), _ref).entries, hasLength(1));
      expect(ExerciseProgress.compute(at(28), _ref).entries, isEmpty);
    });

    test('ein früherer Bestwert ausserhalb des Fensters zählt als Vorher', () {
      final p = ExerciseProgress.compute([
        _s('a', _daysAgo(90), {
          'pull_up': [const LoggedSet(reps: 12)]
        }),
        _s('b', _daysAgo(5), {
          'pull_up': [const LoggedSet(reps: 10)]
        }),
      ], _ref);
      expect(p.entries, isEmpty);
    });
  });

  test('neueste zuerst, je Übung nur der jüngste Bestwert, Zähler stimmen', () {
    final p = ExerciseProgress.compute([
      _s('a', _daysAgo(20), {
        'pull_up': [const LoggedSet(reps: 6)],
        'dip': [const LoggedSet(reps: 10)],
      }),
      _s('b', _daysAgo(10), {
        'pull_up': [const LoggedSet(reps: 7)],
        'dip': [const LoggedSet(reps: 12)],
      }),
      _s('c', _daysAgo(3), {
        'pull_up': [const LoggedSet(reps: 8)],
      }),
      _s('d', _daysAgo(2), {
        'squat': [const LoggedSet(reps: 20)],
      }),
    ], _ref);
    expect(p.entries.map((e) => e.exerciseId), ['pull_up', 'dip']);
    expect(p.entries.first.value, 8);
    expect(p.entries.first.previousBest, 7);
    expect(p.exercisesWithTwoOrMore, 2);
    expect(p.exercisesCompared, 2);
    expect(p.sessionsInWindow, 4);
    expect(p.mostOccurrences, 3);
  });
}
