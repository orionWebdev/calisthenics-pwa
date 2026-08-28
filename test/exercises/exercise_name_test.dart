import 'package:atem/features/exercises/data/exercise_mapper.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Fehler, den dieser Test festhält: Der Mapper las nur `name`. Die
/// Vorgänger-App liest bei deutscher Sprache `name_de` und fällt sonst zurück
/// (`js/views/exercises/model.js`, `getExerciseName`) — die App zeigte
/// deshalb durchweg englische Namen, obwohl deutsche im Bestand stehen.
void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  Future<Exercise?> read(Map<String, dynamic> data) async {
    await db.collection('exercises_curated').doc('x').set(data);
    final doc = await db.collection('exercises_curated').doc('x').get();
    return ExerciseMapper.fromDoc(doc, source: ExerciseSource.curated);
  }

  test('liest das flache name_de', () async {
    final exercise = await read({'name': 'Pull-up', 'name_de': 'Klimmzug'});
    expect(exercise!.name, 'Pull-up');
    expect(exercise.nameDe, 'Klimmzug');
  });

  test('liest auch das verschachtelte i18n.de.name', () async {
    final exercise = await read({
      'name': 'Pull-up',
      'i18n': {
        'de': {'name': 'Klimmzug'},
      },
    });
    expect(exercise!.nameDe, 'Klimmzug');
  });

  test('das flache Feld gewinnt, wenn beide dastehen', () async {
    final exercise = await read({
      'name': 'Pull-up',
      'name_de': 'Klimmzug',
      'i18n': {
        'de': {'name': 'Klimmzieher'},
      },
    });
    expect(exercise!.nameDe, 'Klimmzug');
  });

  test('ohne deutsche Fassung bleibt sie leer, nicht geraten', () async {
    // 24 der kuratierten Übungen haben keinen deutschen Namen. Bei „dips"
    // ist das in Ordnung — die Oberfläche zeigt dann den Grundnamen.
    final exercise = await read({'name': 'Dips'});
    expect(exercise!.nameDe, isNull);
    expect(exercise.name, 'Dips');
  });

  group('Der deutsche Overlay-Block', () {
    test('ersetzt Anleitung, Cues und Fehler', () async {
      final exercise = await read({
        'name': 'Pull-up',
        'instructionsSteps': ['Hang', 'Pull'],
        'cues': ['Chest up'],
        'commonMistakes': ['Swinging'],
        'i18n': {
          'de': {
            'instructionsSteps': ['Hängen', 'Ziehen'],
            'cues': ['Brust raus'],
            'commonMistakes': ['Schwingen'],
          },
        },
      });
      expect(exercise!.instructions, ['Hängen', 'Ziehen']);
      expect(exercise.cues, ['Brust raus']);
      expect(exercise.commonMistakes, ['Schwingen']);
    });

    test('ein leerer Overlay verdrängt die Grundfassung nicht', () async {
      // „übersetzt, aber leer" wäre schlechter als „nicht übersetzt".
      final exercise = await read({
        'name': 'Pull-up',
        'instructionsSteps': ['Hang', 'Pull'],
        'i18n': {
          'de': {'instructionsSteps': <String>[]},
        },
      });
      expect(exercise!.instructions, ['Hang', 'Pull']);
    });

    test('ein fehlender Overlay ist kein Fehler', () async {
      final exercise = await read({
        'name': 'Pull-up',
        'instructionsSteps': ['Hang'],
        'i18n': {'fr': <String, Object?>{}},
      });
      expect(exercise!.instructions, ['Hang']);
      expect(exercise.nameDe, isNull);
    });

    test('ein kaputtes i18n-Feld bringt nichts zum Absturz', () async {
      final exercise = await read({'name': 'Pull-up', 'i18n': 'kaputt'});
      expect(exercise!.name, 'Pull-up');
      expect(exercise.nameDe, isNull);
    });
  });

  test('Timestamps und andere Typen stören nicht', () async {
    final exercise = await read({
      'name': 'Pull-up',
      'name_de': 'Klimmzug',
      'createdAt': Timestamp.now(),
    });
    expect(exercise!.nameDe, 'Klimmzug');
  });
}
