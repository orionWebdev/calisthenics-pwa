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
  });

  final String userId;
  final SessionKind kind;

  /// Der Trainingstag. Wird auf Mitternacht gesetzt — so schreibt es die PWA,
  /// und der Tagesschlüssel im Scoring erwartet es so.
  final DateTime date;

  final Duration duration;
  final List<LoggedExercise> exercises;
  final String? notes;
  final String? planId;
  final String? planName;

  /// Der Termin, aus dem die Einheit entstanden ist. Ist er gesetzt, wird er
  /// beim Speichern als erledigt markiert.
  final String? scheduleId;

  final int? rpe;

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
}
