import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/training_goal_providers.dart';
import '../../domain/briefing_question.dart';
import '../../domain/training_goal.dart';
import '../briefing_ui.dart';

/// Die Trainingsangaben — das Zielbriefing (Board 18).
///
/// ## Formular und Zusammenfassung sind dieselbe Seite
///
/// Beim ersten Aufruf stehen alle Fragen offen da, keine vorgewählt. Sobald
/// es eine Antwort gibt, öffnet die Seite gefaltet: jede Frage eine Zeile,
/// genau eine aufklappbar (Entscheidung 5). Es gibt keine zweite Ansicht, die
/// mit dem Formular auseinanderlaufen kann.
///
/// ## Kein Speichern-Knopf
///
/// Jede Wahl ist sofort geschrieben (Entscheidung 6). Ein „Fertig" erfände
/// einen Zustand „vollständig", den es nicht gibt; ohne „Fertig" gibt es kein
/// „unfertig".
///
/// ## Wer antwortet, bleibt, wo er ist
///
/// Kein Weiterscrollen nach einer Antwort (Entscheidung 17), keine Frage
/// oberhalb, die sich durch eine Antwort ändert (Entscheidung 21). Folgefragen
/// erscheinen unterhalb, und der Fokus bleibt auf der gewählten Antwort.
///
/// ## Abweichungen vom Board, mit Grund
///
/// - Metazeilen stehen in `meta` (13 sp) statt Mono 11: Informationstragender
///   Text ist nie kleiner als 12 sp (CLAUDE.md), und `labelMicro` ist für
///   Köpfe, nicht für Sätze.
/// - „Erneut versuchen" hat 48 statt 44 dp Trefferfläche.
/// - Das Ladeskelett ist das gemeinsame aus Modul 2, nicht ein eigener
///   Schimmer: Ein Skelett heisst überall „gleich kommt etwas", und eine
///   zweite Form dafür wäre eine zu viel.
class TrainingGoalScreen extends ConsumerStatefulWidget {
  const TrainingGoalScreen({super.key, this.today});

  /// Für Tests und Renderbilder; sonst der heutige Tag.
  final DateTime? today;

  @override
  ConsumerState<TrainingGoalScreen> createState() =>
      _TrainingGoalScreenState();
}

class _TrainingGoalScreenState extends ConsumerState<TrainingGoalScreen> {
  /// Erster Aufruf: alles offen. Festgelegt beim ersten geladenen Stand und
  /// danach nicht mehr — eine erste Antwort faltet die Seite nicht unter
  /// den Fingern zusammen.
  bool? _first;

  /// Im Wiederansehen: der eine aufgeklappte Block.
  BriefingQuestion? _open;

  /// Je Frage: wie oft sie aufgeklappt wurde oder erschienen ist. Ändert
  /// sich die Zahl, läuft die Lichtkante — bei jedem Öffnen (entschieden am
  /// 23.09.2026, gegen Board 18b C6).
  final _edgeTicks = <BriefingQuestion, int>{};

  void _edge(BriefingQuestion q) => _edgeTicks[q] = (_edgeTicks[q] ?? 0) + 1;

  DateTime get _today => widget.today ?? DateTime.now();

