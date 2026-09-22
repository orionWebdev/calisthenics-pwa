import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/plans/data/firestore_plan_repository.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/plans/domain/plan_draft.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestorePlanRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestorePlanRepository(db);
  });

  Future<Map<String, dynamic>> doc(String id) async =>
      (await db.collection('plans').doc(id).get()).data()!;

  test('schreibt den verschachtelten target-Aufbau der Vorgänger-App',
      () async {
    final id = await repo.savePlan(const PlanDraft(
      userId: 'u1',
      name: 'Oberkörper A',
      items: [
        PlanItem(
          exerciseId: 'archer_push_up',
          sets: 4,
          reps: '8-12',
          restSeconds: 90,
        ),
      ],
    ));

    final items = (await doc(id))['items'] as List;
    final first = items.first as Map;
    expect(first['exerciseId'], 'archer_push_up');
    expect(first['target'], {'sets': 4, 'reps': '8-12'});
    expect(first['restSec'], 90,
        reason: 'restSec steht am Eintrag, nicht in target');
  });

  test('reps bleibt eine Zeichenkette — Bereiche überleben', () async {
    final id = await repo.savePlan(const PlanDraft(
      userId: 'u1',
      name: 'P',
      items: [PlanItem(exerciseId: 'x', reps: '8-12')],
    ));
    final target =
        ((await doc(id))['items'] as List).first as Map;
    expect(target['target']['reps'], '8-12');
    expect(target['target']['reps'], isA<String>());
  });

  test('auch eine reine Zahl bleibt Text', () async {
    final id = await repo.savePlan(const PlanDraft(
      userId: 'u1',
      name: 'P',
      items: [PlanItem(exerciseId: 'x', reps: '25')],
    ));
    final target = ((await doc(id))['items'] as List).first as Map;
    expect(target['target']['reps'], '25');
    expect(target['target']['reps'], isA<String>());
  });

  test('Zielwerte ohne Angabe fehlen, statt null zu sein', () async {
    final id = await repo.savePlan(const PlanDraft(
      userId: 'u1',
      name: 'P',
      items: [PlanItem(exerciseId: 'x', sets: 3)],
    ));
    final first = ((await doc(id))['items'] as List).first as Map;
    expect(first['target'], {'sets': 3});
    expect(first.containsKey('restSec'), isFalse);
  });

  test('geschriebene Pläne sind wieder lesbar', () async {
    await repo.savePlan(const PlanDraft(
      userId: 'u1',
      name: 'Rundlauf',
      items: [
        PlanItem(exerciseId: 'a', sets: 3, reps: '8-12', restSeconds: 60),
        PlanItem(exerciseId: 'b', holdSeconds: 45),
      ],
    ));

    final plans = await repo.fetchPlans('u1');
    expect(plans, hasLength(1));
    expect(plans.first.name, 'Rundlauf');
    expect(plans.first.items.first.reps, '8-12');
    expect(plans.first.items.last.holdSeconds, 45);
  });

  test('Löschen entfernt den Plan', () async {
    final id = await repo.savePlan(const PlanDraft(
      userId: 'u1',
      name: 'Weg',
      items: [PlanItem(exerciseId: 'x')],
    ));
    await repo.deletePlan(id);
    expect((await db.collection('plans').doc(id).get()).exists, isFalse);
  });

  group('Prüfung des Entwurfs', () {
    test('ein Plan ohne Namen geht nicht', () {
      expect(PlanDraft.faultsIn(name: '  '), contains(PlanDraftFault.name));
    });

    test('ein leerer Plan ist gültig', () {
      // Board 07: „Der Plan existiert, sobald er einen Namen hat." Das war
      // vorher als Fehler gebaut — eine Verwechslung von „darf existieren"
      // mit „ist startbar".
      expect(PlanDraft.faultsIn(name: 'Oberkörper A'), isEmpty);
    });

    test('startbar ist er erst mit Einträgen', () {
      expect(PlanDraft.isStartable(const []), isFalse);
      expect(
        PlanDraft.isStartable(const [PlanItem(exerciseId: 'x')]),
        isTrue,
      );
    });

    test('ein leerer Plan lässt sich speichern und wieder lesen', () async {
      final id = await repo.savePlan(
        const PlanDraft(userId: 'u1', name: 'Noch leer', items: []),
      );
      final plans = await repo.fetchPlans('u1');
      final plan = plans.firstWhere((p) => p.id == id);
      expect(plan.name, 'Noch leer');
      expect(plan.items, isEmpty);
    });
  });

  group('Lücken', () {
    const items = [
      PlanItem(exerciseId: 'da', sets: 4),
      PlanItem(exerciseId: 'weg', sets: 3, reps: '8-12', restSeconds: 90),
    ];
    const exercises = [
      Exercise(id: 'da', name: 'Da', source: ExerciseSource.own),
    ];

    test('ein Eintrag ohne Übung ist eine Lücke, kein Fehler', () {
      final resolved = ResolvedPlanItem.resolve(items, exercises);
      expect(resolved, hasLength(2));
      expect(resolved.first.isDangling, isFalse);
      expect(resolved.last.isDangling, isTrue);
    });

    test('die Zielwerte der Lücke bleiben erhalten', () {
      final gap = ResolvedPlanItem.resolve(items, exercises).last;
      expect(gap.item.sets, 3);
      expect(gap.item.reps, '8-12');
      expect(gap.item.restSeconds, 90,
          reason: 'genau sie sind der Grund, die Lücke stehenzulassen');
    });

    test('eine Lücke lässt sich speichern und wieder lesen', () async {
      // Wichtig: Ein Plan mit Lücke muss durch die Schreibschicht kommen,
      // sonst verlöre man beim ersten Bearbeiten genau die Zielwerte.
      final id = await repo.savePlan(const PlanDraft(
        userId: 'u1',
        name: 'Mit Lücke',
        items: items,
      ));
      final plan = (await repo.fetchPlans('u1'))
          .firstWhere((p) => p.id == id);
      expect(plan.items, hasLength(2));
      expect(plan.items.last.exerciseId, 'weg');
      expect(plan.items.last.reps, '8-12');
    });
  });

  group('Ältere Schreibweisen aus dem Bestand', () {
    /// Die Vorgänger-App normalisiert beim Lesen vier Fassungen
    /// (`js/views/plans/state-helpers.js`). Wer sie hier nicht kennt, verliert
    /// still die Zielwerte: Aus „2 Sätze" wurden drei, aus „14" nichts.
    Future<List<PlanItem>> read(Map<String, dynamic> doc) async {
      await db.collection('plans').add({'name': 'Alt', 'userId': 'u1', ...doc});
      final plan = (await repo.fetchPlans('u1')).single;
      return plan.items;
    }

    test('flach am Eintrag statt unter target', () async {
      final items = await read({
        'items': [
          {'exerciseId': 'push_up', 'sets': 2, 'reps': '14', 'restSec': 60},
        ],
      });
      expect(items.single.sets, 2);
      expect(items.single.reps, '14');
      expect(items.single.restSeconds, 60);
    });

    test('Zahlen als Text', () async {
      final items = await read({
        'items': [
          {
            'exerciseId': 'push_up',
            'target': {'sets': '2', 'reps': 14, 'holdSec': '45'},
            'restSec': '90',
          },
        ],
      });
      expect(items.single.sets, 2);
      expect(items.single.reps, '14', reason: 'reps bleibt Text');
      expect(items.single.holdSeconds, 45);
      expect(items.single.restSeconds, 90);
    });

    test('hold statt holdSec, rest statt restSec, id statt exerciseId',
        () async {
      final items = await read({
        'items': [
          {'id': 'plank', 'hold': 45, 'rest': 30},
        ],
      });
      expect(items.single.exerciseId, 'plank');
      expect(items.single.holdSeconds, 45);
      expect(items.single.restSeconds, 30);
    });

    test('exercises statt items', () async {
      final items = await read({
        'exercises': [
          {'exerciseId': 'push_up', 'sets': 2},
        ],
      });
      expect(items.single.sets, 2);
    });

    test('ein Zielbereich wird nie zur Satzzahl', () async {
      final items = await read({
        'items': [
          {'exerciseId': 'push_up', 'reps': '8-12', 'sets': 'viele'},
        ],
      });
      expect(items.single.reps, '8-12');
      expect(items.single.sets, isNull,
          reason: 'unlesbar heisst ohne Angabe, nicht irgendeine Zahl');
    });
  });
}
