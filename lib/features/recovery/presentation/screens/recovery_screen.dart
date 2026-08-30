import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../cardio/domain/last_activity.dart';
import '../../../cardio/presentation/cardio_ui.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/screens/session_detail_screen.dart';
import '../../../history/presentation/session_ui.dart';
import '../../../hybrid/presentation/widgets/recovery_sheet.dart';

/// Der Regenerations-Tab.
///
/// ## Was er beantwortet
///
/// Der Hybrid-Tab sagt „wie steht es um mich" — dort steht Regeneration als
/// **eine Zeile** neben der Bereitschaft, weil sie dort eine Eingangsgrösse
/// ist. Dieser Tab sagt „was habe ich gemacht": die erfassten Einheiten, nach
/// Art gezählt, mit dem Weg zum Erfassen.
///
/// ## Was er nicht tut
///
/// Er rechnet nichts. Regeneration trägt keine Last — es gibt keinen Wert,
/// den man aus ihr ableiten dürfte, und deshalb keine Kurve, kein Verhältnis
/// und keine Zielvorgabe. Was hier steht, ist gezählt.
class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final sessions = ref.watch(sessionsProvider).value ?? const [];
    final reference = ref.watch(historyReferenceProvider);

    final entries = <RecoverySession>[
      for (final s in sessions)
        if (s is RecoverySession) s,
    ]..sort((a, b) => b.date.compareTo(a.date));

    final status = RecoveryStatus.of(sessions, reference);

    // Zählung je Art — über den ganzen Bestand, nicht über ein Fenster: Bei
    // zwölf Einheiten wäre ein Achtwochenfenster meist leer.
    final byKind = <RecoveryKind, int>{};
    for (final e in entries) {
      final kind = e.recoveryKind;
      if (kind != null) byKind[kind] = (byKind[kind] ?? 0) + 1;
    }

    return AtemTabTheme(
      tone: AtemColors.tabRecovery,
      child: Scaffold(
        backgroundColor: AtemColors.base,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 130),
            children: [
              _Header(count: entries.length),
              const SizedBox(height: 18),
              _StatusCard(status: status, onAdd: () => _add(context)),

              if (byKind.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(l10n.recoveryTabKinds.toUpperCase(),
                    style: AtemType.labelMicro.of(context)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in RecoveryKind.values)
                      if (byKind[kind] case final n? when n > 0)
                        AtemBadge(
                          label:
                              '${recoveryKindName(l10n, kind)} $n'.toUpperCase(),
                        ),
                  ],
                ),
              ],

              // **Ein Block ohne Daten rendert nicht.** Ist noch nichts
              // erfasst, hört der Bildschirm hinter der Statuskarte auf; die
              // Karte trägt dann den Leerzustand selbst.
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(l10n.recoveryTabAll.toUpperCase(),
                    style: AtemType.labelMicro.of(context)),
                const SizedBox(height: 10),
                AtemCard.list(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < entries.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: AtemColors.border),
                        _Row(session: entries[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _add(BuildContext context) =>
      RecoverySheet.show(context);
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final countText = l10n.cardioWeekCount(count);

    return Semantics(
      header: true,
      label: '${l10n.recoveryTitle}, $countText',
      child: ExcludeSemantics(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 10,
          runSpacing: 2,
          children: [
            Text(l10n.recoveryTitle, style: AtemType.titleLarge.of(context)),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(countText.toUpperCase(),
                  style: AtemType.labelMicro.of(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Der Zustand oben: was zuletzt war, und der Weg zum Erfassen.
///
/// Der Ton des Tabs liegt hier als schwacher Verlauf auf der Karte — das ist
/// die einzige Fläche, die ihn trägt. Lime bleibt sonst dem 8-dp-Punkt
/// vorbehalten (Board 11, C2: „Erfolg gehört dem Runner").
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.onAdd});

  final RecoveryStatus status;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final last = status.last;

    final String title;
    final String detail;
    if (last == null) {
      title = l10n.recoveryTabEmptyTitle;
      detail = l10n.recoveryTabEmptyBody;
    } else {
      final days = status.daysAgo!;
      final when = days == 0
          ? l10n.whenToday
          : days == 1
              ? l10n.whenYesterday
              : l10n.whenLast(DateFormat.MMMd(tag).format(last.date));
      title = status.isGap ? l10n.recoveryGap(days) : l10n.recoveryTitle;
      detail = l10n.recoveryLast(
        when,
        recoveryKindLabel(l10n, last),
        last.duration?.inMinutes ?? 0,
      );
    }

    return AtemToneCard(
      tone: AtemColors.tabRecovery,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: '$title. $detail',
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: AtemStatusDot(color: AtemColors.green),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: AtemType.titleMedium.of(context)),
                        const SizedBox(height: 5),
                        Text(detail, style: AtemType.labelSmall.of(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AtemButton.outline(
            label: l10n.recoveryAdd,
            semanticLabel: l10n.recoveryAdd,
            accent: AtemColors.green,
            leading:
                const Icon(Icons.add, size: 18, color: AtemColors.green),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

/// Eine erfasste Regeneration: Datum, Art, Dauer.
class _Row extends StatelessWidget {
  const _Row({required this.session});

  final RecoverySession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final day = DateFormat.d(tag).format(session.date);
    final weekday = DateFormat.E(tag).format(session.date).toUpperCase();
    final minutes = session.duration?.inMinutes;
    final kind = recoveryKindLabel(l10n, session);

    return AtemTappable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionDetailScreen(session: session),
        ),
      ),
      semanticLabel: [
        DateFormat.yMMMMEEEEd(tag).format(session.date),
        kind,
        if (minutes != null) l10n.durationMinutes(minutes),
      ].join(', '),
      minTapSize: const Size(0, 56),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(day,
                      style: AtemType.valueMedium
                          .of(context)
                          .copyWith(fontSize: 13)),
                  Text(weekday,
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(kind,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.titleSmallOrDefault(context)),
            ),
            if (minutes != null) ...[
              const SizedBox(width: 10),
              Text(l10n.durationMinutes(minutes).toUpperCase(),
                  style: AtemType.labelMicro.of(context)),
            ],
          ],
        ),
      ),
    );
  }
}
