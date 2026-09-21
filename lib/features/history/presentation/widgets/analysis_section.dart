import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../application/history_providers.dart';
import '../../domain/muscle_balance.dart';
import '../../domain/strength_progress.dart';
import '../screens/session_list_screen.dart';
import 'estimated_max_card.dart';
import 'exercise_progress_card.dart';
import 'focus_distribution_card.dart';
import 'hard_sets_card.dart';
import 'muscle_balance_card.dart';
import '../../../pulse/presentation/widgets/zone_five_card.dart';
import 'weekly_sets_card.dart';
import 'wellness_trend_card.dart';

/// Der Abschnitt „Auswertung" — **Blöcke, die man nachrechnen kann.**
///
/// ## Was hier stand und warum es weg ist
///
/// Bis zum 16.09.2026 zeigte der Bildschirm die Formkurve und darunter die
/// Zerlegung des Formwerts in fünf Bestandteile. Am Gerät verstand sie
/// niemand: Ein Formwert sprang nach einer einzigen Einheit von 0 auf 75,
/// weil ein Untätigkeitsabzug von 70 Punkten über Nacht verschwand — eine
/// Klippe in der Formel, nicht im Training.
///
/// Hier stehen jetzt Metriken, die ihre Grundlage nennen: Fortschritt je
/// Übung, Sätze je Woche, harte Sätze, Muskelbalance, Verteilung, Befinden
/// und das geschätzte Maximum.
///
/// ## Jeder Block trägt seine eigene Schwelle
///
/// Es gibt keine gemeinsame „zu dünn"-Sperre. Die Muskelbalance braucht acht
/// Einheiten mit Übungen, das Maximum fünf Einheiten je Übung — jeder Block
/// zeigt seinen Stand selbst.
///
/// ## Unter der Schwelle: der Umriss, nicht der Wert (seit 20.09.2026)
///
/// Ein Block, dem Daten fehlen, zeigt die **Form** dessen, was kommt
/// ([AtemThresholdBlock] mit [AtemThresholdShape]) — darunter die Bedingung,
/// ab der er trägt, und den Fortschritt mit Nenner. Kein Wert, kein
/// Null-Chart, keine glatt aussehende Zahl aus zwei Einheiten. Der Umriss
/// **bewegt sich nicht**: Ein Puls sähe aus wie das Ladeskelett und müsste
/// bei reduzierter Bewegung halb eingefroren stehen bleiben.
///
/// Der Abschnitt **scrollt nicht selbst**: Er ist ein Stück der Seite.
class AnalysisSection extends ConsumerWidget {
  const AnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(sessionsProvider);
    final summary = ref.watch(historySummaryProvider);
    final reference = ref.watch(historyReferenceProvider);
    final sessions = async.value ?? const [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 0),
      child: async.when(
        // **Ein Ladegate je Seite, nicht vier** (Board 13, Entscheidung 11).
        // Es steht im Verlauf, der über diesem Thema liegt und dieselben
        // Daten braucht. Vier Skelette untereinander lasen sich wie vier
        // gestapelte Bildschirme — das Gegenteil des Umbaus.
        loading: () => const SizedBox.shrink(),
        // **Erfasstes und Abgeleitetes fallen getrennt aus.** Scheitert die
        // Rechnung, sind die Einheiten trotzdem vollständig da — und der Weg
        // zu ihnen bleibt offen.
        error: (_, __) => Column(
          children: [
            AtemErrorState(
              title: l10n.analysisErrorTitle,
              body: l10n.analysisErrorBody(summary.sessions),
              retryLabel: l10n.analysisErrorRetry,
              onRetry: () => ref.invalidate(sessionStreamProvider),
            ),
            // Der Ausweg zu den echten Daten (Board 06, A4/3): „Zur Liste"
            // existiert, damit niemand im Fehler festsitzt.
            AtemButton.ghost(
              label: l10n.analysisErrorToList,
              semanticLabel: l10n.analysisErrorToList,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const SessionListScreen()),
              ),
            ),
          ],
        ),
        data: (_) {
          if (sessions.isEmpty) {
            return AtemEmptyState(
              title: l10n.emptyHistoryTitle,
              body: l10n.emptyHistoryBody,
            );
          }

          final exercises = ref.watch(exercisesProvider).value ?? const [];
          final names = {for (final e in exercises) e.id: e.name};
          String nameOf(String id) => names[id] ?? id;

          final balance = MuscleBalance.compute(sessions, exercises, reference);
          final series = StrengthProgress.compute(sessions);
          final candidates =
              StrengthProgress.compute(sessions, minimumSessions: 1);

          // **Jeder Block rendert immer** (CLAUDE.md, seit 16.09.2026).
          // Reihenfolge nach der Frage, die jemand zuerst hat — was ist
          // besser geworden, wie viel trainiere ich, worauf, wie fühlt es
          // sich an —, die Schätzung zuletzt, weil sie am meisten
          // voraussetzt.
          final blocks = <Widget>[
            ExerciseProgressCard(sessions: sessions, reference: reference),
            WeeklySetsCard(sessions: sessions, reference: reference),
            HardSetsCard(sessions: sessions, reference: reference),
            // Zone 5 je Woche (auf Wunsch vom 21.09.2026): Die Zeit im
            // obersten Pulsbereich als eigener Graph, neben den harten Sätzen
            // — beides fragt, wie hart trainiert wurde.
            ZoneFiveCard(sessions: sessions, reference: reference),
            MuscleBalanceTile(
                balance: balance, alwaysShow: true, asPanel: true),
            FocusDistributionCard(sessions: sessions, reference: reference),
            WellnessTrendCard(sessions: sessions, reference: reference),
            EstimatedMaxCard(
              series: series,
              candidates: candidates,
              nameOf: nameOf,
              alwaysShow: true,
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < blocks.length; i++) ...[
                if (i > 0) const SizedBox(height: AtemSpacing.cardGap),
                AtemEntrance(index: i, child: blocks[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}
