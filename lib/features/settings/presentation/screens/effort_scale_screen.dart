import 'package:flutter/material.dart' show AppBar, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/settings_providers.dart';
import '../../domain/user_settings.dart';

/// „Anstrengung je Satz" — RPE oder RIR, **auf einer eigenen Seite**.
///
/// Bis zum 21.09.2026 standen die zwei Segmente mitten in der Trainingsliste.
/// Die Wahl hat aber eine Erklärung, eine Richtung und zwei Namen; in einer
/// Zeile zwischen Pausenzeit und Einheiten war das zu viel — und auf der Seite
/// dahinter ist Platz dafür.
///
/// ## Was sich hier ändert
///
/// **Nur die Anzeige.** Gespeichert wird immer RPE 1–10; RIR ist dieselbe Zahl
/// von der anderen Seite gezählt. Ein Wechsel wirkt sofort auf jede
/// Anstrengung im Bestand und geht jederzeit zurück. Deshalb kein „Übernehmen":
/// Ein Blatt mit Bestätigung liesse das Gegenteil vermuten.
class EffortScaleScreen extends ConsumerWidget {
  const EffortScaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final settings = ref.watch(settingsProvider).value ?? const UserSettings();

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.settingsEffortScale,
            style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 40),
          children: [
            AtemSegmented<EffortScale>(
              value: settings.effortScale,
              groupSemanticLabel: l10n.settingsEffortScaleGroupA11y,
              onChanged: (value) => ref
                  .read(settingsControllerProvider.notifier)
                  .update(settings.copyWith(effortScale: value)),
              segments: [
                AtemSegment(
                  value: EffortScale.rpe,
                  label: l10n.settingsEffortScaleRpeLong,
                  semanticLabel: l10n.settingsEffortScaleRpeA11y,
                ),
                AtemSegment(
                  value: EffortScale.rir,
                  label: l10n.settingsEffortScaleRirLong,
                  semanticLabel: l10n.settingsEffortScaleRirA11y,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Die Richtung einmal im Klartext: „hoch ist schwer" gegen
            // „niedrig ist schwer". Ohne sie wäre RIR 2 leicht mit RPE 2 zu
            // verwechseln.
            Text(
              settings.effortScale == EffortScale.rir
                  ? l10n.settingsEffortScaleValueRir
                  : l10n.settingsEffortScaleValue,
              style: AtemType.body.of(context),
            ),
            const SizedBox(height: 12),
            Text(l10n.settingsEffortScaleExplain,
                style: AtemType.meta.of(context)),
          ],
        ),
      ),
    );
  }
}
