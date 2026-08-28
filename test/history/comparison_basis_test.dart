import 'package:atem/features/history/domain/comparison_basis.dart';
import 'package:atem/features/history/domain/session_comparison.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

StrengthSession _strength(
  String id,
  DateTime date, {
  String? planId,
  List<String> exercises = const [],
  int minutes = 50,
}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      planId: planId,
      duration: Duration(minutes: minutes),
      exercises: [
        for (final e in exercises)
          LoggedExercise(
            exerciseId: e,
            sets: const [LoggedSet(reps: 8, weight: 60)],
          ),
      ],
    );

CardioSession _cardio(String id, DateTime date, {int minutes = 40}) =>
    CardioSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      duration: Duration(minutes: minutes),
    );

final _heute = DateTime(2026, 8, 28);

void main() {
  group('Stufe A — gleicher Plan', () {
    test('nimmt die jüngste vorherige desselben Plans', () {
      final all = [
        _strength('alt', _heute.subtract(const Duration(days: 30)),
            planId: 'p1'),
        _strength('mitte', _heute.subtract(const Duration(days: 12)),
            planId: 'p1'),
        _strength('fremd', _heute.subtract(const Duration(days: 3)),
            planId: 'p2'),
        _strength('jetzt', _heute, planId: 'p1'),
      ];

      final match = ComparisonResolver.resolve(all.last, all)!;
      expect(match.basis, ComparisonBasis.samePlan);
      expect(match.reference?.id, 'mitte',
          reason: 'gegen den letzten Stand, nicht gegen den ersten');
    });

    test('geht vor Stufe B, auch wenn die Übungen abweichen', () {
      final all = [
        _strength('plan', _heute.subtract(const Duration(days: 20)),
            planId: 'p1', exercises: ['a']),
        _strength('gleich', _heute.subtract(const Duration(days: 2)),
            exercises: ['x', 'y', 'z']),
        _strength('jetzt', _heute, planId: 'p1', exercises: ['x', 'y', 'z']),
      ];

      final match = ComparisonResolver.resolve(all.last, all)!;
      expect(match.basis, ComparisonBasis.samePlan);
      expect(match.reference?.id, 'plan');
    });
  });

  group('Stufe B — gleiche Übungen', () {
    test('greift ab 60 Prozent Überdeckung', () {
      // 3 gemeinsam von 4 insgesamt = 0,75.
      final all = [
        _strength('davor', _heute.subtract(const Duration(days: 4)),
            exercises: ['a', 'b', 'c']),
        _strength('jetzt', _heute, exercises: ['a', 'b', 'c', 'd']),
      ];

      final match = ComparisonResolver.resolve(all.last, all)!;
      expect(match.basis, ComparisonBasis.sameExercises);
      expect(match.reference?.id, 'davor');
    });

    test('unter 60 Prozent fällt es auf Stufe C', () {
      // 1 gemeinsam von 5 insgesamt = 0,2.
      final all = [
        _strength('rücken', _heute.subtract(const Duration(days: 4)),
            exercises: ['a', 'b', 'c']),
        _strength('jetzt', _heute, exercises: ['a', 'd', 'e']),
      ];

      final match = ComparisonResolver.resolve(all.last, all)!;
      expect(match.basis, ComparisonBasis.sameKind,
          reason: 'eine getauschte Grundübung verschiebt Volumen und Sätze');
    });

    test('älter als 90 Tage zählt nicht mehr', () {
      final all = [
        _strength('uralt', _heute.subtract(const Duration(days: 200)),
            exercises: ['a', 'b']),
        _strength('jetzt', _heute, exercises: ['a', 'b']),
      ];

      final match = ComparisonResolver.resolve(all.last, all)!;
      expect(match.basis, ComparisonBasis.sameKind);
    });

    test('die Überdeckung zählt beide Seiten', () {
      // Zwei Übungen gegen zwanzig: „alle meine kommen vor" wäre 100 %,
      // Jaccard sagt 0,1.
      expect(
        ComparisonResolver.jaccard(
          {'a', 'b'},
          {for (var i = 0; i < 20; i++) 'e$i', 'a', 'b'},
        ),
        lessThan(0.2),
      );
      expect(ComparisonResolver.jaccard({'a'}, {'a'}), 1.0);
      expect(ComparisonResolver.jaccard({}, {'a'}), 0);
    });
  });

  group('Stufe C — gleiche Art', () {
    test('bildet den Median der letzten fünf', () {
      final all = <TrainingSession>[
        for (var i = 1; i <= 6; i++)
          _cardio('c$i', _heute.subtract(Duration(days: i * 3)),
              minutes: i * 10),
        _cardio('jetzt', _heute, minutes: 41),
      ];

      final comparison = SessionComparison.forSession(all.last, all);
      expect(comparison.basis, ComparisonBasis.sameKind);
      expect(comparison.medianCount, 5);
      // Die fünf jüngsten sind 10,20,30,40,50 Minuten → Median 30.
      expect(comparison.previous?.duration, const Duration(minutes: 30));
    });

    test('trägt Volumen und Sätze nicht', () {
      final all = [
        _strength('a', _heute.subtract(const Duration(days: 10)),
            exercises: ['x']),
        _strength('b', _heute.subtract(const Duration(days: 5)),
            exercises: ['y']),
        _strength('jetzt', _heute, exercises: ['z']),
      ];

      final comparison = SessionComparison.forSession(all.last, all);
      expect(comparison.basis, ComparisonBasis.sameKind);
      expect(comparison.comparesVolume, isFalse);
      expect(comparison.previous?.volume, isNull,
          reason: 'zwei Krafteinheiten mit verschiedenen Übungen haben kein '
              'vergleichbares Volumen');
      expect(comparison.previous?.sets, isNull);
      // Dauer und Last sind von den Übungen unabhängig und bleiben.
      expect(comparison.previous?.duration, isNotNull);
    });

    test('der Median glättet einen Ausreisser', () {
      final all = <TrainingSession>[
        _cardio('lang', _heute.subtract(const Duration(days: 3)),
            minutes: 240),
        for (var i = 2; i <= 5; i++)
          _cardio('c$i', _heute.subtract(Duration(days: i * 4)), minutes: 40),
        _cardio('jetzt', _heute, minutes: 45),
      ];

      final comparison = SessionComparison.forSession(all.last, all);
      // Mittelwert wäre 80, Median ist 40.
      expect(comparison.previous?.duration, const Duration(minutes: 40));
    });
  });

  group('Kein Vergleich', () {
    test('Regeneration bekommt keinen', () {
      final all = <TrainingSession>[
        RecoverySession(
            id: 'a',
            userId: 'u',
            date: _heute.subtract(const Duration(days: 5)),
            createdAt: _heute),
        RecoverySession(
            id: 'jetzt', userId: 'u', date: _heute, createdAt: _heute),
      ];
      expect(ComparisonResolver.resolve(all.last, all), isNull);
    });

    test('die erste Einheit überhaupt', () {
      final all = [_strength('erste', _heute, planId: 'p1')];
      final comparison = SessionComparison.forSession(all.first, all);
      expect(comparison.hasReference, isFalse);
      expect(comparison.basis, isNull);
    });

    test('eine spätere Einheit zählt nie als Bezug', () {
      final all = [
        _strength('jetzt', _heute, planId: 'p1'),
        _strength('später', _heute.add(const Duration(days: 3)),
            planId: 'p1'),
      ];
      expect(ComparisonResolver.resolve(all.first, all), isNull);
    });
  });

  test('die Schwelle steht als eine Konstante', () {
    // Sie ist gesetzt und nicht am Bestand geprüft — dafür soll sie an einer
    // Stelle stehen und nicht verstreut.
    expect(ComparisonResolver.overlapThreshold, 0.6);
    expect(ComparisonResolver.overlapWindowDays, 90);
    expect(ComparisonResolver.medianCount, 5);
  });
}
