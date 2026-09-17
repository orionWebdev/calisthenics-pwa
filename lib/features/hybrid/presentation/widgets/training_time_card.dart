import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/tab_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../cardio/presentation/cardio_ui.dart';
import '../../../history/domain/training_session.dart';
import '../../domain/time_split.dart';
import '../../domain/training_time.dart';
import 'track_ui.dart';

/// **Trainingszeit** — Verhältnis und Zeit-Split in einem Block (17.09.2026).
///
/// ## Warum ein Block
///
/// Bis dahin standen hier zwei: „Verhältnis" (Kraft gegen Ausdauer, diese
/// Woche, mit Verschiebung) und „Trainingszeit" (drei Spuren, 14 oder 28
/// Tage). Beide teilten Minuten auf Spuren auf; der Nutzer las zweimal
/// dieselbe Aussage. Jetzt wählt der Umschalter das Fenster — „Diese Woche"
/// oder „28 Tage" —, und beide Fenster rechnen gleich ([TrainingTime]).
///
/// ## Was sichtbar bleibt
///
/// Balken, je Spur Name, Anteil und **eine** Metazeile (Minuten · Einheiten ·
/// Fachgrösse, nur was nicht 0 ist), darunter die Grundlage. Nur im
/// Wochenfenster steht neben dem Anteil die Verschiebung gegen die vier
/// Vorwochen. Rechenweg, Verschiebung und „Kein Sollverhältnis" stehen hinter
/// dem ⓘ (CLAUDE.md, „Text und Erklärungen").
///
/// ## Metazeilen brechen nie in einer Angabe
///
/// „8 / Sätze" war am Gerät zu sehen. Innerhalb einer Angabe stehen
/// geschützte Leerzeichen; umbrochen wird nur an „ · ".
///
/// ## Wann der Block fehlt
///
/// Hybrid ist kein Auswertungsbildschirm: Tragen weder die Woche noch die
/// 28 Tage Minuten, rendert der Block nicht ([hasData]). Ist nur das gewählte
/// Fenster leer, steht eine Zeile statt Balken; der Umschalter bleibt.
class TrainingTimeCard extends ConsumerStatefulWidget {
  const TrainingTimeCard({
    super.key,
    required this.sessions,
    required this.reference,
  });

  final List<TrainingSession> sessions;
  final DateTime reference;

  /// Ob überhaupt eines der beiden Fenster Minuten trägt.
  static bool hasData(List<TrainingSession> sessions, DateTime reference) =>
      TrainingTimeWindow.values
          .any((w) => !TrainingTime.compute(sessions, reference, w).isEmpty);

  @override
  ConsumerState<TrainingTimeCard> createState() => _TrainingTimeCardState();
}

class _TrainingTimeCardState extends ConsumerState<TrainingTimeCard> {
  TrainingTimeWindow _window = TrainingTimeWindow.week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    if (!TrainingTimeCard.hasData(widget.sessions, widget.reference)) {
      return const SizedBox.shrink();
    }
    final time =
        TrainingTime.compute(widget.sessions, widget.reference, _window);
    final isWeek = _window == TrainingTimeWindow.week;

