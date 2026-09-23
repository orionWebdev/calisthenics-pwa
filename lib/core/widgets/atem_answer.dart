import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'atem_glyph.dart';

/// Bausteine für Fragen, die jemand über sich beantwortet (Board 18).
///
/// ## Gewählt ist immer Cyan — und nie nur Cyan
///
/// Cyan heisst bei ATEM „Handlung". Eine gewählte Antwort trägt deshalb
/// Cyan-Rand und -Tönung, dazu einen **Formträger**, der ohne Farbe
/// funktioniert: den Kern im Ring ([AtemAnswerOption]) oder das Häkchen an
/// der Ecke ([AtemAnswerChip], [AtemAnswerTile]). Die Farbe eines Symbols
/// sagt nur, welche Spur eine Antwort betrifft — nie, ob sie gewählt ist
/// (Board 18, Entscheidung 22).
///
/// ## Glow ist Quittung
///
/// Der Schein antwortet auf eine Wahl und ist nach 620 ms weg. Nichts
/// pulsiert, nichts leuchtet an einer offenen Frage: Ein leuchtender offener
/// Block wäre eine Erinnerung (Entscheidung 24, 26).

// --- Bewegung aus Board 18, F ------------------------------------------------

/// Öffnen, Bloom, Scan, Snackbar: schneller Start, weiches Auslaufen.
const Curve atemAnswerEase = Cubic(0.22, 1, 0.36, 1);

/// Die Lichtkante: gleichmässig anlaufen, langsam auslaufen.
const Curve _sweepEase = Cubic(0.45, 0, 0.2, 1);

/// Das Häkchen zieht sich.
const Curve _drawEase = Cubic(0.65, 0, 0.35, 1);

const _bloomDuration = Duration(milliseconds: 620);
const _coreDuration = Duration(milliseconds: 220);
const _checkPop = Duration(milliseconds: 380);
const _checkDraw = Duration(milliseconds: 360);

