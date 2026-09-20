import 'package:flutter/material.dart'
    show showModalBottomSheet, showDatePicker, Icons, DatePickerMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../application/weight_providers.dart';
import '../../domain/weight_entry.dart';
import '../../domain/weight_series.dart';
import '../weight_ui.dart';

/// Öffnet das Eingabeblatt für einen Gewichtswert (Board 14, B und C2).
///
/// Ohne [entry] ein neuer Eintrag für heute, mit [entry] die Bearbeitung.
Future<void> showWeightEntrySheet(
  BuildContext context,
  WidgetRef ref, {
  WeightEntry? entry,
}) {
  final l10n = AppL10n.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0x00000000),
    barrierColor: AtemOverlays.barrier(AtemOverlays.sheetBarrierOpacity),
    barrierLabel: l10n.stepPadClose,
    showDragHandle: false,
    builder: (_) => WeightEntrySheet(entry: entry),
  );
}

/// Das Blatt selbst. Öffentlich, damit Tests und die Sichtprüfung es ohne
/// Route pumpen können.
///
/// ## Was neu ist und was nicht
///
/// Getragen wird die Eingabe unverändert von [AtemStepPad] — Zahlenband,
/// Schrittkapseln, Tastatur-Umschalter. Neu ist **eine** Zeile: der
/// Datums-Chip. Im Runner stand „jetzt" nie zur Debatte; beim Gewicht ist
/// Nachtragen der häufigste Fall (Board 14, B).
class WeightEntrySheet extends ConsumerStatefulWidget {
  const WeightEntrySheet({super.key, this.entry});

  final WeightEntry? entry;

  @override
  ConsumerState<WeightEntrySheet> createState() => _WeightEntrySheetState();
}

class _WeightEntrySheetState extends ConsumerState<WeightEntrySheet> {
  /// Der Stichtag kommt aus dem Verlauf (`historyReferenceProvider`) — in
  /// Tests und Vorschauen setzbar, im Betrieb schlicht heute.
  late DateTime _date = widget.entry?.date ?? _today;

  DateTime get _today =>
      WeightEntry.dayOf(ref.read(historyReferenceProvider));

  bool get _isEdit => widget.entry != null;

  WeightSeries get _series =>
      ref.watch(weightSeriesProvider).value ?? WeightSeries.empty;

  /// Der Wert, mit dem das Band öffnet: was an diesem Tag steht, sonst der
  /// zuletzt bekannte. Nicht 0 — die meisten Änderungen sind klein.
  double? get _startValue =>
      _series.entryOn(_date)?.kg ?? _series.kgOn(_date) ?? _profileKg;

  double? get _profileKg => ref.watch(latestWeightProvider)?.kg;

