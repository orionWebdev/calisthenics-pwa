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
import '../widgets/muscle_balance_card.dart';
import 'session_detail_screen.dart';
import 'session_list_screen.dart';

/// Der Verlauf — Seite 2 des Kraft-Tabs.
///
/// Drei Blöcke: Einheiten je Monat, Muskelbalance, letzte Einheiten. Die
/// Aussagekarte, die hier bis zum 16.09.2026 zuerst stand, ist entfallen;
/// ihre Datei bleibt, falls sie an anderer Stelle wiederkommt.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, this.embedded = false, this.onStart});

  /// Als Segment „Verlauf" im Kraft-Tab (Modul 11): kein eigener Rahmen,
  /// kein eigener Titel — der Verlauf ist ein Segment, kein Tab.
  final bool embedded;

  /// Der Weg in ein freies Training. Seit die Aussagekarte entfallen ist
  /// (16.09.2026), zeigt der Verlauf keinen Startknopf mehr; der Parameter
  /// bleibt, damit Aufrufer nicht brechen, und wird ignoriert.
  final VoidCallback? onStart;

  static const _recentCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(sessionsProvider);

    final body = async.when(
      loading: () => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
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
        padding:
            const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
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
        // **Reihenfolge nach Nutzervorgabe vom 16.09.2026:** Einheiten je
        // Monat, Muskelbalance, letzte Einheiten. Die Aussagekarte und der
        // Knopf zur Auswertung sind entfallen — die Auswertung ist seitdem
        // eine eigene Seite im Kraft-Tab, gleich rechts neben dieser.
        //
        // Ein Monat angetippt: Die Liste öffnet auf genau diesen Monat —
        // der Zeitraumfilter kommt aus dem Streifen (Board 06, A2/2).
        AtemEntrance(
          child: MonthStrip(
            summary: summary,
            onSelect: (year, month) {
              ref.read(sessionFilterProvider.notifier).setPeriod(year, month);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SessionListScreen(),
                ),
              );
            },
          ),
        ),
        // Ohne Einheit mit Übungen rendert die Kachel nicht (ausserhalb der
        // Auswertung gilt weiter: ein Block ohne Daten fehlt).
        const SizedBox(height: AtemSpacing.cardGap),
        const AtemEntrance(index: 1, child: MuscleBalanceEntry()),
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
                // **„Alle" heisst alle.** Ohne das Zurücksetzen öffnete die
                // Liste mit dem Zeitraum, den ein früherer Tap auf den
                // Monatsstreifen gesetzt hatte — und stand leer da.
                onTap: () {
                  ref.read(sessionFilterProvider.notifier).clear();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SessionListScreen(),
                    ),
                  );
                },
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
        AtemEntrance(
          index: 2,
          child: AtemCard.list(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0;
                    i < sessions.length && i < _recentCount;
                    i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1, thickness: 1, color: AtemColors.border),
                  _SessionRow(session: sessions[i]),
                ],
              ],
            ),
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

    // Eine Zeile ist ein Weg ins Detail — wie in der Einheitenliste. Vorher
    // war sie stumm: Antippen tat nichts, und das las sich wie ein Hänger.
    return AtemTappable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailScreen(session: session),
        ),
      ),
      semanticLabel: [
        date,
        name,
        if (minutes != null) l10n.durationMinutes(minutes),
        l10n.listOpenDetail,
      ].join(', '),
      minTapSize: const Size(0, 56),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(date, style: AtemType.meta.of(context)),
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
    );
  }
}
