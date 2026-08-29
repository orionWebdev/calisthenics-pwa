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

import 'package:meta/meta.dart';

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

/// Die Aktivität einer Ausdauereinheit.
///
/// Acht Werte, wie Board 11 sie festlegt. Vier davon kommen im Bestand nie
/// vor (Indoor-Rad, Schwimmen, Gehen, Rudern) — sie sind gestaltet, aber
/// nicht gleich laut. Unbekannte Zeichenketten landen in
/// [CardioSession.rawActivity]; `other` ist ein echter Wert (5 Dokumente).
///
/// Yoga, Sauna und Dehnen sind **keine** Ausdauer — im Bestand tragen sie
/// ausschliesslich `type: recovery`. Sie stehen in [RecoveryKind].
enum CardioActivity {
  run('run'),
  bike('bike'),

  /// Die Vorgänger-App kennt den Wert nicht und zeigt dann „Cardio" — sie
  /// verwirft ihn nicht.
  bikeIndoor('bikeIndoor'),
  swim('swim'),
  hike('hike'),
  walk('walk'),
  row('row'),
  other('other');

  const CardioActivity(this.wire);

  final String wire;

  /// Wird das Tempo als Geschwindigkeit gelesen?
  ///
  /// Rad, Indoor-Rad und Rudern rechnen in km/h, alles andere in min/km —
  /// „die Einheit steht im Wert, nicht im Schlüssel" (Board 11, G).
  bool get usesSpeed => switch (this) {
        CardioActivity.bike ||
        CardioActivity.bikeIndoor ||
        CardioActivity.row =>
          true,
        _ => false,
      };

  static CardioActivity? fromWire(String? value) {
    for (final activity in values) {
      if (activity.wire == value) return activity;
    }
    return null;
  }
}

/// Die Art einer Regenerationseinheit.
///
/// Vier Werte laut Board 11. Die Vorgänger-App schreibt dasselbe Feld
/// (`activityType`) mit einem grösseren Vorrat — `foam_roll`, `walk`,
/// `meditation` — der hier als [RecoverySession.rawKind] überlebt.
enum RecoveryKind {
  yoga('yoga'),
  sauna('sauna'),

  /// Der Draht heisst `stretching`, wie in den fünf Dokumenten des Bestands.
  stretch('stretching'),
  mobility('mobility');

  const RecoveryKind(this.wire);

  final String wire;

  static RecoveryKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// Das Tempo einer Ausdauereinheit — **immer gerechnet, nie gespeichert**.
///
/// Distanz und Dauer sind die Wahrheit. Ein drittes Feld, das von beiden
/// abhängt, müsste bei jeder Korrektur entscheiden, welches es überschreibt
/// (Board 11, Entscheidung „Tempo als Eingabefeld"). Ohne Distanz gibt es
/// kein Tempo — dann steht „—", und die Einheit zählt trotzdem in Minuten.
@immutable
class CardioTempo {
  const CardioTempo._({required this.minutesPerKm, required this.usesSpeed});

  /// Minuten je Kilometer, unabhängig von der Anzeigeeinheit.
  final double minutesPerKm;

  /// Ob die Anzeige in km/h erfolgt.
  final bool usesSpeed;

  double get kmPerHour => 60 / minutesPerKm;

  /// Der Wert in der Einheit der Aktivität — für Vergleiche innerhalb einer
  /// Aktivität, nie darüber hinaus.
  double get value => usesSpeed ? kmPerHour : minutesPerKm;

