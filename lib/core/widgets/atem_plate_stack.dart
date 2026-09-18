import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Eine Stangenhälfte mit ihren Scheiben — die Grafik des Scheibenrechners
/// (Punkt 2.4 der Produktstrategie vom 18.09.2026).
///
/// ## Kein Board — aus den Tokens gebaut
///
/// Für diese Grafik gibt es kein Spezifikations-Board. Sie ist aus
/// `atem_colors.dart` zusammengesetzt und bleibt bewusst zurückhaltend:
///
/// - **Keine Farbcodes der Wettkampfscheiben** (rot 25, blau 20, gelb 15 …).
///   Das wäre eine zehnte Farbe und ein Code, den nicht jeder Hantelraum
///   teilt. Das Gewicht steht in Grösse — schwere Scheiben sind höher und
///   dicker — und als Zahl darunter.
/// - Fläche `surfaceRaised`, Umriss `textSecondary`: Die Scheibe muss sich vom
///   Kartengrund abheben; `border` auf `surfaceRaised` war zu schwach, um
///   eine 1,25er noch als Scheibe zu erkennen.
/// - Die Stange ist eine Linie in `textSecondary`, der Anschlag ein kleiner
///   Block davor.
///
/// ## Nur Bild, kein Vorlese-Text
///
/// Die Grafik ist von den Semantics ausgeschlossen. Wer sie zeigt, fasst sie
/// mit der Textzeile darunter zu **einem** Knoten zusammen („Scheiben je
/// Seite: eine 25, eine 15. Stange 20 Kilogramm") — Regel „eine Datenzeile ist
/// ein Semantics-Knoten".
///
/// ## Feste Höhe, nie gestauchte Schrift
///
/// Die Grafik ist immer [height] hoch, mit oder ohne Scheiben. Sie steht im
/// Eingabeblatt über dem Band; wüchse sie mit der Belegung, spränge das Band
/// beim Ziehen unter dem Daumen weg.
///
/// Wird sie zu breit (acht Scheiben bei 200 % Schrift auf 320 dp), fallen
/// zuerst die Zahlen unter den Scheiben weg, dann werden die Scheiben dünner.
/// Kein `FittedBox`: Der verkleinerte die Zahlen unter die Lesegrösse
/// (Konvention `no_fitted_box_around_text`). Die Zahlen stehen ohnehin
/// vollständig in der Textzeile darunter, die mit der Systemschrift wächst.
class AtemPlateStack extends StatelessWidget {
  const AtemPlateStack({
    super.key,
    required this.plates,
    this.heaviestKg = 25,
    this.dimmed = false,
  });

  /// Die Scheiben **einer** Seite, einzeln, schwerste zuerst — innen am
  /// Anschlag.
  final List<double> plates;

  /// Die schwerste Scheibe im Satz; sie bekommt die volle Höhe.
  final double heaviestKg;

  /// Nur die Stange, abgeblendet — das Ziel ist leichter als die Stange.
  final bool dimmed;

  /// Höhe der Scheibenfläche ohne Beschriftung.
  static const plateAreaHeight = 92.0;

  static const _labelGap = 6.0;
  static const _plateGap = 3.0;

  /// Luft um jede Zahl — ohne sie lasen sich „10" und „1,25" als „101,25".
  static const _labelPad = 8.0;

  /// Gesamthöhe bei gegebener Schrift — für Aufrufer, die Platz reservieren.
  static double height(BuildContext context) =>
      plateAreaHeight + _labelGap + _labelHeight(context);

  static TextStyle _labelStyle(BuildContext context) =>
      AtemType.labelMicro.base.copyWith(letterSpacing: 0, height: 1.2);

  /// Gemessen, nicht aus Grösse × Zeilenhöhe gerechnet — die echten Schriften
  /// tragen ihre eigenen Ober- und Unterlängen.
  static double _labelHeight(BuildContext context) => (TextPainter(
        text: TextSpan(text: '0', style: _labelStyle(context)),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout())
          .height;

  /// Kilogramm mit bis zu zwei Nachkommastellen — `1,25` bleibt `1,25`.
  /// `AtemNumberField.format` rundet auf eine Stelle und machte daraus `1,3`.
  static String formatKg(BuildContext context, double kg) {
    var text = kg.toStringAsFixed(2);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    }
    final comma = Localizations.localeOf(context).languageCode != 'en';
    return comma ? text.replaceAll('.', ',') : text;
  }

