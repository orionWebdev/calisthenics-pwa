import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../cardio/domain/last_activity.dart';
import '../../../cardio/presentation/cardio_ui.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';

/// Die Regenerationszeile — **eine Zeile, keine Ebene** (Board 11, C2/1).
///
/// Regeneration ist keine Leistung, sondern eine Eingangsgrösse der
/// Bereitschaft. Deshalb eine Zeile unter der Bereitschaft, kein eigener
/// Bereich und kein Tab. Lime nur als 8-dp-Punkt, nie als Fläche der Zeile:
/// Erfolg gehört dem Runner.
///
/// Drei Zustände: letzte bekannt · Lücke ab 7 Tagen · nie erfasst.
class RecoveryRow extends StatelessWidget {
  const RecoveryRow({super.key, required this.status, required this.onAdd});

  final RecoveryStatus status;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final last = status.last;

    final String title;
    final String sub;
    final Color dot;
    final Color titleColor;

    if (last == null) {
      title = l10n.recoveryNever;
      sub =
          RecoveryKind.values.map((k) => recoveryKindName(l10n, k)).join(' · ');
      dot = AtemColors.border;
      titleColor = AtemColors.textTertiary;
    } else {
      final days = status.daysAgo!;
      final when = days == 0
          ? l10n.whenToday
          : days == 1
              ? l10n.whenYesterday
              : l10n.whenLast(DateFormat.MMMd(tag).format(last.date));
      final detail = l10n.recoveryLast(
        when,
        recoveryKindLabel(l10n, last),
        last.duration?.inMinutes ?? 0,
      );
      if (status.isGap) {
        title = l10n.recoveryGap(days);
        sub = detail;
        dot = AtemColors.border;
      } else {
        title = l10n.recoveryTitle;
        sub = detail;
        dot = AtemColors.green;
      }
      titleColor = AtemColors.textPrimary;
    }

    // **Der Ton der Regeneration liegt als Verlauf auf der Zeile.**
    //
    // Board 11 verbot Lime als *Fläche der Zeile* — gemeint war eine
    // ausgefüllte Lime-Kachel, die wie ein Erfolg aussieht. Ein Verlauf bei
    // zehn Prozent Deckkraft ist das nicht; er sagt „das gehört zur
    // Regeneration", und der 8-dp-Punkt bleibt der Statusträger.
    return AtemTappable(
      onTap: onAdd,
      // Voll: „Regeneration, gestern, Yoga, 25 Minuten. Regeneration erfassen."
      semanticLabel: '$title, $sub. ${l10n.recoveryTitle} ${l10n.recoveryAdd}',
      child: AtemToneCard(
        tone: AtemColors.tabRecovery,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: AtemType.titleSmallOrDefault(context)
                            .copyWith(color: titleColor)),
                    const SizedBox(height: 2),
                    Text(sub.toUpperCase(),
                        style: AtemType.labelMicro.of(context)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(l10n.recoveryAdd.toUpperCase(),
                  style: AtemType.labelMicro
                      .of(context)
                      .copyWith(color: AtemColors.green)),
            ],
          ),
        ),
      ),
    );
  }
}
