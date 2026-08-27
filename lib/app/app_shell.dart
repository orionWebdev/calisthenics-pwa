import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../core/widgets/widgets.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/widgets/floating_nav.dart';
import '../features/history/application/pending_deletion.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/plans/presentation/start_sheet.dart';
import '../features/workout/presentation/screens/workout_runner_screen.dart';
import '../features/workout/presentation/screens/workouts_screen.dart';
import '../l10n/gen/app_l10n.dart';

/// Der Rahmen um die Tabs.
///
/// ## Warum die Navigation hier liegt und nicht im Dashboard
///
/// Vorher gehörte die schwebende Leiste dem Dashboard, samt seinem eigenen
/// `_activeNav`. Damit war sie an einen einzelnen Bildschirm gebunden — und
/// jeder weitere Tab hätte sie neu bauen müssen. Eine Navigation, die einem
/// ihrer Ziele gehört, ist keine Navigation.
///
/// `go_router` mit `StatefulShellRoute` löst das später sauberer, samt tiefen
/// Verweisen und Zurück-Verhalten je Tab. Bis dahin trägt dieser Rahmen den
/// Zustand — an **einer** Stelle statt an fünf.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  int _tab = 0;

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: AtemMotion.normal,
    value: 1,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _fadeController,
    curve: AtemMotion.curve,
  );

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _tab) return;
    setState(() => _tab = index);
    // Bei „Bewegung reduzieren" liefert `duration` null — dann springt der
    // Wechsel, wie er soll.
    _fadeController.duration = AtemMotion.duration(context, AtemMotion.normal);
    _fadeController.forward(from: 0);
  }

  Future<void> _start(StartRequest request) async {
    // Der Runner bekommt die Termin-Kennung, wenn es eine gibt. Beim freien
    // Training bleibt sie leer.
    await Navigator.of(context).pushNamed(
      WorkoutRunnerScreen.routeName,
      arguments: request.plan?.id ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: Stack(
        children: [
          // IndexedStack, nicht Austausch: Der Zustand eines Tabs — Scrollstand,
          // Suchtext, laufende Animation — überlebt den Wechsel.
          //
          // Der Übergang blendet **nur den neuen Tab ein**, statt zwei
          // Bildschirme gegeneinander zu überblenden. Ein `AnimatedSwitcher`
          // mit wechselndem Schlüssel wäre die naheliegende Lösung und die
          // falsche: Er baut den ganzen Stapel neu, wirft damit genau den
          // Zustand weg, für den der IndexedStack da ist, und lässt bei jedem
          // Wechsel fünf Bildschirme neu entstehen.
          //
          // Kein Schieben nach links: Die Tabs liegen übereinander, nicht
          // nebeneinander. Eine Seitwärtsbewegung behauptete eine Reihenfolge,
          // die es nicht gibt.
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.012),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _fade,
                curve: AtemMotion.curve,
              )),
              child: IndexedStack(
                index: _tab,
                children: [
                  DashboardScreen(onSelectTab: _select),
                  WorkoutsScreen(onStart: _start),
                  const HistoryScreen(),
                  _Soon(l10n: l10n),
                  _Soon(l10n: l10n),
                ],
              ),
            ),
          ),
          Positioned(
            left: AtemSpacing.screenPadding,
            right: AtemSpacing.screenPadding,
            bottom: AtemSpacing.screenPadding +
                MediaQuery.viewPaddingOf(context).bottom,
            // Eigene Malschicht: Die Leiste ändert sich beim Scrollen nicht.
            // Ohne diese Grenze zieht ihr Blur den scrollenden Inhalt in
            // dieselbe Ebene und lässt ihn bei jedem Frame mitzeichnen.
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // **Der Widerruf gehört in die Hülle, nicht auf einen
                  // Bildschirm.** Wer eine Einheit im Detail löscht, landet
                  // danach in der Liste; wer sie in der Liste löscht, bleibt
                  // dort. Ein Hinweis, der am Bildschirm hinge, verschwände
                  // beim ersten dieser beiden Wege — genau dann, wenn er
                  // gebraucht wird.
                  const _UndoSlot(),
                  FloatingNav(activeIndex: _tab, onSelect: _select),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Der Widerrufshinweis über der Navigation.
///
/// Null Pixel hoch, solange nichts schwebt — dieselbe Regel wie bei jedem
/// [AtemNoticeSlot]. Ein reservierter Leerraum sähe aus wie eine Meldung, die
/// noch kommt.
class _UndoSlot extends ConsumerWidget {
  const _UndoSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final pending = ref.watch(pendingDeletionProvider);

    return AtemNoticeSlot(
      notice: pending == null
          ? null
          : AtemNotice(
              title: l10n.sessionDeletedTitle(pending.label),
              body: l10n.sessionDeletedBody(
                  PendingDeletionController.window.inSeconds),
              semanticLabel: '${l10n.sessionDeletedTitle(pending.label)}. '
                  '${l10n.sessionDeletedBody(PendingDeletionController.window.inSeconds)}',
              actionLabel: l10n.sessionDeletedUndo,
              onAction: () =>
                  ref.read(pendingDeletionProvider.notifier).undo(),
            ),
    );
  }
}

class _Soon extends StatelessWidget {
  const _Soon({required this.l10n});

  final AppL10n l10n;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AtemSpacing.screenPadding),
          child: AtemEmptyState(
            title: l10n.navSoonTitle,
            body: l10n.navSoonBody,
          ),
        ),
      );
}
