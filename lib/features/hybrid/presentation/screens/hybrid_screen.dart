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
import '../../../history/domain/training_session.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/training_heatmap.dart';
import '../widgets/ratio_block.dart';
import '../widgets/recovery_row.dart';
import '../widgets/recovery_sheet.dart';
import '../widgets/time_split_card.dart';
import '../widgets/training_heatmap_card.dart';

/// Der Hybrid-Tab — **Start und Analyse verschmolzen, ohne Doppelung**
/// (Board 11, A3).
///
/// Jede Zeitspanne kommt genau einmal vor: Bereitschaft (heute), Verhältnis
/// (diese Woche), Trainingszeit (14 oder 28 Tage), Trainingstage (zwölf
/// Wochen), Regenerationszeile. Das war die Doppelung zwischen Start und
/// Analyse — beide zeigten die Woche, beide die Form.
///
/// ## Der Formwert ist weg (16.09.2026)
///
/// Bis dahin stand unter dem Verhältnis die Formkurve, 0–100 aus fünf
/// Bestandteilen. Nach 16 Tagen Pause sprang sie mit einer Einheit von 0 auf
/// 75 — rechnerisch richtig, für niemanden erklärbar. An ihrer Stelle stehen
/// zwei Zählungen nach Masterplan: die Trainingszeit je Spur und die
/// Trainingstage als Raster. Beide nennen ihren Nenner und urteilen nicht.
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

  /// Bereitschaft ab so vielen Einheiten (C3/1). Trainingszeit und
  /// Trainingstage zählen darunter schon — sie behaupten nichts.
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

            // ---- Verhältnis (diese Woche). Sobald eine Spur Minuten
            // trägt, steht der Block — die fehlende Spur ist darin eine
            // 2-dp-Linie und „0 min", kein eigener Wochenblock mehr (bis
            // 16.09.2026 stand hier bei einer Spur „Kraft diese Woche" mit
            // einem Cardio-Knopf; der Nutzer wollte das Verhältnis sehen).
            // Ohne Minuten nichts — der Bildschirm hört früher auf.
            if (ratio.totalMinutes > 0) ...[
              AtemEntrance(index: 1, child: RatioBlock(ratio: ratio)),
              const SizedBox(height: AtemSpacing.cardGap),
            ],

            // ---- Regenerationszeile — nur, solange Regeneration einen
            // Platz in der Leiste hat. Kein Platzhalter.
            if (AppTab.visible.contains(AppTab.recovery))
              AtemEntrance(
                index: 2,
                child: RecoveryRow(status: recovery, onAdd: _addRecovery),
              ),

            // ---- Trainingszeit (14 | 28 Tage) und Trainingstage (zwölf
            // Wochen). Keine Mindestzahl: Beide zählen nur. Ein Block ohne
            // Daten rendert nicht — der Bildschirm hört früher auf.
            ..._countBlocks(context, sessions, reference),
          ],
        ],
      ),
    );
  }

  List<Widget> _countBlocks(
    BuildContext context,
    List<TrainingSession> sessions,
    DateTime reference,
  ) {
    final heatmap = TrainingHeatmap.compute(sessions, reference);
    final hasTime = TimeSplitCard.hasData(sessions, reference);
    final hasDays = heatmap.trainedDays > 0;
    if (!hasTime && !hasDays) return const [];

    return [
      if (hasTime) ...[
        const SizedBox(height: AtemSpacing.cardGap),
        AtemEntrance(
          index: 3,
          child: TimeSplitCard(sessions: sessions, reference: reference),
        ),
      ],
      if (hasDays) ...[
        const SizedBox(height: AtemSpacing.cardGap),
        AtemEntrance(
          index: 4,
          child: TrainingHeatmapCard(heatmap: heatmap),
        ),
      ],
      // Kein Weg zur Kraft-Auswertung mehr hier (seit 16.09.2026): Sie steht
      // im Kraft-Tab, oben im Verlauf. Hybrid zeigt, was beide Spuren
      // gemeinsam haben.
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
        // Datum und Profilbild sitzen rechtsbündig: das Datum direkt links
        // vom Bild, ohne Restraum dazwischen; das Bild bündig mit dem
        // rechten Rand der Karten darunter.
        Flexible(
          child: Text(
            DateFormat.MMMEd(languageTag(context)).format(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AtemType.meta.of(context),
          ),
        ),
        const SizedBox(width: 10),
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
            Text(parts.join(' · '), style: AtemType.meta.of(context)),
          ],
          const SizedBox(height: 12),
          Text(l10n.hybridWeekThin(HybridScreen.minimumSessions),
              style: AtemType.labelSmall.of(context)),
        ],
      ),
    );
  }
}
