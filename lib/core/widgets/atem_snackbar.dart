import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_type.dart';
import 'atem_status_dot.dart';
import 'atem_tappable.dart';

/// Ton einer Meldung.
enum AtemSnackTone {
  /// Etwas ist gelungen — Punkt in Lime.
  success,

  /// Eine Feststellung ohne Wertung.
  neutral,
}

/// Die flüchtige Meldung über der Navigationsleiste.
///
/// ## Warum kein Material-SnackBar
///
/// Der bringt seine eigene Fläche, sein eigenes Ripple und sein eigenes
/// Timing mit, legt sich über die Navigationsleiste statt darüber, und seine
/// Aktion ist ein `TextButton` mit Material-Farben. Von der Spezifikation
/// bliebe nichts übrig.
///
/// ## Zwei Dauern, und der Grund dafür
///
/// **4 Sekunden ohne Rückgängig, 30 mit.** Eine Meldung, die nur mitteilt, hat
/// ihren Zweck erfüllt, sobald sie gelesen ist. Eine, die einen Widerruf
/// anbietet, muss so lange stehen, wie jemand braucht, um zu merken, dass er
/// ihn will — und das ist deutlich länger als vier Sekunden.
///
/// **Kein Blur.** Sie steht über der Leiste, die bereits einen trägt; zwei
/// übereinander sind zwei Malschichten für eine Zeile Text.
class AtemSnackbar extends StatelessWidget {
  const AtemSnackbar({
    super.key,
    required this.message,
    required this.semanticLabel,
    this.tone = AtemSnackTone.neutral,
    this.actionLabel,
    this.onAction,
  }) : assert(
          (actionLabel == null) == (onAction == null),
          'Eine Aktion braucht Beschriftung und Rückruf.',
        );

  /// Ohne Rückgängig. Die Meldung ist gelesen und geht.
  ///
  /// Seit 16.09.2026 wie [undoDuration] sechs Sekunden: Jede Meldung in der
  /// App steht gleich lange, damit keine länger oder kürzer wirkt als die
  /// andere.
  static const shortDuration = Duration(seconds: 6);

  /// Mit Rückgängig. So lange bleibt der Weg zurück offen.
  /// Sechs statt dreissig Sekunden (seit 16.09.2026): Am Gerät stand die
  /// Meldung „Regeneration gespeichert" so lange, dass sie wie ein Fehler
  /// wirkte. Sechs Sekunden reichen, um „Rückgängig" zu lesen und zu tippen.
  static const undoDuration = Duration(seconds: 6);

  final String message;
  final String semanticLabel;
  final AtemSnackTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Einmalige Ansage. Danach ist die Aktion über den Fokus erreichbar und
      // bleibt es, solange die Meldung steht — für Screenreader-Nutzer ist
      // das der eigentliche Widerrufsweg.
      liveRegion: true,
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        excluding: onAction == null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AtemColors.card,
            borderRadius: AtemRadii.statBoxR,
            border: Border.all(color: AtemColors.border),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: AtemStatusDot(
                  color: tone == AtemSnackTone.success
                      ? AtemColors.green
                      : AtemColors.textSecondary,
                  size: AtemDotSize.large,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AtemType.labelSmall.of(context),
                ),
              ),
              if (actionLabel case final label?) ...[
                const SizedBox(width: 10),
                AtemTappable(
                  onTap: onAction,
                  semanticLabel: label,
                  minTapSize: const Size(0, 44),
                  child: Text(
                    label,
                    style: AtemType.labelMedium
                        .of(context)
                        .copyWith(color: AtemColors.cyan),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
