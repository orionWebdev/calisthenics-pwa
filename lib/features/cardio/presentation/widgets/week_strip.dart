import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/iso_week.dart';
import '../../domain/weekly_distance.dart';
import '../cardio_ui.dart';

/// Wochenkilometer als Streifen — **der Monatsstreifen aus Modul 6, auf
/// Wochen** (Board 11, B3/1).
///
/// Gleiche Balkenlogik, gleiche Lückenregel, gleiche 30er-Radien. Eine Woche
/// ohne Einheit ist ein 2-dp-Balken in `#232334`, kein Nullbalken: „gemessen:
/// 0" ist etwas anderes als „nichts gemessen". Die laufende Woche ist cyan
/// gefüllt und trägt „laufend" — sonst liest man einen Einbruch, wo nur
/// Dienstag ist.
///
/// Ein Semantics-Knoten für acht Balken, und die Lücke wird genannt — ein
/// stiller 2-dp-Balken wäre sonst unsichtbar **und** unhörbar.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.distance});

  final WeeklyDistance distance;

  static const _maxHeight = 76.0;
  static const _minHeight = 34.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final weeks = distance.weeks;
    if (weeks.isEmpty) return const SizedBox.shrink();

    final peak = weeks.fold<double>(0, (a, w) => math.max(a, w.km));
    final filled = weeks.where((w) => !w.isEmpty).map((w) => w.km);
    final low = filled.isEmpty ? 0.0 : filled.reduce(math.min);
    final high = filled.isEmpty ? 0.0 : filled.reduce(math.max);

    final gaps = [
      for (final w in weeks)
        if (w.isEmpty) l10n.analysisWeeklyGapA11y(IsoWeek.number(w.weekStart)),
    ];

    return Semantics(
      image: true,
      label: [
        l10n.analysisWeeklyA11y(formatKm(context, low), formatKm(context, high)),
        ...gaps,
      ].join(' '),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _maxHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < weeks.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(child: _Bar(week: weeks[i], peak: peak)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < weeks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      weeks[i].isCurrent
                          ? l10n.analysisWeeklyCurrent
                          : '${IsoWeek.number(weeks[i].weekStart)}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelDeco.of(context).copyWith(
                            color: weeks[i].isCurrent
                                ? AtemColors.cyan
                                : AtemColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.week, required this.peak});

  final WeekDistance week;
  final double peak;

  @override
  Widget build(BuildContext context) {
    if (week.isEmpty) {
      return Container(
        height: 2,
        decoration: BoxDecoration(
          color: AtemColors.border,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
        ),
      );
    }
    final fraction = peak <= 0 ? 0.0 : week.km / peak;
    final height = WeekStrip._minHeight +
        (WeekStrip._maxHeight - WeekStrip._minHeight) * fraction;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: week.isCurrent ? AtemColors.cyan : AtemColors.track,
        borderRadius: BorderRadius.circular(AtemRadii.pill),
        border: week.isCurrent ? null : Border.all(color: AtemColors.border),
      ),
    );
  }
}
