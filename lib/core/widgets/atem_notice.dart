import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_motion.dart';
import '../theme/atem_type.dart';
import 'atem_tappable.dart';

/// Wie dringend eine Notice ist.
enum AtemNoticeTone {
  /// Zustandsmeldung ohne Schuldzuweisung — „kein Netz".
  neutral,

  /// Etwas ist schiefgegangen.
  error,
}

/// Eine bleibende Meldung an fester Stelle.
///
/// **Bewusst kein Snackbar.** Ein Snackbar verschwindet nach vier Sekunden,
/// der Zustand aber nicht: Wer ohne Netz auf „Anmelden" tippt, hat das Problem
/// auch in Sekunde fünf noch. Die Notice bleibt, bis sich der Zustand ändert,
/// und sitzt an fester Stelle — so stapeln wiederholte Fehlversuche nicht und
/// das Layout springt nicht.
///
/// **Höchstens eine gleichzeitig**, die neueste gewinnt. Zwei Meldungen
/// übereinander sind keine doppelte Information, sondern halbe Aufmerksamkeit.
class AtemNotice extends StatelessWidget {
  const AtemNotice({
    super.key,
    required this.title,
    required this.body,
    required this.semanticLabel,
    this.tone = AtemNoticeTone.neutral,
    this.code,
    this.actionLabel,
    this.onAction,
  }) : assert(
          (actionLabel == null) == (onAction == null),
          'Eine Aktion braucht beides: Beschriftung und Rückruf.',
        );

  final String title;
  final String body;

  /// Was ein Screenreader ansagt. Enthält Titel, Text **und** den Code — beim
  /// Support-Anruf ist genau der die Frage.
  final String semanticLabel;

  final AtemNoticeTone tone;

  /// Technischer Fehlercode, bereits formatiert.
  final String? code;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final accent = tone == AtemNoticeTone.error
        ? AtemColors.magenta
        : AtemColors.textSecondary;

    return Semantics(
      liveRegion: true,
      label: semanticLabel,
      container: true,
      child: ExcludeSemantics(
        // Der Text steckt bereits im Label. Ohne diesen Ausschluss läse ein
        // Screenreader Titel und Text zweimal — einmal als Ansage, einmal als
        // Inhalt.
        excluding: onAction == null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AtemColors.surfaceRaised,
            borderRadius: AtemRadii.statBoxR,
            border: Border.all(
              color: tone == AtemNoticeTone.error
                  ? AtemColors.magenta.withValues(alpha: 0.4)
                  : AtemColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form zusätzlich zur Farbe: Ein Ausrufezeichen im Dreieck sagt
              // auch ohne Farbwahrnehmung „Fehler" (Vertrag R6).
              _NoticeGlyph(tone: tone, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AtemType.labelSmall
                          .of(context)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(body, style: AtemType.labelSmall.of(context)),
                    if (code != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        code!,
                        style: AtemType.labelMicro
                            .of(context)
                            .copyWith(color: AtemColors.magenta),
                      ),
                    ],
                    if (actionLabel != null) ...[
                      const SizedBox(height: 8),
                      AtemTappable(
                        onTap: onAction,
                        semanticLabel: actionLabel!,
                        // Sichtbar ist es Text, die Trefferfläche bleibt 48 dp.
                        minTapSize: const Size(48, 48),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          actionLabel!,
                          style: AtemType.labelSmall
                              .of(context)
                              .copyWith(color: AtemColors.cyan),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Die Statuszone über dem Anmeldeknopf.
///
/// Ohne Meldung ist sie **null Pixel hoch** — sie reserviert keinen Leerraum,
/// der wie ein Fehler aussähe, der noch kommt. Der Wechsel ist ein Crossfade;
/// die Marke darüber weicht nach oben aus, statt dass etwas springt.
class AtemNoticeSlot extends StatelessWidget {
  const AtemNoticeSlot({super.key, this.notice});

  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AtemMotion.duration(context, AtemMotion.normal),
      switchInCurve: AtemMotion.curve,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      // AnimatedSwitcher braucht ein Kind mit stabiler Grösse für den Ausgang;
      // ein leerer SizedBox erfüllt das und misst null.
      child: notice == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: notice,
            ),
    );
  }
}

class _NoticeGlyph extends StatelessWidget {
  const _NoticeGlyph({required this.tone, required this.color});

  final AtemNoticeTone tone;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: const Size.square(20),
          painter: _GlyphPainter(tone: tone, color: color),
        ),
      );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.tone, required this.color});

  final AtemNoticeTone tone;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    if (tone == AtemNoticeTone.error) {
      // Dreieck mit Ausrufezeichen.
      canvas.drawPath(
        Path()
          ..moveTo(s * 0.5, s * 0.16)
          ..lineTo(s * 0.92, s * 0.84)
          ..lineTo(s * 0.08, s * 0.84)
          ..close(),
        paint,
      );
      canvas.drawLine(
          Offset(s * 0.5, s * 0.42), Offset(s * 0.5, s * 0.61), paint);
      // Der Punkt des Ausrufezeichens — als sehr kurze Linie statt über
      // drawPoints, das `PointMode` aus dart:ui verlangt.
      canvas.drawLine(
        Offset(s * 0.5, s * 0.72),
        Offset(s * 0.5, s * 0.73),
        paint..strokeWidth = s * 0.12,
      );
    } else {
      // Durchgestrichene Welle — „keine Verbindung".
      canvas.drawArc(
        Rect.fromCircle(center: Offset(s * 0.5, s * 0.72), radius: s * 0.4),
        3.9,
        1.5,
        false,
        paint,
      );
      canvas.drawLine(
          Offset(s * 0.18, s * 0.82), Offset(s * 0.82, s * 0.2), paint);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.tone != tone || old.color != color;
}
