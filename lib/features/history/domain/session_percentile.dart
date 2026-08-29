import 'training_session.dart';

/// Wo eine Einheit im eigenen Bestand steht — **im Vergleich mit sich selbst**.
///
/// ## Warum ein Perzentil und kein Durchschnitt
///
/// „Pace 5:42, Durchschnitt 5:55" klingt nach einer Aussage, ist aber eine
/// schwache: Ein einziger langsamer Spaziergang zieht den Durchschnitt so
/// weit, dass jede normale Einheit „überdurchschnittlich" wird.
///
/// Das Perzentil sagt stattdessen, wie viele der eigenen Einheiten schlechter
/// waren. „Top 30 %" heisst: Von zehn Läufen waren sieben langsamer. Das
/// hält auch, wenn ein Ausreisser dabei ist.
///
/// ## Nur gegen dieselbe Art
///
/// Verglichen wird gegen Einheiten derselben Aktivität — Läufe gegen Läufe,
/// nicht gegen Radfahrten. Eine Pace von 5:42 ist auf dem Rad keine Leistung
/// und beim Laufen eine.
class SessionPercentile {
  const SessionPercentile({
    required this.rank,
    required this.total,
    required this.higherIsBetter,
  });

  /// Wie viele Einheiten schlechter waren.
  final int rank;

  /// Wie viele verglichen wurden, diese eingeschlossen.
  final int total;

  /// Bei Strecke ist mehr besser, bei Pace weniger.
  final bool higherIsBetter;

  /// Ab hier heisst es „Top {p} %".
  static const topThreshold = 0.5;

  /// So viele gleichartige Einheiten braucht es, bevor ein Perzentil etwas
  /// sagt.
  ///
  /// Unter fünf ist „Top 20 %" nur eine andere Schreibweise für „von fünf der
  /// beste" — und klingt nach mehr.
  static const minimum = 5;

  /// Der Anteil, der schlechter war. 0 bis 1.
  double get share => total <= 1 ? 0 : rank / (total - 1);

  bool get isTop => share >= topThreshold;

  /// „Top 30 %" — wie weit oben, gerundet auf Zehner.
  int get topPercent {
    final fromTop = ((1 - share) * 100).round();
    return fromTop < 10 ? 10 : (fromTop / 10).round() * 10;
  }

  /// Berechnet das Perzentil eines Werts gegen gleichartige Einheiten.
  ///
  /// `null`, wenn es zu wenige gibt oder der Wert fehlt.
  static SessionPercentile? of(
    double? value,
    List<TrainingSession> sessions,
    CardioActivity? activity, {
    required double? Function(CardioSession) select,
    required bool higherIsBetter,
  }) {
    if (value == null) return null;

    final others = <double>[];
    for (final session in sessions) {
      if (session is! CardioSession) continue;
      if (session.activity != activity) continue;
      final other = select(session);
      if (other != null) others.add(other);
    }
    if (others.length < minimum) return null;

    var worse = 0;
    for (final other in others) {
      if (other == value) continue;
      if (higherIsBetter ? other < value : other > value) worse++;
    }

    return SessionPercentile(
      rank: worse,
      total: others.length,
      higherIsBetter: higherIsBetter,
    );
  }
}
