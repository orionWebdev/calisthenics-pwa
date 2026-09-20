import 'health_session.dart';

/// Liest und schreibt die gelesenen Uhr-Einheiten eines Kontos.
///
/// ## Warum eine eigene Sammlung und nicht `sessions`
///
/// `sessions` ist die Sammlung, **die zählt** — jede Auswertung, jede Last,
/// jedes Verhältnis rechnet darüber. Ein wartender Datensatz darf auf keine
/// einzige dieser Zahlen wirken, und das lässt sich nicht durch ein Feld
/// sicherstellen, das jede Rechnung einzeln abfragen müsste: Vergisst eine
/// von zwölf den Filter, zählt Ungeprüftes mit, und niemand sieht es.
///
/// Getrennt liegt die Grenze in der Form der Daten statt in der Disziplin
/// jeder Rechnung. Eine Uhr-Einheit wird erst dann Teil von `sessions`, wenn
/// jemand sie angenommen hat — und bleibt auch dann hier liegen, damit sich
/// die Verknüpfung verlustfrei lösen lässt.
///
/// Der Ort ist `userProfiles/{uid}/healthSessions/{externalId}`, dieselbe
/// Stelle wie die Gewichtsreihe aus Board 14 und aus demselben Grund: Sie
/// gehört zum Konto, nicht zum Bestand.
abstract interface class HealthSessionRepository {
  /// Alle bekannten Datensätze — auch abgelehnte und übernommene. Der Eingang
  /// filtert selbst; wer nur das Wartende liest, kann nicht erkennen, was er
  /// schon gesehen hat.
  Stream<List<HealthSession>> watch(String userId);

  Future<List<HealthSession>> fetch(String userId);

  /// Legt an oder ersetzt — beides derselbe Vorgang, weil die Kennung aus der
  /// Quelle kommt. Ein zweites Lesen desselben Datensatzes ist nie ein
  /// zweiter Eintrag.
  Future<void> save(String userId, HealthSession session);

  /// Nur für die Kontolöschung. Im laufenden Betrieb wird nichts gelöscht:
  /// Abgelehnt ist ein Zustand, kein Verschwinden.
  Future<void> delete(String userId, String externalId);

  /// Wann zuletzt aus Health Connect gelesen wurde — die Lesemarke.
  ///
  /// `null`, solange nie gelesen wurde. Sie steht im Profil und nicht an
  /// einem Datensatz: Sie ist eine Eigenschaft des Kontos, überschreibbar und
  /// ohne Vergangenheit.
  Future<DateTime?> lastRead(String userId);

  Future<void> markRead(String userId, DateTime at);
}
