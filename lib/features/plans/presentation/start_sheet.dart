import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/plan.dart';

/// Was gestartet werden soll.
class StartRequest {
  const StartRequest({this.plan, this.scheduleId, required this.restSeconds});

  /// `null` heißt freies Training.
  final Plan? plan;

  /// Der Kalendertermin, falls die Einheit aus einem stammt. Er wird beim
  /// Speichern als erledigt markiert.
  final String? scheduleId;

  final int restSeconds;

  bool get isFree => plan == null;
}

/// Die Bestätigung vor dem Runner.
///
/// ## Warum ein Sheet und kein direkter Sprung
///
/// Der Runner übernimmt den Vollbildmodus und startet eine Einheit mit Folgen —
/// Kalendereintrag, Verlauf, Auswertung. Ein Tap ohne Rückfrage wäre der
/// teuerste Fehltap der App. Das Sheet kostet einen Tap, zeigt die Pausenzeit
/// und macht den Abbruch billig.
///
/// **Ein Sheet für beide Wege.** Freies Training bekommt keinen eigenen Ablauf:
/// Ein Assistent („wähle erst Übungen") widerspräche seinem Zweck, nämlich
/// sofort anzufangen. Der Runner beginnt dann leer, Übungen kommen dort dazu.
abstract final class StartSheet {
  static const defaultRestSeconds = 90;

  /// Gibt `null` zurück, wenn abgebrochen wurde.
  static Future<StartRequest?> show(
    BuildContext context, {
    Plan? plan,
    String? scheduleId,
    int restSeconds = defaultRestSeconds,
  }) {
    final l10n = AppL10n.of(context);
    final title =
        plan == null ? l10n.workoutsFreeStart : l10n.sheetStartTitle(plan.name);

    // **Die Pausenzeit gehört dem Sheet, nicht dem Aufrufer.** Sie kommt als
    // Vorgabe herein und wird hier geändert — der Startknopf liest den
    // aktuellen Stand, nicht den beim Öffnen.
    final chosen = ValueNotifier<int>(restSeconds);

    return AtemSheet.show<StartRequest>(
      context,
      title: title,
      closeLabel: l10n.commonCancel,
      child: _Body(plan: plan, rest: chosen, l10n: l10n),
      primaryAction: AtemButton.gradient(
        label: l10n.sheetStart,
        semanticLabel: title,
        onPressed: () => Navigator.of(context).pop(
          StartRequest(
            plan: plan,
            scheduleId: scheduleId,
            restSeconds: chosen.value,
          ),
        ),
      ),
      // Schliessen ist nie nur Geste: „Abbrechen" als expliziter Knopf
      // (Board 05, A5 und F).
      secondaryAction: AtemButton.ghost(
        label: l10n.commonCancel,
        semanticLabel: l10n.commonCancel,
        expand: true,
        accent: AtemColors.textTertiary,
        onPressed: () => Navigator.of(context, rootNavigator: true).maybePop(),
      ),
    );
  }
}

/// Der Inhalt: Umfang der Einheit und die Pausenzeit, die gleich gilt.
class _Body extends StatefulWidget {
  const _Body({
    required this.plan,
    required this.rest,
    required this.l10n,
  });

  final Plan? plan;
  final ValueNotifier<int> rest;
  final AppL10n l10n;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  /// Die Vorauswahl bleibt zu, bis jemand sie braucht. Der häufige Fall ist
  /// „Vorgabe stimmt" — ein aufgeklappter Wähler machte aus einem
  /// Bestätigungsschritt ein Formular.
  bool _open = false;

  /// Dieselben Stufen wie in den Einstellungen (Board 08, A3). Zwei Orte mit
  /// zwei Vorratslisten wären zwei Wahrheiten.
  static const _presets = [45, 60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final p = widget.plan;

    return ValueListenableBuilder<int>(
      valueListenable: widget.rest,
      builder: (context, rest, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            p == null
                ? l10n.sheetFreeBody
                : '${l10n.exerciseCountShort(p.exerciseCount)} · '
                    '${l10n.durationApproxMinutes(p.estimatedDuration.inMinutes)}',
            style: AtemType.labelSmall.of(context),
          ),
          const SizedBox(height: 16),
          AtemTappable(
            onTap: () => setState(() => _open = !_open),
            semanticLabel: '${l10n.sheetRestLabel}, ${l10n.restSeconds(rest)}',
            child: AtemStatBox(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.sheetRestLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtemType.labelSmall.of(context)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.restSeconds(rest),
                    style: AtemType.valueMedium
                        .of(context)
                        .copyWith(color: AtemColors.cyan),
                  ),
                  const SizedBox(width: 6),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: AtemColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in {..._presets, rest}.toList()..sort())
                  _RestChip(
                    seconds: value,
                    selected: value == rest,
                    onTap: () => widget.rest.value = value,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Eine Pausenstufe. Wort und Haken, nicht nur Farbe.
class _RestChip extends StatelessWidget {
  const _RestChip({
    required this.seconds,
    required this.selected,
    required this.onTap,
  });

  final int seconds;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = AppL10n.of(context).restSeconds(seconds);
    return AtemTappable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: selected
              ? AtemCategories.surface(AtemColors.cyan)
              : AtemColors.surfaceSolid,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: selected
                ? AtemCategories.border(AtemColors.cyan)
                : AtemColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: AtemColors.cyan),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AtemType.valueMedium.of(context).copyWith(
                    fontSize: 13,
                    color:
                        selected ? AtemColors.cyan : AtemColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
