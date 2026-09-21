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
/// ## Zwei Datentypen, getrennt gefragt
///
/// Google gibt Health-Connect-Zugriff **je Datentyp** frei, mit Begründung
/// und Demo-Video je Typ. Deshalb hat jeder Typ hier sein eigenes Paar aus
/// `has…Access` und `request…Access`: Gewicht kann freigegeben sein und
/// Einheiten nicht, und die Oberfläche zeigt zwei Zeilen statt einer
/// (Board 15, D).
library;

import 'pulse_profile.dart';

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

/// Eine Trainingseinheit, wie die Quelle sie führt.
///
/// **Alles daran ist gemessen oder gemeldet, nichts ist gerechnet.** Was die
/// App daraus macht — annehmen, ablehnen, mit einer eigenen Einheit paaren —
/// entscheidet `SessionPairing` und der Eingang, nicht diese Klasse.
class MeasuredSession {
  const MeasuredSession({
    required this.id,
    required this.start,
    required this.end,
    required this.sourceId,
    this.activity,
    this.deviceName,
    this.averageHeartRate,
    this.maxHeartRate,
    this.calories,
    this.distanceKm,
    this.pulse,
  });

  /// Die Kennung des Datensatzes in der Quelle.
  ///
  /// Sie ist das Gedächtnis des Moduls: Sie steht an der übernommenen
  /// Einheit, damit dieselbe nicht zweimal hereinkommt, und sie steht in der
  /// Ablehnliste, damit ein „Nein" ein „Nein" bleibt (Board 15,
  /// Entscheidung 11).
  final String id;

  final DateTime start;
  final DateTime end;

  /// Das Paket, das den Datensatz geschrieben hat — „com.garmin.android…".
  final String sourceId;

  /// Wie die Uhr das Training nennt: „Laufen", „Andere", „HIIT".
  ///
  /// **Nie eine Paar-Bedingung** (Entscheidung 6): Uhren melden Krafttraining
  /// regelmässig als „Andere" oder „Cardio". Eine Artprüfung verwürfe mehr
  /// echte Paare, als sie falsche verhindert.
  final String? activity;

  /// Der lesbare Name der Quelle für die Oberfläche — „Garmin".
  final String? deviceName;

  final int? averageHeartRate;
  final int? maxHeartRate;
  final int? calories;
  final double? distanceKm;

  /// Der Pulsverlauf der Einheit, als Sekunden je bpm.
  ///
  /// Daraus entstehen Ø, Maximum, Minimum **und** die Zonen — aus einer
  /// Quelle, damit keine Grösse zwei hat. [averageHeartRate] und
  /// [maxHeartRate] bleiben als die Werte, die das Gateway daraus gerechnet
  /// hat.
  final PulseProfile? pulse;

  Duration get duration => end.difference(start);

  /// Wie viele Angaben ausser Dauer und Puls dabei sind — die Zeile
  /// „Weitere Angaben vom Gerät · 3".
  int get extrasCount =>
      [calories, distanceKm].where((v) => v != null).length;
}

/// Liest Gewichtswerte und Trainingseinheiten in einer Gesundheitsquelle —
/// und schreibt Gewichtswerte zurück.
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

  /// Ob Trainingseinheiten **gelesen** werden dürfen.
  ///
  /// Getrennt von [hasWeightAccess], weil Google je Datentyp fragt. `null`
  /// bedeutet dasselbe wie dort: Die Plattform kann es nicht beantworten, es
  /// muss gefragt werden.
  Future<bool?> hasSessionAccess();

  /// Fragt nach. Gibt zurück, ob am Ende Zugriff besteht.
  Future<bool> requestSessionAccess();

  /// Alle Trainingseinheiten im Zeitraum, mit Puls, sofern die Quelle ihn
  /// führt.
  ///
  /// **Dieses Modul liest nur.** Ob ATEM eigene Einheiten nach Health Connect
  /// schreibt, ist eine eigene Entscheidung mit eigener Berechtigung und
  /// eigener Vertrauensfrage (Board 15, offene Frage 2).
  Future<List<MeasuredSession>> readSessions({
    required DateTime from,
    required DateTime to,
  });

  /// Führt zum Installieren von Health Connect. Nur sinnvoll bei
  /// [HealthAvailability.notInstalled].
  Future<void> openInstall();
}
