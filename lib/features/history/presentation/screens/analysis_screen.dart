import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/history_providers.dart';
import '../../domain/data_sufficiency.dart';
import '../../domain/history_summary.dart';
import '../../domain/training_form.dart';
import '../history_zone_ui.dart';
import '../widgets/form_chart.dart';

/// Die Auswertung: Formkurve über die Zeit, darunter die Zerlegung.
///
/// ## Warum die Zerlegung offen liegt
///
/// Ein Formwert von 16 sagt nichts. „Konstanz 17 von 35, Aktualität 0 von 15 —
/// letzte Einheit vor 50 Tagen" sagt alles, und zwar **was zu tun ist**.
///
/// Deshalb fünf Balken mit je einer Begründungszeile, kein Radar und kein
/// Aufklappen. Ein Radar macht fünf Zahlen zu einer Form, die niemand ablesen
/// kann; ein Accordion versteckt genau die Erklärung, für die der Bildschirm da
/// ist.
///
/// **Der Abzug steht getrennt**, nicht verrechnet: Er ist keine Komponente,
/// sondern eine Strafe, und wer ihn sieht, versteht warum die Summe nicht
/// aufgeht.
class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(sessionsProvider);
    final summary = ref.watch(historySummaryProvider);
    final reference = ref.watch(historyReferenceProvider);
    final sessions = async.value ?? const [];

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title:
            Text(l10n.analysisTitle, style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => const _Loading(),
          // **Erfasstes und Abgeleitetes fallen getrennt aus.** Scheitert die
          // Rechnung, sind die Einheiten trotzdem vollständig da — und der Weg
          // zu ihnen bleibt offen.
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtemSpacing.screenPadding),
            child: AtemErrorState(
              title: l10n.analysisErrorTitle,
              body: l10n.analysisErrorBody(summary.sessions),
              retryLabel: l10n.analysisErrorRetry,
              onRetry: () => ref.invalidate(sessionStreamProvider),
            ),
          ),
          data: (_) {
            if (sessions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AtemSpacing.screenPadding),
                child: AtemEmptyState(
                  title: l10n.historyEmptyTitle,
                  body: l10n.historyEmptyBody,
                ),
              );
            }

            if (!DataSufficiency.hasTrend(sessions, reference)) {
              return _Thin(sessions: sessions.length);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
              children: [
                AtemCard.list(
                  padding: const EdgeInsets.all(16),
                  child: FormChart(series: ref.watch(formSeriesProvider)),
                ),
                const SizedBox(height: 28),
                _Breakdown(form: summary.form, summary: summary),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
        child: AtemSkeleton(
          semanticLabel: AppL10n.of(context).dashboardLoadingA11y,
          blocks: const [
            AtemSkeletonBlock(height: 220),
            AtemSkeletonBlock(height: 180),
          ],
        ),
      );
}

/// Zu wenig für einen Trend — **aber nicht zu wenig für alles**.
///
/// Der Bildschirm sagt, wie viel noch fehlt, und zeigt daneben, was es schon
/// gibt. Eine reine Absage wäre eine Sackgasse.
class _Thin extends StatelessWidget {
  const _Thin({required this.sessions});

  final int sessions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
      children: [
        AtemCard.list(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.analysisThinTitle,
                  style: AtemType.titleMedium.of(context)),
              const SizedBox(height: 8),
              Text(
                l10n.analysisThinBody(
                  DataSufficiency.trendMinimumSessions,
                  DataSufficiency.trendMinimumDays,
                ),
                style: AtemType.labelSmall.of(context),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: l10n.analysisThinProgress(
                    sessions, DataSufficiency.trendMinimumSessions),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.analysisThinProgress(
                            sessions, DataSufficiency.trendMinimumSessions),
                        style: AtemType.valueMedium.of(context),
                      ),
                      const SizedBox(height: 8),
                      AtemProgressBar.share(
                        value: (sessions / DataSufficiency.trendMinimumSessions)
                            .clamp(0.0, 1.0),
                        semanticLabel: '',
                        accent: AtemColors.cyan,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.form, required this.summary});

  final FormResult form;
  final HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    final days = summary.daysSinceLast ?? 0;

