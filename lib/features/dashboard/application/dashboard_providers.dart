import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../weight/application/weight_providers.dart';
import '../../history/application/history_providers.dart';
import '../data/firestore_dashboard_repository.dart';
import '../domain/dashboard_data.dart';
import '../domain/dashboard_repository.dart';

/// Baut das Repository für den angemeldeten Nutzer.
///
/// Wirft, solange niemand angemeldet ist. Das ist kein Versehen: Das
/// Anmeldetor lässt den Dashboard-Screen gar nicht erst entstehen, und ein
/// stiller Leerzustand hier würde einen Fehler in der Reihenfolge verdecken.
///
/// In Tests über `overrideWithValue(PreviewDashboardRepository())` ersetzen.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    throw StateError(
      'dashboardRepositoryProvider ohne angemeldeten Nutzer gelesen — '
      'der Dashboard-Screen darf nur hinter dem Anmeldetor stehen.',
    );
  }

  return FirestoreDashboardRepository(
    firestore: FirebaseFirestore.instance,
    sessions: ref.watch(sessionRepositoryProvider),
    userId: user.uid,
    fallbackDisplayName: user.displayName,
    // Kein `watch`: Der Rückruf liest die Reihe erst, wenn gerechnet wird.
    // Sonst baute jeder neue Gewichtseintrag das Repository samt seiner drei
    // Firestore-Ströme neu auf. Den Neubau löst der gespiegelte Profilwert
    // aus (`WeightController._mirrorLatest`) — das Profil ist eine der drei
    // Quellen.
    bodyWeightOn: (date) =>
        ref.read(weightSeriesProvider).value?.kgOn(date),
  );
});

/// Der Zustand, den der Dashboard-Screen rendert.
final dashboardDataProvider = StreamProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchDashboard();
});
