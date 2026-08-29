import 'package:flutter/material.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_type.dart';
import 'atem_button.dart';
import 'atem_overlays.dart';

/// Was beim Verlassen mit ungesicherten Änderungen passieren soll.
enum AtemUnsavedChoice {
  /// Sichern und schliessen.
  save,

  /// Verwerfen und schliessen.
  discard,

  /// Zurück ins Formular.
  keepEditing,
}

/// Der Verlassen-Dialog — **drei Wege, identisch für Übung, Plan und
/// Einheit**.
///
/// ## Warum drei und nicht zwei
///
/// Ein Dialog mit „Verwerfen" und „Weiter bearbeiten" lässt genau den Weg
/// aus, den die meisten wollen: sichern und gehen. Wer ihn nicht anbietet,
/// zwingt zurück ins Formular, zum Speichern-Knopf und ein zweites Mal zur
/// Zurück-Geste — für etwas, das der Dialog gerade erfragt hat.
///
/// Drei Wege sind hier die Ausnahme von der Dialogregel aus Modul 2, und sie
/// ist im Board ausdrücklich vorgesehen: Es sind **zwei Ergebnisse plus
/// Abbrechen**, nicht drei Ergebnisse.
///
/// ## Die Änderungszahl steht im Text
///
/// „Du hast 3 Einträge geändert und 1 hinzugefügt." Ohne sie ist der Dialog
/// eine Formalie; mit ihr weiss man, ob sich das Sichern lohnt.
abstract final class AtemUnsavedDialog {
  static Future<AtemUnsavedChoice?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String saveLabel,
    required String discardLabel,
    required String keepLabel,
  }) {
    return showDialog<AtemUnsavedChoice>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: AtemOverlays.barrier(AtemOverlays.dialogBarrierOpacity),
      barrierLabel: title,
      builder: (context) => _Dialog(
        title: title,
        message: message,
        saveLabel: saveLabel,
        discardLabel: discardLabel,
        keepLabel: keepLabel,
      ),
    );
  }
}

class _Dialog extends StatelessWidget {
  const _Dialog({
    required this.title,
    required this.message,
    required this.saveLabel,
    required this.discardLabel,
    required this.keepLabel,
  });

  final String title;
  final String message;
  final String saveLabel;
  final String discardLabel;
  final String keepLabel;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 48;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: title,
      explicitChildNodes: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width < 340 ? width : 340),
            // `showDialog` legt kein Material an; ohne eins fällt jeder Text
            // auf Flutters Notdarstellung zurück — gelb und doppelt
            // unterstrichen.
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AtemColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AtemColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AtemType.titleMedium.of(context)),
                    const SizedBox(height: 10),
                    Text(message, style: AtemType.body.of(context)),
                    const SizedBox(height: 20),
                    // **Untereinander, nie nebeneinander.** Bei 200 % Schrift
                    // auf 320 dp passt kein zweiter Knopf daneben, und drei
                    // schon gar nicht.
                    AtemButton.gradient(
                      label: saveLabel,
                      semanticLabel: saveLabel,
                      onPressed: () => Navigator.of(context)
                          .pop(AtemUnsavedChoice.save),
                    ),
                    const SizedBox(height: 10),
                    AtemButton.outline(
                      label: discardLabel,
                      semanticLabel: discardLabel,
                      accent: AtemColors.magenta,
                      onPressed: () => Navigator.of(context)
                          .pop(AtemUnsavedChoice.discard),
                    ),
                    const SizedBox(height: 10),
                    AtemButton.ghost(
                      label: keepLabel,
                      semanticLabel: keepLabel,
                      onPressed: () => Navigator.of(context)
                          .pop(AtemUnsavedChoice.keepEditing),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
