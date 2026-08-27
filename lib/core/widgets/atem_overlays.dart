import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/atem_colors.dart';
import '../theme/atem_geometry.dart';
import '../theme/atem_type.dart';
import 'atem_button.dart';
import 'atem_tappable.dart';

/// Wann Sheet, wann Dialog?
///
/// > Ein Dialog stellt genau **eine Frage**, die ohne Eingabe und ohne Scrollen
/// > mit höchstens zwei Aktionen beantwortbar ist. Alles, was Eingabe, Auswahl
/// > aus mehr als zwei Optionen oder Scrollen braucht, ist ein Sheet.
///
/// Die Regel ist benennbar und damit prüfbar — sie soll nicht Gefühlssache
/// bleiben.
abstract final class AtemOverlays {
  /// Der Verdunkler bekommt **keinen Blur**.
  ///
  /// Naheliegend wäre er bei dieser Glas-Ästhetik. Aber ein geblurrter
  /// Hintergrund sagt „der Kontext ist weg", während Sheet und Dialog ihn nur
  /// pausieren. Dazu kostet eine zweite Blur-Ebene über den Karten auf
  /// Mittelklasse-Geräten sichtbar Frames — das Budget gehört den Flächen.
  static const sheetBarrierOpacity = 0.62;
  static const dialogBarrierOpacity = 0.72;

  static Color barrier(double opacity) =>
      AtemColors.base.withValues(alpha: opacity);
}

/// Bottom Sheet.
///
/// Wächst mit dem Inhalt bis zur halben Höhe, danach scrollt der Inhalt bei
/// höchstens 90 % — **nie 100 %**, damit immer ein Streifen Canvas sichtbar
/// bleibt und man sieht, worauf das Sheet liegt.
class AtemSheet extends StatelessWidget {
  const AtemSheet._({
    required this.title,
    required this.child,
    required this.closeLabel,
    this.primaryAction,
    this.secondaryAction,
  });

  final String title;
  final Widget child;

  /// Aus dem ARB — beschriftet Griff, Schließen-X und Verdunkler.
  final String closeLabel;

  /// Genau eine Gradient-Aktion, optional eine Ghost-Aktion daneben.
  /// Die Fußzeile scrollt nie mit.
  final AtemButton? primaryAction;
  final AtemButton? secondaryAction;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String closeLabel,
    required Widget child,
    AtemButton? primaryAction,
    AtemButton? secondaryAction,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0x00000000),
      barrierColor: AtemOverlays.barrier(AtemOverlays.sheetBarrierOpacity),
      // Der Screenreader erreicht den Verdunkler NACH dem Inhalt.
      barrierLabel: closeLabel,
      // Kein eigener Griff von Material — wir zeichnen unseren mit Semantik.
      showDragHandle: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      builder: (_) => AtemSheet._(
        title: title,
        closeLabel: closeLabel,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    const radius = AtemRadii.sheetR;

    return Semantics(
      // Rolle Dialog: Zurück-Geste schließt, Fokus landet auf dem Titel.
      scopesRoute: true,
      namesRoute: true,
      label: title,
      explicitChildNodes: true,
      child: Padding(
        // Über der Tastatur bleiben — sonst verdeckt sie die Fußzeile.
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: const BoxDecoration(
                color: AtemColors.cardTinted,
                borderRadius: radius,
                border: Border(
                  top: BorderSide(color: AtemColors.border),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Grabber(label: closeLabel),
                  _TitleRow(title: title, closeLabel: closeLabel),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: child,
                    ),
                  ),
                  if (primaryAction != null)
                    _Footer(
                      primary: primaryAction!,
                      secondary: secondaryAction,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: () => Navigator.of(context).maybePop(),
        semanticLabel: label,
        pressScale: AtemPressScale.none,
        // Trefferzone volle Breite, damit man den Griff nicht suchen muss.
        minTapSize: const Size(double.infinity, 24),
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AtemColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title, required this.closeLabel});
  final String title;
  final String closeLabel;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AtemType.titleLarge.of(context)),
            ),
            AtemTappable(
              onTap: () => Navigator.of(context).maybePop(),
              semanticLabel: closeLabel,
              child: const _CloseGlyph(),
            ),
          ],
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.primary, this.secondary});
  final AtemButton primary;
  final AtemButton? secondary;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AtemColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            primary,
            if (secondary != null) ...[const SizedBox(height: 8), secondary!],
          ],
        ),
      );
}

/// Wofür ein Dialog gebraucht wird.
enum AtemDialogKind {
  /// Vorwärts mit Gewinn — Gradient erlaubt.
  confirm,

  /// Zerstörend. **Nie Gradient.** Der Gradient steht für „vorwärts mit
  /// Gewinn"; ein zerstörender Gradient-Button wäre eine gelernte Falle.
  destructive,

  /// Nur zur Kenntnis. Eine Aktion.
  inform,
}

/// Dialog mit einer Anatomie und drei Belegungen.
class AtemDialog extends StatelessWidget {
  const AtemDialog._({
    required this.kind,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.dismissLabel,
    this.detail,
    this.alternativeLabel,
    this.onAlternative,
  });

  final AtemDialogKind kind;
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final String? dismissLabel;

  /// Zusatz, etwa ein StatBox-Raster mit höchstens vier Werten.
  final Widget? detail;

