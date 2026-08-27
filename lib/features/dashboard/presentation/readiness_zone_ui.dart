import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../../history/domain/readiness.dart';

/// Darstellung einer [ReadinessZone].
///
/// ## Warum es das neben `ReadinessLevelUi` gibt
///
/// [ReadinessLevel] leitet vier Stufen allein aus dem Punktwert ab. Das reicht
/// nicht: **Ein Wert von 40 kann zwei entgegengesetzte Dinge bedeuten.**
///
/// * `formLoss` — zu wenig trainiert, der Körper ist ausgeruht
/// * `fatigued` — zu viel trainiert, der Körper ist müde
///
/// Beides ergibt dieselbe Punktzahl, verlangt aber die jeweils gegenteilige
/// Empfehlung. Die Punktzahl allein kann das nicht auseinanderhalten; der ACWR
/// kann es, weil er die Richtung kennt. Deshalb rechnet
/// `Readiness.mapZone(score, acwr)` mit beidem.
///
/// `ReadinessLevelUi` bleibt für Datenquellen ohne Zone — die Design-Vorschau
/// liefert nur einen Wert.
extension ReadinessZoneUi on ReadinessZone {
  Color get color => switch (this) {
        ReadinessZone.peak => AtemColors.green,
        ReadinessZone.building => AtemColors.cyan,
        ReadinessZone.maintaining => AtemColors.amber,
        // Formverlust ist kein Alarm, sondern eine Einladung: Der Körper ist
        // ausgeruht. Deshalb Bernstein wie „moderat" und nicht Magenta.
        ReadinessZone.formLoss => AtemColors.amber,
        ReadinessZone.fatigued => AtemColors.magenta,
        ReadinessZone.overreaching => AtemColors.magenta,
      };

  String label(AppL10n l) => switch (this) {
        ReadinessZone.peak => l.dashboardReadinessLevelPeak,
        ReadinessZone.building => l.dashboardReadinessLevelBuilding,
        ReadinessZone.maintaining => l.dashboardReadinessLevelModerate,
        ReadinessZone.formLoss => l.dashboardReadinessLevelFormLoss,
        ReadinessZone.fatigued => l.dashboardReadinessLevelFatigued,
        ReadinessZone.overreaching => l.dashboardReadinessLevelOverreaching,
      };

  /// Die Empfehlung unter dem Bogen.
  String tag(AppL10n l) => switch (this) {
        ReadinessZone.peak => l.dashboardReadinessTagPeak,
        ReadinessZone.building => l.dashboardReadinessTagSolid,
        ReadinessZone.maintaining => l.dashboardReadinessTagModerate,
        // Der entscheidende Unterschied: „wieder aufbauen" statt „erholen".
        ReadinessZone.formLoss => l.dashboardReadinessTagFormLoss,
        ReadinessZone.fatigued => l.dashboardReadinessTagFatigued,
        ReadinessZone.overreaching => l.dashboardReadinessTagOverreaching,
      };
}
