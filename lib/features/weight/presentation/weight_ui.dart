import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../../history/presentation/session_ui.dart' show languageTag;
import '../domain/weight_entry.dart';
import '../domain/weight_series.dart';

/// Formate und Wörter, die im Block, im Blatt und im Verlauf dieselben sein
/// müssen — sonst heisst derselbe Tag an drei Stellen anders.
abstract final class WeightUi {
  /// „15. Sept" — kurz, für Anker, Listenzeilen und den Datums-Chip.
  static String shortDate(BuildContext context, DateTime date) =>
      DateFormat.MMMd(languageTag(context)).format(date);

  /// „1. September" — lang, für die Veränderungszeile, wo der Satz gelesen
  /// wird statt überflogen.
  static String longDate(BuildContext context, DateTime date) =>
      DateFormat.MMMMd(languageTag(context)).format(date);

  /// „78,9"
  static String kg(BuildContext context, double value) =>
      AtemNumberField.format(context, value);

  static String source(AppL10n l10n, WeightSource source) => switch (source) {
        WeightSource.manual => l10n.weightSourceTyped,
        WeightSource.healthConnect => l10n.weightSourceMeasured,
        WeightSource.settings => l10n.weightSourceSettings,
      };

  static String rangeLabel(AppL10n l10n, WeightRange range) => switch (range) {
        WeightRange.threeMonths => l10n.weightRange3m,
        WeightRange.sixMonths => l10n.weightRange6m,
        WeightRange.year => l10n.weightRange1y,
        WeightRange.all => l10n.weightRangeAll,
      };

  /// Die Veränderungszeile — **ohne Vorzeichen im Text**.
  ///
  /// Die Richtung trägt der Glyph daneben und, für Vorleseprogramme, das Wort
  /// in [changeA11y]. Ein Minuszeichen davor wäre ein zweiter Träger derselben
  /// Aussage und läse sich wie eine Wertung.
  static String change(
    BuildContext context,
    AppL10n l10n,
    WeightChange value,
  ) {
    final delta = kg(context, value.magnitudeKg);
    final date = longDate(context, value.from.date);
    return value.isUp
        ? l10n.weightChangeUp(delta, date, value.days)
        : l10n.weightChangeDown(delta, date, value.days);
  }

  static String changeA11y(
    BuildContext context,
    AppL10n l10n,
    WeightChange value,
  ) {
    final delta = kg(context, value.magnitudeKg);
    final date = longDate(context, value.from.date);
    return value.isUp
        ? l10n.weightChangeUpA11y(delta, date, value.days)
        : l10n.weightChangeDownA11y(delta, date, value.days);
  }

  /// Das Von-Bis-Label der Kurve. Nennt die Lücke, wenn es eine gibt — ein
  /// Bruch in der Linie ist für ein Vorleseprogramm sonst nicht vorhanden.
  static String chartLabel(
    BuildContext context,
    AppL10n l10n,
    WeightSeries series,
  ) {
    final from = kg(context, series.first!.kg);
    final to = kg(context, series.latest!.kg);
    if (!series.hasLine) {
      return l10n.weightChartThinA11y(series.length, from, to);
    }
    final gap = series.namedGap;
    if (gap != null) {
      return l10n.weightChartGapA11y(series.length, gap.weeks, from, to);
    }
    return l10n.weightChartA11y(series.length, from, to);
  }
}

/// Der Richtungsglyph der Veränderungszeile — **nie allein der Träger**.
///
/// Dreieck nach oben oder unten in [AtemColors.textTertiary], derselben Farbe
/// wie der Satz daneben: Zunahme und Abnahme sehen gleich aus, nur die Form
/// unterscheidet (Board 14, Entscheidung 4). Für Vorleseprogramme ist er
/// stumm; das Wort steht im Label der Zeile.
class WeightChangeGlyph extends StatelessWidget {
  const WeightChangeGlyph({super.key, required this.up, required this.color});

  final bool up;
  final Color color;

  /// Skaliert mit der Schrift, damit der Glyph neben einem 200 % grossen Satz
  /// nicht zum Staubkorn wird.
  static const _base = 9.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(_base);
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GlyphPainter(up: up, color: color)),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.up, required this.color});

  final bool up;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height * 0.85)
        ..lineTo(0, size.height * 0.85);
    } else {
      path
        ..moveTo(size.width / 2, size.height)
        ..lineTo(0, size.height * 0.15)
        ..lineTo(size.width, size.height * 0.15);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.up != up || old.color != color;
}
