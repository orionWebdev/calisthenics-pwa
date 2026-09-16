import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/screens/exercise_detail_screen.dart';
import '../../domain/exercise_progress.dart';
import '../../domain/training_session.dart';
import '../session_ui.dart';

/// Kraft-Auswertung: **Fortschritte je Übung** in den letzten vier Wochen.
///
/// Drei Zustände, alle sichtbar (Regel für Auswertungsbildschirme,
/// CLAUDE.md seit 16.09.2026):
///
/// - **unter der Schwelle** — noch keine Übung zweimal gemacht:
///   [AtemThresholdBlock], kein Wert;
/// - **gefüllt, ohne Bestwert** — ein Satz und die Grundlage. „Kein neuer
///   Bestwert" ist eine Tatsache, kein Urteil;
/// - **gefüllt** — höchstens fünf Zeilen, jede öffnet die Übung.
class ExerciseProgressCard extends ConsumerWidget {
  const ExerciseProgressCard({
    super.key,
    required this.sessions,
    required this.reference,
  });

  final List<TrainingSession> sessions;
  final DateTime reference;

  /// Mehr als fünf Zeilen wären eine Liste, keine Auswertung.
  static const maxRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final progress = ExerciseProgress.compute(sessions, reference);

    if (!progress.hasEnough) {
      return AtemThresholdBlock(
        title: l10n.progressTitle,
        trailing: l10n.progressWindow,
        what: l10n.progressWhat,
        condition: l10n.progressCondition,
        current: progress.mostOccurrences,
        required: ExerciseProgress.minimumOccurrences,
      );
    }

    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final byId = {for (final e in exercises) e.id: e};
    final basis = l10n.progressBasis(
        progress.exercisesCompared, progress.sessionsInWindow);
    final rows = progress.entries.take(maxRows).toList();

    return AtemCard.list(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AtemSpacing.cardPadding,
                AtemSpacing.cardPadding, AtemSpacing.cardPadding, 8),
            child: Semantics(
              header: true,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(l10n.progressTitle,
                      style: AtemType.titleMedium.of(context)),
                  Text(l10n.progressWindow, style: AtemType.meta.of(context)),
                ],
              ),
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AtemSpacing.cardPadding, vertical: 4),
              child: Text(l10n.progressNone,
                  style: AtemType.labelSmall.of(context)),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(
                    height: 1, thickness: 1, color: AtemColors.border),
              _Row(entry: rows[i], exercise: byId[rows[i].exerciseId]),
            ],
          Padding(
            padding: const EdgeInsets.fromLTRB(AtemSpacing.cardPadding, 10,
                AtemSpacing.cardPadding, AtemSpacing.cardPadding),
            child: Text(basis, style: AtemType.meta.of(context)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.exercise});

  final ExerciseProgressEntry entry;

  /// `null`, wenn die Übung nicht mehr im Bestand ist — dann steht die ID
  /// und die Zeile ist nicht antippbar.
  final Exercise? exercise;

  String _number(BuildContext context, double value) =>
      AtemNumberField.format(context, value);

  String _shown(BuildContext context, AppL10n l10n, double value) =>
      switch (entry.measure) {
        ProgressMeasure.weight => l10n.unitKilograms(_number(context, value)),
        ProgressMeasure.reps => l10n.progressReps(_number(context, value)),
        ProgressMeasure.hold => l10n.progressSeconds(_number(context, value)),
      };

  String _spoken(BuildContext context, AppL10n l10n, double value) =>
      switch (entry.measure) {
        ProgressMeasure.weight => l10n.progressA11yKg(_number(context, value)),
        ProgressMeasure.reps => l10n.progressA11yReps(value.round()),
        ProgressMeasure.hold => l10n.progressA11ySeconds(value.round()),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final exercise = this.exercise;
    final name = exercise?.name ?? entry.exerciseId;
    final date = DateFormat.MMMd(languageTag(context)).format(entry.date);
    final spokenDate =
        DateFormat.MMMMd(languageTag(context)).format(entry.date);
    final value = _shown(context, l10n, entry.value);
    final before = _shown(context, l10n, entry.previousBest);

    final label = [
      l10n.progressRowA11y(
        name,
        _spoken(context, l10n, entry.value),
        _number(context, entry.previousBest),
        _number(context, entry.delta),
        spokenDate,
      ),
      if (exercise != null) l10n.progressOpensExercise,
    ].join(', ');

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AtemSpacing.cardPadding, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: AtemType.titleSmallOrDefault(context)),
                  const SizedBox(height: 2),
                  Text(l10n.progressOn(date), style: AtemType.meta.of(context)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      textAlign: TextAlign.end,
                      style: AtemType.valueMedium.of(context)),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(children: [
                      // Richtung als Glyph, das Wort „mehr" steht im Label.
                      const TextSpan(text: '▲ '),
                      TextSpan(text: l10n.progressBefore(before)),
                    ]),
                    textAlign: TextAlign.end,
                    style: AtemType.meta
                        .of(context)
                        .copyWith(color: AtemColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (exercise != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  size: 20, color: AtemColors.textSecondary),
            ],
          ],
        ),
      ),
    );

    if (exercise == null) {
      return Semantics(
        container: true,
        label: label,
        excludeSemantics: true,
        child: content,
      );
    }

    return AtemTappable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExerciseDetailScreen(exercise: exercise),
        ),
      ),
      semanticLabel: label,
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: content,
    );
  }
}
