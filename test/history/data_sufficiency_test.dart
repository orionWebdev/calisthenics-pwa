import 'package:atem/features/history/domain/data_sufficiency.dart';
import 'package:atem/features/history/domain/readiness.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _ref = DateTime(2026, 6, 1);

/// Kalendarisch zurück, nicht über eine Dauer.
///
/// `subtract(Duration(days: n))` rechnet in Millisekunden und landet bei einer
/// Zeitumstellung im Fenster auf 23:00 des Vortags — derselbe Fehler, den die
/// PWA im Scoring hat. In einem Test, der Tagesabstände prüft, verschiebt er
/// die Erwartung um genau einen Tag.
DateTime _daysBefore(DateTime from, int days) =>
    DateTime(from.year, from.month, from.day - days);

List<TrainingSession> _history({required int spanDays, required int every}) {
  final sessions = <TrainingSession>[];
  for (var d = spanDays; d >= 0; d -= every) {
    final date = _daysBefore(_ref, d);
    sessions.add(StrengthSession(
      id: 's$d',
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      duration: const Duration(minutes: 45),
      rpe: 3,
    ));
  }
  return sessions;
}

void main() {
  group('Warum es die Schwellen zusätzlich zur Formel gibt', () {
    test('die Formel selbst lässt schon ab 14 Tagen alles durch', () {
      expect(Readiness.compute(_history(spanDays: 13, every: 2), _ref).acwr,
          isNull);
      expect(Readiness.compute(_history(spanDays: 14, every: 2), _ref).acwr,
          isNotNull);
    });

    test('und liefert bei dünner Datenlage das Gegenteil der Wahrheit', () {
      // Zweimal in vier Wochen — jemand, der zu WENIG trainiert.
      final duenn = _history(spanDays: 28, every: 28);
      final result = Readiness.compute(duenn, _ref);

      expect(duenn, hasLength(2));
      // Die chronische Last steht nahe null, das Verhältnis explodiert.
      expect(result.acwr, greaterThan(2.5));
      expect(result.zone, ReadinessZone.overreaching,
          reason: 'Die Formel meldet „übertrainiert" für jemanden, der '
              'zweimal im Monat trainiert. Genau davor schützt die Schwelle.');
    });

    test('dieselbe Spanne mit genug Einheiten ergibt einen sinnvollen Wert',
        () {
      final dicht = _history(spanDays: 28, every: 2);
      final result = Readiness.compute(dicht, _ref);

      expect(dicht.length, greaterThanOrEqualTo(8));
      expect(result.acwr, lessThan(2.0));
      expect(result.zone, isNot(ReadinessZone.overreaching));
    });
  });

  group('Die Schwellen halten beides auseinander', () {
    test('zu kurze Spanne genügt nicht, auch mit vielen Einheiten', () {
      // 15 Einheiten, aber nur über 14 Tage.
      final s = _history(spanDays: 14, every: 1);
      expect(s.length, greaterThanOrEqualTo(8));
      expect(DataSufficiency.hasAcwr(s, _ref), isFalse);
    });

    test('zu wenige Einheiten genügen nicht, auch bei langer Spanne', () {
      final s = _history(spanDays: 56, every: 28);
      expect(DataSufficiency.hasAcwr(s, _ref), isFalse);
    });

    test('beides zusammen reicht', () {
      final s = _history(spanDays: 28, every: 2);
      expect(DataSufficiency.hasAcwr(s, _ref), isTrue);
      expect(DataSufficiency.hasTrend(s, _ref), isTrue);
    });

    test('der Trend ist milder als der ACWR', () {
      // 21 bis 27 Tage: Trend ja, Belastungsverhältnis noch nicht.
      final s = _history(spanDays: 22, every: 2);
      expect(DataSufficiency.hasTrend(s, _ref), isTrue);
      expect(DataSufficiency.hasAcwr(s, _ref), isFalse);
    });

    test('Regeneration hübscht die Datenlage nicht auf', () {
      final erholung = [
        for (var d = 28; d >= 0; d -= 2)
          RecoverySession(
            id: 'r$d',
            userId: 'u',
            date: _daysBefore(_ref, d),
            createdAt: _daysBefore(_ref, d),
            duration: const Duration(minutes: 30),
          ),
      ];
      expect(erholung.length, greaterThanOrEqualTo(8));
      expect(DataSufficiency.hasAcwr(erholung, _ref), isFalse);
    });
  });

  group('Median statt Durchschnitt', () {
    test('ein einzelner Ausreißer verschiebt ihn nicht', () {
      final dates = [0, 2, 4, 6, 8, 82];
      final s = [
        for (final d in dates)
          StrengthSession(
            id: '$d',
            userId: 'u',
            date: _daysBefore(_ref, d),
            createdAt: _daysBefore(_ref, d),
            bodyweight: false,
          ),
      ];

      // Abstände: 74, 2, 2, 2, 2 → Median 2, Durchschnitt 16,4.
      expect(DataSufficiency.medianGapDays(s), 2);
      expect(DataSufficiency.longestGapDays(s), 74);
    });

    test('ohne zwei Tage gibt es keinen Abstand', () {
      expect(DataSufficiency.medianGapDays(const []), isNull);
      expect(DataSufficiency.longestGapDays(const []), isNull);
    });

    test('zwei Einheiten am selben Tag sind ein Tag', () {
      final day = _daysBefore(_ref, 3);
      final s = [
        for (var i = 0; i < 2; i++)
          StrengthSession(
            id: 'a$i',
            userId: 'u',
            date: day.add(Duration(hours: i * 6)),
            createdAt: day,
            bodyweight: false,
          ),
        StrengthSession(
          id: 'b',
          userId: 'u',
          date: _ref,
          createdAt: _ref,
          bodyweight: false,
        ),
      ];
      expect(DataSufficiency.medianGapDays(s), 3);
    });
  });

  test('Tage seit der letzten Einheit', () {
    final s = _history(spanDays: 30, every: 10);
    expect(DataSufficiency.daysSinceLast(s, _ref), 0);
    expect(DataSufficiency.daysSinceLast(s, _ref.add(const Duration(days: 50))),
        50);
    expect(DataSufficiency.daysSinceLast(const [], _ref), isNull);
  });
}
