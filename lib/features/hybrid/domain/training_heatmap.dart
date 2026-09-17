/// Die Frequenz-Heatmap — Trainingstage der letzten Wochen, Tag für Tag.
///
/// ## Nur Zählung
///
/// Jede Zelle sagt, ob an diesem Tag trainiert wurde und in welcher Spur.
/// Es gibt keine Punkte, keinen Abzug für Pausen und keine Zielmarke — der
/// Masterplan nennt das „Fokus auf Konsistenz, ohne Strafabzüge". Ob 40 von
/// 84 Tagen viel sind, weiss die App nicht.
///
/// ## Raster
///
/// Wochen beginnen am Montag. Die letzte Woche enthält den Stichtag; ihre
/// Tage danach sind [HeatmapDay.isFuture] und zählen in keinem Nenner.
/// Tagesgrenzen lokal — zwischen zwei Mitternachten liegen bei einer
/// Zeitumstellung 23 oder 25 Stunden, deshalb nie aus Millisekunden
/// gerechnet.
library;

import '../../history/domain/training_session.dart';
import 'time_split.dart';

class HeatmapDay {
  const HeatmapDay({
    required this.date,
    required this.tracks,
    required this.minutes,
    required this.isFuture,
  });

  /// Lokale Mitternacht des Tages.
  final DateTime date;

  /// Welche Spuren an diesem Tag vorkamen. Leer heisst: nichts erfasst.
  final Set<TrainingTrack> tracks;

  /// Minuten aller Einheiten des Tages; ohne Dauer nichts.
  final int minutes;

  /// Nach dem Stichtag — steht im Raster, zählt aber in keinem Nenner.
  final bool isFuture;

  bool get trained => tracks.isNotEmpty;
}

class HeatmapWeek {
  const HeatmapWeek({required this.monday, required this.days});

  final DateTime monday;

  /// Genau sieben, Montag bis Sonntag.
  final List<HeatmapDay> days;

  int get trainedDays => days.where((d) => d.trained).length;

  /// Kalenderwoche nach ISO 8601 — die Woche, die den Donnerstag enthält.
  int get isoWeek => TrainingHeatmap.isoWeekOf(monday);
}

class TrainingHeatmap {
  const TrainingHeatmap({required this.weeks});

  /// Älteste zuerst; die letzte Woche enthält den Stichtag.
  final List<HeatmapWeek> weeks;

  int get weekCount => weeks.length;

  Iterable<HeatmapDay> get _pastDays =>
      weeks.expand((w) => w.days).where((d) => !d.isFuture);

  /// Tage mit mindestens einer Einheit, bis einschliesslich Stichtag.
  int get trainedDays => _pastDays.where((d) => d.trained).length;

  /// Der Nenner: alle Tage des Rasters bis einschliesslich Stichtag.
  int get totalDays => _pastDays.length;

  int trainedDaysOf(TrainingTrack track) =>
      _pastDays.where((d) => d.tracks.contains(track)).length;

  static TrainingHeatmap compute(
    List<TrainingSession> sessions,
    DateTime reference, {
    int weeks = 12,
  }) {
    assert(weeks > 0, 'Ein Raster hat mindestens eine Woche.');
    final refDay = DateTime(reference.year, reference.month, reference.day);
    // Montag der Stichtagswoche: weekday ist 1 für Montag.
    final lastMonday =
        DateTime(refDay.year, refDay.month, refDay.day - (refDay.weekday - 1));
    final firstMonday = DateTime(
        lastMonday.year, lastMonday.month, lastMonday.day - 7 * (weeks - 1));

    // Einheiten je Tag einsammeln — Schlüssel ist der lokale Tag.
    final tracksByDay = <DateTime, Set<TrainingTrack>>{};
    final minutesByDay = <DateTime, int>{};
    for (final session in sessions) {
      final track = TrainingTrack.of(session);
      if (track == null) continue;
      final day =
          DateTime(session.date.year, session.date.month, session.date.day);
      if (day.isBefore(firstMonday) || day.isAfter(refDay)) continue;
      tracksByDay.putIfAbsent(day, () => {}).add(track);
      minutesByDay[day] =
          (minutesByDay[day] ?? 0) + (session.duration?.inMinutes ?? 0);
    }

    final result = <HeatmapWeek>[];
    for (var w = 0; w < weeks; w++) {
      final monday = DateTime(
          firstMonday.year, firstMonday.month, firstMonday.day + 7 * w);
      final days = <HeatmapDay>[];
      for (var d = 0; d < 7; d++) {
        final day = DateTime(monday.year, monday.month, monday.day + d);
        days.add(HeatmapDay(
          date: day,
          tracks: Set.unmodifiable(tracksByDay[day] ?? const <TrainingTrack>{}),
          minutes: minutesByDay[day] ?? 0,
          isFuture: day.isAfter(refDay),
        ));
      }
      result.add(HeatmapWeek(monday: monday, days: List.unmodifiable(days)));
    }
    return TrainingHeatmap(weeks: List.unmodifiable(result));
  }

  /// ISO-8601-Kalenderwoche eines Datums.
  static int isoWeekOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    // Der Donnerstag derselben Woche entscheidet über das Jahr.
    final thursday = DateTime(day.year, day.month, day.day + (4 - day.weekday));
    final firstOfYear = DateTime(thursday.year, 1, 1);
    // Kalendarischer Abstand in Tagen, nicht aus Millisekunden — siehe oben.
    final dayOfYear = _daysBetween(firstOfYear, thursday) + 1;
    return ((dayOfYear - 1) ~/ 7) + 1;
  }

  static int _daysBetween(DateTime from, DateTime to) =>
      (DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays);
}
