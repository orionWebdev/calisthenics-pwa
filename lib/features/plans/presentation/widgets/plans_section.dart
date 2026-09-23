import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/domain/muscle.dart';
import '../../../settings/application/settings_providers.dart';
import '../../application/pending_plan_deletion.dart';
import '../../application/plan_providers.dart';
import '../../domain/plan.dart';
import '../screens/plan_detail_screen.dart';
import '../screens/plan_form_screen.dart';
import '../screens/plan_list_screen.dart';
import '../start_sheet.dart';
import 'plan_card.dart';

/// Der Abschnitt „Pläne" — **die eigenen und die kommenden, an einem Ort**.
///
/// ## Warum beides hier steht
///
/// Bis zum 20.09.2026 lagen die eigenen Pläne als Kartenreihe im Abschnitt
/// „Trainieren" und die Ankündigung des ATEM-Katalogs auf einer eigenen,
/// sonst leeren Seite. Wer seine Pläne suchte, fand unter dem Reiter „Pläne"
/// eine Seite, auf der ausdrücklich stand, dass seine Pläne woanders seien.
///
/// Jetzt trägt der Abschnitt beides: oben die eigenen Pläne mit dem Weg zur
/// vollständigen Liste und zum neuen Plan, darunter, was von ATEM kommt.
///
/// ## Die Ankündigung bleibt, obwohl sie leer ist
///
/// Ausserhalb von Auswertungen gilt: Ein Block ohne Daten rendert nicht.
/// Dieser ist die **ausdrückliche Vorgabe des Nutzers vom 16.09.2026** — der
/// Platz für den Katalog soll sichtbar sein. Deshalb ein ehrlicher Satz, was
/// hier kommt, und **kein Knopf ins Leere**: Es gibt noch nichts zu öffnen,
/// zu kaufen oder vorzumerken.
class PlansSection extends ConsumerWidget {
  const PlansSection({super.key, required this.onStart});

  final ValueChanged<StartRequest> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(visiblePlansProvider);
    final exerciseList = ref.watch(exercisesProvider).value ?? const [];
    final exercisesById = {for (final e in exerciseList) e.id: e};

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemEntrance(
            child: async.when(
              // Ein Ladegate je Seite (Board 13, Entscheidung 11) — es
              // steht weiter oben. Was hier unten liegt, kommt nach, während
              // man dorthin scrollt.
              loading: () => const SizedBox.shrink(),
              error: (_, __) => AtemErrorState(
                title: l10n.listErrorTitle,
                body: l10n.listErrorBody,
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(plansProvider),
              ),
              data: (plans) => _Own(
                plans: plans,
                exercisesById: exercisesById,
                onOpenList: () => _openList(context),
                onOpen: (plan) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlanDetailScreen(
                      plan: plan,
                      onStart: onStart,
                    ),
                  ),
                ),
                onStartPlan: (plan) => _startPlan(context, ref, plan),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AtemEntrance(
            index: 1,
            child: AtemButton.outline(
              label: l10n.planFormNewTitle,
              semanticLabel: l10n.planFormNewTitle,
              leading: const Icon(Icons.add, size: 18, color: AtemColors.cyan),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PlanFormScreen()),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const AtemEntrance(index: 2, child: PlanCatalogTeaser()),
        ],
      ),
    );
  }

  void _openList(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlanListScreen(onStart: onStart),
        ),
      );

  /// Startet einen Plan aus seiner Karte — derselbe Weg wie im Plandetail:
  /// erst das Start-Blatt, dann der Runner.
  Future<void> _startPlan(
      BuildContext context, WidgetRef ref, Plan plan) async {
    final request = await StartSheet.show(
      context,
      plan: plan,
      restSeconds: ref.read(defaultRestSecondsProvider),
    );
    if (request != null) onStart(request);
  }
}

class _Own extends StatelessWidget {
  const _Own({
    required this.plans,
    required this.exercisesById,
    required this.onOpenList,
    required this.onOpen,
    required this.onStartPlan,
  });

