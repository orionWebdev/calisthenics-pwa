import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/application/tab_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../../pulse/presentation/widgets/zone_five_card.dart';
import '../../../strength/presentation/widgets/tab_header.dart';
import '../../application/cardio_providers.dart';
import '../../domain/iso_week.dart';
import '../../domain/pace_series.dart';
import '../../domain/weekly_distance.dart';
import '../cardio_ui.dart';
import '../widgets/cardio_session_row.dart';
import '../widgets/distribution_bars.dart';
import '../widgets/pace_chart.dart';
import '../widgets/week_strip.dart';
import 'cardio_form_screen.dart';
import 'cardio_live_screen.dart';

/// Der Cardio-Tab — Board 11, A2, B1 und B3.
///
/// ## Was oben steht, bei 42, bei 3, bei 0
///
/// Bei genug Wochen die Wochenzahl mit Nenner und Verschiebung. Unter drei
/// belegten Wochen die Gesamtstrecke mit Zeitraum — eine Woche mit einem Lauf
/// ist kein Trend. Bei null der einzige echte Leerzustand des Moduls, weil es
/// keinen anderen Weg zur ersten Einheit gibt.
///
/// Der Erfassen-Knopf ist ein FAB über der Liste, nicht in der Leiste: Die
/// Leiste hat genau drei Plätze. Der Fehler eines rechnenden Blocks nimmt nie
/// die Liste mit — sie ist gespeicherte Wahrheit.
class CardioScreen extends ConsumerWidget {
  const CardioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final segment = ref.watch(appTabsProvider.select((s) => s.cardioSegment));
    final async = ref.watch(sessionsProvider);
    final cardio = ref.watch(cardioSessionsProvider);
    final live = ref.watch(cardioLiveProvider).value;

    // Der Ton des Bereichs: er färbt das Symbol in der Leiste und
    // legt einen sehr schwachen Verlauf über den Grund.
    return AtemTabTheme(
      tone: AtemColors.tabCardio,
      child: Scaffold(
        backgroundColor: AtemColors.base,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabHeader(
                title: l10n.tabCardio,
                count: cardio.length,
                switcher: AtemTabSwitch<CardioSegment>(
                  groupSemanticLabel: l10n.tabCardio,
                  value: segment,
                  onChanged: (s) =>
                      ref.read(appTabsProvider.notifier).setCardioSegment(s),
                  segments: [
                    AtemTabSegment(
                        value: CardioSegment.sessions, label: l10n.segSessions),
                    AtemTabSegment(
                        value: CardioSegment.analysis, label: l10n.segAnalysis),
                  ],
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AtemSpacing.screenPadding),
                    child: AtemSkeleton(
                      semanticLabel: l10n.commonLoading,
                      blocks: const [
                        // In Ergebnishöhe, damit die Liste beim Ankommen
                        // nicht springt.
                        AtemSkeletonBlock(height: 118),
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
                      title: l10n.historyErrorTitle,
                      body: l10n.historyErrorBody,
                      retryLabel: l10n.commonRetry,
                      onRetry: () => ref.invalidate(sessionStreamProvider),
                    ),
                  ),
                  data: (_) {
                    if (cardio.isEmpty && live == null) {
                      return _EmptyCardio(
                        onLog: () => _openForm(context),
                        onLive: () => _openLive(context),
                      );
                    }
                    return Stack(
                      children: [
                        IndexedStack(
                          index: segment == CardioSegment.sessions ? 0 : 1,
                          children: [
                            _Sessions(
                              sessions: cardio,
                              live: live,
                              onLive: () => _openLive(context),
                            ),
                            _Analysis(sessions: cardio),
                          ],
                        ),
                        // Der FAB nur, wenn die Wochenzahl steht (A2). Im dünnen
                        // Zustand trägt die Liste den Knopf selbst (B1/1).
                        if (ref.watch(weeklyDistanceProvider).hasWeekly)
                          Positioned(
                            right: AtemSpacing.screenPadding,
                            // Über der Leiste, die selbst über dem Inhalt liegt.
                            bottom: 96,
                            child: _Fab(onTap: () => _openForm(context)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openForm(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CardioFormScreen()),
      );

  static void _openLive(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CardioLiveScreen()),
      );
}

/// Der Leerzustand — beide Erfassungswege gleichrangig, danach nie wieder.
class _EmptyCardio extends StatelessWidget {
  const _EmptyCardio({required this.onLog, required this.onLive});

  final VoidCallback onLog;
  final VoidCallback onLive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 130),
      children: [
        AtemEmptyState(
          title: l10n.cardioEmptyTitle,
          body: l10n.cardioEmptyBody,
        ),
        const SizedBox(height: 8),
        AtemButton.gradient(
          label: l10n.cardioAddFirst,
          semanticLabel: l10n.cardioAddFirst,
          leading:
              const Icon(Icons.add, size: 18, color: AtemColors.textPrimary),
          onPressed: onLog,
        ),
        const SizedBox(height: 10),
        AtemButton.outline(
          label: l10n.cardioLiveStart,
          semanticLabel: l10n.cardioLiveStart,
          onPressed: onLive,
        ),
      ],
    );
  }
}

/// Der FAB — „+ Einheit erfassen", über der Liste.
class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemButton.gradient(
      label: l10n.cardioAdd,
      semanticLabel: l10n.cardioAdd,
      expand: false,
      size: AtemButtonSize.compact,
      // Kein stehender Schein (Board 18b, C9): Der Knopf antwortet auf den
      // Druck, er ruft nicht.
      leading: const Icon(Icons.add, size: 18, color: AtemColors.textPrimary),
      onPressed: onTap,
    );
  }
}

/// Segment „Einheiten": Wochenzahl oben, darunter die Liste.
class _Sessions extends ConsumerWidget {
  const _Sessions({
    required this.sessions,
    required this.live,
    required this.onLive,
  });

