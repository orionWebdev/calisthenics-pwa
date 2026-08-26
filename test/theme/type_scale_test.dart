import 'package:atem/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die acht Rollen aus Design-Gespräch 01, plus die dekorative Ausnahme.
final _roles = <String, AtemTextRole>{
  'display': AtemType.display,
  'valueLarge': AtemType.valueLarge,
  'valueMedium': AtemType.valueMedium,
  'titleLarge': AtemType.titleLarge,
  'titleMedium': AtemType.titleMedium,
  'labelMedium': AtemType.labelMedium,
  'labelSmall': AtemType.labelSmall,
  'labelMicro': AtemType.labelMicro,
  'body': AtemType.body,
};

void main() {
  group('Typenskala', () {
    test('keine informationstragende Rolle unter 12 sp', () {
      for (final e in _roles.entries) {
        expect(e.value.base.fontSize, greaterThanOrEqualTo(12.0),
            reason: '${e.key} liegt bei ${e.value.base.fontSize}');
      }
    });

    test('labelDeco ist die einzige Ausnahme und bleibt bei 10 sp', () {
      expect(AtemType.labelDeco.base.fontSize, 10.0);
      expect(_roles.values, isNot(contains(AtemType.labelDeco)));
    });

    test('die Skala hat genau die vereinbarten Größen', () {
      expect(AtemType.display.base.fontSize, 48.0);
      expect(AtemType.valueLarge.base.fontSize, 24.0);
      expect(AtemType.titleLarge.base.fontSize, 20.0);
      expect(AtemType.titleMedium.base.fontSize, 16.0);
      expect(AtemType.valueMedium.base.fontSize, 16.0);
      // Bewusst 14, nicht 12 — sonst kippt die CTA-Hierarchie.
      expect(AtemType.labelMedium.base.fontSize, 14.0);
      expect(AtemType.labelSmall.base.fontSize, 12.0);
      expect(AtemType.labelMicro.base.fontSize, 12.0);
    });
  });

  group('Laufweite bleibt proportional', () {
    testWidgets('labelMicro sperrt bei 200 % doppelt so weit', (tester) async {
      late TextStyle atOne;
      late TextStyle atTwo;

      for (final (scale, sink) in [(1.0, 0), (2.0, 1)]) {
        await tester.pumpWidget(MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Builder(
            builder: (c) {
              final style = AtemType.labelMicro.of(c);
              if (sink == 0) {
                atOne = style;
              } else {
                atTwo = style;
              }
              return const SizedBox();
            },
          ),
        ));
      }

      // Der eigentliche Punkt: Flutter skaliert fontSize, aber NICHT
      // letterSpacing. Ohne AtemTextRole.of bliebe die Sperrung konstant und
      // die Labels rückten bei großer Schrift optisch zusammen.
      expect(atOne.letterSpacing, closeTo(12 * 0.16, 0.001));
      expect(atTwo.letterSpacing, closeTo(24 * 0.16, 0.001));
      expect(atTwo.letterSpacing! / atOne.letterSpacing!, closeTo(2.0, 0.001));
    });

    testWidgets('ungesperrte Rollen bleiben unverändert', (tester) async {
      late TextStyle style;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: Builder(builder: (c) {
          style = AtemType.display.of(c);
          return const SizedBox();
        }),
      ));
      expect(style, same(AtemType.display.base));
    });
  });
}
