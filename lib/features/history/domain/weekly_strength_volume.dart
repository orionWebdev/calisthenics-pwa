/// Sätze je Woche — „Trainiere ich gerade mehr oder weniger als sonst?"
///
/// ## Das Muster der Wochenkilometer, auf Sätze
///
/// Dieselbe Frage, die `WeeklyDistance` für Cardio beantwortet, hier in der
/// Grösse, die jede Krafteinheit mit Übungen trägt: Sätze. Nicht Tonnage — bei
/// Calisthenics ist das Gewicht meist leer, eine Tonnagezahl wäre für diese
/// Einheiten 0 und behauptete, es sei nichts passiert.
///
/// ## Der Schnitt zählt nur Wochen seit Beginn
///
/// Die Verschiebung vergleicht die laufende Woche mit den vier vollen Wochen
/// davor. Liegt ein Teil davon **vor** der ersten Krafteinheit, fällt er aus
/// dem Nenner: Nach einem Neubeginn drückten sonst Wochen, in denen die App
/// noch gar nicht benutzt wurde, den Schnitt nach unten, und jede zweite Woche
/// sähe aus wie ein Sprung nach oben.
///
/// Einen Vergleich gibt es erst ab [minimumComparisonWeeks] vollen Vorwochen
/// seit Beginn. Ein „Schnitt" aus einer einzigen Woche wäre nur diese Woche.
///
/// ## Was nicht zählt
///
/// Aufwärmsätze (`rawType == 'warmup'`, der Wert, den der Runner schreibt).
/// Einheiten ohne Sätze zählen als Einheit, tragen aber keinen Satz — sie
/// werden getrennt gezählt, damit die Oberfläche sie nennen kann.
///
/// Wochen beginnen am Montag, Tagesgrenzen lokal. Nie aus Millisekunden
/// gerechnet: Bei einer Zeitumstellung liegen zwischen zwei Mitternachten 23
/// oder 25 Stunden.
library;

import '../../cardio/domain/iso_week.dart';
import 'set_counting.dart';
import 'training_session.dart';

/// Eine Woche im Streifen.
class WeekSets {
  const WeekSets({
    required this.weekStart,
    required this.sets,
    required this.sessions,
    required this.sessionsWithoutSets,
    required this.isCurrent,
    required this.beforeStart,
  });

  /// Montag der Woche, lokale Mitternacht.
  final DateTime weekStart;

  /// Sätze ohne Aufwärmsätze.
  final int sets;

  /// Krafteinheiten der Woche, mit und ohne Sätze.
  final int sessions;

  /// Davon ohne einen einzigen zählbaren Satz.
  final int sessionsWithoutSets;

  /// Die laufende, noch unfertige Woche.
  final bool isCurrent;

  /// Liegt vor der Woche der ersten Krafteinheit — nicht gemessen, nicht 0.
  final bool beforeStart;

  /// Gemessen, aber ohne Satz: der 2-dp-Strich.
  bool get isEmpty => !beforeStart && sets == 0;

  int get isoWeek => IsoWeek.number(weekStart);
}

class WeeklyStrengthVolume {
  const WeeklyStrengthVolume({
    required this.weeks,
    required this.firstSessionDate,
    required this.hasSets,
    required this.comparisonWeeks,
    this.fourWeekAverage,
  });

  static const stripWeeks = 8;

  /// Die Verschiebung vergleicht mit so vielen vollen Wochen davor.
  static const shiftWeeks = 4;

  /// Ab so vielen vollen Vorwochen seit Beginn gibt es einen Vergleich.
  static const minimumComparisonWeeks = 2;

  static const warmupType = 'warmup';

  static const empty = WeeklyStrengthVolume(
    weeks: [],
    firstSessionDate: null,
    hasSets: false,
    comparisonWeeks: 0,
  );

  /// Älteste zuerst, die letzte ist die laufende Woche.
  final List<WeekSets> weeks;

  /// Datum der ersten Krafteinheit überhaupt.
  final DateTime? firstSessionDate;

  /// Es gibt mindestens eine Krafteinheit mit einem zählbaren Satz — die
  /// Schwelle des Blocks.
  final bool hasSets;

  /// Volle Vorwochen seit Beginn, die in den Schnitt eingehen (0 bis 4).
  final int comparisonWeeks;

