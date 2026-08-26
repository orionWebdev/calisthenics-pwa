import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/workout_session.dart';

/// Darstellung eines [SetType].
///
/// Erschöpfendes `switch`: Ein neuer Satz-Typ erzwingt Farbe und Kürzel.
extension SetTypeUi on SetType {
  Color get color => switch (this) {
        SetType.warmup => AtemColors.cyan,
        SetType.normal => AtemColors.textPrimary,
        // violet nur als Fläche zulässig — der Chip färbt Rand und Hintergrund,
        // das Kürzel selbst bleibt hell (Vertrag 01-accessibility R4).
        SetType.dropset => AtemColors.violet,
        SetType.failure => AtemColors.magenta,
      };

  /// Farbe für das Kürzel. Weicht bei dropset ab, weil violet als Text
  /// nur 2,8:1 erreicht.
  Color get labelColor =>
      this == SetType.dropset ? AtemColors.violetLight : color;

  /// Ausgeschrieben — das Kürzel allein sagt einem Screenreader nichts.
  String longLabel(AppL10n l) => switch (this) {
        SetType.warmup => l.workoutSetTypeWarmup,
        SetType.normal => l.workoutSetTypeNormal,
        SetType.dropset => l.workoutSetTypeDropset,
        SetType.failure => l.workoutSetTypeFailure,
      };

  String shortLabel(AppL10n l) => switch (this) {
        SetType.warmup => l.workoutSetTypeShortWarmup,
        SetType.normal => l.workoutSetTypeShortNormal,
        SetType.dropset => l.workoutSetTypeShortDropset,
        SetType.failure => l.workoutSetTypeShortFailure,
      };
}
