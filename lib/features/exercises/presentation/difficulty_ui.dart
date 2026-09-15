import 'package:flutter/widgets.dart';

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

/// Die Stufenauswahl — [AtemScaleChoice] mit den Wörtern aus Modul 7.
///
/// Layout, Umbruchverhalten und Semantics-Aufbau leben im Baustein; hier steht
/// nur, was die Schwierigkeit von den anderen drei Skalen unterscheidet: Sie
/// ist **Pflicht**, deshalb `allowDeselect: false`, und sie kennt einen
/// Fehlerzustand.
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
/// Deshalb steht das Wort auf 12 sp (`AtemType.labelUi` im Baustein). Das
/// Feld wird dadurch höher, was der Ausweichscroller ohnehin abfängt.
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

  /// Nimmt nur echte Stufen entgegen: Die Schwierigkeit ist eine **Pflicht**-
  /// angabe des Formulars, deshalb hebt erneutes Antippen sie nicht auf.
  final ValueChanged<int> onChanged;

  /// Färbt die Ränder magenta. **Nie allein** — das Feldlabel färbt mit, und
  /// der Speichern-Knopf nennt den Grund.
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemScaleChoice(
      value: value,
      onChanged: (level) {
        if (level != null) onChanged(level);
      },
      groupLabel: l10n.exerciseFieldLevel,
      min: Difficulty.min,
      max: Difficulty.max,
      // Pflichtangabe: einmal gewählt, bleibt gewählt.
      allowDeselect: false,
      hasError: hasError,
      wordFor: (level) => difficultyShort(l10n, level),
      // „Stufe 4, Fortgeschritten, 4 von 5" — Zahl und Wort zusammen, sonst
      // ist die eine bedeutungslos und das andere nicht auffindbar.
      semanticLabelFor: (level) =>
          '${l10n.exerciseFieldLevel} $level, ${difficultyLabel(l10n, level)}, '
          '$level ${l10n.commonOf} ${Difficulty.max}',
    );
  }
}
