import 'package:atem/features/exercises/data/firestore_exercise_repository.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/exercise_draft.dart';
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

  Future<Map<String, dynamic>> doc(String id) async =>
      (await db.collection('exercises').doc(id).get()).data()!;

  group('Anlegen', () {
    test('schreibt die drei Pflichtfelder, difficulty als Zahl', () async {
      final id = await repo.saveExercise(const ExerciseDraft(
        userId: 'u1',
        name: '  Klimmzug breit  ',
        muscleGroups: [MuscleGroup.back, MuscleGroup.biceps],
        difficulty: 3,
      ));

      final data = await doc(id);
      expect(data['name'], 'Klimmzug breit', reason: 'getrimmt');
      expect(data['muscleGroups'], ['back', 'biceps']);
      expect(data['difficulty'], 3);
      expect(data['difficulty'], isA<int>(),
          reason: 'Die Regel lautet `difficulty is number` — '
              'ein Wort würde abgewiesen');
      expect(data['userId'], 'u1');
    });

    test('lässt leere Felder weg, statt sie auf null zu setzen', () async {
      final id = await repo.saveExercise(const ExerciseDraft(
        userId: 'u1',
        name: 'Dip',
        muscleGroups: [MuscleGroup.triceps],
        difficulty: 2,
        description: '   ',
      ));

      final data = await doc(id);
      expect(data.containsKey('description'), isFalse);
      expect(data.containsKey('equipment'), isFalse);
      expect(data.containsKey('type'), isFalse);
    });
  });

  group('Bearbeiten', () {
    test('ersetzt ein altes Wort beiläufig durch die Zahl', () async {
      // Der Bestand: 55 von 70 eigenen Übungen tragen ein Wort.
      await db.collection('exercises').doc('alt').set({
        'name': 'Liegestütz',
        'muscleGroups': ['chest'],
        'difficulty': 'intermediate',
        'userId': 'u1',
        'cues': ['Ellbogen eng'],
      });

      // So kommt sie beim Lesen an — das Wort ist schon abgebildet.
      expect(Difficulty.parse('intermediate'), 2);

      await repo.saveExercise(const ExerciseDraft(
        id: 'alt',
        userId: 'u1',
        name: 'Liegestütz',
        muscleGroups: [MuscleGroup.chest],
        difficulty: 2,
      ));

      final data = await doc('alt');
      expect(data['difficulty'], 2);
      expect(data['difficulty'], isNot(isA<String>()));
    });

    test('lässt Felder stehen, die das Formular nicht kennt', () async {
      await db.collection('exercises').doc('alt').set({
        'name': 'Liegestütz',
        'muscleGroups': ['chest'],
        'difficulty': 1,
        'userId': 'u1',
        // Aus der Vorgänger-App — das Formular kennt sie nicht.
        'cues': ['Ellbogen eng'],
        'createdAt': 'irgendwann',
      });

      await repo.saveExercise(const ExerciseDraft(
        id: 'alt',
        userId: 'u1',
        name: 'Liegestütz eng',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
        difficulty: 2,
      ));

      final data = await doc('alt');
      expect(data['name'], 'Liegestütz eng');
      expect(data['cues'], ['Ellbogen eng'],
          reason: 'ein `set` ohne merge hätte sie gelöscht');
      expect(data['createdAt'], 'irgendwann');
    });

    test('schreibt beim Ändern kein neues createdAt', () async {
      await db.collection('exercises').doc('alt').set({
        'name': 'A',
        'muscleGroups': ['core'],
        'difficulty': 1,
        'userId': 'u1',
      });
      await repo.saveExercise(const ExerciseDraft(
        id: 'alt',
        userId: 'u1',
        name: 'B',
        muscleGroups: [MuscleGroup.core],
        difficulty: 1,
      ));
      expect((await doc('alt')).containsKey('createdAt'), isFalse);
    });
  });

  test('Löschen entfernt das Dokument', () async {
    final id = await repo.saveExercise(const ExerciseDraft(
      userId: 'u1',
      name: 'Weg',
      muscleGroups: [MuscleGroup.core],
      difficulty: 1,
    ));
    await repo.deleteExercise(id);
    expect((await db.collection('exercises').doc(id).get()).exists, isFalse);
  });

  group('Prüfung des Entwurfs', () {
    Set<ExerciseDraftFault> faults({
      String name = 'Name',
      List<MuscleGroup> muscles = const [MuscleGroup.core],
      int? difficulty = 3,
    }) =>
        ExerciseDraft.faultsIn(
          name: name,
          muscleGroups: muscles,
          difficulty: difficulty,
        );

    test('vollständig ist fehlerfrei', () => expect(faults(), isEmpty));

    test('ein Name aus Leerzeichen zählt nicht', () {
      expect(faults(name: '   '), contains(ExerciseDraftFault.name));
    });

    test('ohne Muskel geht nicht', () {
      expect(faults(muscles: const []),
          contains(ExerciseDraftFault.muscles));
    });

    test('ohne Stufe geht nicht — die Regel verlangt eine Zahl', () {
      expect(faults(difficulty: null),
          contains(ExerciseDraftFault.difficulty));
    });

    test('eine Stufe ausserhalb 1–5 geht nicht', () {
      expect(faults(difficulty: 0), contains(ExerciseDraftFault.difficulty));
      expect(faults(difficulty: 6), contains(ExerciseDraftFault.difficulty));
    });
  });

  group('Filtermuskeln', () {
    test('es sind neun', () {
      expect(MuscleGroup.filters, hasLength(9));
    });

    test('die Beinfamilie fällt auf einen Filter zusammen', () {
      for (final group in [
        MuscleGroup.glutes,
        MuscleGroup.quads,
        MuscleGroup.hamstrings,
        MuscleGroup.legs,
      ]) {
        expect(group.filter, MuscleGroup.legs, reason: group.wire);
      }
    });

    test('Bizeps und Trizeps bleiben eigenständig', () {
      expect(MuscleGroup.biceps.filter, MuscleGroup.biceps);
      expect(MuscleGroup.triceps.filter, MuscleGroup.triceps);
      expect(MuscleGroup.arms.filter, MuscleGroup.arms);
    });

    test('jeder Filter ist auch sein eigener Filter', () {
      for (final group in MuscleGroup.filters) {
        expect(group.filter, group, reason: group.wire);
      }
    });
  });

  test('eine kuratierte Übung wird nie nach exercises_curated geschrieben',
      () async {
    // Die Regeln verbieten es ohnehin; hier zählt, dass die App es gar nicht
    // erst versucht — „Eigene Fassung" ist ein Anlegen, kein Bearbeiten.
    await repo.saveExercise(const ExerciseDraft(
      userId: 'u1',
      name: 'Archer Push-up (eigene)',
      muscleGroups: [MuscleGroup.chest],
      difficulty: 4,
    ));
    final curated = await db.collection('exercises_curated').get();
    expect(curated.docs, isEmpty);
    expect((await db.collection('exercises').get()).docs, hasLength(1));
  });

  test('ExerciseSource bleibt beim Lesen erhalten', () {
    const own = Exercise(id: 'x', name: 'X', source: ExerciseSource.own);
    expect(own.isOwn, isTrue);
  });
}
