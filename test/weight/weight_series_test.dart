import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:atem/features/weight/domain/weight_series.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Reihe — Lücken, Maßstab und Wirkungsfenster.
///
/// Jede Aussage hier stammt aus Board 14: Eine Lücke wird nicht überbrückt
/// (Entscheidung 8), ein Eintrag wirkt nur bis zum nächsten (Entscheidung 11),
/// und ein Tag trägt genau einen Wert.

WeightEntry _e(int month, int day, double kg,
        [WeightSource source = WeightSource.manual]) =>
    WeightEntry(date: DateTime(2026, month, day), kg: kg, source: source);

void main() {
  group('Ein Tag, ein Wert', () {
    test('zwei Einträge am selben Tag ergeben einen — den letzten', () {
      final series = WeightSeries.of([
        _e(9, 1, 80),
        _e(9, 1, 79.4),
      ]);

      expect(series.length, 1);
      expect(series.latest!.kg, 79.4);
    });

    test('die Kennung ist das Datum', () {
      expect(_e(9, 5, 80).documentId, '2026-09-05');
      expect(WeightEntry.idFor(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
    });

    test('unsortierte Eingaben werden sortiert', () {
      final series = WeightSeries.of([_e(9, 10, 79), _e(9, 1, 80)]);
      expect(series.first!.kg, 80);
      expect(series.latest!.kg, 79);
    });
  });

  group('Lücken sind Lücken', () {
    test('unter drei Wochen verbindet die Kurve', () {
      final series =
          WeightSeries.of([_e(9, 1, 80), _e(9, 14, 79.5), _e(9, 20, 79)]);

      expect(series.segments.length, 1);
      expect(series.gaps, isEmpty);
      expect(series.hasLine, isTrue);
      expect(series.namedGap, isNull);
    });

    test('ab drei Wochen bricht sie — und die Lücke wird benannt', () {
      final series = WeightSeries.of([
        _e(7, 1, 80.2),
        _e(7, 8, 80),
        // Sechs Wochen ohne Eintrag.
        _e(8, 19, 79.2),
        _e(8, 26, 79),
      ]);

      expect(series.segments.map((s) => s.length), [2, 2]);
      expect(series.gaps.length, 1);
      expect(series.namedGap!.weeks, 6);
    });

    test('liegt jeder Abstand über der Schwelle, bleibt die Punktwolke stumm',
        () {
      // Board 14, A3: drei Punkte über vier Monate, keine Linie — und keine
      // Bodennotiz, weil sonst die ganze Fläche beschriftet wäre.
      final series =
          WeightSeries.of([_e(5, 18, 81.5), _e(7, 14, 80.4), _e(9, 14, 79.6)]);

      expect(series.hasLine, isFalse);
      expect(series.namedGap, isNull, reason: 'zwei Lücken, keine Notiz');
      expect(series.segments.every((s) => s.length == 1), isTrue);
    });

    test('bei mehreren Lücken bleibt die Notiz stumm', () {
      final series = WeightSeries.of([
        _e(1, 1, 82),
        _e(1, 7, 81.8),
        _e(3, 1, 81),
        _e(3, 8, 80.8),
        _e(4, 5, 80),
        _e(4, 12, 79.8),
      ]);

      expect(series.gaps.length, 2);
      expect(series.namedGap, isNull,
          reason: 'eine Notiz kann nicht zwei Lücken beschreiben');
    });

    test('zwei weit auseinanderliegende Punkte benennen ihre Lücke', () {
      // Ohne Linie **und** ohne Notiz stünden hier zwei Punkte ohne Erklärung.
      final series = WeightSeries.of([_e(7, 14, 80.4), _e(9, 14, 79.6)]);

      expect(series.hasLine, isFalse);
      expect(series.namedGap!.weeks, 8);
    });
  });

  group('Der Maßstab einer Einheit', () {
    final series = WeightSeries.of([_e(3, 1, 82), _e(6, 1, 80), _e(9, 1, 78)]);

    test('gilt der zuletzt bekannte Wert', () {
      expect(series.kgOn(DateTime(2026, 7, 15)), 80);
      expect(series.kgOn(DateTime(2026, 6, 1)), 80);
      expect(series.kgOn(DateTime(2026, 5, 31)), 82);
    });

    test('vor dem ersten Eintrag der früheste — nicht null und nicht 0', () {
      // Sonst verschwände die Last der gesamten Vergangenheit in dem Moment,
      // in dem die Reihe eingeführt wird.
      expect(series.kgOn(DateTime(2025, 12, 1)), 82);
    });

    test('ohne Einträge gibt es keinen Maßstab', () {
      expect(WeightSeries.empty.kgOn(DateTime(2026, 1, 1)), isNull);
    });
  });

  group('Die Veränderung ist eine Tatsache', () {
    test('vergleicht mit dem vorherigen Eintrag, nicht mit dem Fensteranfang',
        () {
      final series =
          WeightSeries.of([_e(6, 1, 80.9), _e(9, 1, 79.3), _e(9, 15, 78.9)]);
      final change = series.change!;

      expect(change.from.documentId, '2026-09-01');
      expect(change.isUp, isFalse);
      expect(change.magnitudeKg, closeTo(0.4, 0.001));
      expect(change.days, 14);
    });

    test('aus einem Wert folgt keine Veränderung', () {
      expect(WeightSeries.of([_e(9, 1, 80)]).change, isNull);
    });
  });

  group('Ein Eintrag wirkt bis zum nächsten', () {
    final today = DateTime(2026, 9, 20);
    final series = WeightSeries.of([_e(7, 21, 80.2), _e(7, 28, 80), _e(9, 1, 79)]);

    test('das Fenster endet am Tag vor dem nächsten Eintrag', () {
      final (from, to) = series.effectFor(series.entries.first, today);
      expect(from, DateTime(2026, 7, 21));
      expect(to, DateTime(2026, 7, 27));
    });

    test('der jüngste Eintrag wirkt bis heute', () {
      final (from, to) = series.effectFor(series.latest!, today);
      expect(from, DateTime(2026, 9, 1));
      expect(to, today);
    });
  });

  group('Fenster', () {
    test('beschneidet auf den Zeitraum', () {
      final series =
          WeightSeries.of([_e(1, 1, 82), _e(8, 1, 80), _e(9, 15, 79)]);
      final reference = DateTime(2026, 9, 20);

      expect(series.within(WeightRange.threeMonths, reference).length, 2);
      expect(series.within(WeightRange.year, reference).length, 3);
      expect(series.within(WeightRange.all, reference).length, 3);
    });
  });

  group('Herkunft', () {
    test('nur Health Connect wird hohl gezeichnet', () {
      expect(WeightSource.healthConnect.isMeasured, isTrue);
      expect(WeightSource.manual.isMeasured, isFalse);
      expect(WeightSource.settings.isMeasured, isFalse);
    });

    test('eine unbekannte Quelle verwirft den Wert nicht', () {
      expect(WeightSource.fromWire('garmin'), WeightSource.manual);
      expect(WeightSource.fromWire(null), WeightSource.manual);
      expect(
          WeightSource.fromWire('healthConnect'), WeightSource.healthConnect);
    });
  });
}
