import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/strength_progress.dart';
import '../session_ui.dart';

/// Das geschätzte Maximum je Kernübung — **eine Schätzung, kein Test**.
///
/// Ersetzt seit dem 16.09.2026 die Formkurve in der Kraft-Auswertung
/// (Masterplan, Abschnitt 3 B): Epley rechnet aus Gewicht und Wiederholungen
/// eines Satzes ein Maximum, das niemand gehoben hat. Deshalb steht die
/// Formel sichtbar unter dem Diagramm, und jede Zahl nennt die Zahl der
/// Einheiten, aus denen sie kommt.
///
/// ## Was nicht hier steht
///
/// Ein Urteil. Ob 84 kg gut sind, weiss der Nutzer. Der Block zeigt den
/// Verlauf der besten Schätzung je Einheit und die Verschiebung seit der
/// ersten — als Tatsache in `textTertiary` mit Richtungsglyph, keine
/// Ampelfarbe.
///
/// ## Dünn ist sichtbar
///
/// Unter fünf Einheiten je Übung gibt es keine Kurve, sondern den Weg
/// dorthin: die bis zu drei nächsten Kandidaten mit ihrem Stand. Ohne einen
/// einzigen zählbaren Satz rendert die Karte nicht — der Bildschirm hört
/// früher auf.
class EstimatedMaxCard extends StatefulWidget {
  const EstimatedMaxCard({
    super.key,
    required this.series,
    required this.candidates,
    required this.nameOf,
  });

  /// Übungen mit mindestens [StrengthProgress.minimumSessions] Einheiten,
  /// sortiert nach Einheiten absteigend.
  final List<ExerciseStrengthSeries> series;

  /// Alle Übungen mit mindestens einer zählbaren Einheit — daraus kommen die
  /// Kandidaten im dünnen Zustand.
  final List<ExerciseStrengthSeries> candidates;

  /// Der Name zur Übungs-ID; unbekannte ID → die ID selbst.
  final String Function(String exerciseId) nameOf;

  /// Wie viele Kandidaten der dünne Zustand nennt.
  static const thinCandidates = 3;

  @override
  State<EstimatedMaxCard> createState() => _EstimatedMaxCardState();
}

class _EstimatedMaxCardState extends State<EstimatedMaxCard> {
  String? _selectedId;

  ExerciseStrengthSeries? get _selected {
    if (widget.series.isEmpty) return null;
    for (final s in widget.series) {
      if (s.exerciseId == _selectedId) return s;
    }
    // Standard: die Übung mit den meisten Einheiten.
    return widget.series.first;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.isEmpty) {
      final thin = [
        for (final c in widget.candidates)
          if (c.sessionCount < StrengthProgress.minimumSessions) c,
      ]..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));
      if (thin.isEmpty) return const SizedBox.shrink();
      return _Thin(
        candidates: thin.take(EstimatedMaxCard.thinCandidates).toList(),
        nameOf: widget.nameOf,
      );
    }

    final l10n = AppL10n.of(context);
    final selected = _selected!;
    final name = widget.nameOf(selected.exerciseId);

    return AtemCard.list(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.analysisMaxTitle, style: AtemType.titleMedium.of(context)),
          const SizedBox(height: 12),
          // Eine Kapselreihe, horizontal scrollend: Bei 200 % auf 320 dp
          // passen zwei Übungsnamen nebeneinander, mehr nicht — ein Wrap
          // würde die Karte um mehrere Zeilen strecken.
          Semantics(
            container: true,
            label: l10n.analysisMaxExerciseGroup,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, s) in widget.series.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    AtemChoiceChip(
                      label: widget.nameOf(s.exerciseId),
                      semanticLabel:
                          '${widget.nameOf(s.exerciseId)}, ${l10n.hybridTimeUnits(s.sessionCount)}',
                      selected: s.exerciseId == selected.exerciseId,
                      onTap: () => setState(() => _selectedId = s.exerciseId),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Chart(series: selected, name: name),
          const SizedBox(height: 12),
          Text(
            l10n.analysisMaxBasis(
              selected.sessionCount,
              AtemNumberField.format(context, selected.latest),
              AtemNumberField.format(context, selected.best),
            ),
            style: AtemType.meta.of(context),
          ),
          const SizedBox(height: 4),
          _Delta(delta: selected.deltaSinceFirst),
          const SizedBox(height: 10),
          Text(l10n.analysisMaxHint, style: AtemType.labelSmall.of(context)),
        ],
      ),
    );
  }
}

/// Die Verschiebung seit der ersten Einheit — Tatsache mit Richtungsglyph.
///
/// Der Glyph wird nie vorgelesen; das Wort steht im Label. Ein Wert ohne
/// Vergleich ist nie stumm: „kein Vergleich verfügbar".
class _Delta extends StatelessWidget {
  const _Delta({required this.delta});

  final double? delta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final d = delta;
    if (d == null) {
      return Text(l10n.analysisMaxNoDelta, style: AtemType.meta.of(context));
    }
    final rounded = (d * 10).round() / 10;
    final amount = AtemNumberField.format(context, rounded.abs());
    final glyph = rounded > 0 ? '▲ ' : (rounded < 0 ? '▼ ' : '— ');
    final direction = rounded >= 0 ? l10n.ratioShiftUp : l10n.ratioShiftDown;

