import 'dart:ui' show Color;

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/time_split.dart';

/// Farbe und Name einer Spur — an einer Stelle, damit Zeit-Split und
/// Trainingstage dieselbe Sprache sprechen.
///
/// Die Farben sind die der Spuren im Verhältnisblock (Cyan Kraft, Violett
/// Ausdauer) und der Bereichston der Regeneration (Grün). Keine neue Farbe:
/// Wer die drei Blöcke untereinander sieht, soll dieselbe Spur an derselben
/// Farbe erkennen. Violett ist hier Fläche, nie Text.
Color trackColor(TrainingTrack track) => switch (track) {
      TrainingTrack.strength => AtemColors.cyan,
      TrainingTrack.cardio => AtemColors.violet,
      TrainingTrack.recovery => AtemColors.green,
    };

String trackName(AppL10n l10n, TrainingTrack track) => switch (track) {
      TrainingTrack.strength => l10n.typeStrength,
      TrainingTrack.cardio => l10n.typeCardio,
      TrainingTrack.recovery => l10n.recoveryTitle,
    };
