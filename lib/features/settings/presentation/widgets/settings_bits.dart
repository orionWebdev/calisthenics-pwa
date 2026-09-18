import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';

/// Misst, wie breit ein Text in einer Zeile wäre — mit der Schriftgrösse des
/// Nutzers.
///
/// Die Zeilen hier entscheiden damit selbst, ob Beschriftung und Wert
/// nebeneinander passen. Vorher trugen beide `flex: 1` und teilten den freien
/// Platz **hälftig**: „Einheitensystem" brach mitten im Wort, während rechts
/// neben „Metrisch" 80 dp leer blieben.
double _textWidth(BuildContext context, String text, TextStyle style) =>
    (TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout())
        .width;

/// Ein Abschnitt der Einstellungen.
///
/// Die Überschrift steht **über** der Karte, nicht darin: So bleibt sie beim
/// Scrollen als Orientierung sichtbar, und die Karte trägt nur Inhalt.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(title.toUpperCase(),
                style: AtemType.labelMicro.of(context)),
          ),
          const SizedBox(height: 10),
          Semantics(
            container: true,
            label: title,
            explicitChildNodes: true,
            child: AtemCard.list(
              // Dasselbe Polster wie in den Karten der anderen Bereiche.
              padding: const EdgeInsets.all(AtemSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      );
}

/// Eine antippbare Zeile: Beschriftung links, Pfeil rechts.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.onTap,
    this.hint,
    this.value,
    this.accent,
    this.semanticLabel,
    this.onLongPress,
    this.valueAccent = false,
    this.quiet = false,
  });

  /// Der Wert ist eine Auskunft, kein Messwert — „IN DER APP", „DATEN
  /// BLEIBEN". Er bleibt gedämpft statt in Cyan.
  final bool quiet;

  final String label;
  final VoidCallback onTap;

  /// Ein zweiter Weg am selben Ort — etwa „extern öffnen" bei Rechtstexten.
  final VoidCallback? onLongPress;

  /// Wert in Cyan, wenn er vom Standard abweicht (Board 08, Spezifikation).
  final bool valueAccent;

  /// Erklärung unter der Beschriftung.
  final String? hint;

  /// Rechts stehender Wert, etwa eine E-Mail-Adresse.
  final String? value;

  /// Magenta für zerstörende Wege.
  final Color? accent;

  final String? semanticLabel;

  /// Abstand zwischen Beschriftung und Wert.
  static const _gap = 12.0;

  /// Breite des Wegweisers samt Luft davor.
  static const _chevron = 18.0 + 8.0;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AtemColors.textPrimary;
    final labelStyle = AtemType.body.of(context).copyWith(color: color);
    final valueStyle = AtemType.valueMedium.of(context).copyWith(
          fontSize: 13,
          // Werte stehen in Cyan — sie sind Messwerte, keine Unterzeilen
          // (Board 08, A1/1). Nur Auskünfte wie „In der App" bleiben
          // gedämpft.
          color: quiet ? AtemColors.textTertiary : AtemColors.cyan,
        );

    return AtemTappable(
      onTap: onTap,
      onLongPress: onLongPress,
      // Der Wert steht vor der Unterzeile, damit er ohne Abwarten hörbar
      // ist (Board 08, H).
      semanticLabel: semanticLabel ??
          [label, if (value != null) value!, if (hint != null) hint!]
              .join(', '),
      minTapSize: const Size(0, 56),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        // **Gemessen statt geteilt.** Passen Beschriftung und Wert
        // nebeneinander, steht die Beschriftung ungekürzt links und der Wert
        // rechts am Wegweiser. Passen sie nicht, bekommt die Beschriftung die
        // volle Breite und bricht an Wortgrenzen; der Wert rutscht darunter,
        // weiter rechtsbündig. Die Unterzeile läuft immer über die ganze
        // Breite — sie hatte vorher nur die halbe und brach früh um.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final text = value;
            final labelWidth = _textWidth(context, label, labelStyle);
            final valueWidth =
                text == null ? 0.0 : _textWidth(context, text, valueStyle);
            final fits = labelWidth + (text == null ? 0 : _gap + valueWidth) +
                    _chevron <=
                constraints.maxWidth;

            final valueText = text == null
                ? null
                : Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: labelStyle,
                        softWrap: !fits,
                      ),
                    ),
                    if (fits && valueText != null) ...[
                      const SizedBox(width: _gap),
                      valueText,
                    ],
                    const SizedBox(width: 8),
                    // Der Pfeil ist ein Wegweiser, kein Text: gedämpft, ausser
                    // er gehört zu einem zerstörenden Weg (Board 08, A1/2).
                    Icon(Icons.chevron_right,
                        size: 18, color: accent ?? AtemColors.textSecondary),
                  ],
                ),
                if (!fits && valueText != null) ...[
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerRight, child: valueText),
                ],
                if (hint case final text?) ...[
                  const SizedBox(height: 3),
                  Text(text, style: AtemType.labelSmall.of(context)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Eine reine Auskunftszeile: Beschriftung links, Wert rechts, kein Weg
/// dahinter.
///
/// Sie misst wie [SettingsRow]: Passt der Wert daneben, steht er rechtsbündig
/// in derselben Zeile; sonst darunter, ebenfalls rechtsbündig. So bricht keine
/// Beschriftung mitten im Wort.
class SettingsFactRow extends StatelessWidget {
  const SettingsFactRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AtemType.labelMicro.of(context);
    final valueStyle = AtemType.valueMedium
        .of(context)
        .copyWith(fontSize: 12, color: AtemColors.textTertiary);

    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final upper = label.toUpperCase();
              final fits = _textWidth(context, upper, labelStyle) +
                      12 +
                      _textWidth(context, value, valueStyle) <=
                  constraints.maxWidth;
              final valueText = Text(
                value,
                textAlign: TextAlign.right,
                style: valueStyle,
              );

              if (fits) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Text(upper, style: labelStyle)),
                    const SizedBox(width: 12),
                    valueText,
                  ],
                );
              }
              // Umgebrochen steht der Wert **linksbündig** unter seiner
              // Beschriftung: rechtsbündig sähe er aus wie der Wert der
              // nächsten Zeile.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(upper, style: labelStyle),
                  const SizedBox(height: 4),
                  Text(value, style: valueStyle),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Ein Schalter mit Beschriftung, Erklärung und **Wort statt nur Farbe**.
