import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../../dashboard/domain/dashboard_data.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../plans/application/pending_plan_deletion.dart';
import '../../../plans/application/plan_providers.dart';
import '../../../plans/domain/plan.dart';
import '../../../plans/presentation/widgets/plan_card.dart';
import '../../../plans/presentation/screens/plan_detail_screen.dart';
import '../../../plans/presentation/screens/plan_list_screen.dart';
import '../../../plans/presentation/start_sheet.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/domain/muscle.dart';
import '../../../exercises/presentation/screens/exercise_detail_screen.dart';
import '../../../exercises/presentation/screens/exercise_form_screen.dart';
import '../../../exercises/presentation/screens/exercise_list_screen.dart';
import '../../../exercises/presentation/widgets/exercise_bits.dart';
import '../../../exercises/presentation/widgets/exercise_search.dart';
import '../../../strength/presentation/screens/strength_form_screen.dart';

/// Der Workouts-Tab.
///
/// **Zuerst „Was mache ich jetzt?", erst danach „Was gibt es sonst?"** Die
/// heutige Einheit steht ganz oben und ist die einzige hervorgehobene Karte des
/// Bildschirms; Pläne und Übungen sind Nachschlagewerke darunter.
///
/// Er ist zugleich der Eingang zum Runner. Vorher hing der ausschließlich an
/// einem Kalendereintrag — wer keinen hatte, konnte kein Training starten.
///
/// ## Warum die Übungen Gewicht über Fläche bekommen, nicht über Position
///
/// Die Rückmeldung lautete: „Übungen sind mir zu unpräsent." Sie war
/// berechtigt — eine einzelne Suchzeile unter zwei Blöcken ist ein Türschild,
/// kein Raum. Die naheliegende Antwort wäre gewesen, sie nach oben zu
/// schieben.
///
/// Das wäre die falsche Antwort. Die Reihenfolge aus Modul 5 beantwortet
/// zuerst „Was mache ich jetzt?" und erst danach „Was gibt es sonst?", und
/// eine Übungsdatenbank beantwortet die erste Frage nie. Nach oben gerückt
/// verdrängte sie die Antwort, die jemand beim Öffnen des Tabs sucht.
///
/// Also bleibt die Reihenfolge und der Block wächst: Suche, neun
/// Muskelfilter, die ersten Treffer, ein Weg zum Anlegen. Wer sucht, findet
/// hier alles ohne den Tab zu verlassen; wer nicht sucht, scrollt daran vorbei
/// wie vorher.
class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen(
      {super.key, required this.onStart, this.embedded = false});

  /// Trägt die Startanfrage nach oben. Der Tab kennt den Runner nicht.
  final ValueChanged<StartRequest> onStart;

  /// Als Segment „Trainieren" im Kraft-Tab (Modul 11): Titel und Rahmen
  /// stellt dann der Kraft-Tab, hier steht nur der Inhalt.
  final bool embedded;

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  final _search = TextEditingController();

  /// So viele Treffer stehen im Block. Mehr wäre eine zweite Liste im Tab.
  static const _exercisePreview = 3;

  /// Abstand über jedem Abschnittskopf und darunter — auf der ganzen Seite
  /// gleich (seit 17.09.2026; vorher 28/8 und 28/10 gemischt).
  static const _sectionGap = 28.0;
  static const _headerGap = 10.0;

  ValueChanged<StartRequest> get onStart => widget.onStart;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final dashboard = ref.watch(dashboardDataProvider);
    final plans = ref.watch(visiblePlansProvider).value ?? const <Plan>[];
    final exerciseList = ref.watch(exercisesProvider).value ?? const [];
    final exerciseCount = exerciseList.length;
    final exercisesById = {for (final e in exerciseList) e.id: e};
    final matches = ref.watch(filteredExercisesProvider);
    final muscle = ref.watch(exerciseFilterProvider);

    final session = dashboard.value?.session;

    final list = ListView(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 130),
      children: [
        if (!widget.embedded) ...[
          Text(l10n.workoutsTitle, style: AtemType.titleLarge.of(context)),
          const SizedBox(height: 20),
        ],
        if (dashboard.hasError)
          AtemErrorState(
            title: l10n.listErrorTitle,
            body: l10n.listErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(dashboardDataProvider),
          )
        else
          AtemEntrance(
            child: _StartCard(
              session: session,
              onStartToday:
                  session == null ? null : () => _startToday(context, session),
              onFree: () => _startFree(context),
              onPickPlan: () => _openPlans(context),
              onLogWithoutSets: () => _logWithoutSets(context),
            ),
          ),
        const SizedBox(height: _sectionGap),
        _SectionHeader(
          title: l10n.workoutsPlansLabel.toUpperCase(),
          actionLabel:
              plans.isEmpty ? null : l10n.workoutsPlansAll(plans.length),
          onAction: plans.isEmpty ? null : () => _openPlans(context),
        ),
        const SizedBox(height: _headerGap),
        if (plans.isEmpty)
          _PlainEmpty(
            title: l10n.workoutsTodayEmptyTitle,
            body: l10n.workoutsTodayEmptyBody,
          )
        else
          // **Karten statt Zeilen** (seit 16.09.2026): Pläne werden ein
          // eigenes Angebot mit Bild. Die Reihe scrollt seitlich; „Alle"
          // im Kopf bleibt der Weg zur vollständigen Liste.
          PlanCardRow(
            plans: plans,
            horizontalPadding: 0,
            musclesOf: (plan) => _musclesOf(plan, exercisesById),
            onOpen: (plan) => _openPlan(context, plan),
            onStart: (plan) => _startPlan(context, plan),
          ),
        const SizedBox(height: _sectionGap),
        _SectionHeader(
          // Die Zahl steht im Titel, nicht in der Aktion: „Übungen · 154"
          // sagt, wie gross der Bestand ist; „Alle ansehen" sagt, wohin
          // der Weg führt. Beides in einer Zeile wäre eine Zahl zu viel.
          // Der Titel trägt eine Zahl und ist damit eine Metazeile, kein
          // HUD-Kopf — gemischte Schreibung in Poppins.
          title: l10n.exercisesBlockTitle(exerciseCount),
          role: AtemType.meta,
          actionLabel: l10n.exercisesBlockAll,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ExerciseListScreen(),
            ),
          ),
        ),
        const SizedBox(height: _headerGap),
        // **Ein Block, keine losen Zeilen** (Board 07, A1/2): „Gewicht
        // entsteht durch Fläche, nicht durch Position." Aus einer
        // 44-dp-Suchzeile wird eine Karte mit Sucheingang, neun
        // Muskelfiltern und dem Anlegen-Weg.
        AtemCard.list(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExerciseSearchField(
                controller: _search,
                onChanged: (v) {
                  ref.read(exerciseQueryProvider.notifier).set(v);
                  setState(() {});
                },
                onClear: () {
                  _search.clear();
                  ref.read(exerciseQueryProvider.notifier).clear();
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              Text(l10n.exercisesBlockByMuscle.toUpperCase(),
                  style: AtemType.labelMicro.of(context)),
              const SizedBox(height: 10),
              // Ohne eigenes Seitenpolster: Der Block liegt schon in dem
              // der Karte, und ein zweites schöbe den ersten Chip in die
              // Mitte.
              ExerciseFilterRow(
                selected: muscle,
                padding: EdgeInsets.zero,
                onSelect: (m) =>
                    ref.read(exerciseFilterProvider.notifier).toggle(m),
                onAll: () => ref.read(exerciseFilterProvider.notifier).clear(),
              ),
              const SizedBox(height: 10),
              _ExerciseMatches(matches: matches, limit: _exercisePreview),
              const SizedBox(height: 14),
              AtemButton.outline(
                label: l10n.exercisesCreate,
                semanticLabel: l10n.exercisesCreate,
                leading:
                    const Icon(Icons.add, size: 18, color: AtemColors.cyan),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ExerciseFormScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return list;
    return Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(child: list),
    );
  }

  /// Nachtragen ohne Sätze — der Weg zu [StrengthFormScreen].
  Future<void> _logWithoutSets(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const StrengthFormScreen()),
      );

  Future<void> _startFree(BuildContext context) async {
    final request = await StartSheet.show(
      context,
      restSeconds: ref.read(defaultRestSecondsProvider),
    );
    if (request != null) onStart(request);
  }

  /// Startet die geplante Einheit von heute — **mit ihrem Plan**.
  ///
  /// Der Termin trägt eine `planId`; die Vorgänger-App schreibt sie beim
  /// Anlegen (`js/views/calendar.js`, `addPlanToDateById`). Nur
  /// Schnelleinträge haben keine.
  ///
  /// Findet sich der Plan nicht — gelöscht, oder ein Schnelleintrag —, wird
  /// daraus ein freies Training **mit erhaltenem Termin**: Die Einheit soll
  /// den Kalendereintrag trotzdem abhaken.
  Future<void> _startToday(BuildContext context, TodaySession session) async {
    final plans = ref.read(plansProvider).value ?? const <Plan>[];
    final plan = plans.where((p) => p.id == session.planId).firstOrNull;

    final request = await StartSheet.show(
      context,
      plan: plan,
      scheduleId: session.id,
      restSeconds: ref.read(defaultRestSecondsProvider),
    );
    if (request != null) onStart(request);
  }

  void _openPlans(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlanListScreen(onStart: onStart),
        ),
      );

  /// Startet einen Plan aus seiner Karte — derselbe Weg wie im Plandetail:
  /// erst das Start-Blatt, dann der Runner.
  Future<void> _startPlan(BuildContext context, Plan plan) async {
    final request = await StartSheet.show(
      context,
      plan: plan,
      restSeconds: ref.read(defaultRestSecondsProvider),
    );
    if (request != null) onStart(request);
  }

  /// Die Muskeln eines Plans, nach Häufigkeit über seine Übungen.
  static List<MuscleGroup> _musclesOf(
      Plan plan, Map<String, Exercise> exercisesById) {
    final counts = <MuscleGroup, int>{};
    for (final item in plan.items) {
      final exercise = exercisesById[item.exerciseId];
      if (exercise == null) continue;
      for (final m in exercise.displayMuscles) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(3).toList();
  }

  void _openPlan(BuildContext context, Plan plan) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlanDetailScreen(plan: plan, onStart: onStart),
        ),
      );
}

