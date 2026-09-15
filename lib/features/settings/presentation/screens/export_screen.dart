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
  /// **Das Format ist eine Wahl, kein zweiter Knopf** (Board 08, A5/1).
  /// Zwei gleich aussehende Erstellen-Knöpfe zwangen zur Entscheidung, bevor
  /// erkennbar war, dass es überhaupt eine gibt.
  ExportFormat _format = ExportFormat.json;

  bool _running = false;
  ExportResult? _done;
  String? _error;

  Future<void> _create() async {
    final l10n = AppL10n.of(context);
    setState(() {
      _running = true;
      _error = null;
      _done = null;
    });

    final result = await ref.read(accountExportProvider.notifier).run(_format);
    if (!mounted) return;
    setState(() {
      _running = false;
      _done = result;
      _error = result == null ? l10n.settingsExportFailed : null;
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
                  // „Termine" steht im Board, hat in dieser Fassung aber
                  // keine Quelle: Der Kalender gehört nicht zu V1. Eine
                  // Zeile mit erfundener Zahl wäre schlimmer als keine.
                  const SizedBox(height: 8),
                  // Eine grobe Schätzung, und sie sagt das auch: „ca.".
                  // Genauer ginge nur, indem man die Datei vorher baut.
                  Text(
                    l10n.exportSize(_estimateMb(sessions.length, own)),
                    style: AtemType.meta.of(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _FormatChip(
                    title: 'JSON',
                    note: l10n.exportFormatFull,
                    selected: _format == ExportFormat.json,
                    onTap: _running
                        ? null
                        : () => setState(() => _format = ExportFormat.json),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FormatChip(
                    title: 'CSV',
                    note: l10n.exportFormatSessions,
                    selected: _format == ExportFormat.csv,
                    onTap: _running
                        ? null
                        : () => setState(() => _format = ExportFormat.csv),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(l10n.exportFormatNote,
                style: AtemType.labelSmall.of(context)),
            const SizedBox(height: 16),

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
            AtemButton.gradient(
              label: _running ? l10n.settingsExportRunning : l10n.exportCreate,
              semanticLabel: l10n.exportCreate,
              busy: _running,
              onPressed: _running ? null : _create,
            ),

            // Danach: die Datei mit Namen und ein zweiter Weg zum Teilen —
            // das Blatt kann man versehentlich wegwischen (Board 08, A5/2).
            if (_done case final result?) ...[
              const SizedBox(height: 16),
              _DoneRow(
                fileName: result.fileName,
                count: result.documentCount,
                onShare: () =>
                    ref.read(accountExportProvider.notifier).shareAgain(),
              ),
              const SizedBox(height: 10),
              Text(l10n.exportDoneNote,
                  style: AtemType.labelSmall.of(context)),
            ],
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

/// Ein Formatfeld: Name gross, Umfang klein darunter.
class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.title,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String note;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: onTap,
        semanticLabel: '$title, $note',
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AtemCategories.surface(AtemColors.cyan)
                : AtemColors.surfaceSolid,
            borderRadius: BorderRadius.circular(AtemRadii.statBox),
            border: Border.all(
              color: selected
                  ? AtemCategories.border(AtemColors.cyan)
                  : AtemColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.titleSmallOrDefault(context).copyWith(
                      color:
                          selected ? AtemColors.cyan : AtemColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 3),
              Text(note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AtemType.meta.of(context)),
            ],
          ),
        ),
      );
}

/// Die fertige Datei: Punkt, Name, „Teilen".
class _DoneRow extends StatelessWidget {
  const _DoneRow({
    required this.fileName,
    required this.count,
    required this.onShare,
  });

  final String fileName;
  final int count;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemCard.list(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      child: Row(
        children: [
          const ExcludeSemantics(child: AtemStatusDot(color: AtemColors.green)),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: '${l10n.settingsExportDone(count)}. $fileName',
              child: ExcludeSemantics(
                child: Text(fileName,
                    style: AtemType.labelSmall.of(context)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AtemButton.ghost(
            label: l10n.exportDoneShare,
            semanticLabel: '${l10n.exportDoneShare}: $fileName',
            expand: false,
            size: AtemButtonSize.compact,
            onPressed: onShare,
          ),
        ],
      ),
    );
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
