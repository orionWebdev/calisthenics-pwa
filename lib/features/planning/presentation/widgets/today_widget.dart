import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../plans/application/plan_providers.dart';
import '../../../plans/domain/plan.dart';
import '../../../plans/presentation/plan_bits.dart' show planMetaLine;
import '../../application/training_goal_providers.dart';
import '../../application/week_plan_providers.dart';
import '../../domain/training_goal.dart';
import '../../domain/week_plan.dart';
import '../screens/week_screen.dart';
import '../week_ui.dart';

/// „Was wird heute trainiert?" — das Widget im Hybrid-Tab (Board 19, D).
///
/// Nachfolger von `TodayWeekCard`. Oben der Heute-Block — nur, wenn heute
/// etwas steht —, darunter der Wochenstreifen — nur, wenn es eine Woche
/// gibt —, unten die Fusszeile als einziger Weg in die Planung.
///
/// ## Was es nicht tut
///
/// Es startet nichts und schreibt nichts (Entscheidung 15): Starten bleibt
/// beim Startblock im Kraft-Tab und im Cardio-Tab. Kein Häkchen, kein
/// Zähler, keine Ampel im Streifen — jede Markierung vergangener Tage würde
/// als erfüllt oder versäumt gelesen.
///
/// ## Wann es nicht rendert
///
/// Nie geplant und kein Termin: gar nicht. Der Tab beginnt dann mit der
/// Bereitschaft; der Weg zur Planung ist das Kalender-Symbol im Kopf.
class TodayWidget extends ConsumerWidget {
  const TodayWidget({super.key, this.gapAfter = 0});

  /// Abstand darunter — nur, wenn das Widget rendert. Ohne es bliebe eine
  /// Lücke, wo nichts steht.
  final double gapAfter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final words = WeekWords(context);
    final today = ref.watch(todayPlanProvider);
    final week = ref.watch(weekPlanProvider).value;
    final goal = ref.watch(trainingGoalProvider).value ?? TrainingGoal.empty;
    final plans = ref.watch(plansProvider).value ?? const <Plan>[];
    final date = ref.watch(historyReferenceProvider);

    if (today.hasError) {
      return Padding(
        padding: EdgeInsets.only(bottom: gapAfter),
        child: _Error(onRetry: () => ref.invalidate(weekPlanProvider)),
      );
    }
    final items = today.value;
    if (items == null) return const SizedBox.shrink();
    final side = weekSideOn(date, goal);
    final hasWeek = week != null && week.of(side).isNotEmpty;
    if (items.isEmpty && !hasWeek) return const SizedBox.shrink();

    final weekday = words.dayLong(date.weekday);
    String titleOf(TodayItem i) => i.entry != null
        ? words.title(i.entry!, plans)
        : i.appointmentTitle ?? l10n.weekStrengthFree;
    String metaOf(TodayItem i) {
      if (i.entry != null) return words.meta(i.entry!, plans);
      final plan = plans.where((p) => p.id == i.appointmentPlanId).firstOrNull;
      return plan == null
          ? l10n.weekKindStrength
          : '${l10n.weekKindStrength} · ${planMetaLine(l10n, plan)}';
    }

    String sourceOf(TodayItem i) => i.source == TodaySource.week
        ? l10n.todaySourceWeek
        : l10n.todaySourceAppointment;

    final spoken = items.isEmpty
        ? l10n.todayWeekA11y([
            for (final d in WeekWords.weekdays)
              '${words.dayLong(d)}: ${_dayWords(words, week!.day(side, d), plans)}',
          ].join('; '))
        : l10n.todayA11y(
            weekday,
            items.map(titleOf).join(', '),
            items.map(sourceOf).toSet().join(', ').toLowerCase(),
          );

