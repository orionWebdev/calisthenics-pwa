import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
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
