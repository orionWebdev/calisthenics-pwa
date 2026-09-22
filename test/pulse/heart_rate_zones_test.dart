import 'package:atem/core/domain/pulse_profile.dart';
import 'package:atem/features/pulse/domain/heart_rate_zones.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Zonenrechnung aus Board 16 — reine Rechnung, ohne Gerät.
void main() {
  final zones = HeartRateZones.tryFrom(const [112, 131, 149, 168])!;

  group('Grenzen', () {
    test('jeder Wert liegt in genau einer Zone', () {
      // Die Grenze ist der **erste** Wert der oberen Zone.
      expect(zones.zoneOf(60), 1);
      expect(zones.zoneOf(111), 1);
      expect(zones.zoneOf(112), 2);
      expect(zones.zoneOf(130), 2);
      expect(zones.zoneOf(131), 3);
      expect(zones.zoneOf(148), 3);
      expect(zones.zoneOf(149), 4);
      expect(zones.zoneOf(167), 4);
      expect(zones.zoneOf(168), 5);
      expect(zones.zoneOf(220), 5);
    });

    test('Bereiche lassen sich ablesen', () {
      expect(zones.lowerOf(1), isNull, reason: 'Zone 1 ist nach unten offen');
      expect(zones.upperOf(1), 111);
      expect(zones.lowerOf(2), 112);
      expect(zones.upperOf(2), 130);
      expect(zones.lowerOf(5), 168);
      expect(zones.upperOf(5), isNull, reason: 'Zone 5 ist nach oben offen');
    });

    test('eine ungültige Folge gibt es nicht', () {
      // Die Konstruktion schliesst Lücken und Überlappungen aus.
      expect(HeartRateZones.tryFrom(const [112, 112, 149, 168]), isNull);
      expect(HeartRateZones.tryFrom(const [112, 131, 130, 168]), isNull);
      expect(HeartRateZones.tryFrom(const [112, 131, 149]), isNull);
      expect(HeartRateZones.tryFrom(const [10, 131, 149, 168]), isNull);
    });

    test('eine Grenze bleibt einen bpm unter der nächsten', () {
      // Der Stepper aus D3: „Höchstens 148 bpm — Grenze 3 liegt auf 149".
      expect(zones.maxFor(1), 148);
      expect(zones.minFor(1), 113);

      final moved = zones.withBoundary(1, 140);
      expect(moved.bounds, [112, 140, 149, 168]);

      // Darüber tut es nichts — der Grund stand vorher da.
      expect(zones.withBoundary(1, 149), zones);
      expect(zones.withBoundary(1, 112), zones);
    });
  });

  group('Vorschlag aus HFmax', () {
    test('60/70/80/90 Prozent, aufgerundet', () {
      // Das Beispiel des Boards: HFmax 186 → 112, 131, 149, 168.
      expect(HeartRateZones.proposalFor(186)!.bounds, [112, 131, 149, 168]);
    });

    test('aufgerundet, weil die Grenze der erste Wert der oberen Zone ist', () {
      // 60 % von 186 sind 111,6. Wer 111 schlägt, gehört noch in Zone 1.
      expect(HeartRateZones.proposalFor(186)!.zoneOf(111), 1);
      expect(HeartRateZones.proposalFor(186)!.zoneOf(112), 2);
    });

    test('ohne plausiblen HFmax kein Vorschlag', () {
      expect(HeartRateZones.proposalFor(50), isNull);
      expect(HeartRateZones.proposalFor(400), isNull);
    });
  });

  group('Pulsverlauf', () {
    final start = DateTime(2026, 9, 18, 18);
    final end = start.add(const Duration(minutes: 10));

    PulseSample at(int minute, int second, int bpm) => PulseSample(
          at: start.add(Duration(minutes: minute, seconds: second)),
          bpm: bpm,
        );

    test('jeder Wert gilt bis zum nächsten', () {
      final profile = PulseProfile.fromSamples(
        [at(0, 0, 100), at(0, 30, 120), at(1, 0, 140)],
        start: start,
        end: start.add(const Duration(minutes: 1, seconds: 30)),
      );

      expect(profile.secondsByBpm, {100: 30, 120: 30, 140: 30});
      expect(profile.recordedSeconds, 90);
    });

    test('die Zeitachse: bpm je Zehn-Sekunden-Schlitz, zeitgewichtet', () {
      // Seit dem 22.09.2026 (Board 16, Nachtrag, P) sind die Schlüssel
      // Schlitze zu zehn Sekunden, nicht Minuten: Ein Intervall von 40/20
      // verschwand vorher im Minutenmittel.
      final profile = PulseProfile.fromSamples(
        [at(0, 0, 100), at(0, 30, 120), at(1, 0, 140)],
        start: start,
        end: start.add(const Duration(minutes: 1, seconds: 30)),
      );

      expect(profile.slotSeconds, PulseProfile.fineSlotSeconds);
      // 0:00 bei 100 gilt bis 0:30, danach 120 bis 1:00, dann 140.
      expect(profile.curve, {0: 100, 3: 120, 6: 140});
    });

    test('die Auflösung beschreibt, was dasteht — nicht das Raster', () {
      // Eine Uhr, die nur jede Minute misst, füllt auch im feinen Raster nur
      // jeden sechsten Schlitz. „Je 10 Sekunden ein Wert" wäre dann gelogen.
      final coarse = PulseProfile.fromSamples(
        [at(0, 0, 120), at(1, 0, 130), at(2, 0, 125)],
        start: start,
        end: start.add(const Duration(minutes: 3)),
      );
      expect(coarse.curveStepSeconds, 60);

      final fine = PulseProfile.fromSamples(
        [at(0, 0, 120), at(0, 10, 150), at(0, 20, 170), at(0, 30, 160)],
        start: start,
        end: start.add(const Duration(minutes: 1)),
      );
      expect(fine.curveStepSeconds, PulseProfile.fineSlotSeconds);
    });

    test('ein Schlitz ohne Messung bleibt eine Lücke, nie interpoliert', () {
      final profile = PulseProfile.fromSamples(
        [at(0, 0, 120), at(5, 0, 130)],
        start: start,
        end: end,
      );

      // Der erste Wert gilt höchstens eine Minute (`maxGapSeconds`), also
      // die Schlitze 0 bis 5; dann kommt lange nichts, bis 5:00 = Schlitz 30.
      expect(profile.curve[0], 120);
      expect(profile.curve[30], 130);
      expect(profile.curve.containsKey(12), isFalse);
    });

    test('eine Lücke über eine Minute zählt nicht zur Aufzeichnung', () {
      // Die Uhr hat fünf Minuten nichts gemessen. Der Wert davor gilt eine
      // Minute lang — mehr behauptet niemand.
      final profile = PulseProfile.fromSamples(
        [at(0, 0, 120), at(5, 0, 130)],
        start: start,
        end: end,
      );

      expect(profile.secondsByBpm[120], 60);
      expect(profile.recordedSeconds, lessThan(profile.windowSeconds));
      expect(profile.isComplete, isFalse);
    });

    test('Werte ausserhalb der Einheit zählen nicht', () {
      final profile = PulseProfile.fromSamples(
        [
          PulseSample(at: start.subtract(const Duration(minutes: 3)), bpm: 90),
          at(0, 0, 130),
          PulseSample(at: end.add(const Duration(minutes: 3)), bpm: 95),
        ],
        start: start,
        end: end,
      );

      expect(profile.secondsByBpm.keys, [130]);
    });

    test('Durchschnitt, Maximum und Minimum kommen aus derselben Quelle', () {
      // „Keine Grösse hat zwei Quellen": Ø, max und min werden aus dem
      // Histogramm gerechnet, nicht getrennt mitgeführt.
      final profile = PulseProfile.fromSamples(
        [at(0, 0, 100), at(0, 30, 140), at(1, 0, 180)],
        start: start,
        end: start.add(const Duration(minutes: 1, seconds: 30)),
      );

      expect(profile.average, 140);
      expect(profile.max, 180);
      expect(profile.min, 100);
    });

    test('ohne Messwerte kein Profil, keine Null', () {
      final profile =
          PulseProfile.fromSamples(const [], start: start, end: end);
      expect(profile.isEmpty, isTrue);
      expect(profile.average, isNull);
      expect(profile.max, isNull);
      expect(profile.min, isNull);
    });

    test('überlebt die Reise durch Firestore', () {
      final profile = PulseProfile.fromSamples(
        [at(0, 0, 100), at(0, 30, 140)],
        start: start,
        end: start.add(const Duration(minutes: 1)),
      );
      final back = PulseProfile.fromWire(
        profile.toWire(),
        profile.windowSeconds,
        profile.curveToWire(),
      )!;

      expect(back.secondsByBpm, profile.secondsByBpm);
      expect(back.windowSeconds, profile.windowSeconds);
      expect(back.curve, profile.curve);
    });

    test(
        'ohne Kurvenfeld bleibt die Zeitachse leer — Einheiten vor dem '
        '22.09.2026', () {
      final profile = PulseProfile.fromSamples(
        [at(0, 0, 100), at(0, 30, 140)],
        start: start,
        end: start.add(const Duration(minutes: 1)),
      );
      final back =
          PulseProfile.fromWire(profile.toWire(), profile.windowSeconds)!;

      expect(back.curve, isEmpty);
    });

    test('ein unlesbares Dokument ist kein Profil', () {
      expect(PulseProfile.fromWire(null, 60), isNull);
      expect(PulseProfile.fromWire({'x': 5, '0': 3, '120': -1}, 60), isNull);
    });
  });

  group('Verteilung', () {
    test('das Beispiel des Boards: 52 von 52 Minuten', () {
      // Z1 6:10 · Z2 11:40 · Z3 21:30 · Z4 9:20 · Z5 3:20
      final distribution = ZoneDistribution.of(
        secondsByBpm: {
          100: 6 * 60 + 10,
          120: 11 * 60 + 40,
          140: 21 * 60 + 30,
          160: 9 * 60 + 20,
          175: 3 * 60 + 20,
        },
        windowSeconds: 52 * 60,
        zones: zones,
      );

      expect(distribution.secondsPerZone, [370, 700, 1290, 560, 200]);
      expect(distribution.recordedSeconds, 3120);
      expect(distribution.isPartial, isFalse);
    });

    test('Balken sind Anteile der aufgezeichneten Zeit und ergeben eins', () {
      final distribution = ZoneDistribution.of(
        secondsByBpm: {100: 370, 120: 700, 140: 1290, 160: 560, 175: 200},
        windowSeconds: 3120,
        zones: zones,
      );

      final total = [
        for (var z = 1; z <= 5; z++) distribution.shareOfRecorded(z),
      ].reduce((a, b) => a + b);
      expect(total, closeTo(1.0, 1e-9));
      // Die Werte des Boards: 12, 22, 41, 18, 7 Prozent.
      expect(distribution.shareOfRecorded(3), closeTo(0.41, 0.01));
    });

    test('unvollständige Aufzeichnung ist erkennbar', () {
      // C1: 21 von 52 Minuten. Die Balken werden gezeichnet, aber der Satz
      // steht vor ihnen.
      final distribution = ZoneDistribution.of(
        secondsByBpm: {120: 8 * 60 + 10, 140: 10 * 60 + 40, 160: 2 * 60 + 10},
        windowSeconds: 52 * 60,
        zones: zones,
      );

      expect(distribution.isPartial, isTrue);
      expect(distribution.recordedSeconds, 21 * 60);
      // Zonen ohne Zeit bleiben in der Verteilung — 0:00 ist eine Aussage.
      expect(distribution.secondsPerZone.first, 0);
      expect(distribution.secondsPerZone.last, 0);
    });

    test('neue Grenzen rechnen dieselben Sekunden neu', () {
      // Entscheidung 15: Zonen werden nie beim Import festgeschrieben. Wer
      // seine Grenzen ändert, ändert jede Verteilung — auch vergangene.
      final histogram = {100: 600, 130: 600, 160: 600};
      final before = ZoneDistribution.of(
          secondsByBpm: histogram, windowSeconds: 1800, zones: zones);
      final after = ZoneDistribution.of(
        secondsByBpm: histogram,
        windowSeconds: 1800,
        zones: HeartRateZones.tryFrom(const [90, 110, 140, 170])!,
      );

      expect(before.secondsPerZone, [600, 600, 0, 600, 0]);
      expect(after.secondsPerZone, [0, 600, 600, 600, 0]);
      expect(after.recordedSeconds, before.recordedSeconds,
          reason: 'die Aufzeichnung bleibt, nur die Einteilung wandert');
    });
  });
}
