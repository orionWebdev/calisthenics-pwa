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

/// Aktiver Tab der Bottom-Navigation (0–4).
final activeNavIndexProvider = StateProvider<int>((ref) => 0);

/// Steuert die laufende Session: Start-/Stoppzeit und Sekundentakt.
class SessionTimerController extends StateNotifier<Duration?> {
  SessionTimerController(this._ref) : super(null);

  final Ref _ref;
  DateTime? _startedAt;

  bool get isRunning => _startedAt != null;

  Future<void> toggle(String sessionId) async {
    final repo = _ref.read(dashboardRepositoryProvider);
    if (_startedAt != null) {
      await repo.stopSession(sessionId);
      _startedAt = null;
      state = null;
    } else {
      _startedAt = await repo.startSession(sessionId);
      state = Duration.zero;
    }
  }

  /// Vom Screen im Sekundentakt aufgerufen (Ticker läuft dort, damit er an
  /// den Lebenszyklus des Widgets gebunden ist).
  void tick() {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    state = DateTime.now().difference(startedAt);
  }
}

final sessionTimerProvider =
    StateNotifierProvider<SessionTimerController, Duration?>(
  SessionTimerController.new,
);
