import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/session_draft.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../../history/presentation/widgets/wellness_fields.dart';
import '../cardio_ui.dart';
import '../widgets/activity_sheet.dart';
import '../widgets/rpe_choice.dart';
import 'cardio_live_screen.dart';

/// Was die Live-Uhr dem Formular mitgibt.
class CardioPrefill {
  const CardioPrefill({
    required this.activity,
    required this.duration,
    this.distanceText = '',
  });

  final CardioActivity activity;

  /// Sekundengenau — aus der Uhr, nicht getippt.
  final Duration duration;
  final String distanceText;
}

/// Eine Ausdauereinheit erfassen — **der wichtigste Bildschirm des Moduls**
/// (Board 11, B2/1). Ohne ihn wächst der Bestand nicht.
///
/// ## Ein Formular für beide Wege
///
/// Nacherfassen ist der Regelfall — die Uhr hat schon getrackt. Die Live-Uhr
/// endet in **demselben** Formular, vorbefüllt. Es gibt nur eins.
///
/// ## Was Pflicht ist
///
/// Datum, Aktivität, Dauer. Die Distanz steht oben bei den dreien, ist aber
/// keine Pflicht: Sieben von 51 Einheiten im Bestand haben keine, und die
/// Entscheidung „Tempo als Eingabefeld" (Sektion J) sagt ausdrücklich: „Fehlt
/// die Distanz, bleibt Tempo „—" und die Einheit zählt trotzdem in Minuten."
/// Das Board nennt „vier Pflichtfelder" — die Entscheidung ist die genauere
/// Regel und gilt.
///
/// Tempo ist ein **Ausgabefeld**: cyan gerahmt, nicht tippbar, mit dem Wort
/// „gerechnet". Die Feldrezepte, der Fokusring und der Fehlertext kommen
/// unverändert aus Modul 7.
class CardioFormScreen extends ConsumerStatefulWidget {
  const CardioFormScreen({super.key, this.prefill});

  final CardioPrefill? prefill;

  @override
  ConsumerState<CardioFormScreen> createState() => _CardioFormScreenState();
}

class _CardioFormScreenState extends ConsumerState<CardioFormScreen> {
  late DateTime _date;
  CardioActivity? _activity;
  late final TextEditingController _distance;
  late final TextEditingController _duration;
  late final TextEditingController _avgHr;
  late final TextEditingController _maxHr;
  int? _rpe;
  int? _readiness;
  int? _feeling;

  /// Sekundengenaue Dauer aus der Uhr — gilt, solange das Feld unverändert
  /// ist. Wer die Minuten überschreibt, meint die Minuten.
  Duration? _preciseDuration;

