import 'dart:math' as math;

import 'training_load.dart';
import 'training_session.dart';

/// Die Trainingszone aus dem Verhältnis akuter zu chronischer Last.
enum ReadinessZone {
  formLoss('form_loss'),
  overreaching('overreaching'),
  fatigued('fatigued'),
  maintaining('maintaining'),
  building('building'),
  peak('peak');

  const ReadinessZone(this.wire);

  /// Der Bezeichner der PWA. Für Vergleich und Speicherung, nie zur Anzeige.
  final String wire;
}

/// Ergebnis der Readiness-Rechnung.
///
/// `acwr`, `score` und `zone` sind gemeinsam `null`, solange es keine
/// belastbare Grundlage gibt — weniger als 14 Tage Historie oder eine
/// chronische Last nahe null. Ein Wert wäre dann eine Erfindung.
class AcwrResult {
  const AcwrResult({
    required this.acuteLoad,
    required this.chronicLoad,
    required this.todayLoad,
    required this.fatiguePenalty,
    this.acwr,
    this.score,
    this.zone,
    this.daysSinceLastSession,
  });

  static const empty = AcwrResult(
    acuteLoad: 0,
    chronicLoad: 0,
    todayLoad: 0,
    fatiguePenalty: 0,
  );

  final double acuteLoad;
  final double chronicLoad;
  final double todayLoad;
  final int fatiguePenalty;

  final double? acwr;
  final int? score;
  final ReadinessZone? zone;
  final int? daysSinceLastSession;

  bool get hasScore => score != null;
}

/// Portierung von `getACWR` aus `js/views/sessions/scoring.js`.
abstract final class Readiness {
  /// Glättungsfaktoren der beiden gleitenden Mittel.
  ///
  /// α = 0,22 entspricht einem wirksamen Fenster von etwa fünf Tagen, α = 0,07
  /// von etwa vierzehn. Die Werte stehen so in der PWA, mit dem Vermerk, dass
  /// frühere (0,35 und 0,10) zu schnell reagierten.
  static const _acuteAlpha = 0.22;
  static const _chronicAlpha = 0.07;

  /// Aktive Erholung senkt die akute Last zusätzlich um fünf Prozent.
  static const _recoveryBoost = 0.05;

  /// Weiter zurück rechnet die PWA nicht.
  static const _windowDays = 56;

  /// Darunter gibt es keine belastbare Aussage.
  static const _minimumHistoryDays = 14;

