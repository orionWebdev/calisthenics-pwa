import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../cardio/presentation/widgets/rpe_choice.dart';
import '../../../history/presentation/session_ui.dart';
import '../../application/health_import_providers.dart';
import '../../domain/health_session.dart';
import '../health_import_ui.dart';

/// Öffnet das Prüfblatt für die wartenden Einheiten.
///
/// Der Stapel läuft **nacheinander im selben Blatt** (Board 15, A4): Eine
/// Sammelübernahme könnte die Anstrengung nur weglassen oder erfinden
/// (Entscheidung 14).
Future<void> showHealthReviewSheet(
  BuildContext context,
  List<HealthSession> pending,
) {
  final l10n = AppL10n.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0x00000000),
    barrierColor: AtemOverlays.barrier(AtemOverlays.sheetBarrierOpacity),
    barrierLabel: l10n.stepPadClose,
    showDragHandle: false,
    builder: (_) => HealthReviewSheet(pending: pending),
  );
}

/// Das Prüfblatt — **zwei Wege, plus Schliessen**.
///
/// ## Was es fragt und was nicht
///
/// Die Uhr weiss Dauer und Puls, nicht aber, wie schwer es sich angefühlt hat.
/// Genau das wird gefragt: die Anstrengung auf der bestehenden Fünferreihe
/// (Modul 11, unverändert) und die Notiz — das „Empfinden danach", für das die
/// App längst ein Feld hat (Entscheidung 16).
///
/// ## Kein deaktivierter Knopf, kein Ersatzwert
///
/// Ohne Anstrengung heisst der Hauptknopf „Ohne Anstrengung übernehmen" und
/// verliert seine Füllung — **das Label ist die Warnung** (A3). Ein
/// RPE-Mittelwert wäre rechnerisch plausibel und wäre eine erfundene Angabe
/// (Entscheidung 13).
///
/// ## „Später fortsetzen" ist kein dritter Weg
///
/// Den gibt es bereits ohne Knopf: Wer das Blatt schliesst, lässt die Zeilen
/// stehen. Im Stapel steht er trotzdem sichtbar, weil man dort mitten in
/// einer Reihe ist und der Ausgang sonst wie ein Abbruch aussähe
/// (Entscheidung 12).
class HealthReviewSheet extends ConsumerStatefulWidget {
  const HealthReviewSheet({super.key, required this.pending});

  final List<HealthSession> pending;

  @override
  ConsumerState<HealthReviewSheet> createState() => _HealthReviewSheetState();
}

class _HealthReviewSheetState extends ConsumerState<HealthReviewSheet> {
  int _index = 0;
  int? _rpe;
  bool _busy = false;

  HealthSession get _session => widget.pending[_index];

  bool get _hasMore => _index + 1 < widget.pending.length;

  /// Weiter zur nächsten — oder schliessen, wenn keine mehr wartet.
  void _next() {
    if (!_hasMore) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _rpe = null;
      _busy = false;
    });
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final controller = ref.read(healthImportControllerProvider.notifier);
    await controller.accept(_session, rpe: _rpe);
    if (mounted) _next();
  }

  Future<void> _decline() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(healthImportControllerProvider.notifier).decline(_session);
    if (mounted) _next();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final total = widget.pending.length;
    final session = _session;

    // Bei sehr grosser Schrift trägt die Fusszeile nur noch den Hauptweg.
    // Der zweite rutscht in den Inhalt — **nicht** weg: Beide Wege bleiben
    // erreichbar, nur nicht mehr beide im festen Fuss. Sonst schöbe die
    // Fusszeile bei 200 % auf 320 dp den Inhalt aus dem Blatt.
    final tight = MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.6;
    final secondLabel = _hasMore ? l10n.hcContinueLater : l10n.hcDecline;
    void secondWay() => _hasMore ? Navigator.of(context).pop() : _decline();

    return AtemSheet.content(
      title: l10n.hcSheetTitle(_index + 1, total),
      closeLabel: l10n.stepPadClose,
      // **Nie deaktiviert** — deshalb braucht das Label auch keinen Grund
      // im Vorlesetext. Ohne Anstrengung verliert der Knopf seine Füllung und
      // behält seinen Rand: Eine Aktion mit Lücke ist kein voller Knopf
      // (Board 15, A3).
      primaryAction: _rpe == null
          ? AtemButton.outline(
              label: l10n.hcAcceptWithoutEffort,
              semanticLabel: l10n.hcAcceptWithoutEffort,
              accent: AtemColors.magenta,
              size: AtemButtonSize.regular,
              onPressed: _busy ? null : _accept,
              busy: _busy,
            )
          : AtemButton.gradient(
              label: l10n.hcAccept,
              semanticLabel: l10n.hcAccept,
              gradient: AtemGradients.brandCta,
              onPressed: _busy ? null : _accept,
              busy: _busy,
            ),
      secondaryAction: tight
          ? null
          : AtemButton.outline(
              label: secondLabel,
              semanticLabel: secondLabel,
              onPressed: _busy ? null : secondWay,
            ),
      // **Spalte, keine Liste.** `AtemSheet` scrollt seinen Inhalt schon und
      // bringt das seitliche Polster mit; ein zweiter Scroller darin bekäme
      // unbegrenzte Höhe.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (total > 1) ...[
            _StackProgress(index: _index, total: total),
            const SizedBox(height: 14),
          ],
          _Head(session: session, index: _index, total: total),
          const SizedBox(height: 14),
          _Values(session: session),
          const SizedBox(height: 18),
          Text(l10n.formRpe.toUpperCase(),
              style: AtemType.labelMicro.of(context)),
          const SizedBox(height: 10),
          RpeChoice(value: _rpe, onChanged: (v) => setState(() => _rpe = v)),
          if (_rpe == null) ...[
            const SizedBox(height: 12),
            // Die **eine** erlaubte Hinweiszeile. Sie nennt die Folge, nicht
            // eine Mahnung.
            AtemNotice(
              // Der Titel ist die Tatsache, nicht die Aktion — sonst stünde
              // derselbe Satz zweimal auf dem Blatt.
              title: l10n.hcOriginMissingEffort,
              body: l10n.hcNoEffortNote,
              semanticLabel:
                  '${l10n.hcOriginMissingEffort}. ${l10n.hcNoEffortNote}',
            ),
          ],
          const SizedBox(height: 14),
          // Im Stapel hat „Nicht übernehmen" seinen Platz in der Liste, weil
          // der Fussweg dann „Später fortsetzen" trägt.
          if (_hasMore) ...[
            const SizedBox(height: 8),
            AtemButton.ghost(
              label: l10n.hcDecline,
              semanticLabel: l10n.hcDecline,
              onPressed: _busy ? null : _decline,
            ),
          ],
          if (tight) ...[
            const SizedBox(height: 8),
            AtemButton.ghost(
              label: secondLabel,
              semanticLabel: secondLabel,
              onPressed: _busy ? null : secondWay,
            ),
          ],
        ],
      ),
    );
  }
}

