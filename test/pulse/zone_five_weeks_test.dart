import 'package:atem/core/domain/pulse_profile.dart';
import 'package:atem/features/pulse/domain/heart_rate_zones.dart';
import 'package:atem/features/pulse/domain/zone_five_weeks.dart';
import 'package:flutter_test/flutter_test.dart';

/// Zone 5 je Woche — reine Rechnung, ohne Gerät.
void main() {
  final zones = HeartRateZones.tryFrom(const [112, 131, 149, 168])!;
  // Sonntag, 20.09.2026: die laufende Woche beginnt am Montag, 14.09.
  final today = DateTime(2026, 9, 20);

  PulseRecord record(DateTime start, {required int zone5Minutes}) =>
      PulseRecord(
        start: start,
        pulse: PulseProfile(
          secondsByBpm: {
            130: 20 * 60,
            if (zone5Minutes > 0) 175: zone5Minutes * 60,
          },
          windowSeconds: (20 + zone5Minutes) * 60,
        ),
      );

  ZoneFiveWeeks compute(List<PulseRecord> records,
          {List<DateTime> sessions = const []}) =>
      ZoneFiveWeeks.compute(
        records: records,
        sessionDates: sessions,
        zones: zones,
        reference: today,
      );

  test('acht Wochen, die letzte ist die laufende', () {
    final result = compute(const []);
    expect(result.weeks, hasLength(8));
    expect(result.weeks.last.isCurrent, isTrue);
    expect(result.weeks.last.weekStart, DateTime(2026, 9, 14));
    expect(result.weeks.first.weekStart, DateTime(2026, 7, 27));
    expect(result.hasPulse, isFalse, reason: 'die Schwelle des Blocks');
  });

  test('summiert die Zeit in Zone 5 je Woche', () {
    final result = compute([
      record(DateTime(2026, 9, 15, 18), zone5Minutes: 4),
      record(DateTime(2026, 9, 18, 18), zone5Minutes: 6),
      record(DateTime(2026, 9, 9, 18), zone5Minutes: 3),
    ]);

    expect(result.weeks.last.minutes, 10);
    expect(result.weeks.last.sessions, 2);
    expect(result.weeks[result.weeks.length - 2].minutes, 3);
    expect(result.sessionsWithPulse, 3);
  });

  test('gemessen ohne Zone 5 ist etwas anderes als nichts gemessen', () {
    final result = compute([
      record(DateTime(2026, 9, 15, 18), zone5Minutes: 0),
    ]);

    final current = result.weeks.last;
    expect(current.measured, isTrue);
    expect(current.minutes, 0, reason: 'gemessen, und der Puls blieb darunter');

    // Die Woche davor hat keinen Puls: kein „0", sondern nichts.
    final before = result.weeks[result.weeks.length - 2];
    expect(before.measured, isFalse);
  });

  test('die Grenzen der Zonen bestimmen, was Zone 5 ist', () {
    // Dieselben Sekunden, andere Grenzen — Zone 5 wandert mit.
    final entry = PulseRecord(
      start: DateTime(2026, 9, 15, 18),
      pulse: const PulseProfile(
        secondsByBpm: {160: 600},
        windowSeconds: 600,
      ),
    );
    final strict = ZoneFiveWeeks.compute(
      records: [entry],
      sessionDates: const [],
      zones: zones,
      reference: today,
    );
    final loose = ZoneFiveWeeks.compute(
      records: [entry],
      sessionDates: const [],
      zones: HeartRateZones.tryFrom(const [90, 110, 130, 150])!,
      reference: today,
    );

    expect(strict.weeks.last.minutes, 0, reason: '160 liegt in Zone 4');
    expect(loose.weeks.last.minutes, 10, reason: '160 liegt über 150');
  });

  test('Einheiten ausserhalb der acht Wochen zählen nicht', () {
    final result = compute([
      record(DateTime(2026, 7, 1, 18), zone5Minutes: 9),
    ]);
    expect(result.hasPulse, isFalse);
  });

  test('der Nenner sind alle Einheiten, nicht nur die mit Puls', () {
    // „Aus 2 von 5 Einheiten": Puls gibt es nur aus der Uhr. Ein Streifen, der
    // nur die zwei zählte und das verschwiege, behauptete, die drei anderen
    // hätten keine Zeit in Zone 5 gehabt.
    final result = compute(
      [
        record(DateTime(2026, 9, 15, 18), zone5Minutes: 4),
        record(DateTime(2026, 9, 17, 18), zone5Minutes: 2),
      ],
      sessions: [
        DateTime(2026, 9, 15),
        DateTime(2026, 9, 16),
        DateTime(2026, 9, 17),
        DateTime(2026, 9, 18),
        DateTime(2026, 9, 19),
        DateTime(2026, 5, 1),
      ],
    );

    expect(result.sessionsWithPulse, 2);
    expect(result.sessionsInWindow, 5,
        reason: 'die Einheit vom Mai liegt ausserhalb des Streifens');
  });

  test('die längste Woche ist der Bezug der Balken', () {
    final result = compute([
      record(DateTime(2026, 9, 15, 18), zone5Minutes: 8),
      record(DateTime(2026, 9, 8, 18), zone5Minutes: 2),
    ]);
    expect(result.peakSeconds, 8 * 60);
  });

  test('der Nenner ist nie kleiner als der Zähler', () {
    // Eine übernommene Uhr-Einheit, deren App-Einheit fehlt, würde sonst als
    // „aus 2 von 0 Einheiten" erscheinen.
    final result = compute([
      record(DateTime(2026, 9, 15, 18), zone5Minutes: 4),
      record(DateTime(2026, 9, 17, 18), zone5Minutes: 2),
    ]);
    expect(result.sessionsInWindow, 2);
  });
}
