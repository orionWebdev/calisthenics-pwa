import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/presentation/session_ui.dart';
import '../../application/health_import_providers.dart';
import '../../domain/health_session.dart';
import '../health_import_ui.dart';
import '../review_flow.dart';

/// Der Eingang über der Einheitenliste — **eine Zeile, solange etwas wartet**.
///
/// ## Warum er überhaupt da ist
///
/// Ein Blatt, das beim Start von selbst aufgeht, wäre ein Überfall
/// (Entscheidung 2); eine Benachrichtigung bräuchte einen Hintergrunddienst
/// (Entscheidung 3). Eine einzelne wartende Zeile mitten in einer langen
/// Liste wäre dagegen ein Datenfriedhof.
///
/// Der Eingang ist beides nicht: Er gibt den wartenden Einheiten einen Weg,
/// und die Einheiten selbst stehen an ihrem echten Datum in der Liste
/// (Entscheidung 4).
///
/// ## Er rendert nicht, wenn nichts wartet
///
/// Keine leere Karte, kein „nichts gefunden" (Modul 5, A7). Ein leerer
/// Zeitraum ist kein Ereignis; wer wissen will, ob gelesen wurde, findet die
/// Lesemarke in den Einstellungen.
class HealthInboxHeader extends ConsumerWidget {
  const HealthInboxHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final inbox = ref.watch(healthInboxProvider);
    final status = ref.watch(healthImportControllerProvider);

    // Der Fehler betrifft das Lesen, nicht den Bestand: Die Liste bleibt
    // vollständig, nur der Eingang trägt den Zustand (A8).
    if (status.hasError) {
      return _Frame(
        tone: AtemColors.magenta,
        child: _Error(lastRead: inbox.lastRead),
      );
    }

    // Nur der Eingangskopf lädt, die Liste bleibt stehen und bedienbar (A6).
    if (status.isLoading) {
      return _Frame(
        tone: AtemColors.cyan,
        child: Semantics(
          liveRegion: true,
          label: l10n.hcReading,
          child: ExcludeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.hcReading,
                      style: AtemType.labelSmall.of(context)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (inbox.isEmpty) return const SizedBox.shrink();

    final count = l10n.hcInboxTitle(inbox.pending.length);
    final time = _readTime(context, inbox.lastRead);

    return _Frame(
      tone: AtemColors.cyan,
      child: AtemTappable(
        onTap: () => runReview(context, ref, inbox.pending),
        semanticLabel: l10n.hcInboxA11y(count, time),
        minTapSize: const Size(0, 48),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(count, style: AtemType.titleSmallOrDefault(context)),
                  const SizedBox(height: 2),
                  Text(l10n.hcInboxMeta(time),
                      style: AtemType.meta.of(context)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.hcInboxAction,
              style:
                  AtemType.labelUi.of(context).copyWith(color: AtemColors.cyan),
            ),
          ],
        ),
      ),
    );
  }

  static String _readTime(BuildContext context, DateTime? at) {
    if (at == null) return '—';
    return DateFormat.Hm(languageTag(context)).format(at);
  }
}

/// Die Fläche des Eingangs — getönt, damit er sich von den Einheiten darunter
/// abhebt, ohne eine Karte zu sein.
class _Frame extends StatelessWidget {
  const _Frame({required this.tone, required this.child});

  final Color tone;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AtemSpacing.cardGap),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AtemRadii.statBox),
          border: Border.all(color: tone.withValues(alpha: 0.4)),
        ),
        child: child,
      );
}

/// Lesen fehlgeschlagen — mit der letzten erfolgreichen Marke als Tatsache.
class _Error extends ConsumerWidget {
  const _Error({required this.lastRead});

  final DateTime? lastRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final at = lastRead;
    final meta = at == null
        ? null
        : l10n.hcReadErrorMeta(
            DateFormat('d. MMM HH:mm', languageTag(context)).format(at));

