import 'package:atem/features/history/domain/focus_distribution.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _reference = DateTime(2026, 9, 16, 15, 30);

StrengthSession _strength(String id, DateTime date,
        {WorkoutFocus? focus, bool bodyweight = false}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: bodyweight,
      workoutFocus: focus,
    );

void main() {
  group('Fenster', () {
    test('Tag 56 ist drin, Tag 57 nicht', () {
      final d = FocusDistribution.compute([
        // 16.09. minus 55 Tage = 23.07. (Tag 56 des Fensters)
        _strength('in', DateTime(2026, 7, 23, 6), focus: WorkoutFocus.pull),
        _strength('out', DateTime(2026, 7, 22, 23), focus: WorkoutFocus.push),
      ], _reference);
      expect(d.withFocus, 1);
      expect(d.shares.single.focus, WorkoutFocus.pull);
    });

    test('Einheiten nach dem Stichtag zählen nicht', () {
      final d = FocusDistribution.compute([
        _strength('morgen', DateTime(2026, 9, 17, 6), focus: WorkoutFocus.legs),
        _strength('heute spät', DateTime(2026, 9, 16, 23, 59),
            focus: WorkoutFocus.legs),
      ], _reference);
      expect(d.withFocus, 1);
    });
  });

  test('Cardio und Regeneration zählen nicht, Körpergewicht schon', () {
    final d = FocusDistribution.compute([
      CardioSession(
          id: 'c', userId: 'u', date: _reference, createdAt: _reference),
      RecoverySession(
          id: 'r', userId: 'u', date: _reference, createdAt: _reference),
      _strength('bw', _reference, focus: WorkoutFocus.core, bodyweight: true),
    ], _reference);
    expect(d.total, 1);
    expect(d.shares.single.focus, WorkoutFocus.core);
  });

  test('Einheiten ohne Fokus werden getrennt gezählt, nicht als Anteil', () {
    final d = FocusDistribution.compute([
      _strength('a', _reference, focus: WorkoutFocus.push),
      _strength('b', _reference),
      _strength('c', _reference),
    ], _reference);
    expect(d.withFocus, 1);
    expect(d.withoutFocus, 2);
    expect(d.total, 3);
    expect(d.percentOf(d.shares.single), 100,
        reason: 'Der Nenner ist withFocus, nicht total.');
    expect(d.hasEnough, isFalse);
  });

  test('Prozent werden gerundet', () {
    final d = FocusDistribution.compute([
      _strength('1', _reference, focus: WorkoutFocus.push),
      _strength('2', _reference, focus: WorkoutFocus.pull),
      _strength('3', _reference, focus: WorkoutFocus.pull),
    ], _reference);
    final pull = d.shares.firstWhere((s) => s.focus == WorkoutFocus.pull);
    final push = d.shares.firstWhere((s) => s.focus == WorkoutFocus.push);
    expect(d.percentOf(pull), 67);
    expect(d.percentOf(push), 33);
    expect(d.hasEnough, isTrue);
  });

  test('sortiert nach Anzahl, bei Gleichstand in Enum-Reihenfolge', () {
    final d = FocusDistribution.compute([
      _strength('1', _reference, focus: WorkoutFocus.legs),
      _strength('2', _reference, focus: WorkoutFocus.fullBody),
      _strength('3', _reference, focus: WorkoutFocus.fullBody),
      _strength('4', _reference, focus: WorkoutFocus.push),
    ], _reference);
    expect(d.shares.map((s) => s.focus), [
      WorkoutFocus.fullBody,
      WorkoutFocus.push,
      WorkoutFocus.legs,
    ]);
  });

  test('ohne Einheiten ist alles leer und 0', () {
    final d = FocusDistribution.compute(const [], _reference);
    expect(d.shares, isEmpty);
    expect(d.total, 0);
    expect(d.hasEnough, isFalse);
  });
}
