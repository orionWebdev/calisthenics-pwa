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
/// ## Zwei Schwellen, eine Regel
///
/// Board 17 legt den Umbruch fest: **Schriftskalierung über 1,45 oder eine
/// gemessene Hälfte unter 140 dp** — dann stehen die Karten untereinander, in
/// derselben Reihenfolge. Kein Verkleinern, kein Ellipsieren, kein
/// horizontales Scrollen.
///
/// Beide Bedingungen sind nötig, und zwar an *einem* Messpunkt. Die Schrift
/// allein reicht nicht: Auf 320 dp bleiben je Hälfte 138 dp, dort bricht
/// schon bei normaler Schrift ein Wort mitten durch. Die Breite allein
/// reicht auch nicht: Auf einem breiten Gerät sind die Hälften bei 200 %
/// Systemschrift zwar 180 dp breit, tragen aber nur noch ein Wort je Zeile.
/// Und weil beide Hälften dieselbe Messung benutzen, stapelt nie eine, ohne
/// dass die andere mitstapelt.
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

  /// Über dieser Schriftskalierung stehen die Karten untereinander.
  static const stackFrom = 1.45;

  /// Schmaler als das darf eine Hälfte nicht werden.
  static const minHalf = 140.0;

  /// Die Umbruchregel, ohne zu bauen — für Aufrufer, die ihren Inhalt je
  /// nach Lage anders zusammensetzen (etwa eine Kachel, die gestapelt ihr
  /// Symbol neben statt über den Text legt).
  ///
  /// [width] ist die **volle** verfügbare Breite, nicht die einer Hälfte.
  static bool stacksIn(BuildContext context, double width,
      {double gap = AtemSpacing.gridGap}) {
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    if (scale > stackFrom) return true;
    return (width - gap) / 2 < minHalf;
  }

  @override
  Widget build(BuildContext context) {
    final a = left;
    final b = right;
    if (a == null && b == null) return const SizedBox.shrink();
    if (a == null) return b!;
    if (b == null) return a;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ohne obere Schranke gibt es nichts zu messen — dann entscheidet
        // die Schrift allein. Das passiert nur in Tests und in Zeilen ohne
        // Breitenvorgabe; auf jedem Bildschirm ist die Breite bekannt.
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : double.infinity;
        final stacks = width.isFinite
            ? stacksIn(context, width, gap: gap)
            : MediaQuery.textScalerOf(context).scale(10) / 10 > stackFrom;

        if (stacks) {
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
      },
    );
  }
}
