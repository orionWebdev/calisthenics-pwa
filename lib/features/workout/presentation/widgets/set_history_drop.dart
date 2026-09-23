import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/exercise_history.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart' show languageTag;

/// Die früheren Sätze einer Übung, mitten im Runner (23.09.2026).
///
/// ## Warum
///
/// Die Spalte „Zuletzt" zeigt je Zeile genau einen Vorwert. Wer wissen will,
/// wie die letzten Einheiten liefen — drei Sätze vorgestern, zwei letzte
/// Woche —, musste den Runner verlassen. Jetzt klappt ein kleiner Knopf die
/// letzten Sätze unter der Vorgabe auf, gruppiert nach Tag, höchstens sechs.
///
/// ## Klein, weil selten
///
/// Ein runder Knopf mit Verlaufssymbol, 36 dp sichtbar, 48 dp Trefferfläche.
/// Er ist ein Blick zurück, kein Teil des Ablaufs. Ohne Verlauf gibt es ihn
/// nicht — ein Block ohne Daten rendert nicht.
///
/// ## Die Lichtkante auch hier
///
/// Das Aufklappen läuft mit der Kante, **auch in der Stufe Fokus** — der
/// Nutzer hat es so entschieden, gegen Board 18b (dort hat der Runner kein
/// Licht). Sie bleibt die einzige Ausnahme; bei „Animationen reduzieren"
/// steht auch sie still.
class SetHistoryDrop extends ConsumerStatefulWidget {
  const SetHistoryDrop({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  final String exerciseId;
  final String exerciseName;

  /// Wie viele Sätze höchstens gezeigt werden.
  static const maxSets = 6;

  @override
  ConsumerState<SetHistoryDrop> createState() => _SetHistoryDropState();
}

class _SetHistoryDropState extends ConsumerState<SetHistoryDrop> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final sessions = ref.watch(sessionsProvider).value ?? const [];
    final history = ExerciseHistory.of(sessions, widget.exerciseId);
    final groups = recentSets(history, SetHistoryDrop.maxSets);
    if (groups.isEmpty) return const SizedBox.shrink();

    final label = _open
        ? l10n.runnerHistoryHide(widget.exerciseName)
        : l10n.runnerHistoryShow(widget.exerciseName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AtemTappable(
            semanticLabel: label,
            expanded: _open,
            onTap: () => setState(() => _open = !_open),
            child: AnimatedContainer(
              duration: AtemMotion.duration(context, AtemMotion.dPress),
              curve: AtemMotion.press,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _open
                    ? AtemColors.cyan.withValues(alpha: 0.08)
                    : AtemColors.surfaceSolid,
                border: Border.all(
                  color: _open ? AtemColors.cyan : AtemColors.border,
                ),
              ),
              alignment: Alignment.center,
              // Ein Zifferblatt mit Pfeil gegen den Uhrzeigersinn: zurück in
              // der Zeit.
              child: const AtemGlyph(
                'M3 12a9 9 0 1 0 3-6.7M3 4v4h4M12 7v5l3 2',
                color: AtemColors.cyan,
                size: 18,
                strokeWidth: 1.9,
              ),
            ),
          ),
        ),
        // Die Kante liegt **um** die Disclosure, nicht in ihr: Der Inhalt
        // wird erst beim Öffnen gebaut und sähe den Wechsel nie. Die
        // Disclosure ist immer da und wächst — die Kante wächst mit.
        Padding(
          padding: EdgeInsets.only(top: _open ? AtemSpacing.sm : 0),
          child: AtemEdgeSweep(
            trigger: _open,
            when: _open,
            evenInFocus: true,
            radius: AtemRadii.statBox,
            child: AtemDisclosure(
              open: _open,
              child: _List(groups: groups),
            ),
          ),
        ),
      ],
    );
  }
}

/// Die jüngsten Sätze, nach Tag gruppiert, zusammen höchstens [max].
///
/// Neueste Einheit zuerst, innerhalb einer Einheit in der Reihenfolge, in
/// der die Sätze gemacht wurden. Eine ältere Einheit wird angeschnitten, wenn
/// sie über die Grenze ginge — die jüngste steht immer ganz da, solange sie
/// in die Grenze passt, weil sie die ist, an der man sich misst.
List<({DateTime date, List<LoggedSet> sets})> recentSets(
    ExerciseHistory history, int max) {
  final out = <({DateTime date, List<LoggedSet> sets})>[];
  var left = max;
  for (final occurrence in history.occurrences) {
    if (left <= 0) break;
    final sets = occurrence.sets.take(left).toList();
    if (sets.isEmpty) continue;
    out.add((date: occurrence.date, sets: sets));
    left -= sets.length;
  }
  return out;
}

class _List extends StatelessWidget {
  const _List({required this.groups});

  final List<({DateTime date, List<LoggedSet> sets})> groups;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);

    String detail(LoggedSet s) {
      final kg = s.weight;
      final side = switch (s.side) {
        SetSide.left => ' · ${l10n.workoutSideLeft}',
        SetSide.right => ' · ${l10n.workoutSideRight}',
        _ => '',
      };
      if (s.reps != null && kg != null && kg > 0) {
        return '${s.reps} × ${l10n.unitKilograms(NumberFormat.decimalPattern(tag).format(kg))}$side';
      }
      if (s.reps != null) return '${s.reps}$side';
      if (s.holdSeconds != null) return '${l10n.restSeconds(s.holdSeconds!)}$side';
      return l10n.commonNotAvailable;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AtemColors.surfaceSolid,
        borderRadius: BorderRadius.circular(AtemRadii.statBox),
        border: Border.all(color: AtemColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.runnerHistoryTitle, style: AtemType.labelMicro.of(context)),
          for (final group in groups) ...[
            const SizedBox(height: 10),
            Text(
              DateFormat.MMMEd(tag).format(group.date),
              style: AtemType.meta.of(context),
            ),
            for (var i = 0; i < group.sets.length; i++)
              Semantics(
                container: true,
                label:
                    '${DateFormat.MMMMd(tag).format(group.date)}, ${l10n.detailSetRow(i + 1, detail(group.sets[i]))}',
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.detailSetRow(
                          i + 1, detail(group.sets[i])),
                      style: AtemType.labelSmall.of(context),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
