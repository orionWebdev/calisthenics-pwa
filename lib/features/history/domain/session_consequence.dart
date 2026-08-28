import 'history_summary.dart';
import 'training_load.dart';
import 'training_session.dart';

/// Was eine Änderung an den Auswertungen anrichtet — **gerechnet, nicht
/// gewarnt**.
///
/// ## Warum eine Warnung nicht reicht
///
/// „Das Löschen wirkt sich auf deine Auswertung aus" ist wahr und wertlos. Es
/// nennt keine Richtung, keine Größe, und lässt die Entscheidung genauso
/// uninformiert wie vorher. Wer es liest, klickt weiter.
///
/// „Pause 50 → 32 Tage, Form 16 → 14" sagt dasselbe in Zahlen, die jemand
/// abwägen kann. Und es kostet nichts, sie zu haben: [HistorySummary.from] ist
/// eine reine Funktion der Einheitenliste. Wir bauen die Liste, wie sie nach
/// der Änderung aussähe, und rechnen sie ein zweites Mal durch.
///
/// Das ist teurer als eine Warnung und billiger als ein Irrtum.
///
/// ## Der Bezugstag
///
/// Alle Werte werden gegen **denselben** Bezugstag gerechnet, in aller Regel
/// heute. Nur so ist der Vergleich einer: Zwei Zahlen aus zwei Bezugstagen
/// wären keine Folge, sondern zwei Messungen.
class SessionConsequence {
  const SessionConsequence({required this.before, required this.after});

  final HistorySummary before;
  final HistorySummary after;

  /// Tage seit der letzten Einheit — die „Pause".
  int? get pauseBefore => before.daysSinceLast;
  int? get pauseAfter => after.daysSinceLast;

  int? get formBefore => before.form.score;
  int? get formAfter => after.form.score;

  double? get acwrBefore => before.acwr?.acwr;
  double? get acwrAfter => after.acwr?.acwr;

  int get sessionsBefore => before.sessions;
  int get sessionsAfter => after.sessions;

  /// Die längste Pause im ganzen Verlauf.
  ///
  /// Steht auch dann in der Vorschau, wenn sie sich **nicht** ändert — das
  /// Board zeigt sie als neutrale Zeile. Die Auskunft „daran rührt es nicht"
  /// ist bei einer Änderung, die Lücken verschiebt, selbst eine Auskunft.
  int? get longestBefore => before.longestGapDays;
  int? get longestAfter => after.longestGapDays;

  /// Einheiten in einem bestimmten Monat, vorher und nachher.
  (int, int) monthCount(int year, int month) => (
        _count(before, year, month),
        _count(after, year, month),
      );

  static int _count(HistorySummary summary, int year, int month) {
    for (final entry in summary.months) {
      if (entry.year == year && entry.month == month) return entry.count;
    }
    return 0;
  }

  bool get pauseChanges => pauseBefore != pauseAfter;
  bool get formChanges => formBefore != formAfter;

  /// Der ACWR **erscheint oder verschwindet** — das ist die auffälligste Folge
  /// und keine Zahlenänderung. Wer seine letzte Einheit im akuten Fenster
  /// löscht, verliert das Verhältnis ganz.
  bool get acwrAppears => acwrBefore == null && acwrAfter != null;
  bool get acwrDisappears => acwrBefore != null && acwrAfter == null;

  bool get acwrChanges =>
      acwrAppears ||
      acwrDisappears ||
      (acwrBefore != null &&
          acwrAfter != null &&
          (acwrBefore! - acwrAfter!).abs() >= 0.005);

  /// Ändert sich überhaupt etwas Sichtbares?
  ///
  /// Wenn nicht, zeigt der Dialog **keine Folgenzeilen** statt drei Zeilen
  /// „unverändert". Eine Tabelle, in der nichts steht, behauptet Bedeutung,
  /// wo keine ist.
  bool get isVisible => pauseChanges || formChanges || acwrChanges;

  /// Die Folgen des Löschens.
  static SessionConsequence ofDeleting(
    List<TrainingSession> sessions,
    String sessionId,
    DateTime reference, {
    LoadContext context = const LoadContext(),
  }) =>
      _compare(
        sessions,
        [
          for (final s in sessions)
            if (s.id != sessionId) s,
        ],
        reference,
        context,
      );

  /// Die Folgen einer Datums- oder Dauerverschiebung.
  ///
  /// Beides in einer Rechnung, weil beides zugleich geändert werden kann und
  /// zwei getrennte Vorschauen sich widersprächen.
  static SessionConsequence ofEditing(
    List<TrainingSession> sessions,
    String sessionId,
    DateTime reference, {
    DateTime? date,
    Duration? duration,
    LoadContext context = const LoadContext(),
  }) =>
      _compare(
        sessions,
        [
          for (final s in sessions)
            if (s.id == sessionId)
              s.copyWith(date: date, duration: duration)
            else
              s,
        ],
        reference,
        context,
      );

  static SessionConsequence _compare(
    List<TrainingSession> before,
    List<TrainingSession> after,
    DateTime reference,
    LoadContext context,
  ) =>
      SessionConsequence(
        before: HistorySummary.from(before, reference, context: context),
        after: HistorySummary.from(after, reference, context: context),
      );
}
