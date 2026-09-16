import 'data_sufficiency.dart';
import 'readiness.dart';
import 'training_load.dart';
import 'training_session.dart';

/// Wie es gerade um das Training steht — abgeleitet **allein aus dem Abstand
/// zur letzten Einheit**.
///
/// Nicht aus dem Form-Wert: Der ist eine Rechnung mit fünf Bestandteilen und
/// beantwortet „wo stehe ich?". Die Zone beantwortet „was ist gerade los?", und
/// dafür gibt es genau eine ehrliche Zahl — wie lange es her ist.
enum HistoryZone {
  /// Bis 3 Tage. Die Aussage ist die Frequenz, nicht der Abstand.
  rhythm(0, 3),

  /// 4 bis 6 Tage. Kein Alarm, nur eine Feststellung.
  recent(4, 6),

  /// 7 bis 27 Tage. Ab hier erscheinen Lückenstreifen auch in der Liste.
  pause(7, 27),

  /// Ab 28 Tagen. Das akute Fenster ist leer — der ACWR entfällt, statt 0,00
  /// zu behaupten.
  inactive(28, null);

  const HistoryZone(this.fromDays, this.toDays);

  final int fromDays;
  final int? toDays;

  static HistoryZone forDays(int days) {
    for (final zone in values) {
      final to = zone.toDays;
      if (days >= zone.fromDays && (to == null || days <= to)) return zone;
    }
    return HistoryZone.inactive;
  }

  /// Zeigt diese Zone ein Belastungsverhältnis?
  ///
  /// In [inactive] nicht: Ohne Training in den letzten vier Wochen ist das
  /// akute Fenster leer, und ein Verhältnis aus zwei nahezu leeren Fenstern
  /// ist keine Aussage, sondern eine Division.
  bool get showsAcwr => this != HistoryZone.inactive;
}

/// Ein Monat im Streifen.
class MonthCount {
  const MonthCount(
      {required this.year, required this.month, required this.count});

  final int year;
  final int month;
  final int count;

  bool get isEmpty => count == 0;
}

/// Alles, was der Verlaufs-Tab braucht — an einer Stelle gerechnet.
class HistorySummary {
  const HistorySummary({
    required this.sessions,
    required this.zone,
    required this.daysSinceLast,
    required this.months,
    this.trainingDays = 0,
    this.spanDays = 0,
    this.lastSession,
    this.sessionsInWindow,
    this.windowDays,
    this.medianGapDays,
    this.longestGapDays,
    this.acwr,
  });

  static const empty = HistorySummary(
    sessions: 0,
    zone: HistoryZone.inactive,
    daysSinceLast: null,
    months: [],
  );

  final int sessions;
  final HistoryZone zone;

  /// `null`, solange es keine einzige Einheit gibt.
  final int? daysSinceLast;

  final TrainingSession? lastSession;

  /// Für die Frequenzaussage im Rhythmus: „7 Einheiten in 14 Tagen".
  final int? sessionsInWindow;
  final int? windowDays;

  /// **Median, nicht Durchschnitt.** Im Bestand steht 1 Einheit im November und
  /// 30 im Mai; „alle 2,2 Tage" beschreibt keinen realen Monat.
  final int? medianGapDays;
  final int? longestGapDays;

  /// Alle Monate zwischen der ersten und der letzten Einheit — **einschließlich
  /// der leeren**. Ein Streifen, der nur Monate mit Training zeigt, verschweigt
  /// die Pausen und behauptet damit Gleichmaß.
  final List<MonthCount> months;

  /// Tage mit mindestens einer Einheit — die Grundlage der Konstanz.
  final int trainingDays;

  /// Tage von der ersten Einheit bis heute.
  final int spanDays;


  /// `null`, wenn die Datenlage nicht reicht oder die Zone untätig ist.
  final AcwrResult? acwr;

  bool get isEmpty => sessions == 0;

  /// Die Frequenzaussage gilt nur im Rhythmus.
  bool get showsFrequency =>
      zone == HistoryZone.rhythm && sessionsInWindow != null;

  static HistorySummary from(
    List<TrainingSession> sessions,
    DateTime reference, {
    LoadContext context = const LoadContext(),
  }) {
    if (sessions.isEmpty) return HistorySummary.empty;

    final days = DataSufficiency.daysSinceLast(sessions, reference);
    final zone = HistoryZone.forDays(days ?? 9999);

    final last = sessions.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

    // Für die Frequenz: die letzten zwei Wochen.
    const window = 14;
    final from =
        DateTime(reference.year, reference.month, reference.day - (window - 1));
    final inWindow = sessions.where((s) => !s.date.isBefore(from)).length;

    final acwrResult =
        zone.showsAcwr && DataSufficiency.hasAcwr(sessions, reference)
            ? Readiness.compute(sessions, reference, context: context)
            : null;

    return HistorySummary(
      sessions: sessions.length,
      zone: zone,
      daysSinceLast: days,
      lastSession: last,
      sessionsInWindow: inWindow,
      windowDays: window,
      medianGapDays: DataSufficiency.medianGapDays(sessions),
      longestGapDays: DataSufficiency.longestGapDays(sessions),
      months: _months(sessions),
      trainingDays: {for (final s in sessions) Readiness.dayKey(s.date)}.length,
      spanDays: DataSufficiency.spanDays(sessions, reference),
      acwr: acwrResult,
    );
  }

  /// Monate von der ersten bis zur letzten Einheit, Lücken eingeschlossen.
  static List<MonthCount> _months(List<TrainingSession> sessions) {
    final counts = <String, int>{};
    for (final s in sessions) {
      final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return const [];

    final keys = counts.keys.toList()..sort();
    final first = keys.first.split('-').map(int.parse).toList();
    final last = keys.last.split('-').map(int.parse).toList();

    final months = <MonthCount>[];
    var year = first[0];
    var month = first[1];
    while (year < last[0] || (year == last[0] && month <= last[1])) {
      final key = '$year-${month.toString().padLeft(2, '0')}';
      months.add(MonthCount(year: year, month: month, count: counts[key] ?? 0));
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    return months;
  }
}
