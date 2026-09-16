import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_l10n.dart';
import '../theme/theme.dart';
import 'atem_card.dart';
import 'atem_progress.dart';

/// Ein Auswertungsblock **unter seiner Schwelle**.
///
/// ## Warum es ihn gibt
///
/// Bis zum 16.09.2026 galt überall: Ein Block ohne Daten rendert nicht. Nach
/// einem Neubeginn stand in der Kraft-Auswertung deshalb nur eine einzige
/// Kachel, und niemand konnte sehen, was die App überhaupt auswertet.
///
/// Auf Auswertungsbildschirmen rendert jeder Block jetzt immer (CLAUDE.md,
/// „Zustände sind Pflicht"). Unter der Schwelle zeigt er genau vier Dinge:
///
/// 1. seinen **Titel** — derselbe wie im gefüllten Zustand,
/// 2. **was** er zeigen wird, als ein Satz,
/// 3. die **Bedingung**, ab der er es zeigt — konkret, nicht „nach X Tagen":
///    „ab 5 Einheiten mit Gewicht", damit niemand auf etwas wartet, das bei
///    seinem Training nie eintritt,
/// 4. den **Fortschritt mit Nenner**.
///
/// ## Was er nie zeigt
///
/// Keinen Wert und keinen Null-Chart. Ein Balken bei 0 behauptet „gemessen:
/// 0"; ein Anteil aus zwei Einheiten sähe genauso glatt aus wie einer aus
/// zweihundert. Die Fläche unter dem Titel bleibt deshalb Text.
///
/// Ein ganzer Block ist **ein** Semantics-Knoten.
class AtemThresholdBlock extends StatelessWidget {
  const AtemThresholdBlock({
    super.key,
    required this.title,
    required this.what,
    required this.condition,
    required this.current,
    required this.required,
    this.trailing,
    this.accent = AtemColors.cyan,
  }) : assert(required > 0);

  /// Derselbe Titel wie im gefüllten Zustand.
  final String title;

  /// Ein Satz: was der Block zeigen wird, sobald er trägt.
  final String what;

  /// Ab wann er es zeigt — „Erscheint ab 5 Einheiten mit Gewicht".
  final String condition;

  final int current;
  final int required;

  /// Optional rechts neben dem Titel, etwa „8 Wochen".
  final String? trailing;

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final shown = current.clamp(0, required);

    return Semantics(
      container: true,
      label: l10n.thresholdA11y(title, what, condition, shown, required),
      child: ExcludeSemantics(
        child: AtemCard.list(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(title, style: AtemType.titleMedium.of(context)),
                  if (trailing != null)
                    Text(trailing!, style: AtemType.meta.of(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(what, style: AtemType.labelSmall.of(context)),
              const SizedBox(height: 14),
              AtemProgressBar.share(
                value: shown / required,
                semanticLabel: '',
                accent: accent,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    l10n.thresholdProgress(shown, required),
                    style: AtemType.valueMedium
                        .of(context)
                        .copyWith(fontSize: 13, color: AtemColors.textTertiary),
                  ),
                  Text(condition, style: AtemType.meta.of(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
