import 'plan.dart';
import 'plan_draft.dart';

abstract interface class PlanRepository {
  Stream<List<Plan>> watchPlans(String userId);
  Future<List<Plan>> fetchPlans(String userId);

  /// Legt einen Plan an oder überschreibt ihn. Liefert die Kennung.
  Future<String> savePlan(PlanDraft draft);

  /// Löscht einen Plan.
  ///
  /// Anders als beim Löschen einer Übung reißt das nichts mit: Ein Plan wird
  /// von nichts referenziert. Absolvierte Einheiten tragen zwar `planId` und
  /// `planName`, aber der Name steht **im Dokument** — die Einheit bleibt also
  /// vollständig lesbar, auch wenn der Plan verschwindet.
  Future<void> deletePlan(String id);
}
