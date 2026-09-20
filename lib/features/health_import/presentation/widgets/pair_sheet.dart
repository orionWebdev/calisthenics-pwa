import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../application/health_import_providers.dart';
import '../../domain/health_session.dart';
import '../../domain/merge_preview.dart';
import '../../domain/session_pairing.dart';
import '../health_import_ui.dart';
import 'merge_consequences.dart';

/// Fragt, ob eine Uhr-Einheit zu einer App-Einheit gehört (Board 15, B1).
///
/// Gibt die **Kennung der App-Einheit** zurück, mit der zusammengeführt
/// wurde — dann ist die Uhr-Einheit erledigt und das Prüfblatt braucht sie
/// nicht mehr. `null`, wenn nicht zusammengeführt wurde.
///
/// Nicht `bool`: Bei mehreren Kandidaten entscheidet sich erst **im Blatt**,
/// welche Einheit es wird. Die Liste braucht sie danach, um die Bewegung an
/// der richtigen Zeile zu zeigen (B6).
Future<String?> showPairSheet(
  BuildContext context, {
  required HealthSession measured,
  required PairVerdict verdict,
}) async {
  final l10n = AppL10n.of(context);
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0x00000000),
    barrierColor: AtemOverlays.barrier(AtemOverlays.sheetBarrierOpacity),
    barrierLabel: l10n.stepPadClose,
    showDragHandle: false,
    builder: (_) => PairSheet(measured: measured, verdict: verdict),
  );
}

/// **Die Vermutung wird als Frage gestellt, nie als Tatsache angekündigt.**
///
/// Bei genau einem Kandidaten steht die Frage mit beiden Einheiten und dem
/// Überlappungsbalken als Begründung. Bei mehreren gibt es keine Vermutung:
/// Die Zuordnung wird von Hand gewählt, und der Weg ohne Zuordnung bleibt
/// gleichwertig sichtbar (Entscheidung 7).
class PairSheet extends ConsumerWidget {
  const PairSheet({super.key, required this.measured, required this.verdict});

  final HealthSession measured;
  final PairVerdict verdict;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);

    return switch (verdict) {
      PairSuggested(:final session, :final overlap) => _Suggestion(
          measured: measured,
          session: session,
          overlap: overlap,
        ),
      PairAmbiguous(:final candidates) => _Ambiguous(
          measured: measured,
          candidates: candidates,
        ),
      // Ohne Kandidat gibt es nichts zu fragen — der Aufrufer öffnet dann
      // gar kein Paar-Blatt.
      PairNone() => AtemSheet.content(
          title: l10n.hcPairQuestion,
          closeLabel: l10n.stepPadClose,
          child: const SizedBox.shrink(),
        ),
    };
  }
}

class _Suggestion extends ConsumerWidget {
  const _Suggestion({
    required this.measured,
    required this.session,
    required this.overlap,
  });

  final HealthSession measured;
  final TrainingSession session;
  final Duration overlap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final appStart = session.date;
    final appEnd = appStart.add(session.duration ?? Duration.zero);
    final shorter = (session.duration ?? Duration.zero) < measured.duration
        ? (session.duration ?? Duration.zero)
        : measured.duration;
    final apart = appStart.difference(measured.start).abs().inMinutes;

