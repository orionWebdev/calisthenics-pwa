import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart'
    show Icons, showModalBottomSheet, TextBaseline;
import 'package:flutter/widgets.dart';

// Die einzige Stelle, an der `core/` in ein Feature greift: Der
// Scheibenrechner ist reine Domäne ohne Flutter (Schichtregel „domain/"), und
// das Eingabeblatt ist sein einziger Ort. Ihn nach `core/` zu ziehen, hätte
// eine Rechenregel des Trainings zum Baustein des Baukastens gemacht.
import '../domain/plate_calculator.dart';
import '../../l10n/gen/app_l10n.dart';
import '../theme/theme.dart';
import 'atem_button.dart';
import 'atem_choice_chip.dart';
import 'atem_number_field.dart';
import 'atem_overlays.dart';
import 'atem_plate_stack.dart';
import 'atem_tappable.dart';

/// Welches Feld das Blatt einstellt.
///
/// Die ersten drei gehören einem Satz im Runner. [bodyWeight] gehört keinem
/// Satz — es ist der Gewichtsverlauf (Board 14, B), der dasselbe Blatt mit
/// anderen Schrittweiten und einem Datum darüber benutzt.
enum AtemStepField { weight, reps, hold, bodyWeight }

/// Das Zahlen-Eingabeblatt des Runners — **ein Blatt von unten**, kein
/// Bereich in der Satzzeile.
///
/// ## Woher die Gestalt kommt
///
/// Eins zu eins aus der Claude-Design-Vorlage `TEM Workout Runner.dc.html`
/// (Abschnitt `padOpen` und die Klasse `Component`): Kopf mit Titel und
/// Vorwert, Umschalter zur Tastatur, die grosse Zahl mit Einheit, die
/// Delta-Zeile, die Schrittkapseln, das Band mit − und + und zuletzt
/// „ÜBERNEHMEN". Masse, Rasterweite (30 dp je Schritt) und Grenzen je Feld
/// stammen aus dem `cfg`-Block der Vorlage; die Farben kommen aus
/// `atem_colors.dart`, nicht aus dem HTML.
///
/// ## Warum ein Blatt und kein aufklappender Bereich
///
/// Zwischen zwei Sätzen ist eine Hand am Gerät. Ein Blatt legt Zahl, Band und
/// Daumen an dieselbe Stelle, egal welcher Satz gerade dran ist — ein Bereich
/// in der Zeile wandert mit der Zeile und schiebt die Liste auseinander.
///
/// ## Was hier nicht passiert
///
/// Das Blatt schreibt nichts. Es gibt den übernommenen Wert zurück; wer
/// abbricht, bekommt `null`. Damit bleibt die Regel „keine Angabe, die
/// niemand gemacht hat" beim Aufrufer.
Future<double?> showAtemStepPad(
  BuildContext context, {
  required AtemStepField field,
  int setNumber = 1,
  double? value,
  double? previousValue,
  String? previousLabel,
  bool showPlates = false,
  String? title,
  String? applyLabel,
  String? valueNote,
  Widget? headline,
  Widget? notice,
  Widget Function(BuildContext context, double value)? footerBuilder,
  Widget? trailing,
}) {
  final l10n = AppL10n.of(context);
  return showModalBottomSheet<double>(
    context: context,
    // Über allem, auch über der Navigationsleiste: Jeder Tab hat seit Modul 11
    // seinen eigenen Navigator (siehe AtemSheet).
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0x00000000),
    barrierColor: AtemOverlays.barrier(AtemOverlays.sheetBarrierOpacity),
    barrierLabel: l10n.stepPadClose,
    showDragHandle: false,
    builder: (_) => AtemStepPad(
      field: field,
      setNumber: setNumber,
      value: value,
      previousValue: previousValue,
      previousLabel: previousLabel,
      showPlates: showPlates,
      title: title,
      applyLabel: applyLabel,
      valueNote: valueNote,
      headline: headline,
      notice: notice,
      footerBuilder: footerBuilder,
      trailing: trailing,
    ),
  );
}

/// Der Inhalt des Blattes. Öffentlich, damit Tests und die Sichtprüfung ihn
/// ohne Route pumpen können; im Betrieb kommt er über [showAtemStepPad].
class AtemStepPad extends StatefulWidget {
  const AtemStepPad({
    super.key,
    required this.field,
    this.setNumber = 1,
    this.value,
    this.previousValue,
    this.previousLabel,
    this.showPlates = false,
    this.onApply,
    this.title,
    this.applyLabel,
    this.valueNote,
    this.headline,
    this.notice,
    this.footerBuilder,
    this.trailing,
  });

