import 'package:meta/meta.dart';

/// Satz-Typ. Tap auf den Chip zykliert W → N → D → F.
///
/// Reine Daten: Farbe und Beschriftung leben in
/// `presentation/set_type_ui.dart`. Das Kürzel ist NICHT sprachneutral —
/// „W" für Warmup funktioniert im Deutschen nur zufällig, „Aufwärmsatz" wäre
/// „A". Deshalb kommt es aus dem ARB, nicht aus dem Enum.
enum SetType {
  warmup('warmup'),
  normal('normal'),
  dropset('dropset'),
  failure('failure');

  const SetType(this.wire);

  /// Der Wert, unter dem der Satztyp gespeichert wird. Nie anzeigen — dafür
  /// gibt es das ARB.
  final String wire;

  SetType get next => switch (this) {
        SetType.warmup => SetType.normal,
        SetType.normal => SetType.dropset,
        SetType.dropset => SetType.failure,
        SetType.failure => SetType.warmup,
      };
}

/// Was beim letzten Mal an dieser Stelle stand.
///
/// **Zahlen, kein fertiger Satz.** Vorher hielt der Satz ein `previousLabel`
/// wie „80 kg × 10" — also übersetzten Text mitten in der Domäne, was Vertrag 3
/// verbietet und jede Lokalisierung unmöglich macht. Solange die Attrappe die
/// einzige Quelle war, fiel es nicht auf; sobald die Werte aus dem echten
/// Bestand kommen, müsste die Datenschicht deutsch schreiben.
@immutable
class SetReference {
  const SetReference({this.weightKg, this.reps});

  final double? weightKg;
  final int? reps;

  bool get isEmpty => weightKg == null && reps == null;
}

@immutable
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.type,
    this.previous,
    required this.weight,
    required this.reps,
    this.hold = '',
    this.done = false,
    this.carried = false,
  });

  final String id;
  final SetType type;

  /// Referenz aus der Historie. `null`, wenn es keine gibt.
  final SetReference? previous;

  /// Als Text gehalten: das Feld ist die Wahrheit, solange getippt wird.
  final String weight;
  final String reps;

  /// Gehaltene Sekunden. Leer bei Übungen, die Wiederholungen zählen.
  final String hold;

  final bool done;

  /// Stammt der Wert aus dem **vorigen Satz**, nicht aus einer Eingabe?
  ///
  /// Beim Abhaken wandern Gewicht, Wiederholungen und Haltezeit in den
  /// nächsten offenen Satz. Übernommen ist nicht dasselbe wie eingetragen:
  /// Ein übernommener Wert ist ein Vorschlag, den man noch bestätigt oder
  /// ändert. Die Zeile zeigt ihn deshalb in Cyan, bis er angefasst wurde.
  ///
  /// Nur Anzeigezustand: Er wird nicht gespeichert und ist nach dem
  /// Wiederherstellen eines Zwischenstands wieder `false` — dort ist der Wert
  /// dann schlicht der Wert.
  final bool carried;

  WorkoutSet copyWith({
    SetType? type,
    String? weight,
    String? reps,
    String? hold,
    bool? done,
    bool? carried,
  }) {
    return WorkoutSet(
      id: id,
      type: type ?? this.type,
      previous: previous,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      hold: hold ?? this.hold,
      done: done ?? this.done,
      carried: carried ?? this.carried,
    );
  }

  double? get weightValue =>
      double.tryParse(weight.replaceAll(',', '.').trim());
  int? get repsValue => int.tryParse(reps.trim());
  int? get holdValue => int.tryParse(hold.trim());
}

