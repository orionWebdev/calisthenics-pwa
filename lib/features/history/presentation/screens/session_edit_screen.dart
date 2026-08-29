import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/history_providers.dart';
import '../../domain/session_consequence.dart';
import '../../domain/session_patch.dart';
import '../../../cardio/presentation/screens/cardio_form_screen.dart';
import '../../domain/training_load.dart';
import '../../domain/training_session.dart';
import '../../../workout/domain/workout_start.dart';
import '../../../workout/presentation/screens/workout_runner_screen.dart';
import '../session_ui.dart';
import '../widgets/consequence_table.dart';

/// Eine absolvierte Einheit bearbeiten.
///
/// ## Was änderbar ist
///
/// Datum, Dauer, Notiz — und **Sätze nachtragen**. Nicht änderbar ist die Art
/// der Einheit: Aus einem Lauf eine Krafteinheit zu machen hiesse, Felder
/// zusammenzubringen, die nicht zusammenpassen.
///
/// Das Nachtragen betrifft einen echten Teil des Bestands: 16 der 63
/// Krafteinheiten tragen keine Übungen — vermutlich nachträglich ohne Details
/// eingetragen. Für sie gibt es einen Weg hinein; für Einheiten, die schon
/// Sätze haben, führt er in dieselbe Ansicht.
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
  late final TextEditingController _distance;
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
    final km = switch (widget.session) {
      CardioSession(:final distanceKm) => distanceKm,
      _ => null,
    };
    _distance = TextEditingController(text: km == null ? '' : '$km');
  }

  @override
  void dispose() {
    _duration.dispose();
    _notes.dispose();
    _distance.dispose();
    super.dispose();
  }

  CardioSession? get _cardio =>
      widget.session is CardioSession ? widget.session as CardioSession : null;

  double? get _distanceKm {
    final v = AtemNumberField.parse(_distance.text);
    return v == null || v <= 0 ? null : v;
  }

  Duration? get _durationValue {
    final minutes = int.tryParse(_duration.text.trim());
    return minutes == null || minutes <= 0 ? null : Duration(minutes: minutes);
  }

  void _touch() {
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  /// Öffnet den Runner auf dieser Einheit, damit Sätze nachgetragen werden
  /// können.
  ///
  /// **Kein zweiter Satzeditor.** Der Runner kann bereits alles, was dafür
  /// nötig ist: Übungen hinzufügen, Sätze anlegen, Werte eintragen, abhaken.
  /// Eine zweite Oberfläche für dieselbe Aufgabe wäre eine zweite Stelle, an
  /// der sich Fehler einnisten — und zwei Wahrheiten darüber, was ein Satz
  /// ist.
  Future<void> _openSets(BuildContext context) async {
    await Navigator.of(context, rootNavigator: true).pushNamed(
      WorkoutRunnerScreen.routeName,
      arguments: WorkoutStart.session(widget.session.id),
    );
  }

  Future<void> _pickDate() async {
    final now = ref.read(historyReferenceProvider);
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
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

  /// Wie viele der drei Felder überschrieben wurden.
  int get _changedCount {
    var count = 0;
    if (_date != widget.session.date) count++;
    if (widget.session.duration != null &&
        _durationValue != widget.session.duration) {
      count++;
    }
    final before = (widget.session.notes ?? '').trim();
    if (before.isNotEmpty && before != _notes.text.trim()) count++;
    return count;
  }

  /// Wie viele dazugekommen sind — Felder, die vorher leer waren.
  int get _addedCount {
    var count = 0;
    if (widget.session.duration == null && _durationValue != null) count++;
    if ((widget.session.notes ?? '').trim().isEmpty &&
        _notes.text.trim().isNotEmpty) {
      count++;
    }
    return count;
  }

  bool get _changed =>
      _date != widget.session.date ||
      _durationValue != widget.session.duration ||
      _notes.text.trim() != (widget.session.notes ?? '').trim() ||
      (_cardio != null && _distanceKm != _cardio!.distanceKm);

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
              // Nur bei Ausdauer: Distanz änderbar, Puls und RPE bleiben.
              cardio: _cardio == null
                  ? null
                  : CardioPatch(
                      distanceKm: _distanceKm,
                      avgHr: _cardio!.avgHr,
                      maxHr: _cardio!.maxHr,
                      rpe: _cardio!.rpe,
                    ),
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

                    AtemFieldLabel(label: l10n.sessionFieldDatetime),
                    _DateField(
                      date: _date,
                      languageTag: tag,
                      onTap: _pickDate,
                    ),
                    // „Vorher Di 08.07.2026 · +18 Tage" — sobald das Datum
                    // verschoben ist (Board 07, A5/2).
                    if (_date != widget.session.date) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n
                            .sessionDatePrevious(
                              _date.difference(widget.session.date).inDays,
                              DateFormat.yMEd(tag).format(widget.session.date),
                            )
                            .toUpperCase(),
                        style: AtemType.labelMicro.of(context),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Datumsänderung wird nicht verboten, sondern erklärt.
                    AtemNotice(
                      title: l10n.sessionDateAllowedTitle,
                      body: l10n.sessionDateAllowedBody,
                      semanticLabel:
                          '${l10n.sessionDateAllowedTitle}. ${l10n.sessionDateAllowedBody}',
                    ),
                    const SizedBox(height: 24),

                    // Die Art ist nicht änderbar — sie bestimmt, welche Werte
                    // unten stehen (Board 07, A5/1).
                    AtemFieldLabel(
                        label: l10n.sessionFieldKind,
                        hint: l10n.sessionKindNote),
                    Semantics(
                      label:
                          '${l10n.sessionFieldKind}: ${sessionKindLabel(l10n, widget.session)}',
                      child: ExcludeSemantics(
                        child: AtemBadge(
                          label:
                              sessionKindLabel(l10n, widget.session).toUpperCase(),
                          style: AtemType.labelSmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_cardio != null) ...[
                      AtemFieldLabel(label: l10n.formDistance),
                      AtemNumberField(
                        controller: _distance,
                        semanticLabel: l10n.formDistance,
                        width: null,
                        decimal: true,
                        onChanged: (_) {
                          _touch();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 10),
                      TempoOutput(
                        tempo: CardioTempo.of(
                          distanceKm: _distanceKm,
                          duration: _durationValue,
                          activity: _cardio!.activity,
                        ),
                        label: l10n.formPace,
                        note: l10n.formPaceComputed,
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.sessionPaceNote,
                          style: AtemType.labelMicro
                              .of(context)
                              .copyWith(letterSpacing: 0)),
                      const SizedBox(height: 24),
                    ],

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

                    const SizedBox(height: 24),
                    // Der Weg zu den Sätzen. Er steht **unter** den drei
                    // Feldern, weil das Nachtragen die seltenere Absicht ist
                    // — und über der Vorschau, weil er sie verändert.
                    if (widget.session is StrengthSession)
                      AtemButton.outline(
                        label: l10n.setsAdd,
                        semanticLabel: l10n.setsAdd,
                        leading: const Icon(Icons.add,
                            size: 18, color: AtemColors.cyan),
                        onPressed: () => _openSets(context),
                      ),

                    const SizedBox(height: 28),
                    AtemCard.list(
                      padding: const EdgeInsets.all(16),
                      child: ConsequenceTable(
                        // „Vorschau, noch nicht gespeichert." — der Satz
                        // unterscheidet die Rechnung von einer Tatsache.
                        note: l10n.sessionImpactPreview,
                        rows: ConsequenceTable.forEditing(
                          l10n,
                          consequence,
                          DateFormat.MMMM(tag).format(_date),
                          _date.year,
                          _date.month,
                        ),
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
