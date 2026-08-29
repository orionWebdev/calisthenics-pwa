import '../../history/domain/training_session.dart';
import 'pace_series.dart';

/// Welche Stufe der Kaskade urteilt.
enum IntensityLevel {
  /// Ø Herzfrequenz in Prozent vom Maximalpuls.
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
/// des Kastens (Sektion K, Punkt 3). Ohne Maximalpuls fällt die Kaskade auf
/// Stufe 2.
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
    this.percentOfMax,
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

  /// Stufe 1: Zone 1 bis 5.
  final int? zone;
  final int? percentOfMax;

  /// Stufe 3: über dem eigenen Schnitt? `null` bei Gleichstand.
  final bool? aboveAverage;

  /// Zonengrenzen in Prozent vom Maximalpuls — untere Kante je Zone.
  ///
  /// Zone 3 beginnt bei 80 %: Das Board nennt 82 % als „Zone 3 · schwellig".
  static const zoneFloors = <int>[0, 70, 80, 87, 93];

  static int zoneFor(int percent) {
    var zone = 1;
    for (var i = 1; i < zoneFloors.length; i++) {
      if (percent >= zoneFloors[i]) zone = i + 1;
    }
    return zone;
  }

  /// `null` heisst: kein Intensitätskasten.
  static CardioIntensity? of(
    CardioSession session,
    List<TrainingSession> sessions, {
    int? profileMaxHr,
  }) {
    final series = PaceSeries.forActivity(sessions, session.activity);
    final maxHr = session.maxHr ?? profileMaxHr;
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

    // Regel 1: beide Pulswerte, und das Maximum muss über dem Mittel liegen —
    // sonst wäre der Prozentwert eine Behauptung über einen Tippfehler.
    if (avgHr != null && maxHr != null && maxHr > 0 && avgHr <= maxHr) {
      final percent = (avgHr / maxHr * 100).round();
      return CardioIntensity(
        level: IntensityLevel.heartRate,
        avgHr: base.avgHr,
        maxHr: base.maxHr,
        rpe: base.rpe,
        tempoValue: base.tempoValue,
        usesSpeed: base.usesSpeed,
        basisCount: base.basisCount,
        zone: zoneFor(percent),
        percentOfMax: percent,
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
