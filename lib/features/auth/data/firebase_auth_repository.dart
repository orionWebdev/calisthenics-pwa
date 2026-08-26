import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_user.dart';

/// Anmeldung über Google, gegen Firebase Auth.
///
/// ## Vorläufig, aber nicht provisorisch
///
/// Der gestaltete Anmeldebildschirm kommt in Stufe 7. **Diese Mechanik bleibt.**
/// Sie steht hier, weil Stufe 6 sie beim Bauen aufgedeckt hat: Seit die
/// Firestore-Regeln greifen, liefert jede Leseanfrage ohne Anmeldung `403` —
/// der Lesepfad liesse sich sonst nie am echten Bestand prüfen.
///
/// ## Zur Bibliothek
///
/// `google_sign_in` 7.x hat eine andere Form als frühere Fassungen:
/// [GoogleSignIn.instance] ist ein Singleton, [GoogleSignIn.initialize] muss
/// **einmal** vor der ersten Anmeldung laufen, und `authenticate()` ersetzt das
/// alte `signIn()`. Die Authentifizierung liefert nur noch ein `idToken` —
/// kein `accessToken`. Firebase reicht das.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _google = google ?? GoogleSignIn.instance;

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _google;

  bool _initialized = false;

  /// `initialize` ist nicht mehrfach aufrufbar, ohne Nebenwirkungen zu riskieren.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // Ohne Argumente: Auf Android nimmt das Plugin den Web-Client aus der
    // google-services.json. Ein hier fest eingetragener serverClientId wäre
    // eine zweite Quelle, die beim nächsten Neuausrollen veraltet.
    await _google.initialize();
    _initialized = true;
  }

  AuthUser? _map(fb.User? user) => user == null
      ? null
      : AuthUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );

  @override
  Stream<AuthUser?> authState() => _auth.authStateChanges().map(_map);

  @override
  AuthUser? get current => _map(_auth.currentUser);

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException(
            AuthFailure.unbekannt, 'Google lieferte kein idToken');
      }

      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);

      final user = _map(result.user);
      if (user == null) {
        throw const AuthException(
            AuthFailure.unbekannt, 'Firebase lieferte keinen Nutzer');
      }
      return user;
    } on GoogleSignInException catch (e) {
      // Der Abbruch durch den Nutzer ist kein Fehler. Er darf weder eine
      // Meldung erzeugen noch im Protokoll als Störung erscheinen.
      throw AuthException(
        switch (e.code) {
          GoogleSignInExceptionCode.canceled => AuthFailure.abgebrochen,
          GoogleSignInExceptionCode.interrupted => AuthFailure.netzwerk,
          _ => AuthFailure.unbekannt,
        },
        e.description,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(
        e.code == 'network-request-failed'
            ? AuthFailure.netzwerk
            : AuthFailure.unbekannt,
        e.message,
      );
    }
  }

  @override
  Future<void> signOut() async {
    // Beide Seiten: Ohne `disconnect` bliebe die Google-Auswahl bestehen und
    // die nächste Anmeldung liefe stillschweigend mit demselben Konto durch.
    await _auth.signOut();
    if (_initialized) {
      await _google.signOut();
    }
  }
}
