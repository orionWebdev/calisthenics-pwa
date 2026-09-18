import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../workout_ui.dart';
import '../../domain/workout_session.dart';
import '../set_type_ui.dart';

/// Welcher Wert einer Satzzeile gerade am Regler hängt.
enum SetField { weight, reps, hold }

/// Eine Satzzeile im Runner.
///
/// ## Zwei Layouts, ein Schwellwert
///
/// Fünf Spalten (Typ, Historie, KG, WDH, Häkchen) sind bei 320 dp und großer
/// Systemschrift nicht zu halten. Ab Faktor 1,33 oder unter 360 dp Breite
/// bricht die Zeile in eine zweizeilige Karte um: oben Typ und Historie, unten
/// die Eingaben. Der Tabellenkopf entfällt dann, und die Spaltennamen wandern
/// als Einheit in die Felder.
///
/// ## Der Regler klappt **in der Zeile** auf
///
/// Ein Tap auf einen Wert öffnet [AtemStepInput] direkt unter der Zeile, nicht
/// in einem Blatt. Ein Blatt läuft seit dem 16.09.2026 über die volle Höhe —
/// es verdeckte damit die Satzliste, die Pausenleiste und die Vorgabe aus dem
/// Plan, also genau das, worauf man beim Eintragen schaut. Aufgeklappt bleibt
/// alles stehen, und der Daumen liegt neben der Zeile, die er ändert.
///
/// Die Tastatur bleibt der zweite Weg: Der Umschalter sitzt im Regler selbst.
/// Das Feld in der Zeile zeigt den Wert nur noch an — sonst öffneten Regler
/// und Tastatur beim selben Tap.
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.index,
    required this.weightController,
    required this.repsController,
    required this.onToggle,
    required this.onCycleType,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.editing,
    required this.onEdit,
    this.holdController,
    this.onHoldChanged,
  });

  final WorkoutSet set;

  /// Satznummer ab 1 — für die Semantics-Labels.
  final int index;

  final TextEditingController weightController;
  final TextEditingController repsController;
  final VoidCallback onToggle;
  final VoidCallback onCycleType;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onRepsChanged;

  /// Der Wert, dessen Regler gerade offen ist. `null` heisst: zugeklappt.
  final SetField? editing;

  /// Öffnet einen Regler oder schliesst ihn mit `null`.
  final ValueChanged<SetField?> onEdit;

  /// Nur bei Halteübungen gesetzt.
  ///
  /// Die Haltezeit stand bisher im Plan und nirgends sonst: Wer „45 s halten"
  /// eintrug, bekam im Training nur Gewicht und Wiederholungen zu sehen. Die
  /// Vorgabe war damit genau dort unsichtbar, wo sie gebraucht wird.
  final TextEditingController? holdController;
  final ValueChanged<String>? onHoldChanged;

  bool get isHold => holdController != null;

  /// Ab hier trägt die Zeile ihre fünf Spalten nicht mehr.
  static bool isCompact(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) > 16 ||
      MediaQuery.sizeOf(context).width < 360;

  /// Spaltenmasse — **eine Quelle für Zeile und Tabellenkopf**.
  ///
  /// Vorher standen sie doppelt und verschieden da: Der Kopf rechnete mit
  /// 48/72/60/48, die Zeile mit 34/72/60/48. Die Beschriftungen standen
  /// deshalb neben ihren Spalten, und für „letztes Mal" blieben 63 dp — zu
  /// wenig für „99 kg × 8" in einer Zeile.
  static const typeWidth = 32.0;
  static const weightWidth = 68.0;
  static const repsWidth = 56.0;
  static const doneWidth = 48.0;
  static const columnGap = 6.0;
  static const rowPadding = 10.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final compact = isCompact(context);

    return AnimatedContainer(
      duration: AtemMotion.duration(context, AtemMotion.normal),
      margin: const EdgeInsets.only(bottom: AtemSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: rowPadding, vertical: AtemSpacing.sm),
      // Die Zeile wächst auf mindestens 64 dp, damit der Typ-Chip seine
      // 48-dp-Trefferfläche aus dem Zeilenpolster nehmen kann.
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        color: set.done
            ? AtemColors.green.withValues(alpha: 0.07)
            : AtemColors.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: set.done
              ? AtemColors.green.withValues(alpha: 0.35)
              : AtemColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          compact ? _compactLayout(context, l10n) : _wideLayout(context, l10n),
          if (editing != null && !set.done) _stepPanel(context, l10n),
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context, AppL10n l10n) => Row(
        children: [
          _typeChip(context, l10n),
          const SizedBox(width: columnGap),
          Expanded(child: _history(context, l10n)),
          const SizedBox(width: columnGap),
          _weightField(context, l10n),
          const SizedBox(width: columnGap),
          // Bei einer Halteübung tritt die Sekundenspalte an die Stelle der
          // Wiederholungen — beides nebeneinander wäre eine Spalte zu viel,
          // und im Bestand tragen Sätze immer nur eins von beiden.
          if (isHold) _holdField(context, l10n) else _repsField(context, l10n),
          const SizedBox(width: columnGap),
          _doneButton(context, l10n),
        ],
      );

  Widget _compactLayout(BuildContext context, AppL10n l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _typeChip(context, l10n),
              const SizedBox(width: AtemSpacing.sm),
              Expanded(child: _history(context, l10n)),
            ],
          ),
          const SizedBox(height: AtemSpacing.sm),
          Row(
            children: [
              // Die Spaltennamen wandern als Einheit ins Feld.
              Expanded(
                flex: 6,
                child: _weightField(context, l10n,
                    suffix: l10n.workoutSetLoggerWeightUnit, width: null),
              ),
              const SizedBox(width: AtemSpacing.sm),
              Expanded(
                flex: 5,
                child: isHold
                    ? _holdField(context, l10n,
                        suffix: l10n.unitSuffixSeconds, width: null)
                    : _repsField(context, l10n, suffix: '×', width: null),
              ),
              const SizedBox(width: AtemSpacing.sm),
              _doneButton(context, l10n),
            ],
          ),
        ],
      );

  Widget _typeChip(BuildContext context, AppL10n l10n) {
    final tint = set.type.labelColor;
    final neutral = set.type == SetType.normal;

    return AtemTappable(
      // Gesperrt, sobald der Satz abgehakt ist — Fehlertoleranz kommt über
      // das Häkchen, nicht über den Typ.
      onTap: set.done ? null : onCycleType,
      semanticLabel: l10n.workoutA11ySetType(set.type.longLabel(l10n)),
      // Sichtbar bleiben 32x32, die Trefferfläche füllt 48x48 aus dem
      // Zeilenpolster.
      minTapSize: const Size.square(48),
      child: Container(
        width: typeWidth,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: set.done
              ? const Color(0x00000000)
              : (neutral
                  ? AtemColors.surfaceSolid
                  : set.type.color.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: set.done || neutral
                ? AtemColors.border
                : set.type.color.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          set.type.shortLabel(l10n),
          style: AtemType.labelUi.of(context).copyWith(
                fontWeight: FontWeight.w700,
                color: set.done ? AtemColors.textSecondary : tint,
              ),
        ),
      ),
    );
  }

  /// Was beim letzten Mal an dieser Stelle stand — **kurz**.
  ///
  /// „99 kg × 8" brauchte zwei Zeilen; die Spalte hat keine. Die lange
  /// Fassung steht weiter im Vorlese-Label, das Auge bekommt „99×8".
  Widget _history(BuildContext context, AppL10n l10n) => Semantics(
        label: previousSetLabel(context, l10n, set.previous),
        excludeSemantics: true,
        child: Text(
          previousSetShortLabel(context, l10n, set.previous),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AtemType.meta.of(context),
        ),
      );

  Widget _weightField(BuildContext context, AppL10n l10n,
          {String? suffix, double? width = weightWidth}) =>
      _valueCell(
        context,
        l10n,
        field: SetField.weight,
        controller: weightController,
        fieldName: l10n.workoutRunnerTableWeight,
        semanticLabel: l10n.workoutA11yWeightField(index),
        decimal: true,
        width: width,
        suffix: suffix,
      );

  Widget _holdField(BuildContext context, AppL10n l10n,
          {String? suffix, double? width = repsWidth}) =>
      _valueCell(
        context,
        l10n,
        field: SetField.hold,
        controller: holdController!,
        fieldName: l10n.workoutColHold,
        semanticLabel: l10n.workoutA11yHoldField(index),
        decimal: false,
        width: width,
        suffix: suffix,
      );

  Widget _repsField(BuildContext context, AppL10n l10n,
          {String? suffix, double? width = repsWidth}) =>
      _valueCell(
        context,
        l10n,
        field: SetField.reps,
        controller: repsController,
        fieldName: l10n.workoutRunnerTableReps,
        semanticLabel: l10n.workoutA11yRepsField(index),
        decimal: false,
        width: width,
        suffix: suffix,
      );

  /// Ein Wert in der Zeile: sichtbar wie ein Feld, beim Tippen öffnet er den
  /// Regler darunter.
  ///
  /// Das Feld bleibt ein echtes Textfeld — es zeigt den Wert und die Sperre
  /// nach dem Abhaken so, wie die Spezifikation es beschreibt. Nur die Zeiger
  /// kommen nicht mehr an es heran ([AbsorbPointer]); den Tap nimmt die
  /// Fläche darüber und klappt den Regler auf.
  Widget _valueCell(
    BuildContext context,
    AppL10n l10n, {
    required SetField field,
    required TextEditingController controller,
    required String fieldName,
    required String semanticLabel,
    required bool decimal,
    required double? width,
    String? suffix,
  }) {
    final open = editing == field;
    final value = controller.text.trim();

    return AtemTappable(
      onTap: set.done ? null : () => onEdit(open ? null : field),
      semanticLabel: set.done
          ? semanticLabel
          : l10n.workoutValueEditA11y(
              fieldName,
              index,
              value.isEmpty ? l10n.workoutValueEmpty : value,
            ),
      selected: open,
      minTapSize: const Size.square(48),
      child: AbsorbPointer(
        child: AtemNumberField(
          controller: controller,
          semanticLabel: semanticLabel,
          width: width,
          decimal: decimal,
          locked: set.done,
          suffix: suffix,
          onChanged: _onChangedFor(field),
        ),
      ),
    );
  }

  ValueChanged<String>? _onChangedFor(SetField field) => switch (field) {
        SetField.weight => onWeightChanged,
        SetField.reps => onRepsChanged,
        SetField.hold => onHoldChanged,
      };

  /// Der aufgeklappte Regler unter der Zeile.
  Widget _stepPanel(BuildContext context, AppL10n l10n) {
    final field = editing!;
    final (controller, label, steps, decimals, unit) = switch (field) {
      SetField.weight => (
          weightController,
          l10n.workoutRunnerTableWeight,
          // Halbe, ganze und Fünferschritte: Hantelscheiben gibt es in 0,5,
          // Körpergewicht wächst in Einern, Langhanteln springen in Fünfern.
          const [0.5, 1.0, 5.0],
          1,
          l10n.workoutSetLoggerWeightUnit,
        ),
      SetField.reps => (
          repsController,
          l10n.workoutRunnerTableReps,
          const [1.0],
          0,
          null,
        ),
      SetField.hold => (
          holdController!,
          l10n.workoutColHold,
          const [1.0, 5.0],
          0,
          l10n.unitSuffixSeconds,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: AtemSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 1,
            child: ColoredBox(color: AtemColors.border),
          ),
          const SizedBox(height: AtemSpacing.md),
          AtemStepInput(
            label: label,
            controller: controller,
            onChanged: _onChangedFor(field) ?? (_) {},
            steps: steps,
            decimals: decimals,
            unit: unit,
            semanticLabel: switch (field) {
              SetField.weight => l10n.workoutA11yWeightField(index),
              SetField.reps => l10n.workoutA11yRepsField(index),
              SetField.hold => l10n.workoutA11yHoldField(index),
            },
          ),
          const SizedBox(height: AtemSpacing.sm),
          AtemButton.ghost(
            label: l10n.workoutValueDone,
            semanticLabel: l10n.workoutValueDoneA11y(index),
            size: AtemButtonSize.compact,
            accent: AtemColors.cyan,
            onPressed: () => onEdit(null),
          ),
        ],
      ),
    );
  }

  Widget _doneButton(BuildContext context, AppL10n l10n) => AtemTappable(
        onTap: onToggle,
        semanticLabel: set.done
            ? l10n.workoutA11ySetUnlock(index)
            : l10n.workoutA11ySetComplete(index),
        selected: set.done,
        haptic: AtemHaptic.medium,
        child: AnimatedContainer(
          duration: AtemMotion.duration(context, AtemMotion.fast),
          width: doneWidth,
          height: 48,
          decoration: BoxDecoration(
            color: set.done ? AtemColors.green : AtemColors.surfaceSolid,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: set.done ? AtemColors.green : const Color(0xFF3A3A52),
            ),
            boxShadow: set.done
                ? [
                    BoxShadow(
                      color: AtemColors.green.withValues(alpha: 0.7),
                      blurRadius: 18,
                      spreadRadius: -2,
                    )
                  ]
                : null,
          ),
          // Der Haken erscheint NUR im abgehakten Zustand. Vorher stand er in
          // beiden Zuständen und nur seine Farbe wechselte — Form statt Farbe.
          child: set.done
              ? const _Checkmark(color: AtemColors.base)
              : const SizedBox.shrink(),
        ),
      );
}

class _Checkmark extends StatelessWidget {
  const _Checkmark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _CheckPainter(color),
        size: const Size.square(22),
      );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.22, s * 0.52)
        ..lineTo(s * 0.42, s * 0.72)
        ..lineTo(s * 0.78, s * 0.28),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
