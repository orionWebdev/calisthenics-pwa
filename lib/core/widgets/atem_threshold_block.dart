import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_l10n.dart';
import '../theme/theme.dart';
import 'atem_tab_theme.dart';

/// Die Fläche eines Auswertungsblocks.
///
/// **Nicht die Listenkarte.** Ein Auswertungsblock liegt auf dem
/// Bildschirmgrund (`#050507`) mit einer sehr leisen Kante (`#16161F`) statt
/// als aufgesetzte Karte — sieben Karten übereinander waren die graue Säule,
/// gegen die Modul 12 schon einmal angetreten ist.
///
/// Der Rand sagt, woran man ist: leise, solange der Block gesperrt ist, im
/// **Bereichston**, sobald er trägt. Das ist die einzige Farbe am Block, und
/// sie sagt „hier ist etwas zu holen" — nicht „gut" oder „schlecht".
class AtemAnalysisPanel extends StatelessWidget {
  const AtemAnalysisPanel({
    super.key,
    required this.child,
    this.unlocked = true,
    this.accent,
    this.padding = defaultPadding,
  });

  final Widget child;

  /// Trägt der Block Daten?
  final bool unlocked;

  /// `null` nimmt den Ton des Bereichs.
  final Color? accent;

  /// Blöcke mit randloser Darstellung (ein Chart bis an die Kante) setzen
  /// `EdgeInsets.zero` und polstern selbst.
  final EdgeInsetsGeometry padding;

  static const defaultPadding = EdgeInsets.all(18);

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? AtemTabTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AtemColors.base,
        borderRadius: AtemRadii.cardR,
        border: Border.all(
          color: unlocked
              ? tone.withValues(alpha: 0.35)
              : AtemColors.gridLine,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Welche Form der Block annehmen wird, sobald er trägt.
///
/// **An die Datenform gebunden, keine freie Wahl** (Board 13,
/// Entscheidung 10): Der Umriss ist die Silhouette der späteren Darstellung.
/// So lernt man die Form eines Blocks, bevor er Daten hat, und erkennt ihn
/// beim Freischalten wieder. Ein Umriss, der etwas anderes zeigt als das, was
/// kommt, lügt über die Form.
enum AtemThresholdShape {
  /// Trend über Zeit.
  curve,

  /// Vergleich diskreter Werte.
  bars,

  /// Textaussage.
  rows,

  /// Ein Wert mit Bezug.
  ring,
}

/// Ein Auswertungsblock **unter seiner Schwelle**.
///
/// ## Drei Dinge und keine vierte
///
/// 1. **Der Name** — derselbe wie im gefüllten Zustand, mit der Marke
///    „gesperrt" darüber.
/// 2. **Die Form dessen, was kommt** — als Umriss auf `#1A1A26`, ohne Achse,
///    ohne Zahl, ohne Beschriftung. Er behauptet damit keinen Wert, den er
///    nicht hat.
/// 3. **Die Bedingung mit Nenner** — „Ab 8 Einheiten · 5 von 8".
///
/// Er verschwindet nicht: Nach einem Neubeginn steht die ganze Auswertung als
/// Versprechen da statt als leerer Bildschirm.
///
/// ## Warum der Umriss nicht atmet
///
/// Ein Puls wäre das naheliegende „hier kommt noch was" — sähe aber genau aus
/// wie das Ladeskelett (gleiche Fläche, gleiche Geometrie) und müsste bei
/// „Animationen reduzieren" halb eingefroren stehen bleiben, was sich als
/// Renderfehler liest. Der gesperrte Block ist **statisch**; das Einzige, was
/// sich bewegt, ist der Fortschrittsbalken, und der nur, wenn sich Daten
/// ändern (Board 13, Entscheidung 9).
///
/// ## Kein Tap-Ziel, kein ⓘ
///
/// Es gibt nichts zu tun. Der Block ist Text für einen Screenreader, kein
/// Knopf; der Umriss ist von den Semantics ausgenommen.
class AtemThresholdBlock extends StatelessWidget {
  const AtemThresholdBlock({
    super.key,
    required this.title,
    required this.condition,
    required this.current,
    required this.required,
    this.accent,
    this.shape = AtemThresholdShape.curve,
  }) : assert(required > 0);

  /// Derselbe Titel wie im gefüllten Zustand.
  final String title;

  /// Ab wann er trägt — konkret, nicht „nach X Tagen".
  final String condition;

  final int current;
  final int required;

  /// `null` nimmt den Ton des Bereichs.
  final Color? accent;

  /// Die Form, die der Umriss vorzeichnet.
  final AtemThresholdShape shape;

  /// Höhe der Umrissfläche.
  static const outlineHeight = 54.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tone = accent ?? AtemTabTheme.of(context);
    final shown = current.clamp(0, required);

    return Semantics(
      container: true,
      // Kein Knopf: Es gibt keine Handlung.
      label: l10n.analysisLockedA11y(title, condition, shown, required),
      child: ExcludeSemantics(
        child: AtemAnalysisPanel(
          unlocked: false,
          accent: tone,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Das Board setzt die Marke auf 10 sp. Informationstragender
              // Text steht in dieser App bei mindestens 12 sp (CLAUDE.md),
              // und die Tokenregel geht dem Board vor — deshalb `labelMicro`.
              Text(l10n.analysisLockedBadge.toUpperCase(),
                  style: AtemType.labelMicro.of(context)),
              const SizedBox(height: 8),
              Text(
                title,
                style: AtemType.titleMedium
                    .of(context)
                    .copyWith(fontSize: 14, height: 1.2),
              ),
              const SizedBox(height: 12),
              _Outline(shape: shape),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(condition,
                        style: AtemType.labelSmall.of(context)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.thresholdProgress(shown, required),
                    style: AtemType.labelMicro.of(context).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _LockProgress(value: shown / required, tone: tone),
            ],
          ),
        ),
      ),
    );
  }
}

