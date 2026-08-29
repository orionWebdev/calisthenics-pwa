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
    final query = ref.watch(exerciseQueryProvider);
    final all = async.value ?? const <Exercise>[];

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
              child: Text(
                _countLine(l10n, all, filtered, muscle),
                style: AtemType.labelMicro.of(context),
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
                        child: AtemEmptyState(
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
