import 'package:meta/meta.dart';

/// Die Uhr einer laufenden Einheit — **an der Wanduhr, nicht am Zähler**.
///
/// ## Warum das vorher falsch war
///
/// Der Runner zählte Sekunden in einem `Timer.periodic`. Wird die App in den
/// Hintergrund geschickt, feuert der Zeitgeber nicht mehr oder wird gedrosselt
/// — der Zähler bleibt stehen, die Zeit läuft weiter. Ein Training von 43
/// Minuten wurde als 15 gespeichert, und zwar **dauerhaft**: Die Dauer geht in
/// Trainingslast, ACWR und Formwert ein.
///
/// Hier steht deshalb kein Zähler, sondern zwei Zeitpunkte. Der Zeitgeber
/// löst nur noch das Neuzeichnen aus; **er misst nichts.** Ob er zwischendurch
/// aussetzt, ändert am Ergebnis nichts.
///
/// ## Pausen
///
/// Pausiert wird durch Merken des Zeitpunkts; beim Fortsetzen wandert die
/// verstrichene Spanne in [_paused]. So bleibt die Rechnung eine Subtraktion
/// und kommt ohne laufende Korrektur aus.
///
/// ## Warum das ein eigener Typ ist
///
/// Er wird gespeichert und wiederhergestellt: Wer die App verlässt und
/// zurückkommt, soll dieselbe Zeit sehen. Und wenn später ein Android-Widget
/// die Pausenzeit anzeigt, liest es dieselben Zeitpunkte — ein Zähler im
/// Bildschirmzustand wäre dafür unerreichbar gewesen.
@immutable
class WorkoutClock {
  const WorkoutClock({
    required this.startedAt,
    this.paused = Duration.zero,
    this.pausedAt,
    this.restEndsAt,
    this.restTotal = Duration.zero,
  });

  factory WorkoutClock.startingAt(DateTime now) =>
      WorkoutClock(startedAt: now);

  /// Wann die Einheit begonnen hat.
  final DateTime startedAt;

  /// Wie lange sie insgesamt schon pausiert war.
  final Duration paused;

  /// Seit wann sie gerade pausiert. `null` heißt: sie läuft.
  final DateTime? pausedAt;

  /// Wann die aktuelle Satzpause endet. `null` heißt: keine läuft.
  final DateTime? restEndsAt;

  /// Wie lang die aktuelle Satzpause insgesamt ist — für den Fortschrittsring.
  final Duration restTotal;

  bool get isPaused => pausedAt != null;
  bool get isResting => restEndsAt != null;

  /// Die verstrichene Trainingszeit.
  Duration elapsed(DateTime now) {
    final running = now.difference(startedAt) - paused;
    final current = pausedAt == null ? Duration.zero : now.difference(pausedAt!);
    final result = running - current;
    // Eine negative Dauer ist nur möglich, wenn die Systemzeit zurückgestellt
    // wurde. Dann null statt einer Zahl mit Minuszeichen.
    return result.isNegative ? Duration.zero : result;
  }

  /// Was von der Satzpause übrig ist. `Duration.zero`, wenn sie vorbei ist.
  Duration restRemaining(DateTime now) {
    final ends = restEndsAt;
    if (ends == null) return Duration.zero;
    final left = ends.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Ist die Pause abgelaufen, während niemand hinsah?
  ///
  /// Genau dafür ist die Wanduhr da: Wer die App während der Pause
  /// weglegt, bekommt beim Zurückkommen nicht eine Pause, die noch neunzig
  /// Sekunden zu laufen glaubt.
  bool restElapsed(DateTime now) =>
      restEndsAt != null && !now.isBefore(restEndsAt!);

  WorkoutClock pause(DateTime now) =>
      isPaused ? this : _copy(pausedAt: now, keepPausedAt: true);

  WorkoutClock resume(DateTime now) {
    final since = pausedAt;
    if (since == null) return this;
    return WorkoutClock(
      startedAt: startedAt,
      paused: paused + now.difference(since),
      restEndsAt: restEndsAt,
      restTotal: restTotal,
    );
  }

  WorkoutClock startRest(DateTime now, Duration length) => WorkoutClock(
        startedAt: startedAt,
        paused: paused,
        pausedAt: pausedAt,
        restEndsAt: now.add(length),
        restTotal: length,
      );

  WorkoutClock stopRest() => WorkoutClock(
        startedAt: startedAt,
        paused: paused,
        pausedAt: pausedAt,
      );

  /// Verlängert oder verkürzt die laufende Pause.
  WorkoutClock shiftRest(Duration by) {
    final ends = restEndsAt;
    if (ends == null) return this;
    return WorkoutClock(
      startedAt: startedAt,
      paused: paused,
      pausedAt: pausedAt,
      restEndsAt: ends.add(by),
      restTotal: restTotal + by,
    );
  }

  WorkoutClock _copy({DateTime? pausedAt, bool keepPausedAt = false}) =>
      WorkoutClock(
        startedAt: startedAt,
        paused: paused,
        pausedAt: keepPausedAt ? pausedAt : this.pausedAt,
        restEndsAt: restEndsAt,
        restTotal: restTotal,
      );

  Map<String, Object?> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'paused': paused.inMilliseconds,
        if (pausedAt != null) 'pausedAt': pausedAt!.toIso8601String(),
        if (restEndsAt != null) 'restEndsAt': restEndsAt!.toIso8601String(),
        'restTotal': restTotal.inMilliseconds,
      };

  static WorkoutClock? fromJson(Map<String, Object?> json) {
    final started = DateTime.tryParse(json['startedAt'] as String? ?? '');
    if (started == null) return null;
    return WorkoutClock(
      startedAt: started,
      paused: Duration(milliseconds: (json['paused'] as num?)?.round() ?? 0),
      pausedAt: DateTime.tryParse(json['pausedAt'] as String? ?? ''),
      restEndsAt: DateTime.tryParse(json['restEndsAt'] as String? ?? ''),
      restTotal:
          Duration(milliseconds: (json['restTotal'] as num?)?.round() ?? 0),
    );
  }
}
