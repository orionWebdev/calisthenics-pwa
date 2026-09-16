import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/history/presentation/widgets/wellness_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/contrast.dart';

/// Die Skala nach dem Umbau vom 16.09.2026: fünf gleich breite Zahlenfelder,
/// das Wort einmal darunter, Farbe je Stufe.
void main() {
  group('Stufenfarben der Selbstauskunft', () {
    test('die gefüllte Fläche trägt onNeon mit mindestens AA', () {
      for (var level = 1; level <= 5; level++) {
        final ratio = contrastRatio(AtemColors.onNeon, wellnessColor(level));
        expect(ratio, greaterThanOrEqualTo(aaNormalText),
            reason: 'Stufe $level: onNeon auf Stufenfarbe liegt bei '
                '${ratio.toStringAsFixed(2)}:1');
      }
    });

    test('die ungefüllte Zahl in Stufenfarbe hält AA auf Karte und Grund', () {
      for (var level = 1; level <= 5; level++) {
        for (final surface in [AtemColors.card, AtemColors.surfaceSolid]) {
          final ratio = contrastRatio(wellnessColor(level), surface);
          expect(ratio, greaterThanOrEqualTo(aaNormalText),
              reason: 'Stufe $level auf $surface: '
                  '${ratio.toStringAsFixed(2)}:1');
        }
      }
    });
  });

  group('AtemScaleChoice', () {
    Widget host({int? value, double scale = 1.0, double width = 361}) {
      return MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: width,
              child: AtemScaleChoice(
                value: value,
                onChanged: (_) {},
                groupLabel: 'Bereitschaft',
                colorFor: wellnessColor,
                wordFor: (l) =>
                    const ['erschöpft', 'müde', 'okay', 'gut', 'frisch'][l - 1],
                semanticLabelFor: (l) => 'Bereitschaft $l, $l von 5',
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('fünf gleich breite Felder, auch bei 200 % auf 320 dp',
        (tester) async {
      await tester.pumpWidget(host(scale: 2.0, width: 320));
      expect(tester.takeException(), isNull);

      final widths = [
        for (var l = 1; l <= 5; l++)
          tester.getSize(find.text('$l').first).width,
      ];
      // Die Zahl sitzt in einer Expanded-Spalte; die Felder selbst messen wir
      // über die Tappables.
      final fields = find.byType(AtemTappable);
      expect(fields, findsNWidgets(5));
      final fieldWidths = [
        for (final e in fields.evaluate())
          tester.getSize(find.byWidget(e.widget)).width,
      ];
      for (final w in fieldWidths) {
        expect((w - fieldWidths.first).abs(), lessThan(0.5),
            reason: 'Felder ungleich breit: $fieldWidths');
      }
      expect(widths.length, 5);
    });

    testWidgets('ohne Wahl stehen die beiden Enden, mit Wahl das Wort',
        (tester) async {
      await tester.pumpWidget(host());
      expect(find.text('erschöpft … frisch'), findsOneWidget);

      await tester.pumpWidget(host(value: 4));
      expect(find.text('gut'), findsOneWidget);
      expect(find.text('erschöpft … frisch'), findsNothing);
    });

    testWidgets('jedes Feld trägt Zahl und Wort im Semantics-Label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(value: 2));
      expect(find.bySemanticsLabel('Bereitschaft 2, 2 von 5'), findsOneWidget);
      expect(find.bySemanticsLabel('Bereitschaft 5, 5 von 5'), findsOneWidget);
      handle.dispose();
    });
  });
}
