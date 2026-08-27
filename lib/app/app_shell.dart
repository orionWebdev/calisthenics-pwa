import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../core/widgets/widgets.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/widgets/floating_nav.dart';
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

class _AppShellState extends ConsumerState<AppShell> {
  int _tab = 0;

  void _select(int index) => setState(() => _tab = index);

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
          IndexedStack(
            index: _tab,
            children: [
              DashboardScreen(onSelectTab: _select),
              WorkoutsScreen(onStart: _start),
              _Soon(l10n: l10n),
              _Soon(l10n: l10n),
              _Soon(l10n: l10n),
            ],
          ),
          Positioned(
            left: AtemSpacing.screenPadding,
            right: AtemSpacing.screenPadding,
            bottom: AtemSpacing.screenPadding +
                MediaQuery.viewPaddingOf(context).bottom,
            child: FloatingNav(activeIndex: _tab, onSelect: _select),
          ),
        ],
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