  TrainingGoalController get _ctrl =>
      ref.read(trainingGoalControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final words = BriefingWords(context);
    final async = ref.watch(trainingGoalProvider);
    final activity = ref.watch(trainingGoalControllerProvider);

    // Eine Folgefrage erscheint: einmal höflich ansagen.
    ref.listen(trainingGoalProvider, (prev, next) {
      final before = prev?.value;
      final after = next.value;
      if (before == null || after == null) return;
      for (final q in BriefingQuestion.values) {
        if (!q.isAsked(before) && q.isAsked(after)) {
          setState(() => _edge(q));
          _announce(l10n.briefingNewQuestionA11y(words.title(q)));
        }
      }
    });
    // Eine Ablehnung: der Block klappt auf, die Ansage ist bestimmt.
    ref.listen(trainingGoalControllerProvider, (prev, next) {
      final error = next.error;
      if (error == null || prev?.error == error) return;
      if (_first == false) setState(() => _open = error.question);
      _announce(
        '${l10n.briefingSaveError(error.attempted)} '
        '${l10n.briefingSaveErrorKept(error.previous)}',
        assertive: true,
      );
    });

    // **Laden und Fehler gehen einem alten Wert vor.** Riverpod behält beim
    // Nachladen den vorigen Stand — etwa den leeren aus der Zeit vor der
    // Anmeldung. Er sähe aus wie „nie beantwortet" und legte die Seite auf
    // den ersten Aufruf fest, obwohl gleich Antworten kommen.
    final goal = async.isLoading || async.hasError ? null : async.value;
    if (goal != null) _first ??= !goal.hasAny;

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: AtemSubpageBar.of(
              context,
              kicker: l10n.briefingArea,
              backLabel: l10n.commonBack,
              tone: AtemColors.tabHybrid,
            ),
          ),
          SliverToBoxAdapter(
            child: AtemSubpageTitle(
              tone: AtemColors.tabHybrid,
              title: AtemExplainHeader(
                title: l10n.briefingTitle,
                explanation: [l10n.briefingExplainBody],
                titleStyle: AtemType.titleLarge
                    .of(context)
                    .copyWith(fontSize: 22, height: 1.25),
              ),
              below: [
                const SizedBox(height: 2),
                Text(l10n.briefingHint, style: AtemType.meta.of(context)),
                if (goal?.updatedAt != null && goal!.hasAny) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.briefingLastChanged(words.date(goal.updatedAt!)),
                    style: AtemType.meta.of(context),
                  ),
                ],
              ],
            ),
          ),
          if (async.hasError)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
              sliver: SliverToBoxAdapter(
                // Keine leeren Fragen als Rückfall: Ein leeres Formular sähe
                // aus wie „nichts beantwortet" und lüde dazu ein, eine
                // gespeicherte Angabe zu überschreiben (Entscheidung 16).
                child: AtemErrorState(
                  title: l10n.briefingLoadError,
                  body: l10n.briefingLoadErrorBody,
                  retryLabel: l10n.briefingRetry,
                  onRetry: () => ref.invalidate(trainingGoalProvider),
                ),
              ),
            )
          else if (goal == null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              sliver: SliverToBoxAdapter(
                // Zeilenform, nicht Blockform: Die meisten Aufrufe nach dem
                // ersten enden in Zeilen (Board 18, A4).
                child: AtemSkeleton(
                  semanticLabel: l10n.briefingLoading,
                  spacing: 12,
                  blocks: const [
                    AtemSkeletonBlock(height: 64, radius: 16),
                    AtemSkeletonBlock(height: 64, radius: 16),
                    AtemSkeletonBlock(height: 64, radius: 16),
                    AtemSkeletonBlock(height: 64, radius: 16),
                  ],
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverList.list(
                children: [
                  for (final (i, q) in BriefingQuestion.values.indexed)
                    AtemRevealGroup(
                      visible: q.isAsked(goal),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _question(
                            context, words, goal, activity, q, i),
                      ),
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(child: _footer(context, l10n, goal)),
          ],
        ],
      ),
    );
  }

  // --- Eine Frage: Zeile oder Block ----------------------------------------

  Widget _question(
    BuildContext context,
    BriefingWords words,
    TrainingGoal goal,
    BriefingActivity activity,
    BriefingQuestion q,
    int index,
  ) {
    final first = _first ?? true;
    if (first) {
      return AtemEntrance(
        index: index,
        child: _block(context, words, goal, activity, q, review: false),
      );
    }
    final isOpen = _open == q;
    final child = isOpen
        ? _block(context, words, goal, activity, q, review: true)
        : _row(words, goal, q);
    final duration = AtemMotion.duration(context, const Duration(milliseconds: 320));
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: atemAnswerEase,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(isOpen), child: child),
      ),
    );
  }

  Widget _row(BriefingWords words, TrainingGoal goal, BriefingQuestion q) {
    final l10n = words.l10n;
    final answer = words.summary(q, goal, _today);
    final short = words.short(q);
    return AtemAnswerRow(
      question: short,
      answer: answer,
      openLabel: l10n.briefingRowOpen,
      glyph: BriefingGlyphs.of(q),
      semanticLabel: answer == null
          ? l10n.briefingRowA11yOpen(short)
          : l10n.briefingRowA11yAnswered(short, answer),
      onTap: () => setState(() {
        _open = q;
        _edge(q);
        _ctrl.dismissError();
      }),
    );
  }

  Widget _block(
    BuildContext context,
    BriefingWords words,
    TrainingGoal goal,
    BriefingActivity activity,
    BriefingQuestion q, {
    required bool review,
  }) {
    final l10n = words.l10n;
    final error = activity.error?.question == q ? activity.error : null;
    final hint = words.hint(q, goal);
    final answered = q.isAnswered(goal);

    return AtemSaveScan(
      trigger: activity.saved == q ? activity.tick : null,
      child: AtemEdgeSweep(
        trigger: _edgeTicks[q] ?? 0,
        // Der Block entsteht beim Aufklappen oder Erscheinen neu; beim
        // Aufbau der Seite ist der Zähler 0 und nichts läuft.
        onMount: (_edgeTicks[q] ?? 0) > 0,
        radius: AtemRadii.card,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AtemColors.card,
            borderRadius: AtemRadii.cardR,
            border: Border.all(
              color: error != null
                  ? AtemColors.magenta.withValues(alpha: 0.45)
                  : AtemColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BlockHead(
                title: words.title(q),
                glyph: BriefingGlyphs.of(q),
                onCollapse: review
                    ? () => setState(() => _open = null)
                    : null,
                collapseLabel: words.short(q),
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: AtemType.labelSmall.of(context).copyWith(
                        fontSize: 12,
                        color: AtemColors.textSecondary,
                      ),
                ),
              ],
              ..._groups(context, words, goal, q),
              if (error != null) _ErrorBox(error: error),
              if (answered)
                _TextAction(
                  label: l10n.briefingClear,
                  semanticLabel: l10n.briefingClearA11y(words.title(q)),
                  color: AtemColors.cyan,
                  onTap: () => _clear(words, q),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Antwortgruppen je Frage ---------------------------------------------

  List<Widget> _groups(
    BuildContext context,
    BriefingWords words,
    TrainingGoal g,
    BriefingQuestion q,
  ) {
    final l10n = words.l10n;
    final alt = g.weekPattern == WeekPattern.alternating;

    switch (q) {
      case BriefingQuestion.lanes:
        final options = [
          ({Lane.strength}, l10n.briefingOptStrength, BriefingGlyphs.strength,
              BriefingTone.strength),
          ({Lane.cardio}, l10n.briefingOptCardio, BriefingGlyphs.cardio,
              BriefingTone.cardio),
          ({Lane.strength, Lane.cardio}, l10n.briefingOptBoth,
              BriefingGlyphs.both, BriefingTone.both),
        ];
        return [
          _list(words.title(q), [
            for (final (value, label, glyph, tone) in options)
              AtemAnswerOption(
                label: label,
                glyph: glyph,
                glyphFill: tone.fill,
                glyphColor: tone.glyph,
                selected: g.lanes != null &&
                    g.lanes!.length == value.length &&
                    g.lanes!.containsAll(value),
                onTap: () => _pick(words, q, label, (x) => x.withLanes(value)),
              ),
          ]),
        ];

      case BriefingQuestion.pattern:
        final isA = g.isWeekA(_today);
        return [
          _list(words.title(q), [
            for (final p in WeekPattern.values)
              AtemAnswerOption(
                label: words.pattern(p),
                selected: g.weekPattern == p,
                onTap: () => _pick(words, q, words.pattern(p),
                    (x) => x.withWeekPattern(p)),
              ),
          ]),
          AtemRevealGroup(
            visible: alt,
            child: _labelled(l10n.briefingAnchorLabel, [
              for (final a in [true, false])
                AtemAnswerChip(
                  label: a ? l10n.briefingAnchorA : l10n.briefingAnchorB,
                  semanticLabel: l10n.briefingAnchorA11y(
                      a ? l10n.briefingAnchorA : l10n.briefingAnchorB),
                  selected: isA == a,
                  onTap: () => _pick(
                    words,
                    q,
                    a ? l10n.briefingAnchorA : l10n.briefingAnchorB,
                    (x) => x.withCurrentWeek(isA: a, today: _today),
                  ),
                ),
            ]),
          ),
        ];

      case BriefingQuestion.perWeek:
        Widget counts(Lane lane, {required bool weekB}) {
          final art = words.lane(lane);
          final current = weekB ? g.perWeekB[lane] : g.perWeek[lane];
          final label = !alt
              ? art
              : weekB
                  ? l10n.briefingGroupWeekB(art)
                  : l10n.briefingGroupWeekA(art);
          return _labelled(label, [
            for (var n = 1; n <= 8; n++)
              AtemAnswerChip(
                label: words.chipCount(n),
                semanticLabel: words.countA11y(lane, n),
                selected: current == n,
                onTap: () => _pick(
                  words,
                  q,
                  l10n.briefingLaneValue(art, words.count(n)),
                  (x) => x.withPerWeek(lane, n, weekB: weekB),
                ),
              ),
          ]);
        }

        return [
          for (final (i, lane) in Lane.values.indexed) ...[
            AtemRevealGroup(
              visible: g.includes(lane),
              delay: Duration(milliseconds: i * 40),
              child: counts(lane, weekB: false),
            ),
            AtemRevealGroup(
              visible: g.includes(lane) && alt,
              delay: Duration(milliseconds: 60 + i * 40),
              child: counts(lane, weekB: true),
            ),
          ],
        ];

      case BriefingQuestion.days:
        return [
          _list(words.title(q), [
            for (final s in DaySchedule.values)
              AtemAnswerOption(
                label: words.schedule(s),
                selected: g.schedule == s,
                onTap: () => _pick(
                    words, q, words.schedule(s), (x) => x.withSchedule(s)),
              ),
          ]),
          for (final (i, lane) in Lane.values.indexed)
            AtemRevealGroup(
              visible: g.schedule == DaySchedule.fixed && g.includes(lane),
              delay: Duration(milliseconds: i * 60),
              child: _labelled(l10n.briefingDaysGroup(words.lane(lane)), [
                for (final d in words.weekdaysInOrder())
                  AtemAnswerChip(
                    label: words.dayShort(d),
                    semanticLabel:
                        l10n.briefingDayA11y(words.lane(lane), words.dayLong(d)),
                    exclusive: false,
                    selected: g.days[lane]?.contains(d) ?? false,
                    onTap: () => _pick(
                      words,
                      q,
                      l10n.briefingDayA11y(words.lane(lane), words.dayLong(d)),
                      (x) => x.withDays(lane, _toggle(x.days[lane], d)),
                    ),
                  ),
              ]),
            ),
        ];

      case BriefingQuestion.multi:
        final several = g.multiPerDay == MultiPerDay.some ||
            g.multiPerDay == MultiPerDay.most;
        return [
          _list(words.title(q), [
            for (final m in MultiPerDay.values)
              AtemAnswerOption(
                label: words.multi(m),
                selected: g.multiPerDay == m,
                onTap: () => _pick(
                    words, q, words.multi(m), (x) => x.withMultiPerDay(m)),
              ),
          ]),
          for (final (i, lane) in Lane.values.indexed)
            AtemRevealGroup(
              visible: several && g.includes(lane),
              delay: Duration(milliseconds: i * 60),
              child: _labelledTiles(
                l10n.briefingDaypartGroup(words.lane(lane)),
                basis: 84,
                [
                  for (final d in Daypart.values)
                    AtemAnswerTile(
                      label: words.daypart(d),
                      glyph: BriefingGlyphs.ofDaypart(d),
                      semanticLabel: l10n.briefingDaypartA11y(
                          words.lane(lane), words.daypart(d)),
                      selected: g.dayparts[lane]?.contains(d) ?? false,
                      onTap: () => _pick(
                        words,
                        q,
                        l10n.briefingLaneValue(
                            words.lane(lane), words.daypart(d)),
                        (x) =>
                            x.withDayparts(lane, _toggle(x.dayparts[lane], d)),
                      ),
                    ),
                ],
              ),
            ),
        ];

      case BriefingQuestion.places:
        return [
          _labelledTiles(null, basis: 84, [
            for (final p in Place.values)
              AtemAnswerTile(
                label: words.place(p),
                glyph: BriefingGlyphs.ofPlace(p),
                semanticLabel: l10n.briefingPlaceA11y(words.place(p)),
                selected: g.places?.contains(p) ?? false,
                onTap: () => _pick(words, q, words.place(p),
                    (x) => x.withPlaces(_toggle(x.places, p))),
              ),
          ]),
        ];

      case BriefingQuestion.goals:
        return [
          _labelledTiles(null, basis: 130, [
            for (final a in words.aimsInOrder())
              AtemAnswerTile(
                label: words.aim(a),
                glyph: BriefingGlyphs.ofAim(a),
                glyphFill: BriefingTone.ofAim(a).fill,
                glyphColor: BriefingTone.ofAim(a).glyph,
                semanticLabel: l10n.briefingGoalA11y(words.aim(a)),
                selected: g.goals?.contains(a) ?? false,
                onTap: () => _pick(words, q, words.aim(a),
                    (x) => x.withGoals(_toggle(x.goals, a))),
              ),
          ]),
        ];

      case BriefingQuestion.describes:
        return [
          _list(words.title(q), [
            for (final d in Describes.values)
              AtemAnswerOption(
                label: words.describes(d),
                glyph: d == Describes.current
                    ? BriefingGlyphs.now
                    : BriefingGlyphs.describes,
                selected: g.describes == d,
                onTap: () => _pick(
                    words, q, words.describes(d), (x) => x.withDescribes(d)),
              ),
          ]),
        ];
    }
  }

  Widget _list(String groupLabel, List<Widget> options) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Semantics(
          label: groupLabel,
          container: true,
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, o) in options.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                o,
              ],
            ],
          ),
        ),
      );

  Widget _labelled(String label, List<Widget> chips) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupLabel(label),
            const SizedBox(height: 8),
            // Ein Wrap, nie eine Reihe: Sieben Chips à 48 dp brauchen
            // 384 dp, der Block bietet auf 360 dp nur 290 (Entscheidung 9).
            Padding(
              // Platz für das Häkchen, das 6 dp über die Ecke ragt.
              padding: const EdgeInsets.only(top: 6, right: 6),
              child: Wrap(spacing: 8, runSpacing: 12, children: chips),
            ),
          ],
        ),
      );

  Widget _labelledTiles(String? label, List<Widget> tiles,
          {required double basis}) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (label != null) ...[
              _GroupLabel(label),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 6),
              child: AtemAnswerTileGrid(basis: basis, children: tiles),
            ),
          ],
        ),
      );

  // --- Handlungen ----------------------------------------------------------

  void _pick(
    BriefingWords words,
    BriefingQuestion q,
    String attempted,
    TrainingGoal Function(TrainingGoal) edit,
  ) {
    final l10n = words.l10n;
    final before = _ctrl.current;
    final removal = _ctrl.apply(
      q,
      edit,
      attempted: attempted,
      previous: words.summary(q, before, _today) ?? l10n.briefingRowOpen,
    );
    if (removal == null) return;
    _snack(_removalText(l10n, removal), () => _ctrl.restore(before));
  }

  void _clear(BriefingWords words, BriefingQuestion q) {
    final l10n = words.l10n;
    final before = _ctrl.current;
    _ctrl.apply(
      q,
      q.clear,
      attempted: l10n.briefingClear,
      previous: words.summary(q, before, _today) ?? l10n.briefingRowOpen,
    );
    _snack(l10n.briefingSnackCleared, () => _ctrl.restore(before));
  }

  void _clearAll(AppL10n l10n) {
    final before = _ctrl.clearAll();
    setState(() => _open = null);
    _snack(l10n.briefingSnackAll, () => _ctrl.restore(before));
  }

  String _removalText(AppL10n l10n, Removal r) => switch (r) {
        LaneRemoval(:final lanes) when lanes.length > 1 =>
          l10n.briefingSnackBothLanes,
        LaneRemoval(:final lanes) => l10n.briefingSnackDependent(
            lanes.first == Lane.strength
                ? l10n.briefingOptStrength
                : l10n.briefingOptCardio),
        WeekBRemoval() => l10n.briefingSnackWeekB,
        DaysRemoval() => l10n.briefingSnackDays,
        DaypartsRemoval() => l10n.briefingSnackDayparts,
      };

  void _snack(String message, VoidCallback undo) {
    final l10n = AppL10n.of(context);
    ref.read(snackbarProvider.notifier).show(AtemSnack(
          message: message,
          semanticLabel: '$message. ${l10n.briefingSnackUndo}',
          actionLabel: l10n.briefingSnackUndo,
          onAction: undo,
        ));
  }

  void _announce(String message, {bool assertive = false}) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
      assertiveness: assertive ? Assertiveness.assertive : Assertiveness.polite,
    );
  }

  Widget _footer(BuildContext context, AppL10n l10n, TrainingGoal goal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AtemColors.border),
          const SizedBox(height: 16),
          // Ein Register, kein Werbetext (Entscheidung F2): Sobald eine
          // Auswertung die Angaben nutzt, steht sie hier.
          // Seit Board 19 nutzt die Woche die Angaben als Bezug.
          Text(l10n.briefingUsedBy(l10n.weekUsedByPlanning),
              style: AtemType.meta.of(context)),
          if (goal.hasAny)
            _TextAction(
              label: l10n.briefingClearAll,
              semanticLabel: l10n.briefingClearAllA11y,
              color: AtemColors.magenta,
              onTap: () => _clearAll(l10n),
            ),
        ],
      ),
    );
  }
}