    // **Jede Komponente mit ihrer Begründung.** Eine Zahlenreihe erklärt
    // nichts; „Aktualität 0 von 15 — letzte Einheit vor 50 Tagen" schon.
    final rows = <(String, int, int, String)>[
      (
        l10n.analysisCompConsistency,
        form.consistency,
        35,
        l10n.analysisWhyConsistency(summary.trainingDays, summary.spanDays),
      ),
      (
        l10n.analysisCompLoad,
        form.loadLevel,
        30,
        form.loadLevel == 0
            ? l10n.analysisWhyLoadNone
            : l10n.analysisWhyLoadRatio,
      ),
      (
        l10n.analysisCompRecency,
        form.recency,
        15,
        l10n.analysisWhyRecency(days)
      ),
      (
        l10n.analysisCompFitness,
        form.fitnessVsPeak,
        15,
        l10n.analysisWhyFitness
      ),
      (
        l10n.analysisCompToday,
        form.sessionBonus,
        8,
        form.sessionBonus == 0
            ? l10n.analysisWhyTodayNone
            : l10n.analysisWhyToday,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(l10n.analysisToday,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.labelMedium.of(context)),
            ),
            const SizedBox(width: 12),
            if (form.score case final score?)
              // Auch die Zahl muss nachgeben: „100/100" in 48 sp Mono ist bei
              // 200 % Schrift breiter als ein 320-dp-Gerät.
              Flexible(
                child: Text(
                  l10n.historyFormOf(score),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.valueLarge.of(context),
                ),
              ),
          ],
        ),
        if (form.trend.label(l10n) case final trend?) ...[
          const SizedBox(height: 4),
          Text(trend, style: AtemType.labelSmall.of(context)),
        ],
        const SizedBox(height: 16),
        for (final (label, value, max, why) in rows) ...[
          _Row(label: label, value: value, max: max, why: why),
          const SizedBox(height: 14),
        ],
        if (form.inactivityPenalty > 0)
          // Getrennt, nicht verrechnet: Ohne diese Zeile ginge die Summe der
          // fünf Balken nicht auf, und niemand wüsste warum.
          _Row(
            label: l10n.analysisCompPenalty,
            value: -form.inactivityPenalty,
            max: 0,
            why: l10n.analysisWhyPenalty(days),
            negative: true,
          ),
        if (form.recency < 15) ...[
          const SizedBox(height: 18),
          Text(
            l10n.analysisHintRecency(15 - form.recency),
            style: AtemType.labelSmall.of(context),
          ),
        ],
        const SizedBox(height: 24),
        // Die Rechnung selbst, einmal in Worten. Ohne sie bleibt die Zerlegung
        // eine Zahlenreihe, deren Summe nicht aufgeht.
        AtemCard.list(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.analysisExplainTitle,
                  style: AtemType.labelMedium.of(context)),
              const SizedBox(height: 8),
              Text(l10n.analysisExplainBody,
                  style: AtemType.labelSmall.of(context)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.max,
    required this.why,
    this.negative = false,
  });

  final String label;
  final int value;
  final int max;

  /// Woraus die Zahl entsteht. Ohne diese Zeile ist der Balken nur ein Balken.
  final String why;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final fraction = max <= 0 ? 1.0 : (value / max).clamp(0.0, 1.0);
    // Magenta erst, wenn wirklich nichts da ist — nicht schon bei „wenig".
    final color = negative
        ? AtemColors.magenta
        : (value == 0 ? AtemColors.magenta : AtemColors.textPrimary);

    final text =
        negative ? value.toString() : l10n.analysisCompValue(value, max);

    return Semantics(
      label: '$label: $text. $why',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelSmall.of(context)),
                ),
                const SizedBox(width: 12),
                Text(text,
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(color: color, letterSpacing: 0)),
              ],
            ),
            if (!negative) ...[
              const SizedBox(height: 6),
              AtemProgressBar.share(
                value: fraction,
                semanticLabel: '',
                accent: color,
              ),
            ],
            const SizedBox(height: 5),
            Text(why, style: AtemType.labelMicro.of(context)),
          ],
        ),
      ),
    );
  }
}
