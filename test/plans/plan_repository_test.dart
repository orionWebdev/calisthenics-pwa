import 'package:atem/features/plans/data/firestore_plan_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestorePlanRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestorePlanRepository(db);
  });

  Future<void> plan(String id, Map<String, dynamic> data) =>
      db.collection('plans').doc(id).set({'userId': 'u1', ...data});

  test('liest nur die Pläne des Nutzers, sortiert nach Namen', () async {
    await plan('a', {'name': 'Pull Day'});
    await plan('b', {'name': 'legs'});
    await db.collection('plans').add({'userId': 'jemand', 'name': 'Fremd'});

    expect(
        (await repo.fetchPlans('u1')).map((p) => p.name), ['legs', 'Pull Day']);
  });

  test('die Zielvorgaben werden gelesen, wie sie im Bestand stehen', () async {
    await plan('a', {
      'name': 'Plan',
      'items': [
        {
          'exerciseId': 'pull_up',
          'target': {'sets': 4},
          'restSec': 90,
        },
        {
          'exerciseId': 'plank',
          'target': {'sets': 3, 'holdSec': 30},
        },
        {
          // reps steht als Zeichenkette — auch Bereiche müssen durchkommen.
          'exerciseId': 'push_up',
          'target': {'sets': 2, 'reps': '8-12'},
        },
      ],
    });

    final items = (await repo.fetchPlans('u1')).single.items;
    expect(items, hasLength(3));
    expect(items[0].sets, 4);
    expect(items[0].restSeconds, 90);
    expect(items[1].holdSeconds, 30);
    expect(items[2].reps, '8-12');
  });

  test('eine Zahl in reps überlebt als Text', () async {
    await plan('a', {
      'name': 'Plan',
      'items': [
        {
          'exerciseId': 'x',
          'target': {'reps': 25},
        },
      ],
    });

    expect((await repo.fetchPlans('u1')).single.items.single.reps, '25');
  });

  test('ein Eintrag ohne exerciseId fällt weg, der Plan bleibt', () async {
    await plan('a', {
      'name': 'Plan',
      'items': [
        {'exerciseId': 'ok', 'target': <String, dynamic>{}},
        {'target': <String, dynamic>{}},
        'kein Objekt',
      ],
    });

    final p = (await repo.fetchPlans('u1')).single;
    expect(p.items, hasLength(1));
    expect(p.exerciseCount, 1);
  });

  test('die Dauerschätzung bleibt grob, aber plausibel', () async {
    await plan('a', {
      'name': 'Plan',
      'items': [
        for (var i = 0; i < 5; i++)
          {
            'exerciseId': 'e$i',
            'target': {'sets': 4},
            'restSec': 90,
          },
      ],
    });

    final d = (await repo.fetchPlans('u1')).single.estimatedDuration;
    // 5 Übungen à 4 Sätze: 20 × 45 s Arbeit + 15 × 90 s Pause = 37,5 min
    expect(d.inMinutes, 37);
  });

  test('ein Plan ohne Namen wird ausgelassen', () async {
    await plan('a', {'icon': 'fitness_center'});
    await plan('b', {'name': 'Gültig'});

    expect((await repo.fetchPlans('u1')).map((p) => p.name), ['Gültig']);
  });
}
