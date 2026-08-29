import 'training_session.dart';

/// Wonach die Einheitenliste gefiltert wird.
///
/// ## Zwei Achsen, beide optional
///
/// **Art** und **Zeitraum**. Beide leer heisst: alles. Sie sind unabhängig —
/// „Cardio im Mai" ist eine sinnvolle Frage, und „alle im Mai" auch.
///
/// Der Zeitraum kommt aus dem Monatsstreifen: Ein Monat wird angetippt, und
/// die Liste zeigt ihn. Deshalb heisst der Weg zurück „Zeitraum aufheben" und
/// nicht „Filter zurücksetzen" — er hebt genau das auf, was man angetippt hat.
class SessionFilter {
  const SessionFilter({this.kind, this.year, this.month});

  static const none = SessionFilter();

  final SessionKind? kind;
  final int? year;
  final int? month;

  bool get hasPeriod => year != null && month != null;
  bool get isEmpty => kind == null && !hasPeriod;

  /// Wie viele Achsen gesetzt sind — für „{n} aktiv".
  int get activeCount => (kind == null ? 0 : 1) + (hasPeriod ? 1 : 0);

  SessionFilter withKind(SessionKind? value) =>
      SessionFilter(kind: value, year: year, month: month);

  SessionFilter withPeriod(int? y, int? m) =>
      SessionFilter(kind: kind, year: y, month: m);

  bool matches(TrainingSession session) {
    if (kind != null && session.kind != kind) return false;
    if (hasPeriod &&
        (session.date.year != year || session.date.month != month)) {
      return false;
    }
    return true;
  }

  List<TrainingSession> apply(List<TrainingSession> sessions) =>
      isEmpty ? sessions : [for (final s in sessions) if (matches(s)) s];

  /// Wie viele Einheiten es je Art gibt — für die Zahlen an den Chips.
  ///
  /// **Über den ganzen Bestand**, nicht über die gefilterte Menge: Sonst zeigte
  /// der Chip „Cardio 0", sobald „Kraft" gewählt ist, und niemand käme mehr
  /// hin.
  static Map<SessionKind, int> countByKind(List<TrainingSession> sessions) {
    final counts = <SessionKind, int>{};
    for (final session in sessions) {
      final kind = session.kind;
      if (kind == null) continue;
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    return counts;
  }
}
