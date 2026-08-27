import 'dart:math' as math;

import 'training_session.dart';

/// Was die Lastberechnung von außen braucht.
///
/// Im JavaScript hängt `calculateSessionLoadValue` an zwei globalen Variablen:
/// `userProfile.bodyWeight` und `allExercises`. Global heißt hier: nicht
/// testbar, nicht nachvollziehbar, und beim Laden in falscher Reihenfolge
/// stillschweigend leer. In Dart sind es Parameter.
class LoadContext {
  const LoadContext(
      {this.bodyWeightKg = 0, this.bodyweightExerciseIds = const {}});

  /// Körpergewicht in Kilogramm, 0 wenn unbekannt.
  ///
  /// Ist es 0, liefern Körpergewichtsübungen ein Volumen von 0 — dann greift
  /// die Ersatzrechnung nach Dauer. Das ist im JavaScript so angelegt und wird
  /// hier bewusst übernommen.
  final double bodyWeightKg;

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
/// direkt mit denen des JavaScripts (siehe `tool/scoring_oracle.mjs`).
abstract final class TrainingLoad {
  /// Faktoren der Anstrengung. Die Skala reicht **1 bis 5**, nicht 1 bis 10 —
  /// im Bestand kommen 1 bis 4 vor.
  static const _rpeFactors = {1: 0.6, 2: 0.8, 3: 1.0, 4: 1.2, 5: 1.4};

  /// Sportarten-Faktoren für Cardio. `swim` und `row` stehen im JavaScript,
  /// kommen im Bestand aber nicht vor.
  static const _sportFactors = {
    'run': 1.0,
    'bike': 0.85,
    'swim': 0.9,
    'hike': 0.4,
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
  static const _defaultRpe = 3;

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
        CardioSession() => _cardio(session),
        // Regeneration und Unbekanntes tragen keine Last. Regeneration wirkt
        // trotzdem — über den Erholungsbonus im ACWR, nicht über die Last.
        RecoverySession() || UnknownSession() => 0,
      };

  static double _strength(StrengthSession session, LoadContext context) {
    final factor = rpeFactor(session.rpe ?? _defaultRpe);

    // Ohne Übungen: Ersatzrechnung nach Dauer (Schnellerfassung).
    if (session.exercises.isEmpty) {
      return _durationFallback(session, factor);
    }

    var totalVolume = 0.0;
    for (final exercise in session.exercises) {
      final usesBodyweight = exercise.usesBodyweight ??
          context.bodyweightExerciseIds.contains(exercise.exerciseId);

      for (final set in exercise.sets) {
        final reps = set.reps ?? 0;
        if (reps <= 0) continue;
        final weight =
            usesBodyweight ? context.bodyWeightKg : (set.weight ?? 0);
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

  static double _cardio(CardioSession session) {
    final minutes = _minutes(session.duration);
    if (minutes <= 0) return 0;
    final factor = rpeFactor(session.rpe ?? _defaultRpe);
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
    if ((session.rpe ?? _defaultRpe) > 2) return false;

    final minutes = _minutes(session.duration);
    if (minutes <= 0 || minutes > 60) return false;

    return switch (session) {
      CardioSession() || RecoverySession() => true,
      StrengthSession(bodyweight: false) => true,
      _ => false,
    };
  }
}
