import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/exercise_providers.dart';
import '../../domain/exercise.dart';
import '../../domain/exercise_draft.dart';
import '../../domain/muscle.dart';
import '../difficulty_ui.dart';
import '../muscle_ui.dart';

/// Übung anlegen und bearbeiten.
///
/// ## Drei Pflichtfelder, und keins mehr
///
/// Die Regeln verlangen `name`, `muscleGroups` und `difficulty`. Genau die drei
/// stehen unter „Pflicht", alles Weitere unter „Kann warten" — sichtbar
/// getrennt, nicht durch ein Sternchen unterschieden.
///
/// Die Frage war, wie viele Pflichtfelder „Übung anlegen" erträgt, bevor
/// niemand mehr eine anlegt. Drei ist die Antwort der Datenbank, und sie ist
/// zufällig auch eine gute: Ohne Namen ist die Übung unauffindbar, ohne Muskel
/// farblos und aus jedem Filter gefallen, ohne Stufe von der Datenbank
/// abgewiesen. Jedes dieser drei Felder verdient seinen Zwang.
///
/// ## Keine Vorbelegung
///
/// Die Schwierigkeit startet **leer**, nicht auf „Mittel". Eine Vorbelegung
/// wäre eine Angabe, die niemand gemacht hat, und sie sähe hinterher aus wie
/// eine. Von 154 Übungen im Bestand ist das der Unterschied zwischen einer
/// Einschätzung und einem Standardwert.
///
/// ## Das Wort und die Zahl
///
/// Das Segment zeigt „Fortgeschritten", gespeichert wird `3`. Beides ist nötig:
/// Die Regel lautet `difficulty is number`, und ein Segment mit den Ziffern 1
/// bis 5 fragte nach einer Skala, die niemand kennt.
///
/// Wird eine alte Übung bearbeitet, die noch ein Wort trägt, steht das Segment
/// von selbst auf der richtigen Stufe — [Difficulty.parse] hat das Wort beim
/// Lesen längst abgebildet. Beim Speichern wird daraus die Zahl. **Das ist die
/// ganze Migration**, sie passiert beiläufig, und niemand muss davon erfahren.
class ExerciseFormScreen extends ConsumerStatefulWidget {
  const ExerciseFormScreen({super.key, this.original, this.copyOf});

  /// Die zu bearbeitende Übung. `null` heißt anlegen.
  final Exercise? original;

  /// Die kuratierte Übung, von der abgeschrieben wird.
  ///
  /// Führt zu einem **Anlegen** mit vorbelegten Feldern, nicht zu einem
  /// Bearbeiten: Die kuratierte bleibt, wie sie ist.
  final Exercise? copyOf;

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _equipment;
  late final TextEditingController _description;

  late final Set<MuscleGroup> _muscles;
  int? _difficulty;

  /// Erst nach dem ersten Speicherversuch werden Fehler gezeigt. Ein Formular,
  /// das schon beim Öffnen drei Fehler anzeigt, beschuldigt für nichts.
  var _showFaults = false;
  var _saving = false;
  var _dirty = false;
  String? _saveError;

  Exercise? get _source => widget.original ?? widget.copyOf;
  bool get _isCopy => widget.copyOf != null;
  bool get _isEdit => widget.original != null;

  @override
  void initState() {
    super.initState();
    final source = _source;
    _name = TextEditingController(text: source?.name ?? '');
    _equipment = TextEditingController(text: source?.equipment.join(', ') ?? '');
    _description = TextEditingController(text: source?.description ?? '');
    // Beim Abschreiben wird der Name gleich zur Bearbeitung angeboten — sonst
    // stünden zwei Übungen gleichen Namens in der Liste.
    _muscles = {
      for (final m in source?.displayMuscles ?? const <MuscleGroup>[]) m.filter,
    };
    _difficulty = source?.difficulty;
  }

  @override
  void dispose() {
    _name.dispose();
    _equipment.dispose();
    _description.dispose();
    super.dispose();
  }

  Set<ExerciseDraftFault> get _faults => ExerciseDraft.faultsIn(
        name: _name.text,
        muscleGroups: _muscles.toList(),
        difficulty: _difficulty,
      );

