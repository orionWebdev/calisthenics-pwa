import 'package:atem/features/history/domain/training_session.dart'
    show CardioActivity;
import 'package:atem/features/planning/domain/training_goal.dart';
import 'package:atem/features/planning/domain/week_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die sechs Schreibregeln aus Board 19, L — und die eine Ableitung von
/// „heute".
void main() {
  const a = WeekSide.a;
  WeekEntry strength(String id, int wd,
          {String? plan, WeekDaypart? dp}) =>
      WeekEntry(
          id: id,
          weekday: wd,
          kind: WeekKind.strength,
          planId: plan,
          planName: plan == null ? null : 'Plan $plan',
          daypart: dp);
  WeekEntry run(String id, int wd, {WeekDaypart? dp}) => WeekEntry(
      id: id,
      weekday: wd,
      kind: WeekKind.cardio,
      activity: CardioActivity.run,
      durationMin: 40,
      daypart: dp);
  WeekEntry off(String id, int wd) =>
      WeekEntry(id: id, weekday: wd, kind: WeekKind.off);

  group('Regel 1 — Map statt Array, Feld-Update', () {
    test('Verschieben schreibt weekday und order, sonst nichts', () {
      final w = WeekPlan.empty.add(a, strength('x', 1)).next;
      final c = w.move(a, 'x', 3);
      expect(c.writes, {'a.entries.x.weekday': 3, 'a.entries.x.order': 0});
      expect(c.next.day(a, 3).single.id, 'x');
      expect(c.next.day(a, 1), isEmpty);
    });

    test('Ändern schreibt Feld für Feld und löscht, was wegfällt', () {
      final w = WeekPlan.empty.add(a, strength('x', 1, plan: 'p1')).next;
      final c = w.edit(a, strength('x', 1));
      expect(c.writes, {
        'a.entries.x.planId': null,
        'a.entries.x.planName': null,
      });
    });

    test('ein neuer Eintrag wird als Ganzes geschrieben', () {
      final c = WeekPlan.empty.add(a, run('r', 2));
      expect(c.writes.keys, ['a.entries.r']);
      expect((c.writes['a.entries.r']! as Map)['activity'], 'run');
    });
  });

  group('Regel 3 — „Frei" ist exklusiv', () {
    test('Training auf einen freien Tag löscht das „Frei"', () {
      final w = WeekPlan.empty.add(a, off('f', 7)).next;
      final c = w.add(a, strength('x', 7));
      expect(c.replacedOff, isTrue);
      expect(c.writes['a.entries.f'], isNull);
      expect(c.writes.containsKey('a.entries.f'), isTrue);
      expect(c.next.day(a, 7).map((e) => e.id), ['x']);
    });

    test('„Frei" auf einem belegten Tag gibt es nicht', () {
      final w = WeekPlan.empty.add(a, strength('x', 2)).next;
      expect(() => w.add(a, off('f', 2)), throwsStateError);
    });

    test('Verschieben auf einen freien Tag ersetzt das „Frei"', () {
      var w = WeekPlan.empty.add(a, off('f', 7)).next;
      w = w.add(a, strength('x', 6)).next;
      final c = w.move(a, 'x', 7);
      expect(c.replacedOff, isTrue);
      expect(c.next.day(a, 7).map((e) => e.id), ['x']);
    });
  });

  test('Regel 5 — Woche leeren löscht die ganze Map der sichtbaren Woche',
      () {
    final w = WeekPlan.empty.add(a, strength('x', 1)).next;
    final c = w.clearAll(a);
    expect(c.writes, {'a.entries': null});
    expect(c.next.a, isEmpty);
  });

  test('Tag: nach Tageszeit, dann Reihenfolge — Person 4', () {
    var w = WeekPlan.empty;
    w = w.add(a, strength('k', 3, dp: WeekDaypart.evening)).next;
    w = w.add(a, run('l', 3, dp: WeekDaypart.morning)).next;
    expect(w.day(a, 3).map((e) => e.id), ['l', 'k']);
  });

  test('Rückgängig stellt einen Eintrag wieder her, auch sein „Frei"', () {
    final before = WeekPlan.empty.add(a, off('f', 7)).next;
    final after = before.add(a, strength('x', 7)).next;
    final undo = after.restore(a, before, ['x', 'f']);
    expect(undo.next.day(a, 7).map((e) => e.id), ['f']);
    expect(undo.writes['a.entries.x'], isNull);
    expect((undo.writes['a.entries.f']! as Map)['kind'], 'off');
  });

  group('todayPlan — eine Ableitung', () {
    final wed = DateTime(2026, 9, 23); // Mittwoch
    var week = WeekPlan.empty;
    week = week.add(a, strength('k', 3, dp: WeekDaypart.evening)).next;
    week = week.add(a, run('l', 3, dp: WeekDaypart.morning)).next;

    test('liest den Rhythmus des Wochentags', () {
      final items =
          todayPlan(wed, week: week, goal: TrainingGoal.empty);
      expect(items.map((i) => i.kind), [WeekKind.cardio, WeekKind.strength]);
      expect(items.every((i) => i.source == TodaySource.week), isTrue);
    });

    test('Termin schlägt Rhythmus je Spur — der Morgenlauf bleibt', () {
      final items = todayPlan(wed,
          week: week,
          goal: TrainingGoal.empty,
          appointments: const [TodayAppointment(id: 's1', title: 'Push')]);
      expect(items.map((i) => (i.kind, i.source)), [
        (WeekKind.cardio, TodaySource.week),
        (WeekKind.strength, TodaySource.appointment),
      ]);
    });

    test('Wechselwochen lesen Woche B in B-Wochen', () {
      final goal = TrainingGoal.empty
          .withWeekPattern(WeekPattern.alternating)
          .withCurrentWeek(isA: false, today: wed);
      final ab = week.add(WeekSide.b, run('b', 3)).next;
      final items = todayPlan(wed, week: ab, goal: goal);
      expect(items.single.entry?.id, 'b');
    });
  });

  test('Lesen übergeht Kaputtes und löst keinen Plan auf', () {
    final w = WeekPlan.fromStored(const {
      'a': {
        'entries': {
          'ok': {'weekday': 1, 'kind': 'strength', 'planId': 'gone', 'planName': 'Alt'},
          'kaputt': {'weekday': 9, 'kind': 'strength'},
          'cardio_ohne_art': {'weekday': 2, 'kind': 'cardio'},
        },
      },
    });
    expect(w.a.keys, ['ok']);
    expect(w.a['ok']!.planName, 'Alt');
  });
}
