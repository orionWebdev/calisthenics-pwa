import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_type.dart';

/// Zahleneingabe für Gewicht und Wiederholungen.
///
/// **Das eine Element, das [AtemTappable] nicht heilen kann.**
/// `androidTapTargetGuideline` überspringt Textfelder nicht, und eine
/// unsichtbar vergrößerte Trefferfläche hilft hier nicht: In der Satzzeile
/// stehen die Felder dicht nebeneinander, ihre Flächen würden überlappen.
/// Also wächst das Feld **sichtbar** von 44 auf 48 dp — so steht es in der
/// Spezifikation aus Design-Gespräch 01, Fall 4.
///
/// Das Dezimaltrennzeichen folgt der Sprache: Deutsch schreibt „92,5",
/// Englisch „92.5". Die Eingabe akzeptiert beides, damit niemand an der
/// Tastatur scheitert.
class AtemNumberField extends StatelessWidget {
  const AtemNumberField({
    super.key,
    required this.controller,
    required this.semanticLabel,
    required this.width,
    this.onChanged,
    this.decimal = false,
    this.locked = false,
    this.hasError = false,
    this.suffix,
    this.textInputAction = TextInputAction.next,
  });

  /// Breite laut Spezifikation: 72 dp für Gewicht, 60 dp für Wiederholungen.
  const AtemNumberField.weight({
    super.key,
    required this.controller,
    required this.semanticLabel,
    this.onChanged,
    this.locked = false,
    this.hasError = false,
    this.suffix,
    this.textInputAction = TextInputAction.next,
  })  : width = 72,
        decimal = true;

  const AtemNumberField.reps({
    super.key,
    required this.controller,
    required this.semanticLabel,
    this.onChanged,
    this.locked = false,
    this.hasError = false,
    this.suffix,
    this.textInputAction = TextInputAction.next,
  })  : width = 60,
        decimal = false;

  final TextEditingController controller;

  /// Aus dem ARB, mit Satznummer: „Gewicht in Kilogramm, Satz 2".
  final String semanticLabel;

  final double width;
  final ValueChanged<String>? onChanged;
  final bool decimal;

  /// Gesperrt, weil der Satz abgehakt ist. Nicht dasselbe wie deaktiviert —
  /// der Wert bleibt lesbar, nur nicht änderbar.
  final bool locked;

  /// Färbt den Rand magenta. **Nur zusammen mit einem Klartext daneben** —
  /// Farbe ist nie der einzige Statusträger (Vertrag R6).
  final bool hasError;

  /// Einheit hinter der Zahl, etwa „kg" oder „×".
  final String? suffix;

  final TextInputAction textInputAction;

  static const _minHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel,
      value: controller.text,
      enabled: !locked,
      readOnly: locked,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            // Untergrenze, keine feste Höhe: bei großer Schrift wächst das Feld.
            constraints: const BoxConstraints(minHeight: _minHeight),
            child: TextField(
              controller: controller,
              enabled: !locked,
              onChanged: onChanged,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: textInputAction,
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  // Beide Trennzeichen zulassen — die Anzeige normalisiert.
                  decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
                ),
              ],
              style: AtemType.valueMedium.base,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor:
                    locked ? const Color(0x00000000) : AtemColors.surfaceSolid,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                suffixText: suffix,
                suffixStyle: AtemType.labelSmall.base,
                enabledBorder:
                    _border(hasError ? AtemColors.magenta : AtemColors.border),
                disabledBorder:
                    _border(hasError ? AtemColors.magenta : AtemColors.border),
                focusedBorder: _border(
                    hasError ? AtemColors.magenta : AtemColors.cyan,
                    width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AtemRadii.statBoxR,
        borderSide: BorderSide(color: color, width: width),
      );

  /// Welches Trennzeichen die aktuelle Sprache erwartet.
  static String _decimalSeparatorFor(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? '.' : ',';

  /// Wandelt eine Eingabe in eine Zahl, unabhängig vom Trennzeichen.
  ///
  /// Ersetzt das `weight.replaceAll(',', '.')` aus dem Domänenmodell — dort
  /// hatte eine Formatierungsfrage nichts verloren.
  static double? parse(String raw) =>
      double.tryParse(raw.replaceAll(',', '.').trim());

  /// Formatiert eine Zahl für die Anzeige in der aktuellen Sprache.
  static String format(BuildContext context, double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return text.replaceAll('.', _decimalSeparatorFor(context));
  }
}
