import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/domain/pulse_profile.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/weight/application/weight_sync_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';
import '../support/fake_health.dart';

/// Der Pulsverlauf wird nachgetragen — auch dort, wo schon ein Puls liegt.
///
/// Am Gerät aufgefallen (22.09.2026): Eine Cardio-Einheit vom 13.09. zeigte
/// ihre Zonen, aber keine Kurve. Der Datensatz war am 21.09. gelesen worden
/// und trug deshalb Sekunden je bpm, aber keinen Verlauf über die Zeit — den
/// gibt es erst seit dem 22.09. Der Nachtrag übersprang ihn, weil er nur
/// fragte, ob **irgendein** Puls da ist.

final _start = DateTime(2026, 9, 13, 15, 34);
final _end = DateTime(2026, 9, 13, 15, 58);

class _Repo implements HealthSessionRepository {
  _Repo(this.records);

  final List<HealthSession> records;

  @override
  Stream<List<HealthSession>> watch(String userId) => Stream.value(records);
  @override
  Future<List<HealthSession>> fetch(String userId) async => records;
  @override
  Future<void> save(String userId, HealthSession session) async {
    records
      ..removeWhere((r) => r.externalId == session.externalId)
      ..add(session);
  }

  @override
  Future<void> delete(String userId, String externalId) async {}
  @override
  Future<DateTime?> lastRead(String userId) async => null;
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

class _Sessions extends FakeSessionRepository {
  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(const []);
  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => const [];
}

/// Der Verlauf, wie ihn die Uhr heute liefert — mit Kurve.
final _full = PulseProfile(
  secondsByBpm: const {96: 1394, 120: 30},
  windowSeconds: 1440,
  curve: {for (var m = 0; m < 24; m++) m: 96 + (m == 12 ? 24 : 0)},
);

/// Derselbe Verlauf, wie er am 21.09. abgelegt wurde — ohne Kurve.
const _withoutCurve = PulseProfile(
  secondsByBpm: {96: 1394, 120: 30},
  windowSeconds: 1440,
);

HealthSession _record({PulseProfile? pulse}) => HealthSession.pending(
      MeasuredSession(
        id: 'hc-1',
        start: _start,
        end: _end,
        sourceId: 'com.garmin.android.apps.connectmobile',
        pulse: pulse,
      ),
      DateTime(2026, 9, 21, 7),
    ).copyWith(state: HealthSessionState.accepted);

Future<_Repo> _run(List<HealthSession> records) async {
  final repo = _Repo(records);
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
    ),
    sessionRepositoryProvider.overrideWithValue(_Sessions()),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    healthSessionRepositoryProvider.overrideWithValue(repo),
    healthGatewayProvider.overrideWithValue(FakeHealthGateway(
      sessionsGranted: true,
      sessions: [
        MeasuredSession(
          id: 'hc-1',
          start: _start,
          end: _end,
          sourceId: 'com.garmin.android.apps.connectmobile',
          pulse: _full,
        ),
      ],
    )),
  ]);
  addTearDown(container.dispose);

  container.listen(currentUserIdProvider, (_, __) {});
  for (var i = 0;
      i < 100 && container.read(currentUserIdProvider) == null;
      i++) {
    await Future<void>.delayed(Duration.zero);
  }

  await container.read(healthImportControllerProvider.notifier).refresh();
  return repo;
}

void main() {
  test('ein Datensatz ohne Puls bekommt ihn nachgetragen', () async {
    final repo = await _run([_record()]);
    expect(repo.records.single.pulse?.curve, isNotEmpty);
  });

  test('ein Datensatz mit Puls, aber ohne Kurve bekommt die Kurve', () async {
    // Der Fall vom Gerät. Vorher übersprang der Nachtrag ihn.
    final repo = await _run([_record(pulse: _withoutCurve)]);
    expect(repo.records.single.pulse?.curve, isNotEmpty);
  });

  test('der Zustand bleibt, was er war', () async {
    // Nachgetragen wird der Verlauf, nicht die Entscheidung.
    final repo = await _run([_record(pulse: _withoutCurve)]);
    expect(repo.records.single.state, HealthSessionState.accepted);
  });

  test('ein vollständiger Datensatz wird nicht neu geschrieben', () async {
    final repo = await _run([_record(pulse: _full)]);
    expect(repo.records.single.pulse?.curve.length, 24);
  });
}
