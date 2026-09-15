import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../cardio/presentation/cardio_ui.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/session_draft.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../../history/presentation/widgets/wellness_fields.dart';

/// Regeneration erfassen — **vier Felder, keine Distanz, keine Intensität**
/// (Board 11, C2/2). Elf von zwölf Einheiten im Bestand tragen ohnehin nur
/// Datum und Dauer.
///
/// Die Hinweiszeile steht im Formular, nicht erst im Verlauf: Der Widerspruch
/// „frische Einheit, fallender Formwert" wird dort erklärt, wo er entsteht.
abstract final class RecoverySheet {
  static Future<bool?> show(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemSheet.show<bool>(
      context,
      title: l10n.recoveryFormTitle,
      closeLabel: l10n.commonClose,
      child: const _Body(),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body();

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  RecoveryKind? _kind;
  int? _readiness;
  int? _feeling;
  late DateTime _date;
  final _duration = TextEditingController();
  final _notes = TextEditingController();
  var _saving = false;
  var _showFaults = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = ref.read(historyReferenceProvider);
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  Duration? get _durationValue {
    final minutes = int.tryParse(_duration.text.trim());
    return minutes == null || minutes <= 0 ? null : Duration(minutes: minutes);
  }

  int get _missing => (_kind == null ? 1 : 0) + (_durationValue == null ? 1 : 0);

  Future<void> _pickDate() async {
    final now = ref.read(historyReferenceProvider);
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            surface: AtemColors.card,
            primary: AtemColors.cyan,
            onPrimary: AtemColors.base,
            onSurface: AtemColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
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
      _error = null;
    });
    try {
      final repository = ref.read(sessionRepositoryProvider);
      final id = await repository.saveSession(SessionDraft(
        userId: userId,
        kind: SessionKind.recovery,
        date: _date,
        duration: _durationValue!,
        notes: _notes.text,
        recoveryKind: _kind,
        preWorkoutReadiness: _readiness,
        postWorkoutFeeling: _feeling,
      ));
      if (!mounted) return;
      ref.read(snackbarProvider.notifier).show(AtemSnack(
            message: l10n.recoverySavedSnack,
            semanticLabel: l10n.recoverySavedSnack,
            tone: AtemSnackTone.success,
            actionLabel: l10n.commonUndo,
            onAction: () => repository.deleteSession(id),
          ));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.exerciseFormSaveErrorBody;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AtemFieldLabel(label: l10n.formKind),
        Semantics(
          container: true,
          label: l10n.formKind,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in RecoveryKind.values)
                _KindCapsule(
                  label: recoveryKindName(l10n, kind),
                  selected: kind == _kind,
                  hasError: _showFaults && _kind == null,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
        ),
        if (_showFaults && _kind == null) ...[
          const SizedBox(height: 6),
          Text(l10n.formActivityRequired,
              style: AtemType.meta
                  .of(context)
                  .copyWith(color: AtemColors.magenta)),
        ],
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AtemFieldLabel(label: l10n.formDate),
                  AtemTappable(
                    onTap: _pickDate,
                    semanticLabel:
                        '${l10n.formDate}: ${DateFormat.yMMMMEEEEd(tag).format(_date)}',
                    minTapSize: const Size(0, 48),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                      decoration: BoxDecoration(
                        color: AtemColors.surfaceSolid,
                        borderRadius: AtemRadii.statBoxR,
                        border: Border.all(color: AtemColors.border),
                      ),
                      child: Text(DateFormat.MMMEd(tag).format(_date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtemType.body.of(context)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AtemFieldLabel(label: l10n.formDuration),
                  AtemNumberField(
                    controller: _duration,
                    semanticLabel: l10n.formDuration,
                    width: null,
                    hasError: _showFaults && _durationValue == null,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_showFaults && _durationValue == null) ...[
                    const SizedBox(height: 6),
                    Text(l10n.formDurationRequired,
                        style: AtemType.meta
                            .of(context)
                            .copyWith(color: AtemColors.magenta)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Freiwillig, wie überall. Regeneration trägt keine Last — aber wie
        // man vorher und nachher dastand, ist genau hier eine Angabe wert.
        AtemFieldLabel(label: l10n.formReadiness),
        ReadinessChoice(
          value: _readiness,
          onChanged: (v) => setState(() => _readiness = v),
        ),
        const SizedBox(height: 18),
        AtemFieldLabel(label: l10n.formFeeling),
        FeelingChoice(
          value: _feeling,
          onChanged: (v) => setState(() => _feeling = v),
        ),
        const SizedBox(height: 18),
        AtemFieldLabel(label: l10n.formNote),
        AtemTextField(
          controller: _notes,
          semanticLabel: l10n.formNote,
          maxLines: 2,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 14),
        Semantics(
          label: l10n.recoveryNoload,
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AtemColors.border),
                  ),
                  child: Text('i',
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0, height: 1)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.recoveryNoload,
                      style: AtemType.labelSmall.of(context)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AtemNoticeSlot(
          notice: _error == null
              ? null
              : AtemNotice(
                  tone: AtemNoticeTone.error,
                  title: l10n.errorsSaveFailed,
                  body: _error!,
                  semanticLabel: '${l10n.errorsSaveFailed}. $_error',
                ),
        ),
        AtemButton.gradient(
          label: l10n.commonSave,
          semanticLabel: _missing == 0
              ? l10n.commonSave
              : '${l10n.commonSave}, ${l10n.exerciseSaveBlocked(_missing)}',
          busy: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

/// Die Artkapsel: 40 dp sichtbar, 48 dp Ziel, gewählt Lime bei 10 % mit
/// Rand bei 35 % — das eine Mal, dass Lime eine Fläche sein darf: eine
/// gewählte Regenerationsart ist keine Zeile, sondern eine Auswahl.
class _KindCapsule extends StatelessWidget {
  const _KindCapsule({
    required this.label,
    required this.selected,
    required this.hasError,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: onTap,
        semanticLabel: label,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        minTapSize: const Size(48, 48),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AtemColors.green.withValues(alpha: 0.10)
                : AtemColors.card,
            borderRadius: BorderRadius.circular(AtemRadii.statBox),
            border: Border.all(
              color: selected
                  ? AtemColors.green.withValues(alpha: 0.35)
                  : (hasError ? AtemColors.magenta : AtemColors.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 14, color: AtemColors.green),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: AtemType.labelSmall.of(context).copyWith(
                        color: selected
                            ? AtemColors.green
                            : AtemColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      )),
            ],
          ),
        ),
      );
}
