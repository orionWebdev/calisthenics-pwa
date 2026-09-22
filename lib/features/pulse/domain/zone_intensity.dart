import 'heart_rate_zones.dart';

/// **Die gemessene Anstrengung einer Einheit** — aus der Zonenverteilung.
///
/// ## Wozu es das gibt
///
/// Die Trainingslast rechnet mit einer Anstrengung von 1 bis 5. Fehlt sie,
/// setzt `TrainingLoad` den Ersatzwert 3 ein — den neutralen Faktor 1,0. Für
/// eine Einheit, die jemand selbst einträgt und dabei die Anstrengung
/// weglässt, ist das die ehrlichste Antwort: Die App weiss es nicht.
///
/// Für eine Einheit **von der Uhr** ist es das nicht. Dort liegt ein
/// gemessener Pulsverlauf daneben, und die 3 ist dann kein Nichtwissen mehr,
/// sondern ein ungenutzter Messwert. Dieses Stück rechnet ihn aus — und
/// **nur** das. Ob und wo er eingesetzt wird, entscheidet der Aufrufer.
///
/// ## Warum der Zonenschnitt und nichts Klügeres
///
/// Die Anstrengung ist der zeitgewichtete Mittelwert der Zonennummer,
/// gerundet. Zone 3 über die ganze Einheit ergibt 3; die Hälfte in Zone 2,
/// die Hälfte in Zone 4 ergibt ebenfalls 3.
///
/// Das ist die **kleinstmögliche Behauptung**. Jede andere Abbildung — eine
/// exponentielle Gewichtung, ein TRIMP-Faktor, „Zone 5 zählt dreifach" —
/// setzt voraus, dass die App weiss, wie viel härter eine hohe Zone ist. Sie
/// weiss es nicht, und `ZoneDistribution` hält ausdrücklich fest, dass mehr
/// Zeit in einer hohen Zone nicht „besser" ist. Die Zonennummer als ihr
/// eigenes Gewicht zu nehmen, fügt nichts hinzu, was nicht schon in den
/// Grenzen steckt, die der Nutzer selbst gesetzt hat.
///
/// Das ist **keine Bewertung der Einheit**. Es ist dieselbe Art Aussage, die
/// eine getippte Anstrengung trägt — nur gemessen statt erinnert.
///
/// ## Wann sie schweigt
///
/// Unter [coverageFloor] der Einheit sagt die Messung nichts. Hat die Uhr nur
/// zehn von sechzig Minuten aufgezeichnet, können die übrigen fünfzig alles
/// gewesen sein; eine Zahl daraus wäre eine Vermutung im Gewand einer
/// Messung. Dann gibt es [ZoneIntensity.of] `null` zurück, und der Aufrufer
/// bleibt bei dem, was er ohne Puls getan hätte.
///
/// Verworfen: ein Ergebnis mit einem Merkmal „dünn" statt `null`. Es liefe
/// darauf hinaus, dass jeder Aufrufer dieselbe Schwelle erneut prüft — und
/// einer sie vergisst.
class ZoneIntensity {
  const ZoneIntensity._({
    required this.effort,
    required this.meanZone,
    required this.recordedSeconds,
    required this.windowSeconds,
  });

  /// Wie viel der Einheit der Puls beschreiben muss, damit er zählt.
  ///
  /// Die Hälfte. Keine gefundene Wahrheit, sondern die Grenze, ab der die
  /// aufgezeichnete Zeit die Einheit eher beschreibt als verfehlt. Sie steht
  /// hier als Konstante, damit eine Änderung eine Stelle hat und im
  /// Entscheidungsprotokoll auftaucht.
  ///
  /// **Sie ist bewusst streng.** Das Beispiel, das `PulseProfile` und der
  /// Zone-5-Block zitieren — „aus 21 von 52 min Aufzeichnung" — sind 40 % und
  /// fallen damit heraus. Für die **Anzeige** bleibt eine solche Aufzeichnung
  /// eine gültige Grundlage mit sichtbarem Nenner; für die **Last** schweigt
  /// sie, und es bleibt beim Ersatzwert von heute. Im Zweifel ändert sich
  /// nichts — das ist die richtige Richtung für eine Zahl, die rückwirkend
  /// jede Einheit betrifft. `test/pulse/zone_intensity_test.dart` hält den
  /// Fall fest, damit ein Absenken eine Entscheidung bleibt und kein
  /// stiller Wandel wird.
  static const coverageFloor = 0.5;

  /// `null`, wenn die Messung nichts sagt: ohne Aufzeichnung, oder unter
  /// [coverageFloor] der Einheit.
  static ZoneIntensity? of(ZoneDistribution distribution) {
    final recorded = distribution.recordedSeconds;
    if (recorded <= 0) return null;

    final window = distribution.windowSeconds;
    if (window > 0 && recorded < window * coverageFloor) return null;

    var weighted = 0;
    for (var zone = 1; zone <= HeartRateZones.zoneCount; zone++) {
      weighted += zone * distribution.secondsPerZone[zone - 1];
    }
    final mean = weighted / recorded;

    return ZoneIntensity._(
      effort: mean.round().clamp(1, HeartRateZones.zoneCount),
      meanZone: mean,
      recordedSeconds: recorded,
      windowSeconds: window,
    );
  }

  /// 1 bis 5 — dieselbe Skala wie die getippte Anstrengung.
  final int effort;

  /// Der ungerundete Schnitt. Nicht für die Rechnung, sondern für die
  /// Grundlage: „Zonenschnitt 3,4" sagt mehr als „Anstrengung 3".
  final double meanZone;

  /// Der Zähler der Grundlage — „aus 21 von 52 min Aufzeichnung".
  final int recordedSeconds;

  /// Der Nenner der Grundlage. 0, wenn die Länge der Einheit unbekannt ist;
  /// dann zählt die Aufzeichnung für sich.
  final int windowSeconds;
}
