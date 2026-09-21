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
  /// **Immer Ausdauer.** Eine Uhr liefert Zeit, Puls und Strecke — die
  /// Grössen einer Ausdauereinheit. Ob „Yoga", „Dehnen" oder „Atemübung"
  /// stattdessen als Regeneration ankommen sollen, ist im Board ausdrücklich
  /// offen (offene Frage 4: die Artzuordnungstabelle fehlt noch). Bis sie da
  /// ist, wird nicht geraten: Eine falsch einsortierte Regeneration trüge
  /// Last, die sie nicht hat.
  static const kind = SessionKind.cardio;

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
        kind: kind,
        date: session.start,
        // Die Uhr weiss die Uhrzeit — nur landet sie in `date` auf
        // Mitternacht. Hier steht sie, damit auch eine übernommene Einheit
        // später noch zugeordnet werden kann.
        startedAt: session.start,
        duration: session.duration,
        // Die Sekunden sind echt — sie kommen aus einer Uhr, nicht aus einer
        // getippten Minutenzahl.
        durationHasSeconds: true,
        activity: activityOf(session.activity),
        distanceKm: session.distanceKm,
        avgHr: session.averageHeartRate,
        maxHr: session.maxHeartRate,
        rpe: rpe,
        notes: note,
        healthSessionId: session.externalId,
        fromHealth: true,
      );
}
