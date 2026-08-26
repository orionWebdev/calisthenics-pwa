/// Der angemeldete Nutzer, so weit die App ihn braucht.
///
/// Reines Dart — kein Firebase-Typ verlässt die Datenschicht (Vertrag 3).
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  /// Der Schlüssel zu allem: Jedes Dokument in Firestore trägt ihn als
  /// `userId`, und die Rules geben nur eigene Dokumente heraus.
  final String uid;

  final String? email;
  final String? displayName;
  final String? photoUrl;
}

/// Warum eine Anmeldung fehlgeschlagen ist.
///
/// Bewusst wenige Fälle: Für die Oberfläche zählt nur, ob sie es erneut
/// versuchen lässt, still bleibt oder erklärt, dass der Zugang fehlt.
enum AuthFailure {
  /// Der Nutzer hat den Auswahldialog geschlossen. Keine Meldung, kein Fehler.
  abgebrochen,

  /// Kein Netz, oder Google nicht erreichbar.
  netzwerk,

  /// Angemeldet, aber nicht in `allowedUsers` freigeschaltet. Die App ist
  /// geschlossen; das ist ein gültiger Zustand, kein Defekt.
  nichtFreigeschaltet,

  /// Alles andere.
  unbekannt,
}

class AuthException implements Exception {
  const AuthException(this.failure, [this.detail]);

  final AuthFailure failure;
  final String? detail;

  @override
  String toString() =>
      'AuthException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// Vertrag der Anmeldung.
abstract interface class AuthRepository {
  /// `null`, solange niemand angemeldet ist. Meldet jeden Wechsel.
  Stream<AuthUser?> authState();

  AuthUser? get current;

  /// Wirft [AuthException] — auch bei Abbruch durch den Nutzer, damit der
  /// Aufrufer den Unterschied sieht.
  Future<AuthUser> signInWithGoogle();

  Future<void> signOut();
}