  final List<CardioSession> sessions;
  final Object? live;
  final VoidCallback onLive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final weekly = ref.watch(weeklyDistanceProvider);
    final thin = !weekly.hasWeekly;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 170),
      children: [
        if (live != null) ...[
          _LiveNotice(onTap: onLive),
          const SizedBox(height: 14),
        ],
        AtemEntrance(child: _WeekTile(weekly: weekly)),
        const SizedBox(height: 22),
        Text(
          (weekly.hasWeekly ? l10n.historyRecentLabel : l10n.cardioAllSessions)
              .toUpperCase(),
          style: AtemType.labelMedium.of(context),
        ),
        const SizedBox(height: 8),
        AtemEntrance(
          index: 1,
          child: AtemCard.list(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < sessions.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1, thickness: 1, color: AtemColors.border),
                  CardioSessionRow(session: sessions[i]),
                ],
              ],
            ),
          ),
        ),
        if (thin) ...[
          const SizedBox(height: 16),
          AtemButton.gradient(
            label: l10n.cardioAdd,
            semanticLabel: l10n.cardioAdd,
            leading:
                const Icon(Icons.add, size: 18, color: AtemColors.textPrimary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CardioFormScreen()),
            ),
          ),
        ],
      ],
    );
  }
}

/// Die laufende Uhr, wiedergefunden — ein Weg zurück zu ihr.
class _LiveNotice extends ConsumerWidget {
  const _LiveNotice({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final draft = ref.watch(cardioLiveProvider).value;
    if (draft == null) return const SizedBox.shrink();
    final text = l10n
        .liveRunningNotice(formatClock(draft.clock.elapsed(DateTime.now())));

    return AtemCard.list(
      onTap: onTap,
      semanticLabel: text,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AtemStatusDot(
            color: draft.clock.isPaused
                ? AtemColors.textSecondary
                : AtemColors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AtemType.labelSmall.of(context)),
          ),
          const Icon(Icons.chevron_right,
              size: 18, color: AtemColors.textSecondary),
        ],
      ),
    );
  }
}

/// Die Wochenzahl-Kachel — Woche, Gesamt (dünn) oder Fehler.
class _WeekTile extends StatelessWidget {
  const _WeekTile({required this.weekly});

