import 'dart:math' as math;

import 'readiness.dart';
import 'training_load.dart';
import 'training_session.dart';

/// Die langfristige Trainingsform — die Gegenspielerin zur Readiness.
///
/// Readiness beantwortet „was ist heute drin?", die Form „wo stehe ich?".
/// Deshalb gibt es hier **keine** Überlastungszone: Überreizung gehört zum
/// ACWR, nicht zur Form.
enum FormZone {
  detrained('detrained'),
  declining('declining'),
  recovery('recovery'),
  maintaining('maintaining'),
  building('building'),
  productive('productive'),
  peakForm('peak_form');

  const FormZone(this.wire);

  final String wire;
}

/// Richtung der Fitnesskurve im Vergleich zu vor vierzehn Tagen.
enum FormTrend {
  none('none'),
  falling('falling'),
  stable('stable'),
  rising('rising');

  const FormTrend(this.wire);

  final String wire;
}

/// Ergebnis der Formrechnung, mit allen Bestandteilen einzeln.
///
/// Die Zerlegung ist nicht Zierde: Ein Formwert von 48 sagt wenig, „Konstanz 35
/// von 35, aber seit sechs Tagen nichts" sagt alles. Die Oberfläche kann daraus
/// eine Begründung bauen statt einer Zahl.
class FormResult {
  const FormResult({
    required this.consistency,
    required this.loadLevel,
    required this.recency,
    required this.fitnessVsPeak,
    required this.sessionBonus,
    required this.inactivityPenalty,
    required this.trend,
    this.score,
    this.zone,
    this.daysSinceLastSession,
    this.lastWasRecovery = false,
  });

  static const empty = FormResult(
    consistency: 0,
    loadLevel: 0,
    recency: 0,
    fitnessVsPeak: 0,
    sessionBonus: 0,
    inactivityPenalty: 0,
    trend: FormTrend.none,
  );

  /// Trainingstage der letzten 28 Tage, 0 bis 35 Punkte.
  final int consistency;

  /// Lastentwicklung der letzten 14 Tage gegen die 14 davor, 0 bis 30 Punkte.
  final int loadLevel;

  /// Wie frisch die letzte Einheit ist, 0 bis 15 Punkte.
  final int recency;

  /// Aktuelle Fitness im Verhältnis zum eigenen Höchststand, 0 bis 15 Punkte.
  final int fitnessVsPeak;

  /// Sofortzuschlag für eine Einheit am Stichtag, 0 bis 8 Punkte.
  final int sessionBonus;

  /// Abzug für Untätigkeit. Steigt beschleunigt.
  final int inactivityPenalty;

  final FormTrend trend;
  final int? score;
  final FormZone? zone;
  /// Tage seit der letzten **Aktivität** — Regeneration zählt mit.
  final int? daysSinceLastSession;

  /// War diese letzte Aktivität eine Regenerationseinheit?
  ///
  /// Die Oberfläche muss das sagen können. „Letzte Einheit gestern" neben
  /// einem Formwert, der seit zehn Tagen fällt, wäre ein Widerspruch, den
  /// niemand auflösen kann — „Gestern Regeneration" ist keiner.
  final bool lastWasRecovery;

  bool get hasScore => score != null;
}

/// Portierung von `computeFormScore` und `mapFormZone`.
abstract final class TrainingForm {
  /// Sehr langsames Mittel — etwa 33 Tage wirksames Fenster. Es bildet
  /// angesammelte Fitness ab, nicht Tagesform.
  static const _fitnessAlpha = 0.03;

  static const _windowDays = 120;
  static const _minimumHistoryDays = 14;

  /// Ab 16 Trainingstagen in 28 gibt es die volle Punktzahl für Konstanz —
  /// das entspricht viermal pro Woche.
  static const _fullConsistencyDays = 16;

  /// Zählt eine Regenerationseinheit als Aktivität?
  ///
  /// ## Eine bewusste Abweichung von der Vorgänger-App
  ///
  /// Dort geht Regeneration in die Form überhaupt nicht ein: Nach zehn Tagen
  /// täglichem Yoga steht „letzte Einheit vor 10 Tagen" und der volle
  /// Untätigkeitsabzug. Gleichzeitig zählt der Verlaufsbildschirm dieselbe
  /// Einheit sehr wohl mit (`DataSufficiency.daysSinceLast` liest alle Arten) —
  /// die Begründungszeile widersprach also der Zahl, die sie begründen soll.
  ///
  /// Hier bricht Regeneration die Pause, trägt aber **keine Last**: Sie setzt
  /// Aktualität und Untätigkeitsabzug zurück und geht in Konstanz, Fitness und
  /// Tageszuschlag nicht ein. Das beschreibt genau, was passiert ist — ohne zu
  /// behaupten, Sauna baue Form auf.
  ///
  /// [countRecoveryAsActivity] auf `false` stellt die Rechnung der
  /// Vorgänger-App wieder her. Das braucht genau eine Stelle: der Vergleich
  /// gegen `js/views/sessions/scoring.js` in `scoring_oracle_test.dart`. Ohne
  /// diesen Schalter wäre die Abweichung nicht mehr von einem Portierungsfehler
  /// zu unterscheiden.
  static const defaultCountRecoveryAsActivity = true;

