import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Der Markenblock über Anmeldung und Splash.
///
/// **Er bewegt sich nie.** Splash und Anmeldung setzen ihn auf dieselbe Achse;
/// beim Übergang blenden nur die Elemente darunter ein. Ein Markenblock, der
/// nach dem Laden springt, lässt die App unfertig wirken, bevor sie überhaupt
/// etwas gezeigt hat.
class BrandBlock extends StatelessWidget {
  const BrandBlock({super.key, this.semanticLabel});

  /// Wenn gesetzt, trägt der Block die Ansage — auf dem Splash ist er das
  /// einzige Element und damit der einzige Ort dafür.
  final String? semanticLabel;

  // Das Flackern des Markenpunkts fiel (Board 18b, K5): Flackern heisst
  // jetzt „abgelehnt" und wird nie gedämpft — ein Logo darf dieses Wort
  // nicht dauernd sprechen. Der Punkt steht flach.
  @override
  Widget build(BuildContext context) {
    final block = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AtemStatusDot(color: AtemColors.green),
        const SizedBox(width: 10),
        // Flexibel, damit der Block bei 200 % Schrift auf 320 dp nicht über
        // den Rand läuft. Der Markenname wird dabei zur Not abgeschnitten —
        // ein Überlauf wäre schlimmer, und die Ansage trägt ihn ohnehin nicht:
        // Der ganze Block ist aus den Semantics ausgeschlossen.
        Flexible(
          child: Text(
            // Markenname, bewusst nicht lokalisiert.
            'ATEM HYBRID',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtemType.labelMicro.of(context).copyWith(
                  color: AtemColors.green,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );

    final decorated = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AtemRadii.pill),
        border: Border.all(color: AtemColors.green.withValues(alpha: 0.45)),
      ),
      child: block,
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: decorated);
    }
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(child: decorated),
    );
  }
}