  final WeeklyDistance weekly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);

    if (!weekly.hasWeekly) {
      // Dünn: Gesamtstrecke mit Zeitraum, plus der Satz, ab wann die
      // Wochenzahl erscheint.
      final since = DateFormat.MMMd(tag).format(weekly.firstDate!);
      final km = formatKm(context, weekly.totalKm);
      // „3 LÄUFE" · „Ø 6,2 KM" als Kapseln (B1/1) — je Aktivität ein Paar.
      final chips = <String>[
        for (final entry in weekly.countByActivity.entries) ...[
          '${entry.value} ${activityLabel(l10n, entry.key)}',
          'Ø ${formatKm(context, weekly.kmByActivity[entry.key]! / entry.value)} km',
        ],
      ];

      return AtemCard.list(
        padding: const EdgeInsets.all(13),
        child: Semantics(
          label: l10n.cardioTotalA11y(km, since, weekly.totalCount),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.cardioTotalSince(since),
                    style: AtemType.meta.of(context)),
                const SizedBox(height: 6),
                Text(l10n.unitKilometers(km),
                    style:
                        AtemType.valueLarge.of(context).copyWith(fontSize: 28)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final chip in chips)
                      AtemBadge(label: chip),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoLine(text: l10n.cardioWeekThin),
              ],
            ),
          ),
        ),
      );
    }

    final km = formatKm(context, weekly.thisWeekKm);
    final shift = weekly.shiftKm;
    final avg = weekly.fourWeekAverageKm;
    final shiftText = shift == null
        ? null
        : '${shift >= 0 ? '▲' : '▼'} ${shift >= 0 ? '+' : '−'}${formatKm(context, shift.abs())}';

    return AtemCard.list(
      padding: const EdgeInsets.all(13),
      child: Semantics(
        label: [
          l10n.cardioWeekA11y(km, weekly.thisWeekCount),
          if (shift != null && avg != null)
            l10n.cardioWeekShiftA11y(
              formatKm(context, shift.abs()),
              shift >= 0 ? l10n.ratioShiftUp : l10n.ratioShiftDown,
              formatKm(context, avg),
            ),
        ].join(', '),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.cardioWeekTitle(IsoWeek.number(weekly.weeks.last.weekStart))} · ${l10n.cardioWeekCount(weekly.thisWeekCount)}',
                style: AtemType.meta.of(context),
              ),
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 10,
                children: [
                  // Die Wochenzahl läuft zu ihrem Wert: Wer eine Einheit
                  // erfasst und zurückkommt, soll sehen, dass sie
                  // angekommen ist — nicht bloss eine andere Zahl vorfinden.
                  AtemAnimatedNumber(
                    value: weekly.thisWeekKm,
                    builder: (context, v) => Text(
                      l10n.unitKilometers(formatKm(context, v)),
                      style: AtemType.valueLarge
                          .of(context)
                          .copyWith(fontSize: 28),
                    ),
                  ),
                  if (shiftText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: AtemBadge(label: shiftText),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                avg == null
                    ? l10n.ratioNoshift
                    : l10n.cardioWeekBasis(formatKm(context, avg)),
                style: AtemType.meta.of(context),
              ),
              const SizedBox(height: 12),
              _MiniStrip(weeks: weekly.weeks),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segment „Auswertung": Wochenstreifen, Verteilung, Tempo, Perzentil, Zone 5.
class _Analysis extends ConsumerStatefulWidget {
  const _Analysis({required this.sessions});

  final List<CardioSession> sessions;

  @override
  ConsumerState<_Analysis> createState() => _AnalysisState();
}

class _AnalysisState extends ConsumerState<_Analysis> {
  CardioActivity? _activity;
  var _activitySet = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final weekly = ref.watch(weeklyDistanceProvider);
    final distribution = ref.watch(distanceDistributionProvider);
    final activities = PaceSeries.activitiesByCount(widget.sessions);
    final reference = ref.watch(historyReferenceProvider);
    final allSessions = ref.watch(sessionsProvider).value ?? const [];

    // Die häufigste Aktivität voran — beim ersten Öffnen ist sie gewählt.
    if (!_activitySet && activities.isNotEmpty) {
      _activity = activities.first.key;
      _activitySet = true;
    }
    final series = ref.watch(paceSeriesProvider(_activity));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 170),
      children: [
        // ---- Wochenkilometer, 8 Wochen: nur ab drei belegten Wochen.
        if (weekly.hasWeekly) ...[
          _SectionTitle(
            title: l10n.analysisWeeklyTitle,
            tag: '${WeeklyDistance.stripWeeks} ${l10n.commonWeeks}',
          ),
          const SizedBox(height: 10),
          AtemCard.list(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.analysisWeeklyBasis(
                            formatKm(context, weekly.eightWeekAverageKm ?? 0),
                            weekly.eightWeekCount),
                        style: AtemType.meta.of(context),
                      ),
                    ),
                    if (weekly.shiftKm case final shift?)
                      AtemBadge(
                        label:
                            '${shift >= 0 ? '▲' : '▼'} ${shift >= 0 ? '+' : '−'}${formatKm(context, shift.abs())}',
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                WeekStrip(distance: weekly),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ---- Verteilung der Distanzen: nur mit Einheiten mit Distanz.
        if (!distribution.isEmpty) ...[
          _SectionTitle(
            title: l10n.analysisDistTitle,
            tag: l10n.analysisDistBasis(
                distribution.withDistance, distribution.total),
          ),
          const SizedBox(height: 10),
          AtemCard.list(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: DistributionBars(distribution: distribution),
          ),
          const SizedBox(height: 24),
        ],

        // ---- Tempoentwicklung je Aktivität.
        if (activities.isNotEmpty) ...[
          _SectionTitle(title: l10n.analysisPaceTitle),
          const SizedBox(height: 10),
          _ActivityChips(
            activities: activities,
            selected: _activity,
            onSelect: (a) => setState(() => _activity = a),
          ),
          const SizedBox(height: 12),
          _PaceBlock(series: series),
          const SizedBox(height: 24),
        ],

        // ---- Zone 5 je Woche. Hierher verschoben aus der Kraft-Auswertung
        // (`b5a6665`): Die Zonenauswertung gehört in den Cardio-Teil.
        //
        // **Zuletzt, nicht zuerst.** Der Block rendert immer — auf
        // Auswertungsbildschirmen zeigt er unter seiner Schwelle Umriss und
        // Bedingung. Weiter oben eröffnete er den Bildschirm mit „GESPERRT",
        // sobald die Wochenkilometer noch unter ihrer eigenen Schwelle lagen
        // (am Render gesehen). Was gemessen ist, steht vorn; was noch
        // aussteht, danach.
        //
        // **Alle** Einheiten als Nenner, nicht nur die Cardio-Einheiten: So
        // verlangt es `ZoneFiveWeeks.compute`. Der Zähler zählt jede
        // übernommene Uhr-Einheit mit Puls, auch eine Krafteinheit mit Uhr —
        // ein Nenner aus Cardio allein wäre kleiner als sein eigener Zähler.
        ZoneFiveCard(sessions: allSessions, reference: reference),
      ],
    );
  }
}

