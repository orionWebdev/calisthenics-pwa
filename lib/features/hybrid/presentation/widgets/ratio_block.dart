import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/tab_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../cardio/domain/iso_week.dart';
import '../../../cardio/domain/week_ratio.dart';
import '../../../cardio/presentation/cardio_ui.dart';

/// Zwei Spuren, ein Verhältnis — **niemals eine Summe** (Board 11, C1).
///
/// Der einzige neue Baustein des Moduls neben der Live-Uhr: der
/// Verhältnisbalken mit zwei Segmenten, mindestens 4 % je Segment, 14 dp hoch,
/// Radius 30. Kraft in Cyan, Ausdauer in Violet — **nur als Fläche**, nie als
/// Text (Vertrag R4). Unter jeder Prozentzahl steht die Fachgrösse der Spur,
/// damit sichtbar bleibt, dass die Prozente aus Zeit stammen.
///
/// Die Zeilen sind Wege (Sektion A): Kraft führt in den Kraft-Tab, Segment
/// Verlauf; Ausdauer in den Cardio-Tab, Segment Auswertung. Der Zielort steht
/// im Label, weil der Tap den Tab wechselt.
///
/// ## Eine Spur genügt (seit 16.09.2026)
///
/// C1/2 sah vor, dass der Block ohne die zweite Spur nicht rendert und ein
/// Kraft-Wochenblock an seine Stelle tritt. Am Gerät wirkte das wie ein
/// anderes Widget für dieselbe Frage. Jetzt steht der Block, sobald eine Spur
/// Minuten trägt: Die fehlende Spur ist im Balken eine 2-dp-Linie in
/// `border` — „gemessen: 0", nicht „nichts gemessen" — und ihre Zeile nennt
/// 0 % und 0 min. Kein Sollverhältnis, keine Aufforderung.
class RatioBlock extends ConsumerWidget {
  const RatioBlock({super.key, required this.ratio});

  final WeekRatio ratio;

  static const _minShare = 0.04;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final r = ratio;
    final week = IsoWeek.number(r.weekStart);
    final shift = r.shiftPp;

    final strengthShare = r.hasBothTracks
        ? r.strengthShare.clamp(_minShare, 1 - _minShare)
        : r.strengthShare;

