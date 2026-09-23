import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../plans/application/plan_providers.dart';
import '../../../plans/domain/plan.dart';
import '../../application/training_goal_providers.dart';
import '../../application/week_plan_providers.dart';
import '../../domain/training_goal.dart';
import '../../domain/week_plan.dart';
import '../briefing_ui.dart';
import '../week_ui.dart';
import '../widgets/week_entry_sheet.dart';
import 'training_goal_screen.dart';

/// Die Woche von Hand (Board 19).
///
/// ## Sieben Tage untereinander
///
/// Eine Liste bricht bei 200 % nie; Spalten schon bei 100 % nicht — sieben
/// 48-dp-Ziele brauchen 384 dp, eine Karte bietet 290 (Entscheidung F1).
/// Senkrecht trägt jede Anzahl Einträge je Tag: Der zweite Eintrag eines
/// Tages ist eine Zeile mehr, keine halbe Spalte.
///
/// ## Jede Handlung ist sofort geschrieben
///
/// Kein Speichern-Knopf auf der Seite. Anlegen am Plus des Tages,
/// Verschieben per Tipp im Blatt, per Ziehen oder per Screenreader-Aktion,
/// Entfernen im Blatt — alles mit Rückgängig. Eine Ablehnung steht am Tag,
/// nicht in einem Toast.
///
/// ## Plan und Ist nebeneinander, nie abgeglichen
///
/// „Trainiert · Lauf, 35 Min" steht unter dem Tag, auch wenn der Plan Kraft
/// sagte. Ein geplanter, nicht trainierter Tag sieht aus wie ein künftiger:
/// kein Grau, kein Wort, kein „verpasst" (Entscheidung F4).
///
/// ## Abweichungen vom Board, mit Grund
///
/// - Das Blatt ist das gemeinsame `AtemSheet`; sein Verdunkler blurrt
///   (Board 19, Entscheidung 16: ohne Blur). Ein zweites Blatt nur für diese
///   Seite wäre eine zweite Fassung desselben Bausteins.
/// - Metazeilen in `meta` (13 sp) statt Mono 11 — Text ≥ 12 sp.
/// - Das Verschieben fliegt nicht (FLIP): Der Eintrag erscheint am Zieltag
///   mit Eintritt und Speicher-Scan, der Ursprung schliesst.
class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key, this.today});

  /// Für Tests und Renderbilder; sonst der heutige Tag.
  final DateTime? today;

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  /// Welche Woche gezeigt wird — bei Wechselwochen wählbar, sonst A.
  WeekSide? _view;

  /// Der Tag, über dem gerade ein gezogener Eintrag schwebt.
  int? _dragOver;

  DateTime get _today => widget.today ?? DateTime.now();

  WeekPlanController get _ctrl =>
      ref.read(weekPlanControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final words = WeekWords(context);
    final async = ref.watch(weekPlanProvider);
    final goal = ref.watch(trainingGoalProvider).value ?? TrainingGoal.empty;
    final plans = ref.watch(plansProvider).value ?? const <Plan>[];
    final sessions =
        ref.watch(sessionsProvider).value ?? const <TrainingSession>[];
    final activity = ref.watch(weekPlanControllerProvider);

    ref.listen(weekPlanControllerProvider, (prev, next) {
      final error = next.error;
      if (error == null || prev?.error == error) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        _errorText(words, error, ref.read(weekPlanProvider).value, plans),
        Directionality.of(context),
        assertiveness: Assertiveness.assertive,
      );
    });

    final week = async.isLoading || async.hasError ? null : async.value;
    final alternating = goal.weekPattern == WeekPattern.alternating;
    final todaySide = weekSideOn(_today, goal);
    final side = alternating ? (_view ?? todaySide) : WeekSide.a;
    final isCurrent = side == todaySide;

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: AtemSubpageScaffold(
        kicker: l10n.weekPlace,
        backLabel: l10n.commonBack,
        tone: AtemColors.tabHybrid,
        title: Text(
          l10n.weekTitle,
          style: AtemType.titleLarge.of(context).copyWith(fontSize: 22),
        ),
        below: [
          const SizedBox(height: 4),
          Text(
            alternating ? l10n.weekSubAlternating : l10n.weekSub,
            style: AtemType.meta.of(context),
          ),
          if (week?.updatedAt != null && !week!.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.weekEdited(words.briefing.date(week.updatedAt!)),
              style: AtemType.meta.of(context),
            ),
          ],
        ],
        children: [
          if (async.hasError)
            AtemErrorState(
              title: l10n.weekErrLoad,
              body: l10n.weekErrLoadSub,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(weekPlanProvider),
            )
          else if (week == null)
            AtemSkeleton(
              semanticLabel: l10n.commonLoading,
              blocks: const [
                AtemSkeletonBlock(height: 64, radius: 16),
                AtemSkeletonBlock(height: 360),
              ],
            )
          else ...[
            _BriefRow(goal: goal),
            if (alternating) ...[
              const SizedBox(height: 12),
              _AbSwitch(
                side: side,
                todaySide: todaySide,
                kw: isoWeek(_today),
                onChanged: (s) => setState(() => _view = s),
              ),
            ],
            const SizedBox(height: 12),
            _weekCard(context, words, week, side, isCurrent, plans, sessions,
                activity),
            if (!alternating && week.b.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.weekAbInactive, style: AtemType.meta.of(context)),
            ],
            if (isCurrent)
              _SoFar(
                week: week,
                side: side,
                sessions: sessionsThisWeek(sessions, _today),
                kw: isoWeek(_today),
              ),
            _footer(context, l10n, week, side),
          ],
        ],
      ),
    );
  }

  // --- Die Wochenkarte -----------------------------------------------------

  Widget _weekCard(
    BuildContext context,
    WeekWords words,
    WeekPlan week,
    WeekSide side,
    bool isCurrent,
    List<Plan> plans,
    List<TrainingSession> sessions,
    WeekActivity activity,
  ) {
    final l10n = words.l10n;
    final facts = isCurrent ? sessionsThisWeek(sessions, _today) : const {};
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: AtemColors.card,
        borderRadius: AtemRadii.cardR,
        border: Border.all(color: AtemColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            week.b.isNotEmpty || side == WeekSide.b
                ? l10n.weekHeadAb(side.name.toUpperCase())
                : l10n.weekHead,
            style: AtemType.labelMicro.of(context),
          ),
          const SizedBox(height: 4),
          for (final (i, d) in WeekWords.weekdays.indexed) ...[
            if (i > 0) Container(height: 1, color: AtemColors.border),
            _day(context, words, week, side, d,
                isToday: isCurrent && d == _today.weekday,
                facts: facts[d] as List<TrainingSession>? ?? const [],
                plans: plans,
                activity: activity),
          ],
        ],
      ),
    );
  }

  Widget _day(
    BuildContext context,
    WeekWords words,
    WeekPlan week,
    WeekSide side,
    int weekday, {
    required bool isToday,
    required List<TrainingSession> facts,
    required List<Plan> plans,
    required WeekActivity activity,
  }) {
    final l10n = words.l10n;
    final entries = week.day(side, weekday);
    final dayName = words.dayLong(weekday);
    final count = entries.isEmpty
        ? l10n.todayStripNone
        : l10n.weekEntries(entries.length);
    final error = activity.error;
    final errorHere =
        error != null && error.side == side && error.weekday == weekday;

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) {
        final e = week.of(side)[d.data];
        if (e == null || e.weekday == weekday) return false;
        if (e.kind == WeekKind.off && entries.isNotEmpty) return false;
        setState(() => _dragOver = weekday);
        return true;
      },
      onLeave: (_) => setState(() => _dragOver = null),
      onAcceptWithDetails: (d) {
        setState(() => _dragOver = null);
        final e = week.of(side)[d.data];
        if (e != null) _move(words, side, e, weekday, plans);
      },
      builder: (context, candidates, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    container: true,
                    label: isToday
                        ? l10n.weekDayTodayA11y(dayName, count)
                        : l10n.weekDayA11y(dayName, count),
                    child: ExcludeSemantics(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: AtemType.titleMedium
                                .of(context)
                                .copyWith(fontSize: 14),
                          ),
                          if (isToday) const _TodayBadge(),
                        ],
                      ),
                    ),
                  ),
                ),
                _PlusButton(
                  label: l10n.weekAddA11y(dayName),
                  onTap: () => _add(words, side, weekday, week, plans),
                ),
              ],
            ),
            for (final e in entries) ...[
              const SizedBox(height: 8),
              _entry(context, words, week, side, e, plans, activity),
            ],
            if (_dragOver == weekday && candidates.isNotEmpty)
              const _DropLine(),
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 8),
              _FactLine(text: words.fact(facts)),
            ],
            if (errorHere)
              _DayError(
                text: _errorText(words, error, week, plans),
                retry: () {
                  _ctrl.dismissError();
                  error.retry();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _entry(
    BuildContext context,
    WeekWords words,
    WeekPlan week,
    WeekSide side,
    WeekEntry e,
    List<Plan> plans,
    WeekActivity activity,
  ) {
    final l10n = words.l10n;
    final title = words.title(e, plans);
    final meta = words.meta(e, plans);
    final note = words.deletedNote(e, plans);
    final day = e.weekday;
    final row = _EntryRow(
      kind: e.kind,
      title: title,
      meta: meta,
      note: note,
    );

    // **Verschieben ohne Ziehen**: jede andere Tag, früher, später, ändern
    // und entfernen als Screenreader-Aktionen (Board 19, I). Jede Aktion
    // schreibt direkt, ohne Blatt.
    final actions = <CustomSemanticsAction, VoidCallback>{
      for (final d in WeekWords.weekdays)
        if (d != day)
          CustomSemanticsAction(label: l10n.weekEntryMoveTo(words.dayLong(d))):
              () => _move(words, side, e, d, plans),
      if (day > 1)
        CustomSemanticsAction(label: l10n.weekEntryEarlier): () =>
            _move(words, side, e, day - 1, plans),
      if (day < 7)
        CustomSemanticsAction(label: l10n.weekEntryLater): () =>
            _move(words, side, e, day + 1, plans),
      CustomSemanticsAction(label: l10n.weekEntryEdit): () =>
          _edit(words, side, e, week, plans),
      CustomSemanticsAction(label: l10n.weekSheetRemove): () =>
          _remove(words, side, e, plans),
    };

    final tappable = Semantics(
      container: true,
      customSemanticsActions: actions,
      child: AtemTappable(
        semanticLabel: l10n.weekEntryA11y(title, meta, words.dayLong(day)),
        onTap: () => _edit(words, side, e, week, plans),
        child: row,
      ),
    );

    return AtemEntrance(
      key: ValueKey('entry-${e.id}'),
      child: AtemSaveScan(
        trigger: activity.savedEntryId == e.id ? activity.tick : null,
        child: LongPressDraggable<String>(
          data: e.id,
          delay: const Duration(milliseconds: 400),
          hapticFeedbackOnStart: true,
          feedback: _DragGhost(child: row),
          childWhenDragging: Opacity(opacity: 0.35, child: row),
          onDragStarted: () => SemanticsService.sendAnnouncement(
            View.of(context),
            l10n.weekDragLifted(title, words.dayLong(day)),
            Directionality.of(context),
          ),
          child: tappable,
        ),
      ),
    );
  }

  // --- Handlungen ----------------------------------------------------------

  Future<void> _add(WeekWords words, WeekSide side, int weekday,
      WeekPlan week, List<Plan> plans) async {
    final result = await WeekEntrySheet.show(
      context,
      weekday: weekday,
      plans: plans,
      dayHasOtherEntries: week.day(side, weekday).isNotEmpty,
    );
    if (result is! WeekSheetSaved || !mounted) return;
    final before = _ctrl.current;
    final WeekChange change;
    try {
      change = before.add(side, result.entry);
    } on StateError {
      return;
    }
    final entry = result.entry;
    final replaced = [
      for (final e in before.day(side, weekday))
        if (e.kind == WeekKind.off) e.id,
    ];
    _ctrl.apply(
      change,
      savedEntryId: entry.id,
      failure: (retry) => WeekSaveError(
        side: side,
        weekday: weekday,
        kind: WeekFailure.add,
        entryId: entry.id,
        retry: retry,
      ),
    );
    final title = words.title(entry, plans);
    final day = words.dayLong(weekday);
    _snack(
      change.replacedOff
          ? words.l10n.weekSnackAddedReplaced(title, day)
          : words.l10n.weekSnackAdded(title, day),
      () => _undo(side, before, [entry.id, ...replaced]),
    );
  }

  Future<void> _edit(WeekWords words, WeekSide side, WeekEntry e,
      WeekPlan week, List<Plan> plans) async {
    final result = await WeekEntrySheet.show(
      context,
      weekday: e.weekday,
      plans: plans,
      entry: e,
      dayHasOtherEntries: week.day(side, e.weekday).any((x) => x.id != e.id),
    );
    if (!mounted) return;
    switch (result) {
      case WeekSheetSaved(:final entry):
        final before = _ctrl.current;
        _ctrl.apply(
          before.edit(side, entry),
          savedEntryId: entry.id,
          failure: (retry) => WeekSaveError(
            side: side,
            weekday: entry.weekday,
            kind: WeekFailure.edit,
            entryId: entry.id,
            retry: retry,
          ),
        );
      case WeekSheetMoved(:final weekday):
        _move(words, side, e, weekday, plans);
      case WeekSheetRemoved():
        _remove(words, side, e, plans);
      case null:
        break;
    }
  }

  void _move(WeekWords words, WeekSide side, WeekEntry e, int weekday,
      List<Plan> plans) {
    final before = _ctrl.current;
    final WeekChange change;
    try {
      change = before.move(side, e.id, weekday);
    } on StateError {
      return;
    }
    if (change.writes.isEmpty) return;
    final replaced = [
      for (final x in before.day(side, weekday))
        if (x.kind == WeekKind.off) x.id,
    ];
    _ctrl.apply(
      change,
      savedEntryId: e.id,
      failure: (retry) => WeekSaveError(
        side: side,
        weekday: weekday,
        fromWeekday: e.weekday,
        kind: WeekFailure.move,
        entryId: e.id,
        retry: retry,
      ),
    );
    final title = words.title(e, plans);
    _snack(
      words.l10n.weekSnackMoved(title, words.dayLong(weekday)),
      () => _undo(side, before, [e.id, ...replaced]),
    );
  }

  void _remove(WeekWords words, WeekSide side, WeekEntry e, List<Plan> plans) {
    final before = _ctrl.current;
    _ctrl.apply(
      before.delete(side, e.id),
      failure: (retry) => WeekSaveError(
        side: side,
        weekday: e.weekday,
        kind: WeekFailure.remove,
        entryId: e.id,
        retry: retry,
      ),
    );
    _snack(
      words.l10n.weekSnackRemoved(
          words.title(e, plans), words.dayLong(e.weekday)),
      () => _undo(side, before, [e.id]),
    );
  }

  void _undo(WeekSide side, WeekPlan before, List<String> ids) {
    final change = _ctrl.current.restore(side, before, ids);
    _ctrl.apply(
      change,
      failure: (retry) => WeekSaveError(
        side: side,
        weekday: before.of(side)[ids.first]?.weekday ?? 1,
        kind: WeekFailure.edit,
        retry: retry,
      ),
    );
  }

  /// „Woche leeren" — irreversibel, deshalb zwei Stufen (Modul 7): Stufe 1
  /// informiert und zählt die Folgen, Stufe 2 entscheidet.
  Future<void> _clear(AppL10n l10n, WeekPlan week, WeekSide side) async {
    final entries = week.of(side).values.toList();
    final days = entries.map((e) => e.weekday).toSet().length;
    final withPlan = entries.where((e) => e.planId != null).length;
    final title = side == WeekSide.b || week.b.isNotEmpty
        ? l10n.weekClearTitleAb(side.name.toUpperCase())
        : l10n.weekClearTitle;
    final count = l10n.weekClearCount(
        l10n.weekEntries(entries.length), l10n.weekDays(days));

    final proceed = await AtemSheet.show<bool>(
      context,
      title: title,
      closeLabel: l10n.commonCancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: AtemType.body.of(context)),
          if (withPlan > 0) ...[
            const SizedBox(height: 8),
            Text(l10n.weekClearPlans(withPlan),
                style: AtemType.labelSmall.of(context)),
          ],
        ],
      ),
      primaryAction: AtemButton.outline(
        label: l10n.weekClearContinue,
        semanticLabel: l10n.weekClearContinue,
        accent: AtemColors.magenta,
        onPressed: () =>
            Navigator.of(context, rootNavigator: true).pop(true),
      ),
    );
    if (proceed != true || !mounted) return;

    await AtemDialog.show<void>(
      context,
      kind: AtemDialogKind.destructive,
      title: title,
      message: '$count ${l10n.weekClearIrreversible}',
      confirmLabel: l10n.weekClearConfirm,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.commonCancel,
      onConfirm: () {
        Navigator.of(context, rootNavigator: true).pop();
        _ctrl.apply(
          _ctrl.current.clearAll(side),
          failure: (retry) => WeekSaveError(
            side: side,
            weekday: 1,
            kind: WeekFailure.clear,
            retry: retry,
          ),
        );
        ref.read(snackbarProvider.notifier).show(AtemSnack(
              message: l10n.weekSnackCleared,
              semanticLabel: l10n.weekSnackCleared,
            ));
      },
    );
  }

  void _snack(String message, VoidCallback undo) {
    final l10n = AppL10n.of(context);
    ref.read(snackbarProvider.notifier).show(AtemSnack(
          message: message,
          semanticLabel: '$message. ${l10n.commonUndo}',
          actionLabel: l10n.commonUndo,
          onAction: undo,
        ));
  }

  String _errorText(WeekWords words, WeekSaveError error, WeekPlan? week,
      List<Plan> plans) {
    final l10n = words.l10n;
    final entry = error.entryId == null ? null : week?.of(error.side)[error.entryId];
    final title = entry == null
        ? l10n.weekTitle
        : words.title(entry, plans);
    if (error.kind == WeekFailure.move && error.fromWeekday != null) {
      return l10n.weekErrMove(title, words.dayLong(error.weekday),
          words.dayLong(error.fromWeekday!));
    }
    return l10n.weekErrSave(title, words.dayLong(error.weekday));
  }

  Widget _footer(
      BuildContext context, AppL10n l10n, WeekPlan week, WeekSide side) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AtemColors.border),
          const SizedBox(height: 14),
          // Ein Register, kein Werbetext (Board 18, F2).
          Text(l10n.weekUsed, style: AtemType.meta.of(context)),
          if (week.of(side).isNotEmpty)
            Semantics(
              container: true,
              child: AtemTappable(
                semanticLabel: l10n.weekClear,
                alignment: Alignment.centerLeft,
                onTap: () => _clear(l10n, week, side),
                child: Text(
                  l10n.weekClear,
                  style: AtemType.labelSmall.of(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AtemColors.magenta,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Teile der Seite -----------------------------------------------------------

/// Die Bezugszeile: was die Trainingsangaben sagen — **Bezug, nicht
/// Vorlage** (Entscheidung F6). Unbeantwortet in derselben Höhe und Farbe,
/// ohne Punkt, ohne Hervorhebung: eine Möglichkeit, keine Pflicht.
class _BriefRow extends ConsumerWidget {
  const _BriefRow({required this.goal});

  final TrainingGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final words = BriefingWords(context);
    final summary = words.settingsSummary(goal, DateTime.now());
    final at = goal.updatedAt;
    final source = summary == null || at == null
        ? null
        : goal.describes == Describes.intended
            ? l10n.weekBriefSourceIntended(words.date(at))
            : l10n.weekBriefSource(words.date(at));

    return Semantics(
      container: true,
      child: AtemTappable(
        semanticLabel: summary == null
            ? l10n.weekBriefA11yNone
            : l10n.weekBriefA11y(summary, source ?? ''),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TrainingGoalScreen()),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(14, 11, 4, 11),
          decoration: BoxDecoration(
            color: AtemColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AtemColors.border),
          ),
          child: Builder(builder: (context) {
            final glyph = Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AtemColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AtemRadii.iconBox),
              ),
              alignment: Alignment.center,
              child: const AtemGlyph(BriefingGlyphs.aim,
                  color: AtemColors.textTertiary, size: 18, strokeWidth: 1.8),
            );
            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.weekBriefLabel,
                    style: AtemType.labelSmall.of(context).copyWith(
                        fontSize: 12, color: AtemColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  summary ?? l10n.weekBriefNone,
                  style: AtemType.labelSmall.of(context).copyWith(
                        fontSize: 14,
                        color: summary == null
                            ? AtemColors.textTertiary
                            : AtemColors.textPrimary,
                      ),
                ),
                if (source != null) ...[
                  const SizedBox(height: 2),
                  Text(source, style: AtemType.meta.of(context)),
                ],
              ],
            );
            const chevron = SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: AtemGlyph('M9 6l6 6-6 6',
                    color: AtemColors.cyan, size: 18, strokeWidth: 2),
              ),
            );
            // Ab 145 % Schrift stehen Symbol und Chevron über dem Text —
            // sonst brach „Trainingsangaben" mitten im Wort.
            if (MediaQuery.textScalerOf(context).scale(1) > 1.45) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [glyph, const Spacer(), chevron]),
                  const SizedBox(height: 6),
                  Padding(padding: const EdgeInsets.only(right: 10), child: text),
                ],
              );
            }
            return Row(
              children: [
                glyph,
                const SizedBox(width: 12),
                Expanded(child: text),
                chevron,
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _AbSwitch extends StatelessWidget {
  const _AbSwitch({
    required this.side,
    required this.todaySide,
    required this.kw,
    required this.onChanged,
  });

  final WeekSide side;
  final WeekSide todaySide;
  final int kw;
  final ValueChanged<WeekSide> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    String label(WeekSide s) => l10n.weekAb(s.name.toUpperCase());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtemSegmented<WeekSide>(
          expand: true,
          groupSemanticLabel: l10n.weekAbGroup,
          value: side,
          onChanged: onChanged,
          segments: [
            for (final s in WeekSide.values)
              AtemSegment(
                value: s,
                label: label(s),
                semanticLabel:
                    s == todaySide ? '${label(s)}, ${l10n.weekToday.toLowerCase()}' : label(s),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.weekAbCurrent(kw, todaySide.name.toUpperCase()),
          style: AtemType.meta.of(context),
        ),
      ],
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AtemColors.textTertiary),
        ),
        child: Text(
          AppL10n.of(context).weekToday,
          style: AtemType.labelMicro
              .of(context)
              .copyWith(color: AtemColors.textTertiary),
        ),
      );
}

