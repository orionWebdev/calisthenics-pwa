import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/merge_preview.dart';

/// Stufe 1 eines Eingriffs: **rechnen, nicht warnen** (Board 15, B2 und B4).
///
/// Gibt `true`, wenn bestätigt wurde. **Stufe 2 ist der Knopf selbst**; einen
/// dritten Weg gibt es nicht.
Future<bool> showMergeConsequences(
  BuildContext context, {
  required MergePreview preview,
  required bool merging,
}) async {
  final l10n = AppL10n.of(context);
  final title = merging ? l10n.hcMergeStage1Title : l10n.hcUnlinkStage1Title;
  final ok = await AtemDialog.show<bool>(
    context,
    kind: AtemDialogKind.confirm,
    title: title,
    barrierLabel: title,
    // Die Folgen **sind** die Nachricht. Ein Satz darüber sagte dasselbe
    // noch einmal, nur ungenauer.
    message: merging ? l10n.hcPairQuestion : l10n.hcBackToInbox,
    detail: MergeConsequences(preview: preview),
    confirmLabel: merging ? l10n.hcPairMerge : l10n.hcUnlink,
    // Der Dialog liegt auf dem Wurzel-Navigator.
    onConfirm: () =>
        Navigator.of(context, rootNavigator: true).pop(true),
    dismissLabel: l10n.commonCancel,
  );
  return ok ?? false;
}

/// Die Folgen als Zeilen — **drei davon sagen, was bleibt**.
///
/// Genau das nimmt der eingreifendsten Operation den Schrecken: nicht ein
/// Warnton, sondern die gerechnete Folge. Eine Vorschau, in der nur steht,
/// was sich ändert, lässt offen, was sie sonst noch anfasst.
class MergeConsequences extends StatelessWidget {
  const MergeConsequences({super.key, required this.preview});

  final MergePreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in preview.lines) ...[
          _Line(line: line),
          const SizedBox(height: 10),
        ],
        // Der Uhr-Wert verschwindet nicht: zwei Zahlen, eine gültig, beide
        // sichtbar (Entscheidung 8).
        if (preview.durationDiffers) ...[
          const SizedBox(height: 2),
          Text(
            l10n.hcMergeDurationNote(
              preview.appDuration.inMinutes,
              preview.watchDuration.inMinutes,
            ),
            style: AtemType.meta.of(context),
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final MergeLine line;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final label = _labelOf(l10n, line.field);
    final value = line.value;

    // **Der Pfeil wird nie vorgelesen** — „bleibt" und „wird" stehen im
    // Wort, nicht in der Form.
    final (text, color) = switch (line.effect) {
      MergeEffect.stays => (
          l10n.hcMergeStays(value ?? ''),
          AtemColors.green,
        ),
      MergeEffect.gained => (
          value == null ? l10n.hcBackToInbox : l10n.hcMergeGains(value),
          AtemColors.cyan,
        ),
      MergeEffect.lost => (l10n.hcMergeLoses, AtemColors.magenta),
    };

    return Semantics(
      label: '$label, $text',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: AtemType.labelSmall.of(context)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AtemRadii.pill),
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  style: AtemType.labelMicro.of(context).copyWith(
                        letterSpacing: 0,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _labelOf(AppL10n l10n, MergeField field) => switch (field) {
        MergeField.averageHeartRate => l10n.hcFieldHrAvg,
        MergeField.maxHeartRate => l10n.hcFieldHrMax,
        MergeField.sets => l10n.hcFieldSets,
        MergeField.duration => l10n.hcFieldDuration,
        MergeField.effort => l10n.hcFieldEffort,
        MergeField.watchSession => l10n.hcFieldWatchSession,
      };
}
