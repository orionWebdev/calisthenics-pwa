import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'atem_answer.dart' show AtemSelectBloom;
import 'atem_tappable.dart';

/// Eine Auswahl auf einer kleinen ganzzahligen Skala: **fünf gleich breite
/// Zahlenfelder, das Wort einmal darunter**.
///
/// ## Warum dieser Baustein existiert
///
/// Die App fragt an vier Stellen dasselbe: Schwierigkeit einer Übung,
/// Anstrengung einer Einheit, Bereitschaft davor, Gefühl danach. Alle vier
/// sind eine Skala von 1 bis 5 ohne Vorbelegung, und alle vier haben dieselben
/// zwei schwierigen Stellen — fünf Felder, die bei 200 % Schrift auf 320 dp
/// nebeneinander bleiben müssen, und ein Semantics-Label, das Zahl **und**
/// Wort tragen muss.
///
/// ## Die Zahl im Feld, das Wort darunter — nicht beides im Feld
///
/// Bis 16.09.2026 stand das Wort mit in jedem Feld. Das sah unsauber aus:
/// „erschöpft" ist doppelt so breit wie „okay", die Felder wurden ungleich
/// breit, die Lücken dazwischen ungleich gross, und bei grosser Schrift wich
/// die Reihe in einen waagerechten Scroller aus. Auf 320 dp bei 200 % bleibt
/// einem Fünftel keine 50 dp — kein Wort passt da hinein, nicht einmal mit
/// Ellipsis, die aus „erschöpft" ein „e…" macht.
///
/// Deshalb tragen die Felder nur die Zahl und teilen sich die Breite zu
/// gleichen Teilen. Das Wort steht **einmal** unter der Reihe: das der
/// gewählten Stufe, oder — solange nichts gewählt ist — die beiden Enden der
/// Skala („erschöpft … frisch"), damit die Richtung lesbar bleibt. Der
/// Screenreader bekommt je Feld weiter das volle Label aus [semanticLabelFor].
///
/// ## Farbe je Stufe
///
/// Mit [colorFor] trägt jede Stufe eine eigene Farbe: ungewählt als Rand und
/// Zahl, gewählt als **gefüllte Fläche**. Ohne [colorFor] gilt die neutrale
/// Fassung: Rand in `border`, gewählt in Cyan — so bleiben Schwierigkeit und
/// RPE, wie sie waren. Farbe ist nie der einzige Träger: Zahl und Wort bleiben.
class AtemScaleChoice extends StatelessWidget {
  const AtemScaleChoice({
    super.key,
    required this.value,
    required this.onChanged,
    required this.groupLabel,
    required this.wordFor,
    required this.semanticLabelFor,
    this.labelFor,
    this.colorFor,
    this.min = 1,
    this.max = 5,
    this.allowDeselect = true,
    this.hasError = false,
    this.surface = AtemColors.card,
    this.visibleHeight = 52,
  });

  /// `null` heisst: nichts gewählt. **Es gibt keine Vorbelegung** — eine
  /// vorbelegte Selbstauskunft wäre eine Angabe, die niemand gemacht hat.
  final int? value;

  /// Bekommt `null`, wenn ein gewähltes Feld erneut angetippt wird und
  /// [allowDeselect] gilt.
  final ValueChanged<int?> onChanged;

  /// Label der Gruppe für den Screenreader — „RPE", „Bereitschaft".
  final String groupLabel;

  /// Das Wort zur Stufe — steht unter der Reihe, nicht im Feld.
  final String Function(int level) wordFor;

  /// Das vollständige Label, das je Feld vorgelesen wird.
  final String Function(int level) semanticLabelFor;

  /// Die **Zahl im Feld**, wenn sie eine andere ist als die Stufe selbst.
  ///
  /// Gebraucht für RIR: Gespeichert wird RPE 6–10, im Feld steht 4–0. Ohne
  /// diesen Umweg müsste die Skala die Stufen rückwärts führen, und jede
  /// Stelle, die einen Wert liest, müsste die Umrechnung kennen.
  final String Function(int level)? labelFor;

  /// Die Farbe einer Stufe. `null` heisst neutral (Rand in `border`, gewählt
  /// in Cyan).
  final Color Function(int level)? colorFor;

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

