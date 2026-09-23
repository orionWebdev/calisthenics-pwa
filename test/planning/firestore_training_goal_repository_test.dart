import 'package:atem/features/planning/data/firestore_training_goal_repository.dart';
import 'package:atem/features/planning/domain/training_goal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// `userProfiles/{uid}/planning/goal` — die drei Schreibregeln aus Board 18, C.
void main() {
  late FakeFirebaseFirestore db;
  late FirestoreTrainingGoalRepository repo;

  DocumentReference<Map<String, dynamic>> doc() => db
      .collection('userProfiles')
      .doc('u')
      .collection('planning')
      .doc('goal');

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreTrainingGoalRepository(db);
  });

  test('ohne Dokument: leer, nicht kaputt', () async {
    expect(await repo.watch('u').first, TrainingGoal.empty);
  });

  test('eine Antwort legt Wert und answeredAt verschachtelt ab', () async {
    await repo.write('u', {'perWeek.strength': 3, 'modalities': ['strength']});
    final data = (await doc().get()).data()!;
    expect(data['perWeek'], {'strength': 3});
    expect(data['modalities'], ['strength']);
    expect((data['answeredAt'] as Map)['perWeek'], isA<Map>());
    expect(((data['answeredAt'] as Map)['perWeek'] as Map)['strength'],
        isA<Timestamp>());
    expect(data['updatedAt'], isA<Timestamp>());
  });

  test('Offen heisst: der Schlüssel fehlt — samt answeredAt', () async {
    await repo.write('u', {'perWeek.strength': 3, 'perWeek.cardio': 2});
    await repo.write('u', {'perWeek.cardio': null});
    final data = (await doc().get()).data()!;
    expect(data['perWeek'], {'strength': 3});
    expect(((data['answeredAt'] as Map)['perWeek'] as Map).keys, ['strength']);
    // Nie null, nie 0 im Dokument.
    expect((data['perWeek'] as Map).containsKey('cardio'), isFalse);
  });

  test('eine Antwort lässt die anderen stehen (Feld-Update mit Merge)',
      () async {
    await repo.write('u', {'describes': 'current'});
    await repo.write('u', {'goals': ['health']});
    final goal = await repo.watch('u').first;
    expect(goal.describes, Describes.current);
    expect(goal.goals, {TrainingAim.health});
  });

  test('Rückgängig stellt das alte Antwortdatum wieder her', () async {
    final old = DateTime(2026, 9, 14, 8);
    await repo.write('u', {'perWeek.strength': 3},
        answeredAt: {'perWeek.strength': old});
    final goal = await repo.watch('u').first;
    expect(goal.answeredAt['perWeek.strength'], old);
  });

  test('Lesen übergeht Unbekanntes, statt es zu reparieren', () async {
    await doc().set({
      'weekPattern': 'seasonal',
      'perWeek': {'strength': 0, 'cardio': 12},
      'goals': ['health', 'glory'],
      'modalities': [],
    });
    final goal = await repo.watch('u').first;
    expect(goal.weekPattern, isNull);
    expect(goal.perWeek.isEmpty, isTrue);
    expect(goal.goals, {TrainingAim.health});
    expect(goal.lanes, isNull);
  });

  test('Alle Angaben entfernen löscht das Dokument', () async {
    await repo.write('u', {'describes': 'intended'});
    await repo.clear('u');
    expect((await doc().get()).exists, isFalse);
    expect(await repo.watch('u').first, TrainingGoal.empty);
  });
}
