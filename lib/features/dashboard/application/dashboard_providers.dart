import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dashboard_data.dart';
import '../domain/dashboard_repository.dart';

/// Konkrete Implementierung in `main.dart` überschreiben:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     dashboardRepositoryProvider.overrideWithValue(
///       FirestoreDashboardRepository(FirebaseFirestore.instance, uid),
///     ),
///   ],
///   child: const AtemApp(),
/// )
/// ```
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  throw UnimplementedError(
    'dashboardRepositoryProvider muss im ProviderScope überschrieben werden.',
  );
});

/// Der Zustand, den der Dashboard-Screen rendert.
final dashboardDataProvider = StreamProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchDashboard();
});
