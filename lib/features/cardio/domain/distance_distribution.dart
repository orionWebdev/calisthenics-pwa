import '../../history/domain/training_session.dart';

/// Ein Balken der Verteilung.
class DistanceBucket {
  const DistanceBucket({required this.fromKm, this.toKm, required this.count});

  final double fromKm;

  /// `null` heisst: offen nach oben.
  final double? toKm;
  final int count;
}

/// Verteilung der Distanzen — Board 11, B3/1.
///
/// Fünf feste Klassen, keine gleitenden: Die Grenzen sollen von Monat zu Monat
/// dieselben bleiben, sonst sähe ein Balken anders aus, ohne dass sich am
/// Laufen etwas geändert hat. Der Nenner nennt nur Einheiten **mit** Distanz —
/// sieben von 51 haben keine, und die stehen in keiner Klasse.
class DistanceDistribution {
  const DistanceDistribution({required this.buckets, required this.withDistance,
      required this.total});

  static const _edges = <double>[5, 8, 12, 20];

  final List<DistanceBucket> buckets;

  /// Einheiten mit Distanz — der Nenner.
  final int withDistance;

  /// Alle Ausdauereinheiten.
  final int total;

  bool get isEmpty => withDistance == 0;

  int get maxCount => buckets.fold<int>(0, (a, b) => b.count > a ? b.count : a);

  static DistanceDistribution compute(List<TrainingSession> sessions) {
    final counts = List<int>.filled(_edges.length + 1, 0);
    var total = 0;
    var withDistance = 0;
    for (final s in sessions) {
      if (s is! CardioSession) continue;
      total++;
      final km = s.distanceKm;
      if (km == null || km <= 0) continue;
      withDistance++;
      var i = 0;
      while (i < _edges.length && km >= _edges[i]) {
        i++;
      }
      counts[i]++;
    }

    return DistanceDistribution(
      buckets: [
        for (var i = 0; i <= _edges.length; i++)
          DistanceBucket(
            fromKm: i == 0 ? 0 : _edges[i - 1],
            toKm: i == _edges.length ? null : _edges[i],
            count: counts[i],
          ),
      ],
      withDistance: withDistance,
      total: total,
    );
  }
}
