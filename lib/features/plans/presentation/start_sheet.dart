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

    return AtemSheet.show<StartRequest>(
      context,
      title: title,
      closeLabel: l10n.commonCancel,
      child: _Body(plan: plan, restSeconds: restSeconds, l10n: l10n),
      primaryAction: AtemButton.gradient(
        label: l10n.sheetStart,
        semanticLabel: title,
        onPressed: () => Navigator.of(context).pop(
          StartRequest(
            plan: plan,
            scheduleId: scheduleId,
            restSeconds: restSeconds,
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

class _Body extends StatelessWidget {
  const _Body({
    required this.plan,
    required this.restSeconds,
    required this.l10n,
  });

  final Plan? plan;
  final int restSeconds;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    final p = plan;

    return Column(
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
        AtemStatBox(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.sheetRestLabel, style: AtemType.labelSmall.of(context)),
              Text(
                l10n.restSeconds(restSeconds),
                style: AtemType.valueMedium.of(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
