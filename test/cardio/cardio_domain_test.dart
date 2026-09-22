import 'package:atem/features/cardio/domain/cardio_intensity.dart';
import 'package:atem/features/pulse/domain/heart_rate_zones.dart';
import 'package:atem/features/cardio/domain/distance_distribution.dart';
import 'package:atem/features/cardio/domain/iso_week.dart';
import 'package:atem/features/cardio/domain/pace_series.dart';
import 'package:atem/features/cardio/domain/week_ratio.dart';
import 'package:atem/features/cardio/domain/weekly_distance.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mittwoch, 26.08.2026 — KW 35, derselbe Stichtag wie im Board.
final ref = DateTime(2026, 8, 26);

CardioSession run(
  String id,
  DateTime date, {
  double? km,
  int minutes = 40,
  int? rpe,
  int? avgHr,
  int? maxHr,
  CardioActivity? activity = CardioActivity.run,
}) =>
    CardioSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      activity: activity,
      distanceKm: km,
      duration: Duration(minutes: minutes),
      rpe: rpe,
      avgHr: avgHr,
      maxHr: maxHr,
    );

StrengthSession lift(String id, DateTime date, {int minutes = 60}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      duration: Duration(minutes: minutes),
      exercises: const [
        LoggedExercise(
          exerciseId: 'x',
          sets: [LoggedSet(reps: 10, weight: 50), LoggedSet(reps: 10, weight: 50)],
        ),
      ],
    );

