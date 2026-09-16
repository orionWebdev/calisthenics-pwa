import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';

/// Seite 4 des Kraft-Tabs — **Pläne von ATEM**.
///
/// Hier erscheinen später Trainingspläne, die ATEM für alle Nutzer
/// zusammenstellt, frei und als Premium. Die eigenen Pläne des Nutzers stehen
/// weiter auf der Seite „Trainieren".
///
/// ## Warum ein Leerzustand und kein fehlender Block
///
/// Ausserhalb von Auswertungen gilt: Ein Block ohne Daten rendert nicht. Diese
/// Seite ist die **ausdrückliche Vorgabe des Nutzers vom 16.09.2026** — der
/// Reiter soll schon stehen, damit der Platz für den Katalog sichtbar ist.
/// Deshalb ein ehrlicher Satz, was hier kommt, und **kein Knopf ins Leere**:
/// Es gibt noch nichts zu öffnen, zu kaufen oder zu vormerken.
class PlanCatalogPage extends StatelessWidget {
  const PlanCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 24, AtemSpacing.screenPadding, 130),
      children: [
        AtemEntrance(
          child: AtemEmptyState(
            title: l10n.planCatalogTitle,
            body: l10n.planCatalogBody,
          ),
        ),
      ],
    );
  }
}
