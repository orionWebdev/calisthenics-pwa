import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';

/// Kopfzeile des Runners: Laufzeit links, zwei Aktionen rechts.
///
/// Die Icon-Buttons bleiben sichtbar 40×40, ihre Trefferfläche wächst
/// unsichtbar auf 48. Die Zentren rücken damit von 48 auf 56 dp Abstand — der
/// sichtbare Zwischenraum bleibt gleich, weil die Lücke von 8 auf 0 fällt.
///
/// **Ohne Notizen** (seit 18.09.2026): Der dritte Knopf öffnete ein Blatt für
/// eine Session-Notiz. Sie wurde nicht gebraucht und kostete im Training den
/// Platz und die Aufmerksamkeit, die Pause und Beenden brauchen.
class SessionTopBar extends StatelessWidget {
  const SessionTopBar({
    super.key,
    required this.elapsed,
    required this.paused,
    required this.onTogglePause,
    required this.onEnd,
    this.amending = false,
  });

  /// Wird eine bestehende Einheit ergänzt statt trainiert?
  ///
  /// Dann läuft keine Uhr. Beim Nachtragen von Sätzen zu einer Einheit von
  /// vorletzter Woche ist eine mitlaufende Zeit nicht nur bedeutungslos —
  /// sie behauptet, gerade werde trainiert.
  final bool amending;

  final String elapsed;
  final bool paused;
  final VoidCallback onTogglePause;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            // Laufzeit als ein Knoten, nicht "SESSION" und dann "04:12".
            label: amending
                ? l10n.setsAdd
                : '${l10n.workoutRunnerSessionLabel} $elapsed',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amending
                        ? l10n.sessionEditTitle
                        : l10n.workoutRunnerSessionLabel,
                    style: AtemType.labelMicro.of(context),
                  ),
                  const SizedBox(height: 2),
                  if (amending)
                    Text(l10n.setsAdd,
                        style: AtemType.titleMedium.of(context))
                  else
                    Row(
                      children: [
                        AtemStatusDot(
                          color: paused
                              ? AtemColors.textSecondary
                              : AtemColors.green,
                          pulsing: !paused,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            elapsed,
                            style: AtemType.valueLarge.of(context).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        // Pause gibt es nur, wo etwas läuft.
        if (!amending)
          _IconAction(
            glyph: paused ? _Glyph.play : _Glyph.pause,
            semanticLabel:
                paused ? l10n.workoutA11yResume : l10n.workoutA11yPause,
            tint: paused ? AtemColors.green : AtemColors.textSecondary,
            onTap: onTogglePause,
          ),
        _IconAction(
          glyph: _Glyph.close,
          semanticLabel: amending ? l10n.commonSave : l10n.workoutA11yEnd,
          tint: amending ? AtemColors.cyan : AtemColors.magenta,
          background: (amending ? AtemColors.cyan : AtemColors.magenta)
              .withValues(alpha: 0.10),
          border: (amending ? AtemColors.cyan : AtemColors.magenta)
              .withValues(alpha: 0.45),
          onTap: onEnd,
        ),
      ],
    );
  }
}

enum _Glyph { pause, play, close }

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.glyph,
    required this.semanticLabel,
    required this.tint,
    required this.onTap,
    this.background,
    this.border,
  });

  final _Glyph glyph;
  final String semanticLabel;
  final Color tint;
  final VoidCallback onTap;
  final Color? background;
  final Color? border;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background ?? AtemColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border ?? AtemColors.border),
          ),
          child: CustomPaint(
            size: const Size.square(19),
            painter: _GlyphPainter(glyph, tint),
          ),
        ),
      );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);
  final _Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    switch (glyph) {
      case _Glyph.pause:
        canvas.drawLine(Offset(s * 0.32, s * 0.2), Offset(s * 0.32, s * 0.8),
            paint..strokeWidth = s * 0.16);
        canvas.drawLine(
            Offset(s * 0.68, s * 0.2), Offset(s * 0.68, s * 0.8), paint);
      case _Glyph.play:
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.28, s * 0.18)
            ..lineTo(s * 0.82, s * 0.5)
            ..lineTo(s * 0.28, s * 0.82)
            ..close(),
          Paint()..color = color,
        );
      case _Glyph.close:
        canvas
          ..drawLine(
              Offset(s * 0.25, s * 0.25), Offset(s * 0.75, s * 0.75), paint)
          ..drawLine(
              Offset(s * 0.75, s * 0.25), Offset(s * 0.25, s * 0.75), paint);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