  static FormResult compute(
    List<TrainingSession> sessions,
    DateTime referenceDate, {
    LoadContext context = const LoadContext(),
    bool countRecoveryAsActivity = defaultCountRecoveryAsActivity,
  }) {
    if (sessions.isEmpty) return FormResult.empty;

    final refDay =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final end = refDay.add(const Duration(days: 1));

    // **Last und Aktivität sind zwei verschiedene Mengen.** Nur `dailyLoads`
    // geht in Konstanz, Fitnesskurve und Tageszuschlag ein; `recoveryDays`
    // wirkt allein auf Aktualität und Untätigkeitsabzug.
    final dailyLoads = <String, double>{};
    final recoveryDays = <String>{};
    for (final session in sessions) {
      final kind = session.kind;
      if (kind == null) continue;
      if (!session.date.isBefore(end)) continue;

      if (kind == SessionKind.recovery) {
        if (countRecoveryAsActivity) {
          recoveryDays.add(Readiness.dayKey(session.date));
        }
        continue;
      }

      final load = TrainingLoad.of(session, context);
      if (load <= 0) continue;
      final key = Readiness.dayKey(session.date);
      dailyLoads[key] = (dailyLoads[key] ?? 0) + load;
    }

    if (dailyLoads.isEmpty) return FormResult.empty;

    final sortedKeys = dailyLoads.keys.toList()..sort();
    final earliest = DateTime.parse(sortedKeys.first);
    if (_daysBetween(earliest, refDay) < _minimumHistoryDays) {
      return FormResult.empty;
    }

    // Die letzte Aktivität ist die spätere von beiden. Eine Regenerationseinheit
    // **vor** der letzten Trainingseinheit ändert nichts — sie ist dann nicht
    // die letzte Aktivität.
    final lastLoadDay = DateTime.parse(sortedKeys.last);
    final lastRecoveryKey =
        recoveryDays.isEmpty ? null : (recoveryDays.toList()..sort()).last;
    final lastRecoveryDay =
        lastRecoveryKey == null ? null : DateTime.parse(lastRecoveryKey);

    final lastWasRecovery =
        lastRecoveryDay != null && lastRecoveryDay.isAfter(lastLoadDay);
    final lastActivityDay = lastWasRecovery ? lastRecoveryDay : lastLoadDay;
    final daysSinceLastSession = _daysBetween(lastActivityDay, refDay);

    // ---- 1. Konstanz: Trainingstage der letzten 28 Tage ----
    final consistencyStart =
        DateTime(refDay.year, refDay.month, refDay.day - 27);
    var trainingDays = 0;
    for (final key in dailyLoads.keys) {
      final day = DateTime.parse(key);
      if (!day.isBefore(consistencyStart) && !day.isAfter(refDay)) {
        trainingDays++;
      }
    }
    final consistency =
        math.min(35, (trainingDays / _fullConsistencyDays * 35).round());

    // ---- Fitnesskurve über das Fenster ----
    //
    // Die Tage werden vorab als Liste gebildet, damit der Abstand zum Stichtag
    // gezählt und nicht aus Millisekunden gerechnet wird. Zwischen zwei lokalen
    // Mitternachten liegen bei einer Zeitumstellung 23 oder 25 Stunden — die
    // PWA schneidet dort ab und verschiebt damit die 14-Tage-Grenzen.
    final windowStart =
        DateTime(refDay.year, refDay.month, refDay.day - _windowDays);
    final start = earliest.isAfter(windowStart) ? earliest : windowStart;

    final days = <DateTime>[];
    for (var d = start; !d.isAfter(refDay); d = _nextDay(d)) {
      days.add(d);
    }

    var fitness = 0.0;
    var peakFitness = 0.0;
    var fitnessAt14DaysAgo = 0.0;
    var recent14Load = 0.0;
    var prior14Load = 0.0;

    for (var i = 0; i < days.length; i++) {
      final load = dailyLoads[Readiness.dayKey(days[i])] ?? 0;
      fitness = _fitnessAlpha * load + (1 - _fitnessAlpha) * fitness;
      if (fitness > peakFitness) peakFitness = fitness;

      final daysToRef = days.length - 1 - i;
      if (daysToRef < 14) {
        recent14Load += load;
      } else if (daysToRef < 28) {
        prior14Load += load;
      }
      if (daysToRef == 14) fitnessAt14DaysAgo = fitness;
    }

    // ---- 2. Lastentwicklung: die letzten 14 Tage gegen die 14 davor ----
    var loadLevel = 0;
    if (prior14Load > 0) {
      // Deckel bei 2,0: Nach einer sehr ruhigen Vorperiode ergäbe das
      // Verhältnis sonst absurde Werte.
      final ratio = math.min(recent14Load / prior14Load, 2.0);
      if (ratio <= 0.3) {
        loadLevel = 0;
      } else if (ratio <= 1.0) {
        loadLevel = (5 + (ratio - 0.3) / 0.7 * 15).round();
      } else {
        loadLevel = (20 + math.min(ratio - 1.0, 1.0) * 10).round();
      }
    } else if (recent14Load > 0) {
      // Trainingsbeginn: Es gibt nichts zu vergleichen, aber Nulldurchgang
      // wäre falsch.
      loadLevel = 12;
    }

    // ---- 3. Aktualität ----
    final recency = switch (daysSinceLastSession) {
      <= 1 => 15,
      <= 2 => 12,
      <= 3 => 8,
      <= 5 => 4,
      <= 7 => 1,
      _ => 0,
    };

    // ---- 4. Fitness gegen den eigenen Höchststand ----
    final fitnessVsPeak = peakFitness > 0
        ? math.min(15, (fitness / peakFitness * 15).round())
        : 0;

    // ---- 5. Zuschlag für eine Einheit heute ----
    final todayLoad = dailyLoads[Readiness.dayKey(refDay)] ?? 0;
    var sessionBonus = 0;
    if (todayLoad > 0 && recent14Load > 0) {
      final average = recent14Load / 14;
      sessionBonus = average > 0
          ? math.min(8, (4 * math.sqrt(todayLoad / average)).round())
          : 3;
    }

    var score =
        (consistency + loadLevel + recency + fitnessVsPeak + sessionBonus)
            .clamp(0, 100);

    // ---- Abzug für Untätigkeit ----
    //
    // Zwei Ruhetage kosten nichts, danach beschleunigt es: 3 Tage minus 3,
    // 7 Tage minus 21, 14 Tage minus 70. Form ist verderblich.
    var inactivityPenalty = 0;
    if (daysSinceLastSession > 2) {
      if (daysSinceLastSession <= 4) {
        inactivityPenalty = (daysSinceLastSession - 2) * 3;
      } else if (daysSinceLastSession <= 7) {
        inactivityPenalty = 6 + (daysSinceLastSession - 4) * 5;
      } else {
        inactivityPenalty = 21 + (daysSinceLastSession - 7) * 7;
      }
      score = math.max(0, score - inactivityPenalty);
    }

    final trend = fitnessAt14DaysAgo > 0
        ? switch (fitness / fitnessAt14DaysAgo) {
            > 1.05 => FormTrend.rising,
            < 0.95 => FormTrend.falling,
            _ => FormTrend.stable,
          }
        : (fitness > 0 ? FormTrend.rising : FormTrend.stable);

    return FormResult(
      consistency: consistency,
      loadLevel: loadLevel,
      recency: recency,
      fitnessVsPeak: fitnessVsPeak,
      sessionBonus: sessionBonus,
      inactivityPenalty: inactivityPenalty,
      trend: trend,
      score: score,
      zone: mapZone(score, daysSinceLastSession),
      daysSinceLastSession: daysSinceLastSession,
      lastWasRecovery: lastWasRecovery,
    );
  }