  /// `null`, wenn Distanz oder Dauer fehlen oder null sind.
  static CardioTempo? of({
    required double? distanceKm,
    required Duration? duration,
    required CardioActivity? activity,
  }) {
    if (distanceKm == null || duration == null) return null;
    if (distanceKm <= 0 || duration <= Duration.zero) return null;
    return CardioTempo._(
      minutesPerKm: duration.inMilliseconds / 60000 / distanceKm,
      usesSpeed: activity?.usesSpeed ?? false,
    );
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

  /// Eine Kopie mit anderem Datum oder anderer Dauer.
  ///
  /// **Bewusst nur diese beiden Felder.** Sie sind die einzigen, die in die
  /// Bewertung eingehen — das Datum über die Tagesschlüssel der EMA, die Dauer
  /// über die Ersatzrechnung der Last. Ein vollständiges `copyWith` mit
  /// zwanzig Parametern wäre eine Einladung, die Einheit an beliebiger Stelle
  /// umzubauen; gebraucht wird es an genau einer: um auszurechnen, was eine
  /// Änderung anrichtet, **bevor** sie geschrieben wird.
  TrainingSession copyWith({DateTime? date, Duration? duration});
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

  @override
  StrengthSession copyWith({DateTime? date, Duration? duration}) =>
      StrengthSession(
        id: id,
        userId: userId,
        date: date ?? this.date,
        createdAt: createdAt,
        bodyweight: bodyweight,
        exercises: exercises,
        duration: duration ?? this.duration,
        notes: notes,
        rpe: rpe,
        preWorkoutEnergy: preWorkoutEnergy,
        postWorkoutFeeling: postWorkoutFeeling,
        planId: planId,
        planName: planName,
        discipline: discipline,
      );
}

/// Laufen, Rad, Wandern, Schwimmen — alles mit Strecke statt Sätzen.
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
    this.avgHr,
    this.maxHr,
    this.name,
  });

  final CardioActivity? activity;

  /// Der rohe Wert, falls er zu keiner bekannten Aktivität passt. Damit
  /// überlebt die App einen neuen Wert aus der PWA, ohne ihn zu verlieren.
  final String? rawActivity;

  final double? distanceKm;

  final int? avgHr;
  final int? maxHr;
  final String? name;

  /// Das Tempo, gerechnet aus Distanz und Dauer. `null` ohne Distanz.
  ///
  /// Der Bestand trägt ein Feld `pace` — es wird **nicht gelesen**. Wo beide
  /// vorkommen, stimmt es mit dieser Rechnung überein; wo nur das Feld stünde,
  /// wäre es eine Zahl ohne Grundlage.
  CardioTempo? get tempo => CardioTempo.of(
        distanceKm: distanceKm,
        duration: duration,
        activity: activity,
      );

  /// Minuten je Kilometer — die Grösse, in der Perzentil und Vergleich
  /// rechnen. Für Rad und Rudern ist das nur eine andere Schreibweise der
  /// Geschwindigkeit; verglichen wird ohnehin nur innerhalb einer Aktivität.
  double? get pace => tempo?.minutesPerKm;

  @override
  SessionKind get kind => SessionKind.cardio;

  @override
  CardioSession copyWith({DateTime? date, Duration? duration}) => CardioSession(
        id: id,
        userId: userId,
        date: date ?? this.date,
        createdAt: createdAt,
        activity: activity,
        rawActivity: rawActivity,
        duration: duration ?? this.duration,
        notes: notes,
        rpe: rpe,
        preWorkoutEnergy: preWorkoutEnergy,
        postWorkoutFeeling: postWorkoutFeeling,
        distanceKm: distanceKm,
        avgHr: avgHr,
        maxHr: maxHr,
        name: name,
      );
}

/// Regeneration — im Bestand ohne jede Kennzahl außer Dauer und Art.
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
    this.recoveryKind,
    this.rawKind,
    this.name,
  });

  /// Yoga, Sauna, Dehnen, Mobility. `null`, wenn nichts oder Unbekanntes
  /// hinterlegt ist — dann steht der Rohwert in [rawKind].
  final RecoveryKind? recoveryKind;

  /// Der Draht, falls er zu keiner bekannten Art passt (`foam_roll`,
  /// `meditation`, `walk` aus der Vorgänger-App).
  final String? rawKind;

  final String? name;

  @override
  SessionKind get kind => SessionKind.recovery;

  @override
  RecoverySession copyWith({DateTime? date, Duration? duration}) =>
      RecoverySession(
        id: id,
        userId: userId,
        date: date ?? this.date,
        createdAt: createdAt,
        duration: duration ?? this.duration,
        notes: notes,
        rpe: rpe,
        preWorkoutEnergy: preWorkoutEnergy,
        postWorkoutFeeling: postWorkoutFeeling,
        recoveryKind: recoveryKind,
        rawKind: rawKind,
        name: name,
      );
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

  @override
  UnknownSession copyWith({DateTime? date, Duration? duration}) =>
      UnknownSession(
        id: id,
        userId: userId,
        date: date ?? this.date,
        createdAt: createdAt,
        rawType: rawType,
        duration: duration ?? this.duration,
        notes: notes,
        rpe: rpe,
        preWorkoutEnergy: preWorkoutEnergy,
        postWorkoutFeeling: postWorkoutFeeling,
      );
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

/// Ein Satz. Alle Werte können fehlen — im Bestand kommen sowohl `null` als
/// auch vollständig leere Einträge vor.
class LoggedSet {
  const LoggedSet({this.reps, this.weight, this.holdSeconds, this.rawType});

  final int? reps;
  final double? weight;

  /// Haltezeit in Sekunden — für statische Übungen. Im Bestand bei 21 Sätzen,
  /// immer zusammen mit [rawType] `hold`.
  final int? holdSeconds;

  /// Der rohe Wert des Feldes `type` am Satz.
  ///
  /// Bewusst als Zeichenkette und nicht als Aufzählung: Im Bestand kommt
  /// ausschließlich `hold` vor, der Runner kennt daneben Aufwärm-, Drop- und
  /// Failure-Sätze. Beide Vokabulare teilen sich dasselbe Feld, ohne dass eine
  /// Seite die andere kennt. Eine Aufzählung würde behaupten, die Menge sei
  /// bekannt.
  final String? rawType;

  bool get isEmpty =>
      reps == null && weight == null && holdSeconds == null && rawType == null;
}
