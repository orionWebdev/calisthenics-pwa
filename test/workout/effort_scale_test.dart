import 'dart:io';

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/workout/application/workout_providers.dart';
import 'package:atem/features/workout/domain/workout_session.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';

/// RIR statt RPE — dieselbe Angabe, andersherum gezählt (20.09.2026).
///
/// Der Kern dieser Tests: **Umgestellt wird die Anzeige, nicht der Bestand.**
/// Ein Satz, der als „2 RIR" eingetragen wurde, steht in Firestore als RPE 8 —
/// sonst hinge die Bedeutung jeder Zahl an einer Kontoeinstellung, und die
/// Auswertung über Monate wäre nicht mehr vergleichbar.
void main() {
  const start = WorkoutStart(planId: 'p1');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  group('Die Umrechnung', () {
    test('RPE 10 ist 0 RIR, RPE 8 ist 2 RIR', () {
      expect(EffortScale.rir.number(10), 0);
      expect(EffortScale.rir.number(8), 2);
      expect(EffortScale.rir.number(6), 4);
    });

    test('in RPE bleibt die Zahl, wie sie gespeichert ist', () {
      for (var rpe = 1; rpe <= 10; rpe++) {
        expect(EffortScale.rpe.number(rpe), rpe);
      }
    });

    test('kennt keinen dritten Zustand', () {
      expect(EffortScale.fromWire('rir'), EffortScale.rir);
      expect(EffortScale.fromWire('rpe'), EffortScale.rpe);
      // Alles Unbekannte ist RPE: die Skala, in der jede bisherige Angabe im
      // Bestand gemacht wurde.
      expect(EffortScale.fromWire(null), EffortScale.rpe);
      expect(EffortScale.fromWire('RIR'), EffortScale.rpe);
      expect(EffortScale.fromWire(2), EffortScale.rpe);
    });
  });

  test('die Einstellung erreicht den Provider', () async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
      ),
      settingsRepositoryProvider.overrideWithValue(
        FakeSettingsRepository(
          settings: FakeSettingsRepository.fixture
              .copyWith(effortScale: EffortScale.rir),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    // Zuhören, nicht nur lesen: Ohne Zuhörer bleibt der Strom der Anmeldung
    // ungelesen, und die Einstellungen kämen nie an.
    container.listen(effortScaleProvider, (_, __) {});
    await container.read(authStateProvider.future);
    await container.read(settingsProvider.future);

    expect(container.read(effortScaleProvider), EffortScale.rir);
  });

  group('Der Runner in RIR', () {
    Future<ProviderContainer> pump(WidgetTester tester,
        {required EffortScale scale}) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        // Nicht über das Repository: `fixtureOverrides` überschreibt es
        // bereits, und Riverpod verbietet zwei Überschreibungen desselben
        // Providers. Dass die Einstellung beim Provider ankommt, prüft der
        // Test „aus den Einstellungen" weiter unten.
        overrides: [
          ...fixtureOverrides,
          effortScaleProvider.overrideWithValue(scale),
        ],
        child: MaterialApp(
          theme: AtemTheme.dark,
          locale: const Locale('de'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const WorkoutRunnerScreen(start: start),
        ),
      ));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
          tester.element(find.byType(WorkoutRunnerScreen)));
    }

    List<WorkoutSet> sets(ProviderContainer c) =>
        c.read(workoutSessionProvider(start)).value!.exercises.first.sets;

    Future<void> tickFirstSet(WidgetTester tester, ProviderContainer c) async {
      c
          .read(workoutSessionProvider(start).notifier)
          .updateReps(0, sets(c)[0].id, '8');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Satz 1 abschließen'));
      await tester.pumpAndSettle();
    }

    testWidgets('fragt in Wiederholungen in Reserve und speichert RPE',
        (tester) async {
      final handle = tester.ensureSemantics();
      final c = await pump(tester, scale: EffortScale.rir);
      await tickFirstSet(tester, c);

      // Die Reihe trägt 4–3–2–1–0 statt 6–7–8–9–10; nach rechts wird es in
      // beiden Skalen schwerer.
      expect(find.bySemanticsLabel('RIR 4 bis 0'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('10'), findsNothing);

      await tester
          .tap(find.bySemanticsLabel('RIR 2, noch 2 Wiederholungen möglich'));
      await tester.pumpAndSettle();

      expect(sets(c)[0].rpe, 8, reason: 'gespeichert wird weiterhin RPE');
      expect(find.text('2 RIR'), findsOneWidget);
      expect(find.text('RPE 8'), findsNothing);
      handle.dispose();
    });

    testWidgets('die Kapsel nennt die Reserve und bleibt ein Vorlese-Knoten',
        (tester) async {
      final handle = tester.ensureSemantics();
      final c = await pump(tester, scale: EffortScale.rir);
      await tickFirstSet(tester, c);
      await tester
          .tap(find.bySemanticsLabel('RIR 2, noch 2 Wiederholungen möglich'));
      await tester.pumpAndSettle();

      // Harter Satz bleibt harter Satz: RPE 8 ist 2 RIR, die Schwelle liegt
      // in beiden Skalen an derselben Stelle.
      expect(
        find.bySemanticsLabel(
            'Satz 1, 2 Wiederholungen in Reserve, harter Satz. Tippen zum Ändern'),
        findsOneWidget,
      );
      expect(find.text('harter Satz'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('in RPE bleibt alles, wie es war', (tester) async {
      final handle = tester.ensureSemantics();
      final c = await pump(tester, scale: EffortScale.rpe);
      await tickFirstSet(tester, c);

      expect(find.bySemanticsLabel('RPE 6 bis 10'), findsOneWidget);
      await tester
          .tap(find.bySemanticsLabel('RPE 8, noch 2 Wiederholungen möglich'));
      await tester.pumpAndSettle();

      expect(sets(c)[0].rpe, 8);
      expect(find.text('RPE 8'), findsOneWidget);
      handle.dispose();
    });
  });
}
