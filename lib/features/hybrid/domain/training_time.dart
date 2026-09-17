/// Trainingszeit je Spur — **eine** Rechnung für „Diese Woche" und „28 Tage".
///
/// ## Warum es sie gibt (17.09.2026)
///
/// Bis dahin standen auf dem Hybrid-Tab zwei Blöcke: das Verhältnis (Kraft
/// gegen Ausdauer, diese Woche, mit Verschiebung) und die Trainingszeit (drei
/// Spuren, 14 oder 28 Tage). Beide teilten Minuten auf Spuren auf — der Nutzer
/// las darin zweimal dieselbe Aussage. Jetzt gibt es einen Block mit zwei
/// Fenstern, und beide Fenster rechnen gleich: drei Spuren, Anteil an allen
/// Minuten.
///
/// ## Was sich gegenüber dem Verhältnis ändert
///
/// Das Verhältnis liess Regeneration aus (Board 11, C1). Im zusammengeführten
/// Block zählt sie mit, wie in der Trainingszeit — sonst zeigten die zwei
/// Fenster desselben Blocks verschiedene Nenner. Regeneration trägt weiterhin
/// **keine Last**; hier geht es nur um Zeit.
///
/// ## Fachgrösse je Spur
///
/// Unter jeder Spur steht, woraus die Minuten bestanden: Sätze und Tonnage bei
/// Kraft, Kilometer bei Cardio. Eine Grösse, die 0 ist, wird nicht geführt —
/// „0 t Volumen" bei Klimmzügen ohne Zusatzlast wäre eine Messung, die nie
/// stattfand. Aufwärmsätze zählen nicht, wie in „Sätze je Woche".
library;

import '../../cardio/domain/iso_week.dart';
import '../../history/domain/training_session.dart';
import 'time_split.dart';

/// Die zwei Fenster des Blocks.
enum TrainingTimeWindow { week, days28 }

/// Eine Spur im Fenster.
class TrackTotals {
  const TrackTotals({
    required this.track,
    required this.minutes,
    required this.count,
    this.sets = 0,
    this.tonnageKg = 0,
    this.km = 0,
  });

  final TrainingTrack track;
  final int minutes;

  /// Einheiten der Spur, auch die ohne Dauer.
  final int count;

  /// Nur Kraft: Arbeitssätze ohne Aufwärmsätze.
  final int sets;

  /// Nur Kraft: Summe aus Wiederholungen × Gewicht, nur Sätze mit Gewicht.
  final double tonnageKg;

  /// Nur Cardio.
  final double km;
}

class TrainingTime {
  const TrainingTime({
    required this.window,
    required this.start,
    required this.end,
    required this.tracks,
    required this.sessionsWithoutDuration,
    this.shiftPp = const {},
  });

  /// Wie viele volle Vorwochen der Vergleich braucht — wie beim Verhältnis.
  static const shiftWeeks = 4;

  final TrainingTimeWindow window;

  /// Erster Tag des Fensters, 00:00 lokal.
  final DateTime start;

  /// Erster Tag **nach** dem Fenster, 00:00 lokal.
  final DateTime end;

  /// Immer alle drei Spuren, in der Reihenfolge von [TrainingTrack].
  final List<TrackTotals> tracks;

  final int sessionsWithoutDuration;

  /// Nur im Wochenfenster: Verschiebung des Anteils je Spur gegen den
  /// mittleren Anteil der Vorwochen, in Prozentpunkten. Leer, wenn es keinen
  /// Vergleich gibt — „kein 4-Wochen-Schnitt", nicht 0.
  final Map<TrainingTrack, double> shiftPp;

  int get totalMinutes => tracks.fold(0, (sum, t) => sum + t.minutes);
  int get totalCount => tracks.fold(0, (sum, t) => sum + t.count);
  bool get isEmpty => totalMinutes == 0;
  bool get hasShift => shiftPp.isNotEmpty;

  TrackTotals of(TrainingTrack track) =>
      tracks.firstWhere((t) => t.track == track);

  /// Anteil an allen Minuten, gerundet; 0 ohne Minuten.
  int percentOf(TrainingTrack track) =>
      totalMinutes == 0 ? 0 : (of(track).minutes * 100 / totalMinutes).round();

  /// Die Kalenderwoche des Wochenfensters.
  int get isoWeek => IsoWeek.number(start);

