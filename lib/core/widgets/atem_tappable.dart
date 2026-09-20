import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/atem_motion.dart';

/// Wie stark ein Element beim Antippen einfedert.
enum AtemPressScale {
  /// Standard für Karten, Buttons, Chips.
  normal(0.97),

  /// Kräftiger — für kleine, isolierte Ziele wie Navigationseinträge.
  strong(0.88),

  /// Kein Einfedern. Für Elemente, deren Zustandswechsel selbst sichtbar ist.
  none(1.0);

  const AtemPressScale(this.value);
  final double value;
}

/// Haptik beim Antippen.
enum AtemHaptic {
  none,
  selection,
  light,
  medium,
  heavy;

  /// Der Hauptschalter aus den Einstellungen.
  ///
  /// ## Warum eine statische Variable und kein Provider
  ///
  /// Haptik wird an der untersten Stelle ausgelöst, in [AtemTappable] — dem
  /// Baustein, den jedes antippbare Element benutzt. Ihm eine `ref`
  /// mitzugeben, hiesse jeden Knopf, jede Zeile und jeden Chip der App zu
  /// einem `ConsumerWidget` zu machen, damit eine einzige Ja-Nein-Frage
  /// beantwortet werden kann.
  ///
  /// Das hier ist dieselbe Art von Zustand wie die Schriftskalierung: eine
  /// Eigenschaft des Geräts, prozessweit, ohne Aufbau. Der Abgleich mit den
  /// Einstellungen geschieht an genau einer Stelle in `AtemApp`.
  static bool enabled = true;

  Future<void> fire() => !enabled
      ? Future<void>.value()
      : switch (this) {
          AtemHaptic.none => Future<void>.value(),
          AtemHaptic.selection => HapticFeedback.selectionClick(),
          AtemHaptic.light => HapticFeedback.lightImpact(),
          AtemHaptic.medium => HapticFeedback.mediumImpact(),
          AtemHaptic.heavy => HapticFeedback.heavyImpact(),
        };
}

/// Der einzige Weg, etwas antippbar zu machen.
///
/// Siehe `docs/contracts/01-accessibility.md` R3 und R7. Drei Dinge macht
/// dieses Widget, die man einzeln immer wieder vergisst:
///
/// **1. Die Trefferfläche wächst, das Aussehen nicht.** Eine [ConstrainedBox]
/// bringt die Layoutfläche auf mindestens [minTapSize]; das sichtbare Kind
/// bleibt in seiner gestalteten Größe zentriert. Bewusst kein `RenderProxyBox`,
/// der nur den Hit-Test vergrößert — der ließe die Semantics-Größe klein, die
/// Prüfung fiele weiterhin durch, und man wäre versucht sie zu unterdrücken.
/// Genau die Lücke zwischen Test und Finger soll hier verschwinden.
///
/// **2. [semanticLabel] ist Pflicht.** Zusammen mit der Lint-Regel gegen rohe
/// `GestureDetector` wird „Label vergessen" damit vom Prüfbefund zum
/// Compile-Fehler.
///
/// **3. Das Kind wird von den Semantics ausgeschlossen**, sonst liest ein
/// Screenreader Label und Kindtext doppelt vor.
///
/// Das Einfedern bleibt auch bei „Bewegung reduzieren" erhalten — es ist
/// funktionale Rückmeldung, kurz und klein (Bewegungstabelle, Zeile
/// „Press-Feedback").
class AtemTappable extends StatefulWidget {
  const AtemTappable({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.semanticHint,
    this.selected,
    this.expanded,
    this.inMutuallyExclusiveGroup = false,
    this.pressScale = AtemPressScale.normal,
    this.minTapSize = const Size.square(48),
    this.alignment = Alignment.center,
    this.haptic = AtemHaptic.none,
    this.excludeChildSemantics = true,
    this.onLongPress,
    this.pressBuilder,
  });

  final Widget child;

  /// Baut das Kind mit dem Druckzustand — für Flächen, die im gedrückten
  /// Zustand mehr tun als kleiner zu werden (Knöpfe glühen dann in ihrem
  /// Akzent). Ist er gesetzt, wird [child] nicht verwendet.
  final Widget Function(BuildContext context, bool pressed)? pressBuilder;

  /// `null` bedeutet deaktiviert — das meldet auch Semantics.
  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  /// Was ein Screenreader ansagt. Kommt aus dem ARB, nie als Literal.
  final String semanticLabel;

  /// Ergänzung, die beschreibt was passiert („Tippen zum Ändern").
  final String? semanticHint;

  /// Für Elemente in einer Auswahl — Tabs, Filter, Navigationseinträge.
  final bool? selected;

  /// Für Elemente, die etwas auf- und zuklappen — die Ortszeile mit ihrer
  /// Sprungliste. Ein Screenreader sagt dann „eingeblendet" statt nur
  /// „Schaltfläche".
  final bool? expanded;

  /// Einer von mehreren, von denen genau einer gilt — Segmente, Optionsfelder.
  /// Ein Screenreader sagt dann „ausgewählt, 1 von 2" statt nur „ausgewählt".
  final bool inMutuallyExclusiveGroup;

  final AtemPressScale pressScale;
  final Size minTapSize;

  /// Wo das sichtbare Kind in der vergrößerten Fläche sitzt.
  final Alignment alignment;

  final AtemHaptic haptic;

  /// In Ausnahmefällen abschaltbar — etwa wenn das Kind selbst eine
  /// zusammengesetzte Beschreibung liefert.
  final bool excludeChildSemantics;

  @override
  State<AtemTappable> createState() => _AtemTappableState();
}

class _AtemTappableState extends State<AtemTappable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    widget.haptic.fire();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget visual = widget.pressBuilder?.call(context, _pressed) ?? widget.child;
    if (widget.excludeChildSemantics) {
      visual = ExcludeSemantics(child: visual);
    }

    if (widget.pressScale != AtemPressScale.none) {
      visual = AnimatedScale(
        scale: _pressed ? widget.pressScale.value : 1.0,
        // Bleibt auch bei reduzierter Bewegung: funktional, kurz, klein.
        duration: AtemMotion.fast,
        curve: AtemMotion.curve,
        child: visual,
      );
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      expanded: widget.expanded,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        // Die Semantics oben tragen bereits Rolle, Label und onTap. Ohne
        // diesen Ausschluss legt der GestureDetector einen zweiten Knoten mit
        // Tap-Aktion, aber ohne Label daneben — und labeledTapTargetGuideline
        // schlägt an, obwohl das Label da ist.
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        onTap: widget.onTap == null ? null : _handleTap,
        onLongPress: widget.onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minTapSize.width,
            minHeight: widget.minTapSize.height,
          ),
          child: Align(
            alignment: widget.alignment,
            // Ohne die Faktoren dehnt sich Align auf den ganzen Elternraum.
            widthFactor: 1,
            heightFactor: 1,
            child: visual,
          ),
        ),
      ),
    );
  }
}
