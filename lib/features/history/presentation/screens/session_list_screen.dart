import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../health_import/application/health_import_providers.dart';
import '../../../health_import/presentation/pending_in_timeline.dart';
import '../../../health_import/presentation/widgets/health_inbox.dart';
import '../../../health_import/presentation/widgets/merge_motion.dart';
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
class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen>
    with SingleTickerProviderStateMixin {
  /// **Eine Uhr für beide Zeilen.** Die Verschmelzung läuft über zwei
  /// getrennte Blöcke der Liste — die Uhr-Zeile und die Zeile in ihrer Karte.
  /// Zwei eigene Controller liefen auseinander, sobald einer von beiden
  /// einen Frame später gebaut würde; dann rückten die Zeilen nicht mehr
  /// aufeinander zu, sondern aneinander vorbei.
  late final AnimationController _merge = AnimationController(
    vsync: this,
    duration: AtemMergeMotion.duration,
  );

  @override
  void initState() {
    super.initState();
    _merge.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      // Erst im nächsten Frame: Der Auftrag zu löschen baut die Liste neu,
      // und das mitten im Abschluss der Animation wirft.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_merge.isCompleted) return;
        _merge.value = 0;
        ref.read(mergeAnimationProvider.notifier).done();
      });
    });
  }

  @override
  void dispose() {
    _merge.dispose();
    super.dispose();
  }

  /// Fährt los, sobald ein Auftrag vorliegt **und** kein Blatt mehr darüber
  /// liegt. Ohne die zweite Bedingung liefe die Bewegung hinter dem
  /// Prüfblatt ab, und zurück auf der Liste wäre sie vorbei.
  void _driveMerge(MergeAnimation? armed) {
    final route = ModalRoute.of(context);
    if (armed == null || (route != null && !route.isCurrent)) return;
    if (_merge.isAnimating || _merge.isCompleted) return;
    _merge.duration = MediaQuery.disableAnimationsOf(context)
        ? AtemMergeMotion.reducedDuration
        : AtemMergeMotion.duration;
    _merge.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final entries = ref.watch(filteredTimelineProvider);
    final filter = ref.watch(sessionFilterProvider);
    final loaded = ref.watch(sessionsProvider);
    final counts = SessionFilter.countByKind(loaded.value ?? const []);
    final armed = ref.watch(mergeAnimationProvider);
    // Nach dem Bau, nicht währenddessen: `forward()` im Build löste einen
    // zweiten Build im selben Frame aus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _driveMerge(armed);
    });

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        // Board 06, A2: der Titel in Screen-Grösse, nicht als Kartenzeile.
        title: Text(l10n.listTitle, style: AtemType.titleLarge.of(context)),
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
            Expanded(
              // Solange der Strom noch nicht geantwortet hat, Zeilenskelette
              // (Board 06, A2/2) — nie „Noch kein Verlauf": Das wäre eine
              // Aussage über den Bestand, die noch niemand treffen kann.
              child: loaded.isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AtemSpacing.screenPadding),
                      child: AtemSkeleton(
                        semanticLabel: l10n.loadingLabel,
                        blocks:
                            List.filled(4, const AtemSkeletonBlock(height: 64)),
                      ),
                    )
                  : _body(context, ref, l10n, entries, filter, counts, armed),
            ),
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
    MergeAnimation? armed,
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
    // **Einmal mischen, dann gruppieren.** Andersherum bekäme jede
    // Monatsgruppe denselben Stapel wartender Einheiten — sie stünden so oft
    // in der Liste, wie es Monate gibt.
    // **Die zusammengeführte Uhr-Einheit kommt zurück in die Liste** —
    // solange die Bewegung läuft. Geschrieben ist sie längst weg; ohne die
    // Momentaufnahme gäbe es nur noch eine Zeile, und es bliebe nichts, was
    // in etwas hineinlaufen könnte.
    final pending = ref.watch(healthInboxProvider).pending;
    final replay = armed != null && !MediaQuery.disableAnimationsOf(context);
    final listed = mergePendingIntoTimeline(
      entries,
      replay ? [...pending, armed.measured] : pending,
    );

    final groups = <List<ListedEntry>>[];
    for (final item in listed) {
      final isHeader = item is ListedTimeline && item.entry is MonthHeader;
      if (isHeader || groups.isEmpty) groups.add([]);
      groups.last.add(item);
    }

    return CustomScrollView(
      slivers: [
        // Der Eingang steht über der Liste — ein Ort **und** ein Datum
        // (Board 15, Entscheidung 4). Er rendert nicht, wenn nichts wartet.
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 0),
          sliver: SliverToBoxAdapter(child: HealthInboxHeader()),
        ),
        for (final group in groups)
          if (group.first
              case ListedTimeline(
                entry: MonthHeader(
                  :final year,
                  :final month,
                  :final sessions,
                  :final load
                )
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
                  sliver: _blocks(group.skip(1), armed),
                ),
              ],
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AtemSpacing.screenPadding),
              sliver: _blocks(group, armed),
            ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
          sliver: SliverToBoxAdapter(child: HealthDeclinedList()),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  static double _monthHeaderHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) + 30;

  /// **Ein Container je Monat, nicht je Einheit** (Board 06, A2/1).
  ///
  /// Aufeinanderfolgende Einheiten werden zu einer Karte mit Haarlinien
  /// zusammengefasst; eine Lücke unterbricht sie und steht als eigener
  /// Streifen dazwischen. Vorher trug jede Zeile ihre eigene Karte — die
  /// Liste zerfiel damit in gleich aussehende Kacheln, an denen der Monat
  /// nicht mehr ablesbar war.
  Widget _blocks(Iterable<ListedEntry> items, MergeAnimation? armed) {
    final blocks = <Widget>[];
    var run = <TimelineSession>[];

    // Steht die Uhr-Zeile vor oder hinter der Zeile, in die sie läuft? Die
    // Reihenfolge steht nicht fest — eine Uhr-Einheit, die ein paar Minuten
    // früher beginnt, steht davor. Die Richtung entscheidet, wohin die
    // beiden Zeilen in Phase 1 rücken.
    var watchSeen = false;
    var appSeen = false;

    void flush() {
      if (run.isEmpty) return;
      blocks.add(_SessionBlock(
        entries: run,
        merging: armed,
        animation: _merge,
        watchAbove: watchSeen,
      ));
      run = <TimelineSession>[];
    }

    for (final item in items) {
      // Eine wartende Einheit unterbricht den Block: Sie liegt nicht in
      // derselben Karte wie die Einheiten, die zählen.
      if (item case ListedPending(:final session)) {
        flush();
        final merging =
            armed != null && armed.measured.externalId == session.externalId;
        if (merging) watchSeen = true;
        blocks.add(
          merging
              ? AtemMergingWatchRow(
                  animation: _merge,
                  towards: appSeen ? -1 : 1,
                  child: IgnorePointer(
                    // Während der Bewegung ist die Entscheidung schon
                    // gefallen. Ein Tipp darauf öffnete ein Prüfblatt für
                    // etwas, das es nicht mehr gibt.
                    child: ExcludeSemantics(
                      child: HealthPendingRow(session: session, quiet: true),
                    ),
                  ),
                )
              : HealthPendingRow(session: session),
        );
        continue;
      }
      final entry = (item as ListedTimeline).entry;
      switch (entry) {
        case TimelineSession():
          if (entry.session.id == armed?.sessionId) appSeen = true;
          run.add(entry);
        case TimelineGap(
            :final days,
            :final from,
            :final to,
            :final isLongest,
            :final isOpen
          ):
          flush();
          blocks.add(_Gap(
            days: days,
            from: from,
            to: to,
            isLongest: isLongest,
            isOpen: isOpen,
          ));
        case TimelineEnd(:final first, :final daysAgo):
          flush();
          blocks.add(_End(first: first, daysAgo: daysAgo));
        case MonthHeader():
          break;
      }
    }
    flush();

    return SliverList.builder(
      itemCount: blocks.length,
      itemBuilder: (context, i) => blocks[i],
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
            // „Alle 110": mit der Gesamtzahl, wie jeder andere Chip auch.
            label: l10n.historyAll(counts.values.fold<int>(0, (a, b) => a + b)),
            selected: filter.kind == null,
            // Nicht `toggleKind`: Auf „Alle" zu tippen, während „Alle" gilt,
            // sprang vorher auf Kraft.
            onTap: () => ref.read(sessionFilterProvider.notifier).clearKind(),
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
                      color:
                          selected ? AtemColors.cyan : AtemColors.textPrimary,
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
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AtemType.meta.of(context),
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
    this.merging,
    this.towards = 1,
  });

  final TrainingSession session;
  final int? ordinal;
  final double load;
  final double monthMax;

  /// Läuft gerade eine Uhr-Einheit in **diese** Zeile? Dann rückt sie ihr
  /// entgegen (Phase 1) und ihr Herkunftspunkt stellt sich um (Phase 3).
  final Animation<double>? merging;

  /// `-1`, wenn die Uhr-Zeile darüber steht, sonst `1`.
  final double towards;

  /// Die zweite Einheit des Tages — eingerückt, ohne Datum.
  bool get _followUp => ordinal != null && ordinal! > 1;

  @override
  Widget build(BuildContext context) {
    final running = merging;
    if (running == null) return _content(context, null);

    // Bei reduzierter Bewegung bleibt von der Choreografie **nur der
    // Punkt**: Er blendet in 120 ms auf seinen Endzustand um. Kein Rücken,
    // keine Uhr-Zeile, die noch einmal auftaucht — was geschehen ist, sagt
    // die Meldung in Worten.
    if (MediaQuery.disableAnimationsOf(context)) {
      return AnimatedBuilder(
        animation: running,
        builder: (context, _) => _content(context, running.value),
      );
    }

    // Die Verschiebung ist **reine Malerei**: Die Zeile behält ihre Höhe,
    // ihre Nachbarn in der Karte bleiben stehen. Nur so stimmt die Zusage
    // aus Phase 1, dass sonst nichts weicht.
    return AnimatedBuilder(
      animation: running,
      builder: (context, _) => Transform.translate(
        offset: Offset(
          0,
          AtemMergeMotion.approach *
              AtemMergeMotion.gather(running.value) *
              towards,
        ),
        child: _content(context, AtemMergeMotion.settle(running.value)),
      ),
    );
  }

  Widget _content(BuildContext context, double? mergeT) {
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

    // Die Herkunft (Board 15, C1). Der Punkt trägt sie als **Form**, nicht als
    // Farbe — und ab 130 % Systemschrift trägt sie ein Wort in der Metazeile,
    // weil ein 10-dp-Punkt neben 24-sp-Text zum Staubkorn wird. Nie beides.
    final origin = session.origin;
    final showDot = AtemOriginDot.fitsAt(context);
    final originWord = switch (origin) {
      SessionOrigin.app => null,
      SessionOrigin.watch => l10n.hcOriginWatch,
      SessionOrigin.merged => l10n.hcOriginBoth,
    };
    // Was die Uhr nicht messen kann, steht als Tatsache da — keine Mahnung,
    // keine Aufforderung, es nachzutragen. Nur an Einheiten, die überhaupt
    // aus der Uhr kommen: Bei einer App-Einheit ohne Anstrengung hat man die
    // Angabe schlicht nicht gemacht, und das gehört nicht in jede Zeile.
    final missingEffort = origin != SessionOrigin.app && session.rpe == null;
    final visibleMeta = <String>[
      if (meta.isNotEmpty) meta,
      if (!showDot && originWord != null) originWord,
      if (missingEffort) l10n.hcOriginMissingEffort,
    ].join(' · ');

    final hasLoad = load > 0;
    final share = monthMax <= 0 ? 0.0 : (load / monthMax).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.only(left: _followUp ? 10 : 0),
      child: Builder(
        builder: (context) => AtemTappable(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          ),
          // „Dienstag, 8. Juli, Laufen, Cardio, 8,2 Kilometer, Pace 5:42 pro
          // Kilometer, Last 412." — bei Mehrfachtagen ergänzt „2. Einheit",
          // weil die Einrückung nicht hörbar ist.
          //
          // Die Herkunft steht **immer** im Label, auch wenn sie sichtbar nur
          // als Punkt erscheint: Der Punkt ist `excludeSemantics`, und ein
          // eigener Knoten dafür machte aus einer Zeile zwei (Board 15, H).
          // Gesprochen heisst der dritte Zustand „App und Uhr" — App zuerst,
          // damit das Muster hörbar bleibt.
          semanticLabel: [
            spokenDate,
            name,
            meta,
            if (origin == SessionOrigin.watch) l10n.hcOriginWatch,
            if (origin == SessionOrigin.merged) l10n.hcOriginBothSpoken,
            if (missingEffort) l10n.hcOriginMissingEffort,
            if (hasLoad) '${l10n.detailLoad} ${load.round()}',
          ].join(', '),
          minTapSize: const Size(0, 56),
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      if (visibleMeta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          // Der Punkt sitzt auf der **ersten** Zeile, nicht
                          // in der Mitte des Blocks: Bei zwei Zeilen rutschte
                          // er sonst zwischen sie. Drei dp sind die halbe
                          // Differenz zur Zeilenhöhe der Metaschrift — er
                          // erscheint ohnehin nur unter 130 %, wo diese
                          // Differenz kaum wandert.
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Der Punkt sitzt in der Metazeile, nicht als
                            // dritte Spalte vor dem Namen: Er und das Wort,
                            // das ihn bei grosser Schrift ablöst, sollen
                            // denselben Platz haben. Eine eigene Spalte
                            // nähme dem Namen ausserdem 20 dp, und der
                            // ellipsiert auf 320 dp ohnehin schon.
                            if (showDot) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: mergeT == null
                                    ? AtemOriginDot(shape: originShape(origin))
                                    : AtemOriginDot.merging(progress: mergeT),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(visibleMeta,
                                  // **Zwei Zeilen, sobald etwas dazukommt.**
                                  // „Cardio · 42 min · ohne Anstrengung"
                                  // passt auf 361 dp nicht auf eine Zeile —
                                  // abgeschnitten fiele genau die Tatsache
                                  // weg, für die die Zeile steht. Die Höhe
                                  // kommt von innen, es läuft nichts über,
                                  // und betroffen sind nur die wenigen
                                  // Zeilen aus der Uhr.
                                  maxLines: visibleMeta == meta ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AtemType.meta.of(context)),
                            ),
                          ],
                        ),
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
                            borderRadius: BorderRadius.circular(AtemRadii.pill),
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

