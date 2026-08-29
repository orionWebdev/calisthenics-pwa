import '../../history/domain/training_session.dart';
import 'iso_week.dart';

/// Eine Spur im Verhältnis.
class RatioTrack {
  const RatioTrack({
    required this.minutes,
    required this.count,
    required this.measure,
    this.sets = 0,
  });

  final int minutes;
  final int count;

  /// Nur bei Kraft: „8,4 t Volumen · 74 Sätze".
  final int sets;

  /// Die Fachgrösse der Spur: Tonnen bei Kraft, Kilometer bei Ausdauer.
  /// Sie steht **unter** der Prozentzahl, damit sichtbar bleibt, dass die
  /// Prozente aus Zeit stammen und nicht aus Leistung.
  final double measure;
}

/// Zwei Spuren, ein Verhältnis — **niemals eine Summe**. Board 11, C1.
///
/// Der Anteil rechnet über **Trainingsminuten**, die einzige Grösse, die beide
/// Spuren wirklich teilen (Sektion K, Punkt 1: Nenner immer sichtbar). Kein
/// Hybrid-Score, keine Umrechnung von Kilogramm in Kilometer.
///
/// Die Verschiebung ist die Differenz des Kraftanteils dieser Woche zum
/// mittleren Kraftanteil der vier Wochen davor, in Prozentpunkten. Wochen
/// ohne Trainingsminuten fliessen nicht in den Schnitt: Ein Anteil an null
/// Minuten ist keine Zahl. Unter vier Wochen Geschichte gibt es keine
/// Verschiebung — „kein 4-Wochen-Schnitt", nicht 0.
class WeekRatio {
  const WeekRatio({
    required this.weekStart,
    required this.strength,
    required this.cardio,
    this.shiftPp,
  });

  static const shiftWeeks = 4;

  final DateTime weekStart;
  final RatioTrack strength;
  final RatioTrack cardio;

  /// Verschiebung des Kraftanteils in Prozentpunkten; die Ausdauer verschiebt
  /// sich um denselben Betrag in die andere Richtung.
  final double? shiftPp;

  int get totalMinutes => strength.minutes + cardio.minutes;
  int get totalCount => strength.count + cardio.count;

  /// Beide Spuren belegt — sonst gibt es kein Verhältnis (C1/2).
  bool get hasBothTracks => strength.minutes > 0 && cardio.minutes > 0;

  /// Kraftanteil 0..1.
  double get strengthShare =>
      totalMinutes == 0 ? 0 : strength.minutes / totalMinutes;
  double get cardioShare => totalMinutes == 0 ? 0 : 1 - strengthShare;

  int get strengthPercent => (strengthShare * 100).round();
  int get cardioPercent => 100 - strengthPercent;

  static WeekRatio compute(List<TrainingSession> sessions, DateTime reference) {
    final currentStart = IsoWeek.start(reference);
    final current = _week(sessions, currentStart);

    // Vier volle Wochen davor, nur wenn die Geschichte so weit reicht.
    DateTime? first;
    for (final s in sessions) {
      if (s.kind == null || s.kind == SessionKind.recovery) continue;
      if (first == null || s.date.isBefore(first)) first = s.date;
    }
    final windowStart = DateTime(currentStart.year, currentStart.month,
        currentStart.day - 7 * shiftWeeks);

    double? shift;
    if (first != null && !first.isAfter(windowStart)) {
      var sum = 0.0;
      var weeks = 0;
      for (var i = 1; i <= shiftWeeks; i++) {
        final start = DateTime(
            currentStart.year, currentStart.month, currentStart.day - 7 * i);
        final week = _week(sessions, start);
        if (week.totalMinutes == 0) continue;
        sum += week.strengthShare;
        weeks++;
      }
      if (weeks > 0 && current.totalMinutes > 0) {
        shift = (current.strengthShare - sum / weeks) * 100;
      }
    }

    return WeekRatio(
      weekStart: currentStart,
      strength: current.strength,
      cardio: current.cardio,
      shiftPp: shift,
    );
  }

  static WeekRatio _week(List<TrainingSession> sessions, DateTime start) {
    final end = DateTime(start.year, start.month, start.day + 7);
    var strengthMin = 0, strengthCount = 0;
    var cardioMin = 0, cardioCount = 0;
    var tonnageKg = 0.0;
    var sets = 0;
    var km = 0.0;

    for (final s in sessions) {
      if (s.date.isBefore(start) || !s.date.isBefore(end)) continue;
      final minutes = s.duration?.inMinutes ?? 0;
      switch (s) {
        case StrengthSession():
          strengthMin += minutes;
          strengthCount++;
          for (final e in s.exercises) {
            for (final set in e.sets) {
              if (set.isEmpty) continue;
              sets++;
              tonnageKg += (set.reps ?? 0) * (set.weight ?? 0);
            }
          }
        case CardioSession():
          cardioMin += minutes;
          cardioCount++;
          km += s.distanceKm ?? 0;
        case RecoverySession():
        case UnknownSession():
          // Regeneration trägt keine Last — und auch keine Minuten im
          // Verhältnis. Sie ist eine Eingangsgrösse der Bereitschaft.
          break;
      }
    }

    return WeekRatio(
      weekStart: start,
      strength: RatioTrack(
        minutes: strengthMin,
        count: strengthCount,
        measure: tonnageKg / 1000,
        sets: sets,
      ),
      cardio: RatioTrack(minutes: cardioMin, count: cardioCount, measure: km),
    );
  }
}