class _PaceBlock extends StatelessWidget {
  const _PaceBlock({required this.series});

  final PaceSeries series;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final isRun = series.activity == CardioActivity.run;
    String v(double x) =>
        formatTempoValue(context, x, usesSpeed: series.usesSpeed);

    if (series.isEmpty) {
      // Einheiten ohne Distanz haben kein Tempo — nichts zu zeigen, kein
      // Platzhalter. Der Bildschirm endet hier.
      return const SizedBox.shrink();
    }

    final median = series.median!;
    final last = series.last!;
    final delta = last.value - median;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtemCard.list(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: '${v(last.value)}, '
                    '${isRun ? l10n.analysisPaceBasis(v(median), series.count) : l10n.analysisPaceBasisOther(v(median), series.count)}',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 10,
                        children: [
                          Text(v(last.value),
                              style: AtemType.valueLarge
                                  .of(context)
                                  .copyWith(fontSize: 28)),
                          if (delta != 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: AtemBadge(
                                label: formatTempoDelta(context, delta,
                                    usesSpeed: series.usesSpeed),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRun
                            ? l10n.analysisPaceBasis(v(median), series.count)
                            : l10n.analysisPaceBasisOther(
                                v(median), series.count),
                        style: AtemType.meta.of(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (series.hasCurve)
                PaceChart(series: series)
              else
                _InfoLine(
                  text: l10n.analysisPaceThin(
                    PaceSeries.curveMinimum,
                    v(median),
                    v(series.slowest!),
                    v(series.fastest!),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ---- Perzentil und Spanne: erst ab zehn Einheiten. Darunter endet
        // der Bildschirm nach der Spanne.
        if (series.hasPercentile)
          AtemCard.list(
            padding: const EdgeInsets.all(14),
            child: _PercentileBlock(series: series, isRun: isRun, tag: tag),
          ),
      ],
    );
  }
}

class _PercentileBlock extends StatelessWidget {
  const _PercentileBlock({
    required this.series,
    required this.isRun,
    required this.tag,
  });

  final PaceSeries series;
  final bool isRun;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final last = series.last!;
    final faster = series.fasterThan(last.value);
    final total = series.count;
    String v(double x) =>
        formatTempoValue(context, x, usesSpeed: series.usesSpeed);
    final sentence = isRun
        ? l10n.analysisPctFaster(faster, total)
        : l10n.analysisPctFasterOther(faster, total);
    final share = total <= 1 ? 0.0 : faster / (total - 1);

    return Semantics(
      label: '${l10n.analysisPctThis(DateFormat.MMMd(tag).format(last.date))}, '
          '${v(last.value)}. $sentence. ${l10n.analysisPctNoothers}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analysisPctThis(DateFormat.MMMd(tag).format(last.date)),
              style: AtemType.meta.of(context),
            ),
            const SizedBox(height: 6),
            Text(v(last.value),
                style: AtemType.valueLarge.of(context).copyWith(fontSize: 28)),
            const SizedBox(height: 10),
            // Der Balken aus Modul 9: 8 dp, Marker 3×14, Füllung Cyan.
            SizedBox(
              height: 14,
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      top: 3,
                      bottom: 3,
                      child: AtemProgressBar.share(
                        value: share,
                        semanticLabel: '',
                        accent: AtemColors.cyan,
                      ),
                    ),
                    Positioned(
                      left: (c.maxWidth - 3) * share,
                      child: Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AtemColors.textPrimary,
                          borderRadius: BorderRadius.circular(AtemRadii.pill),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${v(series.slowest!)} ${l10n.analysisPctSlowest}',
                    style: AtemType.labelDeco.of(context)),
                Text(
                    '${v(series.fastest!)} ${l10n.analysisPctFastest}',
                    style: AtemType.labelDeco.of(context)),
              ],
            ),
            const SizedBox(height: 10),
            Text('$sentence ${l10n.analysisPctNoothers}',
                style: AtemType.labelSmall.of(context)),
          ],
        ),
      ),
    );
  }
}

