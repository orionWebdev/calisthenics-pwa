import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/firestore_exercise_repository.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import '../domain/muscle.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return FirestoreExerciseRepository(FirebaseFirestore.instance);
});

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(exerciseRepositoryProvider).watchExercises(userId);
});

/// Der aktive Regionsfilter, `null` heißt „Alle".
///
/// `Notifier` statt `StateProvider`: Letzterer liegt in Riverpod 3 in
/// `legacy.dart`. Für neuen Code lohnt der Altbestand nicht.
class ExerciseFilter extends Notifier<MuscleRegion?> {
  @override
  MuscleRegion? build() => null;

  /// Nochmal auf dieselbe Region tippen hebt den Filter auf — sonst müsste man
  /// den „Alle"-Chip suchen, der weit links steht.
  void toggle(MuscleRegion region) => state = state == region ? null : region;

  void clear() => state = null;
}

final exerciseFilterProvider =
    NotifierProvider<ExerciseFilter, MuscleRegion?>(ExerciseFilter.new);

/// Die Suchanfrage.
class ExerciseQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

final exerciseQueryProvider =
    NotifierProvider<ExerciseQuery, String>(ExerciseQuery.new);

/// Die gefilterte und durchsuchte Liste.
///
/// ## Warum die Suche über den rohen Namen läuft
///
/// 24 kuratierte Übungen haben keinen deutschen Namen, viele eigene sind
/// ohnehin englisch benannt. Wer „Klimmzug" sucht, findet `pull_up` nicht — und
/// wer „pull" sucht, findet „Liegestütz" nicht. Die Suche gleicht deshalb
/// **Name und Kennung** ab: Die Kennung ist bei kuratierten Übungen der
/// englische Slug (`archer_push_up`) und schließt damit genau die Lücke, die
/// die fehlende Übersetzung reißt.
final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final all = ref.watch(exercisesProvider).value ?? const <Exercise>[];
  final region = ref.watch(exerciseFilterProvider);
  final query = ref.watch(exerciseQueryProvider).trim().toLowerCase();

  return all.where((exercise) {
    if (region != null &&
        !exercise.displayMuscles.any((m) => m.region == region)) {
      return false;
    }
    if (query.isEmpty) return true;
    return exercise.name.toLowerCase().contains(query) ||
        exercise.id.toLowerCase().replaceAll('_', ' ').contains(query);
  }).toList();
});
