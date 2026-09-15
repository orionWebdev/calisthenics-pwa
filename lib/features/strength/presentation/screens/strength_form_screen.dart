import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../cardio/presentation/widgets/rpe_choice.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/session_draft.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../../history/presentation/widgets/wellness_fields.dart';

/// Eine Krafteinheit **ohne Sätze** erfassen.
///
/// ## Warum es diesen Bildschirm gibt
///
/// 16 der 63 Krafteinheiten im Bestand tragen keine einzige Übung. Sie sind
/// gültiger Bestand — nachträglich eingetragen, ohne Detail-Loggen. Die App
/// konnte so etwas bisher **lesen, aber nicht schreiben**: Der Runner verwirft
/// eine Einheit ohne abgehakten Satz (`toDraft` gibt `null` zurück), und
/// nichts anderes legt Krafteinheiten an.
///
/// Damit war `workoutFocus` ein Feld ohne Weg hinein. Dieser Bildschirm ist
/// der Weg.
///
/// ## Was Pflicht ist
///
/// Datum, Dauer, Fokus — dieselbe Regel wie beim Regenerationsblatt, das Art
/// und Dauer verlangt. Der Fokus ist Pflicht, weil er der einzige Grund für
/// diesen Bildschirm ist: Eine Einheit ohne Sätze **und** ohne Fokus sagt nur,
/// dass es sie gab, und davon hat der Bestand schon genug.
///
/// ## Was er ausdrücklich nicht tut
///
/// Er erfindet kein Volumen. Eine so erfasste Einheit zählt in Minuten und
/// erscheint in **keiner** Muskelverteilung — der Hinweis oben sagt das,
/// bevor jemand tippt, nicht erst in der Auswertung.
class StrengthFormScreen extends ConsumerStatefulWidget {
  const StrengthFormScreen({super.key});

  @override
  ConsumerState<StrengthFormScreen> createState() => _StrengthFormScreenState();
}

class _StrengthFormScreenState extends ConsumerState<StrengthFormScreen> {
  late DateTime _date;
  final _duration = TextEditingController();
  final _notes = TextEditingController();

  WorkoutFocus? _focus;
  int? _rpe;
  int? _readiness;
  int? _feeling;

  var _dirty = false;
  var _saving = false;
  var _showFaults = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _touch() => _dirty = true;

  Duration? get _durationValue {
    final minutes = int.tryParse(_duration.text.trim());
    if (minutes == null || minutes <= 0) return null;
    return Duration(minutes: minutes);
  }