/// Die Kapselreihe der Aktivitäten: belegte voran, mit Zahl.
class _ActivityChips extends StatelessWidget {
  const _ActivityChips({
    required this.activities,
    required this.selected,
    required this.onSelect,
  });

  final List<MapEntry<CardioActivity?, int>> activities;
  final CardioActivity? selected;
  final ValueChanged<CardioActivity?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in activities)
          AtemTappable(
            onTap: entry.key == selected ? null : () => onSelect(entry.key),
            semanticLabel:
                '${activityLabel(l10n, entry.key)}, ${l10n.cardioListCount(entry.value)}',
            selected: entry.key == selected,
            inMutuallyExclusiveGroup: true,
            minTapSize: const Size(48, 48),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: entry.key == selected
                    ? AtemColors.cyan.withValues(alpha: 0.08)
                    : AtemColors.card,
                borderRadius: BorderRadius.circular(AtemRadii.pill),
                border: Border.all(
                  color: entry.key == selected
                      ? AtemColors.cyan.withValues(alpha: 0.35)
                      : AtemColors.border,
                ),
              ),
              child: Text(
                '${activityLabel(l10n, entry.key)} · ${entry.value}',
                style: AtemType.labelUi.of(context).copyWith(
                      color: entry.key == selected
                          ? AtemColors.cyan
                          : AtemColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Der Kopf eines Abschnitts der Auswertung: **Titel links, Grundlage rechts**.
///
/// ## Warum hier nichts gekürzt wird (seit 22.09.2026)
///
/// Beide Texte standen bis dahin auf `maxLines: 1` mit Ellipse. Schon bei
/// Schriftfaktor 1,15 auf 361 dp las man deshalb „Verteilung der …" und
/// „6 von 6 Einheiten m…" — am Render gesehen. Der abgeschnittene Teil ist
/// nicht Zierrat: Rechts steht die **Grundlage mit Nenner**, und eine Zahl
/// ohne ihre Grundlage ist in dieser App keine Zahl.
///
/// Die Regel und die Mechanik stammen aus [AtemBlockHeader]: gemessen wird
/// mit einem [TextPainter], und passen beide nicht nebeneinander, rutscht
/// der rechte Teil darunter. Eine Zeile mehr ist billiger als ein verlorener
/// Titel. Anders als dort ist die Grundlage **keine Handlung** — sie bleibt
/// linksbündig und in der dritten Textstufe, damit niemand sie für ein
/// Tap-Ziel hält.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.tag});
  final String title;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final titleStyle = AtemType.titleMedium.of(context);
    final tagStyle = AtemType.meta.of(context);
    final titleText = Text(title, style: titleStyle);
    final label = tag;
    if (label == null) return titleText;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        // `Directionality`, nicht `TextDirection.ltr`: In dieser Datei
        // verdeckt `intl` den Namen — und die Leserichtung des Baums ist
        // ohnehin die richtige Antwort.
        final direction = Directionality.of(context);
        double widthOf(String text, TextStyle style) => (TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: direction,
              textScaler: scaler,
              maxLines: 1,
            )..layout())
                .width;
        final fits = widthOf(title, titleStyle) + 10 + widthOf(label, tagStyle) <=
            constraints.maxWidth;

        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleText,
              const SizedBox(height: 2),
              Text(label, style: tagStyle),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: titleText),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(label, style: tagStyle),
            ),
          ],
        );
      },
    );
  }
}

