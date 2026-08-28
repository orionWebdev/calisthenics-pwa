import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../plans/application/plan_providers.dart';
import '../../application/account_export.dart';

/// Daten ausgeben — **erst zeigen, was drin ist, dann erstellen**.
///
/// ## Warum ein Bildschirm und keine Zeile
///
/// Vorher lief die Ausgabe sofort los, sobald man die Zeile antippte: keine
/// Auskunft darüber, was in der Datei landet, keine Wahl des Formats, kein
/// Fortschritt. Bei 136 Einheiten dauert das Sammeln mehrere Sekunden, in
/// denen nichts passiert zu sein scheint.
///
/// Der Bildschirm nennt vorher, was mitkommt, und zwar in Zahlen. „Deine
/// Daten" ist eine Behauptung; „110 Einheiten mit Sätzen · 10 Pläne · 70
/// eigene Übungen" ist eine überprüfbare.
///
/// ## Die App verschickt nichts selbst
///
/// Sie erstellt eine Datei und übergibt sie dem Teilen-Blatt. Wohin sie geht,
/// entscheidet das System und der Nutzer — Drive, Dateien, E-Mail an sich
/// selbst. Ein eigener Versandweg wäre ein Weg, auf dem persönliche Daten die
/// App verlassen, ohne dass jemand ihn gewählt hat.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat? _running;
  int? _done;
  String? _error;

  Future<void> _create(ExportFormat format) async {
    final l10n = AppL10n.of(context);
    setState(() {
      _running = format;
      _error = null;
      _done = null;
    });

    final count = await ref.read(accountExportProvider.notifier).run(format);
    if (!mounted) return;
    setState(() {
      _running = null;
      _done = count;
      _error = count == null ? l10n.settingsExportFailed : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    final sessions = ref.watch(sessionsProvider).value ?? const [];
    final plans = ref.watch(plansProvider).value ?? const [];
    final own = (ref.watch(exercisesProvider).value ?? const [])
        .where((e) => e.isOwn)
        .length;

    final withSets = sessions
        .where((s) => s is StrengthSession && s.hasExerciseData)
        .length;
    final span = _spanDays(sessions, ref.watch(historyReferenceProvider));

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.exportTitle,
            style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
          children: [
            Text(l10n.exportSub, style: AtemType.body.of(context)),
            const SizedBox(height: 6),
            Text(l10n.exportBody, style: AtemType.labelSmall.of(context)),
            const SizedBox(height: 20),

            AtemCard.list(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Row(label: l10n.exportRowSessions, value: '$withSets'),
                  _Row(label: l10n.exportRowPlans, value: '${plans.length}'),
                  _Row(label: l10n.exportRowExercises, value: '$own'),
                  _Row(
                    label: l10n.exportRowScores,
                    value: l10n.exportRowDays(span),
                  ),
                  _Row(label: l10n.exportRowProfile, value: '1'),
                  const SizedBox(height: 8),
                  // Eine grobe Schätzung, und sie sagt das auch: „ca.".
                  // Genauer ginge nur, indem man die Datei vorher baut.
                  Text(
                    l10n.exportSize(_estimateMb(sessions.length, own)),
                    style: AtemType.labelMicro.of(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(l10n.exportFormatNote,
                style: AtemType.labelSmall.of(context)),
            const SizedBox(height: 14),

            AtemNoticeSlot(
              notice: _error == null
                  ? null
                  : AtemNotice(
                      tone: AtemNoticeTone.error,
                      title: l10n.settingsExportFailed,
                      body: l10n.commonRetry,
                      semanticLabel: '${l10n.settingsExportFailed}. ${l10n.commonRetry}',
                    ),
            ),
            if (_done case final count?) ...[
              AtemNotice(
                title: l10n.settingsExportDone(count),
                body: l10n.exportDoneNote,
                semanticLabel:
                    '${l10n.settingsExportDone(count)}. ${l10n.exportDoneNote}',
              ),
              const SizedBox(height: 14),
            ],

            AtemButton.gradient(
              label: _running == ExportFormat.json
                  ? l10n.settingsExportRunning
                  : l10n.exportCreateJson,
              semanticLabel: l10n.exportCreateJson,
              busy: _running == ExportFormat.json,
              onPressed:
                  _running != null ? null : () => _create(ExportFormat.json),
            ),
            const SizedBox(height: 10),
            AtemButton.outline(
              label: _running == ExportFormat.csv
                  ? l10n.settingsExportRunning
                  : l10n.exportCreateCsv,
              semanticLabel: l10n.exportCreateCsv,
              busy: _running == ExportFormat.csv,
              onPressed:
                  _running != null ? null : () => _create(ExportFormat.csv),
            ),
          ],
        ),
      ),
    );
  }

  /// Über wie viele Tage sich der Bestand erstreckt.
  static int _spanDays(List<TrainingSession> sessions, DateTime reference) {
    if (sessions.isEmpty) return 0;
    final first =
        sessions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;
    return reference.difference(first).inDays;
  }

  /// Grob geschätzt: rund 1,5 kB je Einheit, 0,5 kB je Übung.
  ///
  /// Genauer wäre nur möglich, indem man die Datei vorher baut — dann wäre
  /// die Schätzung überflüssig. Eine Stelle hinter dem Komma, mehr gibt die
  /// Schätzung nicht her.
  static String _estimateMb(int sessions, int exercises) {
    final bytes = sessions * 1500 + exercises * 500 + 2000;
    return (bytes / 1024 / 1024).toStringAsFixed(1);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: $value',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child:
                      Text(label, style: AtemType.labelSmall.of(context)),
                ),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: AtemType.labelMicro
                      .of(context)
                      .copyWith(letterSpacing: 0, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      );
}
