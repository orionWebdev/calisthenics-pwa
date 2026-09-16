import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/training_session.dart';

/// Die drei Angaben, die keine Messung sind — Bereitschaft, Gefühl, Fokus.
///
/// Sie stehen hier zusammen, weil sie an vier Stellen gebraucht werden: beim
/// Starten einer Krafteinheit, beim Beenden, im Ausdauerformular, im
/// Regenerationsblatt und beim Bearbeiten. Fünf Kopien derselben Auswahl wären
/// fünf Gelegenheiten, die Wortliste auseinanderlaufen zu lassen.
///
/// **Alle drei sind freiwillig und ohne Vorbelegung.** Eine vorbelegte
/// Selbstauskunft wäre eine Angabe, die niemand gemacht hat — und sie stünde
/// später als Zahl in einer Auswertung.

/// Das Wort zu einer Bereitschaftsstufe.
String readinessWord(AppL10n l, int level) => switch (level) {
      1 => l.formReadiness1,
      2 => l.formReadiness2,
      3 => l.formReadiness3,
      4 => l.formReadiness4,
      _ => l.formReadiness5,
    };

/// Das Wort zu einer Gefühlsstufe.
String feelingWord(AppL10n l, int level) => switch (level) {
      1 => l.formFeeling1,
      2 => l.formFeeling2,
      3 => l.formFeeling3,
      4 => l.formFeeling4,
      _ => l.formFeeling5,
    };

/// Der Name eines Fokus.
String workoutFocusName(AppL10n l, WorkoutFocus focus) => switch (focus) {
      WorkoutFocus.push => l.focusPush,
      WorkoutFocus.pull => l.focusPull,
      WorkoutFocus.legs => l.focusLegs,
      WorkoutFocus.upperBody => l.focusUpperBody,
      WorkoutFocus.lowerBody => l.focusLowerBody,
      WorkoutFocus.fullBody => l.focusFullBody,
      WorkoutFocus.core => l.focusCore,
      WorkoutFocus.other => l.focusOther,
    };

/// Die Farbe einer Stufe der Selbstauskunft, 1 bis 5.
///
/// Rot, Orange, Neutral, Grün, Blau — die Reihenfolge, die der Nutzer am
/// 16.09.2026 festgelegt hat. Nur Tokens: Rot ist [AtemColors.magenta], Orange
/// [AtemColors.amber], Grün [AtemColors.green], Blau [AtemColors.tabCardio].
/// Für Gelb gibt es kein Token, und CLAUDE.md verbietet erfundene Töne; die
/// mittlere Stufe „okay" trägt deshalb das neutrale [AtemColors.textTertiary]
/// — ein Mittelwert ist keine Warnung und kein Lob. Die Farbe ist nie der
/// einzige Träger: Zahl und Wort bleiben.
Color wellnessColor(int level) => switch (level) {
      1 => AtemColors.magenta,
      2 => AtemColors.amber,
      3 => AtemColors.textTertiary,
      4 => AtemColors.green,
      _ => AtemColors.tabCardio,
    };

/// Bereitschaft vor der Einheit, 1 bis 5.
class ReadinessChoice extends StatelessWidget {
  const ReadinessChoice({
    super.key,
    required this.value,
    required this.onChanged,
    this.surface = AtemColors.card,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemScaleChoice(
      value: value,
      onChanged: onChanged,
      groupLabel: l10n.formReadiness,
      colorFor: wellnessColor,
      wordFor: (level) => readinessWord(l10n, level),
      semanticLabelFor: (level) => '${l10n.formReadiness} $level, '
          '${readinessWord(l10n, level)}, $level ${l10n.commonOf} 5',
      surface: surface,
    );
  }
}

/// Gefühl nach der Einheit, 1 bis 5.
class FeelingChoice extends StatelessWidget {
  const FeelingChoice({
    super.key,
    required this.value,
    required this.onChanged,
    this.surface = AtemColors.card,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AtemScaleChoice(
      value: value,
      onChanged: onChanged,
      groupLabel: l10n.formFeeling,
      colorFor: wellnessColor,
      wordFor: (level) => feelingWord(l10n, level),
      semanticLabelFor: (level) => '${l10n.formFeeling} $level, '
          '${feelingWord(l10n, level)}, $level ${l10n.commonOf} 5',
      surface: surface,
    );
  }
}

/// Der Fokus einer Krafteinheit — acht Kapseln, eine davon gewählt.
///
/// Keine Skala: Die acht Werte haben keine Ordnung, und Zahlen darunter wären
/// erfunden. Deshalb [AtemChoiceChip] in einem [Wrap] — er bricht bei 200 %
/// Schrift auf 320 dp von selbst um, und eine umgebrochene Menge ohne Ordnung
/// bleibt dieselbe Menge.
///
/// Erneutes Antippen hebt die Wahl auf: Der Fokus ist freiwillig.
class FocusChoice extends StatelessWidget {
  const FocusChoice({super.key, required this.value, required this.onChanged});

  final WorkoutFocus? value;
  final ValueChanged<WorkoutFocus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Semantics(
      container: true,
      label: l10n.formFocus,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final focus in WorkoutFocus.values)
            AtemChoiceChip(
              label: workoutFocusName(l10n, focus),
              semanticLabel:
                  '${l10n.formFocus}, ${workoutFocusName(l10n, focus)}',
              selected: focus == value,
              onTap: () => onChanged(focus == value ? null : focus),
            ),
        ],
      ),
    );
  }
}
