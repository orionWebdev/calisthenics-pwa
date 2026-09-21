import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/session_detail.dart';
import '../../domain/training_session.dart';
import '../session_ui.dart';
import 'detail_text.dart';

/// Der Kopf — **zwei Sekunden, eine Zahl** (Board 16, A).
///
/// Vier Zeilen, immer dieselben: Art und Name · Tag mit Beginn–Ende · die
/// Leitzahl mit ihrer Einheit · ein Satz Grundlage. Der Blick fällt auf die
/// Leitzahl, weil sie die einzige grosse ist — nicht weil sie farbig wäre.
///
/// **Ohne Zahl ist er trotzdem gültig.** Läuft die Leitwertkette leer, wächst
/// der Titel auf Leitzahl-Rang, und der Satz benennt die Lücke. Keine „0",
/// kein „—" als Wert, kein Nachtrag-Aufruf für etwas, das vor Monaten war.
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.session, required this.text});

  final TrainingSession session;
  final DetailHeaderText text;

  @override
  Widget build(BuildContext context) {
    final titleStyle = text.hasLead
        // Poppins 17/600 — der Titel ist da, aber nicht der Blickfang.
        ? AtemType.titleSmallOrDefault(context).copyWith(fontSize: 17)
        // Ohne Zahl trägt der Titel den Kopf: Leitzahl-Rang, 20 sp.
        : AtemType.titleLarge.of(context);

    return Semantics(
      // **Ein Knoten**, nicht vier: Der Kopf wird als ein Satz vorgelesen.
      header: true,
      container: true,
      label: text.spoken,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _KindGlyph(session: session),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(text.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(text.time, style: AtemType.meta.of(context)),
            if (text.hasLead) ...[
              const SizedBox(height: 14),
              // **Die Leitzahl schrumpft nicht, sie wird umbrochen**: Bei 200 %
              // stehen Zahl und Einheit übereinander. Kein FittedBox — Text
              // herunterzuskalieren nähme zurück, was jemand eingestellt hat.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                children: [
                  Text(
                    text.leadValue!,
                    style: AtemType.valueLarge.of(context).copyWith(
                      fontSize: 46,
                      fontWeight: FontWeight.w700,
                      color: AtemColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(text.leadUnit!.toUpperCase(),
                        style: AtemType.meta.of(context)),
                  ),
                ],
              ),
            ],
            if (text.basis.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(text.basis,
                  style: AtemType.body
                      .of(context)
                      .copyWith(color: AtemColors.textTertiary, height: 1.55)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Die Art als 12-dp-Glyph: Quadrat, halbes Quadrat, Raute, Ring.
///
/// **Vier Formen tragen sieben Arten**: Laufen, Radfahren und Schwimmen haben
/// dieselbe Raute und verschiedene Wörter. Eine Farbe je Art wäre sofort
/// lesbar und führte vier Farbbedeutungen ein, die mit der Rollenordnung
/// (Handlung, Quelle, Eingriff, Bestätigung) kollidieren (Entscheidung 6).
class _KindGlyph extends StatelessWidget {
  const _KindGlyph({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: 12,
          child: CustomPaint(painter: _GlyphPainter(session.kind)),
        ),
      );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.kind);

  final SessionKind? kind;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = AtemColors.textTertiary;
    final stroke = Paint()
      ..color = AtemColors.textTertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final rect = Offset.zero & size;

    switch (kind) {
      case SessionKind.strength:
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)), fill);
      case SessionKind.bodyweight:
        // Halbes Quadrat: links gefüllt, rechts nur der Rand.
        canvas
          ..drawRRect(
              RRect.fromRectAndRadius(
                  rect.deflate(0.8), const Radius.circular(2)),
              stroke)
          ..drawRect(Rect.fromLTWH(0, 0, size.width / 2, size.height), fill);
      case SessionKind.cardio:
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
        canvas.drawPath(path, fill);
      case SessionKind.recovery:
        canvas.drawCircle(rect.center, size.width / 2 - 1, stroke);
      case null:
        canvas.drawCircle(rect.center, size.width / 2 - 1, stroke);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.kind != kind;
}

/// Die Kennzahlkacheln — höchstens vier, zwei Spalten, ab 200 % eine.
///
/// **Die Fläche ist die Quelle.** Violett hinterlegt heisst: aus der Uhr; dazu
/// ein Ring-Glyph, damit Farbe nicht allein trägt. Werte stehen weiss —
/// **nie cyan**: Auf diesem Bildschirm trägt Cyan ausschliesslich Handlung
/// (Entscheidung 3, Korrektur zu Modul 15). Wären zwölf gemessene Zahlen
/// cyan, sähe die Hälfte des Bildschirms tippbar aus.
class MetricTiles extends StatelessWidget {
  const MetricTiles({super.key, required this.tiles, this.loading = false});

  final List<MetricTile> tiles;

  /// Solange die Uhr noch antwortet: Skelett in der Höhe, die die Kacheln
  /// haben werden — **keine Nullen, keine Striche**, ein Skelett behauptet
  /// keinen Wert.
  final bool loading;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty && !loading) return const SizedBox.shrink();

    // Ab 200 % Schrift eine Spalte: Wrap, kein horizontaler Scroll.
    final oneColumn = MediaQuery.textScalerOf(context).scale(10) / 10 >= 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = oneColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - _gap) / 2;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            if (loading)
              for (var i = 0; i < 4; i++)
                SizedBox(width: width, child: const _TileSkeleton())
            else
              for (final tile in tiles)
                SizedBox(width: width, child: _TileView(tile: tile)),
          ],
        );
      },
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
        child: SizedBox(
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AtemColors.card,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
      );
}

