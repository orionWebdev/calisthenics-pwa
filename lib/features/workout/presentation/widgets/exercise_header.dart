import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/domain/muscle.dart';
import '../../../exercises/presentation/muscle_ui.dart';
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
    this.onUnilateralChanged,
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

  /// `null`, wenn die Übung keine Anleitung trägt — dann **fehlt der Chip**.
  ///
  /// Er lag bis zum 18.09.2026 auf einem leeren Rückruf: Ein Tap tat nichts.
  /// Von 154 Übungen im Bestand haben nur die kuratierten eine Anleitung; für
  /// alle anderen ist kein Chip die ehrliche Antwort.
  final VoidCallback? onFormGuide;

  /// Wählt „Beidseitig" oder „Getrennt" für diese Übung. `null`
  /// blendet die Zeile aus.
  final ValueChanged<bool>? onUnilateralChanged;

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
                  // Zählung und Name als ein Knoten — mit dem **angezeigten**
                  // Namen: `exercise.name` trägt den englischen Grundnamen
                  // aus der Datenschicht.
                  label: '${l10n.workoutScreenExerciseOf(index + 1, total)}: '
                      '$title',
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
              //
              // **Übersetzt.** Die Einheit trägt die Rohwerte (`chest`,
              // `triceps`); sie standen bis zum 18.09.2026 englisch im
              // deutschen Kopf.
              for (final m in exercise.muscles)
                AtemBadge(label: MuscleGroup.fromWire(m)?.label(l10n) ?? m),
              // Kein Chip ohne Bestwert: „PR —" wäre eine Behauptung über
              // eine Übung, die noch nie protokolliert wurde.
              if (recordLabel(context, l10n, exercise.recordWeightKg)
                  case final record?)
                AtemBadge(
                  label: record,
                  accent: AtemColors.green,
                  leadingDot: true,
                ),
              if (onFormGuide case final open?)
                AtemBadge.chip(
                  label: l10n.workoutRunnerFormGuide,
                  semanticLabel: l10n.workoutA11yFormGuide(title),
                  accent: AtemColors.cyan,
                  onTap: open,
                ),
            ],
          ),
          if (onUnilateralChanged case final change?) ...[
            const SizedBox(height: 12),
            _SidesChoice(
              title: title,
              unilateral: exercise.unilateral,
              onChanged: change,
            ),
          ],
        ],
      ),
    );
  }
}

/// Die Seitenwahl „Beidseitig | Getrennt" — kein Board, aus Tokens
/// gebaut (18.09.2026).
///
/// **Eine eigene Zeile, keine Kapsel mehr.** Bis zum 18.09.2026 stand hier
/// ein Chip „Seiten getrennt" zwischen Muskeln und Form Guide. Er sah aus wie
/// die Muskel-Chips neben ihm — eine Angabe, kein Schalter — und wurde auf
/// dem Honor übersehen. Zwei Segmente zeigen beide Möglichkeiten zugleich:
/// Man sieht, dass es eine Wahl gibt, und welche gilt, ohne zu tippen.
///
/// Die Trennlinie darüber setzt die Zeile von den Chips ab: Die Chips
/// beschreiben die Übung, diese Zeile steuert die Einheit.
class _SidesChoice extends StatelessWidget {
  const _SidesChoice({
    required this.title,
    required this.unilateral,
    required this.onChanged,
  });

  final String title;
  final bool unilateral;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      children: [
        Container(height: 1, color: AtemColors.border),
        const SizedBox(height: 12),
        // **Beschriftung über der Auswahl, nicht daneben**, und die zwei
        // Segmente teilen sich die volle Breite. Nebeneinander mit der
        // Beschriftung blieb auf 361 dp zu wenig Platz, und die Segmente
        // stapelten sich — eine Wahl, die wie eine Liste aussah. Erst wenn ein
        // Segment seinen halben Anteil nicht mehr füllt (200 % Schrift auf
        // 320 dp), stehen beide untereinander.
        Column(
          children: [
            // Die Gruppe benennt sich selbst („Seiten für Übung …") —
            // die sichtbare Beschriftung wäre vorgelesen doppelt.
            ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.compare_arrows,
                      size: 18, color: AtemColors.cyan),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.workoutSidesLabel,
                      style: AtemType.labelUi
                          .of(context)
                          .copyWith(color: AtemColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AtemSegmented<bool>(
              value: unilateral,
              onChanged: onChanged,
              groupSemanticLabel: l10n.workoutSidesGroupA11y(title),
              expand: true,
              segments: [
                AtemSegment(
                  value: false,
                  label: l10n.workoutSidesBoth,
                  semanticLabel: l10n.workoutSidesBothA11y,
                ),
                AtemSegment(
                  value: true,
                  label: l10n.workoutSidesSplit,
                  semanticLabel: l10n.workoutSidesSplitA11y,
                ),
              ],
            ),
          ],
        ),
      ],
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
