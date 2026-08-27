import 'package:flutter/widgets.dart';

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
