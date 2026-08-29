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
import '../../../cardio/presentation/cardio_ui.dart';
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

    // **Angeheftete Monatsköpfe** (Board 06, Spezifikation): Der Kopf sitzt
    // beim Anheften auf massivem #050507 mit Hairline — kein Blur, der bei
    // jedem Scrollframe über die volle Breite neu gerechnet würde
    // (Entscheidung 12). Dafür ist die Liste in Slivers gruppiert: je Monat
    // ein Kopf und die Zeilen darunter.
    final groups = <List<TimelineEntry>>[];
    for (final entry in entries) {
      if (entry is MonthHeader || groups.isEmpty) groups.add([]);
      groups.last.add(entry);
    }

    return CustomScrollView(
      slivers: [
        for (final group in groups)
          if (group.first case MonthHeader(
            :final year,
            :final month,
            :final sessions,
            :final load
          ))
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _MonthHeaderDelegate(
                    year: year,
                    month: month,
                    sessions: sessions,
                    load: load,
                    height: _monthHeaderHeight(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AtemSpacing.screenPadding),
                  sliver: SliverList.builder(
                    itemCount: group.length - 1,
                    itemBuilder: (context, i) => _entry(group[i + 1]),
                  ),
                ),
              ],
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AtemSpacing.screenPadding),
              sliver: SliverList.builder(
                itemCount: group.length,
                itemBuilder: (context, i) => _entry(group[i]),
              ),
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  static double _monthHeaderHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) + 30;

  Widget _entry(TimelineEntry entry) => switch (entry) {
        MonthHeader() => const SizedBox.shrink(),
        TimelineSession(
          :final session,
          :final ordinalOnDay,
          :final load,
          :final monthMaxLoad
        ) =>
          _Row(
            session: session,
            ordinal: ordinalOnDay,
            load: load,
            monthMax: monthMaxLoad,
          ),
        TimelineGap(:final days, :final from, :final to, :final isLongest) =>
          _Gap(days: days, from: from, to: to, isLongest: isLongest),
        TimelineEnd(:final first, :final daysAgo) =>
          _End(first: first, daysAgo: daysAgo),
      };

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

/// Der Monatskopf — angeheftet, auf massivem Canvas, mit Hairline.
///
/// Rolle Kopfzeile; beim Anheften derselbe Knoten, damit der Fokus nicht
/// springt (G).
class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _MonthHeaderDelegate({
    required this.year,
    required this.month,
    required this.sessions,
    required this.load,
    required this.height,
  });

  final int year;
  final int month;
  final int sessions;
  final int load;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final l10n = AppL10n.of(context);
    final name =
        DateFormat.yMMMM(languageTag(context)).format(DateTime(year, month));
    final summary =
        l10n.listMonthSummary(l10n.exerciseCountShort(sessions), load);

    return Semantics(
      header: true,
      label: '$name, $summary',
      child: ExcludeSemantics(
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 12, AtemSpacing.screenPadding, 0),
          decoration: BoxDecoration(
            color: AtemColors.base,
            // Die Hairline erscheint nur beim Anheften — als Beweis, dass
            // darunter etwas weiterscrollt.
            border: overlapsContent
                ? const Border(bottom: BorderSide(color: AtemColors.border))
                : null,
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.labelMicro.of(context)),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  summary.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AtemType.labelMicro.of(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_MonthHeaderDelegate old) =>
      old.year != year ||
      old.month != month ||
      old.sessions != sessions ||
      old.load != load ||
      old.height != height;
}

/// Die Verlaufszeile — **Datum als Anker, Name mittig, Last rechts**.
///
/// Board 06, Spezifikation: Datumsspalte mit Tag (Mono 13/700) und Wochentag,
/// Name mit Ellipsis, Meta darunter, rechts die Last in Mono mit einem
/// 34×4-Balken relativ zum Monatsmaximum. Zwei Einheiten am selben Tag: das
/// Datum steht nur an der ersten, die zweite rückt 10 dp ein und ihre
/// Datumsspalte bleibt leer — an 21 von 87 Tagen passiert das.
class _Row extends StatelessWidget {
  const _Row({
    required this.session,
    required this.ordinal,
    required this.load,
    required this.monthMax,
  });