  Future<void> _pickDate() async {
    final now = _today;
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      helpText: AppL10n.of(context).weightDatePick,
      initialDate: _date,
      // Kein Datum in der Zukunft: Ein Gewicht, das noch niemand gemessen
      // hat, ist keine Nachtragung, sondern ein Ziel — und Ziele hat dieser
      // Block bewusst nicht (Entscheidung 5).
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.day,
    );
    if (picked != null && mounted) {
      setState(() => _date = WeightEntry.dayOf(picked));
    }
  }

  Future<void> _save(double kg) async {
    final l10n = AppL10n.of(context);
    final navigator = Navigator.of(context);
    final existing = _series.entryOn(_date);
    final previous = widget.entry;

    // Die Herkunft wechselt nur, wenn sich die Zahl wirklich ändert
    // (Entscheidung 10): Ein unverändert bestätigter Messwert bleibt gemessen.
    final source = existing != null && (existing.kg - kg).abs() < 0.001
        ? existing.source
        : WeightSource.manual;

    final entry = WeightEntry(
      date: _date,
      kg: kg,
      source: source,
      externalId: source.isMeasured ? existing?.externalId : null,
    );

    // Ein verschobener Eintrag ist ein Umzug, kein zweiter: Der alte Tag muss
    // weg, sonst stünden zwei Punkte da, wo einer gemeint war.
    if (previous != null && previous.documentId != entry.documentId) {
      await ref.read(weightControllerProvider.notifier).delete(previous);
    }
    await ref.read(weightControllerProvider.notifier).save(entry);
    if (!mounted) return;

    final message = l10n.weightConfirmSnack(
      WeightUi.kg(context, kg),
      WeightUi.shortDate(context, _date),
    );
    ref.read(snackbarProvider.notifier).show(AtemSnack(
          message: message,
          semanticLabel: message,
          tone: AtemSnackTone.success,
          actionLabel: l10n.commonUndo,
          onAction: () => ref.read(weightControllerProvider.notifier).undo(),
        ));
    navigator.pop();
  }

  /// Löschen in zwei Stufen (Modul 2): Stufe 1 nennt die Folge, Stufe 2
  /// entscheidet. Kein Wisch-Gestus (Entscheidung 13).
  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null) return;
    final l10n = AppL10n.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await AtemDialog.show<bool>(
      context,
      kind: AtemDialogKind.destructive,
      title: l10n.weightDeleteTitle,
      message: l10n.weightDeleteBody(
        WeightUi.shortDate(context, entry.date),
        WeightUi.kg(context, entry.kg),
      ),
      confirmLabel: l10n.weightDeleteConfirm,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.weightDeleteTitle,
      onConfirm: () =>
          Navigator.of(context, rootNavigator: true).pop<bool>(true),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(weightControllerProvider.notifier).delete(entry);
    if (!mounted) return;

    final message =
        l10n.weightDeletedSnack(WeightUi.shortDate(context, entry.date));
    ref.read(snackbarProvider.notifier).show(AtemSnack(
          message: message,
          semanticLabel: message,
        ));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final today = _today;
    final isToday = _date == today;
    final existing = _series.entryOn(_date);
    final before = _series.kgOn(_date);
    final lastEntry = _series.latest;

    final start = _startValue;

    return AtemStepPad(
      // Der Schlüssel trägt Datum **und** Startwert. Das Datum, weil ein
      // Tageswechsel das Band neu bei dem Wert öffnen muss, der für diesen Tag
      // gilt — sonst stünde die Zahl des vorigen Tages über einem fremden
      // Datum. Der Startwert, weil die Reihe beim ersten Bild noch laden kann:
      // Ohne ihn im Schlüssel bliebe das Band auf seinem Rückfallwert stehen,
      // und „Aktualisieren" überschriebe einen gemessenen Wert mit 75 kg.
      key: ValueKey((_date, start)),
      field: AtemStepField.bodyWeight,
      value: start,
      previousValue: before,
      title: _isEdit ? l10n.weightSheetEditTitle : l10n.weightSheetTitle,
      applyLabel:
          existing != null ? l10n.weightUpdateCta : l10n.weightEnterCta,
      valueNote: lastEntry == null || _isEdit
          ? null
          : l10n.weightPadPrevious(
              WeightUi.kg(context, lastEntry.kg),
              today.difference(lastEntry.date).inDays.clamp(0, 99999),
            ),
      headline: _DateChip(
        label: isToday
            ? l10n.weightDateToday(WeightUi.shortDate(context, _date))
            : WeightUi.shortDate(context, _date),
        semanticLabel: l10n.weightDateChipA11y(
            WeightUi.shortDate(context, _date)),
        onTap: _pickDate,
      ),
      notice: existing != null && isToday && !_isEdit
          ? _SameDayNotice(kg: existing.kg)
          : null,
      footerBuilder: _date.isBefore(today)
          ? (context, value) => _RetroPreview(date: _date, candidateKg: value)
          : null,
      trailing: _isEdit
          ? AtemButton.ghost(
              label: l10n.weightDeleteEntry,
              semanticLabel: l10n.weightDeleteEntry,
              onPressed: _delete,
            )
          : null,
      onApply: _save,
    );
  }
}

