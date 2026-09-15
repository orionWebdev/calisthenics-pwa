import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'atem_tappable.dart';

/// Eine Auswahl auf einer kleinen ganzzahligen Skala: **Zahl oben, Wort
/// darunter**.
///
/// ## Warum dieser Baustein existiert
///
/// Die App fragt an vier Stellen dasselbe: Schwierigkeit einer Übung,
/// Anstrengung einer Einheit, Bereitschaft davor, Gefühl danach. Alle vier
/// sind eine Skala von 1 bis 5 ohne Vorbelegung, und alle vier haben dieselben
/// zwei schwierigen Stellen — fünf Felder, die bei 200 % Schrift auf 320 dp
/// nicht mehr nebeneinander passen, und ein Semantics-Label, das Zahl **und**
/// Wort tragen muss.
///
/// Das zweimal zu lösen war schon einmal zu viel; viermal wäre es sicher.
///
/// ## Zwei Zeilen, nicht eine
///
/// Die Zahl ist das, was gespeichert wird und was auf der Skala verortet; das
/// Wort ist das, wonach jemand greift. Die Zahl allein wäre bedeutungslos, das
/// Wort allein nicht auffindbar. Deshalb nicht die Segmentauswahl aus Modul 2,
/// die ein Wort je Feld trägt.
///
/// ## Waagerecht scrollbar statt umbrechend
///
/// Fünf gleiche Felder über die volle Breite, solange sie passen. Erst wenn
/// die Kurzform bei 200 % Schrift nicht mehr in ihr Fünftel passt, weicht die
/// Reihe in einen waagerechten Scroller aus — **nicht** in zwei Reihen.
///
/// Eine Skala ist eine Ordnung, und ein Umbruch in der Mitte zerschneidet sie:
/// „Mittel" stünde rechts aussen, „Fortgeschritten" links unten, obwohl sie
/// benachbart sind. Was nicht mehr passt, ist angeschnitten sichtbar — die
/// übliche Andeutung, dass es weitergeht, und sie stimmt hier auch inhaltlich.
///
/// ## Beschriftung
///
/// [wordFor] liefert die **Kurzform** für die Fläche, [semanticLabelFor] das
/// vollständige Label für den Screenreader. Beide kommen vom Aufrufer, weil
/// nur er weiss, ob gerade „Stufe 4, Fortgeschritten, 4 von 5" oder
/// „Bereitschaft 2, wenig, 2 von 5" vorgelesen werden soll. Der Baustein
/// selbst kennt keine Sprache.
class AtemScaleChoice extends StatelessWidget {
  const AtemScaleChoice({
    super.key,
    required this.value,
    required this.onChanged,
    required this.groupLabel,
    required this.wordFor,
    required this.semanticLabelFor,
    this.min = 1,
    this.max = 5,
    this.allowDeselect = true,
    this.hasError = false,
    this.surface = AtemColors.card,
    this.visibleHeight = 48,
  });

  /// `null` heisst: nichts gewählt. **Es gibt keine Vorbelegung** — eine
  /// vorbelegte Selbstauskunft wäre eine Angabe, die niemand gemacht hat.
  final int? value;

  /// Bekommt `null`, wenn ein gewähltes Feld erneut angetippt wird und
  /// [allowDeselect] gilt.
  final ValueChanged<int?> onChanged;

  /// Label der Gruppe für den Screenreader — „RPE", „Bereitschaft".
  final String groupLabel;

  /// Die Kurzform auf der Fläche.
  final String Function(int level) wordFor;

  /// Das vollständige Label, das vorgelesen wird.
  final String Function(int level) semanticLabelFor;

  final int min;
  final int max;

  /// Hebt erneutes Antippen die Wahl auf?
  ///
  /// Bei optionalen Angaben ja — ein Wert, den man nicht mehr loswird, wäre
  /// eine Vorbelegung durch die Hintertür. Bei Pflichtangaben nein.
  final bool allowDeselect;

  /// Färbt die Ränder magenta. **Nie allein** — das Feldlabel färbt mit, und
  /// der Speichern-Knopf nennt den Grund.
  final bool hasError;

  /// Die Fläche eines nicht gewählten Feldes. Auf einer Karte [AtemColors.card],
  /// auf blankem Grund [AtemColors.surfaceSolid].
  final Color surface;

  /// Sichtbare Höhe eines Feldes. Die **Trefferfläche** ist unabhängig davon
  /// immer mindestens 48 dp.
  final double visibleHeight;

  static const _gap = 6.0;
  static const _tapHeight = 48.0;

  /// Auch das kürzeste Wort bekommt eine Fläche, die man trifft.
  static const _minWidth = 48.0;

  int get _count => max - min + 1;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);

    // Eine waagerechte Liste braucht eine feste Höhe; sie folgt der
    // Schriftskalierung, damit bei 200 % nichts abgeschnitten wird.
    final height = math.max(visibleHeight, scaler.scale(30) + 30);

    // Die Breite folgt der längsten Kurzform, nie dem vollen Wort.
    final needed = math.max(_minWidth, _widest(scaler) + 16);

    return Semantics(
      container: true,
      label: groupLabel,
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fair = (constraints.maxWidth - _gap * (_count - 1)) / _count;

            if (fair >= needed) {
              return Row(
                children: [
                  for (var i = 0; i < _count; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    Expanded(child: _field(min + i)),
                  ],
                ],
              );
            }

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _count,
              separatorBuilder: (_, __) => const SizedBox(width: _gap),
              itemBuilder: (context, i) =>
                  SizedBox(width: needed, child: _field(min + i)),
            );
          },
        ),
      ),
    );
  }

  Widget _field(int level) {
    final selected = level == value;
    return _ScaleField(
      level: level,
      word: wordFor(level),
      semanticLabel: semanticLabelFor(level),
      selected: selected,
      hasError: hasError,
      surface: surface,
      visibleHeight: visibleHeight,
      onTap: () => onChanged(selected && allowDeselect ? null : level),
    );
  }

  double _widest(TextScaler scaler) {
    var widest = 0.0;
    for (var level = min; level <= max; level++) {
      final painter = TextPainter(
        text: TextSpan(text: wordFor(level), style: AtemType.labelMicro.base),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
    }
    return widest;
  }
}

class _ScaleField extends StatelessWidget {
  const _ScaleField({
    required this.level,
    required this.word,
    required this.semanticLabel,
    required this.selected,
    required this.hasError,
    required this.surface,
    required this.visibleHeight,
    required this.onTap,
  });

  final int level;
  final String word;

  /// Das vollständige Label — es wird vorgelesen, während die Fläche kürzt.
  final String semanticLabel;
  final bool selected;
  final bool hasError;
  final Color surface;
  final double visibleHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? AtemColors.cyan
        : (hasError ? AtemColors.magenta : AtemColors.border);

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      minTapSize: const Size(0, AtemScaleChoice._tapHeight),
      child: Container(
        constraints: BoxConstraints(minHeight: visibleHeight),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AtemCategories.surface(AtemColors.cyan) : surface,
          borderRadius: BorderRadius.circular(AtemRadii.statBox),
          border: Border.all(color: border, width: selected ? 1.5 : 1),
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
                    color: selected ? AtemColors.cyan : AtemColors.textPrimary,
                  ),
            ),
            Text(
              word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AtemType.labelMicro.of(context).copyWith(
                    letterSpacing: 0,
                    color:
                        selected ? AtemColors.cyan : AtemColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
