import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';

/// Der Anmeldeknopf.
///
/// ## Warum er nicht unser Gradient trägt
///
/// Der Marken-Gradient hätte ihn zur stärksten Fläche des Bildschirms gemacht —
/// und genau das ist falsch. Googles Sign-in-Branding verlangt definierte
/// Flächen und ein unverändertes G, und der bekannte, neutrale Knopf trägt ein
/// Vertrauenssignal, das ein eigener Farbverlauf zerstören würde. Der Gradient
/// bleibt den Trainings-Aktionen vorbehalten.
///
/// Das G-Logo ist die **einzige** Nicht-Token-Farbe dieses Moduls.
///
/// Beim Laden ersetzt der Kreisel die Beschriftung und die Breite wird
/// eingefroren — ein Knopf, der beim Antippen schmaler wird, wirkt wie ein
/// Fehler.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.onPressed,
    required this.busy,
    this.focusNode,
  });

  final VoidCallback onPressed;
  final bool busy;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final label = busy ? l10n.authSigningIn : l10n.authGoogle;

    return Focus(
      focusNode: focusNode,
      child: AtemTappable(
        onTap: busy ? null : onPressed,
        semanticLabel: label,
        haptic: AtemHaptic.light,
        minTapSize: const Size(0, 52),
        child: Opacity(
          opacity: busy ? 0.5 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AtemColors.card,
              borderRadius: BorderRadius.circular(AtemRadii.pill),
              border: Border.all(color: AtemColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const AtemButtonSpinner()
                else
                  const _GoogleMark(size: 20),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.labelMedium.of(context).copyWith(
                          color: AtemColors.textPrimary,
                          fontWeight: FontWeight.w500,
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

/// Das G in seinen vorgeschriebenen vier Farben.
///
/// Als Zeichnung und nicht als Bilddatei: Ein SVG oder PNG wäre ein weiteres
/// Asset im Bündel, und die Form ist einfach genug. Die Farben stammen aus
/// Googles Vorgaben und dürfen **nicht** durch Tokens ersetzt werden.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _GooglePainter(),
        ),
      );
}

class _GooglePainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Rect.fromLTWH(0, 0, s, s).deflate(s * 0.08);
    final stroke = s * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Vier Bögen im Uhrzeigersinn ab dem rechten Ansatz des roten Segments.
    canvas.drawArc(rect, -0.35, -1.25, false, paint..color = _red);
    canvas.drawArc(rect, -1.6, -1.6, false, paint..color = _yellow);
    canvas.drawArc(rect, 3.05, -1.5, false, paint..color = _green);
    canvas.drawArc(rect, 0.72, -1.1, false, paint..color = _blue);

    // Der Querbalken des G.
    canvas.drawRect(
      Rect.fromLTWH(s * 0.5, s * 0.42, s * 0.46, stroke * 0.82),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}