/// Die Einheiten eines Monats in **einer** Karte, mit Haarlinien getrennt.
class _SessionBlock extends StatelessWidget {
  const _SessionBlock({
    required this.entries,
    this.merging,
    this.animation,
    this.watchAbove = false,
  });

  final List<TimelineSession> entries;

  /// Die laufende Zusammenführung, falls eine läuft. Betrifft höchstens
  /// **eine** Zeile dieser Karte.
  final MergeAnimation? merging;
  final Animation<double>? animation;

  /// Ob die Uhr-Zeile über dieser Karte steht. Die Zeile rückt ihr entgegen.
  final bool watchAbove;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AtemCard.list(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Divider(
                        height: 1, thickness: 1, color: AtemColors.border),
                  ),
                _Row(
                  session: entries[i].session,
                  ordinal: entries[i].ordinalOnDay,
                  load: entries[i].load,
                  monthMax: entries[i].monthMaxLoad,
                  merging: entries[i].session.id == merging?.sessionId
                      ? animation
                      : null,
                  towards: watchAbove ? -1 : 1,
                ),
              ],
            ],
          ),
        ),
      );
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
    this.isOpen = false,
  });

  final int days;
  final DateTime from;
  final DateTime to;
  final bool isLongest;

  /// Bis heute offen: „09.07. – heute" statt zweier Daten.
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final range = isOpen
        ? l10n.listGapOpen(DateFormat.MMMd(tag).format(from))
        : l10n.listGapRange(
            DateFormat.MMMd(tag).format(from),
            DateFormat.MMMd(tag).format(to),
          );
    // Drei Textstufen (17.09.2026): Eine gewöhnliche Pause ist Beschriftung,
    // nur die längste trägt Magenta.
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
            // **Stack, nicht Row mit `stretch`.** Der Streifen liegt in einer
            // Sliver-Liste und bekommt keine Höhe von oben. Eine Row mit
            // `CrossAxisAlignment.stretch` reicht dann „unendlich hoch" an
            // ihre Kinder weiter — im Debug-Build ein Assert, im Release-Build
            // eine Rinne mit unendlicher Höhe, deren Strichschleife nie endet.
            // Genau so hing die App am 16.09.2026, sobald der Verlauf eine
            // Lücke von sieben Tagen enthielt. Der Text gibt jetzt die Höhe
            // vor, die Rinne füllt sie.
            child: Stack(
              children: [
                // Die linke Rinne, 34 dp, mit gestrichelter Vertikalen: Der
                // Streifen liest sich als Abwesenheit, nicht als Eintrag.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 34,
                  child: CustomPaint(painter: _DashedRail(color: color)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(46, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.listGap(days),
                        style: AtemType.labelSmall.of(context).copyWith(
                            color: color, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLongest ? '$range · ${l10n.listGapLongest}' : range,
                        style: AtemType.meta.of(context),
                      ),
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

/// Die gestrichelte Vertikale in der Rinne des Lückenstreifens.
class _DashedRail extends CustomPainter {
  _DashedRail({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.5);
    // Nie gegen eine unendliche Höhe zeichnen — die Schleife endete sonst
    // nicht. Das Layout darf das nicht mehr liefern; der Maler prüft trotzdem.
    if (!size.height.isFinite || !size.width.isFinite) return;
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

    if (!size.height.isFinite || !size.width.isFinite) return;
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

    // Board 06, A2/3: Das Ende ist eine Karte mit Mono-Kopf und Satz —
    // gestaltet, nicht bloss Scrollstopp.
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Semantics(
        label: '${l10n.listEndTitle}. ${l10n.listEndBody(date, daysAgo)}',
        child: ExcludeSemantics(
          child: AtemCard.list(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.listEndTitle.toUpperCase(),
                    style: AtemType.labelMicro.of(context)),
                const SizedBox(height: 6),
                Text(
                  l10n.listEndBody(date, daysAgo),
                  style: AtemType.labelSmall.of(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
