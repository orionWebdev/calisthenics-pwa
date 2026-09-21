import 'package:cloud_firestore/cloud_firestore.dart';

import '../../pulse/domain/heart_rate_zones.dart';
import '../domain/settings_repository.dart';
import '../domain/user_settings.dart';

/// Einstellungen aus `userProfiles/{uid}`.
///
/// Die Feldnamen folgen der Vorgänger-App, damit beide Anwendungen dasselbe
/// Profil lesen: `bodyWeight`, `unitSystem`, `language`, `defaultRestTimer`,
/// `hapticsEnabled`. Dazu ein Feld, das es dort nicht gibt: `effortScale`.
/// Die PWA kennt es nicht und lässt es beim Schreiben stehen.
class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository(this._db);

  final FirebaseFirestore _db;

  static const collection = 'userProfiles';

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _db.collection(collection).doc(userId);

  @override
  Stream<UserSettings> watch(String userId) =>
      _doc(userId).snapshots().map((doc) => _from(doc.data()));

  @override
  Future<UserSettings> fetch(String userId) async =>
      _from((await _doc(userId).get()).data());

  @override
  Future<void> save(String userId, UserSettings settings) async {
    await _doc(userId).set({
      if (settings.bodyWeightKg != null) 'bodyWeight': settings.bodyWeightKg,
      'unitSystem': settings.unitSystem.wire,
      if (settings.language != null) 'language': settings.language!.code,
      'defaultRestTimer': settings.restSeconds,
      'hapticsEnabled': settings.hapticsEnabled,
      'effortScale': settings.effortScale.wire,
      // Die Schalter für Health Connect. Fehlt das Feld, gilt „an" — siehe
      // `UserSettings.healthWeightEnabled`.
      'healthWeightEnabled': settings.healthWeightEnabled,
      'healthSessionsEnabled': settings.healthSessionsEnabled,
      // Herzfrequenz — Felder, die es in der Vorgänger-App nicht gibt. Sie
      // lässt sie beim Schreiben stehen.
      if (settings.heartRate.hrMax != null) ...{
        'hrMax': settings.heartRate.hrMax,
        if (settings.heartRate.hrMaxSetAt != null)
          'hrMaxSetAt': Timestamp.fromDate(settings.heartRate.hrMaxSetAt!),
      },
      if (settings.heartRate.zones != null) ...{
        'hrZones': settings.heartRate.zones!.bounds,
        if (settings.heartRate.zonesSetAt != null)
          'hrZonesSetAt': Timestamp.fromDate(settings.heartRate.zonesSetAt!),
      },
      'updatedAt': Timestamp.now(),
      // `merge`: Im Profil stehen zwanzig Felder, die diese App nicht kennt.
      // Ohne merge wären sie nach dem ersten Speichern weg.
    }, SetOptions(merge: true));
  }

  static HeartRateSettings _heartRate(Map<String, dynamic> data) {
    final max = (data['hrMax'] as num?)?.round();
    final rawBounds = data['hrZones'];
    final bounds = rawBounds is List
        ? [
            for (final b in rawBounds)
              if (b is num) b.round()
          ]
        : const <int>[];
    final maxAt = data['hrMaxSetAt'];
    final zonesAt = data['hrZonesSetAt'];
    return HeartRateSettings(
      hrMax: max != null &&
              max >= HeartRateZones.minHrMax &&
              max <= HeartRateZones.maxHrMax
          ? max
          : null,
      hrMaxSetAt: maxAt is Timestamp ? maxAt.toDate() : null,
      // Eine ungültige Folge ist keine Einstellung — sie wird nicht
      // repariert, sondern gilt als nicht festgelegt.
      zones: HeartRateZones.tryFrom(bounds),
      zonesSetAt: zonesAt is Timestamp ? zonesAt.toDate() : null,
    );
  }

  static UserSettings _from(Map<String, dynamic>? data) {
    if (data == null) return const UserSettings();

    // R1 aus Vertrag 4: Im Bestand steht das Gewicht einmal als 70 und einmal
    // als 68.5. Ein `as int` oder `as double` fällt über je einen der beiden.
    final weight = (data['bodyWeight'] as num?)?.toDouble();
    final rest = (data['defaultRestTimer'] as num?)?.round();

    return UserSettings(
      bodyWeightKg: weight != null && weight > 0 ? weight : null,
      unitSystem: UnitSystem.fromWire(data['unitSystem']),
      language: AppLanguage.fromCode(data['language']),
      restSeconds: rest == null
          ? UserSettings.defaultRestSeconds
          : rest.clamp(
              UserSettings.minRestSeconds, UserSettings.maxRestSeconds),
      // Fehlt das Feld, ist Haptik an. Ein stiller Schalter, den niemand
      // gesetzt hat, sollte im aktiveren Zustand stehen.
      hapticsEnabled: data['hapticsEnabled'] != false,
      // Fehlt das Feld — im ganzen Bestand der Fall —, gilt RPE: die Skala,
      // in der alle bisherigen Angaben gemacht wurden.
      effortScale: EffortScale.fromWire(data['effortScale']),
      heartRate: _heartRate(data),
      healthWeightEnabled: data['healthWeightEnabled'] != false,
      healthSessionsEnabled: data['healthSessionsEnabled'] != false,
    );
  }
}
