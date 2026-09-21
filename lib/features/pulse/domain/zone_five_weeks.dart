import 'dart:math' as math;

import '../../../core/domain/pulse_profile.dart';
import '../../cardio/domain/iso_week.dart';
import 'heart_rate_zones.dart';

/// Ein Pulsverlauf mit dem Zeitpunkt seiner Einheit — **neutral**, ohne den
/// Datensatz aus dem Import.
///
/// Die Auswertung kennt den Import nicht und soll es nicht: Sie bekommt, was
/// sie rechnet, als Zeitpunkt und Verlauf.
class PulseRecord {
  const PulseRecord({required this.start, required this.pulse});

  final DateTime start;
  final PulseProfile pulse;
}

/// Eine Woche im Zone-5-Streifen.
class ZoneWeek {
  const ZoneWeek({
    required this.weekStart,
    required this.zone5Seconds,
    required this.sessions,
    required this.isCurrent,
  });

  /// Montag der Woche, lokale Mitternacht.
  final DateTime weekStart;

  /// Sekunden in Zone 5, summiert über die Einheiten mit Puls dieser Woche.
  final int zone5Seconds;

  /// Einheiten dieser Woche, **die einen Puls tragen**.
  final int sessions;

  final bool isCurrent;

  /// Ob in dieser Woche überhaupt Puls gemessen wurde.
  ///
  /// „Gemessen, 0 Minuten in Zone 5" und „nichts gemessen" sind verschiedene
  /// Aussagen. Die erste ist eine Tatsache über den Puls, die zweite sagt
  /// über ihn nichts — und bekommt deshalb kein Zeichen im Streifen, keinen
  /// Strich, der eine Pause behauptete.
  bool get measured => sessions > 0;

  int get minutes => (zone5Seconds / 60).round();
  int get isoWeek => IsoWeek.number(weekStart);
}

/// **Zone 5 je Woche** — die Zeit im obersten Pulsbereich, acht Wochen lang
/// (Auswertung, auf Wunsch vom 21.09.2026).
///
/// ## Was sie sagt und was nicht
///
/// Sie beschreibt, was war: Minuten, in denen der Puls oberhalb der fünften
/// Grenze lag. Sie vergleicht **nicht** mit einem Schnitt und nennt keinen
/// Sollwert. Mehr Zeit in Zone 5 ist nicht besser, weniger nicht schlechter —
/// die App weiss nicht, wie viel richtig ist (CLAUDE.md: kein Sollverhältnis,
/// kein Urteil).
///
/// ## Jede Zahl nennt ihre Grundlage
///
/// Puls gibt es nur für Einheiten aus der Uhr. Deshalb steht neben der Zahl
/// immer, **aus wie vielen** Einheiten sie gerechnet ist — „aus 4 von 14".
/// Ein Streifen, der nur die Einheiten mit Puls zählte und das verschwiege,
/// behauptete, die anderen hätten keine Zeit in Zone 5 gehabt.
///
/// ## Wochen ohne Puls
///
/// Bleiben ohne Zeichen. Keine Interpolation über Wochen ohne Ereignis, und
/// kein „0", das eine Messung vortäuschte, die es nie gab.
class ZoneFiveWeeks {
  const ZoneFiveWeeks({
    required this.weeks,
    required this.sessionsWithPulse,
    required this.sessionsInWindow,
  });

  static const stripWeeks = 8;

  final List<ZoneWeek> weeks;

  /// Einheiten im ganzen Streifen, die einen Puls tragen — der Zähler.
  final int sessionsWithPulse;

  /// Alle Einheiten im ganzen Streifen — der Nenner.
  final int sessionsInWindow;

  /// Es gibt mindestens eine Einheit mit Puls: die Schwelle des Blocks.
  bool get hasPulse => sessionsWithPulse > 0;

  ZoneWeek? get current => weeks.isEmpty ? null : weeks.last;

  /// Die längste Woche in Sekunden — der Bezug der Balkenhöhe.
  int get peakSeconds =>
      weeks.fold(0, (m, w) => w.zone5Seconds > m ? w.zone5Seconds : m);

  /// [records]: die Einheiten mit Puls. [sessionDates]: **alle** Einheiten,
  /// mit und ohne Puls — nur ihre Zahl im Zeitraum geht ein, als Nenner.
  static ZoneFiveWeeks compute({
    required List<PulseRecord> records,
    required List<DateTime> sessionDates,
    required HeartRateZones zones,
    required DateTime reference,
    int weeks = stripWeeks,
  }) {
    final refDay = DateTime(reference.year, reference.month, reference.day);
    final currentStart = IsoWeek.start(refDay);
    DateTime weekAt(int back) => DateTime(
        currentStart.year, currentStart.month, currentStart.day - 7 * back);

    final windowStart = weekAt(weeks - 1);
    final windowEnd = DateTime(refDay.year, refDay.month, refDay.day + 1);

    final seconds = <String, int>{};
    final sessions = <String, int>{};
    var withPulse = 0;

    for (final r in records) {
      if (r.start.isBefore(windowStart) || !r.start.isBefore(windowEnd)) {
        continue;
      }
      final distribution = ZoneDistribution.of(
        secondsByBpm: r.pulse.secondsByBpm,
        windowSeconds: r.pulse.windowSeconds,
        zones: zones,
      );
      final key = IsoWeek.key(r.start);
      seconds[key] = (seconds[key] ?? 0) +
          distribution.secondsPerZone[HeartRateZones.zoneCount - 1];
      sessions[key] = (sessions[key] ?? 0) + 1;
      withPulse++;
    }

    return ZoneFiveWeeks(
      weeks: [
        for (var i = weeks - 1; i >= 0; i--)
          ZoneWeek(
            weekStart: weekAt(i),
            zone5Seconds: seconds[IsoWeek.key(weekAt(i))] ?? 0,
            sessions: sessions[IsoWeek.key(weekAt(i))] ?? 0,
            isCurrent: i == 0,
          ),
      ],
      sessionsWithPulse: withPulse,
      // Nie kleiner als der Zähler: Eine übernommene Uhr-Einheit, deren
      // App-Einheit gerade verschwunden ist, stünde sonst als „aus 3 von 2".
      sessionsInWindow: math.max(
        withPulse,
        sessionDates
            .where((d) => !d.isBefore(windowStart) && d.isBefore(windowEnd))
            .length,
      ),
    );
  }
}
