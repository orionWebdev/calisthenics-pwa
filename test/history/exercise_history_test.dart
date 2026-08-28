import 'package:atem/features/history/domain/exercise_history.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

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

LoggedExercise _bench(List<LoggedSet> sets) =>
    LoggedExercise(exerciseId: 'bench', sets: sets);

void main() {
  final sessions = [
    _session('alt', DateTime(2026, 5, 1), [
      _bench(const [LoggedSet(reps: 8, weight: 95)]),
    ]),
    _session('mitte', DateTime(2026, 6, 15), [
      _bench(const [LoggedSet(reps: 6, weight: 100)]),
      const LoggedExercise(exerciseId: 'row', sets: [
        LoggedSet(reps: 10, weight: 60),
      ]),
    ]),
    _session('neu', DateTime(2026, 8, 1), [
      _bench(const [
        LoggedSet(reps: 10, weight: 80),
        LoggedSet(reps: 8, weight: 85),
      ]),
    ]),
  ];

  group('Reihenfolge', () {
    test('neueste Ausführung zuerst', () {
      final history = ExerciseHistory.of(sessions, 'bench');
      expect(history.occurrences.map((o) => o.sessionId),
          ['neu', 'mitte', 'alt']);
      expect(history.lastDate, DateTime(2026, 8, 1));
      expect(history.firstDate, DateTime(2026, 5, 1));
    });

    test('die letzten Sätze sind die der jüngsten Ausführung', () {
      final history = ExerciseHistory.of(sessions, 'bench');
      expect(history.lastSets, hasLength(2));
      expect(history.lastSets.first.weight, 80);
    });
  });

  group('Bestwert', () {
    test('kommt aus der ganzen Historie, nicht aus der jüngsten', () {
      expect(ExerciseHistory.of(sessions, 'bench').recordWeightKg, 100);
    });

    test('nennt die Ausführung, in der er erreicht wurde', () {
      final record = ExerciseHistory.of(sessions, 'bench').recordOccurrence;
      expect(record?.sessionId, 'mitte');
      expect(record?.date, DateTime(2026, 6, 15));
    });

    test('die früheste zählt, wenn er zweimal erreicht wurde', () {
      final twice = [
        _session('a', DateTime(2026, 1, 1),
            [_bench(const [LoggedSet(reps: 5, weight: 100)])]),
        _session('b', DateTime(2026, 2, 1),
            [_bench(const [LoggedSet(reps: 5, weight: 100)])]),
      ];
      expect(ExerciseHistory.of(twice, 'bench').recordOccurrence?.sessionId,
          'a', reason: 'wann es zum ersten Mal ging, ist die Auskunft');
    });

    test('ohne Gewicht gibt es keinen', () {
      final holds = [
        _session('a', DateTime(2026, 1, 1), [
          const LoggedExercise(exerciseId: 'plank', sets: [
            LoggedSet(holdSeconds: 45, rawType: 'hold'),
          ]),
        ]),
      ];
      final history = ExerciseHistory.of(holds, 'plank');
      expect(history.recordWeightKg, isNull);
      expect(history.sessionCount, 1, reason: 'gemacht wurde sie trotzdem');
    });
  });

  group('Zahlen je Ausführung', () {
    test('Volumen zählt nur Sätze mit beidem', () {
      final mixed = [
        _session('a', DateTime(2026, 1, 1), [
          _bench(const [
            LoggedSet(reps: 10, weight: 50),
            LoggedSet(reps: 10),
            LoggedSet(weight: 50),
          ]),
        ]),
      ];
      final occurrence = ExerciseHistory.of(mixed, 'bench').occurrences.first;
      expect(occurrence.volume, 500,
          reason: 'Wiederholungen ohne Gewicht sind kein Volumen von null');
      expect(occurrence.setCount, 3);
    });

    test('Wiederholungen summieren sich', () {
      final occurrence =
          ExerciseHistory.of(sessions, 'bench').occurrences.first;
      expect(occurrence.totalReps, 18);
      expect(occurrence.bestWeightKg, 85);
    });

    test('eine Halteübung hat keine Wiederholungen', () {
      final holds = [
        _session('a', DateTime(2026, 1, 1), [
          const LoggedExercise(exerciseId: 'plank', sets: [
            LoggedSet(holdSeconds: 45),
          ]),
        ]),
      ];
      expect(ExerciseHistory.of(holds, 'plank').occurrences.first.totalReps,
          isNull, reason: 'null, nicht 0 — sie kennt die Frage nicht');
    });
  });

  group('Was nicht zählt', () {
    test('leere Sätze fallen weg', () {
      final withEmpty = [
        _session('a', DateTime(2026, 1, 1), [
          _bench(const [LoggedSet(), LoggedSet(reps: 5, weight: 60)]),
        ]),
      ];
      expect(ExerciseHistory.of(withEmpty, 'bench').totalSets, 1);
    });

    test('eine Übung ohne einen einzigen inhaltlichen Satz gilt als nie '
        'gemacht', () {
      final onlyEmpty = [
        _session('a', DateTime(2026, 1, 1), [
          _bench(const [LoggedSet(), LoggedSet()]),
        ]),
      ];
      final history = ExerciseHistory.of(onlyEmpty, 'bench');
      expect(history.isEmpty, isTrue);
      expect(history.sessionCount, 0);
    });

    test('Cardio und Regeneration tragen nichts bei', () {
      final other = <TrainingSession>[
        CardioSession(
            id: 'c',
            userId: 'u',
            date: DateTime(2026, 1, 1),
            createdAt: DateTime(2026, 1, 1)),
        RecoverySession(
            id: 'r',
            userId: 'u',
            date: DateTime(2026, 1, 2),
            createdAt: DateTime(2026, 1, 2)),
      ];
      expect(ExerciseHistory.index(other), isEmpty);
    });

    test('eine nie gemachte Übung liefert einen leeren Verlauf, kein null', () {
      final history = ExerciseHistory.of(sessions, 'gibtsnicht');
      expect(history.isEmpty, isTrue);
      expect(history.exerciseId, 'gibtsnicht');
      expect(history.lastSets, isEmpty);
      expect(history.recordWeightKg, isNull);
    });
  });

  test('der Index enthält jede vorkommende Übung', () {
    final index = ExerciseHistory.index(sessions);
    expect(index.keys, unorderedEquals(['bench', 'row']));
    expect(index['bench']!.sessionCount, 3);
    expect(index['row']!.sessionCount, 1);
  });

  test('zweimal dieselbe Übung in einer Einheit zählt zweimal', () {
    // Ein Rundlauf macht genau das.
    final twice = [
      _session('a', DateTime(2026, 1, 1), [
        _bench(const [LoggedSet(reps: 5, weight: 60)]),
        _bench(const [LoggedSet(reps: 5, weight: 65)]),
      ]),
    ];
    final history = ExerciseHistory.of(twice, 'bench');
    expect(history.sessionCount, 2);
    expect(history.recordWeightKg, 65);
  });
}
