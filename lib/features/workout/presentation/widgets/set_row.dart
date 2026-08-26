import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/workout_session.dart';
import '../set_type_ui.dart';

/// Eine Satzzeile im Runner.
///
/// ## Zwei Layouts, ein Schwellwert
///
/// Fünf Spalten (Typ, Historie, KG, WDH, Häkchen) sind bei 320 dp und großer
/// Systemschrift nicht zu halten. Ab Faktor 1,33 oder unter 360 dp Breite
/// bricht die Zeile in eine zweizeilige Karte um: oben Typ und Historie, unten
/// die Eingaben. Der Tabellenkopf entfällt dann, und die Spaltennamen wandern
/// als Einheit in die Felder.
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

  /// Ab hier trägt die Zeile ihre fünf Spalten nicht mehr.
  static bool isCompact(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) > 16 ||
      MediaQuery.sizeOf(context).width < 360;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final compact = isCompact(context);

    return AnimatedContainer(
      duration: AtemMotion.normal,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
      child:
          compact ? _compactLayout(context, l10n) : _wideLayout(context, l10n),
    );
  }

  Widget _wideLayout(BuildContext context, AppL10n l10n) => Row(
        children: [
          _typeChip(context, l10n),
          const SizedBox(width: 8),
          Expanded(child: _history(context)),
          const SizedBox(width: 8),
          _weightField(l10n),
          const SizedBox(width: 8),
          _repsField(l10n),
          const SizedBox(width: 8),
          _doneButton(context, l10n),
        ],
      );

  Widget _compactLayout(BuildContext context, AppL10n l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _typeChip(context, l10n),
              const SizedBox(width: 10),
              Expanded(child: _history(context)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Die Spaltennamen wandern als Einheit ins Feld.
              Expanded(
                flex: 6,
                child:
                    _weightField(l10n, suffix: l10n.workoutSetLoggerWeightUnit),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 5, child: _repsField(l10n, suffix: '×')),
              const SizedBox(width: 8),
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
      // Sichtbar bleiben 34x32, die Trefferfläche füllt 48x48 aus dem
      // Zeilenpolster.
      minTapSize: const Size.square(48),
      child: Container(
        width: 34,
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
          style: AtemType.labelMicro.of(context).copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: set.done ? AtemColors.textSecondary : tint,
              ),
        ),
      ),
    );
  }

  Widget _history(BuildContext context) => Text(
        set.previousLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AtemType.labelSmall.of(context),
      );

  Widget _weightField(AppL10n l10n, {String? suffix}) => AtemNumberField.weight(
        controller: weightController,
        semanticLabel: l10n.workoutA11yWeightField(index),
        locked: set.done,
        suffix: suffix,
        onChanged: onWeightChanged,
      );

  Widget _repsField(AppL10n l10n, {String? suffix}) => AtemNumberField.reps(
        controller: repsController,
        semanticLabel: l10n.workoutA11yRepsField(index),
        locked: set.done,
        suffix: suffix,
        onChanged: onRepsChanged,
      );

  Widget _doneButton(BuildContext context, AppL10n l10n) => AtemTappable(
        onTap: onToggle,
        semanticLabel: set.done
            ? l10n.workoutA11ySetUnlock(index)
            : l10n.workoutA11ySetComplete(index),
        selected: set.done,
        haptic: AtemHaptic.medium,
        child: AnimatedContainer(
          duration: AtemMotion.fast,
          width: 48,
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