  static const _gap = 8.0;
  static const _tapHeight = 48.0;

  int get _count => max - min + 1;

  @override
  Widget build(BuildContext context) {
    final selected = value;
    final selectedColor =
        selected == null ? null : (colorFor?.call(selected) ?? AtemColors.cyan);

    return Semantics(
      container: true,
      label: groupLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < _count; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                Expanded(child: _field(min + i)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Das Wort ist im Feld-Label schon enthalten; hier nur zum Sehen.
          ExcludeSemantics(
            child: Text(
              selected == null
                  ? '${wordFor(min)} … ${wordFor(max)}'
                  : wordFor(selected),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtemType.meta.of(context).copyWith(
                    color: selectedColor ?? AtemColors.textTertiary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(int level) {
    final selected = level == value;
    return _ScaleField(
      label: labelFor?.call(level) ?? '$level',
      semanticLabel: semanticLabelFor(level),
      selected: selected,
      color: colorFor?.call(level),
      hasError: hasError,
      surface: surface,
      visibleHeight: visibleHeight,
      onTap: () => onChanged(selected && allowDeselect ? null : level),
    );
  }
}

class _ScaleField extends StatelessWidget {
  const _ScaleField({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.color,
    required this.hasError,
    required this.surface,
    required this.visibleHeight,
    required this.onTap,
  });

  /// Was im Feld steht — meist die Stufe, bei RIR die Gegenzahl.
  final String label;

  /// Das vollständige Label — Zahl und Wort — für den Screenreader.
  final String semanticLabel;
  final bool selected;

  /// Die Stufenfarbe; `null` ist die neutrale Fassung.
  final Color? color;
  final bool hasError;
  final Color surface;
  final double visibleHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = color;
    final neutral = tone == null;

    // Neutral: wie bisher — Rand in `border`, gewählt Cyan-Tönung mit
    // Cyan-Rand. Farbig: ungewählt Rand und Zahl in der Farbe, gewählt die
    // Fläche voll gefüllt und die Zahl in `onNeon`. Alle fünf Stufenfarben
    // halten auf `onNeon` mindestens 5,0:1 (test/core/widgets/atem_scale_choice_test).
    final borderColor = hasError && !selected
        ? AtemColors.magenta
        : neutral
            ? (selected ? AtemColors.cyan : AtemColors.border)
            : tone.withValues(alpha: selected ? 1 : 0.6);
    final fill = neutral
        ? (selected ? AtemCategories.surface(AtemColors.cyan) : surface)
        : (selected ? tone : surface);
    final numberColor = neutral
        ? (selected ? AtemColors.cyan : AtemColors.textPrimary)
        : (selected ? AtemColors.onNeon : tone);
    final glowColor = neutral ? AtemColors.cyan : tone;

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      haptic: AtemHaptic.selection,
      minTapSize: const Size(0, AtemScaleChoice._tapHeight),
      // Gedrückt heisst leuchten: scale 0,97 aus AtemTappable, der Glow in
      // der Stufenfarbe hier — 200 ms, kein Ripple.
      //
      // Bloom beim Wählen (Board 18b, C3) — und **keine Füllung der Felder
      // links davon**: Eine Skala ist eine Antwort, kein Fortschritt, und 3
      // ist kein „noch 2 bis 5".
      pressBuilder: (context, pressed) => SizedBox(
        width: double.infinity,
        child: AtemSelectBloom(
          active: selected,
          radius: AtemRadii.statBox,
          child: AnimatedContainer(
          duration: AtemMotion.duration(context, AtemMotion.fast),
          curve: AtemMotion.curve,
          constraints: BoxConstraints(minHeight: visibleHeight),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AtemRadii.statBox),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            boxShadow: pressed ? AtemGlow.soft(glowColor, opacity: 0.55) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: AtemType.valueMedium.of(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: numberColor,
                    ),
              ),
              const SizedBox(height: 3),
              // Der Kern unter der Ziffer: der Träger von „gewählt", der
              // ohne Farbe funktioniert. Er poppt mit Überschwinger.
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: AtemMotion.duration(
                    context, selected ? AtemMotion.dKern : AtemMotion.dOff),
                curve: selected ? AtemMotion.pop : AtemMotion.exit,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: numberColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}
