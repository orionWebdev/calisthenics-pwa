import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../auth/application/auth_providers.dart';
import '../data/firestore_account_repository.dart';
import '../data/firestore_settings_repository.dart';
import '../domain/settings_repository.dart';
import '../domain/user_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => FirestoreSettingsRepository(FirebaseFirestore.instance),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => FirestoreAccountRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  ),
);

/// Die Einstellungen des angemeldeten Kontos.
///
/// Ohne Anmeldung die Vorgaben statt eines Fehlers: Die Anmeldung selbst
/// braucht Sprache und Haptik schon, bevor jemand angemeldet ist.
final settingsProvider = StreamProvider<UserSettings>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const UserSettings());
  return ref.watch(settingsRepositoryProvider).watch(userId);
});

/// Die Einstellungen, sobald sie **geladen** sind — höchstens zehn Sekunden.
///
/// Wer eine Sperre aus den Einstellungen liest, darf nicht den Vorgabewert
/// nehmen, solange der Strom noch nicht geantwortet hat: „an" ist die
/// Vorgabe, und ein Abgleich, den jemand ausgeschaltet hat, liefe sonst beim
/// App-Start einmal los. `isLoading` wird mitgeprüft, weil der Zustand beim
/// Neubau den alten Wert weiterträgt.
Future<UserSettings> loadedSettings(Ref ref) async {
  // **Zuhören, solange gewartet wird.** Ein Provider ohne Zuhörer wird
  // angehalten und liefert nie einen Wert — in der App hält ihn die
  // Oberfläche wach, hier niemand.
  final subscription = ref.listen(settingsProvider, (_, __) {});
  try {
    for (var i = 0; i < 100; i++) {
      final state = ref.read(settingsProvider);
      if (state.hasValue && !state.isLoading) return state.requireValue;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  } finally {
    subscription.close();
  }
  // Lieber „aus" annehmen als etwas tun, das jemand ausgeschaltet haben
  // könnte: Beim nächsten Öffnen läuft der Abgleich noch einmal.
  return const UserSettings(
    healthWeightEnabled: false,
    healthSessionsEnabled: false,
  );
}

/// Die Sprache der App.
///
/// ## Die Systemsprache zählt genau einmal
///
/// Ist noch keine Sprache hinterlegt, gilt die des Geräts — und wird beim
/// ersten Speichern festgeschrieben. Ab da entscheidet die Einstellung, auch
/// wenn das Gerät später umgestellt wird.
///
/// Solange die Einstellungen laden, liefert der Provider `null`. Das ist
/// wichtig: Ein Vorgabewert während des Ladens liesse die App für einen
/// Wimpernschlag in der falschen Sprache aufblitzen. `null` heisst für
/// `MaterialApp`, dass sie selbst nach der Systemsprache entscheidet — und die
/// ist in aller Regel schon die richtige.
final localeProvider = Provider<Locale?>((ref) {
  final language = ref.watch(settingsProvider).value?.language;
  return language == null ? null : Locale(language.code);
});

/// Die Pausenzeit, die ein neues Training vorschlägt.
final defaultRestSecondsProvider = Provider<int>(
  (ref) =>
      ref.watch(settingsProvider).value?.restSeconds ??
      UserSettings.defaultRestSeconds,
);

/// In welcher Skala die Anstrengung je Satz erscheint — RPE oder RIR.
///
/// Reine Anzeigefrage: Gespeichert wird immer RPE, ein Wechsel wirkt sofort
/// auch auf alle früheren Sätze.
final effortScaleProvider = Provider<EffortScale>(
  (ref) => ref.watch(settingsProvider).value?.effortScale ?? EffortScale.rpe,
);

/// Ob Haptik überhaupt ausgelöst wird.
final hapticsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).value?.hapticsEnabled ?? true,
);

/// Schreibt Einstellungen und hält den Schreibzustand.
///
/// **Kein optimistisches Setzen.** Der Strom aus Firestore ist die Wahrheit;
/// er kommt mit dem lokalen Zwischenspeicher ohnehin sofort zurück. Einen
/// zweiten Zustand daneben zu führen hiesse, zwei Wahrheiten zu haben, von
/// denen eine bei einem Fehler stillschweigend falsch bliebe.
class SettingsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> update(UserSettings settings) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(settingsRepositoryProvider).save(userId, settings),
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AsyncValue<void>>(
  SettingsController.new,
);

/// Die Version, wie sie im Paket steht — **nicht als Konstante im Code**.
///
/// Eine Zeichenkette, die jemand beim Release von Hand nachziehen muss, ist
/// spätestens beim zweiten Release falsch. `1.0.0 (118)` liest sich aus
/// `pubspec.yaml` und der Build-Nummer des installierten Pakets.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});
