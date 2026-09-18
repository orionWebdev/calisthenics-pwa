import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/domain/training_session.dart' show LoggedSet;

// Anstrengung je Satz im Runner — kein Board, aus Tokens gebaut (18.09.2026).
//
// Zwei Teile: der **Streifen**, der nach dem Abhaken unter der Zeile steht und
// fragt, und die **Kapsel** in der Zeile, die die Antwort zeigt. Beide sind
// freiwillig und ohne Vorbelegung; die Angabe wandert nie in den nächsten
// Satz.

/// Das Wort zu einer Stufe — als Wiederholungen in Reserve, nicht als Urteil.
///
/// RPE 10 heisst „nichts mehr drin", 9 „noch eine", und so abwärts bis 6. Das
/// ist die übliche Lesart der Skala für Krafttraining; sie sagt, was die Zahl
/// **bedeutet**, nicht, ob sie gut ist.
String rpeWord(AppL10n l10n, int level) => switch (level) {
      >= 10 => l10n.workoutRpeWordMax,
      >= 6 => l10n.workoutRpeWordReserve(10 - level),
      5 => l10n.workoutRpeWordReserveMany,
      _ => l10n.workoutRpeWordEasy,
    };

/// Dasselbe ausgeschrieben, für den Screenreader — „Wdh." liest keiner gern.
///
/// Die sichtbaren Wörter sind dafür knapp: Unter der Reihe steht „noch 4 Wdh.
/// … Max" in **einer** Zeile, und die muss bei 200 % auf 320 dp passen.
String rpeWordA11y(AppL10n l10n, int level) => switch (level) {
      >= 10 => l10n.workoutRpeMaxA11y,
      >= 6 => l10n.workoutRpeReserveA11y(10 - level),
      5 => l10n.workoutRpeReserveManyA11y,
      _ => l10n.workoutRpeWordEasy,
    };

bool isHardRpe(int? rpe) => rpe != null && rpe >= LoggedSet.hardSetRpe;

/// Der Streifen „Wie schwer war Satz N?".
///
/// ## Zwei Reihen, die obere eingeklappt
///
/// Wer eine Anstrengung angibt, gibt fast immer 6 bis 10 an — ein Satz auf
/// RPE 3 ist ein Aufwärmsatz, und der hat einen eigenen Typ. Die zehn Stufen
/// nebeneinander hätten auf 320 dp je 19 dp: keine Trefferfläche. Also stehen
/// 6–10 als [AtemScaleChoice] da, und „1–5 zeigen" klappt eine zweite Reihe
/// darüber auf. Ist schon eine Stufe unter 6 gewählt, ist sie offen.
///
/// Eine waagerechte Reihe mit allen zehn zum Wischen war die Alternative;
/// sie verbirgt die Hälfte der Skala hinter dem Rand, und wer nicht wischt,
/// sieht nicht, dass es 10 gibt.
///
/// ## Eine Wahl schliesst
///
/// Der Runner schliesst den Streifen nach jeder Wahl, nach „keine Angabe"
/// und wenn der nächste Satz abgehakt wird. Er hält dafür den Zustand; der
/// Streifen selbst merkt sich nur, ob 1–5 offen sind.
class RpeStrip extends StatefulWidget {
  const RpeStrip({
    super.key,
    required this.setNumber,
    required this.value,
    required this.onChanged,
  });

  /// Satznummer ab 1 — für Frage und Labels.
  final int setNumber;

  /// Die bisherige Angabe; `null` heisst keine.
  final int? value;

  /// `null` heisst „keine Angabe".
  final ValueChanged<int?> onChanged;

  @override
  State<RpeStrip> createState() => _RpeStripState();
}

class _RpeStripState extends State<RpeStrip> {
  late bool _showLow = widget.value != null && widget.value! < _highFrom;

  static const _highFrom = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final value = widget.value;

