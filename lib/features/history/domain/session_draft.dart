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
}
