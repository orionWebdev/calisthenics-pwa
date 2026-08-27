/// Die Historien-Referenzen als Text — **hier und nicht in der Domäne**.
///
/// Vorher trugen [WorkoutSet] und [WorkoutExercise] fertige Zeichenketten
/// („80 kg × 10", „PR 140 KG"). Solange die Attrappe sie lieferte, fiel nicht
/// auf, dass damit übersetzter Text in der Domäne stand — beim Anschluss an
/// echte Daten hätte die Datenschicht deutsch schreiben müssen.
library;

import 'package:flutter/widgets.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/workout_session.dart';


/// Was beim letzten Mal an dieser Stelle stand.
///
/// Drei Fälle, weil der Bestand alle drei kennt: Gewicht und Wiederholungen,
/// nur Wiederholungen (Körpergewichtsübung), nur Gewicht.
String previousSetLabel(
  BuildContext context,
  AppL10n l10n,
  SetReference? previous,
) {
  if (previous == null || previous.isEmpty) return l10n.commonNotAvailable;

  final weight = previous.weightKg;
  final reps = previous.reps;

  if (weight != null && reps != null) {
    return l10n.workoutPreviousSet(AtemNumberField.format(context, weight), reps);
  }
  if (reps != null) return l10n.workoutPreviousReps(reps);
  return l10n.workoutPreviousWeight(AtemNumberField.format(context, weight!));
}

/// Das schwerste je protokollierte Gewicht. `null`, wenn es keins gibt —
/// dann erscheint **kein Chip**, statt „PR —" zu behaupten.
String? recordLabel(BuildContext context, AppL10n l10n, double? weightKg) =>
    weightKg == null
        ? null
        : l10n.workoutRecordKg(AtemNumberField.format(context, weightKg));
