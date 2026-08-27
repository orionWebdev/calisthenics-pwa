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
  const WorkoutStart({this.planId, this.restSeconds = 90});

  /// Freies Training: kein Plan, leerer Runner, Übungen kommen dort dazu.
  const WorkoutStart.free({this.restSeconds = 90}) : planId = null;

  final String? planId;
  final int restSeconds;

  bool get isFree => planId == null;

  @override
  bool operator ==(Object other) =>
      other is WorkoutStart &&
      other.planId == planId &&
      other.restSeconds == restSeconds;

  @override
  int get hashCode => Object.hash(planId, restSeconds);

  @override
  String toString() => 'WorkoutStart(plan: $planId, rest: ${restSeconds}s)';
}
