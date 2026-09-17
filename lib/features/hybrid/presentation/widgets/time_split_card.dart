import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/domain/training_session.dart';
import '../../domain/time_split.dart';
import 'track_ui.dart';

/// Trainingszeit der letzten 14 oder 28 Tage, aufgeteilt in Kraft, Ausdauer
/// und Regeneration — **Minuten, kein Urteil** (Masterplan, Phase 1).
///
/// ## Was hier ersetzt wurde
///
/// Bis 16.09.2026 stand an dieser Stelle der Formwert: eine Zahl 0–100 aus
/// fünf Bestandteilen, die nach 16 Tagen Pause durch eine einzige Einheit von
/// 0 auf 75 sprang. Der Nutzer konnte sie nicht erklären, und die App konnte
/// es auch nicht ohne einen Absatz. Dieser Block zählt nur: Wie viele Minuten
/// gingen in welche Spur, wie viele Einheiten waren das, in wie vielen Tagen.
/// Jede Zahl nennt ihren Nenner.
///
/// ## Zwei Fenster, ein Zustand
///
/// Der Umschalter 14 | 28 ist lokal: Er wählt eine Sicht, keinen Wert, und
/// überlebt weder Tabwechsel noch Neustart. Beim Wechsel wandern die
/// Balkenanteile — sie werden nicht neu gebaut, sonst sähe der Wechsel wie
/// ein Ladefehler aus.
///
/// ## Wann der Block fehlt
///
/// Trägt keines der beiden Fenster Minuten, rendert die Karte nicht — der
/// Bildschirm hört früher auf (CLAUDE.md). Ist nur das gewählte Fenster leer,
/// steht statt Balken und Zeilen eine Zeile, die das sagt; der Umschalter
/// bleibt, damit man das andere Fenster erreicht.
class TimeSplitCard extends StatefulWidget {
  const TimeSplitCard({
    super.key,
    required this.sessions,
    required this.reference,
  });

  final List<TrainingSession> sessions;
  final DateTime reference;

  static const shortWindow = 14;
  static const longWindow = 28;

  /// Ob es überhaupt etwas zu zeigen gibt — für den Bildschirm, der
  /// entscheidet, ob der Block steht.
  static bool hasData(List<TrainingSession> sessions, DateTime reference) =>
      !TimeSplit.compute(sessions, reference, days: longWindow).isEmpty;

  @override
  State<TimeSplitCard> createState() => _TimeSplitCardState();
}

class _TimeSplitCardState extends State<TimeSplitCard> {
  int _days = TimeSplitCard.shortWindow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    // 28 Tage umfassen 14: Ist das lange Fenster leer, ist es auch das kurze.
    final long = TimeSplit.compute(widget.sessions, widget.reference,
        days: TimeSplitCard.longWindow);
    if (long.isEmpty) return const SizedBox.shrink();
    final split = _days == TimeSplitCard.longWindow
        ? long
        : TimeSplit.compute(widget.sessions, widget.reference,
            days: TimeSplitCard.shortWindow);

    return AtemCard.list(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, l10n),
          const SizedBox(height: 14),
          if (split.isEmpty)
            Text(
              l10n.hybridTimeEmpty(split.days),
              style: AtemType.meta.of(context),
            )
          else ...[
            _Bar(split: split),
            const SizedBox(height: 12),
            for (final (i, track) in TrainingTrack.values.indexed) ...[
              if (i > 0) const SizedBox(height: 6),
              _TrackRow(split: split, track: track),
            ],
            const SizedBox(height: 12),
            const SizedBox(
                height: 1, child: ColoredBox(color: AtemColors.border)),
            const SizedBox(height: 12),
            Text(
              l10n.hybridTimeBasis(
                  split.totalMinutes, split.totalCount, split.days),
              style: AtemType.meta.of(context),
            ),
            if (split.sessionsWithoutDuration > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.hybridTimeWithoutDuration(split.sessionsWithoutDuration),
                style: AtemType.labelSmall.of(context),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Titel mit ⓘ, darunter der Umschalter (seit 17.09.2026). Was der Block
  /// zeigt und „Kein Sollverhältnis" stehen hinter dem ⓘ — CLAUDE.md, „Text
  /// und Erklärungen". Der Umschalter steht nicht im Kopf, damit das ⓘ
  /// neben dem Titel bleibt und bei 200 % nichts abgeschnitten wird.
  Widget _header(BuildContext context, AppL10n l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtemExplainHeader(
            title: l10n.hybridTimeTitle,
            explanation: [l10n.hybridTimeExplain, l10n.hybridTimeNote],
          ),
          const SizedBox(height: 10),
          AtemTabSwitch<int>(
            groupSemanticLabel: l10n.hybridTimeGroup,
            value: _days,
            onChanged: (days) => setState(() => _days = days),
            segments: [
              AtemTabSegment(
                  value: TimeSplitCard.shortWindow,
                  label: l10n.hybridTimeDays14),
              AtemTabSegment(
                  value: TimeSplitCard.longWindow,
                  label: l10n.hybridTimeDays28),
            ],
          ),
        ],
      );
}

/// Der gestapelte Balken — **ein** Semantics-Knoten, nicht drei Segmente.
///
/// Eine Spur ohne Minuten erscheint nicht: Ein Nullsegment wäre eine Lücke,
/// die wie ein Fehler aussieht. Die Zeile darunter nennt die 0 trotzdem.
class _Bar extends StatelessWidget {
  const _Bar({required this.split});

  final TimeSplit split;

  static const _height = 12.0;
  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final visible = [
      for (final t in TrainingTrack.values)
        if (split.of(t).minutes > 0) t,
    ];
    final total = split.totalMinutes;
    final label = [
      for (final t in TrainingTrack.values)
        l10n.hybridTimeRowA11y(
          trackName(l10n, t),
          split.of(t).minutes,
          split.of(t).count,
          split.percentOf(t),
        ),
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
                    // Die Breite wandert beim Fensterwechsel; das Segment
                    // bleibt dasselbe Widget (Key je Spur).
                    TweenAnimationBuilder<double>(
                      key: ValueKey(t),
                      tween: Tween(end: width * split.of(t).minutes / total),
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

/// Eine Spur: Punkt, Name, Minuten · Einheiten, rechts der Anteil.
/// Ein Semantics-Knoten je Zeile.
class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.split, required this.track});

  final TimeSplit split;
  final TrainingTrack track;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final time = split.of(track);
    final percent = split.percentOf(track);
    final name = trackName(l10n, track);

    return Semantics(
      label: l10n.hybridTimeRowA11y(name, time.minutes, time.count, percent),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AtemStatusDot(color: trackColor(track)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: AtemType.titleSmallOrDefault(context)),
                  Text(
                    '${l10n.durationMinutes(time.minutes)} · ${l10n.hybridTimeUnits(time.count)}',
                    style: AtemType.meta.of(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('$percent %',
                softWrap: false, style: AtemType.valueMedium.of(context)),
          ],
        ),
      ),
    );
  }
}
