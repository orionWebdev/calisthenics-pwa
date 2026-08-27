import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../../exercises/presentation/muscle_ui.dart';
import '../../exercises/presentation/widgets/exercise_bits.dart';
import '../domain/plan.dart';

/// Eine Zeile der Planliste.
///
/// **Kein Fortschrittsring.** Die Daten kennen name, icon, type und items —
/// keinen Fortschritt. Ein Ring würde Präzision behaupten, die nicht existiert.
class PlanRow extends StatelessWidget {
  const PlanRow({super.key, required this.plan, required this.onTap});

  final Plan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final meta =
        l10n.planMeta(plan.exerciseCount, trainingTypeLabel(l10n, plan.type));

    return AtemTappable(
      onTap: onTap,
      semanticLabel: '${plan.name}. $meta',
      minTapSize: const Size(0, 64),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Neutral, nicht eingefärbt: Ein Plan hat keine Region.
            ExerciseInitials(name: plan.name, color: AtemCategories.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.titleSmallOrDefault(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
