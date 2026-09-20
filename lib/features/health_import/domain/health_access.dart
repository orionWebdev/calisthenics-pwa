import '../../../core/domain/health_gateway.dart';

/// Wie es um **einen** Datentyp steht.
///
/// Google fragt je Datentyp einzeln, mit eigener Begründung und eigenem
/// Demo-Video. Gewicht kann freigegeben sein und Einheiten nicht — deshalb
/// zwei Zeilen und zwei Zustände, nie einer für beides.
enum HealthAccess {
  /// Health Connect ist auf diesem Gerät nicht eingerichtet. Kein Weg dorthin.
  missing,

  /// Erreichbar, aber nie freigegeben.
  denied,

  /// Freigegeben.
  granted,

  /// **Entzogen, und es liegen schon Daten da.**
  ///
  /// Der interessante Fall: Was übernommen wurde, bleibt, wie es ist. Nur
  /// Neues kommt nicht mehr. Die Zeile nennt zuerst, was bleibt.
  revoked,
}

/// Der Zustand beider Zeilen (Board 15, D).
///
/// **Reine Ableitung**, ohne Gerät prüfbar: Aus Erreichbarkeit, zwei
/// Freigaben und dem, was schon im Bestand liegt, folgen die fünf Artboards
/// des Boards — es gibt keinen sechsten Zustand und keine Mischung.
class HealthAccessState {
  const HealthAccessState({
    required this.weight,
    required this.sessions,
    required this.importedSessions,
    required this.measuredWeights,
    this.lastRead,
  });

  final HealthAccess weight;
  final HealthAccess sessions;

  /// Was schon übernommen wurde — die Zahl, die in D5 zuerst genannt wird.
  final int importedSessions;
  final int measuredWeights;

  /// Wann zuletzt gelesen wurde.
  final DateTime? lastRead;

  /// Ob überhaupt eine Zeile bedienbar ist.
  bool get isMissing =>
      weight == HealthAccess.missing && sessions == HealthAccess.missing;

  /// Gelesen wird, aber es kam nichts — kein Fehler, nur eine Tatsache.
  bool get readNothing =>
      sessions == HealthAccess.granted && lastRead != null;

  static HealthAccessState of({
    required HealthAvailability availability,
    required bool? weightGranted,
    required bool? sessionsGranted,
    required int importedSessions,
    required int measuredWeights,
    DateTime? lastRead,
  }) {
    HealthAccess stateOf(bool? granted, int existing) {
      if (availability != HealthAvailability.available) {
        return HealthAccess.missing;
      }
      if (granted == true) return HealthAccess.granted;
      // Android antwortet bei entzogener Berechtigung dasselbe wie bei nie
      // erteilter. Der Unterschied steckt im Bestand: Wer schon Daten aus
      // der Quelle hat, hatte den Zugang einmal.
      return existing > 0 ? HealthAccess.revoked : HealthAccess.denied;
    }

    return HealthAccessState(
      weight: stateOf(weightGranted, measuredWeights),
      sessions: stateOf(sessionsGranted, importedSessions),
      importedSessions: importedSessions,
      measuredWeights: measuredWeights,
      lastRead: lastRead,
    );
  }
}
