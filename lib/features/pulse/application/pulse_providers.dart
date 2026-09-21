import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../../settings/domain/user_settings.dart';
import '../domain/heart_rate_zones.dart';

/// HFmax und Zonengrenzen — was in den Einstellungen steht, nichts sonst.
final heartRateSettingsProvider = Provider<HeartRateSettings>(
  (ref) =>
      ref.watch(settingsProvider).value?.heartRate ?? const HeartRateSettings(),
);

/// Die festgelegten Zonen — oder `null`.
///
/// **Ohne Grenzen keine Verteilung.** ATEM rechnet keine, solange sie fehlen,
/// und schlägt auch keine still vor: Ein Vorschlag aus HFmax ist ein Angebot
/// in den Einstellungen, nie ein Wert, der im Einheitendetail als Norm
/// erscheint (Board 16, Entscheidung 13).
final heartRateZonesProvider = Provider<HeartRateZones?>(
  (ref) => ref.watch(heartRateSettingsProvider).zones,
);

/// Schreibt HFmax und Zonen.
///
/// Über [SettingsController.update]: Es gibt ein Profildokument, und ein
/// zweiter Schreibweg daneben wäre eine zweite Wahrheit. Gelesen wird der
/// **aktuelle** Stand aus dem Strom, damit ein Schreiben die übrigen
/// Einstellungen nicht auf Vorgabewerte zurücksetzt.
class HeartRateController {
  HeartRateController(this._ref);

  final Ref _ref;

  Future<void> setHrMax(int bpm, {DateTime? at}) => _write(
        (s) => s.copyWith(
          heartRate: s.heartRate.copyWith(
            hrMax: bpm,
            hrMaxSetAt: at ?? DateTime.now(),
          ),
        ),
      );

  Future<void> setZones(HeartRateZones zones, {DateTime? at}) => _write(
        (s) => s.copyWith(
          heartRate: s.heartRate.copyWith(
            zones: zones,
            zonesSetAt: at ?? DateTime.now(),
          ),
        ),
      );

  Future<void> _write(UserSettings Function(UserSettings) change) async {
    final current = _ref.read(settingsProvider).value ?? const UserSettings();
    await _ref
        .read(settingsControllerProvider.notifier)
        .update(change(current));
  }
}

final heartRateControllerProvider =
    Provider<HeartRateController>(HeartRateController.new);