  /// Ordnet einen Formwert einer Zone zu.
  ///
  /// Die Kurve wird mit Exponent 1,3 gestaucht, damit sich die Werte nicht im
  /// oberen Bereich stauen und `peakForm` selten bleibt.
  static FormZone mapZone(int score, int daysSinceLastSession) {
    final adjusted = math.pow(math.max(0, score) / 100, 1.3) * 100;

    // Zwei bis fünf Ruhetage bei noch guter Form heißen Erholung, nicht Abbau.
    if (daysSinceLastSession >= 2 &&
        daysSinceLastSession <= 5 &&
        adjusted > 13) {
      return FormZone.recovery;
    }
    if (adjusted <= 13) return FormZone.detrained;
    if (adjusted <= 32) return FormZone.declining;
    if (adjusted <= 58) return FormZone.maintaining;
    if (adjusted <= 78) return FormZone.building;
    if (adjusted <= 94) return FormZone.productive;
    return FormZone.peakForm;
  }

  static DateTime _nextDay(DateTime day) =>
      DateTime(day.year, day.month, day.day + 1);

  /// Kalendarischer Abstand in Tagen — nicht aus Millisekunden gerechnet.
  static int _daysBetween(DateTime from, DateTime to) =>
      (DateTime(to.year, to.month, to.day)
                  .difference(DateTime(from.year, from.month, from.day))
                  .inHours /
              24)
          .round();
}