    Widget row(int min, int max) => AtemScaleChoice(
          value: value != null && value >= min && value <= max ? value : null,
          onChanged: widget.onChanged,
          groupLabel: l10n.workoutRpeRangeA11y(min, max),
          wordFor: (level) => rpeWord(l10n, level),
          semanticLabelFor: (level) =>
              l10n.workoutRpeLevelA11y(level, rpeWordA11y(l10n, level)),
          min: min,
          max: max,
          surface: AtemColors.surfaceSolid,
          visibleHeight: 44,
          // Die Stufen ab 7 zählen als harter Satz — sie tragen den Ton der
          // Kraft, die darunter bleiben neutral. Zahl und Wort stehen immer
          // dabei; die Farbe sagt nur „ab hier zählt es".
          colorFor: (level) => isHardRpe(level)
              ? AtemColors.tabStrength
              : AtemColors.textSecondary,
        );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.workoutRpeGroupA11y(widget.setNumber),
      child: Container(
        margin: const EdgeInsets.only(bottom: AtemSpacing.sm),
        // **Seitlich nur 5 dp.** Die fünf Felder teilen sich die Breite mit
        // vier festen 8-dp-Lücken; bei 320 dp bleiben nach Bildschirmrand,
        // Rahmen und 12 dp Polster je Feld 46 dp — unter der Trefferfläche.
        // Mit 5 dp sind es 48,8. Die Frage darüber rückt selbst ein.
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 4),
        decoration: BoxDecoration(
          color: AtemColors.card.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AtemColors.tabStrength.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Text(
                  l10n.workoutRpeQuestion(widget.setNumber),
                  style: AtemType.labelUi
                      .of(context)
                      .copyWith(color: AtemColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_showLow) ...[
              row(1, 5),
              const SizedBox(height: 10),
            ],
            row(_highFrom, 10),
            // Umbrechen statt kürzen: Bei 200 % auf 320 dp stehen die beiden
            // Knöpfe untereinander.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AtemSpacing.sm,
              children: [
                _TextAction(
                  label: _showLow
                      ? l10n.workoutRpeHideLow
                      : l10n.workoutRpeShowLow,
                  semanticLabel: _showLow
                      ? l10n.workoutRpeHideLowA11y
                      : l10n.workoutRpeShowLowA11y,
                  onTap: () => setState(() => _showLow = !_showLow),
                ),
                _TextAction(
                  label: l10n.workoutRpeNone,
                  semanticLabel: l10n.workoutRpeNoneA11y(widget.setNumber),
                  onTap: () => widget.onChanged(null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ein Knopf, der nur Text ist — 48 dp hoch, ohne Rahmen.
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        minTapSize: const Size(48, 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: AtemType.labelUi
                .of(context)
                .copyWith(color: AtemColors.textSecondary),
          ),
        ),
      );
}

/// Die Kapsel „RPE 8" in der Satzzeile.
///
/// Mono in `textSecondary` — eine Angabe, keine Hervorhebung. Ab RPE 7 steht
/// ein Punkt im Kraft-Ton davor **und das Wort „harter Satz" dahinter**: Der
/// Punkt allein wäre Farbe als einziger Träger.
///
/// Tippen öffnet den Streifen erneut; [open] zeigt, dass er gerade offen ist.
class RpeBadge extends StatelessWidget {
  const RpeBadge({
    super.key,
    required this.rpe,
    required this.setNumber,
    required this.open,
    required this.onTap,
  });

  final int rpe;
  final int setNumber;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final hard = isHardRpe(rpe);
    // Ohne Sperrung: `labelMicro` ist für Überschriften gesperrt, und „RPE 8"
    // zerfiel damit in zwei Wörter mit einem Loch dazwischen.
    final text = AtemType.labelMicro
        .of(context)
        .copyWith(color: AtemColors.textSecondary, letterSpacing: 0);

    return AtemTappable(
      onTap: onTap,
      semanticLabel: hard
          ? l10n.workoutRpeBadgeHardA11y(setNumber, rpe)
          : l10n.workoutRpeBadgeA11y(setNumber, rpe),
      selected: open,
      minTapSize: const Size(48, 48),
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: AtemMotion.duration(context, AtemMotion.fast),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: open
              ? AtemColors.tabStrength.withValues(alpha: 0.08)
              : const Color(0x00000000),
          borderRadius: AtemRadii.pillR,
          border: Border.all(
            color: open
                ? AtemColors.tabStrength.withValues(alpha: 0.4)
                : AtemColors.border,
          ),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 2,
          children: [
            if (hard)
              const ExcludeSemantics(
                child: AtemStatusDot(color: AtemColors.tabStrength),
              ),
            Text(l10n.workoutRpeBadge(rpe), style: text),
            if (hard)
              Text(
                l10n.workoutHardSet,
                style: AtemType.meta
                    .of(context)
                    .copyWith(color: AtemColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
