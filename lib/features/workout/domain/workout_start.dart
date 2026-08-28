import 'package:meta/meta.dart';

/// Was gestartet werden soll — der Schlüssel des Runners.
///
/// ## Warum nicht länger eine blosse Kennung
///
/// Vorher bekam der Runner eine `sessionId` als Zeichenkette, und die Hülle
/// schob ihm dafür `request.plan?.id ?? ''` hin. Zwei Dinge gingen dabei
/// verloren: die gewählte Pausenzeit, die niemand weiterreichte, und die
/// Unterscheidung zwischen „kein Plan" und „Plan mit leerer Kennung".
///
/// Ein eigener Typ macht beides sichtbar und taugt zugleich als
/// Familien-Schlüssel — dafür braucht er Gleichheit, sonst legte Riverpod bei
/// jedem Neubau eine zweite Einheit an.
@immutable
class WorkoutStart {
  const WorkoutStart({
    this.planId,
    this.scheduleId,
    this.sessionId,
    this.restSeconds = 90,
  });

  /// Eine bereits gespeicherte Einheit weiterbearbeiten — „Sätze nachtragen".
  ///
  /// 16 der 63 Krafteinheiten im Bestand tragen keine Übungen. Für sie ist
  /// das der Weg hinein; für Einheiten mit Sätzen der Weg zur Korrektur.
  const WorkoutStart.session(String this.sessionId, {this.restSeconds = 90})
      : planId = null,
        scheduleId = null;

  /// Freies Training: kein Plan, leerer Runner, Übungen kommen dort dazu.
  const WorkoutStart.free({this.restSeconds = 90})
      : planId = null,
        scheduleId = null,
        sessionId = null;

  final String? planId;

  /// Der Kalendertermin, aus dem die Einheit entsteht.
  ///
  /// **Muss mitwandern.** Er ist die einzige Verbindung zum Kalender: Beim
  /// Speichern wird der Termin darüber als erledigt markiert, beim Löschen
  /// wieder geöffnet. Ohne ihn bliebe jede aus dem Kalender gestartete
  /// Einheit dort für immer offen.
  final String? scheduleId;

  /// Die bestehende Einheit, die ergänzt wird. `null` bei einer neuen.
  final String? sessionId;

  final int restSeconds;

  bool get isFree => planId == null && sessionId == null;

  /// Wird eine bestehende Einheit ergänzt statt eine neue geschrieben?
  bool get amends => sessionId != null;

  @override
  bool operator ==(Object other) =>
      other is WorkoutStart &&
      other.planId == planId &&
      other.scheduleId == scheduleId &&
      other.sessionId == sessionId &&
      other.restSeconds == restSeconds;

  @override
  int get hashCode =>
      Object.hash(planId, scheduleId, sessionId, restSeconds);

  @override
  String toString() => 'WorkoutStart(plan: $planId, termin: $scheduleId, '
      'einheit: $sessionId, rest: ${restSeconds}s)';
}
