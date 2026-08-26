import 'dart:convert';
import 'dart:io';

import 'package:atem/features/history/data/firestore_session_repository.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dieselben 80 Formen wie im Mapper-Test — hier aber durch die vollständige
/// Firestore-Schicht, inklusive Abfrage, Sortierung und Bericht.
List<Map<String, dynamic>> _shapes() {
  final raw = File('test/fixtures/session_shapes.json').readAsStringSync();
  return (jsonDecode(raw) as List)
      .map((e) => _rehydrate(e) as Map<String, dynamic>)
      .toList();
}

dynamic _rehydrate(Object? value) {
  if (value is Map<String, dynamic>) {
    final ts = value['__ts__'];
    if (ts is String) return Timestamp.fromDate(DateTime.parse(ts));
    return value.map((k, v) => MapEntry(k, _rehydrate(v)));
  }
  if (value is List) return value.map(_rehydrate).toList();
  return value;
}

Map<String, dynamic> _session({
  required String userId,
  required String type,
  required DateTime date,
  DateTime? createdAt,
}) =>
    {
      'userId': userId,
      'type': type,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt ?? date),
    };

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreSessionRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreSessionRepository(db);
  });

  Future<void> add(Map<String, dynamic> data) =>
      db.collection('sessions').add(data);

  test('liest nur die Einheiten des angefragten Nutzers', () async {
    await add(
        _session(userId: 'a', type: 'strength', date: DateTime(2026, 3, 1)));
    await add(
        _session(userId: 'a', type: 'cardio', date: DateTime(2026, 3, 2)));
    await add(
        _session(userId: 'b', type: 'strength', date: DateTime(2026, 3, 3)));

    final sessions = await repo.fetchSessions('a');
    expect(sessions, hasLength(2));
    expect(sessions.every((s) => s.userId == 'a'), isTrue);
  });

  test('sortiert neueste zuerst', () async {
    await add(
        _session(userId: 'a', type: 'cardio', date: DateTime(2026, 1, 5)));
    await add(
        _session(userId: 'a', type: 'cardio', date: DateTime(2026, 3, 9)));
    await add(
        _session(userId: 'a', type: 'cardio', date: DateTime(2026, 2, 7)));

    final dates = (await repo.fetchSessions('a')).map((s) => s.date).toList();
    expect(dates,
        [DateTime(2026, 3, 9), DateTime(2026, 2, 7), DateTime(2026, 1, 5)]);
  });

  test('bei gleichem Datum entscheidet der Erfassungszeitpunkt', () async {
    final day = DateTime(2026, 3, 1);
    await add(_session(
        userId: 'a',
        type: 'cardio',
        date: day,
        createdAt: DateTime(2026, 3, 1, 8)));
    await add(_session(
        userId: 'a',
        type: 'strength',
        date: day,
        createdAt: DateTime(2026, 3, 1, 19)));

    final sessions = await repo.fetchSessions('a');
    expect(sessions.first.createdAt.hour, 19);
    expect(sessions.last.createdAt.hour, 8);
  });

  test('jede Form aus dem Produktivbestand überlebt den vollen Weg', () async {
    for (final shape in _shapes()) {
      await add({...shape, 'userId': 'a'});
    }

    final sessions = await repo.fetchSessions('a');
    expect(sessions, hasLength(80));
    expect(repo.lastReport!.skipped, 0);
    expect(sessions.whereType<StrengthSession>(), isNotEmpty);
    expect(sessions.whereType<CardioSession>(), isNotEmpty);
    expect(sessions.whereType<RecoverySession>(), isNotEmpty);
  });

  test('unbrauchbare Dokumente werden gezählt, nicht verschwiegen', () async {
    await add(
        _session(userId: 'a', type: 'strength', date: DateTime(2026, 3, 1)));
    // Kein `date` — der Mapper lässt das Dokument aus.
    await add({'userId': 'a', 'type': 'strength'});

    final sessions = await repo.fetchSessions('a');
    expect(sessions, hasLength(1));
    expect(repo.lastReport!.skipped, 1);
    expect(repo.lastReport!.hasSkipped, isTrue);
  });

  test('kein Bestand ist kein Fehler', () async {
    expect(await repo.fetchSessions('niemand'), isEmpty);
    expect(repo.lastReport!.skipped, 0);
  });

  test('der Strom meldet jede Änderung', () async {
    final seen = <int>[];
    final sub = repo.watchSessions('a').listen((s) => seen.add(s.length));

    await add(
        _session(userId: 'a', type: 'cardio', date: DateTime(2026, 3, 1)));
    await Future<void>.delayed(Duration.zero);
    await add(
        _session(userId: 'a', type: 'strength', date: DateTime(2026, 3, 2)));
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    expect(seen.last, 2);
  });
}