  final AtemStepField field;

  /// 1-basiert, steht im Titel: „GEWICHT · SATZ 2". Ohne Satzbezug
  /// bedeutungslos — dann trägt [title] die Kopfzeile.
  final int setNumber;

  /// Ersetzt den Titel aus dem Feld. Für Aufrufer ausserhalb des Runners.
  final String? title;

  /// Ersetzt „ÜBERNEHMEN" — „EINTRAGEN" oder „AKTUALISIEREN" (Board 14, B).
  final String? applyLabel;

  /// Eine Zeile unter der grossen Zahl statt der Delta-Zeile.
  ///
  /// Der Runner vergleicht mit dem letzten Mal; der Gewichtsverlauf nennt
  /// stattdessen den zuletzt bekannten Wert samt Abstand („ZULETZT 78,9 KG ·
  /// VOR 5 TAGEN"). Beides an derselben Stelle, nie beides zugleich.
  final String? valueNote;

  /// Unter dem Titel, über dem Wert — der Datums-Chip aus Board 14.
  ///
  /// **Die einzige echte Ergänzung an diesem Blatt.** Im Runner stand „jetzt"
  /// nie zur Debatte; beim Gewicht ist Nachtragen der häufigste Fall.
  final Widget? headline;

  /// Über dem Wert: die Notiz „heute schon erfasst" (Board 14, B2). Sie
  /// informiert und blockiert nichts.
  final Widget? notice;

  /// Zwischen Band und Knopf, mit dem **aktuellen** Wert.
  ///
  /// Die rückwirkende Vorschau aus Board 14, C2 zeigt „80,5 → 80,2" und muss
  /// dem Band folgen — ein fertiges Widget könnte das nicht.
  final Widget Function(BuildContext context, double value)? footerBuilder;

  /// Unter dem Knopf: „Eintrag löschen". Der zerstörende Weg steht nie neben
  /// dem vorwärts führenden, sondern darunter (Modul 2).
  final Widget? trailing;

  /// Der aktuelle Wert; `null` heisst leer — dann startet das Band beim
  /// Vorwert, sonst beim Rückfallwert aus der Vorlage.
  final double? value;

  /// Für die Delta-Zeile.
  final double? previousValue;

  /// „100 kg × 8" — steht als „Letztes Mal: …" unter dem Titel.
  final String? previousLabel;

  /// Bietet beim Gewicht den Scheibenrechner an („Scheiben"). Aus für
  /// Übungen ohne Langhantel — eine Kurzhantel oder eine Weste steckt man
  /// nicht. Bei Wiederholungen und Haltezeit wirkungslos.
  final bool showPlates;

  /// Nur für Tests und die Sichtprüfung. Ohne ihn schliesst „ÜBERNEHMEN" das
  /// Blatt und gibt den Wert zurück.
  final ValueChanged<double>? onApply;

  /// Abstand zweier Rastpunkte auf dem Band — wie in der Vorlage.
  static const pixelsPerStep = 30.0;

  /// Höhe des Bandes.
  static const rulerHeight = 76.0;

  /// Damit Tests das Band finden, ohne im Baum zu raten.
  static const rulerKey = ValueKey<String>('atem_step_pad_ruler');

  @override
  State<AtemStepPad> createState() => _AtemStepPadState();
}

/// Grenzen, Schrittweiten und Rückfallwerte je Feld — der `cfg`-Block der
/// Vorlage.
class _PadConfig {
  const _PadConfig({
    required this.steps,
    required this.defaultStep,
    required this.min,
    required this.max,
    required this.fallback,
    required this.quick,
    required this.decimals,
  });

  final List<double> steps;
  final double defaultStep;
  final double min;
  final double max;

  /// Wert, mit dem das Band öffnet, wenn es weder einen Wert noch einen
  /// Vorwert gibt.
  final double fallback;

  /// Die vier Schnellknöpfe im Tastaturmodus.
  final List<double> quick;

  final int decimals;

