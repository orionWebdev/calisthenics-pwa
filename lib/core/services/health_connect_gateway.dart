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

  static const _types = [HealthDataType.WEIGHT];
  static const _access = [HealthDataAccess.READ_WRITE];

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
    return _health.hasPermissions(_types, permissions: _access);
  }

  @override
  Future<bool> requestWeightAccess() async {
    await _ensureConfigured();
    return _health.requestAuthorization(_types, permissions: _access);
  }

  @override
  Future<List<MeasuredWeight>> readWeights({
    required DateTime from,
    required DateTime to,
  }) async {
    await _ensureConfigured();
    final points = await _health.getHealthDataFromTypes(
      types: _types,
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
  Future<void> openInstall() async {
    if (!Platform.isAndroid) return;
    await _health.installHealthConnect();
  }
}
