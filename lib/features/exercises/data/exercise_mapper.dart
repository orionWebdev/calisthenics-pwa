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

    // Der deutsche Overlay-Block der kuratierten Übungen. Die Vorgänger-App
    // liest daraus Name, Anleitung, Cues und typische Fehler.
    final german = data['i18n'] is Map
        ? (data['i18n'] as Map)['de'] as Map<Object?, Object?>?
        : null;

    return Exercise(
      id: doc.id,
      name: name,
      // Zwei Schreibweisen im Bestand: ein flaches `name_de` und ein
      // verschachteltes `i18n.de.name`. Beide kommen vor.
      nameDe: _string(data['name_de']) ?? _string(german?['name']),
      source: source,
      muscleGroups: _muscles(data['muscleGroups']),
      primaryMuscles: _muscles(data['primaryMuscles']),
      secondaryMuscles: _muscles(data['secondaryMuscles']),
      equipment: _strings(data['equipment']),
      // Zahlen und Wörter im selben Feld — siehe [Difficulty].
      difficulty: Difficulty.parse(data['difficulty']),
      type: _string(data['type']),
      description:
          _string(german?['description']) ?? _string(data['description']),
      instructions: _pick(german?['instructionsSteps'],
          data['instructionsSteps']),
      cues: _pick(german?['cues'], data['cues']),
      commonMistakes:
          _pick(german?['commonMistakes'], data['commonMistakes']),
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

  /// Die deutsche Fassung, wenn sie etwas enthält — sonst die Grundfassung.
  ///
  /// Ein leerer Overlay-Eintrag darf die englische Anleitung nicht
  /// verdrängen: „übersetzt, aber leer" wäre schlechter als „nicht übersetzt".
  static List<String> _pick(Object? german, Object? base) {
    final translated = _strings(german);
    return translated.isEmpty ? _strings(base) : translated;
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
