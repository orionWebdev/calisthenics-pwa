import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/muscle.dart';

/// Die Schwierigkeitsstufe in Worten — die Skala aus Modul 7.
///
/// ## Die Namen kommen vom Board, die Zahlen aus dem Bestand
///
/// Gespeichert wird 1–5. Welches Wort daneben steht, setzt das Board:
/// Einstieg · Leicht · Mittel · Fortgeschritten · Experte.
///
/// Die Wörter des Altbestands bilden über [Difficulty.parse] auf Zahlen ab —
/// `beginner` auf 1, belegt an zwei Stellen der Vorgänger-App
/// (`js/views/sessionTemplates.js:68`, `js/views/exercises/form.js:153`, beide
/// `value: 1`). Das Entscheidungsprotokoll des Boards nennt in einer
/// Klammerbemerkung Stufe 2; das ist ein Versehen, die Quelle ist eindeutig.
///
/// **Eine Verschiebung bleibt trotzdem sichtbar:** Eine Übung mit `advanced`
/// hiess in der Vorgänger-App „Fortgeschritten" und heisst hier „Mittel". Das
/// ist gewollt — die Skala wurde neu benannt, nicht umgerechnet. Die Zahl im
/// Dokument ändert sich dabei nicht.
String difficultyLabel(AppL10n l, int level) => switch (level) {
      1 => l.exerciseLevel1,
      2 => l.exerciseLevel2,
      3 => l.exerciseLevel3,
      4 => l.exerciseLevel4,
      _ => l.exerciseLevel5,
    };

/// Die Kurzform für die Auswahlreihe — „FORTG." statt „Fortgeschritten".
///
/// Fünf Felder müssen nebeneinander auf 320 dp passen; das längste volle Wort
/// machte die Reihe dreimal so breit wie der Bildschirm. Vorgelesen wird
/// weiterhin das ganze Wort: [difficultyLabel] steht im Semantics-Label.
String difficultyShort(AppL10n l, int level) => switch (level) {
      1 => l.exerciseLevel1Short,
      2 => l.exerciseLevel2Short,
      3 => l.exerciseLevel3Short,
      4 => l.exerciseLevel4Short,
      _ => l.exerciseLevel5Short,
    };

