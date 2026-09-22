import 'package:atem/features/pulse/domain/heart_rate_zones.dart';
import 'package:atem/features/pulse/domain/zone_intensity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die gemessene Anstrengung aus der Zonenverteilung (A1, Schritt 1).
///
/// Sie geht hier noch nirgends in eine Last ein — das ist Schritt 2. Geprüft
/// wird die Rechnung für sich: der Schnitt, die Rundung und vor allem die
/// Fälle, in denen sie **schweigt**.
void main() {
  /// Eine Verteilung mit [seconds] je Zone (Index 0 ist Zone 1).
  ZoneDistribution dist(List<int> seconds, {int? window}) {
    final recorded = seconds.fold<int>(0, (a, b) => a + b);
    return ZoneDistribution(
      secondsPerZone: List.unmodifiable(seconds),
      recordedSeconds: recorded,
      windowSeconds: window ?? recorded,
    );
  }

  group('der Schnitt', () {
    test('eine ganze Einheit in Zone 3 ergibt Anstrengung 3', () {
      final i = ZoneIntensity.of(dist([0, 0, 2400, 0, 0]))!;
      expect(i.effort, 3);
      expect(i.meanZone, 3.0);
    });

    test('halb Zone 2, halb Zone 4 ergibt ebenfalls 3', () {
      final i = ZoneIntensity.of(dist([0, 1200, 0, 1200, 0]))!;
      expect(i.effort, 3);
      expect(i.meanZone, 3.0);
    });

    test('ein ruhiger Lauf fällt unter die Ersatzzahl 3', () {
      // Genau der Fall, für den es das gibt: Ohne Puls rechnete diese
      // Einheit mit 3 und damit dem neutralen Faktor 1,0.
      final i = ZoneIntensity.of(dist([1800, 1200, 0, 0, 0]))!;
      expect(i.effort, 1);
      expect(i.meanZone, closeTo(1.4, 0.001));
    });

    test('ein Intervall darüber', () {
      final i = ZoneIntensity.of(dist([0, 300, 600, 900, 1200]))!;
      expect(i.meanZone, closeTo(4.0, 0.001));
      expect(i.effort, 4);
    });

    test('der Schnitt wird gerundet, nicht abgeschnitten', () {
      // Schnitt 3,5 — kaufmännisch auf 4.
      expect(ZoneIntensity.of(dist([0, 0, 600, 600, 0]))!.meanZone,
          closeTo(3.5, 0.001));
      expect(ZoneIntensity.of(dist([0, 0, 600, 600, 0]))!.effort, 4);
    });

    test('nie ausserhalb von 1 bis 5', () {
      expect(ZoneIntensity.of(dist([600, 0, 0, 0, 0]))!.effort, 1);
      expect(ZoneIntensity.of(dist([0, 0, 0, 0, 600]))!.effort,
          HeartRateZones.zoneCount);
    });
  });

  group('wann sie schweigt', () {
    test('ohne Aufzeichnung gibt es keine Anstrengung', () {
      expect(ZoneIntensity.of(dist([0, 0, 0, 0, 0], window: 2400)), isNull);
    });

    test('unter der halben Einheit sagt die Messung nichts', () {
      // Zehn von sechzig Minuten: Die übrigen fünfzig können alles gewesen
      // sein. Lieber der alte Ersatzwert als eine Vermutung im Gewand einer
      // Messung.
      expect(ZoneIntensity.of(dist([0, 0, 600, 0, 0], window: 3600)), isNull);
    });

    test('genau auf der Schwelle zählt sie', () {
      final i = ZoneIntensity.of(dist([0, 0, 1800, 0, 0], window: 3600));
      expect(i, isNotNull);
      expect(i!.effort, 3);
    });

    test('ohne bekannte Länge zählt die Aufzeichnung für sich', () {
      // `windowSeconds == 0` heisst „Länge unbekannt", nicht „Länge null".
      // Eine Schwelle gegen 0 wäre sonst immer verletzt.
      final i = ZoneIntensity.of(dist([0, 0, 600, 0, 0], window: 0));
      expect(i, isNotNull);
      expect(i!.effort, 3);
      expect(i.windowSeconds, 0);
    });
  });

  group('die Grundlage', () {
    test('trägt Zähler und Nenner der Aufzeichnung', () {
      final i = ZoneIntensity.of(dist([0, 0, 2100, 0, 0], window: 3120))!;
      expect(i.recordedSeconds, 2100); // 35 min
      expect(i.windowSeconds, 3120); // von 52 min
    });

    test('das Beispiel „21 von 52 min" liegt unter der Schwelle', () {
      // Der Satz steht so im Kopf von `PulseProfile` und im Zone-5-Block —
      // als Beispiel für eine **teilweise** Aufzeichnung. 21 von 52 sind
      // 40 %, also unter [ZoneIntensity.coverageFloor]. Für die Anzeige
      // bleibt das eine gültige Grundlage; für die Last schweigt sie.
      //
      // Dieser Test steht hier, weil die Schwelle damit den häufig zitierten
      // Fall ausschliesst. Fällt sie irgendwann tiefer, schlägt er fehl und
      // zwingt zu einer Entscheidung statt zu einem stillen Wandel.
      expect(ZoneIntensity.of(dist([0, 0, 1260, 0, 0], window: 3120)), isNull);
    });
  });
}