class _TileView extends StatelessWidget {
  const _TileView({required this.tile});

  final MetricTile tile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final fromWatch = tile.source == MetricSource.watch;

    final (label, spokenLabel, value, unit) = switch (tile.kind) {
      MetricKind.duration => (
          l10n.detailMetricDuration,
          l10n.detailMetricDuration,
          '${tile.value.toInt()}',
          l10n.detailLeadDuration
        ),
      MetricKind.volume => (
          l10n.detailMetricVolume,
          l10n.detailMetricVolume,
          DetailHeaderText.groupedInt(tile.value.round()),
          l10n.detailLeadVolume
        ),
      MetricKind.load => (
          l10n.detailLoad,
          l10n.detailSpokenLoad,
          '${tile.value.toInt()}',
          ''
        ),
      MetricKind.heartRateAvg => (
          l10n.detailMetricHrAvg,
          l10n.detailSpokenHrAvg,
          '${tile.value.toInt()}',
          l10n.detailUnitBpm
        ),
      MetricKind.calories => (
          l10n.detailMetricCalories,
          l10n.detailMetricCalories,
          '${tile.value.toInt()}',
          l10n.detailUnitKcal
        ),
      MetricKind.elevation => (
          l10n.detailMetricElevation,
          l10n.detailMetricElevation,
          NumberFormat.decimalPattern(tag).format(tile.value.round()),
          l10n.detailUnitHm
        ),
    };

    // **Die Herkunft im Label, nicht als eigener Knoten**: „Durchschnittspuls
    // 118 bpm, aus der Uhr".
    final spoken = l10n.detailSpokenTile(
      spokenLabel,
      value,
      unit,
      fromWatch ? l10n.hcOriginWatch : l10n.detailSourceApp,
    );

    return Semantics(
      container: true,
      label: spoken,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: fromWatch
                ? AtemColors.violet.withValues(alpha: 0.22)
                : AtemColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: fromWatch
                  ? AtemColors.violet.withValues(alpha: 0.55)
                  : AtemColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label.toUpperCase(),
                        style: AtemType.labelMicro.of(context).copyWith(
                            color: fromWatch
                                ? AtemColors.textTertiary
                                : AtemColors.textSecondary)),
                  ),
                  // Der Ring-Glyph: Farbe allein trüge die Quelle nicht.
                  if (fromWatch)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: AtemOriginDot(
                        shape: AtemOriginShape.hollow,
                        color: AtemColors.textTertiary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 4,
                children: [
                  Text(value,
                      style: AtemType.valueMedium.of(context).copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AtemColors.textPrimary)),
                  if (unit.isNotEmpty)
                    Text(unit.toUpperCase(), style: AtemType.meta.of(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
