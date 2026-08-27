import 'package:atem/features/exercises/data/firestore_exercise_repository.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreExerciseRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreExerciseRepository(db);
  });

  Future<void> curated(String id, Map<String, dynamic> data) =>
      db.collection('exercises_curated').doc(id).set(data);

  Future<void> own(String id, Map<String, dynamic> data) =>
      db.collection('exercises').doc(id).set({'userId': 'u1', ...data});

  test('beide Sammlungen werden zu einer Liste', () async {
    await curated('push_up', {'name': 'Liegestütz'});
    await own('x1', {'name': 'Eigene Übung'});
    await db.collection('exercises').add({'userId': 'jemand', 'name': 'Fremd'});

    final list = await repo.fetchExercises('u1');

    expect(list.map((e) => e.name), ['Eigene Übung', 'Liegestütz']);
    expect(list.firstWhere((e) => e.id == 'push_up').isOwn, isFalse);
    expect(list.firstWhere((e) => e.id == 'x1').isOwn, isTrue);
  });

  test('sortiert ohne Rücksicht auf Groß- und Kleinschreibung', () async {
    await curated('a', {'name': 'zercher squat'});
    await curated('b', {'name': 'Archer Push-up'});
    await own('c', {'name': 'muscle up'});

    final names = (await repo.fetchExercises('u1')).map((e) => e.name);
    expect(names, ['Archer Push-up', 'muscle up', 'zercher squat']);
  });

  group('Schwierigkeit — zwei Schreibweisen im selben Feld', () {
    test('Zahlen wie in den kuratierten Übungen', () async {
      await curated('a', {'name': 'A', 'difficulty': 3});
      expect((await repo.fetchExercises('u1')).single.difficulty, 3);
    });

    test('Wörter wie in mehr als der Hälfte der eigenen', () async {
      for (final entry in {
        'beginner': 1,
        'intermediate': 2,
        'advanced': 3,
        'elite': 4,
      }.entries) {
        final fresh = FakeFirebaseFirestore();
        await fresh
            .collection('exercises')
            .doc('a')
            .set({'userId': 'u1', 'name': 'A', 'difficulty': entry.key});
        final list =
            await FirestoreExerciseRepository(fresh).fetchExercises('u1');
        expect(list.single.difficulty, entry.value, reason: entry.key);
      }
    });

    test('Unsinn ergibt null statt einer erfundenen Stufe', () async {
      await curated('a', {'name': 'A', 'difficulty': 'sehr schwer'});
      await curated('b', {'name': 'B', 'difficulty': 99});
      final list = await repo.fetchExercises('u1');
      expect(list.every((e) => e.difficulty == null), isTrue);
    });
  });

  group('Muskelgruppen', () {
    test(
        'die beiden Sammlungen benennen unterschiedlich, treffen sich aber '
        'in der Region', () async {
      // Kuratiert nennt einzelne Muskeln …
      await curated('a', {
        'name': 'Curl',
        'primaryMuscles': ['biceps'],
      });
      // … eigene nennen zum Teil schon Regionen.
      await own('b', {
        'name': 'Dip',
        'muscleGroups': ['arms'],
      });

      final list = await repo.fetchExercises('u1');
      expect(list.map((e) => e.region), everyElement(MuscleRegion.arms));
    });

    test('primär vor sekundär, ohne Wiederholung', () async {
      await curated('a', {
        'name': 'A',
        'primaryMuscles': ['chest'],
        'secondaryMuscles': ['triceps', 'chest'],
        'muscleGroups': ['chest', 'shoulders'],
      });

      expect((await repo.fetchExercises('u1')).single.displayMuscles, [
        MuscleGroup.chest,
        MuscleGroup.triceps,
        MuscleGroup.shoulders,
      ]);
    });

    test('unbekannte Bezeichnung kostet nur den Chip, nicht die Übung',
        () async {
      await curated('a', {
        'name': 'A',
        'muscleGroups': ['back', 'nackenmuskulatur'],
      });

      final e = (await repo.fetchExercises('u1')).single;
      expect(e.displayMuscles, [MuscleGroup.back]);
    });
  });

  group('spärlich ist der Normalfall', () {
    test('eine Übung mit nur einem Namen ist gültig', () async {
      await own('a', {'name': 'Nur ein Name'});

      final e = (await repo.fetchExercises('u1')).single;
      expect(e.name, 'Nur ein Name');
      expect(e.hasGuidance, isFalse);
      expect(e.instructions, isEmpty);
      expect(e.difficulty, isNull);
    });

    test('ohne Namen wird sie ausgelassen, nicht geraten', () async {
      await curated('a', {
        'muscleGroups': ['back']
      });
      await curated('b', {'name': '   '});
      await curated('c', {'name': 'Gültig'});

      expect((await repo.fetchExercises('u1')).map((e) => e.name), ['Gültig']);
    });

    test('hasGuidance erkennt jeden erklärenden Block', () async {
      await curated('a', {
        'name': 'A',
        'cues': ['Brust raus']
      });
      await curated('b', {'name': 'B', 'description': 'Text'});
      await curated('c', {'name': 'C'});

      final list = await repo.fetchExercises('u1');
      expect(list.firstWhere((e) => e.id == 'a').hasGuidance, isTrue);
      expect(list.firstWhere((e) => e.id == 'b').hasGuidance, isTrue);
      expect(list.firstWhere((e) => e.id == 'c').hasGuidance, isFalse);
    });
  });

  test('equipment steht mal als Liste, mal als einzelner Wert', () async {
    await curated('a', {
      'name': 'A',
      'equipment': ['barbell', 'bench']
    });
    await own('b', {'name': 'B', 'equipment': 'none'});

    final list = await repo.fetchExercises('u1');
    expect(list.firstWhere((e) => e.id == 'a').equipment, ['barbell', 'bench']);
    expect(list.firstWhere((e) => e.id == 'b').equipment, ['none']);
  });

  test('der Strom meldet neue eigene Übungen', () async {
    await curated('a', {'name': 'A'});

    final seen = <int>[];
    final sub = repo.watchExercises('u1').listen((l) => seen.add(l.length));
    await Future<void>.delayed(Duration.zero);
    await own('b', {'name': 'B'});
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen.last, 2);
  });
}
