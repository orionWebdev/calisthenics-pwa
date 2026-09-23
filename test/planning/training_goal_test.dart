import 'package:atem/features/planning/domain/training_goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const both = {Lane.strength, Lane.cardio};

  group('Offen ist keine Null', () {
    test('ein leeres Briefing hat keine Felder', () {
      expect(TrainingGoal.empty.fields, isEmpty);
      expect(TrainingGoal.empty.hasAny, isFalse);
    });

    test('eine leere Menge ist keine Antwort', () {
      final g = TrainingGoal.empty.withPlaces({}).withGoals({});
      expect(g.fields, isEmpty);
    });

    test('Zurücknehmen löscht den Pfad', () {
      final a = TrainingGoal.empty.withDescribes(Describes.current);
      final b = a.withDescribes(null);
      expect(a.diff(b), {'describes': null});
    });
  });

  group('Geschrieben wird die Differenz', () {
    test('nur der geänderte Pfad', () {
      final a = TrainingGoal.empty
          .withLanes(both)
          .withPerWeek(Lane.strength, 3);
      final b = a.withPerWeek(Lane.strength, 4);
      expect(a.diff(b), {'perWeek.strength': 4});
    });

    test('Mengen werden sortiert geschrieben — gleicher Inhalt, kein Diff', () {
      final a = TrainingGoal.empty.withGoals({TrainingAim.strength, TrainingAim.weight});
      final b = TrainingGoal.empty.withGoals({TrainingAim.weight, TrainingAim.strength});
      expect(a.diff(b), isEmpty);
      expect(a.fields['goals'], ['weight', 'strength']);
    });

    test('Rückgängig ist die umgekehrte Differenz', () {
      final before = TrainingGoal.empty
          .withLanes(both)
          .withPerWeek(Lane.cardio, 3)
          .withSchedule(DaySchedule.fixed)
          .withDays(Lane.cardio, {2, 4});
      final after = before.withLanes({Lane.strength});
      final undo = after.diff(before);
      expect(undo, {
        'modalities': ['strength', 'cardio'],
        'perWeek.cardio': 3,
        'days.cardio': [2, 4],
      });
    });
  });

  group('Abhängiges geht mit (Schreibregel 2)', () {
    test('„nur Kraft" löscht alles unter Cardio in einem Schreibvorgang', () {
      final before = TrainingGoal.empty
          .withLanes(both)
          .withPerWeek(Lane.strength, 3)
          .withPerWeek(Lane.cardio, 3)
          .withSchedule(DaySchedule.fixed)
          .withDays(Lane.cardio, {2})
          .withMultiPerDay(MultiPerDay.some)
          .withDayparts(Lane.cardio, {Daypart.morning});
      final after = before.withLanes({Lane.strength});
      expect(before.diff(after), {
        'modalities': ['strength'],
        'perWeek.cardio': null,
        'days.cardio': null,
        'dayparts.cardio': null,
      });
      final removal = TrainingGoal.removedBy(before, after);
      expect(removal, isA<LaneRemoval>());
      expect((removal! as LaneRemoval).lanes, [Lane.cardio]);
    });

    test('ohne Angaben unter der Spur gibt es keine Snackbar', () {
      final before = TrainingGoal.empty.withLanes(both);
      final after = before.withLanes({Lane.strength});
      expect(TrainingGoal.removedBy(before, after), isNull);
    });

    test('Frage 1 zurücknehmen nimmt auch „feste Tage" mit', () {
      final before = TrainingGoal.empty
          .withLanes({Lane.strength})
          .withSchedule(DaySchedule.free);
      final after = before.withLanes(null);
      expect(after.schedule, isNull);
      expect(after.fields, isEmpty);
    });

    test('ohne Wechselwochen fallen Woche B und Anker weg', () {
      final before = TrainingGoal.empty
          .withLanes({Lane.strength})
          .withWeekPattern(WeekPattern.alternating)
          .withCurrentWeek(isA: true, today: DateTime(2026, 9, 23))
          .withPerWeek(Lane.strength, 2, weekB: true);
      final after = before.withWeekPattern(WeekPattern.same);
      expect(before.diff(after), {
        'weekPattern': 'same',
        'anchorWeekStart': null,
        'perWeekB.strength': null,
      });
      expect(TrainingGoal.removedBy(before, after), isA<WeekBRemoval>());
    });

    test('„wie es passt" löscht die Tage', () {
      final before = TrainingGoal.empty
          .withLanes({Lane.strength})
          .withSchedule(DaySchedule.fixed)
          .withDays(Lane.strength, {1, 3, 5});
      final after = before.withSchedule(DaySchedule.free);
      expect(after.days.isEmpty, isTrue);
      expect(TrainingGoal.removedBy(before, after), isA<DaysRemoval>());
    });

    test('„Nein" bei mehrmals am Tag löscht die Tageszeiten', () {
      final before = TrainingGoal.empty
          .withLanes({Lane.cardio})
          .withMultiPerDay(MultiPerDay.most)
          .withDayparts(Lane.cardio, {Daypart.morning});
      final after = before.withMultiPerDay(MultiPerDay.no);
      expect(after.dayparts.isEmpty, isTrue);
      expect(TrainingGoal.removedBy(before, after), isA<DaypartsRemoval>());
    });
  });

  group('Wechselwochen', () {
    final wed = DateTime(2026, 9, 23); // Mittwoch

    test('„diese Woche ist A" legt den Montag dieser Woche ab', () {
      final g = TrainingGoal.empty
          .withWeekPattern(WeekPattern.alternating)
          .withCurrentWeek(isA: true, today: wed);
      expect(g.fields['anchorWeekStart'], '2026-09-21');
      expect(g.isWeekA(wed), isTrue);
      expect(g.isWeekA(DateTime(2026, 9, 28)), isFalse);
      expect(g.isWeekA(DateTime(2026, 10, 5)), isTrue);
    });

    test('„diese Woche ist B" legt den Montag der Vorwoche ab', () {
      final g = TrainingGoal.empty
          .withWeekPattern(WeekPattern.alternating)
          .withCurrentWeek(isA: false, today: wed);
      expect(g.fields['anchorWeekStart'], '2026-09-14');
      expect(g.isWeekA(wed), isFalse);
    });

    test('ohne Wechselwochen keine Aussage über A oder B', () {
      expect(TrainingGoal.empty.isWeekA(wed), isNull);
    });
  });

  test('die vier Menschen aus Board 18 sind vier verschiedene Datensätze', () {
    final p1 = TrainingGoal.empty
        .withLanes(both)
        .withWeekPattern(WeekPattern.same)
        .withPerWeek(Lane.strength, 3)
        .withPerWeek(Lane.cardio, 3)
        .withSchedule(DaySchedule.fixed)
        .withDays(Lane.strength, {1, 3, 5})
        .withDays(Lane.cardio, {2, 4, 6});
    final p2 = TrainingGoal.empty
        .withLanes({Lane.strength})
        .withPerWeek(Lane.strength, 4)
        .withSchedule(DaySchedule.free)
        .withPlaces({Place.home});
    final p3 = TrainingGoal.empty
        .withLanes({Lane.cardio})
        .withWeekPattern(WeekPattern.irregular)
        .withPerWeek(Lane.cardio, 5);
    final p4 = TrainingGoal.empty
        .withLanes(both)
        .withPerWeek(Lane.strength, 5)
        .withPerWeek(Lane.cardio, 6)
        .withMultiPerDay(MultiPerDay.most)
        .withDayparts(Lane.strength, {Daypart.evening})
        .withDayparts(Lane.cardio, {Daypart.morning});
    final all = [p1, p2, p3, p4];
    for (var i = 0; i < all.length; i++) {
      for (var j = i + 1; j < all.length; j++) {
        expect(all[i] == all[j], isFalse, reason: 'Person ${i + 1} ≠ ${j + 1}');
      }
    }
    // Bei „nur Kraft" taucht Cardio nirgends auf.
    expect(p2.fields.keys.where((k) => k.contains('cardio')), isEmpty);
  });
}
