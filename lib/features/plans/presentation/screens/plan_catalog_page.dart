import 'package:flutter/material.dart' show Icons;
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
    // **Kein `AtemEmptyState`** (seit 17.09.2026): Der Baustein kürzt seinen
    // Text nach zwei Zeilen mit „…". Am Gerät stand hier „Deine eigenen…" —
    // ein abgeschnittener Satz ist kein ehrlicher Satz. Derselbe Aufbau,
    // aber der Text steht vollständig und wächst mit der Schrift.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 40, AtemSpacing.screenPadding, 130),
      children: [
        AtemEntrance(
          child: Semantics(
            container: true,
            label: '${l10n.planCatalogTitle}. ${l10n.planCatalogBody}',
            child: ExcludeSemantics(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AtemColors.tabStrength.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AtemRadii.iconBox),
                    ),
                    child: const Icon(Icons.auto_awesome_outlined,
                        size: 22, color: AtemColors.tabStrength),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.planCatalogTitle,
                    textAlign: TextAlign.center,
                    style: AtemType.titleMedium.of(context),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    // Lesbare Zeilenlänge: nicht über die volle Breite.
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      l10n.planCatalogBody,
                      textAlign: TextAlign.center,
                      style: AtemType.labelSmall.of(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
