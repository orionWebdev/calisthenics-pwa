import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'atem_button.dart';
import 'atem_card.dart';
import 'atem_split.dart';
import 'atem_states.dart';
import 'atem_status_dot.dart';
import 'atem_tab_theme.dart';
import 'atem_tappable.dart';

/// **Der Startblock** — ein Gegenstand mit drei Zonen (Board 17, Abschnitt B).
///
/// ## Warum ein Gegenstand statt drei Karten
///
/// Bis zum 21.09.2026 stapelte „Trainieren" drei gleichberechtigte Bauformen:
/// eine Karte mit Gradient-Rand, zwei Halbkarten, zwei Zeilen mit Chevron.
/// Inhaltlich war die Rangfolge richtig — visuell waren es drei Objekte mit
/// drei Rändern und drei Radien, und keines sagte, wo man anfängt.
///
/// Daraus wird **ein** Gegenstand mit Kopf, Knopf und Fuss. Die Rangfolge
/// nach Häufigkeit bleibt exakt erhalten; sie wird nur nicht mehr durch
/// Kartengrenzen ausgedrückt, sondern durch Fläche, Grösse und Lage
/// innerhalb einer Karte. Ein Rand statt drei, ein Blickziel statt drei.
///
/// ## Der Zustand steckt im Kopf, nie in der Komposition
///
/// Karte, Position und Knopf sind in allen Zuständen identisch — mit Plan,
/// ohne Plan, beim Laden, im Fehlerfall und bei der Erstöffnung. Verglichen
/// wird immer nur der [head], und ein Kopf, der eine andere Tatsache trägt,
/// ist kein Loch. Hätte der Fall ohne Plan ein anderes Raster, wäre er
/// erkennbar die zweite Wahl (Entscheidung 2).
///
/// Ohne Kopf beginnt die Karte eben beim Knopf. Keine Platzhalterkarte, kein
/// „Heute nichts geplant": Das behauptete einen Mangel und rendete einen
/// Block ohne Daten (Entscheidung 3).
///
/// ## Der Knopf ist der Zustandsträger
///
/// „STARTEN" mit Plan, „FREI STARTEN" ohne. Damit bekommt niemand etwas
/// anderes, als er erwartet, und der Zustand bleibt lesbar, wenn der Kopf
/// noch lädt oder vorgelesen wird. **Nie ausgegraut**: Frei starten braucht
/// keine einzige geladene Zeile, und ein deaktivierter Startknopf behauptete
/// eine Abhängigkeit, die es nicht gibt (Entscheidung 7).
///
/// ## Der Fuss wiederholt nie die Handlung des Knopfs
///
/// Zwei Tap-Ziele auf angehobener Fläche, innerhalb derselben Karte. Rechts
/// steht, was auch eine Einheit erzeugt (Nachtragen); links das, was der
/// Knopf gerade **nicht** tut. Bei enger Breite oder grosser Schrift stapeln
/// die Hälften zu zwei vollbreiten Zeilen — die Karte wächst, die Ordnung
/// bleibt.
class AtemStartBlock extends StatelessWidget {
  const AtemStartBlock({
    super.key,
    this.head,
    required this.ctaLabel,
    required this.ctaSemanticLabel,
    required this.onStart,
    required this.footLeft,
    required this.footRight,
  });

  /// `null` heisst Erstöffnung: kein Plan, kein Verlauf, kein Kopf.
  final AtemStartHead? head;

  /// „STARTEN" oder „FREI STARTEN" — der Aufrufer schreibt sie in Versalien.
  final String ctaLabel;
  final String ctaSemanticLabel;
  final VoidCallback onStart;

  final AtemStartFoot footLeft;
  final AtemStartFoot footRight;

  /// Höhe des Knopfs und jeder Fusshälfte.
  static const ctaHeight = 56.0;

  /// Innenabstand um den Knopf.
  static const gutter = 16.0;

  @override
  Widget build(BuildContext context) {
    final filling = head;

    return AtemCard.gradientBorder(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filling != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(gutter, gutter, gutter, 0),
              child: filling._build(context),
            ),
          Padding(
            padding: const EdgeInsets.all(gutter),
            child: SizedBox(
              height: ctaHeight,
              child: AtemButton.gradient(
                // **Der Marken-CTA bleibt der Magenta-Verlauf.** Die
                // Neonwelle trägt Daten, nicht Handlungen.
                gradient: AtemGradients.brandCta,
                label: ctaLabel,
                semanticLabel: ctaSemanticLabel,
                onPressed: onStart,
              ),
            ),
          ),
          _Foot(left: footLeft, right: footRight),
        ],
      ),
    );
  }
}

/// Eine der Füllungen des Kopfs — **vier Tatsachen, eine Zone**.
@immutable
class AtemStartHead {
  /// Eine überprüfbare Tatsache: der Plan für heute oder die letzte Einheit.
  ///
  /// [toned] trägt den Bereichston und heisst genau eine Sache: dass für
  /// heute etwas ansteht. Trüge „ZULETZT" dasselbe Amber, hiesse Amber
  /// nichts mehr (Entscheidung 4).
  const AtemStartHead.fact({
    required this.kicker,
    required this.title,
    required this.semanticLabel,
    this.meta,
    this.toned = false,
  })  : _kind = _HeadKind.fact,
        retryLabel = null,
        onRetry = null;