/// Das Plus je Tag: 48 dp Treffer, 32 dp sichtbar, Cyan-Rand.
class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: AtemTappable(
          semanticLabel: label,
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AtemColors.cyan.withValues(alpha: 0.45)),
            ),
            alignment: Alignment.center,
            child: const AtemGlyph('M12 6v12M6 12h12',
                color: AtemColors.cyan, size: 16, strokeWidth: 2),
          ),
        ),
      );
}

/// Eine Zeile der Woche — Spurkachel, Titel, Metazeile, ggf. die Notiz zum
/// gelöschten Plan, und „⋯" als Zeichen, dass die Zeile sich öffnen lässt.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.kind,
    required this.title,
    required this.meta,
    this.note,
  });

  final WeekKind kind;
  final String title;
  final String meta;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final tile = WeekLaneTile(kind: kind, size: scale > 1.45 ? 48 : 36);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: AtemType.labelSmall.of(context).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AtemColors.textPrimary)),
        const SizedBox(height: 2),
        Text(meta,
            style: AtemType.labelSmall
                .of(context)
                .copyWith(fontSize: 12, color: AtemColors.textSecondary)),
        if (note != null) ...[
          const SizedBox(height: 2),
          Text(note!,
              style: AtemType.labelSmall.of(context).copyWith(fontSize: 12)),
        ],
      ],
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: AtemColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AtemRadii.statBox),
        border: Border.all(color: AtemColors.border),
      ),
      // Ab 145 % Schrift steht die Kachel über dem Text — sonst blieben
      // dem Titel keine 120 dp (Board 19, B14).
      child: scale > 1.45
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [tile, const Spacer(), const _More()]),
                const SizedBox(height: 8),
                text,
              ],
            )
          : Row(
              children: [
                tile,
                const SizedBox(width: 12),
                Expanded(child: text),
                const _More(),
              ],
            ),
    );
  }
}

