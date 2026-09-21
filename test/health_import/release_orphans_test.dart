import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/weight/application/weight_sync_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';
import '../support/fake_health.dart';

/// Eine Uhr-Einheit, deren App-Einheit es nicht mehr gibt, muss zurück in den
/// Eingang.
///
/// Ohne das bleibt sie „übernommen", steht in keinem Eingang und ist durch
/// nichts mehr erreichbar — genau der Zustand, in dem das Gerät am
/// 21.09.2026 stand.

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
  _Sessions(this.sessions);

  final List<TrainingSession> sessions;

  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(sessions);
  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => sessions;
}

HealthSession _accepted(String id, String sessionId) => HealthSession.pending(
      MeasuredSession(
        id: id,
        start: DateTime(2026, 9, 18, 18, 4),
        end: DateTime(2026, 9, 18, 18, 56),
        sourceId: 'com.garmin.android.apps.connectmobile',
      ),
      DateTime(2026, 9, 20, 7),
    ).copyWith(state: HealthSessionState.accepted, sessionId: sessionId);

TrainingSession _session(String id) => StrengthSession(
      id: id,
      userId: 'u',
      date: DateTime(2026, 9, 18),
      createdAt: DateTime(2026, 9, 18),
      startedAt: DateTime(2026, 9, 18, 18, 2),
      duration: const Duration(minutes: 52),
      bodyweight: false,
    );

Future<_Repo> _run({
  required List<HealthSession> records,
  required List<TrainingSession> sessions,
}) async {
  final repo = _Repo(records);
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
    ),
    sessionRepositoryProvider.overrideWithValue(_Sessions(sessions)),
    healthSessionRepositoryProvider.overrideWithValue(repo),
    healthGatewayProvider.overrideWithValue(
      FakeHealthGateway(sessionsGranted: true, sessions: const []),
    ),
  ]);
  addTearDown(container.dispose);

  // Auf die Anmeldung warten — ohne sie tut der Abgleich nichts.
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
  test('eine übernommene Einheit ohne App-Einheit kommt zurück in den Eingang',
      () async {
    final repo = await _run(
      records: [_accepted('hc-1', 'weg')],
      sessions: [_session('noch-da')],
    );

    expect(repo.records.single.state, HealthSessionState.pending);
    expect(repo.records.single.sessionId, isNull,
        reason: 'ein Verweis auf nichts ist schlimmer als kein Verweis');
  });

  test('eine übernommene Einheit mit App-Einheit bleibt, wie sie ist',
      () async {
    final repo = await _run(
      records: [_accepted('hc-1', 'noch-da')],
      sessions: [_session('noch-da')],
    );

    expect(repo.records.single.state, HealthSessionState.accepted);
    expect(repo.records.single.sessionId, 'noch-da');
  });

  test('ein leerer Bestand gibt nichts frei', () async {
    // Offline mit leerem Zwischenspeicher sieht aus wie „alles gelöscht".
    // Dann lieber nichts tun.
    final repo = await _run(
      records: [_accepted('hc-1', 'weg')],
      sessions: const [],
    );

    expect(repo.records.single.state, HealthSessionState.accepted);
  });
}
