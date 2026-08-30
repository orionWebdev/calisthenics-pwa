import 'package:atem/core/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/contrast.dart';

/// Flächen, auf denen Text stehen kann.
const _surfaces = <String, Color>{
  'base': AtemColors.base,
  'surfaceSolid': AtemColors.surfaceSolid,
  'card': AtemColors.card,
  'surfaceRaised': AtemColors.surfaceRaised,
};

/// Farben, die als Textfarbe zugelassen sind.
///
/// `violet` und `violetLight` fehlen hier absichtlich — sie erreichen auf keiner
/// Fläche AA. Siehe den Test „violet ist keine Textfarbe" weiter unten.
const _textColors = <String, Color>{
  'textPrimary': AtemColors.textPrimary,
  'textSecondary': AtemColors.textSecondary,
  'textTertiary': AtemColors.textTertiary,
  'cyan': AtemColors.cyan,
  'green': AtemColors.green,
  'amber': AtemColors.amber,
  // Die vier Tab-Töne färben die Beschriftung in der Leiste mit — sie sind
  // damit Textfarben und gehören in die Matrix.
  'tabHybrid': AtemColors.tabHybrid,
  'tabStrength': AtemColors.tabStrength,
  'tabCardio': AtemColors.tabCardio,
  'tabRecovery': AtemColors.tabRecovery,
};

/// Paare, die nur für großen Text zugelassen sind (≥ 18 sp, oder ≥ 14 sp fett).
/// Jede Ausnahme braucht eine Begründung — sonst wächst die Liste still.
const _largeTextOnly = <String>{
  // Magenta liegt auf card bei 4,53 und auf surfaceRaised bei 4,26.
  // Als Marken-/CTA-Farbe auf Sheets und Dialogen daher nur groß.
  'magenta on surfaceRaised',
};

void main() {
  group('Kontrastmatrix', () {
    test('jede zugelassene Textfarbe erreicht AA auf jeder Fläche', () {
      final failures = <String>[];

      for (final t in _textColors.entries) {
        for (final s in _surfaces.entries) {
          final pair = '${t.key} on ${s.key}';
          final ratio = contrastRatio(t.value, s.value);
          final threshold =
              _largeTextOnly.contains(pair) ? aaLargeText : aaNormalText;

          if (ratio < threshold) {
            failures.add(
              '$pair: ${ratio.toStringAsFixed(2)}:1 '
              '(nötig ${threshold.toStringAsFixed(1)}:1)',
            );
          }
        }
      }

      expect(failures, isEmpty,
          reason: 'Kontrast unter WCAG AA:\n${failures.join('\n')}');
    });

    test('magenta ist die Marken-CTA-Farbe und liegt auf card knapp über AA',
        () {
      final onCard = contrastRatio(AtemColors.magenta, AtemColors.card);
      expect(onCard, greaterThanOrEqualTo(aaNormalText),
          reason: 'magenta auf card muss AA halten, liegt bei '
              '${onCard.toStringAsFixed(2)}:1');

      // Dokumentiert den bekannten Grenzfall, damit eine Farbänderung auffällt.
      final onRaised =
          contrastRatio(AtemColors.magenta, AtemColors.surfaceRaised);
      expect(onRaised, lessThan(aaNormalText),
          reason: 'Erwartet: magenta hält auf surfaceRaised AA NICHT. '
              'Falls sich das geändert hat, _largeTextOnly aufräumen.');
      expect(onRaised, greaterThanOrEqualTo(aaLargeText));
    });

    test('violet ist keine Textfarbe', () {
      // Vertrag 01-accessibility R4: nur Fläche, Rand, Verlaufsstop.
      expect(_textColors.values, isNot(contains(AtemColors.violet)),
          reason: 'violet darf nicht in die Liste zugelassener Textfarben');
      expect(_textColors.values, isNot(contains(AtemColors.violetLight)),
          reason:
              'violetLight darf nicht in die Liste zugelassener Textfarben');

      // Und der Grund dafür, als Zahl festgehalten.
      for (final s in _surfaces.entries) {
        final v = contrastRatio(AtemColors.violet, s.value);
        expect(v, lessThan(aaNormalText),
            reason: 'violet auf ${s.key} liegt bei ${v.toStringAsFixed(2)}:1 — '
                'falls eine Palettenänderung das behoben hat, diesen Test und '
                'den A11y-Vertrag anpassen');
      }
    });
  });
}
