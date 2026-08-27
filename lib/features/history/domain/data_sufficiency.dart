import 'readiness.dart';
import 'training_session.dart';

/// Wann eine Auswertung überhaupt etwas aussagt.
///
/// ## Warum es diese Schwellen zusätzlich zur Formel gibt
///
/// Die portierten Formeln haben genau **ein** Tor: 14 Tage zwischen der ersten
/// und der betrachteten Einheit. Einheiten zählen sie nicht. Am echten Bestand
/// gemessen ist das zu wenig:
///
/// ```
/// 28 Tage Spanne, aber nur  2 Einheiten  ->  ACWR 2,78  ->  „overreaching"
/// 28 Tage Spanne, aber     15 Einheiten  ->  ACWR 1,22  ->  „maintaining"
/// ```
///
/// **Wer zweimal im Monat trainiert, bekommt „übertrainiert" angezeigt** — das
/// Gegenteil der Wahrheit. Es passiert, weil die chronische Last nahe null
/// steht und das Verhältnis dadurch explodiert. Die Formel hat dagegen keine
/// Sicherung; diese Schwellen sind sie.
///
/// Tage **und** Einheiten zusammen: Die Tage schützen vor zu kurzer Historie,
/// die Zahl vor zu dünner. Beide allein lassen sich austricksen.
///
/// Alle Werte stehen hier an **einer** Stelle. Ändert sich die Formel oder
/// zeigt sich ein besseres Mindestfenster, wird hier geschraubt — nicht in den
/// Bildschirmen.
abstract final class DataSufficiency {
  /// Ab hier zeigen wir einen Form-Trend.
  static const trendMinimumSessions = 8;
  static const trendMinimumDays = 21;

  /// Ab hier zeigen wir ein Belastungsverhältnis.
  ///
  /// Strenger als der Trend: Der ACWR reagiert auf dünne Daten mit extremen
  /// Werten, der Form-Wert bleibt im Rahmen.
  static const acwrMinimumDays = 28;
  static const acwrMinimumSessions = 8;

  /// Trägt der Bestand eine Trendaussage?
  static bool hasTrend(List<TrainingSession> sessions, DateTime reference) =>
      _spanDays(sessions, reference) >= trendMinimumDays &&
      _counted(sessions) >= trendMinimumSessions;

  /// Trägt der Bestand ein Belastungsverhältnis?
  static bool hasAcwr(List<TrainingSession> sessions, DateTime reference) =>
      _spanDays(sessions, reference) >= acwrMinimumDays &&
      _counted(sessions) >= acwrMinimumSessions;

  /// Nur Einheiten, die Last tragen. Regeneration zählt für die Belastung
  /// nicht mit — sonst hübschte ein Saunagang die Datenlage auf.
  static int _counted(List<TrainingSession> sessions) => sessions
      .where((s) => s.kind != null && s.kind != SessionKind.recovery)
      .length;

  static int _spanDays(List<TrainingSession> sessions, DateTime reference) {
    if (sessions.isEmpty) return 0;
    final earliest =
        sessions.map((s) => s.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final ref = DateTime(reference.year, reference.month, reference.day);
    final from = DateTime(earliest.year, earliest.month, earliest.day);
    return (ref.difference(from).inHours / 24).round();
  }

  /// Tage seit der letzten Einheit — die Zahl, die den Verlaufsbildschirm
  /// anführt.
  static int? daysSinceLast(
      List<TrainingSession> sessions, DateTime reference) {
    if (sessions.isEmpty) return null;
    final last =
        sessions.map((s) => s.date).reduce((a, b) => a.isAfter(b) ? a : b);
    final ref = DateTime(reference.year, reference.month, reference.day);
    final day = DateTime(last.year, last.month, last.day);
    return (ref.difference(day).inHours / 24).round();
  }

  /// Ab hier gilt eine Unterbrechung als Lücke und wird gestaltet.
  static const gapDays = 7;

  /// Median statt Durchschnitt.
  ///
  /// Im Bestand stehen 1 Einheit im November und 30 im Mai. „Im Schnitt alle
  /// 2,2 Tage" beschreibt keinen einzigen realen Monat.
  static int? medianGapDays(List<TrainingSession> sessions) {
    final days = sessions.map((s) => Readiness.dayKey(s.date)).toSet().toList()
      ..sort();
    if (days.length < 2) return null;

    final gaps = <int>[];
    for (var i = 1; i < days.length; i++) {
      final a = DateTime.parse(days[i - 1]);
      final b = DateTime.parse(days[i]);
      gaps.add((b.difference(a).inHours / 24).round());
    }
    gaps.sort();
    final middle = gaps.length ~/ 2;
    return gaps.length.isOdd
        ? gaps[middle]
        : ((gaps[middle - 1] + gaps[middle]) / 2).round();
  }

  /// Die längste Unterbrechung im Bestand.
  static int? longestGapDays(List<TrainingSession> sessions) {
    final days = sessions.map((s) => Readiness.dayKey(s.date)).toSet().toList()
      ..sort();
    if (days.length < 2) return null;
    var longest = 0;
    for (var i = 1; i < days.length; i++) {
      final gap = (DateTime.parse(days[i])
                  .difference(DateTime.parse(days[i - 1]))
                  .inHours /
              24)
          .round();
      if (gap > longest) longest = gap;
    }
    return longest;
  }
}
