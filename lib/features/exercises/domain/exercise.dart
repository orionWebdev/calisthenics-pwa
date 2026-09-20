import 'muscle.dart';

/// Woher eine Übung stammt.
enum ExerciseSource {
  /// Aus `exercises_curated` — kuratiert, vollständig, für alle gleich.
  curated,

  /// Aus `exercises` — selbst angelegt, oft spärlich.
  own,
}

/// Eine Übung.
///
/// ## Spärlich ist der Normalfall
///
/// Von 154 Übungen im Bestand haben **15** eine Beschreibung, **138** eine
/// Anleitung, und Cues und typische Fehler gibt es nur bei den 84 kuratierten.
/// Ein Modell mit lauter Pflichtfeldern würde also an der Mehrheit scheitern.
///
/// Deshalb ist hier fast alles optional, und die Oberfläche zeigt einen Block
/// nur, wenn er Daten hat. **Kein Platzhalter, keine Leerstelle** — der
/// Bildschirm hört einfach früher auf.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.source,
    this.nameDe,
    this.muscleGroups = const [],
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.equipment = const [],
    this.difficulty,
    this.type,
    this.description,
    this.instructions = const [],
    this.cues = const [],
    this.commonMistakes = const [],
    this.unilateral = false,
  });

  final String id;

  /// Der angezeigte Name.
  ///
  /// **Kann englisch sein.** 24 der kuratierten Übungen haben keinen deutschen
  /// Namen, und viele eigene sind ohnehin englisch benannt. Die Liste muss
  /// gemischte Sprachen aushalten; eine Kennzeichnung gibt es bewusst nicht —
  /// Namen sind Namen.
  final String name;

  /// Der deutsche Name, falls hinterlegt.
  ///
  /// Die Vorgänger-App liest ihn aus `name_de` und fällt sonst auf [name]
  /// zurück (`js/views/exercises/model.js`, `getExerciseName`). Genau das war
  /// hier lange nicht umgesetzt — die App zeigte durchweg die englischen
  /// Namen, obwohl deutsche im Bestand stehen.
  ///
  /// **Zwei Felder statt einem übersetzten**, weil die Datenschicht die
  /// Sprache nicht kennt und nicht kennen soll (Vertrag 3). Welcher gezeigt
  /// wird, entscheidet die Oberfläche.
  final String? nameDe;

  final ExerciseSource source;

  bool get isOwn => source == ExerciseSource.own;

  final List<MuscleGroup> muscleGroups;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;

  /// Rohwerte wie `dumbbell`, `pull-up-bar`, `none`. Übersetzt wird in der
  /// Oberfläche.
  final List<String> equipment;

  /// 1 bis 5, oder `null`.
  final int? difficulty;

  /// `bodyweight` oder `strength`, roh.
  final String? type;

  final String? description;
  final List<String> instructions;
  final List<String> cues;
  final List<String> commonMistakes;

  /// Wird diese Übung **je Seite** trainiert — Bizeps-Curl mit einer Hantel,
  /// Ausfallschritt, einarmiges Rudern? Dann trägt der Runner je Satz eine
  /// Seite (`LoggedSet.side`). Seit 18.09.2026; im Bestand bei keiner Übung
  /// gesetzt, deshalb `false` als Vorgabe. Auch ohne dieses Merkmal lässt sich
  /// im Runner je Übung auf „Seiten getrennt" umschalten.
  final bool unilateral;

  /// Wird die Übung an einer **Langhantel** ausgeführt?
  ///
  /// Entscheidet allein darüber, ob das Eingabeblatt die Scheibenrechnung
  /// anbietet. Nur an der Langhantel steckt man ein Gewicht zusammen; am
  /// Latzug, an der Kurzhantel und an der Kettlebell wählt man eines aus, und
  /// bei Körpergewichtsübungen ist die Angabe die Zusatzlast am Gürtel.
  ///
  /// Massstab ist [equipment], nicht [type]: Von 155 Übungen im Bestand nennen
  /// 13 eine Langhantel, 13 nennen gar kein Gerät — und diese 13 sind bis auf
  /// zwei Körpergewichtsübungen. **Ohne Geräteangabe also keine Rechnung.** Wer
  /// sie für eine eigene Übung will, trägt `barbell` oder `Langhantel` in
  /// „Ausrüstung" ein.
  ///
  /// `dumbbell` enthält die Zeichenfolge `barbell` **nicht** — die Prüfung auf
  /// einen Teilstring trifft die Kurzhantel nicht versehentlich mit.
  bool get usesBarbell => equipment.any((item) {
        final name = item.toLowerCase();
        return name.contains('barbell') || name.contains('langhantel');
      });

  /// Die Muskeln in der Reihenfolge, in der sie angezeigt werden: primär
  /// zuerst, sekundär danach, ohne Wiederholung.
  ///
  /// Fehlen beide Listen — bei den eigenen Übungen die Regel —, tritt
  /// [muscleGroups] an ihre Stelle.
  List<MuscleGroup> get displayMuscles {
    final ordered = <MuscleGroup>[];
    for (final group in [
      ...primaryMuscles,
      ...secondaryMuscles,
      ...muscleGroups
    ]) {
      if (!ordered.contains(group)) ordered.add(group);
    }
    return ordered;
  }

  /// Die Region, die die Farbe der Zeile bestimmt.
  MuscleRegion? get region => displayMuscles.firstOrNull?.region;

  /// Trägt die Übung überhaupt erklärenden Inhalt?
  ///
  /// Entscheidet, ob das Detail einen Hinweis zum Bearbeiten zeigt — und zwar
  /// **nur bei eigenen Übungen**. Bei einer kuratierten ohne Anleitung wäre der
  /// Hinweis eine Aufforderung an jemanden, der nichts ändern kann.
  bool get hasGuidance =>
      instructions.isNotEmpty ||
      cues.isNotEmpty ||
      commonMistakes.isNotEmpty ||
      (description != null && description!.isNotEmpty);
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
