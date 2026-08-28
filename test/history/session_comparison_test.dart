import 'package:atem/features/history/domain/session_comparison.dart';
import 'package:atem/features/history/domain/training_load.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

StrengthSession _strength(
  String id,
  DateTime date, {
  String? planId,
  List<LoggedExercise> exercises = const [],
  Duration? duration,
}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      planId: planId,
      exercises: exercises,
      duration: duration,
    );

LoggedExercise _bench(List<LoggedSet> sets) =>
    LoggedExercise(exerciseId: 'bench', sets: sets);

void main() {
  group('Kennzahlen', () {
    test('Volumen ist null ohne Satzdaten, nicht 0', () {
      final figures = SessionFigures.of(
        _strength('a', DateTime(2026, 8, 1)),
        const LoadContext(),
      );
      expect(figures.volume, isNull,
          reason: '„kein Volumen erfasst" und „nichts bewegt" sind '
              'verschiedene Aussagen');
      expect(figures.sets, isNull);
    });

    test('zählt Sätze und Volumen getrennt', () {
      final figures = SessionFigures.of(
        _strength('a', DateTime(2026, 8, 1), exercises: [
          _bench(const [
            LoggedSet(reps: 10, weight: 50),
            LoggedSet(reps: 10),
          ]),
        ]),
        const LoadContext(),
      );
      expect(figures.sets, 2);
      expect(figures.volume, 500);
      expect(figures.exercises, 1);
    });

    test('leere Sätze zählen nicht mit', () {
      final figures = SessionFigures.of(
        _strength('a', DateTime(2026, 8, 1), exercises: [
          _bench(const [LoggedSet(), LoggedSet(reps: 5, weight: 60)]),
        ]),
        const LoadContext(),
      );
      expect(figures.sets, 1);
    });

    test('Cardio trägt die Strecke, Kraft nicht', () {
      final cardio = SessionFigures.of(
        CardioSession(
          id: 'c',
          userId: 'u',
          date: DateTime(2026, 8, 1),
          createdAt: DateTime(2026, 8, 1),
          distanceKm: 8,
        ),
        const LoadContext(),
      );
      expect(cardio.distanceKm, 8);
      expect(cardio.volume, isNull);
    });
  });

  group('Das Gegenstück finden', () {
    final all = [
      _strength('alt', DateTime(2026, 5, 1), planId: 'p1'),
      _strength('mitte', DateTime(2026, 6, 1), planId: 'p1'),
      _strength('anderer', DateTime(2026, 7, 1), planId: 'p2'),
      _strength('neu', DateTime(2026, 8, 1), planId: 'p1'),
    ];

    test('nimmt die jüngste frühere, die passt', () {
      final previous = SessionComparison.previousOf(
        all.last,
        all,
        matches: (c) => c is StrengthSession && c.planId == 'p1',
      );
      expect(previous?.id, 'mitte');
    });

    test('sieht nie nach vorn', () {
      // Eine später erfasste Einheit ist kein „letztes Mal".
      final previous = SessionComparison.previousOf(
        all.first,
        all,
        matches: (c) => true,
      );
      expect(previous, isNull);
    });

    test('überspringt sich selbst', () {
      final previous = SessionComparison.previousOf(
        all[1],
        all,
        matches: (c) => c.id == 'mitte',
      );
      expect(previous, isNull);
    });

    test('liefert null, wenn nichts passt', () {
      final previous = SessionComparison.previousOf(
        all.last,
        all,
        matches: (c) => c is StrengthSession && c.planId == 'gibtsnicht',
      );
      expect(previous, isNull);
    });

    test('bei gleichem Datum entscheidet keine Zufälligkeit', () {
      // Zwei Einheiten am selben Tag: Keine liegt *vor* der anderen, also
      // gibt es kein Gegenstück. Lieber keine Aussage als eine geratene.
      final sameDay = [
        _strength('a', DateTime(2026, 8, 1), planId: 'p1'),
        _strength('b', DateTime(2026, 8, 1), planId: 'p1'),
      ];
      expect(
        SessionComparison.previousOf(sameDay.first, sameDay,
            matches: (c) => true),
        isNull,
      );
    });
  });

  group('Der Vergleich', () {
    test('ohne Gegenstück gibt es keine Veränderung', () {
      final comparison = SessionComparison.build(
        _strength('a', DateTime(2026, 8, 1)),
        null,
      );
      expect(comparison.hasReference, isFalse);
      expect(comparison.loadChange, isNull);
      expect(comparison.daysBetween, isNull);
    });

    test('nennt beide Zahlen und den Abstand', () {
      final current = _strength('neu', DateTime(2026, 8, 1), exercises: [
        _bench(const [LoggedSet(reps: 10, weight: 50)]),
      ]);
      final earlier = _strength('alt', DateTime(2026, 7, 25), exercises: [
        _bench(const [LoggedSet(reps: 10, weight: 40)]),
      ]);

      final comparison = SessionComparison.build(current, earlier);
      expect(comparison.hasReference, isTrue);
      expect(comparison.current.volume, 500);
      expect(comparison.previous!.volume, 400);
      expect(comparison.volumeChange, closeTo(0.25, 0.0001));
      expect(comparison.daysBetween, 7);
    });

    test('von null aus gibt es keine Prozentzahl', () {
      expect(SessionComparison.change(0, 100), isNull,
          reason: 'eine Steigerung von null ist ein Anfang, keine Rate');
      expect(SessionComparison.change(null, 100), isNull);
      expect(SessionComparison.change(100, null), isNull);
    });

    test('ein Rückgang ist negativ, nicht fehlend', () {
      expect(SessionComparison.change(100, 80), closeTo(-0.2, 0.0001));
    });
  });
}
