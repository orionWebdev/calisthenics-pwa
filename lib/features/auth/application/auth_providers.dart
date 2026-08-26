import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/auth_user.dart';

/// Die Anmeldung. Im Test über `overrideWithValue` ersetzbar.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
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
