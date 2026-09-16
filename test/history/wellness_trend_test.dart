import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/domain/wellness_trend.dart';
import 'package:flutter_test/flutter_test.dart';

final _ref = DateTime(2026, 9, 16);

StrengthSession _strength(
  String id,
  DateTime date, {
  int? before,
  int? after,
  bool bodyweight = false,
}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: bodyweight,
      preWorkoutReadiness: before,
      postWorkoutFeeling: after,
    );

void main() {
  group('WellnessTrend', () {
    test('ein Paar nur mit beiden Angaben, sortiert älteste zuerst', () {
      final t = WellnessTrend.compute([
        _strength('b', DateTime(2026, 9, 14), before: 2, after: 4),
        _strength('a', DateTime(2026, 9, 10), before: 3, after: 3),
        _strength('c', DateTime(2026, 9, 12), before: 4),
        _strength('d', DateTime(2026, 9, 11), after: 5),
        _strength('e', DateTime(2026, 9, 9)),
      ], _ref);

      expect(t.withBoth, 2);
      expect(t.pairs.map((p) => p.date.day), [10, 14]);
      expect(t.withOnlyOne, 2);
      expect(t.total, 5, reason: 'Der Nenner zählt jede Krafteinheit');
      expect(t.pairs.last.difference, 2);
    });

    test('zählt höher, gleich und niedriger — kein Mittelwert', () {
      final t = WellnessTrend.compute([
        _strength('a', DateTime(2026, 9, 1), before: 2, after: 4),
        _strength('b', DateTime(2026, 9, 2), before: 3, after: 5),
        _strength('c', DateTime(2026, 9, 3), before: 3, after: 3),
        _strength('d', DateTime(2026, 9, 4), before: 5, after: 2),
      ], _ref);
      expect((t.higher, t.same, t.lower), (2, 1, 1));
    });

    test('Fenster: Tag 56 zählt, Tag 57 nicht, die Zukunft nicht', () {
      final t = WellnessTrend.compute([
        _strength('in', DateTime(2026, 7, 23, 23, 30), before: 3, after: 3),
        _strength('out', DateTime(2026, 7, 22, 23, 59), before: 3, after: 3),
        _strength('heute', DateTime(2026, 9, 16, 21), before: 3, after: 3),
        _strength('morgen', DateTime(2026, 9, 17, 0, 1), before: 3, after: 3),
      ], _ref);
      expect(t.withBoth, 2);
      expect(t.total, 2);
    });

    test('nur Kraft und Körpergewicht, ausser strengthOnly ist aus', () {
      final sessions = <TrainingSession>[
        _strength('k', DateTime(2026, 9, 1), before: 3, after: 4),
        _strength('kg', DateTime(2026, 9, 2),
            before: 3, after: 4, bodyweight: true),
        CardioSession(
          id: 'c',
          userId: 'u',
          date: DateTime(2026, 9, 3),
          createdAt: DateTime(2026, 9, 3),
          activity: CardioActivity.run,
          preWorkoutReadiness: 2,
          postWorkoutFeeling: 5,
        ),
      ];
      expect(WellnessTrend.compute(sessions, _ref).withBoth, 2);
      expect(
          WellnessTrend.compute(sessions, _ref, strengthOnly: false).withBoth,
          3);
    });

    test('Werte ausserhalb von 1 bis 5 sind keine Angabe', () {
      final t = WellnessTrend.compute([
        _strength('a', DateTime(2026, 9, 1), before: 0, after: 4),
        _strength('b', DateTime(2026, 9, 2), before: 3, after: 9),
      ], _ref);
      expect(t.withBoth, 0);
      expect(t.withOnlyOne, 2);
    });

    test('Schwelle bei fünf Paaren, latest behält die jüngsten', () {
      final sessions = [
        for (var i = 1; i <= 14; i++)
          _strength('s$i', DateTime(2026, 9, i), before: 3, after: 4),
      ];
      final t = WellnessTrend.compute(sessions, _ref);
      expect(t.hasEnough, isTrue);
      expect(WellnessTrend.compute(sessions.take(4).toList(), _ref).hasEnough,
          isFalse);
      final last = t.latest(12);
      expect(last.length, 12);
      expect(last.first.date.day, 3);
      expect(last.last.date.day, 14);
    });

    test('über die Zeitumstellung am 25.10. bleiben Tagesgrenzen lokal', () {
      final ref = DateTime(2026, 10, 26);
      final t = WellnessTrend.compute([
        _strength('a', DateTime(2026, 10, 25, 1), before: 3, after: 4),
        _strength('b', DateTime(2026, 9, 1), before: 3, after: 4),
        _strength('c', DateTime(2026, 8, 31, 23), before: 3, after: 4),
      ], ref);
      expect(t.withBoth, 2, reason: '01.09. ist Tag 56, 31.08. ist Tag 57');
    });
  });
}
