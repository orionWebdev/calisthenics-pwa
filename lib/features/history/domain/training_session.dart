/// Absolvierte Trainingseinheiten — die Collection `sessions`.
///
/// Reines Dart, kein Flutter, kein Firestore (Vertrag 3, Schichtregeln). Die
/// Übersetzung aus einem Firestore-Dokument liegt in `data/session_mapper.dart`.
///
/// ## Warum eine versiegelte Hierarchie
///
/// Von 136 Dokumenten im Produktivbestand tragen nur vier Felder **alle**:
/// `userId`, `createdAt`, `date`, `type`. Alles Weitere hängt an der Art:
/// Krafteinheiten tragen Übungen, Cardio trägt Strecke, Pace und Puls. Eine
/// einzige Klasse mit zwei Dutzend optionalen Feldern könnte nicht ausdrücken,
/// dass `distanceKm` bei einer Krafteinheit nicht fehlt, sondern bedeutungslos
/// ist. Siehe `docs/contracts/04-firestore-schema.md`.
library;

/// Die Art einer Einheit — der Diskriminator `type` im Dokument.
enum SessionKind {
  strength('strength'),
  bodyweight('bodyweight'),
  cardio('cardio'),
  recovery('recovery');

  const SessionKind(this.wire);

  /// Der Wert, wie er in Firestore steht. Nie übersetzen, nie anzeigen.
  final String wire;

  static SessionKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// Die Aktivität einer Cardio-Einheit.
///
/// `other` ist kein Auffangbecken für Unbekanntes, sondern ein echter Wert im
/// Bestand (5 Dokumente). Unbekannte Zeichenketten landen in
/// [CardioSession.rawActivity].
enum CardioActivity {
  run('run'),
  bike('bike'),
  hike('hike'),
  walk('walk'),
  stretching('stretching'),
  yoga('yoga'),
  sauna('sauna'),
  other('other');

  const CardioActivity(this.wire);

  final String wire;

  static CardioActivity? fromWire(String? value) {
    for (final activity in values) {
      if (activity.wire == value) return activity;
    }
    return null;
  }
}

/// Gemeinsamer Kern jeder Einheit.
sealed class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.userId,
    required this.date,
    required this.createdAt,
    this.duration,
    this.notes,
    this.rpe,
    this.preWorkoutEnergy,
    this.postWorkoutFeeling,
  });

  final String id;
  final String userId;

  /// Wann trainiert wurde.
  final DateTime date;

  /// Wann der Eintrag entstand. Weicht ab, wenn nachträglich erfasst wurde.
  final DateTime createdAt;

  /// Dauer der Einheit. `null`, wenn nicht erfasst — im Bestand bei 25 von 136.
  final Duration? duration;

  final String? notes;

  /// Anstrengung auf einer Skala von **1 bis 5** — nicht die übliche
  /// RPE-Skala von 1 bis 10. Im Bestand kommen 1 bis 4 vor.
  ///
  /// Steht auf der Basisklasse, weil das Feld in allen vier Arten vorkommt,
  /// jeweils in etwa zwei Dritteln der Dokumente. Die Lastberechnung liest es
  /// auch bei Cardio.
  final int? rpe;

  /// Ebenfalls in allen Arten, in genau denselben Dokumenten wie [rpe].
  final int? preWorkoutEnergy;
  final int? postWorkoutFeeling;

  SessionKind? get kind;

  /// Trägt die Einheit Satzdaten?
  ///
  /// Auch bei Kraft nicht selbstverständlich: 16 der 63 Krafteinheiten im
  /// Bestand haben gar keine Übungen. Das ist gültiger Bestand, kein Fehler.
  bool get hasExerciseData => false;
}

/// Kraft und Körpergewicht — beide tragen Übungen und dieselben Felder.
final class StrengthSession extends TrainingSession {
  const StrengthSession({
    required super.id,
    required super.userId,
    required super.date,
    required super.createdAt,
    required this.bodyweight,
    this.exercises = const [],
    super.duration,
    super.notes,
    super.rpe,
    super.preWorkoutEnergy,
    super.postWorkoutFeeling,
    this.planId,
    this.planName,
    this.discipline,
  });

