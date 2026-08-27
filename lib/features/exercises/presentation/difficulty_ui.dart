import 'package:flutter/widgets.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/muscle.dart';

/// Die Schwierigkeitsstufe in Worten.
///
/// Die vier unteren Wörter sind **dieselben** wie in der Zuordnungstabelle der
/// Vorgänger-App (`js/views/sessionTemplates.js`): `beginner`, `intermediate`,
/// `advanced`, `elite`. Damit zeigt eine alte Übung, die noch ein Wort trägt,
/// nach dem Einlesen genau das Wort wieder an, das in ihr steht — die
/// Abbildung ist unsichtbar, weil sie an keiner Stelle etwas verschiebt.
///
/// Stufe 5 hat kein Gegenstück in der Tabelle; sie kommt nur in den kuratierten
/// Übungen vor, die durchweg Zahlen führen.
String difficultyLabel(AppL10n l, int level) => switch (level) {
      1 => l.difficultyLevel1,
      2 => l.difficultyLevel2,
      3 => l.difficultyLevel3,
      4 => l.difficultyLevel4,
      _ => l.difficultyLevel5,
    };

/// Die Auswahl der Schwierigkeit: **Wörter sichtbar, Zahl gespeichert**.
///
/// Der Rückgabewert ist `int?` und startet auf `null` — es gibt keine
/// Vorbelegung. Die Begründung steht am [ExerciseFormScreen].
class DifficultyChoice extends StatelessWidget {
  const DifficultyChoice({super.key, required this.value, required this.onChanged});

  /// `null` heißt: noch nichts gewählt.
  final int? value;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemSegmented<int>(
      // Ein Wert außerhalb von 1–5 wählt nichts aus. `AtemSegmented` verlangt
      // einen Wert; das ist der ehrlichste Weg, „keiner" auszudrücken, ohne
      // die Schnittstelle des Primitivs für einen Sonderfall aufzuweichen.
      value: value ?? 0,
      onChanged: onChanged,
      groupSemanticLabel: l10n.exerciseFormDifficulty,
      segments: [
        for (var level = Difficulty.min; level <= Difficulty.max; level++)
          AtemSegment(
            value: level,
            label: difficultyLabel(l10n, level),
            semanticLabel:
                l10n.difficultyPick(difficultyLabel(l10n, level), level),
          ),
      ],
    );
  }
}
