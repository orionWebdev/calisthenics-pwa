import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/dashboard_data.dart';

/// Die vier Kacheln unter der Session-Card.
///
/// Sie waren im Vorgänger **nicht antippbar** — `onTapDown` war verdrahtet,
/// `onTap` fehlte. Sie federten beim Antippen ein und taten nichts.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.data,
    required this.onSelect,
  });

  final DashboardData data;

  /// Zielbereich der Navigation.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final n = data.nutrition;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  accent: AtemColors.cyan,
                  glyph: _Glyph.bars,
                  title: l10n.dashboardQuickWorkout,
                  body: l10n.dashboardQuickSets(
                      data.workoutLog.headline, data.workoutLog.totalSets),
                  onTap: () => onSelect(1),
                ),
              ),
              const SizedBox(width: AtemSpacing.gridGap),
              Expanded(
                child: _Tile(
                  accent: AtemColors.magenta,
                  glyph: _Glyph.bolt,
                  title: l10n.dashboardQuickNutrition,
                  body: l10n.dashboardProteinOf(n.proteinGrams) +
                      l10n.dashboardProteinGoal(n.proteinTargetGrams),
                  semanticBody: l10n.dashboardProteinA11y(
                      n.proteinGrams, n.proteinTargetGrams),
                  trailing: AtemProgressRing(
                    value: n.progress,
                    label: '${n.progressPercent}%',
                    semanticLabel: l10n.dashboardProteinA11y(
                        n.proteinGrams, n.proteinTargetGrams),
                  ),
                  onTap: () => onSelect(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AtemSpacing.gridGap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Tile(
                  accent: AtemColors.green,
                  glyph: _Glyph.wave,
                  title: l10n.dashboardQuickRecovery,
                  body: data.recovery.liveHrvMs == null
                      ? l10n
                          .dashboardBreathwork(data.recovery.breathworkMinutes)
                      : l10n.dashboardLiveHrv(data.recovery.liveHrvMs!,
                          data.recovery.breathworkMinutes),
                  onTap: () => onSelect(3),
                ),
              ),
              const SizedBox(width: AtemSpacing.gridGap),
              Expanded(
                child: _Tile(
                  accent: AtemColors.violet,
                  glyph: _Glyph.calendar,
                  title: l10n.dashboardQuickPeriod,
                  body: l10n.dashboardPhaseWeek(
                    data.periodization.currentWeek,
                    data.periodization.totalWeeks,
                    data.periodization.phaseName,
                  ),
                  footer: AtemProgressBar.share(
                    value: data.periodization.progress,
                    semanticLabel: l10n.dashboardPhaseA11y(
                      data.periodization.currentWeek,
                      data.periodization.totalWeeks,
                      data.periodization.phaseName,
                    ),
                    gradient: AtemGradients.accent(AtemColors.violet),
                  ),
                  onTap: () => onSelect(2),
                ),
              ),
            ],
          ),
        ),
      ],
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
    this.semanticBody,
    this.trailing,
    this.footer,
  });

  final Color accent;
  final _Glyph glyph;
  final String title;
  final String body;

  /// Falls der sichtbare Text vorgelesen schlecht klingt.
  final String? semanticBody;

  final Widget? trailing;
  final Widget? footer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtemCard.list(
        onTap: onTap,
        semanticLabel: '$title. ${semanticBody ?? body}',
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
            if (footer != null) ...[const SizedBox(height: 8), footer!],
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
