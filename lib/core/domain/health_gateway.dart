/// Was ATEM von einer Gesundheitsquelle braucht — **ohne zu wissen, welche**.
///
/// ## Warum ein eigener Vertrag über dem Plugin
///
/// Das Paket `health` spricht `HealthDataPoint`, `HealthDataType` und
/// `RecordingMethod`. Diese Typen durch die halbe App zu reichen hiesse, jede
/// Rechnung und jeden Test an eine Plattform-Abhängigkeit zu binden, die sich
/// nicht ohne Gerät ausführen lässt. Hier stehen drei Werte und vier Methoden;
/// alles dahinter ist auswechselbar und im Test ein paar Zeilen.
///
/// ## Warum in `core/domain/` und nicht neben dem Plugin
///
/// Der Abgleich (`WeightSync`) ist reine Rechnung und liegt in der Domäne;
/// die Schichtregel lässt sie nur andere Domänendateien lesen. Der Vertrag
/// gehört deshalb hierher, die Umsetzung nach `core/services/` — dieselbe
/// Trennung wie bei `plate_calculator.dart` und dem Eingabeblatt.
///
/// ## Was hier bewusst fehlt
///
/// Alles ausser Gewicht. Google gibt Health-Connect-Zugriff **je Datentyp**
/// frei, mit Begründung und Demo-Video je Typ — ein Vertrag, der schon
/// Einheiten und Puls kennt, lädt dazu ein, sie zu deklarieren, bevor jemand
/// sie begründen kann. Sie kommen mit Abschnitt 8.4 dazu.
library;

/// Ob und wie die Quelle auf diesem Gerät zu erreichen ist.
///
/// Vier Zustände, nicht zwei: „Nicht da" und „nichts freigegeben" fühlen sich
/// gleich an und brauchen verschiedene Antworten — einmal installieren,
/// einmal fragen.
enum HealthAvailability {
  /// Kein Android, oder zu alt. Kein Weg dorthin, kein Angebot.
  unsupported,

  /// Health Connect ist nicht installiert.
  notInstalled,

  /// Installiert, aber zu alt.
  needsUpdate,

  /// Erreichbar. Sagt **nichts** über Berechtigungen.
  available,
}

/// Ein gemessener Gewichtswert, wie ihn die Quelle führt.
class MeasuredWeight {
  const MeasuredWeight({
    required this.id,
    required this.measuredAt,
    required this.kg,
    required this.sourceId,
  });

  /// Die Kennung des Datensatzes in der Quelle.
  ///
  /// Sie landet als `externalId` am Eintrag. Ohne sie liesse sich beim zweiten
  /// Lesen nicht unterscheiden, ob ein Wert neu ist oder derselbe noch einmal.
  final String id;

  /// Wann gemessen wurde — mit Uhrzeit. Die Reihe rechnet tagesgenau, aber
  /// bei zwei Messungen an einem Tag entscheidet die Uhrzeit, welche gilt.
  final DateTime measuredAt;

  final double kg;

  /// Das Paket, das den Datensatz geschrieben hat.
  ///
  /// **Der Schlüssel gegen die Schleife.** Was ATEM selbst zurückschreibt,
  /// trägt hier das eigene Paket — und darf nicht als fremde Messung wieder
  /// hereinkommen.
  final String sourceId;
}

/// Liest und schreibt Gewichtswerte in einer Gesundheitsquelle.
abstract interface class HealthGateway {
  /// Das eigene Paket. Wird gebraucht, um eigene Rückschreibungen beim Lesen
  /// wiederzuerkennen.
  Future<String> ownSourceId();

  Future<HealthAvailability> availability();

  /// Ob Lesen **und** Schreiben von Gewicht freigegeben sind.
  ///
  /// `null`, wenn die Plattform es nicht beantworten kann — Android liefert
  /// bei entzogener Berechtigung aus Datenschutzgründen dasselbe wie bei nie
  /// erteilter. Der Unterschied ist für die App keiner: Beide Male muss
  /// gefragt werden.
  Future<bool?> hasWeightAccess();

  /// Fragt nach. Gibt zurück, ob am Ende Zugriff besteht.
  Future<bool> requestWeightAccess();

  /// Alle Gewichtswerte im Zeitraum, **einschliesslich der eigenen**.
  ///
  /// Die eigenen auszufiltern ist Sache des Abgleichs, nicht der Quelle: Er
  /// braucht sie, um zu wissen, welche Einträge bereits zurückgeschrieben
  /// sind (siehe `WeightSync`).
  Future<List<MeasuredWeight>> readWeights({
    required DateTime from,
    required DateTime to,
  });

  /// Schreibt einen Wert zurück. Gibt zurück, ob es geklappt hat.
  Future<bool> writeWeight({
    required DateTime at,
    required double kg,
    required String recordId,
  });

  /// Führt zum Installieren von Health Connect. Nur sinnvoll bei
  /// [HealthAvailability.notInstalled].
  Future<void> openInstall();
}