    return Semantics(
      liveRegion: true,
      label: [l10n.hcReadError, if (meta != null) meta].join('. '),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.hcReadError,
                      style: AtemType.titleSmallOrDefault(context)),
                  if (meta != null) ...[
                    const SizedBox(height: 2),
                    Text(meta, style: AtemType.meta.of(context)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            AtemTappable(
              onTap: () =>
                  ref.read(healthImportControllerProvider.notifier).refresh(),
              semanticLabel: l10n.hcRetry,
              minTapSize: const Size(48, 48),
              alignment: Alignment.centerRight,
              child: Text(
                l10n.hcRetry,
                style: AtemType.labelUi
                    .of(context)
                    .copyWith(color: AtemColors.magenta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine wartende Einheit an ihrem Datum — **sichtbar, ohne zu zählen**.
///
/// Drei Träger ohne Farbe allein: der gestrichelte Punkt und der gestrichelte
/// Rand (Zustand), das Wort „Ungeprüft" und die Folge „zählt noch nicht".
class HealthPendingRow extends ConsumerWidget {
  const HealthPendingRow({
    super.key,
    required this.session,
    this.all,
    this.quiet = false,
  });

  final HealthSession session;

  /// Der ganze Stapel, falls die Zeile aus dem Eingang heraus geöffnet wird.
  /// Ohne ihn prüft sie nur sich selbst.
  final List<HealthSession>? all;

  /// Ohne Aufforderung — die Zeile, während sie in eine andere läuft
  /// (Board 15, B6). Die Entscheidung ist da schon gefallen; „Prüfen"
  /// lüde zu etwas ein, das es nicht mehr gibt.
  final bool quiet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final title = HealthImportUi.title(l10n, session);
    final meta = HealthImportUi.day(session, languageTag(context));
    final showDot = AtemOriginDot.fitsAt(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AtemTappable(
        onTap: () => runReview(context, ref, all ?? [session]),
        semanticLabel: l10n.hcRowA11y(title, meta),
        minTapSize: const Size(0, 52),
        alignment: Alignment.centerLeft,
        child: CustomPaint(
          painter: const _DashedRow(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                if (showDot) ...[
                  const AtemOriginDot(shape: AtemOriginShape.dashed),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtemType.labelSmall.of(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // Ohne Punkt trägt die Metazeile die Herkunft als
                        // Wort — nicht beides (Board 15, C2).
                        [
                          meta,
                          if (!showDot) l10n.hcOriginWatch,
                          l10n.hcRowUnreviewed,
                        ].join(' · '),
                        style: AtemType.meta.of(context),
                      ),
                    ],
                  ),
                ),
                if (!quiet) ...[
                  const SizedBox(width: 10),
                  Text(
                    l10n.hcInboxAction,
                    style: AtemType.labelUi
                        .of(context)
                        .copyWith(color: AtemColors.cyan),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Der gestrichelte Rand — „hier fehlt noch eine Entscheidung", als Form.
class _DashedRow extends CustomPainter {
  const _DashedRow();

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final paint = Paint()
      ..color = const Color(0xFF2E3142)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end =
            distance + _dash < metric.length ? distance + _dash : metric.length;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRow old) => false;
}

/// Die Abgelehnten — am **Fuss des Eingangs**, nicht im Verlauf.
///
/// Abgelehnt ist keine Einheit. Sie stehen hier, damit „Doch übernehmen"
/// einen Ort hat, und tragen den Satz, warum sie nicht wiederkommen.
class HealthDeclinedList extends ConsumerWidget {
  const HealthDeclinedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final declined = ref.watch(healthInboxProvider).declined;
    if (declined.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemBlockHeader(
            title: '${l10n.hcDeclinedSection.toUpperCase()} · '
                '${declined.length}',
          ),
          const SizedBox(height: 8),
          AtemCard.list(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < declined.length; i++) ...[
                  if (i > 0)
                    const SizedBox(
                        height: 1,
                        child: ColoredBox(color: AtemColors.gridLine)),
                  _DeclinedRow(session: declined[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.hcDeclinedNote, style: AtemType.meta.of(context)),
        ],
      ),
    );
  }
}

class _DeclinedRow extends ConsumerWidget {
  const _DeclinedRow({required this.session});

  final HealthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final title = HealthImportUi.title(l10n, session);
    final at = session.decidedAt;
    final meta = at == null
        ? HealthImportUi.meta(l10n, session, languageTag(context))
        : l10n.hcDeclinedMeta(
            DateFormat('d. MMM', languageTag(context)).format(at));

    return AtemTappable(
      onTap: () =>
          ref.read(healthImportControllerProvider.notifier).restore(session),
      semanticLabel: '$title, $meta. ${l10n.hcDeclinedRestore}',
      minTapSize: const Size(0, 44),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelSmall.of(context)),
                  const SizedBox(height: 2),
                  Text(meta, style: AtemType.meta.of(context)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.undo, size: 16, color: AtemColors.cyan),
          ],
        ),
      ),
    );
  }
}