  static const weight = _PadConfig(
    steps: [0.5, 1, 5],
    defaultStep: 1,
    min: 0,
    max: 400,
    fallback: 20,
    quick: [-5, -1, 1, 5],
    decimals: 1,
  );
  static const reps = _PadConfig(
    steps: [1, 5],
    defaultStep: 1,
    min: 1,
    max: 60,
    fallback: 8,
    quick: [-5, -1, 1, 5],
    decimals: 0,
  );
  static const hold = _PadConfig(
    steps: [1, 5],
    defaultStep: 5,
    min: 1,
    max: 600,
    fallback: 30,
    quick: [-10, -5, 5, 10],
    decimals: 0,
  );

  /// Körpergewicht (Board 14, B): 0,1 / 0,5 / 1 kg.
  ///
  /// Feiner als beim Satzgewicht, weil die meisten Änderungen klein sind —
  /// eine halbe Hantelscheibe gibt es nicht, ein halbes Kilo Körpergewicht
  /// schon. Die Grenzen 30–250 kg sind dieselben wie in den Einstellungen
  /// (`UserSettings`): Sie fangen den Vertipper, aus dem 780 statt 78 wird.
  static const bodyWeight = _PadConfig(
    steps: [0.1, 0.5, 1],
    defaultStep: 0.1,
    min: 30,
    max: 250,
    fallback: 75,
    quick: [-1, -0.5, 0.5, 1],
    decimals: 1,
  );

  static _PadConfig of(AtemStepField field) => switch (field) {
        AtemStepField.weight => weight,
        AtemStepField.reps => reps,
        AtemStepField.hold => hold,
        AtemStepField.bodyWeight => bodyWeight,
      };
}

class _AtemStepPadState extends State<AtemStepPad> {
  late final _PadConfig _cfg = _PadConfig.of(widget.field);
  late double _value;
  late double _step = _cfg.defaultStep;
  final _controller = TextEditingController();
  bool _keyboard = false;

  /// Scheibenrechner aufgeklappt — startet zu, jedes Blatt neu.
  bool _platesOpen = false;

  /// Die gewählte Stange. Nur für dieses Blatt; 20 kg ist die übliche.
  double _barKg = PlateCalculator.bars.first;

