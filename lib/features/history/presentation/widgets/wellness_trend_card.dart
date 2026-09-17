import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/training_session.dart';
import '../../domain/wellness_trend.dart';
import '../session_ui.dart';
import 'wellness_fields.dart';

/// „Vorher und nachher" — Bereitschaft und Gefühl je Krafteinheit.
///
/// Frage: *Wie fühle ich mich nach dem Training im Vergleich zu vorher?*
///
/// Auf dem Auswertungsbildschirm rendert der Block immer (CLAUDE.md, seit
/// 16.09.2026). Unter [WellnessTrend.minimumPairs] Einheiten mit beiden
/// Angaben steht [AtemThresholdBlock] — Titel, Bedingung, Fortschritt, aber
/// keine Punkte: Drei Paare sähen genauso aus wie dreissig.
///
/// Gefüllt zeigt er die jüngsten Paare als Punktreihe — oben vorher, unten
/// nachher, je in der Stufenfarbe mit der Zahl darin — und zählt, wie oft
/// nachher höher, gleich oder niedriger lag. **Wertfrei:** „höher" ist nicht
/// „besser".
///
/// Seit 17.09.2026 stehen die Erklärung der Punkte, das „höher ist nicht
/// besser" und der Hinweis auf Einheiten mit nur einer Angabe hinter dem ⓘ.
/// Sichtbar bleiben die kurze Legende — ohne sie ist die Reihe nicht lesbar
/// —, die Zählung und die Grundlage mit Nenner. Keine Zahl in Amber: Die
/// Stufenfarben der Punkte sind hier der Träger.
class WellnessTrendCard extends StatelessWidget {
  const WellnessTrendCard({
    super.key,
    required this.sessions,
    required this.reference,
  });

  final List<TrainingSession> sessions;
  final DateTime reference;

  /// Höchstens so viele Paare in der Reihe — mehr passt auf keine Breite.
  static const maxPairs = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final trend = WellnessTrend.compute(sessions, reference);
    final weeks = (trend.windowDays / 7).round();

    if (!trend.hasEnough) {
      return AtemThresholdBlock(
        title: l10n.wellnessTrendTitle,
        trailing: l10n.wellnessTrendWindow(weeks),
        what: l10n.wellnessTrendWhat,
        condition: l10n.wellnessTrendCondition(WellnessTrend.minimumPairs),
        current: trend.withBoth,
        required: WellnessTrend.minimumPairs,
      );
    }

    // Eigene Knoten für Titel, Reihe, Zählung und Grundlage: Ohne Container
    // verschmolz TalkBack die ganze Karte zu einem einzigen Absatz.
    return AtemCard.list(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtemExplainHeader(
              title: l10n.wellnessTrendTitle,
              trailing: l10n.wellnessTrendWindow(weeks),
              explanation: [
                l10n.wellnessTrendWhat,
                l10n.wellnessTrendExplain,
              ],
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Text(l10n.wellnessTrendLegend,
                  style: AtemType.meta.of(context)),
            ),
            const SizedBox(height: 10),
            _PairRow(pairs: trend.latest(maxPairs)),
            const SizedBox(height: 14),
            Semantics(
              container: true,
              label: l10n.wellnessTrendCountsA11y(
                  trend.higher, trend.same, trend.lower),
              child: ExcludeSemantics(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text('▲ ${l10n.wellnessTrendHigher(trend.higher)}',
                        style: AtemType.meta.of(context)),
                    Text('— ${l10n.wellnessTrendSame(trend.same)}',
                        style: AtemType.meta.of(context)),
                    Text('▼ ${l10n.wellnessTrendLower(trend.lower)}',
                        style: AtemType.meta.of(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(
                height: 1, child: ColoredBox(color: AtemColors.border)),
            const SizedBox(height: 10),
            Text(
              l10n.wellnessTrendBasis(trend.withBoth, trend.total),
              style: AtemType.meta.of(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Die Punktreihe: je Einheit eine Spalte, oben vorher, unten nachher.
///
/// Die Zahlen in den Punkten skalieren **nicht** mit der Systemschrift — ein
/// Kreis kann nicht mitwachsen, ohne die Reihe zu sprengen. Sie sind
/// deshalb Verstärkung: Die Reihe ist ein Semantics-Knoten mit allen Paaren
/// als Satz, und die Zählung darunter skaliert voll.
class _PairRow extends StatelessWidget {
  const _PairRow({required this.pairs});

  final List<WellnessPair> pairs;

  static const _gap = 4.0;
  static const _minDot = 22.0;
  static const _maxDot = 28.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final format = DateFormat.MMMMd(languageTag(context));

    return LayoutBuilder(builder: (context, constraints) {
      // So viele Spalten, wie mit mindestens 22 dp je Punkt passen — die
      // jüngsten gewinnen.
      final fit = math.max(
          1, ((constraints.maxWidth + _gap) / (_minDot + _gap)).floor());
      final shown =
          pairs.length <= fit ? pairs : pairs.sublist(pairs.length - fit);
      final dot = math.min(
        _maxDot,
        (constraints.maxWidth - _gap * (shown.length - 1)) / shown.length,
      );

      final spoken = [
        for (final p in shown)
          l10n.wellnessTrendPair(
            format.format(p.date),
            p.before,
            readinessWord(l10n, p.before),
            p.after,
            feelingWord(l10n, p.after),
          ),
      ].join('; ');

      return Semantics(
        container: true,
        label: l10n.wellnessTrendRowA11y(spoken),
        child: ExcludeSemantics(
          child: MediaQuery.withNoTextScaling(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  _PairColumn(pair: shown[i], size: dot),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _PairColumn extends StatelessWidget {
  const _PairColumn({required this.pair, required this.size});

  final WellnessPair pair;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(level: pair.before, size: size),
          Container(width: 1, height: 10, color: AtemColors.border),
          _Dot(level: pair.after, size: size),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.level, required this.size});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: wellnessColor(level),
        shape: BoxShape.circle,
      ),
      // Auf allen fünf Stufenfarben erreicht onNeon mindestens 5:1
      // (atem_scale_choice_test.dart prüft das).
      child: Text(
        '$level',
        style: AtemType.valueMedium.of(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AtemColors.onNeon,
              height: 1,
            ),
      ),
    );
  }
}
