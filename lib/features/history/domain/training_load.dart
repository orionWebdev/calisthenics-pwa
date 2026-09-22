import 'dart:math' as math;

import 'training_session.dart';

/// Was die Lastberechnung von außen braucht.
///
/// Im JavaScript hängt `calculateSessionLoadValue` an zwei globalen Variablen:
/// `userProfile.bodyWeight` und `allExercises`. Global heißt hier: nicht
/// testbar, nicht nachvollziehbar, und beim Laden in falscher Reihenfolge
/// stillschweigend leer. In Dart sind es Parameter.
class LoadContext {
  const LoadContext({
    this.bodyWeightKg = 0,
    this.bodyweightExerciseIds = const {},
    this.bodyWeightOn,
    this.measuredEffortOf,
  });

  /// Körpergewicht in Kilogramm, 0 wenn unbekannt.
  ///
  /// Ist es 0, liefern Körpergewichtsübungen ein Volumen von 0 — dann greift
  /// die Ersatzrechnung nach Dauer. Das ist im JavaScript so angelegt und wird
  /// hier bewusst übernommen.
  ///
  /// Seit dem 20.09.2026 ist dies der **Rückfall**, nicht mehr der Maßstab:
  /// Gibt es eine Gewichtsreihe, fragt [weightOn] sie nach dem Wert, der am
  /// Tag der Einheit galt.
  final double bodyWeightKg;

  /// Das Körpergewicht, das an einem bestimmten Tag zuletzt bekannt war.
  ///
  /// ## Warum die Last ein Datum braucht (Board 14, Abschnitt E)
  ///
  /// Bis hierher bewertete **ein** aktuelles Gewicht jede Körpergewichtsübung
  /// des gesamten Verlaufs. Wer über ein Jahr zehn Kilo verliert, liess damit
  /// die Trainingslast jeder Einheit dieses Jahres mitwandern — rückwirkend
  /// und ohne dass sich eine einzige Einheit geändert hätte.
  ///
  /// Mit einer Reihe gilt je Einheit der Wert, der an ihrem Tag zuletzt
  /// bekannt war. Ein neuer Eintrag verschiebt deshalb nur noch die Spanne bis
  /// zum nächsten Eintrag, nicht mehr die ganze Vergangenheit.
  ///
  /// `null` — der Rückruf selbst oder sein Ergebnis — heisst: für diesen Tag
  /// weiss die Reihe nichts, dann gilt [bodyWeightKg] wie bisher. Die Funktion
  /// ist bewusst ein Rückruf und keine Reihe: Die Lastrechnung soll nichts
  /// über die Form des Verlaufs wissen müssen.
  final double? Function(DateTime date)? bodyWeightOn;

  /// Der Maßstab für eine Einheit an [date].
  double weightOn(DateTime date) => bodyWeightOn?.call(date) ?? bodyWeightKg;

  /// Die **gemessene** Anstrengung einer Einheit, 1 bis 5 — oder `null`.
  ///
  /// ## Warum das hier steht und nicht an der Einheit
  ///
  /// Der Puls liegt am Uhr-Datensatz daneben, nicht in der Einheit (Board 15,
  /// Entscheidung 1: „Lösen ist verlustfrei"). Die Lastrechnung soll davon
  /// nichts wissen müssen — so wenig, wie sie von der Form der Gewichtsreihe
  /// weiss. Deshalb ein Rückruf, der eine fertige Zahl liefert, genau wie
  /// [bodyWeightOn]: Der Aufrufer schlägt nach, hier wird nur gerechnet.
  ///
  /// `null` heisst durchweg dasselbe: **Die Messung sagt nichts.** Keine Uhr,
  /// keine Zonen, kein Pulsverlauf oder zu wenig davon. Ohne den Rückruf
  /// verhält sich alles wie vor dem 22.09.2026.
  final int? Function(TrainingSession session)? measuredEffortOf;

  /// Die Anstrengung, mit der eine Einheit rechnet — **in dieser Reihenfolge**.
  ///
  /// 1. Was jemand **eingetragen** hat. Eine Messung überschreibt keine
  ///    Eingabe; wer eine Zahl genannt hat, hat eine Aussage gemacht, und ein
  ///    stiller Ersatz nähme sie zurück, ohne zu fragen. Dieselbe Regel gilt
  ///    seit dem 20.09.2026 fürs Gewicht (`weight_sync.dart`).
  /// 2. Was die Uhr **gemessen** hat.
  /// 3. Sonst der Ersatzwert 3 — der neutrale Faktor 1,0, wie bisher.
  ///
  /// Schritt 2 ist der ganze Unterschied: Er tritt **nur** an die Stelle, an
  /// der die App bisher geraten hat.
  int effortFor(TrainingSession session) =>
      session.rpe ?? measuredEffortOf?.call(session) ?? TrainingLoad.defaultRpe;

