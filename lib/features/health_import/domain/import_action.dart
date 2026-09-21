import '../../history/domain/session_draft.dart';
import '../../history/domain/training_session.dart';
import 'health_session.dart';

/// Wie aus einer angenommenen Uhr-Einheit eine Einheit im Bestand wird.
///
/// **Reine Übersetzung, kein Schreibzugriff** — damit sich ohne Firestore und
/// ohne Gerät prüfen lässt, was im Bestand landet.
abstract final class ImportAction {
  /// Welche Art eine Uhr-Einheit im Bestand bekommt.
  ///
  /// ## Drei Arten, die die Uhr sicher benennt
  ///
  /// Health Connect führt feste Kennungen für die Trainingsart. Wo sie
  /// eindeutig sind, wird ihnen geglaubt: Krafttraining ist Kraft, und
  /// Calisthenics ist Körpergewicht. Vorher landete beides als Ausdauer,
  /// und wer auf der Uhr „Krafttraining" abschloss, fand es in ATEM unter
  /// Cardio wieder (gemeldet am 21.09.2026).
  ///
  /// ## Warum der Rest Ausdauer bleibt
  ///
  /// Eine Uhr liefert Zeit, Puls und Strecke — die Grössen einer
  /// Ausdauereinheit. Ob „Yoga", „Pilates" oder „Atemübung" stattdessen als
  /// Regeneration ankommen sollen, ist im Board weiterhin offen (offene
  /// Frage 4). Dort wird nicht geraten: Eine falsch einsortierte Regeneration
  /// trüge Last, die sie nicht hat, und „Andere" meldet jede Uhr für alles.
  ///
  /// ## Was die Art **nicht** entscheidet
  ///
  /// Die Zuordnung zu einer App-Einheit. `SessionPairing` prüft die Art nie
  /// (Entscheidung 6) — Uhren melden Krafttraining regelmässig als „Andere".
  /// Diese Tabelle gilt nur für Einheiten, die **eigenständig** hereinkommen.
  static SessionKind kindOf(String? raw) => switch (raw?.toUpperCase()) {
        'STRENGTH_TRAINING' || 'WEIGHTLIFTING' => SessionKind.strength,
        'CALISTHENICS' => SessionKind.bodyweight,
        _ => SessionKind.cardio,
      };

  /// Die Aktivität, wenn die Uhr eine nennt, die ATEM kennt.
  ///
  /// Bewusst knapp und ohne Rateversuche: Was nicht sicher zuzuordnen ist,
  /// bleibt leer. Eine leere Aktivität ist eine fehlende Angabe, eine falsche
  /// eine Behauptung.
  static CardioActivity? activityOf(String? raw) =>
      switch (raw?.toUpperCase()) {
        'RUNNING' || 'RUNNING_TREADMILL' => CardioActivity.run,
        'BIKING' => CardioActivity.bike,
        'BIKING_STATIONARY' => CardioActivity.bikeIndoor,
        'WALKING' => CardioActivity.walk,
        'HIKING' => CardioActivity.hike,
        'ROWING' || 'ROWING_MACHINE' => CardioActivity.row,
        _ => null,
      };

  /// Der Entwurf für eine übernommene Uhr-Einheit.
  ///
  /// Welche Grösse woher kommt, steht fest und wird nie gewählt
  /// (Entscheidung 9): Dauer, Strecke und Puls aus der Uhr, Anstrengung und
  /// Notiz vom Menschen. Gerechnet wird nichts.
  static SessionDraft draftOf({
    required HealthSession session,
    required String userId,
    int? rpe,
    String? note,
  }) =>
      SessionDraft(
        userId: userId,
        kind: kindOf(session.activity),
        date: session.start,
        // Die Uhr weiss die Uhrzeit — nur landet sie in `date` auf
        // Mitternacht. Hier steht sie, damit auch eine übernommene Einheit
        // später noch zugeordnet werden kann.
        startedAt: session.start,
        duration: session.duration,
        // Die Sekunden sind echt — sie kommen aus einer Uhr, nicht aus einer
        // getippten Minutenzahl.
        durationHasSeconds: true,
        // **Nur an einer Ausdauereinheit.** Eine Krafteinheit trägt weder
        // Aktivität noch Strecke; Puls und Kalorien liegen ohnehin am
        // Uhr-Datensatz und werden nicht in die Einheit kopiert
        // (Entscheidung 1 und 9 — nur deshalb ist Lösen verlustfrei).
        activity: kindOf(session.activity) == SessionKind.cardio
            ? activityOf(session.activity)
            : null,
        distanceKm: session.distanceKm,
        avgHr: session.averageHeartRate,
        maxHr: session.maxHeartRate,
        rpe: rpe,
        notes: note,
        healthSessionId: session.externalId,
        fromHealth: true,
      );
}
