import '../../history/domain/training_session.dart';
import 'iso_week.dart';

/// Eine Woche im Streifen.
class WeekDistance {
  const WeekDistance({
    required this.weekStart,
    required this.km,
    required this.count,
    required this.isCurrent,
  });

  final DateTime weekStart;
  final double km;
  final int count;

  /// Die laufende, noch unfertige Woche — cyan und „laufend" beschriftet,
  /// sonst liest man einen Einbruch, wo nur Dienstag ist.
  final bool isCurrent;

  /// Ohne Einheit: der 2-dp-Balken. „Nichts gemessen" ist etwas anderes als
  /// „gemessen: 0".
  bool get isEmpty => count == 0;
}

/// Wochenkilometer — Board 11, A2 und B3/1.
///
/// ## Zwei Schwellen, beide gezählt
///
/// **Unter 3 Wochen mit Einheiten** gibt es keine Wochenzahl: Eine Woche mit
/// einem Lauf ist kein Trend. Dann steht die Gesamtstrecke mit ihrem
/// Zeitraum. **Unter 4 Wochen Geschichte** gibt es keine Verschiebung: Ein
/// 4-Wochen-Schnitt aus zwei Wochen wäre eine Zahl, die etwas behauptet, was
/// sie nicht ist.
///
/// Leere Wochen zählen im Schnitt mit **0 km** — die Woche fand statt, das
/// Training nicht. Ein Schnitt nur über Wochen mit Training verschwiege die
/// Pausen und behauptete Gleichmass (dieselbe Regel wie beim Monatsstreifen).
class WeeklyDistance {
  const WeeklyDistance({
    required this.weeks,
    required this.thisWeekKm,
    required this.thisWeekCount,
    required this.weeksWithSessions,
    required this.totalKm,
    required this.totalCount,
    required this.countByActivity,
    required this.kmByActivity,
    this.firstDate,
    this.fourWeekAverageKm,
    this.eightWeekAverageKm,
    this.eightWeekCount = 0,
  });

  static const empty = WeeklyDistance(
    weeks: [],
    thisWeekKm: 0,
    thisWeekCount: 0,
    weeksWithSessions: 0,
    totalKm: 0,
    totalCount: 0,
    countByActivity: {},
    kmByActivity: {},
  );

  /// Ab so vielen Wochen mit Einheiten erscheint die Wochenzahl.
  static const minimumWeeks = 3;

  /// So viele volle Wochen Geschichte braucht die Verschiebung.
  static const shiftWeeks = 4;

  /// So viele Wochen zeigt der Streifen.
  static const stripWeeks = 8;

  /// Die letzten [stripWeeks] Wochen, älteste zuerst — auch die leeren.
  final List<WeekDistance> weeks;

  final double thisWeekKm;
  final int thisWeekCount;

  /// Wochen im ganzen Bestand, in denen mindestens eine Einheit liegt.
  final int weeksWithSessions;

  /// Die Wochenzahl darf gezeigt werden.
  bool get hasWeekly => weeksWithSessions >= minimumWeeks;

  /// Gesamtstrecke seit der ersten Einheit — der dünne Zustand.
  final double totalKm;
  final int totalCount;
  final DateTime? firstDate;

  /// Für „3 Läufe Ø 6,2 km".
  final Map<CardioActivity?, int> countByActivity;
  final Map<CardioActivity?, double> kmByActivity;

  /// Schnitt der vier Wochen **vor** der laufenden. `null` unter vier Wochen
  /// Geschichte.
  final double? fourWeekAverageKm;

  /// Verschiebung der laufenden Woche gegen den 4-Wochen-Schnitt.
  double? get shiftKm =>
      fourWeekAverageKm == null ? null : thisWeekKm - fourWeekAverageKm!;

  /// Schnitt über die acht Wochen des Streifens, leere mit 0.
  final double? eightWeekAverageKm;

  /// Einheiten in diesen acht Wochen — der Nenner des Schnitts.
  final int eightWeekCount;

  bool get isEmpty => totalCount == 0;

  static WeeklyDistance compute(
    List<TrainingSession> sessions,
    DateTime reference,
  ) {
    final cardio = sessions.whereType<CardioSession>().toList();
    if (cardio.isEmpty) return WeeklyDistance.empty;

    final kmByWeek = <String, double>{};
    final countByWeek = <String, int>{};
    var totalKm = 0.0;
    DateTime? first;
    final countByActivity = <CardioActivity?, int>{};
    final kmByActivity = <CardioActivity?, double>{};

    for (final s in cardio) {
      final key = IsoWeek.key(s.date);
      final km = s.distanceKm ?? 0;
      kmByWeek[key] = (kmByWeek[key] ?? 0) + km;
      countByWeek[key] = (countByWeek[key] ?? 0) + 1;
      totalKm += km;
      if (first == null || s.date.isBefore(first)) first = s.date;
      countByActivity[s.activity] = (countByActivity[s.activity] ?? 0) + 1;
      kmByActivity[s.activity] = (kmByActivity[s.activity] ?? 0) + km;
    }

    final currentStart = IsoWeek.start(reference);
    final weeks = <WeekDistance>[];
    for (var i = stripWeeks - 1; i >= 0; i--) {
      final start = DateTime(
          currentStart.year, currentStart.month, currentStart.day - 7 * i);
      final key = IsoWeek.key(start);
      weeks.add(WeekDistance(
        weekStart: start,
        km: kmByWeek[key] ?? 0,
        count: countByWeek[key] ?? 0,
        isCurrent: i == 0,
      ));
    }

    // Vier volle Wochen vor der laufenden — nur, wenn die Geschichte so
    // weit zurückreicht.
    final windowStart = DateTime(currentStart.year, currentStart.month,
        currentStart.day - 7 * shiftWeeks);
    double? fourWeek;
    if (!first!.isAfter(windowStart)) {
      var sum = 0.0;
      for (var i = 1; i <= shiftWeeks; i++) {
        final start = DateTime(
            currentStart.year, currentStart.month, currentStart.day - 7 * i);
        sum += kmByWeek[IsoWeek.key(start)] ?? 0;
      }
      fourWeek = sum / shiftWeeks;
    }

    final eightCount = weeks.fold<int>(0, (a, w) => a + w.count);
    final eightKm = weeks.fold<double>(0, (a, w) => a + w.km);

    return WeeklyDistance(
      weeks: weeks,
      thisWeekKm: weeks.last.km,
      thisWeekCount: weeks.last.count,
      weeksWithSessions: countByWeek.length,
      totalKm: totalKm,
      totalCount: cardio.length,
      firstDate: first,
      countByActivity: countByActivity,
      kmByActivity: kmByActivity,
      fourWeekAverageKm: fourWeek,
      eightWeekAverageKm: eightCount == 0 ? null : eightKm / stripWeeks,
      eightWeekCount: eightCount,
    );
  }
}
