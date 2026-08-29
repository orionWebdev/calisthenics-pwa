import 'package:atem/features/history/domain/session_percentile.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

CardioSession _run(String id, {double? km, double? pace}) => CardioSession(
      id: id,
      userId: 'u',
      date: DateTime(2026, 8, 1),
      createdAt: DateTime(2026, 8, 1),
      activity: CardioActivity.run,
      distanceKm: km,
      pace: pace,
    );

void main() {
  group('Strecke — mehr ist besser', () {
    final runs = [
      for (final km in [3.0, 5.0, 8.0, 10.0, 12.0, 6.0])
        _run('r$km', km: km),
    ];

    test('die längste steht ganz oben', () {
      final p = SessionPercentile.of(12.0, runs, CardioActivity.run,
          select: (s) => s.distanceKm, higherIsBetter: true)!;
      expect(p.rank, 5, reason: 'fünf waren kürzer');
      expect(p.isTop, isTrue);
      expect(p.topPercent, 10);
    });

    test('die kürzeste ganz unten', () {
      final p = SessionPercentile.of(3.0, runs, CardioActivity.run,
          select: (s) => s.distanceKm, higherIsBetter: true)!;
      expect(p.rank, 0);
      expect(p.isTop, isFalse);
    });

    test('die Mitte ist Mittelfeld', () {
      final p = SessionPercentile.of(6.0, runs, CardioActivity.run,
          select: (s) => s.distanceKm, higherIsBetter: true)!;
      expect(p.isTop, isFalse);
      expect(p.share, closeTo(0.4, 0.01));
    });
  });

  group('Pace — weniger ist besser', () {
    final runs = [
      for (final pace in [5.0, 5.5, 6.0, 6.5, 7.0])
        _run('p$pace', pace: pace),
    ];

    test('die schnellste steht oben', () {
      final p = SessionPercentile.of(5.0, runs, CardioActivity.run,
          select: (s) => s.pace, higherIsBetter: false)!;
      expect(p.rank, 4, reason: 'vier waren langsamer');
      expect(p.isTop, isTrue);
    });

    test('die langsamste unten', () {
      final p = SessionPercentile.of(7.0, runs, CardioActivity.run,
          select: (s) => s.pace, higherIsBetter: false)!;
      expect(p.rank, 0);
    });
  });

  group('Wann es gar nichts sagt', () {
    test('unter fünf gleichartigen Einheiten', () {
      // „Top 20 %" wäre bei vier Läufen nur eine andere Schreibweise für
      // „von vier der beste" — und klänge nach mehr.
      final few = [for (var i = 0; i < 4; i++) _run('r$i', km: i + 1.0)];
      expect(
        SessionPercentile.of(4.0, few, CardioActivity.run,
            select: (s) => s.distanceKm, higherIsBetter: true),
        isNull,
      );
      expect(SessionPercentile.minimum, 5);
    });

    test('ohne Wert gibt es kein Perzentil', () {
      final runs = [for (var i = 0; i < 8; i++) _run('r$i', km: i + 1.0)];
      expect(
        SessionPercentile.of(null, runs, CardioActivity.run,
            select: (s) => s.distanceKm, higherIsBetter: true),
        isNull,
      );
    });

    test('eine andere Aktivität zählt nicht mit', () {
      // Eine Pace von 5:42 ist auf dem Rad keine Leistung und beim Laufen eine.
      final mixed = <TrainingSession>[
        for (var i = 0; i < 8; i++)
          CardioSession(
            id: 'b$i',
            userId: 'u',
            date: DateTime(2026, 8, 1),
            createdAt: DateTime(2026, 8, 1),
            activity: CardioActivity.bike,
            distanceKm: 30.0 + i,
          ),
      ];
      expect(
        SessionPercentile.of(8.0, mixed, CardioActivity.run,
            select: (s) => s.distanceKm, higherIsBetter: true),
        isNull,
        reason: 'acht Radfahrten sind kein Bestand für einen Lauf',
      );
    });

    test('Krafteinheiten fallen ganz weg', () {
      final strength = <TrainingSession>[
        for (var i = 0; i < 8; i++)
          StrengthSession(
            id: 's$i',
            userId: 'u',
            date: DateTime(2026, 8, 1),
            createdAt: DateTime(2026, 8, 1),
            bodyweight: false,
          ),
      ];
      expect(
        SessionPercentile.of(8.0, strength, CardioActivity.run,
            select: (s) => s.distanceKm, higherIsBetter: true),
        isNull,
      );
    });
  });

  test('Top-Prozent runden auf Zehner und nie unter zehn', () {
    const p = SessionPercentile(rank: 99, total: 100, higherIsBetter: true);
    expect(p.topPercent, 10, reason: '„Top 1 %" bei 100 Einheiten wäre '
        'eine Genauigkeit, die der Bestand nicht hergibt');
  });
}