  /// Übungen, die laut Katalog mit dem Körpergewicht rechnen.
  ///
  /// **Im Produktivbestand ist diese Menge leer.** Keines der 154 Dokumente in
  /// `exercises_curated` und `exercises` trägt `usesBodyweight`; der
  /// Rückfallpfad des JavaScripts greift also nie. Der Haken bleibt, damit die
  /// Portierung vollständig ist und ein späterer Katalog ihn benutzen kann.
  final Set<String> bodyweightExerciseIds;
}

/// Die Trainingslast einer Einheit — portiert aus `js/views/sessions/scoring.js`.
///
/// Jede Zahl hier stammt aus der PWA und ist **nicht** neu erfunden. Wo sie
/// überrascht, steht der Grund daneben. Ein Testorakel vergleicht die Ergebnisse
/// direkt mit denen des JavaScripts (siehe `tool/scoring_oracle.mjs`) — mit
/// **einer** bewussten Ausnahme, siehe [_strength].
abstract final class TrainingLoad {
  /// Faktoren der Anstrengung. Die Skala reicht **1 bis 5**, nicht 1 bis 10 —
  /// im Bestand kommen 1 bis 4 vor.
  static const _rpeFactors = {1: 0.6, 2: 0.8, 3: 1.0, 4: 1.2, 5: 1.4};

  /// Sportarten-Faktoren für Cardio. `swim` und `row` stehen im JavaScript,
  /// kommen im Bestand aber nicht vor.
  ///
  /// **Zwei Einträge sind nicht aus der PWA:** `bikeIndoor` und `walk` kennt
  /// sie nicht (Board 11 führt sie neu ein). Indoor-Rad bekommt den Radfaktor
  /// — dieselbe Bewegung ohne Wind; Gehen den Wanderfaktor — Wandern ohne
  /// Berg. Beide stehen hier, damit eine neue Aktivität nicht stillschweigend
  /// mit 1,0 rechnet wie ein Lauf.
  static const _sportFactors = {
    'run': 1.0,
    'bike': 0.85,
    'bikeindoor': 0.85,
    'swim': 0.9,
    'hike': 0.4,
    'walk': 0.4,
    'row': 0.95,
    'other': 1.0,
  };

  static const _defaultSportFactor = 1.0;
  static const _strengthVolumeDivisor = 50.0;

  /// Ab hier zählt jede weitere Minute weniger. Eine Wanderung von vier Stunden
  /// ist nicht doppelt so belastend wie eine von zwei.
  static const _dampeningThresholdMinutes = 120.0;
  static const _dampeningExponent = 0.8;

  /// Fehlt `rpe`, rechnet die PWA mit 3 — der neutrale Wert, Faktor 1,0.
  ///
  /// Öffentlich, seit [LoadContext.effortFor] die Reihenfolge kennt: Der
  /// Ersatzwert ist das letzte Glied dieser Kette und soll nur einmal im
  /// Quelltext stehen.
  static const defaultRpe = 3;

  static double rpeFactor(int? rpe) =>
      rpe == null ? 1.0 : (_rpeFactors[rpe] ?? 1.0);

  static double sportFactor(String? activityType) => activityType == null
      ? _defaultSportFactor
      : (_sportFactors[activityType.toLowerCase()] ?? _defaultSportFactor);

  static double effectiveDuration(double minutes) {
    if (minutes <= _dampeningThresholdMinutes) return minutes;
    final excess = minutes - _dampeningThresholdMinutes;
    return _dampeningThresholdMinutes + math.pow(excess, _dampeningExponent);
  }

  /// Auf zwei Nachkommastellen — wie `Math.round(x * 100) / 100` im JavaScript.
  static double _round2(double value) => (value * 100).round() / 100;

  static double _minutes(Duration? duration) =>
      duration == null ? 0 : duration.inMilliseconds / 60000;

  /// Die Rohlast einer Einheit. `0` bedeutet: trägt nicht zur Belastung bei.
  static double of(TrainingSession session, LoadContext context) =>
      switch (session) {
        StrengthSession() => _strength(session, context),
        CardioSession() => _cardio(session, context),
        // Regeneration und Unbekanntes tragen keine Last. Regeneration wirkt
        // trotzdem — über den Erholungsbonus im ACWR, nicht über die Last.
        RecoverySession() || UnknownSession() => 0,
      };

