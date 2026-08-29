import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/tab_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../cardio/domain/last_activity.dart';
import '../../../cardio/domain/week_ratio.dart';
import '../../../cardio/presentation/cardio_ui.dart';
import '../../../cardio/presentation/screens/cardio_form_screen.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../../dashboard/domain/dashboard_data.dart';
import '../../../dashboard/presentation/widgets/cyber_header.dart';
import '../../../dashboard/presentation/widgets/readiness_hero.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/data_sufficiency.dart';
import '../../../history/domain/form_series.dart';
import '../../../history/domain/training_load.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/history_zone_ui.dart';
import '../../../history/presentation/screens/analysis_screen.dart';
import '../../../history/presentation/widgets/form_chart.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/ratio_block.dart';
import '../widgets/recovery_row.dart';
import '../widgets/recovery_sheet.dart';

/// Der Hybrid-Tab — **Start und Analyse verschmolzen, ohne Doppelung**
/// (Board 11, A3).
///
/// Jede Zeitspanne kommt genau einmal vor: Bereitschaft (heute), Verhältnis
/// (diese Woche), Formwert (vier Wochen), Regenerationszeile. Das war die
/// Doppelung zwischen Start und Analyse — beide zeigten die Woche, beide die
/// Form.
///
/// ## Was hier nicht mehr steht
///
/// Die Wochenkurve, die Session-Karte und die vier Kacheln des früheren
/// Start-Tabs. Die Wochenkurve war eine zweite Sicht auf dieselbe Woche wie das
/// Verhältnis; die Session-Karte gehört in den Kraft-Tab, wo gestartet wird;
/// die Kacheln zeigten Zahlen, die der Verlauf besser zeigt. Ein Block ohne
/// eigene Zeitspanne rendert hier nicht.
class HybridScreen extends ConsumerStatefulWidget {
  const HybridScreen({super.key});

  /// Bereitschaft und Formwert ab so vielen Einheiten (C3/1).
  static const minimumSessions = 8;

  @override
  ConsumerState<HybridScreen> createState() => _HybridScreenState();
}

