import '../../history/domain/training_session.dart';
import '../../pulse/domain/heart_rate_zones.dart';
import 'pace_series.dart';

/// Welche Stufe der Kaskade urteilt.
enum IntensityLevel {
  /// Ø Herzfrequenz, eingeordnet in die **festgelegten** Zonen.
  heartRate,

  /// Die eigene Angabe, 1 bis 5.
  rpe,

  /// Tempo gegen den eigenen Schnitt derselben Aktivität.
  pace,
}

/// Die Intensitätskaskade — Board 11, B4.
///
/// **Genau eine Stufe urteilt**, die anderen stehen als Zahl ohne Bewertung
/// darunter. Die Regel, in dieser Reihenfolge (Karte C):
///
/// 1. Stufe 1 führt, wenn Ø Puls **und** Maximalpuls beide vorliegen.
/// 2. Sonst Stufe 2, wenn RPE erfasst ist.
/// 3. Sonst Stufe 3, wenn mindestens 3 Einheiten derselben Aktivität existieren.
/// 4. Sonst kein Intensitätskasten.
///
/// ## Keine Altersformel
///
/// Der Maximalpuls kommt aus der Einheit oder aus dem Profil — nie aus „220
/// minus Alter". Das wäre eine erfundene Grundlage für den wichtigsten Wert
/// des Kastens (Sektion K, Punkt 3).
///
/// ## Ein Zonensystem, nicht zwei (seit 22.09.2026)
///
/// Stufe 1 rechnete bis dahin `Ø / Max` in Prozent und ordnete das Ergebnis
/// einer eigenen Tabelle zu (`[0, 70, 80, 87, 93]`). Das war ein **zweites**
/// Zonensystem neben den fünf Grenzen, die der Nutzer in den Einstellungen
/// selbst setzt — zwei Antworten auf dieselbe Frage, je nachdem, welcher
/// Bildschirm gerade fragt.
///
/// Es widersprach ausserdem Board 16, Entscheidung 13: „Ohne Grenzen keine
/// Verteilung. ATEM rechnet keine, solange sie fehlen, und schlägt auch keine
/// still vor." Eine Prozenttabelle **ist** ein stiller Vorschlag.
///
/// Stufe 1 fragt jetzt [HeartRateZones.zoneOf] mit dem Ø-Puls. Fehlen die
/// Grenzen, fällt die Kaskade auf Stufe 2 — wie sie es ohne Maximalpuls schon
/// immer tat. Der Prozentwert entfällt ersatzlos: Er war ein Anteil am
/// Maximum **dieser** Einheit, nicht an HFmax, und damit ohnehin schwer zu
/// lesen.
class CardioIntensity {
  const CardioIntensity({
    required this.level,
    required this.avgHr,
    required this.maxHr,
    required this.rpe,
    required this.tempoValue,
    required this.usesSpeed,
    required this.basisCount,
    this.zone,
    this.aboveAverage,
  });

  final IntensityLevel level;

  /// Die drei Rohwerte — auch die, die nicht urteilen. „—" bleibt sichtbar,
  /// damit erkennbar ist, dass es eine feinere Stufe gibt und woran sie hängt.
  final int? avgHr;
  final int? maxHr;
  final int? rpe;
  final double? tempoValue;
  final bool usesSpeed;

  /// Wie viele Einheiten derselben Aktivität den Schnitt bilden.
  final int basisCount;

  /// Stufe 1: Zone 1 bis 5 — die **festgelegten** Zonen, dieselben wie im
  /// Pulsblock und in „Zone 5 je Woche".
  final int? zone;

  /// Stufe 3: über dem eigenen Schnitt? `null` bei Gleichstand.
  final bool? aboveAverage;

  /// `null` heisst: kein Intensitätskasten.
  static CardioIntensity? of(
    CardioSession session,
    List<TrainingSession> sessions, {
    HeartRateZones? zones,
  }) {
    final series = PaceSeries.forActivity(sessions, session.activity);
    final maxHr = session.maxHr;
    final avgHr = session.avgHr;
    final tempo = session.tempo;

    final base = (
      avgHr: avgHr,
      maxHr: maxHr,
      rpe: session.rpe,
      tempoValue: tempo?.value,
      usesSpeed: tempo?.usesSpeed ?? (session.activity?.usesSpeed ?? false),
      basisCount: series.count,
    );

    // Regel 1: Ø-Puls und festgelegte Zonen. Der Maximalpuls der Einheit
    // wird nicht mehr gebraucht — er steht weiter als Rohwert darunter.
    if (avgHr != null && avgHr > 0 && zones != null) {
      return CardioIntensity(
        level: IntensityLevel.heartRate,
        avgHr: base.avgHr,
        maxHr: base.maxHr,
        rpe: base.rpe,
        tempoValue: base.tempoValue,
        usesSpeed: base.usesSpeed,
        basisCount: base.basisCount,
        zone: zones.zoneOf(avgHr),
      );
    }

    // Regel 2.
    if (session.rpe != null) {
      return CardioIntensity(
        level: IntensityLevel.rpe,
        avgHr: base.avgHr,
        maxHr: base.maxHr,
        rpe: base.rpe,
        tempoValue: base.tempoValue,
        usesSpeed: base.usesSpeed,
        basisCount: base.basisCount,
      );
    }

    // Regel 3: drei Einheiten derselben Aktivität, und diese hat ein Tempo.
    if (tempo != null && series.count >= PaceSeries.intensityMinimum) {
      return CardioIntensity(
        level: IntensityLevel.pace,
        avgHr: base.avgHr,
        maxHr: base.maxHr,
        rpe: base.rpe,
        tempoValue: base.tempoValue,
        usesSpeed: base.usesSpeed,
        basisCount: base.basisCount,
        aboveAverage: series.aboveMedian(tempo.value),
      );
    }

    // Regel 4.
    return null;
  }
}
