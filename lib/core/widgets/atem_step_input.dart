import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_l10n.dart';
import '../theme/theme.dart';
import 'atem_choice_chip.dart';
import 'atem_number_field.dart';
import 'atem_tappable.dart';

/// Eine Zahl, die man **zieht** statt tippt — mit Umschalter für Schrittweite
/// und Tastatur.
///
/// ## Warum ein Regler und nicht nur ein Feld
///
/// Im Runner steht zwischen zwei Sätzen wenig Zeit und oft eine Hand am
/// Gerät. Die Tastatur verdeckt dabei die halbe Liste, und für „60 → 62,5"
/// sind es vier Tipper. Das Band hier liegt unter dem Daumen: Ziehen rastet
/// auf die Schrittweite, die Zahl darüber wächst mit.
///
/// **Die Tastatur bleibt trotzdem erreichbar.** Für „107,5" ist Tippen
/// schneller als Ziehen; der Umschalter oben rechts wechselt jederzeit, und
/// beide Wege schreiben in denselben [controller].
///
/// ## Die Schrittweite gehört dem Nutzer, nicht der App
///
/// Kilogramm springt bei dem einen in Fünferschritten, bei der anderen in
/// halben. Beides ist richtig — deshalb wählt man es über [steps] als Kapsel
/// über dem Band, statt dass die App eine Schrittweite errät.
///
/// ## Leer bleibt leer
///
/// Ohne Text im [controller] zeigt das Band [min] **blass** und schreibt
/// nichts. Erst die erste Geste macht daraus eine Angabe. Sonst stünde in
/// jedem Satz eine Zahl, die niemand eingetragen hat (CLAUDE.md: keine
/// Vorbelegung, wo die Angabe freiwillig ist).
class AtemStepInput extends StatefulWidget {
  const AtemStepInput({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.steps,
    required this.semanticLabel,
    this.unit,
    this.min = 0,
    this.max,
    this.decimals = 0,
    this.accent = AtemColors.cyan,
    this.enabled = true,
  }) : assert(steps.length > 0, 'Ohne Schrittweite gibt es nichts zu rasten.');

  /// Kurzform über dem Band: „KG", „WDH", „HALTEN".
  final String label;

  /// Die Quelle der Wahrheit. Regler und Tastatur schreiben beide hierhin,
  /// und eine Änderung von aussen bewegt das Band.
  final TextEditingController controller;

  /// Bekommt denselben Text, den auch [controller] trägt — der Aufrufer
  /// speichert unverändert weiter wie bei einem Textfeld.
  final ValueChanged<String> onChanged;

  /// Wählbare Schrittweiten, z. B. `[0.5, 1, 5]`. Bei genau einer entfallen
  /// die Kapseln.
  final List<double> steps;

  final String semanticLabel;

  /// Einheit neben der grossen Zahl: „kg", „Wdh", „s".
  final String? unit;

  final double min;
  final double? max;

  /// Nachkommastellen der Anzeige. 1 bei Kilogramm mit halben Schritten.
  final int decimals;

  final Color accent;
  final bool enabled;

  /// Abstand zweier Rastpunkte auf dem Band.
  ///
  /// Bewusst unabhängig von der Schrittweite: Dieselbe Daumenbewegung rastet
  /// bei Schritt 5 durch Fünfer und bei Schritt 0,5 durch Halbe. Genau das
  /// ist der Sinn des Umschalters darüber.
  static const pixelsPerStep = 18.0;

  /// Damit Tests und Aufrufer das Band finden, ohne im Baum zu raten.
  static const rulerKey = ValueKey<String>('atem_step_input_ruler');

  @override
  State<AtemStepInput> createState() => _AtemStepInputState();
}

