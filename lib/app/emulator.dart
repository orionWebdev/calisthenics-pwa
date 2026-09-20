import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Die lokalen Firebase-Emulatoren — Anmeldung und Datenbank auf dem eigenen
/// Rechner statt im echten Projekt.
///
/// ## Warum es das gibt
///
/// Die geschlossene Beta ist doppelt gesichert: Der Client zeigt den Warteraum,
/// und die Firestore-Regeln verweigern jedem Konto ausserhalb von
/// `allowedUsers` jeden Zugriff. Eine Umgehung im Client allein brächte also
/// nichts. Im Emulator laufen **dieselben** `firestore.rules`, nur mit einer
/// eigenen, leeren Datenbank — das Testkonto steht dort auf der Liste (siehe
/// `tool/emulator_seed.mjs`), und die echten Daten bleiben unberührt.
///
/// ## Einschalten
///
/// ```
/// firebase emulators:start --only auth,firestore
/// node tool/emulator_seed.mjs
/// flutter run --dart-define=USE_EMULATOR=true
/// ```
///
/// Auf einem echten Gerät statt im Emulator zusätzlich
/// `--dart-define=EMULATOR_HOST=<IP des Rechners>`.
///
/// **Nur Debug.** Ein Release-Build ignoriert das Flag — der Store-Build kann
/// nicht versehentlich auf `localhost` zeigen.
abstract final class AtemEmulator {
  static const _requested = bool.fromEnvironment('USE_EMULATOR');
  static const _hostOverride = String.fromEnvironment('EMULATOR_HOST');

  static bool get active => kDebugMode && _requested;

  /// `localhost` genügt auch auf Android: Die Plugins bilden es selbst auf
  /// `10.0.2.2` ab, die Adresse des Rechners aus Sicht des Emulators.
  static String get host => _hostOverride.isEmpty ? 'localhost' : _hostOverride;

  /// Muss zu `firebase.json` passen. Firestore liegt auf 8081, weil 8080 dem
  /// Entwicklungsserver der PWA gehört.
  static const authPort = 9099;
  static const firestorePort = 8081;

  /// Das Testkonto. Steht nur in der Emulator-Datenbank auf der Liste.
  static const testEmail = 'test@atem.local';
  static const testPassword = 'atem-test-2026';

  /// Verbindet beide Dienste — **nach** `Firestore.settings` und vor der ersten
  /// Abfrage. Die Einstellungen später zu setzen würde den Host überschreiben.
  static Future<void> connect() async {
    if (!active) return;
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
    debugPrint('ATEM: Firebase-Emulator aktiv ($host, '
        'Auth $authPort, Firestore $firestorePort)');
  }
}