/// Die Stufenauswahl: **Zahl oben, Wort darunter**.
///
/// ## Warum nicht die Segmentauswahl aus Modul 2
///
/// Die trägt ein Wort je Feld. Hier stehen zwei Zeilen übereinander, weil
/// beides gebraucht wird: Die Zahl ist das, was gespeichert wird und was auf
/// der Skala verortet; das Wort ist das, wonach jemand greift. Die Zahl allein
/// wäre bedeutungslos, das Wort allein nicht auffindbar.
///
/// ## Eine bewusste Abweichung von der Spezifikationstabelle
///
/// Das Board nennt für das Wort **7,5 sp**. Das widerspricht der Regel, die
/// dasselbe Dokument als nicht verhandelbar führt: informationstragender Text
/// ≥ 12 sp effektiv.
///
/// Und das Wort trägt hier die Aussage. Wer eine Stufe wählt, liest
/// „Fortgeschritten" — die Zahl ist das, was gespeichert wird, nicht das,
/// wonach man greift. Die Ausnahme des Vertrags („Beschriftung neben einem
/// grösseren Wert") greift also gerade nicht.
///
/// Deshalb steht das Wort auf 12 sp. Das Feld wird dadurch höher, was der
/// Umbruch unten ohnehin abfängt.
///
/// ## Waagerecht scrollbar statt umbrechend
///
/// Das Board schreibt fünf Felder nebeneinander vor, bei 200 % Schrift
/// umbrechend auf zwei Reihen à 3 und 2. In der Erprobung war der Einwand:
/// Es wird genau **eines** gewählt, und eine einzeilige Reihe, die man
/// schiebt, liest sich als eine Skala — zwei Reihen als zwei Gruppen.
///
/// Das trifft zu. Eine Skala ist eine Ordnung, und ein Umbruch in der Mitte
/// zerschneidet sie: „Mittel" stünde rechts aussen, „Fortgeschritten" links
/// unten, obwohl sie benachbart sind.
///
/// Die Felder behalten deshalb ihre Breite und die Reihe scrollt. Was nicht
/// mehr passt, ist angeschnitten sichtbar — das ist die übliche Andeutung,
/// dass es weitergeht, und sie stimmt hier auch inhaltlich.
class DifficultyChoice extends StatelessWidget {
  const DifficultyChoice({
    super.key,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  /// `null` heisst: noch nichts gewählt. Es gibt keine Vorbelegung —
  /// Entscheidung 05 des Boards: „Drei bewusste Angaben sind ehrlicher als
  /// zwei plus eine Lüge."
  final int? value;

  final ValueChanged<int> onChanged;

  /// Färbt die Ränder magenta. **Nie allein** — das Feldlabel färbt mit, und
  /// der Speichern-Knopf nennt den Grund.
  final bool hasError;

  static const _height = 48.0;
  static const _gap = 6.0;

  /// Auch das kürzeste Wort bekommt eine Fläche, die man trifft.
  static const _minWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    // Eine waagerechte Liste braucht eine feste Höhe; sie folgt der
    // Schriftskalierung, damit bei 200 % nichts abgeschnitten wird.
    final height = math.max(_height, scaler.scale(30) + 30);

    // Die Breite folgt der längsten Kurzform, nie dem vollen Wort.
    final needed = math.max(_minWidth, _widest(context, l10n, scaler) + 16);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fair =
              (constraints.maxWidth - _gap * (Difficulty.max - 1)) /
                  Difficulty.max;

          // **Fünf gleiche Felder über die volle Breite** (Board 07, A2/1) —
          // die Reihe stand vorher weit auseinandergezogen im Scroller, weil
          // ihre Breite dem Wort „Fortgeschritten" folgte. Nur wenn die
          // Kurzform bei 200 % Schrift nicht mehr in ihr Fünftel passt,
          // bleibt der waagerechte Scroller als Ausweg.
          if (fair >= needed) {
            return Row(
              children: [
                for (var i = 0; i < Difficulty.max; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(child: _field(l10n, Difficulty.min + i)),
                ],
              ],
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: Difficulty.max,
            separatorBuilder: (_, __) => const SizedBox(width: _gap),
            itemBuilder: (context, i) => SizedBox(
              width: needed,
              child: _field(l10n, Difficulty.min + i),
            ),
          );
        },
      ),
    );
  }

  Widget _field(AppL10n l10n, int level) => _Field(
        level: level,
        label: difficultyShort(l10n, level),
        semanticLabel: difficultyLabel(l10n, level),
        selected: level == value,
        hasError: hasError,
        onTap: () => onChanged(level),
      );

  static double _widest(
    BuildContext context,
    AppL10n l10n,
    TextScaler scaler,
  ) {
    var widest = 0.0;
    for (var level = Difficulty.min; level <= Difficulty.max; level++) {
      final painter = TextPainter(
        text: TextSpan(
          text: difficultyShort(l10n, level),
          style: AtemType.labelMicro.base,
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
    }
    return widest;
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.level,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.hasError,
    required this.onTap,
  });

  final int level;
  final String label;

  /// Das volle Wort — es wird vorgelesen, während die Fläche kürzt.
  final String semanticLabel;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final border = selected
        ? AtemColors.cyan
        : (hasError ? AtemColors.magenta : AtemColors.border);

    return AtemTappable(
      onTap: onTap,
      // „Stufe 4, Fortgeschritten, 4 von 5" — Zahl und Wort zusammen, sonst
      // ist die eine bedeutungslos und das andere nicht auffindbar.
      semanticLabel:
          '${l10n.exerciseFieldLevel} $level, $semanticLabel, '
          '$level ${l10n.commonOf} ${Difficulty.max}',
      selected: selected,
      inMutuallyExclusiveGroup: true,
      minTapSize: const Size(0, DifficultyChoice._height),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: DifficultyChoice._height,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AtemCategories.surface(AtemColors.cyan)
              : AtemColors.card,
          borderRadius: BorderRadius.circular(AtemRadii.statBox),
          border: Border.all(
            color: border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$level',
              style: AtemType.valueMedium.of(context).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AtemColors.cyan : AtemColors.textPrimary,
                  ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AtemType.labelMicro.of(context).copyWith(
                    letterSpacing: 0,
                    color: selected
                        ? AtemColors.cyan
                        : AtemColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