    return Padding(
      padding: EdgeInsets.only(bottom: gapAfter),
      child: Container(
      decoration: BoxDecoration(
        color: AtemColors.card,
        borderRadius: AtemRadii.cardR,
        border: Border.all(color: AtemColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ein Knoten für Heute und Woche; die Fusszeile ist der zweite.
          Semantics(
            container: true,
            label: spoken,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      items.isEmpty
                          ? l10n.todayKickerWeek
                          : l10n.todayKicker(weekday.toUpperCase()),
                      style: AtemType.labelMicro.of(context),
                    ),
                    for (final i in items) ...[
                      const SizedBox(height: 8),
                      _TodayRow(
                        kind: i.kind,
                        title: titleOf(i),
                        meta: metaOf(i),
                        source: sourceOf(i),
                      ),
                    ],
                    if (hasWeek) ...[
                      const SizedBox(height: 12),
                      _WeekStrip(
                        week: week,
                        side: side,
                        today: date.weekday,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(height: 1, color: AtemColors.border),
          Semantics(
            container: true,
            child: AtemTappable(
              semanticLabel: l10n.hybridWeekButtonA11y,
              minTapSize: const Size(double.infinity, 52),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const WeekScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.todayLink,
                        style: AtemType.labelSmall.of(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AtemColors.cyan),
                      ),
                    ),
                    const AtemGlyph('M9 6l6 6-6 6',
                        color: AtemColors.cyan, size: 16, strokeWidth: 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  static String _dayWords(
      WeekWords words, List<WeekEntry> entries, List<Plan> plans) {
    if (entries.isEmpty) return words.l10n.todayStripNone;
    return entries.map((e) => words.title(e, plans)).join(', ');
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({
    required this.kind,
    required this.title,
    required this.meta,
    required this.source,
  });

  final WeekKind kind;
  final String title;
  final String meta;
  final String source;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: AtemColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AtemRadii.statBox),
        ),
        child: Row(
          children: [
            WeekLaneTile(kind: kind),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AtemType.labelSmall.of(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AtemColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(meta,
                      style: AtemType.labelSmall.of(context).copyWith(
                          fontSize: 12, color: AtemColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(source, style: AtemType.labelMicro.of(context)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Der Wochenstreifen: sieben Zellen, Montag bis Sonntag, je Eintrag ein
/// Pip in der Farbe der Spur. **Nicht tippbar** — ein Weg in die Planung
/// genügt. Ab 145 % Schrift wird aus der Reihe ein Umbruch aus Zellen mit
/// den Pips neben dem Kürzel (Board 19, D13).
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.week,
    required this.side,
    required this.today,
  });

  final WeekPlan week;
  final WeekSide side;
  final int today;

  @override
  Widget build(BuildContext context) {
    final words = WeekWords(context);
    final wide = MediaQuery.textScalerOf(context).scale(1) > 1.45;
    Widget cell(int d) {
      final entries = week.day(side, d);
      final isToday = d == today;
      final pips = [
        for (final e in entries)
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: e.kind == WeekKind.strength
                  ? AtemColors.tabStrength.withValues(alpha: 0.85)
                  : e.kind == WeekKind.cardio
                      ? AtemColors.violet
                      : AtemColors.surfaceSolid,
              borderRadius: BorderRadius.circular(4),
              border: e.kind == WeekKind.off
                  ? Border.all(color: AtemColors.textSecondary)
                  : null,
            ),
          ),
      ];
      final label = Text(
        words.dayShort(d),
        style: AtemType.labelMicro.of(context).copyWith(
              color: isToday ? AtemColors.textPrimary : AtemColors.textSecondary,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
      );
      return Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isToday ? AtemColors.surfaceRaised : null,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: AtemColors.textTertiary, width: 1.5)
              : null,
        ),
        child: wide
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                label,
                const SizedBox(width: 6),
                ...pips.expand((p) => [p, const SizedBox(width: 3)]),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                label,
                const SizedBox(height: 4),
                Wrap(spacing: 3, runSpacing: 3, children: pips),
              ]),
      );
    }

    if (wide) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final d in WeekWords.weekdays) cell(d)],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, d) in WeekWords.weekdays.indexed) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(child: cell(d)),
        ],
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Semantics(
      container: true,
      child: AtemTappable(
        semanticLabel: '${l10n.todayErr} ${l10n.commonRetry}',
        alignment: Alignment.centerLeft,
        onTap: onRetry,
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: '${l10n.todayErr} '),
            TextSpan(
              text: l10n.commonRetry,
              style: const TextStyle(
                  color: AtemColors.cyan, fontWeight: FontWeight.w600),
            ),
          ]),
          style: AtemType.meta.of(context),
        ),
      ),
    );
  }
}
