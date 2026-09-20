import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/health_gateway.dart';

/// [HealthGateway] über das Paket `health` — **die einzige Datei, die es
/// kennt**.
///
/// ## Warum so dünn
///
/// Alles, was hier passiert, ist Übersetzung: `HealthDataPoint` zu
/// [MeasuredWeight], `HealthConnectSdkStatus` zu [HealthAvailability]. Jede
/// Regel darüber — was übernommen wird, was gewinnt, was zurückgeschrieben
/// wird — steht in `WeightSync` und ist ohne Gerät prüfbar. Eine Schicht, die
/// beides mischt, wäre nur auf einem Telefon mit installiertem Health Connect
/// und erteilter Berechtigung zu testen, also praktisch nie.
///
/// ## Google Fit ist kein Weg mehr
///
/// Die Fit-APIs sind abgekündigt und abgeschaltet. Auf Android läuft alles
/// über Health Connect — und damit zugleich Garmin, Fitbit, Withings und
/// Samsung, deren Apps dorthin schreiben. Eine Anbindung statt vier
/// (Produktstrategie 8.3).
class HealthConnectGateway implements HealthGateway {
  HealthConnectGateway({Health? health}) : _health = health ?? Health();

  final Health _health;

  /// `configure()` liest die Gerätekennung und muss **einmal** vor dem ersten
  /// Zugriff laufen. Zweimal aufgerufen ist es nicht falsch, nur unnötig.
  bool _configured = false;

  String? _ownSourceId;

  static const _weightTypes = [HealthDataType.WEIGHT];
  static const _weightAccess = [HealthDataAccess.READ_WRITE];

  /// Einheiten **und** Puls: Health Connect führt beides getrennt, und ein
  /// Ø-Puls entsteht erst, wenn man die Pulspunkte im Zeitfenster der Einheit
  /// zusammenfasst. Beides nur lesend — dieses Modul schreibt nichts zurück.
  static const _sessionTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE,
  ];
  static const _sessionAccess = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<String> ownSourceId() async =>
      _ownSourceId ??= (await PackageInfo.fromPlatform()).packageName;

  @override
  Future<HealthAvailability> availability() async {
    if (!Platform.isAndroid) return HealthAvailability.unsupported;
    await _ensureConfigured();
    return switch (await _health.getHealthConnectSdkStatus()) {
      HealthConnectSdkStatus.sdkAvailable => HealthAvailability.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        HealthAvailability.needsUpdate,
      HealthConnectSdkStatus.sdkUnavailable => HealthAvailability.notInstalled,
      // `null` heisst: Die Plattform hat nicht geantwortet. Das ist kein
      // „nicht installiert" — ein Installationsangebot wäre hier falsch.
      null => HealthAvailability.unsupported,
    };
  }

  @override
  Future<bool?> hasWeightAccess() async {
    await _ensureConfigured();
    return _health.hasPermissions(_weightTypes, permissions: _weightAccess);
  }

  @override
  Future<bool> requestWeightAccess() async {
    await _ensureConfigured();
    return _health.requestAuthorization(_weightTypes,
        permissions: _weightAccess);
  }

  @override
  Future<List<MeasuredWeight>> readWeights({
    required DateTime from,
    required DateTime to,
  }) async {
    await _ensureConfigured();
    final points = await _health.getHealthDataFromTypes(
      types: _weightTypes,
      startTime: from,
      endTime: to,
    );

    final result = <MeasuredWeight>[];
    for (final point in points) {
      final value = point.value;
      if (value is! NumericHealthValue) continue;
      final kg = value.numericValue.toDouble();
      // Health Connect führt Gewicht in Kilogramm. Ein Wert ausserhalb jeder
      // Plausibilität ist eher ein Einheitenfehler als ein Mensch — er wird
      // übergangen, statt die Reihe zu verderben.
      if (kg <= 0 || kg > 500) continue;
      result.add(MeasuredWeight(
        id: point.uuid,
        measuredAt: point.dateFrom,
        kg: kg,
        sourceId: point.sourceId,
      ));
    }
    return result;
  }

  @override
  Future<bool> writeWeight({
    required DateTime at,
    required double kg,
    required String recordId,
  }) async {
    await _ensureConfigured();
    return _health.writeHealthData(
      value: kg,
      unit: HealthDataUnit.KILOGRAM,
      type: HealthDataType.WEIGHT,
      startTime: at,
      // Die Kennung des Eintrags (`2026-09-20`) als Kundenkennung: Ein
      // zweites Zurückschreiben desselben Tages ersetzt den Datensatz, statt
      // einen zweiten daneben zu legen.
      clientRecordId: recordId,
      // Der Wert ist getippt, nicht gemessen. Health Connect zeigt das an,
      // und andere Apps können danach filtern.
      recordingMethod: RecordingMethod.manual,
    );
  }

  @override
  Future<bool?> hasSessionAccess() async {
    await _ensureConfigured();
    return _health.hasPermissions(_sessionTypes, permissions: _sessionAccess);
  }

  @override
  Future<bool> requestSessionAccess() async {
    await _ensureConfigured();
    return _health.requestAuthorization(_sessionTypes,
        permissions: _sessionAccess);
  }

  @override
  Future<List<MeasuredSession>> readSessions({
    required DateTime from,
    required DateTime to,
  }) async {
    await _ensureConfigured();
    final points = await _health.getHealthDataFromTypes(
      types: _sessionTypes,
      startTime: from,
      endTime: to,
    );

    // Puls kommt als Punktwolke, nicht als Zusammenfassung. Er wird je
    // Einheit über ihr Zeitfenster gebündelt — das ist die einzige Rechnung
    // in dieser Datei, und sie ist eine Übersetzung, keine Regel.
    final pulses = <({DateTime at, int bpm})>[];
    for (final point in points) {
      if (point.type != HealthDataType.HEART_RATE) continue;
      final value = point.value;
      if (value is! NumericHealthValue) continue;
      final bpm = value.numericValue.round();
      if (bpm <= 0 || bpm > 300) continue;
      pulses.add((at: point.dateFrom, bpm: bpm));
    }

    final result = <MeasuredSession>[];
    for (final point in points) {
      if (point.type != HealthDataType.WORKOUT) continue;
      final value = point.value;
      if (value is! WorkoutHealthValue) continue;
      // Eine Einheit ohne Dauer kann nie ein Paar bilden und trägt keine
      // Aussage — sie kommt gar nicht erst in den Eingang.
      if (!point.dateTo.isAfter(point.dateFrom)) continue;

      final inside = [
        for (final p in pulses)
          if (!p.at.isBefore(point.dateFrom) && !p.at.isAfter(point.dateTo))
            p.bpm,
      ];

      result.add(MeasuredSession(
        id: point.uuid,
        start: point.dateFrom,
        end: point.dateTo,
        sourceId: point.sourceId,
        activity: value.workoutActivityType.name,
        deviceName: point.sourceName,
        averageHeartRate: inside.isEmpty
            ? null
            : (inside.reduce((a, b) => a + b) / inside.length).round(),
        maxHeartRate:
            inside.isEmpty ? null : inside.reduce((a, b) => a > b ? a : b),
        calories: value.totalEnergyBurned,
        distanceKm: value.totalDistance == null
            ? null
            : value.totalDistance! / 1000,
      ));
    }
    return result;
  }

  @override
  Future<void> openInstall() async {
    if (!Platform.isAndroid) return;
    await _health.installHealthConnect();
  }
}
