import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/user_settings.dart';
import '../data/firestore_weight_repository.dart';
import '../domain/weight_entry.dart';
import '../domain/weight_repository.dart';
import '../domain/weight_series.dart';

final weightRepositoryProvider = Provider<WeightRepository>(
  (ref) => FirestoreWeightRepository(FirebaseFirestore.instance),
);

/// Die Gewichtsreihe des angemeldeten Kontos.
///
/// Ohne Anmeldung eine leere Reihe statt eines Fehlers — dieselbe Haltung wie
/// bei den Einstellungen: Ein Bildschirm, der noch niemandem gehört, hat einen
/// leeren Verlauf, keinen kaputten.
final weightSeriesProvider = StreamProvider<WeightSeries>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(WeightSeries.empty);
  return ref.watch(weightRepositoryProvider).watch(userId);
});

/// Der jüngste bekannte Wert — aus der Reihe, sonst aus dem Profil.
///
/// Die Einstellung „Körpergewicht" zeigt genau diesen Wert und schreibt ihn
/// nicht mehr selbst (Board 14, Abschnitt E).
final latestWeightProvider = Provider<WeightEntry?>((ref) {
  final series = ref.watch(weightSeriesProvider).value ?? WeightSeries.empty;
  final latest = series.latest;
  if (latest != null) return latest;

  // Kein Verlaufseintrag, aber ein Profilwert: der Zustand jedes Kontos, das
  // vor dem 20.09.2026 angelegt wurde. Er erscheint als Eintrag ohne Datum —
  // ein erfundenes Datum wäre schlimmer als gar keins (Board 14, E).
  final profile = ref.watch(settingsProvider).value?.bodyWeightKg;
  if (profile == null) return null;
  return WeightEntry(
    date: DateTime(1970),
    kg: profile,
    source: WeightSource.settings,
  );
});

/// Ob der jüngste Wert nur aus dem Profil stammt und noch kein Eintrag ist.
final weightIsUnseededProvider = Provider<bool>((ref) {
  final series = ref.watch(weightSeriesProvider).value ?? WeightSeries.empty;
  return series.isEmpty &&
      (ref.watch(settingsProvider).value?.bodyWeightKg != null);
});

/// Ein gerade geschriebener Eintrag, der noch zurückgenommen werden kann.
class PendingWeightEntry {
  const PendingWeightEntry({required this.saved, this.replaced});

  final WeightEntry saved;

  /// Was an diesem Tag vorher stand. `null`, wenn der Tag leer war — dann
  /// entfernt „Rückgängig" den Eintrag, statt einen alten zurückzuschreiben.
  final WeightEntry? replaced;
}

/// Schreibt Einträge und hält das Widerrufsfenster.
///
/// ## Warum sofort geschrieben wird
///
/// Wie beim Körpergewicht in Modul 7/8: Die Karte zeigt den neuen Punkt
/// bereits, während die Meldung noch steht. Ein aufgeschobener Schreibvorgang
/// hiesse, dass die Kurve etwas zeigt, was noch nicht gilt. „Rückgängig" ist
/// deshalb ein **zweiter Schreibvorgang**, kein Abbruch des ersten — bei einem
/// Gewichtswert ist das verlustfrei.
class WeightController extends Notifier<PendingWeightEntry?> {
  // Deckt sich mit AtemSnackbar.undoDuration: Rückgängig gibt es nur, solange
  // die Meldung steht. Board 14 nennt 30 s aus Modul 7 — seit dem 16.09.2026
  // stehen alle Meldungen 6 s (CLAUDE.md), und zwei Fristen im selben Produkt
  // wären ein Versprechen, das der eine Bildschirm nicht hält.
  static const window = Duration(seconds: 6);

  Timer? _timer;

  @override
  PendingWeightEntry? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  WeightSeries get _series =>
      ref.read(weightSeriesProvider).value ?? WeightSeries.empty;

  /// Trägt einen Wert ein oder ersetzt den des Tages.
  Future<void> save(WeightEntry entry) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final replaced = _series.entryOn(entry.date);
    await ref.read(weightRepositoryProvider).save(userId, entry);
    await _mirrorLatest(entry);

    _timer?.cancel();
    state = PendingWeightEntry(saved: entry, replaced: replaced);
    _timer = Timer(window, dismiss);
  }

  /// Übernimmt Einträge aus einer Gesundheitsquelle.
  ///
  /// **Ohne Widerrufsfenster und ohne Meldung je Eintrag.** Ein Abgleich ist
  /// keine einzelne Handlung, die sich zurücknehmen liesse — er kann zehn Tage
  /// auf einmal betreffen. Wer einen übernommenen Wert nicht will, ändert oder
  /// löscht ihn im Verlauf; dort steht er mit seiner Herkunft.
  ///
  /// Der Profilwert wird **einmal am Ende** nachgezogen, nicht je Eintrag.
  Future<void> importFromHealth(List<WeightEntry> entries) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || entries.isEmpty) return;

    final repository = ref.read(weightRepositoryProvider);
    for (final entry in entries) {
      await repository.save(userId, entry);
    }

    final latest = WeightSeries.of([..._series.entries, ...entries]).latest;
    if (latest != null) await _mirrorLatest(latest);
  }

  /// Löscht einen Eintrag. **Ohne Widerruf** — der Weg dorthin ist die
  /// zweistufige Bestätigung aus Modul 2, und zwei Sicherungen hintereinander
  /// sind eine zu viel.
  Future<void> delete(WeightEntry entry) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    dismiss();
    await ref.read(weightRepositoryProvider).delete(userId, entry.date);

    // War es der jüngste, rückt der davor nach — auch im Profil.
    final remaining = WeightSeries([
      for (final e in _series.entries)
        if (e.documentId != entry.documentId) e,
    ]);
    final latest = remaining.latest;
    if (latest != null) await _mirrorLatest(latest);
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  /// Nimmt den letzten Eintrag zurück: den vorherigen Tageswert wieder
  /// herstellen — oder „kein Wert", falls der Tag leer war.
  Future<void> undo() async {
    final pending = state;
    dismiss();
    if (pending == null) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final repository = ref.read(weightRepositoryProvider);
    final replaced = pending.replaced;
    if (replaced == null) {
      await repository.delete(userId, pending.saved.date);
    } else {
      await repository.save(userId, replaced);
    }

    final latest = WeightSeries.of([
      for (final e in _series.entries)
        if (e.documentId != pending.saved.documentId) e,
      if (replaced != null) replaced,
    ]).latest;
    if (latest != null) await _mirrorLatest(latest);
  }

  /// Hält `userProfiles/{uid}.bodyWeight` auf dem jüngsten Wert.
  ///
  /// Das Feld bleibt die Brücke zur Vorgänger-App und der Rückfall für jede
  /// Rechnung, die noch keine Reihe hat. Geschrieben wird nur, wenn der neue
  /// Eintrag tatsächlich der jüngste ist — ein nachgetragener Wert vom letzten
  /// Monat darf den aktuellen nicht überschreiben.
  Future<void> _mirrorLatest(WeightEntry entry) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final latest = _series.latest;
    if (latest != null && latest.date.isAfter(entry.date)) return;

    final settings = ref.read(settingsProvider).value ?? const UserSettings();
    if (settings.bodyWeightKg == entry.kg) return;
    await ref
        .read(settingsRepositoryProvider)
        .save(userId, settings.copyWith(bodyWeightKg: entry.kg));
  }
}

final weightControllerProvider =
    NotifierProvider<WeightController, PendingWeightEntry?>(
  WeightController.new,
);
