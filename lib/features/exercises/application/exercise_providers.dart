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

/// Der aktive Muskelfilter, `null` heißt „Alle".
///
/// **Neun Muskeln, nicht sechs Regionen.** Der Filter folgt der Farbe, und die
/// hängt seit der Korrektur an Modul 5 am Muskel. Eine Filterzeile, die
/// „Arme" anbietet, während die Liste daneben Bizeps und Trizeps in zwei
/// Farben zeigt, wäre zwei Ordnungen nebeneinander.
///
/// Welche neun das sind und warum die Beinfamilie zusammenfällt, steht an
/// [MuscleGroup.filters].
///
/// `Notifier` statt `StateProvider`: Letzterer liegt in Riverpod 3 in
/// `legacy.dart`. Für neuen Code lohnt der Altbestand nicht.
class ExerciseFilter extends Notifier<MuscleGroup?> {
  @override
  MuscleGroup? build() => null;

  /// Nochmal auf denselben Muskel tippen hebt den Filter auf — sonst müsste man
  /// den „Alle"-Chip suchen, der weit links steht.
  void toggle(MuscleGroup muscle) => state = state == muscle ? null : muscle;

  void clear() => state = null;
}

final exerciseFilterProvider =
    NotifierProvider<ExerciseFilter, MuscleGroup?>(ExerciseFilter.new);

/// Eigen, kuratiert oder beides — Board 07, A1/3.
///
/// Der Filter existiert, weil nur eine der beiden Mengen bearbeitbar ist:
/// Wer aufräumen will, filtert auf 70 statt in 154 zu suchen.
enum ExerciseOrigin { all, own, curated }

class ExerciseOriginFilter extends Notifier<ExerciseOrigin> {
  @override
  ExerciseOrigin build() => ExerciseOrigin.all;

  void set(ExerciseOrigin origin) => state = origin;
}

final exerciseOriginProvider =
    NotifierProvider<ExerciseOriginFilter, ExerciseOrigin>(
  ExerciseOriginFilter.new,
);

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
  final muscle = ref.watch(exerciseFilterProvider);
  final origin = ref.watch(exerciseOriginProvider);
  final query = ref.watch(exerciseQueryProvider).trim().toLowerCase();

  return all.where((exercise) {
    if (origin == ExerciseOrigin.own && !exercise.isOwn) return false;
    if (origin == ExerciseOrigin.curated && exercise.isOwn) return false;
    // Über `filter` verglichen, nicht direkt: Eine Übung mit `quads` muss
    // unter „Beine" erscheinen, sonst wäre sie über keinen Filter erreichbar.
    if (muscle != null &&
        !exercise.displayMuscles.any((m) => m.filter == muscle)) {
      return false;
    }
    if (query.isEmpty) return true;
    return exercise.name.toLowerCase().contains(query) ||
        exercise.id.toLowerCase().replaceAll('_', ' ').contains(query);
  }).toList();
});
