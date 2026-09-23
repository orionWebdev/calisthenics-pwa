import 'package:flutter/material.dart' show Icons, MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../../exercises/presentation/screens/exercise_detail_screen.dart';
import '../../domain/session_detail.dart';
import '../../domain/training_session.dart';
import '../session_ui.dart';

/// Der Rahmen jedes Blocks — **eine Anatomie**.
///
/// Titelzeile mit ⓘ (48 dp), darunter der Inhalt. Alle Blöcke sitzen auf
/// derselben Fläche mit 1-dp-Rand; der scrollende Bildschirm hat **keinen**
/// `BackdropFilter` (Board 16, Spezifikation).
///
/// Die Erklärung klappt **im Block** auf, nicht als Blatt: Ein Blatt würde die
/// Werte verdecken, um sie zu erklären (Entscheidung 18). Der Bildschirm
/// scrollt beim Aufklappen nicht von selbst.
class DetailBlock extends StatelessWidget {
  const DetailBlock({
    super.key,
    required this.title,
    required this.explanation,
    required this.child,
    this.trailing,
  });

  final String title;

  /// Die Sätze hinter dem ⓘ. Leer → kein ⓘ.
  final List<String> explanation;

  /// Der Kopfwert rechts — „24 SÄTZE".
  final String? trailing;

  final Widget child;

  @override
  Widget build(BuildContext context) => AtemCard.list(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Die Titelzeile ist immer 48 dp hoch — auch ohne ⓘ. Ohne dieses
            // Mass klebte der Titel eines Blocks ohne Erklärung („Notiz") am
            // oberen Rand der Karte.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AtemExplainHeader(
                  title: title.toUpperCase(),
                  titleStyle: AtemType.labelMicro
                      .of(context)
                      .copyWith(color: AtemColors.textPrimary),
                  explanation: explanation,
                  trailing: trailing,
                ),
              ),
            ),
            child,
          ],
        ),
      );
}

/// „Arbeit" — was genau wurde gemacht (Platz 3).
///
/// Eine Zeilenliste mit Kopfwert. Für Kraft sind es Übungen mit Sätzen; für
/// Ausdauer werden es Splits je Kilometer, für Schwimmen Bahnen. **Der
/// Unterschied ist die Spaltenbelegung, nicht der Baustein** (Entscheidung 2).
class WorkBlock extends ConsumerStatefulWidget {
  const WorkBlock({super.key, required this.rows, required this.setCount});

  final List<ExerciseSummary> rows;
  final int setCount;

  @override
  ConsumerState<WorkBlock> createState() => _WorkBlockState();
}

class _WorkBlockState extends ConsumerState<WorkBlock> {
  /// Welche Zeile offen ist — **eine zugleich**.
  int? _open;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final rows = widget.rows;
    if (rows.isEmpty) return const SizedBox.shrink();

    final shown = _all || rows.length <= SessionDetail.visibleExercises + 1
        ? rows.length
        : SessionDetail.visibleExercises;
    final hidden = rows.length - shown;

