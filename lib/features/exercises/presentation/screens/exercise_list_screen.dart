import 'dart:math' as math;

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
import 'exercise_detail_screen.dart';

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
    final region = ref.watch(exerciseFilterProvider);
    final query = ref.watch(exerciseQueryProvider);
    final all = async.value ?? const <Exercise>[];

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title:
            Text(l10n.exercisesTitle, style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 12),
              child: _SearchField(
                controller: _search,
                onChanged: (v) =>
                    ref.read(exerciseQueryProvider.notifier).set(v),
                onClear: () {
                  _search.clear();
                  ref.read(exerciseQueryProvider.notifier).clear();
                },
              ),
            ),
            _FilterRow(
              selected: region,
              onSelect: (r) =>
                  ref.read(exerciseFilterProvider.notifier).toggle(r),
              onAll: () => ref.read(exerciseFilterProvider.notifier).clear(),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AtemSpacing.screenPadding),
              child: Text(
                _countLine(l10n, all, filtered, region),
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
                          title: l10n.exercisesEmptyTitle,
                          body: query.isEmpty
                              ? l10n.workoutsTodayEmptyBody
                              : l10n.exercisesEmptyBody(query),
                          // Die Handlung erscheint nur, wenn sie etwas
                          // bewirkt: Ohne Filter und ohne Suche gibt es
                          // nichts zurückzusetzen.
                          action: region == null && query.isEmpty
                              ? null
                              : AtemButton.outline(
                                  label: l10n.exercisesFilterReset,
                                  semanticLabel: l10n.exercisesFilterReset,
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
    MuscleRegion? region,
  ) {
    if (region != null) {
      return l10n.exercisesFilterResult(filtered.length, region.label(l10n));
    }
    if (filtered.length != all.length) {
      return l10n.exerciseCountShort(filtered.length);
    }
    final own = all.where((e) => e.isOwn).length;
    return l10n.exercisesCount(all.length, all.length - own, own);
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AtemType.body.of(context),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.exercisesSearchHint,
        hintStyle: AtemType.body.of(context).copyWith(
              color: AtemColors.textSecondary,
            ),
        filled: true,
        fillColor: AtemColors.card,
        isDense: true,
        // **48 dp, nicht 44.** Die Spezifikationstabelle nennt 44 dp für das
        // Suchfeld — das widerspricht ihrer eigenen Randbedingung „Tap ≥ 48 dp"
        // und dem A11y-Vertrag R3. Der Vertrag gewinnt; die Prüfmatrix hat den
        // Widerspruch bei 320 und 360 dp aufgedeckt.
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: _border(AtemColors.border),
        focusedBorder: _border(AtemColors.cyan, width: 1.5),
        // Erst ab dem ersten Zeichen — ein Löschknopf an einem leeren Feld ist
        // eine Aktion ohne Wirkung.
        suffixIcon: controller.text.isEmpty
            ? null
            : AtemTappable(
                onTap: onClear,
                semanticLabel: l10n.exercisesFilterReset,
                child: const Icon(Icons.close,
                    size: 18, color: AtemColors.textSecondary),
              ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AtemRadii.statBoxR,
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Die Filterzeile. „Alle" steht fest an Position 1, der Rest scrollt.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onSelect,
    required this.onAll,
  });

  final MuscleRegion? selected;
  final ValueChanged<MuscleRegion> onSelect;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    // Eine waagerechte Liste braucht eine feste Höhe — die darf aber nicht
    // fest bleiben: Bei 200 % Schrift wachsen die Chips, und 48 dp liefen um
    // 25 px über. Die Höhe folgt deshalb der Schriftskalierung.
    final height = math.max(
      48.0,
      MediaQuery.textScalerOf(context).scale(20) + 28,
    );

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
        children: [
          _Chip(
            label: l10n.exercisesFilterAll,
            selected: selected == null,
            onTap: onAll,
          ),
          for (final region in MuscleRegion.values) ...[
            const SizedBox(width: 8),
            _Chip(
              label: region.label(l10n),
              color: region.color,
              selected: selected == region,
              onTap: () => onSelect(region),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AtemColors.cyan;

    return AtemTappable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        constraints: const BoxConstraints(minHeight: 36),
        decoration: BoxDecoration(
          color: selected ? AtemCategories.surface(tint) : AtemColors.card,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: selected ? AtemCategories.border(tint) : AtemColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Der Punkt zeigt die Farbe auch im nicht gewählten Zustand — so
            // ist die Zuordnung Region/Farbe lernbar, bevor man tippt.
            if (color != null && !selected) ...[
              ExcludeSemantics(child: AtemStatusDot(color: tint)),
              const SizedBox(width: 8),
            ],
            if (selected) ...[
              Icon(Icons.check, size: 14, color: tint),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AtemType.labelSmall.of(context).copyWith(
                    color: selected ? tint : AtemColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