///
/// Der Zustand steht im Semantics-Label als Satz („Vibration an"), nicht nur
/// als Stellung des Knopfs — Vertrag R6.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.hint,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return AtemTappable(
      onTap: () => onChanged(!value),
      semanticLabel: semanticLabel,
      selected: value,
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        // **Wie eine Zeile mit Wert:** Beschriftung links, Bahn rechts, und
        // die Erklärung darunter über die **ganze** Breite. Vorher stand sie
        // in einer schmalen Spalte neben der Bahn und brach früh um; seit
        // 17.09.2026 nutzt sie den Platz.
        //
        // Passen Beschriftung und Bahn nicht nebeneinander (200 % Schrift auf
        // 320 dp), rutscht die Bahn unter die Beschriftung — deshalb ein
        // `Wrap` und keine `Row`.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: constraints.maxWidth - 120),
                    child: Text(label, style: AtemType.body.of(context)),
                  ),
                  _Track(on: value),
                ],
              ),
            ),
            if (hint case final text?) ...[
              const SizedBox(height: 3),
              Text(text, style: AtemType.labelSmall.of(context)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Die Schalterbahn — **Wort und Glyph, nicht nur Stellung**.
///
/// Kein Material-Switch: Der bringt sein eigenes Ripple und seine eigene
/// Palette mit. Wichtiger aber ist, was das Board zusätzlich verlangt: Neben
/// der Bahn steht „AN" oder „AUS", und im Knopf sitzt ein Haken bzw. ein
/// Kreuz.
///
/// Das ist Vertrag R6 in seiner strengsten Lesart. Eine Bahn, die links oder
/// rechts steht, ist eine **Form** — aber eine, die man kennen muss. Wer die
/// App zum ersten Mal öffnet und farbenblind ist, liest an einem
/// Material-Switch nichts.
class _Track extends StatelessWidget {
  const _Track({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final accent = on ? AtemColors.green : AtemColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          on ? l10n.switchOn : l10n.switchOff,
          style: AtemType.labelUi
              .of(context)
              .copyWith(color: accent, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: AtemMotion.duration(context, AtemMotion.fast),
          curve: AtemMotion.curve,
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: on
                ? AtemColors.green.withValues(alpha: 0.16)
                : AtemColors.track,
            borderRadius: BorderRadius.circular(AtemRadii.pill),
            border: Border.all(color: on ? AtemColors.green : AtemColors.border),
          ),
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
            child: Icon(
              on ? Icons.check : Icons.close,
              size: 13,
              // Auf dem hellen Knopf: die Grundfarbe des Bildschirms.
              color: AtemColors.base,
            ),
          ),
        ),
      ],
    );
  }
}

/// Der Trenner zwischen zwei Zeilen einer Sektion, 1 dp in `#232334`.
class SettingsRule extends StatelessWidget {
  const SettingsRule({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AtemColors.border);
}

/// Eine reine Auskunftszeile — Mono, kein Weg dahinter.
class SettingsFact extends StatelessWidget {
  const SettingsFact({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: AtemType.labelSmall.of(context),
        ),
      );
}
