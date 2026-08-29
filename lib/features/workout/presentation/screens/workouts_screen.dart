import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../../dashboard/domain/dashboard_data.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/muscle_balance.dart';
import '../../../history/presentation/widgets/muscle_balance_card.dart';
import '../../../plans/application/pending_plan_deletion.dart';
import '../../../plans/application/plan_providers.dart';
import '../../../plans/domain/plan.dart';
import '../../../plans/presentation/plan_bits.dart';
import '../../../plans/presentation/screens/plan_detail_screen.dart';
import '../../../plans/presentation/screens/plan_list_screen.dart';
import '../../../plans/presentation/start_sheet.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../../exercises/presentation/screens/exercise_detail_screen.dart';
import '../../../exercises/presentation/screens/exercise_form_screen.dart';
import '../../../exercises/presentation/screens/exercise_list_screen.dart';
import '../../../exercises/presentation/widgets/exercise_bits.dart';
import '../../../exercises/presentation/widgets/exercise_search.dart';

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
  const WorkoutsScreen({super.key, required this.onStart, this.embedded = false});

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

  static const _plansPreview = 3;

  /// So viele Treffer stehen im Block. Mehr wäre eine zweite Liste im Tab.
  static const _exercisePreview = 3;

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
    final exerciseCount = ref.watch(exercisesProvider).value?.length ?? 0;
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
            else if (session != null)
              _TodayCard(
                session: session,
                plan: ref
                    .watch(plansProvider)
                    .value
                    ?.where((p) => p.id == session.planId)
                    .firstOrNull,
                onStart: () => _startToday(context, session),
              )
            else
              _EmptyToday(
                onFree: () => _startFree(context),
                onPickPlan: () => _openPlans(context),
              ),
            // „Freies Training" ist gleichwertiger Eingang, kein versteckter
            // Link — direkt unter der Heute-Karte (Board 05, A1/1).
            if (session != null) ...[
              const SizedBox(height: 8),
              AtemButton.ghost(
                label: l10n.workoutsFree,
                semanticLabel: l10n.workoutsFreeStart,
                expand: true,
                onPressed: () => _startFree(context),
              ),
            ],
            const SizedBox(height: 28),
            _SectionHeader(
              title: l10n.workoutsPlansLabel.toUpperCase(),
              actionLabel:
                  plans.isEmpty ? null : l10n.workoutsPlansAll(plans.length),
              onAction: plans.isEmpty ? null : () => _openPlans(context),
            ),
            const SizedBox(height: 8),
            if (plans.isEmpty)
              AtemCard.list(
                padding: const EdgeInsets.all(18),
                child: AtemEmptyState(
                  title: l10n.workoutsTodayEmptyTitle,
                  body: l10n.workoutsTodayEmptyBody,
                ),
              )
            else
              AtemCard.list(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0;
                        i < plans.length && i < _plansPreview;
                        i++) ...[
                      if (i > 0)
                        const Divider(
                            height: 1, thickness: 1, color: AtemColors.border),
                      PlanRow(
                        plan: plans[i],
                        onTap: () => _openPlan(context, plans[i]),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 28),
            // Die Balance steht **zwischen** Plänen und Übungen: Sie
            // beantwortet weder „was mache ich jetzt" noch „was gibt es
            // sonst", sondern „was habe ich vernachlässigt" — und das ist
            // die Frage, die zwischen beiden liegt.
            MuscleBalanceCard(
              balance: MuscleBalance.compute(
                ref.watch(sessionsProvider).value ?? const [],
                ref.watch(exercisesProvider).value ?? const [],
                ref.watch(historyReferenceProvider),
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              // Die Zahl steht im Titel, nicht in der Aktion: „Übungen · 154"
              // sagt, wie gross der Bestand ist; „Alle ansehen" sagt, wohin
              // der Weg führt. Beides in einer Zeile wäre eine Zahl zu viel.
              title: l10n.exercisesBlockTitle(exerciseCount).toUpperCase(),
              actionLabel: l10n.exercisesBlockAll,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExerciseListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            // Ohne eigenes Seitenpolster: Der Block liegt schon in dem der
            // Seite, und ein zweites schöbe den ersten Chip in die Mitte.
            ExerciseFilterRow(
              selected: muscle,
              padding: EdgeInsets.zero,
              onSelect: (m) =>
                  ref.read(exerciseFilterProvider.notifier).toggle(m),
              onAll: () => ref.read(exerciseFilterProvider.notifier).clear(),
            ),
            const SizedBox(height: 10),
            _ExerciseMatches(matches: matches, limit: _exercisePreview),
            const SizedBox(height: 12),
            AtemButton.outline(
              label: l10n.exercisesCreate,
              semanticLabel: l10n.exercisesCreate,
              leading: const Icon(Icons.add, size: 18, color: AtemColors.cyan),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExerciseFormScreen(),
                ),
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
      return AtemCard.list(
        padding: const EdgeInsets.all(18),
        child: AtemEmptyState(
          title: l10n.exercisesNoMatchTitle,
          body: l10n.exercisesNoMatchBody,
        ),
      );
    }

    final visible = matches.take(limit).toList();

    return AtemCard.list(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AtemColors.border),
            ExerciseRow(
              exercise: visible[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExerciseDetailScreen(exercise: visible[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Die einzige hervorgehobene Karte des Bildschirms.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.session,
    required this.onStart,
    this.plan,
  });

  final TodaySession session;
  final VoidCallback onStart;

  /// Der Plan hinter dem Termin — für „8 ÜBUNGEN · ~45 MIN · KRAFT".
  final Plan? plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final minutes = plan?.estimatedDuration.inMinutes ?? session.duration.inMinutes;
    final meta = <String>[
      if (plan != null) l10n.exerciseCountShort(plan!.exerciseCount),
      l10n.durationApproxMinutes(minutes),
      if (trainingTypeLabel(l10n, plan?.type ?? session.intensityLabel)
          .isNotEmpty)
        trainingTypeLabel(l10n, plan?.type ?? session.intensityLabel),
    ].join(' · ');

    return AtemCard.gradientBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.workoutsTodayLabel.toUpperCase(),
              style: AtemType.labelMicro
                  .of(context)
                  .copyWith(color: AtemColors.cyan)),
          const SizedBox(height: 8),
          Text(session.title, style: AtemType.titleMedium.of(context)),
          const SizedBox(height: 8),
          Text(
            meta.toUpperCase(),
            style: AtemType.labelMicro.of(context),
          ),
          const SizedBox(height: 16),
          AtemButton.gradient(
            label: l10n.workoutsStart,
            // Der Planname gehört ins Label (Board 05, F).
            semanticLabel: '${l10n.workoutsStart}: ${session.title}',
            size: AtemButtonSize.compact,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.onFree, required this.onPickPlan});

  final VoidCallback onFree;
  final VoidCallback onPickPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    // **Gleiche Kartenposition wie die Heute-Karte, kein Warnsymbol**
    // (Board 05, A1/2). Leer ist kein Fehler; der Nutzer hat nichts falsch
    // gemacht. Zwei Wege stehen bereit, weil beide gleich naheliegen: frei
    // anfangen oder einen Plan holen.
    return AtemCard.list(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.workoutsTodayLabel.toUpperCase(),
              style: AtemType.labelMicro.of(context)),
          const SizedBox(height: 8),
          Text(l10n.emptyTodayTitle,
              style: AtemType.titleMedium.of(context)),
          const SizedBox(height: 6),
          Text(l10n.emptyTodayBody, style: AtemType.labelSmall.of(context)),
          const SizedBox(height: 16),
          AtemButton.gradient(
            label: l10n.workoutsFreeStart,
            semanticLabel: l10n.workoutsFreeStart,
            size: AtemButtonSize.compact,
            onPressed: onFree,
          ),
          const SizedBox(height: 8),
          AtemButton.outline(
            label: l10n.workoutsPlanPick,
            semanticLabel: l10n.workoutsPlanPick,
            size: AtemButtonSize.compact,
            onPressed: onPickPlan,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // Beide Seiten flexibel: Bei 200 % Schrift auf 320 dp passen Titel und
    // Aktion sonst nicht nebeneinander und laufen um 11 px über.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtemType.labelMicro.of(context),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: AtemTappable(
              onTap: onAction,
              semanticLabel: actionLabel!,
              alignment: Alignment.centerRight,
              child: Text(
                actionLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AtemType.labelSmall
                    .of(context)
                    .copyWith(color: AtemColors.cyan),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
