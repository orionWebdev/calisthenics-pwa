import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../../dashboard/domain/dashboard_data.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/presentation/screens/exercise_list_screen.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../../planning/application/week_plan_providers.dart';
import '../../../planning/domain/week_plan.dart';
import '../../../planning/presentation/week_ui.dart' show WeekWords;
import '../../../plans/application/pending_plan_deletion.dart';
import '../../../plans/application/plan_providers.dart';
import '../../../plans/domain/plan.dart';
import '../../../plans/presentation/plan_bits.dart';
import '../../../plans/presentation/screens/plan_form_screen.dart';
import '../../../plans/presentation/screens/plan_list_screen.dart';
import '../../../plans/presentation/start_sheet.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../strength/presentation/screens/strength_form_screen.dart';

/// Das Thema „Trainieren" — **ein Gegenstand mit einem Knopf** (Board 17).
///
/// ## Zwei Gegenstände statt drei Bauformen
///
/// Bis zum 21.09.2026 standen hier drei gleichrangige Objekte untereinander:
/// eine Karte mit Gradient-Rand, zwei Halbkarten, zwei Zeilen mit Chevron.
/// Die Gewichtung nach Häufigkeit war richtig, die Form nicht — drei Ränder,
/// drei Radien, drei Anfänge.
///
/// Jetzt trägt der [AtemStartBlock] alle drei Gewichtsklassen in einer
/// Karte: Kopf (woran man heute ist), Knopf (der eine Weg), Fuss (die zwei
/// Umwege). Darunter liegt das **Kachelpaar** für die beiden echten
/// Unterseiten — Übungen und Training planen — als [AtemSplit].
///
/// „Nachtragen" ist dabei aus der Zeilenklasse in den Fuss gewandert: Es
/// erzeugt eine Einheit, genau wie der Startknopf, und gehört deshalb in
/// denselben Gegenstand (Entscheidung 5).
///
/// ## Die Kadenz
///
/// Schwerster Block zuerst, leichtestes Element zuletzt — der Startblock,
/// dann die Kacheln. Dadurch fällt die Masse zur Zäsur hin ab und springt
/// direkt danach auf den Gipfel des nächsten Themas (Board 17, Abschnitt D).
class TrainSection extends ConsumerWidget {
  const TrainSection({super.key, required this.onStart});

