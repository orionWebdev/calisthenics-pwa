@Tags(['render'])
library;

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
import '../support/render.dart';

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
  Future<DateTime?> lastRead(String userId) async =>
      DateTime(2026, 9, 20, 7, 12);
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

final _measuredWeight = WeightSeries.of([
  WeightEntry(
    date: DateTime(2026, 9, 19),
    kg: 78,
    source: WeightSource.healthConnect,
    externalId: 'hc-w',
  ),
]);

void main() {
  final cases = <String, ({
    HealthAvailability availability,
    bool weight,
    bool sessions,
    List<HealthSession> known,
    WeightSeries series,
  })>{
    'hc_d1_fehlt': (
      availability: HealthAvailability.notInstalled,
      weight: false,
      sessions: false,
      known: const [],
      series: WeightSeries.empty,
    ),
    'hc_d2_nichts_frei': (
      availability: HealthAvailability.available,
      weight: false,
      sessions: false,
      known: const [],
      series: WeightSeries.empty,
    ),
    'hc_d3_teilweise': (
      availability: HealthAvailability.available,
      weight: true,
      sessions: false,
      known: const [],
      series: _measuredWeight,
    ),
    'hc_d4_nichts_gefunden': (
      availability: HealthAvailability.available,
      weight: true,
      sessions: true,
      known: const [],
      series: _measuredWeight,
    ),
    'hc_d5_entzogen': (
      availability: HealthAvailability.available,
      weight: false,
      sessions: false,
      known: [_accepted('a'), _accepted('b')],
      series: _measuredWeight,
    ),
  };

  for (final entry in cases.entries) {
    testWidgets('rendert ${entry.key}', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      tester.view.physicalSize = const Size(361, 560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final c = entry.value;
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...fixtureOverrides,
          healthGatewayProvider.overrideWithValue(FakeHealthGateway(
            availabilityValue: c.availability,
            granted: c.weight,
            sessionsGranted: c.sessions,
          )),
          healthSessionRepositoryProvider.overrideWithValue(_Repo(c.known)),
          currentUserIdProvider.overrideWithValue('u'),
          weightSeriesProvider.overrideWith((ref) => Stream.value(c.series)),
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AtemTheme.dark,
            locale: const Locale('de'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.15),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const Scaffold(
              backgroundColor: AtemColors.base,
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(AtemSpacing.screenPadding),
                  child: SingleChildScrollView(
                    child: HealthPermissionsSection(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await writePng(tester, key, entry.key);
    });
  }
}
