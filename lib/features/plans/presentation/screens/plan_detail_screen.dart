import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../app/application/snackbar_providers.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../../settings/application/settings_providers.dart';
import '../../application/pending_plan_deletion.dart';
import '../../domain/plan.dart';
import '../start_sheet.dart';
import 'plan_form_screen.dart';

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
                  const SizedBox(height: 32),
                  AtemButton.outline(
                    label: l10n.commonEdit,
                    semanticLabel: '${l10n.commonEdit}: ${plan.name}',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlanFormScreen(original: plan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AtemButton.ghost(
                    label: l10n.commonDelete,
                    semanticLabel: '${l10n.commonDelete}: ${plan.name}',
                    accent: AtemColors.magenta,
                    onPressed: () => _delete(context, ref, plan),
                  ),
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
                    final request = await StartSheet.show(
                      context,
                      plan: plan,
                      restSeconds: ref.read(defaultRestSecondsProvider),
                    );
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

/// Plan löschen — **zwei Stufen, dann dreissig Sekunden Widerruf**.
///
/// ## Warum beides, obwohl nichts daran hängt
///
/// Absolvierte Einheiten tragen `planName` in sich selbst und bleiben
/// vollständig lesbar; es geht nur die Zusammenstellung verloren. Genau die
/// ist aber Arbeit — bis zu sechs Einträge mit Zielwerten und Reihenfolge.
///
/// Deshalb sagt die Schreibmatrix des Boards: zweistufig **und** Widerruf.
/// Der Widerruf ist hier möglich, weil nichts anderes an dem Plan hängt —
/// anders als beim Löschen einer Übung, wo Planeinträge umgeschrieben werden.
Future<void> _delete(BuildContext context, WidgetRef ref, Plan plan) async {
  final l10n = AppL10n.of(context);

  final first = await AtemDialog.show<bool>(
    context,
    kind: AtemDialogKind.destructive,
    title: l10n.planDeleteTitle,
    message: l10n.planDeleteBody,
    confirmLabel: l10n.deleteStep1Continue,
    dismissLabel: l10n.commonCancel,
    barrierLabel: l10n.planDeleteTitle,
    detail: Text(
      l10n.exerciseCountShort(plan.exerciseCount),
      style: AtemType.labelSmall.of(context),
    ),
    onConfirm: () => Navigator.of(context).pop(true),
  );
  if (first != true || !context.mounted) return;

  final second = await AtemDialog.show<bool>(
    context,
    kind: AtemDialogKind.destructive,
    title: l10n.deleteStep2Title,
    message: l10n.sessionDeleteWindow,
    confirmLabel: l10n.deleteConfirm,
    dismissLabel: l10n.deleteKeep,
    barrierLabel: l10n.planDeleteTitle,
    onConfirm: () => Navigator.of(context).pop(true),
  );
  if (second != true) return;

  await ref.read(pendingPlanDeletionProvider.notifier).start(plan);
  if (!context.mounted) return;

  ref.read(snackbarProvider.notifier).show(
        AtemSnack(
          message: l10n.planDeleteTitle,
          semanticLabel: '${l10n.planDeleteTitle} ${plan.name}',
          actionLabel: l10n.commonUndo,
          onAction: () =>
              ref.read(pendingPlanDeletionProvider.notifier).undo(),
        ),
      );
  Navigator.of(context).pop();
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
                  // Der deutsche Name, wenn es einen gibt — `name` ist der
                  // englische Grundname aus dem Bestand.
                  e == null ? l10n.planItemMissing : exerciseName(context, e),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
                if (muscle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    muscle.label(l10n).toUpperCase(),
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(color: muscle.color),
                  ),
                ],
              ],
            ),
          ),
          if (scheme.isNotEmpty) ...[
            const SizedBox(width: 10),
            // „4×8" ist ein Messwert, kein Schmuck: Cyan-Mono, gross genug
            // zum Ablesen (Board 05, A4/2).
            Text(
              scheme,
              style: AtemType.valueMedium.of(context).copyWith(
                    fontSize: 14,
                    color:
                        e == null ? AtemColors.textSecondary : AtemColors.cyan,
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