/// Die ersten Treffer der Suche.
///
/// Zeigt höchstens [limit] Zeilen. Mehr wäre eine zweite Übungsliste mitten im
/// Tab — und der Weg in die vollständige steht bereits im Abschnittskopf.
class _ExerciseMatches extends StatelessWidget {
  const _ExerciseMatches({required this.matches, required this.limit});

  final List<Exercise> matches;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    if (matches.isEmpty) {
      return _PlainEmpty(
        title: l10n.exercisesNoMatchTitle,
        body: l10n.exercisesNoMatchBody,
      );
    }

    final visible = matches.take(limit).toList();

    // **Keine Karte in der Karte** (seit 17.09.2026): Die Treffer stehen
    // schon im Übungsblock. Eine zweite Kartenkante mit eigenem Radius
    // machte zwei Ränder übereinander und zog das Innenpolster doppelt ein.
    // Trennlinien oben und zwischen den Zeilen genügen.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          const Divider(height: 1, thickness: 1, color: AtemColors.border),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: ExerciseRow(
              exercise: visible[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExerciseDetailScreen(exercise: visible[i]),
                ),
              ),
            ),
          ),
        ],
        const Divider(height: 1, thickness: 1, color: AtemColors.border),
      ],
    );
  }
}

/// Ein Leerzustand **innerhalb** eines Blocks — ohne Symbol, ohne Karte,
/// und ohne abgeschnittenen Satz.
///
/// `AtemEmptyState` kürzt den Text nach zwei Zeilen mit „…" und bringt ein
/// eigenes Polster von 24 dp mit. In einem Abschnitt der Seite ist beides zu
/// viel: Der Satz muss ganz stehen, und das Polster kommt vom Abschnitt.
class _PlainEmpty extends StatelessWidget {
  const _PlainEmpty({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $body',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AtemType.titleMedium.of(context)),
              const SizedBox(height: 4),
              Text(body, style: AtemType.labelSmall.of(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Die Startkarte des Kraft-Tabs — **drei Wege ins Training, kein Tagesplan**.
///
/// ## Warum hier nichts mehr über „heute" steht
///
/// Bis zum 18.09.2026 eröffnete eine Heute-Karte den Tab: „Heute ist nichts
/// geplant", „Ruhetag — oder Platz für eine freie Session". Sie versprach
/// eine Planung, die es in ATEM nicht gibt — Termine stammen aus der
/// Vorgänger-App, anlegen kann man sie hier nicht. Der Tag steht jetzt auf dem
/// Hybrid-Tab neben der Woche ([TodayWeekCard]); hier steht nur noch, was der
/// Tab kann: anfangen.
///
/// ## Ruhiger Block, keine Hervorhebung
///
/// Sie trägt bewusst keinen Gradient-Rand mehr. Auf dieser Seite gibt es
/// nichts zu betonen — drei Wege stehen nebeneinander, und die Rangfolge
/// steckt schon in Gradient-Knopf, Umriss-Knopf und Textlink.
class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.session,
    required this.onStartToday,
    required this.onFree,
    required this.onPickPlan,
    required this.onLogWithoutSets,
  });

  /// Der Termin von heute, falls die Vorgänger-App einen trägt. Er ändert
  /// nur die Beschriftung des ersten Knopfes — mehr sagt die Karte nicht
  /// über den Tag.
  final TodaySession? session;

  /// Startet den Termin. `null`, wenn keiner vorliegt.
  final VoidCallback? onStartToday;

  final VoidCallback onFree;
  final VoidCallback onPickPlan;
  final VoidCallback onLogWithoutSets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final today = session;
    final hasToday = today != null && onStartToday != null;

    return AtemCard.list(
      padding: const EdgeInsets.all(AtemSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mit Termin führt der erste Weg dorthin, und der Planname steht
          // im Vorlese-Label (Board 05, F). Ohne Termin ist freies Training
          // der erste Weg — nicht „nichts geplant".
          AtemButton.gradient(
            label: hasToday ? l10n.workoutsStart : l10n.workoutsFreeStart,
            semanticLabel: hasToday
                ? '${l10n.workoutsStart}: ${today.title}'
                : l10n.workoutsFreeStart,
            size: AtemButtonSize.compact,
            onPressed: hasToday ? onStartToday : onFree,
          ),
          const SizedBox(height: 8),
          AtemButton.outline(
            label: hasToday ? l10n.workoutsFree : l10n.workoutsPlanPick,
            semanticLabel:
                hasToday ? l10n.workoutsFreeStart : l10n.workoutsPlanPick,
            size: AtemButtonSize.compact,
            onPressed: hasToday ? onFree : onPickPlan,
          ),
          _LogWithoutSetsLink(onPressed: onLogWithoutSets),
        ],
      ),
    );
  }
}

