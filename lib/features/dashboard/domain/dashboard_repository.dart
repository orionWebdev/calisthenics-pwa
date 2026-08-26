import 'dashboard_data.dart';

/// Datenquelle des Dashboards.
///
/// Die Implementierung gehört in `data/` und liest aus denselben Quellen wie
/// die bestehende PWA (Firestore: `sessions`, `schedule`, `userProfiles`)
/// bzw. später aus der Wearable-Anbindung.
///
/// Bewusst als Stream: Firestore liefert Echtzeit-Updates, und das Dashboard
/// soll sich aktualisieren, während eine Session läuft.
///
/// Der Session-Lebenszyklus liegt bewusst NICHT hier, sondern am
/// `WorkoutRepository` — er steuert ein Workout, nicht das Dashboard.
abstract interface class DashboardRepository {
  /// Aggregierter Dashboard-Zustand des aktuellen Nutzers.
  Stream<DashboardData> watchDashboard();
}
