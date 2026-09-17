import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_l10n.dart';
import '../theme/theme.dart';
import 'atem_tappable.dart';

/// Kopf eines Blocks mit **aufklappbarer Erklärung**.
///
/// ## Warum es ihn gibt
///
/// Bis zum 17.09.2026 trug jeder Auswertungsblock fünf bis acht Textzeilen:
/// was er zeigt, wie er rechnet, eine Formel, ein „Kein Sollverhältnis". Beim
/// ersten Lesen nützlich, beim zwanzigsten nur Lärm — der Überblick ging
/// verloren (CLAUDE.md, „Text und Erklärungen").
///
/// Die Erklärung steht jetzt hinter einem ⓘ rechts neben dem Titel und klappt
/// **im Block** auf, nicht in einem Blatt: Seit alle Blätter die volle Höhe
/// haben, wäre ein Blatt für drei Sätze zu wuchtig, und man verlöre den Block
/// aus dem Blick, den die Sätze erklären.
///
/// ## Was nie hierher gehört
///
/// Die **Grundlage mit Nenner** („18 Sätze · 2 Einheiten"). Sie gehört zur
/// Zahl und bleibt sichtbar — sonst sieht ein Wert aus zwei Einheiten genauso
/// sicher aus wie einer aus zweihundert.
///
/// ## Layout (seit 17.09.2026)
///
/// Am Gerät brachen Titel um — „Einheiten je / Monat", sogar mitten im Wort
/// („Muskelbalanc / e") —, weil Titel und Zeitraum sich die Breite teilten.
/// Und Zeitraum und ⓘ standen irgendwo in der Mitte. Jetzt wird gemessen:
///
/// 1. **Passt alles in eine Zeile**, steht der Titel links ohne Umbruch, und
///    Zeitraum, ⓘ und [action] stehen **rechtsbündig** zusammen.
/// 2. **Sonst** hat der Titel Vorrang: Titel links, ⓘ/[action] rechts, der
///    Zeitraum rutscht linksbündig in die zweite Zeile.
/// 3. Erst wenn der Titel allein nicht passt (200 % Schrift auf 320 dp),
///    bricht er — an Wortgrenzen, nie im Wort.
///
/// ## Zustand
///
/// Zugeklappt ist die Ruhelage. Der Zustand lebt im Widget und überlebt den
/// Seitenwechsel über `AutomaticKeepAlive` der umgebenden Seite; er wird nicht
/// gespeichert.
class AtemExplainHeader extends StatefulWidget {
  const AtemExplainHeader({
    super.key,
    required this.title,
    required this.explanation,
    this.trailing,
    this.action,
    this.titleStyle,
  });

  final String title;

  /// Die Sätze hinter dem ⓘ, je Eintrag ein Absatz. Leer → kein ⓘ.
  final List<String> explanation;

  /// Optional zwischen Titel und ⓘ, etwa „8 Wochen".
  final String? trailing;

  /// Optional ganz rechts, etwa ein Chevron auf einer antippbaren Kachel.
  /// Dekorativ; die Kachel trägt die Semantik.
  final Widget? action;

  final TextStyle? titleStyle;

  /// Sichtbare Grösse des ⓘ-Knopfs; die Trefferfläche ist 48 dp.
  static const _iconBox = 32.0;
  static const _gap = 8.0;

  @override
  State<AtemExplainHeader> createState() => _AtemExplainHeaderState();
}

