import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/access.dart';
import '../domain/auth_user.dart';

/// Zugangsliste der geschlossenen Beta.
///
/// ## Die Regeln erlauben nicht beide Nachschläge gleich
///
/// `isAllowed()` in `firestore.rules` prüft `allowedUsers/{uid}`, ersatzweise
/// `allowedUsers/{email}`. Für die App sind die beiden Wege **nicht**
/// gleichwertig:
///
/// * Der Nachschlag über die eigene UID ist immer erlaubt — die Leseregel
///   greift über `request.auth.uid == userId`, unabhängig davon, ob das
///   Dokument existiert.
/// * Der Nachschlag über die E-Mail ist nur erlaubt, wenn das Dokument
///   existiert **und** seine `email` zur angemeldeten passt. Existiert es
///   nicht, wird der Lesezugriff **verweigert**, nicht leer beantwortet.
///
/// Deshalb: erst die UID, und ein Fehler beim E-Mail-Nachschlag zählt als
/// „nicht gefunden", nicht als Störung.
class FirestoreAllowlistRepository implements AllowlistRepository {
  FirestoreAllowlistRepository(this._db);

  final FirebaseFirestore _db;

  static const collection = 'allowedUsers';

  @override
  Future<bool> isAllowed(AuthUser user) async {
    // Dieser Nachschlag darf werfen — ohne Netz ist die Antwort unbekannt, und
    // unbekannt darf nicht als „nicht freigeschaltet" durchgehen.
    final byUid = await _db.collection(collection).doc(user.uid).get();
    if (_enabled(byUid)) return true;

    final email = user.email;
    if (email == null || email.isEmpty) return false;

    try {
      final byEmail = await _db.collection(collection).doc(email).get();
      return _enabled(byEmail);
    } on FirebaseException {
      // Existiert das Dokument nicht, verweigern die Regeln den Zugriff. Das
      // ist hier die Antwort „steht nicht drauf", keine Störung.
      return false;
    }
  }

  bool _enabled(DocumentSnapshot<Map<String, dynamic>> doc) =>
      doc.exists && doc.data()?['enabled'] == true;
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._db);

  final FirebaseFirestore _db;

  static const collection = 'userProfiles';

  @override
  Future<double?> bodyWeightKg(String userId) async {
    final doc = await _db.collection(collection).doc(userId).get();
    // R1 aus Vertrag 4: Im Bestand steht das Gewicht einmal als 70 und einmal
    // als 68.5 — `as int` oder `as double` würde je einen der beiden fällen.
    final value = (doc.data()?['bodyWeight'] as num?)?.toDouble();
    return value != null && value > 0 ? value : null;
  }

  @override
  Future<void> saveBodyWeight(
    String userId, {
    required double kilograms,
    required String unitSystem,
  }) async {
    // `merge`, nicht überschreiben: Im Profil stehen zwanzig weitere Felder,
    // die die PWA gesetzt hat.
    await _db.collection(collection).doc(userId).set({
      'bodyWeight': kilograms,
      'unitSystem': unitSystem,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}
