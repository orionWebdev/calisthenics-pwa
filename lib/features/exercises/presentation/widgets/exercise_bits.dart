import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/exercise.dart';
import '../../domain/muscle.dart';
import '../muscle_ui.dart';

/// Die Initialen einer Übung in einer getönten Box.
///
/// Ersetzt ein Bild, das es für 139 von 154 Übungen nicht gibt. Die Farbe
/// stammt aus der Region, nicht aus dem Namen — zwei Rückenübungen sehen
/// deshalb verwandt aus, was beim Überfliegen hilft.
class ExerciseInitials extends StatelessWidget {
  const ExerciseInitials({
    super.key,
    required this.name,
    required this.color,
    this.size = 36,
  });

  final String name;
  final Color color;
  final double size;

  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'[\s\-_]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }
    return (words[0].characters.first + words[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AtemCategories.surface(color),
            borderRadius: BorderRadius.circular(AtemRadii.iconBox),
          ),
          child: Text(
            initialsOf(name),
            style: AtemType.labelMicro.of(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
          ),
        ),
      );
}

/// Ein Muskelchip: getönte Fläche, voller Text.
class MuscleChip extends StatelessWidget {
  const MuscleChip({super.key, required this.muscle});

  final MuscleGroup muscle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final color = muscle.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AtemCategories.surface(color),
        borderRadius: BorderRadius.circular(AtemRadii.pill),
        border: Border.all(color: AtemCategories.border(color)),
      ),
      child: Text(
        muscle.label(l10n),
        style: AtemType.labelMicro.of(context).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

/// Höchstens drei Chips, der Rest als „+n".
///
/// Eine Übung mit sieben Muskeln würde die Zeile sonst allein füllen. Die
/// Zusammenfassung steht als Text im Semantics-Label — abgeschnitten ist die
/// Liste nur im Bild.
class MuscleChipRow extends StatelessWidget {
  const MuscleChipRow({super.key, required this.muscles, this.maxVisible = 3});

  final List<MuscleGroup> muscles;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (muscles.isEmpty) return const SizedBox.shrink();
    final l10n = AppL10n.of(context);
    final visible = muscles.take(maxVisible).toList();
    final rest = muscles.length - visible.length;

    return Semantics(
      label: muscles.map((m) => m.label(l10n)).join(', '),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final muscle in visible) MuscleChip(muscle: muscle),
            if (rest > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AtemRadii.pill),
                  border: Border.all(color: AtemColors.border),
                ),
                child: Text('+$rest',
                    style: AtemType.labelMicro.of(context).copyWith(
                          letterSpacing: 0,
                        )),
              ),
          ],
        ),
      ),
    );
  }
}

/// Schwierigkeit als **Form und Zahl, monochrom**.
///
/// Bewusst kein Teil der Kategoriepalette: Eine Ampelfarbe wäre ein zweites
/// Farbsystem neben den Regionen. Und bewusst kein Wort — „Fortgeschritten"
/// sprengt bei 320 dp und 200 % Schrift die Zeile.
class DifficultyMeter extends StatelessWidget {
  const DifficultyMeter({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Semantics(
      label: l10n.exerciseDifficultyA11y(level),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++) ...[
              if (i > 1) const SizedBox(width: 2),
              Container(
                width: 7,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      i <= level ? AtemColors.textPrimary : AtemColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Text('$level/5',
                style: AtemType.labelMicro.of(context).copyWith(
                      letterSpacing: 0,
                    )),
          ],
        ),
      ),
    );
  }
}

/// Eine Zeile der Übungsliste.
///
/// Trägt **genau einen Farbwert** — die Region, über Initialenbox und
/// Muskelnamen. Gerät bleibt grau, Schwierigkeit monochrom. Vier eingefärbte
/// Kategorien nebeneinander wären ein Flickenteppich.
class ExerciseRow extends StatelessWidget {
  const ExerciseRow({super.key, required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final color = exercise.region?.color ?? AtemCategories.grey;
    final muscle = exercise.displayMuscles.firstOrNull;

    final sub = <String>[
      if (muscle != null) muscle.label(l10n),
      if (exercise.equipment.isNotEmpty) exercise.equipment.first,
      if (exercise.isOwn) l10n.exercisesOwnTag,
    ].join(' · ');

    return AtemTappable(
      onTap: onTap,
      semanticLabel: exercise.difficulty == null
          ? '${exercise.name}. $sub'
          : '${exercise.name}. $sub. '
              '${l10n.exerciseDifficultyA11y(exercise.difficulty!)}',
      minTapSize: const Size(0, 64),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ExerciseInitials(name: exercise.name, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.titleSmallOrDefault(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0),
                    ),
                  ],
                ],
              ),
            ),
            if (exercise.difficulty != null) ...[
              const SizedBox(width: 10),
              DifficultyMeter(level: exercise.difficulty!),
            ],
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