class _AtemExplainHeaderState extends State<AtemExplainHeader> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final hasExplanation = widget.explanation.isNotEmpty;
    final duration = AtemMotion.duration(context, AtemMotion.normal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) =>
              _headRow(context, constraints.maxWidth, l10n, duration),
        ),
        if (hasExplanation)
          // Bei „Animationen reduzieren" ist die Dauer null — AnimatedSize
          // verträgt das nicht (es mutiert sich im eigenen Layout). Dann
          // klappt die Erklärung ohne Übergang auf.
          duration == Duration.zero
              ? (_open ? _body(context) : const SizedBox.shrink())
              : AnimatedSize(
                  duration: duration,
                  curve: AtemMotion.curve,
                  alignment: Alignment.topCenter,
                  child: _open
                      ? _body(context)
                      : const SizedBox(width: double.infinity),
                ),
      ],
    );
  }

  Widget _body(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AtemColors.surfaceSolid,
            borderRadius: BorderRadius.circular(AtemRadii.iconBox),
            border: const Border(
              left: BorderSide(color: AtemColors.cyan, width: 2),
            ),
          ),
          child: Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.explanation.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  Text(
                    widget.explanation[i],
                    style: AtemType.labelSmall.of(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _headRow(
    BuildContext context,
    double maxWidth,
    AppL10n l10n,
    Duration duration,
  ) {
    final titleStyle = widget.titleStyle ?? AtemType.titleMedium.of(context);
    final metaStyle = AtemType.meta.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double widthOf(String text, TextStyle style) => (TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout())
            .width;

    final hasExplanation = widget.explanation.isNotEmpty;
    // Die Trefferfläche des ⓘ ragt unsichtbar über die sichtbare Box hinaus;
    // für die Zeile zählt die sichtbare Breite.
    final endWidth = (hasExplanation ? AtemExplainHeader._iconBox : 0) +
        (widget.action != null ? 24 + AtemExplainHeader._gap : 0);
    final trailingWidth = widget.trailing == null
        ? 0.0
        : widthOf(widget.trailing!, metaStyle) + AtemExplainHeader._gap;
    final titleWidth = widthOf(widget.title, titleStyle);

    final title = Semantics(
      header: true,
      child: Text(widget.title, style: titleStyle),
    );
    final end = <Widget>[
      if (hasExplanation) _infoButton(l10n, duration),
      if (widget.action != null) ...[
        const SizedBox(width: AtemExplainHeader._gap),
        ExcludeSemantics(child: widget.action!),
      ],
    ];
    final trailingText = widget.trailing == null
        ? null
        : Text(widget.trailing!, style: metaStyle, softWrap: false);

    // 1 — alles in einer Zeile, rechts gebündelt.
    if (titleWidth + AtemExplainHeader._gap + trailingWidth + endWidth <=
        maxWidth) {
      return Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(widget.title, style: titleStyle, softWrap: false),
            ),
          ),
          if (trailingText != null) ...[
            const SizedBox(width: AtemExplainHeader._gap),
            trailingText,
          ],
          if (end.isNotEmpty) ...[
            if (hasExplanation) const SizedBox(width: 4),
            ...end,
          ],
        ],
      );
    }

    // 2 und 3 — Titel hat Vorrang, Zeitraum darunter.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: title),
            if (end.isNotEmpty) ...[
              const SizedBox(width: AtemExplainHeader._gap),
              ...end,
            ],
          ],
        ),
        if (widget.trailing != null) ...[
          const SizedBox(height: 2),
          Text(widget.trailing!, style: metaStyle),
        ],
      ],
    );
  }

  Widget _infoButton(AppL10n l10n, Duration duration) => AtemTappable(
        onTap: () => setState(() => _open = !_open),
        semanticLabel: _open
            ? l10n.explainCloseA11y(widget.title)
            : l10n.explainOpenA11y(widget.title),
        selected: _open,
        child: SizedBox.square(
          dimension: AtemExplainHeader._iconBox,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              curve: AtemMotion.curve,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _open
                    ? AtemColors.cyan.withValues(alpha: 0.14)
                    : const Color(0x00000000),
                border: Border.all(
                  color: _open
                      ? AtemColors.cyan.withValues(alpha: 0.6)
                      : AtemColors.border,
                ),
              ),
              child: Icon(
                _open ? Icons.close : Icons.info_outline,
                size: 14,
                color: _open ? AtemColors.cyan : AtemColors.textSecondary,
              ),
            ),
          ),
        ),
      );
}
