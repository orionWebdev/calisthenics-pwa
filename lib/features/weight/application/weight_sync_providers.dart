import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/health_gateway.dart';
import '../../../core/services/health_connect_gateway.dart';
import '../../history/application/history_providers.dart';
import '../domain/weight_entry.dart';
import '../domain/weight_series.dart';
import '../domain/weight_sync.dart';
import 'weight_providers.dart';

final healthGatewayProvider = Provider<HealthGateway>(
  (ref) => HealthConnectGateway(),
);

/// Was ein Lauf ergeben hat — **mit Zahlen, nicht mit „fertig"**.
class WeightSyncResult {
  const WeightSyncResult({
    required this.availability,
    required this.granted,
    this.imported = 0,
    this.published = 0,
    this.failedToPublish = 0,
  });

  final HealthAvailability availability;

  /// Ob Lesen und Schreiben von Gewicht freigegeben sind.
  final bool granted;

  /// Übernommene Messwerte.
  final int imported;

  /// Zurückgeschriebene eigene Einträge.
  final int published;

  /// Einträge, die die Quelle nicht angenommen hat. Sie bleiben in ATEM
  /// stehen und werden beim nächsten Lauf erneut angeboten — ein Fehler beim
  /// Zurückschreiben darf keinen Wert kosten.
  final int failedToPublish;

  bool get ran => availability == HealthAvailability.available && granted;

  bool get changedNothing => imported == 0 && published == 0;
}

/// Der Abgleich mit Health Connect (Produktstrategie 8.2, Schritt 1 und 2).
///
/// ## Noch ohne Auslöser
///
/// Niemand ruft [run] auf. Wann abgeglichen wird, wo der Zugang sitzt und wie
/// die fünf Berechtigungszustände aussehen, entscheidet Board 15 („Trainings
/// aus Health Connect übernehmen", Abschnitt 4) — gebaut wird gegen das Board,
/// nicht gegen eine Vermutung. Was hier steht, ist der Teil, den das Board
/// nicht bestimmt: lesen, rechnen, schreiben.
///
/// ## Warum das Fragen nach der Berechtigung ein Parameter ist
///
/// Ein Abgleich, der von sich aus den Systemdialog öffnet, überfällt jeden,
/// der die App aus einem anderen Grund gestartet hat. Fragen darf nur, wer
/// gerade danach gefragt wurde.
class WeightSyncController extends Notifier<AsyncValue<WeightSyncResult?>> {
  @override
  AsyncValue<WeightSyncResult?> build() => const AsyncData(null);

  Future<WeightSyncResult?> run({bool askForAccess = false}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _run(askForAccess));
    state = result;
    return result.value;
  }

  Future<WeightSyncResult> _run(bool askForAccess) async {
    final gateway = ref.read(healthGatewayProvider);

    final availability = await gateway.availability();
    if (availability != HealthAvailability.available) {
      return WeightSyncResult(availability: availability, granted: false);
    }

    var granted = await gateway.hasWeightAccess() ?? false;
    if (!granted && askForAccess) {
      granted = await gateway.requestWeightAccess();
    }
    if (!granted) {
      return WeightSyncResult(availability: availability, granted: false);
    }

    final reference = ref.read(historyReferenceProvider);
    final from = WeightSync.windowStart(reference);
    final to = WeightEntry.dayOf(reference)
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    // **Erst wenn die Reihe wirklich da ist.** Gegen eine leere Reihe zu
    // rechnen hiesse, die getippten Werte nicht zu kennen — und Regel 3
    // („eine Messung überschreibt keine Eingabe") könnte sie dann
    // überschreiben. Beim App-Start ist der Strom noch nicht angekommen.
    final series = await _loadedSeries();
    if (series == null) {
      // Lieber gar nichts tun als gegen einen Stand rechnen, den es nicht
      // gibt. Beim nächsten Öffnen läuft der Abgleich noch einmal.
      return WeightSyncResult(availability: availability, granted: true);
    }

    final measured = await gateway.readWeights(from: from, to: to);
    final plan = WeightSync.plan(
      series: series,
      measured: measured,
      ownSourceId: await gateway.ownSourceId(),
      reference: reference,
    );

    await ref
        .read(weightControllerProvider.notifier)
        .importFromHealth(plan.toSave);

    var published = 0;
    var failed = 0;
    for (final entry in plan.toPublish) {
      final ok = await gateway.writeWeight(
        // Mittags, nicht um Mitternacht: Ein Tageswert, der auf 00:00 sitzt,
        // fällt in anderen Apps je nach Zeitzone auf den Vortag.
        at: entry.date.add(const Duration(hours: 12)),
        kg: entry.kg,
        recordId: entry.documentId,
      );
      ok ? published++ : failed++;
    }

    return WeightSyncResult(
      availability: availability,
      granted: true,
      imported: plan.toSave.length,
      published: published,
      failedToPublish: failed,
    );
  }

  /// Die Reihe, sobald sie **geladen** ist — höchstens zehn Sekunden.
  ///
  /// ## Warum kein `weightSeriesProvider.future`
  ///
  /// Der Strom wird neu gebaut, sobald die Anmeldung eintrifft; die erste
  /// Zukunft läuft dann ins Leere.
  ///
  /// ## Warum `isLoading` mitgeprüft wird
  ///
  /// Beim Neubau trägt der Zustand den **alten** Wert weiter — den leeren aus
  /// der Zeit vor der Anmeldung. `hasValue` allein hielte ihn für die Reihe.
  Future<WeightSeries?> _loadedSeries() async {
    for (var i = 0; i < 100; i++) {
      final state = ref.read(weightSeriesProvider);
      if (state.hasValue && !state.isLoading) return state.requireValue;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }
}

final weightSyncProvider =
    NotifierProvider<WeightSyncController, AsyncValue<WeightSyncResult?>>(
  WeightSyncController.new,
);