    return Semantics(
      label: l10n.analysisMaxDeltaA11y(direction, amount),
      child: ExcludeSemantics(
        child: Text(
          '$glyph${l10n.analysisMaxDelta(amount)}',
          style: AtemType.meta
              .of(context)
              .copyWith(color: AtemColors.textTertiary),
        ),
      ),
    );
  }
}

/// Die Kurve — **gleichmässig verteilte Punkte, ein Punkt je Einheit.**
///
/// Wie die Tempokurve (Board 11, B3/2): Die x-Achse ist die Reihenfolge,
/// nicht die Zeit, deshalb keine Linie über Lücken, die es nicht gibt. Der
/// Rug-Plot darunter zeigt, wo die Einheiten wirklich lagen.
class _Chart extends StatelessWidget {
  const _Chart({required this.series, required this.name});

  final ExerciseStrengthSeries series;
  final String name;

  static const height = 66.0;
  static const rug = 4.0;
  static const radius = 3.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final points = series.points;
    final fmt = DateFormat.MMMd(languageTag(context));

    return Semantics(
      image: true,
      label: l10n.analysisMaxChartA11y(
        name,
        AtemNumberField.format(context, points.first.estimatedMax),
        AtemNumberField.format(context, points.last.estimatedMax),
        points.length,
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AtemNumberField.format(context, series.best)} ${l10n.analysisMaxYAxis}',
                  style: AtemType.labelDeco.of(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: height + rug + 6,
              child: AtemSweep(
                child: CustomPaint(painter: _Painter(series: series)),
              ),
            ),
            const SizedBox(height: 6),
            // Beide Daten nachgiebig: Bei 200 % auf 320 dp sind zwei
            // Monatsdaten breiter als die Zeile — sie kürzen, statt zu
            // überlaufen; die Werte stehen ohnehin im Semantics-Label.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(fmt.format(points.first.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelDeco.of(context)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(fmt.format(points.last.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AtemType.labelDeco.of(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter({required this.series});

  final ExerciseStrengthSeries series;

  @override
  void paint(Canvas canvas, Size size) {
    final points = series.points;
    if (points.isEmpty || size.width <= 0 || !size.width.isFinite) return;

    const chartHeight = _Chart.height;
    final values = points.map((p) => p.estimatedMax).toList();
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (hi == lo) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.12;
    lo -= pad;
    hi += pad;

    double y(double value) {
      final t = (value - lo) / (hi - lo);
      return chartHeight -
          t * (chartHeight - 2 * _Chart.radius) -
          _Chart.radius;
    }

    double x(int i) => points.length == 1
        ? size.width / 2
        : _Chart.radius +
            (size.width - 2 * _Chart.radius) * i / (points.length - 1);

    final axis = Paint()
      ..color = AtemColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
        const Offset(0, chartHeight), Offset(size.width, chartHeight), axis);

    // Bestwert als gestrichelte Referenz.
    final by = y(series.best);
    var dx = 0.0;
    while (dx < size.width) {
      canvas.drawLine(Offset(dx, by), Offset(dx + 4, by), axis);
      dx += 8;
    }

    final line = Paint()
      ..color = AtemColors.cyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < points.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = AtemColors.cyan;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(x(i), y(values[i])), _Chart.radius, dot);
    }

    // Rug-Plot: wo die Einheiten wirklich lagen, auf der Zeitachse.
    final first = points.first.date;
    final span = points.last.date.difference(first).inDays;
    final rugPaint = Paint()
      ..color = AtemColors.cyan.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const top = chartHeight + 4;
    for (final p in points) {
      final offset = p.date.difference(first).inDays;
      final rx = span <= 0
          ? size.width / 2
          : _Chart.radius + (size.width - 2 * _Chart.radius) * offset / span;
      canvas.drawLine(Offset(rx, top), Offset(rx, top + _Chart.rug), rugPaint);
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.series != series;
}

/// Noch keine Übung mit fünf Einheiten — **der Weg dorthin, kein Fake-Chart.**
class _Thin extends StatelessWidget {
  const _Thin({required this.candidates, required this.nameOf});

  final List<ExerciseStrengthSeries> candidates;
  final String Function(String exerciseId) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    const target = StrengthProgress.minimumSessions;

    return AtemCard.list(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.analysisMaxThinTitle,
              style: AtemType.titleMedium.of(context)),
          const SizedBox(height: 6),
          Text(
            l10n.analysisMaxThinBody(target, StrengthProgress.maximumReps),
            style: AtemType.labelSmall.of(context),
          ),
          for (final c in candidates) ...[
            const SizedBox(height: 14),
            _Progress(
              text: l10n.analysisMaxProgress(
                  nameOf(c.exerciseId), c.sessionCount, target),
              value: c.sessionCount / target,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ein Fortschrittsbalken der Wartezeit — Rolle progressBar mit value/max.
class _Progress extends StatelessWidget {
  const _Progress({required this.text, required this.value});

  final String text;
  final double value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(text, style: AtemType.meta.of(context)),
          ),
          const SizedBox(height: 8),
          AtemProgressBar.share(
            value: value.clamp(0.0, 1.0),
            semanticLabel: text,
            accent: AtemColors.cyan,
          ),
        ],
      );
}
