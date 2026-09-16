import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'history_providers.dart';

/// Eine Löschung, die noch zurückgenommen werden kann.
class PendingDeletion {
  const PendingDeletion({required this.sessionId, required this.label});

  final String sessionId;

  /// Wie die Einheit hieß — für den Widerrufshinweis. Nach dem Löschen ist
  /// der Name sonst nirgends mehr abzulesen.
  final String label;
}

/// Das Löschfenster: dreißig Sekunden, in denen die Einheit **weg aussieht**,
/// aber noch da ist.
///
/// ## Warum das Verschwinden sofort passieren muss
///
/// Ein Widerruf, der neben einer noch sichtbaren Einheit angeboten wird, ist
/// keiner — es gäbe nichts zurückzunehmen. Deshalb filtert
/// [sessionsProvider] die schwebende Kennung sofort heraus: Verlauf,
/// Auswertung und Dashboard rechnen ab dem Antippen so, als wäre sie fort. Wer
/// widerruft, sieht alles zurückspringen. Das ist die eigentliche Vorschau auf
/// die Folgen, und sie kostet keine zusätzliche Rechnung.
///
/// ## Offline gilt dasselbe
///
/// Das Fenster liegt vollständig in der Anwendung — ein Zeitgeber und eine
/// Kennung. Es fragt nie nach einer Verbindung, also verhält es sich ohne eine
/// genau gleich. Läuft es ab, geht der Löschbefehl an Firestore, und dessen
/// eigener Offline-Puffer trägt ihn, sobald das Netz zurück ist. Es gibt
/// keinen zweiten Mechanismus, der offline anders funktionieren könnte.
///
/// ## Was beim Beenden der App passiert
///
/// Nichts — und das ist die richtige Richtung. Wird die App innerhalb der
/// dreißig Sekunden geschlossen, bleibt die Einheit bestehen. Eine Löschung,
/// die niemand mehr bestätigen konnte, nicht auszuführen, ist der Fehler, mit
/// dem sich leben lässt.
class PendingDeletionController extends Notifier<PendingDeletion?> {
  // Deckt sich mit AtemSnackbar.undoDuration — Rückgängig gibt es nur,
  // solange die Meldung steht (6 s seit 16.09.2026, vorher 30 s).
  static const window = Duration(seconds: 6);

  Timer? _timer;

  @override
  PendingDeletion? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// Beginnt das Fenster. Eine bereits schwebende Löschung wird dabei sofort
  /// ausgeführt — zwei Widerrufe nebeneinander wären nicht zuzuordnen.
  Future<void> start(String sessionId, {required String label}) async {
    await _commit();
    state = PendingDeletion(sessionId: sessionId, label: label);
    _timer = Timer(window, () => unawaited(_commit()));
  }

  /// Nimmt die Löschung zurück. Die Einheit taucht sofort wieder auf.
  void undo() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  /// Führt sofort aus, ohne den Rest des Fensters abzuwarten.
  Future<void> commitNow() => _commit();

  Future<void> _commit() async {
    final pending = state;
    _timer?.cancel();
    _timer = null;
    if (pending == null) return;

    // Zustand **vor** dem Schreiben zurücksetzen: Schlägt das Löschen fehl,
    // erscheint die Einheit über den Strom von selbst wieder. Sie im
    // schwebenden Zustand zu lassen, hieße sie unsichtbar zu halten, obwohl
    // sie noch existiert.
    state = null;
    await ref.read(sessionRepositoryProvider).deleteSession(pending.sessionId);
  }
}

final pendingDeletionProvider =
    NotifierProvider<PendingDeletionController, PendingDeletion?>(
  PendingDeletionController.new,
);