  /// Schnitt über [comparisonWeeks] Wochen; `null` ohne Vergleich.
  final double? fourWeekAverage;

  bool get hasComparison => fourWeekAverage != null;

  /// Wie viele volle Wochen bis zum ersten Vergleich noch fehlen.
  int get weeksUntilComparison => (minimumComparisonWeeks - comparisonWeeks)
      .clamp(0, minimumComparisonWeeks);

  WeekSets? get current => weeks.isEmpty ? null : weeks.last;

  int get currentSets => current?.sets ?? 0;
  int get currentSessions => current?.sessions ?? 0;

  /// Verschiebung der laufenden Woche gegen den Schnitt, in Sätzen.
  double? get shift =>
      fourWeekAverage == null ? null : currentSets - fourWeekAverage!;

  /// Einheiten ohne Sätze im ganzen Streifen.
  int get sessionsWithoutSets =>
      weeks.fold(0, (total, w) => total + w.sessionsWithoutSets);

  int get peakSets => weeks.fold(0, (m, w) => w.sets > m ? w.sets : m);

  /// Zählbar ist jeder Satz ausser dem Aufwärmsatz.
  static bool countsSet(LoggedSet set) => set.rawType != warmupType;

  static WeeklyStrengthVolume compute(
    List<TrainingSession> sessions,
    DateTime reference, {
    int weeks = stripWeeks,
  }) {
    final refDay = DateTime(reference.year, reference.month, reference.day);
    final end = DateTime(refDay.year, refDay.month, refDay.day + 1);

    final strength = [
      for (final s in sessions)
        if (s is StrengthSession && s.date.isBefore(end)) s,
    ];
    if (strength.isEmpty) return empty;

    final setsByWeek = <String, int>{};
    final sessionsByWeek = <String, int>{};
    final withoutByWeek = <String, int>{};
    DateTime? first;
    var hasSets = false;

    for (final s in strength) {
      final key = IsoWeek.key(s.date);
      var count = 0;
      for (final exercise in s.exercises) {
        // Seitengetrennte Sätze nach [SetCounting]: ein Paar links/rechts ist
        // ein Satz, nicht zwei.
        count += SetCounting.count(exercise.sets, include: countsSet);
      }
      if (count > 0) hasSets = true;
      setsByWeek[key] = (setsByWeek[key] ?? 0) + count;
      sessionsByWeek[key] = (sessionsByWeek[key] ?? 0) + 1;
      if (count == 0) withoutByWeek[key] = (withoutByWeek[key] ?? 0) + 1;
      if (first == null || s.date.isBefore(first)) first = s.date;
    }

    final startWeek = IsoWeek.start(first!);
    final currentStart = IsoWeek.start(refDay);

    DateTime weekAt(int back) => DateTime(
        currentStart.year, currentStart.month, currentStart.day - 7 * back);

    final strip = <WeekSets>[
      for (var i = weeks - 1; i >= 0; i--)
        _week(weekAt(i), i == 0, startWeek, setsByWeek, sessionsByWeek,
            withoutByWeek),
    ];

    // Vier volle Wochen vor der laufenden — nur die seit Beginn.
    var counted = 0;
    var sum = 0;
    for (var i = 1; i <= shiftWeeks; i++) {
      final start = weekAt(i);
      if (start.isBefore(startWeek)) continue;
      counted++;
      sum += setsByWeek[IsoWeek.key(start)] ?? 0;
    }

    return WeeklyStrengthVolume(
      weeks: strip,
      firstSessionDate: first,
      hasSets: hasSets,
      comparisonWeeks: counted,
      fourWeekAverage: counted >= minimumComparisonWeeks ? sum / counted : null,
    );
  }

  static WeekSets _week(
    DateTime start,
    bool isCurrent,
    DateTime startWeek,
    Map<String, int> sets,
    Map<String, int> sessions,
    Map<String, int> without,
  ) {
    final key = IsoWeek.key(start);
    return WeekSets(
      weekStart: start,
      sets: sets[key] ?? 0,
      sessions: sessions[key] ?? 0,
      sessionsWithoutSets: without[key] ?? 0,
      isCurrent: isCurrent,
      beforeStart: start.isBefore(startWeek),
    );
  }
}
