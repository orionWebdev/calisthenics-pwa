import 'package:flutter/widgets.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_motion.dart';
import '../theme/atem_type.dart';

/// Gemeinsame Anatomie von Leer, Fehler und Laden.
///
/// Symbol, **eine Zeile Wahrheit**, höchstens eine Handlung. Zentriert und
/// vertikal mittig in der Zielfläche.
///
/// Der Text ist auf zwei Zeilen begrenzt: Wer mehr braucht, erklärt statt zu
/// benennen — dann gehört die Erklärung woanders hin.
class _StateScaffold extends StatelessWidget {
  const _StateScaffold({
    required this.icon,
    required this.title,
    required this.body,
    required this.iconTint,
    this.action,
  });

  final Widget icon;
  final String title;
  final String body;
  final Color iconTint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconTint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AtemRadii.iconBox),
              ),
              child: ExcludeSemantics(child: icon),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AtemType.titleMedium.of(context),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AtemType.labelSmall.of(context),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Nichts da — als Feststellung oder als Einladung.
///
/// **Eine Einladung nur, wenn die Handlung das Fehlen an Ort und Stelle
/// behebt.** Die leere Verlaufsliste bekommt bewusst keinen Knopf: „Session
/// starten" konkurriert dort mit der Session-Card einen Tab weiter, und zwei
/// Marken-CTAs für dieselbe Handlung sind einer zu viel.
class AtemEmptyState extends StatelessWidget {
  const AtemEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.action,
  });

  final String title;
  final String body;

  /// Nur setzen, wenn die Handlung genau hier hilft.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Bewusst KEINE Live-Region: Leere ist ein Ergebnis, kein Ereignis.
      label: '$title. $body',
      child: ExcludeSemantics(
        child: _StateScaffold(
          icon: const _EmptyGlyph(),
          iconTint: AtemColors.textSecondary,
          title: title,
          body: body,
          action: action,
        ),
      ),
    );
  }
}

/// Etwas ist schiefgegangen.
///
/// **Keine eigene Fehlerfarbe.** Die Palette enthält kein Rot, und statt eins
/// zu erfinden trägt Magenta die Fehlersemantik — unterschieden vom
/// Marken-Magenta durch die Form: Dreieck, gestrichelter Rand, Outline statt
/// Gradient.
///
/// **Kein Shake.** Der übliche Fehler-Rüttler ist eine Weg-Animation, die bei
/// reduzierter Bewegung ersatzlos stürbe. Die Unterscheidung darf nicht an
/// einer Animation hängen.
class AtemErrorState extends StatelessWidget {
  const AtemErrorState({
    super.key,
    required this.title,
    required this.body,
    this.onRetry,
    this.retryLabel,
  });

  final String title;
  final String body;

