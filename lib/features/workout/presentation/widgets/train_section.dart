import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../../dashboard/domain/dashboard_data.dart';
import '../../../exercises/presentation/screens/exercise_list_screen.dart';
import '../../../plans/application/pending_plan_deletion.dart';
import '../../../plans/application/plan_providers.dart';
import '../../../plans/domain/plan.dart';
import '../../../plans/presentation/plan_bits.dart';
import '../../../plans/presentation/screens/plan_form_screen.dart';
import '../../../plans/presentation/screens/plan_list_screen.dart';
import '../../../plans/presentation/start_sheet.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../strength/presentation/screens/strength_form_screen.dart';

/// Das Thema „Trainieren" — **Häufigkeit als Grösse** (Board 13, Abschnitt C).
///
/// ## Drei Gewichtsklassen, nach Häufigkeit belegt
///
/// 1. **Die Karte mit Gradient-Rand** (K2, genau eine je Bildschirm) trägt
///    den einen Weg, den die Seite verkauft: die für heute geplante Einheit.
///    Liegt kein Termin vor, rückt „Frei starten" auf diesen Platz und aus
///    dem Raster.
/// 2. **Die Halbkarten** (K3) tragen die regelmässigen Alternativen.
/// 3. **Die Zeilen mit Chevron** tragen die Wege auf Unterseiten und die
///    seltenen Handlungen — Übungskatalog und Nachtragen.
///
/// Das Raster ändert seine Belegung, nie die Klassenordnung. Ohne Termin und
/// ohne Plan trägt die Gradient-Karte „Frei starten", aus den Halbkarten wird
/// eine („Neuer Plan"), die Zeilen bleiben.
///
/// ## Warum der Katalog eine Zeile ist
///
/// Bis zum 17.09.2026 stand hier ein Block mit Suche, neun Muskelfiltern und
/// drei Treffern, weil „Übungen zu unpräsent" waren. Der Grund war richtig,
/// das Mittel nicht: Nachschlagen beantwortet nie die Frage „wie fange ich
/// an". Die Übungen haben seitdem eine eigene Unterseite, auf der Suche und
/// Filter vollständig sind; hierher gehört nur der Weg dorthin.
class TrainSection extends ConsumerWidget {
  const TrainSection({super.key, required this.onStart});

  /// Trägt die Startanfrage nach oben. Das Thema kennt den Runner nicht.
  final ValueChanged<StartRequest> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final dashboard = ref.watch(dashboardDataProvider);
    final plans = ref.watch(visiblePlansProvider).value ?? const <Plan>[];
    final session = dashboard.value?.session;
    final hasToday = session != null;
    final hasPlans = plans.isNotEmpty;

    final halves = <Widget>[
      if (hasToday)
        _HalfCard(
          icon: Icons.play_arrow_rounded,
          title: l10n.trainFreeTitle,
          body: l10n.trainFreeBody,
          semanticLabel: l10n.workoutsFreeStart,
          onTap: () => _startFree(context, ref),
        ),
      if (hasPlans)
        _HalfCard(
          icon: Icons.list_alt_rounded,
          title: l10n.workoutsPlanPick,
          body: l10n.trainPlanBody,
          semanticLabel: l10n.workoutsPlanPick,
          onTap: () => _openPlans(context),
        )
      else
        _HalfCard(
          icon: Icons.add,
          title: l10n.planFormNewTitle,
          body: l10n.workoutsTodayEmptyBody,
          semanticLabel: l10n.planFormNewTitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlanFormScreen()),
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 16, AtemSpacing.screenPadding, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dashboard.hasError)
            AtemErrorState(
              title: l10n.listErrorTitle,
              body: l10n.listErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(dashboardDataProvider),
            )
          else
            AtemEntrance(
              child: hasToday
                  ? _StartCard(
                      kicker: l10n.trainTodayKicker,
                      title: session.title,
                      meta: _todayMeta(l10n, plans, session),
                      onStart: () => _startToday(context, ref, session),
                    )
                  : _StartCard(
                      title: l10n.trainFreeTitle,
                      meta: l10n.trainFreeBody,
                      onStart: () => _startFree(context, ref),
                    ),
            ),
          const SizedBox(height: 10),
          AtemEntrance(index: 1, child: _HalfRow(cards: halves)),
          AtemEntrance(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ChevronRow(
                  label: l10n.trainCatalog,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExerciseListScreen(),
                    ),
                  ),
                ),
                _ChevronRow(
                  label: l10n.trainLogLater,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StrengthFormScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// „5 Übungen · ca. 40 Min" — aus dem Plan des Termins, sofern er noch
  /// existiert. Ohne Plan bleibt die Zeile leer statt zu raten.
  static String? _todayMeta(
      AppL10n l10n, List<Plan> plans, TodaySession session) {
    for (final plan in plans) {
      if (plan.id == session.planId) {
        return planMetaLine(l10n, plan, withDuration: true);
      }
    }
    return null;
  }

  Future<void> _startFree(BuildContext context, WidgetRef ref) async {
    final request = await StartSheet.show(
      context,
      restSeconds: ref.read(defaultRestSecondsProvider),
    );
    if (request != null) onStart(request);
  }

  /// Startet die geplante Einheit von heute — **mit ihrem Plan**.
  ///
  /// Findet sich der Plan nicht — gelöscht, oder ein Schnelleintrag —, wird
  /// daraus ein freies Training **mit erhaltenem Termin**: Die Einheit soll
  /// den Kalendereintrag trotzdem abhaken.
  Future<void> _startToday(
      BuildContext context, WidgetRef ref, TodaySession session) async {
    final all = ref.read(plansProvider).value ?? const <Plan>[];
    final plan = all.where((p) => p.id == session.planId).firstOrNull;

    final request = await StartSheet.show(
      context,
      plan: plan,
      scheduleId: session.id,
      restSeconds: ref.read(defaultRestSecondsProvider),
    );
    if (request != null) onStart(request);
  }

  void _openPlans(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlanListScreen(onStart: onStart),
        ),
      );
}

