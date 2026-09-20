import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:atem/features/weight/domain/weight_series.dart';
import 'package:atem/features/weight/domain/weight_sync.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Abgleich mit Health Connect (Produktstrategie 8.2).
///
/// Die vier Regeln aus `WeightSync`: keine Schleife, ein Tag ein Wert, eine
/// Messung überschreibt keine Eingabe, und nur Getipptes geht zurück.

const _own = 'com.atemhybrid.app';
const _watch = 'com.garmin.android.apps.connectmobile';

final _today = DateTime(2026, 9, 20);

DateTime _daysAgo(int days) =>
    DateTime(_today.year, _today.month, _today.day - days);

WeightEntry _entry(int daysAgo, double kg,
        {WeightSource source = WeightSource.manual, String? externalId}) =>
    WeightEntry(
      date: _daysAgo(daysAgo),
      kg: kg,
      source: source,
      externalId: externalId,
    );

MeasuredWeight _measured(
  int daysAgo,
  double kg, {
  String id = 'r1',
  String source = _watch,
  int hour = 7,
}) =>
    MeasuredWeight(
      id: id,
      measuredAt: _daysAgo(daysAgo).add(Duration(hours: hour)),
      kg: kg,
      sourceId: source,
    );

WeightSyncPlan _plan(
  List<WeightEntry> entries,
  List<MeasuredWeight> measured,
) =>
    WeightSync.plan(
      series: WeightSeries.of(entries),
      measured: measured,
      ownSourceId: _own,
      reference: _today,
    );

void main() {
  group('Keine Schleife', () {
    test('was ATEM selbst geschrieben hat, kommt nicht zurück', () {
      final plan = _plan(
        [_entry(2, 78.9)],
        [_measured(2, 78.9, source: _own, id: 'eigen')],
      );

      expect(plan.toSave, isEmpty,
          reason: 'sonst würde die eigene Eingabe zur Messung');
      expect(plan.toPublish, isEmpty,
          reason: 'der Tag steht schon in der Quelle');
    });

    test('ein eigener Datensatz mit anderem Wert wird erneut geschrieben', () {
      // Jemand hat den Eintrag in ATEM geändert; die Quelle hat den alten.
      final plan = _plan(
        [_entry(2, 78.5)],
        [_measured(2, 78.9, source: _own, id: 'eigen')],
      );

      expect(plan.toSave, isEmpty);
      expect(plan.toPublish.single.kg, 78.5);
    });
  });

  group('Ein Tag, ein Wert', () {
    test('bei zwei Messungen am selben Tag gilt die spätere', () {
      final plan = _plan([], [
        _measured(1, 79.4, id: 'morgens', hour: 7),
        _measured(1, 80.1, id: 'abends', hour: 21),
      ]);

      expect(plan.toSave.single.kg, 80.1);
      expect(plan.toSave.single.externalId, 'abends');
    });

    test('übernommene Werte tragen Herkunft und Kennung', () {
      final plan = _plan([], [_measured(3, 79.2, id: 'hc-7')]);
      final entry = plan.toSave.single;

      expect(entry.source, WeightSource.healthConnect);
      expect(entry.externalId, 'hc-7');
      expect(entry.date, _daysAgo(3));
    });
  });

  group('Eine Messung überschreibt keine Eingabe', () {
    test('ein getippter Tag bleibt, wie er ist', () {
      final plan = _plan(
        [_entry(4, 78.0)],
        [_measured(4, 81.3, id: 'hc-1')],
      );

      expect(plan.toSave, isEmpty,
          reason: 'die Eingabe ist eine Aussage, kein Vorschlag');
      // Und sie geht weiter an die Quelle: Der Widerspruch bleibt sichtbar,
      // statt still auf eine Seite aufgelöst zu werden.
      expect(plan.toPublish.single.kg, 78.0);
    });

    test('ein gemessener Tag wird von seiner Quelle aktualisiert', () {
      final plan = _plan(
        [
          _entry(4, 79.0,
              source: WeightSource.healthConnect, externalId: 'hc-1')
        ],
        [_measured(4, 79.4, id: 'hc-1')],
      );

      expect(plan.toSave.single.kg, 79.4);
    });

    test('ein unveränderter Messwert löst keinen Schreibvorgang aus', () {
      final plan = _plan(
        [
          _entry(4, 79.4,
              source: WeightSource.healthConnect, externalId: 'hc-1')
        ],
        [_measured(4, 79.4, id: 'hc-1')],
      );

      expect(plan.isEmpty, isTrue);
    });
  });

  group('Nur Getipptes geht zurück', () {
    test('gemessene Einträge werden nicht zurückgeschrieben', () {
      final plan = _plan(
        [
          _entry(5, 79.1,
              source: WeightSource.healthConnect, externalId: 'hc-2')
        ],
        const [],
      );

      expect(plan.toPublish, isEmpty, reason: 'sonst stünde der Wert zweimal');
    });

    test('ein getippter Tag ohne Gegenstück wird angeboten', () {
      final plan = _plan([_entry(1, 78.8)], const []);
      expect(plan.toPublish.single.kg, 78.8);
    });

    test('was gerade hereinkommt, geht im selben Lauf nicht hinaus', () {
      // Der Tag trägt bisher nichts; die Messung wird übernommen. Sie
      // anschliessend zurückzuschreiben wäre ein Ringtausch.
      final plan = _plan([], [_measured(2, 79.6, id: 'hc-3')]);

      expect(plan.toSave, hasLength(1));
      expect(plan.toPublish, isEmpty);
    });
  });

  group('Das Fenster', () {
    test('beginnt dreissig Tage vor dem Stichtag', () {
      expect(WeightSync.windowStart(_today), DateTime(2026, 8, 22));
    });

    test('lässt nichts Älteres durch — weder hinein noch hinaus', () {
      final plan = _plan(
        [_entry(90, 82.0)],
        [_measured(90, 82.5, id: 'alt')],
      );

      expect(plan.isEmpty, isTrue,
          reason: 'ohne READ_HEALTH_DATA_HISTORY gibt es dort ohnehin nichts');
    });
  });
}
