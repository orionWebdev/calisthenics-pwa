import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/health_import/presentation/widgets/health_permissions.dart';
import 'package:atem/features/weight/application/weight_providers.dart';
import 'package:atem/features/weight/application/weight_sync_providers.dart';
import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:atem/features/weight/domain/weight_series.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_health.dart';

class _Repo implements HealthSessionRepository {
  _Repo(this.sessions);

  final List<HealthSession> sessions;

  @override
  Stream<List<HealthSession>> watch(String userId) => Stream.value(sessions);
  @override
  Future<List<HealthSession>> fetch(String userId) async => sessions;
  @override
  Future<void> save(String userId, HealthSession session) async {}
  @override
  Future<void> delete(String userId, String externalId) async {}
  @override
  Future<DateTime?> lastRead(String userId) async => null;
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

HealthSession _accepted(String id) => HealthSession.pending(
      MeasuredSession(
        id: id,
        start: DateTime(2026, 9, 20, 9),
        end: DateTime(2026, 9, 20, 9, 42),
        sourceId: 'garmin',
      ),
      DateTime(2026, 9, 20, 10),
    ).copyWith(state: HealthSessionState.accepted, sessionId: 's$id');

/// Die zwei Berechtigungszeilen aus Board 15, Abschnitt D.
void main() {
  late FakeHealthGateway gateway;

  Future<AppL10n> pump(
    WidgetTester tester, {
    HealthAvailability availability = HealthAvailability.available,
    bool weight = false,
    bool sessions = false,
    List<HealthSession> known = const [],
    WeightSeries series = WeightSeries.empty,
  }) async {
    gateway = FakeHealthGateway(
      availabilityValue: availability,
      granted: weight,
      sessionsGranted: sessions,
    );
    tester.view.physicalSize = const Size(361, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...fixtureOverrides,
        healthGatewayProvider.overrideWithValue(gateway),
        healthSessionRepositoryProvider.overrideWithValue(_Repo(known)),
        currentUserIdProvider.overrideWithValue('u'),
        // Die Fixtures tragen gemessene Gewichtswerte; die machten aus
        // „nie freigegeben" ein „entzogen". Jeder Fall stellt seine eigene
        // Reihe.
        weightSeriesProvider.overrideWith((ref) => Stream.value(series)),
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
        home: const Scaffold(
          backgroundColor: AtemColors.base,
          body: SingleChildScrollView(
            child: HealthPermissionsSection(),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return AppL10n.of(tester.element(find.byType(HealthPermissionsSection)));
  }

  testWidgets('D1 — ohne Health Connect keine bedienbare Zeile',
      (tester) async {
    final l10n =
        await pump(tester, availability: HealthAvailability.notInstalled);

    expect(find.text(l10n.hcStateMissing.toUpperCase()), findsNWidgets(2));
    expect(find.text(l10n.hcPermGrant), findsNothing);
    expect(find.text(l10n.hcPermMissingNote), findsOneWidget);
    // Der Weg zum Installieren steht unter der Notiz, ohne Ausrufezeichen.
    expect(find.text(l10n.hcPermInstall), findsOneWidget);
  });

  testWidgets('D2 — zwei Wege, weil Google zwei Fragen stellt',
      (tester) async {
    final l10n = await pump(tester);

    expect(find.text(l10n.hcStateDenied.toUpperCase()), findsNWidgets(2));
    // Kein Sammelknopf „Alles erlauben".
    expect(find.text(l10n.hcPermGrant), findsNWidgets(2));
    expect(find.text(l10n.hcPermNoneNote), findsOneWidget);
  });

  testWidgets('D3 — Gewicht ja, Einheiten nein', (tester) async {
    final l10n = await pump(tester, weight: true);

    expect(find.text(l10n.hcStateGranted.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.hcStateDenied.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.hcPermGrant), findsOneWidget);
    expect(find.text(l10n.hcPermPartialNote), findsOneWidget);
  });

  testWidgets('D5 — entzogen: zuerst, was bleibt', (tester) async {
    // Entzogen heisst: Es liegt schon etwas aus der Quelle da. Beide Zeilen
    // brauchen dafür ihren eigenen Bestand — Google fragt je Datentyp.
    final l10n = await pump(
      tester,
      known: [_accepted('a'), _accepted('b')],
      series: WeightSeries.of([
        WeightEntry(
          date: DateTime(2026, 9, 19),
          kg: 78,
          source: WeightSource.healthConnect,
          externalId: 'hc-w',
        ),
      ]),
    );

    expect(find.text(l10n.hcStateRevoked.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.hcStateRevokedKept(2).toUpperCase()), findsOneWidget);
    // Kein Countdown, kein Ausrufezeichen — erst das Bleibende.
    expect(find.text(l10n.hcPermRevokedNote(2)), findsOneWidget);
  });

  testWidgets('Freigeben fragt genau einmal, je Datentyp', (tester) async {
    final l10n = await pump(tester);

    await tester.tap(find.text(l10n.hcPermGrant).first);
    await tester.pumpAndSettle();
    expect(gateway.requests, 1);
    expect(gateway.sessionRequests, 0);
  });
}