    return AtemSheet.content(
      title: l10n.hcPairQuestion,
      closeLabel: l10n.stepPadClose,
      primaryAction: AtemButton.gradient(
        label: l10n.hcPairMerge,
        semanticLabel: l10n.hcPairMerge,
        gradient: AtemGradients.brandCta,
        onPressed: () => _confirm(context, ref),
      ),
      secondaryAction: AtemButton.outline(
        label: l10n.hcPairKeepApart,
        semanticLabel: l10n.hcPairKeepApart,
        // Getrennt lassen führt in den normalen Prüfbildschirm — sie wird
        // dann eine eigene Einheit.
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PairCard(
            kicker: l10n.hcPairAppRow,
            title: sessionName(l10n, session),
            meta: [
              _span(tag, appStart, appEnd, session.duration),
              if (_setsOf(session) case final sets? when sets > 0)
                '$sets ${l10n.hcFieldSets}',
              if (session.rpe case final rpe?) 'RPE $rpe',
            ].join(' · '),
            tone: AtemColors.cyan,
            filled: false,
          ),
          const SizedBox(height: 8),
          // **Ohne eigene Überschrift**: Die Uhr-Karte zeigt, was die Uhr
          // gemessen hat. Ein Titel „58 min" sagte nur noch einmal, was in
          // der Zeile darunter steht.
          _PairCard(
            kicker: l10n.hcPairWatchRow,
            meta: [
              _span(tag, measured.start, measured.end, measured.duration),
              if (measured.averageHeartRate case final bpm?)
                '${l10n.hcFieldHrAvg} $bpm',
              if (measured.maxHeartRate case final bpm?)
                '${l10n.hcFieldHrMax} $bpm',
            ].join(' · '),
            tone: AtemColors.violet,
            filled: true,
          ),
          const SizedBox(height: 12),
          _OverlapBar(
            appStart: appStart,
            appEnd: appEnd,
            watchStart: measured.start,
            watchEnd: measured.end,
            label: l10n.hcPairOverlap(
              overlap.inMinutes,
              shorter.inMinutes,
              apart,
            ),
          ),
        ],
      ),
    );
  }

  static int? _setsOf(TrainingSession session) => session is StrengthSession
      ? session.exercises.fold<int>(0, (n, e) => n + e.sets.length)
      : null;

  static String _span(
      String tag, DateTime from, DateTime to, Duration? duration) {
    final clock = DateFormat.Hm(tag);
    final minutes = (duration ?? to.difference(from)).inMinutes;
    return '${clock.format(from)}–${clock.format(to)} · $minutes min';
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await showMergeConsequences(
      context,
      preview: MergePreview.merging(session: session, measured: measured),
      merging: true,
    );
    if (!ok || !context.mounted) return;
    await ref
        .read(healthImportControllerProvider.notifier)
        .merge(measured, session);
    if (!context.mounted) return;
    _announceMerge(ref, AppL10n.of(context), measured, session.id);
    Navigator.of(context).pop(session.id);
  }
}

/// Die Meldung nach dem Eingriff — **mit dem ersten der beiden Rückwege**.
///
/// Sechs Sekunden Rücknahme unmittelbar danach; dauerhaft bleibt „Verbindung
/// lösen" im Einheitendetail (Board 15, B4). Zwei Wege zurück, bewusst
/// getrennt: Der eine ist für den Fehlgriff, der andere für die spätere
/// Einsicht.
///
/// Die Rücknahme ist dieselbe Handlung wie das Lösen — verlustfrei, weil die
/// Uhr-Einheit die ganze Zeit als eigener Datensatz danebenlag.
void _announceMerge(
  WidgetRef ref,
  AppL10n l10n,
  HealthSession measured,
  String sessionId,
) {
  // **Den Controller greifen, nicht `ref`.** Das Blatt schliesst sich gleich;
  // sechs Sekunden später hängt `ref` an einem abgebauten Widget, und die
  // Rücknahme stürbe mit der Meldung, die sie anbietet.
  final controller = ref.read(healthImportControllerProvider.notifier);
  ref.read(snackbarProvider.notifier).show(AtemSnack(
        message: l10n.hcMergedSnack,
        semanticLabel: l10n.hcMergedSnack,
        tone: AtemSnackTone.success,
        actionLabel: l10n.commonUndo,
        onAction: () => controller.unlink(measured, sessionId),
      ));
}

/// Zwei Einheiten im Zeitraum: **keine Vermutung**, sondern eine Auswahl.
class _Ambiguous extends ConsumerWidget {
  const _Ambiguous({required this.measured, required this.candidates});