  /// `null` bedeutet endgültig — dann gibt es nichts zu wiederholen.
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Ein Fehlschlag ist ein Ereignis: genau eine Ansage.
      liveRegion: true,
      label: '$title. $body',
      child: ExcludeSemantics(
        child: _StateScaffold(
          icon: const _WarningGlyph(),
          iconTint: AtemColors.magenta,
          title: title,
          body: body,
          action: onRetry == null
              ? null
              : Semantics(
                  button: true,
                  label: retryLabel,
                  onTap: onRetry,
                  child: ExcludeSemantics(
                    child: _RetryButton(
                      label: retryLabel ?? '',
                      onTap: onRetry!,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AtemRadii.pillR,
            border:
                Border.all(color: AtemColors.magenta.withValues(alpha: 0.6)),
          ),
          child: Text(
            label,
            style: AtemType.labelMedium
                .of(context)
                .copyWith(color: AtemColors.magenta),
          ),
        ),
      );
}

/// Platzhalter in der Geometrie des erwarteten Inhalts.
///
/// **Skeletons pulsieren, sie schimmern nicht.** Ein Schimmer-Sweep ist eine
/// gerichtete Dauerschleife: Er konkurriert mit den Daten-Glows, sieht bei
/// reduzierter Bewegung eingefroren wie ein Renderfehler aus und suggeriert
/// Fortschritt, den es nicht gibt. Der Deckkraft-Puls friert sauber ein.
///
/// **Erscheint erst nach 300 ms.** Wer schneller lädt, soll nicht flackern.
class AtemSkeleton extends StatefulWidget {
  const AtemSkeleton({
    super.key,
    required this.blocks,
    required this.semanticLabel,
    this.spacing = 13,
  });

  /// Höhe und Radius je Platzhalter — in der Geometrie des Zielinhalts.
  final List<AtemSkeletonBlock> blocks;

  final String semanticLabel;
  final double spacing;

  @override
  State<AtemSkeleton> createState() => _AtemSkeletonState();
}

/// Ein Platzhalterblock.
@immutable
class AtemSkeletonBlock {
  const AtemSkeletonBlock({required this.height, this.radius = AtemRadii.card});
  final double height;
  final double radius;
}

class _AtemSkeletonState extends State<AtemSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ruhelage 0,8: sichtbar, aber erkennbar Platzhalter.
    AtemMotion.syncLoop(context, _controller, reverse: true, restingValue: 0.5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        // Die Blockhöhen sind fest — auf einem 320x640-Gerät ist der
        // Platzhalter höher als der Bildschirm. Ein nicht scrollbarer
        // Scroll-Container gibt ihm unbegrenzte Höhe und schneidet den Rest
        // ab, statt einen Überlauf zu werfen. Scrollen wäre hier sinnlos:
        // Es gibt nichts zu lesen.
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.blocks.length; i++) ...[
                if (i > 0) SizedBox(height: widget.spacing),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Versatz je Block, damit die Fläche nicht im Gleichtakt
                    // atmet — das wirkte wie ein einziger großer Block.
                    final phase = (_controller.value + i * 0.12) % 1.0;
                    return Opacity(
                      opacity: 0.55 + 0.45 * (1 - (phase - 0.5).abs() * 2),
                      child: child,
                    );
                  },
                  child: Container(
                    height: widget.blocks[i].height,
                    decoration: BoxDecoration(
                      color: AtemColors.track,
                      borderRadius:
                          BorderRadius.circular(widget.blocks[i].radius),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kleiner Kreisel — **nur** im auslösenden Button, 16 dp.
///
/// Ein Vollbild-Kreisel verspricht nichts und verortet nichts. Wo die
/// Zielgeometrie bekannt ist, gehört ein [AtemSkeleton] hin.
class AtemButtonSpinner extends StatefulWidget {
  const AtemButtonSpinner({super.key, this.size = 16});
  final double size;

  @override
  State<AtemButtonSpinner> createState() => _AtemButtonSpinnerState();
}

class _AtemButtonSpinnerState extends State<AtemButtonSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AtemMotion.syncLoop(context, _controller, restingValue: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.rotate(
              angle: _controller.value * 6.283,
              child: child,
            ),
            child: CustomPaint(painter: _SpinnerPainter()),
          ),
        ),
      );
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 1.25,
    );
    canvas.drawArc(
      rect,
      0,
      6.283,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AtemColors.border,
    );
    canvas.drawArc(
      rect,
      -1.57,
      2.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = AtemColors.cyan,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _EmptyGlyph extends StatelessWidget {
  const _EmptyGlyph();

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size.square(22),
        painter: _GlyphPainter(
          color: AtemColors.textSecondary,
          build: (s) => Path()
            ..addRRect(RRect.fromRectAndRadius(
              Rect.fromLTWH(s * 0.1, s * 0.2, s * 0.8, s * 0.6),
              Radius.circular(s * 0.14),
            ))
            ..moveTo(s * 0.3, s * 0.5)
            ..lineTo(s * 0.7, s * 0.5),
        ),
      );
}

/// Dreieck — der Formträger der Fehlersemantik, damit sie nicht an Magenta
/// allein hängt.
class _WarningGlyph extends StatelessWidget {
  const _WarningGlyph();

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size.square(22),
        painter: _GlyphPainter(
          color: AtemColors.magenta,
          build: (s) => Path()
            ..moveTo(s * 0.5, s * 0.14)
            ..lineTo(s * 0.94, s * 0.86)
            ..lineTo(s * 0.06, s * 0.86)
            ..close()
            ..moveTo(s * 0.5, s * 0.42)
            ..lineTo(s * 0.5, s * 0.62),
        ),
      );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.color, required this.build});
  final Color color;
  final Path Function(double side) build;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      build(size.shortestSide),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.color != color;
}
