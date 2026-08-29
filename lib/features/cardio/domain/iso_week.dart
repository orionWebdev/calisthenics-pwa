/// Kalenderwochen — **Montag zuerst, wie überall in der App**.
///
/// Dashboard und Formkurve rechnen ihre Wochen ab Montag; die Wochenzahl
/// folgt ISO 8601, damit „KW 35" dasselbe meint wie im Kalender des Geräts.
abstract final class IsoWeek {
  /// Der Montag der Woche, in der [date] liegt — um Mitternacht.
  static DateTime start(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  /// Die Kalenderwoche nach ISO 8601.
  ///
  /// Gerechnet in UTC: Zwischen zwei lokalen Mitternachten liegen bei einer
  /// Zeitumstellung 23 oder 25 Stunden, und `inDays` schneidet dann einen Tag
  /// ab — aus KW 35 würde KW 34. Dieselbe Falle wie in der ACWR-Rechnung
  /// (Vertrag 4).
  static int number(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    // Der Donnerstag derselben Woche entscheidet über das Jahr.
    final thursday = day.add(Duration(days: 4 - day.weekday));
    final firstOfYear = DateTime.utc(thursday.year, 1, 1);
    return 1 + (thursday.difference(firstOfYear).inDays ~/ 7);
  }

  /// Tagesgenauer Schlüssel einer Woche, für Mengen und Zählungen.
  static String key(DateTime date) {
    final s = start(date);
    return '${s.year}-${s.month.toString().padLeft(2, '0')}-'
        '${s.day.toString().padLeft(2, '0')}';
  }
}
