/// Suchfeld und Filterzeile — **geteilt zwischen Tab und Vollbild**.
///
/// Der Übungsblock im Workouts-Tab und die vollständige Liste stellen dieselbe
/// Frage. Zwei Fassungen davon wären zwei Verhaltensweisen, die auseinanderdriften:
/// eine, die beim Leeren den Filter mitnimmt, und eine, die es nicht tut.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/muscle.dart';
import '../muscle_ui.dart';

/// Das Suchfeld der Übungen.
class ExerciseSearchField extends StatelessWidget {
  const ExerciseSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemTextField(
      controller: controller,
      semanticLabel: l10n.exercisesSearchHint,
      hint: l10n.exercisesSearchHint,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      // Übungsnamen sind halb englisch, halb deutsch — eine automatische
      // Großschreibung des ersten Buchstabens hilft beim Suchen nicht und
      // stört bei „pull_up".
      textCapitalization: TextCapitalization.none,
      onChanged: onChanged,
      leading:
          const Icon(Icons.search, size: 20, color: AtemColors.textSecondary),
      // Erst ab dem ersten Zeichen — ein Löschknopf an einem leeren Feld ist
      // eine Aktion ohne Wirkung.
      trailing: controller.text.isEmpty
          ? null
          : AtemTappable(
              onTap: onClear,
              semanticLabel: l10n.exercisesFilterReset,
              child: const Icon(Icons.close,
                  size: 18, color: AtemColors.textSecondary),
            ),
    );
  }
}

/// Die Filterzeile. „Alle" steht fest an Position 1, der Rest scrollt.
///
/// Neun Muskeln statt sechs Regionen — die Begründung steht am
/// [MuscleGroup.filters].
class ExerciseFilterRow extends StatelessWidget {
  const ExerciseFilterRow({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onAll,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
  });

  final MuscleGroup? selected;
  final ValueChanged<MuscleGroup> onSelect;
  final VoidCallback onAll;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    // Eine waagerechte Liste braucht eine feste Höhe — die darf aber nicht
    // fest bleiben: Bei 200 % Schrift wachsen die Chips, und 48 dp liefen um
    // 25 px über. Die Höhe folgt deshalb der Schriftskalierung.
    final height = math.max(
      48.0,
      MediaQuery.textScalerOf(context).scale(20) + 28,
    );

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          _Chip(
            label: l10n.exercisesFilterAll,
            semanticLabel: l10n.exercisesFilterAll,
            selected: selected == null,
            onTap: onAll,
          ),
          for (final muscle in MuscleGroup.filters) ...[
            const SizedBox(width: 8),
            _Chip(
              label: muscle.label(l10n),
              semanticLabel: selected == muscle
                  ? l10n.exercisesFilterActive(muscle.label(l10n))
                  : l10n.exercisesFilterMuscle(muscle.label(l10n)),
              color: muscle.color,
              selected: selected == muscle,
              onTap: () => onSelect(muscle),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AtemColors.cyan;

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        constraints: const BoxConstraints(minHeight: 36),
        decoration: BoxDecoration(
          color: selected ? AtemCategories.surface(tint) : AtemColors.card,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: selected ? AtemCategories.border(tint) : AtemColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Der Punkt zeigt die Farbe auch im nicht gewählten Zustand — so
            // ist die Zuordnung Muskel/Farbe lernbar, bevor man tippt.
            if (color != null && !selected) ...[
              ExcludeSemantics(child: AtemStatusDot(color: tint)),
              const SizedBox(width: 8),
            ],
            if (selected) ...[
              Icon(Icons.check, size: 14, color: tint),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AtemType.labelSmall.of(context).copyWith(
                    color: selected ? tint : AtemColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
