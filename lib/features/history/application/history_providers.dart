import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/firestore_session_repository.dart';
import '../domain/session_repository.dart';
import '../domain/training_session.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return FirestoreSessionRepository(FirebaseFirestore.instance);
});

/// Alle Einheiten des angemeldeten Nutzers, neueste zuerst.
///
/// Ohne Anmeldung ein leerer Strom statt eines Fehlers: Die Regeln würden
/// ohnehin mit `403` antworten, und „niemand angemeldet" ist kein Defekt. Ob
/// die App überhaupt etwas anzeigen darf, entscheidet der Anmeldezustand
/// weiter oben — nicht dieser Provider.
final sessionsProvider = StreamProvider<List<TrainingSession>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(sessionRepositoryProvider).watchSessions(userId);
});
