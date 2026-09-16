import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/history_summary.dart';

/// Farbe und Text zu einer [HistoryZone].
///
/// **Farbe trägt hier nur die Richtung des Zustands** — nicht die Trainingsart.
/// Der Entscheid aus Modul 5 gilt weiter: Arten bekommen keine Farbe.
extension HistoryZoneUi on HistoryZone {
  Color get color => switch (this) {
        HistoryZone.rhythm => AtemColors.green,
        HistoryZone.recent => AtemColors.cyan,
        // Kein Magenta: Eine Pause ist keine Störung. Neutralton.
        HistoryZone.pause => AtemColors.textPrimary,
        HistoryZone.inactive => AtemCategories.grey,
      };

  String label(AppL10n l) => switch (this) {
        HistoryZone.rhythm => l.historyZoneRhythm,
        HistoryZone.recent => l.historyZoneRecent,
        HistoryZone.pause => l.historyZonePause,
        HistoryZone.inactive => l.historyZoneInactive,
      };
}