  /// Ein **zweiter Ausgang**, nicht bloß eine zweite Aktion.
  ///
  /// Nur für den Fall „zwei Ergebnisse plus Abbrechen": Ein Workout kann
  /// gespeichert **oder** verworfen werden, und beides zu unterdrücken wäre
  /// eine Sackgasse. Er wird als zerstörend dargestellt und steht nie an
  /// erster Stelle.
  ///
  /// **Drei Aktionen sind das Maximum.** Ein Dialog mit vier Wegen ist eine
  /// Liste, die sich als Frage verkleidet.
  final String? alternativeLabel;
  final VoidCallback? onAlternative;

  static Future<T?> show<T>(
    BuildContext context, {
    required AtemDialogKind kind,
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    required String barrierLabel,
    String? dismissLabel,
    Widget? detail,
    String? alternativeLabel,
    VoidCallback? onAlternative,
  }) {
    assert(
      (alternativeLabel == null) == (onAlternative == null),
      'Ein zweiter Ausgang braucht Beschriftung und Rückruf.',
    );
    return showDialog<T>(
      context: context,
      // Kein Tap-to-close: Der Dialog verlangt eine Entscheidung.
      barrierDismissible: false,
      barrierColor: AtemOverlays.barrier(AtemOverlays.dialogBarrierOpacity),
      barrierLabel: barrierLabel,
      builder: (_) => AtemDialog._(
        kind: kind,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        dismissLabel: dismissLabel,
        detail: detail,
        alternativeLabel: alternativeLabel,
        onAlternative: onAlternative,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width - 48, 340.0);

    final confirm = switch (kind) {
      AtemDialogKind.confirm => AtemButton.gradient(
          label: confirmLabel,
          semanticLabel: confirmLabel,
          onPressed: onConfirm,
        ),
      AtemDialogKind.destructive => AtemButton.outline(
          label: confirmLabel,
          // Die Warnung steckt im Label, nicht nur im Fließtext.
          semanticLabel: '$confirmLabel. $message',
          accent: AtemColors.magenta,
          size: AtemButtonSize.regular,
          leading: const _WarningTriangle(),
          onPressed: onConfirm,
        ),
      AtemDialogKind.inform => AtemButton.outline(
          label: confirmLabel,
          semanticLabel: confirmLabel,
          size: AtemButtonSize.regular,
          onPressed: onConfirm,
        ),
    };

    // **Material ist Pflicht, auch wenn wir keins sehen wollen.**
    // `showDialog` legt anders als `showModalBottomSheet` keines an. Ohne
    // Material fällt jeder `Text` auf Flutters Notdarstellung zurück: gelbe
    // Schrift, doppelt unterstrichen. Am Gerät sofort sichtbar, im Widget-Test
    // nicht — dort prüft niemand die Textfarbe.
    //
    // `transparency` heißt: Nur der Textstil kommt, keine Fläche und kein
    // Schatten. Beides bringt der Container darunter selbst mit.
    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: title,
        explicitChildNodes: true,
        child: Center(
          child: Container(
            width: width,
            decoration: BoxDecoration(
              // Vollton, kein Blur — der Dialog liegt über allem.
              color: AtemColors.card,
              borderRadius: AtemRadii.cardR,
              border: Border.all(color: AtemColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 60,
                  offset: Offset(0, 24),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titel und Botschaft als ein Block — ein Screenreader soll die
                // Frage am Stück hören, nicht in zwei Anläufen.
                Semantics(
                  label: '$title. $message',
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AtemType.titleMedium.of(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AtemType.labelSmall.of(context),
                        ),
                      ],
                    ),
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 16),
                  detail!,
                ],
                const SizedBox(height: 16),
                confirm,
                if (alternativeLabel != null) ...[
                  const SizedBox(height: 9),
                  AtemButton.outline(
                    label: alternativeLabel!,
                    semanticLabel: alternativeLabel!,
                    expand: true,
                    accent: AtemColors.magenta,
                    leading: const _WarningTriangle(),
                    onPressed: onAlternative,
                  ),
                ],
                if (dismissLabel != null) ...[
                  const SizedBox(height: 9),
                  // Der Fokus liegt auf der sichersten Aktion, nie auf der
                  // zerstörenden.
                  AtemButton.ghost(
                    label: dismissLabel!,
                    semanticLabel: dismissLabel!,
                    expand: true,
                    accent: AtemColors.textPrimary,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseGlyph extends StatelessWidget {
  const _CloseGlyph();

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size.square(24),
        painter: _StrokePainter((s) => Path()
          ..moveTo(s * 0.25, s * 0.25)
          ..lineTo(s * 0.75, s * 0.75)
          ..moveTo(s * 0.75, s * 0.25)
          ..lineTo(s * 0.25, s * 0.75)),
      );
}

class _WarningTriangle extends StatelessWidget {
  const _WarningTriangle();

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size.square(14),
        painter: _StrokePainter(
          (s) => Path()
            ..moveTo(s * 0.5, s * 0.1)
            ..lineTo(s * 0.95, s * 0.88)
            ..lineTo(s * 0.05, s * 0.88)
            ..close(),
          color: AtemColors.magenta,
        ),
      );
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.build, {this.color = AtemColors.textSecondary});
  final Path Function(double side) build;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
        build(size.shortestSide),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );

  @override
  bool shouldRepaint(_StrokePainter old) => old.color != color;
}