    return DetailBlock(
      title: l10n.detailBlockWorkStrength(rows.length),
      // Das Volumen ist die Zahl, die eine Erklärung braucht: Sätze ohne
      // Gewicht fehlen darin und stehen im Nenner.
      explanation: [l10n.detailExplainVolume],
      trailing: '${widget.setCount} ${l10n.detailLeadSets}'.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < shown; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ExerciseRow(
              summary: rows[i],
              open: _open == i,
              onToggle: () => setState(() => _open = _open == i ? null : i),
            ),
          ],
          if (hidden > 0)
            AtemTappable(
              onTap: () => setState(() => _all = true),
              semanticLabel: l10n.detailWorkMore(hidden),
              minTapSize: const Size(0, 48),
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.detailWorkMore(hidden).toUpperCase(),
                  style: AtemType.meta.of(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({
    required this.summary,
    required this.open,
    required this.onToggle,
  });

  final ExerciseSummary summary;
  final bool open;
  final VoidCallback onToggle;

  static String _num(BuildContext context, double v) {
    // Dieselbe Formatierung wie überall: Dezimalzeichen der Sprache, eine
    // Nachkommastelle nur, wo sie etwas sagt.
    return AtemNumberField.format(context, v.abs());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final catalog = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final entry = catalog.where((e) => e.id == summary.exerciseId).firstOrNull;
    final name =
        entry == null ? summary.exerciseId : exerciseName(context, entry);

    // ---- Satzzeile: „3×8 · 80 kg" ------------------------------------
    final reps = summary.reps;
    final weight = summary.weightKg;
    final line = <String>[
      if (reps != null)
        '${summary.sets}×$reps'
      else if (summary.holdSeconds != null)
        '${summary.sets}× ${l10n.restSeconds(summary.holdSeconds!)}'
      else
        '${summary.sets}',
      if (weight != null)
        l10n.unitKilograms(_num(context, weight))
      else if (reps != null || summary.holdSeconds != null)
        l10n.typeBodyweight,
    ].join(' · ');

    // ---- Vergleich: eine Tatsache, kein Urteil ------------------------
    final delta = summary.delta;
    String? deltaText;
    String? deltaSpoken;
    if (delta.kind == DeltaKind.none) {
      deltaText = l10n.detailWorkNoComparison;
    } else if (delta.against != null) {
      final date = DateFormat.MMMd(tag).format(delta.against!);
      final glyph = delta.kind == DeltaKind.same
          ? '='
          : delta.amount > 0
              ? '▲'
              : '▼';
      final value = switch (delta.kind) {
        DeltaKind.weight => l10n.detailDeltaWeight(_num(context, delta.amount)),
        DeltaKind.reps => l10n.detailDeltaReps(_num(context, delta.amount)),
        _ => l10n.detailDeltaSame,
      };
      deltaText = l10n.detailDeltaVs(glyph, value, date);
      final spokenValue = switch (delta.kind) {
        DeltaKind.weight => l10n.detailSpokenKg(_num(context, delta.amount)),
        DeltaKind.reps => l10n.detailSpokenReps(delta.amount.abs().round()),
        _ => '',
      };
      // **Richtungsglyphen werden nie vorgelesen** — das Wort steht im Label.
      deltaSpoken = delta.kind == DeltaKind.same
          ? l10n.detailDeltaSpokenSame(date)
          : delta.amount > 0
              ? l10n.detailDeltaSpokenMore(spokenValue, date)
              : l10n.detailDeltaSpokenLess(spokenValue, date);
    }

    final best = [
      if (reps != null) l10n.detailSpokenReps(reps),
      if (weight != null) l10n.detailSpokenKg(_num(context, weight)),
    ].join(', ');

    // Aufklappen ist ein Erscheinen aus eigener Handlung: die Lichtkante,
    // **bei jedem Öffnen** (entschieden am 23.09.2026, gegen Board 18b C6).
    // Zuklappen hat keine.
    return AtemEdgeSweep(
      trigger: open,
      when: open,
      radius: AtemRadii.statBox,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtemTappable(
          onTap: onToggle,
          expanded: open,
          semanticLabel: l10n.detailExerciseA11y(
            name,
            l10n.detailWorkSets(summary.sets),
            best,
            deltaSpoken == null ? '' : ', $deltaSpoken',
          ),
          minTapSize: const Size(0, 56),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AtemColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AtemColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AtemType.titleSmallOrDefault(context)
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(line.toUpperCase(),
                          style: AtemType.meta
                              .of(context)
                              .copyWith(color: AtemColors.textTertiary)),
                      if (deltaText != null)
                        Text(deltaText.toUpperCase(),
                            style: AtemType.meta
                                .of(context)
                                .copyWith(color: AtemColors.textTertiary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Der Pfeil dreht 0 → 90°: offen = nach unten.
                AnimatedRotation(
                  turns: open ? 0.25 : 0,
                  duration: AtemMotion.duration(
                      context, const Duration(milliseconds: 220)),
                  child: const Icon(Icons.chevron_right,
                      size: 20, color: AtemColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AtemDisclosure(
          open: open,
          child: _Sets(summary: summary, entry: entry, label: name),
        ),
      ],
    ),
    );
  }
}

/// Die aufgeklappte Zeile: jeder Satz, und der Weg zum Übungsverlauf.
class _Sets extends StatelessWidget {
  const _Sets(
      {required this.summary, required this.entry, required this.label});

  final ExerciseSummary summary;
  final Exercise? entry;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    String detail(LoggedSet s) {
      final parts = <String>[
        if (s.reps != null && s.weight != null && s.weight! > 0)
          '${s.reps} × ${l10n.unitKilograms(_ExerciseRow._num(context, s.weight!))}'
        else if (s.reps != null)
          '${s.reps}'
        else if (s.holdSeconds != null)
          l10n.restSeconds(s.holdSeconds!),
      ];
      return parts.join(' · ');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < summary.allSets.length; i++)
            Semantics(
              container: true,
              label: l10n.detailSetRow(i + 1, detail(summary.allSets[i])),
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    l10n.detailSetRow(i + 1, detail(summary.allSets[i])),
                    style: AtemType.meta
                        .of(context)
                        .copyWith(color: AtemColors.textTertiary),
                  ),
                ),
              ),
            ),
          if (entry != null)
            // Der Weg zum Übungsverlauf (16.09.2026) bleibt erhalten — er
            // steht jetzt in der aufgeklappten Zeile, weil die Zeile selbst
            // die Sätze öffnet.
            AtemTappable(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExerciseDetailScreen(exercise: entry!),
                ),
              ),
              semanticLabel: l10n.wellnessTrendOpenExercise(label),
              minTapSize: const Size(0, 48),
              alignment: Alignment.centerLeft,
              child: Text(l10n.detailExerciseHistory,
                  style: AtemType.labelSmall.of(context).copyWith(
                      color: AtemColors.cyan, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

/// „Notiz" — freier Text, unverändert aus Modul 6 (Platz 5).
class NoteBlock extends StatelessWidget {
  const NoteBlock({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return DetailBlock(
      title: l10n.detailBlockNote,
      explanation: const [],
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(text,
            style: AtemType.body
                .of(context)
                .copyWith(color: AtemColors.textTertiary, height: 1.55)),
      ),
    );
  }
}
