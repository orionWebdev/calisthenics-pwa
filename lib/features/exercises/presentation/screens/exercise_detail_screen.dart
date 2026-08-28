import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/exercise_history.dart';
import '../../../plans/application/plan_providers.dart';
import '../../application/exercise_providers.dart';
import '../../domain/exercise.dart';
import '../difficulty_ui.dart';
import '../muscle_ui.dart';
import '../widgets/exercise_bits.dart';
import 'exercise_form_screen.dart';

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
///
/// ## Kuratiert bekommt keinen ausgegrauten Knopf
///
/// Die Regeln verbieten Schreiben auf `exercises_curated`. Ein deaktiviertes
/// „Bearbeiten" wäre die naheliegende Darstellung und die falsche: Es sieht aus
/// wie ein Fehler, den man beheben könnte, und lädt zum Antippen ein, das nie
/// etwas tut.
///
/// Stattdessen steht an derselben Stelle ein **Schloss-Chip** mit einem Satz
/// dazu — und darunter der Weg, der tatsächlich offensteht: „Eigene Fassung
/// anlegen". Die kuratierte Übung bleibt dabei bestehen und die eigene stellt
/// sich daneben. Sie zu ersetzen hieße, rückwirkend jede absolvierte Einheit
/// umzuschreiben, die auf die kuratierte zeigt.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final color =
        exercise.displayMuscles.firstOrNull?.color ?? AtemCategories.grey;

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
                MuscleOrb(color: color, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exerciseName(context, exercise),
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
            if (exercise.difficulty case final level?) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  DifficultyMeter(level: level),
                  const SizedBox(width: 10),
                  // Das Wort neben den Balken: Dieselbe Stufe, die im Formular
                  // gewählt wird, damit „Fortgeschritten" hier und dort
                  // dasselbe meint.
                  Flexible(
                    child: ExcludeSemantics(
                      child: Text(
                        difficultyLabel(l10n, level),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtemType.labelMicro.of(context),
                      ),
                    ),
                  ),
                ],
              ),
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

            const SizedBox(height: 32),
            if (exercise.isOwn) ...[
              AtemButton.outline(
                label: l10n.commonEdit,
                semanticLabel: '${l10n.commonEdit}: ${exercise.name}',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExerciseFormScreen(original: exercise),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AtemButton.ghost(
                label: l10n.exerciseDelete,
                semanticLabel: l10n.exerciseDeleteQ(exercise.name),
                accent: AtemColors.magenta,
                onPressed: () => _delete(context, ref),
              ),
            ] else ...[
              const _CuratedLock(),
              const SizedBox(height: 14),
              AtemButton.outline(
                label: l10n.exerciseCuratedCopy,
                semanticLabel: l10n.exerciseCuratedCopy,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExerciseFormScreen(copyOf: exercise),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Zweimal fragen, dann endgültig.
  ///
  /// Anders als beim Löschen einer Einheit gibt es hier **keinen Widerruf**:
  /// Die Übung hängt in Plänen und in absolvierten Einheiten, und diese Kette
  /// lässt sich nicht verlässlich zurückdrehen — zwischen Löschen und Widerruf
  /// kann ein Plan bearbeitet worden sein. Ein Rückgängig, das manchmal nicht
  /// vollständig zurückdreht, verspricht Sicherheit und liefert sie nicht.
  ///
  /// Deshalb tritt an seine Stelle die zweite Frage, und die **erste** sagt
  /// bereits, in wie vielen Plänen die Übung steckt.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppL10n.of(context);

    // **Beides zählen.** Das Board nennt Pläne und Einheiten getrennt, weil
    // die Folgen verschieden sind: Pläne bekommen eine Lücke, Einheiten
    // bleiben vollständig. Nur eine der beiden Zahlen zu nennen liesse die
    // andere Folge unausgesprochen.
    final plans = ref.read(plansProvider).value ?? const [];
    final inPlans = plans
        .where((p) => p.items.any((i) => i.exerciseId == exercise.id))
        .length;
    final sessions = ExerciseHistory.of(
      ref.read(sessionsProvider).value ?? const [],
      exercise.id,
    ).sessionCount;

    final first = await AtemDialog.show<bool>(
      context,
      kind: AtemDialogKind.destructive,
      title: l10n.exerciseDeleteQ(exercise.name),
      message: l10n.exerciseDeleteUsage(inPlans, sessions),
      confirmLabel: l10n.deleteStep1Continue,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.exerciseDelete,
      // Was bleibt und was sich ändert — die Aufzählung aus dem Board.
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sessions > 0)
            _DeleteFact(
              text: l10n.exerciseDeleteKeepUnits(sessions),
              keeps: true,
            ),
          if (inPlans > 0)
            _DeleteFact(
              text: l10n.exerciseDeletePlansGap(inPlans),
              keeps: false,
            ),
        ],
      ),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    if (first != true || !context.mounted) return;

    final second = await AtemDialog.show<bool>(
      context,
      kind: AtemDialogKind.destructive,
      title: l10n.deleteStep2Title,
      message: l10n.deleteStep2NoUndo,
      confirmLabel: l10n.deleteConfirm,
      dismissLabel: l10n.deleteKeep,
      barrierLabel: l10n.exerciseDelete,
      onConfirm: () => Navigator.of(context).pop(true),
    );
    if (second != true) return;

    await ref.read(exerciseRepositoryProvider).deleteExercise(exercise.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// Der Schloss-Chip an der Stelle, an der bei eigenen Übungen „Bearbeiten"
/// steht. Symbol **und** Wort — ein Schloss allein ist eine Vermutung.
class _CuratedLock extends StatelessWidget {
  const _CuratedLock();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Semantics(
      label: '${l10n.exerciseCuratedBadge}. ${l10n.exerciseCuratedTitle}. '
          '${l10n.exerciseCuratedBody}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AtemRadii.pill),
                border: Border.all(color: AtemColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 15, color: AtemColors.textSecondary),
                  const SizedBox(width: 7),
                  Text(l10n.exerciseCuratedBadge,
                      style: AtemType.labelSmall.of(context)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(l10n.exerciseCuratedTitle,
                style: AtemType.labelMedium.of(context)),
            const SizedBox(height: 4),
            Text(l10n.exerciseCuratedBody,
                style: AtemType.labelSmall.of(context)),
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

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Eine Zeile der Folgenaufzählung im ersten Löschdialog.
///
/// Der Punkt trägt die Richtung — lime für „bleibt erhalten", neutral für
/// „verändert sich". Das Wort steht daneben, die Farbe ist Verstärkung.
class _DeleteFact extends StatelessWidget {
  const _DeleteFact({required this.text, required this.keeps});

  final String text;
  final bool keeps;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: ExcludeSemantics(
                child: AtemStatusDot(
                  color: keeps ? AtemColors.green : AtemColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(text, style: AtemType.labelSmall.of(context)),
            ),
          ],
        ),
      );
}
