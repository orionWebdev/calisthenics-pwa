import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

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
            child: Text(title, style: AtemType.labelMedium.of(context)),
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
  });

  final String label;
  final VoidCallback onTap;

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
      semanticLabel: semanticLabel ??
          (hint == null ? label : '$label. $hint'),
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                  style: AtemType.labelSmall.of(context),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: color),
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
        child: Row(
          children: [
            Expanded(
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
            const SizedBox(width: 12),
            _Track(on: value),
          ],
        ),
      ),
    );
  }
}

/// Die Schalterbahn. Kein Material-Switch: Der bringt sein eigenes Ripple und
/// seine eigene Palette mit.
class _Track extends StatelessWidget {
  const _Track({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AtemMotion.duration(context, AtemMotion.fast),
      curve: AtemMotion.curve,
      width: 46,
      height: 28,
      padding: const EdgeInsets.all(3),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? AtemCategories.surface(AtemColors.cyan) : AtemColors.track,
        borderRadius: BorderRadius.circular(AtemRadii.pill),
        border: Border.all(
          color: on ? AtemColors.cyan : AtemColors.border,
        ),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? AtemColors.cyan : AtemColors.textSecondary,
        ),
      ),
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
