import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../application/health_import_providers.dart';
import '../../domain/health_session.dart';
import '../../domain/merge_preview.dart';
import 'merge_consequences.dart';

/// **Eine Einheit, zwei Quellen** (Board 15, B3).
///
/// ## Was sie beantwortet
///
/// Welche Grösse woher kommt — und was die Uhr abweichend meldet. Die
/// widersprüchliche Dauer verschwindet nicht: 52 min ist der Wert der
/// Einheit, 58 min steht als Meldung der Uhr daneben, violett hinterlegt.
/// Zwei Zahlen, eine gültig, beide sichtbar.
///
/// ## Sie rendert nur bei einer Verknüpfung
///
/// Eine Einheit ohne fremde Quelle hat keine Quellenfrage — und ausserhalb
/// von Auswertungen rendert ein Block ohne Daten nicht.
class SourceCapsule extends ConsumerWidget {
  const SourceCapsule({super.key, required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = session.healthSessionId;
    if (linked == null) return const SizedBox.shrink();

    final all = ref.watch(healthSessionsProvider).value ?? const [];
    HealthSession? measured;
    for (final s in all) {
      if (s.externalId == linked) measured = s;
    }
    // Der Verweis steht, der Datensatz fehlt — etwa nach einer
    // Kontoübertragung. Dann ist die Quellenfrage nicht zu beantworten, und
    // eine halbe Antwort wäre schlechter als keine.
    if (measured == null) return const SizedBox.shrink();

    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final clock = DateFormat.Hm(tag);
    final device = measured.deviceName ?? l10n.hcPairWatchRow;
    final appMinutes = (session.duration ?? Duration.zero).inMinutes;
    final watchMinutes = measured.duration.inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        AtemCard.list(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.hcSourcesLabel.toUpperCase(),
                  style: AtemType.labelMicro.of(context)),
              const SizedBox(height: 8),
              _SourceLine(
                text: l10n.hcSourceApp,
                shape: AtemOriginShape.filled,
              ),
              const SizedBox(height: 6),
              _SourceLine(
                text: l10n.hcSourceWatch(device),
                shape: AtemOriginShape.hollow,
              ),
              if (appMinutes != watchMinutes) ...[
                const SizedBox(height: 10),
                _WatchReport(
                  text: l10n.hcWatchReports(
                    clock.format(measured.start),
                    clock.format(measured.end),
                    watchMinutes,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _UnlinkRow(session: session, measured: measured),
      ],
    );
  }
}

/// Eine Quelle mit ihrem Punkt — dieselbe Form wie in der Liste.
class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.text, required this.shape});

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
class _WatchReport extends StatelessWidget {
  const _WatchReport({required this.text});

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
class _UnlinkRow extends ConsumerWidget {
  const _UnlinkRow({required this.session, required this.measured});

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
              child: Text(l10n.hcUnlink,
                  style: AtemType.labelSmall.of(context)),
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
      preview:
          MergePreview.unlinking(session: session, measured: measured),
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
