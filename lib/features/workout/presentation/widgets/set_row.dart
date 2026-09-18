import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../workout_ui.dart';
import '../../domain/workout_session.dart';
import '../set_type_ui.dart';
import '../../../history/domain/training_session.dart' show SetSide;
import 'set_effort.dart';

/// Welcher Wert einer Satzzeile gerade geändert wird.
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
/// ## Die Werte sind **Knöpfe**, keine Eingabefelder
///
/// Vorlage „TEM Workout Runner" (Claude Design, gelesen am 18.09.2026): Ein
/// Tap öffnet das Eingabeblatt mit Regler und Tastatur, die Zeile selbst
/// zeigt den Wert nur an. Leer heißt „—" — kein leeres Feld, das aussieht,
/// als stünde dort eine Null.
///
/// Vorher lagen hier echte Textfelder unter einem [AbsorbPointer], damit sie
/// nicht gleichzeitig die Tastatur öffneten. Ein Feld, das man nicht
/// beschreiben kann, ist aber kein Feld; jetzt steht dort, was es ist.
///
/// ## Übernommen ist nicht eingetragen
///
/// Ein Wert, der beim Abhaken aus dem vorigen Satz kam ([WorkoutSet.carried]),
/// steht in Cyan mit cyanem Rand. Er bleibt ein Vorschlag, bis man ihn ändert
/// oder bestätigt — danach ist er weiß wie jede andere Angabe.
///
/// ## Seite und Anstrengung (18.09.2026, kein Board, aus Tokens gebaut)
///
/// Seitengetrennte Übungen tragen eine Marke L/R neben dem Typ. Für sie ist in
/// der breiten Zeile kein Platz — 48 dp mehr liessen der Historie nichts —,
/// deshalb nehmen sie **immer** das zweizeilige Layout.
///
/// Ein abgehakter Satz mit Anstrengung zeigt darunter die Kapsel „RPE 8"
/// ([RpeBadge]). Sie steht in einer eigenen Zeile, nicht in der Historie:
/// Dort bleiben bei 361 dp keine 50 dp, und „harter Satz" muss ausgeschrieben
/// dabeistehen.
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.index,
    required this.onToggle,
    required this.onCycleType,
    required this.onEdit,
    this.isHold = false,
    this.unilateral = false,
    this.onToggleSide,
    this.onOpenRpe,
    this.rpeOpen = false,
  });

  final WorkoutSet set;

  /// Satznummer ab 1 — für die Semantics-Labels.
  final int index;

  final VoidCallback onToggle;
  final VoidCallback onCycleType;

  /// Öffnet das Eingabeblatt für einen Wert.
  final ValueChanged<SetField> onEdit;

  /// Halteübung: Die Sekundenspalte tritt an die Stelle der Wiederholungen.
  ///
  /// Beides nebeneinander wäre eine Spalte zu viel, und im Bestand tragen
  /// Sätze immer nur eins von beiden.
  final bool isHold;

  /// Seitengetrennt: Die Zeile zeigt die Marke L/R und nimmt das zweizeilige
  /// Layout.
  final bool unilateral;

  /// Wechselt die Seite. Nur bei [unilateral] und offenem Satz wirksam.
  final VoidCallback? onToggleSide;

  /// Öffnet den Anstrengungs-Streifen über die Kapsel erneut.
  final VoidCallback? onOpenRpe;

  /// Steht der Streifen dieses Satzes gerade offen?
  final bool rpeOpen;

  /// Ab hier trägt die Zeile ihre fünf Spalten nicht mehr.
  static bool isCompact(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(12) > 16 ||
      MediaQuery.sizeOf(context).width < 360;

  /// Spaltenmasse — **eine Quelle für Zeile und Tabellenkopf**.
  ///
  /// Zahlen aus der Vorlage (32 / flexibel / 74 / 60 / 44). Das Häkchen ist
  /// sichtbar 44 dp breit, seine Trefferfläche 48 — [AtemTappable] vergrößert
  /// die Layoutfläche, deshalb rechnet die Spalte mit 48.
  static const typeWidth = 32.0;
  static const weightWidth = 74.0;
  static const repsWidth = 60.0;

  /// Halteübungen haben **keine Gewichtsspalte** (Vorlage: `holdMode` zeigt
  /// „SATZ · LETZTES MAL · HALTEN"). Ein Unterarmstütz wiegt nichts, was man
  /// einträgt; die freie Breite bekommt die Haltezeit.
  static const holdWidth = 100.0;
  static const doneVisibleWidth = 44.0;
  static const doneWidth = 48.0;
  static const columnGap = 8.0;
  static const rowPadding = 10.0;
  static const _cellHeight = 46.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final compact = isCompact(context) || unilateral;
    final rpe = set.rpe;
    final main =
        compact ? _compactLayout(context, l10n) : _wideLayout(context, l10n);

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: set.done
              ? AtemColors.green.withValues(alpha: 0.35)
              : AtemColors.border,
        ),
      ),
      child: !set.done || rpe == null
          ? main
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                main,
                const SizedBox(height: 4),
                // Unter der Historienspalte, nicht am Zeilenrand: Dort liest
                // man ohnehin, was zu diesem Satz gehört.
                Padding(
                  padding: EdgeInsets.only(left: compact ? 0 : 48 + columnGap),
                  child: RpeBadge(
                    rpe: rpe,
                    setNumber: index,
                    open: rpeOpen,
                    onTap: onOpenRpe ?? () {},
                  ),
                ),
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
          if (isHold)
            _holdCell(context, l10n, width: holdWidth)
          else ...[
            _weightCell(context, l10n),
            const SizedBox(width: columnGap),
            _repsCell(context, l10n),
          ],
          const SizedBox(width: columnGap),
          _doneButton(context, l10n),
        ],
      );

  Widget _compactLayout(BuildContext context, AppL10n l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _typeChip(context, l10n),
              const SizedBox(width: AtemSpacing.sm),
              if (unilateral) ...[
                _sideMark(context, l10n),
                const SizedBox(width: AtemSpacing.sm),
              ],
              Expanded(child: _history(context, l10n)),
            ],
          ),
          const SizedBox(height: AtemSpacing.sm),
          Row(
            children: [
              // Die Spaltennamen wandern als Einheit ins Feld.
              if (isHold)
                Expanded(
                  child: _holdCell(context, l10n,
                      suffix: l10n.unitSuffixSeconds, width: null),
                )
              else ...[
                Expanded(
                  flex: 6,
                  child: _weightCell(context, l10n,
                      suffix: l10n.workoutSetLoggerWeightUnit, width: null),
                ),
                const SizedBox(width: AtemSpacing.sm),
                Expanded(
                  flex: 5,
                  child: _repsCell(context, l10n, suffix: '×', width: null),
                ),
              ],
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

  /// Die Seite des Satzes, L oder R. Tippen wechselt sie.
  ///
  /// Gebaut wie der Typ-Chip daneben — sichtbar 32 dp, Trefferfläche 48 —,
  /// aber mit Cyan-Rand: Sie ist eine Angabe zum Satz, kein Satztyp. Ohne
  /// Seite (abgehakt, bevor „Seiten getrennt" an war) steht ein Geviertstrich,
  /// vorgelesen als „keine Angabe" — eine Seite wird nicht erfunden.
  Widget _sideMark(BuildContext context, AppL10n l10n) {
    final side = set.side;
    final name = switch (side) {
      SetSide.left => l10n.workoutSideLeft,
      SetSide.right => l10n.workoutSideRight,
      null => l10n.workoutValueEmpty,
    };
    final other =
        side == SetSide.left ? l10n.workoutSideRight : l10n.workoutSideLeft;
    final short = switch (side) {
      SetSide.left => l10n.workoutSideLeftShort,
      SetSide.right => l10n.workoutSideRightShort,
      null => l10n.workoutValueNone,
    };

    return AtemTappable(
      // Gesperrt wie der Typ: Abgehakt ist abgehakt, erst entsperren.
      onTap: set.done ? null : onToggleSide,
      semanticLabel: set.done
          ? l10n.workoutSideDoneA11y(name, index)
          : l10n.workoutSideA11y(name, index, other),
      minTapSize: const Size.square(48),
      child: Container(
        width: typeWidth,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: set.done ? const Color(0x00000000) : AtemColors.surfaceSolid,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: set.done
                ? AtemColors.border
                : AtemColors.cyan.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          short,
          style: AtemType.labelUi.of(context).copyWith(
                fontWeight: FontWeight.w700,
                color: set.done ? AtemColors.textSecondary : AtemColors.cyan,
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

  Widget _weightCell(BuildContext context, AppL10n l10n,
          {String? suffix, double? width = weightWidth}) =>
      _valueCell(
        context,
        l10n,
        field: SetField.weight,
        value: set.weight,
        fieldName: l10n.workoutRunnerTableWeight,
        semanticLabel: l10n.workoutA11yWeightField(index),
        width: width,
        suffix: suffix,
      );

  Widget _holdCell(BuildContext context, AppL10n l10n,
          {String? suffix, double? width = repsWidth}) =>
      _valueCell(
        context,
        l10n,
        field: SetField.hold,
        value: set.hold,
        fieldName: l10n.workoutColHold,
        semanticLabel: l10n.workoutA11yHoldField(index),
        width: width,
        // Die Sekunde steht in der Zeile mit dabei („45 s"), weil die
        // Spaltenüberschrift „HALTEN" heißt und nicht „SEK".
        suffix: suffix ?? l10n.unitSuffixSeconds,
      );

  Widget _repsCell(BuildContext context, AppL10n l10n,
          {String? suffix, double? width = repsWidth}) =>
      _valueCell(
        context,
        l10n,
        field: SetField.reps,
        value: set.reps,
        fieldName: l10n.workoutRunnerTableReps,
        semanticLabel: l10n.workoutA11yRepsField(index),
        width: width,
        suffix: suffix,
      );

  /// Ein Wert in der Zeile: ein Knopf, der das Eingabeblatt öffnet.
  Widget _valueCell(
    BuildContext context,
    AppL10n l10n, {
    required SetField field,
    required String value,
    required String fieldName,
    required String semanticLabel,
    required double? width,
    String? suffix,
  }) {
    final text = value.trim();
    final empty = text.isEmpty;
    // Übernommen zählt nur, solange der Satz offen ist: Ist er abgehakt, ist
    // der Wert das Ergebnis und kein Vorschlag mehr.
    final carried = set.carried && !set.done && !empty;

    final Color valueColor = empty
        ? AtemColors.textDisabled
        : (carried ? AtemColors.cyan : AtemColors.textPrimary);
    final Color borderColor = set.done
        ? AtemColors.green.withValues(alpha: 0.3)
        : (carried
            ? AtemColors.cyan.withValues(alpha: 0.35)
            : AtemColors.border);

    final cell = AnimatedContainer(
      duration: AtemMotion.duration(context, AtemMotion.fast),
      width: width,
      height: _cellHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: set.done ? const Color(0x00000000) : AtemColors.surfaceSolid,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        // Geviertstrich wie in der Vorlage: Er füllt die Zelle sichtbar aus,
        // ein Bindestrich sah aus wie ein Rest vom Rand.
        empty ? l10n.workoutValueNone : _withSuffix(text, suffix),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AtemType.valueMedium.of(context).copyWith(color: valueColor),
      ),
    );

    // Abgehakt ist nicht bearbeitbar — erst entsperren, dann ändern. Der
    // Knopf bleibt als Anzeige stehen, damit die Zeile nicht springt.
    if (set.done) {
      return Semantics(
        label: '$semanticLabel, ${empty ? l10n.workoutValueEmpty : text}',
        excludeSemantics: true,
        child: cell,
      );
    }

    return AtemTappable(
      onTap: () => onEdit(field),
      semanticLabel: l10n.workoutValueEditA11y(
        fieldName,
        index,
        empty ? l10n.workoutValueEmpty : text,
      ),
      minTapSize: Size(width ?? 0, 48),
      child: cell,
    );
  }

  String _withSuffix(String value, String? suffix) =>
      suffix == null ? value : '$value $suffix';

  Widget _doneButton(BuildContext context, AppL10n l10n) => AtemTappable(
        onTap: onToggle,
        semanticLabel: set.done
            ? l10n.workoutA11ySetUnlock(index)
            : l10n.workoutA11ySetComplete(index),
        selected: set.done,
        haptic: AtemHaptic.medium,
        child: AnimatedContainer(
          duration: AtemMotion.duration(context, AtemMotion.fast),
          width: doneVisibleWidth,
          height: doneVisibleWidth,
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