/// Die Hinweiszeile — der Notice-Slot aus Modul 2 in Grau.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        label: text,
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AtemColors.border),
                ),
                child: Text('i',
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(letterSpacing: 0, height: 1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: AtemType.labelSmall.of(context)),
              ),
            ],
          ),
        ),
      );
}

/// Der Mini-Streifen in der Wochenkachel: acht Wochen als Balken, die
/// laufende in Cyan, eine leere als 2-dp-Strich (A2). Rein dekorativ — die
/// Kachel trägt die Zahl, der Streifen nur ihren Verlauf.
class _MiniStrip extends StatelessWidget {
  const _MiniStrip({required this.weeks});

  final List<WeekDistance> weeks;

  @override
  Widget build(BuildContext context) {
    final max = weeks.fold<double>(0, (m, w) => w.km > m ? w.km : m);
    return ExcludeSemantics(
      child: SizedBox(
        height: 22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < weeks.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AtemReveal(
                  delay: Duration(milliseconds: 40 * i),
                  builder: (context, t) => Container(
                    height: weeks[i].isEmpty || max <= 0
                        ? 2
                        : math.max(
                            2.0,
                            (6 + 16 * (weeks[i].km / max).clamp(0.0, 1.0)) * t),
                    decoration: BoxDecoration(
                      color: weeks[i].isCurrent
                          ? AtemColors.cyan
                          : (weeks[i].isEmpty
                              ? AtemColors.border
                              : AtemColors.surfaceRaised),
                      borderRadius: BorderRadius.circular(AtemRadii.pill),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
