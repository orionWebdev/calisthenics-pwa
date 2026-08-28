import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/settings_repository.dart';

/// Löscht und gibt aus, was einem Konto gehört.
///
/// ## Die sechs Sammlungen
///
/// Dieselben, die die Vorgänger-App löscht (`js/views/settings.js`,
/// `deleteAllUserFirestoreData`), abzüglich derer, die es in dieser App nicht
/// gibt. `exercises_curated` ist **nicht** dabei: Die kuratierten Übungen
/// gehören allen, und die Regeln lassen ohnehin niemanden dort schreiben.
class FirestoreAccountRepository implements AccountRepository {
  FirestoreAccountRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Sammlungen mit einem `userId`-Feld.
  static const ownedCollections = [
    'sessions',
    'plans',
    'exercises',
    'schedule',
    'progress',
    'workouts',
  ];

  /// Sammlungen, deren Dokument-Kennung die Nutzerkennung **ist**.
  static const keyedCollections = ['userProfiles'];

  /// Firestore nimmt höchstens 500 Schreibvorgänge je Stapel.
  static const _batchLimit = 450;

  /// Alle Sammlungen in der Reihenfolge, in der gelöscht wird.
  ///
  /// **Das Profil zuletzt.** Es trägt die Freischaltungsspur und das
  /// Körpergewicht; solange es steht, lässt sich ein abgebrochener Lauf
  /// fortsetzen. Wäre es das erste, stünde nach einem Abbruch ein Bestand
  /// ohne Maßstab da.
  static const deletionOrder = [...ownedCollections, ...keyedCollections];

  @override
  Future<void> deleteData(
    String userId, {
    void Function(int done, int total, String collection)? onProgress,
  }) async {
    final total = deletionOrder.length;
    var done = 0;

    for (final name in deletionOrder) {
      if (keyedCollections.contains(name)) {
        await _db.collection(name).doc(userId).delete();
      } else {
        final snapshot =
            await _db.collection(name).where('userId', isEqualTo: userId).get();
        await _deleteAll(snapshot.docs.map((d) => d.reference));
      }
      onProgress?.call(++done, total, name);
    }
  }

  Future<void> _deleteAll(Iterable<DocumentReference<Object?>> refs) async {
    var batch = _db.batch();
    var count = 0;
    for (final ref in refs) {
      batch.delete(ref);
      if (++count < _batchLimit) continue;
      await batch.commit();
      batch = _db.batch();
      count = 0;
    }
    if (count > 0) await batch.commit();
  }

  @override
  Future<void> deleteAccount() async {
    // Die Anmeldung zuletzt: Ohne sie verweigern die Regeln jeden Zugriff auf
    // die Daten, und ein Rest bliebe unerreichbar liegen.
    await _auth.currentUser?.delete();
  }

  /// Firestore-Typen zu etwas, das sich schreiben lässt.
  ///
  /// **Hier und nicht im Formatierer.** Ein `Timestamp` ist ein Firebase-Typ;
  /// er darf die Datenschicht nicht verlassen (Vertrag 3). Zeitpunkte gehen
  /// als ISO 8601 raus — maschinenlesbar und in jeder Tabellenkalkulation
  /// erkennbar.
  static Object? _plain(Object? value) => switch (value) {
        Timestamp() => value.toDate().toUtc().toIso8601String(),
        GeoPoint() => '${value.latitude},${value.longitude}',
        DocumentReference() => value.path,
        Map() => {
            for (final entry in value.entries)
              entry.key.toString(): _plain(entry.value),
          },
        List() => [for (final entry in value) _plain(entry)],
        _ => value,
      };

  @override
  Future<AccountExport> export(String userId) async {
    final collections = <String, List<Map<String, Object?>>>{};

    for (final name in ownedCollections) {
      final snapshot =
          await _db.collection(name).where('userId', isEqualTo: userId).get();
      if (snapshot.docs.isEmpty) continue;
      collections[name] = [
        for (final doc in snapshot.docs)
          {'id': doc.id, ..._plain(doc.data()) as Map<String, Object?>},
      ];
    }

    for (final name in keyedCollections) {
      final doc = await _db.collection(name).doc(userId).get();
      final data = doc.data();
      if (data == null) continue;
      collections[name] = [
        {'id': doc.id, ..._plain(data) as Map<String, Object?>},
      ];
    }

    return AccountExport(collections: collections);
  }
}
