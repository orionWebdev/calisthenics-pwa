import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/exercise_history.dart';

/// Dein Verlauf mit einer Übung — **vier Stufen, je nach Datenlage**
/// (Board 09, A4).
///
/// | Ausführungen | Was erscheint |
/// |---|---|
/// | 0 | nichts — der Bildschirm hört früher auf |
/// | 1 | „1× ausgeführt · Datum", eine Kachel „Damals", der Satz warum |
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

  /// Ab dieser skalierten Wertgrösse stehen die Kacheln untereinander.
  ///
  /// Bei 14 sp Mono passt „2.640 kg" in eine halbe Karte auf 320 dp. Ab etwa
  /// 150 % nicht mehr — dann wird das Raster einspaltig, statt Werte zu
  /// kürzen (Board 09, A4: Werte nowrap).
  static const _twoColumnMaxValueSize = 21.0;

  /// Unter dieser Breite je Kachel wird das Raster ebenfalls einspaltig.
  static const _twoColumnMinTileWidth = 128.0;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final l10n = AppL10n.of(context);
    final once = history.sessionCount == 1;

    return AtemCard.list(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Head(history: history, once: once),
          const SizedBox(height: 14),
          if (once)
            ..._once(context, l10n)
          else ...[
            _Grid(tiles: _tiles(context, l10n)),
            if (history.hasCurve && history.curve.length >= 2) ...[
              const SizedBox(height: 16),
              const _Rule(),
              const SizedBox(height: 14),
              _Curve(history: history, languageTag: languageTag),
            ],
          ],
        ],
      ),
    );
  }

  /// Stufe 1 — eine Ausführung (A4/2).
  List<Widget> _once(BuildContext context, AppL10n l10n) {
    final last = history.occurrences.first;
    final shortDate = DateFormat.MMMd(languageTag).format(last.date);
    final longDate = DateFormat.MMMMd(languageTag).format(last.date);

    return [
      Semantics(
        label: '${l10n.historyCountA11y(1)}, '
            '${l10n.historyDateA11y(longDate)}',
        child: ExcludeSemantics(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 2,
            children: [
              Text(l10n.historyCount(1),
                  style: AtemType.valueLarge.of(context)),
              Text(l10n.historyOnce(shortDate),
                  style: AtemType.meta.of(context)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      _Tile(
        label: l10n.historyOnceLabel,
        value: _setsWithWeight(context, l10n, last),
        semanticLabel: l10n.historyTileA11y(
          l10n.historyOnceLabel,
          _setsA11y(l10n, last),
          _weightA11y(context, l10n, last) ?? l10n.historyDateA11y(longDate),
        ),
      ),
      const SizedBox(height: 16),
      const _Rule(),
      const SizedBox(height: 14),
      Text(l10n.historyOnceNote, style: AtemType.labelSmall.of(context)),
    ];
  }

  /// Stufe 2 bis 4 und ab 5 — die Kacheln (A4/1).
  List<Widget> _tiles(BuildContext context, AppL10n l10n) {
    final short = DateFormat.MMMd(languageTag);
    final long = DateFormat.MMMMd(languageTag);
    final last = history.occurrences.first;
    final tiles = <Widget>[];

    // ---- Zuletzt: „4 × 8" · „82,5 kg · 24. Aug."
    final lastWeight = last.bestWeightKg;
    tiles.add(_Tile(
      label: l10n.historyLast,
      value: _sets(last),
      sub: [
        if (lastWeight != null)
          l10n.unitKilograms(AtemNumberField.format(context, lastWeight)),
        short.format(last.date),
      ].join(' · '),
      semanticLabel: l10n.historyTileA11y(
        l10n.historyLast,
        _setsA11y(l10n, last),
        [
          if (_weightA11y(context, l10n, last) case final w?) w,
          l10n.historyDateA11y(long.format(last.date)),
        ].join(', '),
      ),
    ));

    // ---- Bestwert: „82,5 kg" · „4 × 8 · 24. Aug."
    //
    // **Bestes Satzgewicht, wie im Runner.** Bei Körpergewichtsübungen ohne
    // Zusatzlast gibt es keinen Bestwert in Kilogramm — dann trägt die
    // Kachel die meisten Wiederholungen einer Einheit und sagt das im Wert.
    final best = history.recordOccurrence ?? _mostReps();
    if (best != null) {
      final record = history.recordWeightKg;
      final value = record != null
          ? l10n.unitKilograms(AtemNumberField.format(context, record))
          : l10n.historyRepsValue(best.totalReps ?? 0);
      final valueA11y = record != null
          ? l10n.historyKgA11y(AtemNumberField.format(context, record))
          : l10n.historyRepsA11y(best.totalReps ?? 0);
      tiles.add(_Tile(
        label: l10n.historyBest,
        value: value,
        sub: '${_sets(best)} · ${short.format(best.date)}',
        highlight: true,
        semanticLabel: l10n.historyTileA11y(
          l10n.historyBest,
          valueA11y,
          '${_setsA11y(l10n, best)}, '
          '${l10n.historyDateA11y(long.format(best.date))}',
        ),
      ));
    }

    // ---- Häufigkeit: „1,8 / Wo" · „14× in 8 Wochen"
    final frequency = history.frequencyPerWeek(reference);
    final weeks = history.weeksSpan(reference);
    if (frequency != null && weeks != null) {
      // Eine Nachkommastelle: „1,8 / Wo" sagt etwas, „2 / Wo" rundet die
      // Aussage weg.
      final f = NumberFormat('0.#', languageTag).format(frequency);
      tiles.add(_Tile(
        label: l10n.historyFreq,
        value: l10n.historyFreqValue(f),
        sub: l10n.historyFreqBasis(history.sessionCount, weeks),
        semanticLabel: l10n.historyTileA11y(
          l10n.historyFreq,
          l10n.historyFreqA11y(f),
          l10n.historyFreqBasis(history.sessionCount, weeks),
        ),
      ));
    }

    // ---- Volumen: „2.640 kg" · „letzte Einheit"
    //
    // Nur mit Gewicht. Wiederholungen ohne Gewicht sind kein Volumen von
    // null, sondern gar keins — „0 kg" wäre eine falsche Aussage.
    if (last.volume > 0) {
      final volume =
          NumberFormat.decimalPattern(languageTag).format(last.volume.round());
      tiles.add(_Tile(
        label: l10n.historyVolume,
        value: l10n.unitKilograms(volume),
        sub: l10n.historyVolumeSub,
        semanticLabel: l10n.historyTileA11y(
          l10n.historyVolume,
          l10n.historyKgA11y(volume),
          l10n.historyVolumeSub,
        ),
      ));
    }

    return tiles;
  }

  /// Die Ausführung mit den meisten Wiederholungen — Bestwert ohne Gewicht.
  ExerciseOccurrence? _mostReps() {
    ExerciseOccurrence? best;
    for (final occurrence in history.occurrences.reversed) {
      final reps = occurrence.totalReps;
      if (reps == null) continue;
      if (best == null || reps > (best.totalReps ?? 0)) best = occurrence;
    }
    return best;
  }

  /// „4 × 8" — Sätze mal Wiederholungen des ersten Satzes; ohne
  /// Wiederholungen (Halteübung) nur die Satzzahl.
  static String _sets(ExerciseOccurrence occurrence) {
    final reps = occurrence.sets.first.reps;
    return reps == null
        ? '${occurrence.setCount}'
        : '${occurrence.setCount} × $reps';
  }

  static String _setsA11y(AppL10n l10n, ExerciseOccurrence occurrence) {
    final reps = occurrence.sets.first.reps;
    return reps == null
        ? l10n.historySetsOnlyA11y(occurrence.setCount)
        : l10n.historySetsA11y(occurrence.setCount, reps);
  }

  /// „3 × 5 · 60 kg" — das Gewicht nur, wenn eins erfasst ist.
  static String _setsWithWeight(
    BuildContext context,
    AppL10n l10n,
    ExerciseOccurrence occurrence,
  ) {
    final weight = occurrence.bestWeightKg;
    return weight == null
        ? _sets(occurrence)
        : '${_sets(occurrence)} · '
            '${l10n.unitKilograms(AtemNumberField.format(context, weight))}';
  }

  static String? _weightA11y(
    BuildContext context,
    AppL10n l10n,
    ExerciseOccurrence occurrence,
  ) {
    final weight = occurrence.bestWeightKg;
    return weight == null
        ? null
        : l10n.historyKgA11y(AtemNumberField.format(context, weight));
  }
}

/// Titel links, „14×" rechts. Bei einer Ausführung steht die Zahl in der
/// Zeile darunter, gross — oben würde sie sich wiederholen.
class _Head extends StatelessWidget {
  const _Head({required this.history, required this.once});

  final ExerciseHistory history;
  final bool once;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(l10n.exerciseHistoryTitle,
                style: AtemType.titleMedium.of(context)),
          ),
        ),
        if (!once) ...[
          const SizedBox(width: 10),
          Semantics(
            label: l10n.historyCountA11y(history.sessionCount),
            child: ExcludeSemantics(
              child: Text(
                l10n.historyCount(history.sessionCount),
                style:
                    AtemType.labelMicro.of(context).copyWith(letterSpacing: 0),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Zwei gleich breite Spalten, bei grosser Schrift oder schmaler Karte eine.
class _Grid extends StatelessWidget {
  const _Grid({required this.tiles});

  final List<Widget> tiles;

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final valueSize = MediaQuery.textScalerOf(context).scale(16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - _gap) / 2;
        final twoColumns =
            valueSize <= ExerciseHistoryBlock._twoColumnMaxValueSize &&
                half >= ExerciseHistoryBlock._twoColumnMinTileWidth;

        if (!twoColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: _gap),
                tiles[i],
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i += 2) ...[
              if (i > 0) const SizedBox(height: _gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[i]),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: i + 1 < tiles.length
                          ? tiles[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Eine Kachel. Die Bestwert-Variante trägt einen magentafarbenen Rand und
/// einen magentafarbenen Kopf — **Verstärkung, nicht Träger**: Das Wort
/// „Bestwert" steht als Label da.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.semanticLabel,
    this.sub,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String? sub;
  final String semanticLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                label.toUpperCase(),
                style: AtemType.labelMicro.of(context).copyWith(
                      color: highlight
                          ? AtemColors.magenta
                          : AtemColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(value,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: AtemType.valueMedium.of(context)),
              if (sub != null) ...[
                const SizedBox(height: 4),
                Text(sub!, style: AtemType.meta.of(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 1, child: ColoredBox(color: AtemColors.border));
}

/// Die Verlaufskurve — **ein Bild, kein bedienbares Diagramm**.
///
/// Kein Antippen einzelner Punkte: Der Bestwert steht ohnehin als Kachel
/// darüber und muss nicht aus der Kurve gelesen werden. Das Label nennt
/// Anzahl, Anfangs-, End- und Bestwert.
///
/// Nur Einheiten mit dieser Übung sind Punkte, gleichmässig verteilt —
/// keine Interpolation über Wochen ohne Ausführung, sonst entstünde eine
/// Kurve, die Tage behauptet, an denen nichts war.
class _Curve extends StatelessWidget {
  const _Curve({required this.history, required this.languageTag});

  final ExerciseHistory history;
  final String languageTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final points = history.curve;
    final weight = history.measuresWeight;

    final short = DateFormat.MMMd(languageTag);
    var best = points.first.value;
    for (final p in points) {
      best = math.max(best, p.value);
    }

    String shown(double v) => weight
        ? l10n.unitKilograms(AtemNumberField.format(context, v))
        : l10n.historyRepsValue(v.round());
    String spoken(double v) => weight
        ? l10n.historyKgA11y(AtemNumberField.format(context, v))
        : l10n.historyRepsA11y(v.round());

    final label = [
      weight
          ? l10n.historyCurveA11y(points.length, spoken(points.first.value),
              spoken(points.last.value))
          : l10n.historyCurveRepsA11y(points.length, spoken(points.first.value),
              spoken(points.last.value)),
      l10n.historyCurveBestA11y(spoken(best)),
    ].join(', ');

    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wrap statt Row: Bei 200 % rutscht die Anzahl unter den Kopf,
            // statt ihn Buchstabe für Buchstabe umbrechen zu lassen.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 10,
              runSpacing: 4,
              children: [
                Text(
                  (weight ? l10n.historyCurveLabel : l10n.historyCurveRepsLabel)
                      .toUpperCase(),
                  style: AtemType.labelMicro.of(context),
                ),
                Text(
                  l10n.historyCurveCount(points.length),
                  style: AtemType.labelMicro.of(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 62,
              child: AtemSweep(
                child: CustomPaint(
                  painter: _CurvePainter(points: points, best: best),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Datum und Wert an beiden Enden. `Flexible` statt Spacer: Bei
            // 200 % auf 320 dp passen zwei Angaben nicht nebeneinander, dann
            // kürzt die linke, statt über den Rand zu laufen.
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${short.format(points.first.date)} · ${shown(points.first.value)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(letterSpacing: 0),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '${short.format(points.last.date)} · ${shown(points.last.value)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(letterSpacing: 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AtemColors.magenta, width: 2),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(l10n.historyCurveLegend,
                      style: AtemType.labelSmall.of(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.points, required this.best});

  final List<({DateTime date, double value})> points;
  final double best;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || !size.isFinite) return;

    var min = points.first.value;
    for (final point in points) {
      min = math.min(min, point.value);
    }
    // Eine waagerechte Kurve ist gültig — dann liegt sie in der Mitte, statt
    // durch eine Division durch null zu verschwinden.
    final span = best - min;
    const padX = 8.0;
    const padTop = 8.0;
    const padBottom = 12.0;

    double x(int i) => padX + i / (points.length - 1) * (size.width - padX * 2);
    double y(double value) => span == 0
        ? size.height / 2
        : padTop +
            (1 - (value - min) / span) * (size.height - padTop - padBottom);

    // Grundlinie.
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..strokeWidth = 1
        ..color = AtemColors.border,
    );

    // Gestrichelte Bestwertlinie.
    final bestY = y(best);
    final dash = Paint()
      ..strokeWidth = 1
      ..color = AtemColors.border;
    for (var dx = 0.0; dx < size.width; dx += 7) {
      canvas.drawLine(
        Offset(dx, bestY),
        Offset(math.min(dx + 4, size.width), bestY),
        dash,
      );
    }

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

    // Der Bestwert wird einmal markiert — beim ersten Erreichen.
    var bestMarked = false;
    for (var i = 0; i < points.length; i++) {
      final center = Offset(x(i), y(points[i].value));
      final isBest = !bestMarked && points[i].value == best;
      if (isBest) {
        bestMarked = true;
        canvas.drawCircle(center, 5.5, Paint()..color = AtemColors.card);
        canvas.drawCircle(
          center,
          5.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AtemColors.magenta,
        );
      } else {
        canvas.drawCircle(center, 3, Paint()..color = AtemColors.cyan);
      }
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.points != points || old.best != best;
}
