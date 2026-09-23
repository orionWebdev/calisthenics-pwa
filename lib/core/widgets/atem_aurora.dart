import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'atem_glyph.dart';
import 'atem_tappable.dart';

/// Der Ort als Raum: „eine Ebene tiefer, in …" (Board 18b, Verb ORT, C7).
///
/// Zwei weiche Flächen im **Bereichston** und eine Violett-Fläche als Tiefe.
/// **Kein Cyan** — Cyan trägt Handlung und treibt nicht dekorativ hinter
/// einem Titel (G1). Grün ist heller als die anderen Töne und bekommt
/// weniger Deckkraft.
///
/// **Nur auf Unterseiten** (F4): Auf Hauptbildschirmen stehen Ortszeile und
/// Kicker für den Ort, die Aurora würde dort zur Tapete. Sie ist die einzige
/// dekorative Schleife der App (16 s) und steht bei „Animationen reduzieren"
/// still. Liegt eine Route darüber, hält `TickerMode` sie an.
///
/// Mit [moving] `false` steht sie von Anfang an — so trägt sie die
/// Bildfläche einer Plankarte, ohne eine Schleife in eine Kartenreihe zu
/// legen (entschieden am 23.09.2026).
class AtemAurora extends StatefulWidget {
  const AtemAurora({
    super.key,
    required this.tone,
    this.moving = true,
    this.spread = 1,
  });

  /// Der Bereichston — oder die Farbe der Körperregion auf einer Plankarte.
  /// `null`: Seiten ohne Bereich, nur die Violett-Fläche.
  final Color? tone;
  final bool moving;

  /// Wie weit die Flächen reichen, relativ zur Grösse. Der Kopf einer
  /// Unterseite ist 460 dp breit und kommt mit 1 aus; auf einer 260-dp-Karte
  /// zerfiele dasselbe Rezept in drei Flecken und braucht rund das Doppelte.
  final double spread;

  @override
  State<AtemAurora> createState() => _AtemAuroraState();
}

class _AtemAuroraState extends State<AtemAurora>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AtemMotion.dAurora);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.moving) {
      AtemMotion.syncLoop(context, _c, reverse: true, restingValue: 0.25);
    } else {
      _c.value = 0.25;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = _AuroraPainter(widget.tone, widget.spread);
    return IgnorePointer(
      child: ExcludeSemantics(
        // Einmal gemalt; die Bewegung ist eine Verschiebung der fertigen
        // Schicht, kein Neumalen (Board 18b, K).
        child: RepaintBoundary(
          child: widget.moving
              ? AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) {
                    final a = AtemMotion.drift.transform(_c.value) * 2 * math.pi;
                    return Transform.translate(
                      offset: Offset(12 * math.sin(a), 6 * math.cos(a)),
                      child: Transform.rotate(angle: 0.04 * math.sin(a), child: child),
                    );
                  },
                  child: CustomPaint(painter: painter, size: Size.infinite),
                )
              : CustomPaint(painter: painter, size: Size.infinite),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.tone, this.spread);

  final Color? tone;
  final double spread;

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset center, Size r, Color c) {
      final rect = Rect.fromCenter(
          center: center,
          width: r.width * 2 * spread,
          height: r.height * 2 * spread);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [c, c.withValues(alpha: 0)],
            stops: const [0, 0.7],
          ).createShader(rect),
      );
    }

    final w = size.width, h = size.height;
    final t = tone;
    if (t != null) {
      final green = t == AtemColors.green;
      blob(Offset(w * 0.24, h * 0.58), Size(w * 0.34, h * 0.36),
          t.withValues(alpha: green ? 0.16 : 0.22));
      blob(Offset(w * 0.78, h * 0.40), Size(w * 0.42, h * 0.40),
          t.withValues(alpha: green ? 0.09 : 0.12));
    }
    blob(Offset(w * 0.52, h * 0.88), Size(w * 0.40, h * 0.34),
        AtemColors.violet.withValues(alpha: 0.26));
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.tone != tone || old.spread != spread;
}

