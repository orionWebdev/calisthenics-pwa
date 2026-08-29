import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/tab_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../strength/presentation/screens/strength_screen.dart';

/// Der Cardio-Tab — Board 11, Sektion A2 und B1.
///
/// Schritt S1: die Wurzel mit Kopf, Umschalter und dem Leerzustand aus B1/2.
/// Wochenzahl, Liste und Auswertung folgen in S5 und S6.
class CardioScreen extends ConsumerWidget {
  const CardioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final segment = ref.watch(appTabsProvider.select((s) => s.cardioSegment));
    final sessions = ref.watch(sessionsProvider).value ?? const [];
    final count = sessions.where((s) => s.kind == SessionKind.cardio).length;

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabHeader(
              title: l10n.tabCardio,
              count: count,
              switcher: AtemTabSwitch<CardioSegment>(
                groupSemanticLabel: l10n.tabCardio,
                value: segment,
                onChanged: (s) =>
                    ref.read(appTabsProvider.notifier).setCardioSegment(s),
                segments: [
                  AtemTabSegment(
                      value: CardioSegment.sessions, label: l10n.segSessions),
                  AtemTabSegment(
                      value: CardioSegment.analysis, label: l10n.segAnalysis),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AtemSpacing.screenPadding),
                child: AtemEmptyState(
                  title: l10n.cardioEmptyTitle,
                  body: l10n.cardioEmptyBody,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
