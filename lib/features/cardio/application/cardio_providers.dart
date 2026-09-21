import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/application/history_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../history/domain/training_session.dart';
import '../data/cardio_live_store.dart';
import '../domain/distance_distribution.dart';
import '../domain/pace_series.dart';
import '../domain/weekly_distance.dart';
import '../../workout/domain/workout_clock.dart';

/// Nur die Ausdauereinheiten, neueste zuerst.
final cardioSessionsProvider = Provider<List<CardioSession>>((ref) {
  final sessions = ref.watch(sessionsProvider).value ?? const [];
  return sessions.whereType<CardioSession>().toList();
});

/// Wochenkilometer mit Schwellen und Verschiebung.
final weeklyDistanceProvider = Provider<WeeklyDistance>((ref) => WeeklyDistance
    .compute(
        ref.watch(sessionsProvider).value ?? const [],
        ref.watch(historyReferenceProvider)));

final distanceDistributionProvider = Provider<DistanceDistribution>((ref) =>
    DistanceDistribution.compute(ref.watch(sessionsProvider).value ?? const []));

/// Die Tempokurve einer Aktivität.
final paceSeriesProvider =
    Provider.family<PaceSeries, CardioActivity?>((ref, activity) =>
        PaceSeries.forActivity(
            ref.watch(sessionsProvider).value ?? const [], activity));

/// Der Maximalpuls aus dem Profil — was jemand **selbst eingetragen** hat.
///
/// Board 11, Sektion K: Stufe 1 der Kaskade führt nur mit gemessenem
/// Maximalpuls aus der Einheit oder aus dem Profil, nie aus einer Altersformel.
/// Der Haken stand bis zum 21.09.2026 leer; seitdem füllt ihn das Feld aus
/// den Herzfrequenz-Einstellungen (Board 16, D), ohne dass ein Bildschirm neu
/// gebaut werden musste. `null`, solange niemand einen Wert eingetragen hat —
/// geschätzt wird nie.
final profileMaxHrProvider = Provider<int?>(
  (ref) => ref.watch(settingsProvider).value?.heartRate.hrMax,
);

final cardioLiveStoreProvider =
    Provider<CardioLiveStore>((ref) => const CardioLiveStore());

/// Die laufende Live-Uhr — oder `null`.
///
/// Der Zustand ist die Datei: Jede Änderung wird sofort geschrieben, und beim
/// Start wird gelesen. Ein Prozesskill findet die Uhr so wieder, wie sie war.
class CardioLiveController extends AsyncNotifier<CardioLiveDraft?> {
  @override
  Future<CardioLiveDraft?> build() =>
      ref.watch(cardioLiveStoreProvider).read(DateTime.now());

  Future<void> start(CardioActivity activity) async {
    final draft = CardioLiveDraft(
      activity: activity,
      clock: WorkoutClock.startingAt(DateTime.now()),
    );
    await _set(draft);
  }

  Future<void> togglePause() async {
    final draft = state.value;
    if (draft == null) return;
    final now = DateTime.now();
    await _set(draft.copyWith(
      clock: draft.clock.isPaused
          ? draft.clock.resume(now)
          : draft.clock.pause(now),
    ));
  }

  Future<void> setDistance(String text) async {
    final draft = state.value;
    if (draft == null) return;
    await _set(draft.copyWith(distanceText: text));
  }

  /// Beendet die Uhr und liefert den Stand — für das vorbefüllte Formular.
  Future<CardioLiveDraft?> stop() async {
    final draft = state.value;
    if (draft == null) return null;
    final now = DateTime.now();
    final stopped = draft.copyWith(
        clock: draft.clock.isPaused ? draft.clock : draft.clock.pause(now));
    await ref.read(cardioLiveStoreProvider).clear();
    state = const AsyncData(null);
    return stopped;
  }

  Future<void> discard() async {
    await ref.read(cardioLiveStoreProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> _set(CardioLiveDraft draft) async {
    state = AsyncData(draft);
    await ref.read(cardioLiveStoreProvider).save(draft);
  }
}

final cardioLiveProvider =
    AsyncNotifierProvider<CardioLiveController, CardioLiveDraft?>(
  CardioLiveController.new,
);
