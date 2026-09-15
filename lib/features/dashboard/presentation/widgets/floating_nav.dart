import 'package:flutter/widgets.dart';

import '../../../../app/application/tab_providers.dart';
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
/// ## Vier Plätze
///
/// Es waren einmal fünf, zwei davon führten auf „Kommt noch"; dann drei, weil
/// ein Platz ohne Bildschirm ein Versprechen ist, das die Leiste bei jedem
/// Blick wiederholt. **RECOVERY ist zurück, weil jetzt ein Bildschirm
/// dahintersteht** — genau die Bedingung, die damals gestellt wurde.
///
/// **PROFIL bleibt entfallen** — die Einstellungen liegen seit Modul 8 am
/// Profilbild im Kopf, wo man sie sucht.
///
/// ## Hybrid · Kraft · Cardio · Regeneration
///
/// Seit Modul 11 heissen die drei Plätze anders — und sie sind anders belegt.
/// Der Verlauf ist kein Tab mehr, sondern ein Segment des Kraft-Tabs; der
/// Start-Tab und die Auswertung sind zum Hybrid-Tab verschmolzen. Die App
/// heisst Hybrid, und vorher konnte sie nur Kraft: 51 Ausdauereinheiten lagen
/// im Bestand ohne Bildschirm.
///
/// Die Leiste selbst ist unverändert Modul 1: 48 dp, Skalierung 0,88 mit
/// Glow, Labels 12 sp, die bei Platzmangel nur der aktive trägt.
///
/// ## Der Ton des Platzes
///
/// Der aktive Eintrag trägt den Ton seines Bereichs statt Cyan — lila für
/// Hybrid, orange für Kraft, blau für Cardio, grün für Regeneration. Farbe
/// ist dabei nie der einzige Träger: Das Wort steht daneben, der Punkt
/// darunter, und Semantics nennt Namen und Position.
///
/// Ob sie passen, wird **gemessen statt geschätzt**. Eine Breitenschwelle war
/// hier falsch: Bei 360 dp lag sie auf der sicheren Seite, die Zeile lief
/// trotzdem über — und ein Überlauf beschneidet die Semantics-Rechtecke am
/// `ClipRRect` der Leiste, sodass die Tap-Ziel-Prüfung 34 dp statt 48 dp misst.
/// Der Fehler sah aus wie ein zu kleines Ziel und war ein Layoutfehler.
class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.active,
    required this.onSelect,
  });

  final AppTab active;
  final ValueChanged<AppTab> onSelect;

  /// Die Einträge der Leiste — nur die sichtbaren Tabs, siehe
  /// [AppTab.visible]. Position und „Tab n von m" zählen über diese Liste,
  /// nicht über alle vier.
  static List<_NavTab> get _tabs =>
      [for (final t in AppTab.visible) _NavTab.values[t.index]];

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
    // Gemischte Schreibung: Der Tab-Name ist ein Bedienelement, kein
    // HUD-Kopf. In Mono-Versalien las sich die Leiste wie ein Terminal.
    final tabs = _tabs;
    final activeIndex = tabs.indexOf(_NavTab.values[active.index]);
    final labels = [for (final tab in tabs) tab.label(l10n)];

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
                    child: _item(l10n, tabs, labels, i,
                        active: i == activeIndex, showLabel: true),
                  )
                else
                  _item(l10n, tabs, labels, i,
                      active: i == activeIndex, showLabel: false),
            ],
          );
        },
      ),
    );
  }

  Widget _item(
    AppL10n l10n,
    List<_NavTab> tabs,
    List<String> labels,
    int i, {
    required bool active,
    required bool showLabel,
  }) =>
      _NavItem(
        label: labels[i],
        glyph: tabs[i].glyph,
        active: active,
        showLabel: showLabel,
        tone: tabs[i].tone,
        // Die Ansage in normaler Schreibung: „Kraft, Tab 2 von 2".
        semanticLabel: l10n.dashboardNavA11y(
          tabs[i].label(l10n),
          i + 1,
          labels.length,
        ),
        onTap: () => onSelect(AppTab.values[tabs[i].index]),
      );
}

enum _NavGlyph { strength, cardio, hybrid, recovery }

/// Die vier Plätze in der Reihenfolge von [AppTab] — gezeigt werden davon
/// nur die aus [AppTab.visible].
enum _NavTab {
  hybrid(_NavGlyph.hybrid, AtemColors.tabHybrid),
  strength(_NavGlyph.strength, AtemColors.tabStrength),
  cardio(_NavGlyph.cardio, AtemColors.tabCardio),
  recovery(_NavGlyph.recovery, AtemColors.tabRecovery);

  const _NavTab(this.glyph, this.tone);

  final _NavGlyph glyph;
  final Color tone;

  String label(AppL10n l) => switch (this) {
        _NavTab.hybrid => l.tabHybrid,
        _NavTab.strength => l.tabStrength,
        _NavTab.cardio => l.tabCardio,
        _NavTab.recovery => l.recoveryTitle,
      };
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.glyph,
    required this.tone,
    required this.active,
    required this.showLabel,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final _NavGlyph glyph;

  /// Der Ton des Bereichs — er gilt nur im aktiven Zustand.
  final Color tone;
  final bool active;
  final bool showLabel;
  final String semanticLabel;
  final VoidCallback onTap;

  /// Auch von [FloatingNav._allLabelsFit] benutzt — die Messung muss
  /// denselben Stil sehen wie die Darstellung.
  static TextStyle labelStyle(BuildContext context, Color color) =>
      AtemType.labelUi.of(context).copyWith(color: color);

  @override
  Widget build(BuildContext context) {
    // **Der Ton läuft in seinen Platz.** Ein Farbsprung beim Umschalten liest
    // sich wie ein Neuaufbau der Leiste; der Übergang zeigt, dass derselbe
    // Eintrag jetzt aktiv ist.
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: active ? tone : AtemColors.textSecondary,
      ),
      duration: AtemMotion.duration(context, AtemMotion.normal),
      curve: AtemMotion.curve,
      builder: (context, animated, _) =>
          _build(context, animated ?? AtemColors.textSecondary),
    );
  }

  Widget _build(BuildContext context, Color color) {
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
            // Der Punkt wächst in seinen Platz statt aufzublitzen.
            AnimatedScale(
              scale: active ? 1 : 0,
              duration: AtemMotion.duration(context, AtemMotion.normal),
              curve: AtemMotion.curve,
              child: AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: AtemMotion.duration(context, AtemMotion.normal),
                child: AtemStatusDot(color: tone, size: AtemDotSize.small),
              ),
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
      // Ein Herz — für Ausdauer die naheliegende Form. Die Welle, die hier
      // stand, war aus Modul 1 geliehen, wo sie „Recovery" hiess; sie steht
      // jetzt wieder dort.
      case _NavGlyph.cardio:
        p
          ..moveTo(12, 20)
          ..cubicTo(12, 20, 3.5, 14.8, 3.5, 9.2)
          ..cubicTo(3.5, 6.3, 5.8, 4, 8.6, 4)
          ..cubicTo(10.3, 4, 11.4, 4.9, 12, 6)
          ..cubicTo(12.6, 4.9, 13.7, 4, 15.4, 4)
          ..cubicTo(18.2, 4, 20.5, 6.3, 20.5, 9.2)
          ..cubicTo(20.5, 14.8, 12, 20, 12, 20)
          ..close();
      // Die Welle aus Modul 1: eine Bewegung, die abklingt — Regeneration.
      case _NavGlyph.recovery:
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
