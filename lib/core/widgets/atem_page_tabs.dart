import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_l10n.dart';
import '../theme/theme.dart';
import 'atem_tappable.dart';

/// Reiterleiste für **wischbare Seiten** — gekoppelt an einen [PageController].
///
/// ## Warum nicht [AtemTabSwitch]
///
/// Der Umschalter hat genau zwei Seiten und springt. Seit dem 16.09.2026 hat
/// der Kraft-Tab vier Seiten, die man mit dem Finger wechselt: Trainieren,
/// Verlauf, Auswertung, Pläne. Vier Pillen passen bei 200 % Schrift auf
/// 320 dp nicht in eine Zeile, und ein Umschalter, der erst nach dem
/// Loslassen reagiert, fühlt sich beim Wischen tot an.
///
/// ## Der Indikator folgt dem Finger
///
/// Position und Breite der hellen Pille werden **aus `controller.page`**
/// zwischen zwei Reitern interpoliert — bei 1,4 steht sie zu 40 % auf dem
/// Weg von „Verlauf" zu „Auswertung" und hat eine Breite zwischen beiden.
/// Die Schriftfarbe blendet im selben Takt von Grau zu Cyan. So sieht man
/// während der Geste, wohin sie führt, und nicht erst danach.
///
/// Die Leiste scrollt den Reiter, auf dem die Seite landet, von selbst in
/// Sicht. Bei „Animationen reduzieren" springen Seite und Leiste.
class AtemPageTabs extends StatefulWidget {
  const AtemPageTabs({
    super.key,
    required this.controller,
    required this.labels,
    required this.groupSemanticLabel,
    this.horizontalPadding = AtemSpacing.screenPadding,
  });

  final PageController controller;
  final List<String> labels;

  /// Benennt die Gruppe: „Kraft-Seiten".
  final String groupSemanticLabel;

  /// Seitlicher Abstand der ersten und letzten Pille. Die Leiste selbst
  /// läuft bis an den Bildschirmrand, damit man sieht, dass sie weitergeht.
  final double horizontalPadding;

  static const visibleHeight = 36.0;
  static const _gap = 8.0;

  /// Dauer eines Seitenwechsels nach einem Tipp.
  static const pageDuration = Duration(milliseconds: 300);

  @override
  State<AtemPageTabs> createState() => _AtemPageTabsState();
}

class _AtemPageTabsState extends State<AtemPageTabs> {
  final _scroll = ScrollController();
  final _stackKey = GlobalKey();
  late List<GlobalKey> _tabKeys;

  /// Gemessene Pillen relativ zum Stapel. Leer bis zum ersten Layout.
  List<Rect> _rects = const [];

  int _landed = 0;

  @override
  void initState() {
    super.initState();
    _tabKeys = [for (final _ in widget.labels) GlobalKey()];
    _landed = widget.controller.initialPage;
    widget.controller.addListener(_onPage);
  }

  @override
  void didUpdateWidget(AtemPageTabs old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onPage);
      widget.controller.addListener(_onPage);
    }
    if (old.labels.length != widget.labels.length) {
      _tabKeys = [for (final _ in widget.labels) GlobalKey()];
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPage);
    _scroll.dispose();
    super.dispose();
  }

  double get _page {
    final c = widget.controller;
    if (c.hasClients && c.position.hasContentDimensions) {
      return c.page ?? c.initialPage.toDouble();
    }
    return c.initialPage.toDouble();
  }

  void _onPage() {
    final nearest = _page.round().clamp(0, widget.labels.length - 1);
    if (nearest != _landed) {
      _landed = nearest;
      _revealTab(nearest);
    }
  }

  void _revealTab(int index) {
    final ctx = _tabKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: AtemMotion.duration(context, AtemMotion.normal),
      curve: AtemMotion.curve,
    );
  }

  /// Misst die Pillen nach dem Layout. Neue Schriftgrösse, neue Breiten.
  void _measure() {
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || !stack.hasSize) return;
    final rects = <Rect>[];
    for (final key in _tabKeys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final origin = box.localToGlobal(Offset.zero, ancestor: stack);
      rects.add(origin & box.size);
    }
    if (!_sameRects(rects, _rects)) setState(() => _rects = rects);
  }

  static bool _sameRects(List<Rect> a, List<Rect> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i].left - b[i].left).abs() > 0.5 ||
          (a[i].width - b[i].width).abs() > 0.5 ||
          (a[i].height - b[i].height).abs() > 0.5) {
        return false;
      }
    }
    return true;
  }

  void _select(int index) {
    final c = widget.controller;
    if (!c.hasClients) return;
    if (AtemMotion.reduced(context)) {
      c.jumpToPage(index);
    } else {
      c.animateToPage(
        index,
        duration: AtemPageTabs.pageDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });

    final l10n = AppL10n.of(context);
    final total = widget.labels.length;

    return Semantics(
      container: true,
      label: widget.groupSemanticLabel,
      explicitChildNodes: true,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final page = _page.clamp(0.0, (total - 1).toDouble());
            final selected = page.round();

            return Stack(
              key: _stackKey,
              clipBehavior: Clip.none,
              children: [
                if (_rects.length == total) _indicator(page),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < total; i++) ...[
                      if (i > 0) const SizedBox(width: AtemPageTabs._gap),
                      _Tab(
                        pillKey: _tabKeys[i],
                        label: widget.labels[i],
                        semanticLabel: l10n.pageTabA11y(
                            widget.labels[i], i + 1, total),
                        selected: i == selected,
                        // 1 auf dem Reiter, 0 ab einer Seite Abstand.
                        activity: (1 - (page - i).abs()).clamp(0.0, 1.0),
                        onTap: () => _select(i),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _indicator(double page) {
    final from = page.floor().clamp(0, _rects.length - 1);
    final to = page.ceil().clamp(0, _rects.length - 1);
    final t = page - page.floor();
    final rect = Rect.lerp(_rects[from], _rects[to], t)!;

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AtemColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AtemRadii.pill),
              border:
                  Border.all(color: AtemColors.cyan.withValues(alpha: 0.35)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.pillKey,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.activity,
    required this.onTap,
  });

  final GlobalKey pillKey;
  final String label;
  final String semanticLabel;
  final bool selected;

  /// 0 bis 1 — wie nah die Seite gerade an diesem Reiter steht.
  final double activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        Color.lerp(AtemColors.textSecondary, AtemColors.cyan, activity)!;

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      minTapSize: const Size(48, 48),
      child: Container(
        key: pillKey,
        constraints:
            const BoxConstraints(minHeight: AtemPageTabs.visibleHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Der ruhende Reiter trägt einen feinen Rand; der Indikator liegt
        // darunter und übernimmt beim aktiven.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(
            color: AtemColors.border.withValues(alpha: 1 - activity),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AtemType.labelUi.of(context).copyWith(
                color: color,
                fontWeight: activity > 0.5 ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
