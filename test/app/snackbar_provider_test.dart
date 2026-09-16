import 'package:atem/app/application/snackbar_providers.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der eine Meldungskanal: Er räumt sich selbst weg.
///
/// Anlass: „Regeneration gespeichert" schien am Gerät stehen zu bleiben. Die
/// Meldung trägt „Rückgängig", also gilt das 6-s-Fenster — hier steht,
/// dass es nach genau 6 s auch wirklich zu ist und nichts es verlängert.
void main() {
  AtemSnack undoSnack() => AtemSnack(
        message: 'Regeneration gespeichert',
        semanticLabel: 'Regeneration gespeichert',
        tone: AtemSnackTone.success,
        actionLabel: 'Rückgängig',
        onAction: () {},
      );

  test('mit Rückgängig verschwindet die Meldung nach 6 s, nicht früher', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(snackbarProvider.notifier).show(undoSnack());
      expect(container.read(snackbarProvider), isNotNull);

      async.elapse(AtemSnackbar.undoDuration - const Duration(seconds: 1));
      expect(container.read(snackbarProvider), isNotNull,
          reason: 'das Widerrufsfenster ist noch offen');

      async.elapse(const Duration(seconds: 1));
      expect(container.read(snackbarProvider), isNull);
    });
  });

  test('ohne Rückgängig nach 4 s', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(snackbarProvider.notifier).show(const AtemSnack(
            message: 'Gespeichert',
            semanticLabel: 'Gespeichert',
          ));
      async.elapse(AtemSnackbar.shortDuration);
      expect(container.read(snackbarProvider), isNull);
    });
  });

  test('eine zweite Meldung verdrängt die erste und startet die Uhr neu', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(snackbarProvider.notifier);

      notifier.show(undoSnack());
      async.elapse(const Duration(seconds: 4));
      notifier.show(undoSnack());
      async.elapse(const Duration(seconds: 4));
      // 8 s nach der ersten, 4 s nach der zweiten: Die zweite steht noch.
      expect(container.read(snackbarProvider), isNotNull);
      async.elapse(const Duration(seconds: 2));
      expect(container.read(snackbarProvider), isNull);
      // Kein zweiter Timer feuert nach: Der Zustand bleibt leer.
      async.elapse(const Duration(minutes: 1));
      expect(container.read(snackbarProvider), isNull);
    });
  });

  test('Rückgängig oder Wegtippen räumt sofort und kein Timer holt sie zurück',
      () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(snackbarProvider.notifier);

      notifier.show(undoSnack());
      notifier.dismiss();
      expect(container.read(snackbarProvider), isNull);
      async.elapse(const Duration(minutes: 1));
      expect(container.read(snackbarProvider), isNull);
    });
  });
}
