import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child,
    {bool reduced = true}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    home: Scaffold(body: Center(child: SizedBox(width: 200, child: child))),
    builder: (context, w) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: w!,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Kappenlogik', () {
    test('unter 3 Prozent ohne Kappen, darüber rund', () {
      expect(AtemProgressRules.capFor(0.0), StrokeCap.butt);
      expect(AtemProgressRules.capFor(0.02), StrokeCap.butt);
      expect(AtemProgressRules.capFor(0.03), StrokeCap.round);
      expect(AtemProgressRules.capFor(0.8), StrokeCap.round);
    });

    test('100 Prozent wird als abgeschlossen erkannt', () {
      expect(AtemProgressRules.isComplete(1.0), isTrue);
      expect(AtemProgressRules.isComplete(0.99), isFalse);
    });
  });

  group('AtemProgressBar', () {
    testWidgets('Anteil ist 4 dp hoch, Ablauf 5 dp', (tester) async {
      await _pump(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtemProgressBar.share(value: 0.33, semanticLabel: 'Woche 4 von 12'),
            AtemProgressBar.elapse(value: 0.62, semanticLabel: 'Pause'),
          ],
        ),
      );
      final heights = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .map((s) => s.height)
          .toSet();
      // Der Höhenunterschied ist das Zweitmerkmal neben der Richtung.
      expect(heights, containsAll(<double>[4, 5]));
    });

    testWidgets('meldet den Wert, nicht nur die Existenz', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AtemProgressBar.share(
            value: 0.33, semanticLabel: 'Woche 4 von 12'),
      );
      final node = tester.getSemantics(find.byType(AtemProgressBar));
      expect(node.label, 'Woche 4 von 12');
      expect(node.value, '33 %');
      handle.dispose();
    });

    testWidgets('unbestimmt meldet keinen Wert', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AtemProgressBar.share(
            value: null, semanticLabel: 'Wird ermittelt'),
      );
      final node = tester.getSemantics(find.byType(AtemProgressBar));
      expect(node.value, isEmpty);
      handle.dispose();
    });

    testWidgets('unbestimmt terminiert bei reduzierter Bewegung',
        (tester) async {
      await _pump(
        tester,
        const AtemProgressBar.share(value: null, semanticLabel: 'Misst'),
      );
      // pumpAndSettle wäre sonst hängengeblieben.
      expect(tester.takeException(), isNull);
    });

    testWidgets('überlebt eine Breite von null', (tester) async {
      // Column ohne Streckung — der Balken bekommt keine Breite.
      await _pump(
        tester,
        const Column(children: [
          AtemProgressBar.share(value: 0.5, semanticLabel: 'Test'),
        ]),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert 0 und 100 Prozent ohne Fehler', (tester) async {
      for (final v in [0.0, 1.0]) {
        await _pump(
          tester,
          AtemProgressBar.share(value: v, semanticLabel: 'Test'),
        );
        expect(tester.takeException(), isNull, reason: 'bei $v');
      }
    });
  });

  group('AtemProgressRing', () {
    testWidgets('zeigt bei 100 Prozent einen Haken statt der Zahl',
        (tester) async {
      await _pump(
        tester,
        const AtemProgressRing(
          value: 1.0,
          semanticLabel: 'Protein: Ziel erreicht',
          label: '100%',
        ),
      );
      // Form statt nur Farbe: die Zahl weicht dem Haken.
      expect(find.text('100%'), findsNothing);
    });

    testWidgets('zeigt bei unbestimmt einen Gedankenstrich', (tester) async {
      await _pump(
        tester,
        const AtemProgressRing(value: null, semanticLabel: 'Wird ermittelt'),
      );
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('meldet Label und Wert', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AtemProgressRing(
          value: 0.87,
          semanticLabel: 'Protein: 165 von 190 Gramm',
          label: '87%',
        ),
      );
      final node = tester.getSemantics(find.byType(AtemProgressRing));
      expect(node.label, 'Protein: 165 von 190 Gramm');
      expect(node.value, '87 %');
      handle.dispose();
    });
  });
}
