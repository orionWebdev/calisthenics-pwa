import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/user_settings.dart';
import 'settings_providers.dart';

/// Ein Gewichtswechsel, der noch zurückgenommen werden kann.
class PendingWeightChange {
  const PendingWeightChange({required this.previousKg, required this.newKg});

  /// `null`, wenn vorher gar keins hinterlegt war.
  final double? previousKg;

  final double newKg;
}

/// Das Widerrufsfenster nach einer Gewichtsänderung.
///
/// ## Warum es anders funktioniert als beim Löschen einer Einheit
///
/// Dort wird die Ausführung **aufgeschoben**: Die Einheit sieht gelöscht aus,
/// ist es aber noch nicht, und der Zeitgeber führt sie am Ende aus. Das geht,
/// weil Löschen bis dahin folgenlos zurückzunehmen ist.
///
/// Hier wird sofort geschrieben. Der Grund ist die Vorschau: Sie hat gerade
/// gezeigt, was der neue Wert bedeutet, und die App muss diese Zahlen
/// unmittelbar danach auch zeigen — sonst wäre die Vorschau eine Ankündigung
/// gewesen, die nicht eintritt. Der Widerruf ist deshalb ein **zweiter
/// Schreibvorgang** auf den alten Wert, kein Abbruch des ersten.
///
/// Beides ist verlustfrei: Ein Körpergewicht ist eine Zahl, kein Bestand.
class PendingWeightController extends Notifier<PendingWeightChange?> {
  static const window = Duration(seconds: 30);

  Timer? _timer;

  @override
  PendingWeightChange? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void begin({required double? previousKg, required double newKg}) {
    _timer?.cancel();
    state = PendingWeightChange(previousKg: previousKg, newKg: newKg);
    _timer = Timer(window, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  /// Schreibt den alten Wert zurück.
  Future<void> undo() async {
    final pending = state;
    dismiss();
    if (pending == null) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final current = ref.read(settingsProvider).value ?? const UserSettings();
    await ref.read(settingsRepositoryProvider).save(
          userId,
          // War vorher keins hinterlegt, bleibt es dabei: `save` lässt ein
          // `null` weg, statt das Feld auf null zu setzen (Vertrag 4, R2).
          UserSettings(
            bodyWeightKg: pending.previousKg,
            unitSystem: current.unitSystem,
            language: current.language,
            restSeconds: current.restSeconds,
            hapticsEnabled: current.hapticsEnabled,
          ),
        );
  }
}

final pendingWeightProvider =
    NotifierProvider<PendingWeightController, PendingWeightChange?>(
  PendingWeightController.new,
);
