import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../app/application/snackbar_providers.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/exercise_providers.dart';
import '../../domain/exercise.dart';
import '../../domain/exercise_draft.dart';
import '../../domain/muscle.dart';
import '../difficulty_ui.dart';
import '../muscle_sheet.dart';
import '../muscle_ui.dart';
import '../widgets/exercise_bits.dart';
import 'exercise_detail_screen.dart';

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
  late final TextEditingController _cues;

  /// Die optionalen Felder sind zugeklappt, bis jemand sie will.
  var _showOptional = false;

  late final Set<MuscleGroup> _muscles;
  int? _difficulty;

  /// Erst nach dem ersten Speicherversuch werden Fehler gezeigt. Ein Formular,
  /// das schon beim Öffnen drei Fehler anzeigt, beschuldigt für nichts.
  var _showFaults = false;
  var _saving = false;
  var _dirty = false;
  String? _saveError;

  /// Die gleichnamige Übung, die es schon gibt. `null`, solange keine im Weg
  /// ist.
  Exercise? _duplicate;

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
    _cues = TextEditingController(text: source?.cues.join('\n') ?? '');
    // Wer eine Übung bearbeitet, die schon Angaben trägt, soll sie sehen —
    // sonst sähe der Bildschirm aus, als wären sie verloren.
    _showOptional = _optionalCount > 0;
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
    _cues.dispose();
    super.dispose();
  }

  /// Wie viele der optionalen Felder gefüllt sind.
  int get _optionalCount => [
        _equipment.text,
        _description.text,
        _cues.text,
      ].where((t) => t.trim().isNotEmpty).length;

  /// Wie viele Angaben gegenüber dem Ausgangszustand **geändert** wurden.
  ///
  /// Der Verlassen-Dialog zählt beides getrennt, weil sich beides anders
  /// anfühlt: Etwas zu überschreiben ist ein Eingriff, etwas zu ergänzen
  /// nicht. Bei einer neuen Übung ist alles Ergänzung.
  int get _changedCount {
    final source = _source;
    if (source == null) return 0;
    var count = 0;
    void compare(String before, String now) {
      if (before.trim().isNotEmpty && before.trim() != now.trim()) count++;
    }

    compare(source.name, _name.text);
    compare(source.equipment.join(', '), _equipment.text);
    compare(source.description ?? '', _description.text);
    compare(source.cues.join('\n'), _cues.text);
    if (source.difficulty != null && source.difficulty != _difficulty) count++;
    return count;
  }

  /// Wie viele Angaben **dazugekommen** sind.
  int get _addedCount {
    final source = _source;
    var count = 0;
    void added(String before, String now) {
      if (before.trim().isEmpty && now.trim().isNotEmpty) count++;
    }

    added(source?.name ?? '', _name.text);
    added(source?.equipment.join(', ') ?? '', _equipment.text);
    added(source?.description ?? '', _description.text);
    added(source?.cues.join('\n') ?? '', _cues.text);
    if (source?.difficulty == null && _difficulty != null) count++;
    if ((source?.displayMuscles.isEmpty ?? true) && _muscles.isNotEmpty) {
      count++;
    }
    return count;
  }

  /// Warum gerade nicht gespeichert werden kann — oder `null`.
  ///
  /// Erscheint **erst nach dem ersten Versuch**. Ein Knopf, der beim Öffnen
  /// „Noch 3 Angaben nötig" sagt, beschuldigt für nichts; nach dem ersten
  /// Tippen ist derselbe Satz eine Antwort.
  String? _blockedReason(AppL10n l10n) {
    if (!_showFaults) return null;
    final open = _faults.length;
    return open == 0 ? null : l10n.exerciseSaveBlocked(open);
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

  /// Eine eigene Übung gleichen Namens — ohne sich selbst.
  ///
  /// Verglichen wird ohne Rücksicht auf Gross- und Kleinschreibung und ohne
  /// Randleerzeichen: „Dips" und „dips " sind für einen Menschen dieselbe
  /// Übung, und zwei davon in der Liste sind ein Ärgernis, kein Feature.
  ///
  /// **Kuratierte zählen nicht.** Eine eigene Fassung heisst absichtlich wie
  /// ihr Vorbild; sie deshalb abzuweisen, verböte genau den Weg, den das
  /// Übungsdetail anbietet.
  Exercise? _findDuplicate(String name) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final exercise in ref.read(exercisesProvider).value ?? const []) {
      if (!exercise.isOwn) continue;
      if (exercise.id == widget.original?.id) continue;
      if (exercise.name.trim().toLowerCase() == needle) return exercise;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppL10n.of(context);
    final faults = _faults;
    if (faults.isNotEmpty) {
      setState(() => _showFaults = true);
      return;
    }

    // Vor dem Schreiben, nicht danach: Die Datenbank kennt keine Eindeutigkeit
    // auf `name`, sie würde die zweite „Dips" anstandslos annehmen.
    final duplicate = _findDuplicate(_name.text);
    if (duplicate != null) {
      setState(() => _duplicate = duplicate);
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _saving = true;
      _saveError = null;
      _duplicate = null;
    });

    final before = widget.original;

    try {
      final id = await ref.read(exerciseRepositoryProvider).saveExercise(
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
              cues: _splitLines(_cues.text),
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      _announce(l10n, id: id, before: before);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        // **Zurück ins Formular, nicht in einen Toast.** Board, Schreibregeln:
        // Was abgewiesen wurde, muss dort landen, wo man es korrigieren kann.
        _saveError = l10n.commonRetrySave;
      });
    }
  }

  /// Was nach dem Speichern über der Leiste steht.
  ///
  /// Beim **Anlegen** ein Weg vorwärts („Öffnen") — es gibt nichts
  /// zurückzunehmen, wohl aber etwas anzusehen. Beim **Bearbeiten** ein Weg
  /// zurück: Der Vorzustand ist ein einzelner Datensatz und vollständig
  /// zurückschreibbar (Schreibmatrix, 30 s).
  void _announce(AppL10n l10n, {required String id, Exercise? before}) {
    final notifier = ref.read(snackbarProvider.notifier);

    if (before == null) {
      notifier.show(AtemSnack(
        message: l10n.commonCreated,
        semanticLabel: l10n.commonCreated,
        tone: AtemSnackTone.success,
        actionLabel: l10n.commonOpen,
        onAction: () {
          // Der Strom kann die neue Übung noch nicht führen — dann führt der
          // Weg nirgendwohin, und das ist besser als auf eine erfundene.
          final created = (ref.read(exercisesProvider).value ?? const [])
              .where((e) => e.id == id)
              .firstOrNull;
          if (created == null) return;
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ExerciseDetailScreen(exercise: created),
          ));
        },
      ));
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    notifier.show(AtemSnack(
      message: l10n.commonSaved,
      semanticLabel: l10n.commonSaved,
      tone: AtemSnackTone.success,
      actionLabel: l10n.commonUndo,
      onAction: () => ref.read(exerciseRepositoryProvider).saveExercise(
            ExerciseDraft(
              id: before.id,
              userId: userId,
              name: before.name,
              muscleGroups: before.displayMuscles,
              difficulty: before.difficulty ?? Difficulty.min,
              equipment: before.equipment,
              type: before.type,
              description: before.description,
              instructions: before.instructions,
              cues: before.cues,
            ),
          ),
    ));
  }

  /// „Hantel, Klimmzugstange" wird zu zwei Einträgen. Leere fallen weg.
  static List<String> _splitList(String raw) => [
        for (final part in raw.split(','))
          if (part.trim().isNotEmpty) part.trim(),
      ];

  /// Cues stehen einer je Zeile — so schreibt es das Board, und so liegen sie
  /// auch im Bestand.
  static List<String> _splitLines(String raw) => [
        for (final line in raw.split('\n'))
          if (line.trim().isNotEmpty) line.trim(),
      ];

  /// Der Verlassen-Dialog mit drei Wegen.
  ///
  /// Gibt `true` zurück, wenn der Bildschirm geschlossen werden darf. Beim
  /// Sichern wird zuerst geschrieben — schlägt das fehl, bleibt das Formular
  /// stehen und die Meldung erklärt, warum.
  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = AppL10n.of(context);

    final choice = await AtemUnsavedDialog.show(
      context,
      title: l10n.unsavedTitle,
      message: l10n.unsavedBody(_changedCount, _addedCount),
      saveLabel: l10n.unsavedSave,
      discardLabel: l10n.unsavedDiscard,
      keepLabel: l10n.unsavedContinue,
    );

    switch (choice) {
      case AtemUnsavedChoice.save:
        await _save();
        // `_save` schliesst selbst, wenn es geklappt hat. Ist der Bildschirm
        // noch da, ist etwas schiefgegangen — dann bleibt er.
        return false;
      case AtemUnsavedChoice.discard:
        return true;
      case AtemUnsavedChoice.keepEditing:
      case null:
        return false;
    }
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
            _isEdit ? l10n.exerciseEditTitle : l10n.exerciseNewTitle,
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
                        title: l10n.exerciseCuratedCopy,
                        body: l10n.exerciseCuratedBody,
                        semanticLabel:
                            '${l10n.exerciseCuratedCopy}. ${l10n.exerciseCuratedBody}',
                      ),
                      const SizedBox(height: 24),
                    ],
                    AtemFieldLabel(label: l10n.exerciseFieldName),
                    AtemTextField(
                      controller: _name,
                      semanticLabel: l10n.exerciseFieldName,
                      hint: l10n.exerciseFieldNameHint,
                      autofocus: !_isEdit,
                      onChanged: (_) {
                        _touch();
                        setState(() => _duplicate = null);
                      },
                      // Der Name ist das einzige Feld mit einer Meldung: Ein
                      // leeres Textfeld sieht man nicht so unmittelbar wie
                      // einen fehlenden Chip. Bei Muskeln und Stufe färbt nur
                      // der Rand — „keine Meldung für etwas, das man sofort
                      // sieht" (Board, Fehlerfälle).
                      errorText: faults.contains(ExerciseDraftFault.name)
                          ? l10n.exerciseFieldName
                          : null,
                    ),
                    const SizedBox(height: 24),

                    AtemFieldLabel(
                      label: l10n.exerciseFieldMuscles,
                      hint: l10n.exerciseFieldMusclesCount(_muscles.length),
                    ),
                    _MuscleField(
                      selected: _muscles,
                      hasError: faults.contains(ExerciseDraftFault.muscles),
                      onTap: () async {
                        final chosen =
                            await MuscleSheet.show(context, _muscles);
                        if (chosen == null) return;
                        _touch();
                        setState(() {
                          _muscles
                            ..clear()
                            ..addAll(chosen);
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    AtemFieldLabel(
                      label: l10n.exerciseFieldLevel,
                      hint: l10n.exerciseLevelHint,
                    ),
                    DifficultyChoice(
                      value: _difficulty,
                      hasError: faults.contains(ExerciseDraftFault.difficulty),
                      onChanged: (level) {
                        _touch();
                        setState(() => _difficulty = level);
                      },
                    ),

                    const SizedBox(height: 28),
                    // **Alles Optionale hinter einer einzigen Zeile.** Board,
                    // Entscheidung 06: Drei Pflichtfelder auf drei Seiten zu
                    // verteilen macht aus einer Zwanzig-Sekunden-Aufgabe eine
                    // Prozedur — und alles Weitere sichtbar daneben zu legen
                    // liesse sie länger aussehen, als sie ist.
                    _MoreSection(
                      open: _showOptional,
                      count: _optionalCount,
                      onToggle: () =>
                          setState(() => _showOptional = !_showOptional),
                    ),
                    if (_showOptional) ...[
                      const SizedBox(height: 16),
                      AtemFieldLabel(label: l10n.exerciseFieldEquipment),
                      AtemTextField(
                        controller: _equipment,
                        semanticLabel: l10n.exerciseFieldEquipment,
                        hint: l10n.exerciseFieldEquipmentHint,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(_touch),
                      ),
                      const SizedBox(height: 20),
                      AtemFieldLabel(label: l10n.exerciseFieldInstructions),
                      AtemTextField(
                        controller: _description,
                        semanticLabel: l10n.exerciseFieldInstructions,
                        hint: l10n.exerciseFieldInstructionsHint,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) => setState(_touch),
                      ),
                      const SizedBox(height: 20),
                      AtemFieldLabel(label: l10n.exerciseFieldCues),
                      AtemTextField(
                        controller: _cues,
                        semanticLabel: l10n.exerciseFieldCues,
                        hint: l10n.exerciseFieldCuesHint,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) => setState(_touch),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_duplicate case final existing?) ...[
                      AtemNotice(
                        tone: AtemNoticeTone.error,
                        title: l10n.exerciseDuplicateTitle,
                        body: l10n.exerciseDuplicateBody(existing.name),
                        semanticLabel: '${l10n.exerciseDuplicateTitle}. '
                            '${l10n.exerciseDuplicateBody(existing.name)}',
                      ),
                      const SizedBox(height: 10),
                      // Zwei Wege, beide vorwärts: die vorhandene öffnen oder
                      // den Namen abwandeln. Kein „Trotzdem speichern" — zwei
                      // gleichnamige eigene Übungen sind für niemanden nützlich.
                      Row(
                        children: [
                          Expanded(
                            child: AtemButton.outline(
                              label: l10n.exerciseDuplicateOpen,
                              semanticLabel: l10n.exerciseDuplicateOpen,
                              onPressed: () => Navigator.of(context)
                                  .pushReplacement(MaterialPageRoute<void>(
                                builder: (_) =>
                                    ExerciseDetailScreen(exercise: existing),
                              )),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AtemButton.outline(
                              label: l10n.exerciseDuplicateSuggest,
                              semanticLabel: l10n.exerciseDuplicateSuggest,
                              accent: AtemColors.cyan,
                              onPressed: () => setState(() {
                                _name.text = '${existing.name} 2';
                                _duplicate = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    AtemNoticeSlot(
                      notice: _saveError == null
                          ? null
                          : AtemNotice(
                              tone: AtemNoticeTone.error,
                              title: l10n.exerciseDuplicateTitle,
                              body: _saveError!,
                              semanticLabel:
                                  '${l10n.exerciseDuplicateTitle}. $_saveError',
                            ),
                    ),
                    // **Der gesperrte Knopf trägt seinen Grund.** A11y-Notiz
                    // des Boards: „Ein disabled-Knopf ohne Grund ist die
                    // häufigste Sackgasse." Sichtbar wie vorgelesen — nicht
                    // nur im Label, sondern als Beschriftung.
                    AtemButton.gradient(
                      label: _blockedReason(l10n) ??
                          (_saving ? l10n.commonSaving : l10n.commonSave),
                      semanticLabel: _blockedReason(l10n) ??
                          (_saving ? l10n.commonSaving : l10n.commonSave),
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

/// Das Feld, das die Muskelauswahl zusammenfasst und das Blatt öffnet.
///
/// Es zeigt die gewählten Muskeln als kleine Kugeln plus Namen — die Auswahl
/// ist damit ablesbar, ohne zu öffnen. Die Begründung für den Umbau steht am
/// [MuscleSheet].
class _MuscleField extends StatelessWidget {
  const _MuscleField({
    required this.selected,
    required this.hasError,
    required this.onTap,
  });

  final Set<MuscleGroup> selected;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final ordered = [
      for (final muscle in MuscleGroup.filters)
        if (selected.contains(muscle)) muscle,
    ];
    final names = ordered.map((m) => m.label(l10n)).join(', ');

    return AtemTappable(
      onTap: onTap,
      semanticLabel: ordered.isEmpty
          ? '${l10n.exerciseFieldMuscles}. ${l10n.muscleFieldEmpty}'
          : '${l10n.exerciseFieldMuscles}. '
              '${l10n.muscleFieldCount(ordered.length, names)}',
      minTapSize: const Size(0, 52),
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AtemColors.surfaceSolid,
          borderRadius: AtemRadii.statBoxR,
          border: Border.all(
            color: hasError ? AtemColors.magenta : AtemColors.border,
            width: hasError ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (ordered.isNotEmpty) ...[
              // Höchstens drei Kugeln — mehr wäre eine Farbreihe ohne
              // Aussage, und die Namen stehen ohnehin daneben.
              for (final muscle in ordered.take(3)) ...[
                MuscleOrb(color: muscle.color, size: 22),
                const SizedBox(width: 4),
              ],
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                ordered.isEmpty
                    ? l10n.muscleFieldEmpty
                    : l10n.muscleFieldCount(ordered.length, names),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AtemType.body.of(context).copyWith(
                      color: ordered.isEmpty
                          ? AtemColors.textSecondary
                          : AtemColors.textPrimary,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more,
                size: 20, color: AtemColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Die Zeile, hinter der alles Optionale liegt.
///
/// Board, Entscheidung 06: ein Screen, drei Pflichtfelder, und der Rest hinter
/// **einer** Zeile. Der Zähler daneben sagt, wie viel dahinter schon steht —
/// sonst müsste man aufklappen, um zu sehen, ob sich das Aufklappen lohnt.
class _MoreSection extends StatelessWidget {
  const _MoreSection({
    required this.open,
    required this.count,
    required this.onToggle,
  });

  final bool open;
  final int count;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final count_ = l10n.exerciseMoreCount(count);

    return AtemTappable(
      onTap: onToggle,
      semanticLabel: '${l10n.exerciseMore}, $count_',
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(
            open ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: AtemColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l10n.exerciseMore,
                style: AtemType.body.of(context)),
          ),
          const SizedBox(width: 10),
          // Nachgiebig: „3 optional" ist bei 200 % Schrift auf 320 dp
          // breiter als der Rest der Zeile übrig lässt.
          Flexible(
            child: Text(
              count_,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AtemType.labelMicro.of(context),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