/// **K2 — die eine hervorgehobene Karte je Bildschirm.**
///
/// Kicker mit Punkt, Titel, Grundlage, ein Knopf über die volle Breite. Der
/// Kicker trägt den Bereichston und sagt, woher die Einheit kommt; ohne
/// Termin entfällt er, weil es nichts zu verorten gibt.
class _StartCard extends StatelessWidget {
  const _StartCard({
    this.kicker,
    required this.title,
    required this.meta,
    required this.onStart,
  });

  final String? kicker;
  final String title;
  final String? meta;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tone = AtemTabTheme.of(context);
    final label = kicker;

    return AtemCard.gradientBorder(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Semantics(
              label: label,
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    AtemStatusDot(color: tone, size: AtemDotSize.medium),
                    const SizedBox(width: 6),
                    // `Flexible`: Bei 200 % auf 320 dp ist „HEUTE GEPLANT"
                    // mit seiner Sperrung breiter als die Karte.
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        style: AtemType.labelMicro
                            .of(context)
                            .copyWith(color: tone),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(title, style: AtemType.titleMedium.of(context)),
          if (meta != null) ...[
            const SizedBox(height: 3),
            Text(meta!, style: AtemType.meta.of(context)),
          ],
          const SizedBox(height: 14),
          AtemButton.gradient(
            // **Der Marken-CTA bleibt der Magenta-Verlauf** (Board 13,
            // Farbteilung). Die Neonwelle trägt Daten, nicht Handlungen.
            gradient: AtemGradients.brandCta,
            label: l10n.sheetStart.toUpperCase(),
            semanticLabel: '${l10n.sheetStart}: $title',
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// Die Halbkarten — zwei je Reihe, eine über die volle Breite.
///
/// Bei 200 % Systemschrift auf 320 dp bleibt je Karte zu wenig Breite für ein
/// Wort; dann stehen sie untereinander (Board 13, Artboard „200 % auf
/// 320 dp": „Halbkarten stapeln").
class _HalfRow extends StatelessWidget {
  const _HalfRow({required this.cards});

  final List<Widget> cards;

  static const _sideBySide = 150.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (cards.length == 1) return cards.single;
          final half = (constraints.maxWidth - AtemSpacing.gridGap) / 2;
          if (half < _sideBySide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: AtemSpacing.gridGap),
                  cards[i],
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: AtemSpacing.gridGap),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        },
      );
}

/// **K3 — eine regelmässige Alternative.**
///
/// Symbolkasten im Bereichston, Titel, eine Zeile Grundlage. Der Ton sitzt
/// nur im Kasten: Vier getönte Flächen untereinander hoben sich gegenseitig
/// auf.
class _HalfCard extends StatelessWidget {
  const _HalfCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String semanticLabel;
  final VoidCallback onTap;

  static const minHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    final tone = AtemTabTheme.of(context);

    return AtemTappable(
      onTap: onTap,
      semanticLabel: '$semanticLabel. $body',
      minTapSize: const Size(0, minHeight),
      pressBuilder: (context, pressed) => AnimatedContainer(
        duration: AtemMotion.duration(context, AtemMotion.fast),
        decoration: BoxDecoration(
          borderRadius: AtemRadii.cardR,
          boxShadow: pressed ? AtemGlow.soft(tone, opacity: 0.3) : const [],
        ),
        child: _HalfBody(icon: icon, title: title, body: body, tone: tone),
      ),
      child: _HalfBody(icon: icon, title: title, body: body, tone: tone),
    );
  }
}

class _HalfBody extends StatelessWidget {
  const _HalfBody({
    required this.icon,
    required this.title,
    required this.body,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
        constraints:
            const BoxConstraints(minHeight: _HalfCard.minHeight),
        padding: const EdgeInsets.all(AtemSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: AtemRadii.cardR,
          border: Border.all(color: AtemColors.border),
        ),
        // `stretch`, nicht `start`: Sonst nimmt die Spalte nur die Breite
        // ihres längsten Wortes an, und die Karte stünde als Streifen mitten
        // in ihrer Spalte — `AtemTappable` legt sein Kind lose und mittig in
        // die Trefferfläche.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AtemRadii.iconBox),
                  border: Border.all(color: tone.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, size: 16, color: tone),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AtemType.titleMedium
                  .of(context)
                  .copyWith(fontSize: 13, height: 1.25),
            ),
            const SizedBox(height: 2),
            Text(body, style: AtemType.meta.of(context)),
          ],
        ),
      );
}

/// Ein Weg auf eine Unterseite oder eine seltene Handlung — die leiseste der
/// drei Gewichtsklassen.
class _ChevronRow extends StatelessWidget {
  const _ChevronRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 48 dp bei 100 %, rund 65 bei 200 % — das Board lässt die Zeilen
    // mitwachsen statt den Text zu quetschen.
    final height = math.max(
      48.0,
      MediaQuery.textScalerOf(context).scale(13) * 1.35 + 30,
    );

    return AtemTappable(
        onTap: onTap,
        semanticLabel: label,
        minTapSize: Size(0, height),
        alignment: Alignment.centerLeft,
        child: Container(
          height: height,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AtemColors.gridLine)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: AtemType.labelSmall.of(context)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right,
                  size: 20, color: AtemColors.textSecondary),
            ],
          ),
        ),
      );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
