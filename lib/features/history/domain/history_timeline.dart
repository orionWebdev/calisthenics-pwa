import 'data_sufficiency.dart';
import 'readiness.dart';
import 'training_session.dart';

/// Ein Eintrag der Verlaufsliste — Einheit, Lücke oder Monatskopf.
///
/// Eine Liste aus nur Einheiten wäre unehrlich: Sie reiht die Trainingstage
/// aneinander und lässt die Pausen dazwischen verschwinden. Die Lücke bekommt
/// deshalb eine eigene Zeile.
sealed class TimelineEntry {
  const TimelineEntry();
}

/// Ein Monatswechsel.
final class MonthHeader extends TimelineEntry {
  const MonthHeader({
    required this.year,
    required this.month,
    required this.sessions,
    required this.load,
  });

  final int year;
  final int month;
  final int sessions;

  /// Aufsummierte Rohlast des Monats, gerundet.
  final int load;
}

/// Eine absolvierte Einheit.
final class TimelineSession extends TimelineEntry {
  const TimelineSession({
    required this.session,
    this.ordinalOnDay,
    this.load = 0,
    this.monthMaxLoad = 0,
  });

  final TrainingSession session;

  /// `null` bei der einzigen Einheit des Tages, sonst 2, 3 … für die
  /// nachfolgenden. Im Bestand kommt das an 21 Tagen vor.
  final int? ordinalOnDay;

  /// Die Rohlast dieser Einheit — rechts in der Zeile, mit Mini-Balken.
  final double load;

  /// Der höchste Wert im selben Monat: der Balken ist relativ dazu, nicht zu
  /// einem Sollwert (Board 06, Spezifikation Verlaufszeile).
  final double monthMaxLoad;
}

/// Eine Unterbrechung ab sieben Tagen.
final class TimelineGap extends TimelineEntry {
  const TimelineGap({
    required this.days,
    required this.from,
    required this.to,
    required this.isLongest,
    this.isOpen = false,
  });

  final int days;

  /// Der Tag **nach** der letzten Einheit bis zum Tag **vor** der nächsten.
  final DateTime from;
  final DateTime to;

  /// Die längste Pause im gesamten Verlauf. Sie wird eigens benannt — eine
  /// Zahl allein sagt nicht, ob 74 Tage viel sind.
  final bool isLongest;

  /// Die Pause **seit der letzten Einheit bis heute** (Board 06, A2/1:
  /// „50 Tage ohne Training · 09.07. – heute"). Sie steht ganz oben, vor dem
  /// ersten Monat, und zählt nie als längste: Sie ist noch nicht zu Ende.
  final bool isOpen;
}

/// Das Ende: die erste aufgezeichnete Einheit.
final class TimelineEnd extends TimelineEntry {
  const TimelineEnd({required this.first, required this.daysAgo});

  final DateTime first;
  final int daysAgo;
}

/// Baut die Liste von neu nach alt.
abstract final class HistoryTimeline {
  static List<TimelineEntry> build(
    List<TrainingSession> sessions,
    DateTime reference, {
    Map<String, double> loadByDay = const {},
    double Function(TrainingSession)? loadOf,
  }) {
    if (sessions.isEmpty) return const [];

    final sorted = [...sessions]..sort((a, b) => b.date.compareTo(a.date));
    final longest = DataSufficiency.longestGapDays(sessions);
    double load(TrainingSession s) => loadOf?.call(s) ?? 0;

    // Wie oft trat ein Tag auf? Für die Kennzeichnung der Mehrfachtage.
    final perDay = <String, int>{};
    for (final s in sorted) {
      final key = Readiness.dayKey(s.date);
      perDay[key] = (perDay[key] ?? 0) + 1;
    }
    final seenOnDay = <String, int>{};

    final entries = <TimelineEntry>[];
    int? currentYear;
    int? currentMonth;

    // Die offene Lücke: Was seit der letzten Einheit vergangen ist, gehört
    // genauso in die Liste wie die Pausen dazwischen — sonst sähe ein Verlauf
    // mit 50 Tagen Stille aus, als wäre gestern trainiert worden.
    final sinceLast = _days(sorted.first.date, reference);
    if (sinceLast >= DataSufficiency.gapDays) {
      entries.add(TimelineGap(
        days: sinceLast,
        from: _dayAfter(sorted.first.date),
        to: DateTime(reference.year, reference.month, reference.day),
        isLongest: false,
        isOpen: true,
      ));
    }

    for (var i = 0; i < sorted.length; i++) {
      final session = sorted[i];

      if (session.date.year != currentYear ||
          session.date.month != currentMonth) {
        currentYear = session.date.year;
        currentMonth = session.date.month;
        final inMonth = sorted.where(
            (s) => s.date.year == currentYear && s.date.month == currentMonth);
        entries.add(MonthHeader(
          year: currentYear,
          month: currentMonth,
          sessions: inMonth.length,
          load: inMonth
              .map((s) => loadByDay[Readiness.dayKey(s.date)] ?? 0)
              .fold<double>(0, (a, b) => a + b)
              .round(),
        ));
      }

      final key = Readiness.dayKey(session.date);
      final count = perDay[key] ?? 1;
      // Von neu nach alt gezählt: Die zuletzt erfasste Einheit des Tages ist
      // die höchste Nummer.
      final index = (seenOnDay[key] = (seenOnDay[key] ?? 0) + 1);
      final monthMax = sorted
          .where(
              (s) => s.date.year == currentYear && s.date.month == currentMonth)
          .map(load)
          .fold<double>(0, (a, b) => b > a ? b : a);
      entries.add(TimelineSession(
        session: session,
        ordinalOnDay: count > 1 ? count - index + 1 : null,
        load: load(session),
        monthMaxLoad: monthMax,
      ));

      // Die Lücke zur nächstälteren Einheit.
      if (i + 1 < sorted.length) {
        final older = sorted[i + 1];
        final days = _days(older.date, session.date);
        if (days >= DataSufficiency.gapDays) {
          entries.add(TimelineGap(
            days: days,
            from: _dayAfter(older.date),
            to: _dayBefore(session.date),
            isLongest: longest != null && days == longest,
          ));
        }
      }
    }

    final first = sorted.last.date;
    entries.add(TimelineEnd(first: first, daysAgo: _days(first, reference)));
    return entries;
  }

  static int _days(DateTime from, DateTime to) =>
      (DateTime(to.year, to.month, to.day)
                  .difference(DateTime(from.year, from.month, from.day))
                  .inHours /
              24)
          .round();

  static DateTime _dayAfter(DateTime d) => DateTime(d.year, d.month, d.day + 1);
  static DateTime _dayBefore(DateTime d) =>
      DateTime(d.year, d.month, d.day - 1);
}
