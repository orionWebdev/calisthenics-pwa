import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../data/firestore_access_repository.dart';
import '../domain/access.dart';
import '../domain/auth_user.dart';

/// Die Anmeldung. Im Test über `overrideWithValue` ersetzbar.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final allowlistRepositoryProvider = Provider<AllowlistRepository>((ref) {
  return FirestoreAllowlistRepository(FirebaseFirestore.instance);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirestoreProfileRepository(FirebaseFirestore.instance);
});

/// Wer gerade angemeldet ist — `null`, solange niemand.
///
/// Kein `autoDispose`: Der Anmeldezustand überlebt jeden Bildschirm, und ein
/// Abriss des Stroms würde die App kurzzeitig abgemeldet aussehen lassen.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authState();
});

/// Die UID, oder `null`. Bequemlichkeit für Provider, die nur den Schlüssel
/// brauchen und nicht bei jedem Namenswechsel neu bauen sollen.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

/// Wo die angemeldete Person auf dem Weg in die App steht.
///
/// Zwei Abfragen hängen daran — Zugangsliste und Profil —, deshalb ein
/// [FutureProvider] statt einer Ableitung. Solange er lädt, gilt der Zustand
/// als **unentschieden**, nicht als abgemeldet: Der Unterschied ist der ganze
/// Grund, warum es einen Splash gibt.
final accessProvider = FutureProvider<AccessState>((ref) async {
  final auth = ref.watch(authStateProvider);

  // Der Anmeldestrom selbst ist noch nicht geantwortet.
  if (auth.isLoading) return AccessState.undecided;

  final user = auth.value;
  if (user == null) return AccessState.signedOut;

  final allowed = await ref.watch(allowlistRepositoryProvider).isAllowed(user);
  if (!allowed) {
    return AccessState(AccessStage.waitlisted, user: user);
  }

  final weight =
      await ref.watch(profileRepositoryProvider).bodyWeightKg(user.uid);
  return AccessState(
    weight == null ? AccessStage.onboarding : AccessStage.granted,
    user: user,
  );
});
