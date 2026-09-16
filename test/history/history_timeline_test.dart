import 'package:atem/features/history/domain/history_timeline.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _ref = DateTime(2026, 8, 27);

TrainingSession _s(DateTime date, {String id = 'x'}) => StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      duration: const Duration(minutes: 45),
    );

void main() {
  test('leer bleibt leer', () {
    expect(HistoryTimeline.build(const [], _ref), isEmpty);
  });

  test('Monatsköpfe trennen die Einheiten', () {
    final entries = HistoryTimeline.build([
      _s(DateTime(2026, 8, 20)),
      _s(DateTime(2026, 8, 18)),
      _s(DateTime(2026, 7, 30)),
    ], _ref);

    final months = entries.whereType<MonthHeader>().toList();
    expect(months, hasLength(2));
    expect(months.first.month, 8);
    expect(months.first.sessions, 2);
    expect(months.last.month, 7);
  });

  test('eine Lücke ab sieben Tagen bekommt eine eigene Zeile', () {
    final entries = HistoryTimeline.build([
      _s(DateTime(2026, 8, 20)),
      // 6 Tage Abstand — noch keine Lücke.
      _s(DateTime(2026, 8, 14)),
      // 20 Tage Abstand — Lücke.
      _s(DateTime(2026, 7, 25)),
    ], _ref);

    // Die offene Pause bis zum Stichtag zählt hier nicht mit.
    final gaps =
        entries.whereType<TimelineGap>().where((g) => !g.isOpen).toList();
    expect(gaps, hasLength(1));
    expect(gaps.single.days, 20);
    // Der Streifen umfasst die trainingsfreien Tage, nicht die Einheiten
    // selbst.
    expect(gaps.single.from, DateTime(2026, 7, 26));
    expect(gaps.single.to, DateTime(2026, 8, 13));
  });

  test('die längste Pause wird als solche gekennzeichnet', () {
    final entries = HistoryTimeline.build([
      _s(DateTime(2026, 8, 20)),
      _s(DateTime(2026, 8, 5)),
      _s(DateTime(2026, 6, 1)),
    ], _ref);

    final gaps =
        entries.whereType<TimelineGap>().where((g) => !g.isOpen).toList();
    expect(gaps, hasLength(2));
    expect(gaps.where((g) => g.isLongest), hasLength(1));
    expect(gaps.firstWhere((g) => g.isLongest).days, 65);
  });

  test('mehrere Einheiten am selben Tag werden durchnummeriert', () {
    final day = DateTime(2026, 8, 20);
    final entries = HistoryTimeline.build([
      _s(day.add(const Duration(hours: 7)), id: 'morgens'),
      _s(day.add(const Duration(hours: 18)), id: 'abends'),
      _s(DateTime(2026, 8, 19), id: 'allein'),
    ], _ref);

    final rows = entries.whereType<TimelineSession>().toList();
    // Neueste zuerst: abends ist die zweite Einheit des Tages.
    expect(rows[0].ordinalOnDay, 2);
    expect(rows[1].ordinalOnDay, 1);
    // Ein Tag mit nur einer Einheit bekommt keine Nummer.
    expect(rows[2].ordinalOnDay, isNull);
  });

  test('die Pause seit der letzten Einheit steht offen ganz oben', () {
    final entries = HistoryTimeline.build([
      // 20 Tage vor dem Stichtag — offen, aber nicht „längste".
      _s(DateTime(2026, 8, 7)),
      _s(DateTime(2026, 8, 5)),
    ], _ref);

    expect(entries.first, isA<TimelineGap>());
    final open = entries.first as TimelineGap;
    expect(open.isOpen, isTrue);
    expect(open.isLongest, isFalse);
    expect(open.days, 20);
    expect(open.from, DateTime(2026, 8, 8));
    expect(open.to, _ref);
    // Unter sieben Tagen gibt es sie nicht.
    final fresh = HistoryTimeline.build([_s(DateTime(2026, 8, 25))], _ref);
    expect(fresh.first, isA<MonthHeader>());
  });

  test('das Ende nennt die erste Einheit', () {
    final entries = HistoryTimeline.build([
      _s(DateTime(2026, 8, 20)),
      _s(DateTime(2026, 8, 1)),
    ], _ref);

    final end = entries.whereType<TimelineEnd>().single;
    expect(end.first, DateTime(2026, 8, 1));
    expect(end.daysAgo, 26);
  });

  test('die Monatslast wird aufsummiert', () {
    final entries = HistoryTimeline.build(
      [_s(DateTime(2026, 8, 20)), _s(DateTime(2026, 8, 18))],
      _ref,
      loadByDay: {'2026-08-20': 120.4, '2026-08-18': 80.2},
    );

    expect(entries.whereType<MonthHeader>().single.load, 201);
  });
}