    return AtemCard.list(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemExplainHeader(
            title: l10n.hybridTimeTitle,
            trailing: isWeek ? l10n.analysisWeeklyWeek(time.isoWeek) : null,
            explanation: [
              l10n.hybridTimeExplain,
              l10n.hybridTimeShiftExplain,
              l10n.hybridTimeNote,
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: AtemTabSwitch<TrainingTimeWindow>(
              groupSemanticLabel: l10n.hybridTimeGroup,
              value: _window,
              onChanged: (w) => setState(() => _window = w),
              segments: [
                AtemTabSegment(
                    value: TrainingTimeWindow.week, label: l10n.hybridTimeWeek),
                AtemTabSegment(
                    value: TrainingTimeWindow.days28,
                    label: l10n.hybridTimeDays28),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (time.isEmpty)
            Text(
              isWeek ? l10n.hybridTimeEmptyWeek : l10n.hybridTimeEmpty(28),
              style: AtemType.meta.of(context),
            )
          else ...[
            _Bar(time: time),
            const SizedBox(height: 14),
            for (final (i, track) in TrainingTrack.values.indexed) ...[
              if (i > 0) const SizedBox(height: 4),
              _TrackRow(time: time, track: track),
            ],
            const SizedBox(height: 12),
            const SizedBox(
                height: 1, child: ColoredBox(color: AtemColors.border)),
            const SizedBox(height: 12),
            Text(
              l10n.hybridTimeBasisShort(time.totalMinutes, time.totalCount),
              style: AtemType.meta.of(context),
            ),
            if (time.sessionsWithoutDuration > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.hybridTimeWithoutDuration(time.sessionsWithoutDuration),
                style: AtemType.labelSmall.of(context),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Der gestapelte Balken — **ein** Semantics-Knoten. Spuren ohne Minuten
/// erscheinen nicht; die Breiten wandern beim Fensterwechsel.
class _Bar extends StatelessWidget {
  const _Bar({required this.time});

  final TrainingTime time;

  static const _height = 12.0;
  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final visible = [
      for (final t in TrainingTrack.values)
        if (time.of(t).minutes > 0) t,
    ];
    final label = [
      for (final t in TrainingTrack.values)
        l10n.hybridTimeRowA11y(trackName(l10n, t), time.of(t).minutes,
            time.of(t).count, time.percentOf(t)),
    ].join('. ');

    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth - _gap * (visible.length - 1);
            return SizedBox(
              height: _height,
              child: Row(
                children: [
                  for (final (i, t) in visible.indexed) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(t),
                      tween: Tween(
                          end: width * time.of(t).minutes / time.totalMinutes),
                      duration: AtemMotion.duration(context, AtemMotion.normal),
                      curve: AtemMotion.curve,
                      builder: (context, w, _) => SizedBox(
                        width: w.clamp(0, width),
                        height: _height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: trackColor(t),
                            borderRadius: AtemRadii.pillR,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Eine Spur: Punkt, Name, Metazeile, rechts Anteil und ggf. Verschiebung.
/// Ein Semantics-Knoten; Kraft (und Cardio, sobald sichtbar) antippbar.
class _TrackRow extends ConsumerWidget {
  const _TrackRow({required this.time, required this.track});

  final TrainingTime time;
  final TrainingTrack track;

  /// Geschützte Leerzeichen innerhalb einer Angabe: „8 Sätze" bricht nie.
  static String _keep(String part) => part.replaceAll(' ', ' ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final totals = time.of(track);
    final percent = time.percentOf(track);
    final name = trackName(l10n, track);

    final parts = <String>[
      l10n.durationMinutes(totals.minutes),
      l10n.hybridTimeUnits(totals.count),
      if (track == TrainingTrack.strength && totals.sets > 0)
        l10n.hybridTimeSets(totals.sets),
      if (track == TrainingTrack.strength && totals.tonnageKg > 0)
        l10n.hybridTimeTonnage(
            AtemNumberField.format(context, totals.tonnageKg / 1000)),
      if (track == TrainingTrack.cardio && totals.km > 0)
        l10n.unitKilometers(formatKm(context, totals.km)),
    ];
    final meta = parts.map(_keep).join(' · ');

    final shift =
        time.window == TrainingTimeWindow.week ? time.shiftPp[track] : null;
    final shiftRounded = shift?.round();
    final showShift = shiftRounded != null && shiftRounded != 0;

    final a11y = showShift
        ? l10n.hybridTimeRowShiftA11y(
            name,
            totals.minutes,
            totals.count,
            percent,
            l10n.ratioShiftA11y('${shiftRounded.abs()}',
                shiftRounded > 0 ? l10n.ratioShiftUp : l10n.ratioShiftDown),
          )
        : l10n.hybridTimeRowA11y(name, totals.minutes, totals.count, percent);

    final VoidCallback? onTap = switch (track) {
      TrainingTrack.strength => () => ref.read(appTabsProvider.notifier).jump(
            AppTab.strength,
            strengthSegment: StrengthSegment.history,
          ),
      TrainingTrack.cardio when AppTab.visible.contains(AppTab.cardio) => () =>
          ref.read(appTabsProvider.notifier).jump(
                AppTab.cardio,
                cardioSegment: CardioSegment.analysis,
              ),
      _ => null,
    };
    final target = switch (track) {
      TrainingTrack.strength => l10n.ratioOpenStrength,
      TrainingTrack.cardio when onTap != null => l10n.ratioOpenCardio,
      _ => null,
    };

    // Ab 160 % effektiver Schrift wird die Zeile zweizeilig: Name und Anteil
    // oben, Metazeile und Verschiebung darunter über die volle Breite. Sonst
    // bleibt für die Metazeile so wenig Platz, dass selbst „Einheiten" im
    // Wort bricht (gerendert bei 200 % auf 320 dp) — dasselbe Muster wie die
    // Muskelbalance-Zeilen (Board 09, A3/3).
    final stacked = MediaQuery.textScalerOf(context).scale(10) >= 16;
    final percentText = Text('$percent %',
        softWrap: false, style: AtemType.valueMedium.of(context));
    final nameText = Text(name,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: AtemType.titleSmallOrDefault(context));
    final metaText = Text(meta, style: AtemType.meta.of(context));

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AtemStatusDot(color: trackColor(track)),
                    const SizedBox(width: 10),
                    Expanded(child: nameText),
                    const SizedBox(width: 12),
                    percentText,
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 17),
                  child: metaText,
                ),
                if (showShift) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 17),
                    child: _ShiftPill(pp: shiftRounded),
                  ),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AtemStatusDot(color: trackColor(track)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      nameText,
                      const SizedBox(height: 2),
                      metaText,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    percentText,
                    if (showShift) ...[
                      const SizedBox(height: 4),
                      _ShiftPill(pp: shiftRounded),
                    ],
                  ],
                ),
              ],
            ),
    );

    if (onTap == null) {
      return Semantics(label: a11y, excludeSemantics: true, child: content);
    }
    return AtemTappable(
      onTap: onTap,
      semanticLabel: [a11y, if (target != null) target].join(', '),
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: content,
    );
  }
}

/// „▲ 6 pp" — Tatsache, keine Wertung: #CDD3EA, keine Ampelfarbe. Mono, weil
/// Poppins die Richtungsglyphen nicht trägt.
class _ShiftPill extends StatelessWidget {
  const _ShiftPill({required this.pp});

  final int pp;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: AtemRadii.pillR,
          border: Border.all(color: AtemColors.border),
        ),
        child: Text(
          '${pp > 0 ? '▲' : '▼'} ${pp.abs()} pp',
          softWrap: false,
          style: AtemType.labelMicro
              .of(context)
              .copyWith(color: AtemColors.textTertiary, letterSpacing: 0),
        ),
      );
}
