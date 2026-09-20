import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/app/application/snackbar_providers.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/health_import/domain/session_pairing.dart';
import 'package:atem/features/health_import/presentation/widgets/pair_sheet.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

class _Repo implements HealthSessionRepository {
  final saved = <HealthSession>[];

  @override
  Stream<List<HealthSession>> watch(String userId) => Stream.value(saved);
  @override
  Future<List<HealthSession>> fetch(String userId) async => saved;
  @override
  Future<void> save(String userId, HealthSession session) async {
    saved
      ..removeWhere((s) => s.externalId == session.externalId)
      ..add(session);
  }

  @override
  Future<void> delete(String userId, String externalId) async {}
  @override
  Future<DateTime?> lastRead(String userId) async => null;
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

/// Das Paar-Blatt aus Board 15, B1 und B5.
void main() {
  final start = DateTime(2026, 9, 18, 18, 2);
  late _Repo repo;

  HealthSession watch() => HealthSession.pending(
        MeasuredSession(
          id: 'hc-1',
          start: DateTime(2026, 9, 18, 18),
          end: DateTime(2026, 9, 18, 18, 58),
          sourceId: 'garmin',
          deviceName: 'Garmin',
          averageHeartRate: 118,
          maxHeartRate: 164,
        ),
        start,
      );

  StrengthSession app({String id = 'a1', DateTime? at}) => StrengthSession(
        id: id,
        userId: 'u',
        date: at ?? start,
        createdAt: at ?? start,
        duration: const Duration(minutes: 52),
        rpe: 4,
        bodyweight: false,
        exercises: [
          LoggedExercise(
            exerciseId: 'e1',
            sets: [for (var i = 0; i < 24; i++) const LoggedSet(reps: 8)],
          ),
        ],
      );

  Future<AppL10n> pump(WidgetTester tester, PairVerdict verdict) async {
    repo = _Repo();
    tester.view.physicalSize = const Size(361, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...fixtureOverrides,
        healthSessionRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue('u'),
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
        home: Scaffold(
          backgroundColor: AtemColors.base,
          body: SizedBox(
            height: 960,
            child: PairSheet(measured: watch(), verdict: verdict),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return AppL10n.of(tester.element(find.byType(PairSheet)));
  }

  testWidgets('die Vermutung wird als Frage gestellt, mit ihrer Begründung',
      (tester) async {
    final l10n = await pump(
      tester,
      PairSuggested(session: app(), overlap: const Duration(minutes: 52)),
    );

    expect(find.text(l10n.hcPairQuestion), findsOneWidget);
    expect(find.text(l10n.hcPairAppRow.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.hcPairWatchRow.toUpperCase()), findsOneWidget);
    // Die Begründung steht in Zahlen: 52 von 52 min, 2 min auseinander.
    expect(find.text(l10n.hcPairOverlap(52, 52, 2)), findsOneWidget);
    expect(find.text(l10n.hcPairMerge), findsOneWidget);
    expect(find.text(l10n.hcPairKeepApart), findsOneWidget);
  });

  testWidgets('Zusammenführen zeigt zuerst die Folgen, dann verknüpft es',
      (tester) async {
    final l10n = await pump(
      tester,
      PairSuggested(session: app(), overlap: const Duration(minutes: 52)),
    );

    await tester.tap(find.text(l10n.hcPairMerge));
    await tester.pumpAndSettle();

    // Stufe 1: gerechnet, nicht gewarnt — drei Zeilen sagen „bleibt".
    expect(find.text(l10n.hcMergeStage1Title), findsOneWidget);
    expect(find.text(l10n.hcMergeStays('24')), findsOneWidget);
    expect(find.text(l10n.hcMergeStays('52')), findsOneWidget);
    expect(find.text(l10n.hcMergeGains('118')), findsOneWidget);
    // Der Uhr-Wert verschwindet nicht.
    expect(find.text(l10n.hcMergeDurationNote(52, 58)), findsOneWidget);

    // Stufe 2 ist der Knopf selbst.
    await tester.tap(find.text(l10n.hcPairMerge).last);
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(1));
    expect(repo.saved.single.state, HealthSessionState.accepted);
    expect(repo.saved.single.sessionId, 'a1');
  });

  testWidgets('die Rücknahme löst die Verbindung wieder', (tester) async {
    // B4: Zwei Wege zurück. Der erste sind sechs Sekunden unmittelbar danach
    // — verlustfrei, weil die Uhr-Einheit danebenliegen bleibt.
    final l10n = await pump(
      tester,
      PairSuggested(session: app(), overlap: const Duration(minutes: 52)),
    );

    // Das Blatt schliesst sich nach dem Zusammenführen — der Behälter wird
    // vorher gegriffen.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(PairSheet)));

    await tester.tap(find.text(l10n.hcPairMerge));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.hcPairMerge).last);
    await tester.pumpAndSettle();
    expect(repo.saved.single.state, HealthSessionState.accepted);

    // Die Meldung liegt im zentralen Kanal; ihr Wirt ist die App-Hülle, die
    // dieser Test nicht mitbringt. Geprüft wird deshalb der Vertrag: Die
    // Meldung trägt einen Rückweg, und der löst die Verbindung.
    final snack = container.read(snackbarProvider);
    expect(snack?.message, l10n.hcMergedSnack);
    expect(snack?.actionLabel, l10n.commonUndo);

    snack!.onAction!();
    await tester.pumpAndSettle();

    expect(repo.saved.single.state, HealthSessionState.pending);
    expect(repo.saved.single.sessionId, isNull);
  });

  testWidgets('„Getrennt lassen" verknüpft nichts', (tester) async {
    final l10n = await pump(
      tester,
      PairSuggested(session: app(), overlap: const Duration(minutes: 52)),
    );

    await tester.tap(find.text(l10n.hcPairKeepApart));
    await tester.pumpAndSettle();
    expect(repo.saved, isEmpty);
  });

  testWidgets('bei mehreren Kandidaten gibt es keine Vermutung',
      (tester) async {
    final l10n = await pump(
      tester,
      PairAmbiguous([
        app(),
        app(id: 'a2', at: DateTime(2026, 9, 18, 19)),
      ]),
    );

    expect(find.text(l10n.hcAmbiguousNote), findsOneWidget);
    // Beide stehen zur Auswahl, keiner ist vorausgewählt.
    expect(find.text(l10n.hcAmbiguousPick), findsNWidgets(3));
    // Der Weg ohne Zuordnung bleibt gleichwertig sichtbar.
    expect(find.text(l10n.hcAmbiguousStandalone), findsOneWidget);
  });
}
