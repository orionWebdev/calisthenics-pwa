import 'package:atem/core/domain/health_gateway.dart';

/// Eine Gesundheitsquelle im Speicher.
///
/// Sie hält dieselben Zustände wie das echte Health Connect — nicht
/// vorhanden, nichts freigegeben, erreichbar — damit sich der Abgleich ohne
/// Gerät durch alle davon führen lässt.
class FakeHealthGateway implements HealthGateway {
  FakeHealthGateway({
    this.availabilityValue = HealthAvailability.available,
    this.granted = false,
    this.grantOnRequest = true,
    this.writeSucceeds = true,
    this.sessionsGranted = false,
    List<MeasuredWeight>? records,
    List<MeasuredSession>? sessions,
  })  : records = records ?? [],
        sessions = sessions ?? [];

  HealthAvailability availabilityValue;
  bool granted;

  /// Was der Systemdialog antwortet.
  bool grantOnRequest;

  bool writeSucceeds;

  final List<MeasuredWeight> records;

  /// Einheiten und Berechtigung sind vom Gewicht getrennt — Google fragt je
  /// Datentyp einzeln, und die Oberfläche zeigt darum zwei Zeilen.
  bool sessionsGranted;
  final List<MeasuredSession> sessions;

  /// Zählt mit, damit ein Test „hat nicht gefragt" prüfen kann.
  int requests = 0;
  int sessionRequests = 0;
  int installs = 0;

  static const packageName = 'com.atemhybrid.app';

  @override
  Future<String> ownSourceId() async => packageName;

  @override
  Future<HealthAvailability> availability() async => availabilityValue;

  @override
  Future<bool?> hasWeightAccess() async => granted;

  @override
  Future<bool> requestWeightAccess() async {
    requests++;
    return granted = grantOnRequest;
  }

  @override
  Future<List<MeasuredWeight>> readWeights({
    required DateTime from,
    required DateTime to,
  }) async =>
      [
        for (final record in records)
          if (!record.measuredAt.isBefore(from) &&
              !record.measuredAt.isAfter(to))
            record,
      ];

  @override
  Future<bool> writeWeight({
    required DateTime at,
    required double kg,
    required String recordId,
  }) async {
    if (!writeSucceeds) return false;
    records
      ..removeWhere((r) => r.id == recordId)
      ..add(MeasuredWeight(
        id: recordId,
        measuredAt: at,
        kg: kg,
        sourceId: packageName,
      ));
    return true;
  }

  @override
  Future<bool?> hasSessionAccess() async => sessionsGranted;

  @override
  Future<bool> requestSessionAccess() async {
    sessionRequests++;
    return sessionsGranted = grantOnRequest;
  }

  @override
  Future<List<MeasuredSession>> readSessions({
    required DateTime from,
    required DateTime to,
  }) async =>
      [
        for (final session in sessions)
          if (!session.start.isBefore(from) && !session.start.isAfter(to))
            session,
      ];

  @override
  Future<void> openInstall() async => installs++;
}