  var _moreOpen = false;
  var _saving = false;
  var _dirty = false;
  var _showFaults = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final now = ref.read(historyReferenceProvider);
    _date = DateTime(now.year, now.month, now.day);
    final prefill = widget.prefill;
    _activity = prefill?.activity;
    _preciseDuration = prefill?.duration;
    _distance = TextEditingController(text: prefill?.distanceText ?? '');
    _duration = TextEditingController(
      text:
          prefill == null ? '' : '${(prefill.duration.inSeconds / 60).round()}',
    );
    _avgHr = TextEditingController();
    _maxHr = TextEditingController();
    if (prefill != null) _dirty = true;
  }

  @override
  void dispose() {
    _distance.dispose();
    _duration.dispose();
    _avgHr.dispose();
    _maxHr.dispose();
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  double? get _distanceKm {
    final raw = _distance.text.trim();
    if (raw.isEmpty) return null;
    final value = AtemNumberField.parse(raw);
    return value == null || value <= 0 ? null : value;
  }

  bool get _distanceInvalid =>
      _distance.text.trim().isNotEmpty && _distanceKm == null;

  Duration? get _durationValue {
    if (_preciseDuration != null) return _preciseDuration;
    final minutes = AtemNumberField.parse(_duration.text);
    if (minutes == null || minutes <= 0) return null;
    return Duration(milliseconds: (minutes * 60000).round());
  }

  int? _intOf(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return v == null || v <= 0 ? null : v;
  }

  /// Was noch fehlt — der Grund am gesperrten Knopf.
  int get _missing =>
      (_activity == null ? 1 : 0) +
      (_durationValue == null ? 1 : 0) +
      (_distanceInvalid ? 1 : 0);

  CardioTempo? get _tempo => CardioTempo.of(
        distanceKm: _distanceKm,
        duration: _durationValue,
        activity: _activity,
      );

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
    _touch();
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickActivity() async {
    final picked = await ActivitySheet.show(context);
    if (picked == null) return;
    _touch();
    setState(() => _activity = picked);
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

    final activity = _activity!;
    final draft = SessionDraft(
      userId: userId,
      kind: SessionKind.cardio,
      date: _date,
      duration: _durationValue!,
      durationHasSeconds: _preciseDuration != null,
      rpe: _rpe,
      preWorkoutReadiness: _readiness,
      postWorkoutFeeling: _feeling,
      activity: activity,
      distanceKm: _distanceKm,
      avgHr: _intOf(_avgHr),
      maxHr: _intOf(_maxHr),
    );

    try {
      final repository = ref.read(sessionRepositoryProvider);
      final id = await repository.saveSession(draft);
      if (!mounted) return;
      _dirty = false;
      // Das 30-Sekunden-Fenster aus Modul 7 gilt auch hier (Sektion I):
      // Rückgängig löscht die gerade gespeicherte Einheit wieder.
      final message = l10n.cardioSavedSnack(activityLabel(l10n, activity));
      ref.read(snackbarProvider.notifier).show(AtemSnack(
            message: message,
            semanticLabel: message,
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

  /// Wie viele Felder schon etwas tragen — für den Verlassen-Dialog.
  int get _filled =>
      (_activity == null ? 0 : 1) +
      (_distanceKm == null ? 0 : 1) +
      (_durationValue == null ? 0 : 1) +
      (_rpe == null ? 0 : 1) +
      (_readiness == null ? 0 : 1) +
      (_feeling == null ? 0 : 1) +
      (_intOf(_avgHr) == null ? 0 : 1) +
      (_intOf(_maxHr) == null ? 0 : 1);

  void _switchToLive() {
    // Dasselbe Formular am Ende — der Weg dorthin ersetzt diesen Bildschirm,
    // damit Zurück aus der Uhr nicht in ein leeres Formular führt.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const CardioLiveScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final today = ref.watch(historyReferenceProvider);
    final isToday = _date.year == today.year &&
        _date.month == today.month &&
        _date.day == today.day;
    final tempo = _tempo;

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
          // „✕ Ausdauer erfassen" — das Formular schliesst, es geht nicht
          // zurück (B2/1).
          leading: AtemTappable(
            onTap: () => Navigator.of(context).maybePop(),
            semanticLabel: l10n.commonClose,
            child: const Icon(Icons.close,
                size: 22, color: AtemColors.textPrimary),
          ),
          title: Text(l10n.cardioFormTitle,
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
                    // Nacherfassen | Live — nur ohne Vorbefüllung: Wer aus
                    // der Uhr kommt, hat den Weg schon hinter sich.
                    if (widget.prefill == null) ...[
                      AtemTabSwitch<bool>(
                        groupSemanticLabel: l10n.cardioFormTitle,
                        value: false,
                        onChanged: (live) {
                          if (live) _switchToLive();
                        },
                        segments: [
                          AtemTabSegment(value: false, label: l10n.formModeLog),
                          AtemTabSegment(value: true, label: l10n.formModeLive),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],

                    AtemCard.list(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AtemFieldLabel(label: l10n.formDate),
                          _PickField(
                            text: DateFormat.yMMMEd(tag).format(_date),
                            badge: isToday ? l10n.formToday : null,
                            icon: Icons.event,
                            semanticLabel:
                                '${l10n.formDate}: ${DateFormat.yMMMMEEEEd(tag).format(_date)}',
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 20),
                          AtemFieldLabel(label: l10n.formActivity),
                          _PickField(
                            text: _activity == null
                                ? l10n.commonSelect
                                : activityLabel(l10n, _activity),
                            icon: Icons.expand_more,
                            hasError: _showFaults && _activity == null,
                            errorText: _showFaults && _activity == null
                                ? l10n.formActivityRequired
                                : null,
                            semanticLabel: _activity == null
                                ? '${l10n.formActivity}: ${l10n.commonSelect}'
                                : '${l10n.formActivity}: ${activityLabel(l10n, _activity)}',
                            onTap: _pickActivity,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AtemFieldLabel(label: l10n.formDistance),
                                    AtemNumberField(
                                      controller: _distance,
                                      semanticLabel: l10n.formDistance,
                                      width: null,
                                      decimal: true,
                                      hasError: _showFaults && _distanceInvalid,
                                      onChanged: (_) {
                                        _touch();
                                        setState(() {});
                                      },
                                    ),
                                    if (_showFaults && _distanceInvalid) ...[
                                      const SizedBox(height: 6),
                                      Text(l10n.formDistanceInvalid,
                                          style: AtemType.meta
                                              .of(context)
                                              .copyWith(
                                                  color: AtemColors.magenta)),
                                    ],
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
                                      decimal: false,
                                      hasError:
                                          _showFaults && _durationValue == null,
                                      onChanged: (_) {
                                        _touch();
                                        // Getippt schlägt gemessen: Ab jetzt
                                        // gilt die Minutenzahl.
                                        _preciseDuration = null;
                                        setState(() {});
                                      },
                                    ),
                                    if (_showFaults &&
                                        _durationValue == null) ...[
                                      const SizedBox(height: 6),
                                      Text(l10n.formDurationRequired,
                                          style: AtemType.meta
                                              .of(context)
                                              .copyWith(
                                                  color: AtemColors.magenta)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TempoOutput(
                            tempo: tempo,
                            label: l10n.formPace,
                            note: l10n.formPaceComputed,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    // Die vier optionalen Felder in ihrer eigenen Karte,
                    // deren Kopf die Zahl nennt (B2/1).
                    AtemCard.list(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MoreSection(
                            open: _moreOpen,
                            count: 6,
                            onToggle: () =>
                                setState(() => _moreOpen = !_moreOpen),
                          ),
                          if (_moreOpen) ...[
                            const SizedBox(height: 16),
                            AtemFieldLabel(label: l10n.formRpe),
                            RpeChoice(
                              value: _rpe,
                              onChanged: (v) {
                                _touch();
                                setState(() => _rpe = v);
                              },
                            ),
                            const SizedBox(height: 20),
                            // Selbstauskunft. Beim Nacherfassen steht sie hier und
                            // nicht oben: Wer einen Lauf von vorgestern einträgt,
                            // erinnert Distanz und Dauer — nicht, wie bereit er war.
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AtemFieldLabel(label: l10n.formHrAvg),
                                      AtemNumberField(
                                        controller: _avgHr,
                                        semanticLabel: l10n.formHrAvg,
                                        width: null,
                                        onChanged: (_) {
                                          _touch();
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AtemFieldLabel(label: l10n.formHrMax),
                                      AtemNumberField(
                                        controller: _maxHr,
                                        semanticLabel: l10n.formHrMax,
                                        width: null,
                                        onChanged: (_) {
                                          _touch();
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.formHrHint,
                                style: AtemType.meta.of(context)),
                          ],
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
                      // Ein gesperrter Knopf trägt den Grund im Label:
                      // „Speichern, nicht möglich, noch 2 Angaben nötig".
                      semanticLabel: _missing == 0
                          ? l10n.commonSave
                          : '${l10n.commonSave}, ${l10n.exerciseSaveBlocked(_missing)}',
                      busy: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                    if (_missing > 0) ...[
                      const SizedBox(height: 6),
                      ExcludeSemantics(
                        child: Text(l10n.exerciseSaveBlocked(_missing),
                            style: AtemType.meta.of(context)),
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

/// Das Tempo als Ausgabefeld — **cyan gerahmt, nicht tippbar**.
///
/// Kein TextField-Fokus, damit die Tastatur nicht erscheint und niemand
/// hineinzutippen versucht (Sektion H). Ohne Distanz steht „—", vorgelesen
/// als „nicht erfasst".
class TempoOutput extends StatelessWidget {
  const TempoOutput({
    super.key,
    required this.tempo,
    required this.label,
    required this.note,
  });

  final CardioTempo? tempo;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final value =
        tempo == null ? l10n.intensityNoneValue : formatTempo(context, tempo!);

    return Semantics(
      label: tempo == null
          ? '$label, ${l10n.intensityNoneA11y}'
          : '$label $value, $note',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AtemColors.cyan.withValues(alpha: 0.06),
            borderRadius: AtemRadii.statBoxR,
            border: Border.all(color: AtemColors.cyan.withValues(alpha: 0.30)),
          ),
          // Wrap statt Row: „TEMPO 5:23 /km GERECHNET" ist bei 200 % Schrift
          // breiter als 320 dp. Dann bricht das Wort um, statt zu reissen.
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(label.toUpperCase(),
                  style: AtemType.labelMicro
                      .of(context)
                      .copyWith(color: AtemColors.cyan)),
              Text(value, style: AtemType.valueMedium.of(context)),
              Text(note.toUpperCase(), style: AtemType.labelMicro.of(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ein Feld, das man antippt statt hineinzutippen — Datum, Aktivität.
class _PickField extends StatelessWidget {
  const _PickField({
    required this.text,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.badge,
    this.hasError = false,
    this.errorText,
  });

  final String text;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final String? badge;
  final bool hasError;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtemTappable(
            onTap: onTap,
            semanticLabel: errorText == null
                ? semanticLabel
                : '$semanticLabel. $errorText',
            minTapSize: const Size(0, 48),
            alignment: Alignment.centerLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AtemColors.surfaceSolid,
                borderRadius: AtemRadii.statBoxR,
                border: Border.all(
                    color: hasError ? AtemColors.magenta : AtemColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(text, style: AtemType.body.of(context)),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    AtemBadge(label: badge!),
                  ],
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: AtemColors.textSecondary),
                ],
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Text(errorText!,
                  style: AtemType.meta
                      .of(context)
                      .copyWith(color: AtemColors.magenta)),
            ),
          ],
        ],
      );
}

/// „Optional · 4 Felder" — der Kopf nennt die Zahl, damit niemand raten
/// muss, was dort verborgen ist.
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
    final text = l10n.formOptionalCount(count);

    return AtemTappable(
      onTap: onToggle,
      semanticLabel: text,
      selected: open,
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: AtemType.labelUi.of(context)),
          ),
          const SizedBox(width: 8),
          Icon(open ? Icons.expand_less : Icons.expand_more,
              size: 20, color: AtemColors.textSecondary),
        ],
      ),
    );
  }
}
