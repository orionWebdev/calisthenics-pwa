import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_import/application/health_import_providers.dart';
import '../../domain/session_detail.dart';
import '../../domain/training_session.dart';

/// Was die Uhr zu einer Einheit gemessen hat — **als drei Zustände**.
///
/// - **Lädt**: Der Strom der Uhr-Datensätze hat noch nicht geantwortet. Die
///   Kacheln, die von ihm abhängen, stehen im Skelett; nie eine Null.
/// - **Fehler**: Er antwortet nicht. Das ist ein Fehler und bleibt sichtbar,
///   weil es Daten gibt, die man erwarten darf.
/// - **Daten oder `null`**: `null` heisst, dass die Einheit keine Uhr hat —
///   oder der Datensatz fehlt. Das ist **kein** Fehler und verschwindet
///   vollständig (Board 16, C6).
///
/// Eine Einheit ohne Verknüpfung fragt gar nicht erst: Für sie gibt es keine
/// Quelle, und ein Ladezustand wäre eine Behauptung.
final watchFiguresProvider =
    Provider.family<AsyncValue<WatchFigures?>, TrainingSession>(
  (ref, session) {
    final linked = session.healthSessionId;
    if (linked == null) return const AsyncData(null);

    final records = ref.watch(healthSessionsProvider);
    return records.when(
      loading: () => const AsyncLoading(),
      error: (e, s) => AsyncError(e, s),
      data: (all) {
        for (final r in all) {
          if (r.externalId != linked) continue;
          return AsyncData(WatchFigures(
            start: r.start,
            end: r.end,
            pulse: r.pulse,
            averageHeartRate: r.averageHeartRate,
            maxHeartRate: r.maxHeartRate,
            calories: r.calories,
            distanceKm: r.distanceKm,
            deviceName: r.deviceName,
          ));
        }
        return const AsyncData(null);
      },
    );
  },
);
