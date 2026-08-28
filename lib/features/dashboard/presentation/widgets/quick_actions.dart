import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/dashboard_data.dart';

/// Die vier Kacheln unter der Session-Card.
///
/// Sie waren im Vorgänger **nicht antippbar** — `onTapDown` war verdrahtet,
/// `onTap` fehlte. Sie federten beim Antippen ein und taten nichts.
///
/// ## Drei von ihnen zeigten dauerhaft „Noch keine Daten"
///
/// Das Board zeichnet Ernährung, Recovery mit HRV und Periodisierung. Für
/// alle drei gibt es in V1 keine Datenquelle — Health Connect steht
/// ausdrücklich nicht darin, Ernährung wird nirgends erfasst, und eine
/// Periodisierung gibt es weder in dieser App noch in der Vorgängerin. Die
/// Felder waren im Repository fest auf `null`.
///
/// Drei leere Kacheln nehmen die halbe Fläche des Dashboards ein und sagen
/// nie etwas. Sie zeigen jetzt, was die App tatsächlich weiss: den Formwert,
/// die letzte Einheit mit ihrem Vergleich und den nächsten Termin. Die
/// gezeichneten Kacheln kommen zurück, wenn ihre Daten kommen — nicht vorher.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.data,
    required this.onSelect,
  });

  final DashboardData data;

  /// Zielbereich der Navigation.
  ///
  /// Die Zahlen sind die Tab-Indizes des Rahmens: 0 Dashboard · 1 Workouts ·
  /// 2 Verlauf · 3 und 4 noch leer. Sie standen hier fest verdrahtet aus einer
  /// Zeit, in der es nur einen Bildschirm gab — Ernährung zeigte auf 2 und
  /// landete nach dem Umbau im Verlauf. Kacheln ohne eigenes Ziel führen jetzt
  /// dorthin, wo ihre Zahlen herkommen.
  final ValueChanged<int> onSelect;

  /// Der Verlauf. Dort stehen die Einheiten, aus denen die Kachel ihre Zahlen
  /// zieht.
  static const _historyTab = 2;
  static const _workoutsTab = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _workout(l10n)),
              const SizedBox(width: AtemSpacing.gridGap),
              Expanded(child: _form(l10n)),
            ],
          ),
        ),
        const SizedBox(height: AtemSpacing.gridGap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _last(l10n)),
              const SizedBox(width: AtemSpacing.gridGap),
              Expanded(child: _next(l10n)),
            ],
          ),
        ),
      ],
    );
  }

  /// Sätze der letzten Einheit — unverändert aus dem Board.
  Widget _workout(AppL10n l10n) {
    final log = data.workoutLog;
    return _Tile(
      accent: AtemColors.cyan,
      glyph: _Glyph.bars,
      title: l10n.dashboardQuickWorkout,
      // Der Satz wird hier gebaut, nicht in der Domäne — sonst liesse er sich
      // nicht übersetzen.
      body: switch (log) {
        null => l10n.quickNoSessions,
        WorkoutLogSummary(planName: final plan?) =>
          l10n.dashboardQuickSetsPlan(plan, log.totalSets),
        _ => l10n.dashboardQuickSetsPlain(log.totalSets),
      },
      onTap: () => onSelect(_historyTab),
    );
  }

  /// Der Formwert. **Die Richtung steht als Wort daneben**, nicht als Farbe —
  /// ob steigend gut ist, hängt davon ab, was jemand vorhat.
  Widget _form(AppL10n l10n) {
    final form = data.form;
    return _Tile(
      accent: AtemColors.magenta,
      glyph: _Glyph.bolt,
      title: l10n.quickForm,
      body: form == null
          ? l10n.quickNoSessions
          : '${l10n.quickFormValue(form.score)} · '
              '${!form.changed ? l10n.quickFormFlat : (form.rising ? l10n.quickFormRising : l10n.quickFormFalling)}',
      trailing: form == null
          ? null
          : AtemProgressRing(
              value: (form.score / 100).clamp(0.0, 1.0),
              label: '${form.score}',
              semanticLabel: l10n.quickFormValue(form.score),
            ),
      onTap: () => onSelect(_historyTab),
    );
  }

  /// Die letzte Einheit mit dem Abstand und, wenn es einen Bezug gibt, der
  /// Veränderung der Last.
  Widget _last(AppL10n l10n) {
    final last = data.lastSession;
    if (last == null) {
      return _Tile(
        accent: AtemColors.green,
        glyph: _Glyph.wave,
        title: l10n.quickLast,
        body: l10n.quickNoSessions,
        onTap: () => onSelect(_historyTab),
      );
    }

    final when = last.daysAgo == 0
        ? l10n.quickLastToday
        : l10n.quickLastDays(last.daysAgo);
    final before = last.loadBefore;
    final delta = before == null || before == 0
        ? null
        : (last.load - before).round();

    return _Tile(
      accent: AtemColors.green,
      glyph: _Glyph.wave,
      title: l10n.quickLast,
      body: delta == null || delta == 0
          ? '${last.name} · $when'
          : '${last.name} · ${l10n.detailLoad} '
              '${delta > 0 ? '+' : '−'}${delta.abs()}',
      onTap: () => onSelect(_historyTab),
    );
  }

  /// Der nächste Termin. Führt in die Workouts, wo er gestartet wird.
  Widget _next(AppL10n l10n) {
    final next = data.nextSession;
    return _Tile(
      accent: AtemColors.violet,
      glyph: _Glyph.calendar,
      title: l10n.quickNext,
      body: next == null
          ? l10n.quickNextNone
          : '${next.title} · ${switch (next.daysAhead) {
              0 => l10n.quickNextToday,
              1 => l10n.quickNextTomorrow,
              _ => l10n.quickNextDays(next.daysAhead),
            }}',
      onTap: () => onSelect(_workoutsTab),
    );
  }
}

