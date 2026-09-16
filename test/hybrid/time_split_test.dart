import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/hybrid/domain/time_split.dart';
import 'package:flutter_test/flutter_test.dart';

final _reference = DateTime(2026, 9, 16, 15, 30);

StrengthSession _strength(String id, DateTime date, {int? minutes}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      duration: minutes == null ? null : Duration(minutes: minutes),
    );

StrengthSession _bodyweight(String id, DateTime date, {int? minutes}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: true,
      duration: minutes == null ? null : Duration(minutes: minutes),
    );

CardioSession _cardio(String id, DateTime date, {int? minutes}) =>
    CardioSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      duration: minutes == null ? null : Duration(minutes: minutes),
    );

RecoverySession _recovery(String id, DateTime date, {int? minutes}) =>
    RecoverySession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      duration: minutes == null ? null : Duration(minutes: minutes),
    );

void main() {
  group('Fensterkanten', () {
    test('Tag 14 ist drin, Tag 15 nicht — bei 14 Tagen', () {
      final split = TimeSplit.compute(
        [
          _strength('in', DateTime(2026, 9, 3, 6), minutes: 30),
          _strength('out', DateTime(2026, 9, 2, 23, 59), minutes: 30),
        ],
        _reference,
        days: 14,
      );
      expect(split.of(TrainingTrack.strength).minutes, 30);
      expect(split.of(TrainingTrack.strength).count, 1);
      expect(split.reference, DateTime(2026, 9, 16));
      expect(split.days, 14);
    });

    test('der Stichtag zählt bis Mitternacht, Zukunft nicht', () {
      final split = TimeSplit.compute(
        [
          _cardio('today', DateTime(2026, 9, 16, 23, 30), minutes: 40),
          _cardio('tomorrow', DateTime(2026, 9, 17, 0, 1), minutes: 40),
        ],
        _reference,
        days: 7,
      );
      expect(split.of(TrainingTrack.cardio).minutes, 40);
    });

    test('28 Tage reichen bis zum 20. August', () {
      final split = TimeSplit.compute(
        [
          _recovery('in', DateTime(2026, 8, 20), minutes: 20),
          _recovery('out', DateTime(2026, 8, 19), minutes: 20),
        ],
        _reference,
        days: 28,
      );
      expect(split.of(TrainingTrack.recovery).minutes, 20);
      expect(split.totalCount, 1);
    });

    test('Zeitumstellung verschiebt die Kante nicht', () {
      // 29.03.2026 ist die Umstellung auf Sommerzeit in Europa. 14 Tage vor
      // dem 10.04. ist der 28.03. — kalendarisch, nicht in Stunden.
      final split = TimeSplit.compute(
        [
          _strength('in', DateTime(2026, 3, 28, 0, 30), minutes: 10),
          _strength('out', DateTime(2026, 3, 27, 23, 30), minutes: 10),
        ],
        DateTime(2026, 4, 10),
        days: 14,
      );
      expect(split.of(TrainingTrack.strength).count, 1);
    });
  });

  group('Spuren', () {
    test('Kraft umfasst strength und bodyweight', () {
      final split = TimeSplit.compute(
        [
          _strength('a', DateTime(2026, 9, 15), minutes: 40),
          _bodyweight('b', DateTime(2026, 9, 14), minutes: 20),
        ],
        _reference,
        days: 7,
      );
      expect(split.of(TrainingTrack.strength).minutes, 60);
      expect(split.of(TrainingTrack.strength).count, 2);
    });

    test('immer alle drei Spuren in fester Reihenfolge', () {
      final split = TimeSplit.compute(const [], _reference, days: 14);
      expect(split.tracks.map((t) => t.track), [
        TrainingTrack.strength,
        TrainingTrack.cardio,
        TrainingTrack.recovery,
      ]);
      expect(split.isEmpty, isTrue);
      expect(split.totalCount, 0);
    });
  });

  group('Einheiten ohne Dauer', () {
    test('zählen, tragen aber keine Minuten', () {
      final split = TimeSplit.compute(
        [
          _strength('a', DateTime(2026, 9, 15), minutes: 45),
          _strength('b', DateTime(2026, 9, 14)),
          _cardio('c', DateTime(2026, 9, 13)),
        ],
        _reference,
        days: 7,
      );
      expect(split.of(TrainingTrack.strength).count, 2);
      expect(split.of(TrainingTrack.strength).minutes, 45);
      expect(split.of(TrainingTrack.cardio).count, 1);
      expect(split.of(TrainingTrack.cardio).minutes, 0);
      expect(split.sessionsWithoutDuration, 2);
      expect(split.totalCount, 3);
      expect(split.totalMinutes, 45);
    });

    test('nur Einheiten ohne Dauer: gezählt, aber leer', () {
      final split = TimeSplit.compute(
        [_strength('a', DateTime(2026, 9, 15))],
        _reference,
        days: 7,
      );
      expect(split.isEmpty, isTrue);
      expect(split.totalCount, 1);
      expect(split.percentOf(TrainingTrack.strength), 0);
    });
  });

  group('Prozent', () {
    test('rundet kaufmännisch', () {
      final split = TimeSplit.compute(
        [
          _strength('a', DateTime(2026, 9, 15), minutes: 100),
          _cardio('b', DateTime(2026, 9, 15), minutes: 50),
          _recovery('c', DateTime(2026, 9, 15), minutes: 10),
        ],
        _reference,
        days: 7,
      );
      // 100/160 = 62,5 → 63; 50/160 = 31,25 → 31; 10/160 = 6,25 → 6
      expect(split.percentOf(TrainingTrack.strength), 63);
      expect(split.percentOf(TrainingTrack.cardio), 31);
      expect(split.percentOf(TrainingTrack.recovery), 6);
    });

    test('eine Spur allein ist 100', () {
      final split = TimeSplit.compute(
        [_cardio('b', DateTime(2026, 9, 15), minutes: 33)],
        _reference,
        days: 7,
      );
      expect(split.percentOf(TrainingTrack.cardio), 100);
      expect(split.percentOf(TrainingTrack.strength), 0);
    });
  });
}
