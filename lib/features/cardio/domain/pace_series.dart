import '../../history/domain/training_session.dart';

/// Ein Lauf in der Tempokurve.
class PacePoint {
  const PacePoint({required this.session, required this.value});

  final CardioSession session;

  /// In der Einheit der Aktivität: min/km oder km/h.
  final double value;

  DateTime get date => session.date;
}

/// Tempoentwicklung **je Aktivität** — Board 11, B3/2 und B3/3.
///
/// Nie über Aktivitäten hinweg: Ein Wanderschnitt neben einem Laufschnitt wäre
/// eine Zahl ohne Bedeutung. Verglichen wird gegen den **Median** derselben
/// Aktivität (B4, Stufe 3) — ein einzelner Spaziergang verzerrt ihn nicht.
///
/// ## Drei Schwellen
///
/// * Kurve ab [curveMinimum] Einheiten, sonst Schnitt und Spanne.
/// * Perzentil ab [percentileMinimum]: „Schneller als 3 von 5" ist eine
///   Rangfolge, keine Verteilung.
/// * Der Intensitätskasten (Stufe 3) verlangt nur [intensityMinimum] — er
///   urteilt gröber und sagt das dazu.
class PaceSeries {
  const PaceSeries({
    required this.activity,
    required this.points,
  });

  static const curveMinimum = 8;
  static const percentileMinimum = 10;
  static const intensityMinimum = 3;

  final CardioActivity? activity;

  /// Älteste zuerst. Nur Einheiten mit Tempo — ohne Distanz gibt es keins.
  final List<PacePoint> points;

  int get count => points.length;
  bool get isEmpty => points.isEmpty;
  bool get hasCurve => count >= curveMinimum;
  bool get hasPercentile => count >= percentileMinimum;

  bool get usesSpeed => activity?.usesSpeed ?? false;

  /// Ist ein kleinerer Wert besser? Bei min/km ja, bei km/h nein.
  bool get lowerIsBetter => !usesSpeed;

  /// Der Median — „dein Schnitt".
  double? get median {
    if (points.isEmpty) return null;
    final sorted = points.map((p) => p.value).toList()..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// Langsamster und schnellster Wert — die Spanne.
  double? get slowest => points.isEmpty
      ? null
      : points.map((p) => p.value).reduce(lowerIsBetter
          ? (a, b) => a > b ? a : b
          : (a, b) => a < b ? a : b);

  double? get fastest => points.isEmpty
      ? null
      : points.map((p) => p.value).reduce(lowerIsBetter
          ? (a, b) => a < b ? a : b
          : (a, b) => a > b ? a : b);

  PacePoint? get last => points.isEmpty ? null : points.last;

  /// Wie viele Einheiten dieser Aktivität langsamer waren als [value].
  int fasterThan(double value) {
    var n = 0;
    for (final p in points) {
      if (lowerIsBetter ? p.value > value : p.value < value) n++;
    }
    return n;
  }

  /// Liegt [value] über dem eigenen Schnitt? `null` ohne Schnitt oder bei
  /// Gleichstand.
  bool? aboveMedian(double value) {
    final m = median;
    if (m == null || value == m) return null;
    return lowerIsBetter ? value < m : value > m;
  }

  /// Alle Einheiten dieser Aktivität mit Tempo, älteste zuerst.
  static PaceSeries forActivity(
    List<TrainingSession> sessions,
    CardioActivity? activity,
  ) {
    final points = <PacePoint>[];
    for (final s in sessions) {
      if (s is! CardioSession || s.activity != activity) continue;
      final tempo = s.tempo;
      if (tempo == null) continue;
      points.add(PacePoint(session: s, value: tempo.value));
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return PaceSeries(activity: activity, points: points);
  }

  /// Aktivitäten nach Häufigkeit, die häufigste zuerst — für die Kapselreihe.
  static List<MapEntry<CardioActivity?, int>> activitiesByCount(
    List<TrainingSession> sessions,
  ) {
    final counts = <CardioActivity?, int>{};
    for (final s in sessions) {
      if (s is! CardioSession) continue;
      counts[s.activity] = (counts[s.activity] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
