import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../../exercises/presentation/muscle_ui.dart';
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
            // IconBox 36 dp mit Initialen (Board 05): Ein Plan hat keinen
            // Muskel, also keine Farbe — die Initialen stehen in #CDD3EA.
            _Initials(name: plan.name),
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
                  Text(meta.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 18, color: AtemColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Die Initialen eines Plans — zweistellig, Mono 700, wie in Modul 5/6.
class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  static String _of(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.map((w) => w[0]).take(2).join();
    return (letters.isEmpty ? '·' : letters).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AtemColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AtemRadii.iconBox),
          ),
          child: Text(
            _of(name),
            style: AtemType.labelDeco.of(context).copyWith(
                  color: AtemColors.textTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
          ),
        ),
      );
}
