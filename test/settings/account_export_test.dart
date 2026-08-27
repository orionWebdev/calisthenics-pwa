import 'dart:convert';

import 'package:atem/features/settings/data/firestore_account_repository.dart';
import 'package:atem/features/settings/domain/account_export_format.dart';
import 'package:atem/features/settings/domain/settings_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

AccountExport _export(Map<String, List<Map<String, Object?>>> c) =>
    AccountExport(collections: c);

void main() {
  group('CSV', () {
    test('eine Zeile je Satz', () {
      final csv = AccountExportFormat.sessionsToCsv(_export({
        'sessions': [
          {
            'id': 's1',
            'date': '2026-08-20T00:00:00.000Z',
            'type': 'strength',
            'duration': 45,
            'exercises': [
              {
                'exerciseId': 'squat',
                'sets': [
                  {'reps': 5, 'weight': 100},
                  {'reps': 5, 'weight': 105, 'type': 'dropset'},
                ],
              },
            ],
          },
        ],
      }));

      final lines = csv.split('\r\n');
      expect(lines, hasLength(3), reason: 'Kopfzeile plus zwei Sätze');
      expect(lines.first, AccountExportFormat.csvColumns.join(','));
      expect(lines[1], contains('squat,1,5,100'));
      expect(lines[2], contains('squat,2,5,105'));
      expect(lines[2], endsWith('dropset'));
    });

    test('eine Einheit ohne Sätze bekommt trotzdem ihre Zeile', () {
      // Im Bestand 16 von 63 Krafteinheiten, dazu jede Cardio-Einheit. Sie
      // wegzulassen hiesse, eine Datenausgabe zu machen, die Daten weglässt.
      final csv = AccountExportFormat.sessionsToCsv(_export({
        'sessions': [
          {'id': 's1', 'type': 'cardio', 'duration': 30},
        ],
      }));
      final lines = csv.split('\r\n');
      expect(lines, hasLength(2));
      expect(lines[1], startsWith('s1,,cardio,30'));
    });

    test('eine Übung ohne Sätze verschwindet nicht', () {
      final csv = AccountExportFormat.sessionsToCsv(_export({
        'sessions': [
          {
            'id': 's1',
            'exercises': [
              {'exerciseId': 'plank', 'sets': <Object?>[]},
            ],
          },
        ],
      }));
      expect(csv.split('\r\n')[1], contains('plank'));
    });

    test('Kommas und Anführungszeichen in einer Notiz zerlegen nichts', () {
      final csv = AccountExportFormat.sessionsToCsv(_export({
        'sessions': [
          {'id': 's1', 'notes': 'schwer, aber gut — "PR"'},
        ],
      }));
      final line = csv.split('\r\n')[1];
      expect(line, contains('"schwer, aber gut — ""PR"""'));
      // Genau so viele Spalten wie der Kopf.
      expect(_columns(line), AccountExportFormat.csvColumns.length);
    });

    test('ein Zeilenumbruch in der Notiz bleibt in seiner Zelle', () {
      final csv = AccountExportFormat.sessionsToCsv(_export({
        'sessions': [
          {'id': 's1', 'notes': 'Zeile eins\nZeile zwei'},
        ],
      }));
      expect(csv, contains('"Zeile eins\nZeile zwei"'));
    });

    test('ohne Einheiten bleibt die Kopfzeile', () {
      final csv = AccountExportFormat.sessionsToCsv(_export(const {}));
      expect(csv, AccountExportFormat.csvColumns.join(','));
    });
  });

  group('JSON', () {
    test('gibt jede Sammlung vollständig aus', () {
      final json = AccountExportFormat.toJson(_export({
        'sessions': [
          {'id': 's1', 'unbekanntesFeld': 42},
        ],
        'plans': [
          {'id': 'p1', 'name': 'A'},
        ],
      }));

      final parsed = jsonDecode(json) as Map<String, dynamic>;
      expect(parsed.keys, containsAll(['sessions', 'plans']));
      expect((parsed['sessions'] as List).first['unbekanntesFeld'], 42,
          reason: 'ausgegeben wird, was in der Datenbank steht — nicht das, '
              'was diese App davon versteht');
    });
  });

  group('Sammeln aus Firestore', () {
    late FakeFirebaseFirestore db;
    late FirestoreAccountRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirestoreAccountRepository(db, MockFirebaseAuth());
    });

    test('Zeitstempel werden zu ISO-8601-Text', () async {
      await db.collection('sessions').add({
        'userId': 'u1',
        'date': Timestamp.fromDate(DateTime.utc(2026, 8, 20, 18, 30)),
      });

      final export = await repo.export('u1');
      final session = export.collections['sessions']!.first;
      expect(session['date'], '2026-08-20T18:30:00.000Z');
      expect(session['date'], isA<String>(),
          reason: 'ein Firebase-Typ darf die Datenschicht nicht verlassen');
    });

    test('nimmt nur eigene Dokumente', () async {
      await db.collection('sessions').add({'userId': 'u1'});
      await db.collection('sessions').add({'userId': 'fremd'});

      final export = await repo.export('u1');
      expect(export.collections['sessions'], hasLength(1));
    });

    test('das Profil kommt über die Dokument-Kennung', () async {
      await db.collection('userProfiles').doc('u1').set({'bodyWeight': 78});
      final export = await repo.export('u1');
      expect(export.collections['userProfiles']!.first['bodyWeight'], 78);
    });

    test('leere Sammlungen erscheinen gar nicht', () async {
      final export = await repo.export('u1');
      expect(export.collections, isEmpty);
      expect(export.documentCount, 0);
    });

    test('kuratierte Übungen gehören nicht zum Konto', () {
      expect(FirestoreAccountRepository.ownedCollections,
          isNot(contains('exercises_curated')));
    });
  });

  group('Löschen', () {
    late FakeFirebaseFirestore db;
    late FirestoreAccountRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirestoreAccountRepository(db, MockFirebaseAuth());
    });

    test('entfernt alle eigenen Dokumente', () async {
      await db.collection('sessions').add({'userId': 'u1'});
      await db.collection('plans').add({'userId': 'u1'});
      await db.collection('exercises').add({'userId': 'u1'});
      await db.collection('userProfiles').doc('u1').set({'bodyWeight': 78});

      await repo.deleteData('u1');

      expect((await db.collection('sessions').get()).docs, isEmpty);
      expect((await db.collection('plans').get()).docs, isEmpty);
      expect((await db.collection('exercises').get()).docs, isEmpty);
      expect((await db.collection('userProfiles').doc('u1').get()).exists,
          isFalse);
    });

    test('lässt fremde Dokumente stehen', () async {
      await db.collection('sessions').add({'userId': 'fremd'});
      await repo.deleteData('u1');
      expect((await db.collection('sessions').get()).docs, hasLength(1));
    });

    test('rührt die Zugangsliste nicht an', () async {
      // Sie gehört der geschlossenen Beta, nicht dem Konto — und die Regeln
      // liessen niemanden sie anfassen.
      await db.collection('allowedUsers').doc('u1').set({'enabled': true});
      await repo.deleteData('u1');
      expect((await db.collection('allowedUsers').doc('u1').get()).exists,
          isTrue);
    });
  });
}

int _columns(String line) {
  var count = 1;
  var inQuotes = false;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == '"') inQuotes = !inQuotes;
    if (ch == ',' && !inQuotes) count++;
  }
  return count;
}
