import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/atem_origin_dot.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/training_session.dart';

/// Das Gebietsschema als Sprach-Kennung für `intl`.
String languageTag(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// Der Name, unter dem eine Einheit erscheint.
///
/// Ohne eigenen Namen tritt die Trainingsart an seine Stelle. Ein leeres Feld
/// wäre in einer Liste schlimmer als eine grobe Bezeichnung — im Bestand
/// tragen nur 29 von 136 Einheiten überhaupt einen Namen.
String sessionName(AppL10n l10n, TrainingSession session) => switch (session) {
      StrengthSession(planName: final name?) => name,
      CardioSession(name: final name?) => name,
      RecoverySession(name: final name?) => name,
      _ => switch (session.kind) {
          SessionKind.strength => l10n.typeStrength,
          SessionKind.bodyweight => l10n.typeBodyweight,
          SessionKind.cardio => l10n.typeCardio,
          SessionKind.recovery => l10n.typeRecovery,
          null => l10n.historyTitle,
        },
    };

/// Die Trainingsart als Wort.
String sessionKindLabel(AppL10n l10n, TrainingSession session) =>
    sessionKindName(l10n, session.kind);

/// Der Name einer Art — auch ohne eine Einheit in der Hand.
///
/// Der Filter braucht ihn für seine Chips, und dort gibt es keine Einheit,
/// nur die Art.
String sessionKindName(AppL10n l10n, SessionKind? kind) => switch (kind) {
      SessionKind.strength => l10n.typeStrength,
      SessionKind.bodyweight => l10n.typeBodyweight,
      SessionKind.cardio => l10n.typeCardio,
      SessionKind.recovery => l10n.typeRecovery,
      null => l10n.historyTitle,
    };

/// Ein Punkt, der die Art auf einen Blick zeigt.
///
/// **Farbe allein reicht nicht** (Vertrag R6) — der Punkt steht deshalb immer
/// neben dem Wort. Er beschleunigt das Überfliegen, er ersetzt es nicht.
///
/// Bewusst keine Kategoriepalette: Der Entscheid aus Modul 5 gilt, dass die
/// Trainingsart keine eigene Farbfamilie bekommt. Hier trägt sie nur eine
/// Abstufung derselben Systemfarben.
Color sessionKindColor(TrainingSession session) => switch (session.kind) {
      SessionKind.strength => AtemColors.magenta,
      SessionKind.bodyweight => AtemColors.violetLight,
      SessionKind.cardio => AtemColors.cyan,
      SessionKind.recovery => AtemColors.green,
      null => AtemColors.textSecondary,
    };

/// Welche Punktform die Herkunft einer Einheit trägt (Board 15, C).
///
/// Die Zuordnung steht hier und nicht an [SessionOrigin]: Die Domäne kennt
/// kein Flutter, und `AtemOriginShape` ist ein Zeichenbefehl.
///
/// Den vierten Zustand — gestrichelt — gibt es hier nicht. Er gehört keiner
/// Einheit: Was noch ungeprüft ist, ist gar keine, sondern ein Datensatz im
/// Eingang.
AtemOriginShape originShape(SessionOrigin origin) => switch (origin) {
      SessionOrigin.app => AtemOriginShape.filled,
      SessionOrigin.watch => AtemOriginShape.hollow,
      SessionOrigin.merged => AtemOriginShape.ringWithCore,
    };