/// Der Titelglanz: Weiss → Bereichston → Weiss wandert einmal durch den
/// Titel, **nur beim Push**, nicht bei der Rückkehr (Board 18b, C7). Danach
/// ist er nicht mehr im Baum — der `ShaderMask` kostet eine Schicht und darf
/// nur 1,4 s existieren (K).
class AtemTitleSheen extends StatefulWidget {
  const AtemTitleSheen({super.key, required this.tone, required this.child});

  final Color? tone;
  final Widget child;

  @override
  State<AtemTitleSheen> createState() => _AtemTitleSheenState();
}

class _AtemTitleSheenState extends State<AtemTitleSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AtemMotion.dSheen)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) setState(() {});
        });
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || AtemMotion.reduced(context)) return;
    _started = true;
    Future<void>.delayed(AtemMotion.dSheenDelay, () {
      if (mounted) setState(() => _c.forward());
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.isAnimating) return widget.child;
    final tone = widget.tone ?? AtemColors.violetLight;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final p = AtemMotion.travel.transform(_c.value);
          final c = -0.2 + p * 1.4;
          return LinearGradient(
            colors: [
              const Color(0x00FFFFFF),
              tone,
              const Color(0x00FFFFFF),
            ],
            stops: [
              (c - 0.12).clamp(0, 1),
              c.clamp(0, 1),
              (c + 0.12).clamp(0, 1),
            ],
          ).createShader(rect);
        },
        child: child,
      ),
    );
  }
}

/// Die Kopfleiste einer Unterseite: Zurück und der Ort als Kicker
/// („KRAFT · ÜBUNG"). Der einzige `BackdropFilter` der Seite — die Aurora
/// dahinter wird von ihm mitgeblurrt, wenn sie darunter wegscrollt.
///
/// **Sie wächst mit der Schrift, statt abzuschneiden.** 56 dp ist die
/// Grundhöhe; bei 200 % auf 320 dp bricht der Kicker in zwei Zeilen, und die
/// Leiste wird so hoch, wie er es braucht. Der Kicker-Punkt ist flach, ohne
/// Schein (Board 18b, G6).
class AtemSubpageBar extends SliverPersistentHeaderDelegate {
  /// Misst Statusleiste und Kicker im Kontext der Seite.
  factory AtemSubpageBar.of(
    BuildContext context, {
    required String kicker,
    required String backLabel,
    Color? tone,
  }) =>
      AtemSubpageBar._(
        kicker: kicker,
        backLabel: backLabel,
        tone: tone,
        top: MediaQuery.paddingOf(context).top,
        height: _heightFor(context, kicker),
      );

  AtemSubpageBar._({
    required this.kicker,
    required this.backLabel,
    required this.tone,
    required double top,
    required double height,
  })  : _top = top,
        _height = height;

  final String kicker;
  final String backLabel;
  final Color? tone;
  final double _top;
  final double _height;

  static const _base = 56.0;

  /// Links 4 + Zurück 48 + 4 + Punkt 6 + 8, rechts 16.
  static const _reserved = 4 + 48 + 4 + 6 + 8 + 16.0;

