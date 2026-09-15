import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import '../../../dashboard/domain/readiness_level.dart';
import '../../../dashboard/presentation/readiness_level_ui.dart';
import '../../../dashboard/presentation/readiness_zone_ui.dart';
import '../../../history/presentation/session_ui.dart';
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

    // Der Ton des Bereichs: er färbt das Symbol in der Leiste und
    // legt einen sehr schwachen Verlauf über den Grund.
    return AtemTabTheme(
      tone: AtemColors.tabHybrid,
      child: Scaffold(
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

    // Kopf wie im Artboard A3: „Hybrid" mit dem Datum rechts. Das
    // Profilbild bleibt der Zugang zu den Einstellungen (Modul 8) — klein,
    // ganz rechts.
    final header = _Header(
      user: data.user,
      date: reference,
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
            //
            // Ab hier läuft die Kaskade: Die Blöcke steigen versetzt ein, in
            // der Reihenfolge, in der man sie lesen soll.
            AtemEntrance(
              child: thin
                  ? _ThinWeek(ratio: ratio, sessions: sessions)
                  : _ReadinessCard(
                      readiness: data.readiness,
                      scoreAnimation: _score,
                      last: last,
                    ),
            ),
            const SizedBox(height: AtemSpacing.cardGap),

            // ---- Verhältnis (diese Woche). Mit beiden Spuren der Block;
            // mit einer der Kraft-Wochenblock plus Hinweis; ohne Minuten
            // nichts — der Bildschirm hört früher auf.
            if (ratio.hasBothTracks) ...[
              AtemEntrance(index: 1, child: RatioBlock(ratio: ratio)),
              const SizedBox(height: AtemSpacing.cardGap),
            ] else if (ratio.strength.minutes > 0) ...[
              AtemEntrance(
                index: 1,
                child: _StrengthWeek(ratio: ratio, onCardio: _openCardioForm),
              ),
              const SizedBox(height: AtemSpacing.cardGap),
            ],

            // ---- Regenerationszeile.
            AtemEntrance(
              index: 2,
              child: RecoveryRow(status: recovery, onAdd: _addRecovery),
            ),

            // ---- Formwert (vier Wochen), nur mit Trend.
            if (!thin)
              AtemEntrance(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _formBlock(context, sessions, reference),
                ),
              ),
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
                  Flexible(
                    child: Text(
                      [
                        l10n.historyFormOf(score),
                        if (trend != null) trend,
                      ].join(' · '),
                      textAlign: TextAlign.end,
                      style: AtemType.labelSmall.of(context),
                    ),
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

/// Der Kopf des Tabs: Titel, Datum, Profilbild (A3).
class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.date,
    required this.onProfile,
  });

  final UserSummary user;
  final DateTime date;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(l10n.tabHybrid, style: AtemType.titleLarge.of(context)),
        ),
        Flexible(
          child: Text(
            DateFormat.MMMEd(languageTag(context)).format(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtemType.meta.of(context),
          ),
        ),
        const SizedBox(width: 12),
        AtemTappable(
          onTap: onProfile,
          semanticLabel: l10n.settingsEntryA11y,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AtemColors.violet, AtemColors.magentaDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(user.initial, style: AtemType.labelMedium.of(context)),
          ),
        ),
      ],
    );
  }
}

/// Die Bereitschaftskarte — **Ring, Wort, Art der letzten Einheit** (A3).
///
/// Ring 56 dp in Zonenfarbe mit der Zahl innen; daneben „BEREITSCHAFT",
/// die Zone als Wort und darunter „Gestern Regeneration" — die Sprachregel
/// aus C2/3. Ab zwei Tagen „Seit n Tagen keine Einheit", als Tatsache ohne
/// Aufforderung. Ein Semantics-Knoten für alles drei.
class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.readiness,
    required this.scoreAnimation,
    required this.last,
  });

  final ReadinessSnapshot readiness;
  final Animation<double> scoreAnimation;
  final LastActivity? last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final zone = readiness.zone;
    final lastText = switch (last) {
      null => null,
      final l when l.daysAgo >= 2 => l10n.lastNone(l.daysAgo),
      LastActivity(session: RecoverySession(), :final daysAgo) =>
        l10n.lastRecovery(daysAgo),
      LastActivity(session: CardioSession(:final activity), :final daysAgo) =>
        l10n.lastCardio(activityLabel(l10n, activity), daysAgo),
      final l => l10n.lastStrength(l.daysAgo),
    };

    return AnimatedBuilder(
      animation: scoreAnimation,
      builder: (context, _) {
        final value = scoreAnimation.value;
        final level = ReadinessLevel.fromScore(value);
        final color = zone?.color ?? level.color;
        final word = zone?.label(l10n) ?? level.label(l10n);

        return AtemCard.list(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            label: [
              l10n.dashboardReadinessA11y(value.round(), word),
              if (lastText != null) lastText,
            ].join('. '),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CustomPaint(
                      painter: _RingPainter(value: value / 100, color: color),
                      child: Center(
                        child: Text(
                          '${value.round()}',
                          style: AtemType.valueLarge
                              .of(context)
                              .copyWith(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.dashboardReadinessSection.toUpperCase(),
                            style: AtemType.labelMicro.of(context)),
                        const SizedBox(height: 2),
                        Text(word,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtemType.titleMedium.of(context)),
                        if (lastText != null) ...[
                          const SizedBox(height: 4),
                          Text(lastText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AtemType.meta
                                  .of(context)
                                  .copyWith(color: AtemColors.textTertiary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Der Ring: Track in #16161F, Wert in Zonenfarbe, Start bei zwölf Uhr.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AtemColors.track,
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
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
            Text(parts.join(' · '),
                style: AtemType.meta.of(context)),
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
                  Text(measure,
                      style: AtemType.meta.of(context)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // **Der fehlende Teil ist eine Zeile, kein Kasten.**
          //
          // Hier stand eine ganze Notice mit Titel, Fliesstext und Aktion —
          // sie war höher als die Kachel, die sie erklärte, und liess den
          // Bildschirm so aussehen, als sei das Fehlen die Nachricht. Der
          // Satz genügt; der Weg daneben ist ein Knopf im Ton des
          // Cardio-Tabs, damit er als Weg dorthin erkennbar ist.
          const SizedBox(
              height: 1, child: ColoredBox(color: AtemColors.border)),
          const SizedBox(height: 12),
          Semantics(
            label: '${l10n.ratioSingleTitle}. ${l10n.ratioSingleBody}',
            child: ExcludeSemantics(
              child: Text(l10n.ratioSingleTitle,
                  style: AtemType.labelSmall.of(context)),
            ),
          ),
          const SizedBox(height: 10),
          AtemButton.outline(
            label: l10n.hybridEmptyCardio,
            semanticLabel: l10n.hybridEmptyCardio,
            size: AtemButtonSize.compact,
            accent: AtemColors.tabCardio,
            onPressed: onCardio,
          ),
        ],
      ),
    );
  }
}
