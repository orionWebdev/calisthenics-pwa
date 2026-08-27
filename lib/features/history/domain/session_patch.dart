import 'training_session.dart';

/// Die änderbaren Felder einer bereits gespeicherten Einheit.
///
/// ## Warum nicht [SessionDraft] wiederverwenden
///
/// Ein Entwurf beschreibt eine Einheit, die es noch nicht gibt: Er trägt
/// `userId` und `type`, weil die Regeln sie beim **Anlegen** verlangen. Beim
/// Ändern sind genau diese beiden Felder tabu — `userId` zu ändern hieße, die
/// Einheit zu verschenken, und `type` zu ändern hieße, aus einem Lauf eine
/// Krafteinheit zu machen, deren Datenfelder gar nicht passen.
///
/// ## Wie `null` zu lesen ist
///
/// Vertrag `04-firestore-schema.md`, R2 warnt davor, „fehlt" und „ist null" zu
/// vermischen. Deshalb ist es hier **je Feld ausdrücklich** festgelegt:
///
/// | Feld | `null` bedeutet |
/// |---|---|
/// | [date] | nichts — Pflicht, immer gesetzt |
/// | [duration] | **Feld löschen**, die Dauer wurde nicht erfasst |
/// | [notes] | **Feld löschen**, die Notiz wurde geleert |
/// | [exercises] | **nicht anfassen** — diese Einheit führt keine Sätze |
///
/// Der Ausreißer ist [exercises], und er ist begründet: Eine Cardio-Einheit hat
/// kein Übungsfeld, das man leeren könnte. Ein leeres Feld zu schreiben wäre
/// eine Behauptung über eine Einheit, die die Frage gar nicht kennt.
class SessionPatch {
  const SessionPatch({
    required this.date,
    this.duration,
    this.notes,
    this.exercises,
  });

  /// Der Trainingstag. Wird auf Mitternacht gesetzt.
  ///
  /// **Änderbar, mit Absicht.** Das Datum verschiebt Lücken, Monatsstreifen und
  /// jede Kurve — aber der häufigste Grund, eine Einheit zu bearbeiten, ist,
  /// dass sie am falschen Tag steht. Wer nachträglich erfasst, tippt sie heute
  /// ein und meint vorgestern. Es zu sperren hieße, den Normalfall zu verbieten,
  /// um eine Folge zu vermeiden, die ohnehin ausgerechnet und angezeigt wird.
  final DateTime date;

  final Duration? duration;
  final String? notes;

  /// `null` heißt **unverändert**, nicht leer. Siehe Klassendokumentation.
  final List<LoggedExercise>? exercises;
}
