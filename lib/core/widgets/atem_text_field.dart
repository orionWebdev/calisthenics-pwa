import 'package:flutter/material.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_type.dart';

/// Freitexteingabe — Name, Beschreibung, Notiz, Suchbegriff.
///
/// ## Warum es das erst jetzt gibt
///
/// Bis hierher brauchte die App kein Textfeld: Alles, was eingegeben wurde,
/// waren Zahlen ([AtemNumberField]) oder eine Suche, die als roher `TextField`
/// im Bildschirm lag. Erst das Anlegen von Übungen und Plänen macht Freitext
/// zum Thema — und dann sofort an sechs Stellen. Der siebte rohe `TextField`
/// wäre der Moment gewesen, an dem sich das Muster verselbständigt.
///
/// ## Der Fehler steht als Satz darunter, nicht nur als Rand
///
/// Ein magenta Rand allein sagt Farbenblinden nichts (Vertrag R6) und
/// Sehenden nichts Genaues. [errorText] steht deshalb als eigene Zeile
/// darunter und geht zugleich in das Vorlesefeld ein.
///
/// ## Höhe wächst, statt festzustehen
///
/// Mindestens 48 dp, nach oben offen. Bei 200 % Systemschrift wird aus einer
/// Zeile schnell eine dreifache — eine feste Höhe schnitte sie ab.
class AtemTextField extends StatelessWidget {
  const AtemTextField({
    super.key,
    required this.controller,
    required this.semanticLabel,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.sentences,
    this.maxLines = 1,
    this.leading,
    this.trailing,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController controller;

  /// Was ein Screenreader ansagt. Ohne sichtbare Beschriftung darüber muss er
  /// den Zweck allein tragen.
  final String semanticLabel;

  final String? hint;

  /// Gesetzt heißt: Rand magenta **und** Satz darunter.
  final String? errorText;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;

  /// `null` heißt beliebig viele Zeilen — für Beschreibungen und Notizen.
  final int? maxLines;

  final Widget? leading;
  final Widget? trailing;
  final bool autofocus;
  final bool enabled;

  /// **56 dp, nicht 48.** 48 ist die Untergrenze fuer einen Finger, nicht
  /// das Mass fuer ein Eingabefeld: Ein Feld, das genauso hoch ist wie
  /// eine Zeile Text, sieht aus wie eine Zeile Text. Die Boards zeigen
  /// durchgehend die hoehere Fassung (07_A2, 08_A2).
  static const _minHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          textField: true,
          label: hasError ? '$semanticLabel. $errorText' : semanticLabel,
          value: controller.text,
          enabled: enabled,
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: TextField(
                controller: controller,
                enabled: enabled,
                autofocus: autofocus,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                maxLines: maxLines,
                minLines: 1,
                textInputAction: textInputAction,
                textCapitalization: textCapitalization,
                style: AtemType.body.of(context),
                cursorColor: AtemColors.cyan,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AtemColors.surfaceSolid,
                  hintText: hint,
                  hintStyle: AtemType.body
                      .of(context)
                      .copyWith(color: AtemColors.textSecondary),
                  prefixIcon: leading,
                  suffixIcon: trailing,
                  // Genug Platz, dass die Schrift bei 200 % nicht am Rand klebt.
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  enabledBorder: _border(
                      hasError ? AtemColors.magenta : AtemColors.border),
                  disabledBorder: _border(AtemColors.border),
                  focusedBorder: _border(
                      hasError ? AtemColors.magenta : AtemColors.cyan,
                      width: 1.5),
                ),
              ),
            ),
          ),
        ),
        if (errorText case final text?) ...[
          const SizedBox(height: 6),
          // Im Vorlesefeld steckt der Satz schon — hier wäre er ein Echo.
          ExcludeSemantics(
            child: Text(
              text,
              style: AtemType.labelMicro
                  .of(context)
                  .copyWith(color: AtemColors.magenta, letterSpacing: 0),
            ),
          ),
        ],
      ],
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AtemRadii.statBoxR,
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Eine Feldbeschriftung über einem Eingabefeld.
///
/// Getrennt vom Feld, nicht als `labelText` darin: Ein Material-Label wandert
/// beim Fokus in den Rand und wird dabei kleiner — bei 12 sp Ausgangsgröße
/// landet es unter der Grenze aus Vertrag R1.
class AtemFieldLabel extends StatelessWidget {
  const AtemFieldLabel({super.key, required this.label, this.hint});

  final String label;

  /// Erklärung darunter, etwa „Mindestens einer".
  final String? hint;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AtemType.labelMedium.of(context)),
            if (hint case final text?) ...[
              const SizedBox(height: 4),
              Text(text, style: AtemType.labelMicro.of(context)),
            ],
            const SizedBox(height: 8),
          ],
        ),
      );
}
