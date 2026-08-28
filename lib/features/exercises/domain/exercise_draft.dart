import 'muscle.dart';

/// Was an einem Entwurf noch fehlt.
///
/// Feldgenau, nicht als Satz: Die Oberfläche muss den Fehler **am Feld**
/// zeigen können, nicht nur oben als Meldung. Ein „Bitte alles ausfüllen"
/// zwingt zum Suchen.
enum ExerciseDraftFault {
  /// Leerer Name. Die Regeln verlangen `name is string`, aber ein Name aus
  /// Leerzeichen käme durch — und wäre in der Liste unauffindbar.
  name,

  /// Keine Muskelgruppe. Die Regeln verlangen `muscleGroups is list`; eine
  /// leere Liste käme durch, aber die Übung hätte dann keine Kugel, keine
  /// Farbe und fiele aus jedem Filter.
  muscles,

  /// Keine Schwierigkeit. **Die schärfste Regel:** `difficulty is number`.
  /// Ohne Wert wird das Dokument abgewiesen.
  difficulty,
}

/// Eine Übung, wie sie geschrieben werden soll.
///
/// ## Warum ein eigener Typ neben [Exercise]
///
/// [Exercise] beschreibt, was **gelesen** wurde: Die Kennung steht fest, die
/// Quelle auch, und `difficulty` darf fehlen, weil der Bestand Übungen ohne
/// kennt. Beim Schreiben gilt das Gegenteil — die Kennung entsteht erst, die
/// Quelle ist immer `own`, und `difficulty` ist Pflicht.
///
/// ## Die Falle im Feld `difficulty`
///
/// Die Firestore-Regel lautet `difficulty is number`. Im Bestand stehen aber
/// 55 von 70 eigenen Übungen mit **Wörtern** (`beginner`, `intermediate`).
/// Diese Dokumente bleiben lesbar — [Difficulty.parse] bildet sie auf 1–4 ab.
/// Geschrieben wird jedoch ausnahmslos eine Zahl, sonst weist die Datenbank
/// das Dokument ab.
///
/// Daraus folgt: **Beim ersten Bearbeiten einer alten Übung wird das Wort
/// beiläufig zur Zahl.** Das ist keine Migration, es passiert nebenbei und
/// niemand muss davon erfahren. Eine eigene Migrationsaufgabe wäre Arbeit für
/// ein Problem, das sich von selbst erledigt.
class ExerciseDraft {
  const ExerciseDraft({
    this.id,
    required this.userId,
    required this.name,
    required this.muscleGroups,
    required this.difficulty,
    this.equipment = const [],
    this.type,
    this.description,
    this.instructions = const [],
    this.cues = const [],
  });

  /// `null` heißt anlegen, gesetzt heißt überschreiben.
  final String? id;

  final String userId;
  final String name;

  /// Mindestens eine — sonst hat die Übung keine Farbe und keinen Filter.
  final List<MuscleGroup> muscleGroups;

  /// 1 bis 5. **Immer eine Zahl**, siehe Klassendokumentation.
  final int difficulty;

  final List<String> equipment;

  /// `bodyweight` oder `strength`, roh — dieselben Werte wie im Bestand.
  final String? type;

  final String? description;
  final List<String> instructions;

  /// Kurze Merksätze, einer je Zeile — so liegen sie im Bestand und so
  /// schreibt es das Board.
  final List<String> cues;

  bool get isNew => id == null;

  /// Was fehlt. Leer heißt speicherbar.
  ///
  /// Die Prüfung liegt in der Domäne und nicht im Formular, damit sie ohne
  /// Widget prüfbar ist — sie ist die Stelle, an der ein Dokument entsteht,
  /// das die Regeln abweisen könnten.
  static Set<ExerciseDraftFault> faultsIn({
    required String name,
    required List<MuscleGroup> muscleGroups,
    required int? difficulty,
  }) =>
      {
        if (name.trim().isEmpty) ExerciseDraftFault.name,
        if (muscleGroups.isEmpty) ExerciseDraftFault.muscles,
        if (difficulty == null ||
            difficulty < Difficulty.min ||
            difficulty > Difficulty.max)
          ExerciseDraftFault.difficulty,
      };
}
