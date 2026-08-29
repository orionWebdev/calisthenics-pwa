import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../application/pending_plan_deletion.dart';
import '../domain/plan.dart';
import 'plan_bits.dart';

/// „Plan wählen" — für „Zu Plan hinzufügen" im Übungsdetail (Board 07, A3/1).
///
/// Ein Sheet im kurzen Höhenmodus aus Modul 2: Auswahl aus mehr als zwei
/// Optionen ist ein Sheet, kein Dialog. Die Zeilen sind die Planzeilen aus
/// Modul 5; die Fusszeile entfällt, weil die Zeilen selbst die Aktion sind.
abstract final class PlanPickerSheet {
  static Future<Plan?> show(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemSheet.show<Plan>(
      context,
      title: l10n.workoutsPlanPick,
      closeLabel: l10n.commonCancel,
      child: const _Body(),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final plans = ref.watch(visiblePlansProvider).value ?? const <Plan>[];

    if (plans.isEmpty) {
      return AtemEmptyState(
        title: l10n.workoutsTodayEmptyTitle,
        body: l10n.planEmptyAllowed,
      );
    }

    return AtemCard.list(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < plans.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AtemColors.border),
            PlanRow(
              plan: plans[i],
              onTap: () => Navigator.of(context).pop(plans[i]),
            ),
          ],
        ],
      ),
    );
  }
}
