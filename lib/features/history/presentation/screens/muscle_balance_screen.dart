import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../application/history_providers.dart';
import '../../domain/muscle_balance.dart';
import '../widgets/muscle_balance_card.dart';

/// Die Muskelbalance im Detail (Board 09, A3) — erreicht über die Kachel im
/// Kraft-Tab oder in der Auswertung.
///
/// Die Kachel sagt „es gibt eine Verteilung"; diese Seite sagt, wie sie
/// aussieht: Anteil, Sätze und Abstand je Muskel, darunter die längsten
/// Abstände als eigene Karte. Das Fenster steht im Kopf, weil es für beide
/// Karten gilt.
class MuscleBalanceScreen extends ConsumerWidget {
  const MuscleBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(sessionsProvider);

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.balanceTitle, style: AtemType.titleLarge.of(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AtemSpacing.screenPadding),
            child: Center(
              child: Text(l10n.balanceWindow, style: AtemType.meta.of(context)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtemSpacing.screenPadding),
            child: AtemSkeleton(
              semanticLabel: l10n.balanceLoading,
              blocks: const [
                AtemSkeletonBlock(height: 420),
                AtemSkeletonBlock(height: 200),
              ],
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtemSpacing.screenPadding),
            child: Center(
              child: AtemErrorState(
                title: l10n.balanceErrorTitle,
                body: l10n.balanceErrorBody,
                retryLabel: l10n.analysisErrorRetry,
                onRetry: () => ref.invalidate(sessionStreamProvider),
              ),
            ),
          ),
          data: (sessions) {
            final balance = MuscleBalance.compute(
              sessions,
              ref.watch(exercisesProvider).value ?? const [],
              ref.watch(historyReferenceProvider),
            );
            if (balance.sessionsInWindow == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AtemSpacing.screenPadding),
                child: AtemEmptyState(
                  title: l10n.emptyHistoryTitle,
                  body: l10n.emptyHistoryBody,
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 40),
              children: [
                MuscleBalanceCard(balance: balance),
                if (balance.hasEnough && balance.longestGaps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  MuscleGapsCard(balance: balance),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