  /// `true` für `type: bodyweight`, `false` für `type: strength`. Die Daten
  /// sind identisch aufgebaut; nur der Diskriminator unterscheidet sie.
  final bool bodyweight;

  final List<LoggedExercise> exercises;
  final String? planId;
  final String? planName;

  /// `bodyweight` oder `weights` — im Bestand 14 beziehungsweise 3 Dokumente.
  /// Steuert im Scoring den Multiplikator der Ersatzrechnung nach Dauer.
  final String? discipline;

  @override
  SessionKind get kind =>
      bodyweight ? SessionKind.bodyweight : SessionKind.strength;

  @override
  bool get hasExerciseData => exercises.isNotEmpty;
}

/// Laufen, Rad, Wandern, Dehnen, Sauna — alles ohne Satzprotokoll.
final class CardioSession extends TrainingSession {
  const CardioSession({
    required super.id,
    required super.userId,
    required super.date,
    required super.createdAt,
    this.activity,
    this.rawActivity,
    super.duration,
    super.notes,
    super.rpe,
    super.preWorkoutEnergy,
    super.postWorkoutFeeling,
    this.distanceKm,
    this.pace,
    this.avgHr,
    this.maxHr,
    this.name,
  });

  final CardioActivity? activity;

  /// Der rohe Wert, falls er zu keiner bekannten Aktivität passt. Damit
  /// überlebt die App einen neuen Wert aus der PWA, ohne ihn zu verlieren.
  final String? rawActivity;

  final double? distanceKm;

  /// Minuten je Kilometer.
  final double? pace;

  final int? avgHr;
  final int? maxHr;
  final String? name;

  @override
  SessionKind get kind => SessionKind.cardio;
}

/// Regeneration — im Bestand ohne jede Kennzahl außer Dauer.
final class RecoverySession extends TrainingSession {
  const RecoverySession({
    required super.id,
    required super.userId,
    required super.date,
    required super.createdAt,
    super.duration,
    super.notes,
    super.rpe,
    super.preWorkoutEnergy,
    super.postWorkoutFeeling,
    this.name,
  });

  final String? name;

  @override
  SessionKind get kind => SessionKind.recovery;
}

/// Eine Einheit mit unbekanntem `type`.
///
/// Existiert, damit ein neuer Typ aus der PWA die App nicht zum Absturz bringt
/// und die Einheit auch nicht stillschweigend verschwindet. Sie zählt in
/// Summen mit; die Oberfläche zeigt sie neutral.
final class UnknownSession extends TrainingSession {
  const UnknownSession({
    required super.id,
    required super.userId,
    required super.date,
    required super.createdAt,
    required this.rawType,
    super.duration,
    super.notes,
    super.rpe,
    super.preWorkoutEnergy,
    super.postWorkoutFeeling,
  });

  final String? rawType;

  @override
  SessionKind? get kind => null;
}

/// Eine Übung innerhalb einer Krafteinheit.
class LoggedExercise {
  const LoggedExercise({
    required this.exerciseId,
    this.sets = const [],
    this.usesBodyweight,
  });

  /// Slug wie `push_up`, `pull_up` — zeigt auf `exercises_curated` oder
  /// `exercises`. **Nicht** die Dokument-ID aus `progress`, siehe Vertrag 4.
  final String exerciseId;

  final List<LoggedSet> sets;

  /// Zählt beim Volumen das Körpergewicht statt der Hantellast?
  ///
  /// Im Bestand bei 77 von 292 Einträgen gesetzt. Die PWA schlägt sonst in der
  /// Übungsdatenbank nach — **dort trägt aber kein einziges der 154 Dokumente
  /// dieses Feld**, der Rückfallpfad greift also nie. Siehe Vertrag 4.
  final bool? usesBodyweight;
}

/// Ein Satz. Beide Werte können fehlen — im Bestand kommen sowohl `null` als
/// auch vollständig leere Einträge vor.
class LoggedSet {
  const LoggedSet({this.reps, this.weight});

  final int? reps;
  final double? weight;

  bool get isEmpty => reps == null && weight == null;
}
