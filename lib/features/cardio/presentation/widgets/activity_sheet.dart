import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/domain/training_session.dart';
import '../../application/cardio_providers.dart';
import '../cardio_ui.dart';

/// Die Aktivitätsauswahl — **acht Werte, nicht gleich laut** (Board 11, B2/2).
///
/// Belegte Aktivitäten stehen als 48-dp-Zeilen mit ihrer Zahl, sortiert nach
/// Häufigkeit im eigenen Bestand — die Liste ist ein Werkzeug, kein
/// Verzeichnis. Die unbelegten stehen als Kapseln unter „Weitere": erreichbar
/// in einem Tap, aber nicht auf Augenhöhe mit 37 Läufen. Wird eine davon
/// benutzt, wandert sie beim nächsten Öffnen nach oben — die Sortierung
/// zählt, sie merkt sich nichts.
///
/// Sheet im kurzen Höhenmodus aus Modul 2. Kapseln 36 dp sichtbar, 48 dp
/// Ziel — und semantisch gleichrangig mit den Zeilen: die visuelle
/// Zurückstufung ist keine semantische (Sektion H).
abstract final class ActivitySheet {
  static Future<CardioActivity?> show(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemSheet.show<CardioActivity>(
      context,
      title: l10n.formActivity,
      closeLabel: l10n.commonClose,
      child: const _Body(),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final sessions = ref.watch(cardioSessionsProvider);

    final counts = <CardioActivity, int>{};
    for (final s in sessions) {
      final a = s.activity ?? CardioActivity.other;
      counts[a] = (counts[a] ?? 0) + 1;
    }
    final frequent = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final rare = [
      for (final a in CardioActivity.values)
        if (!counts.containsKey(a)) a,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (frequent.isNotEmpty) ...[
          Text(
            l10n.activityOwn(sessions.length),
            style: AtemType.meta.of(context),
          ),
          const SizedBox(height: 8),
          AtemCard.list(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < frequent.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1, thickness: 1, color: AtemColors.border),
                  _Row(
                    activity: frequent[i],
                    count: counts[frequent[i]]!,
                    strongest: i == 0,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (rare.isNotEmpty) ...[
          Text(l10n.activityMore.toUpperCase(),
              style: AtemType.labelMicro.of(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final a in rare) _Capsule(activity: a)],
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.activity,
    required this.count,
    required this.strongest,
  });

  final CardioActivity activity;
  final int count;

  /// Die häufigste bekommt den Cyan-Rand-Punkt — Betonung, nicht Auswahl.
  final bool strongest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final name = activityLabel(l10n, activity);
    final countText = l10n.cardioListCount(count);

    return AtemTappable(
      onTap: () => Navigator.of(context).pop(activity),
      // Dasselbe Label wie die Kapseln: „Schwimmen, Aktivität wählen".
      semanticLabel: '$name, $countText. ${l10n.formActivity}',
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            AtemStatusDot(
              color: activity == CardioActivity.other
                  ? AtemColors.textSecondary
                  : AtemColors.cyan,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.titleSmallOrDefault(context).copyWith(
                      fontWeight: strongest ? FontWeight.w600 : FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            Text('$count×',
                style: AtemType.labelMicro
                    .of(context)
                    .copyWith(letterSpacing: 0)),
          ],
        ),
      ),
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({required this.activity});

  final CardioActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final name = activityLabel(l10n, activity);

    return AtemTappable(
      onTap: () => Navigator.of(context).pop(activity),
      semanticLabel: '$name, ${l10n.formActivity}',
      minTapSize: const Size(48, 48),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AtemColors.surfaceSolid,
          borderRadius: BorderRadius.circular(AtemRadii.pill),
          border: Border.all(color: AtemColors.border),
        ),
        child: Text(name,
            style: AtemType.labelSmall
                .of(context)
                .copyWith(color: AtemColors.textPrimary)),
      ),
    );
  }
}
