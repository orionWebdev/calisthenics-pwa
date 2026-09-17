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
    this.titleStyle,
  });

  final String title;

  /// Die Sätze hinter dem ⓘ, je Eintrag ein Absatz. Leer → kein ⓘ.
  final List<String> explanation;

  /// Optional zwischen Titel und ⓘ, etwa „8 Wochen".
  final String? trailing;

  final TextStyle? titleStyle;

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  widget.title,
                  style: widget.titleStyle ?? AtemType.titleMedium.of(context),
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.trailing!,
                  textAlign: TextAlign.end,
                  style: AtemType.meta.of(context),
                ),
              ),
            ],
            if (hasExplanation)
              AtemTappable(
                onTap: () => setState(() => _open = !_open),
                semanticLabel: _open
                    ? l10n.explainCloseA11y(widget.title)
                    : l10n.explainOpenA11y(widget.title),
                selected: _open,
                child: SizedBox.square(
                  dimension: 32,
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
                        color:
                            _open ? AtemColors.cyan : AtemColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
}
