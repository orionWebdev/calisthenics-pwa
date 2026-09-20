import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Woher eine Zeile stammt — **dieselbe Form in vier Zuständen**.
///
/// ## Warum kein Abzeichen
///
/// Ein Chip „AUS DER UHR" wäre sofort lesbar und wäre eine zweite
/// Bedeutungsebene über jeder Zeile. Board 14 hat dieselbe Idee für den
/// Gewichtspunkt schon verworfen; Board 15 übernimmt das Idiom und ergänzt
/// zwei Zustände (Entscheidung 18).
///
/// ## Warum 10 dp und nicht 6
///
/// Bei 6 dp ist „Ring mit Kern" nicht von „gefüllt" zu unterscheiden — der
/// Kern hätte weniger als zwei Pixel. Zehn dp lösen das ohne neue Farbe
/// (Entscheidung 19).
///
/// ## Wo es nicht trägt
///
/// Ein 10-dp-Punkt wächst nicht mit der Schrift und wird neben 24-sp-Text zum
/// Staubkorn. Ab Textskalierung 1,3 tritt an seine Stelle ein Wort in der
/// Metazeile — **nicht beides**. Die Entscheidung trifft der Aufrufer über
/// [AtemOriginDot.fitsAt]; dieser Baustein zeichnet nur.
enum AtemOriginShape {
  /// Selbst geführt.
  filled,

  /// Aus einer fremden Quelle übernommen.
  hollow,

  /// Beides, zusammengeführt.
  ringWithCore,

  /// Noch ungeprüft — zählt nicht.
  dashed,
}

class AtemOriginDot extends StatelessWidget {
  const AtemOriginDot({super.key, required this.shape, this.color});

  final AtemOriginShape shape;

  /// `null` nimmt die Metazeilenfarbe. Der ungeprüfte Zustand bleibt immer
  /// grau: Er sagt noch nichts über die Einheit aus.
  final Color? color;

  static const size = 10.0;

  /// Ab welcher Schriftskalierung der Punkt durch ein Wort ersetzt wird.
  static const wordFrom = 1.3;

  static bool fitsAt(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(10) / 10 < wordFrom;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _OriginPainter(
              shape,
              shape == AtemOriginShape.dashed
                  ? AtemColors.textSecondary
                  : (color ?? AtemColors.textSecondary),
            ),
          ),
        ),
      );
}

class _OriginPainter extends CustomPainter {
  const _OriginPainter(this.shape, this.color);

  final AtemOriginShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (shape) {
      case AtemOriginShape.filled:
        canvas.drawCircle(center, radius, fill);

      case AtemOriginShape.hollow:
        canvas.drawCircle(center, radius - 1, stroke);

      case AtemOriginShape.ringWithCore:
        canvas
          ..drawCircle(center, radius - 1, stroke..strokeWidth = 1.6)
          ..drawCircle(center, 2.2, fill);

      case AtemOriginShape.dashed:
        // Acht Striche auf dem Kreis — „hier fehlt noch etwas" als Form.
        const segments = 8;
        final rect = Rect.fromCircle(center: center, radius: radius - 1);
        const sweep = 6.283 / segments;
        for (var i = 0; i < segments; i++) {
          canvas.drawArc(
            rect,
            i * sweep,
            sweep * 0.55,
            false,
            stroke..strokeWidth = 1.6,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_OriginPainter old) =>
      old.shape != shape || old.color != color;
}
