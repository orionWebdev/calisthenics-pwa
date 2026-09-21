import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/history_providers.dart';
import '../../domain/training_session.dart';
import '../screens/session_detail_screen.dart';
import '../screens/session_list_screen.dart';
import '../session_ui.dart';
import 'month_strip.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../domain/muscle_balance.dart';
import 'muscle_balance_card.dart';

/// Der Abschnitt „Verlauf" — **Einheiten je Monat, Muskelbalance, zuletzt**.
///
/// Die Reihenfolge ist Nutzervorgabe vom 16.09.2026. Die Aussagekarte, die
/// hier davor zuerst stand, ist entfallen; ihre Datei bleibt, falls sie an
/// anderer Stelle wiederkommt.
///
/// ## Die Einheitenzahl steht jetzt hier
///
/// Bis zum 20.09.2026 trug der Kraft-Tab einen Kopf: „Kraft · 63 Einheiten".
/// Mit dem One-Pager ist die Ortszeile die Überschrift, und ein zweiter Titel
/// darüber wäre derselbe Name zweimal. Die Zahl gehört ohnehin hierher — sie
/// zählt, was im Verlauf liegt — und steht als eigener Block mit ihrer
/// Grundlage daneben (Board 13, „Verlauf & Pläne — knapp gehalten").
///
/// ## Ein Rezept für alle Blocküberschriften
///
/// `labelMicro` in Versalien, optional mit rechtsbündiger Aktion in derselben
/// Zeile. Vorher stand „Letzte Einheiten" in `titleMedium` neben Mono-Köpfen
/// — zwei Rezepte nebeneinander, gewachsen statt entschieden.
///
/// Der Abschnitt **scrollt nicht selbst**: Er ist ein Stück der Seite.
class HistorySection extends ConsumerWidget {
  const HistorySection({super.key});

  static const _recentCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(sessionsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 0),
      child: async.when(
        loading: () => AtemSkeleton(
          semanticLabel: l10n.dashboardLoadingA11y,
          blocks: const [
            AtemSkeletonBlock(height: 140),
            AtemSkeletonBlock(height: 120),
            AtemSkeletonBlock(height: 64, radius: 14),
            AtemSkeletonBlock(height: 64, radius: 14),
          ],
        ),
        error: (_, __) => AtemErrorState(
          title: l10n.historyErrorTitle,
          body: l10n.historyErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(sessionStreamProvider),
        ),
        data: (sessions) => _content(context, ref, l10n, sessions),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    List<TrainingSession> sessions,
  ) {
    if (sessions.isEmpty) {
      return AtemEmptyState(
        title: l10n.emptyHistoryTitle,
        body: l10n.emptyHistoryBody,
      );
    }

    final summary = ref.watch(historySummaryProvider);
    final balance = MuscleBalance.compute(
      sessions,
      ref.watch(exercisesProvider).value ?? const [],
      ref.watch(historyReferenceProvider),
    );
    final strength = sessions
        .where((s) =>
            s.kind == SessionKind.strength || s.kind == SessionKind.bodyweight)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // **Split-Card**: Muskelbalance und Einheitenzahl teilen sich eine
        // Zeile (21.09.2026). Beide sind schmale Blöcke; untereinander
        // schoben sie den Monatsstreifen unnötig weit nach unten.
        AtemEntrance(
          child: AtemSplit(
            left: _TotalCard(count: strength, sessions: sessions),
            // Ohne Einheit mit Übungen im Fenster rendert die Kachel nicht —
            // dann nimmt die Einheitenzahl die ganze Zeile.
            right: balance.sessionsInWindow == 0
                ? null
                : MuscleBalanceTile(balance: balance, compact: true),
          ),
        ),
        const SizedBox(height: AtemSpacing.cardGap),
        // Ein Monat angetippt: Die Liste öffnet auf genau diesen Monat —
        // der Zeitraumfilter kommt aus dem Streifen (Board 06, A2/2).
        AtemEntrance(
          index: 1,
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
        const SizedBox(height: 24),
        AtemBlockHeader(
          title: l10n.historyRecentLabel.toUpperCase(),
          actionLabel: l10n.historyAll(summary.sessions),
          // **„Alle" heisst alle.** Ohne das Zurücksetzen öffnete die Liste
          // mit dem Zeitraum, den ein früherer Tap auf den Monatsstreifen
          // gesetzt hatte — und stand leer da.
          onAction: () {
            ref.read(sessionFilterProvider.notifier).clear();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const SessionListScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        AtemEntrance(
          index: 3,
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

/// **Erfasste Einheiten** — die Zahl und woher sie kommt.
///
/// Die Zahl steht weiss, nicht im Bereichston: Das Board teilt die Farben neu
/// auf — Amber sagt „wo du bist", Cyan sagt „das kannst du antippen". Eine
/// Zahl sagt keines von beidem.
///
/// Die Grundlage steht in derselben Zeile wie der Wert, wie überall in der
/// App: nie ein Wert ohne seinen Nenner.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.count, required this.sessions});

  final int count;
  final List<TrainingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final since = _since(context);
    final basis = since == null ? null : l10n.historyTotalSince(since);

    return Semantics(
      container: true,
      label: [
        l10n.historyTotalLabel,
        l10n.cardioWeekCount(count),
        if (basis != null) basis,
      ].join(', '),
      child: ExcludeSemantics(
        child: AtemCard.list(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.historyTotalLabel.toUpperCase(),
                  style: AtemType.labelMicro.of(context)),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 6,
                children: [
                  Text(
                    '$count',
                    style: AtemType.display.of(context).copyWith(
                      fontSize: 28,
                      height: 1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(basis ?? l10n.cardioWeekCount(count),
                        style: AtemType.meta.of(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Der Monat der ältesten Einheit — „seit Mai 2025".
  String? _since(BuildContext context) {
    DateTime? first;
    for (final s in sessions) {
      if (first == null || s.date.isBefore(first)) first = s.date;
    }
    if (first == null) return null;
    return DateFormat('MMMM yyyy', languageTag(context)).format(first);
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    // Kurzes Datum mit Wochentag, wie in der Einheitenliste: „Di 25. Aug".
    // Vorher „25.8.2026" in einer 76-dp-Spalte, die am Gerät zu schmal war —
    // Datum und Name klebten aneinander.
    final date = DateFormat('EEE d. MMM', languageTag(context))
        .format(session.date)
        .replaceAll('.,', '');
    final name = sessionName(l10n, session);
    final kind = sessionKindLabel(l10n, session);
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
        padding: const EdgeInsets.symmetric(
            horizontal: AtemSpacing.cardPadding, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.titleSmallOrDefault(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [date, if (kind != name) kind].join(' · '),
                    style: AtemType.meta.of(context),
                  ),
                ],
              ),
            ),
            if (minutes != null) ...[
              const SizedBox(width: 12),
              Text(l10n.durationMinutes(minutes),
                  softWrap: false,
                  style:
                      AtemType.valueMedium.of(context).copyWith(fontSize: 14)),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 20, color: AtemColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
