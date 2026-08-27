import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/plan_providers.dart';
import '../../domain/plan.dart';
import '../plan_bits.dart';
import '../start_sheet.dart';
import 'plan_detail_screen.dart';
import 'plan_form_screen.dart';

/// Alle Pläne.
class PlanListScreen extends ConsumerWidget {
  const PlanListScreen({super.key, this.onStart});

  final ValueChanged<StartRequest>? onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(plansProvider);

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.workoutsPlansLabel,
            style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _list(context, ref, l10n, async)),
            // Der Weg zum neuen Plan steht unten und fest, nicht als
            // schwebender Knopf über der Liste: Er würde sonst die letzte
            // Planzeile verdecken, und die schwebende Navigation ist an dieser
            // Stelle des Bildschirms schon vergeben.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 12),
              child: AtemButton.outline(
                label: l10n.planFormNewTitle,
                semanticLabel: l10n.planFormNewTitle,
                leading:
                    const Icon(Icons.add, size: 18, color: AtemColors.cyan),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlanFormScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    AsyncValue<List<Plan>> async,
  ) =>
      async.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtemSpacing.screenPadding),
            child: AtemSkeleton(
              semanticLabel: l10n.dashboardLoadingA11y,
              blocks: const [
                AtemSkeletonBlock(height: 64, radius: 14),
                AtemSkeletonBlock(height: 64, radius: 14),
                AtemSkeletonBlock(height: 64, radius: 14),
              ],
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtemSpacing.screenPadding),
            child: AtemErrorState(
              title: l10n.listErrorTitle,
              body: l10n.listErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(plansProvider),
            ),
          ),
          data: (plans) => plans.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AtemSpacing.screenPadding),
                  child: AtemEmptyState(
                    title: l10n.workoutsTodayEmptyTitle,
                    body: l10n.workoutsTodayEmptyBody,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AtemSpacing.screenPadding,
                      0, AtemSpacing.screenPadding, 24),
                  itemCount: plans.length + 1,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, thickness: 1, color: AtemColors.border),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(l10n.planCount(plans.length),
                            style: AtemType.labelMicro.of(context)),
                      );
                    }
                    final plan = plans[i - 1];
                    return PlanRow(
                      plan: plan,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PlanDetailScreen(plan: plan, onStart: onStart),
                        ),
                      ),
                    );
                  },
                ),
      );
}
