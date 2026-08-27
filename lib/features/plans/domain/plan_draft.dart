import '../../exercises/domain/exercise.dart';
import 'plan.dart';

/// Was an einem Planentwurf noch fehlt.
enum PlanDraftFault {
  /// Leerer Name. Die Regeln verlangen `name is string`.
  name,

  /// Kein einziger Eintrag.
  ///
  /// Die Regeln lassen einen leeren Plan durch — `hasAll(['name','userId'])`
  /// prüft `items` nicht. Wir lassen ihn trotzdem nicht zu: Ein Plan ohne
  /// Übungen kann nicht gestartet werden und stünde als Sackgasse in der Liste.
  items,
}

/// Ein Plan, wie er geschrieben werden soll.
class PlanDraft {
  const PlanDraft({
    this.id,
    required this.userId,
    required this.name,
    required this.items,
    this.icon,
    this.type,
  });

  /// `null` heißt anlegen.
  final String? id;

  final String userId;
  final String name;
  final List<PlanItem> items;
  final String? icon;
  final String? type;

  bool get isNew => id == null;

  static Set<PlanDraftFault> faultsIn({
    required String name,
    required List<PlanItem> items,
  }) =>
      {
        if (name.trim().isEmpty) PlanDraftFault.name,
        if (items.isEmpty) PlanDraftFault.items,
      };
}

/// Ein Planeintrag zusammen mit der Übung, auf die er zeigt.
///
/// ## Warum ein fehlender Verweis kein Fehler ist
///
/// Eine Übung kann gelöscht werden, während sie noch in Plänen steckt. Drei
/// Umgänge damit wären denkbar, und zwei davon sind schlecht:
///
/// **Den Eintrag mitlöschen** vernichtet die Zielwerte — drei Sätze, acht
/// Wiederholungen, neunzig Sekunden Pause. Die hat jemand einmal überlegt, und
/// sie gelten weiter, auch wenn die Übung wechselt.
///
/// **Den Plan sperren** bestraft für etwas, das an anderer Stelle passiert ist.
/// Ein Plan mit einer Lücke ist immer noch ein Plan.
///
/// Bleibt: **Die Lücke stehenlassen und benennen.** Der Eintrag behält seine
/// Zielwerte, wird als gestrichelte Fläche gezeichnet, und der erste angebotene
/// Weg heißt „Ersetzen" — nicht „Entfernen". Denn das Übliche ist, dass jemand
/// eine bessere Fassung derselben Bewegung will, nicht dass die Zeile weg soll.
class ResolvedPlanItem {
  const ResolvedPlanItem({required this.item, this.exercise});

  final PlanItem item;

  /// `null`, wenn die Übung gelöscht wurde oder nie existierte.
  final Exercise? exercise;

  bool get isDangling => exercise == null;

  /// Löst alle Einträge eines Plans gegen den Übungsbestand auf.
  static List<ResolvedPlanItem> resolve(
    List<PlanItem> items,
    List<Exercise> exercises,
  ) {
    final byId = {for (final e in exercises) e.id: e};
    return [
      for (final item in items)
        ResolvedPlanItem(item: item, exercise: byId[item.exerciseId]),
    ];
  }
}
