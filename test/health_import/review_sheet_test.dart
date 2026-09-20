import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/health_import/presentation/widgets/review_sheet.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Eine Uhr-Quelle im Speicher.
class _FakeRepo implements HealthSessionRepository {
  final saved = <HealthSession>[];
  DateTime? mark;

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
  Future<void> delete(String userId, String externalId) async =>
      saved.removeWhere((s) => s.externalId == externalId);

  @override
  Future<DateTime?> lastRead(String userId) async => mark;

  @override
  Future<void> markRead(String userId, DateTime at) async => mark = at;
}

/// Das Prüfblatt aus Board 15, A2 bis A4.
void main() {
  late _FakeRepo repo;

  HealthSession session(String id, {int? avg = 148}) => HealthSession.pending(
        MeasuredSession(
          id: id,
          start: DateTime(2026, 9, 20, 9, 14),
          end: DateTime(2026, 9, 20, 9, 56),
          sourceId: 'garmin',
          activity: 'RUNNING',
          deviceName: 'Garmin',
          averageHeartRate: avg,
          maxHeartRate: 171,
          calories: 412,
        ),
        DateTime(2026, 9, 20, 10),
      );

  Future<AppL10n> pump(
    WidgetTester tester,
    List<HealthSession> pending, {
    double scale = 1.0,
    Size size = const Size(361, 900),
  }) async {
    repo = _FakeRepo();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...fixtureOverrides,
        healthSessionRepositoryProvider.overrideWithValue(repo),
        // Der Anmeldestrom antwortet erst nach dem ersten Frame; ohne
        // Kennung täte der Controller nichts, und der Test prüfte das
        // Nichtstun.
        currentUserIdProvider.overrideWithValue('u'),
      ],
      child: MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        // `showModalBottomSheet` gibt dem Blatt eine feste Höhe. Ohne Route
        // muss der Test sie stellen, sonst bekommt die Liste im Blatt
        // unbegrenzte Höhe.
        home: Scaffold(
          backgroundColor: AtemColors.base,
          body: SizedBox(
            height: size.height - 40,
            child: HealthReviewSheet(pending: pending),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return AppL10n.of(tester.element(find.byType(HealthReviewSheet)));
  }

  testWidgets('ohne Anstrengung benennt der Knopf, was er tut', (tester) async {
    final l10n = await pump(tester, [session('hc-1')]);

    // A3: Kein deaktivierter Knopf, kein Ersatzwert — das Label ist die
    // Warnung.
    expect(find.text(l10n.hcAcceptWithoutEffort), findsOneWidget);
    expect(find.text(l10n.hcAccept), findsNothing);
    expect(find.text(l10n.hcNoEffortNote), findsOneWidget);
  });

  testWidgets('mit Anstrengung heisst er schlicht „Übernehmen"',
      (tester) async {
    final l10n = await pump(tester, [session('hc-1')]);

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.hcAccept), findsOneWidget);
    expect(find.text(l10n.hcAcceptWithoutEffort), findsNothing);
    // Die eine Hinweiszeile verschwindet mit ihrem Grund.
    expect(find.text(l10n.hcNoEffortNote), findsNothing);
  });

  testWidgets('das Gemessene steht da, gerechnet wird nichts', (tester) async {
    final l10n = await pump(tester, [session('hc-1')]);

    expect(find.text(l10n.durationMinutes(42)), findsOneWidget);
    expect(find.text('148'), findsOneWidget);
    expect(find.text('171'), findsOneWidget);
    // Kalorien sind „weitere Angaben", nicht die vierte Kachel.
    expect(find.text(l10n.hcMoreDeviceValues(1)), findsOneWidget);
  });

  testWidgets('ablehnen merkt sich den Datensatz, statt ihn zu löschen',
      (tester) async {
    final l10n = await pump(tester, [session('hc-1')]);

    await tester.tap(find.text(l10n.hcDecline));
    await tester.pumpAndSettle();

    expect(repo.saved, hasLength(1));
    expect(repo.saved.single.state, HealthSessionState.rejected);
    expect(repo.saved.single.decidedAt, isNotNull);
  });

  testWidgets('ein Stapel führt nacheinander, mit Zähler und Ausgang',
      (tester) async {
    final l10n = await pump(
      tester,
      [session('hc-1'), session('hc-2'), session('hc-3')],
    );

    expect(find.text(l10n.hcSheetTitle(1, 3)), findsOneWidget);
    // Der Fussweg heisst „Später fortsetzen", solange noch etwas wartet —
    // „Nicht übernehmen" steht dann in der Liste.
    expect(find.text(l10n.hcContinueLater), findsOneWidget);
    expect(find.text(l10n.hcDecline), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.hcDecline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.hcDecline));
    await tester.pumpAndSettle();
    expect(find.text(l10n.hcSheetTitle(2, 3)), findsOneWidget);
  });

  testWidgets('bei 200 % auf 320 dp läuft nichts über', (tester) async {
    await pump(tester, [session('hc-1')],
        scale: 2.0, size: const Size(320, 1400));
    expect(tester.takeException(), isNull);
  });
}
