import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/muscle.dart';

/// Farbe und Text zu einer Muskelgruppe.
///
/// Die Farbe hängt an der **Region**, der Text am **Muskel**. Zehn Gruppen auf
/// sechs fließtextsichere Töne — die Farbe sortiert vor, benennt aber nicht.
/// Deshalb steht der Muskelname immer daneben; Farbe allein wäre für
/// Farbenblinde keine Information (Vertrag R6).
extension MuscleRegionUi on MuscleRegion {
  Color get color => switch (this) {
        MuscleRegion.shoulders => AtemCategories.amber,
        MuscleRegion.back => AtemCategories.blue,
        MuscleRegion.chest => AtemCategories.red,
        MuscleRegion.core => AtemCategories.orange,
        MuscleRegion.arms => AtemCategories.teal,
        MuscleRegion.legs => AtemCategories.green,
      };

  String label(AppL10n l) => switch (this) {
        MuscleRegion.shoulders => l.regionShoulders,
        MuscleRegion.back => l.regionBack,
        MuscleRegion.chest => l.regionChest,
        MuscleRegion.core => l.regionCore,
        MuscleRegion.arms => l.regionArms,
        MuscleRegion.legs => l.regionLegs,
      };
}

extension MuscleGroupUi on MuscleGroup {
  Color get color => region.color;

  String label(AppL10n l) => switch (this) {
        MuscleGroup.shoulders => l.muscleShoulders,
        MuscleGroup.back => l.muscleBack,
        MuscleGroup.chest => l.muscleChest,
        MuscleGroup.core => l.muscleCore,
        MuscleGroup.biceps => l.muscleBiceps,
        MuscleGroup.triceps => l.muscleTriceps,
        MuscleGroup.arms => l.muscleArms,
        MuscleGroup.glutes => l.muscleGlutes,
        MuscleGroup.quads => l.muscleQuads,
        MuscleGroup.hamstrings => l.muscleHamstrings,
        MuscleGroup.calves => l.muscleCalves,
        MuscleGroup.legs => l.muscleLegs,
      };
}

/// Übersetzt die Trainingsart eines Plans oder einer Übung.
///
/// Rohwerte aus Firestore: `strength`, `bodyweight`, `hybrid`. Unbekanntes wird
/// **durchgereicht statt verworfen** — ein neuer Typ aus der PWA erscheint dann
/// englisch, aber er erscheint.
String trainingTypeLabel(AppL10n l, String? wire) => switch (wire) {
      'strength' => l.typeStrength,
      'bodyweight' => l.typeBodyweight,
      'hybrid' => l.typeHybrid,
      _ => wire ?? '',
    };