/// Die Silhouette dessen, was kommt — ohne Achse, ohne Zahl, ohne
/// Beschriftung.
class _Outline extends StatelessWidget {
  const _Outline({required this.shape});

  final AtemThresholdShape shape;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          height: AtemThresholdBlock.outlineHeight,
          decoration: BoxDecoration(
            color: AtemColors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(painter: _OutlinePainter(shape)),
        ),
      );
}

class _OutlinePainter extends CustomPainter {
  const _OutlinePainter(this.shape);

  final AtemThresholdShape shape;

  static const _stroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtemColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = AtemColors.border;

    final w = size.width;
    final h = size.height;
    final inset = w * 0.12;
    final usable = w - inset * 2;

    switch (shape) {
      case AtemThresholdShape.curve:
        // Ein Verlauf über die Zeit: fünf Stützstellen, kein Raster.
        const ys = [0.78, 0.40, 0.58, 0.18, 0.10];
        final path = Path();
        for (var i = 0; i < ys.length; i++) {
          final x = inset + usable * (i / (ys.length - 1));
          final y = h * 0.18 + h * 0.64 * ys[i];
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(path, paint);

      case AtemThresholdShape.bars:
        // Diskrete Werte nebeneinander, auf einer Grundlinie stehend.
        const heights = [0.55, 0.85, 0.40, 1.0, 0.65];
        const gap = 8.0;
        final barWidth =
            (usable - gap * (heights.length - 1)) / heights.length;
        final base = h - h * 0.22;
        for (var i = 0; i < heights.length; i++) {
          final x = inset + i * (barWidth + gap);
          final barHeight = (h * 0.56) * heights[i];
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, base - barHeight, barWidth, barHeight),
              const Radius.circular(3),
            ),
            fill,
          );
        }

      case AtemThresholdShape.rows:
        // Eine Aussage in Worten: zwei Zeilen, die zweite kürzer.
        const widths = [1.0, 0.64];
        for (var i = 0; i < widths.length; i++) {
          final y = h / 2 + (i == 0 ? -8 : 8);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(inset, y - 3, usable * widths[i], 6),
              const Radius.circular(3),
            ),
            fill,
          );
        }

      case AtemThresholdShape.ring:
        // Ein Wert mit Bezug: ein offener Ring.
        final radius = h * 0.30;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w / 2, h / 2), radius: radius),
          -2.2,
          4.4,
          false,
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_OutlinePainter old) => old.shape != shape;
}

/// Der Fortschritt zur Schwelle — 5 dp, und bei null ein Stummel statt
/// nichts.
///
/// Ein Balken, der bei null gar nicht sichtbar ist, sieht aus wie ein
/// fehlender Balken. Der Stummel in `#94A3B8` sagt „gemessen, aber noch
/// nichts" — und er trägt bewusst **nicht** den Bereichston, denn Fortschritt
/// gibt es noch keinen.
class _LockProgress extends StatelessWidget {
  const _LockProgress({required this.value, required this.tone});

  final double value;
  final Color tone;

  static const height = 5.0;

  @override
  Widget build(BuildContext context) {
    final share = value.clamp(0.0, 1.0);

    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AtemColors.track,
            borderRadius: BorderRadius.circular(height),
          ),
          child: share <= 0
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 2,
                    height: height,
                    decoration: BoxDecoration(
                      color: AtemColors.textSecondary,
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: share,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tone,
                        borderRadius: BorderRadius.circular(height),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