  /// Wie viele Pflichtangaben noch fehlen — der Grund im Label des Knopfes.
  int get _missing =>
      (_durationValue == null ? 1 : 0) + (_focus == null ? 1 : 0);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    _touch();
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  /// Wie viele Felder schon etwas tragen — für den Verlassen-Dialog.
  int get _filled =>
      (_durationValue == null ? 0 : 1) +
      (_focus == null ? 0 : 1) +
      (_rpe == null ? 0 : 1) +
      (_readiness == null ? 0 : 1) +
      (_feeling == null ? 0 : 1) +
      (_notes.text.trim().isEmpty ? 0 : 1);

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = AppL10n.of(context);
    final choice = await AtemUnsavedDialog.show(
      context,
      title: l10n.unsavedTitle,
      message: l10n.unsavedBody(0, _filled),
      saveLabel: l10n.unsavedSave,
      discardLabel: l10n.unsavedDiscard,
      keepLabel: l10n.unsavedContinue,
    );
    switch (choice) {
      case AtemUnsavedChoice.save:
        await _save();
        return false;
      case AtemUnsavedChoice.discard:
        return true;
      case AtemUnsavedChoice.keepEditing:
      case null:
        return false;
    }
  }

  Future<void> _save() async {
    final l10n = AppL10n.of(context);
    if (_missing > 0) {
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
      final repository = ref.read(sessionRepositoryProvider);
      final id = await repository.saveSession(SessionDraft(
        userId: userId,
        kind: SessionKind.strength,
        date: _date,
        duration: _durationValue!,
        notes: _notes.text,
        workoutFocus: _focus,
        rpe: _rpe,
        preWorkoutReadiness: _readiness,
        postWorkoutFeeling: _feeling,
      ));
      if (!mounted) return;
      ref.read(snackbarProvider.notifier).show(AtemSnack(
            message: l10n.strengthSavedSnack,
            semanticLabel: l10n.strengthSavedSnack,
            tone: AtemSnackTone.success,
            actionLabel: l10n.commonUndo,
            onAction: () => repository.deleteSession(id),
          ));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = l10n.exerciseFormSaveErrorBody;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AtemColors.base,
        appBar: AppBar(
          backgroundColor: AtemColors.base,
          leading: AtemTappable(
            onTap: () => Navigator.of(context).maybePop(),
            semanticLabel: l10n.commonClose,
            child: const Icon(Icons.close,
                size: 22, color: AtemColors.textPrimary),
          ),
          title: Text(l10n.strengthFormTitle,
              style: AtemType.titleMedium.of(context)),
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
                    // **Vor der ersten Eingabe, nicht in der Auswertung.**
                    AtemNotice(
                      tone: AtemNoticeTone.neutral,
                      title: l10n.strengthFormTitle,
                      body: l10n.strengthFormNoSets,
                      semanticLabel: l10n.strengthFormNoSets,
                    ),
                    const SizedBox(height: 20),
                    AtemCard.list(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AtemFieldLabel(label: l10n.formDate),
                          AtemTappable(
                            onTap: _pickDate,
                            semanticLabel: '${l10n.formDate}, '
                                '${DateFormat.yMMMEd(tag).format(_date)}',
                            child: AtemStatBox(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat.yMMMEd(tag).format(_date),
                                      style: AtemType.labelSmall
                                          .of(context)
                                          .copyWith(
                                              color: AtemColors.textPrimary),
                                    ),
                                  ),
                                  const Icon(Icons.event,
                                      size: 18,
                                      color: AtemColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AtemFieldLabel(label: l10n.formDuration),
                          AtemNumberField(
                            controller: _duration,
                            semanticLabel: l10n.formDuration,
                            width: null,
                            suffix: l10n.commonMinutes,
                            hasError: _showFaults && _durationValue == null,
                            onChanged: (_) {
                              _touch();
                              setState(() {});
                            },
                          ),
                          if (_showFaults && _durationValue == null) ...[
                            const SizedBox(height: 6),
                            Text(l10n.formDurationRequired,
                                style: AtemType.labelMicro.of(context).copyWith(
                                    color: AtemColors.magenta,
                                    letterSpacing: 0)),
                          ],
                          const SizedBox(height: 20),
                          AtemFieldLabel(label: l10n.formFocus),
                          FocusChoice(
                            value: _focus,
                            onChanged: (v) {
                              _touch();
                              setState(() => _focus = v);
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(l10n.formFocusHint,
                              style: AtemType.labelMicro
                                  .of(context)
                                  .copyWith(letterSpacing: 0)),
                          const SizedBox(height: 20),
                          AtemFieldLabel(label: l10n.formRpe),
                          RpeChoice(
                            value: _rpe,
                            onChanged: (v) {
                              _touch();
                              setState(() => _rpe = v);
                            },
                          ),
                          const SizedBox(height: 20),
                          AtemFieldLabel(label: l10n.formReadiness),
                          ReadinessChoice(
                            value: _readiness,
                            surface: AtemColors.surfaceSolid,
                            onChanged: (v) {
                              _touch();
                              setState(() => _readiness = v);
                            },
                          ),
                          const SizedBox(height: 20),
                          AtemFieldLabel(label: l10n.formFeeling),
                          FeelingChoice(
                            value: _feeling,
                            surface: AtemColors.surfaceSolid,
                            onChanged: (v) {
                              _touch();
                              setState(() => _feeling = v);
                            },
                          ),
                          const SizedBox(height: 20),
                          AtemFieldLabel(label: l10n.formNote),
                          AtemTextField(
                            controller: _notes,
                            semanticLabel: l10n.formNote,
                            maxLines: null,
                            textInputAction: TextInputAction.newline,
                            onChanged: (_) => _touch(),
                          ),
                        ],
                      ),
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
                              title: l10n.errorsSaveFailed,
                              body: _saveError!,
                              semanticLabel:
                                  '${l10n.errorsSaveFailed}. $_saveError',
                              actionLabel: l10n.commonRetrySave,
                              onAction: _save,
                            ),
                    ),
                    AtemButton.gradient(
                      label: l10n.commonSave,
                      // Ein gesperrter Knopf trägt den Grund im Label.
                      semanticLabel: _missing == 0
                          ? l10n.commonSave
                          : '${l10n.commonSave}, '
                              '${l10n.exerciseSaveBlocked(_missing)}',
                      busy: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                    if (_missing > 0) ...[
                      const SizedBox(height: 6),
                      ExcludeSemantics(
                        child: Text(
                          l10n.exerciseSaveBlocked(_missing),
                          textAlign: TextAlign.center,
                          style: AtemType.labelMicro
                              .of(context)
                              .copyWith(letterSpacing: 0),
                        ),
                      ),
                    ],
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
