import 'auth_user.dart';

/// Wo eine Person auf dem Weg in die App steht.
///
/// Vier Stufen, und jede hat ihren eigenen Bildschirm. Der Zustand
/// „angemeldet, aber nicht freigeschaltet" ist ausdrücklich **kein Fehler**:
/// Die Anmeldung war erfolgreich, es fehlt nur der Platz in der geschlossenen
/// Beta. Er bekommt deshalb einen Warteraum, keine Fehlermeldung.
enum AccessStage {
  /// Firebase weiß noch nicht, ob jemand angemeldet ist. Darf **nie** wie
  /// „abgemeldet" aussehen — sonst blitzt die Anmeldung bei jedem Start auf.
  undecided,

  signedOut,

  /// Angemeldet, aber nicht auf der Zugangsliste.
  waitlisted,

  /// Freigeschaltet, aber es fehlt noch das Körpergewicht. Ohne das rechnet
  /// jede Körpergewichtsübung mit einer Trainingslast von null.
  onboarding,

  granted,
}

class AccessState {
  const AccessState(this.stage, {this.user});

  static const undecided = AccessState(AccessStage.undecided);
  static const signedOut = AccessState(AccessStage.signedOut);

  final AccessStage stage;
  final AuthUser? user;
}

/// Prüft die Zugangsliste der geschlossenen Beta.
abstract interface class AllowlistRepository {
  /// Steht dieses Konto auf der Liste und ist es freigeschaltet?
  ///
  /// Wirft nicht bei fehlendem Eintrag — „nicht freigeschaltet" ist ein
  /// gültiges Ergebnis, kein Fehler. Wirft nur, wenn die Prüfung selbst nicht
  /// stattfinden konnte, etwa ohne Netz: Dann ist die Antwort unbekannt, und
  /// unbekannt darf nicht als „nein" durchgehen.
  Future<bool> isAllowed(AuthUser user);
}

/// Liest und schreibt das Nutzerprofil.
abstract interface class ProfileRepository {
  /// Das hinterlegte Körpergewicht in Kilogramm, oder `null`.
  Future<double?> bodyWeightKg(String userId);

  /// Schreibt Körpergewicht und Einheitensystem.
  ///
  /// Gespeichert wird **immer in Kilogramm** — das Einheitensystem ist eine
  /// Anzeigeeinstellung, kein zweites Datenformat. Der Bestand führt
  /// `bodyWeight` einheitlich metrisch, und zwei Einheiten im selben Feld
  /// wären eine Falle für jede spätere Rechnung.
  Future<void> saveBodyWeight(
    String userId, {
    required double kilograms,
    required String unitSystem,
  });
}