class _More extends StatelessWidget {
  const _More();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(left: 6),
        child: AtemGlyph('M5 12h.01M12 12h.01M19 12h.01',
            color: AtemColors.cyan, size: 18, strokeWidth: 3),
      );
}

/// Die angehobene Zeile beim Ziehen: scale 1,03 und Schatten.
class _DragGhost extends StatelessWidget {
  const _DragGhost({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 2 * 16 - 2 * 14;
    return Transform.scale(
      scale: AtemMotion.reduced(context) ? 1 : 1.03,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Color(0x99000000), blurRadius: 28, offset: Offset(0, 12)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Die gestrichelte Einfügelinie am Tagesende, solange ein Eintrag darüber
/// schwebt.
class _DropLine extends StatelessWidget {
  const _DropLine();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: CustomPaint(
          size: const Size(double.infinity, 2),
          painter: _DashPainter(),
        ),
      );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtemColors.cyan
      ..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 1), Offset(x + 5, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

/// „Trainiert · …" — eine Tatsache neben dem Tag, nie am Eintrag.
class _FactLine extends StatelessWidget {
  const _FactLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: text,
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AtemColors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: AtemType.labelSmall.of(context).copyWith(
                      fontSize: 12, color: AtemColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
}

class _DayError extends StatelessWidget {
  const _DayError({required this.text, required this.retry});

  final String text;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemRejectFlicker(
      trigger: text,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        decoration: BoxDecoration(
          color: AtemColors.magenta.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AtemRadii.statBox),
          border: Border.all(color: AtemColors.magenta.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: AtemType.labelSmall
                    .of(context)
                    .copyWith(fontSize: 12.5, color: AtemColors.magenta)),
            Semantics(
              container: true,
              child: AtemTappable(
                semanticLabel: l10n.commonRetry,
                alignment: Alignment.centerLeft,
                onTap: retry,
                child: Text(
                  l10n.commonRetry,
                  style: AtemType.labelSmall.of(context).copyWith(
                      fontWeight: FontWeight.w600, color: AtemColors.cyan),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// „Diese Woche bisher" — zwei Tatsachen nebeneinander, nach Messregel F3:
/// nie ein Bruch, nie ein Balken, kein Farbwechsel beim Erreichen.
class _SoFar extends StatelessWidget {
  const _SoFar({
    required this.week,
    required this.side,
    required this.sessions,
    required this.kw,
  });

  final WeekPlan week;
  final WeekSide side;
  final Map<int, List<TrainingSession>> sessions;
  final int kw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    int done(WeekKind k) => sessions.values
        .expand((s) => s)
        .where((s) => laneOf(s) == k)
        .length;
    int planned(WeekKind k) =>
        week.of(side).values.where((e) => e.kind == k).length;

    final lines = [
      for (final k in [WeekKind.strength, WeekKind.cardio])
        if (done(k) > 0 || planned(k) > 0)
          (
            k,
            [
              k == WeekKind.strength
                  ? l10n.weekSumStrength(done(k))
                  : l10n.weekSumCardio(done(k)),
              if (planned(k) > 0) l10n.weekSumPlanned(planned(k)),
            ].join(' · '),
          ),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        container: true,
        label: [
          l10n.weekSumHead(kw),
          for (final (_, line) in lines) line,
        ].join('. '),
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AtemColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AtemColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.weekSumHead(kw),
                    style: AtemType.labelMicro.of(context)),
                for (final (k, line) in lines) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      WeekLaneTile(kind: k, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(line,
                            style: AtemType.labelSmall.of(context).copyWith(
                                fontSize: 13.5,
                                color: AtemColors.textPrimary)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
