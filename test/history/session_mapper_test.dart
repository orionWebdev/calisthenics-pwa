import 'dart:convert';
import 'dart:io';

import 'package:atem/features/history/data/session_mapper.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Prüfbestand stammt aus dem **echten** Produktivbestand.
///
/// `tool/session_shapes.py` destilliert aus 136 Dokumenten die 80
/// unterschiedlichen Feld-Typ-Kombinationen und ersetzt jeden Wert durch einen
/// Platzhalter desselben Typs. Die Datei enthält damit keine Trainingsdaten,
/// keine Zeitpunkte und keine Kennungen — aber jede Form, an der ein
/// Deserialisierer scheitern kann.
///
/// Erneuern nach jeder Schemaänderung in der PWA:
///
///     python3 tool/session_shapes.py ~/atem-firestore-sicherung-<datum> \
///         test/fixtures/session_shapes.json
List<Map<String, dynamic>> _shapes() {
  final raw = File('test/fixtures/session_shapes.json').readAsStringSync();
  return (jsonDecode(raw) as List)
      .map((e) => _rehydrate(e) as Map<String, dynamic>)
      .toList();
}

/// JSON kennt keinen `Timestamp`. Das Werkzeug markiert Zeitstempel als
/// `{"__ts__": "..."}`; hier werden daraus wieder echte Firestore-Typen —
/// sonst prüfte der Test an dem Typ vorbei, den das SDK tatsächlich liefert.
dynamic _rehydrate(Object? value) {
  if (value is Map<String, dynamic>) {
    final ts = value['__ts__'];
    if (ts is String) return Timestamp.fromDate(DateTime.parse(ts));
    return value.map((k, v) => MapEntry(k, _rehydrate(v)));
  }
  if (value is List) return value.map(_rehydrate).toList();
  return value;
}

