import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../application/health_import_providers.dart';
import '../../domain/health_session.dart';
import '../../domain/merge_preview.dart';
import 'merge_consequences.dart';

/// **Woher weiss die App das?** — die Quellenkapsel (Board 15, B3 · Board 16,
/// Platz 6).
///
/// ## Sie steht immer da
///
/// Bis zum 21.09.2026 rendete sie nur bei einer Verknüpfung. Board 16 macht
/// „Herkunft und Eingriffe" zum sechsten Platz, der **für jede Art gefüllt
/// ist**: Auch eine Einheit, die niemand je mit einer Uhr gesehen hat, sagt,
/// dass sie selbst geführt ist. Ohne diese Zeile wäre das Fehlen der Uhr
/// unlesbar — man sähe nicht, ob sie fehlt oder ob niemand nachgesehen hat.
///
/// ## Drei Herkünfte, eine Form
///
/// Gefüllter Punkt = selbst geführt, hohler Ring = aus der Uhr, Ring mit Kern
/// = zusammengeführt (Idiom aus Modul 14/15, unverändert). Die Kapsel klappt
/// auf und nennt, welche Grösse woher kommt — und was die Uhr abweichend
/// meldet: Die widersprüchliche Dauer verschwindet nicht, 52 min ist der Wert
/// der Einheit, 58 min steht als Meldung der Uhr daneben, violett hinterlegt.
class SourceCapsule extends ConsumerStatefulWidget {
  const SourceCapsule({
    super.key,
    required this.session,
    this.onlyKindAndDay = false,
  });

  final TrainingSession session;

  /// Die Einheit trägt nichts ausser Art und Tag — das steht dann in der
  /// Metazeile, damit die Lücke eine Tatsache bleibt.
  final bool onlyKindAndDay;

  @override
  ConsumerState<SourceCapsule> createState() => _SourceCapsuleState();
}

