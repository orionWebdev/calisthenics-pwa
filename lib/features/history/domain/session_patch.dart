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
/// | [preWorkoutReadiness] | **Feld löschen**, die Antwort wurde zurückgenommen |
/// | [postWorkoutFeeling] | **Feld löschen**, dieselbe Regel |
/// | [strength] | **nicht anfassen** — diese Einheit kennt keinen Fokus |
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
    this.cardio,
    this.preWorkoutReadiness,
    this.postWorkoutFeeling,
    this.strength,
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

  /// Die Ausdauerfelder. `null` heißt **nicht anfassen** — wie bei
  /// [exercises]: Eine Krafteinheit kennt die Frage nach der Distanz nicht.
  final CardioPatch? cardio;

  /// Selbstauskunft vor und nach der Einheit, 1 bis 5. `null` **löscht**.
  ///
  /// Anders als [exercises] und [cardio], weil die Frage jede Art betrifft:
  /// Es gibt keine Einheit, bei der „wie bereit warst du" bedeutungslos wäre.
  /// Wer die Antwort wieder leert, meint „nicht erfasst" — und genau das
  /// entsteht daraus.
  final int? preWorkoutReadiness;
  final int? postWorkoutFeeling;

  /// Die Kraftfelder. `null` heißt **nicht anfassen** — wie bei [cardio]:
  /// Ein Lauf kennt die Frage nach dem Fokus nicht.
  final StrengthPatch? strength;
}

/// Das änderbare Kraftfeld — der Fokus.
///
/// Ein eigenes Objekt für ein einziges Feld, und das aus demselben Grund wie
/// [CardioPatch]: Ohne es liessen sich „diese Einheit hat keinen Fokus mehr"
/// und „diese Einheit kennt die Frage gar nicht" nicht unterscheiden, und
/// jede Bearbeitung eines Laufs schriebe ein `FieldValue.delete()` für ein
/// Feld, das dort nie stand.
///
/// Innerhalb des Objekts gilt die Regel von [SessionPatch.duration]:
/// **`null` löscht das Feld.**
///
/// Der Grund, warum der Fokus überhaupt änderbar ist: Die 16 bestehenden
/// Krafteinheiten ohne Übungen sind längst geschrieben. Nur über das
/// Bearbeiten bekommen sie nachträglich einen.
class StrengthPatch {
  const StrengthPatch({this.workoutFocus});

  final WorkoutFocus? workoutFocus;
}

/// Die änderbaren Ausdauerfelder — Distanz und Puls.
///
/// Innerhalb dieses Objekts gilt die Regel von [SessionPatch.duration]:
/// **`null` löscht das Feld.** Wer eine Distanz zurücknimmt, meint „nicht
/// erfasst", nicht „unverändert" — deshalb wird das ganze Objekt geschrieben,
/// nie ein Teil davon.
///
/// Das Tempo steht nicht hier: Es wird beim Lesen aus Distanz und Dauer
/// gerechnet. Die Vorgänger-App liest allerdings ein Feld `pace`; das
/// Repository schreibt es deshalb aus beiden **nach**, sobald sich eines von
/// ihnen ändert.
class CardioPatch {
  const CardioPatch({this.distanceKm, this.avgHr, this.maxHr, this.rpe});

  final double? distanceKm;
  final int? avgHr;
  final int? maxHr;
  final int? rpe;
}
