import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/exercise_history.dart';

/// Dein Verlauf mit einer Übung — **vier Stufen, je nach Datenlage**.
///
/// | Ausführungen | Was erscheint |
/// |---|---|
/// | 0 | nichts — der Bildschirm hört früher auf |
/// | 1 | nur „Damals", mit dem Satz warum |
/// | 2–4 | die Kacheln, keine Kurve |
/// | ab 5 | mit Kurve |
///
/// ## Warum der Block bei null ganz fehlt
///
/// 84 der 154 Übungen sind kuratiert und die meisten nie ausgeführt. Ein
/// Block mit „noch keine Daten" stünde bei der Mehrheit da und machte den
/// Bildschirm leerer, nicht voller. Die Regel aus Modul 5 gilt: Ein Block
/// rendert nur mit Daten.
///
/// ## Warum die Kurve erst ab fünf
///
/// Aus zwei Punkten wird eine Gerade, und eine Gerade sieht aus wie ein
/// Trend. Die Schwelle liegt niedriger als beim Formtrend (acht), weil hier
/// ein Punkt eine **Ausführung** ist und kein Tag.
class ExerciseHistoryBlock extends StatelessWidget {
  const ExerciseHistoryBlock({
    super.key,
    required this.history,
    required this.reference,
    required this.languageTag,
  });

  final ExerciseHistory history;
  final DateTime reference;
  final String languageTag;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final l10n = AppL10n.of(context);
    final date = DateFormat.yMMMd(languageTag);
    final last = history.occurrences.first;

    return AtemCard.list(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.exerciseHistoryTitle,
                    style: AtemType.labelMedium.of(context)),
              ),
              const SizedBox(width: 10),
              Text(l10n.historyCount(history.sessionCount),
                  style: AtemType.labelMicro.of(context)),
            ],
          ),
          const SizedBox(height: 12),

          // Eine einzige Ausführung: „Damals", und der Satz, warum nicht mehr.
          if (history.sessionCount == 1) ...[
            _Tile(
              label: l10n.historyOnceLabel,
              value: _setsLabel(l10n, last),
              sub: l10n.historyOnce(date.format(last.date)),
            ),
            const SizedBox(height: 10),
            Text(l10n.historyOnceNote,
                style: AtemType.meta.of(context)),
          ] else ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Tile(
                  label: l10n.historyLast,
                  value: _setsLabel(l10n, last),
                  sub: date.format(last.date),
                ),
                if (history.recordOccurrence case final best?)
                  _Tile(
                    label: l10n.historyBest,
                    // **Bestes Satzgewicht, wie im Runner.** Bei
                    // Körpergewichtsübungen ohne Zusatzlast tritt die
                    // Wiederholungszahl an seine Stelle — was gemessen wird,
                    // steht im Untertitel.
                    value: history.measuresWeight
                        ? l10n.unitKilograms(
                            _trim(history.recordWeightKg!))
                        : '${best.totalReps ?? 0}',
                    sub: '${_setsLabel(l10n, best)} · '
                        '${date.format(best.date)}',
                    highlight: true,
                  ),
                if (history.frequencyPerWeek(reference) case final f?)
                  _Tile(
                    label: l10n.historyFreq,
                    // Eine Nachkommastelle: „1,8 / Wo" sagt etwas, „2 / Wo" rundet die
                    // Aussage weg.
                    value: l10n.historyFreqValue(
                        NumberFormat('0.#', languageTag).format(f)),
                    sub: l10n.historyCount(history.sessionCount),
                  ),
                _Tile(
                  label: l10n.historyVolume,
                  value: l10n.unitKilograms(last.volume.round().toString()),
                  sub: l10n.historyLast,
                ),
              ],
            ),
            if (history.hasCurve) ...[
              const SizedBox(height: 14),
              _Curve(history: history, languageTag: languageTag),
            ],
          ],
        ],
      ),
    );
  }

  static String _setsLabel(AppL10n l10n, ExerciseOccurrence occurrence) {
    final reps = occurrence.sets.first.reps;
    return reps == null
        ? '${occurrence.setCount}'
        : '${occurrence.setCount} × $reps';
  }

  static String _trim(double value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';
}