void main() {
  final shapes = _shapes();

  test('der Prüfbestand deckt ab, was er abdecken soll', () {
    expect(shapes, hasLength(80));
    final kinds = shapes.map((s) => s['type']).toSet();
    expect(kinds, {'strength', 'bodyweight', 'cardio', 'recovery'});
  });

  test('jede Form aus dem Produktivbestand wird übersetzt', () {
    for (var i = 0; i < shapes.length; i++) {
      final session = SessionMapper.fromMap('doc$i', shapes[i]);
      expect(session, isNotNull, reason: 'Form $i: ${shapes[i]}');
    }
  });

  test('der Diskriminator landet in der richtigen Klasse', () {
    for (final shape in shapes) {
      final session = SessionMapper.fromMap('x', shape)!;
      switch (shape['type']) {
        case 'strength':
          expect(session, isA<StrengthSession>());
          expect((session as StrengthSession).bodyweight, isFalse);
        case 'bodyweight':
          expect(session, isA<StrengthSession>());
          expect((session as StrengthSession).bodyweight, isTrue);
        case 'cardio':
          expect(session, isA<CardioSession>());
        case 'recovery':
          expect(session, isA<RecoverySession>());
      }
    }
  });

  test('alle acht Aktivitätsarten des Bestands sind bekannt', () {
    final unbekannt = <String>{};
    for (final shape in shapes) {
      final session = SessionMapper.fromMap('x', shape);
      if (session is CardioSession && session.rawActivity != null) {
        unbekannt.add(session.rawActivity!);
      }
    }
    expect(unbekannt, isEmpty,
        reason: 'CardioActivity kennt diese Werte nicht: $unbekannt');
  });

  group('R1 — niemals as int', () {
    test('duration als integer und als double', () {
      final base = {
        'userId': 'u',
        'type': 'strength',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      };
      // 111 Dokumente tragen integer, 25 double. Beides muss dasselbe ergeben.
      expect(SessionMapper.fromMap('a', {...base, 'duration': 45})!.duration,
          const Duration(minutes: 45));
      expect(SessionMapper.fromMap('b', {...base, 'duration': 45.0})!.duration,
          const Duration(minutes: 45));
      // Und Nachkommastellen dürfen nicht verlorengehen: 3,1 Minuten sind
      // 186 Sekunden, nicht 180.
      expect(SessionMapper.fromMap('c', {...base, 'duration': 3.1})!.duration,
          const Duration(seconds: 186));
    });

    test('distanceKm als double und als integer', () {
      final doc = {
        'userId': 'u',
        'type': 'cardio',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      };
      final a = SessionMapper.fromMap('a', {...doc, 'distanceKm': 5});
      final b = SessionMapper.fromMap('b', {...doc, 'distanceKm': 5.0});
      expect((a! as CardioSession).distanceKm, 5.0);
      expect((b! as CardioSession).distanceKm, 5.0);
    });

    test('durationSec hat Vorrang vor duration', () {
      final session = SessionMapper.fromMap('a', {
        'userId': 'u',
        'type': 'cardio',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'duration': 57,
        'durationSec': 3420,
      });
      expect(session!.duration, const Duration(seconds: 3420));
    });
  });

  group('R2 — null und fehlend sind derselbe Fall', () {
    final base = {
      'userId': 'u',
      'type': 'cardio',
      'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    };

    test('notes: null, fehlend und leer ergeben dasselbe', () {
      expect(SessionMapper.fromMap('a', {...base, 'notes': null})!.notes, null);
      expect(SessionMapper.fromMap('b', base)!.notes, null);
      expect(
          SessionMapper.fromMap('c', {...base, 'notes': '   '})!.notes, null);
    });

    test('pace: null, fehlend, integer und double', () {
      CardioSession read(Object? value) => SessionMapper.fromMap(
          'x', {...base, if (value != null) 'pace': value})! as CardioSession;
      expect(read(null).pace, null);
      expect(read(6).pace, 6.0);
      expect(read(6.42).pace, 6.42);
    });
  });

  group('Randfälle aus dem Bestand', () {
    final base = {
      'userId': 'u',
      'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    };

    test('Krafteinheit ohne Übungen ist gültig, nicht leer', () {
      final session = SessionMapper.fromMap('a', {...base, 'type': 'strength'})!
          as StrengthSession;
      expect(session.exercises, isEmpty);
      expect(session.hasExerciseData, isFalse);
    });

    test('leerer Satzeintrag bleibt erhalten, damit die Satzzahl stimmt', () {
      final session = SessionMapper.fromMap('a', {
        ...base,
        'type': 'strength',
        'exercises': [
          {
            'exerciseId': 'push_up',
            'sets': [
              {'reps': 8, 'weight': null},
              <String, dynamic>{},
            ],
          },
        ],
      })! as StrengthSession;
      expect(session.exercises.single.sets, hasLength(2));
      expect(session.exercises.single.sets.last.isEmpty, isTrue);
      expect(session.hasExerciseData, isTrue);
    });

    test('unbekannter type geht nicht verloren', () {
      final session = SessionMapper.fromMap('a', {...base, 'type': 'hyrox'})!;
      expect(session, isA<UnknownSession>());
      expect((session as UnknownSession).rawType, 'hyrox');
      expect(session.kind, isNull);
    });

    test('unbekannte Aktivität bleibt im Rohwert erhalten', () {
      final session = SessionMapper.fromMap(
              'a', {...base, 'type': 'cardio', 'activityType': 'padel'})!
          as CardioSession;
      expect(session.activity, isNull);
      expect(session.rawActivity, 'padel');
    });

    test('Dokument ohne Pflichtfelder wird ausgelassen, nicht geraten', () {
      expect(SessionMapper.fromMap('a', null), isNull);
      expect(SessionMapper.fromMap('a', {'type': 'strength'}), isNull);
      expect(SessionMapper.fromMap('a', {...base}..remove('date')), isNull);
    });

    test('fehlendes createdAt fällt auf date zurück', () {
      final map = {...base, 'type': 'recovery'}..remove('createdAt');
      final session = SessionMapper.fromMap('a', map)!;
      expect(session.createdAt, session.date);
    });
  });
}
