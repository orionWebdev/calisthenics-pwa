import '../../../core/domain/health_gateway.dart';
import '../../../core/domain/pulse_profile.dart';

/// Wo eine Uhr-Einheit im Eingang steht.
///
/// Drei Zustände, und **keiner davon löscht etwas**: Der Datensatz gehört
/// Health Connect, nicht uns (Board 15, Entscheidung 11).
enum HealthSessionState {
  /// Gelesen, noch nicht geprüft. Sichtbar an ihrem Datum, ohne Wirkung auf
  /// eine einzige Zahl.
  pending('pending'),

  /// Übernommen — als eigene Einheit oder mit einer App-Einheit verknüpft.
  accepted('accepted'),

  /// Abgelehnt **und gemerkt**. Ohne dieses Gedächtnis läge derselbe
  /// Datensatz beim nächsten Lesen wieder im Eingang.
  rejected('rejected');

  const HealthSessionState(this.wire);

  final String wire;

  /// Unbekannte Werte gelten als wartend: Ein Zustand aus einer späteren
  /// Fassung darf einen Datensatz nicht verschwinden lassen.
  static HealthSessionState fromWire(Object? value) {
    for (final state in values) {
      if (state.wire == value) return state;
    }
    return HealthSessionState.pending;
  }
}

/// Eine gelesene Uhr-Einheit, wie ATEM sie führt.
///
/// ## Warum sie überhaupt gespeichert wird
///
/// Sie könnte bei jedem Start neu aus Health Connect gelesen werden. Drei
/// Dinge gingen dabei verloren, und jedes einzelne ist ein Rückweg aus dem
/// Auftrag:
///
/// 1. **Das Nein.** Abgelehnt heisst gemerkt — sonst steht derselbe Datensatz
///    am nächsten Morgen wieder da.
/// 2. **Das Lösen.** Eine zusammengeführte Einheit muss sich trennen lassen,
///    und danach liegt die Uhr-Einheit wieder im Eingang. Das geht nur, wenn
///    sie die ganze Zeit als eigener Datensatz danebenlag.
/// 3. **Der Entzug.** Wird die Berechtigung zurückgenommen, bleibt lesbar,
///    was schon übernommen wurde — die Zahlen im Bestand hängen dann nicht
///    an einer fremden App.
class HealthSession {
  const HealthSession({
    required this.externalId,
    required this.state,
    required this.start,
    required this.end,
    required this.sourceId,
    required this.seenAt,
    this.activity,
    this.deviceName,
    this.averageHeartRate,
    this.maxHeartRate,
    this.calories,
    this.distanceKm,
    this.pulse,
    this.sessionId,
    this.decidedAt,
  });

  /// Aus einem frisch gelesenen Datensatz — wartend, noch ohne Entscheidung.
  factory HealthSession.pending(MeasuredSession measured, DateTime seenAt) =>
      HealthSession(
        externalId: measured.id,
        state: HealthSessionState.pending,
        start: measured.start,
        end: measured.end,
        sourceId: measured.sourceId,
        seenAt: seenAt,
        activity: measured.activity,
        deviceName: measured.deviceName,
        averageHeartRate: measured.averageHeartRate,
        maxHeartRate: measured.maxHeartRate,
        calories: measured.calories,
        distanceKm: measured.distanceKm,
        pulse: measured.pulse,
      );

  /// Die Kennung des Datensatzes in Health Connect.
  final String externalId;

  final HealthSessionState state;
  final DateTime start;
  final DateTime end;

  /// Das Paket, das den Datensatz geschrieben hat.
  final String sourceId;

  /// Wann ATEM ihn zum ersten Mal gelesen hat.
  final DateTime seenAt;

  final String? activity;
  final String? deviceName;
  final int? averageHeartRate;
  final int? maxHeartRate;
  final int? calories;
  final double? distanceKm;

  /// Der Pulsverlauf als Sekunden je bpm — die Quelle für Ø, Maximum,
  /// Minimum und Zonen. `null` an Datensätzen, die vor dem 21.09.2026
  /// gelesen wurden; der nächste Abgleich trägt ihn nach.
  final PulseProfile? pulse;

  /// Die App-Einheit, zu der er gehört — sobald übernommen oder
  /// zusammengeführt.
  final String? sessionId;

  /// Wann angenommen oder abgelehnt wurde.
  final DateTime? decidedAt;

  Duration get duration => end.difference(start);

  bool get isPending => state == HealthSessionState.pending;

  /// Wie viele Angaben ausser Dauer und Puls dabei sind — die Zeile
  /// „Weitere Angaben vom Gerät · 3".
  int get extrasCount =>
      [calories, distanceKm].where((v) => v != null).length;

  /// Die Dokumentkennung.
  ///
  /// **Die Health-Connect-Kennung ist die Kennung des Dokuments** — damit ist
  /// „ein Datensatz aus der Quelle, ein Dokument" die Form der Daten und
  /// keine Regel im Code. Zweimal Lesen legt nie ein zweites Dokument an.
  ///
  /// Firestore verbietet `/` in Kennungen und die beiden Namen `.` und `..`.
  /// Health Connect vergibt UUIDs, aber der Vertrag sagt es nicht zu — der
  /// rohe Wert steht deshalb zusätzlich im Feld [externalId].
  String get documentId => idFor(externalId);

  static String idFor(String externalId) {
    final safe = externalId.replaceAll('/', '_');
    return safe == '.' || safe == '..' || safe.isEmpty ? '_$safe' : safe;
  }

  HealthSession copyWith({
    HealthSessionState? state,
    String? sessionId,
    DateTime? decidedAt,
    bool clearSession = false,
    PulseProfile? pulse,
    int? averageHeartRate,
    int? maxHeartRate,
  }) =>
      HealthSession(
        externalId: externalId,
        state: state ?? this.state,
        start: start,
        end: end,
        sourceId: sourceId,
        seenAt: seenAt,
        activity: activity,
        deviceName: deviceName,
        averageHeartRate: averageHeartRate ?? this.averageHeartRate,
        maxHeartRate: maxHeartRate ?? this.maxHeartRate,
        calories: calories,
        distanceKm: distanceKm,
        pulse: pulse ?? this.pulse,
        sessionId: clearSession ? null : (sessionId ?? this.sessionId),
        decidedAt: decidedAt ?? this.decidedAt,
      );
}
