import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/hybrid/domain/time_split.dart';
import 'package:atem/features/hybrid/domain/training_heatmap.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mittwoch, 16.09.2026.
final _reference = DateTime(2026, 9, 16, 11);

StrengthSession _strength(String id, DateTime date, {int? minutes}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
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

HeatmapDay _day(TrainingHeatmap map, DateTime date) => map.weeks
    .expand((w) => w.days)
    .firstWhere((d) => d.date == DateTime(date.year, date.month, date.day));

void main() {
  group('Raster', () {
    test('zwölf Wochen, jede beginnt montags und hat sieben Tage', () {
      final map = TrainingHeatmap.compute(const [], _reference);
      expect(map.weekCount, 12);
      expect(map.weeks.length, 12);
      for (final week in map.weeks) {
        expect(week.monday.weekday, DateTime.monday);
        expect(week.days.length, 7);
        expect(week.days.first.date, week.monday);
        expect(week.days.last.date.weekday, DateTime.sunday);
      }
    });

    test('die letzte Woche enthält den Stichtag, die erste liegt 11 Wochen davor',
        () {
      final map = TrainingHeatmap.compute(const [], _reference);
      expect(map.weeks.last.monday, DateTime(2026, 9, 14));
      expect(map.weeks.first.monday, DateTime(2026, 6, 29));
    });

    test('Tage nach dem Stichtag sind Zukunft und zählen nicht', () {
      final map = TrainingHeatmap.compute(
        [_strength('x', DateTime(2026, 9, 18), minutes: 30)],
        _reference,
      );
      final thursday = _day(map, DateTime(2026, 9, 17));
      final friday = _day(map, DateTime(2026, 9, 18));
      expect(thursday.isFuture, isTrue);
      expect(friday.isFuture, isTrue);
      // Eine Einheit in der Zukunft steht nicht im Raster.
      expect(friday.trained, isFalse);
      expect(_day(map, _reference).isFuture, isFalse);
      // Nenner: 11 volle Wochen plus Mo, Di, Mi.
      expect(map.totalDays, 11 * 7 + 3);
      expect(map.trainedDays, 0);
    });

    test('eine Woche ist einstellbar', () {
      final map = TrainingHeatmap.compute(const [], _reference, weeks: 4);
      expect(map.weekCount, 4);
      expect(map.weeks.first.monday, DateTime(2026, 8, 24));
    });

    test('Stichtag am Sonntag: die Woche ist komplett', () {
      final map = TrainingHeatmap.compute(const [], DateTime(2026, 9, 20));
      expect(map.weeks.last.monday, DateTime(2026, 9, 14));
      expect(map.weeks.last.days.every((d) => !d.isFuture), isTrue);
      expect(map.totalDays, 84);
    });
  });

  group('Zählung', () {
    test('ein Tag mit zwei Spuren trägt beide, einmal', () {
      final map = TrainingHeatmap.compute(
        [
          _strength('a', DateTime(2026, 9, 15, 7), minutes: 40),
          _cardio('b', DateTime(2026, 9, 15, 18), minutes: 30),
          _cardio('c', DateTime(2026, 9, 15, 19)),
        ],
        _reference,
      );
      final day = _day(map, DateTime(2026, 9, 15));
      expect(day.tracks, {TrainingTrack.strength, TrainingTrack.cardio});
      expect(day.minutes, 70);
      expect(day.trained, isTrue);
      expect(map.trainedDays, 1);
      expect(map.trainedDaysOf(TrainingTrack.strength), 1);
      expect(map.trainedDaysOf(TrainingTrack.cardio), 1);
      expect(map.trainedDaysOf(TrainingTrack.recovery), 0);
      expect(map.weeks.last.trainedDays, 1);
    });

    test('Regeneration ist ein Trainingstag ohne Wertung', () {
      final map = TrainingHeatmap.compute(
        [_recovery('r', DateTime(2026, 9, 14), minutes: 25)],
        _reference,
      );
      expect(_day(map, DateTime(2026, 9, 14)).tracks, {TrainingTrack.recovery});
      expect(map.trainedDays, 1);
    });

    test('Einheiten vor dem Raster fallen heraus', () {
      final map = TrainingHeatmap.compute(
        [_strength('old', DateTime(2026, 6, 28), minutes: 30)],
        _reference,
      );
      expect(map.trainedDays, 0);
    });

    test('Zeitumstellung: der Tag bleibt der Tag', () {
      // Nacht der Sommerzeit-Umstellung 2026: 29.03., 02:00 → 03:00.
      final map = TrainingHeatmap.compute(
        [
          _strength('before', DateTime(2026, 3, 28, 23, 45), minutes: 30),
          _strength('after', DateTime(2026, 3, 29, 0, 15), minutes: 30),
        ],
        DateTime(2026, 4, 5),
      );
      expect(_day(map, DateTime(2026, 3, 28)).trained, isTrue);
      expect(_day(map, DateTime(2026, 3, 29)).trained, isTrue);
      expect(map.trainedDays, 2);
      // Jede Woche hat sieben Tage, auch die mit 23 Stunden Sonntag.
      for (final week in map.weeks) {
        expect(week.days.length, 7);
        for (var i = 1; i < 7; i++) {
          expect(week.days[i].date.difference(week.days[i - 1].date).inHours,
              anyOf(23, 24, 25));
        }
      }
    });
  });

  group('Kalenderwoche', () {
    test('ISO 8601', () {
      expect(TrainingHeatmap.isoWeekOf(DateTime(2026, 9, 14)), 38);
      expect(TrainingHeatmap.isoWeekOf(DateTime(2026, 1, 1)), 1);
      // 2027 beginnt an einem Freitag: der 1.1. gehört zu KW 53 von 2026.
      expect(TrainingHeatmap.isoWeekOf(DateTime(2027, 1, 1)), 53);
      expect(TrainingHeatmap.isoWeekOf(DateTime(2027, 1, 4)), 1);
      final map = TrainingHeatmap.compute(const [], _reference);
      expect(map.weeks.last.isoWeek, 38);
      expect(map.weeks.first.isoWeek, 27);
    });
  });
}