enum _Glyph { bars, bolt, wave, calendar }

class _Tile extends StatelessWidget {
  const _Tile({
    required this.accent,
    required this.glyph,
    required this.title,
    required this.body,
    required this.onTap,
    this.trailing,
  });

  final Color accent;
  final _Glyph glyph;
  final String title;
  final String body;


  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtemCard.list(
        onTap: onTap,
        semanticLabel: '$title. $body',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 33,
                  height: 33,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AtemRadii.iconBox),
                  ),
                  child: CustomPaint(
                    painter: _GlyphPainter(glyph: glyph, color: accent),
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AtemType.titleSmallOrDefault(context)),
            const SizedBox(height: 3),
            Text(body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AtemType.labelSmall.of(context)),
          ],
        ),
      );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.glyph, required this.color});
  final _Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24 * 0.72;
    canvas.save();
    canvas.translate(
        (size.width - 24 * scale) / 2, (size.height - 24 * scale) / 2);
    canvas.scale(scale);

    final p = Path();
    switch (glyph) {
      case _Glyph.bars:
        p
          ..moveTo(4, 20)
          ..lineTo(4, 10)
          ..moveTo(9, 20)
          ..lineTo(9, 4)
          ..moveTo(14, 20)
          ..lineTo(14, 13)
          ..moveTo(19, 20)
          ..lineTo(19, 8);
      case _Glyph.bolt:
        p
          ..moveTo(13, 2)
          ..lineTo(5, 13)
          ..lineTo(10, 13)
          ..lineTo(8, 22)
          ..lineTo(17, 10)
          ..lineTo(12, 10)
          ..close();
      case _Glyph.wave:
        p
          ..moveTo(3, 12)
          ..cubicTo(6, 5.5, 9, 5.5, 12, 12)
          ..cubicTo(15, 18.5, 18, 18.5, 21, 12);
      case _Glyph.calendar:
        p
          ..moveTo(4.5, 6.5)
          ..lineTo(19.5, 6.5)
          ..lineTo(19.5, 19.5)
          ..lineTo(4.5, 19.5)
          ..close()
          ..moveTo(4.5, 10.5)
          ..lineTo(19.5, 10.5)
          ..moveTo(8.5, 4)
          ..lineTo(8.5, 8)
          ..moveTo(15.5, 4)
          ..lineTo(15.5, 8);
    }

    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
