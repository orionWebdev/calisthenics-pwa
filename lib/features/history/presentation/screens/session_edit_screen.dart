import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/history_providers.dart';
import '../../domain/session_consequence.dart';
import '../../domain/session_patch.dart';
import '../../domain/training_load.dart';
import '../../domain/training_session.dart';
import '../session_ui.dart';
import '../widgets/consequence_table.dart';

/// Eine absolvierte Einheit bearbeiten.
///
/// ## Was änderbar ist
///
/// Datum, Dauer und Notiz. **Nicht** die Art der Einheit und nicht die Sätze:
/// Die Art zu ändern machte aus einem Lauf eine Krafteinheit mit Feldern, die
/// nicht zusammenpassen, und für einen Satzeditor liegt kein Entwurf vor. Er
/// gehört in ein eigenes Modul, nicht nebenbei hierher.
///
/// ## Das Datum darf sich ändern
///
/// Es verschiebt Lücken, Monatsstreifen und jede Kurve. Trotzdem ist es
/// änderbar, denn der häufigste Grund, eine Einheit zu bearbeiten, ist, dass
/// sie am falschen Tag steht — wer nachträglich erfasst, tippt sie heute ein
/// und meint vorgestern.
///
/// Was das anrichtet, steht darunter, **während** man tippt: Pause, Form und
/// Belastung mit ihrem Vorher und Nachher. Eine Sperre hätte den Normalfall
/// verboten, um eine Folge zu vermeiden, die sich auch anzeigen lässt.
class SessionEditScreen extends ConsumerStatefulWidget {
  const SessionEditScreen({super.key, required this.session});

  final TrainingSession session;

  @override
  ConsumerState<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends ConsumerState<SessionEditScreen> {
  late final TextEditingController _duration;
  late final TextEditingController _notes;
  late DateTime _date;

  var _saving = false;
  var _dirty = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _date = widget.session.date;
    _duration = TextEditingController(
      text: widget.session.duration?.inMinutes.toString() ?? '',
    );
    _notes = TextEditingController(text: widget.session.notes ?? '');
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

  void _touch() {
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  Future<void> _pickDate() async {
    final now = ref.read(historyReferenceProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // Die Vorgänger-App reicht bis 2023 zurück; ein Jahr Vorlauf lässt Raum
      // für eine Einheit, die versehentlich in der Zukunft gelandet ist.
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      // Der Material-Kalender ist nicht auf ATEM gestaltet — er ist aber
      // vollständig lokalisiert, bedienbar mit TalkBack und kennt jede
      // Kalenderbesonderheit. Ein eigener wäre ein Modul für sich.
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
    _touch();
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  bool get _changed =>
      _date != widget.session.date ||
      _durationValue != widget.session.duration ||
      _notes.text.trim() != (widget.session.notes ?? '').trim();

  Future<void> _save() async {
    final l10n = AppL10n.of(context);
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await ref.read(sessionRepositoryProvider).updateSession(
            widget.session.id,
            SessionPatch(
              date: _date,
              duration: _durationValue,
              notes: _notes.text,
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
    final tag = languageTag(context);

    // Die Folgen werden bei jedem Tastendruck neu gerechnet. Das ist eine
    // Rechnung über die gesamte Historie — bei 137 Einheiten unmerklich, und
    // sie ist der ganze Zweck des Bildschirms.
    final consequence = SessionConsequence.ofEditing(
      ref.watch(sessionsProvider).value ?? const [],
      widget.session.id,
      ref.watch(historyReferenceProvider),
      date: _date,
      duration: _durationValue,
      context: LoadContext(
        bodyWeightKg: ref.watch(bodyWeightProvider).value ?? 0,
      ),
    );

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
          title: Text(l10n.sessionEditTitle,
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
                    Text(sessionName(l10n, widget.session),
                        style: AtemType.titleMedium.of(context)),
                    const SizedBox(height: 24),

                    AtemFieldLabel(label: l10n.sessionEditDate),
                    _DateField(
                      date: _date,
                      languageTag: tag,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 24),

                    AtemFieldLabel(label: l10n.sessionEditDuration),
                    AtemNumberField(
                      controller: _duration,
                      semanticLabel: l10n.sessionEditDuration,
                      width: null,
                      suffix: l10n.commonMinutes,
                      onChanged: (_) {
                        _touch();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),

                    AtemFieldLabel(label: l10n.commonNotes),
                    AtemTextField(
                      controller: _notes,
                      semanticLabel: l10n.commonNotes,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => _touch(),
                    ),

                    const SizedBox(height: 28),
                    AtemCard.list(
                      padding: const EdgeInsets.all(16),
                      child: ConsequenceTable(consequence: consequence),
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
                              title: l10n.sessionEditSaveError,
                              body: _saveError!,
                              semanticLabel:
                                  '${l10n.sessionEditSaveError}. $_saveError',
                            ),
                    ),
                    AtemButton.gradient(
                      // Ohne Änderung sagt der Knopf, warum er nichts tut —
                      // statt still gesperrt dazustehen.
                      label: _changed
                          ? l10n.commonSave
                          : l10n.sessionEditNoChange,
                      semanticLabel: _changed
                          ? l10n.commonSave
                          : l10n.sessionEditNoChange,
                      busy: _saving,
                      onPressed: _saving || !_changed ? null : _save,
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

/// Das Datum als antippbare Fläche.
///
/// Kein Eingabefeld: Ein Datum getippt einzugeben heißt, ein Format zu erraten.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.languageTag,
    required this.onTap,
  });

  final DateTime date;
  final String languageTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final text = DateFormat.yMMMMEEEEd(languageTag).format(date);

    return AtemTappable(
      onTap: onTap,
      semanticLabel: l10n.sessionEditDateA11y(text),
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AtemColors.surfaceSolid,
          borderRadius: AtemRadii.statBoxR,
          border: Border.all(color: AtemColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, size: 18, color: AtemColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: AtemType.body.of(context)),
            ),
          ],
        ),
      ),
    );
  }
}
