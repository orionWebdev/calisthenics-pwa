import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/tab_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../plans/presentation/start_sheet.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../workout/presentation/screens/workouts_screen.dart';

/// Der Kraft-Tab — **Trainieren und Verlauf, ein Tab, zwei Segmente**.
///
/// Board 11, Sektion A1: „Der heutige Workouts-Tab, ergänzt um den
/// Segment-Umschalter Trainieren / Verlauf. Der komplette Verlauf aus Modul 6
/// wandert hierher — keine neuen Bildschirme, nur ein neuer Einstieg."
///
/// Beide Segmente sind die bestehenden Bildschirme, eingebettet. Der Kopf
/// darüber ist das Einzige, was neu ist: der Name des Tabs mit der Zahl seiner
/// Einheiten — mit Nenner, wie jede Zahl in dieser App.
class StrengthScreen extends ConsumerWidget {
  const StrengthScreen({super.key, required this.onStart});

  final ValueChanged<StartRequest> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final segment =
        ref.watch(appTabsProvider.select((s) => s.strengthSegment));
    final sessions = ref.watch(sessionsProvider).value ?? const [];
    final count = sessions
        .where((s) =>
            s.kind == SessionKind.strength || s.kind == SessionKind.bodyweight)
        .length;

    // Der Ton des Bereichs: er färbt das Symbol in der Leiste und
    // legt einen sehr schwachen Verlauf über den Grund.
    return AtemTabTheme(
      tone: AtemColors.tabStrength,
      child: Scaffold(
        backgroundColor: AtemColors.base,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TabHeader(
                title: l10n.tabStrength,
                count: count,
                switcher: AtemTabSwitch<StrengthSegment>(
                  groupSemanticLabel: l10n.tabStrength,
                  value: segment,
                  onChanged: (s) =>
                      ref.read(appTabsProvider.notifier).setStrengthSegment(s),
                  segments: [
                    AtemTabSegment(
                        value: StrengthSegment.train, label: l10n.segTrain),
                    AtemTabSegment(
                        value: StrengthSegment.history, label: l10n.segHistory),
                  ],
                ),
              ),
              Expanded(
                // IndexedStack: Der Scrollstand des anderen Segments überlebt
                // den Wechsel — man kommt zurück, wo man war.
                child: IndexedStack(
                  index: segment == StrengthSegment.train ? 0 : 1,
                  children: [
                    WorkoutsScreen(onStart: onStart, embedded: true),
                    HistoryScreen(
                      embedded: true,
                      onStart: () => _startFree(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ein freies Training aus der Aussage-Karte heraus.
Future<void> _startFree(BuildContext context, WidgetRef ref) async {
  final request = await StartSheet.show(
    context,
    restSeconds: ref.read(defaultRestSecondsProvider),
  );
  if (request != null && context.mounted) {
    final screen = context.findAncestorWidgetOfExactType<StrengthScreen>();
    screen?.onStart(request);
  }
}

/// Der Kopf eines Tabs: Name, Zahl der Einheiten, Segment-Umschalter.
///
/// Geteilt von Kraft und Cardio. Der Name steht in Titelgrösse, die Zahl
/// daneben als Mono-Label: „Kraft · 63 Einheiten". Der Umschalter darunter,
/// nicht daneben — bei 200 % Schrift auf 320 dp passen beide nicht in eine
/// Zeile.
class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.title,
    required this.count,
    required this.switcher,
  });

  final String title;
  final int count;
  final Widget switcher;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final countText = l10n.cardioWeekCount(count);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            // Ein Knoten: „Kraft, 63 Einheiten".
            label: '$title, $countText',
            header: true,
            child: ExcludeSemantics(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 10,
                runSpacing: 2,
                children: [
                  Text(title, style: AtemType.titleLarge.of(context)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      countText,
                      style: AtemType.meta.of(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          switcher,
        ],
      ),
    );
  }
}

/// Öffentlich für den Cardio-Tab — derselbe Kopf, andere Segmente.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    required this.count,
    required this.switcher,
  });

  final String title;
  final int count;
  final Widget switcher;

  @override
  Widget build(BuildContext context) =>
      _TabHeader(title: title, count: count, switcher: switcher);
}
