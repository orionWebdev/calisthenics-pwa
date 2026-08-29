import 'package:flutter/widgets.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../../history/domain/training_session.dart';

/// Der Name einer Aktivität.
String activityLabel(AppL10n l, CardioActivity? activity) => switch (activity) {
      CardioActivity.run => l.activityRun,
      CardioActivity.bike => l.activityBike,
      CardioActivity.bikeIndoor => l.activityBikeIndoor,
      CardioActivity.swim => l.activitySwim,
      CardioActivity.hike => l.activityHike,
      CardioActivity.walk => l.activityWalk,
      CardioActivity.row => l.activityRow,
      CardioActivity.other || null => l.activityOther,
    };

/// Das Kürzel in der IconBox der Einheitenzeile — „LA", „RA" (Board 11, A2).
///
/// Die ersten zwei Buchstaben des lokalisierten Namens, in Versalien. Kein
/// Symbol: Neun Aktivitäten bräuchten neun Zeichnungen, und die Farbe trägt
/// ohnehin nichts — das Kürzel steht in Cyan, weil es Daten sind.
String activityAbbreviation(AppL10n l, CardioActivity? activity) {
  final name = activityLabel(l, activity);
  return name.length < 2 ? name.toUpperCase() : name.substring(0, 2).toUpperCase();
}

/// Der Name einer Regenerationsart.
String recoveryKindLabel(AppL10n l, RecoverySession session) =>
    switch (session.recoveryKind) {
      RecoveryKind.yoga => l.recoveryKindYoga,
      RecoveryKind.sauna => l.recoveryKindSauna,
      RecoveryKind.stretch => l.recoveryKindStretch,
      RecoveryKind.mobility => l.recoveryKindMobility,
      // Unbekanntes aus der Vorgänger-App wird durchgereicht, nicht versteckt.
      null => session.rawKind ?? session.name ?? l.typeRecovery,
    };

String recoveryKindName(AppL10n l, RecoveryKind kind) => switch (kind) {
      RecoveryKind.yoga => l.recoveryKindYoga,
      RecoveryKind.sauna => l.recoveryKindSauna,
      RecoveryKind.stretch => l.recoveryKindStretch,
      RecoveryKind.mobility => l.recoveryKindMobility,
    };

/// Das Wort zu einer Anstrengung 1–5.
String rpeWord(AppL10n l, int rpe) => switch (rpe) {
      1 => l.formRpe1,
      2 => l.formRpe2,
      3 => l.formRpe3,
      4 => l.formRpe4,
      _ => l.formRpe5,
    };

/// Minuten je Kilometer als „5:23".
String formatMinPerKm(double minutesPerKm) {
  final total = (minutesPerKm * 60).round();
  final min = total ~/ 60;
  final sec = total % 60;
  return '$min:${sec.toString().padLeft(2, '0')}';
}

/// Ein Tempowert in der Einheit seiner Aktivität — „5:23 /km" oder
/// „20,4 km/h". Die Einheit steht im Wert, nicht im Schlüssel (Board 11, G).
String formatTempoValue(BuildContext context, double value,
    {required bool usesSpeed}) {
  final l = AppL10n.of(context);
  return usesSpeed
      ? l.tempoKmh(AtemNumberField.format(context, value))
      : l.tempoPerKm(formatMinPerKm(value));
}

String formatTempo(BuildContext context, CardioTempo tempo) =>
    formatTempoValue(context, tempo.value, usesSpeed: tempo.usesSpeed);

/// Eine Differenz zweier Tempowerte, mit Richtungsglyph und Vorzeichen.
///
/// Bei min/km ist weniger schneller — der Glyph zeigt die Richtung der
/// **Zahl**, das Wort daneben (in Semantics) sagt, ob das schneller ist.
String formatTempoDelta(BuildContext context, double delta,
    {required bool usesSpeed}) {
  final glyph = delta >= 0 ? '▲' : '▼';
  final sign = delta >= 0 ? '+' : '−';
  final magnitude = usesSpeed
      ? AtemNumberField.format(context, delta.abs())
      : formatMinPerKm(delta.abs());
  return '$glyph $sign$magnitude';
}

/// Kilometer mit einer Nachkommastelle in der Sprache des Geräts.
String formatKm(BuildContext context, double km) =>
    AtemNumberField.format(context, (km * 10).round() / 10);

/// Eine Dauer als „18:42" oder „1:02:05".
String formatClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final ms = '${m.toString().padLeft(h > 0 ? 2 : 1, '0')}:'
      '${s.toString().padLeft(2, '0')}';
  return h > 0 ? '$h:$ms' : ms;
}
