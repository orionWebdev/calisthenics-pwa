import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/weight/application/weight_providers.dart';
import 'package:atem/features/weight/application/weight_sync_providers.dart';
import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';
import '../support/fake_health.dart';

/// Der Ablauf eines Abgleichs — ohne Gerät, ohne Netz.

final _today = DateTime(2026, 9, 20);

DateTime _daysAgo(int days) =>
    DateTime(_today.year, _today.month, _today.day - days);

ProviderContainer _container({
  required FakeHealthGateway gateway,
  required FakeWeightRepository repository,
}) {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
    ),
    weightRepositoryProvider.overrideWithValue(repository),
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(settings: const UserSettings(bodyWeightKg: 78)),
    ),
    healthGatewayProvider.overrideWithValue(gateway),
    historyReferenceProvider.overrideWithValue(_today),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// Wartet, bis Anmeldung **und** Reihe stehen.
///
/// Nicht `read(weightSeriesProvider.future)`: Der Strom baut zuerst für
/// „niemand angemeldet" auf und wird neu gebaut, sobald die Anmeldung
/// eintrifft — die erste Zukunft läuft dann ins Leere und der Test hängt bis
/// zum Zeitlimit. Hier wird gewartet, bis beides beisammen ist.
Future<void> _settle(ProviderContainer container) async {
  container.listen(weightSeriesProvider, (_, __) {});
  for (var i = 0; i < 100; i++) {
    if (container.read(currentUserIdProvider) != null &&
        container.read(weightSeriesProvider).hasValue) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Reihe wurde nicht geladen');
}

void main() {
  test('ohne Health Connect wird nichts gelesen und nichts geschrieben',
      () async {
    final gateway =
        FakeHealthGateway(availabilityValue: HealthAvailability.notInstalled);
    final repository = FakeWeightRepository(entries: []);
    final container = _container(gateway: gateway, repository: repository);
    await _settle(container);

    final result =
        await container.read(weightSyncProvider.notifier).run();

    expect(result!.ran, isFalse);
    expect(result.availability, HealthAvailability.notInstalled);
    expect(gateway.requests, 0, reason: 'kein Dialog ohne Health Connect');
    expect(repository.entries, isEmpty);
  });

  test('ohne Freigabe fragt der Abgleich von sich aus nicht', () async {
    final gateway = FakeHealthGateway(granted: false);
    final container = _container(
      gateway: gateway,
      repository: FakeWeightRepository(entries: []),
    );
    await _settle(container);

    final result = await container.read(weightSyncProvider.notifier).run();

    expect(result!.granted, isFalse);
    expect(gateway.requests, 0,
        reason: 'fragen darf nur, wer gerade danach gefragt wurde');
  });

  test('mit askForAccess öffnet er den Dialog genau einmal', () async {
    final gateway = FakeHealthGateway(granted: false, grantOnRequest: true);
    final container = _container(
      gateway: gateway,
      repository: FakeWeightRepository(entries: []),
    );
    await _settle(container);

    final result = await container
        .read(weightSyncProvider.notifier)
        .run(askForAccess: true);

    expect(gateway.requests, 1);
    expect(result!.ran, isTrue);
  });

  test('übernimmt Messwerte und schreibt eigene Einträge zurück', () async {
    final gateway = FakeHealthGateway(granted: true, records: [
      MeasuredWeight(
        id: 'hc-1',
        measuredAt: _daysAgo(3).add(const Duration(hours: 7)),
        kg: 79.2,
        sourceId: 'com.garmin.android.apps.connectmobile',
      ),
    ]);
    final repository = FakeWeightRepository(entries: [
      WeightEntry(
          date: _daysAgo(1), kg: 78.9, source: WeightSource.manual),
    ]);
    final container = _container(gateway: gateway, repository: repository);
    await _settle(container);

    final result = await container.read(weightSyncProvider.notifier).run();

    expect(result!.imported, 1);
    expect(result.published, 1);

    // Der Messwert steht jetzt in ATEM — mit Herkunft und Kennung.
    final imported = repository.entries
        .firstWhere((e) => e.date == _daysAgo(3));
    expect(imported.source, WeightSource.healthConnect);
    expect(imported.externalId, 'hc-1');

    // Und der eigene Eintrag steht in der Quelle, unter dem eigenen Paket.
    final published =
        gateway.records.firstWhere((r) => r.sourceId == FakeHealthGateway.packageName);
    expect(published.kg, 78.9);
    expect(published.id, '2026-09-19');
  });

  test('ein zweiter Lauf ändert nichts mehr', () async {
    final gateway = FakeHealthGateway(granted: true, records: [
      MeasuredWeight(
        id: 'hc-1',
        measuredAt: _daysAgo(3).add(const Duration(hours: 7)),
        kg: 79.2,
        sourceId: 'com.withings.wiscale2',
      ),
    ]);
    final repository = FakeWeightRepository(entries: [
      WeightEntry(
          date: _daysAgo(1), kg: 78.9, source: WeightSource.manual),
    ]);
    final container = _container(gateway: gateway, repository: repository);
    await _settle(container);

    await container.read(weightSyncProvider.notifier).run();
    // Dem Strom Zeit lassen, die Schreibvorgänge nachzumelden — sonst rechnet
    // der zweite Lauf gegen den Stand vor dem ersten.
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final second = await container.read(weightSyncProvider.notifier).run();

    expect(second!.changedNothing, isTrue,
        reason: 'sonst liefe der Abgleich im Kreis');
  });

  test('ein abgelehnter Schreibvorgang kostet keinen Wert', () async {
    final gateway = FakeHealthGateway(granted: true, writeSucceeds: false);
    final repository = FakeWeightRepository(entries: [
      WeightEntry(
          date: _daysAgo(1), kg: 78.9, source: WeightSource.manual),
    ]);
    final container = _container(gateway: gateway, repository: repository);
    await _settle(container);

    final result = await container.read(weightSyncProvider.notifier).run();

    expect(result!.published, 0);
    expect(result.failedToPublish, 1);
    expect(repository.entries, hasLength(1),
        reason: 'der Eintrag bleibt in ATEM stehen');
  });
}
