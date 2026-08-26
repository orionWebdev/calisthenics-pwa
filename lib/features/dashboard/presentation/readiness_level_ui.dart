import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/readiness_level.dart';

/// Darstellung einer [ReadinessLevel].
///
/// Farbe und Text leben hier, nicht im Enum — siehe
/// `docs/contracts/03-architecture.md`, Domänenreinheit.
///
/// Erschöpfendes `switch`: Eine neue Stufe erzwingt Farbe, Label und Empfehlung,
/// sonst kompiliert es nicht. Kostenlose Absicherung gegen halbe Erweiterungen.
extension ReadinessLevelUi on ReadinessLevel {
  Color get color => switch (this) {
        ReadinessLevel.peak => AtemColors.green,
        ReadinessLevel.solid => AtemColors.cyan,
        // Nicht violetLight: erreicht als Text kein AA (3,98:1 auf card).
        ReadinessLevel.moderate => AtemColors.amber,
        ReadinessLevel.focusRecovery => AtemColors.magenta,
      };

  String label(AppL10n l) => switch (this) {
        ReadinessLevel.peak => l.dashboardReadinessLevelPeak,
        ReadinessLevel.solid => l.dashboardReadinessLevelSolid,
        ReadinessLevel.moderate => l.dashboardReadinessLevelModerate,
        ReadinessLevel.focusRecovery => l.dashboardReadinessLevelRecovery,
      };

  String tag(AppL10n l) => switch (this) {
        ReadinessLevel.peak => l.dashboardReadinessTagPeak,
        ReadinessLevel.solid => l.dashboardReadinessTagSolid,
        ReadinessLevel.moderate => l.dashboardReadinessTagModerate,
        ReadinessLevel.focusRecovery => l.dashboardReadinessTagRecovery,
      };
}