class _HybridScreenState extends ConsumerState<HybridScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scoreController = AnimationController(
    vsync: this,
    duration: AtemMotion.countUp,
  );
  Animation<double> _score = const AlwaysStoppedAnimation(0);
  double _lastScore = 0;

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  void _animateScoreTo(double target) {
    if ((target - _lastScore).abs() < 0.01 && _scoreController.isCompleted) {
      return;
    }
    _score = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _scoreController, curve: AtemMotion.curve),
    );
    _lastScore = target;
    _scoreController.duration =
        AtemMotion.duration(context, AtemMotion.countUp);
    _scoreController.forward(from: 0);
  }

  Future<void> _addRecovery() async {
    await RecoverySheet.show(context);
  }

  void _openCardioForm() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CardioFormScreen()),
      );

  void _openStrength() => ref
      .read(appTabsProvider.notifier)
      .jump(AppTab.strength, strengthSegment: StrengthSegment.train);

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(dashboardDataProvider);
    final sessionsAsync = ref.watch(sessionsProvider);

    ref.listen<AsyncValue<DashboardData>>(dashboardDataProvider, (_, next) {
      final score = next.value?.readiness.score;
      if (score != null) _animateScoreTo(score);
    });

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: async.when(
        loading: () => Padding(
          padding: EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding,
              MediaQuery.paddingOf(context).top + 16,
              AtemSpacing.screenPadding,
              130),
          child: AtemSkeleton(
            semanticLabel: l10n.dashboardLoadingA11y,
            blocks: const [
              AtemSkeletonBlock(height: 64, radius: 14),
              AtemSkeletonBlock(height: 360),
              AtemSkeletonBlock(height: 210),
              AtemSkeletonBlock(height: 64),
            ],
          ),
        ),
        error: (e, _) => AtemErrorState(
          title: l10n.dashboardNotAvailable,
          body: l10n.errorsLoadFailed,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(dashboardDataProvider),
        ),
        data: (data) => _content(
          context,
          data,
          sessionsAsync.value ?? const [],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    DashboardData data,
    List<TrainingSession> sessions,
  ) {
    final l10n = AppL10n.of(context);
    final reference = ref.watch(historyReferenceProvider);
    final ratio = WeekRatio.compute(sessions, reference);
    final recovery = RecoveryStatus.of(sessions, reference);
    final last = LastActivity.of(sessions, reference);
    final thin = sessions.length < HybridScreen.minimumSessions;

    final header = CyberHeader(
      user: data.user,
      // Kein Platz in der Leiste: Einstellungen tut man selten. Das
      // Profilbild ist die Stelle, an der man sie sucht (Modul 8).
      onProfile: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      ),
    );

    return RefreshIndicator(
      color: AtemColors.cyan,
      backgroundColor: AtemColors.surfaceRaised,
      onRefresh: () async {
        ref.invalidate(dashboardDataProvider);
        ref.invalidate(sessionStreamProvider);
      },
      child: ListView(
        padding: EdgeInsets.only(
          left: AtemSpacing.screenPadding,
          right: AtemSpacing.screenPadding,
          top: MediaQuery.paddingOf(context).top + 8,
          bottom: 130 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          header,
          const SizedBox(height: AtemSpacing.cardGap),

          // ---- Leer: null Einheiten gesamt (C3/2). Beide Spuren sind
          // gleich weit entfernt — der einzige Zustand mit zwei gleichrangigen
          // Knöpfen. Keine Regenerationszeile: ohne Training ist Regeneration
          // von nichts eine Erholung.
          if (sessions.isEmpty) ...[
            AtemCard.list(
              padding: const EdgeInsets.all(18),
              child: AtemEmptyState(
                title: l10n.hybridEmptyTitle,
                body: l10n.hybridEmptyBody,
              ),
            ),
            const SizedBox(height: 10),
            AtemButton.gradient(
              label: l10n.hybridEmptyStrength,
              semanticLabel: l10n.hybridEmptyStrength,
              onPressed: _openStrength,
            ),
            const SizedBox(height: 10),
            AtemButton.outline(
              label: l10n.hybridEmptyCardio,
              semanticLabel: l10n.hybridEmptyCardio,
              onPressed: _openCardioForm,
            ),
          ] else ...[
            // ---- Bereitschaft (heute), oder der dünne Wochenblock (C3/1).
            if (thin)
              _ThinWeek(ratio: ratio, sessions: sessions)
            else ...[
              ReadinessHero(
                readiness: data.readiness,
                scoreAnimation: _score,
              ),
              if (last != null) ...[
                const SizedBox(height: 8),
                _LastActivityLine(last: last),
              ],
            ],
            const SizedBox(height: AtemSpacing.cardGap),

            // ---- Verhältnis (diese Woche). Mit beiden Spuren der Block;
            // mit einer der Kraft-Wochenblock plus Hinweis; ohne Minuten
            // nichts — der Bildschirm hört früher auf.
            if (ratio.hasBothTracks) ...[
              RatioBlock(ratio: ratio),
              const SizedBox(height: AtemSpacing.cardGap),
            ] else if (ratio.strength.minutes > 0) ...[
              _StrengthWeek(ratio: ratio, onCardio: _openCardioForm),
              const SizedBox(height: AtemSpacing.cardGap),
            ],

            // ---- Regenerationszeile.
            RecoveryRow(status: recovery, onAdd: _addRecovery),

            // ---- Formwert (vier Wochen), nur mit Trend.
            if (!thin) ..._formBlock(context, sessions, reference),
          ],
        ],
      ),
    );
  }

  List<Widget> _formBlock(
    BuildContext context,
    List<TrainingSession> sessions,
    DateTime reference,
  ) {
    final l10n = AppL10n.of(context);
    if (!DataSufficiency.hasTrend(sessions, reference)) return const [];

    final summary = ref.watch(historySummaryProvider);
    final weight = ref.watch(bodyWeightProvider).value ?? 0;
    final series = FormSeries.compute(
      sessions,
      reference,
      days: 28,
      context: LoadContext(bodyWeightKg: weight),
    );
    if (series.isEmpty) return const [];
    final form = summary.form;
    final trend = form.trend.label(l10n);

    return [
      const SizedBox(height: AtemSpacing.cardGap),
      AtemCard.list(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(l10n.hybridFormSection,
                      style: AtemType.titleMedium.of(context)),
                ),
                if (form.score case final score?)
                  Text(
                    [
                      l10n.historyFormOf(score),
                      if (trend != null) trend,
                    ].join(' · '),
                    style: AtemType.labelSmall.of(context),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FormChart(series: series),
          ],
        ),
      ),
      const SizedBox(height: 12),
      AtemButton.outline(
        label: l10n.historyAnalysisOpen,
        semanticLabel: l10n.historyAnalysisOpen,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AnalysisScreen()),
        ),
      ),
    ];
  }
}

