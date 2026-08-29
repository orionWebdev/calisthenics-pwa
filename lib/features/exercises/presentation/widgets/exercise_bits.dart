import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/exercise.dart';
import '../../domain/muscle.dart';
import '../muscle_ui.dart';

/// Die Muskelkugel — der Farbträger einer Übungszeile.
///
/// ## Warum keine Initialen mehr
///
/// Vorher standen hier die Anfangsbuchstaben des Namens. Bei „3 Second Pause
/// Squat" wurde daraus „3S", bei „90 Degree Row" ein „9D" — Kürzel, die
/// niemand einer Übung zuordnen kann. Und selbst wenn sie lesbar waren, sagten
/// sie nichts, was der Name daneben nicht schon sagte.
///
/// Die Kugel sagt etwas anderes: **welcher Muskel**. Das ist beim Überfliegen
/// einer Liste von 154 Übungen die nützlichere Information, und sie wiederholt
/// den Namen nicht.
///
/// Voller Kern in der Muskelfarbe, getönter Hof drumherum — dasselbe Rezept
/// wie überall: Fläche 20 Prozent, Farbe voll. Ohne Muskel bleibt sie grau.
class MuscleOrb extends StatelessWidget {
  const MuscleOrb({super.key, required this.color, this.size = 36});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AtemCategories.surface(color),
              ),
              child: Center(
                child: Container(
                  width: size * 0.42,
                  height: size * 0.42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: size * 0.22,
                      ),
                    ],
                  ),
                ),
              ),
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
    final muscle = exercise.displayMuscles.firstOrNull;
    // Die Farbe des Muskels, nicht die der Region.
    final color = muscle?.color ?? AtemCategories.grey;

    // Subzeile: Muskel in seiner Farbe, Gerät grau, der Herkunfts-Tag als
    // Pille dahinter (Board 05, Spezifikation Übungszeile / EIGEN-Tag).
    final sub = <String>[
      if (muscle != null) muscle.label(l10n),
      if (exercise.equipment.isNotEmpty) exercise.equipment.first,
      if (exercise.isOwn) l10n.exercisesOwnTag,
    ].join(' · ');

    return AtemTappable(
      onTap: onTap,
      semanticLabel: exercise.difficulty == null
          ? '${exerciseName(context, exercise)}. $sub'
          : '${exerciseName(context, exercise)}. $sub. '
              '${l10n.exerciseDifficultyA11y(exercise.difficulty!)}',
      minTapSize: const Size(0, 64),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            MuscleOrb(color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exerciseName(context, exercise),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.titleSmallOrDefault(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(children: [
                        if (muscle != null)
                          TextSpan(
                            text: muscle.label(l10n),
                            style: TextStyle(color: color),
                          ),
                        if (muscle != null && exercise.equipment.isNotEmpty)
                          const TextSpan(text: ' · '),
                        if (exercise.equipment.isNotEmpty)
                          TextSpan(text: exercise.equipment.first),
                        if (exercise.isOwn) ...[
                          if (muscle != null || exercise.equipment.isNotEmpty)
                            const TextSpan(text: ' · '),
                          TextSpan(
                            text: l10n.exercisesOwnTag.toUpperCase(),
                            style: const TextStyle(
                                color: AtemColors.textTertiary),
                          ),
                        ],
                      ]),
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
