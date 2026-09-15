import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/screens/session_detail_screen.dart';
import '../../../history/presentation/session_ui.dart';
import '../cardio_ui.dart';

/// Die Cardio-Einheitenzeile — **die Übungskarte aus Modul 5** mit
/// Aktivitätskürzel statt Kategoriefarbe (Board 11, Sektion I).
///
/// 48 dp Mindesthöhe, IconBox 26 dp mit Radius 10, das Kürzel in Cyan. Zwei
/// Varianten: mit Distanz (km und Tempo rechts) und ohne (nur Minuten).
class CardioSessionRow extends StatelessWidget {
  const CardioSessionRow({super.key, required this.session});

  final CardioSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final date = DateFormat.E(tag).format(session.date);
    final day = DateFormat.MMMd(tag).format(session.date);
    final minutes = session.duration?.inMinutes;
    final name = session.name ?? activityLabel(l10n, session.activity);
    final meta = [
      '$date $day',
      if (minutes != null) l10n.durationMinutes(minutes),
    ].join(' · ');
    final km = session.distanceKm;
    final tempo = session.tempo;

    return AtemTappable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailScreen(session: session),
        ),
      ),
      semanticLabel: [
        name,
        meta,
        if (km != null) l10n.unitKilometers(formatKm(context, km)),
        if (tempo != null) formatTempo(context, tempo),
      ].join(', '),
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AtemColors.cyan.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AtemRadii.iconBox),
              ),
              child: Text(
                activityAbbreviation(l10n, session.activity),
                style: AtemType.labelDeco
                    .of(context)
                    .copyWith(color: AtemColors.cyan, letterSpacing: 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.titleSmallOrDefault(context)),
                  const SizedBox(height: 2),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.meta.of(context)),
                ],
              ),
            ),
            if (km != null) ...[
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.unitKilometers(formatKm(context, km)),
                      style: AtemType.valueMedium
                          .of(context)
                          .copyWith(fontSize: 14)),
                  if (tempo != null)
                    Text(formatTempo(context, tempo),
                        style: AtemType.labelMicro.of(context).copyWith(
                            color: AtemColors.textTertiary, letterSpacing: 0)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
