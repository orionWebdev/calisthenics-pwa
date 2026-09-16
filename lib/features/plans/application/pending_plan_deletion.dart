import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/plan.dart';
import 'plan_providers.dart';

/// Das Widerrufsfenster beim Löschen eines Plans.
///
/// ## Warum aufgeschoben und nicht zurückgeschrieben
///
/// Beim Körpergewicht ist der Widerruf ein zweiter Schreibvorgang — eine Zahl
/// lässt sich verlustfrei zurücksetzen. Ein Plan nicht: Sein Dokument bekäme
/// beim Wiederherstellen eine **neue Kennung**, und jede Einheit, die auf die
/// alte zeigt, zeigte danach ins Leere.
///
/// Deshalb wird hier wie beim Löschen einer Einheit verfahren: Der Plan
/// verschwindet sofort aus der Liste, gelöscht wird er erst, wenn das Fenster
/// abgelaufen ist.
class PendingPlanDeletionController extends Notifier<Plan?> {
  // Deckt sich mit AtemSnackbar.undoDuration — Rückgängig gibt es nur,
  // solange die Meldung steht.
  static const window = Duration(seconds: 6);

  Timer? _timer;

  @override
  Plan? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  Future<void> start(Plan plan) async {
    await _commit();
    state = plan;
    _timer = Timer(window, () => unawaited(_commit()));
  }

  void undo() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  Future<void> _commit() async {
    final pending = state;
    _timer?.cancel();
    _timer = null;
    if (pending == null) return;

    // Zustand vor dem Schreiben zurücksetzen: Schlägt das Löschen fehl,
    // erscheint der Plan über den Strom von selbst wieder.
    state = null;
    await ref.read(planRepositoryProvider).deletePlan(pending.id);
  }
}

final pendingPlanDeletionProvider =
    NotifierProvider<PendingPlanDeletionController, Plan?>(
  PendingPlanDeletionController.new,
);

/// Die Pläne, die gerade sichtbar sind — ohne den schwebend gelöschten.
///
/// Wie bei den Einheiten eine **Ableitung** über dem Strom: Ein zweiter Strom
/// setzte die Firestore-Abfrage neu auf, sobald sich der Löschzustand ändert,
/// und ein Widerruf liesse die Liste durch den Ladezustand flackern.
final visiblePlansProvider = Provider<AsyncValue<List<Plan>>>((ref) {
  final pending = ref.watch(pendingPlanDeletionProvider)?.id;
  return ref.watch(plansProvider).whenData((plans) {
    if (pending == null) return plans;
    return [
      for (final plan in plans)
        if (plan.id != pending) plan,
    ];
  });
});