class _SourceCapsuleState extends ConsumerState<SourceCapsule> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final linked = session.healthSessionId;

    HealthSession? measured;
    if (linked != null) {
      for (final s in ref.watch(healthSessionsProvider).value ?? const []) {
        if (s.externalId == linked) measured = s;
      }
    }

    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final clock = DateFormat.Hm(tag);
    final origin = session.origin;
    final device = measured?.deviceName ?? l10n.hcPairWatchRow;
    final appMinutes = (session.duration ?? Duration.zero).inMinutes;
    final watchMinutes = measured?.duration.inMinutes;

    final (word, meta, shape) = switch (origin) {
      SessionOrigin.app => (
          l10n.detailOriginApp,
          widget.onlyKindAndDay
              ? l10n.detailOriginMetaEmpty
              : l10n.detailOriginMetaApp,
          AtemOriginShape.filled,
        ),
      SessionOrigin.watch => (
          l10n.detailOriginWatch,
          l10n.detailOriginMetaWatch(device),
          AtemOriginShape.hollow,
        ),
      SessionOrigin.merged => (
          l10n.detailOriginBoth,
          l10n.detailOriginMetaMerged,
          AtemOriginShape.ringWithCore,
        ),
    };

    // **Herkunft als Wort im Label, der Punkt stumm**: „zusammengeführt" ist
    // das Wort dafür (Board 16, H).
    final spoken = switch (origin) {
      SessionOrigin.app => '${l10n.hcSourcesLabel}: $word. $meta.',
      SessionOrigin.watch => '${l10n.hcSourcesLabel}: $word. $meta.',
      SessionOrigin.merged => l10n.detailOriginA11yBoth,
    };

    final showApp = origin != SessionOrigin.watch;
    final showWatch = origin != SessionOrigin.app;

    final explain = _explainLoad(l10n, session, measured);

    // Aufklappen ist ein Erscheinen aus eigener Handlung: die Lichtkante,
    // **bei jedem Öffnen** (entschieden am 23.09.2026, gegen Board 18b C6).
    // Zuklappen hat keine.
    return AtemEdgeSweep(
      trigger: _open,
      when: _open,
      radius: 16,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtemTappable(
          onTap: () => setState(() => _open = !_open),
          expanded: _open,
          semanticLabel: spoken,
          minTapSize: const Size(0, 56),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AtemColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AtemColors.border),
            ),
            child: Row(
              children: [
                // 12 dp, wie im Board; der Punkt selbst ist stumm.
                Transform.scale(
                  scale: 1.2,
                  child: AtemOriginDot(
                    shape: shape,
                    color: AtemColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word, style: AtemType.labelSmall.of(context)),
                      const SizedBox(height: 2),
                      Text(meta.toUpperCase(),
                          style: AtemType.meta.of(context)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.25 : 0,
                  duration: AtemMotion.duration(
                      context, const Duration(milliseconds: 200)),
                  child: const Icon(Icons.chevron_right,
                      size: 20, color: AtemColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AtemDisclosure(
          open: _open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showApp)
                  SourceLine(
                    text: l10n.hcSourceApp,
                    shape: AtemOriginShape.filled,
                  ),
                if (showApp && showWatch) const SizedBox(height: 6),
                if (showWatch)
                  SourceLine(
                    text: l10n.hcSourceWatch(device),
                    shape: AtemOriginShape.hollow,
                  ),
                // **Wie die Last gerechnet wird** (Board 16, Nachtrag, M).
                // Sie ist eine App-Rechnung; was daran gemessen sein kann,
                // ist die Anstrengung. Das gehört erklärt, nicht behauptet —
                // und es klappt hier auf, statt ein Blatt zu öffnen.
                if (explain.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  AtemExplainHeader(
                    title: l10n.detailLoadExplainTitle,
                    titleStyle: AtemType.meta.of(context),
                    explanation: explain,
                  ),
                ],
                // Der abweichende Fremdwert — nur bei einer
                // Zusammenführung, denn nur dort gibt es zwei Zahlen.
                if (origin == SessionOrigin.merged &&
                    measured != null &&
                    watchMinutes != appMinutes) ...[
                  const SizedBox(height: 10),
                  WatchReport(
                    text: l10n.hcWatchReports(
                      clock.format(measured.start),
                      clock.format(measured.end),
                      watchMinutes!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }

  /// Die Sätze hinter dem ⓘ: Formel, dann der Fall, der hier gilt.
  ///
  /// Leer, wo es keine Last gibt — Regeneration trägt keine, und ein ⓘ über
  /// eine Zahl, die nicht da ist, wäre ein Versprechen ins Leere.
  ///
  /// **Die Formel steht hier voll**, nicht in der verkürzten Fassung des
  /// Boards: Dort heisst es „Dauer × Anstrengung" und „Volumen × Anstrengung
  /// / 100". Gerechnet wird aber mit dem Faktor 4 und der Sportart, und bei
  /// Kraft durch 50 (`TrainingLoad`). Ein Erklärtext, der die Rechnung falsch
  /// wiedergibt, ist schlimmer als keiner.
  List<String> _explainLoad(
    AppL10n l10n,
    TrainingSession session,
    HealthSession? measured,
  ) {
    final formula = switch (session) {
      CardioSession() => l10n.detailLoadExplainFormulaEndurance,
      StrengthSession() => l10n.detailLoadExplainFormulaStrength,
      _ => null,
    };
    if (formula == null) return const [];

    final context = ref.watch(loadContextProvider);
    final entered = session.rpe;
    final fromPulse = context.measuredEffortOf?.call(session);

    if (entered != null) {
      // Beide da: Beide nennen, ohne die eine zur Abweichung der anderen zu
      // erklären. „Eingetragen gilt" ist die Reihenfolge, kein Urteil.
      return [
        formula,
        fromPulse == null
            ? l10n.detailLoadExplainEntered(entered)
            : l10n.detailLoadExplainEnteredWins(entered, fromPulse),
      ];
    }

    if (fromPulse != null) {
      final seconds = measured?.pulse?.recordedSeconds ?? 0;
      return [
        formula,
        l10n.detailLoadExplainMeasured(fromPulse, (seconds / 60).round()),
      ];
    }

    return [formula, l10n.detailLoadExplainFallback(context.effortFor(session))];
  }
}

/// Eine Quelle mit ihrem Punkt — dieselbe Form wie in der Liste.
class SourceLine extends StatelessWidget {
  const SourceLine({super.key, required this.text, required this.shape});

  final String text;
  final AtemOriginShape shape;

  @override
  Widget build(BuildContext context) => Semantics(
        label: text,
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AtemOriginDot(shape: shape),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: AtemType.labelSmall.of(context)),
              ),
            ],
          ),
        ),
      );
}

/// Der abweichende Fremdwert — **violett als Fläche, nie als Text**.
class WatchReport extends StatelessWidget {
  const WatchReport({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        label: text,
        child: ExcludeSemantics(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AtemColors.violet.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AtemRadii.iconBox),
            ),
            child: Text(
              text.toUpperCase(),
              style: AtemType.labelMicro
                  .of(context)
                  .copyWith(color: AtemColors.textTertiary),
            ),
          ),
        ),
      );
}

/// **Zweistufig, weil es eine Einheit im Bestand verändert.**
class UnlinkRow extends ConsumerWidget {
  const UnlinkRow({super.key, required this.session, required this.measured});

  final TrainingSession session;
  final HealthSession measured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);

    return AtemTappable(
      onTap: () => _unlink(context, ref),
      semanticLabel: l10n.hcUnlink,
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtemRadii.statBox),
          border: Border.all(color: AtemColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child:
                  Text(l10n.hcUnlink, style: AtemType.labelSmall.of(context)),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AtemColors.magenta),
          ],
        ),
      ),
    );
  }

  Future<void> _unlink(BuildContext context, WidgetRef ref) async {
    final l10n = AppL10n.of(context);
    final ok = await showMergeConsequences(
      context,
      preview: MergePreview.unlinking(session: session, measured: measured),
      merging: false,
    );
    if (!ok || !context.mounted) return;

    await ref
        .read(healthImportControllerProvider.notifier)
        .unlink(measured, session.id);
    ref.read(snackbarProvider.notifier).show(AtemSnack(
          message: l10n.hcUnlinkedSnack,
          semanticLabel: l10n.hcUnlinkedSnack,
          tone: AtemSnackTone.success,
        ));
  }
}
