import '../../history/domain/training_session.dart';

/// Die letzte Aktivität — für die Zeile unter der Bereitschaft.
///
/// Board 11, C2/3 (Sprachregel): Die Bereitschaftskarte nennt die **Art** der
/// letzten Einheit, nicht nur ihr Datum. „Gestern Regeneration" erklärt,
/// warum der Formwert trotzdem fällt.
class LastActivity {
  const LastActivity({required this.session, required this.daysAgo});

  final TrainingSession session;
  final int daysAgo;

  static LastActivity? of(List<TrainingSession> sessions, DateTime reference) {
    if (sessions.isEmpty) return null;
    final last = sessions.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    final ref = DateTime(reference.year, reference.month, reference.day);
    final day = DateTime(last.date.year, last.date.month, last.date.day);
    return LastActivity(
      session: last,
      daysAgo: (ref.difference(day).inHours / 24).round(),
    );
  }
}

/// Die letzte Regenerationseinheit — für die Regenerationszeile.
///
/// Drei Zustände (C2/1): bekannt, Lücke ab [gapDays] Tagen, nie erfasst.
class RecoveryStatus {
  const RecoveryStatus({this.last, this.daysAgo});

  /// Ab hier ist es eine Lücke: „Seit 9 Tagen keine Regeneration".
  static const gapDays = 7;

  final RecoverySession? last;
  final int? daysAgo;

  bool get isNever => last == null;
  bool get isGap => daysAgo != null && daysAgo! >= gapDays;

  static RecoveryStatus of(List<TrainingSession> sessions, DateTime reference) {
    RecoverySession? last;
    for (final s in sessions) {
      if (s is! RecoverySession) continue;
      if (last == null || s.date.isAfter(last.date)) last = s;
    }
    if (last == null) return const RecoveryStatus();
    final ref = DateTime(reference.year, reference.month, reference.day);
    final day = DateTime(last.date.year, last.date.month, last.date.day);
    return RecoveryStatus(
      last: last,
      daysAgo: (ref.difference(day).inHours / 24).round(),
    );
  }
}
