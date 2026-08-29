import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/history_providers.dart';
import '../../domain/training_session.dart';
import '../session_ui.dart';
import '../widgets/month_strip.dart';
import '../widgets/statement_card.dart';
import 'analysis_screen.dart';
import 'session_list_screen.dart';

/// Der Verlaufs-Tab.
///
/// **Die eine Aussage zuerst.** Wer diesen Bildschirm öffnet, will nicht einen
/// Balkenwald deuten, sondern wissen, was gerade gilt. Erst danach kommen
/// Verteilung und Einzelheiten.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, this.embedded = false});

  /// Als Segment „Verlauf" im Kraft-Tab (Modul 11): kein eigener Rahmen,
  /// kein eigener Titel — der Verlauf ist ein Segment, kein Tab.
  final bool embedded;

  static const _recentCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(sessionsProvider);

    final body = async.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtemSpacing.screenPadding),
            child: AtemSkeleton(
              semanticLabel: l10n.dashboardLoadingA11y,
              blocks: const [
                AtemSkeletonBlock(height: 140),
                AtemSkeletonBlock(height: 120),
                AtemSkeletonBlock(height: 64, radius: 14),
                AtemSkeletonBlock(height: 64, radius: 14),
              ],
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtemSpacing.screenPadding),
            child: AtemErrorState(
              title: l10n.historyErrorTitle,
              body: l10n.historyErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(sessionStreamProvider),
            ),
          ),
          data: (sessions) => _content(context, ref, l10n, sessions),
        );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(child: body),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    List<TrainingSession> sessions,
  ) {
    if (sessions.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
        child: AtemEmptyState(
          title: l10n.emptyHistoryTitle,
          body: l10n.emptyHistoryBody,
        ),
      );
    }

    final summary = ref.watch(historySummaryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 130),
      children: [
        if (!embedded) ...[
          Text(l10n.historyTitle, style: AtemType.titleLarge.of(context)),
          const SizedBox(height: 20),
        ],
        StatementCard(summary: summary),
        if (summary.lastSession case final last?) ...[
          const SizedBox(height: 10),
          Text(
            l10n.historyLeadLast(
              DateFormat.E(languageTag(context)).format(last.date),
              DateFormat.yMd(languageTag(context)).format(last.date),
              sessionName(l10n, last),
            ),
            style: AtemType.labelMicro.of(context),
          ),
        ],
        const SizedBox(height: 28),
        MonthStrip(summary: summary),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l10n.historyRecentLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.labelMedium.of(context),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: AtemTappable(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SessionListScreen(),
                  ),
                ),
                semanticLabel: l10n.historyAll(summary.sessions),
                alignment: Alignment.centerRight,
                child: Text(
                  l10n.historyAll(summary.sessions),
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
        ),
        const SizedBox(height: 8),
        AtemCard.list(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < sessions.length && i < _recentCount; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1, thickness: 1, color: AtemColors.border),
                _SessionRow(session: sessions[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        AtemButton.outline(
          label: l10n.historyAnalysisOpen,
          semanticLabel: l10n.historyAnalysisOpen,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AnalysisScreen()),
          ),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final date = DateFormat.yMd(languageTag(context)).format(session.date);
    final name = sessionName(l10n, session);
    final minutes = session.duration?.inMinutes;

    return Semantics(
      label: [
        date,
        name,
        if (minutes != null) l10n.durationMinutes(minutes),
      ].join(', '),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(date,
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(letterSpacing: 0)),
              ),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.titleSmallOrDefault(context),
                ),
              ),
              if (minutes != null) ...[
                const SizedBox(width: 8),
                Text(l10n.durationMinutes(minutes),
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(letterSpacing: 0)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
