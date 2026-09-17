/// Der Zeit-Split — Trainingsminuten je Spur über ein Fenster von Tagen.
///
/// ## Warum Minuten
///
/// Minuten sind die einzige Grösse, die Kraft, Ausdauer und Regeneration
/// wirklich teilen (Board 11, C1). Tonnage und Kilometer lassen sich nicht
/// addieren, ohne eine Umrechnung zu erfinden. Der Split sagt, wie sich die
/// Zeit verteilt hat — nicht, ob das richtig war.
///
/// ## Nenner
///
/// Einheiten ohne Dauer werden gezählt, tragen aber keine Minuten
/// ([TimeSplit.sessionsWithoutDuration]). Die Oberfläche nennt beides, damit
/// „184 min · 4 Einheiten" nicht glatter aussieht, als es ist.
library;

import '../../history/domain/training_session.dart';

/// Die drei Spuren. Kraft umfasst `strength` und `bodyweight`.
enum TrainingTrack {
  strength,
  cardio,
  recovery;

  static TrainingTrack? of(TrainingSession session) => switch (session.kind) {
        SessionKind.strength || SessionKind.bodyweight => strength,
        SessionKind.cardio => cardio,
        SessionKind.recovery => recovery,
        null => null,
      };
}

/// Minuten und Anzahl einer Spur im Fenster.
class TrackTime {
  const TrackTime({
    required this.track,
    required this.minutes,
    required this.count,
  });

  final TrainingTrack track;

  /// Summe der Dauern; Einheiten ohne Dauer tragen nichts bei.
  final int minutes;

  /// Anzahl der Einheiten, auch die ohne Dauer.
  final int count;
}

class TimeSplit {
  const TimeSplit({
    required this.days,
    required this.reference,
    required this.tracks,
    required this.sessionsWithoutDuration,
  });

  /// Länge des Fensters in Kalendertagen.
  final int days;

  /// Der Stichtag — der letzte Tag des Fensters, einschliesslich.
  final DateTime reference;

  /// Immer alle drei, in der Reihenfolge Kraft, Ausdauer, Regeneration.
  final List<TrackTime> tracks;

  /// Einheiten im Fenster ohne Dauer — gezählt, aber ohne Minuten.
  final int sessionsWithoutDuration;

  int get totalMinutes => tracks.fold(0, (sum, t) => sum + t.minutes);

  int get totalCount => tracks.fold(0, (sum, t) => sum + t.count);

  /// Ohne Minuten gibt es keinen Split — der Block rendert dann nicht.
  bool get isEmpty => totalMinutes == 0;

  TrackTime of(TrainingTrack track) =>
      tracks.firstWhere((t) => t.track == track);

  /// Anteil der Spur an den Minuten, gerundet. 0 ohne Minuten.
  int percentOf(TrainingTrack track) {
    final total = totalMinutes;
    if (total == 0) return 0;
    return (of(track).minutes / total * 100).round();
  }

  /// Fenster: die letzten [days] Kalendertage bis einschliesslich [reference].
  /// Tagesgrenzen lokal — nicht aus Millisekunden gerechnet, damit eine
  /// Zeitumstellung die Kante nicht verschiebt.
  static TimeSplit compute(
    List<TrainingSession> sessions,
    DateTime reference, {
    required int days,
  }) {
    assert(days > 0, 'Ein Fenster hat mindestens einen Tag.');
    final refDay = DateTime(reference.year, reference.month, reference.day);
    final start = DateTime(refDay.year, refDay.month, refDay.day - (days - 1));

    final minutes = {for (final t in TrainingTrack.values) t: 0};
    final counts = {for (final t in TrainingTrack.values) t: 0};
    var withoutDuration = 0;

    for (final session in sessions) {
      final track = TrainingTrack.of(session);
      if (track == null) continue;
      final day =
          DateTime(session.date.year, session.date.month, session.date.day);
      if (day.isBefore(start) || day.isAfter(refDay)) continue;
      counts[track] = counts[track]! + 1;
      final duration = session.duration;
      if (duration == null) {
        withoutDuration++;
      } else {
        minutes[track] = minutes[track]! + duration.inMinutes;
      }
    }

    return TimeSplit(
      days: days,
      reference: refDay,
      tracks: [
        for (final t in TrainingTrack.values)
          TrackTime(track: t, minutes: minutes[t]!, count: counts[t]!),
      ],
      sessionsWithoutDuration: withoutDuration,
    );
  }
}
