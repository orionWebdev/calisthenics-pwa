import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../application/history_providers.dart';
import '../../domain/muscle_balance.dart';
import '../../domain/strength_progress.dart';
import '../widgets/estimated_max_card.dart';
import '../widgets/muscle_balance_card.dart';
import 'session_list_screen.dart';

/// Die Kraft-Auswertung — **zwei Blöcke, die man nachrechnen kann.**
///
/// ## Was hier stand und warum es weg ist
///
/// Bis zum 16.09.2026 zeigte der Bildschirm die Formkurve und darunter die
/// Zerlegung des Formwerts in fünf Bestandteile. Am Gerät verstand sie
/// niemand: Ein Formwert sprang nach einer einzigen Einheit von 0 auf 75,
/// weil ein Untätigkeitsabzug von 70 Punkten über Nacht verschwand — eine
/// Klippe in der Formel, nicht im Training. Drei der fünf Bestandteile
/// (Lastentwicklung, Fitness gegen Höchststand, Tageszuschlag) waren
/// Rechnungen ohne Grundlage, die man erklären musste, damit sie nicht
/// falsch wirkten.
///
/// Der Masterplan sagt dasselbe: Formwert raus, ehrliche Metriken rein. Hier
/// stehen jetzt Sätze je Muskelgruppe mit Nenner und das geschätzte Maximum
/// je Kernübung. Beides nennt seine Grundlage, beides braucht keine
/// Erklärung.
///
/// ## Jeder Block trägt seine eigene Schwelle
///
/// Es gibt keine gemeinsame „zu dünn"-Sperre mehr. Die Muskelbalance braucht
/// acht Einheiten mit Übungen, das Maximum fünf Einheiten je Übung — jeder
/// Block zeigt seinen Stand selbst, und ein Block ohne einen einzigen
/// zählbaren Satz rendert nicht.
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AtemErrorState(
                  title: l10n.analysisErrorTitle,
                  body: l10n.analysisErrorBody(summary.sessions),
                  retryLabel: l10n.analysisErrorRetry,
                  onRetry: () => ref.invalidate(sessionStreamProvider),
                ),
                // Der Ausweg zu den echten Daten (Board 06, A4/3): „Zur
                // Liste" existiert, damit niemand im Fehler festsitzt.
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
          ),
          data: (_) {
            if (sessions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AtemSpacing.screenPadding),
                child: AtemEmptyState(
                  title: l10n.emptyHistoryTitle,
                  body: l10n.emptyHistoryBody,
                ),
              );
            }

            final exercises = ref.watch(exercisesProvider).value ?? const [];
            final names = {for (final e in exercises) e.id: e.name};
            String nameOf(String id) => names[id] ?? id;

            // Dieselbe Einbindung wie im Workouts-Tab: Übungen für die
            // Muskelzuordnung, Stichtag aus dem Provider.
            final balance =
                MuscleBalance.compute(sessions, exercises, reference);
            final series = StrengthProgress.compute(sessions);
            final candidates =
                StrengthProgress.compute(sessions, minimumSessions: 1);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
              children: [
                // Dieselbe Kachel wie im Kraft-Tab: Die Details stehen an
                // genau einer Stelle, der Unterseite.
                MuscleBalanceTile(balance: balance),
                const SizedBox(height: 28),
                EstimatedMaxCard(
                  series: series,
                  candidates: candidates,
                  nameOf: nameOf,
                ),
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
