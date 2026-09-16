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

/// Ein Monat im festen Fenster des Monatsstreifens.
class MonthSlot {
  const MonthSlot({
    required this.year,
    required this.month,
    required this.count,
    required this.measured,
    required this.isCurrent,
    this.trainingDays = 0,
    this.firstDate,
  });

  final int year;
  final int month;
  final int count;

  /// Tage mit mindestens einer Einheit in diesem Monat.
  final int trainingDays;

  /// Die früheste Einheit in diesem Monat.
  final DateTime? firstDate;

  /// `false` für Monate **vor** der ersten Einheit überhaupt: nicht
  /// gemessen, also weder Balken noch Nullstrich.
  final bool measured;

  /// Der Monat des Stichtags.
  final bool isCurrent;

  bool get hasSessions => count > 0;
}

/// Die letzten [MonthWindow.defaultMonths] Kalendermonate bis einschliesslich
/// des Stichtags — **unabhängig vom Bestand**.
///
/// ## Warum ein festes Fenster
///
/// Bis zum 16.09.2026 zeigte der Streifen nur die Monate von der ersten bis
/// zur letzten Einheit, jede Spalte `Expanded`. Nach einem Neubeginn mit einer
/// einzigen Einheit füllte ein Balken die ganze Breite und sah aus wie ein
/// Rekordmonat. Ein festes Fenster gibt jedem Monat dieselbe schmale Spalte.
class MonthWindow {
  const MonthWindow({
    required this.slots,
    required this.sessions,
    required this.trainingDays,
    this.firstDate,
  });

  static const defaultMonths = 6;

  static const empty = MonthWindow(slots: [], sessions: 0, trainingDays: 0);

  /// Älteste zuerst, genau [defaultMonths] Einträge (leer ohne Bestand).
  final List<MonthSlot> slots;

  /// Einheiten im Fenster.
  final int sessions;

  /// Tage mit mindestens einer Einheit im Fenster.
  final int trainingDays;

  /// Datum der ersten Einheit im Fenster.
  final DateTime? firstDate;

  int get peak =>
      slots.fold(0, (max, slot) => slot.count > max ? slot.count : max);

  /// Die letzten [months] Monate dieses Fensters, mit neu gezählter
  /// Grundlage. Für schmale Bildschirme, auf denen nicht alle Spalten ein
  /// 48-dp-Ziel bekommen — Kopf, Grundlage und Ansage zählen dann genau die
  /// sichtbaren Monate.
  MonthWindow lastMonths(int months) {
    if (months >= slots.length) return this;
    final kept = slots.sublist(slots.length - months);
    DateTime? first;
    for (final slot in kept) {
      final d = slot.firstDate;
      if (d != null && (first == null || d.isBefore(first))) first = d;
    }
    return MonthWindow(
      slots: kept,
      sessions: kept.fold(0, (a, s) => a + s.count),
      trainingDays: kept.fold(0, (a, s) => a + s.trainingDays),
      firstDate: first,
    );
  }

  static MonthWindow compute(
    List<TrainingSession> sessions,
    DateTime reference, {
    int months = defaultMonths,
  }) {
    if (sessions.isEmpty) return empty;

    final earliest =
        sessions.map((s) => s.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final firstMonth = DateTime(earliest.year, earliest.month);
    final start = DateTime(reference.year, reference.month - (months - 1));
    final end = DateTime(reference.year, reference.month + 1);

    final counts = <String, int>{};
    final days = <String, Set<String>>{};
    final firsts = <String, DateTime>{};
    for (final s in sessions) {
      final d = s.date;
      if (d.isBefore(start) || !d.isBefore(end)) continue;
      final key = '${d.year}-${d.month}';
      counts[key] = (counts[key] ?? 0) + 1;
      (days[key] ??= <String>{}).add(Readiness.dayKey(d));
      final f = firsts[key];
      if (f == null || d.isBefore(f)) firsts[key] = d;
    }

    final slots = <MonthSlot>[
      for (var i = 0; i < months; i++)
        () {
          // `DateTime` normalisiert den Monatsüberlauf selbst — Dezember
          // plus eins ist Januar des Folgejahres.
          final m = DateTime(start.year, start.month + i);
          return MonthSlot(
            year: m.year,
            month: m.month,
            count: counts['${m.year}-${m.month}'] ?? 0,
            measured: !m.isBefore(firstMonth),
            isCurrent: m.year == reference.year && m.month == reference.month,
            trainingDays: days['${m.year}-${m.month}']?.length ?? 0,
            firstDate: firsts['${m.year}-${m.month}'],
          );
        }(),
    ];

    DateTime? first;
    for (final d in firsts.values) {
      if (first == null || d.isBefore(first)) first = d;
    }
    return MonthWindow(
      slots: slots,
      sessions: counts.values.fold(0, (a, b) => a + b),
      trainingDays: days.values.fold(0, (a, set) => a + set.length),
      firstDate: first,
    );
  }
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
    this.monthWindow = MonthWindow.empty,
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

  /// Das feste Sechs-Monats-Fenster für den Monatsstreifen.
  final MonthWindow monthWindow;

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
      monthWindow: MonthWindow.compute(sessions, reference),
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