  /// Reservierte Höhe der Textzeilen unter der Grafik und wofür sie gilt.
  String? _platesTextKey;
  double _platesTextHeight = 0;

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.value ?? widget.previousValue ?? _cfg.fallback);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _clamp(double v) {
    final rounded = (v * 10).roundToDouble() / 10;
    return rounded.clamp(_cfg.min, _cfg.max);
  }

  void _setValue(double v) {
    final next = _clamp(v);
    if (next == _value) return;
    AtemHaptic.selection.fire();
    setState(() {
      _value = next;
      if (_keyboard) _controller.text = AtemNumberField.format(context, next);
    });
  }

  void _openKeyboard() {
    setState(() {
      _keyboard = true;
      _controller.text = AtemNumberField.format(context, _value);
    });
  }

  void _onText(String raw) {
    final parsed = AtemNumberField.parse(raw);
    if (parsed == null) return;
    setState(() => _value = _clamp(parsed));
  }

  /// Eigene Einheiten-Keys statt der Tabellenköpfe des Runners: Die gehören
  /// dem Runner und dürfen sich dort ändern, ohne dass hier „HALTEN" neben
  /// der Zahl steht, wo „SEK" hingehört.
  String get _unit => switch (widget.field) {
        AtemStepField.weight ||
        AtemStepField.bodyWeight =>
          AppL10n.of(context).stepPadUnitWeight,
        AtemStepField.reps => AppL10n.of(context).stepPadUnitReps,
        AtemStepField.hold => AppL10n.of(context).stepPadUnitHold,
      };

  String get _fieldName => switch (widget.field) {
        AtemStepField.weight ||
        AtemStepField.bodyWeight =>
          AppL10n.of(context).stepPadFieldWeight,
        AtemStepField.reps => AppL10n.of(context).stepPadFieldReps,
        AtemStepField.hold => AppL10n.of(context).stepPadFieldHold,
      };

  String _title(AppL10n l10n) =>
      widget.title ??
      switch (widget.field) {
        AtemStepField.weight => l10n.stepPadTitleWeight(widget.setNumber),
        AtemStepField.reps => l10n.stepPadTitleReps(widget.setNumber),
        AtemStepField.hold => l10n.stepPadTitleHold(widget.setNumber),
        // Ohne Titel vom Aufrufer gibt es für dieses Feld keinen Satzbezug,
        // aus dem sich einer bilden liesse.
        AtemStepField.bodyWeight => l10n.stepPadFieldWeight,
      };

  String _stepLabel(AppL10n l10n, double step) {
    final text = AtemNumberField.format(context, step);
    return switch (widget.field) {
      AtemStepField.weight ||
      AtemStepField.bodyWeight =>
        l10n.stepPadStepKg(text),
      AtemStepField.hold => l10n.stepPadStepSeconds(text),
      AtemStepField.reps => l10n.stepPadStepPlain(text),
    };
  }

  void _apply() {
    final onApply = widget.onApply;
    if (onApply != null) {
      onApply(_value);
      return;
    }
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      // Über der Tastatur bleiben — sonst verdeckt sie „ÜBERNEHMEN".
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: Container(
          decoration: const BoxDecoration(
            color: AtemColors.surfaceSolid,
            border: Border(top: BorderSide(color: AtemColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(l10n),
                    if (widget.headline != null) ...[
                      const SizedBox(height: 6),
                      widget.headline!,
                    ],
                    if (widget.notice != null) ...[
                      const SizedBox(height: 10),
                      widget.notice!,
                    ],
                    const SizedBox(height: 18),
                    _value_(l10n),
                    if (widget.valueNote != null)
                      _note(widget.valueNote!)
                    else
                      _delta(l10n),
                    if (widget.field == AtemStepField.weight &&
                        widget.showPlates)
                      ..._plates(l10n),
                    if (_keyboard) ..._keys(l10n) else ..._ruler(l10n),
                    if (widget.footerBuilder != null) ...[
                      const SizedBox(height: 12),
                      widget.footerBuilder!(context, _value),
                    ],
                    const SizedBox(height: 18),
                    AtemButton.gradient(
                      label: widget.applyLabel ?? l10n.stepPadApply,
                      semanticLabel: widget.applyLabel ?? l10n.stepPadApply,
                      onPressed: _apply,
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(height: 10),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Kopf ------------------------------------------------------------------

  /// Titel, Vorwert und Umschalter.
  ///
  /// Gemessen statt geraten: Passt der Titel nicht neben den Umschalter,
  /// rutscht der Umschalter darunter. Sonst bricht der Titel bei 200 %
  /// Systemschrift auf 320 dp mitten im Wort („GEWI / CHT").
  Widget _header(AppL10n l10n) {
    final title = _title(l10n);
    final previous = widget.previousLabel;
    final titleStyle =
        AtemType.labelMicro.of(context).copyWith(color: AtemColors.cyan);
    final scaler = MediaQuery.textScalerOf(context);

    double widthOf(String text, TextStyle style) => (TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout())
            .width;

    final pillLabel = _keyboard ? l10n.stepPadRuler : l10n.stepPadKeyboard;
    final pillWidth = widthOf(
          pillLabel,
          AtemType.labelMicro.of(context).copyWith(fontWeight: FontWeight.w700),
        ) +
        15 + // Symbol
        7 + // Abstand dahinter
        26; // Innenpolster der Kapsel

    return LayoutBuilder(
      builder: (context, constraints) {
        final texts = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: titleStyle),
            if (previous != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.stepPadPrevious(previous),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.meta.of(context),
              ),
            ],
          ],
        );

        final fits =
            widthOf(title, titleStyle) + 12 + pillWidth <= constraints.maxWidth;
        if (fits) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: texts),
              const SizedBox(width: 12),
              _modePill(l10n),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            texts,
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: _modePill(l10n)),
          ],
        );
      },
    );
  }

  Widget _modePill(AppL10n l10n) {
    final active = _keyboard;
    return AtemTappable(
      onTap: () => active ? setState(() => _keyboard = false) : _openKeyboard(),
      semanticLabel: active
          ? l10n.stepPadRulerA11y(_fieldName)
          : l10n.stepPadKeyboardA11y(_fieldName),
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: active
              ? AtemColors.cyan.withValues(alpha: 0.10)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: active
                ? AtemColors.cyan.withValues(alpha: 0.45)
                : AtemColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.tune : Icons.keyboard_alt_outlined,
              size: 15,
              color: active ? AtemColors.cyan : AtemColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              active ? l10n.stepPadRuler : l10n.stepPadKeyboard,
              style: AtemType.labelMicro.of(context).copyWith(
                    color: active ? AtemColors.cyan : AtemColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Wert und Delta --------------------------------------------------------

  /// Die grosse Zahl. Sie wächst nicht unbegrenzt mit der Systemschrift: Bei
  /// 200 % wäre sie höher als das halbe Blatt, deshalb deckelt sie bei 56 dp
  /// gerenderter Höhe — nie kleiner als 28 sp.
  Widget _value_(AppL10n l10n) {
    final scaler = MediaQuery.textScalerOf(context);
    var size = 44.0;
    final scaled = scaler.scale(size);
    if (scaled > 56) size = size * 56 / scaled;
    if (size < 28) size = 28;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            AtemNumberField.format(context, _value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtemType.valueLarge.of(context).copyWith(
                  fontSize: size,
                  height: 1,
                  letterSpacing: -1,
                  shadows: AtemGlow.text(AtemColors.cyan, opacity: 0.35),
                ),
          ),
        ),
        const SizedBox(width: 8),
        Text(_unit, style: AtemType.labelMicro.of(context)),
      ],
    );
  }

  /// Die Zeile unter der grossen Zahl, wenn der Aufrufer eine eigene mitgibt.
  ///
  /// Sie belegt dieselbe Höhe wie die Delta-Zeile, damit das Band an derselben
  /// Stelle steht, egal welches Feld das Blatt gerade führt.
  Widget _note(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          height: MediaQuery.textScalerOf(context).scale(16),
          child: Center(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtemType.labelMicro.of(context),
            ),
          ),
        ),
      );

  /// Der Unterschied zum letzten Mal.
  ///
  /// **Bewusst ohne Ampelfarbe.** Die Vorlage färbt ein Plus grün; CLAUDE.md
  /// schliesst das aus („Deltas sind Tatsachen in `#CDD3EA` … keine
  /// Ampelfarben"), und „mehr" ist beim Gewicht nicht immer besser — an einem
  /// Technik-Tag ist weniger die Absicht.
  Widget _delta(AppL10n l10n) {
    final previous = widget.previousValue;
    final delta = previous == null
        ? null
        : ((_value - previous) * 10).roundToDouble() / 10;
    final visible = delta != null && delta != 0;
    final text = visible
        ? '${delta > 0 ? '+' : ''}${AtemNumberField.format(context, delta)}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Semantics(
        label: visible ? l10n.stepPadDeltaA11y(text, _unit) : '',
        child: ExcludeSemantics(
          child: SizedBox(
            // Der Platz bleibt reserviert, damit das Band nicht springt,
            // sobald der Wert den Vorwert trifft.
            height: MediaQuery.textScalerOf(context).scale(16),
            child: Center(
              child: Text(
                visible ? l10n.stepPadDelta(text, _unit) : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.labelMicro
                    .of(context)
                    .copyWith(color: AtemColors.textTertiary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Scheiben --------------------------------------------------------------

  /// Der Scheibenrechner (Punkt 2.4 der Produktstrategie vom 18.09.2026).
  ///
  /// Kein Board — aus den Tokens gebaut. Eine zurückhaltende Kapsel unter der
  /// Delta-Zeile; aufgeklappt eine Karte mit Stangenwahl, einer Stangenhälfte
  /// und der Belegung als Satz. Sie folgt dem Wert beim Ziehen sofort und
  /// ohne Übergang — es gibt also auch bei „Bewegung reduzieren" nichts
  /// abzuschalten ausser dem Aufklappen selbst.
  List<Widget> _plates(AppL10n l10n) {
    final section = _platesOpen
        ? Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _platesCard(l10n),
          )
        : const SizedBox(width: double.infinity);

    return [
      const SizedBox(height: 6),
      Center(child: _platesToggle(l10n)),
      // AnimatedSize nimmt keine Dauer null; bei „Bewegung reduzieren" steht
      // die Karte deshalb ohne ihn da.
      if (AtemMotion.reduced(context))
        section
      else
        AnimatedSize(
          duration: AtemMotion.normal,
          curve: AtemMotion.curve,
          alignment: Alignment.topCenter,
          child: section,
        ),
    ];
  }

  /// Gestalt wie der Umschalter zur Tastatur — dieselbe Familie, damit sie
  /// als Bedienelement des Blattes erkannt wird und nicht als Inhalt.
  Widget _platesToggle(AppL10n l10n) {
    final open = _platesOpen;
    final tint = open ? AtemColors.cyan : AtemColors.textSecondary;
    return AtemTappable(
      onTap: () => setState(() => _platesOpen = !open),
      semanticLabel:
          open ? l10n.platesToggleHideA11y : l10n.platesToggleShowA11y,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: open
              ? AtemColors.cyan.withValues(alpha: 0.10)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: open
                ? AtemColors.cyan.withValues(alpha: 0.45)
                : AtemColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.album_outlined, size: 15, color: tint),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                l10n.platesToggle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.labelUi.of(context).copyWith(color: tint),
              ),
            ),
            const SizedBox(width: 4),
            Icon(open ? Icons.expand_less : Icons.expand_more,
                size: 16, color: tint),
          ],
        ),
      ),
    );
  }

  Widget _platesCard(AppL10n l10n) {
    final loading = PlateCalculator.solve(_value, barKg: _barKg);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AtemColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtemColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Der Kopf steht über den Kapseln, nicht davor: In einer Zeile
          // mit ihnen brach schon bei 361 dp die dritte Kapsel um. Vorgelesen
          // nennt jede Kapsel „Stange 20 Kilogramm" selbst.
          ExcludeSemantics(
            child: Text(l10n.platesBarLabel,
                style: AtemType.labelMicro.of(context)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final bar in PlateCalculator.bars)
                IntrinsicWidth(
                  child: AtemChoiceChip(
                    label: l10n.platesBarKg(_kg(bar)),
                    semanticLabel: l10n.platesBarA11y(_kg(bar)),
                    selected: bar == _barKg,
                    onTap: () => setState(() => _barKg = bar),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Grafik und Zeilen sind **ein** Knoten.
          Semantics(
            container: true,
            label: _platesA11y(l10n, loading),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AtemPlateStack(
                    plates: loading.belowBar ? const [] : loading.sidePlates,
                    heaviestKg: PlateCalculator.defaultPlates.first,
                    dimmed: loading.belowBar,
                  ),
                  const SizedBox(height: 8),
                  _platesText(l10n, loading),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _kg(double kg) => AtemPlateStack.formatKg(context, kg);

  String _sideText(AppL10n l10n, PlateLoading loading) => [
        for (final p in loading.perSide)
          p.count == 1
              ? _kg(p.plateKg)
              : l10n.platesTimes('${p.count}', _kg(p.plateKg)),
      ].join(' + ');

  String _platesLine(AppL10n l10n, PlateLoading loading) {
    final bar = _kg(loading.barKg);
    if (loading.belowBar) return l10n.platesBelowBar(bar);
    if (loading.isEmptyBar) return l10n.platesEmptyBar(bar);
    return l10n.platesPerSide(_sideText(l10n, loading), bar);
  }

  String? _remainderLine(AppL10n l10n, PlateLoading loading) =>
      loading.belowBar || loading.remainderKg <= 0
          ? null
          : l10n.platesRemainder(
              _kg(loading.remainderKg), _kg(loading.loadedKg));

  String _platesA11y(AppL10n l10n, PlateLoading loading) {
    final bar = _kg(loading.barKg);
    if (loading.belowBar) return l10n.platesA11yBelowBar(bar);
    final base = loading.isEmptyBar
        ? l10n.platesA11yEmptyBar(bar)
        : l10n.platesA11y(
            [
              for (final p in loading.perSide)
                l10n.platesA11yPlate(p.count, _kg(p.plateKg)),
            ].join(', '),
            bar,
          );
    if (loading.remainderKg <= 0) return base;
    return '$base. ${l10n.platesA11yRemainder(_kg(loading.remainderKg), _kg(loading.loadedKg))}';
  }

  /// Die Belegung als Satz, darunter der Rest.
  ///
  /// **Die Höhe wächst, schrumpft aber nicht**, solange das Blatt offen ist.
  /// Sonst bräche die Zeile beim Ziehen mal ein-, mal zweizeilig um, und
  /// alles darüber spränge. Den längsten denkbaren Fall (bis 400 kg, mit
  /// Rest) von Anfang an zu reservieren, liess bei 361 dp drei leere Zeilen
  /// unter einer einzeiligen Belegung stehen — so wächst die Karte höchstens
  /// ein-, zweimal und bleibt dann ruhig.
  Widget _platesText(AppL10n l10n, PlateLoading loading) {
    final lineStyle = AtemType.labelSmall.of(context);
    final restStyle = AtemType.meta.of(context);
    final line = _platesLine(l10n, loading);
    final rest = _remainderLine(l10n, loading);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final scaler = MediaQuery.textScalerOf(context);
      final key = '$width|${scaler.scale(100)}|'
          '${Localizations.localeOf(context)}';
      if (key != _platesTextKey) {
        _platesTextKey = key;
        _platesTextHeight = 0;
      }

      double measure(String text, TextStyle style) => (TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: width))
              .height;

      final height = measure(line, lineStyle) +
          (rest == null ? 0 : 4 + measure(rest, restStyle));
      if (height > _platesTextHeight) _platesTextHeight = height;

      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: _platesTextHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(line, style: lineStyle),
            if (rest != null) ...[
              const SizedBox(height: 4),
              Text(rest, style: restStyle),
            ],
          ],
        ),
      );
    });
  }

  // --- Regler ----------------------------------------------------------------

  List<Widget> _ruler(AppL10n l10n) => [
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final step in _cfg.steps)
              // IntrinsicWidth, weil Wrap seine Kinder mit der vollen Breite
              // als Obergrenze misst — ohne das streckt sich jede Kapsel über
              // die Zeile und die drei stehen untereinander.
              IntrinsicWidth(
                  child: AtemChoiceChip(
                label: _stepLabel(l10n, step),
                semanticLabel: l10n.stepPadStepA11y(
                  AtemNumberField.format(context, step),
                  _fieldName,
                ),
                selected: step == _step,
                onTap: () => setState(() => _step = step),
              )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stepButton(l10n, up: false),
            const SizedBox(width: 10),
            Expanded(child: _band(l10n)),
            const SizedBox(width: 10),
            _stepButton(l10n, up: true),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.stepPadHint(_stepLabel(l10n, _step)),
          textAlign: TextAlign.center,
          // Bewusst die dekorative Grösse: Die Schrittweite steht schon als
          // gewählte Kapsel darüber, hier wiederholt sie nur den Hinweis —
          // in labelMicro brach die Zeile um.
          style: AtemType.labelDeco.of(context),
        ),
      ];

  Widget _stepButton(AppL10n l10n, {required bool up}) => AtemTappable(
        onTap: () => _setValue(_value + (up ? _step : -_step)),
        semanticLabel: up ? l10n.stepPadIncrease : l10n.stepPadDecrease,
        child: Container(
          width: 42,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AtemColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AtemColors.border),
          ),
          child: Text(
            // Echtes Minuszeichen wie in der Vorlage; JetBrains Mono zeichnet
            // es, Poppins nicht.
            up ? '+' : '−',
            style: AtemType.valueLarge.of(context).copyWith(fontSize: 19),
          ),
        ),
      );

  Widget _band(AppL10n l10n) {
    final valueText = '${AtemNumberField.format(context, _value)} $_unit';
    return Semantics(
      slider: true,
      label: l10n.stepPadSliderA11y(_fieldName),
      value: valueText,
      increasedValue:
          '${AtemNumberField.format(context, _clamp(_value + _step))} $_unit',
      decreasedValue:
          '${AtemNumberField.format(context, _clamp(_value - _step))} $_unit',
      onIncrease: () => _setValue(_value + _step),
      onDecrease: () => _setValue(_value - _step),
      child: ExcludeSemantics(
        child: GestureDetector(
          key: AtemStepPad.rulerKey,
          behavior: HitTestBehavior.opaque,
          // Ab dem Aufsetzen messen, nicht ab dem gewonnenen Wettstreit: Wird
          // das Blatt scrollbar (aufgeklappte Scheiben, grosse Schrift),
          // streitet die senkrechte Geste mit, und `start` verschluckte die
          // ersten ~18 dp jedes Zugs — ein Schritt fehlte.
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: (d) =>
              _dragFrom = (d.localPosition.dx, _value),
          onHorizontalDragUpdate: (d) {
            final from = _dragFrom;
            if (from == null) return;
            final dx = d.localPosition.dx - from.$1;
            // Nach links ziehen heisst mehr — das Band wandert unter dem
            // festen Zeiger durch, wie in der Vorlage.
            final raw = from.$2 - (dx / AtemStepPad.pixelsPerStep) * _step;
            _setValue((raw / _step).roundToDouble() * _step);
          },
          onHorizontalDragEnd: (_) => _dragFrom = null,
          onHorizontalDragCancel: () => _dragFrom = null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: AtemStepPad.rulerHeight,
              decoration: BoxDecoration(
                color: AtemColors.surfaceSolid,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AtemColors.border),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RulerPainter(
                        value: _value,
                        step: _step,
                        min: _cfg.min,
                        max: _cfg.max,
                        scaler: MediaQuery.textScalerOf(context),
                        labelStyle: AtemType.labelDeco.of(context),
                      ),
                    ),
                  ),
                  // Der Zeiger steht fest in der Mitte.
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 2.5,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AtemColors.cyan, AtemColors.violet],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: AtemGlow.dot(
                          AtemColors.cyan.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  _fade(left: true),
                  _fade(left: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  (double, double)? _dragFrom;

  Widget _fade({required bool left}) => Positioned(
        left: left ? 0 : null,
        right: left ? null : 0,
        top: 0,
        bottom: 0,
        width: 44,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: left ? Alignment.centerLeft : Alignment.centerRight,
                end: left ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  AtemColors.surfaceSolid,
                  AtemColors.surfaceSolid.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      );

  // --- Tastatur --------------------------------------------------------------

  List<Widget> _keys(AppL10n l10n) => [
        const SizedBox(height: 14),
        AtemNumberField.large(
          controller: _controller,
          semanticLabel: _fieldName,
          onChanged: _onText,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (i, q) in _cfg.quick.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: AtemTappable(
                  onTap: () {
                    _setValue(_value + q);
                    _controller.text =
                        AtemNumberField.format(context, _clamp(_value));
                  },
                  semanticLabel: l10n.stepPadQuickA11y(
                    AtemNumberField.format(context, q),
                  ),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AtemColors.card,
                      borderRadius: BorderRadius.circular(AtemRadii.pill),
                      border: Border.all(color: AtemColors.border),
                    ),
                    child: Text(
                      '${q > 0 ? '+' : '−'}'
                      '${AtemNumberField.format(context, q.abs())}',
                      style: AtemType.labelMicro.of(context).copyWith(
                            color: AtemColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ];
}

/// Die Skala unter dem Zeiger: ein Strich je Schritt, jeder fünfte länger und
/// beschriftet — Masse aus der Vorlage.
class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.value,
    required this.step,
    required this.min,
    required this.max,
    required this.scaler,
    required this.labelStyle,
  });

  final double value;
  final double step;
  final double min;
  final double max;
  final TextScaler scaler;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite || size.width <= 0) return;
    final centerX = size.width / 2;
    final reach = (centerX / AtemStepPad.pixelsPerStep).ceil() + 1;
    final paint = Paint();

    for (var k = -reach; k <= reach; k++) {
      if (k == 0) continue; // Der Zeiger deckt die Mitte ab.
      final tick = ((value + k * step) * 10).roundToDouble() / 10;
      if (tick < min - 0.001 || tick > max + 0.001) continue;

      final x = centerX + k * AtemStepPad.pixelsPerStep;
      if (x < -2 || x > size.width + 2) continue;

      final ratio = tick / (step * 5);
      final major = (ratio - ratio.roundToDouble()).abs() < 0.001;
      final width = major ? 2.0 : 1.5;
      final height = major ? 24.0 : 14.0;
      final top = major ? 16.0 : 22.0;
      paint.color = major ? AtemColors.textSecondary : AtemColors.textDisabled;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - width / 2, top, width, height),
          const Radius.circular(2),
        ),
        paint,
      );

      if (!major) continue;
      final label = TextPainter(
        text: TextSpan(text: _format(tick), style: labelStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final labelY = size.height - 9 - label.height;
      if (labelY < top + height + 2) continue;
      label.paint(canvas, Offset(x - label.width / 2, labelY));
    }
  }

  /// Ohne `BuildContext` im Painter: Komma wie im deutschen Format, Ganzzahlen
  /// ohne Nachkommastelle.
  String _format(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(1).replaceAll('.', ',');

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.value != value ||
      old.step != step ||
      old.labelStyle != labelStyle ||
      old.scaler != scaler;
}