  static double _heightFor(BuildContext context, String kicker) {
    final tp = TextPainter(
      text: TextSpan(text: kicker, style: AtemType.labelMicro.of(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: MediaQuery.sizeOf(context).width - _reserved);
    final needed = tp.height + 24;
    tp.dispose();
    return math.max(_base, needed);
  }

  @override
  double get minExtent => _top + _height;
  @override
  double get maxExtent => _top + _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final color = tone ?? AtemColors.textSecondary;
    // Die Leiste füllt ihre Ausdehnung ganz — sonst beansprucht der Kopf im
    // Scroller mehr Höhe, als er malt, und die Sliver-Geometrie ist ungültig.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: maxExtent,
          padding: EdgeInsets.only(top: _top, left: 4, right: 16),
          decoration: BoxDecoration(
            color: AtemColors.base.withValues(alpha: 0.82),
            border: const Border(bottom: BorderSide(color: AtemColors.border)),
          ),
          child: Row(
            children: [
              AtemTappable(
                semanticLabel: backLabel,
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: AtemGlyph('M15 5l-7 7 7 7',
                        color: AtemColors.cyan, size: 20, strokeWidth: 2),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              ExcludeSemantics(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  kicker,
                  style: AtemType.labelMicro.of(context).copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(AtemSubpageBar old) =>
      old._top != _top ||
      old._height != _height ||
      old.kicker != kicker ||
      old.backLabel != backLabel ||
      old.tone != tone;
}

/// Titelbereich einer Unterseite: Aurora dahinter, Titel mit einmaligem
/// Glanz davor. Die Aurora ragt 64 dp nach oben unter die Kopfleiste und
/// wird dort mitgeblurrt.
class AtemSubpageTitle extends StatelessWidget {
  const AtemSubpageTitle({
    super.key,
    required this.tone,
    required this.title,
    this.below = const [],
  });

  final Color? tone;

  /// Der Titel — meist ein `AtemExplainHeader` oder ein `Text`.
  final Widget title;

  /// Hinweis- und Metazeilen unter dem Titel.
  final List<Widget> below;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -50,
          right: -50,
          top: -64,
          height: 200,
          child: AtemAurora(tone: tone),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ein schlichter Text wird hier zur Überschrift. Ein
              // `AtemExplainHeader` markiert seinen Titel selbst — eine
              // Überschrift darum schluckte sonst sein ⓘ in einen Knoten.
              if (title is Text)
                Semantics(
                  header: true,
                  child: AtemTitleSheen(tone: tone, child: title),
                )
              else
                AtemTitleSheen(tone: tone, child: title),
              ...below,
            ],
          ),
        ),
      ],
    );
  }
}

/// Eine Unterseite mit dem Kopf aus Board 18b, C7: Glasleiste mit Kicker,
/// Aurora im Bereichston hinter dem Titel, einmaliger Titelglanz beim Push.
///
/// [children] sind der Inhalt unter dem Titel, als Liste wie in einem
/// `ListView` — die Seite scrollt als Ganzes, und die Aurora wandert unter
/// die Leiste, wo deren `BackdropFilter` sie mitblurrt. Einen zweiten Filter
/// gibt es nicht.
class AtemSubpageScaffold extends StatelessWidget {
  const AtemSubpageScaffold({
    super.key,
    required this.kicker,
    required this.backLabel,
    required this.tone,
    required this.title,
    required this.children,
    this.below = const [],
    this.padding = const EdgeInsets.fromLTRB(
        AtemSpacing.screenPadding, 16, AtemSpacing.screenPadding, 40),
  });

  /// „KRAFT · ÜBUNG" — der Ort als Wort, in Versalien.
  final String kicker;
  final String backLabel;

  /// Der Bereichston; `null` für Seiten ohne Bereich.
  final Color? tone;

  /// Der Titel — ein `Text` oder ein `AtemExplainHeader`.
  final Widget title;

  /// Hinweis- und Metazeilen direkt unter dem Titel.
  final List<Widget> below;

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AtemColors.base,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: AtemSubpageBar.of(
              context,
              kicker: kicker,
              backLabel: backLabel,
              tone: tone,
            ),
          ),
          SliverToBoxAdapter(
            child: AtemSubpageTitle(tone: tone, title: title, below: below),
          ),
          SliverPadding(
            padding: padding.copyWith(
              bottom: padding.bottom + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.list(children: children),
          ),
        ],
      ),
    );
  }
}

/// Die Aurora hinter einem vorhandenen Kopf — für Unterseiten, deren Kopf
/// ein eigener Entwurf ist (Übungsdetail, Board 09; Einheitendetail,
/// Board 16). Sie ragt 64 dp nach oben und 50 dp zu den Seiten hinaus und
/// liegt hinter dem Inhalt; Semantics und Treffer gehen durch.
class AtemAuroraBehind extends StatelessWidget {
  const AtemAuroraBehind({super.key, required this.tone, required this.child});

  final Color? tone;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -50,
            right: -50,
            top: -64,
            height: 200,
            child: AtemAurora(tone: tone),
          ),
          child,
        ],
      );
}
