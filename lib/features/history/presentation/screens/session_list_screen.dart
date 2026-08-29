import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/history_providers.dart';
import '../../domain/history_timeline.dart';
import '../../domain/training_session.dart';
import '../../domain/session_filter.dart';
import '../session_ui.dart';
import 'session_detail_screen.dart';

/// Alle Einheiten — mit den Lücken dazwischen.
///
/// Eine Liste aus lauter Trainingstagen wäre unehrlich: Sie reiht die guten
/// Tage aneinander und lässt die Pausen verschwinden. Ab sieben Tagen bekommt
/// die Unterbrechung deshalb eine eigene Zeile.
class SessionListScreen extends ConsumerWidget {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final entries = ref.watch(filteredTimelineProvider);
    final filter = ref.watch(sessionFilterProvider);
    final counts = SessionFilter.countByKind(
        ref.watch(sessionsProvider).value ?? const []);

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.listTitle, style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Die Artenreihe steht über der Liste, nicht in einem Blatt:
            // Sie hat vier Einträge mit Zahlen daneben — das ist eine Zeile,
            // kein Formular.
            _KindRow(filter: filter, counts: counts),
            const SizedBox(height: 10),
            Expanded(child: _body(context, ref, l10n, entries, filter, counts)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    List<TimelineEntry> entries,
    SessionFilter filter,
    Map<SessionKind, int> counts,
  ) {
    if (entries.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
        // **Der leere Filter sagt, woran es liegt.** „Noch kein Verlauf"
        // wäre falsch, wenn 136 Einheiten da sind und nur keine im Mai.
        child: filter.isEmpty
            ? AtemEmptyState(
                title: l10n.emptyHistoryTitle,
                body: l10n.emptyHistoryBody,
              )
            : AtemEmptyState(
                title: l10n.listFilterEmptyTitle,
                body: l10n.listFilterEmptyBody(
                  filter.kind == null
                      ? l10n.commonSession
                      : sessionKindName(l10n, filter.kind!),
                  _periodLabel(context, filter, l10n),
                  counts[filter.kind] ?? 0,
                ),
                action: AtemButton.outline(
                  label: l10n.listFilterClear,
                  semanticLabel: l10n.listFilterClear,
                  expand: false,
                  size: AtemButtonSize.compact,
                  onPressed: () =>
                      ref.read(sessionFilterProvider.notifier).clear(),
                ),
              ),
      );
    }

    return ListView.builder(
                padding: const EdgeInsets.fromLTRB(AtemSpacing.screenPadding, 0,
                    AtemSpacing.screenPadding, 32),
                itemCount: entries.length,
                itemBuilder: (context, i) => switch (entries[i]) {
                  MonthHeader(
                    :final year,
                    :final month,
                    :final sessions,
                    :final load
                  ) =>
                    _Month(
                        year: year,
                        month: month,
                        sessions: sessions,
                        load: load),
                  TimelineSession(:final session, :final ordinalOnDay) =>
                    _Row(session: session, ordinal: ordinalOnDay),
                  TimelineGap(
                    :final days,
                    :final from,
                    :final to,
                    :final isLongest
                  ) =>
                    _Gap(days: days, from: from, to: to, isLongest: isLongest),
                  TimelineEnd(:final first, :final daysAgo) =>
                    _End(first: first, daysAgo: daysAgo),
                },
    );
  }

  /// Der gewählte Zeitraum in Worten, für den leeren Filterzustand.
  static String _periodLabel(
    BuildContext context,
    SessionFilter filter,
    AppL10n l10n,
  ) {
    // Ohne Zeitraum steht die Zeitspanne des Bestands — „insgesamt" wäre
    // hier eine Zeitangabe, die keine ist.
    if (!filter.hasPeriod) return l10n.listTitle;
    return DateFormat.yMMMM(languageTag(context))
        .format(DateTime(filter.year!, filter.month!));
  }
}

/// Die Artenreihe: „Alle" plus vier Arten mit ihren Zahlen.
///
/// Die Zahlen stehen am Chip, nicht in der Liste — so sieht man vor dem
/// Antippen, ob sich das Antippen lohnt. Und sie zählen über den **ganzen**
/// Bestand: Zählten sie über die gefilterte Menge, stünde an „Cardio" eine
/// Null, sobald „Kraft" gewählt ist.
class _KindRow extends ConsumerWidget {
  const _KindRow({required this.filter, required this.counts});

