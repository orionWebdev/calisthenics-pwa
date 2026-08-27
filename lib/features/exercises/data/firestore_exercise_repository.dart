import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/exercise.dart';
import '../domain/exercise_draft.dart';
import '../domain/exercise_repository.dart';
import '../domain/muscle.dart';
import 'exercise_mapper.dart';

/// Liest beide Übungssammlungen und führt sie zusammen.
///
/// `exercises_curated` ist global und für alle Konten gleich; die Regeln lassen
/// jeden freigeschalteten Nutzer lesen, aber niemanden schreiben.
/// `exercises` gehört einem Konto und wird über `userId` gefiltert.
///
/// Sortiert wird in Dart, nach Namen und ohne Rücksicht auf Gross- und
/// Kleinschreibung — die Sammlungen kämen sonst als zwei Blöcke hintereinander,
/// und niemand sucht so.
class FirestoreExerciseRepository implements ExerciseRepository {
  FirestoreExerciseRepository(this._db);

  final FirebaseFirestore _db;

  static const curatedCollection = 'exercises_curated';
  static const ownCollection = 'exercises';

  @override
  Stream<List<Exercise>> watchExercises(String userId) {
    final curated = _db.collection(curatedCollection).snapshots();
    final own = _db
        .collection(ownCollection)
        .where('userId', isEqualTo: userId)
        .snapshots();
    return _combine2(curated, own, _merge);
  }

  @override
  Future<List<Exercise>> fetchExercises(String userId) async {
    final results = await Future.wait([
      _db.collection(curatedCollection).get(),
      _db.collection(ownCollection).where('userId', isEqualTo: userId).get(),
    ]);
    return _merge(results[0], results[1]);
  }

  @override
  Future<String> saveExercise(ExerciseDraft draft) async {
    final data = _toDocument(draft);
    final id = draft.id;

    if (id == null) {
      final reference = await _db.collection(ownCollection).add(data);
      return reference.id;
    }

    // `update`, nicht `set`: Ein `set` ohne `merge` löschte jedes Feld, das
    // das Formular nicht kennt — etwa `cues` oder `createdAt` aus der PWA.
    await _db.collection(ownCollection).doc(id).update(data);
    return id;
  }

  @override
  Future<void> deleteExercise(String id) =>
      _db.collection(ownCollection).doc(id).delete();

  /// Baut das Dokument für `exercises`.
  ///
  /// **`difficulty` geht als Zahl raus, ausnahmslos.** Die Regel lautet
  /// `difficulty is number`; ein Wort wird beim Anlegen abgewiesen. Im Bestand
  /// stehen zwar 55 von 70 eigenen Übungen mit Wörtern, aber die sind vor
  /// dieser Regel entstanden und bleiben nur deshalb liegen. Wird eine von
  /// ihnen bearbeitet, ersetzt diese Zeile das Wort durch die Zahl, auf die
  /// [Difficulty.parse] es ohnehin schon abgebildet hat.
  ///
  /// `userId` steht auch beim Ändern im Dokument: Die Regeln prüfen `isOwner`
  /// auf **beiden** Seiten — auf dem alten Stand und auf dem neuen. Ein
  /// `update`, das `userId` wegließe, ist zwar erlaubt, aber ein `update`, das
  /// es fälschlich änderte, nicht. Es unverändert mitzuschreiben ist die
  /// einfachste Art, das nicht zu verwechseln.
  Map<String, dynamic> _toDocument(ExerciseDraft draft) => {
        'name': draft.name.trim(),
        'muscleGroups': [for (final m in draft.muscleGroups) m.wire],
        'difficulty': draft.difficulty,
        'userId': draft.userId,
        if (draft.equipment.isNotEmpty) 'equipment': draft.equipment,
        if (draft.type != null) 'type': draft.type,
        if (draft.description case final text?
            when text.trim().isNotEmpty)
          'description': text.trim(),
        if (draft.instructions.isNotEmpty)
          'instructionsSteps': draft.instructions,
        if (draft.isNew) 'createdAt': Timestamp.now(),
      };

  List<Exercise> _merge(
    QuerySnapshot<Map<String, dynamic>> curated,
    QuerySnapshot<Map<String, dynamic>> own,
  ) {
    final exercises = <Exercise>[];
    var skipped = 0;

    void take(
      QuerySnapshot<Map<String, dynamic>> snapshot,
      ExerciseSource source,
    ) {
      for (final doc in snapshot.docs) {
        final exercise = ExerciseMapper.fromDoc(doc, source: source);
        if (exercise == null) {
          skipped++;
          continue;
        }
        exercises.add(exercise);
      }
    }

    take(curated, ExerciseSource.curated);
    take(own, ExerciseSource.own);

    exercises
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (skipped > 0) {
      developer.log('$skipped Übung(en) ohne Namen übersprungen',
          name: 'atem.exercises');
    }
    return exercises;
  }
}

/// Verbindet zwei Ströme. Gibt erst aus, wenn **beide** geliefert haben —
/// sonst blitzte die Liste kurz halb gefüllt auf.
Stream<R> _combine2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A, B) combine,
) {
  late StreamController<R> controller;
  final subscriptions = <StreamSubscription<void>>[];
  A? lastA;
  B? lastB;
  var hasA = false, hasB = false;

  void emit() {
    if (!hasA || !hasB) return;
    try {
      controller.add(combine(lastA as A, lastB as B));
    } catch (error, stack) {
      controller.addError(error, stack);
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subscriptions.addAll([
        a.listen((v) {
          lastA = v;
          hasA = true;
          emit();
        }, onError: controller.addError),
        b.listen((v) {
          lastB = v;
          hasB = true;
          emit();
        }, onError: controller.addError),
      ]);
    },
    onCancel: () async {
      for (final s in subscriptions) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}
