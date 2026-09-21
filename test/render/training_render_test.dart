@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/plans/presentation/widgets/plan_card.dart';
import 'package:atem/features/strength/presentation/screens/strength_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/dashboard/domain/dashboard_data.dart';
import 'package:atem/features/dashboard/domain/dashboard_repository.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/features/workout/presentation/widgets/train_section.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Kein Termin für heute — der Kopf trägt dann die letzte Einheit.
class _NoToday implements DashboardRepository {
  @override
  Stream<DashboardData> watchDashboard() =>
      PreviewDashboardRepository().watchDashboard().map((d) => DashboardData(
            user: d.user,
            readiness: d.readiness,
            performance: d.performance,
            session: null,
            workoutLog: d.workoutLog,
            lastSession: d.lastSession,
            nextSession: d.nextSession,
          ));
}

/// Der Plan liess sich nicht lesen.
class _Broken implements DashboardRepository {
  @override
  Stream<DashboardData> watchDashboard() =>
      Stream<DashboardData>.error(StateError('offline'));
}

/// Sichtprüfung Kraft › Trainieren und Pläne mit echten Schriften.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/training_render_test.dart
///
/// Ohne `ATEM_RENDER_DIR` wird nichts geschrieben.
void main() {
  Future<GlobalKey> pump(
    WidgetTester tester,
    Widget child, {
    double width = 361,
    double height = 2000,
    double scale = 1.15,
  }) async {
    await loadRealFonts();
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      overrides: fixtureOverrides,
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AtemTheme.dark,
          locale: const Locale('de'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: c!,
          ),
          home: child,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return key;
  }

  /// Schreibt [count] bildschirmhohe Ausschnitte, dazwischen wird die Seite
  /// um eine gute Bildschirmhöhe weitergescrollt.
  Future<void> shots(WidgetTester tester, GlobalKey key, String name,
      {int count = 3, double step = 620}) async {
    for (var i = 0; i < count; i++) {
      await writePng(tester, key, '${name}_$i');
      final lists = find.byType(Scrollable);
      if (lists.evaluate().isEmpty) break;
      // Die senkrechte Liste der aktiven Seite: die grösste Scrollable.
      Finder? vertical;
      var best = 0.0;
      for (final e in lists.evaluate()) {
        final state = (e as StatefulElement).state as ScrollableState;
        if (state.axisDirection != AxisDirection.down) continue;
        final box = e.renderObject! as RenderBox;
        if (!box.hasSize || !box.attached) continue;
        final area = box.size.width * box.size.height;
        if (area > best) {
          best = area;
          vertical = find.byElementPredicate((x) => identical(x, e));
        }
      }
      if (vertical == null) break;
      await tester.drag(vertical, Offset(0, -step));
      await tester.pumpAndSettle();
    }
  }

  /// Springt über die Ortszeile in ein Thema.
  ///
  /// Seit dem One-Pager (Board 13) steht in der Zeile **genau ein Wort** — das
  /// Thema, in dem man gerade ist. Die anderen liegen in einer Liste, die ein
  /// Tipp aufklappt. Bis zum 20.09.2026 suchte dieser Test `find.text('Pläne')`
  /// direkt und starb an „Bad state: No element", weil es den Reiter nicht
  /// mehr gibt.
  Future<void> jumpTo(WidgetTester tester, String label) async {
    await tester.tap(find.byType(AtemSectionBar));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AtemSectionJumpList),
      matching: find.text(label),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('rendert Kraft › Trainieren (Kopf, Reiter, Seite)',
      (tester) async {
    if (!renderEnabled) return;
    final key = await pump(tester, StrengthScreen(onStart: (_) {}),
        height: 800);
    await shots(tester, key, 'strength_trainieren');
  });

  /// Die drei übrigen Füllungen des Kopfs — mit Plan steht schon oben.
  testWidgets('rendert den Startblock ohne Plan, leer und im Fehler',
      (tester) async {
    if (!renderEnabled) return;

    for (final entry in <String, List<dynamic>>{
      'ohne_plan': [
        dashboardRepositoryProvider.overrideWithValue(_NoToday()),
      ],
      'erstoeffnung': [
        dashboardRepositoryProvider.overrideWithValue(_NoToday()),
        sessionStreamProvider
            .overrideWith((ref) => Stream.value(const <TrainingSession>[])),
        plansProvider.overrideWith((ref) => Stream.value(const <Plan>[])),
      ],
      'fehler': [
        dashboardRepositoryProvider.overrideWithValue(_Broken()),
      ],
    }.entries) {
      await loadRealFonts();
      tester.view.physicalSize = const Size(361, 460);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        // Eigener Schlüssel je Fall: Riverpod verbietet es, die **Anzahl**
        // der Überschreibungen eines bestehenden Scopes zu ändern.
        key: ValueKey(entry.key),
        overrides: [
          for (final o in fixtureOverrides)
            if (!entry.value.any((x) =>
                x.toString().split('#').first ==
                o.toString().split('#').first))
              o,
          ...entry.value,
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AtemTheme.dark,
            locale: const Locale('de'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, c) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.15)),
              child: c!,
            ),
            home: Scaffold(
              backgroundColor: AtemColors.base,
              body: TrainSection(onStart: (_) {}),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await writePng(tester, key, 'startblock_${entry.key}');
    }
  });

  testWidgets('rendert Kraft › Trainieren bei 200 % auf 320 dp',
      (tester) async {
    if (!renderEnabled) return;
    final key = await pump(tester, StrengthScreen(onStart: (_) {}),
        width: 320, height: 800, scale: 2.0);
    await shots(tester, key, 'strength_trainieren_320_200',
        count: 5, step: 640);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rendert Kraft › Pläne über die Ortszeile', (tester) async {
    if (!renderEnabled) return;
    final key =
        await pump(tester, StrengthScreen(onStart: (_) {}), height: 800);
    await jumpTo(tester, 'Pläne');
    await writePng(tester, key, 'strength_plaene');
    expect(tester.takeException(), isNull);
  });

  testWidgets('rendert Kraft › Pläne bei 200 % auf 320 dp', (tester) async {
    if (!renderEnabled) return;
    final key = await pump(tester, StrengthScreen(onStart: (_) {}),
        width: 320, height: 800, scale: 2.0);
    await jumpTo(tester, 'Pläne');
    await writePng(tester, key, 'strength_plaene_320_200');
    expect(tester.takeException(), isNull);
  });

  testWidgets('rendert eine Plan-Karten-Reihe mit langen Namen',
      (tester) async {
    if (!renderEnabled) return;
    const plans = [
      Plan(
        id: 'a',
        name: 'Oberkörper Push mit Zusatzgewicht und Handstand',
        items: [
          PlanItem(exerciseId: 'push_up'),
          PlanItem(exerciseId: 'dip'),
          PlanItem(exerciseId: 'pike'),
        ],
      ),
      Plan(id: 'b', name: 'Pull', items: [PlanItem(exerciseId: 'pull_up')]),
      Plan(
        id: 'c',
        name: 'Beine & Rumpf Ganzkörper',
        items: [PlanItem(exerciseId: 'squat'), PlanItem(exerciseId: 'plank')],
      ),
    ];
    final key = await pump(
      tester,
      Scaffold(
        backgroundColor: AtemColors.base,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: PlanCardRow(
            plans: plans,
            musclesOf: (p) => p.id == 'a'
                ? const [MuscleGroup.chest, MuscleGroup.triceps, MuscleGroup.shoulders]
                : const [MuscleGroup.back],
            onOpen: (_) {},
            onStart: (_) {},
          ),
        ),
      ),
      height: 700,
    );
    await writePng(tester, key, 'plan_row_long');
  });
}