class _AtemStepInputState extends State<AtemStepInput>
    with SingleTickerProviderStateMixin {
  /// Der stetige Stand des Bandes — auch zwischen zwei Rastpunkten.
  double _display = 0;

  /// Der eingetragene Wert. `null` heisst: noch keine Angabe.
  double? _value;

  late double _step;
  bool _keyboard = false;
  bool _dragging = false;

  late final AnimationController _settle;
  Animation<double>? _settleTween;

  /// Schützt vor der eigenen Schreibrunde: Wir schreiben in den Controller,
  /// dessen Listener würde sonst das Band mitten in der Geste zurücksetzen.
  bool _writing = false;

  @override
  void initState() {
    super.initState();
    _step = widget.steps.first;
    _settle = AnimationController(vsync: this)
      ..addListener(() {
        final tween = _settleTween;
        if (tween == null) return;
        _moveTo(tween.value, commit: true);
      });
    _readController();
    widget.controller.addListener(_readController);
  }

  @override
  void didUpdateWidget(AtemStepInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_readController);
      widget.controller.addListener(_readController);
      _readController();
    }
    if (!widget.steps.contains(_step)) _step = widget.steps.first;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_readController);
    _settle.dispose();
    super.dispose();
  }

  // --- Wert und Band --------------------------------------------------------

  double _clamp(double value) {
    final max = widget.max;
    final upper = max ?? double.infinity;
    return math.min(math.max(value, widget.min), upper);
  }

  double _snap(double value) {
    final snapped = (value / _step).roundToDouble() * _step;
    // Gegen Fliesskomma-Reste wie 62,499999 bei Schritt 0,5.
    return _clamp(double.parse(snapped.toStringAsFixed(3)));
  }

  void _readController() {
    if (_writing) return;
    final parsed = AtemNumberField.parse(widget.controller.text);
    setState(() {
      if (parsed == null) {
        _value = null;
        _display = _clamp(widget.min);
      } else {
        _value = _clamp(parsed);
        _display = _value!;
      }
    });
  }

  /// Schiebt das Band und trägt den gerasteten Wert ein, sobald er wechselt.
  void _moveTo(double display, {required bool commit}) {
    final next = _clamp(display);
    final snapped = _snap(next);
    final changed = _value == null || (snapped - _value!).abs() > 1e-9;
    setState(() => _display = next);
    if (!commit || !changed) return;

    _value = snapped;
    final text = AtemNumberField.format(context, snapped);
    _writing = true;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _writing = false;
    AtemHaptic.selection.fire();
    widget.onChanged(text);
  }

  void _stepBy(int direction) {
    final base = _value ?? _clamp(widget.min);
    _settle.stop();
    _moveTo(_snap(base + direction * _step), commit: true);
  }

  void _onDragStart(DragStartDetails _) {
    _settle.stop();
    setState(() => _dragging = true);
    // Die erste Geste macht aus „nichts eingetragen" eine Angabe.
    if (_value == null) _moveTo(_display, commit: true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = -(details.primaryDelta ?? 0) / AtemStepInput.pixelsPerStep;
    _moveTo(_display + delta * _step, commit: true);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _dragging = false);
    final perSecond = -details.velocity.pixelsPerSecond.dx /
        AtemStepInput.pixelsPerStep *
        _step;
    // Nachlauf statt Sprung: gut eine Fünftelsekunde Schwung, dann rastet es.
    final target = _snap(_display + perSecond * 0.2);
    final duration = AtemMotion.duration(context, AtemMotion.slow);
    if (duration == Duration.zero || (target - _display).abs() < 1e-9) {
      _moveTo(target, commit: true);
      return;
    }
    _settleTween = Tween<double>(begin: _display, end: target).animate(
      CurvedAnimation(parent: _settle, curve: AtemMotion.curve),
    );
    _settle
      ..duration = duration
      ..forward(from: 0);
  }

  // --- Aufbau ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final labelStyle = AtemType.labelMicro.of(context);

    final probe = TextPainter(
      text: TextSpan(text: '888', style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final bandHeight = math.max(56.0, 30 + probe.height + 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _head(context, l10n),
        const SizedBox(height: 8),
        if (_keyboard)
          AtemNumberField(
            controller: widget.controller,
            semanticLabel: widget.semanticLabel,
            width: null,
            decimal: widget.decimals > 0,
            locked: !widget.enabled,
            suffix: widget.unit,
            onChanged: widget.onChanged,
          )
        else ...[
          _readout(context),
          const SizedBox(height: 4),
          _band(context, bandHeight, labelStyle, scaler),
        ],
      ],
    );
  }

  /// Beschriftung links, Schrittweiten und Umschalter rechts.
  ///
  /// Ein `Wrap` statt einer Zeile: Bei 200 % Schrift auf 320 dp passen
  /// Kapseln und Umschalter nicht mehr neben die Beschriftung, sie rücken
  /// dann darunter statt überzulaufen.
  Widget _head(BuildContext context, AppL10n l10n) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Text(widget.label, style: AtemType.labelMicro.of(context)),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!_keyboard && widget.steps.length > 1)
                for (final step in widget.steps)
                  // **IntrinsicWidth, sonst füllt jede Kapsel die Zeile.**
                  // Ein `Wrap` misst seine Kinder mit der vollen Breite als
                  // Obergrenze; die zentrierte Fläche der Kapsel nimmt sie
                  // sich. Ohne diese Klammer stand jede Schrittweite als
                  // bildschirmbreiter Balken untereinander.
                  IntrinsicWidth(
                    child: AtemChoiceChip(
                      label: AtemNumberField.format(context, step),
                      semanticLabel: l10n.stepInputStep(
                        AtemNumberField.format(context, step),
                        widget.label,
                      ),
                      selected: step == _step,
                      color: widget.accent,
                      onTap: widget.enabled
                          ? () => setState(() => _step = step)
                          : () {},
                    ),
                  ),
              AtemTappable(
                onTap: widget.enabled
                    ? () => setState(() => _keyboard = !_keyboard)
                    : null,
                semanticLabel: _keyboard
                    ? l10n.stepInputSlider(widget.label)
                    : l10n.stepInputKeyboard(widget.label),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AtemColors.card,
                    borderRadius: BorderRadius.circular(AtemRadii.iconBox),
                    border: Border.all(color: AtemColors.border),
                  ),
                  child: Icon(
                    _keyboard ? Icons.tune : Icons.keyboard_alt_outlined,
                    size: 16,
                    color: AtemColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  /// Die grosse Zahl über dem Zeiger. Ohne Angabe steht sie blass da.
  Widget _readout(BuildContext context) {
    final entered = _value != null;
    final text = AtemNumberField.format(context, _snap(_display));
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              style: AtemType.valueLarge.of(context).copyWith(
                    color: entered ? widget.accent : AtemColors.textSecondary,
                  ),
            ),
          ),
          if (widget.unit != null) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                widget.unit!,
                style: AtemType.labelSmall.of(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _band(
    BuildContext context,
    double height,
    TextStyle labelStyle,
    TextScaler scaler,
  ) {
    final next =
        AtemNumberField.format(context, _snap((_value ?? widget.min) + _step));
    final previous =
        AtemNumberField.format(context, _snap((_value ?? widget.min) - _step));

    return Semantics(
      slider: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      value: AtemNumberField.format(context, _snap(_display)),
      increasedValue: next,
      decreasedValue: previous,
      onIncrease: widget.enabled ? () => _stepBy(1) : null,
      onDecrease: widget.enabled ? () => _stepBy(-1) : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          key: AtemStepInput.rulerKey,
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: widget.enabled ? _onDragStart : null,
          onHorizontalDragUpdate: widget.enabled ? _onDragUpdate : null,
          onHorizontalDragEnd: widget.enabled ? _onDragEnd : null,
          // Kein Ripple — das Band federt ein wie jede andere Fläche.
          child: AnimatedScale(
            scale: _dragging ? AtemPressScale.normal.value : 1.0,
            duration: AtemMotion.duration(context, AtemMotion.fast),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: AtemColors.surfaceSolid,
                borderRadius: AtemRadii.statBoxR,
                border: Border.all(color: AtemColors.border),
              ),
              // Die Skala läuft unter dem Zeiger durch — ohne Schnitt malte
              // sie ihre Striche und Zahlen über den Rand hinaus.
              child: ClipRRect(
                borderRadius: AtemRadii.statBoxR,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _RulerPainter(
                    display: _display,
                    step: _step,
                    min: widget.min,
                    max: widget.max,
                    accent: widget.accent,
                    labelStyle: labelStyle,
                    scaler: scaler,
                    // Bei grosser Schrift trägt nur jeder zehnte Strich eine
                    // Zahl — sonst überlagern sich die Beschriftungen.
                    labelEvery: scaler.scale(12) > 16 ? 10 : 5,
                    separator:
                        AtemNumberField.format(context, 0.5).contains(',')
                            ? ','
                            : '.',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skala, Zeiger und Beschriftung des Bandes.
class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.display,
    required this.step,
    required this.min,
    required this.max,
    required this.accent,
    required this.labelStyle,
    required this.scaler,
    required this.labelEvery,
    required this.separator,
  });

  final double display;
  final double step;
  final double min;
  final double? max;
  final Color accent;
  final TextStyle labelStyle;
  final TextScaler scaler;
  final int labelEvery;
  final String separator;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = size.width / 2;
    final perUnit = AtemStepInput.pixelsPerStep / step;
    final first = ((display - center / perUnit) / step).floor();
    final last = ((display + center / perUnit) / step).ceil();

    final tick = Paint()
      ..color = AtemColors.border
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final tickStrong = Paint()
      ..color = AtemColors.textSecondary
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const top = 10.0;
    for (var k = first; k <= last; k++) {
      final value = k * step;
      if (value < min - 1e-9) continue;
      if (max != null && value > max! + 1e-9) continue;

      final x = center + (value - display) * perUnit;
      final major = k % labelEvery == 0;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + (major ? 18 : 10)),
        major ? tickStrong : tick,
      );
      if (!major) continue;

      final painter = TextPainter(
        text: TextSpan(text: _format(value), style: labelStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      painter.paint(canvas, Offset(x - painter.width / 2, top + 22));
    }

    // Der Zeiger steht fest in der Mitte; das Band läuft darunter durch.
    final pointer = Paint()..color = accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        // Nur über der Strichzone: Ein Zeiger bis zum Boden schnitte durch
        // die Beschriftung, die er gerade meint.
        Rect.fromLTWH(center - 1.5, top - 4, 3, 26),
        const Radius.circular(2),
      ),
      pointer,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center - 6, top - 4)
        ..lineTo(center + 6, top - 4)
        ..lineTo(center, top + 5)
        ..close(),
      pointer,
    );
  }

  String _format(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return text.replaceAll('.', separator);
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.display != display ||
      old.step != step ||
      old.min != min ||
      old.max != max ||
      old.accent != accent ||
      old.labelEvery != labelEvery;
}
