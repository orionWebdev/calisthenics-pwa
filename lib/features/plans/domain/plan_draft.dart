import '../../exercises/domain/exercise.dart';
import 'plan.dart';

/// Was an einem Planentwurf noch fehlt.
///
/// **Nur der Name.** Ein Plan ohne Einträge ist gültig — Board 07: „Der Plan
/// existiert, sobald er einen Namen hat."
///
/// Das war anders gedacht und ist eine Korrektur: Ein leerer Plan sei eine
/// Sackgasse, also solle er nicht speicherbar sein. Das verwechselt zwei
/// Fragen. Ob ein Plan **existieren** darf, entscheidet die Datenbank — sie
/// verlangt einen Namen. Ob er **startbar** ist, entscheidet die Oberfläche,
/// und die kann das sagen, ohne das Anlegen zu verbieten.
///
/// Der Unterschied ist praktisch: Wer einen Plan anlegt, tippt den Namen und
/// füllt ihn danach. Ihn beim ersten Schritt abzuweisen zwingt dazu, alles in
/// einem Zug zu tun.
enum PlanDraftFault {
  /// Leerer Name. Die Regeln verlangen `name is string`.
  name,
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

  static Set<PlanDraftFault> faultsIn({required String name}) => {
        if (name.trim().isEmpty) PlanDraftFault.name,
      };

  /// Startbar ist er erst mit Einträgen — eine Anzeigefrage, keine des
  /// Speicherns.
  static bool isStartable(List<PlanItem> items) => items.isNotEmpty;
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
