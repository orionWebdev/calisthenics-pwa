import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../workout_ui.dart';
import '../../domain/workout_session.dart';

/// Übungskopf mit Navigation und Chips.
class ExerciseHeader extends StatelessWidget {
  const ExerciseHeader({
    super.key,
    required this.exercise,
    required this.title,
    required this.index,
    required this.total,
    required this.onPrevious,
    required this.onNext,
    required this.onFormGuide,
  });

  final WorkoutExercise exercise;

  /// Der anzuzeigende Name. Er kommt von aussen, weil die Einheit nur die
  /// Kennung und den englischen Grundnamen kennt — die deutsche Fassung
  /// steht im Übungsbestand.
  final String title;

  final int index;
  final int total;

  /// `null` an den Enden — der Pfeil meldet sich dann als deaktiviert.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onFormGuide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemCard.list(
      child: Column(
        children: [
          Row(
            children: [
              _Arrow(
                back: true,
                semanticLabel: l10n.workoutA11yPrevExercise,
                onTap: onPrevious,
              ),
              Expanded(
                child: Semantics(
                  // Zählung und Name als ein Knoten.
                  label: '${l10n.workoutScreenExerciseOf(index + 1, total)}: '
                      '${exercise.name}',
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Text(
                          l10n.workoutScreenExerciseOf(index + 1, total),
                          textAlign: TextAlign.center,
                          style: AtemType.meta
                              .of(context)
                              .copyWith(color: AtemColors.cyan),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AtemType.titleMedium.of(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _Arrow(
                back: false,
                semanticLabel: l10n.workoutA11yNextExercise,
                onTap: onNext,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 7,
            runSpacing: 7,
            children: [
              // Neutral, nicht violett: Die Spezifikation rendert
              // Muskel-Chips als schlichte Statusträger — und violetter Text
              // erreicht ohnehin kein AA.
              for (final m in exercise.muscles) AtemBadge(label: m),
              // Kein Chip ohne Bestwert: „PR —" wäre eine Behauptung über
              // eine Übung, die noch nie protokolliert wurde.
              if (recordLabel(context, l10n, exercise.recordWeightKg)
                  case final record?)
                AtemBadge(
                  label: record,
                  accent: AtemColors.green,
                  leadingDot: true,
                ),
              AtemBadge.chip(
                label: l10n.workoutRunnerFormGuide,
                semanticLabel: l10n.workoutA11yFormGuide(exercise.name),
                accent: AtemColors.cyan,
                onTap: onFormGuide,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.back,
    required this.semanticLabel,
    required this.onTap,
  });

  final bool back;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: Opacity(
          // Deaktiviert meldet Semantics ohnehin — die Deckkraft ist die
          // sichtbare Entsprechung.
          opacity: onTap == null ? 0.35 : 1,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AtemColors.surfaceSolid,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AtemColors.border),
            ),
            child: CustomPaint(
              size: const Size.square(24),
              painter: _ChevronPainter(back: back),
            ),
          ),
        ),
      );
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter({required this.back});
  final bool back;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final path = back
        ? (Path()
          ..moveTo(s * 0.62, s * 0.25)
          ..lineTo(s * 0.38, s * 0.5)
          ..lineTo(s * 0.62, s * 0.75))
        : (Path()
          ..moveTo(s * 0.38, s * 0.25)
          ..lineTo(s * 0.62, s * 0.5)
          ..lineTo(s * 0.38, s * 0.75));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AtemColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.back != back;
}
