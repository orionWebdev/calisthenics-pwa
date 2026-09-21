import 'training_session.dart';

/// Eine abgeschlossene Einheit, wie sie geschrieben werden soll.
///
/// Absichtlich **nicht** [TrainingSession]: Die trägt eine Dokument-ID und
/// einen Erfassungszeitpunkt, die erst beim Schreiben entstehen. Ein Modell für
/// beide Richtungen müsste beides optional führen und könnte dann nicht mehr
/// ausdrücken, dass eine gelesene Einheit immer eine ID hat.
class SessionDraft {
  const SessionDraft({
    required this.userId,
    required this.kind,
    required this.date,
    required this.duration,
    this.exercises = const [],
    this.notes,
    this.planId,
    this.planName,
    this.scheduleId,
    this.rpe,
    this.activity,
    this.distanceKm,
    this.avgHr,
    this.maxHr,
    this.recoveryKind,
    this.durationHasSeconds = false,
    this.preWorkoutReadiness,
    this.postWorkoutFeeling,
    this.workoutFocus,
    this.healthSessionId,
    this.fromHealth = false,
    this.startedAt,
  });

  final String userId;
  final SessionKind kind;

  /// Der Trainingstag. Wird auf Mitternacht gesetzt — so schreibt es die PWA,
  /// und der Tagesschlüssel im Scoring erwartet es so.
  final DateTime date;

  /// Wann begonnen wurde, **mit Uhrzeit** — oder `null`, wenn es niemand
  /// weiss (nachgetragene Einheiten). Ohne sie kann nichts gepaart werden;
  /// siehe `TrainingSession.startedAt`.
  final DateTime? startedAt;

  final Duration duration;
  final List<LoggedExercise> exercises;
  final String? notes;
  final String? planId;
  final String? planName;

  /// Der Termin, aus dem die Einheit entstanden ist. Ist er gesetzt, wird er
  /// beim Speichern als erledigt markiert.
  final String? scheduleId;

  final int? rpe;

  // ---- Selbstauskunft: in jeder Art, immer freiwillig ----

  /// Bereitschaft **vor** der Einheit, 1 bis 5. Geht nach `preWorkoutEnergy` —
  /// der Draht der Vorgänger-App, siehe `TrainingSession`.
  ///
  /// `null` heisst „nicht beantwortet", nicht „mittelmäßig". Das Feld hat
  /// keine Vorbelegung, und ein Entwurf ohne Antwort ist der Normalfall.
  final int? preWorkoutReadiness;

  /// Gefühl **nach** der Einheit, 1 bis 5. Dieselbe Regel.
  final int? postWorkoutFeeling;

  // ---- Kraft ----

  /// Wogegen die Einheit ging. Nur bei [SessionKind.strength] und
  /// [SessionKind.bodyweight] — der einzige Weg, eine Krafteinheit **ohne**
  /// Sätze überhaupt beschreibbar zu machen.
  final WorkoutFocus? workoutFocus;

  // ---- Ausdauer (Board 11, nur diese Felder, keine Vorratsfelder) ----

  /// Nur bei [SessionKind.cardio].
  final CardioActivity? activity;

  /// Fehlt sie, bleibt das Tempo „—" und die Einheit zählt in Minuten.
  final double? distanceKm;

  /// Puls ist nie Voraussetzung — 4 von 51 Einheiten tragen ihn.
  final int? avgHr;
  final int? maxHr;

  // ---- Regeneration ----

  /// Nur bei [SessionKind.recovery].
  final RecoveryKind? recoveryKind;

  /// Stammt die Dauer aus einer laufenden Uhr, sind die Sekunden echt und
  /// werden zusätzlich als `durationSec` geschrieben. Eine getippte
  /// Minutenzahl bekommt keine erfundenen Sekunden.
  final bool durationHasSeconds;

  /// Die Health-Connect-Kennung, aus der diese Einheit entstanden ist
  /// (Board 15). Der Uhr-Datensatz bleibt daneben liegen — deshalb ein
  /// Verweis und keine Kopie.
  final String? healthSessionId;

  /// Ob die Einheit aus der Uhr stammt. Siehe [TrainingSession.origin].
  final bool fromHealth;
}
