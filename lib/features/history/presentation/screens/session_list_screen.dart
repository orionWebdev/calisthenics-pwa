import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/history_providers.dart';
import '../../domain/history_timeline.dart';
import '../../domain/training_session.dart';
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
    final entries = ref.watch(historyTimelineProvider);

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.listTitle, style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: entries.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AtemSpacing.screenPadding),
                child: AtemEmptyState(
                  title: l10n.historyEmptyTitle,
                  body: l10n.historyEmptyBody,
                ),
              )
            : ListView.builder(
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
              ),
      ),
    );
  }
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