  final TrainingSession session;
  final int? ordinal;
  final double load;
  final double monthMax;

  /// Die zweite Einheit des Tages — eingerückt, ohne Datum.
  bool get _followUp => ordinal != null && ordinal! > 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final day = DateFormat.d(tag).format(session.date);
    final weekday = DateFormat.E(tag).format(session.date).toUpperCase();
    final spokenDate = DateFormat.yMMMMEEEEd(tag).format(session.date);
    final name = sessionName(l10n, session);
    final minutes = session.duration?.inMinutes;

    // Die Art steht vorn: Ohne sie sieht man einer Zeile mit Plannamen nicht
    // an, ob dahinter Kraft, Cardio oder Regeneration steckt.
    final meta = <String>[
      sessionKindLabel(l10n, session),
      if (session case CardioSession(distanceKm: final km?))
        l10n.unitKilometers(km.toStringAsFixed(1)),
      if (session case CardioSession(tempo: final tempo?))
        formatTempo(context, tempo),
      if (minutes != null) l10n.durationMinutes(minutes),
      if (_followUp) l10n.listSecond(ordinal!),
    ].join(' · ');

    final hasLoad = load > 0;
    final share = monthMax <= 0 ? 0.0 : (load / monthMax).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.only(bottom: 8, left: _followUp ? 10 : 0),
      child: AtemCard.list(
        padding: EdgeInsets.zero,
        child: AtemTappable(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          ),
          // „Dienstag, 8. Juli, Laufen, Cardio, 8,2 Kilometer, Pace 5:42 pro
          // Kilometer, Last 412." — bei Mehrfachtagen ergänzt „2. Einheit",
          // weil die Einrückung nicht hörbar ist.
          semanticLabel: [
            spokenDate,
            name,
            meta,
            if (hasLoad) '${l10n.detailLoad} ${load.round()}',
          ].join(', '),
          minTapSize: const Size(0, 56),
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: _followUp
                      ? null
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(day,
                                style: AtemType.valueMedium
                                    .of(context)
                                    .copyWith(fontSize: 13)),
                            Text(weekday,
                                style: AtemType.labelMicro
                                    .of(context)
                                    .copyWith(letterSpacing: 0)),
                          ],
                        ),
                ),
                const SizedBox(width: 10),
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
                        Text(meta.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtemType.labelMicro
                                .of(context)
                                .copyWith(letterSpacing: 0)),
                      ],
                    ],
                  ),
                ),
                if (hasLoad) ...[
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${load.round()}',
                          style: AtemType.valueMedium
                              .of(context)
                              .copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 34,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AtemColors.track,
                            borderRadius:
                                BorderRadius.circular(AtemRadii.pill),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: share.clamp(0.06, 1.0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AtemColors.cyan,
                                  borderRadius:
                                      BorderRadius.circular(AtemRadii.pill),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
    final color = isLongest ? AtemColors.magenta : AtemColors.textTertiary;

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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Die linke Rinne, 34 dp, mit gestrichelter Vertikalen: Der
                // Streifen liest sich als Abwesenheit, nicht als Eintrag.
                SizedBox(
                  width: 34,
                  child: CustomPaint(painter: _DashedRail(color: color)),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.listGap(days).toUpperCase(),
                          style: AtemType.labelSmall.of(context).copyWith(
                              color: color, fontWeight: FontWeight.w600),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Die gestrichelte Vertikale in der Rinne des Lückenstreifens.
class _DashedRail extends CustomPainter {
  _DashedRail({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.5);
    final x = size.width / 2;
    var y = 6.0;
    while (y < size.height - 6) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), paint);
      y += 8;
    }
  }

  @override
  bool shouldRepaint(_DashedRail old) => old.color != color;
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
