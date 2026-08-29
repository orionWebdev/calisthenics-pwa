import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';

/// Die schwebende Navigation.
///
/// **Labels sind nicht dekorativ** — sie benennen Ziele. Sie wachsen deshalb
/// auf 12 sp, und der Platzkonflikt auf schmalen Geräten wird kompositorisch
/// gelöst: Passen nicht alle Labels nebeneinander, trägt nur der aktive
/// Eintrag seines, die übrigen liefern ihren Namen über Semantics.
///
/// ## Drei Plätze, nicht fünf
///
/// Es waren fünf, und zwei davon führten auf „Kommt noch". Das ist kein
/// Ausblick, sondern eine Lücke: 40 Prozent der Hauptnavigation zeigten einen
/// Platzhalter, und die App wirkte dadurch leerer, als sie ist.
///
/// **PROFIL ist ersatzlos entfallen** — die Einstellungen liegen seit Modul 8
/// am Profilbild im Kopf, wo man sie sucht. **RECOVERY** ist noch nicht
/// gebaut; ein Platz, der darauf wartet, ist ein Versprechen, das die Leiste
/// bei jedem Blick wiederholt.
///
/// Ein Platz kommt zurück, wenn ein Bildschirm dahinter steht. Nicht vorher.
///
/// ## Kraft · Cardio · Hybrid
///
/// Seit Modul 11 heissen die drei Plätze anders — und sie sind anders belegt.
/// Der Verlauf ist kein Tab mehr, sondern ein Segment des Kraft-Tabs; der
/// Start-Tab und die Auswertung sind zum Hybrid-Tab verschmolzen. Die App
/// heisst Hybrid, und vorher konnte sie nur Kraft: 51 Ausdauereinheiten lagen
/// im Bestand ohne Bildschirm.
///
/// Die Leiste selbst ist unverändert Modul 1: drei Plätze, 48 dp, Skalierung
/// 0,88 mit Glow, Labels 12 sp, die bei Platzmangel nur der aktive trägt.
///
/// Ob sie passen, wird **gemessen statt geschätzt**. Eine Breitenschwelle war
/// hier falsch: Bei 360 dp lag sie auf der sicheren Seite, die Zeile lief
/// trotzdem über — und ein Überlauf beschneidet die Semantics-Rechtecke am
/// `ClipRRect` der Leiste, sodass die Tap-Ziel-Prüfung 34 dp statt 48 dp misst.
/// Der Fehler sah aus wie ein zu kleines Ziel und war ein Layoutfehler.
class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.activeIndex,
    required this.onSelect,
  });

  final int activeIndex;
  final ValueChanged<int> onSelect;

  /// Innenpolster eines Eintrags — fließt in die Platzrechnung ein.
  static const _itemInset = 8.0;

  /// Trefferfläche laut Vertrag R3.
  static const _minItem = 48.0;

  /// Passen alle Labels in ihre gleich breiten Fächer?
  static bool _allLabelsFit(
    BuildContext context,
    List<String> labels,
    double available,
  ) {
    final slot = available / labels.length;
    if (slot < _minItem + _itemInset) return false;

    final style = _NavItem.labelStyle(context, AtemColors.textSecondary);
    final scaler = MediaQuery.textScalerOf(context);
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > slot - _itemInset) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    // Versalien wie in Modul 1 — die Rolle labelMicro ist Mono in Grossbuchstaben.
    final labels = [
      l10n.tabStrength.toUpperCase(),
      l10n.tabCardio.toUpperCase(),
      l10n.tabHybrid.toUpperCase(),
    ];

    return AtemBar(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showAll = _allLabelsFit(context, labels, constraints.maxWidth);

          return Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                if (showAll || i == activeIndex)
                  // Expanded verteilt die Breite und verhindert damit den
                  // Überlauf strukturell — nicht über eine Schwelle, die man
                  // auf dem nächsten Gerät wieder nachziehen muss.
                  Expanded(
                    child: _item(l10n, labels, i, showLabel: true),
                  )
                else
                  _item(l10n, labels, i, showLabel: false),
            ],
          );
        },
      ),
    );
  }

  Widget _item(
    AppL10n l10n,
    List<String> labels,
    int i, {
    required bool showLabel,
  }) =>
      _NavItem(
        label: labels[i],
        glyph: _NavGlyph.values[i],
        active: i == activeIndex,
        showLabel: showLabel,
        // Die Ansage in normaler Schreibung: „Cardio, Tab 2 von 3".
        semanticLabel: l10n.dashboardNavA11y(
          [l10n.tabStrength, l10n.tabCardio, l10n.tabHybrid][i],
          i + 1,
          labels.length,
        ),
        onTap: () => onSelect(i),
      );
}

enum _NavGlyph { strength, cardio, hybrid }

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.glyph,
    required this.active,
    required this.showLabel,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final _NavGlyph glyph;
  final bool active;
  final bool showLabel;
  final String semanticLabel;
  final VoidCallback onTap;

  /// Auch von [FloatingNav._allLabelsFit] benutzt — die Messung muss
  /// denselben Stil sehen wie die Darstellung.
  static TextStyle labelStyle(BuildContext context, Color color) =>
      AtemType.labelMicro
          .of(context)
          .copyWith(color: color, letterSpacing: 0.5);

  @override
  Widget build(BuildContext context) {
    final color = active ? AtemColors.cyan : AtemColors.textSecondary;

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: active,
      pressScale: AtemPressScale.strong,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 21,
              child: CustomPaint(
                painter: _NavPainter(glyph: glyph, color: color, glow: active),
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle(context, color),
              ),
            ],
            const SizedBox(height: 3),
            // Der Punkt ist dekorativ; der aktive Zustand steckt in Semantics.
            Opacity(
              opacity: active ? 1 : 0,
              child: const AtemStatusDot(
                  color: AtemColors.cyan, size: AtemDotSize.small),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavPainter extends CustomPainter {
  _NavPainter({required this.glyph, required this.color, required this.glow});

  final _NavGlyph glyph;
  final Color color;
  final bool glow;

  Path _build() {
    final p = Path();
    switch (glyph) {
      // Die Hantel aus Modul 1 — sie stand schon für Workouts.
      case _NavGlyph.strength:
        p
          ..moveTo(2.5, 12)
          ..lineTo(5.5, 12)
          ..moveTo(18.5, 12)
          ..lineTo(21.5, 12)
          ..moveTo(6.5, 8.5)
          ..lineTo(6.5, 15.5)
          ..moveTo(17.5, 8.5)
          ..lineTo(17.5, 15.5)
          ..moveTo(9.5, 6)
          ..lineTo(9.5, 18)
          ..moveTo(14.5, 6)
          ..lineTo(14.5, 18)
          ..moveTo(9.5, 12)
          ..lineTo(14.5, 12);
      // Die Welle aus Modul 1 (dort „Recovery"): eine Bewegung, die
      // weitergeht — Ausdauer.
      case _NavGlyph.cardio:
        p
          ..moveTo(3, 12)
          ..cubicTo(6, 5.5, 9, 5.5, 12, 12)
          ..cubicTo(15, 18.5, 18, 18.5, 21, 12);
      // Zwei Kreise, die sich überlappen: beide Spuren, eine Schnittmenge.
      case _NavGlyph.hybrid:
        p
          ..addOval(Rect.fromCircle(center: const Offset(9, 12), radius: 5.5))
          ..addOval(Rect.fromCircle(center: const Offset(15, 12), radius: 5.5));
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final path = _build();
    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NavPainter old) =>
      old.color != color || old.glow != glow || old.glyph != glyph;
}
