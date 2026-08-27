/// Muskelgruppen und ihre Körperregionen.
///
/// Reines Dart, keine Farben — die liegen in `presentation/muscle_ui.dart`
/// (Vertrag 3, Domänenreinheit).
///
/// ## Warum es zwei Ebenen gibt
///
/// Die Kategoriepalette trägt nur **sechs** fließtextsichere Töne, der Bestand
/// kennt aber **zehn** Muskelgruppen. Statt Farben willkürlich zu doppeln,
/// kodiert die Farbe die **Region** und der Text den **Muskel**. Farbe ist
/// damit Vorsortierung, nie Information allein — was ohnehin Vertrag R6
/// verlangt.
library;

/// Die farbtragende Ebene. Sechs Regionen, sechs Töne.
enum MuscleRegion {
  shoulders,
  back,
  chest,
  core,
  arms,
  legs,
}

/// Die Ebene, die im Text steht.
///
/// Die beiden Sammlungen sprechen **nicht dieselbe Sprache**: `exercises_curated`
/// nennt einzelne Muskeln (`biceps`, `quads`), die nutzereigenen Übungen zum
/// Teil schon Regionen (`arms`, `legs`). Beides landet hier, und beides findet
/// über [region] denselben Farbton — die Zuordnung passt also von selbst.
enum MuscleGroup {
  shoulders('shoulders', MuscleRegion.shoulders),
  back('back', MuscleRegion.back),
  chest('chest', MuscleRegion.chest),
  core('core', MuscleRegion.core),
  biceps('biceps', MuscleRegion.arms),
  triceps('triceps', MuscleRegion.arms),
  arms('arms', MuscleRegion.arms),
  glutes('glutes', MuscleRegion.legs),
  quads('quads', MuscleRegion.legs),
  hamstrings('hamstrings', MuscleRegion.legs),
  calves('calves', MuscleRegion.legs),
  legs('legs', MuscleRegion.legs);

  const MuscleGroup(this.wire, this.region);

  /// Wie es in Firestore steht.
  final String wire;

  final MuscleRegion region;

  static MuscleGroup? fromWire(String? value) {
    if (value == null) return null;
    final needle = value.trim().toLowerCase();
    for (final group in values) {
      if (group.wire == needle) return group;
    }
    return null;
  }
}

/// Schwierigkeit auf einer Skala von 1 bis 5.
///
/// ## Zwei Schreibweisen im selben Feld
///
/// `exercises_curated` führt Zahlen (1–5). Die nutzereigenen Übungen führen
/// **beides**: 15 Dokumente mit Zahlen, 55 mit Wörtern (`beginner`,
/// `intermediate`, `advanced`, `elite`). Ein `as int` fiele über die Hälfte
/// des Bestands.
///
/// Die Zuordnung ist **nicht geraten**: Sie steht als Tabelle in
/// `js/views/sessionTemplates.js` der Vorgänger-App und wird von dort
/// übernommen. Die Stufe 5 ist damit nur über Zahlen erreichbar.
abstract final class Difficulty {
  static const min = 1;
  static const max = 5;

  static const _words = {
    'beginner': 1,
    'intermediate': 2,
    'advanced': 3,
    'elite': 4,
  };

  /// `null`, wenn sich nichts Sinnvolles lesen lässt.
  static int? parse(Object? value) {
    if (value is num) {
      final level = value.round();
      return level >= min && level <= max ? level : null;
    }
    if (value is String) return _words[value.trim().toLowerCase()];
    return null;
  }
}
