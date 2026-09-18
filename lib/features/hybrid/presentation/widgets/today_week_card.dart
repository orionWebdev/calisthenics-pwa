import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../cardio/domain/week_ratio.dart';
import '../../../dashboard/domain/dashboard_data.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../../plans/domain/plan.dart';

/// Heute und diese Woche — **eine Karte, zwei Teile** (seit 18.09.2026).
///
/// ## Warum zusammen
///
/// Die Heute-Karte stand bis dahin im Kraft-Tab und eröffnete ihn mit einer
/// Planung, die es in ATEM nicht gibt: Termine kommen aus der Vorgänger-App,
/// anlegen kann man sie hier nicht. Im Kraft-Tab will man trainieren, nicht
/// den Tag lesen. Der Tag gehört auf den Hybrid-Tab, wo ohnehin steht, wie es
/// um einen steht — und dort direkt an die Woche, die ihn einordnet.
///
/// ## Warum getrennt lesbar
///
/// Zwei Aussagen in einer Karte verschwimmen leicht. Deshalb trägt der
/// **Tagesteil** oben den Akzent: Datum, Name des Termins, ein Startknopf im
/// Verlauf. Darunter trennt eine 1-px-Linie, und der **Wochenteil** bleibt
/// ruhig — eine Zahl in der Titelgrösse, der Rest in der dritten Textstufe.
/// Jeder Teil hat genau eine Hauptzahl; nichts blinkt um die Aufmerksamkeit.
///
/// ## Wann sie nicht rendert
///
/// Ohne Termin steht nur die Woche, ohne Minuten diese Woche nur der Tag —
/// keine leere Zeile, kein „nichts geplant". Ohne beides gibt [hasData]
/// `false` zurück, und der Bildschirm hört hier einfach früher auf.
class TodayWeekCard extends StatelessWidget {
  const TodayWeekCard({
    super.key,
    required this.ratio,
    this.session,
    this.plan,
    this.onStart,
    this.thinHint,
  });

  /// Der Termin von heute, oder `null`. Ohne [onStart] bleibt er verborgen —
  /// ein Tagesteil ohne Weg ins Training wäre eine Auskunft ohne Nutzen.
  final TodaySession? session;

  /// Der Plan hinter dem Termin — für „6 Übungen · ~45 min · Kraft".
  final Plan? plan;

  final WeekRatio ratio;
  final VoidCallback? onStart;

  /// Die Zeile „Bereitschaft ab 8 Einheiten." — nur, solange die Bereitschaft
  /// noch nicht trägt. Sie erklärt eine Lücke, die man sonst sucht.
  final String? thinHint;

  bool get _hasDay => session != null && onStart != null;
  bool get _hasWeek => ratio.totalCount > 0 || ratio.totalMinutes > 0;

  /// Ob die Karte überhaupt etwas zu sagen hat.
  static bool hasData({
    required WeekRatio ratio,
    TodaySession? session,
    VoidCallback? onStart,
  }) =>
      (session != null && onStart != null) ||
      ratio.totalCount > 0 ||
      ratio.totalMinutes > 0;

  @override
  Widget build(BuildContext context) {
    if (!_hasDay && !_hasWeek) return const SizedBox.shrink();

    return AtemCard.gradientBorder(
      padding: const EdgeInsets.all(AtemSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasDay) _day(context),
          if (_hasDay && _hasWeek) ...[
            const SizedBox(height: 14),
            const SizedBox(
                height: 1, child: ColoredBox(color: AtemColors.border)),
            const SizedBox(height: 14),
          ],
          if (_hasWeek) _week(context),
        ],
      ),
    );
  }

  Widget _day(BuildContext context) {
    final l10n = AppL10n.of(context);
    final today = session!;
    final minutes =
        plan?.estimatedDuration.inMinutes ?? today.duration.inMinutes;
    final meta = <String>[
      if (plan != null) l10n.exerciseCountShort(plan!.exerciseCount),
      l10n.durationApproxMinutes(minutes),
      if (trainingTypeLabel(l10n, plan?.type ?? today.intensityLabel)
          .isNotEmpty)
        trainingTypeLabel(l10n, plan?.type ?? today.intensityLabel),
    ]
        // Geschützte Leerzeichen in einer Angabe: Die Zeile bricht nur
        // zwischen Angaben um, nie „High / Intensity".
        .map((p) => p.replaceAll(' ', '\u00A0'))
        .join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nur die Beschriftung, kein Datum: Der Kopf des Tabs nennt den Tag
        // schon — zweimal dasselbe Datum untereinander las sich wie zwei
        // verschiedene Angaben (am Render gesehen, 18.09.2026).
        Text(l10n.workoutsTodayLabel.toUpperCase(),
            style: AtemType.labelMicro.of(context)),
        const SizedBox(height: 8),
        Text(today.title, style: AtemType.titleMedium.of(context)),
        const SizedBox(height: 4),
        Text(meta, style: AtemType.meta.of(context)),
        const SizedBox(height: 16),
        AtemButton.gradient(
          label: l10n.workoutsStart,
          // Der Planname gehört ins Label (Board 05, F).
          semanticLabel: '${l10n.workoutsStart}: ${today.title}',
          size: AtemButtonSize.compact,
          onPressed: onStart,
        ),
      ],
    );
  }

  Widget _week(BuildContext context) {
    final l10n = AppL10n.of(context);
    final parts = <String>[
      if (ratio.strength.count > 0)
        '${ratio.strength.count} ${l10n.typeStrength}',
      if (ratio.cardio.count > 0) '${ratio.cardio.count} ${l10n.typeCardio}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.hybridWeekTitle.toUpperCase(),
            style: AtemType.labelMicro.of(context)),
        const SizedBox(height: 8),
        Text(
          l10n.hybridWeekSummary(ratio.totalCount, ratio.totalMinutes),
          style: AtemType.titleLarge.of(context),
        ),
        if (parts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(parts.join(' · '), style: AtemType.meta.of(context)),
        ],
        if (thinHint != null) ...[
          const SizedBox(height: 12),
          Text(thinHint!, style: AtemType.labelSmall.of(context)),
        ],
      ],
    );
  }
}