    return AtemCard.list(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wie gerechnet wird und „Kein Sollverhältnis" stehen hinter dem ⓘ
          // (seit 17.09.2026). Sichtbar bleiben Balken, Zeilen, Grundlage und
          // die Verschiebung — sie gehören zur Zahl.
          AtemExplainHeader(
            title: l10n.ratioTitle,
            trailing:
                '${l10n.analysisWeeklyWeek(week)} · ${l10n.cardioWeekCount(r.totalCount)}',
            explanation: [l10n.ratioExplain],
          ),
          const SizedBox(height: 14),
          // Ein Knoten, keine zwei Segmente.
          Semantics(
            image: true,
            label: l10n.ratioA11y(r.strengthPercent, r.cardioPercent,
                r.totalMinutes, r.totalCount),
            child: ExcludeSemantics(
              child: SizedBox(
                height: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Segment(
                      color: AtemColors.cyan,
                      share: strengthShare,
                      empty: r.strength.minutes == 0,
                    ),
                    const SizedBox(width: 3),
                    _Segment(
                      color: AtemColors.violet,
                      share: 1 - strengthShare,
                      empty: r.cardio.minutes == 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TrackRow(
            color: AtemColors.cyan,
            name: l10n.typeStrength,
            percent: r.strengthPercent,
            minutes: r.strength.minutes,
            measure: l10n.ratioStrengthMeasure(
              AtemNumberField.format(context, r.strength.measure),
              r.strength.sets,
            ),
            shiftPp: shift,
            target: l10n.ratioOpenStrength,
            onTap: () => ref.read(appTabsProvider.notifier).jump(
                  AppTab.strength,
                  strengthSegment: StrengthSegment.history,
                ),
          ),
          const SizedBox(height: 6),
          _TrackRow(
            color: AtemColors.violet,
            name: l10n.typeCardio,
            percent: r.cardioPercent,
            minutes: r.cardio.minutes,
            measure: l10n.unitKilometers(formatKm(context, r.cardio.measure)),
            shiftPp: shift == null ? null : -shift,
            // Kein Sprung, solange Cardio nicht in der Leiste steht — die
            // Zeile bliebe sonst ein Tap-Ziel in einen Tab ohne Rückweg.
            target: AppTab.visible.contains(AppTab.cardio)
                ? l10n.ratioOpenCardio
                : null,
            onTap: AppTab.visible.contains(AppTab.cardio)
                ? () => ref.read(appTabsProvider.notifier).jump(
                      AppTab.cardio,
                      cardioSegment: CardioSegment.analysis,
                    )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.ratioBasis(r.totalMinutes, r.totalCount),
            style: AtemType.meta.of(context),
          ),
          const SizedBox(height: 4),
          Text(
            (shift == null
                ? l10n.ratioNoshift
                : '${shift >= 0 ? '▲' : '▼'} ${l10n.ratioShift(shift.abs().round().toString())} · ${l10n.typeStrength}'),
            style: AtemType.meta
                .of(context)
                .copyWith(color: AtemColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Ein Segment des Verhältnisbalkens.
///
/// Mit Minuten: eine Fläche in der Spurfarbe, Anteil nach Zeit. Ohne Minuten:
/// eine 24 dp breite, 2 dp hohe Linie in `border` — der leere Balken aus
/// Modul 11, kein Nullbalken und keine Lücke.
class _Segment extends StatelessWidget {
  const _Segment({
    required this.color,
    required this.share,
    required this.empty,
  });

  final Color color;
  final double share;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    if (empty) {
      return Container(
        width: 24,
        height: 2,
        decoration: BoxDecoration(
          color: AtemColors.border,
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }
    return Expanded(
      flex: math.max(1, (share * 1000).round()),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Eine Verhältniszeile: Punkt, Spur, Prozent, Fachgrösse, Verschiebung.
/// Mindestens 30 dp sichtbar, 48 dp Ziel; Werte nowrap.
class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.color,
    required this.name,
    required this.percent,
    required this.minutes,
    required this.measure,
    required this.shiftPp,
    required this.target,
    required this.onTap,
  });

  final Color color;
  final String name;
  final int percent;
  final int minutes;
  final String measure;
  final double? shiftPp;

  /// Ohne [onTap] ist die Zeile reine Anzeige: ein Semantics-Knoten mit
  /// denselben Werten, nur ohne Ziel und ohne Rolle „Knopf".
  final String? target;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final shift = shiftPp;
    final shiftText = shift == null || shift.abs().round() == 0
        ? null
        : '${shift >= 0 ? '▲' : '▼'} ${shift.abs().round()} pp';
    final shiftA11y = shift == null || shift.abs().round() == 0
        ? null
        : l10n.ratioShiftA11y('${shift.abs().round()}',
            shift >= 0 ? l10n.ratioShiftUp : l10n.ratioShiftDown);

    final semanticLabel = [
      l10n.ratioRowA11y(name, percent, minutes),
      measure,
      if (shiftA11y != null) shiftA11y,
      if (target != null) target!,
    ].join(', ');
    final onTap = this.onTap;

    if (onTap == null) {
      return Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: _content(context, l10n, shiftText),
      );
    }

    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: _content(context, l10n, shiftText),
    );
  }

  Widget _content(BuildContext context, AppL10n l10n, String? shiftText) =>
      Container(
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: AtemType.titleSmallOrDefault(context)),
                  Text(
                    '${l10n.durationMinutes(minutes)} · $measure',
                    style: AtemType.meta.of(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$percent %',
                    softWrap: false, style: AtemType.valueMedium.of(context)),
                if (shiftText != null)
                  Text(shiftText,
                      softWrap: false,
                      style: AtemType.labelMicro.of(context).copyWith(
                          color: AtemColors.textTertiary, letterSpacing: 0)),
              ],
            ),
          ],
        ),
      );
}