  final HealthSession measured;
  final List<TrainingSession> candidates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);

    return AtemSheet.content(
      title: HealthImportUi.title(l10n, measured),
      closeLabel: l10n.stepPadClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemNotice(
            title: l10n.hcAmbiguousPick,
            body: l10n.hcAmbiguousNote,
            semanticLabel: '${l10n.hcAmbiguousPick}. ${l10n.hcAmbiguousNote}',
          ),
          const SizedBox(height: 12),
          for (final candidate in candidates) ...[
            _CandidateRow(
              session: candidate,
              languageTag: tag,
              onPick: () => _pick(context, ref, candidate),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          // **Gleichwertig sichtbar, nicht bevorzugt.** Als Marken-CTA im
          // Fuss wäre der Weg ohne Zuordnung die empfohlene Antwort — und
          // damit doch wieder eine Vermutung.
          AtemButton.outline(
            label: l10n.hcAmbiguousStandalone,
            semanticLabel: l10n.hcAmbiguousStandalone,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(
      BuildContext context, WidgetRef ref, TrainingSession session) async {
    final ok = await showMergeConsequences(
      context,
      preview: MergePreview.merging(session: session, measured: measured),
      merging: true,
    );
    if (!ok || !context.mounted) return;
    await ref
        .read(healthImportControllerProvider.notifier)
        .merge(measured, session);
    if (!context.mounted) return;
    _announceMerge(ref, AppL10n.of(context), measured, session.id);
    Navigator.of(context).pop(session.id);
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.session,
    required this.languageTag,
    required this.onPick,
  });

  final TrainingSession session;
  final String languageTag;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final name = sessionName(l10n, session);
    final clock = DateFormat.Hm(languageTag);
    final end = session.date.add(session.duration ?? Duration.zero);
    final meta = '${clock.format(session.date)}–${clock.format(end)}';

    return AtemTappable(
      onTap: onPick,
      semanticLabel: '$name, $meta. ${l10n.hcAmbiguousPick}',
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: BorderRadius.circular(AtemRadii.statBox),
          border: Border.all(color: AtemColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.titleSmallOrDefault(context)),
                  const SizedBox(height: 2),
                  Text(meta, style: AtemType.meta.of(context)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.hcAmbiguousPick,
              style:
                  AtemType.labelUi.of(context).copyWith(color: AtemColors.cyan),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine der beiden Einheiten in der Frage.
///
/// Die App trägt Cyan als Rand, die Uhr Violett als **Fläche** — violett ist
/// in dieser App nie Text.
class _PairCard extends StatelessWidget {
  const _PairCard({
    required this.kicker,
    required this.meta,
    required this.tone,
    required this.filled,
    this.title,
  });

  final String kicker;

  /// `null` bei der Uhr-Karte — dort sind die Werte die Auskunft.
  final String? title;
  final String meta;
  final Color tone;
  final bool filled;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: [kicker, if (title != null) title!, meta].join(', '),
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: filled ? tone.withValues(alpha: 0.2) : AtemColors.card,
              borderRadius: BorderRadius.circular(AtemRadii.statBox),
              border: Border.all(
                color: tone.withValues(alpha: filled ? 0.5 : 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kicker.toUpperCase(),
                    style: AtemType.labelMicro.of(context)),
                const SizedBox(height: 4),
                if (title case final name?) ...[
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.titleSmallOrDefault(context)),
                  const SizedBox(height: 2),
                ],
                Text(meta, style: AtemType.meta.of(context)),
              ],
            ),
          ),
        ),
      );
}

/// Der Balken **ist die Begründung in Form**: oben die App, unten die Uhr,
/// dazwischen die gemeinsame Spanne.
///
/// Die Zahl steht im Vorlesetext, die Balken sind stumm.
class _OverlapBar extends StatelessWidget {
  const _OverlapBar({
    required this.appStart,
    required this.appEnd,
    required this.watchStart,
    required this.watchEnd,
    required this.label,
  });

  final DateTime appStart;
  final DateTime appEnd;
  final DateTime watchStart;
  final DateTime watchEnd;
  final String label;

  @override
  Widget build(BuildContext context) {
    final from = appStart.isBefore(watchStart) ? appStart : watchStart;
    final to = appEnd.isAfter(watchEnd) ? appEnd : watchEnd;
    final total = to.difference(from).inSeconds;

    (double, double) range(DateTime a, DateTime b) => total <= 0
        ? (0, 1)
        : (
            a.difference(from).inSeconds / total,
            b.difference(from).inSeconds / total,
          );

    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Track(range: range(appStart, appEnd), color: AtemColors.cyan),
            const SizedBox(height: 4),
            _Track(
                range: range(watchStart, watchEnd), color: AtemColors.violet),
            const SizedBox(height: 8),
            Text(label, style: AtemType.meta.of(context)),
          ],
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.range, required this.color});

  final (double, double) range;
  final Color color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final left = (range.$1.clamp(0.0, 1.0)) * width;
          final right = (range.$2.clamp(0.0, 1.0)) * width;
          return SizedBox(
            height: 10,
            child: Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AtemColors.card,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  left: left,
                  width: (right - left).clamp(2.0, width),
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