void main() {
  group('IsoWeek', () {
    test('Montag zuerst, KW nach ISO', () {
      expect(IsoWeek.start(ref), DateTime(2026, 8, 24));
      expect(IsoWeek.number(ref), 35);
      // Der 1. Januar 2027 ist ein Freitag — er gehört noch zu KW 53 von 2026.
      expect(IsoWeek.number(DateTime(2027, 1, 1)), 53);
    });
  });

  group('WeeklyDistance', () {
    test('leer ohne Ausdauereinheiten', () {
      expect(WeeklyDistance.compute([lift('a', ref)], ref).isEmpty, isTrue);
    });

    test('unter drei Wochen mit Einheiten keine Wochenzahl', () {
      final w = WeeklyDistance.compute([
        run('a', DateTime(2026, 8, 4), km: 5.7),
        run('b', DateTime(2026, 8, 13), km: 6.1),
        run('c', DateTime(2026, 8, 24), km: 6.8),
      ], ref);
      // Drei Läufe in drei verschiedenen Wochen — das reicht gerade.
      expect(w.weeksWithSessions, 3);
      expect(w.hasWeekly, isTrue);

      final thin = WeeklyDistance.compute([
        run('a', DateTime(2026, 8, 4), km: 5.7),
        run('b', DateTime(2026, 8, 24), km: 6.8),
      ], ref);
      expect(thin.hasWeekly, isFalse);
      expect(thin.totalKm, closeTo(12.5, 1e-9));
      expect(thin.firstDate, DateTime(2026, 8, 4));
    });

    test('acht Wochen im Streifen, die leeren eingeschlossen', () {
      final w = WeeklyDistance.compute([
        run('a', DateTime(2026, 7, 6), km: 10), // KW 28
        run('b', DateTime(2026, 8, 25), km: 7.8), // KW 35, laufend
        run('c', DateTime(2026, 8, 24), km: 5.2),
      ], ref);
      expect(w.weeks, hasLength(8));
      expect(w.weeks.first.weekStart, DateTime(2026, 7, 6));
      expect(w.weeks.last.isCurrent, isTrue);
      expect(w.weeks.last.km, closeTo(13.0, 1e-9));
      expect(w.weeks.last.count, 2);
      // KW 29 bis 34 sind leer — und stehen trotzdem da.
      expect(w.weeks.where((x) => x.isEmpty).length, 6);
      expect(w.thisWeekKm, closeTo(13.0, 1e-9));
    });

    test('4-Wochen-Schnitt erst ab vier Wochen Geschichte, leere zählen 0',
        () {
      final young = WeeklyDistance.compute([
        run('a', DateTime(2026, 8, 12), km: 10),
        run('b', DateTime(2026, 8, 25), km: 7),
      ], ref);
      expect(young.fourWeekAverageKm, isNull);
      expect(young.shiftKm, isNull);

      final old = WeeklyDistance.compute([
        run('a', DateTime(2026, 7, 20), km: 20), // KW 30
        run('b', DateTime(2026, 8, 12), km: 12), // KW 33
        run('c', DateTime(2026, 8, 25), km: 7), // KW 35
      ], ref);
      // KW 31–34 sind die vier Wochen davor: 0 + 0 + 12 + 0.
      expect(old.fourWeekAverageKm, closeTo(3.0, 1e-9));
      expect(old.shiftKm, closeTo(4.0, 1e-9));
    });
  });

  group('DistanceDistribution', () {
    test('fünf Klassen, Nenner nur mit Distanz', () {
      final d = DistanceDistribution.compute([
        run('a', ref, km: 3),
        run('b', ref, km: 5),
        run('c', ref, km: 7.9),
        run('d', ref, km: 12),
        run('e', ref, km: 25),
        run('f', ref), // ohne Distanz
      ]);
      expect(d.total, 6);
      expect(d.withDistance, 5);
      expect(d.buckets.map((b) => b.count), [1, 2, 0, 1, 1]);
    });
  });

  group('PaceSeries', () {
    final runs = [
      for (var i = 0; i < 10; i++)
        run('r$i', DateTime(2026, 6, 1 + i * 5), km: 10, minutes: 50 + i),
    ];

    test('Median, Spanne, Kurve und Perzentil je Aktivität', () {
      final s = PaceSeries.forActivity(runs, CardioActivity.run);
      expect(s.count, 10);
      expect(s.hasCurve, isTrue);
      expect(s.hasPercentile, isTrue);
      // 5,0 bis 5,9 min/km — Median zwischen 5,4 und 5,5.
      expect(s.median, closeTo(5.45, 1e-9));
      expect(s.fastest, closeTo(5.0, 1e-9));
      expect(s.slowest, closeTo(5.9, 1e-9));
      expect(s.fasterThan(5.0), 9);
      expect(s.aboveMedian(5.0), isTrue);
      expect(s.aboveMedian(5.9), isFalse);
    });

    test('Rad rechnet in km/h — grösser ist besser', () {
      final rides = [
        for (var i = 0; i < 3; i++)
          run('b$i', DateTime(2026, 7, 1 + i), km: 20, minutes: 60 - i * 6,
              activity: CardioActivity.bike),
      ];
      final s = PaceSeries.forActivity(rides, CardioActivity.bike);
      expect(s.usesSpeed, isTrue);
      expect(s.fastest, closeTo(25.0, 1e-9)); // 20 km in 48 min
      expect(s.slowest, closeTo(20.0, 1e-9));
      expect(s.fasterThan(25.0), 2);
      expect(s.hasCurve, isFalse);
    });

    test('Einheiten ohne Distanz haben kein Tempo und fehlen', () {
      final s = PaceSeries.forActivity(
          [...runs, run('x', ref)], CardioActivity.run);
      expect(s.count, 10);
    });
  });

  group('CardioIntensity — welche Stufe führt', () {
    final base = [
      for (var i = 0; i < 5; i++)
        run('r$i', DateTime(2026, 7, 1 + i * 4), km: 10, minutes: 55),
    ];

    // Dieselben fünf Grenzen wie im Pulsblock und in „Zone 5 je Woche".
    final zones = HeartRateZones.tryFrom(const [120, 140, 160, 175])!;

    test('Stufe 1 braucht Ø-Puls und festgelegte Zonen', () {
      final s = run('h', ref, km: 10, minutes: 50, avgHr: 154, maxHr: 188);
      final i = CardioIntensity.of(s, [...base, s], zones: zones)!;
      expect(i.level, IntensityLevel.heartRate);
      expect(i.zone, 3); // 154 liegt zwischen 140 und 160
    });

    test('ohne festgelegte Zonen fällt die Kaskade auf Stufe 2', () {
      // Board 16, Entscheidung 13: ATEM rechnet keine Zonen, solange die
      // Grenzen fehlen, und schlägt auch keine still vor. Eine Prozenttabelle
      // wäre genau so ein stiller Vorschlag — sie ist am 22.09.2026 entfallen.
      final s = run('a', ref, km: 10, avgHr: 154, maxHr: 188, rpe: 4);
      expect(CardioIntensity.of(s, [...base, s])!.level, IntensityLevel.rpe);
    });

    test('der Maximalpuls entscheidet die Stufe nicht mehr mit', () {
      // Früher brauchte Stufe 1 **beide** Pulswerte. Der Ø-Puls genügt
      // jetzt — das Maximum steht weiter als Rohwert darunter.
      final s = run('a', ref, km: 10, avgHr: 150);
      expect(CardioIntensity.of(s, [...base, s])!.level, IntensityLevel.pace);
      final withZones = CardioIntensity.of(s, [...base, s], zones: zones)!;
      expect(withZones.level, IntensityLevel.heartRate);
      expect(withZones.maxHr, isNull);
    });

    test('Stufe 3 braucht drei Einheiten derselben Aktivität', () {
      final s = run('a', ref, km: 10, minutes: 50);
      expect(CardioIntensity.of(s, [...base, s])!.level, IntensityLevel.pace);
      expect(CardioIntensity.of(s, [...base, s])!.aboveAverage, isTrue);
      expect(CardioIntensity.of(s, [s]), isNull);
      // Ohne Distanz kein Tempo, also auch keine Stufe 3.
      final noKm = run('n', ref);
      expect(CardioIntensity.of(noKm, [...base, noKm]), isNull);
    });

    test('die Rohwerte stehen immer alle drei da', () {
      final s = run('a', ref, km: 10, minutes: 50, rpe: 4);
      final i = CardioIntensity.of(s, [...base, s])!;
      expect(i.level, IntensityLevel.rpe);
      expect(i.avgHr, isNull);
      expect(i.tempoValue, closeTo(5.0, 1e-9));
      expect(i.basisCount, 6);
    });

    test('die Zone kommt aus den festgelegten Grenzen, nicht aus Prozent', () {
      CardioIntensity at(int bpm) {
        final s = run('z$bpm', ref, km: 10, minutes: 50, avgHr: bpm);
        return CardioIntensity.of(s, [...base, s], zones: zones)!;
      }

      expect(at(110).zone, 1); // Zone 1 ist nach unten offen
      expect(at(130).zone, 2);
      expect(at(154).zone, 3);
      expect(at(168).zone, 4);
      expect(at(180).zone, 5);
    });
  });

  group('WeekRatio', () {
    test('Anteil über Trainingsminuten, Fachgrösse je Spur', () {
      final r = WeekRatio.compute([
        lift('a', DateTime(2026, 8, 24), minutes: 60),
        lift('b', DateTime(2026, 8, 25), minutes: 60),
        run('c', DateTime(2026, 8, 25), km: 10, minutes: 60),
        // Regeneration zählt nicht.
        RecoverySession(
            id: 'r',
            userId: 'u',
            date: DateTime(2026, 8, 25),
            createdAt: ref,
            duration: const Duration(minutes: 30)),
      ], ref);
      expect(r.totalMinutes, 180);
      expect(r.totalCount, 3);
      expect(r.strengthPercent, 67);
      expect(r.cardioPercent, 33);
      expect(r.strength.measure, closeTo(2.0, 1e-9)); // 2 × 1000 kg
      expect(r.cardio.measure, closeTo(10, 1e-9));
      expect(r.hasBothTracks, isTrue);
      expect(r.shiftPp, isNull, reason: 'keine vier Wochen Geschichte');
    });

    test('Verschiebung gegen die vier Wochen davor, leere Wochen ausgelassen',
        () {
      final r = WeekRatio.compute([
        // KW 30: nur Kraft → 100 %.
        lift('a', DateTime(2026, 7, 20)),
        // KW 33: halbe-halbe.
        lift('b', DateTime(2026, 8, 12), minutes: 30),
        run('c', DateTime(2026, 8, 12), km: 5, minutes: 30),
        // KW 35: 75 % Kraft.
        lift('d', DateTime(2026, 8, 24), minutes: 90),
        run('e', DateTime(2026, 8, 25), km: 5, minutes: 30),
      ], ref);
      // KW 31–34: nur KW 33 trägt Minuten → Schnitt 50 %. 75 − 50 = 25 pp.
      expect(r.shiftPp, closeTo(25, 1e-9));
    });

    test('nur eine Spur — kein Verhältnis', () {
      final r = WeekRatio.compute([lift('a', DateTime(2026, 8, 24))], ref);
      expect(r.hasBothTracks, isFalse);
      expect(r.strengthPercent, 100);
    });
  });
}