  /// Höhe und Dicke wachsen mit der Wurzel des Gewichts: Linear wäre die
  /// 1,25er ein Strich neben einer 25er, und zwei kleine Scheiben sähen aus
  /// wie ein Rest.
  double _fraction(double kg) => math.sqrt((kg / heaviestKg).clamp(0.0, 1.0));

  double _plateHeight(double kg) => 42 + (plateAreaHeight - 42) * _fraction(kg);
  double _plateWidth(double kg) => 9 + 15 * _fraction(kg);

  // Stangenstück innen, Anschlag, Abstand — und das freie Ende.
  static const _innerStub = 14.0;
  static const _collarWidth = 8.0;
  static const _collarGap = 4.0;
  static const _minOuterStub = 16.0;

  @override
  Widget build(BuildContext context) {
    final labelStyle = _labelStyle(context);
    final scaler = MediaQuery.textScalerOf(context);
    final labels = [for (final p in plates) formatKg(context, p)];
    final labelWidths = [
      for (final l in labels)
        (TextPainter(
          text: TextSpan(text: l, style: labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout())
            .width,
    ];
    final barColor =
        dimmed ? AtemColors.textDisabled : AtemColors.textSecondary;
    final totalHeight = height(context);

    return ExcludeSemantics(
      child: SizedBox(
        height: totalHeight,
        child: LayoutBuilder(builder: (context, constraints) {
          final available = constraints.maxWidth;
          const fixed = _innerStub + _collarWidth + _collarGap + _minOuterStub;
          final gaps = plates.isEmpty ? 0.0 : (plates.length - 1) * _plateGap;

          double widthWith({required bool labelled, double squeeze = 1}) {
            var sum = fixed + gaps;
            for (var i = 0; i < plates.length; i++) {
              final plate = _plateWidth(plates[i]) * squeeze;
              sum += labelled
                  ? math.max(plate, labelWidths[i] + _labelPad)
                  : plate;
            }
            return sum;
          }

          // Erst die Zahlen opfern, dann die Dicke — nie die Schrift.
          final labelled = widthWith(labelled: true) <= available;
          var squeeze = 1.0;
          if (!labelled) {
            final natural = widthWith(labelled: false);
            if (natural > available) {
              final plateSum = natural - fixed - gaps;
              squeeze = ((available - fixed - gaps) / plateSum).clamp(0.3, 1.0);
            }
          }

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Die Stange läuft über die ganze Breite, hinter den Scheiben.
              Positioned(
                left: 0,
                right: 0,
                top: plateAreaHeight / 2 - 1.5,
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: _innerStub),
                  SizedBox(
                    height: plateAreaHeight,
                    child: Center(
                      child: Container(
                        width: _collarWidth,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AtemColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: barColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: _collarGap),
                  for (var i = 0; i < plates.length; i++) ...[
                    if (i > 0) const SizedBox(width: _plateGap),
                    _plate(
                      plates[i],
                      squeeze: squeeze,
                      label: labelled ? labels[i] : null,
                      labelWidth: labelWidths[i],
                      labelStyle: labelStyle,
                    ),
                  ],
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _plate(
    double kg, {
    required double squeeze,
    required String? label,
    required double labelWidth,
    required TextStyle labelStyle,
  }) {
    final width = _plateWidth(kg) * squeeze;
    return SizedBox(
      width: label == null ? width : math.max(width, labelWidth + _labelPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: plateAreaHeight,
            child: Center(
              child: Container(
                width: width,
                height: _plateHeight(kg),
                decoration: BoxDecoration(
                  color: AtemColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AtemColors.textSecondary),
                ),
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: _labelGap),
            Text(label, maxLines: 1, softWrap: false, style: labelStyle),
          ],
        ],
      ),
    );
  }
}