/// Eine Kachel. Die Bestwert-Variante trägt einen magentafarbenen Rand —
/// **Verstärkung, nicht Träger**: Das Wort „Bestwert" steht als Label da.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.sub,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String sub;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value, $sub',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minWidth: 132),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: AtemColors.surfaceSolid,
            borderRadius: AtemRadii.statBoxR,
            border: Border.all(
              color: highlight
                  ? AtemColors.magenta.withValues(alpha: 0.4)
                  : AtemColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AtemType.labelMicro.of(context).copyWith(
                      color: highlight
                          ? AtemColors.magenta
                          : AtemColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 3),
              Text(value, style: AtemType.valueMedium.of(context)),
              const SizedBox(height: 2),
              Text(sub, style: AtemType.meta.of(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Die Verlaufskurve — **ein Bild, kein bedienbares Diagramm**.
///
/// Kein Antippen einzelner Punkte: Der Bestwert steht ohnehin als Kachel
/// darüber und muss nicht aus der Kurve gelesen werden. Das Label nennt
/// Anzahl, Anfangs- und Endwert.
class _Curve extends StatelessWidget {
  const _Curve({required this.history, required this.languageTag});

  final ExerciseHistory history;
  final String languageTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final points = history.curve;
    if (points.length < 2) return const SizedBox.shrink();

    final date = DateFormat.MMMd(languageTag);
    final best = history.recordWeightKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          history.measuresWeight
              ? l10n.historyCurveLabel
              : l10n.historyVolume,
          style: AtemType.labelMicro.of(context),
        ),
        const SizedBox(height: 6),
        Semantics(
          image: true,
          label: l10n.historyCurveA11y(
            points.length,
            points.first.value.round().toString(),
            points.last.value.round().toString(),
          ),
          child: ExcludeSemantics(
            child: SizedBox(
              height: 62,
              child: CustomPaint(
                painter: _CurvePainter(points: points, best: best),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Erst die beiden Datumsangaben an den Enden — sie gehören zur Achse.
        // Die Legende steht darunter: „Ring markiert den Bestwert" ist bei
        // 320 dp breiter als der Platz zwischen zwei Datumsangaben, und ein
        // `Spacer` dazwischen lief um 315 px über.
        Row(
          children: [
            Expanded(
              child: Text(date.format(points.first.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.labelMicro.of(context)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                date.format(points.last.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AtemType.labelMicro.of(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(l10n.historyCurveLegend,
            style: AtemType.meta.of(context)),
      ],
    );
  }
}

class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.points, required this.best});

  final List<({DateTime date, double value})> points;
  final double? best;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    var min = points.first.value;
    var max = points.first.value;
    for (final point in points) {
      min = math.min(min, point.value);
      max = math.max(max, point.value);
    }
    // Eine waagerechte Kurve ist gültig — dann liegt sie in der Mitte, statt
    // durch eine Division durch null zu verschwinden.
    final span = max - min;
    const padding = 6.0;

    double x(int i) => i / (points.length - 1) * size.width;
    double y(double value) => span == 0
        ? size.height / 2
        : size.height - padding -
            (value - min) / span * (size.height - padding * 2);

    final line = Path()..moveTo(x(0), y(points.first.value));
    for (var i = 1; i < points.length; i++) {
      line.lineTo(x(i), y(points[i].value));
    }

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AtemColors.cyan,
    );

    for (var i = 0; i < points.length; i++) {
      final isBest = best != null && points[i].value == best;
      canvas.drawCircle(
        Offset(x(i), y(points[i].value)),
        isBest ? 3.5 : 3,
        Paint()..color = isBest ? AtemColors.magenta : AtemColors.cyan,
      );
      if (isBest) {
        // Der Ring markiert den Bestwert — die Legende sagt das auch in Worten.
        canvas.drawCircle(
          Offset(x(i), y(points[i].value)),
          6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = AtemColors.magenta,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.points != points || old.best != best;
}