  /// Tagesschlüssel in **lokaler** Zeit.
  ///
  /// Bewusst nicht UTC: Ein Training um 23:30 gehört zu diesem Tag, nicht zum
  /// nächsten. Die PWA macht es genauso, und jede Abweichung verschöbe Werte.
  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static AcwrResult compute(
    List<TrainingSession> sessions,
    DateTime referenceDate, {
    LoadContext context = const LoadContext(),
    bool applyFatigue = false,
  }) {
    if (sessions.isEmpty) return AcwrResult.empty;

    final refDay = _startOfDay(referenceDate);
    final end = refDay.add(const Duration(days: 1));

    // Tageslasten aufsummieren, Erholungstage getrennt merken.
    final dailyLoads = <String, double>{};
    final recoveryDays = <String>{};

    for (final session in sessions) {
      if (!session.date.isBefore(end)) continue;

      if (TrainingLoad.isRecovery(session)) {
        recoveryDays.add(dayKey(session.date));
      }

      // Nur Kraft, Körpergewicht und Cardio tragen Last. Regeneration wirkt
      // ausschließlich über den Erholungsbonus.
      final kind = session.kind;
      if (kind == null || kind == SessionKind.recovery) continue;

      final load = TrainingLoad.of(session, context);
      if (load <= 0) continue;
      final key = dayKey(session.date);
      dailyLoads[key] = (dailyLoads[key] ?? 0) + load;
    }

    if (dailyLoads.isEmpty) return AcwrResult.empty;

    final sortedKeys = dailyLoads.keys.toList()..sort();
    final earliest = DateTime.parse(sortedKeys.first);
    final daySpan = refDay.difference(earliest).inDays;
    if (daySpan < _minimumHistoryDays) return AcwrResult.empty;

    final lastSession = DateTime.parse(sortedKeys.last);
    final daysSinceLastSession = refDay.difference(lastSession).inDays;

    // Fortlaufendes EMA über **alle** Tage, Ruhetage mit Last 0 eingeschlossen.
    // Nur die Ruhetage lassen die akute Last überhaupt abklingen.
    //
    // Die Fenstergrenze wird **kalendarisch** gebildet, nicht über 56 mal 24
    // Stunden. Das ist eine bewusste Abweichung von der PWA: Dort landet der
    // Startpunkt bei einer Zeitumstellung im Fenster auf 23:00 des Vortags,
    // die Schleife schleppt diese Uhrzeit mit und endet einen Tag zu früh —
    // der Referenztag fällt aus dem Mittel heraus. Zweimal im Jahr, jeweils
    // für die folgenden acht Wochen. Siehe Vertrag 4.
    final windowStart =
        DateTime(refDay.year, refDay.month, refDay.day - _windowDays);
    var cursor = earliest.isAfter(windowStart) ? earliest : windowStart;

    var acute = 0.0;
    var chronic = 0.0;

    while (!cursor.isAfter(refDay)) {
      final key = dayKey(cursor);
      final load = dailyLoads[key] ?? 0;

      acute = _acuteAlpha * load + (1 - _acuteAlpha) * acute;
      chronic = _chronicAlpha * load + (1 - _chronicAlpha) * chronic;

      if (recoveryDays.contains(key)) {
        acute *= 1 - _recoveryBoost;
      }

      cursor = _startOfDay(cursor.add(const Duration(days: 1)));
    }

    if (chronic < 0.01) {
      return AcwrResult(
        acuteLoad: acute,
        chronicLoad: chronic,
        todayLoad: 0,
        fatiguePenalty: 0,
        daysSinceLastSession: daysSinceLastSession,
      );
    }

    final acwr = (acute / chronic * 100).round() / 100;
    final raw = mapScore(acwr);

    final todayLoad = dailyLoads[dayKey(refDay)] ?? 0;
    var penalty = 0;
    if (applyFatigue && todayLoad > 0) {
      // Wurzelkurve mit abnehmendem Ertrag: Eine harte Einheit kostet nicht
      // doppelt so viel wie eine mittlere.
      penalty = math.min(35, (10 * math.sqrt(todayLoad / chronic)).round());
    }

    final score = math.max(5, raw - penalty);

    return AcwrResult(
      acuteLoad: acute,
      chronicLoad: chronic,
      todayLoad: todayLoad,
      fatiguePenalty: penalty,
      acwr: acwr,
      score: score,
      zone: mapZone(score, acwr),
      daysSinceLastSession: daysSinceLastSession,
    );
  }

  /// Stützstellen der Bewertungskurve. Spitze bei ACWR 1,0, symmetrischer
  /// Abfall nach beiden Seiten — Untertraining zählt genauso als Verlust wie
  /// Übertraining.
  static const _curve = <(double, double)>[
    (0.0, 10),
    (0.3, 22),
    (0.5, 38),
    (0.65, 50),
    (0.75, 60),
    (0.85, 72),
    (0.95, 85),
    (1.0, 90),
    (1.05, 85),
    (1.15, 72),
    (1.25, 60),
    (1.35, 50),
    (1.5, 38),
    (1.7, 25),
    (2.0, 14),
    (2.5, 6),
  ];

  /// Lineare Interpolation zwischen den Stützstellen.
  static int mapScore(double acwr) {
    final clamped = acwr.clamp(0.0, 2.5);
    if (clamped <= _curve.first.$1) return _curve.first.$2.round();

    for (var i = 0; i < _curve.length - 1; i++) {
      final (x0, y0) = _curve[i];
      final (x1, y1) = _curve[i + 1];
      if (clamped >= x0 && clamped <= x1) {
        final t = (clamped - x0) / (x1 - x0);
        return (y0 + (y1 - y0) * t).round();
      }
    }
    return _curve.last.$2.round();
  }

  /// Der ACWR unterscheidet, ob ein niedriger Wert von zu wenig oder zu viel
  /// kommt — dieselbe Punktzahl kann beides bedeuten.
  static ReadinessZone mapZone(int score, double acwr) {
    if (acwr < 0.8 && score <= 55) return ReadinessZone.formLoss;
    if (score <= 30) return ReadinessZone.overreaching;
    if (score <= 50) return ReadinessZone.fatigued;
    if (score <= 68) return ReadinessZone.maintaining;
    if (score <= 82) return ReadinessZone.building;
    return ReadinessZone.peak;
  }
}
