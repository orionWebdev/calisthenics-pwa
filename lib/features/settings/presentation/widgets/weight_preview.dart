import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../../history/domain/training_session.dart';
import '../../domain/body_weight_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Die Vorschau unter dem Gewichtsfeld — **rechnen statt warnen**.
///
/// ## Was sie zeigt und was sie ausdrücklich nicht sagt
///
/// Vier Zeilen: Trainingslast der Woche, ACWR, Formwert heute und der
/// Bestwert der häufigsten Körpergewichtsübung. Dazu ein Satz, der die
/// wichtigste Beruhigung ausspricht — **die Sätze selbst ändern sich nicht**,
/// nur ihre Bewertung. Ohne ihn liest sich „Bestwert 78 → 82" wie ein
/// gefälschter Rekord.
///
/// ## Der Nenner steht dabei
///
/// „245 Tage · 34 Einheiten mit Körpergewichtsübungen". Ändert sich nichts,
/// liegt das fast immer daran, dass dieser Nenner klein ist — und nicht
/// daran, dass die Rechnung nichts hergibt. Im Produktivbestand tragen 22 von
/// 80 Einheitenformen überhaupt `usesBodyweight`.
class WeightPreview extends ConsumerWidget {
  const WeightPreview({
    super.key,
    required this.sessions,
    required this.reference,
    required this.currentKg,
    required this.candidateKg,
  });

  final List<TrainingSession> sessions;
  final DateTime reference;
  final double currentKg;
  final double candidateKg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);

    final preview = BodyWeightPreview.compute(
      sessions,
      reference,
      currentKg: currentKg,
      candidateKg: candidateKg,
    );
    final (loadBefore, loadAfter) = BodyWeightPreview.weekLoad(
      sessions,
      reference,
      currentKg: currentKg,
      candidateKg: candidateKg,
    );
    final (days, counted) = BodyWeightPreview.scope(sessions, reference);
    final exerciseId = BodyWeightPreview.bodyweightExercise(sessions);

    final rows = <Widget>[
      _Row(
        label: l10n.weightImpactLoad,
        before: loadBefore.round().toString(),
        after: loadAfter.round().toString(),
        rises: loadAfter > loadBefore,
        changes: (loadAfter - loadBefore).abs() >= 0.5,
      ),
      _Row(
        label: l10n.weightImpactAcwr,
        before: preview.acwrBefore?.toStringAsFixed(2) ??
            l10n.commonNotAvailable,
        after:
            preview.acwrAfter?.toStringAsFixed(2) ?? l10n.commonNotAvailable,
        rises: (preview.acwrAfter ?? 0) > (preview.acwrBefore ?? 0),
        changes: preview.acwrChanges,
      ),
      _Row(
        label: l10n.weightImpactForm,
        before: preview.formBefore?.toString() ?? l10n.commonNotAvailable,
        after: preview.formAfter?.toString() ?? l10n.commonNotAvailable,
        rises: (preview.formAfter ?? 0) > (preview.formBefore ?? 0),
        changes: preview.formChanges,
      ),
      // Der Bestwert einer Körpergewichtsübung **ist** das Körpergewicht.
      // Deshalb steht hier „neu bewertet" und nicht „höher": Es ist derselbe
      // Klimmzug, nur anders gerechnet.
      if (exerciseId != null)
        _Row(
          label: l10n.weightImpactBest(_name(context, ref, exerciseId)),
          before: AtemNumberField.format(context, currentKg),
          after: AtemNumberField.format(context, candidateKg),
          rises: candidateKg > currentKg,
          changes: true,
          rescored: true,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.weightImpactTitle,
            style: AtemType.labelMedium.of(context)),
        const SizedBox(height: 4),
        Text(l10n.weightImpactScope(days, counted),
            style: AtemType.meta.of(context)),
        const SizedBox(height: 12),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          rows[i],
        ],
        const SizedBox(height: 12),
        Text(l10n.weightImpactNote,
            style: AtemType.labelSmall.of(context)),
      ],
    );
  }

  /// Der Name der Übung — oder ihre Kennung, wenn der Katalog sie nicht führt.
  String _name(BuildContext context, WidgetRef ref, String exerciseId) {
    for (final exercise in ref.read(exercisesProvider).value ?? const []) {
      if (exercise.id == exerciseId) return exerciseName(context, exercise);
    }
    return exerciseId;
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.before,
    required this.after,
    required this.rises,
    required this.changes,
    this.rescored = false,
  });

  final String label;
  final String before;
  final String after;
  final bool rises;
  final bool changes;

  /// „neu bewertet" statt „höher"/„niedriger".
  final bool rescored;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    final word = !changes
        ? l10n.weightDirSame
        : (rescored
            ? l10n.weightDirRescored
            : (rises ? l10n.weightDirUp : l10n.weightDirDown));

    return Semantics(
      // Eine Zeile ist ein Knoten, und das Richtungswort steht darin — die
      // Farbe trägt sie nie allein.
      label: '$label, ${l10n.consequenceStepA11y(label, before, after)}, $word',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: AtemType.labelSmall.of(context)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(before,
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0)),
                  Text('→',
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0)),
                  Text(
                    after,
                    style: AtemType.labelMicro.of(context).copyWith(
                          letterSpacing: 0,
                          fontWeight: FontWeight.w700,
                          color: changes
                              ? AtemColors.cyan
                              : AtemColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