Set<T>? _toggle<T>(Set<T>? set, T value) {
  final next = {...?set};
  if (!next.remove(value)) next.add(value);
  return next.isEmpty ? null : next;
}

// --- Teile eines Blocks ------------------------------------------------------

class _BlockHead extends StatelessWidget {
  const _BlockHead({
    required this.title,
    required this.glyph,
    required this.onCollapse,
    required this.collapseLabel,
  });

  final String title;
  final String glyph;
  final VoidCallback? onCollapse;
  final String collapseLabel;

  @override
  Widget build(BuildContext context) {
    final head = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AtemColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AtemRadii.iconBox),
          ),
          alignment: Alignment.center,
          child: AtemGlyph(glyph,
              color: AtemColors.textTertiary, size: 17, strokeWidth: 1.8),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Semantics(
              header: true,
              container: true,
              child: Text(
                title,
                style: AtemType.titleMedium
                    .of(context)
                    .copyWith(fontSize: 15, height: 1.4),
              ),
            ),
          ),
        ),
        if (onCollapse != null)
          Semantics(
            container: true,
            child: AtemTappable(
              semanticLabel: collapseLabel,
              expanded: true,
              onTap: onCollapse,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: AtemGlyph('M6 15l6-6 6 6',
                      color: AtemColors.cyan, size: 18, strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
    return head;
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AtemType.labelMicro.of(context));
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error});

  final BriefingSaveError error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final text = '${l10n.briefingSaveError(error.attempted)} '
        '${l10n.briefingSaveErrorKept(error.previous)}';
    return AtemRejectFlicker(
      trigger: error,
      child: Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: AtemColors.magenta.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AtemRadii.statBox),
        border: Border.all(color: AtemColors.magenta.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: AtemGlyph('M12 3L22 20H2zM12 10v4.5M12 17.2v.1',
                    color: AtemColors.magenta, size: 14, strokeWidth: 1.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AtemType.labelSmall.of(context).copyWith(
                        fontSize: 12.5,
                        color: AtemColors.magenta,
                      ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: _TextAction(
              label: l10n.briefingRetry,
              semanticLabel: l10n.briefingRetry,
              color: AtemColors.cyan,
              onTap: error.retry,
            ),
          ),
        ],
      ),
    ));
  }
}

/// Eine Textaktion, 48 dp hoch, linksbündig.
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  // **Ein eigener Knoten.** Ohne `container` wanderte die Aktion in den
  // Knoten des Blocks und verschmolz mit Titel und Hinweis — wer den Titel
  // antippte, hätte die Antwort zurückgenommen.
  @override
  Widget build(BuildContext context) => Semantics(
      container: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AtemTappable(
          semanticLabel: semanticLabel,
          alignment: Alignment.centerLeft,
          onTap: onTap,
          child: Text(
            label,
            style: AtemType.labelSmall.of(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ),
      ));
}
