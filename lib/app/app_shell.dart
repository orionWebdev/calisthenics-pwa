import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../core/widgets/widgets.dart';
import '../features/cardio/presentation/screens/cardio_screen.dart';
import '../features/dashboard/presentation/widgets/floating_nav.dart';
import '../features/health_import/application/health_import_providers.dart';
import '../features/weight/application/weight_sync_providers.dart';
import '../features/history/application/history_providers.dart';
import '../features/hybrid/presentation/screens/hybrid_screen.dart';
import '../features/recovery/presentation/screens/recovery_screen.dart';
import '../features/plans/presentation/start_sheet.dart';
import '../features/strength/presentation/screens/strength_screen.dart';
import '../features/workout/domain/workout_start.dart';
import '../features/workout/presentation/screens/workout_runner_screen.dart';
import 'application/snackbar_providers.dart';
import 'application/tab_providers.dart';

/// Der Rahmen um die drei Tabs — Kraft, Cardio, Hybrid.
///
/// ## Drei Stapel, nie zusammengelegt
///
/// Jeder Tab hat seinen eigenen `Navigator` (Board 11, Sektion A, Weg 3).
/// Wer im Kraft-Tab ein Plandetail öffnet, in den Hybrid-Tab wechselt und
/// zurückkommt, findet das Plandetail wieder vor. Ein gemeinsamer Stapel
/// hätte beim Tabwechsel entweder alles verworfen oder Bildschirme aus
/// verschiedenen Tabs übereinander gelegt.
///
/// Systemzurück geht zuerst in den Stapel des aktuellen Tabs. Ist der leer und
/// der Tab wurde **aus einer Zeile** erreicht — die Kraft-Zeile im
/// Verhältnisblock —, führt Zurück in den Hybrid-Tab an dieselbe
/// Scrollposition; der `IndexedStack` hat sie aufgehoben. Sonst schliesst die
/// App.
///
/// ## Die Leiste liegt nur auf den Wurzeln
///
/// Sobald ein Tab etwas gepusht hat, weicht die Leiste. Ein Formular mit
/// Speichern-Knopf am unteren Rand unter einer schwebenden Leiste wäre ein
/// Knopf, den man nicht trifft.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _keys = [
    for (final _ in AppTab.values) GlobalKey<NavigatorState>(),
  ];

  /// Beobachtet je Tab, ob etwas über der Wurzel liegt.
  late final _observers = [
    for (final _ in AppTab.values) _DepthObserver(onChange: _onDepthChanged),
  ];

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Beim Start einmal — danach bei jeder Rückkehr in den Vordergrund.
    WidgetsBinding.instance.addPostFrameCallback((_) => _readHealthConnect());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // „Heute" neu bestimmen. `historyReferenceProvider` wertet `DateTime.now()`
    // **einmal** aus und lebt so lange wie der Prozess — bei einer App, die
    // über Mitternacht im Hintergrund bleibt, läse der Abgleich sonst nur bis
    // zum Ende des Tages, an dem sie gestartet wurde, und Werte vom neuen Tag
    // kämen nie an.
    ref.invalidate(historyReferenceProvider);
    _readHealthConnect();
  }

  /// Liest Health Connect — **beim Öffnen, nicht im Hintergrund**.
  ///
  /// Kein Dienst, keine Benachrichtigung, keine Berechtigung mehr (Board 15,
  /// Entscheidung 3). Und **ohne zu fragen**: Ein Lesen, das von sich aus den
  /// Systemdialog öffnet, überfiele jeden, der die App aus einem anderen
  /// Grund gestartet hat. Gefragt wird nur in den Einstellungen, wo jemand
  /// danach gefragt hat.
  ///
  /// Ohne Freigabe kehrt der Lauf sofort zurück; was er findet, legt er als
  /// ungeprüft an. Sichtbar wird es als Zeile im Verlauf, nicht als Blatt.
  void _readHealthConnect() {
    if (!mounted) return;
    ref.read(healthImportControllerProvider.notifier).refresh();
    // Das Gewicht hatte bis zum 20.09.2026 **keinen Auslöser**: Der Abgleich
    // aus Modul 14 war gebaut und getestet, aber niemand rief ihn auf — auf
    // dem Gerät blieb die Kurve deshalb leer, obwohl der Zugriff frei war.
    //
    // Auch hier ohne zu fragen. Und der Abgleich wartet selbst, bis die
    // Reihe geladen ist, bevor er rechnet (`WeightSyncController`).
    ref.read(weightSyncProvider.notifier).run();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  void _onDepthChanged() {
    if (mounted) setState(() {});
  }

  void _select(AppTab tab) {
    if (tab == ref.read(appTabsProvider).tab) return;
    ref.read(appTabsProvider.notifier).select(tab);
  }

  void _animateSwitch() {
    // Bei „Bewegung reduzieren" liefert `duration` null — dann springt der
    // Wechsel, wie er soll.
    _fadeController.duration = AtemMotion.duration(context, AtemMotion.normal);
    _fadeController.forward(from: 0);
  }

  Future<void> _start(StartRequest request) async {
    // Der Runner liegt auf dem Wurzel-Navigator, über allen Tabs: Er
    // übernimmt den ganzen Bildschirm und gehört keinem Tab. Plan **und**
    // Pausenzeit wandern mit.
    await Navigator.of(context, rootNavigator: true).pushNamed(
      WorkoutRunnerScreen.routeName,
      arguments: WorkoutLaunch(
        WorkoutStart(
          planId: request.plan?.id,
          scheduleId: request.scheduleId,
          restSeconds: request.restSeconds,
        ),
        readiness: request.readiness,
      ),
    );
  }

  /// Systemzurück: Tab-Stapel, dann Rückweg eines Sprungs, dann die App.
  Future<void> _onBack() async {
    final tab = ref.read(appTabsProvider).tab;
    final navigator = _keys[tab.index].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (ref.read(appTabsProvider.notifier).goBack()) return;
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(appTabsProvider.select((s) => s.tab));
    ref.listen(appTabsProvider.select((s) => s.tab), (previous, next) {
      if (previous != next) _animateSwitch();
    });

    final atRoot = !(_keys[tab.index].currentState?.canPop() ?? false);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AtemColors.base,
        body: Stack(
          children: [
            // IndexedStack, nicht Austausch: Der Zustand eines Tabs —
            // Scrollstand, Suchtext, gepushte Bildschirme — überlebt den
            // Wechsel. Der Übergang blendet nur den neuen Tab ein; ein
            // AnimatedSwitcher baute den Stapel neu und würfe genau das weg.
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
                  index: tab.index,
                  // Die Reihenfolge folgt `AppTab` — Hybrid links.
                  children: [
                    _TabNavigator(
                      navigatorKey: _keys[AppTab.hybrid.index],
                      observer: _observers[AppTab.hybrid.index],
                      root: const AtemEntranceScope(
                        id: 'hybrid',
                        child: HybridScreen(),
                      ),
                    ),
                    _TabNavigator(
                      navigatorKey: _keys[AppTab.strength.index],
                      observer: _observers[AppTab.strength.index],
                      root: AtemEntranceScope(
                        id: 'strength',
                        child: StrengthScreen(onStart: _start),
                      ),
                    ),
                    _TabNavigator(
                      navigatorKey: _keys[AppTab.cardio.index],
                      observer: _observers[AppTab.cardio.index],
                      root: const AtemEntranceScope(
                        id: 'cardio',
                        child: CardioScreen(),
                      ),
                    ),
                    _TabNavigator(
                      navigatorKey: _keys[AppTab.recovery.index],
                      observer: _observers[AppTab.recovery.index],
                      root: const AtemEntranceScope(
                        id: 'recovery',
                        child: RecoveryScreen(),
                      ),
                    ),
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
                    // Das Band steht über der Meldung: Es beschreibt einen
                    // Zustand, sie ein Ereignis — und Zustände gehören weiter
                    // weg vom Daumen als Dinge, die man wegtippt.
                    const _OfflineSlot(),
                    const _SnackSlot(),
                    // Weicht, sobald ein Tab etwas gepusht hat — kein
                    // Ausblenden per Deckkraft: Ein unsichtbares Tap-Ziel
                    // bliebe ein Tap-Ziel.
                    if (atRoot) FloatingNav(active: tab, onSelect: _select),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ein Tab mit eigenem Stapel.
class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.observer,
    required this.root,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final NavigatorObserver observer;
  final Widget root;

  @override
  Widget build(BuildContext context) => Navigator(
        key: navigatorKey,
        observers: [observer],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          builder: (_) => root,
          settings: settings,
        ),
      );
}

/// Meldet, wenn sich die Tiefe eines Tab-Stapels ändert.
///
/// Nur das — keine Zählung, keine Namen. Die Hülle fragt den Navigator
/// selbst, ob er poppen kann; der Beobachter sorgt nur dafür, dass sie es
/// zum richtigen Zeitpunkt tut.
class _DepthObserver extends NavigatorObserver {
  _DepthObserver({required this.onChange});

  final VoidCallback onChange;

  // Nach dem Frame, nicht mitten im Aufbau: Push und Pop feuern während der
  // Navigator sich gerade ändert, und ein setState dort ist ein Fehler.
  void _later() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => onChange());

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _later();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _later();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _later();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _later();
}

/// Das Offline-Band über der Navigation.
class _OfflineSlot extends ConsumerWidget {
  const _OfflineSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      AtemOfflineBanner(offline: ref.watch(offlineProvider));
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
