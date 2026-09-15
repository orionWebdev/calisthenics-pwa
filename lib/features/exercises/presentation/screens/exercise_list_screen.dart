import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/exercise_providers.dart';
import '../../domain/exercise.dart';
import '../../domain/muscle.dart';
import '../muscle_ui.dart';
import '../widgets/exercise_bits.dart';
import '../widgets/exercise_search.dart';
import 'exercise_detail_screen.dart';
import 'exercise_form_screen.dart';

/// Die Übungsliste: Suche, Regionsfilter, gemischte Sprachen.
class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  static const routeName = '/exercises';

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(exercisesProvider);
    final filtered = ref.watch(filteredExercisesProvider);
    final muscle = ref.watch(exerciseFilterProvider);
    final origin = ref.watch(exerciseOriginProvider);
    final query = ref.watch(exerciseQueryProvider);
    final all = async.value ?? const <Exercise>[];
    final own = all.where((e) => e.isOwn).length;
    final filtered_ = muscle != null || origin != ExerciseOrigin.all;

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title:
            Text(l10n.exercisesTitle, style: AtemType.titleMedium.of(context)),
        actions: [
          // Im Kopf und nicht am Fuß: Die Liste ist lang, und ein Knopf unter
          // ihr wäre nur nach einer Reise durch 154 Zeilen erreichbar.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AtemTappable(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExerciseFormScreen(),
                ),
              ),
              semanticLabel: l10n.exercisesCreate,
              child: const Icon(Icons.add, size: 22, color: AtemColors.cyan),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 12),
              child: ExerciseSearchField(
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
            ),
            // Eigen / Kuratiert (Board 07, A1/3): Nur eine der beiden
            // Mengen ist bearbeitbar — wer aufräumen will, filtert auf 70.
            _OriginRow(origin: origin, all: all.length, own: own),
            const SizedBox(height: 8),
            ExerciseFilterRow(
              selected: muscle,
              onSelect: (m) =>
                  ref.read(exerciseFilterProvider.notifier).toggle(m),
              onAll: () => ref.read(exerciseFilterProvider.notifier).clear(),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AtemSpacing.screenPadding),
              // Das Ergebnis ist hörbar, nicht nur sichtbar (Board 05, F):
              // nach jedem Filterwechsel eine höfliche Ansage.
              child: Semantics(
                liveRegion: true,
                label: _countLine(l10n, all, filtered, muscle),
                child: ExcludeSemantics(
                  excluding: !filtered_,
                  // Wrap statt Row: „Zurücksetzen" ist bei 200 % Schrift auf
                  // 320 dp breiter als der Rest der Zeile übrig lässt.
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          _countLine(l10n, all, filtered, muscle),
                          style: AtemType.meta.of(context),
                        ),
                      ),
                      // „Zurücksetzen" steht neben dem Ergebnis, nicht im
                      // Chip-Band versteckt (Board 05, A2/2).
                      if (filtered_)
                        AtemTappable(
                          onTap: () {
                            ref.read(exerciseFilterProvider.notifier).clear();
                            ref
                                .read(exerciseOriginProvider.notifier)
                                .set(ExerciseOrigin.all);
                          },
                          semanticLabel: l10n.exercisesFilterReset,
                          alignment: Alignment.centerRight,
                          child: Text(l10n.exercisesFilterReset,
                              style: AtemType.labelSmall
                                  .of(context)
                                  .copyWith(color: AtemColors.cyan)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: async.when(
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AtemSpacing.screenPadding),
                  child: AtemSkeleton(
                    semanticLabel: l10n.dashboardLoadingA11y,
                    blocks: const [
                      AtemSkeletonBlock(height: 64, radius: 14),
                      AtemSkeletonBlock(height: 64, radius: 14),
                      AtemSkeletonBlock(height: 64, radius: 14),
                      AtemSkeletonBlock(height: 64, radius: 14),
                    ],
                  ),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AtemSpacing.screenPadding),
                  child: AtemErrorState(
                    title: l10n.listErrorTitle,
                    body: l10n.listErrorBody,
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(exercisesProvider),
                  ),
                ),
                data: (_) => filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AtemSpacing.screenPadding),
                        // Gefiltert auf „Eigen" und nichts da: Der Text nennt
                        // vorab die drei Pflichtfelder (Board 07, A1/4).
                        child: origin == ExerciseOrigin.own &&
                                query.isEmpty &&
                                muscle == null
                            ? AtemEmptyState(
                                title: l10n.exercisesEmptyOwnTitle,
                                body: l10n.exercisesEmptyOwnBody,
                                action: AtemButton.gradient(
                                  label: l10n.exercisesCreate,
                                  semanticLabel: l10n.exercisesCreate,
                                  expand: false,
                                  size: AtemButtonSize.compact,
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const ExerciseFormScreen(),
                                    ),
                                  ),
                                ),
                              )
                            : AtemEmptyState(
                          // Board 02: Der Leerzustand nennt **beides** — den
                          // Begriff und die Zahl der Filter. „Keine Treffer"
                          // lässt offen, woran es lag.
                          title: l10n.emptySearchTitle,
                          body: l10n.emptySearchBody(
                            query,
                            muscle == null ? 0 : 1,
                          ),
                          // Die Handlung erscheint nur, wenn sie etwas
                          // bewirkt: Ohne Filter und ohne Suche gibt es
                          // nichts zurückzusetzen.
                          action: muscle == null && query.isEmpty
                              ? null
                              : AtemButton.outline(
                                  label: l10n.emptySearchCta,
                                  semanticLabel: l10n.emptySearchCta,
                                  expand: false,
                                  size: AtemButtonSize.compact,
                                  onPressed: () {
                                    _search.clear();
                                    ref
                                        .read(exerciseQueryProvider.notifier)
                                        .clear();
                                    ref
                                        .read(exerciseFilterProvider.notifier)
                                        .clear();
                                    ref
                                        .read(exerciseOriginProvider.notifier)
                                        .set(ExerciseOrigin.all);
                                  },
                                ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AtemSpacing.screenPadding,
                            0,
                            AtemSpacing.screenPadding,
                            24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: AtemColors.border,
                        ),
                        itemBuilder: (context, i) => ExerciseRow(
                          exercise: filtered[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ExerciseDetailScreen(exercise: filtered[i]),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _countLine(
    AppL10n l10n,
    List<Exercise> all,
    List<Exercise> filtered,
    MuscleGroup? muscle,
  ) {
    final origin = ref.read(exerciseOriginProvider);
    if (origin != ExerciseOrigin.all && muscle == null) {
      return l10n.exercisesFilterResult(
        filtered.length,
        origin == ExerciseOrigin.own
            ? l10n.exercisesOwnTag
            : l10n.exerciseCuratedBadge,
      );
    }
    if (muscle != null) {
      return l10n.exercisesFilterResult(filtered.length, muscle.label(l10n));
    }
    if (filtered.length != all.length) {
      return l10n.exerciseCountShort(filtered.length);
    }
    final own = all.where((e) => e.isOwn).length;
    return l10n.exercisesCount(all.length, all.length - own, own);
  }
}


/// Die Herkunftschips: Alle · Eigen · Kuratiert, mit Zahlen.
class _OriginRow extends ConsumerWidget {
  const _OriginRow({required this.origin, required this.all, required this.own});

  final ExerciseOrigin origin;
  final int all;
  final int own;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final entries = [
      (ExerciseOrigin.all, l10n.exercisesFilterAll, all),
      (ExerciseOrigin.own, l10n.exercisesOwnTag, own),
      (ExerciseOrigin.curated, l10n.exerciseCuratedBadge, all - own),
    ];

    return Semantics(
      container: true,
      label: l10n.exercisesFilterOrigin,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label, count) in entries)
              AtemTappable(
                onTap: value == origin
                    ? null
                    : () => ref.read(exerciseOriginProvider.notifier).set(value),
                semanticLabel: '$label, ${l10n.exerciseCountShort(count)}',
                selected: value == origin,
                inMutuallyExclusiveGroup: true,
                minTapSize: const Size(48, 48),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: value == origin
                        ? AtemColors.cyan.withValues(alpha: 0.08)
                        : AtemColors.card,
                    borderRadius: BorderRadius.circular(AtemRadii.pill),
                    border: Border.all(
                      color: value == origin
                          ? AtemColors.cyan.withValues(alpha: 0.35)
                          : AtemColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (value == origin) ...[
                        const Icon(Icons.check, size: 13, color: AtemColors.cyan),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          '$label $count',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtemType.labelUi.of(context).copyWith(
                                color: value == origin
                                    ? AtemColors.cyan
                                    : AtemColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