/// „Gestern Regeneration" — die Art der letzten Einheit, nicht nur ihr
/// Datum (Sprachregel C2/3). Ab zwei Tagen: „Seit n Tagen keine Einheit",
/// als Tatsache ohne Aufforderung — kein Ausrufezeichen, kein Magenta.
class _LastActivityLine extends StatelessWidget {
  const _LastActivityLine({required this.last});

  final LastActivity last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final days = last.daysAgo;
    final text = days >= 2
        ? l10n.lastNone(days)
        : switch (last.session) {
            RecoverySession() => l10n.lastRecovery(days),
            CardioSession(:final activity) =>
              l10n.lastCardio(activityLabel(l10n, activity), days),
            _ => l10n.lastStrength(days),
          };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text.toUpperCase(),
          style: AtemType.labelMicro.of(context)),
    );
  }
}

/// Der dünne Hybrid-Tab: was gezählt ist, nicht, was daraus folgt (C3/1).
class _ThinWeek extends StatelessWidget {
  const _ThinWeek({required this.ratio, required this.sessions});

  final WeekRatio ratio;
  final List<TrainingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final parts = <String>[
      if (ratio.strength.count > 0)
        '${ratio.strength.count} ${l10n.typeStrength}',
      if (ratio.cardio.count > 0) '${ratio.cardio.count} ${l10n.typeCardio}',
    ];

    return AtemCard.gradientBorder(
      child: Column(
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
            Text(parts.join(' · ').toUpperCase(),
                style: AtemType.labelMicro.of(context)),
          ],
          const SizedBox(height: 12),
          Text(l10n.hybridWeekThin(HybridScreen.minimumSessions),
              style: AtemType.labelSmall.of(context)),
        ],
      ),
    );
  }
}

/// Kein Verhältnis — nur eine Spur (C1/2). An die Stelle des Blocks tritt
/// der Kraft-Wochenblock; die eine Hinweiszeile ist erlaubt, weil sie den
/// einzigen Weg zur Gegenspur trägt.
class _StrengthWeek extends StatelessWidget {
  const _StrengthWeek({required this.ratio, required this.onCardio});

  final WeekRatio ratio;
  final VoidCallback onCardio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final s = ratio.strength;
    final measure = l10n.ratioStrengthMeasure(
        AtemNumberField.format(context, s.measure), s.sets);

    return AtemCard.list(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label:
                '${l10n.ratioStrengthWeek}, ${l10n.hybridWeekSummary(s.count, s.minutes)}, $measure',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.ratioStrengthWeek,
                      style: AtemType.titleMedium.of(context)),
                  const SizedBox(height: 6),
                  Text(l10n.hybridWeekSummary(s.count, s.minutes),
                      style: AtemType.valueMedium.of(context)),
                  const SizedBox(height: 2),
                  Text(measure.toUpperCase(),
                      style: AtemType.labelMicro.of(context)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AtemNotice(
            title: l10n.ratioSingleTitle,
            body: l10n.ratioSingleBody,
            semanticLabel: '${l10n.ratioSingleTitle}. ${l10n.ratioSingleBody}',
            actionLabel: l10n.hybridEmptyCardio,
            onAction: onCardio,
          ),
        ],
      ),
    );
  }
}
