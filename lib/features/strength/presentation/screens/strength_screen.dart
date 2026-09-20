import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/tab_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/presentation/widgets/analysis_section.dart';
import '../../../history/presentation/widgets/history_section.dart';
import '../../../plans/presentation/start_sheet.dart';
import '../../../plans/presentation/widgets/plans_section.dart';
import '../../../workout/presentation/widgets/train_section.dart';

/// Der Kraft-Tab — **eine Seite, vier Abschnitte**.
///
/// ## Was sich am 20.09.2026 geändert hat
///
/// Vorher waren es vier wischbare Seiten in einem `PageView`, jede mit
/// eigenem Scrollstand, dahinter eine Pillenleiste. Wer den Verlauf sehen
/// wollte, musste wissen, dass er existiert und in welche Richtung er liegt.
///
/// Jetzt ist es ein One-Pager: Man scrollt aus „Trainieren" in den
/// „Verlauf", weiter in die „Auswertung" und zuletzt in die „Pläne".
///
/// Oben klebt die **Ortszeile** ([AtemSectionBar], Board 13) — ein Wort, ein
/// Zähler, ein Chevron und vier Marken. Sie zeigt immer nur das Thema, in dem
/// man steht; die anderen drei liegen vollständig in einer Liste, die ein
/// Tipp aufklappt. Damit schneidet die Navigation nie ein Wort ab, auch nicht
/// bei 200 % Systemschrift auf 320 dp. Sie ist zugleich die Überschrift des
/// Themas — deshalb trägt der Tab keinen eigenen Kopf mehr, und kein Thema
/// wiederholt seinen Namen im Inhalt.
///
/// Zwischen zwei Themen liegt eine Fuge ([AtemSectionSeam]): Man soll auch im
/// schnellen Scrollen merken, dass gerade eines zu Ende ist. Nach dem letzten
/// steht die Endfuge — Ende statt Ankündigung.
///
/// ## Wer was trägt
///
/// * **Trainieren** ([TrainSection]) — wie man anfängt, sonst nichts. Die
///   Übungen liegen seitdem auf ihrer eigenen Unterseite.
/// * **Verlauf** ([HistorySection]) — Monate, Muskelbalance, letzte
///   Einheiten, und die Einheitenzahl, die vorher im Kopf stand.
/// * **Auswertung** ([AnalysisSection]) — jeder Block immer, unter seiner
///   Schwelle als Umriss mit Bedingung.
/// * **Pläne** ([PlansSection]) — die eigenen **und** der kommende
///   ATEM-Katalog; vorher lagen die eigenen unter „Trainieren".
///
/// ## Seite und Provider
///
/// [StrengthSegment] im [appTabsProvider] bleibt die eine Wahrheit. Scrollen
/// setzt es; ein Sprung von aussen — die Kraft-Zeile im Hybrid-Tab öffnet den
/// Verlauf — scrollt an den Abschnitt. Systemzurück wechselt keinen
/// Abschnitt.
class StrengthScreen extends ConsumerWidget {
  const StrengthScreen({super.key, required this.onStart});

  final ValueChanged<StartRequest> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final segment = ref.watch(appTabsProvider.select((s) => s.strengthSegment));

    // Der Ton des Bereichs: er färbt das Symbol in der Leiste, den
    // Unterstrich der Reiterleiste und die Fuge zwischen den Abschnitten.
    return AtemTabTheme(
      tone: AtemColors.tabStrength,
      child: Scaffold(
        backgroundColor: AtemColors.base,
        body: SafeArea(
          bottom: false,
          child: AtemSectionPage(
            selected: segment.index,
            onSelected: (i) => ref
                .read(appTabsProvider.notifier)
                .setStrengthSegment(StrengthSegment.values[i]),
            barSemanticLabel: l10n.sectionBarA11y,
            jumpListLabel: l10n.sectionJumpTitle,
            jumpSemanticLabel: l10n.sectionJumpA11y,
            arrivedSemanticLabel: l10n.sectionArrivedA11y,
            hereLabel: l10n.sectionHere,
            sections: [
              AtemSection(
                label: l10n.segTrain,
                child: TrainSection(onStart: onStart),
              ),
              AtemSection(
                label: l10n.segHistory,
                child: const HistorySection(),
              ),
              AtemSection(
                label: l10n.segAnalysis,
                child: const AnalysisSection(),
              ),
              AtemSection(
                label: l10n.segPlans,
                child: PlansSection(onStart: onStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
