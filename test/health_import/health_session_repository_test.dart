import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/domain/pulse_profile.dart';
import 'package:atem/features/health_import/data/firestore_health_session_repository.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// `userProfiles/{uid}/healthSessions` — die gelesenen Uhr-Einheiten
/// (Board 15, Entscheidung 1).
void main() {
  const uid = 'u1';
  final seen = DateTime(2026, 9, 20, 7, 12);

  late FakeFirebaseFirestore db;
  late FirestoreHealthSessionRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreHealthSessionRepository(db);
  });

  MeasuredSession measured({
    String id = 'hc-1',
    DateTime? start,
    int? avg = 148,
  }) =>
      MeasuredSession(
        id: id,
        start: start ?? DateTime(2026, 9, 20, 9, 14),
        end: (start ?? DateTime(2026, 9, 20, 9, 14))
            .add(const Duration(minutes: 42)),
        sourceId: 'com.garmin.android.apps.connectmobile',
        activity: 'RUNNING',
        deviceName: 'Garmin',
        averageHeartRate: avg,
        maxHeartRate: 171,
        calories: 412,
      );

  test('ein Datensatz aus der Quelle, ein Dokument — auch beim zweiten Lesen',
      () async {
    await repo.save(uid, HealthSession.pending(measured(), seen));
    await repo.save(uid, HealthSession.pending(measured(), seen));

    final all = await repo.fetch(uid);
    expect(all, hasLength(1));
    expect(all.single.externalId, 'hc-1');
    expect(all.single.state, HealthSessionState.pending);
  });

  test('alles Gemessene überlebt den Weg durch Firestore', () async {
    await repo.save(uid, HealthSession.pending(measured(), seen));

    final stored = (await repo.fetch(uid)).single;
    expect(stored.averageHeartRate, 148);
    expect(stored.maxHeartRate, 171);
    expect(stored.calories, 412);
    expect(stored.activity, 'RUNNING');
    expect(stored.deviceName, 'Garmin');
    expect(stored.duration, const Duration(minutes: 42));
    expect(stored.seenAt, seen);
  });

  test('die Pulskurve überlebt den Weg durch Firestore', () async {
    const profile = PulseProfile(
      secondsByBpm: {118: 42, 140: 38},
      windowSeconds: 80,
      curve: {0: 118, 2: 140},
    );
    await repo.save(
      uid,
      HealthSession.pending(measured(), seen).copyWith(pulse: profile),
    );

    final stored = (await repo.fetch(uid)).single;
    expect(stored.pulse!.curve, {0: 118, 2: 140});
  });

  test('eine Einheit ohne Kurve schreibt kein pulseCurve-Feld', () async {
    const profile = PulseProfile(secondsByBpm: {118: 42}, windowSeconds: 42);
    await repo.save(
      uid,
      HealthSession.pending(measured(), seen).copyWith(pulse: profile),
    );

    final doc = await db
        .collection('userProfiles')
        .doc(uid)
        .collection('healthSessions')
        .doc(HealthSession.idFor('hc-1'))
        .get();
    expect(doc.data(), isNot(contains('pulseCurve')));
  });

  test('abgelehnt ist ein Zustand, kein Verschwinden', () async {
    final pending = HealthSession.pending(measured(), seen);
    await repo.save(uid, pending);
    await repo.save(
      uid,
      pending.copyWith(
        state: HealthSessionState.rejected,
        decidedAt: DateTime(2026, 9, 20, 8),
      ),
    );

    final stored = (await repo.fetch(uid)).single;
    expect(stored.state, HealthSessionState.rejected);
    expect(stored.decidedAt, DateTime(2026, 9, 20, 8));
    // Er liegt weiter da — sonst käme derselbe Datensatz morgen wieder.
    expect(await repo.fetch(uid), hasLength(1));
  });

  test('eine gelöste Verknüpfung entfernt den Verweis wirklich', () async {
    final pending = HealthSession.pending(measured(), seen);
    await repo.save(uid, pending);
    await repo.save(uid,
        pending.copyWith(state: HealthSessionState.accepted, sessionId: 's1'));
    expect((await repo.fetch(uid)).single.sessionId, 's1');

    // `merge` liesse ein `null` sonst als alten Verweis stehen.
    await repo.save(
      uid,
      pending.copyWith(state: HealthSessionState.pending, clearSession: true),
    );
    final loosened = (await repo.fetch(uid)).single;
    expect(loosened.sessionId, isNull);
    expect(loosened.isPending, isTrue);
  });

  test('eine Kennung mit Schrägstrich bleibt ein gültiges Dokument', () async {
    // Firestore verbietet `/` in Dokumentkennungen; der rohe Wert gilt
    // trotzdem beim Abgleich mit Health Connect.
    await repo.save(uid, HealthSession.pending(measured(id: 'a/b'), seen));

    final stored = (await repo.fetch(uid)).single;
    expect(stored.externalId, 'a/b');
    final snapshot = await db
        .collection('userProfiles')
        .doc(uid)
        .collection('healthSessions')
        .get();
    expect(snapshot.docs.single.id, 'a_b');
  });

  test('ein Dokument ohne Zeitraum ist kein Datensatz', () async {
    await db
        .collection('userProfiles')
        .doc(uid)
        .collection('healthSessions')
        .doc('kaputt')
        .set({'state': 'pending'});

    expect(await repo.fetch(uid), isEmpty);
  });

  group('Lesemarke', () {
    test('ohne Marke wurde nie gelesen', () async {
      expect(await repo.lastRead(uid), isNull);
    });

    test('sie steht im Profil und überschreibt sich', () async {
      await repo.markRead(uid, DateTime(2026, 9, 19, 8, 3));
      expect(await repo.lastRead(uid), DateTime(2026, 9, 19, 8, 3));

      await repo.markRead(uid, DateTime(2026, 9, 20, 7, 12));
      expect(await repo.lastRead(uid), DateTime(2026, 9, 20, 7, 12));
    });

    test('sie legt das Profil nicht lahm', () async {
      await db
          .collection('userProfiles')
          .doc(uid)
          .set({'displayName': 'Chris'});
      await repo.markRead(uid, DateTime(2026, 9, 20, 7, 12));

      final profile = await db.collection('userProfiles').doc(uid).get();
      expect(profile.data()?['displayName'], 'Chris');
      expect(profile.data()?['healthSessionsReadAt'], isA<Timestamp>());
    });
  });

  test('watch meldet jede Änderung', () async {
    final seenCounts = <int>[];
    final sub = repo.watch(uid).listen((list) => seenCounts.add(list.length));

    await repo.save(uid, HealthSession.pending(measured(), seen));
    await repo.save(
      uid,
      HealthSession.pending(
          measured(id: 'hc-2', start: DateTime(2026, 9, 19, 18)), seen),
    );
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seenCounts.last, 2);
  });
}
