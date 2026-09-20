import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';

/// Der Kopf eines Tabs: Name, Zahl der Einheiten, Segment-Umschalter.
///
/// ## Nur noch Cardio
///
/// Der Kraft-Tab trug diesen Kopf bis zum 20.09.2026. Seit er ein One-Pager
/// mit geheftetem [AtemSectionNav] ist, wäre ein Titel darüber derselbe Name
/// zweimal — die Reiterleiste ist die Überschrift, und die Einheitenzahl
/// steht im Abschnitt „Verlauf", wo sie zählt.
///
/// Cardio hat weiter zwei Segmente und deshalb weiter diesen Kopf. Der Name
/// steht in Titelgrösse, die Zahl daneben als Metazeile: „Cardio · 51
/// Einheiten". Der Umschalter darunter, nicht daneben — bei 200 % Schrift auf
/// 320 dp passen beide nicht in eine Zeile.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    required this.count,
    required this.switcher,
  });

  final String title;
  final int count;
  final Widget switcher;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final countText = l10n.cardioWeekCount(count);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            // Ein Knoten: „Cardio, 51 Einheiten".
            label: '$title, $countText',
            header: true,
            child: ExcludeSemantics(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 10,
                runSpacing: 2,
                children: [
                  Text(title, style: AtemType.titleLarge.of(context)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(countText, style: AtemType.meta.of(context)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          switcher,
        ],
      ),
    );
  }
}
