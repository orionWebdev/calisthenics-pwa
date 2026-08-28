import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../app/application/snackbar_providers.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/exercise_picker.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../../exercises/presentation/widgets/exercise_bits.dart';
import '../../application/plan_providers.dart';
import '../../domain/plan.dart';
import '../../domain/plan_draft.dart';

/// Plan anlegen und bearbeiten.
///
/// ## Die Lücke ist ein Eintrag, kein Fehler
///
/// Zeigt ein Eintrag auf eine gelöschte Übung, bleibt er stehen — gestrichelt,
/// mit seinen Zielwerten, und mit „Ersetzen" als **erstem** angebotenen Weg.
/// Die Begründung liegt an [ResolvedPlanItem]: Die Zielwerte hat jemand einmal
/// überlegt, und sie gelten weiter, auch wenn die Übung wechselt.
///
/// „Entfernen" gibt es auch, aber an zweiter Stelle. Die Reihenfolge ist die
/// Aussage: Das Übliche ist, dass jemand eine andere Fassung derselben Bewegung
/// will, nicht dass die Zeile weg soll.
class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key, this.original});

  final Plan? original;

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  late final TextEditingController _name;
  late final List<PlanItem> _items;

  var _showFaults = false;
  var _saving = false;
  var _dirty = false;
  String? _saveError;

  bool get _isEdit => widget.original != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.original?.name ?? '');
    _items = [...?widget.original?.items];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Einträge, die es vorher schon gab und die jetzt anders aussehen.
  int get _changedCount {
    final before = widget.original?.items ?? const <PlanItem>[];
    var count = 0;
    for (var i = 0; i < _items.length && i < before.length; i++) {
      final a = before[i];
      final b = _items[i];
      if (a.exerciseId != b.exerciseId ||
          a.sets != b.sets ||
          a.reps != b.reps ||
          a.holdSeconds != b.holdSeconds ||
          a.restSeconds != b.restSeconds) {
        count++;
      }
    }
    if (_name.text.trim() != (widget.original?.name ?? '').trim() &&
        (widget.original?.name ?? '').isNotEmpty) {
      count++;
    }
    return count;
  }

  /// Einträge, die dazugekommen sind.
  int get _addedCount {
    final before = widget.original?.items.length ?? 0;
    return _items.length > before ? _items.length - before : 0;
  }

  Set<PlanDraftFault> get _faults =>
      PlanDraft.faultsIn(name: _name.text);

  void _touch() {
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  Future<void> _add() async {
    final exercise = await ExercisePicker.show(context);
    if (exercise == null) return;
    _touch();
    setState(() {
      // Zielwerte bleiben leer: Drei Sätze zu unterstellen wäre eine Angabe,
      // die niemand gemacht hat. Der Plan rechnet ohnehin mit drei, wenn
      // nichts dasteht — aber er behauptet dann nicht, es sei gewählt worden.
      _items.add(PlanItem(exerciseId: exercise.id));
    });
  }

  Future<void> _replace(int index) async {
    final exercise = await ExercisePicker.show(context);
    if (exercise == null) return;
    _touch();
    setState(() {
      final old = _items[index];
      // **Die Zielwerte wandern mit.** Das ist der ganze Sinn des Ersetzens.
      _items[index] = PlanItem(
        exerciseId: exercise.id,
        sets: old.sets,
        reps: old.reps,
        holdSeconds: old.holdSeconds,
        restSeconds: old.restSeconds,
      );
    });
  }

  void _move(int index, int by) {
    final target = index + by;
    if (target < 0 || target >= _items.length) return;
    _touch();
    setState(() {
      final item = _items.removeAt(index);
      _items.insert(target, item);
    });
  }

  /// Entfernt einen Eintrag — **mit Widerruf**.
  ///
  /// Schreibmatrix des Boards: keine Bestätigung, aber dreissig Sekunden
  /// zurück. Eine Zeile ist sofort wiederherstellbar; ein Dialog je Zeile
  /// wäre Lärm, ein endgültiges Entfernen ohne Weg zurück eine Falle.
  void _remove(int index) {
    final removed = _items[index];
    final name = _nameOf(removed.exerciseId);
    _touch();
    setState(() => _items.removeAt(index));

    ref.read(snackbarProvider.notifier).show(
          AtemSnack(
            message: AppL10n.of(context).planFormRemoveA11y(name),
            semanticLabel: AppL10n.of(context).planFormRemoveA11y(name),
            actionLabel: AppL10n.of(context).commonUndo,
            onAction: () => setState(() => _items.insert(index, removed)),
          ),
        );
  }

  String _nameOf(String exerciseId) {
    for (final exercise in ref.read(exercisesProvider).value ?? const []) {
      if (exercise.id == exerciseId) return exercise.name;
    }
    return AppL10n.of(context).planBrokenEntry;
  }

  void _updateItem(int index, PlanItem item) {
    _touch();
    setState(() => _items[index] = item);
  }

  Future<void> _save() async {
    final l10n = AppL10n.of(context);
    if (_faults.isNotEmpty) {
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
      await ref.read(planRepositoryProvider).savePlan(
            PlanDraft(
              id: widget.original?.id,
              userId: userId,
              name: _name.text.trim(),
              items: _items,
              icon: widget.original?.icon,
              type: widget.original?.type,
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
    final faults = _showFaults ? _faults : const <PlanDraftFault>{};
    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final resolved = ResolvedPlanItem.resolve(_items, exercises);

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
            _isEdit ? l10n.planFormEditTitle : l10n.planNewTitle,
            style: AtemType.titleMedium.of(context),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AtemSpacing.screenPadding,
                      0, AtemSpacing.screenPadding, 24),
                  children: [
                    AtemFieldLabel(label: l10n.planFormName),
                    AtemTextField(
                      controller: _name,
                      semanticLabel: l10n.planFormName,
                      hint: l10n.planFormNameHint,
                      autofocus: !_isEdit,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        _touch();
                        if (_showFaults) setState(() {});
                      },
                      errorText: faults.contains(PlanDraftFault.name)
                          ? l10n.planFormName
                          : null,
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.planFormItems,
                        style: AtemType.labelMedium.of(context)),
                    const SizedBox(height: 10),
                    if (resolved.isEmpty)
                      // Kein Fehler, sondern eine Feststellung: Der Plan darf
                      // leer gespeichert werden, nur starten lässt er sich so
                      // nicht.
                      Text(l10n.planEmptyAllowed,
                          style: AtemType.labelSmall.of(context))
                    else
                      for (var i = 0; i < resolved.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _ItemCard(
                          index: i,
                          total: resolved.length,
                          resolved: resolved[i],
                          onChanged: (item) => _updateItem(i, item),
                          onReplace: () => _replace(i),
                          onRemove: () => _remove(i),
                          onMoveUp: i == 0 ? null : () => _move(i, -1),
                          onMoveDown:
                              i == resolved.length - 1 ? null : () => _move(i, 1),
                        ),
                      ],
                    const SizedBox(height: 16),
                    AtemButton.outline(
                      label: l10n.planEntryAdd,
                      semanticLabel: l10n.planEntryAdd,
                      leading: const Icon(Icons.add,
                          size: 18, color: AtemColors.cyan),
                      onPressed: _add,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AtemSpacing.screenPadding, 8,
                    AtemSpacing.screenPadding, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AtemNoticeSlot(
                      notice: _saveError == null
                          ? null
                          : AtemNotice(
                              tone: AtemNoticeTone.error,
                              title: l10n.planFormSaveError,
                              body: _saveError!,
                              semanticLabel:
                                  '${l10n.planFormSaveError}. $_saveError',
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

/// Ein Planeintrag: Übung oben, Zielwerte darunter, Aktionen ganz unten.
class _ItemCard extends StatefulWidget {
  const _ItemCard({
    required this.index,
    required this.total,
    required this.resolved,
    required this.onChanged,
    required this.onReplace,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final int index;
  final int total;
  final ResolvedPlanItem resolved;
  final ValueChanged<PlanItem> onChanged;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _hold;
  late final TextEditingController _rest;

  @override
  void initState() {
    super.initState();
    final item = widget.resolved.item;
    _sets = TextEditingController(text: item.sets?.toString() ?? '');
    _reps = TextEditingController(text: item.reps ?? '');
    _hold = TextEditingController(text: item.holdSeconds?.toString() ?? '');
    _rest = TextEditingController(text: item.restSeconds?.toString() ?? '');
  }

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    _hold.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(PlanItem(
      exerciseId: widget.resolved.item.exerciseId,
      sets: int.tryParse(_sets.text.trim()),
      // Bleibt Text: „8-12" ist ein gültiger Zielwert und wäre als Zahl
      // verloren.
      reps: _reps.text.trim().isEmpty ? null : _reps.text.trim(),
      holdSeconds: int.tryParse(_hold.text.trim()),
      restSeconds: int.tryParse(_rest.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final exercise = widget.resolved.exercise;
    final dangling = widget.resolved.isDangling;
    final muscle = exercise?.displayMuscles.firstOrNull;
    final name = exercise?.name ?? l10n.planItemMissing;

    return Container(
      decoration: BoxDecoration(
        color: AtemColors.card,
        borderRadius: BorderRadius.circular(AtemRadii.card),
        // Die Lücke trägt keinen durchgezogenen Rand: Sie ist kein Eintrag
        // wie die anderen, und das muss sichtbar sein, ohne dass Farbe es
        // allein tragen muss — deshalb steht der Satz darunter dabei.
        border: dangling
            ? null
            : Border.all(color: AtemColors.border),
      ),
      foregroundDecoration: dangling
          ? const _DashedBorder(color: AtemColors.textSecondary)
          : null,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: dangling
                ? l10n.planFormGapA11y(widget.index + 1, _scheme(l10n))
                : l10n.planFormMoveA11y(name, widget.index + 1, widget.total),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  MuscleOrb(
                    color: muscle?.color ?? AtemCategories.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dangling ? l10n.planFormGapTitle : name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AtemType.titleSmallOrDefault(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: dangling
                                ? AtemColors.textSecondary
                                : AtemColors.textPrimary,
                          ),
                        ),
                        if (dangling) ...[
                          const SizedBox(height: 4),
                          // Was von der Übung übrig ist: die Zielwerte. Genau
                          // sie sind der Grund, die Zeile stehenzulassen.
                          Text(
                            l10n.planBrokenKeepTarget(_scheme(l10n)),
                            style: AtemType.labelMicro.of(context).copyWith(
                                color: AtemColors.cyan, letterSpacing: 0),
                          ),
                        ] else if (muscle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            muscle.label(l10n),
                            style: AtemType.labelMicro.of(context).copyWith(
                                color: muscle.color, letterSpacing: 0),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Die Zielwerte bleiben auch an der Lücke änderbar. Sie sind das
          // Einzige, was von ihr übrig ist — sie zu sperren nähme ihr den Zweck.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Target(
                label: l10n.planEntrySets,
                controller: _sets,
                onChanged: _emit,
              ),
              _Target(
                label: l10n.planEntryReps,
                controller: _reps,
                hint: l10n.planEntryRepsHint,
                // **Kein Zahlenfeld.** Bereiche wie „8-12" gehören zum Bestand.
                text: true,
                onChanged: _emit,
              ),
              _Target(
                label: l10n.planFormHold,
                controller: _hold,
                onChanged: _emit,
              ),
              _Target(
                label: l10n.planEntryRest,
                controller: _rest,
                onChanged: _emit,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Bei einer Lücke steht „Ersetzen" zuerst — und ist die einzige
              // hervorgehobene Aktion.
              if (dangling)
                _Action(
                  icon: Icons.swap_horiz,
                  label: l10n.planBrokenReplace,
                  semanticLabel: l10n.planBrokenReplace,
                  accent: AtemColors.cyan,
                  onTap: widget.onReplace,
                ),
              if (widget.onMoveUp != null)
                _Action(
                  icon: Icons.arrow_upward,
                  label: l10n.planFormMoveUp,
                  semanticLabel: '${l10n.planFormMoveUp}: $name',
                  onTap: widget.onMoveUp!,
                ),
              if (widget.onMoveDown != null)
                _Action(
                  icon: Icons.arrow_downward,
                  label: l10n.planFormMoveDown,
                  semanticLabel: '${l10n.planFormMoveDown}: $name',
                  onTap: widget.onMoveDown!,
                ),
              if (!dangling)
                _Action(
                  icon: Icons.swap_horiz,
                  label: l10n.planBrokenReplace,
                  semanticLabel: '${l10n.planFormReplace}: $name',
                  onTap: widget.onReplace,
                ),
              _Action(
                icon: Icons.close,
                label: l10n.planBrokenRemove,
                semanticLabel: l10n.planFormRemoveA11y(name),
                accent: AtemColors.magenta,
                onTap: widget.onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _scheme(AppL10n l10n) => <String>[
        if (_sets.text.trim().isNotEmpty) '${_sets.text.trim()}×',
        if (_reps.text.trim().isNotEmpty) _reps.text.trim(),
        if (_hold.text.trim().isNotEmpty)
          l10n.restSeconds(int.tryParse(_hold.text.trim()) ?? 0),
      ].join(' ');
}

/// Ein Zielwert mit Beschriftung darüber.
class _Target extends StatelessWidget {
  const _Target({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hint,
    this.text = false,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? hint;
  final bool text;

  @override
  Widget build(BuildContext context) {
    // **Die Breite folgt der Schrift.** 74 dp reichen für „Sätze" bei
    // Faktor 1.0 und laufen bei 2.0 um 29 px über — die Prüfmatrix hat es auf
    // 320 dp gefunden. Nach oben gedeckelt, damit vier Zielwerte nicht zu
    // vier Zeilen werden.
    final width =
        MediaQuery.textScalerOf(context).scale(74).clamp(74.0, 150.0);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtemType.labelMicro.of(context),
            ),
          ),
          const SizedBox(height: 4),
          if (text)
            AtemTextField(
              controller: controller,
              semanticLabel: label,
              hint: hint,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => onChanged(),
            )
          else
            AtemNumberField(
              controller: controller,
              semanticLabel: label,
              width: null,
              onChanged: (_) => onChanged(),
            ),
        ],
      ),
    );
  }
}

/// Eine Aktion an einem Planeintrag: Symbol **und** Wort.
///
/// Ein reines Symbol wäre kleiner und schöner. Es wäre auch für einen
/// Screenreader gleichwertig — aber nicht für jemanden, der sechs Pfeile und
/// Kreuze auf einer Karte sieht und raten muss, welches welches ist.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AtemColors.textSecondary;
    // Ein `Wrap` gibt seinen Kindern unbegrenzte Breite — eine Pille, die
    // breiter wird als die Karte, läuft deshalb über, statt umzubrechen. Die
    // Obergrenze zwingt sie zurück, der Text weicht mit Auslassungspunkten.
    final maxWidth = math.max(
      120.0,
      MediaQuery.sizeOf(context).width - AtemSpacing.screenPadding * 2 - 28,
    );

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      minTapSize: const Size(0, 48),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(color: AtemColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.labelMicro
                    .of(context)
                    .copyWith(color: color, letterSpacing: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Der gestrichelte Rand einer Lücke.
///
/// Als `Decoration` und nicht als Bild: Er muss jede Höhe mitmachen, und bei
/// 200 % Schrift ist eine Karte schnell dreimal so hoch.
class _DashedBorder extends Decoration {
  const _DashedBorder({required this.color});

  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DashedBorderPainter(color);
}

class _DashedBorderPainter extends BoxPainter {
  _DashedBorderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;

    final rect = offset & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      const Radius.circular(AtemRadii.card),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }
}