@immutable
class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.muscles,
    this.recordWeightKg,
    this.targetReps,
    this.targetHoldSeconds,
    required this.sets,
  });

  final String id;
  final String name;

  /// Muskelgruppen, roh — die Übersetzung steht in der Oberfläche.
  final List<String> muscles;

  /// Das schwerste je protokollierte Gewicht dieser Übung, in Kilogramm.
  /// `null`, wenn es keins gibt — dann erscheint kein Chip statt „PR —".
  final double? recordWeightKg;

  /// Die Zielvorgabe aus dem Plan, als Text — „8-12" ist gültig.
  ///
  /// Sie steht **neben** dem Eingabefeld, nicht darin: Ein vorbelegtes Feld
  /// wäre nach dem Abhaken eine Leistungsangabe, die niemand gemacht hat.
  final String? targetReps;

  /// Die Haltezeit aus dem Plan, in Sekunden.
  ///
  /// Sie fehlte im Runner vollständig — wer im Plan „45 s halten" eintrug,
  /// bekam beim Training nur Wiederholungen und Gewicht zu sehen. Die
  /// Vorgabe war damit unsichtbar an genau der Stelle, an der sie gebraucht
  /// wird.
  final int? targetHoldSeconds;

  final List<WorkoutSet> sets;

  /// Trägt die Übung eine Haltezeit statt Wiederholungen?
  bool get isHold => targetHoldSeconds != null;

  WorkoutExercise copyWith({List<WorkoutSet>? sets}) => WorkoutExercise(
        id: id,
        name: name,
        muscles: muscles,
        recordWeightKg: recordWeightKg,
        targetReps: targetReps,
        targetHoldSeconds: targetHoldSeconds,
        sets: sets ?? this.sets,
      );
}

/// Die laufende Trainingseinheit.
@immutable
class ActiveWorkout {
  const ActiveWorkout({
    required this.sessionId,
    this.amendsSessionId,
    this.planId,
    this.title,
    required this.exercises,
    this.notes = '',
    this.defaultRestSeconds = 90,
    this.preWorkoutReadiness,
    this.postWorkoutFeeling,
  });

  final String sessionId;

  /// Die bestehende Einheit, die ergänzt wird.
  ///
  /// Ist sie gesetzt, wird beim Beenden **geändert statt angelegt** — sonst
  /// entstünde aus einem Nachtragen eine zweite Einheit am selben Tag.
  final String? amendsSessionId;

  /// Der Plan, aus dem die Einheit stammt. `null` beim freien Training.
  final String? planId;

  /// Der Planname. `null` beim freien Training — dann setzt die Oberfläche
  /// ihren eigenen Titel, statt einen erfundenen zu tragen.
  final String? title;
  final List<WorkoutExercise> exercises;
  final String notes;
  final int defaultRestSeconds;

  /// Wie bereit man sich vor dem Start gefühlt hat, 1 bis 5.
  ///
  /// Steht hier und nicht in [WorkoutStart], obwohl sie dort erfragt wird:
  /// `WorkoutStart` ist der Familienschlüssel des Providers, und ein Schlüssel,
  /// der die Antwort enthält, legte bei jeder Änderung eine zweite Einheit an.
  final int? preWorkoutReadiness;

  /// Wie es sich am Ende angefühlt hat, 1 bis 5. Wird beim Beenden erfragt.
  final int? postWorkoutFeeling;

  Iterable<WorkoutSet> get allSets => exercises.expand((e) => e.sets);
  int get completedSets => allSets.where((s) => s.done).length;
  int get totalSets => allSets.length;

  /// Bewegtes Gesamtvolumen in kg — Grundlage für den Load-Score.
  double get totalVolume {
    var v = 0.0;
    for (final s in allSets.where((s) => s.done)) {
      final w = s.weightValue, r = s.repsValue;
      if (w != null && r != null) v += w * r;
    }
    return v;
  }

  ActiveWorkout copyWith({
    List<WorkoutExercise>? exercises,
    String? notes,
    int? preWorkoutReadiness,
    int? postWorkoutFeeling,
  }) {
    return ActiveWorkout(
      sessionId: sessionId,
      amendsSessionId: amendsSessionId,
      planId: planId,
      title: title,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      defaultRestSeconds: defaultRestSeconds,
      preWorkoutReadiness: preWorkoutReadiness ?? this.preWorkoutReadiness,
      postWorkoutFeeling: postWorkoutFeeling ?? this.postWorkoutFeeling,
    );
  }
}