  /// Trägt die Startanfrage nach oben. Das Thema kennt den Runner nicht.
  final ValueChanged<StartRequest> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final dashboard = ref.watch(dashboardDataProvider);
    final plans = ref.watch(visiblePlansProvider).value ?? const <Plan>[];
    // **Heute aus derselben Ableitung wie das Hybrid-Widget** (Board 19,
    // F2), nur auf Kraft gefiltert: Ist heute Cardio oder „Frei", schweigt
    // der Kraft-Tab darüber und zeigt „Zuletzt" — er sagt weniger, nie
    // etwas anderes.
    final todayItem = (ref.watch(todayPlanProvider).value ?? const [])
        .where((i) => i.kind == WeekKind.strength)
        .firstOrNull;
    final session = todayItem?.source == TodaySource.appointment
        ? dashboard.value?.session
        : null;
    final weekEntry = todayItem?.entry;
    final hasToday = session != null || weekEntry != null;
    final todayTitle = session?.title ??
        (weekEntry == null ? null : WeekWords(context).title(weekEntry, plans));
    final hasPlans = plans.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 16, AtemSpacing.screenPadding, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemEntrance(
            child: AtemStartBlock(
              head: _head(context, ref, l10n, dashboard, plans, weekEntry),
              ctaLabel: hasToday
                  ? l10n.sheetStart.toUpperCase()
                  : l10n.trainStartFree.toUpperCase(),
              ctaSemanticLabel: hasToday
                  ? l10n.trainStartA11yPlanned(todayTitle!)
                  : l10n.trainStartA11yFree,
              onStart: () => session != null
                  ? _startToday(context, ref, session)
                  : weekEntry != null
                      ? _startWeek(context, ref, weekEntry)
                      : _startFree(context, ref),
              // **Der Fuss wiederholt nie die Handlung des Knopfs**: Links
              // steht, was der Knopf gerade nicht tut.
              footLeft: hasToday
                  ? AtemStartFoot(
                      icon: Icons.play_arrow_rounded,
                      label: l10n.trainFreeTitle,
                      onTap: () => _startFree(context, ref),
                    )
                  : hasPlans
                      ? AtemStartFoot(
                          icon: Icons.list_alt_rounded,
                          label: l10n.workoutsPlanPick,
                          onTap: () => _openPlans(context),
                        )
                      : AtemStartFoot(
                          icon: Icons.add,
                          label: l10n.trainFootNewPlan,
                          onTap: () => _newPlan(context),
                        ),
              footRight: AtemStartFoot(
                icon: Icons.edit_calendar_outlined,
                label: l10n.trainFootLog,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StrengthFormScreen(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AtemEntrance(
            index: 1,
            child: AtemSplit(
              left: _Tile(
                icon: Icons.fitness_center,
                title: l10n.trainTileExercises,
                meta: l10n.trainTileExercisesMeta(
                    ref.watch(exercisesProvider).value?.length ?? 0),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ExerciseListScreen(),
                  ),
                ),
              ),
              right: _Tile(
                icon: Icons.event_note_outlined,
                title: l10n.trainTilePlan,
                meta: hasPlans
                    ? l10n.trainTilePlanMeta(plans.length)
                    : l10n.trainTilePlanMetaNone,
                onTap: () =>
                    hasPlans ? _openPlans(context) : _newPlan(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Der Zustand steckt im Kopf** — vier Füllungen, eine Zone.
  ///
  /// Die Reihenfolge ist die der Verlässlichkeit: Ein Fehler verdeckt den
  /// Plan, ein laufender Abruf verdeckt die letzte Einheit, und wo es weder
  /// Termin noch Verlauf gibt, rendert die Zone gar nicht.
  AtemStartHead? _head(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    AsyncValue<DashboardData> dashboard,
    List<Plan> plans,
    WeekEntry? weekEntry,
  ) {
    if (dashboard.hasError) {
      return AtemStartHead.failed(
        kicker: l10n.trainErrorKicker,
        title: l10n.trainErrorTitle,
        meta: l10n.trainErrorMeta(
            DateFormat.Hm(languageTag(context)).format(DateTime.now())),
        semanticLabel: '${l10n.trainErrorTitle}. ${l10n.trainErrorKicker}',
        retryLabel: l10n.commonRetry,
        onRetry: () => ref.invalidate(dashboardDataProvider),
      );
    }
    if (dashboard.isLoading) {
      return AtemStartHead.loading(semanticLabel: l10n.trainLoadingA11y);
    }

    // Aus der Woche: Titel und Umfang wie in der Woche, dazu die Quelle.
    if (weekEntry != null) {
      final words = WeekWords(context);
      final plan = words.planOf(weekEntry, plans);
      final title = words.title(weekEntry, plans);
      return AtemStartHead.fact(
        kicker: l10n.trainTodayKicker,
        title: title,
        meta: [
          plan == null
              ? l10n.weekStrengthNoPlan
              : planMetaLine(l10n, plan, withDuration: true),
          l10n.trainTodaySourceWeek,
        ].join(' · '),
        toned: true,
        semanticLabel: plan == null
            ? l10n.trainBlockA11yPlannedPlain(title)
            : l10n.trainBlockA11yPlanned(title, plan.exerciseCount,
                plan.estimatedDuration.inMinutes),
      );
    }

    final today = dashboard.value?.session;
    if (today != null) {
      final plan = plans.where((p) => p.id == today.planId).firstOrNull;
      return AtemStartHead.fact(
        kicker: l10n.trainTodayKicker,
        title: today.title,
        // Ohne den Plan bleibt die Zeile leer statt zu raten; die Quelle
        // steht immer dabei (Board 19, F2).
        meta: plan == null
            ? l10n.trainTodaySourceAppointment
            : '${planMetaLine(l10n, plan, withDuration: true)} · '
                '${l10n.trainTodaySourceAppointment}',
        toned: true,
        semanticLabel: plan == null
            ? l10n.trainBlockA11yPlannedPlain(today.title)
            : l10n.trainBlockA11yPlanned(today.title, plan.exerciseCount,
                plan.estimatedDuration.inMinutes),
      );
    }

    final last = _lastSession(ref);
    if (last == null) return null;

    final days = _daysAgo(ref, last.date);
    final minutes = last.duration?.inMinutes;
    final exercises = last is StrengthSession && last.exercises.isNotEmpty
        ? last.exercises.length
        : null;
    final name = sessionName(l10n, last);

    return AtemStartHead.fact(
      kicker: l10n.trainLastKicker,
      title: name,
      meta: switch ((exercises, minutes)) {
        (final int e, final int m) => l10n.trainLastMeta(days, e, m),
        (null, final int m) => l10n.trainLastMetaShort(days, m),
        _ => l10n.trainLastMetaBare(days),
      },
      // **Keine Ansage über einen fehlenden Plan** — es fehlt nichts.
      semanticLabel: l10n.trainBlockA11yLast(name, days),
    );
  }

  /// Die jüngste Einheit — die Liste kommt absteigend, aber darauf verlässt
  /// sich hier nichts.
  static TrainingSession? _lastSession(WidgetRef ref) {
    final all = ref.watch(sessionsProvider).value ?? const <TrainingSession>[];
    TrainingSession? newest;
    for (final s in all) {
      if (newest == null || s.date.isAfter(newest.date)) newest = s;
    }
    return newest;
  }

  /// Ganze Tage zwischen zwei lokalen Mitternachten — nicht 24-Stunden-
  /// Schritte, sonst hiesse gestern Abend „heute".
  static int _daysAgo(WidgetRef ref, DateTime date) {
    final now = ref.watch(historyReferenceProvider);
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(date.year, date.month, date.day);
    return a.difference(b).inDays.clamp(0, 9999);
  }

  Future<void> _startFree(BuildContext context, WidgetRef ref) async {
    final request = await StartSheet.show(
      context,
      restSeconds: ref.read(defaultRestSecondsProvider),
    );
    if (request != null) onStart(request);
  }

  /// Startet die geplante Einheit von heute — **mit ihrem Plan**.
  ///
  /// Findet sich der Plan nicht — gelöscht, oder ein Schnelleintrag —, wird
  /// daraus ein freies Training **mit erhaltenem Termin**: Die Einheit soll
  /// den Kalendereintrag trotzdem abhaken.
  Future<void> _startToday(
      BuildContext context, WidgetRef ref, TodaySession session) async {
    final all = ref.read(plansProvider).value ?? const <Plan>[];
    final plan = all.where((p) => p.id == session.planId).firstOrNull;

    final request = await StartSheet.show(
      context,
      plan: plan,
      scheduleId: session.id,
      restSeconds: ref.read(defaultRestSecondsProvider),
    );
    if (request != null) onStart(request);
  }

  /// Startet den Kraft-Eintrag von heute aus der Woche — mit seinem Plan,
  /// wenn es ihn noch gibt, sonst als freies Training. Kein Termin: Die
  /// Woche legt keine an (Board 19, Regel 2).
  Future<void> _startWeek(
      BuildContext context, WidgetRef ref, WeekEntry entry) async {
    final all = ref.read(plansProvider).value ?? const <Plan>[];
    final plan = all.where((p) => p.id == entry.planId).firstOrNull;
    final request = await StartSheet.show(
      context,
      plan: plan,
      restSeconds: ref.read(defaultRestSecondsProvider),
    );
    if (request != null) onStart(request);
  }

  void _openPlans(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlanListScreen(onStart: onStart),
        ),
      );

  void _newPlan(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PlanFormScreen()),
      );
}

/// Eine der beiden Kacheln — **K3 in halber Breite**.
///
/// Symbolkasten, Titel, eine Zahl, die ihre Grundlage nennt. Der Glyph ist
/// cyan: Die Kachel ist eine Handlung, kein Ort (Board 17, Abschnitt F).
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String meta;
  final VoidCallback onTap;

  static const minHeight = 88.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemTappable(
      onTap: onTap,
      // Titel und Zahl als **ein** Knoten, nicht als zwei.
      semanticLabel: l10n.trainTileExercisesA11y(title, meta),
      minTapSize: const Size(0, minHeight),
      pressBuilder: (context, pressed) => AnimatedContainer(
        duration: AtemMotion.duration(context, AtemMotion.fast),
        decoration: BoxDecoration(
          borderRadius: AtemRadii.cardR,
          boxShadow:
              pressed ? AtemGlow.soft(AtemColors.cyan, opacity: 0.3) : const [],
        ),
        child: _TileBody(icon: icon, title: title, meta: meta),
      ),
      child: _TileBody(icon: icon, title: title, meta: meta),
    );
  }
}

class _TileBody extends StatelessWidget {
  const _TileBody({
    required this.icon,
    required this.title,
    required this.meta,
  });

  final IconData icon;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: _Tile.minHeight),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: AtemRadii.cardR,
          border: Border.all(color: AtemColors.border),
        ),
        // `stretch`, nicht `start`: Sonst nimmt die Spalte nur die Breite
        // ihres längsten Wortes an, und die Kachel stünde als Streifen in
        // ihrer Spalte — `AtemTappable` legt sein Kind lose in die
        // Trefferfläche.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AtemColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AtemRadii.iconBox),
                ),
                child: Icon(icon, size: 18, color: AtemColors.cyan),
              ),
            ),
            const SizedBox(height: 10),
            Text(title, style: AtemType.titleSmallOrDefault(context)),
            const SizedBox(height: 2),
            Text(meta, style: AtemType.meta.of(context)),
          ],
        ),
      );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