  final List<Plan> plans;
  final Map<String, Exercise> exercisesById;
  final VoidCallback onOpenList;
  final ValueChanged<Plan> onOpen;
  final ValueChanged<Plan> onStartPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtemBlockHeader(
          title: l10n.plansOwnLabel.toUpperCase(),
          actionLabel:
              plans.isEmpty ? null : l10n.workoutsPlansAll(plans.length),
          onAction: plans.isEmpty ? null : onOpenList,
        ),
        const SizedBox(height: 10),
        if (plans.isEmpty)
          Semantics(
            container: true,
            label: '${l10n.workoutsTodayEmptyTitle}. '
                '${l10n.workoutsTodayEmptyBody}',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.workoutsTodayEmptyTitle,
                        style: AtemType.titleMedium.of(context)),
                    const SizedBox(height: 4),
                    Text(l10n.workoutsTodayEmptyBody,
                        style: AtemType.labelSmall.of(context)),
                  ],
                ),
              ),
            ),
          )
        else
          PlanCardRow(
            plans: plans,
            horizontalPadding: 0,
            musclesOf: (plan) => _musclesOf(plan, exercisesById),
            leadOf: (plan) => planLeadRegion(plan, exercisesById),
            onOpen: onOpen,
            onStart: onStartPlan,
          ),
      ],
    );
  }

  /// Die Muskeln eines Plans, nach Häufigkeit über seine Übungen.
  static List<MuscleGroup> _musclesOf(
      Plan plan, Map<String, Exercise> exercisesById) {
    final counts = <MuscleGroup, int>{};
    for (final item in plan.items) {
      final exercise = exercisesById[item.exerciseId];
      if (exercise == null) continue;
      for (final m in exercise.displayMuscles) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(3).toList();
  }
}

/// Was von ATEM kommt — **ein Satz, kein Knopf**.
///
/// Der leere Platz trägt den **gestrichelten Rand** aus Modul 2 („hier fehlt
/// etwas", als Form statt als Farbe) und keinen Knopf: Es gibt nichts zu
/// tippen, was den Zustand ändert. Keine Live-Region und kein Fokus — eine
/// Ankündigung ist kein Ereignis.
class PlanCatalogTeaser extends StatelessWidget {
  const PlanCatalogTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Semantics(
      container: true,
      label: '${l10n.plansAtemLabel}. ${l10n.planCatalogBody}',
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: const _DashedBorder(),
          child: Padding(
            padding: const EdgeInsets.all(AtemSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.plansAtemLabel.toUpperCase(),
                    style: AtemType.labelMicro.of(context)),
                const SizedBox(height: 4),
                Text(l10n.planCatalogBody,
                    style: AtemType.labelSmall.of(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Der gestrichelte Rand aus Modul 2 — „hier fehlt etwas" als Form, nicht als
/// Farbe.
class _DashedBorder extends CustomPainter {
  const _DashedBorder();

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AtemRadii.card),
    );
    canvas.drawRRect(rect, Paint()..color = AtemColors.card);

    final paint = Paint()
      ..color = AtemColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}

/// Die Hauptregion eines Plans — sie färbt die Aurora seiner Karte
/// (entschieden am 23.09.2026).
///
/// Gezählt werden **Hauptmuskeln**, gewichtet nach Sätzen: Bankdrücken
/// mit vier Sätzen zählt viermal Brust, nicht einmal Brust, Trizeps und
/// Schulter. Eigene Übungen kennen noch keinen Hauptmuskel; bis Board 21
/// festlegt, wie sie unterschieden werden, zählt ihr erster Muskel. Bei
/// Gleichstand gewinnt die Region, die im Plan zuerst vorkommt.
MuscleRegion? planLeadRegion(
    Plan plan, Map<String, Exercise> exercisesById) {
  final weight = <MuscleRegion, int>{};
  final order = <MuscleRegion>[];
  for (final item in plan.items) {
    final exercise = exercisesById[item.exerciseId];
    if (exercise == null) continue;
    final lead = exercise.primaryMuscles.isNotEmpty
        ? exercise.primaryMuscles
        : exercise.displayMuscles.take(1);
    for (final m in lead) {
      final region = m.region;
      if (!weight.containsKey(region)) order.add(region);
      weight[region] = (weight[region] ?? 0) + (item.sets ?? 3);
    }
  }
  if (order.isEmpty) return null;
  return order.reduce((a, b) => weight[b]! > weight[a]! ? b : a);
}
