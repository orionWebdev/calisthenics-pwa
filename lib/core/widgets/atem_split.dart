import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// **Zwei Karten nebeneinander** — das Split-Card-Modul (21.09.2026).
///
/// ## Wofür
///
/// Zwei Blöcke, die zusammengehören und einzeln zu schmal wären, teilen sich
/// eine Zeile: Muskelbalance neben der Einheitenzahl, später anderes. Der
/// Bildschirm wird kürzer, ohne dass ein Block etwas verliert.
///
/// ## Oben bündig, nicht gleich hoch
///
/// Naheliegend wäre, beide Karten auf dieselbe Höhe zu ziehen. Das verlangt
/// `IntrinsicHeight` — und das verträgt sich nicht mit `LayoutBuilder`, den
/// jeder Blockkopf benutzt, um zu entscheiden, ob Titel und Zeitraum in eine
/// Zeile passen („LayoutBuilder does not support returning intrinsic
/// dimensions"). Eine Karte dafür umzubauen hiesse, das Modul auf Karten
/// ohne messenden Kopf zu beschränken; das wäre eine Falle für den nächsten
/// Aufrufer.
///
/// Stattdessen stehen beide oben bündig und sind so hoch wie ihr Inhalt. Wer
/// sie gleich hoch haben will, gibt beiden denselben Aufbau — gleicher Kopf,
/// gleiche Zahl, gleiche Grundlage.
///
/// ## Ab 130 % Schrift untereinander
///
/// Auf 320 dp bleiben je Karte rund 145 dp. Was dort in zwei Zeilen passt,
/// braucht bei anderthalbfacher Schrift fünf — und bei 200 % steht in jeder
/// Karte ein Wort je Zeile. Die Grenze liegt deshalb früh: **ab 130 %** stehen
/// die Karten untereinander, in derselben Reihenfolge. Kein Verkleinern, kein
/// Ellipsieren, kein horizontales Scrollen.
///
/// ## Was es nicht tut
///
/// Es nimmt keine Karte auseinander und baut keine dritte Spalte. Drei Karten
/// nebeneinander wären auf einem Telefon je 95 dp breit — dafür gibt es kein
/// Rezept, und es soll keins geben.
class AtemSplit extends StatelessWidget {
  const AtemSplit({
    super.key,
    this.left,
    this.right,
    this.gap = AtemSpacing.gridGap,
  });

  /// **`null` heisst: dieser Block hat keine Daten.**
  ///
  /// Dann nimmt der andere die volle Breite — eine halb leere Zeile wäre
  /// schlimmer als eine ganze Karte. Ausserhalb der Auswertung gilt weiter:
  /// Ein Block ohne Daten rendert nicht, und die Seite hört früher auf. Das
  /// Modul kann das nicht selbst sehen; es baut nur, was es bekommt.
  final Widget? left;
  final Widget? right;

  /// Abstand zwischen den beiden — waagerecht wie senkrecht.
  final double gap;

  /// Ab dieser Schriftskalierung stehen die Karten untereinander.
  static const stackFrom = 1.3;

  static bool stacksAt(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(10) / 10 >= stackFrom;

  @override
  Widget build(BuildContext context) {
    final a = left;
    final b = right;
    if (a == null && b == null) return const SizedBox.shrink();
    if (a == null) return b!;
    if (b == null) return a;

    if (stacksAt(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [a, SizedBox(height: gap), b],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        SizedBox(width: gap),
        Expanded(child: b),
      ],
    );
  }
}
