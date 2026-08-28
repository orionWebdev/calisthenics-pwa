import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../core/widgets/widgets.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/widgets/floating_nav.dart';
import 'application/snackbar_providers.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/plans/presentation/start_sheet.dart';
import '../features/workout/domain/workout_start.dart';
import '../features/workout/presentation/screens/workout_runner_screen.dart';
import '../features/workout/presentation/screens/workouts_screen.dart';

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
    // Plan **und** Pausenzeit wandern mit. Vorher ging beim Sprung in den
    // Runner beides verloren: Er bekam eine Zeichenkette, die niemand las,
    // und lud stattdessen immer dieselben drei Übungen aus einer Attrappe.
    await Navigator.of(context).pushNamed(
      WorkoutRunnerScreen.routeName,
      arguments: WorkoutStart(
        planId: request.plan?.id,
        scheduleId: request.scheduleId,
        restSeconds: request.restSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  // Die Meldung gehört in die Hülle, nicht auf einen
                  // Bildschirm: Wer eine Einheit im Detail löscht, landet
                  // danach in der Liste. Ein Hinweis, der am Bildschirm
                  // hinge, verschwände genau dann, wenn der Widerruf
                  // gebraucht wird.
                  const _SnackSlot(),
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

/// Die Meldung über der Navigation.
///
/// Null Pixel hoch, solange keine steht — ein reservierter Leerraum sähe aus
/// wie eine Meldung, die noch kommt.
class _SnackSlot extends ConsumerWidget {
  const _SnackSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snack = ref.watch(snackbarProvider);
    if (snack == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AtemSnackbar(
        message: snack.message,
        semanticLabel: snack.semanticLabel,
        tone: snack.tone,
        actionLabel: snack.actionLabel,
        onAction: snack.onAction == null
            ? null
            : () {
                ref.read(snackbarProvider.notifier).dismiss();
                snack.onAction!();
              },
      ),
    );
  }
}
