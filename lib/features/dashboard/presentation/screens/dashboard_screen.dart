import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../workout/application/workout_providers.dart';
import '../../../workout/domain/workout_start.dart';
import '../../../workout/presentation/screens/workout_runner_screen.dart';
import '../../application/dashboard_providers.dart';
import '../../domain/dashboard_data.dart';
import '../widgets/cyber_header.dart';
import '../widgets/quick_actions.dart';
import '../widgets/readiness_hero.dart';
import '../widgets/session_card.dart';

/// ATEM Performance Dashboard.
///
/// Der Screen orchestriert: Score-Animation, Navigation, Bausteine. Alles
/// Sichtbare liegt in `presentation/widgets/`.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.onSelectTab});

  /// Wechselt den Tab. Der Bildschirm besitzt die Navigation **nicht** — sie
  /// liegt im Rahmen darüber, sonst gehörte sie einem ihrer eigenen Ziele.
  final ValueChanged<int> onSelectTab;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
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

  Future<void> _onToggleSession(TodaySession session) async {
    final wasRunning = ref.read(sessionTimerProvider).isRunning;
    ref.read(sessionTimerProvider.notifier).toggle();

    // Beim Start direkt in den Runner — dort wird trainiert. Der Timer läuft
    // im Notifier weiter und zeigt nach der Rückkehr „SESSION LÄUFT".
    //
    // Plan **und** Termin wandern mit: der Plan, damit die Übungen ankommen;
    // der Termin, damit er nach dem Speichern als erledigt gilt.
    if (!wasRunning && ref.read(sessionTimerProvider).isRunning && mounted) {
      await Navigator.of(context).pushNamed(
        WorkoutRunnerScreen.routeName,
        arguments: WorkoutStart(
          planId: session.planId,
          scheduleId: session.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(dashboardDataProvider);

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
              AtemSkeletonBlock(height: 180),
            ],
          ),
        ),
        error: (e, _) => AtemErrorState(
          title: l10n.dashboardNotAvailable,
          body: l10n.errorsLoadFailed,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(dashboardDataProvider),
        ),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(DashboardData data) {
    final l10n = AppL10n.of(context);

    return RefreshIndicator(
      color: AtemColors.cyan,
      backgroundColor: AtemColors.surfaceRaised,
      onRefresh: () async => ref.invalidate(dashboardDataProvider),
      child: ListView(
        padding: EdgeInsets.only(
          left: AtemSpacing.screenPadding,
          right: AtemSpacing.screenPadding,
          top: MediaQuery.paddingOf(context).top + 8,
          // Freiraum für die schwebende Navigation, inklusive Systemleiste.
          bottom: 130 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          CyberHeader(user: data.user, onProfile: () => _select(4)),
          const SizedBox(height: AtemSpacing.cardGap),
          ReadinessHero(
            readiness: data.readiness,
            scoreAnimation: _score,
          ),
          const SizedBox(height: AtemSpacing.cardGap),
          // **Deckend, nicht Glas.** Hinter dieser Karte liegt der blanke
          // Canvas — es scheint nichts durch, was ein Blur zeigen könnte. Ein
          // BackdropFilter in einer scrollenden Liste ist dagegen der teuerste
          // Fall überhaupt: Der Hintergrund wird bei jedem Frame neu
          // abgetastet und weichgezeichnet. Vertrag Modul 2: „In Listen gehört
          // AtemCard.list hin."
          AtemCard.list(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: AtemChartCard(
              title: l10n.dashboardChartSection,
              semanticSummary: l10n.dashboardChartA11y,
              axisLabels: l10n.dashboardWeekdays.split(','),
              highlightIndex: data.performance.todayIndex,
              tooltip: _tooltip(l10n, data),
              series: [
                AtemChartSeries(
                  label: l10n.dashboardSeriesLoad,
                  values: [for (final d in data.performance.days) d.load],
                  color: AtemColors.cyan,
                  style: AtemSeriesStyle.primary,
                ),
                AtemChartSeries(
                  label: l10n.dashboardSeriesStrain,
                  values: [for (final d in data.performance.days) d.strain],
                  color: AtemColors.magenta,
                  style: AtemSeriesStyle.dashed,
                ),
                AtemChartSeries(
                  label: l10n.dashboardSeriesRecovery,
                  values: [for (final d in data.performance.days) d.recovery],
                  color: AtemColors.green,
                  style: AtemSeriesStyle.angled,
                ),
              ],
            ),
          ),
          const SizedBox(height: AtemSpacing.cardGap),
          if (data.session != null)
            SessionCard(
              session: data.session!,
              elapsed: ref.watch(sessionTimerProvider).elapsed,
              onToggle: () => _onToggleSession(data.session!),
            )
          else
            AtemCard.list(
              padding: const EdgeInsets.all(18),
              child: AtemEmptyState(
                title: l10n.dashboardSessionNone,
                body: l10n.dashboardSessionNoneHint,
              ),
            ),
          const SizedBox(height: AtemSpacing.cardGap),
          QuickActions(data: data, onSelect: _select),
        ],
      ),
    );
  }

  String? _tooltip(AppL10n l10n, DashboardData data) {
    final today = data.performance.today;
    final i = data.performance.todayIndex;
    if (today == null || i < 0) return null;
    final labels = l10n.dashboardWeekdays.split(',');
    if (i >= labels.length) return null;
    return l10n.dashboardChartToday(labels[i], today.load.round());
  }

  void _select(int index) => widget.onSelectTab(index);
}