/// Erledigt in Lime, aktuell in Cyan, offen in Grau.
class _StackProgress extends StatelessWidget {
  const _StackProgress({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: i < index
                        ? AtemColors.green
                        : i == index
                            ? AtemColors.cyan
                            : AtemColors.border,
                    borderRadius: BorderRadius.circular(AtemRadii.pill),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// Kicker, Quellkapsel, Titel, Metazeile.
class _Head extends StatelessWidget {
  const _Head(
      {required this.session, required this.index, required this.total});

  final HealthSession session;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final title = HealthImportUi.title(l10n, session);
    final meta = HealthImportUi.meta(l10n, session, languageTag(context));

    return Semantics(
      container: true,
      label: '$title, $meta',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kein Kicker mehr: `AtemSheet` trägt den Titel „Einheit aus
            // Health Connect prüfen, 1 von 2" schon in der Kopfzeile, und der
            // Fortschrittsstrich darüber sagt dasselbe noch einmal in Form.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SourceCapsule(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AtemType.titleMedium.of(context)),
                      const SizedBox(height: 2),
                      Text(meta, style: AtemType.meta.of(context)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// „HC" — die fremde Quelle als **Fläche**, nie als Text.
///
/// Violett ist in dieser App nie Textfarbe (Modul 11). Hier trägt es die
/// Fläche, die Schrift darauf bleibt weiss.
class _SourceCapsule extends StatelessWidget {
  const _SourceCapsule();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          height: 26,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AtemColors.violet.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(AtemRadii.iconBox),
            border:
                Border.all(color: AtemColors.violet.withValues(alpha: 0.55)),
          ),
          child: Text(
            'HC',
            style: AtemType.labelMicro
                .of(context)
                .copyWith(color: AtemColors.textPrimary),
          ),
        ),
      );
}

/// Dauer, Ø Puls, Max — **cyan trägt nur das Gemessene**.
class _Values extends StatelessWidget {
  const _Values({required this.session});

  final HealthSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tiles = <Widget>[
      _Tile(
        label: l10n.hcFieldDuration,
        value: l10n.durationMinutes(session.duration.inMinutes),
        measured: false,
      ),
      if (session.averageHeartRate != null)
        _Tile(
          label: l10n.hcFieldHrAvg,
          value: '${session.averageHeartRate}',
          measured: true,
        ),
      if (session.maxHeartRate != null)
        _Tile(
          label: l10n.hcFieldHrMax,
          value: '${session.maxHeartRate}',
          measured: true,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bei 200 % kippen die Kacheln von drei Spalten in drei Zeilen (A9).
        LayoutBuilder(
          builder: (context, constraints) {
            final perTile =
                (constraints.maxWidth - AtemSpacing.gridGap * 2) / tiles.length;
            if (perTile < 92) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: AtemSpacing.gridGap),
                    tiles[i],
                  ],
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: AtemSpacing.gridGap),
                    Expanded(child: tiles[i]),
                  ],
                ],
              ),
            );
          },
        ),
        if (session.extrasCount > 0) ...[
          const SizedBox(height: 10),
          Text(l10n.hcMoreDeviceValues(session.extrasCount),
              style: AtemType.meta.of(context)),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.measured,
  });

  final String label;
  final String value;

  /// Kam der Wert von der Uhr? Dann trägt er Cyan — die Theme-Semantik für
  /// Gemessenes.
  final bool measured;

  @override
  Widget build(BuildContext context) {
    final tint = measured ? AtemColors.cyan : null;

    return Semantics(
      label: '$label $value',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          constraints: const BoxConstraints(minHeight: 46),
          decoration: BoxDecoration(
            color: measured
                ? AtemColors.cyan.withValues(alpha: 0.07)
                : AtemColors.card,
            borderRadius: BorderRadius.circular(AtemRadii.statBox),
            border: Border.all(
              color: tint?.withValues(alpha: 0.3) ?? AtemColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.labelMicro
                      .of(context)
                      .copyWith(color: tint ?? AtemColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.valueMedium.of(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// „Notiz hinzufügen" — das vorhandene Feld, keine neue Skala.
///
/// Board 15, Entscheidung 16: Ein eigenes Fünf-Stufen-Raster fürs Empfinden
/// wäre eine neue Bewertungsachse im ganzen Produkt — und stünde im Import,
/// nicht aber im Runner, wo dieselbe Frage entsteht.
