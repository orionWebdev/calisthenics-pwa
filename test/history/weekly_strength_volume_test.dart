import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/domain/weekly_strength_volume.dart';
import 'package:flutter_test/flutter_test.dart';

StrengthSession _session(
  String id,
  DateTime date, {
  int sets = 3,
  int warmups = 0,
  bool noExercises = false,
}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: true,
      exercises: noExercises
          ? const []
          : [
              LoggedExercise(exerciseId: 'pull_up', sets: [
                for (var i = 0; i < warmups; i++)
                  const LoggedSet(reps: 5, rawType: 'warmup'),
                for (var i = 0; i < sets; i++) const LoggedSet(reps: 8),
              ]),
            ],
    );

void main() {
  // Mittwoch, 16.09.2026 — KW 38, Montag ist der 14.09.
  final ref = DateTime(2026, 9, 16, 15);

  test('ohne Krafteinheit ist das Ergebnis leer', () {
    final v = WeeklyStrengthVolume.compute(const [], ref);
    expect(v.hasSets, isFalse);
    expect(v.weeks, isEmpty);
  });

  test('acht Wochen, älteste zuerst, die letzte läuft', () {
    final v = WeeklyStrengthVolume.compute(
        [_session('a', DateTime(2026, 9, 15))], ref);
    expect(v.weeks, hasLength(8));
    expect(v.weeks.last.isCurrent, isTrue);
    expect(v.weeks.last.weekStart, DateTime(2026, 9, 14));
    expect(v.weeks.first.weekStart, DateTime(2026, 7, 27));
    expect(v.weeks.last.isoWeek, 38);
  });

  test('Sonntag gehört zur alten Woche, Montag zur neuen', () {
    final v = WeeklyStrengthVolume.compute([
      _session('so', DateTime(2026, 9, 13, 23, 30), sets: 2),
      _session('mo', DateTime(2026, 9, 14, 0, 10), sets: 5),
    ], ref);
    expect(v.weeks[6].sets, 2);
    expect(v.weeks[7].sets, 5);
  });

  test('Aufwärmsätze zählen nicht', () {
    final v = WeeklyStrengthVolume.compute(
        [_session('a', DateTime(2026, 9, 15), sets: 4, warmups: 2)], ref);
    expect(v.currentSets, 4);
  });

  test('eine Einheit nur mit Aufwärmsätzen ist eine Einheit ohne Sätze', () {
    final v = WeeklyStrengthVolume.compute(
        [_session('a', DateTime(2026, 9, 15), sets: 0, warmups: 3)], ref);
    expect(v.hasSets, isFalse);
    expect(v.currentSessions, 1);
    expect(v.sessionsWithoutSets, 1);
  });

  test('Einheiten ohne Sätze zählen als Einheit, nicht als Satz', () {
    final v = WeeklyStrengthVolume.compute([
      _session('a', DateTime(2026, 9, 15), sets: 4),
      _session('b', DateTime(2026, 9, 16), noExercises: true),
    ], ref);
    expect(v.hasSets, isTrue);
    expect(v.currentSessions, 2);
    expect(v.currentSets, 4);
    expect(v.sessionsWithoutSets, 1);
  });

  test('die Woche der ersten Einheit ist gemessen, die davor nicht', () {
    final v = WeeklyStrengthVolume.compute([
      _session('a', DateTime(2026, 9, 1)),
      _session('b', DateTime(2026, 9, 16)),
    ], ref);
    // weeks[5] = KW 36 (31.08.) trägt die erste Einheit, weeks[4] liegt davor.
    expect(v.weeks[5].weekStart, DateTime(2026, 8, 31));
    expect(v.weeks[5].beforeStart, isFalse);
    expect(v.weeks[5].sets, 3);
    expect(v.weeks[4].beforeStart, isTrue);
    // KW 37 (07.09.) ist gemessen und leer.
    expect(v.weeks[6].weekStart, DateTime(2026, 9, 7));
    expect(v.weeks[6].isEmpty, isTrue);
  });

  test('gemessene Woche ohne Satz ist leer, vor Beginn nicht', () {
    final v = WeeklyStrengthVolume.compute([
      _session('a', DateTime(2026, 8, 25)),
      _session('b', DateTime(2026, 9, 16)),
    ], ref);
    // KW 35 (24.08.) erste, KW 36 und 37 leer, KW 34 vor Beginn.
    expect(v.weeks[4].weekStart, DateTime(2026, 8, 24));
    expect(v.weeks[5].isEmpty, isTrue);
    expect(v.weeks[6].isEmpty, isTrue);
    expect(v.weeks[3].beforeStart, isTrue);
    expect(v.weeks[3].isEmpty, isFalse);
  });

  group('Vergleich', () {
    test('ohne volle Vorwoche kein Vergleich, noch 2', () {
      final v = WeeklyStrengthVolume.compute(
          [_session('a', DateTime(2026, 9, 15))], ref);
      expect(v.hasComparison, isFalse);
      expect(v.comparisonWeeks, 0);
      expect(v.weeksUntilComparison, 2);
      expect(v.shift, isNull);
    });

    test('eine volle Vorwoche reicht nicht, noch 1', () {
      final v = WeeklyStrengthVolume.compute([
        _session('a', DateTime(2026, 9, 8)),
        _session('b', DateTime(2026, 9, 15)),
      ], ref);
      expect(v.comparisonWeeks, 1);
      expect(v.hasComparison, isFalse);
      expect(v.weeksUntilComparison, 1);
    });

    test('der Schnitt zählt nur Wochen seit Beginn', () {
      // Beginn KW 36 (31.08.): Vorwochen KW 36 und 37 zählen, KW 34/35 nicht.
      final v = WeeklyStrengthVolume.compute([
        _session('a', DateTime(2026, 9, 2), sets: 10),
        _session('b', DateTime(2026, 9, 9), sets: 6),
        _session('c', DateTime(2026, 9, 15), sets: 12),
      ], ref);
      expect(v.comparisonWeeks, 2);
      expect(v.hasComparison, isTrue);
      expect(v.fourWeekAverage, 8);
      expect(v.shift, 4);
    });

    test('mit vier Wochen Geschichte zählen leere Vorwochen mit 0', () {
      final v = WeeklyStrengthVolume.compute([
        _session('a', DateTime(2026, 8, 10), sets: 20),
        _session('b', DateTime(2026, 8, 18), sets: 8),
        _session('c', DateTime(2026, 9, 15), sets: 4),
      ], ref);
      // Vorwochen KW 34 (8), 35 (0), 36 (0), 37 (0) → Schnitt 2.
      expect(v.comparisonWeeks, 4);
      expect(v.fourWeekAverage, 2);
      expect(v.shift, 2);
    });
  });

  test('Zeitumstellung: Wochen bleiben Montage um Mitternacht', () {
    // 25.10.2026 endet die Sommerzeit — Sonntag in KW 43.
    final late = DateTime(2026, 10, 28, 12);
    final v = WeeklyStrengthVolume.compute([
      _session('a', DateTime(2026, 10, 25, 23, 59), sets: 2),
      _session('b', DateTime(2026, 10, 26, 0, 1), sets: 7),
    ], late);
    expect(v.weeks.last.weekStart, DateTime(2026, 10, 26));
    expect(v.weeks[6].weekStart, DateTime(2026, 10, 19));
    for (final w in v.weeks) {
      expect(w.weekStart.hour, 0);
      expect(w.weekStart.weekday, DateTime.monday);
    }
    expect(v.weeks[6].sets, 2);
    expect(v.weeks[7].sets, 7);
  });

  test('Einheiten nach dem Stichtag zählen nicht', () {
    final v = WeeklyStrengthVolume.compute([
      _session('a', DateTime(2026, 9, 15), sets: 3),
      _session('b', DateTime(2026, 9, 17), sets: 9),
    ], ref);
    expect(v.currentSets, 3);
  });
}