/// „Ohne Sätze erfassen" — **in** der ersten Karte, als dritter Weg.
///
/// Seit 16.09.2026 steht er in der Karte statt als eigener Knopf darunter:
/// Alle Wege, eine Einheit anzulegen, gehören an eine Stelle. Er ist ein
/// Textlink unter einer Trennlinie und kein dritter gleich breiter Knopf —
/// nachtragen ist seltener als trainieren, und drei gleich gewichtete Knöpfe
/// untereinander liessen keine Rangfolge erkennen.
class _LogWithoutSetsLink extends StatelessWidget {
  const _LogWithoutSetsLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const SizedBox(height: 1, child: ColoredBox(color: AtemColors.border)),
        AtemTappable(
          onTap: onPressed,
          semanticLabel: l10n.strengthFormTitle,
          minTapSize: const Size(0, 48),
          alignment: Alignment.centerLeft,
          child: Padding(
            // Unten ohne Polster: Die Karte bringt ihres mit, und die Zeile
            // endet sonst sichtbar tiefer als der Inhalt der Karte.
            padding: const EdgeInsets.only(top: 12, bottom: 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.strengthFormEntry,
                    style: AtemType.labelUi
                        .of(context)
                        .copyWith(color: AtemColors.textTertiary),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: AtemColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    AtemTextRole? role,
  }) : _role = role;

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Standard ist der Mono-Kopf. Ein Titel mit Zahl übergibt
  /// [AtemType.meta] — dann ohne Versalien.
  final AtemTextRole? _role;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;
    final titleText = Text(
      title,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: (_role ?? AtemType.labelMicro).of(context),
    );
    if (!hasAction) return titleText;

    // **Eine Grundlinie, Aktion rechtsbündig** (seit 17.09.2026). Vorher
    // standen Mono-Kopf und Aktion zentriert zueinander; weil beide
    // verschieden gross sind, sass „Alle 4" sichtbar höher als „PLÄNE".
    //
    // Passen beide nicht nebeneinander (200 % Schrift auf 320 dp), wird
    // nicht der Titel gekürzt — die Aktion rutscht rechtsbündig darunter.
    final titleStyle = (_role ?? AtemType.labelMicro).of(context);
    final actionStyle =
        AtemType.labelUi.of(context).copyWith(color: AtemColors.cyan);
    final action = AtemTappable(
      onTap: onAction,
      semanticLabel: actionLabel!,
      minTapSize: const Size(48, 48),
      alignment: Alignment.centerRight,
      child: Text(
        actionLabel!,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.right,
        style: actionStyle,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        double widthOf(String text, TextStyle style) => (TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout())
                .width;
        final fits = widthOf(title, titleStyle) +
                12 +
                widthOf(actionLabel!, actionStyle) <=
            constraints.maxWidth;

        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: titleStyle),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: titleText),
            const SizedBox(width: 12),
            action,
          ],
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
