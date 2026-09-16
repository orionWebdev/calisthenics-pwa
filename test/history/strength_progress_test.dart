import 'package:atem/features/history/domain/strength_progress.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime(2026, 8, 1);

StrengthSession _session(
  String id,
  DateTime date,
  List<LoggedExercise> exercises, {
  bool bodyweight = false,
}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: bodyweight,
      exercises: exercises,
    );

/// [count] Einheiten im Wochenabstand, je ein Satz mit [weight] × [reps].
List<TrainingSession> _series(
  String exerciseId,
  int count, {
  double weight = 60,
  int reps = 5,
  String prefix = 's',
}) =>
    [
      for (var i = 0; i < count; i++)
        _session(
          '$prefix$i',
          DateTime(_start.year, _start.month, _start.day + 7 * i),
          [
            LoggedExercise(exerciseId: exerciseId, sets: [
              LoggedSet(weight: weight + i, reps: reps),
            ]),
          ],
        ),
    ];

void main() {
  group('Epley', () {
    test('rechnet w · (1 + n/30)', () {
      expect(StrengthProgress.epley(100, 10), closeTo(133.333, 0.001));
      expect(StrengthProgress.epley(60, 5), closeTo(70, 0.001));
    });

    test('eine Wiederholung ist das Gewicht selbst', () {
      expect(StrengthProgress.epley(120, 1), 120);
    });
  });

  group('Ausschlüsse', () {
    test('Aufwärmsatz zählt nicht, auch wenn er der schwerste wäre', () {
      const set = LoggedSet(weight: 200, reps: 3, rawType: 'warmup');
      expect(StrengthProgress.countsSet(set), isFalse);
      expect(
        StrengthProgress.countsSet(
            const LoggedSet(weight: 200, reps: 3, rawType: 'dropset')),
        isTrue,
      );
    });

    test('Haltesatz zählt nicht', () {
      expect(
        StrengthProgress.countsSet(
            const LoggedSet(weight: 20, reps: 5, holdSeconds: 30)),
        isFalse,
      );
    });

    test('mehr als zwölf Wiederholungen zählen nicht', () {
      expect(StrengthProgress.countsSet(const LoggedSet(weight: 40, reps: 13)),
          isFalse);
      expect(StrengthProgress.countsSet(const LoggedSet(weight: 40, reps: 12)),
          isTrue);
    });

    test('ohne Gewicht, null oder 0, kein Punkt', () {
      expect(StrengthProgress.countsSet(const LoggedSet(reps: 8)), isFalse);
      expect(StrengthProgress.countsSet(const LoggedSet(weight: 0, reps: 8)),
          isFalse);
    });

    test('Körpergewichtsübung ohne Gewicht erscheint nicht', () {
      final sessions = [
        for (var i = 0; i < 6; i++)
          _session(
            'b$i',
            DateTime(2026, 8, 1 + i),
            [
              const LoggedExercise(
                exerciseId: 'pull_up',
                usesBodyweight: true,
                sets: [LoggedSet(reps: 8)],
              ),
            ],
            bodyweight: true,
          ),
      ];
      expect(StrengthProgress.compute(sessions), isEmpty);
    });

    test('Ausdauer- und Regenerationseinheiten spielen keine Rolle', () {
      final sessions = <TrainingSession>[
        ..._series('squat', 5),
        CardioSession(
            id: 'c', userId: 'u', date: _start, createdAt: _start),
        RecoverySession(
            id: 'r', userId: 'u', date: _start, createdAt: _start),
      ];
      expect(StrengthProgress.compute(sessions).single.exerciseId, 'squat');
    });
  });

  group('Mindestzahl und Sortierung', () {
    test('unter fünf Einheiten erscheint die Übung nicht', () {
      expect(StrengthProgress.compute(_series('squat', 4)), isEmpty);
      expect(StrengthProgress.compute(_series('squat', 5)).length, 1);
    });

    test('die Mindestzahl ist einstellbar', () {
      expect(
        StrengthProgress.compute(_series('squat', 2), minimumSessions: 2)
            .length,
        1,
      );
    });

    test('mehr Einheiten zuerst, bei Gleichstand alphabetisch', () {
      final sessions = [
        ..._series('squat', 5, prefix: 'a'),
        ..._series('bench', 7, prefix: 'b'),
        ..._series('deadlift', 5, prefix: 'c'),
      ];
      final ids = StrengthProgress.compute(sessions).map((s) => s.exerciseId);
      expect(ids, ['bench', 'deadlift', 'squat']);
    });
  });

  group('Punkte', () {
    test('je Einheit der beste Satz, aufsteigend nach Datum', () {
      final sessions = [
        _session('late', DateTime(2026, 8, 20), [
          const LoggedExercise(exerciseId: 'squat', sets: [
            LoggedSet(weight: 80, reps: 5),
          ]),
        ]),
        _session('early', DateTime(2026, 8, 1), [
          const LoggedExercise(exerciseId: 'squat', sets: [
            LoggedSet(weight: 100, reps: 3), // 110
            LoggedSet(weight: 90, reps: 8), // 114 — besser
            LoggedSet(weight: 120, reps: 2, rawType: 'warmup'),
          ]),
        ]),
      ];
      final series =
          StrengthProgress.compute(sessions, minimumSessions: 1).single;
      expect(series.points.map((p) => p.date),
          [DateTime(2026, 8, 1), DateTime(2026, 8, 20)]);
      expect(series.points.first.estimatedMax, closeTo(114, 0.001));
      expect(series.points.first.weight, 90);
      expect(series.points.first.reps, 8);
      expect(series.latest, closeTo(80 * (1 + 5 / 30), 0.001));
      expect(series.best, closeTo(114, 0.001));
      expect(series.deltaSinceFirst, closeTo(93.333 - 114, 0.01));
    });

    test('dieselbe Übung zweimal in einer Einheit ist ein Punkt', () {
      final sessions = [
        _session('s', _start, [
          const LoggedExercise(exerciseId: 'squat', sets: [
            LoggedSet(weight: 60, reps: 5),
          ]),
          const LoggedExercise(exerciseId: 'squat', sets: [
            LoggedSet(weight: 70, reps: 5),
          ]),
        ]),
      ];
      final series =
          StrengthProgress.compute(sessions, minimumSessions: 1).single;
      expect(series.sessionCount, 1);
      expect(series.points.single.weight, 70);
    });

    test('zwei Einheiten am selben Tag sind zwei Punkte', () {
      final sessions = [
        _session('am', DateTime(2026, 8, 1, 8), [
          const LoggedExercise(
              exerciseId: 'squat', sets: [LoggedSet(weight: 60, reps: 5)]),
        ]),
        _session('pm', DateTime(2026, 8, 1, 18), [
          const LoggedExercise(
              exerciseId: 'squat', sets: [LoggedSet(weight: 65, reps: 5)]),
        ]),
      ];
      expect(
        StrengthProgress.compute(sessions, minimumSessions: 1)
            .single
            .sessionCount,
        2,
      );
    });

    test('mit einem Punkt gibt es kein Delta', () {
      final series = StrengthProgress.compute(
        _series('squat', 1),
        minimumSessions: 1,
      ).single;
      expect(series.deltaSinceFirst, isNull);
    });

    test('Einheiten ohne gültigen Satz zählen im Nenner nicht mit', () {
      final sessions = [
        ..._series('squat', 5),
        _session('hold', DateTime(2026, 9, 30), [
          const LoggedExercise(exerciseId: 'squat', sets: [
            LoggedSet(weight: 60, reps: 5, holdSeconds: 20),
          ]),
        ]),
      ];
      expect(StrengthProgress.compute(sessions).single.sessionCount, 5);
    });
  });
}
