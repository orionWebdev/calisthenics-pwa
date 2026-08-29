import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';

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
              padding: const EdgeInsets.all(16),
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

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AtemColors.textPrimary;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: AtemType.body.of(context).copyWith(color: color)),
                  if (hint case final text?) ...[
                    const SizedBox(height: 3),
                    Text(text, style: AtemType.labelMicro.of(context)),
                  ],
                ],
              ),
            ),
            if (value case final text?) ...[
              const SizedBox(width: 12),
              // Nachgiebig: Eine lange E-Mail-Adresse sprengt bei 200 %
              // Schrift auf 320 dp jede feste Aufteilung.
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AtemType.valueMedium.of(context).copyWith(
                        fontSize: 13,
                        // Werte stehen in Cyan — sie sind Messwerte, keine
                        // Unterzeilen (Board 08, A1/1). Nur Auskünfte wie
                        // „IN DER APP" bleiben gedämpft.
                        color: quiet ? AtemColors.textTertiary : AtemColors.cyan,
                      ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            // Der Pfeil ist ein Wegweiser, kein Text: gedämpft, ausser er
            // gehört zu einem zerstörenden Weg (Board 08, A1/2).
            Icon(Icons.chevron_right,
                size: 18,
                color: accent ?? AtemColors.textSecondary),
          ],
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
        // **Ein `Wrap`, keine `Row`.** Wort, Bahn und Beschriftung stehen bei
        // 200 % Schrift auf 320 dp nicht nebeneinander — die Prüfmatrix hat
        // 38 px Überlauf gefunden. Passt es, sieht es aus wie eine Reihe;
        // passt es nicht, rutscht der Schalter unter die Beschriftung.
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width -
                    AtemSpacing.screenPadding * 2 -
                    32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AtemType.body.of(context)),
                  if (hint case final text?) ...[
                    const SizedBox(height: 3),
                    Text(text, style: AtemType.labelMicro.of(context)),
                  ],
                ],
              ),
            ),
            _Track(on: value),
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
          style: AtemType.labelMicro
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

/// Eine reine Auskunftszeile — Mono, kein Weg dahinter.
class SettingsFact extends StatelessWidget {
  const SettingsFact({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: AtemType.labelMicro.of(context).copyWith(letterSpacing: 0),
        ),
      );
}
