import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/hybrid/domain/time_split.dart';
import 'package:atem/features/hybrid/domain/training_time.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stichtag Donnerstag, 17.09.2026 — KW 38 beginnt am Montag, 14.09.
final _today = DateTime(2026, 9, 17);

DateTime _day(int y, int m, int d) => DateTime(y, m, d, 18);

StrengthSession _lift(String id, DateTime date, int minutes,
        {List<LoggedSet> sets = const []}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      duration: Duration(minutes: minutes),
      exercises: [LoggedExercise(exerciseId: 'pull_up', sets: sets)],
    );

CardioSession _run(String id, DateTime date, int? minutes, double km) =>
    CardioSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      duration: minutes == null ? null : Duration(minutes: minutes),
      distanceKm: km,
    );

RecoverySession _yoga(String id, DateTime date, int minutes) => RecoverySession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      duration: Duration(minutes: minutes),
    );

void main() {
  group('Wochenfenster', () {
    test('rechnet Montag bis Sonntag der Stichtagswoche', () {
      final t = TrainingTime.compute([
        _lift('sun', _day(2026, 9, 13), 30), // Vorwoche
        _lift('mon', _day(2026, 9, 14), 40),
        _lift('sun2', _day(2026, 9, 20), 50), // gleiche Woche, Zukunft
      ], _today, TrainingTimeWindow.week);
      expect(t.of(TrainingTrack.strength).minutes, 90);
      expect(t.of(TrainingTrack.strength).count, 2);
      expect(t.isoWeek, 38);
    });

    test('drei Spuren, Anteil an allen Minuten — Regeneration zählt mit', () {
      final t = TrainingTime.compute([
        _lift('a', _day(2026, 9, 15), 60),
        _run('b', _day(2026, 9, 16), 30, 5),
        _yoga('c', _day(2026, 9, 16), 10),
      ], _today, TrainingTimeWindow.week);
      expect(t.totalMinutes, 100);
      expect(t.percentOf(TrainingTrack.strength), 60);
      expect(t.percentOf(TrainingTrack.cardio), 30);
      expect(t.percentOf(TrainingTrack.recovery), 10);
    });
  });

  test('28-Tage-Fenster: Tag 28 drin, Tag 29 nicht', () {
    final t = TrainingTime.compute([
      _lift('in', _day(2026, 8, 21), 20),
      _lift('out', _day(2026, 8, 20), 99),
    ], _today, TrainingTimeWindow.days28);
    expect(t.of(TrainingTrack.strength).minutes, 20);
  });

  test('Sätze ohne Aufwärmen, Tonnage nur aus Sätzen mit Gewicht, km', () {
    final t = TrainingTime.compute([
      _lift('a', _day(2026, 9, 15), 40, sets: const [
        LoggedSet(reps: 8, rawType: 'warmup'),
        LoggedSet(reps: 8),
        LoggedSet(reps: 6, weight: 20),
      ]),
      _run('r', _day(2026, 9, 16), 30, 6.2),
      _run('n', _day(2026, 9, 16), null, 3),
    ], _today, TrainingTimeWindow.week);
    final s = t.of(TrainingTrack.strength);
    expect(s.sets, 2);
    expect(s.tonnageKg, 120);
    expect(t.of(TrainingTrack.cardio).km, closeTo(9.2, 1e-9));
    expect(t.sessionsWithoutDuration, 1);
    expect(t.of(TrainingTrack.cardio).count, 2);
  });

  group('Verschiebung', () {
    test('ohne vier Wochen Geschichte keine Verschiebung — nicht 0', () {
      final t = TrainingTime.compute([
        _lift('a', _day(2026, 9, 1), 30),
        _lift('b', _day(2026, 9, 15), 30),
      ], _today, TrainingTimeWindow.week);
      expect(t.hasShift, isFalse);
    });

    test('Anteil dieser Woche gegen den Schnitt der Vorwochen, in pp', () {
      final sessions = [
        // Vier Vorwochen je 50 % Kraft, 50 % Cardio.
        for (var w = 1; w <= 4; w++) ...[
          _lift('l$w', DateTime(2026, 9, 15 - 7 * w, 18), 30),
          _run('r$w', DateTime(2026, 9, 16 - 7 * w, 18), 30, 5),
        ],
        // Diese Woche 75 % Kraft.
        _lift('now', _day(2026, 9, 15), 90),
        _run('nowr', _day(2026, 9, 16), 30, 5),
      ];
      final t = TrainingTime.compute(sessions, _today, TrainingTimeWindow.week);
      expect(t.shiftPp[TrainingTrack.strength], closeTo(25, 1e-9));
      expect(t.shiftPp[TrainingTrack.cardio], closeTo(-25, 1e-9));
      expect(t.shiftPp[TrainingTrack.recovery], closeTo(0, 1e-9));
    });

    test('28-Tage-Fenster trägt keine Verschiebung', () {
      final t = TrainingTime.compute([
        for (var w = 0; w <= 5; w++)
          _lift('l$w', DateTime(2026, 9, 15 - 7 * w, 18), 30),
      ], _today, TrainingTimeWindow.days28);
      expect(t.hasShift, isFalse);
    });
  });

  test('Zeitumstellung verschiebt die Wochenkante nicht', () {
    // Sonntag 25.10.2026 hat 25 Stunden; Montag 26.10. beginnt KW 44.
    final t = TrainingTime.compute([
      _lift('sun', DateTime(2026, 10, 25, 23, 30), 30),
      _lift('mon', DateTime(2026, 10, 26, 0, 30), 40),
    ], DateTime(2026, 10, 27), TrainingTimeWindow.week);
    expect(t.of(TrainingTrack.strength).minutes, 40);
  });
}
