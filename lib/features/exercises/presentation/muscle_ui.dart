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
  /// Die Farbe der Region ist die ihres bekanntesten Muskels — sie erscheint
  /// nur noch am Filter-Chip, wo eine ganze Region gemeint ist.
  Color get color => switch (this) {
        MuscleRegion.shoulders => AtemCategories.shoulders,
        MuscleRegion.back => AtemCategories.back,
        MuscleRegion.chest => AtemCategories.chest,
        MuscleRegion.core => AtemCategories.core,
        MuscleRegion.arms => AtemCategories.arms,
        MuscleRegion.legs => AtemCategories.legs,
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
  /// **Jeder Muskel trägt seine eigene Farbe**, nicht die seiner Region.
  ///
  /// Die Zusammenlegung auf sechs Regionstöne entstand aus einer falschen
  /// Annahme: Der Auftrag an das Design nannte die Zonen- und
  /// Schwierigkeitsfarben der Vorgänger-App und nicht ihre tatsächlichen
  /// Muskelfarben. Die sind heller — und alle neun halten den Kontrastvertrag
  /// mit Abstand. Der Grund für den Kompromiss existierte also nie.
  ///
  /// Was die Vorgänger-App **nicht** unterscheidet, wird auch hier nicht
  /// unterschieden: Gesäß, Quadrizeps und Beinbeuger teilen sich den Beinton.
  /// Der Name daneben benennt den Muskel weiterhin genau.
  Color get color => switch (this) {
        MuscleGroup.shoulders => AtemCategories.shoulders,
        MuscleGroup.back => AtemCategories.back,
        MuscleGroup.chest => AtemCategories.chest,
        MuscleGroup.core => AtemCategories.core,
        MuscleGroup.biceps => AtemCategories.biceps,
        MuscleGroup.triceps => AtemCategories.triceps,
        MuscleGroup.arms => AtemCategories.arms,
        MuscleGroup.calves => AtemCategories.calves,
        MuscleGroup.glutes ||
        MuscleGroup.quads ||
        MuscleGroup.hamstrings ||
        MuscleGroup.legs =>
          AtemCategories.legs,
      };

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