  /// Es lädt — nur der Kopf, nie der ganze Bildschirm.
  const AtemStartHead.loading({required this.semanticLabel})
      : _kind = _HeadKind.loading,
        kicker = null,
        title = null,
        meta = null,
        toned = false,
        retryLabel = null,
        onRetry = null;

  /// Der Plan liess sich nicht lesen. **Betroffen ist eine Zone von dreien**
  /// — ein Vollbild-Fehler hätte einen funktionsfähigen Bildschirm für eine
  /// fehlende Zeile stillgelegt (Entscheidung 8).
  const AtemStartHead.failed({
    required this.kicker,
    required this.title,
    required this.semanticLabel,
    required this.retryLabel,
    required this.onRetry,
    this.meta,
  })  : _kind = _HeadKind.failed,
        toned = false;

  final _HeadKind _kind;
  final String? kicker;
  final String? title;
  final String? meta;
  final bool toned;
  final String? retryLabel;
  final VoidCallback? onRetry;

  /// Kicker, Titel und Metazeile werden als **ein** Knoten gelesen.
  final String semanticLabel;

  /// Höhe der drei Skelettbalken — in der Geometrie des Zielinhalts.
  static const _skeleton = [
    AtemSkeletonBlock(height: 9, radius: 4),
    AtemSkeletonBlock(height: 13, radius: 4),
    AtemSkeletonBlock(height: 9, radius: 4),
  ];

  Widget _build(BuildContext context) {
    if (_kind == _HeadKind.loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: AtemSkeleton(
          blocks: _skeleton,
          spacing: 8,
          semanticLabel: semanticLabel,
        ),
      );
    }

    final failed = _kind == _HeadKind.failed;
    final tone = failed
        ? AtemColors.magenta
        : toned
            ? AtemTabTheme.of(context)
            : AtemColors.textSecondary;

    final action = onRetry;
    final label = retryLabel;

    return Semantics(
      label: semanticLabel,
      liveRegion: failed,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AtemStatusDot(color: tone, size: AtemDotSize.medium),
                    const SizedBox(width: 6),
                    // `Flexible`: Bei 200 % auf 320 dp ist „HEUTE GEPLANT"
                    // mit seiner Sperrung breiter als die Karte.
                    Flexible(
                      child: Text(
                        kicker!.toUpperCase(),
                        style: AtemType.labelMicro
                            .of(context)
                            .copyWith(color: tone),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Zweizeilig umbrechen ist erlaubt, ellipsieren nicht.
                Text(title!, style: AtemType.titleMedium.of(context)),
                if (meta != null) ...[
                  const SizedBox(height: 3),
                  Text(meta!, style: AtemType.meta.of(context)),
                ],
              ],
            ),
          ),
          if (action != null && label != null)
            // Eine Handlung ist cyan — auch die im Fehlerkopf.
            AtemTappable(
              onTap: action,
              semanticLabel: label,
              minTapSize: const Size(0, 48),
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: AtemType.labelSmall.of(context).copyWith(
                          color: AtemColors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _HeadKind { fact, loading, failed }

/// Eine Hälfte des Fusses.
@immutable
class AtemStartFoot {
  const AtemStartFoot({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Der Fuss — angehobene Fläche **innerhalb** derselben Karte.
///
/// Keine neue Flächenebene: `surfaceRaised` ist dieselbe Fläche wie das
/// Innere einer StatBox (Modul 3).
class _Foot extends StatelessWidget {
  const _Foot({required this.left, required this.right});

  final AtemStartFoot left;
  final AtemStartFoot right;

  /// Gestapelt wächst jede Hälfte — sonst stünde das Wort bei 200 % im Rand.
  static const stackedHeight = 72.0;

  @override
  Widget build(BuildContext context) => ClipRRect(
        // Der Fuss sitzt an der Unterkante der Karte und muss deren
        // Innenradius mitnehmen, sonst steht seine Fläche über die Rundung
        // hinaus.
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AtemRadii.card - 1.5),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacks = AtemSplit.stacksIn(context, constraints.maxWidth,
                gap: 0);
            final height =
                stacks ? stackedHeight : AtemStartBlock.ctaHeight;

            final halves = [
              _FootHalf(item: left, height: height),
              _FootHalf(item: right, height: height),
            ];

            return DecoratedBox(
              decoration: const BoxDecoration(
                color: AtemColors.surfaceRaised,
                border: Border(top: BorderSide(color: AtemColors.border)),
              ),
              child: stacks
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        halves[0],
                        const _Rule(vertical: false),
                        halves[1],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: halves[0]),
                        _Rule(vertical: true, height: height),
                        Expanded(child: halves[1]),
                      ],
                    ),
            );
          },
        ),
      );
}

class _Rule extends StatelessWidget {
  const _Rule({required this.vertical, this.height});

  final bool vertical;
  final double? height;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: vertical ? 1 : double.infinity,
        height: vertical ? height : 1,
        child: const ColoredBox(color: AtemColors.border),
      );
}

class _FootHalf extends StatelessWidget {
  const _FootHalf({required this.item, required this.height});

  final AtemStartFoot item;
  final double height;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: item.onTap,
        semanticLabel: item.label,
        minTapSize: Size(0, height),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 20, color: AtemColors.cyan),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.label,
                    style: AtemType.labelSmall.of(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