  void _touch() {
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  Future<void> _save() async {
    final l10n = AppL10n.of(context);
    final faults = _faults;
    if (faults.isNotEmpty) {
      setState(() => _showFaults = true);
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await ref.read(exerciseRepositoryProvider).saveExercise(
            ExerciseDraft(
              // Beim Abschreiben bleibt die Kennung leer: Es entsteht eine
              // neue Übung, die kuratierte bleibt unberührt.
              id: widget.original?.id,
              userId: userId,
              name: _name.text.trim(),
              muscleGroups: _muscles.toList(),
              difficulty: _difficulty!,
              equipment: _splitList(_equipment.text),
              type: _source?.type,
              description: _description.text,
              instructions: _source?.instructions ?? const [],
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = l10n.exerciseFormSaveErrorBody;
      });
    }
  }

  /// „Hantel, Klimmzugstange" wird zu zwei Einträgen. Leere fallen weg.
  static List<String> _splitList(String raw) => [
        for (final part in raw.split(','))
          if (part.trim().isNotEmpty) part.trim(),
      ];

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = AppL10n.of(context);

    final discard = await AtemDialog.show<bool>(
      context,
      kind: AtemDialogKind.destructive,
      title: l10n.formDiscardTitle,
      message: l10n.formDiscardBody,
      confirmLabel: l10n.formDiscardConfirm,
      dismissLabel: l10n.formDiscardKeep,
      barrierLabel: l10n.formDiscardBarrier,
      onConfirm: () => Navigator.of(context).pop(true),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final faults = _showFaults ? _faults : const <ExerciseDraftFault>{};

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AtemColors.base,
        appBar: AppBar(
          backgroundColor: AtemColors.base,
          title: Text(
            _isEdit ? l10n.exerciseFormEditTitle : l10n.exerciseFormNewTitle,
            style: AtemType.titleMedium.of(context),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 24),
                  children: [
                    if (_isCopy) ...[
                      AtemNotice(
                        title: l10n.exerciseCopyAction,
                        body: l10n.exerciseCopyNotice,
                        semanticLabel:
                            '${l10n.exerciseCopyAction}. ${l10n.exerciseCopyNotice}',
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(l10n.exerciseFormRequiredSection,
                        style: AtemType.labelSmall
                            .of(context)
                            .copyWith(color: AtemColors.cyan)),
                    const SizedBox(height: 14),

                    AtemFieldLabel(label: l10n.exerciseFormName),
                    AtemTextField(
                      controller: _name,
                      semanticLabel: l10n.exerciseFormName,
                      hint: l10n.exerciseFormNameHint,
                      autofocus: !_isEdit,
                      onChanged: (_) {
                        _touch();
                        if (_showFaults) setState(() {});
                      },
                      errorText: faults.contains(ExerciseDraftFault.name)
                          ? l10n.exerciseFormNameFault
                          : null,
                    ),
                    const SizedBox(height: 24),

                    AtemFieldLabel(
                      label: l10n.exerciseFormMuscles,
                      hint: l10n.exerciseFormMusclesHint,
                    ),
                    _MuscleChoice(
                      selected: _muscles,
                      onToggle: (muscle) {
                        _touch();
                        setState(() {
                          if (!_muscles.remove(muscle)) _muscles.add(muscle);
                        });
                      },
                    ),
                    if (faults.contains(ExerciseDraftFault.muscles)) ...[
                      const SizedBox(height: 8),
                      _Fault(text: l10n.exerciseFormMusclesFault),
                    ],
                    const SizedBox(height: 24),

                    AtemFieldLabel(
                      label: l10n.exerciseFormDifficulty,
                      hint: l10n.exerciseFormDifficultyHint,
                    ),
                    DifficultyChoice(
                      value: _difficulty,
                      onChanged: (level) {
                        _touch();
                        setState(() => _difficulty = level);
                      },
                    ),
                    if (faults.contains(ExerciseDraftFault.difficulty)) ...[
                      const SizedBox(height: 8),
                      _Fault(text: l10n.exerciseFormDifficultyFault),
                    ],

                    const SizedBox(height: 32),
                    Text(l10n.exerciseFormOptionalSection,
                        style: AtemType.labelSmall.of(context)),
                    const SizedBox(height: 14),

                    AtemFieldLabel(label: l10n.exerciseFormEquipment),
                    AtemTextField(
                      controller: _equipment,
                      semanticLabel: l10n.exerciseFormEquipment,
                      hint: l10n.exerciseFormEquipmentHint,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => _touch(),
                    ),
                    const SizedBox(height: 24),

                    AtemFieldLabel(label: l10n.exerciseFormDescription),
                    AtemTextField(
                      controller: _description,
                      semanticLabel: l10n.exerciseFormDescription,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => _touch(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AtemNoticeSlot(
                      notice: _saveError == null
                          ? null
                          : AtemNotice(
                              tone: AtemNoticeTone.error,
                              title: l10n.exerciseFormSaveError,
                              body: _saveError!,
                              semanticLabel:
                                  '${l10n.exerciseFormSaveError}. $_saveError',
                            ),
                    ),
                    AtemButton.gradient(
                      label: l10n.commonSave,
                      semanticLabel: l10n.commonSave,
                      busy: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neun Schalter, einer je Filtermuskel.
///
/// Ein `Wrap`, keine Reihe: Bei 200 % Schrift auf 320 dp braucht „Fortgeschritten"
/// allein fast die halbe Breite. Und ein Haken neben dem Namen, nicht nur eine
/// hellere Fläche — Farbe trägt hier ohnehin schon die Muskelkennung, sie kann
/// nicht zusätzlich den Auswahlzustand tragen.
class _MuscleChoice extends StatelessWidget {
  const _MuscleChoice({required this.selected, required this.onToggle});

  final Set<MuscleGroup> selected;
  final ValueChanged<MuscleGroup> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final muscle in MuscleGroup.filters)
          _MuscleToggle(
            muscle: muscle,
            selected: selected.contains(muscle),
            label: muscle.label(l10n),
            onTap: () => onToggle(muscle),
          ),
      ],
    );
  }
}

class _MuscleToggle extends StatelessWidget {
  const _MuscleToggle({
    required this.muscle,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final MuscleGroup muscle;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final color = muscle.color;

    return AtemTappable(
      onTap: onTap,
      semanticLabel: selected
          ? l10n.exerciseFormMuscleChosen(label)
          : l10n.exerciseFormMuscleToggle(label),
      selected: selected,
      minTapSize: const Size(0, 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AtemCategories.surface(color) : AtemColors.card,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: selected ? color : AtemColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AtemType.labelSmall.of(context).copyWith(
                    color: selected ? color : AtemColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fault extends StatelessWidget {
  const _Fault({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        label: text,
        child: ExcludeSemantics(
          child: Text(
            text,
            style: AtemType.labelMicro
                .of(context)
                .copyWith(color: AtemColors.magenta, letterSpacing: 0),
          ),
        ),
      );
}
