import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../application/exercise_providers.dart';
import '../domain/exercise.dart';
import '../domain/muscle.dart';
import 'muscle_ui.dart';
import 'screens/exercise_form_screen.dart';
import 'widgets/exercise_bits.dart';
import 'widgets/exercise_search.dart';

/// Übungen auswählen — **mehrere auf einmal, mit Filter und Ausweg**.
///
/// ## Drei Änderungen gegenüber dem ersten Entwurf
///
/// **Mehrfachauswahl.** Einen Plan mit sechs Einträgen zu füllen hiess vorher
/// sechsmal: Blatt öffnen, suchen, tippen, Blatt schliesst. Der Weg ist immer
/// derselbe, nur die Übung wechselt — genau der Fall, für den man mehrere auf
/// einmal wählt.
///
/// **Muskelfilter.** Die reine Textsuche verlangt, dass man den Namen kennt.
/// Wer „irgendwas für den Rücken" sucht, hat keinen Namen — er hat einen
/// Muskel, und der ist eine Zeile weiter oben schon eine Filterleiste.
///
/// **Ein Weg zum Anlegen.** Vorher war das Blatt eine Sackgasse: Wer merkte,
/// dass eine Übung fehlt, musste abbrechen, den Plan verlassen, die Übung
/// anlegen und von vorn beginnen. Jetzt führt eine Zeile ins Formular und
/// **zurück** — die neue Übung ist danach vorausgewählt.
///
/// ## Eine eigene Suche, nicht die des Tabs
///
/// Der Filter im Workouts-Tab ist ein Zustand, den jemand gesetzt hat und
/// nach dem Schliessen wiederhaben will. Ihn hier mitzubenutzen hiesse, ihn
/// beim Auswählen zu überschreiben.
class ExercisePicker extends ConsumerStatefulWidget {
  const ExercisePicker({super.key});

  /// Liefert die gewählten Übungen, oder `null` beim Abbrechen.
  static Future<List<Exercise>?> show(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemSheet.show<List<Exercise>>(
      context,
      title: l10n.pickerTitle,
      closeLabel: l10n.commonClose,
      child: const ExercisePicker(),
    );
  }

  @override
  ConsumerState<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<ExercisePicker> {
  final _query = TextEditingController();
  final _chosen = <String>{};

  MuscleGroup? _muscle;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Exercise> get _matches {
    final all = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final needle = _query.text.trim().toLowerCase();
    final german = Localizations.localeOf(context).languageCode == 'de';

    return [
      for (final exercise in all)
        if (_matchesMuscle(exercise) && _matchesText(exercise, needle, german))
          exercise,
    ];
  }

  bool _matchesMuscle(Exercise exercise) =>
      _muscle == null ||
      exercise.displayMuscles.any((m) => m.filter == _muscle);

  /// Sucht über **beide Namen und die Kennung**.
  ///
  /// 24 kuratierte Übungen haben keinen deutschen Namen; wer „Klimmzug"
  /// eingibt, soll `pull_up` trotzdem finden, und wer „pull" eingibt, den
  /// Klimmzug.
  bool _matchesText(Exercise exercise, String needle, bool german) {
    if (needle.isEmpty) return true;
    final candidates = [
      exercise.name,
      if (exercise.nameDe case final n?) n,
      exercise.id.replaceAll('_', ' '),
    ];
    return candidates.any((c) => c.toLowerCase().contains(needle));
  }

  Future<void> _create() async {
    // Das Blatt schliesst, damit das Formular den ganzen Bildschirm hat.
    // Was schon gewählt war, geht dabei verloren — deshalb steht der Weg
    // unten, nach den Treffern, und nicht als erste Zeile.
    Navigator.of(context).pop(<Exercise>[]);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExerciseFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final matches = _matches;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExerciseSearchField(
          controller: _query,
          autofocus: false,
          onChanged: (_) => setState(() {}),
          onClear: () {
            _query.clear();
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        ExerciseFilterRow(
          selected: _muscle,
          padding: EdgeInsets.zero,
          onSelect: (m) => setState(() => _muscle = _muscle == m ? null : m),
          onAll: () => setState(() => _muscle = null),
        ),
        const SizedBox(height: 10),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: AtemEmptyState(
              title: l10n.exercisesNoMatchTitle,
              body: l10n.exercisesNoMatchBody,
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.40,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: matches.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, thickness: 1, color: AtemColors.border),
              itemBuilder: (_, i) => _Row(
                exercise: matches[i],
                chosen: _chosen.contains(matches[i].id),
                total: _chosen.length,
                onTap: () => setState(() {
                  if (!_chosen.remove(matches[i].id)) {
                    _chosen.add(matches[i].id);
                  }
                }),
              ),
            ),
          ),
        const SizedBox(height: 12),
        AtemButton.ghost(
          label: l10n.pickerCreate,
          semanticLabel: l10n.pickerCreate,
          leading: const Icon(Icons.add, size: 16, color: AtemColors.cyan),
          onPressed: _create,
        ),
        const SizedBox(height: 10),
        AtemButton.gradient(
          // Der gesperrte Knopf trägt seinen Grund, wie überall sonst.
          label: _chosen.isEmpty
              ? l10n.pickerNone
              : l10n.pickerAdd(_chosen.length),
          semanticLabel: _chosen.isEmpty
              ? l10n.pickerNone
              : l10n.pickerAdd(_chosen.length),
          size: AtemButtonSize.compact,
          onPressed: _chosen.isEmpty
              ? null
              : () {
                  final all =
                      ref.read(exercisesProvider).value ?? const <Exercise>[];
                  // In der Reihenfolge der Liste, nicht der Antippfolge:
                  // Wer von oben nach unten auswählt, erwartet sie so im Plan.
                  Navigator.of(context).pop([
                    for (final exercise in all)
                      if (_chosen.contains(exercise.id)) exercise,
                  ]);
                },
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.exercise,
    required this.chosen,
    required this.total,
    required this.onTap,
  });

  final Exercise exercise;
  final bool chosen;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final muscle = exercise.displayMuscles.firstOrNull;
    final color = muscle?.color ?? AtemCategories.grey;
    final name = exerciseName(context, exercise);

    return AtemTappable(
      onTap: onTap,
      semanticLabel: '$name, ${l10n.exerciseFieldMusclesCount(total)}',
      selected: chosen,
      minTapSize: const Size(0, 56),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            MuscleOrb(color: color, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.titleSmallOrDefault(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (muscle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      muscle.label(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(color: color, letterSpacing: 0),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: chosen
                    ? AtemCategories.surface(AtemColors.cyan)
                    : AtemColors.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: chosen ? AtemColors.cyan : AtemColors.border),
              ),
              child: chosen
                  ? const Icon(Icons.check, size: 15, color: AtemColors.cyan)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
