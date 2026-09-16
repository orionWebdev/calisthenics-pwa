import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/application/tab_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/screens/analysis_screen.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../plans/presentation/screens/plan_catalog_page.dart';
import '../../../plans/presentation/start_sheet.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../workout/presentation/screens/workouts_screen.dart';

/// Der Kraft-Tab — **vier Seiten, die man wischt**.
///
/// Seit dem 16.09.2026 auf Wunsch des Nutzers: Trainieren, Verlauf,
/// Auswertung, Pläne. Vorher waren es zwei Segmente (Board 11, A1); die
/// Auswertung lag dahinter als eigener Bildschirm, und ATEM-Pläne gab es nicht.
///
/// ## Aufbau
///
/// Kopf mit Name und Zahl der Einheiten — mit Nenner, wie jede Zahl in dieser
/// App —, darunter [AtemPageTabs], darunter ein [PageView]. Jede Seite behält
/// Zustand und Scrollstand, wenn man weiterwischt.
///
/// ## Übergang
///
/// Die eintretende Seite läuft nicht starr mit dem Finger: Ihr Inhalt hängt
/// um 12 % der Breite nach und blendet von 0,6 auf volle Deckkraft. Beim
/// ersten Besuch einer Seite laufen ihre Blöcke zusätzlich mit der
/// Eintrittskaskade ein ([AtemEntrance]) — der [PageView] baut eine Seite
/// erst, wenn sie erreicht wird, und hält sie danach am Leben, deshalb
/// wiederholt sich die Kaskade bei der Rückkehr nicht.
///
/// ## Seite und Provider
///
/// [StrengthSegment] im [appTabsProvider] bleibt die eine Wahrheit. Wischen
/// setzt es; ein Sprung von aussen — die Kraft-Zeile im Hybrid-Tab öffnet
/// den Verlauf — wirft die Seite an. Systemzurück wechselt keine Seite.
class StrengthScreen extends ConsumerStatefulWidget {
  const StrengthScreen({super.key, required this.onStart});

  final ValueChanged<StartRequest> onStart;

  /// Deckkraft einer Seite, die eine volle Seitenbreite entfernt steht.
  static const pageFadeFloor = 0.6;

  /// Wie weit der Inhalt der Bewegung der Seite nachhängt.
  static const pageParallax = 0.12;

  @override
  ConsumerState<StrengthScreen> createState() => _StrengthScreenState();
}

class _StrengthScreenState extends ConsumerState<StrengthScreen> {
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _pages = PageController(
      initialPage: ref.read(appTabsProvider).strengthSegment.index,
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Ein Sprung von aussen: Seite anwerfen, sofern nicht gerade gewischt
  /// oder animiert wird — sonst kämpfte der Provider gegen den Finger.
  void _follow(StrengthSegment segment) {
    if (!_pages.hasClients) return;
    final position = _pages.position;
    if (position.isScrollingNotifier.value) return;
    final current = (_pages.page ?? _pages.initialPage.toDouble()).round();
    if (current == segment.index) return;
    if (AtemMotion.reduced(context) || !TickerMode.valuesOf(context).enabled) {
      _pages.jumpToPage(segment.index);
    } else {
      _pages.animateToPage(
        segment.index,
        duration: AtemPageTabs.pageDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    ref.listen(appTabsProvider.select((s) => s.strengthSegment),
        (_, next) => _follow(next));

    final sessions = ref.watch(sessionsProvider).value ?? const [];
    final count = sessions
        .where((s) =>
            s.kind == SessionKind.strength || s.kind == SessionKind.bodyweight)
        .length;
    final countText = l10n.cardioWeekCount(count);

    final pages = <Widget>[
      WorkoutsScreen(onStart: widget.onStart, embedded: true),
      HistoryScreen(
        embedded: true,
        onStart: () => _startFree(context, ref),
      ),
      const AnalysisScreen(embedded: true),
      const PlanCatalogPage(),
    ];
    final labels = [
      l10n.segTrain,
      l10n.segHistory,
      l10n.segAnalysis,
      l10n.segPlans,
    ];

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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 8),
                child: Semantics(
                  // Ein Knoten: „Kraft, 63 Einheiten".
                  label: '${l10n.tabStrength}, $countText',
                  header: true,
                  child: ExcludeSemantics(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        Text(l10n.tabStrength,
                            style: AtemType.titleLarge.of(context)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child:
                              Text(countText, style: AtemType.meta.of(context)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AtemPageTabs(
                controller: _pages,
                labels: labels,
                groupSemanticLabel: l10n.strengthPagesA11y,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: pages.length,
                  // Der PageView meldet jede überquerte Seitenmitte, auch
                  // die Zwischenseiten einer Tipp-Animation über mehrere
                  // Seiten. Das ist unschädlich: `_follow` greift nicht ein,
                  // solange gescrollt wird, und die letzte Meldung ist die
                  // Zielseite.
                  onPageChanged: (i) => ref
                      .read(appTabsProvider.notifier)
                      .setStrengthSegment(StrengthSegment.values[i]),
                  itemBuilder: (context, index) => _KeepAlive(
                    child: _PageMotion(
                      controller: _pages,
                      index: index,
                      child: pages[index],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Parallax und Deckkraft einer Seite, abhängig vom Wischfortschritt.
class _PageMotion extends StatelessWidget {
  const _PageMotion({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AtemMotion.reduced(context)) return child;

    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          var delta = 0.0;
          if (controller.hasClients &&
              controller.position.hasContentDimensions) {
            delta = (controller.page ?? index.toDouble()) - index;
          }
          final distance = delta.abs().clamp(0.0, 1.0);
          final opacity = 1 - distance * (1 - StrengthScreen.pageFadeFloor);
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              // Der Inhalt hängt der Seite nach — zur Mitte hin.
              offset: Offset(
                  delta * constraints.maxWidth * StrengthScreen.pageParallax,
                  0),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Hält eine Seite am Leben, wenn man weiterwischt — Zustand, Scrollstand
/// und die schon gelaufene Eintrittskaskade bleiben.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Ein freies Training aus dem Verlauf heraus.
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