  static TrainingTime compute(
    List<TrainingSession> sessions,
    DateTime reference,
    TrainingTimeWindow window,
  ) {
    final refDay = DateTime(reference.year, reference.month, reference.day);
    switch (window) {
      case TrainingTimeWindow.days28:
        return _range(
          sessions,
          window,
          DateTime(refDay.year, refDay.month, refDay.day - 27),
          DateTime(refDay.year, refDay.month, refDay.day + 1),
        );
      case TrainingTimeWindow.week:
        final weekStart = IsoWeek.start(refDay);
        final current = _range(
          sessions,
          window,
          weekStart,
          DateTime(weekStart.year, weekStart.month, weekStart.day + 7),
        );
        return TrainingTime(
          window: window,
          start: current.start,
          end: current.end,
          tracks: current.tracks,
          sessionsWithoutDuration: current.sessionsWithoutDuration,
          shiftPp: _shift(sessions, weekStart, current),
        );
    }
  }

  /// Verschiebung gegen die Vorwochen. Wie beim Verhältnis: nur, wenn die
  /// Geschichte vier volle Wochen zurückreicht; Wochen ohne Minuten gehen
  /// nicht in den Schnitt, weil ein Anteil an null Minuten keine Zahl ist.
  static Map<TrainingTrack, double> _shift(
    List<TrainingSession> sessions,
    DateTime weekStart,
    TrainingTime current,
  ) {
    if (current.isEmpty) return const {};
    DateTime? first;
    for (final s in sessions) {
      if (TrainingTrack.of(s) == null) continue;
      if (first == null || s.date.isBefore(first)) first = s.date;
    }
    final windowStart = DateTime(
        weekStart.year, weekStart.month, weekStart.day - 7 * shiftWeeks);
    // Massgeblich ist die **Woche** der ersten Einheit: Liegt sie in der
    // vierten Vorwoche, reicht die Geschichte vier Wochen zurück — auch wenn
    // die erste Einheit ein Dienstag war.
    if (first == null || IsoWeek.start(first).isAfter(windowStart)) {
      return const {};
    }

    final sums = {for (final t in TrainingTrack.values) t: 0.0};
    var weeks = 0;
    for (var i = 1; i <= shiftWeeks; i++) {
      final start =
          DateTime(weekStart.year, weekStart.month, weekStart.day - 7 * i);
      final week = _range(sessions, TrainingTimeWindow.week, start,
          DateTime(start.year, start.month, start.day + 7));
      if (week.isEmpty) continue;
      weeks++;
      for (final t in TrainingTrack.values) {
        sums[t] = sums[t]! + week.of(t).minutes / week.totalMinutes;
      }
    }
    if (weeks == 0) return const {};
    return {
      for (final t in TrainingTrack.values)
        t: (current.of(t).minutes / current.totalMinutes - sums[t]! / weeks) *
            100,
    };
  }

  static TrainingTime _range(
    List<TrainingSession> sessions,
    TrainingTimeWindow window,
    DateTime start,
    DateTime end,
  ) {
    final minutes = {for (final t in TrainingTrack.values) t: 0};
    final counts = {for (final t in TrainingTrack.values) t: 0};
    var sets = 0;
    var tonnage = 0.0;
    var km = 0.0;
    var withoutDuration = 0;

    for (final s in sessions) {
      final track = TrainingTrack.of(s);
      if (track == null) continue;
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      if (day.isBefore(start) || !day.isBefore(end)) continue;
      counts[track] = counts[track]! + 1;
      final duration = s.duration;
      if (duration == null) {
        withoutDuration++;
      } else {
        minutes[track] = minutes[track]! + duration.inMinutes;
      }
      switch (s) {
        case StrengthSession():
          for (final e in s.exercises) {
            for (final set in e.sets) {
              if (set.isEmpty || set.rawType == 'warmup') continue;
              sets++;
              final weight = set.weight ?? 0;
              if (weight > 0) tonnage += (set.reps ?? 0) * weight;
            }
          }
        case CardioSession():
          km += s.distanceKm ?? 0;
        case RecoverySession():
        case UnknownSession():
          break;
      }
    }

    return TrainingTime(
      window: window,
      start: start,
      end: end,
      tracks: [
        for (final t in TrainingTrack.values)
          TrackTotals(
            track: t,
            minutes: minutes[t]!,
            count: counts[t]!,
            sets: t == TrainingTrack.strength ? sets : 0,
            tonnageKg: t == TrainingTrack.strength ? tonnage : 0,
            km: t == TrainingTrack.cardio ? km : 0,
          ),
      ],
      sessionsWithoutDuration: withoutDuration,
    );
  }
}