/// Der Datums-Chip über dem Wert. Öffnet den Systemkalender — kein selbst
/// gebauter Picker (Entscheidung 9).
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: AtemTappable(
          onTap: onTap,
          semanticLabel: semanticLabel,
          minTapSize: const Size(44, 44),
          alignment: Alignment.centerLeft,
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AtemColors.textSecondary),
                const SizedBox(width: 6),
                Text(label, style: AtemType.meta.of(context)),
              ],
            ),
          ),
        ),
      );
}

/// B2 — „heute bereits erfasst". Informiert, blockiert nichts.
class _SameDayNotice extends StatelessWidget {
  const _SameDayNotice({required this.kg});

  final double kg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final text = l10n.weightSameDayNote(WeightUi.kg(context, kg));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AtemColors.card,
        borderRadius: BorderRadius.circular(AtemRadii.iconBox),
        border: Border.all(color: AtemColors.border),
      ),
      child: Text(text, style: AtemType.labelSmall.of(context)),
    );
  }
}

/// C2 — worauf ein rückwirkender Eintrag wirkt.
///
/// **Nur auf das betroffene Fenster** (Entscheidung 11): von diesem Eintrag
/// bis zum nächsten, nicht auf den ganzen Verlauf. Modul 7/8 rechnete jedes
/// Mal die gesamte Vergangenheit neu, weil es nur einen Wert gab; mit einer
/// Reihe gilt ein Eintrag nur bis zum nächsten.
class _RetroPreview extends ConsumerWidget {
  const _RetroPreview({required this.date, required this.candidateKg});

  final DateTime date;
  final double candidateKg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final series = ref.watch(weightSeriesProvider).value ?? WeightSeries.empty;
    final reference = ref.watch(historyReferenceProvider);
    final probe = WeightEntry(
        date: date, kg: candidateKg, source: WeightSource.manual);
    final (from, to) = WeightSeries.of([...series.entries, probe])
        .effectFor(probe, reference);

    final sets = _bodyweightSets(
        ref.watch(sessionsProvider).value ?? const [], from, to);
    final before = series.kgOn(date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AtemColors.card,
        borderRadius: BorderRadius.circular(AtemRadii.statBox),
        border: Border.all(color: AtemColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weightRetroTitle(WeightUi.shortDate(context, from),
                WeightUi.shortDate(context, to)),
            style: AtemType.labelMicro
                .of(context)
                .copyWith(color: AtemColors.cyan),
          ),
          const SizedBox(height: 4),
          Text(l10n.weightRetroScope, style: AtemType.labelMicro.of(context)),
          const SizedBox(height: 8),
          if (sets == 0)
            Text(l10n.weightRetroNone, style: AtemType.labelSmall.of(context))
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 7,
              runSpacing: 2,
              children: [
                Text(l10n.weightRetroSets(sets),
                    style: AtemType.labelSmall.of(context)),
                if (before != null)
                  Text(
                    '${WeightUi.kg(context, before)} → '
                    '${WeightUi.kg(context, candidateKg)}',
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(color: AtemColors.textTertiary),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Wie viele Eigengewichts-Sätze in der Spanne liegen — **der Nenner**.
  /// Ohne ihn sähe „wirkt auf 21. Jul – 27. Jul" nach viel aus, auch wenn in
  /// diesen Tagen niemand trainiert hat.
  static int _bodyweightSets(
    List<TrainingSession> sessions,
    DateTime from,
    DateTime to,
  ) {
    var count = 0;
    for (final session in sessions) {
      if (session is! StrengthSession) continue;
      final day = WeightEntry.dayOf(session.date);
      if (day.isBefore(from) || day.isAfter(to)) continue;
      for (final exercise in session.exercises) {
        if (exercise.usesBodyweight != true) continue;
        count += exercise.sets.length;
      }
    }
    return count;
  }
}
