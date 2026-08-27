import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
