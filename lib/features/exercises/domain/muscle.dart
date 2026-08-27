/// Muskelgruppen und ihre Körperregionen.
///
/// Reines Dart, keine Farben — die liegen in `presentation/muscle_ui.dart`
/// (Vertrag 3, Domänenreinheit).
///
/// ## Warum es zwei Ebenen gibt
///
/// Die **Region** fasst zusammen, der **Muskel** benennt. Beide werden
/// gebraucht: Die Region ordnet den Bestand grob, der Muskel steht im Text und
/// trägt seine eigene Farbe.
///
/// Dass die Farbe an der Region hinge, war einmal so — es beruhte auf der
/// Annahme, nur sechs Töne seien fließtextsicher. Die tatsächlichen
/// Muskelfarben der Vorgänger-App halten den Kontrastvertrag alle neun, der
/// schlechteste mit 6,33:1. Farbe hängt seither am Muskel; die Region bleibt
/// als Ordnungsebene bestehen.
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

  /// Die neun Muskeln, nach denen gefiltert und ausgewählt wird.
  ///
  /// Es sind genau die neun mit eigener Farbe. Die fehlenden drei — Gesäß,
  /// Quadrizeps, Beinbeuger — sind keine Auslassung: Die Vorgänger-App
  /// unterscheidet sie farblich nicht, und ein Filter für „Quadrizeps" neben
  /// einem für „Beine" träfe auf denselben Bestand.
  ///
  /// Die Reihenfolge ist von oben nach unten gedacht, nicht alphabetisch:
  /// Schultern, Brust, Rücken, dann die Arme, dann Rumpf und Beine. Wer nach
  /// einer Übung sucht, denkt am Körper entlang.
  static const filters = <MuscleGroup>[
    MuscleGroup.shoulders,
    MuscleGroup.chest,
    MuscleGroup.back,
    MuscleGroup.arms,
    MuscleGroup.biceps,
    MuscleGroup.triceps,
    MuscleGroup.core,
    MuscleGroup.legs,
    MuscleGroup.calves,
  ];

  /// Auf welchen Filter dieser Muskel fällt.
  ///
  /// Nur die Beinfamilie wird zusammengezogen: Eine Übung, die `quads` trägt,
  /// muss unter „Beine" erscheinen, sonst wäre sie über keinen Filter
  /// erreichbar. Bizeps und Trizeps bleiben dagegen eigenständig — sie haben
  /// eigene Farben, eigene Filter, und wer sie sucht, meint sie.
  MuscleGroup get filter => switch (this) {
        MuscleGroup.glutes ||
        MuscleGroup.quads ||
        MuscleGroup.hamstrings ||
        MuscleGroup.legs =>
          MuscleGroup.legs,
        _ => this,
      };
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
