import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/exercise.dart';
import '../muscle_ui.dart';
import '../widgets/exercise_bits.dart';

/// Übungsdetail — **reich und spärlich sind dasselbe Layout**.
///
/// Von 154 Übungen haben 138 eine Anleitung, 84 Cues und typische Fehler, und
/// nur 15 eine Beschreibung. Ein Gerüst, das all das voraussetzt, wäre bei der
/// Mehrheit eine Sammlung von Leerstellen.
///
/// Die Regel ist deshalb: **Ein Block rendert nur mit Daten.** Kein
/// „Keine Anleitung hinterlegt"-Platzhalter, kein ausgegrauter Bereich — der
/// Bildschirm hört einfach früher auf.
///
/// Die einzige Ausnahme ist der Hinweis bei **eigenen** Übungen ohne Inhalt.
/// Der ist keine Leerstelle, sondern eine Handlungsmöglichkeit: Nur dort kann
/// jemand etwas nachtragen. Bei einer kuratierten Übung wäre derselbe Hinweis
/// eine Aufforderung an jemanden, der nichts ändern kann.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final color = exercise.region?.color ?? AtemCategories.grey;

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(backgroundColor: AtemColors.base),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseInitials(name: exercise.name, color: color, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name,
                          style: AtemType.titleLarge.of(context)),
                      if (exercise.isOwn) ...[
                        const SizedBox(height: 8),
                        AtemBadge(
                          label: l10n.exercisesOwnTag,
                          accent: AtemCategories.grey,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            MuscleChipRow(muscles: exercise.displayMuscles, maxVisible: 6),
            if (exercise.difficulty != null) ...[
              const SizedBox(height: 16),
              DifficultyMeter(level: exercise.difficulty!),
            ],
            if (exercise.equipment.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Gerät bleibt grauer Text, kein Chip: Vier eingefärbte
              // Kategorien nebeneinander wären ein Flickenteppich.
              Text(exercise.equipment.join(' · '),
                  style: AtemType.labelMicro.of(context)),
            ],

            // Ab hier: nur was Daten hat.
            _Block(
              title: l10n.exerciseInstructions,
              lines: exercise.instructions,
              numbered: true,
            ),
            if (exercise.description case final text? when text.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(text, style: AtemType.body.of(context)),
            ],
            _Block(title: l10n.exerciseCues, lines: exercise.cues),
            _Block(
                title: l10n.exerciseMistakes, lines: exercise.commonMistakes),

            if (exercise.isOwn && !exercise.hasGuidance) ...[
              const SizedBox(height: 28),
              AtemNotice(
                title: l10n.exerciseSparseTitle,
                body: l10n.exerciseSparseBody,
                semanticLabel:
                    '${l10n.exerciseSparseTitle}. ${l10n.exerciseSparseBody}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ein Abschnitt — oder nichts.
class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.lines,
    this.numbered = false,
  });

  final String title;
  final List<String> lines;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text(title, style: AtemType.labelMedium.of(context)),
        const SizedBox(height: 12),
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  numbered ? '${i + 1}.' : '·',
                  style: AtemType.labelSmall.of(context).copyWith(
                        color: AtemColors.cyan,
                      ),
                ),
              ),
              Expanded(
                child: Text(lines[i], style: AtemType.body.of(context)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
