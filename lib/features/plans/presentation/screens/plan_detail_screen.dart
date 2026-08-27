import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../domain/plan.dart';
import '../start_sheet.dart';

/// Plandetail mit der Übungsfolge.
///
/// ## Kaputte Pläne blockieren nicht
///
/// Nutzereigene Übungen sind löschbar; ein Plan kann also auf Übungen zeigen,
/// die es nicht mehr gibt. Die Zeile bleibt trotzdem stehen — sie sagt, dass
/// dort etwas war — und ein Hinweis erklärt, dass der Plan ohne sie startet.
///
/// **Ein blockierender Fehler würde den Nutzer für Datenpflege bestrafen.**
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.plan, this.onStart});

  final Plan plan;

  /// Wird mit der Startanfrage gerufen. `null` blendet die Aktion aus — für
  /// die Vorschau.
  final ValueChanged<StartRequest>? onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final byId = {for (final e in exercises) e.id: e};

    final missing =
        plan.items.where((i) => !byId.containsKey(i.exerciseId)).length;

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(backgroundColor: AtemColors.base),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AtemSpacing.screenPadding, 0,
                    AtemSpacing.screenPadding, 24),
                children: [
                  Text(plan.name, style: AtemType.titleLarge.of(context)),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.exerciseCountShort(plan.exerciseCount)} · '
                    '${l10n.durationApproxMinutes(plan.estimatedDuration.inMinutes)} · '
                    '${trainingTypeLabel(l10n, plan.type)}',
                    style: AtemType.labelSmall.of(context),
                  ),
                  if (missing > 0) ...[
                    const SizedBox(height: 18),
                    AtemNotice(
                      title: l10n.planMissingTitle(missing),
                      body: l10n.planMissingBody,
                      semanticLabel:
                          '${l10n.planMissingTitle(missing)}. ${l10n.planMissingBody}',
                    ),
                  ],
                  const SizedBox(height: 20),
                  for (var i = 0; i < plan.items.length; i++) ...[
                    if (i > 0)
                      const Divider(
                          height: 1, thickness: 1, color: AtemColors.border),
                    _ItemRow(
                      index: i + 1,
                      item: plan.items[i],
                      exercise: byId[plan.items[i].exerciseId],
                    ),
                  ],
                ],
              ),
            ),
            if (onStart != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AtemSpacing.screenPadding, 8,
                    AtemSpacing.screenPadding, 12),
                child: AtemButton.gradient(
                  label: l10n.workoutsStart,
                  semanticLabel: l10n.sheetStartTitle(plan.name),
                  onPressed: () async {
                    final request = await StartSheet.show(context, plan: plan);
                    if (request != null) onStart!(request);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.index,
    required this.item,
    required this.exercise,
  });

  final int index;
  final PlanItem item;
  final Exercise? exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final e = exercise;
    final muscle = e?.displayMuscles.firstOrNull;

    // Fehlt die Übung, wird alles grau — Farbe wäre eine Behauptung über etwas,
    // das nicht mehr da ist.
    final nameStyle = AtemType.titleSmallOrDefault(context).copyWith(
      fontWeight: FontWeight.w600,
      color: e == null ? AtemColors.textSecondary : AtemColors.textPrimary,
    );

    final scheme = <String>[
      if (item.sets != null) '${item.sets}×',
      if (item.reps != null) item.reps!,
      if (item.holdSeconds != null) l10n.restSeconds(item.holdSeconds!),
    ].join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text('$index',
                style:
                    AtemType.labelMicro.of(context).copyWith(letterSpacing: 0)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e?.name ?? l10n.planItemMissing,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
                if (muscle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    muscle.label(l10n),
                    style: AtemType.labelMicro.of(context).copyWith(
                          color: muscle.color,
                          letterSpacing: 0,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (scheme.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              scheme,
              style: AtemType.labelMicro.of(context).copyWith(
                    color:
                        e == null ? AtemColors.textSecondary : AtemColors.cyan,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
