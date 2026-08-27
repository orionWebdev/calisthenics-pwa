import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../../dashboard/domain/dashboard_data.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../plans/application/plan_providers.dart';
import '../../../plans/domain/plan.dart';
import '../../../plans/presentation/plan_bits.dart';
import '../../../plans/presentation/screens/plan_detail_screen.dart';
import '../../../plans/presentation/screens/plan_list_screen.dart';
import '../../../plans/presentation/start_sheet.dart';
import '../../../exercises/presentation/screens/exercise_list_screen.dart';

/// Der Workouts-Tab.
///
/// **Zuerst „Was mache ich jetzt?", erst danach „Was gibt es sonst?"** Die
/// heutige Einheit steht ganz oben und ist die einzige hervorgehobene Karte des
/// Bildschirms; Pläne und Übungen sind Nachschlagewerke darunter.
///
/// Er ist zugleich der Eingang zum Runner. Vorher hing der ausschließlich an
/// einem Kalendereintrag — wer keinen hatte, konnte kein Training starten.
class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key, required this.onStart});

  /// Trägt die Startanfrage nach oben. Der Tab kennt den Runner nicht.
  final ValueChanged<StartRequest> onStart;

  static const _plansPreview = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final dashboard = ref.watch(dashboardDataProvider);
    final plans = ref.watch(plansProvider).value ?? const <Plan>[];
    final exerciseCount = ref.watch(exercisesProvider).value?.length ?? 0;

    final session = dashboard.value?.session;

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 130),
          children: [
            Text(l10n.workoutsTitle, style: AtemType.titleLarge.of(context)),
            const SizedBox(height: 20),
            Text(l10n.workoutsTodayLabel,
                style: AtemType.labelMedium.of(context)),
            const SizedBox(height: 10),
            if (dashboard.hasError)
              AtemErrorState(
                title: l10n.listErrorTitle,
                body: l10n.listErrorBody,
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(dashboardDataProvider),
              )
            else if (session != null)
              _TodayCard(session: session, onStart: () => _startToday(context))
            else
              _EmptyToday(onFree: () => _startFree(context)),
            const SizedBox(height: 28),
            _SectionHeader(
              title: l10n.workoutsPlansLabel,
              actionLabel:
                  plans.isEmpty ? null : l10n.workoutsPlansAll(plans.length),
              onAction: plans.isEmpty ? null : () => _openPlans(context),
            ),
            const SizedBox(height: 8),
            if (plans.isEmpty)
              AtemCard.list(
                padding: const EdgeInsets.all(18),
                child: AtemEmptyState(
                  title: l10n.workoutsTodayEmptyTitle,
                  body: l10n.workoutsTodayEmptyBody,
                ),
              )
            else
              AtemCard.list(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0;
                        i < plans.length && i < _plansPreview;
                        i++) ...[
                      if (i > 0)
                        const Divider(
                            height: 1, thickness: 1, color: AtemColors.border),
                      PlanRow(
                        plan: plans[i],
                        onTap: () => _openPlan(context, plans[i]),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 28),
            _SectionHeader(title: l10n.exercisesTitle),
            const SizedBox(height: 8),
            AtemCard.list(
              padding: EdgeInsets.zero,
              child: AtemTappable(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ExerciseListScreen(),
                  ),
                ),
                semanticLabel: l10n.workoutsSearchEntry(exerciseCount),
                minTapSize: const Size(0, 56),
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          size: 20, color: AtemColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.workoutsSearchEntry(exerciseCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtemType.body.of(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AtemButton.outline(
              label: l10n.workoutsFree,
              semanticLabel: l10n.workoutsFreeStart,
              onPressed: () => _startFree(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startFree(BuildContext context) async {
    final request = await StartSheet.show(context);
    if (request != null) onStart(request);
  }

  Future<void> _startToday(BuildContext context) async {
    // Die geplante Einheit von heute kommt aus `schedule`; welcher Plan
    // dahintersteht, weiß der Termin noch nicht. Bis der Planbuilder das
    // verbindet, startet sie wie ein freies Training.
    final request = await StartSheet.show(context);
    if (request != null) onStart(request);
  }

  void _openPlans(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlanListScreen(onStart: onStart),
        ),
      );

  void _openPlan(BuildContext context, Plan plan) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlanDetailScreen(plan: plan, onStart: onStart),
        ),
      );
}

/// Die einzige hervorgehobene Karte des Bildschirms.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.session, required this.onStart});

  final TodaySession session;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemCard.gradientBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(session.title, style: AtemType.titleMedium.of(context)),
          const SizedBox(height: 8),
          Text(
            l10n.durationApproxMinutes(session.duration.inMinutes),
            style: AtemType.labelSmall.of(context),
          ),
          const SizedBox(height: 16),
          AtemButton.gradient(
            label: l10n.workoutsStart,
            semanticLabel: l10n.workoutsStart,
            size: AtemButtonSize.compact,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.onFree});

  final VoidCallback onFree;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemCard.list(
      padding: const EdgeInsets.all(18),
      child: AtemEmptyState(
        title: l10n.workoutsTodayEmptyTitle,
        body: l10n.workoutsTodayEmptyBody,
        action: AtemButton.gradient(
          label: l10n.workoutsFree,
          semanticLabel: l10n.workoutsFreeStart,
          expand: false,
          size: AtemButtonSize.compact,
          onPressed: onFree,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // Beide Seiten flexibel: Bei 200 % Schrift auf 320 dp passen Titel und
    // Aktion sonst nicht nebeneinander und laufen um 11 px über.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtemType.labelMedium.of(context),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: AtemTappable(
              onTap: onAction,
              semanticLabel: actionLabel!,
              alignment: Alignment.centerRight,
              child: Text(
                actionLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AtemType.labelSmall
                    .of(context)
                    .copyWith(color: AtemColors.cyan),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
