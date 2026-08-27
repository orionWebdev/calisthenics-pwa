import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/exercise.dart';
import '../domain/muscle.dart';

/// Übersetzt Dokumente aus `exercises_curated` und `exercises`.
///
/// **Eine Abbildung für beide Sammlungen.** Sie unterscheiden sich in den
/// Feldern, die sie tragen, nicht in deren Bedeutung — und die Unterschiede
/// sind ohnehin nur Lücken. Zwei Mapper wären zwei Wahrheiten.
abstract final class ExerciseMapper {
  static Exercise? fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required ExerciseSource source,
  }) {
    final data = doc.data();
    if (data == null) return null;

    final name = _string(data['name']);
    // Ohne Namen ist eine Übung nicht anzeigbar. Der Bestand kennt keinen
    // solchen Fall, aber Raten wäre schlimmer als Auslassen.
    if (name == null) return null;

    return Exercise(
      id: doc.id,
      name: name,
      source: source,
      muscleGroups: _muscles(data['muscleGroups']),
      primaryMuscles: _muscles(data['primaryMuscles']),
      secondaryMuscles: _muscles(data['secondaryMuscles']),
      equipment: _strings(data['equipment']),
      // Zahlen und Wörter im selben Feld — siehe [Difficulty].
      difficulty: Difficulty.parse(data['difficulty']),
      type: _string(data['type']),
      description: _string(data['description']),
      instructions: _strings(data['instructionsSteps']),
      cues: _strings(data['cues']),
      commonMistakes: _strings(data['commonMistakes']),
    );
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Liest sowohl eine Liste als auch einen einzelnen Wert.
  ///
  /// `equipment` steht im Bestand mal als Liste, mal als einzelne Zeichenkette.
  static List<String> _strings(Object? value) {
    if (value is String) {
      final single = _string(value);
      return single == null ? const [] : [single];
    }
    if (value is! List) return const [];
    return [
      for (final entry in value)
        if (_string(entry) case final s?) s,
    ];
  }

  static List<MuscleGroup> _muscles(Object? value) {
    return [
      for (final raw in _strings(value))
        // Unbekannte Bezeichnungen fallen weg statt aufzuschlagen: Die Übung
        // bleibt sichtbar, sie verliert nur einen Chip.
        if (MuscleGroup.fromWire(raw) case final group?) group,
    ];
  }
}
