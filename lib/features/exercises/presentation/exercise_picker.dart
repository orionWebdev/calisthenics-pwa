import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../application/exercise_providers.dart';
import '../domain/exercise.dart';
import 'widgets/exercise_bits.dart';

/// Übung auswählen — für „hinzufügen" und für „ersetzen".
///
/// **Eigene Suche, nicht die des Tabs.** Der Filter im Workouts-Tab ist ein
/// Zustand, den jemand gesetzt hat und nach dem Schließen des Blatts wiederhaben
/// will. Ihn hier mitzubenutzen hieße, ihn beim Auswählen zu überschreiben.
class ExercisePicker extends ConsumerStatefulWidget {
  const ExercisePicker({super.key});

  /// Liefert die gewählte Übung, oder `null` beim Abbrechen.
  static Future<Exercise?> show(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemSheet.show<Exercise>(
      context,
      title: l10n.planFormPickTitle,
      closeLabel: l10n.commonClose,
      child: const ExercisePicker(),
    );
  }

  @override
  ConsumerState<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<ExercisePicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final all = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final needle = _query.text.trim().toLowerCase();

    // Dieselbe Regel wie in der Liste: Name **und** Kennung. 24 kuratierte
    // Übungen haben keinen deutschen Namen; über die Kennung sind sie trotzdem
    // auffindbar.
    final matches = [
      for (final exercise in all)
        if (needle.isEmpty ||
            exercise.name.toLowerCase().contains(needle) ||
            exercise.id.toLowerCase().replaceAll('_', ' ').contains(needle))
          exercise,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtemTextField(
          controller: _query,
          semanticLabel: l10n.exercisesSearchHint,
          hint: l10n.exercisesSearchHint,
          autofocus: true,
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.none,
          leading: const Icon(Icons.search,
              size: 20, color: AtemColors.textSecondary),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: AtemEmptyState(
              title: l10n.exercisesNoMatchTitle,
              body: l10n.exercisesNoMatchBody,
            ),
          )
        else
          // Begrenzte Höhe: Das Blatt darf wachsen, aber nicht den ganzen
          // Bildschirm nehmen — die Suchzeile muss sichtbar bleiben.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: matches.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, thickness: 1, color: AtemColors.border),
              itemBuilder: (_, i) => ExerciseRow(
                exercise: matches[i],
                onTap: () => Navigator.of(context).pop(matches[i]),
              ),
            ),
          ),
      ],
    );
  }
}