  /// **Bewusste Abweichung vom Orakel** (seit 18.09.2026, Gemini-Review):
  /// Die PWA verwarf ein eingetragenes `set.weight`, sobald eine Übung als
  /// Körpergewicht galt — ein Klimmzug mit 20 kg Zusatzweste zählte wie einer
  /// ohne. Hier zählt beides zusammen: `effectiveWeight = bodyWeightKg +
  /// (set.weight ?? 0)`. Das ist kein übersehener Fall, sondern das
  /// tatsächliche Verhalten des Originals über den ganzen Bestand — deshalb
  /// prüft `test/history/scoring_oracle_test.dart` diese eine Stelle nicht
  /// gegen die rohe PWA-Last, sondern gegen eine gleichermassen korrigierte
  /// zweite Ausführung des Originals (`tool/scoring_oracle.mjs`, `corrected`).
  ///
  /// Wirkung auf den Bestand (geprüft gegen die Sicherung vom 16.09.2026):
  /// 3 von 292 aufgezeichneten Übungseinträgen tragen sowohl die
  /// Körpergewichts-Kennzeichnung als auch ein Satzgewicht — ihre Rohlast
  /// ändert sich rückwirkend. Keiner davon gehört zum aktuell aktiven Konto.
  static double _strength(StrengthSession session, LoadContext context) {
    final factor = rpeFactor(session.rpe ?? defaultRpe);

    // Ohne Übungen: Ersatzrechnung nach Dauer (Schnellerfassung).
    if (session.exercises.isEmpty) {
      return _durationFallback(session, factor);
    }

    // Einmal je Einheit, nicht je Satz: Der Maßstab ist für die ganze
    // Einheit derselbe — sie hat genau ein Datum.
    final bodyWeight = context.weightOn(session.date);

    var totalVolume = 0.0;
    for (final exercise in session.exercises) {
      final usesBodyweight = exercise.usesBodyweight ??
          context.bodyweightExerciseIds.contains(exercise.exerciseId);

      for (final set in exercise.sets) {
        final reps = set.reps ?? 0;
        if (reps <= 0) continue;
        final weight = usesBodyweight
            ? bodyWeight + (set.weight ?? 0)
            : (set.weight ?? 0);
        if (weight == 0) continue;
        totalVolume += weight * reps;
      }
    }

    // Alle Übungen ohne wirksames Gewicht — etwa Körpergewichtstraining ohne
    // hinterlegtes Körpergewicht. Dann zählt die Dauer, damit die Einheit
    // überhaupt in den ACWR eingeht statt zu verschwinden.
    if (totalVolume == 0) {
      return _durationFallback(session, factor);
    }

    return _round2(totalVolume / _strengthVolumeDivisor * factor);
  }

  static double _durationFallback(StrengthSession session, double factor) {
    final minutes = _minutes(session.duration);
    if (minutes <= 0) return 0;
    // `discipline`, nicht `type`: Eine Einheit mit `type: strength` kann
    // `discipline: bodyweight` tragen. Das JavaScript prüft ebenfalls nur das
    // Feld — der Diskriminator bleibt außen vor.
    final multiplier = session.discipline == 'bodyweight' ? 4.5 : 6.0;
    return _round2(minutes * factor * multiplier);
  }

  /// ## Warum hier der Puls zählt und bei Kraft (noch) nicht
  ///
  /// Cardio geht **ausschliesslich** über Dauer mal Anstrengung mal Sportart
  /// ein — es gibt kein Volumen, das die Anstrengung relativieren würde. Eine
  /// geratene 3 wiegt hier also schwerer als anderswo. Und bei Ausdauer
  /// beschreibt der Puls genau das, wonach gefragt wird: wie hart es war.
  ///
  /// Bei Kraft misst er etwas anderes — eine schwere Kniebeuge treibt ihn
  /// kaum, ein Zirkel dafür weit. Deshalb bleibt [_strength] vorerst bei der
  /// getippten Anstrengung und ihrem Ersatzwert. Der Weg dorthin ist offen:
  /// Es wäre dieselbe eine Zeile, [LoadContext.effortFor]. Was fehlt, ist
  /// nicht der Code, sondern die Begründung.
  static double _cardio(CardioSession session, LoadContext context) {
    final minutes = _minutes(session.duration);
    if (minutes <= 0) return 0;
    final factor = rpeFactor(context.effortFor(session));
    final sport = sportFactor(session.rawActivity ?? session.activity?.wire);
    return _round2(effectiveDuration(minutes) * factor * 4 * sport);
  }

  /// Zählt als aktive Erholung?
  ///
  /// Kurz, leicht, und von einer der drei Arten. **`bodyweight` fehlt in dieser
  /// Liste** — so steht es im JavaScript. Ob Absicht oder Versehen, ist nicht
  /// zu erkennen; die Portierung bildet es ab, statt es stillschweigend zu
  /// korrigieren. Eine Änderung verschöbe jeden historischen Wert.
  static bool isRecovery(TrainingSession session) {
    if ((session.rpe ?? defaultRpe) > 2) return false;

    final minutes = _minutes(session.duration);
    if (minutes <= 0 || minutes > 60) return false;

    return switch (session) {
      CardioSession() || RecoverySession() => true,
      StrengthSession(bodyweight: false) => true,
      _ => false,
    };
  }
}