/// Wahl: Einfachauswahl als Zeile mit Ring und Kern.
///
/// Mindestens 52 dp hoch. Mit [glyph] steht links ein 40-dp-Symbolkasten in
/// der Farbe der Spur ([glyphFill], [glyphColor]).
class AtemAnswerOption extends StatelessWidget {
  const AtemAnswerOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
    this.glyph,
    this.glyphFill = AtemColors.surfaceSolid,
    this.glyphColor = AtemColors.textTertiary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticLabel;
  final String? glyph;
  final Color glyphFill;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    return _AnswerPress(
      label: semanticLabel ?? label,
      checked: selected,
      exclusive: true,
      onTap: onTap,
      radius: AtemRadii.statBox,
      child: _Bloom(
        selected: selected,
        radius: AtemRadii.statBox,
        child: _SelectionSurface(
          selected: selected,
          radius: AtemRadii.statBox,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              if (glyph != null) ...[
                _GlyphBox(glyph: glyph!, fill: glyphFill, color: glyphColor),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: _labelStyle(context, selected, 14),
                ),
              ),
              const SizedBox(width: 12),
              _RadioMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wahl: ein Chip mit Zahl, Tag, Tageszeit oder Woche, mindestens 48 × 48.
///
/// Sichtbar ist die volle Trefferfläche — kein Überstand, weil Chips im
/// `Wrap` dicht stehen und ein unsichtbarer Rand den Nachbarn überlagerte.
class AtemAnswerChip extends StatelessWidget {
  const AtemAnswerChip({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    this.exclusive = true,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  /// `true`: Radio in einer Gruppe. `false`: Häkchen einer Mehrfachwahl.
  final bool exclusive;

  @override
  Widget build(BuildContext context) {
    return _AnswerPress(
      label: semanticLabel,
      checked: selected,
      exclusive: exclusive,
      onTap: onTap,
      radius: AtemRadii.statBox,
      child: _CheckCorner(
        selected: selected,
        size: 16,
        child: _Bloom(
          selected: selected,
          radius: AtemRadii.statBox,
          child: _SelectionSurface(
            selected: selected,
            radius: AtemRadii.statBox,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            // Kein `alignment` am Container: Er dehnte sich damit auf die
            // volle Zeile, und aus dem Umbruch wurde eine Liste. Die Reihe
            // mit `min` bleibt so schmal wie der Inhalt, mindestens 48 dp,
            // und zentriert ihn darin.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AtemType.valueMedium.of(context).copyWith(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? AtemColors.textPrimary
                              : AtemColors.textTertiary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wahl: eine Kachel mit Symbolkasten und Wort, für Mehrfachwahl.
///
/// Mindestens 92 dp hoch. Die Breite setzt [AtemAnswerTileGrid].
class AtemAnswerTile extends StatelessWidget {
  const AtemAnswerTile({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    required this.glyph,
    this.glyphFill = AtemColors.surfaceSolid,
    this.glyphColor = AtemColors.textTertiary,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;
  final String glyph;
  final Color glyphFill;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    return _AnswerPress(
      label: semanticLabel,
      checked: selected,
      exclusive: false,
      onTap: onTap,
      radius: AtemRadii.statBox,
      child: _CheckCorner(
        selected: selected,
        size: 18,
        child: _Bloom(
          selected: selected,
          radius: AtemRadii.statBox,
          child: _SelectionSurface(
            selected: selected,
            radius: AtemRadii.statBox,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            constraints: const BoxConstraints(minHeight: 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _GlyphBox(glyph: glyph, fill: glyphFill, color: glyphColor),
                const SizedBox(height: 10),
                Text(label, style: _labelStyle(context, selected, 13.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Legt Kacheln in Zeilen, die ihre Breite füllen — wie `flex: 1 1 basis`.
///
/// Ein `Wrap` kennt kein Wachsen: Drei Kacheln à 84 dp liessen auf 328 dp
/// einen Streifen frei. Hier wird gezählt, wie viele Kacheln der
/// Mindestbreite [basis] in eine Zeile passen, und jede Zeile teilt ihre
/// Breite gleich auf — auch die letzte, kürzere. Bei 200 % Schrift werden
/// die Kacheln höher, nicht schmaler.
class AtemAnswerTileGrid extends StatelessWidget {
  const AtemAnswerTileGrid({
    super.key,
    required this.basis,
    required this.children,
    this.gap = 8,
  });

  final double basis;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final perRow =
          math.max(1, ((width + gap) / (basis + gap)).floor()).toInt();
      final rows = <List<Widget>>[
        for (var i = 0; i < children.length; i += perRow)
          children.sublist(i, math.min(i + perRow, children.length)),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows[r].length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    Expanded(child: rows[r][i]),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

/// Eine beantwortete oder offene Frage als Zeile — die gefaltete Form.
///
/// ## Beantwortet und offen sehen gleich aus
///
/// Gleiche Höhe, gleicher Chevron, gleiches Gewicht (Board 18, A2). Der
/// Unterschied ist ein gefüllter Punkt mit der Antwort in Weiss gegen einen
/// Ring mit dem Wort „Offen" in `#94A3B8`. Kein Zähler, keine Sortierung
/// nach „fehlt noch": Ein offenes Feld ist ein Zustand, kein Auftrag.
class AtemAnswerRow extends StatelessWidget {
  const AtemAnswerRow({
    super.key,
    required this.question,
    required this.answer,
    required this.openLabel,
    required this.glyph,
    required this.semanticLabel,
    required this.onTap,
  });

  /// Die Kurzform der Frage, etwa „Einheiten je Woche".
  final String question;

  /// Die Antwort in Kurzform, `null` = offen.
  final String? answer;

  /// Das Wort für „offen".
  final String openLabel;
  final String glyph;
  final String semanticLabel;
  final VoidCallback onTap;

  static const _glyphBox = 36.0;
  static const _chevronBox = 44.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final answered = answer != null;
    final questionStyle = AtemType.labelSmall.of(context).copyWith(
          fontSize: 12,
          color: AtemColors.textSecondary,
        );
    final answerStyle = AtemType.labelSmall.of(context).copyWith(
          fontSize: 14,
          color: answered ? AtemColors.textPrimary : AtemColors.textSecondary,
        );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(question, style: questionStyle),
        const SizedBox(height: 2),
        Text(answer ?? openLabel, style: answerStyle),
      ],
    );
    const chevron = SizedBox(
      width: _chevronBox,
      height: _chevronBox,
      child: Center(
        child: AtemGlyph(
          'M6 9l6 6 6-6',
          color: AtemColors.cyan,
          size: 18,
          strokeWidth: 2,
        ),
      ),
    );

    return _AnswerPress(
      label: semanticLabel,
      onTap: onTap,
      radius: 16,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.fromLTRB(14, 11, 4, 11),
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtemColors.border),
        ),
        // **Gemessen, nicht geraten.** Bei 200 % Schrift auf 320 dp bleiben
        // neben Symbol und Chevron rund 180 dp — „Wochenmuster" brach dort
        // mitten im Wort. Passt das längste Wort nicht in die Textspalte,
        // stehen Symbol und Chevron in einer eigenen Zeile darüber, und der
        // Text bekommt die volle Breite. Der Chevron bleibt oben rechts.
        child: LayoutBuilder(builder: (context, constraints) {
          final column = constraints.maxWidth - _glyphBox - _chevronBox - _gap;
          final scaler = MediaQuery.textScalerOf(context);
          final fits = _longestWord(question, questionStyle, scaler) <= column &&
              _longestWord(answer ?? openLabel, answerStyle, scaler) <= column;
          if (fits) {
            return Row(
              children: [
                _StatusGlyph(glyph: glyph, answered: answered),
                const SizedBox(width: _gap),
                Expanded(child: text),
                chevron,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _StatusGlyph(glyph: glyph, answered: answered),
                  const Spacer(),
                  chevron,
                ],
              ),
              const SizedBox(height: 6),
              Padding(padding: const EdgeInsets.only(right: 10), child: text),
            ],
          );
        }),
      ),
    );
  }

  static double _longestWord(String s, TextStyle style, TextScaler scaler) {
    var widest = 0.0;
    for (final word in s.split(RegExp(r'\s+'))) {
      final tp = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (tp.width > widest) widest = tp.width;
      tp.dispose();
    }
    return widest;
  }
}

/// Das Fragesymbol mit Statuspunkt an der Ecke: gefüllt = beantwortet,
/// Ring = offen. Punkt und Symbol sind dekorativ; „offen" steht im Label.
class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.glyph, required this.answered});

  final String glyph;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AtemColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AtemRadii.iconBox),
            ),
            alignment: Alignment.center,
            child: AtemGlyph(
              glyph,
              size: 18,
              strokeWidth: 1.8,
              color: answered
                  ? AtemColors.textPrimary
                  : AtemColors.textSecondary,
            ),
          ),
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: answered ? AtemColors.textTertiary : AtemColors.card,
                border: Border.all(
                  color: answered
                      ? AtemColors.textTertiary
                      : AtemColors.textSecondary,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(color: AtemColors.card, spreadRadius: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Eine Gruppe, die mit einer Antwort erscheint oder verschwindet.
///
/// **Öffnen ist langsamer als Schliessen** (320 gegen 240 ms): Neues soll
/// gelesen werden, Wegfallendes nur bemerkt. Schliessen blendet zuerst aus
/// und schrumpft dann — sonst sähe man Text zusammengequetscht. [delay]
/// versetzt Gruppen desselben Blocks um 40–60 ms.
///
/// Ganz geschlossen ist die Gruppe nicht gebaut: Sie trägt dann weder
/// Semantics noch Trefferflächen.
class AtemRevealGroup extends StatefulWidget {
  const AtemRevealGroup({
    super.key,
    required this.visible,
    required this.child,
    this.delay = Duration.zero,
  });

  final bool visible;
  final Widget child;
  final Duration delay;

  @override
  State<AtemRevealGroup> createState() => _AtemRevealGroupState();
}

class _AtemRevealGroupState extends State<AtemRevealGroup>
    with SingleTickerProviderStateMixin {
  static const _open = Duration(milliseconds: 320);
  static const _close = Duration(milliseconds: 300);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _open,
    reverseDuration: _close,
    value: widget.visible ? 1 : 0,
  )..addStatusListener((_) => setState(() {}));

  // Vorwärts: Höhe über die ganze Zeit, Deckkraft in den ersten 240 ms.
  // Rückwärts (t läuft 1 → 0): Deckkraft in den ersten 120 ms, Höhe ab 60 ms.
  late final Animation<double> _size = CurvedAnimation(
    parent: _c,
    curve: atemAnswerEase,
    reverseCurve: const Interval(0, 0.8, curve: Curves.easeOut),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.75, curve: Curves.easeOut),
    reverseCurve: const Interval(0.6, 1, curve: Curves.easeIn),
  );

  @override
  void didUpdateWidget(AtemRevealGroup old) {
    super.didUpdateWidget(old);
    if (old.visible == widget.visible) return;
    if (AtemMotion.reduced(context)) {
      _c.value = widget.visible ? 1 : 0;
      return;
    }
    if (widget.visible) {
      Future<void>.delayed(widget.delay, () {
        if (mounted && widget.visible) _c.forward();
      });
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c.isDismissed && !widget.visible) return const SizedBox.shrink();
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _size,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: _opacity, child: widget.child),
      ),
    );
  }
}

/// Die Lichtkante: ein Bogen Cyan → Hybrid-Ton läuft einmal um einen Block,
/// der gerade erscheint oder aufklappt. Danach steht der Standardrand.
///
/// **Keine Gradient-Karte** (Entscheidung 25): Sie markiert einen Moment,
/// keinen Rang, und ist nach 1,2 s weg. Jede Änderung von [trigger] startet
/// den Lauf neu; [delay] versetzt ihn in der Eintrittskaskade.
class AtemEdgeSweep extends StatefulWidget {
  const AtemEdgeSweep({
    super.key,
    required this.trigger,
    required this.radius,
    required this.child,
    this.delay = Duration.zero,
  });

  final Object trigger;
  final double radius;
  final Duration delay;
  final Widget child;

  @override
  State<AtemEdgeSweep> createState() => _AtemEdgeSweepState();
}

class _AtemEdgeSweepState extends State<AtemEdgeSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed && !_started) _run();
  }

  bool _started = false;

  void _run() {
    _started = true;
    if (AtemMotion.reduced(context)) return;
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(AtemEdgeSweep old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _run();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        if (t == 0 || t == 1) return child!;
        return CustomPaint(
          foregroundPainter: _SweepPainter(
            progress: _sweepEase.transform(t),
            opacity: t < 0.12 ? t / 0.12 : (t > 0.8 ? (1 - t) / 0.2 : 1),
            radius: widget.radius,
          ),
          child: child,
        );
      },
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter({
    required this.progress,
    required this.opacity,
    required this.radius,
  });

  final double progress;
  final double opacity;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(radius),
    );
    const clear = Color(0x0000F2FE);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        colors: [
          clear,
          clear,
          AtemColors.cyan.withValues(alpha: opacity),
          AtemColors.tabHybrid.withValues(alpha: opacity),
          AtemColors.tabHybrid.withValues(alpha: 0),
        ],
        stops: const [0, 230 / 360, 292 / 360, 332 / 360, 1],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SweepPainter old) =>
      old.progress != progress || old.opacity != opacity;
}

/// Der Speicher-Scan: Ein Lichtpunkt läuft über die Oberkante des Blocks,
/// dessen Antwort gerade geschrieben wurde. Er ersetzt ein Wort
/// „Gespeichert". Jede Änderung von [trigger] (ausser `null`) startet ihn.
class AtemSaveScan extends StatefulWidget {
  const AtemSaveScan({
    super.key,
    required this.trigger,
    required this.child,
    this.inset = 20,
  });

  final Object? trigger;
  final double inset;
  final Widget child;

  @override
  State<AtemSaveScan> createState() => _AtemSaveScanState();
}

class _AtemSaveScanState extends State<AtemSaveScan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  @override
  void didUpdateWidget(AtemSaveScan old) {
    super.didUpdateWidget(old);
    if (widget.trigger != null &&
        old.trigger != widget.trigger &&
        !AtemMotion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          left: widget.inset,
          right: widget.inset,
          top: -1,
          height: 2,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                if (t == 0 || t == 1) return const SizedBox.shrink();
                final p = atemAnswerEase.transform(t);
                return LayoutBuilder(builder: (context, c) {
                  final w = c.maxWidth * 0.34;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        left: -w + (c.maxWidth + w) * p,
                        width: w,
                        top: 0,
                        bottom: 0,
                        child: Opacity(
                          opacity: t < 0.85 ? 1 : (1 - t) / 0.15,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(colors: [
                                Color(0x0000F2FE),
                                AtemColors.cyan,
                                Color(0x0000F2FE),
                              ]),
                              boxShadow: AtemGlow.soft(AtemColors.cyan),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

// --- Gemeinsame Teile --------------------------------------------------------

TextStyle _labelStyle(BuildContext context, bool selected, double size) =>
    AtemType.labelSmall.of(context).copyWith(
          fontSize: size,
          height: 1.35,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AtemColors.textPrimary : AtemColors.textTertiary,
        );

/// Fläche einer Antwort: angehoben, gewählt Cyan getönt mit Cyan-Rand.
class _SelectionSurface extends StatelessWidget {
  const _SelectionSurface({
    required this.selected,
    required this.radius,
    required this.padding,
    required this.constraints,
    required this.child,
  });

  final bool selected;
  final double radius;
  final EdgeInsets padding;
  final BoxConstraints constraints;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AtemMotion.duration(context, const Duration(milliseconds: 200)),
      curve: Curves.easeOut,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: selected
            ? AtemColors.cyan.withValues(alpha: 0.08)
            : AtemColors.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: selected ? AtemColors.cyan : AtemColors.border,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

/// Symbolkasten 40 dp in der Farbe der Spur.
class _GlyphBox extends StatelessWidget {
  const _GlyphBox({
    required this.glyph,
    required this.fill,
    required this.color,
  });

  final String glyph;
  final Color fill;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AtemRadii.iconBox),
        ),
        alignment: Alignment.center,
        child: AtemGlyph(glyph, color: color),
      );
}

/// Ring 20 dp, Kern 10 dp mit Überschwinger: die einzige Bewegung, die
/// „das hast du gesagt" heisst.
class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AtemMotion.duration(context, const Duration(milliseconds: 200)),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AtemColors.cyan : AtemColors.textSecondary,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: AtemMotion.duration(context, _coreDuration),
        curve: Curves.easeOutBack,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AtemColors.cyan,
            boxShadow: [
              BoxShadow(
                color: AtemColors.cyan.withValues(alpha: 0.9),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Das Häkchen an der Ecke: Es poppt und zieht sich dann als Strich. Es ist
/// der Nicht-Farb-Träger von „gewählt" und darf deshalb auftreten.
class _CheckCorner extends StatelessWidget {
  const _CheckCorner({
    required this.selected,
    required this.size,
    required this.child,
  });

  final bool selected;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = AtemMotion.reduced(context);
    return Stack(
      clipBehavior: Clip.none,
      // Die Maße des Rasters durchreichen: Mit lockeren Maßen schrumpfte
      // eine Kachel auf ihren Inhalt, statt ihre Spalte zu füllen.
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          top: -6,
          right: -6,
          child: IgnorePointer(
            child: AnimatedScale(
              scale: selected ? 1 : 0,
              duration: reduced ? Duration.zero : _checkPop,
              curve: Curves.easeOutBack,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AtemColors.cyan,
                  boxShadow: [
                    BoxShadow(
                      color: AtemColors.cyan.withValues(alpha: 0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(selected),
                  tween: Tween(begin: selected && !reduced ? 0 : 1, end: 1),
                  duration: reduced ? Duration.zero : _checkDraw,
                  curve: const Interval(0.25, 1, curve: _drawEase),
                  builder: (context, t, _) => CustomPaint(
                    size: Size.square(size * 0.62),
                    painter: _CheckPainter(t),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);

  final double progress;
  static final _path = parseSvgPath('M5 12.5l4.2 4.2L19 7');

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.shortestSide / 24);
    final paint = Paint()
      ..color = AtemColors.onNeon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (progress >= 1) {
      canvas.drawPath(_path, paint);
      return;
    }
    final out = Path();
    var remaining =
        _path.computeMetrics().fold<double>(0, (s, m) => s + m.length) *
            progress;
    for (final m in _path.computeMetrics()) {
      if (remaining <= 0) break;
      out.addPath(m.extractPath(0, math.min(remaining, m.length)), Offset.zero);
      remaining -= m.length;
    }
    canvas.drawPath(out, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

/// Der Auswahl-Bloom: Cyan-Schein blüht aus der gewählten Fläche und löst
/// sich auf. Nur beim Wechsel auf „gewählt", nie im Ruhezustand.
class _Bloom extends StatefulWidget {
  const _Bloom({
    required this.selected,
    required this.radius,
    required this.child,
  });

  final bool selected;
  final double radius;
  final Widget child;

  @override
  State<_Bloom> createState() => _BloomState();
}

class _BloomState extends State<_Bloom> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: _bloomDuration);

  @override
  void didUpdateWidget(_Bloom old) {
    super.didUpdateWidget(old);
    if (!old.selected && widget.selected && !AtemMotion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final raw = _c.value;
        if (raw == 0 || raw == 1) return child!;
        final t = atemAnswerEase.transform(raw);
        // Bis 35 % wächst der Schein, danach klingt er aus.
        final glow = raw < 0.35 ? raw / 0.35 : (1 - raw) / 0.65;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: AtemColors.cyan.withValues(alpha: 0.6 * (1 - t)),
                spreadRadius: 10 * t,
              ),
              BoxShadow(
                color: AtemColors.cyan.withValues(alpha: 0.38 * glow),
                blurRadius: 28,
                spreadRadius: 4 * glow,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// Gedrückt = scale 0,97 + Cyan-Schein, 200 ms. Trägt die Rolle einer
/// Antwort — Radio oder Häkchen —, nicht die eines Knopfs.
class _AnswerPress extends StatefulWidget {
  const _AnswerPress({
    required this.label,
    required this.onTap,
    required this.radius,
    required this.child,
    this.checked,
    this.exclusive = false,
  });

  final String label;
  final VoidCallback onTap;
  final double radius;
  final Widget child;

  /// `null`: keine Wahl, sondern ein Knopf (die gefaltete Zeile).
  final bool? checked;
  final bool exclusive;

  @override
  State<_AnswerPress> createState() => _AnswerPressState();
}

class _AnswerPressState extends State<_AnswerPress> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AtemMotion.reduced(context);
    return Semantics(
      // Ein eigener Knoten je Antwort, auch ohne umgebende Liste.
      container: true,
      button: widget.checked == null,
      checked: widget.checked,
      inMutuallyExclusiveGroup: widget.exclusive ? true : null,
      label: widget.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed && !reduced ? 0.97 : 1,
            duration: AtemMotion.fast,
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                boxShadow: _pressed
                    ? [
                        BoxShadow(
                          color: AtemColors.cyan.withValues(alpha: 0.35),
                          blurRadius: 18,
                        ),
                      ]
                    : const [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