  final SessionFilter filter;
  final Map<SessionKind, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
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
          _KindChip(
            label: l10n.commonAll,
            selected: filter.kind == null,
            onTap: () => ref.read(sessionFilterProvider.notifier).toggleKind(
                  filter.kind ?? SessionKind.strength,
                ),
          ),
          for (final kind in SessionKind.values)
            if ((counts[kind] ?? 0) > 0) ...[
              const SizedBox(width: 8),
              _KindChip(
                label: '${sessionKindName(l10n, kind)} ${counts[kind]}',
                selected: filter.kind == kind,
                onTap: () =>
                    ref.read(sessionFilterProvider.notifier).toggleKind(kind),
              ),
            ],
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: onTap,
        semanticLabel: label,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          constraints: const BoxConstraints(minHeight: 36),
          decoration: BoxDecoration(
            color: selected
                ? AtemCategories.surface(AtemColors.cyan)
                : AtemColors.card,
            borderRadius: BorderRadius.circular(AtemRadii.pill),
            border: Border.all(
              color: selected
                  ? AtemCategories.border(AtemColors.cyan)
                  : AtemColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 14, color: AtemColors.cyan),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AtemType.labelSmall.of(context).copyWith(
                      color: selected
                          ? AtemColors.cyan
                          : AtemColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      );
}

class _Month extends StatelessWidget {
  const _Month({
    required this.year,
    required this.month,
    required this.sessions,
    required this.load,
  });

  final int year;
  final int month;
  final int sessions;
  final int load;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final name =
        DateFormat.yMMMM(languageTag(context)).format(DateTime(year, month));

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.labelMedium.of(context)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              l10n.listMonthSummary(l10n.exerciseCountShort(sessions), load),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AtemType.labelMicro.of(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.session, required this.ordinal});

  final TrainingSession session;
  final int? ordinal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final date = DateFormat.MMMd(languageTag(context)).format(session.date);
    final name = sessionName(l10n, session);
    final minutes = session.duration?.inMinutes;

    // Die Art steht vorn: Ohne sie sieht man einer Zeile mit Plannamen nicht
    // an, ob dahinter Kraft, Cardio oder Regeneration steckt.
    final meta = <String>[
      sessionKindLabel(l10n, session),
      if (ordinal != null) l10n.listSecond(ordinal!),
      if (minutes != null) l10n.durationMinutes(minutes),
    ].join(' · ');

    return Padding(
      // Die Karten standen ohne Abstand aufeinander und wirkten wie eine
      // durchgehende Fläche.
      padding: const EdgeInsets.only(bottom: 8),
      child: AtemCard.list(
        padding: EdgeInsets.zero,
        child: AtemTappable(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          ),
          semanticLabel: [date, name, if (meta.isNotEmpty) meta].join(', '),
          minTapSize: const Size(0, 64),
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(date,
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtemType.titleSmallOrDefault(context)
                              .copyWith(fontWeight: FontWeight.w600)),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtemType.labelMicro
                                .of(context)
                                .copyWith(letterSpacing: 0)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Der Lückenstreifen.
///
/// Gestrichelter Rand statt Fläche: Er soll als **Abwesenheit** lesbar sein,
/// nicht als weiterer Eintrag. Und Magenta nur beim längsten — sonst wäre jede
/// Pause ein Alarm.
class _Gap extends StatelessWidget {
  const _Gap({
    required this.days,
    required this.from,
    required this.to,
    required this.isLongest,
  });

  final int days;
  final DateTime from;
  final DateTime to;
  final bool isLongest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final range = l10n.listGapRange(
      DateFormat.MMMd(tag).format(from),
      DateFormat.MMMd(tag).format(to),
    );
    final color = isLongest ? AtemColors.magenta : AtemColors.textSecondary;

    return Semantics(
      label: [
        l10n.listGap(days),
        range,
        if (isLongest) l10n.listGapLongest,
      ].join(', '),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: CustomPaint(
            painter: _DashedBorder(color: color),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.listGap(days),
                    style: AtemType.labelSmall
                        .of(context)
                        .copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLongest ? '$range · ${l10n.listGapLongest}' : range,
                    style: AtemType.labelMicro.of(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.5);

    const radius = Radius.circular(AtemRadii.statBox);
    final rect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    final path = Path()..addRRect(rect);

    // Gestrichelt von Hand: Flutter kennt keinen Strichmuster-Rand.
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 5).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

class _End extends StatelessWidget {
  const _End({required this.first, required this.daysAgo});

  final DateTime first;
  final int daysAgo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final date = DateFormat.yMMMd(languageTag(context)).format(first);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
      child: Column(
        children: [
          Text(l10n.listEndTitle,
              textAlign: TextAlign.center,
              style: AtemType.labelMedium.of(context)),
          const SizedBox(height: 6),
          Text(
            l10n.listEndBody(date, daysAgo),
            textAlign: TextAlign.center,
            style: AtemType.labelMicro.of(context),
          ),
        ],
      ),
    );
  }
}
